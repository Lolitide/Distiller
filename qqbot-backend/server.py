"""QQ 机器人本地控制台（Web 版）。

一个只跑在本机的小服务，用来：
  - 一键启动 / 停止 / 重启机器人
  - 实时查看机器人日志（含历史日志回放）
  - 查看机器人运行状态与消息统计
  - 浏览已收集的群消息，并能打开/下载原始数据库

依赖只用标准库 + 已有的 aiosqlite（见 requirements.txt），不需要 Flask/FastAPI。

启动：
    .venv\\Scripts\\python.exe -X utf8 server.py
然后浏览器打开 http://127.0.0.1:8730
"""

from __future__ import annotations

import asyncio
import base64
import functools
import hmac
import json
import os
import sqlite3
import sys
import time
from collections import OrderedDict, deque
from datetime import datetime, timedelta
from http import HTTPStatus
from pathlib import Path

import relay  # 机器人消息中继：订阅路由 + 内存消息窗口（不含正文落盘）
import llm_worker  # 后台解析线程（小模型优先、失败回退规则）
import llm_parse  # 小模型调用层（/parse 的图片 OCR 与能力探测用）
import candidate_engine  # v2 候选管道：去重 + 聚类 + 综合总结（/candidates 的数据来源）
import group_lexicon  # 按群自学习的领域词表（只落盘词+次数+类别，不含正文）
import office_extract  # docx/xlsx/pptx（标准库）与 PDF（pypdf 软依赖）文本抽取
import profile_summarize  # 用户画像词条归纳（无状态：只处理、不存储）
import push_sender  # Push Kit 云侧发送（服务账号 JWT(PS256) -> 华为网关）

import aiohttp  # /attachment 从 QQ 拉附件字节（共享依赖，见 requirements.txt）

# 读取 qqbot-backend/.env（与 botpy_main.py 同源），让控制台口令等配置只写一处。
# python-dotenv 缺失时静默跳过，不影响启动。
try:
    from dotenv import load_dotenv

    load_dotenv()
except Exception:  # noqa: BLE001
    pass

BASE_DIR = Path(__file__).resolve().parent
WEB_DIR = BASE_DIR / "web"
BOT_SCRIPT = BASE_DIR / "botpy_main.py"
DB_PATH = BASE_DIR / "bot.db"
LOG_FILE = BASE_DIR / "botpy.log"

# 默认只听本机；要让手机上的 App 连进来，启动时设 QQBOT_CONSOLE_HOST=0.0.0.0
HOST = os.environ.get("QQBOT_CONSOLE_HOST", "127.0.0.1")
PORT = int(os.environ.get("QQBOT_CONSOLE_PORT", "8730"))

# 公开口：**只放行 /api/relay/***（App 用的那套接口），专门给内网穿透指向。
# 控制台（网页 / 日志 / 数据库下载 / 启停）一律不在此端口上，所以穿透到公网
# 也看不到、动不了控制台。
PUBLIC_HOST = os.environ.get("QQBOT_PUBLIC_HOST", "127.0.0.1")
PUBLIC_PORT = int(os.environ.get("QQBOT_PUBLIC_PORT", "8731"))

# 控制台口令：设置后，所有「非 /api/relay/*」的路径（含网页、日志、下载、
# 启停接口）都要 HTTP Basic Auth 才放行。用于「只让内部测试人员进控制台」。
# 不设则为不启用（仅适合纯本机使用，启动时会打印告警）。
CONSOLE_USER = os.environ.get("QQBOT_CONSOLE_USER", "admin")
CONSOLE_PASSWORD = os.environ.get("QQBOT_CONSOLE_PASSWORD", "")

# 机器人日志最多缓存多少行
LOG_BUFFER_SIZE = 2000

# ---------------------------------------------------------------- 日志缓冲


class LogBuffer:
    """线程安全的环形日志缓冲，同时落一份到文件。"""

    def __init__(self, size: int = LOG_BUFFER_SIZE):
        self._lines: deque[dict] = deque(maxlen=size)
        self._seq = 0
        self._lock = asyncio.Lock()

    async def add(self, text: str, stream: str = "stdout") -> None:
        text = text.rstrip("\r\n")
        if not text:
            return
        async with self._lock:
            self._seq += 1
            self._lines.append(
                {
                    "seq": self._seq,
                    "ts": datetime.now().strftime("%H:%M:%S"),
                    "stream": stream,
                    "text": text,
                }
            )
        # 追加到日志文件，方便事后查看
        try:
            with open(LOG_FILE, "a", encoding="utf-8") as fh:
                fh.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} {text}\n")
        except OSError:
            pass

    async def since(self, after_seq: int, limit: int = 500) -> list[dict]:
        async with self._lock:
            items = [l for l in self._lines if l["seq"] > after_seq]
        return items[-limit:]

    async def tail(self, count: int = 300) -> list[dict]:
        async with self._lock:
            return list(self._lines)[-count:]

    @property
    def last_seq(self) -> int:
        return self._seq

    async def clear(self) -> None:
        async with self._lock:
            self._lines.clear()


# ---------------------------------------------------------------- 进程管理


class BotProcess:
    """管理 botpy_main.py 子进程。"""

    def __init__(self, log_buffer: LogBuffer):
        self.logs = log_buffer
        self.proc: asyncio.subprocess.Process | None = None
        self.started_at: float | None = None
        self._pump_task: asyncio.Task | None = None
        self._lock = asyncio.Lock()
        self.ready = False
        self.exited_after_start = False

    # -- 状态 --------------------------------------------------------
    @property
    def running(self) -> bool:
        return self.proc is not None and self.proc.returncode is None

    def status(self) -> dict:
        uptime = None
        if self.running and self.started_at:
            uptime = int(time.time() - self.started_at)

        # 区分"进程活着但还没连上网关"和"真正就绪"
        if self.running:
            phase = "ready" if self.ready else "starting"
        elif self.exited_after_start:
            phase = "failed"
        else:
            phase = "stopped"

        return {
            "running": self.running,
            "phase": phase,
            "ready": self.ready,
            "pid": self.proc.pid if self.running else None,
            "uptime_seconds": uptime,
            "started_at": (
                datetime.fromtimestamp(self.started_at).strftime("%Y-%m-%d %H:%M:%S")
                if self.started_at
                else None
            ),
            "last_exit_code": (
                None if self.proc is None or self.running else self.proc.returncode
            ),
            "script": BOT_SCRIPT.name,
        }

    # -- 启动 --------------------------------------------------------
    async def start(self) -> dict:
        async with self._lock:
            if self.running:
                return {"ok": False, "error": "机器人已经在运行中"}

            if not BOT_SCRIPT.exists():
                return {"ok": False, "error": f"找不到 {BOT_SCRIPT.name}"}

            await self.logs.add("=" * 60)
            await self.logs.add(f"[控制台] 正在启动 {BOT_SCRIPT.name} ...")

            env = os.environ.copy()
            env["PYTHONIOENCODING"] = "utf-8"
            env["PYTHONUTF8"] = "1"
            env["PYTHONUNBUFFERED"] = "1"
            # 把本进程解析出的内部推送密钥显式传给机器人进程，保证两边一致
            env["QQBOT_RELAY_KEY"] = relay.INTERNAL_RELAY_KEY

            try:
                self.proc = await asyncio.create_subprocess_exec(
                    sys.executable,
                    "-u",
                    "-X",
                    "utf8",
                    str(BOT_SCRIPT),
                    cwd=str(BASE_DIR),
                    env=env,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.STDOUT,
                )
            except Exception as exc:  # noqa: BLE001
                self.proc = None
                await self.logs.add(f"[控制台] 启动失败: {exc}", "stderr")
                return {"ok": False, "error": f"启动失败: {exc}"}

            self.started_at = time.time()
            self.ready = False
            self.exited_after_start = False
            self._pump_task = asyncio.create_task(self._pump(self.proc))
            await self.logs.add(f"[控制台] 已启动，PID={self.proc.pid}")
            return {"ok": True, "pid": self.proc.pid}

    async def _pump(self, proc: asyncio.subprocess.Process) -> None:
        """持续读取子进程输出，写入日志缓冲。"""
        assert proc.stdout is not None
        try:
            while True:
                raw = await proc.stdout.readline()
                if not raw:
                    break
                text = raw.decode("utf-8", errors="replace")
                await self.logs.add(text, "stdout")
                if "启动成功" in text or "已上线" in text:
                    self.ready = True
        except asyncio.CancelledError:
            raise
        except Exception as exc:  # noqa: BLE001
            await self.logs.add(f"[控制台] 读取日志异常: {exc}", "stderr")

        code = await proc.wait()
        await self.logs.add(f"[控制台] 机器人进程已退出，退出码={code}")
        if proc is self.proc:
            self.proc = None
            self.ready = False
            self.exited_after_start = True

    # -- 停止 --------------------------------------------------------
    async def stop(self, timeout: float = 8.0) -> dict:
        async with self._lock:
            proc = self.proc
            if proc is None or proc.returncode is not None:
                self.proc = None
                return {"ok": False, "error": "机器人当前没有在运行"}

            await self.logs.add("[控制台] 正在停止机器人 ...")
            try:
                proc.terminate()
            except ProcessLookupError:
                pass

            try:
                await asyncio.wait_for(proc.wait(), timeout=timeout)
            except asyncio.TimeoutError:
                await self.logs.add("[控制台] 等待超时，强制结束进程 ...")
                try:
                    proc.kill()
                except ProcessLookupError:
                    pass
                try:
                    await asyncio.wait_for(proc.wait(), timeout=5)
                except asyncio.TimeoutError:
                    await self.logs.add("[控制台] 无法结束进程，请手动处理", "stderr")

            if self._pump_task and not self._pump_task.done():
                self._pump_task.cancel()

            self.proc = None
            self.started_at = None
            self.ready = False
            self.exited_after_start = False  # 主动停止不算启动失败
            await self.logs.add("[控制台] 机器人已停止")
            return {"ok": True}

    async def restart(self) -> dict:
        if self.running:
            await self.stop()
            await asyncio.sleep(1.5)
        return await self.start()

    async def shutdown(self) -> None:
        """控制台退出时顺手把机器人也停掉，避免残留进程。"""
        if self.running:
            await self.stop(timeout=5)


# ------------------------------------------------------------ 网页心跳看门狗


class Watchdog:
    """网页关掉后自动停止控制台的可选功能。

    网页每隔几秒发一次心跳；一旦超过 ``timeout`` 秒没收到心跳，
    就认为网页已经关闭，于是停机器人并结束控制台进程。

    超时故意设得比较长（默认 60 秒），这样切换标签页、切换网络、
    系统短暂休眠都不会误触发。
    """

    def __init__(self, timeout: float = 60.0, enabled: bool = False):
        self.timeout = timeout
        self.enabled = enabled
        self.last_beat = 0.0
        self._task: asyncio.Task | None = None
        self.fired = False

    def beat(self) -> None:
        self.last_beat = time.time()
        self.fired = False

    def pending(self) -> bool:
        """是否已经收到过心跳（没收到过就不该触发）。"""
        return self.last_beat > 0

    def start(self) -> None:
        if self._task is None or self._task.done():
            self._task = asyncio.create_task(self._loop())

    async def _loop(self) -> None:
        while True:
            await asyncio.sleep(2.0)
            if not self.enabled or not self.pending():
                continue
            idle = time.time() - self.last_beat
            if idle > self.timeout:
                self.fired = True
                await bot.logs.add(
                    f"[控制台] 网页已关闭（{int(idle)} 秒无心跳），自动停止控制台"
                )
                await bot.shutdown()
                os._exit(0)

    def status(self) -> dict:
        return {
            "enabled": self.enabled,
            "timeout": self.timeout,
            "idle": round(time.time() - self.last_beat, 1) if self.pending() else None,
        }


# ---------------------------------------------------------------- 数据查询


def _connect() -> sqlite3.Connection:
    """以只读方式打开数据库，避免和机器人抢写锁。"""
    uri = f"file:{DB_PATH.as_posix()}?mode=ro"
    conn = sqlite3.connect(uri, uri=True, timeout=5.0)
    conn.row_factory = sqlite3.Row
    return conn


def _run_db(fn):
    """把阻塞的 sqlite 操作丢到线程池执行。"""
    return asyncio.to_thread(fn)


def _table_columns(conn: sqlite3.Connection, table: str) -> list[str]:
    rows = conn.execute(f'PRAGMA table_info("{table}")').fetchall()
    return [r["name"] for r in rows]


def _list_tables(conn: sqlite3.Connection) -> list[str]:
    rows = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name"
    ).fetchall()
    return [r["name"] for r in rows]


def _stats_sync() -> dict:
    if not DB_PATH.exists():
        return {"total": 0, "senders": 0, "groups": 0, "today": 0, "daily": []}
    conn = _connect()
    try:
        tables = _list_tables(conn)
        if "group_messages" not in tables:
            return {"total": 0, "senders": 0, "groups": 0, "today": 0, "daily": [],
                    "note": "数据库里还没有建表，先启动一次机器人"}

        total = conn.execute("SELECT COUNT(*) c FROM group_messages").fetchone()["c"]
        senders = conn.execute(
            "SELECT COUNT(DISTINCT sender_openid) c FROM group_messages"
        ).fetchone()["c"]
        groups = conn.execute(
            "SELECT COUNT(DISTINCT group_openid) c FROM group_messages"
        ).fetchone()["c"]

        today = datetime.now().strftime("%Y-%m-%d")
        today_count = conn.execute(
            "SELECT COUNT(*) c FROM group_messages "
            "WHERE substr(COALESCE(timestamp, created_at), 1, 10) = ?",
            (today,),
        ).fetchone()["c"]

        # event_type 列可能不存在（旧库）
        cols = _table_columns(conn, "group_messages")
        by_event = []
        if "event_type" in cols:
            by_event = [
                {"event_type": r["event_type"] or "(未知)", "count": r["c"]}
                for r in conn.execute(
                    "SELECT event_type, COUNT(*) c FROM group_messages "
                    "GROUP BY event_type ORDER BY c DESC"
                ).fetchall()
            ]

        # 最近 7 天
        daily = []
        for i in range(6, -1, -1):
            day = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
            c = conn.execute(
                "SELECT COUNT(*) c FROM group_messages "
                "WHERE substr(COALESCE(timestamp, created_at), 1, 10) = ?",
                (day,),
            ).fetchone()["c"]
            daily.append({"date": day, "count": c})

        latest = None
        row = conn.execute(
            "SELECT sender_name, content, COALESCE(timestamp, created_at) t "
            "FROM group_messages ORDER BY created_at DESC, rowid DESC LIMIT 1"
        ).fetchone()
        if row:
            latest = {"sender": row["sender_name"], "content": row["content"], "time": row["t"]}

        return {
            "total": total,
            "senders": senders,
            "groups": groups,
            "today": today_count,
            "daily": daily,
            "by_event": by_event,
            "latest": latest,
            "db_size": DB_PATH.stat().st_size if DB_PATH.exists() else 0,
        }
    finally:
        conn.close()


def _messages_sync(
    keyword: str = "",
    group: str = "",
    limit: int = 50,
    offset: int = 0,
    order: str = "desc",
) -> dict:
    if not DB_PATH.exists():
        return {"total": 0, "rows": [], "groups": []}
    conn = _connect()
    try:
        tables = _list_tables(conn)
        if "group_messages" not in tables:
            return {"total": 0, "rows": [], "groups": []}

        cols = _table_columns(conn, "group_messages")
        has_event = "event_type" in cols
        has_mtype = "message_type" in cols

        where, params = [], []
        if keyword:
            where.append("(content LIKE ? OR sender_name LIKE ?)")
            params.extend([f"%{keyword}%", f"%{keyword}%"])
        if group:
            where.append("group_openid = ?")
            params.append(group)
        clause = f"WHERE {' AND '.join(where)}" if where else ""

        total = conn.execute(
            f"SELECT COUNT(*) c FROM group_messages {clause}", params
        ).fetchone()["c"]

        direction = "ASC" if str(order).lower() == "asc" else "DESC"
        select_cols = [
            "msg_id",
            "group_openid",
            "sender_openid",
            "sender_name",
            "content",
            "timestamp",
            "created_at",
            "attachments",
            "mentions",
            "member_role",
        ]
        if has_event:
            select_cols.append("event_type")
        if has_mtype:
            select_cols.append("message_type")

        sql = (
            f"SELECT {', '.join(select_cols)} FROM group_messages {clause} "
            f"ORDER BY created_at {direction}, rowid {direction} LIMIT ? OFFSET ?"
        )
        rows = [dict(r) for r in conn.execute(sql, [*params, limit, offset]).fetchall()]

        # 附件数量 / @数量 便于前端展示
        for r in rows:
            r["attachment_count"] = _json_len(r.get("attachments"))
            r["mention_count"] = _json_len(r.get("mentions"))

        groups = [
            {"group_openid": r["group_openid"], "count": r["c"]}
            for r in conn.execute(
                "SELECT group_openid, COUNT(*) c FROM group_messages "
                "GROUP BY group_openid ORDER BY c DESC"
            ).fetchall()
        ]
        return {"total": total, "rows": rows, "groups": groups, "offset": offset, "limit": limit}
    finally:
        conn.close()


def _json_len(value) -> int:
    if not value:
        return 0
    try:
        parsed = json.loads(value)
        return len(parsed) if isinstance(parsed, list) else 0
    except (TypeError, ValueError):
        return 0


# ------------------------------------------------------- 群名称查询（按需）
# 说明：数据库里只存了 group_openid（平台从不下发群名），所以网页上的"全部群"
# 下拉框以前只能显示一串截断的 openid。
#
# 具体实现已挪到 relay.py（`resolve_group_names` / `group_label`），原因是
# **机器人进程也需要群名**：群消息进中继窗口时要带上 group_label，
# 这样 App 拿到的每条消息都自带可读群名。两个进程共享 group_names.json 缓存。
#
# 这个能力是"尽力而为"的：
#   - 拿不到凭证 / 平台报错（没权限、机器人不在群里）-> 群名返回 null，
#     界面自动回退显示"群 …（openid 尾号）"，不报错、不影响其他功能。
#   - 失败过的群 10 分钟内不重复查平台。


def _group_names_sync(ids: list[str], refresh: bool = False) -> dict:
    return relay.resolve_group_names(ids, refresh)


def _tables_sync() -> dict:
    if not DB_PATH.exists():
        return {"tables": [], "columns": {}}
    conn = _connect()
    try:
        tables = _list_tables(conn)
        columns = {}
        counts = {}
        for t in tables:
            columns[t] = _table_columns(conn, t)
            try:
                counts[t] = conn.execute(f'SELECT COUNT(*) c FROM "{t}"').fetchone()["c"]
            except sqlite3.Error:
                counts[t] = None
        return {"tables": tables, "columns": columns, "counts": counts}
    finally:
        conn.close()


def _table_rows_sync(table: str, limit: int = 50, offset: int = 0) -> dict:
    if not DB_PATH.exists():
        return {"total": 0, "rows": [], "columns": []}
    conn = _connect()
    try:
        if table not in _list_tables(conn):
            return {"error": f"表 {table} 不存在"}
        columns = _table_columns(conn, table)
        total = conn.execute(f'SELECT COUNT(*) c FROM "{table}"').fetchone()["c"]
        rows = [
            dict(r)
            for r in conn.execute(
                f'SELECT * FROM "{table}" ORDER BY rowid DESC LIMIT ? OFFSET ?',
                (limit, offset),
            ).fetchall()
        ]
        return {"total": total, "rows": rows, "columns": columns}
    finally:
        conn.close()


# ---------------------------------------------------------------- HTTP 路由

bot = BotProcess(LogBuffer())
watchdog = Watchdog(timeout=60.0, enabled=False)
_START_TIME = time.time()


async def api_status() -> dict:
    status = bot.status()
    try:
        stats = await _run_db(_stats_sync)
    except sqlite3.Error as exc:
        stats = {"error": str(exc)}
    status["stats"] = stats
    status["watchdog"] = watchdog.status()
    status["console_uptime"] = int(time.time() - _START_TIME)
    status["server_time"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return status


async def api_start() -> dict:
    return await bot.start()


async def api_stop() -> dict:
    return await bot.stop()


async def api_restart() -> dict:
    return await bot.restart()


async def api_logs(query: dict) -> dict:
    after = int(query.get("after", ["0"])[0] or 0)
    if after > 0:
        lines = await bot.logs.since(after)
    else:
        lines = await bot.logs.tail(400)
    return {"lines": lines, "last_seq": bot.logs.last_seq}


async def api_messages(query: dict) -> dict:
    keyword = (query.get("keyword", [""])[0] or "").strip()
    group = (query.get("group", [""])[0] or "").strip()
    order = (query.get("order", ["desc"])[0] or "desc").strip()
    try:
        limit = min(max(int(query.get("limit", ["50"])[0]), 1), 500)
        offset = max(int(query.get("offset", ["0"])[0]), 0)
    except ValueError:
        limit, offset = 50, 0
    return await _run_db(lambda: _messages_sync(keyword, group, limit, offset, order))


async def api_group_names(query: dict) -> dict:
    """按 openid 查群名：/api/group_names?ids=a,b,c&refresh=1

    结果会缓存在内存里，网页每次加载消息都带上 ids 就是走缓存，不会每次都请求平台。
    """
    raw = (query.get("ids", [""])[0] or "").strip()
    ids = [g.strip() for g in raw.split(",") if g.strip()]
    refresh = (query.get("refresh", ["0"])[0] or "") not in ("", "0", "false")
    if not ids:
        return {"names": {}, "queried": 0, "error": None}
    return await _run_db(lambda: _group_names_sync(ids, refresh))


async def api_tables() -> dict:
    return await _run_db(_tables_sync)


async def api_table_rows(query: dict) -> dict:
    table = (query.get("table", [""])[0] or "").strip()
    try:
        limit = min(max(int(query.get("limit", ["50"])[0]), 1), 500)
        offset = max(int(query.get("offset", ["0"])[0]), 0)
    except ValueError:
        limit, offset = 50, 0
    return await _run_db(lambda: _table_rows_sync(table, limit, offset))


# ------------------------------------------------- 机器人通道（App ↔ 中继）

OK = HTTPStatus.OK
BAD_REQUEST = HTTPStatus.BAD_REQUEST
UNAUTHORIZED = HTTPStatus.UNAUTHORIZED

# 开发用假消息注入开关：默认关闭。
# 让 App 在没有真实 QQ 消息的情况下也能联调（见《开发指南》第 6 节）。
DEV_INGEST = os.environ.get("QQBOT_DEV_INGEST", "0") not in ("", "0", "false", "False")

# 启动后端时是否顺带把机器人拉起来（一条龙启动用；默认关，保持原行为）
AUTOSTART_BOT = os.environ.get("QQBOT_AUTOSTART_BOT", "0") not in ("", "0", "false", "False")

# 机器人通道的接口清单（去掉 /api/relay 前缀后的**内部键**）。
# 注意：外部路径统一是 **/api/relay/***。控制台自己已经有 /api/messages（读 bot.db
# 的网页消息页）和 /api/status，如果机器人通道直接占用 /api/messages 会撞车——
# 这个坑已经踩过一次，所以机器人通道的接口都放在 /api/relay/ 命名空间下。
RELAY_PATHS = {
    "/health",
    "/device/register",
    "/bind/code",
    "/bind/status",
    "/groups",
    "/subscribe",
    "/unsubscribe",
    "/messages",
    "/messages/update",
    "/candidates",
    "/attachment",
    "/parse",
    "/feedback",
    "/profile",
    "/push/token",
    "/my/data",
    "/dev/ingest",
    "/internal/ingest",
    "/admin/bindings",
    "/admin/grant",
    "/admin/revoke",
}


# 候选流状态：内存中维护 candidate_id -> candidate 与单调 rev_seq（不落盘，
# 随 30 分钟窗口一起过期）。/candidates 每次重建时只有「内容变了」的候选会带新 rev_seq。
CANDIDATE_STREAM = candidate_engine.CandidateStream()

# ---- POST /api/relay/parse（手动添加任务：文本/截图/文件）的约束 ----
# 请求体总上限（base64 图片会放大 4/3，原来 1MB 不够一张截图）
MAX_BODY_BYTES = 12 * 1024 * 1024
# 单张图片 base64 上限（约 6MB 原图）
MAX_PARSE_IMAGE_B64 = 8 * 1024 * 1024
# 单个文件 base64 上限（约 3MB 原文件）
MAX_PARSE_FILE_B64 = 4 * 1024 * 1024
# 送解析的文本长度上限（超长 OCR / 文本截断，避免撑爆模型上下文）
MAX_PARSE_TEXT_CHARS = 4000
# 文件来源支持的扩展名：图片走后端 OCR；纯文本直接当正文；
# Office/PDF（docx/xlsx/pptx/pdf）走 office_extract 抽取（pdf 需 pypdf 软依赖）
_PARSE_IMAGE_EXTS = (".png", ".jpg", ".jpeg", ".webp", ".bmp")
_PARSE_TEXT_EXTS = (".txt", ".md", ".csv", ".log", ".json")
_PARSE_OFFICE_EXTS = (".docx", ".xlsx", ".pptx", ".pdf")

# ---- GET /api/relay/attachment（附件过路）的约束 ----
# 单附件字节上限：QQ 单文件 12MB，过路不放大它
ATTACHMENT_MAX_BYTES = 12 * 1024 * 1024
# 同时从 QQ 拉附件的并发上限：家庭上行带宽是瓶颈，8 路够一屋子设备用
ATTACHMENT_FETCH_CONCURRENCY = 8
# 同一附件的短 TTL 缓存（纯内存）：90 秒内多个设备要同一附件只打一次 QQ
ATTACHMENT_CACHE_TTL = 90.0
ATTACHMENT_CACHE_MAX_ITEMS = 16
ATTACHMENT_CACHE_MAX_BYTES = 64 * 1024 * 1024
# 从 QQ 读流的分块大小
ATTACHMENT_CHUNK = 64 * 1024


def _normalize_time(text: str) -> tuple[str, bool]:
    """把用户改写的时间原话按**规则**归一化（绝不靠 AI）；认不出就留空、不猜。

    与候选管道同一套规则（`pipeline_proto.parse_time`）：
      * 解析不出来 -> ("", False)；
      * 看得出是「下周 / 月底」这类推不出确切日期的 -> ("", True)（即 unresolved）。
    """
    slot = candidate_engine.RULES.parse_time(text or "", datetime.now())
    if slot is None:
        return "", False
    if slot.unresolved:
        return "", True
    return (slot.normalized or ""), False

# 群领域词表的在线学习间隔（秒）。学到的词落盘、跨重启累积。
LEXICON_INTERVAL = int(os.environ.get("QQBOT_LEXICON_INTERVAL", "300"))


async def push_loop() -> None:
    """后台推送：窗口里出现**新增/变化**的候选时，给订阅了该群的设备发通知。

    为什么必须有它：App 在后台不轮询（HarmonyOS 不允许普通应用后台长跑），
    只有云侧推送能把用户叫回来。候选的 `changed` 由 `CandidateStream.rebuild`
    的窗口指纹闸保证 —— 同一份窗口不会重复推。

    隐私：默认带标题+摘要（`QQBOT_PUSH_INCLUDE_TEXT=0` 可改成只推"有新提醒"）。
    推送内容会经过华为网关，这一条已记进 06 文档的隐私表。
    """
    interval = max(10.0, float(os.environ.get("QQBOT_PUSH_INTERVAL", "10") or 10))
    include_text = (os.environ.get("QQBOT_PUSH_INCLUDE_TEXT", "1") or "1").strip() != "0"
    if not push_sender.configured():
        print("[推送] 未配置服务账号（QQBOT_PUSH_SA），后台推送不启动")
        return
    print(f"[推送] 已启动（间隔 {interval:.0f}s，正文={'开' if include_text else '关'}）")
    while True:
        await asyncio.sleep(interval)
        try:
            changed = await _run_db(
                lambda: CANDIDATE_STREAM.rebuild(relay.window_candidate_source())
            )
            for c in changed:
                if c.get("kind") not in candidate_engine._ACTIONABLE:
                    continue
                gid = str((c.get("source") or {}).get("group_openid") or "")
                if not gid:
                    continue
                tokens = await _run_db(lambda g=gid: relay.STORE.push_tokens_of_group(g))
                if not tokens:
                    continue
                if include_text:
                    title = str(c.get("title") or "知了")[:32]
                    body = str(c.get("summary") or "")[:80]
                else:
                    title, body = "知了", "有新的校园提醒，点开查看"
                for tk in tokens[:200]:
                    await _run_db(lambda t=tk, ti=title, bo=body: push_sender.send(t, ti, bo))
        except Exception as exc:  # noqa: BLE001
            print(f"[推送] 本轮失败：{exc}")


async def lexicon_loop() -> None:
    """后台定期从窗口里给每个群增量学词表（个性化识别的数据来源）。

    只落盘「词 + 次数 + 类别」，不落盘正文（见 group_lexicon 的隐私红线）。
    """
    while True:
        await asyncio.sleep(max(30, LEXICON_INTERVAL))
        try:
            items = relay.window_candidate_source()
            if not items:
                continue
            added = await _run_db(lambda: group_lexicon.learn_from_window(items))
            if added:
                await bot.logs.add(
                    f"[词表] 增量学习：{len(added)} 个群，"
                    f"新增 {sum(added.values())} 词；累计 {group_lexicon.STORE.stats()}"
                )
        except Exception as exc:  # noqa: BLE001
            await bot.logs.add(f"[词表] 学习异常：{exc}", "stderr")


# ---------------------------------------------------------------- 附件过路
# GET /api/relay/attachment?msg_id=…&index=…：App 按需取某条消息的第 index 个附件。
# 设计（07_前后端对接方案 §5.3）：**字节不落盘**——消息元数据只在 30 分钟窗口里，
# 设备必须订阅了所在群；服务器从 QQ 拉、内存里短缓存，转发给 App 后即丢。
# QQ 附件直链能否 GET 属「未取证」项：拉取失败统一 502 降级，真机联调时重点关注。


async def _fetch_attachment_bytes(url: str) -> tuple[str, bytes]:
    """从 QQ 拉附件字节（64KB 流式读、12MB 截断），返回 (content_type, body)。

    全程内存、不落盘；失败抛异常（由调用方统一转 502）。
    """
    timeout = aiohttp.ClientTimeout(total=30, connect=10)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        async with session.get(url) as resp:
            if resp.status != 200:
                raise RuntimeError(f"QQ 返回 HTTP {resp.status}")
            ctype = (resp.headers.get("Content-Type") or "").split(";")[0].strip()
            declared = resp.headers.get("Content-Length") or ""
            if declared.isdigit() and int(declared) > ATTACHMENT_MAX_BYTES:
                raise RuntimeError(f"附件超过 12MB（{int(declared)} 字节），拒绝转发")
            buf = bytearray()
            async for chunk in resp.content.iter_chunked(ATTACHMENT_CHUNK):
                buf.extend(chunk)
                if len(buf) > ATTACHMENT_MAX_BYTES:
                    raise RuntimeError("附件超过 12MB，中途截断")
            return (ctype or "application/octet-stream"), bytes(buf)


_att_gate: asyncio.Semaphore | None = None
_att_gate_loop: asyncio.AbstractEventLoop | None = None
_att_cache: OrderedDict[str, tuple[float, str, bytes]] = OrderedDict()
_att_cache_bytes = 0


def _att_gate_get() -> asyncio.Semaphore:
    global _att_gate, _att_gate_loop
    loop = asyncio.get_running_loop()
    # Semaphore 绑定创建它的 event loop：常驻服务一个 loop 用到底；
    # 测试每次 asyncio.run 都是新 loop，检测到换了就重建
    # （3.14 的 C 版 Semaphore 没有 get_loop()，自己记一份所属循环）。
    if _att_gate is None or _att_gate_loop is not loop:
        _att_gate = asyncio.Semaphore(ATTACHMENT_FETCH_CONCURRENCY)
        _att_gate_loop = loop
    return _att_gate


def _att_cache_get(url: str) -> tuple[str, bytes] | None:
    global _att_cache_bytes
    entry = _att_cache.get(url)
    if entry is None:
        return None
    fetched_at, ctype, blob = entry
    if time.monotonic() - fetched_at > ATTACHMENT_CACHE_TTL:
        _att_cache.pop(url, None)
        _att_cache_bytes -= len(blob)
        return None
    _att_cache.move_to_end(url)
    return ctype, blob


def _att_cache_put(url: str, ctype: str, blob: bytes) -> None:
    global _att_cache_bytes
    _att_cache[url] = (time.monotonic(), ctype, blob)
    _att_cache.move_to_end(url)
    _att_cache_bytes += len(blob)
    # 先清过期，再按「条数 16 / 总量 64MB」从最旧开始逐出，内存有界
    now = time.monotonic()
    expired = [k for k, (at, _, _) in _att_cache.items() if now - at > ATTACHMENT_CACHE_TTL]
    for key in expired:
        _, _, old = _att_cache.pop(key)
        _att_cache_bytes -= len(old)
    while _att_cache and (
        len(_att_cache) > ATTACHMENT_CACHE_MAX_ITEMS
        or _att_cache_bytes > ATTACHMENT_CACHE_MAX_BYTES
    ):
        _, entry = _att_cache.popitem(last=False)
        _att_cache_bytes -= len(entry[2])


async def resolve_attachment(
    method: str, query: dict, headers: dict
) -> tuple[int, dict, bytes, str]:
    """GET /api/relay/attachment 的处理逻辑（与 writer 解耦，方便直调测试）。

    返回 ``(status, error_payload, body, content_type)``：
    成功时 status=200、error_payload={}、body=附件字节；失败时 body=b""、
    error_payload 是标准错误 JSON。约束链：设备鉴权 → 消息在 30 分钟窗口 →
    群已订阅 → 附件存在 → 拉取（并发闸 + 短缓存）。
    """
    if method != "GET":
        return HTTPStatus.METHOD_NOT_ALLOWED, _err("bad_request", "attachment 只支持 GET"), b"", ""
    try:
        device_id = _auth(headers)
    except _AuthFail as exc:
        return HTTPStatus.UNAUTHORIZED, exc.payload, b"", ""
    msg_id = ((query.get("msg_id") or [""])[0] or "").strip()
    raw_index = ((query.get("index") or ["0"])[0] or "0").strip()
    if not msg_id:
        return BAD_REQUEST, _err("bad_request", "缺少 msg_id"), b"", ""
    try:
        index = int(raw_index)
    except ValueError:
        return BAD_REQUEST, _err("bad_request", "index 必须是整数"), b"", ""
    meta = relay.attachment_meta_for_device(device_id, msg_id, index)
    if meta is None:
        return (
            HTTPStatus.NOT_FOUND,
            _err("not_found", "消息不在 30 分钟窗口内、群未订阅，或附件不存在"),
            b"",
            "",
        )

    url = meta["url"]
    cached = _att_cache_get(url)
    if cached is not None:
        return HTTPStatus.OK, {}, cached[1], cached[0]
    async with _att_gate_get():
        # 排队期间可能有人刚拉好：再查一次缓存，同附件并发不重复打 QQ
        cached = _att_cache_get(url)
        if cached is not None:
            return HTTPStatus.OK, {}, cached[1], cached[0]
        try:
            ctype, blob = await _fetch_attachment_bytes(url)
        except Exception as exc:  # noqa: BLE001
            return (
                HTTPStatus.BAD_GATEWAY,
                _err("fetch_failed", f"附件拉取失败（QQ 直链未取证，真机联调关注）：{exc}"),
                b"",
                "",
            )
        _att_cache_put(url, ctype, blob)
    return HTTPStatus.OK, {}, blob, ctype


async def serve_attachment(
    writer: asyncio.StreamWriter, method: str, query: dict, headers: dict
) -> None:
    """/attachment 的响应封装：成功回原始字节，失败回标准错误 JSON。"""
    status, payload, blob, ctype = await resolve_attachment(method, query, headers)
    if status == HTTPStatus.OK:
        await serve_file(writer, status, blob, ctype or "application/octet-stream")
    else:
        await serve_json(writer, status, payload)


def _relay_key(path: str) -> str:
    """把外部路径 /api/relay/xxx 归一化成内部键 /xxx；不是中继接口返回空串。"""
    if path.startswith("/api/relay/"):
        inner = "/" + path[len("/api/relay/") :]
        return inner if inner in RELAY_PATHS else ""
    return ""


def _err(code: str, message: str) -> dict:
    return {"ok": False, "error": {"code": code, "message": message}}


def _ok(data) -> dict:
    return {"ok": True, "data": data}


class _AuthFail(Exception):
    def __init__(self, payload: dict):
        super().__init__("unauthorized")
        self.payload = payload


def _auth(headers: dict) -> str:
    """从请求头取设备身份，返回 device_id；失败抛 _AuthFail。"""
    device_id = (headers.get("x-device-id") or "").strip()
    token = (headers.get("x-device-token") or "").strip()
    if not device_id or not token:
        raise _AuthFail(_err("unauthorized", "缺少 X-Device-Id / X-Device-Token"))
    if not relay.STORE.auth(device_id, token):
        raise _AuthFail(_err("unauthorized", "设备令牌无效，请在 App 内重新注册设备"))
    return device_id


def _json_body(body: bytes) -> dict:
    if not body:
        return {}
    try:
        parsed = json.loads(body.decode("utf-8"))
        return parsed if isinstance(parsed, dict) else {}
    except (ValueError, UnicodeDecodeError):
        return {}


def _body_str(body: dict, key: str, default: str = "") -> str:
    value = body.get(key, default)
    return value if isinstance(value, str) else str(value)


def _body_bool(body: dict, key: str, default: bool = False) -> bool:
    value = body.get(key, default)
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.lower() in ("1", "true", "yes")
    return default


def _known_groups_sync() -> list[dict]:
    """机器人「所在的群」= bot.db 里出现过消息的群（带条数与最近时间）。"""
    if not DB_PATH.exists():
        return []
    conn = _connect()
    try:
        if "group_messages" not in _list_tables(conn):
            return []
        rows = conn.execute(
            "SELECT group_openid, COUNT(*) c, MAX(COALESCE(timestamp, created_at)) last_at "
            "FROM group_messages WHERE COALESCE(group_openid,'') <> '' "
            "GROUP BY group_openid ORDER BY c DESC"
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


def api_relay_groups(device_id: str) -> dict:
    """机器人「所在的群」列表——按请求设备做隔离。

    ``visible is None`` 表示运营者（放行全部）；否则只返回该账号被授权的群，
    未绑定账号拿到的是空集合，因此什么都看不到。
    """
    visible = relay.STORE.visible_groups(device_id)
    if visible is not None and not visible:
        return {"groups": []}
    known = _known_groups_sync()
    subscribed = relay.STORE.groups_of(device_id)
    groups = []
    for row in known:
        gid = row.get("group_openid") or ""
        if visible is not None and gid not in visible:
            continue
        name = relay.group_name(gid)
        groups.append(
            {
                "group_openid": gid,
                "label": relay.group_label(gid),
                "has_name": bool(name),
                "message_count": row.get("c", 0),
                "last_message_at": row.get("last_at"),
                "subscribed": gid in subscribed,
                "bot_present": True,  # bot.db 里有消息说明机器人进过这个群
            }
        )
    return {"groups": groups}


async def handle_relay_api(
    path: str,
    method: str,
    query: dict,
    headers: dict,
    body: bytes,
) -> tuple[int, dict]:
    """机器人通道的 HTTP 接口。

    契约见《机器人通道_开发指南.md》第 2 节。
    ``path`` 是**去掉 /api/relay 前缀**的内部键（如 ``/health``）。
    外部真实路径为 ``/api/relay/health`` 等。
    """
    payload = _json_body(body)

    # --- 不需要鉴权的两个接口 ---
    if path == "/health":
        # ocr 是「本机多模态模型可用」才有的能力（截图来源走后端 OCR）；
        # 模型不在时前端退回端侧 OCR（Core Vision Kit），互为降级路径。
        # attachment：附件过路。图片/文件都已在真机验证过（截图显示、docx 保存到手机），
        # 所以不再"不谎报"地藏着它。
        caps = ["candidates", "parse", "feedback", "attachment", "profile"]
        if llm_parse.available():
            caps.append("ocr")
        # push 只在**服务账号真的配好**时才声明（不谎报）
        if push_sender.configured():
            caps.append("push")
        return OK, _ok(
            {
                "ok": True,
                "version": "mvp0",
                # v2 能力协商：前端读 capabilities 决定走候选流还是退回 v1 本地规则。
                # 只声明**真的实现并验证过**的能力，不写没做的。
                "api_version": 2,
                "capabilities": caps,
                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "bot_running": bot.running,
                "window": relay.window_stats(),
            }
        )

    if path == "/device/register":
        data = relay.STORE.register_device(_body_str(payload, "name"))
        return OK, _ok(data)

    if path == "/internal/ingest":
        # 机器人进程内部推送：把群消息写入本进程（服务端）的中继窗口。
        # 不需要设备身份，但必须带正确的 X-Relay-Key，且只有本机机器人进程会调用。
        if not relay.check_internal_key(headers.get("x-relay-key") or ""):
            return HTTPStatus.FORBIDDEN, _err("forbidden", "内部通道密钥错误")
        gid = _body_str(payload, "group_openid").strip()
        if not gid:
            return BAD_REQUEST, _err("bad_request", "缺少 group_openid")
        info = relay.ingest_group_message(
            group_openid=gid,
            sender=_body_str(payload, "sender") or "未知用户",
            content=_body_str(payload, "content") or "",
            msg_id=_body_str(payload, "msg_id"),
            timestamp=_body_str(payload, "timestamp") or None,
            event_type=_body_str(payload, "event_type", "GROUP_MESSAGE_CREATE"),
            group_label=_body_str(payload, "group_label"),
            sender_openid=_body_str(payload, "sender_openid"),
            attachments=payload.get("attachments"),
        )
        return OK, _ok(info)

    if path.startswith("/admin/"):
        # 运营管理接口：把「某个 QQ 账号」授权到「某些群」，用于多用户隔离。
        # 只允许本机（命令行 / 运维脚本）调用，用内部通道密钥保护，不走设备身份。
        if not relay.check_internal_key(headers.get("x-relay-key") or ""):
            return HTTPStatus.FORBIDDEN, _err("forbidden", "管理接口密钥错误")
        if path == "/admin/bindings":
            return OK, _ok({"bindings": relay.STORE.bindings_overview()})
        if path == "/admin/grant":
            openid = _body_str(payload, "user_openid").strip()
            gid = _body_str(payload, "group_openid").strip()
            if not openid or not gid:
                return BAD_REQUEST, _err("bad_request", "缺少 user_openid / group_openid")
            return OK, _ok(relay.STORE.grant(openid, gid))
        if path == "/admin/revoke":
            openid = _body_str(payload, "user_openid").strip()
            gid = _body_str(payload, "group_openid").strip()
            if not openid or not gid:
                return BAD_REQUEST, _err("bad_request", "缺少 user_openid / group_openid")
            return OK, _ok(relay.STORE.revoke(openid, gid))
        return HTTPStatus.NOT_FOUND, _err("not_found", f"未知管理接口 {path}")

    # --- 以下全部需要设备身份 ---
    device_id = _auth(headers)

    if path == "/bind/code":
        return OK, _ok(relay.STORE.mint_bind_code(device_id))

    if path == "/bind/status":
        return OK, _ok(relay.STORE.bind_status(device_id))

    if path == "/groups":
        groups = await _run_db(lambda: api_relay_groups(device_id))
        # 顺手把还没查到名字的群问一次平台（有缓存，失败会自动回退成尾号）
        missing = [g["group_openid"] for g in groups["groups"] if not g["has_name"]]
        if missing:
            await _run_db(lambda: relay.resolve_group_names(missing))
            groups = await _run_db(lambda: api_relay_groups(device_id))
        return OK, _ok(groups)

    if path == "/feedback":
        # 契约 §2.3：用户对候选的动作回传（接受 / 忽略 / 改过哪些字段）。
        # 只记计数、不存内容；可选的 drop_words 把「用户手动删掉的词」同步给按群词表
        # （AGENTS.md §3.1：词表必须能手动删词）。
        if method != "POST":
            return BAD_REQUEST, _err("bad_request", "feedback 只支持 POST")
        action = _body_str(payload, "action").strip()
        if action not in ("accept", "dismiss"):
            return BAD_REQUEST, _err("bad_request", "action 必须是 accept 或 dismiss")
        cid = _body_str(payload, "candidate_id").strip()
        if not cid:
            return BAD_REQUEST, _err("bad_request", "缺少 candidate_id")
        gid = _body_str(payload, "group_openid").strip()
        kind = _body_str(payload, "kind").strip()
        relay.FEEDBACK.record(gid, kind, action)

        dropped: list[str] = []
        words = payload.get("drop_words")
        if isinstance(words, list) and gid:
            for w in words:
                if isinstance(w, str) and w and group_lexicon.STORE.drop(gid, w):
                    dropped.append(w)
        return OK, _ok({
            "recorded": True,
            "candidate_id": cid,
            "action": action,
            "edited_fields": payload.get("edited_fields") if isinstance(payload.get("edited_fields"), list) else [],
            "dropped_words": dropped,
        })

    if path == "/profile":
        # 用户画像词条归纳（**无状态**）：端侧把「用户自己发过的消息」统计成
        # 「词 + 次数 + 类别」的词频表发来，这里只归纳、只回值。
        # 隐私红线与 /parse 同级：**不落盘、不进 30 分钟窗口、不进候选流**
        # （test_profile_api.py 有专测）。素材里本来就没有聊天原话。
        if method != "POST":
            return BAD_REQUEST, _err("bad_request", "profile 只支持 POST")
        material = payload.get("material")
        if not isinstance(material, dict):
            return BAD_REQUEST, _err("bad_request", "缺少 material（词频表）")
        return OK, _ok(
            profile_summarize.summarize(material, payload.get("max_entries"))
        )

    if path == "/push/token":
        # 设备上报 Push Token（后台通知用）。
        # 只存 token，不存任何消息内容；空串表示注销。
        if method != "POST":
            return BAD_REQUEST, _err("bad_request", "push/token 只支持 POST")
        tk = _body_str(payload, "token").strip()
        ok = relay.STORE.set_push_token(device_id, tk)
        if not ok:
            return HTTPStatus.NOT_FOUND, _err("not_found", "设备不存在")
        return OK, _ok({"registered": bool(tk), "push_ready": push_sender.configured()})

    if path == "/subscribe":
        gid = _body_str(payload, "group_openid").strip()
        if not gid:
            return BAD_REQUEST, _err("bad_request", "缺少 group_openid")
        visible = relay.STORE.visible_groups(device_id)
        if visible is not None and gid not in visible:
            return HTTPStatus.FORBIDDEN, _err("forbidden", "该群未授权给你的账号")
        relay.STORE.subscribe(
            device_id,
            gid,
            keywords=_body_str(payload, "keywords"),
            min_priority=_body_str(payload, "min_priority", "all") or "all",
            mute=_body_bool(payload, "mute"),
        )
        return OK, _ok({"subscribed": True, "group_openid": gid})

    if path == "/unsubscribe":
        gid = _body_str(payload, "group_openid").strip()
        if not gid:
            return BAD_REQUEST, _err("bad_request", "缺少 group_openid")
        return OK, _ok(relay.STORE.unsubscribe(device_id, gid))

    if path == "/messages":
        try:
            after = int((query.get("after", ["0"])[0] or "0"))
            limit = int((query.get("limit", [str(relay.DEFAULT_LIMIT)])[0] or relay.DEFAULT_LIMIT))
        except ValueError:
            after, limit = 0, relay.DEFAULT_LIMIT
        return OK, _ok(relay.window_since(device_id, after, limit))

    if path == "/messages/update":
        # 契约 §2.6：用户改「待办」（消息级 parse）里的字段（kind / 摘要 / 时间 / 地点…）。
        # 只覆盖**下发值**、不改历史；覆盖表在内存里，随 30 分钟窗口一起失效（不落盘）。
        if method != "POST":
            return HTTPStatus.METHOD_NOT_ALLOWED, _err("method_not_allowed", "只支持 POST")
        msg_id = _body_str(payload, "msg_id").strip()
        if not msg_id:
            return BAD_REQUEST, _err("bad_request", "缺少 msg_id")
        item = relay.message_editable_for_device(device_id, msg_id)
        if item is None:
            return HTTPStatus.NOT_FOUND, _err(
                "not_found", "消息不在 30 分钟窗口内，或该群未订阅"
            )
        clean, err = relay.normalize_parse_edits(payload.get("fields"))
        if err:
            return BAD_REQUEST, _err("bad_request", err)
        overrides = dict(clean)
        if "timeText" in clean:
            # 时间原话改了就把归一化重算一遍（规则算，绝不信客户端）
            norm, unresolved = _normalize_time(clean["timeText"])
            overrides["timeNormalized"] = norm
            overrides["timeUnresolved"] = unresolved
        overrides["edited"] = sorted(clean.keys())
        relay.set_message_override(msg_id, overrides)
        effective = relay.apply_override(msg_id, item.get("parse") or {})
        return OK, _ok(
            {
                "msg_id": msg_id,
                "parse": effective,
                "edited_fields": sorted(clean.keys()),
            }
        )

    if path == "/parse":
        # 契约 §2.2：无状态文本抽取（手动添加任务，文本/截图/文件三来源）。
        # 隐私红线：**只处理、不存储** —— 内容不进窗口、不进候选流、不落盘；
        # 图片/文件只在本进程内解码用于本次抽取。
        if method != "POST":
            return BAD_REQUEST, _err("bad_request", "parse 只支持 POST")
        text = _body_str(payload, "text").strip()
        image_b64 = _body_str(payload, "image_b64").strip()
        file_b64 = _body_str(payload, "file_b64").strip()
        file_name = _body_str(payload, "file_name").strip()
        channel = _body_str(payload, "source", "manual").strip() or "manual"

        def _too_large(size: int, cap: int, what: str) -> tuple[int, dict] | None:
            if size > cap:
                return BAD_REQUEST, _err(
                    "bad_request", f"{what}过大（上限 {cap // (1024 * 1024)}MB），请压缩后重试"
                )
            return None

        parts: list[str] = []
        if text:
            parts.append(text[:MAX_PARSE_TEXT_CHARS])

        # ① 截图：后端多模态模型 OCR（capabilities 含 "ocr" 时前端才应传这个字段）
        if image_b64:
            if not llm_parse.available():
                return HTTPStatus.NOT_IMPLEMENTED, _err(
                    "not_supported",
                    "本机未运行多模态模型，无法识别图片；请改传 text，或在端侧完成 OCR 后把文字放进 text",
                )
            limited = _too_large(len(image_b64), MAX_PARSE_IMAGE_B64, "图片")
            if limited is not None:
                return limited
            ocr_text = await _run_db(lambda: llm_parse.ocr_image(image_b64))
            if not ocr_text:
                return BAD_REQUEST, _err(
                    "bad_request", "没识别出文字（模型不可用或图中无文字），请换一张或改用文本输入"
                )
            parts.append(ocr_text[:MAX_PARSE_TEXT_CHARS])

        # ② 文件：图片扩展名走 OCR；文本扩展名直接当正文；其余类型明确拒绝
        if file_b64:
            suffix = Path(file_name).suffix.lower()
            if suffix in _PARSE_TEXT_EXTS:
                limited = _too_large(len(file_b64), MAX_PARSE_FILE_B64, "文件")
                if limited is not None:
                    return limited
                try:
                    raw_file = base64.b64decode(file_b64)
                except Exception:  # noqa: BLE001
                    return BAD_REQUEST, _err("bad_request", "file_b64 不是合法的 base64")
                file_text = ""
                for enc in ("utf-8", "gbk"):
                    try:
                        file_text = raw_file.decode(enc)
                        break
                    except UnicodeDecodeError:
                        continue
                file_text = file_text.strip()
                if not file_text:
                    return BAD_REQUEST, _err("bad_request", "文件内容为空或不是 UTF-8/GBK 文本")
                parts.append(file_text[:MAX_PARSE_TEXT_CHARS])
            elif suffix in _PARSE_IMAGE_EXTS:
                if not llm_parse.available():
                    return HTTPStatus.NOT_IMPLEMENTED, _err(
                        "not_supported", "本机未运行多模态模型，无法识别图片文件；请改传 text"
                    )
                limited = _too_large(len(file_b64), MAX_PARSE_IMAGE_B64, "图片")
                if limited is not None:
                    return limited
                ocr_text = await _run_db(lambda: llm_parse.ocr_image(file_b64))
                if not ocr_text:
                    return BAD_REQUEST, _err(
                        "bad_request", "没识别出文字（模型不可用或图中无文字），请换一张或改用文本输入"
                    )
                parts.append(ocr_text[:MAX_PARSE_TEXT_CHARS])
            elif suffix in _PARSE_OFFICE_EXTS:
                # docx/xlsx/pptx（标准库 zip+XML）与 pdf（pypdf 软依赖）
                limited = _too_large(len(file_b64), MAX_PARSE_FILE_B64, "文件")
                if limited is not None:
                    return limited
                if suffix == ".pdf" and not office_extract.pdf_supported():
                    return HTTPStatus.NOT_IMPLEMENTED, _err(
                        "not_supported",
                        "服务端未安装 pypdf，无法解析 PDF；请转成图片/文字，或手动输入",
                    )
                try:
                    raw_file = base64.b64decode(file_b64)
                except Exception:  # noqa: BLE001
                    return BAD_REQUEST, _err("bad_request", "file_b64 不是合法的 base64")
                try:
                    file_text = await _run_db(
                        lambda: office_extract.extract_any(suffix, raw_file)
                    )
                except Exception:  # noqa: BLE001
                    return BAD_REQUEST, _err(
                        "bad_request",
                        f"文件解析失败（可能已损坏或不是真正的 {suffix} 文件）",
                    )
                file_text = (file_text or "").strip()
                if not file_text:
                    return BAD_REQUEST, _err(
                        "bad_request",
                        "没从文件里抽到文本（扫描版 PDF 或空文档）；"
                        "请截图后按图片上传，或手动输入",
                    )
                parts.append(file_text[:MAX_PARSE_TEXT_CHARS])
            else:
                return BAD_REQUEST, _err(
                    "bad_request",
                    "不支持的文件类型："
                    + (suffix or "（无扩展名）")
                    + "；支持图片（png/jpg/jpeg/webp/bmp）、文本（txt/md/csv/log/json）、"
                      "文档（docx/xlsx/pptx/pdf）",
                )

        if not parts:
            return BAD_REQUEST, _err(
                "bad_request", "缺少要解析的内容：text / image_b64 / file_b64 至少提供一个"
            )
        joined = "\n".join(parts)
        # 抽取放线程池：内部可能调本地模型（OCR 后的簇级抽取），不能阻塞事件循环
        candidate = await _run_db(
            lambda: candidate_engine.build_manual_candidate(joined, source=channel)
        )
        return OK, _ok({"candidate": candidate, "text": joined})

    if path == "/candidates":
        # v2 候选流：后端做「去重 + 聚类 + 综合总结」，App 按 candidate_id upsert。
        # 候选在全量窗口上统一算（rev_seq 全局单调），这里再按该设备订阅的群过滤。
        try:
            after = int((query.get("after", ["0"])[0] or "0"))
            limit = int((query.get("limit", ["100"])[0] or 100))
        except ValueError:
            after, limit = 0, 100
        limit = max(1, min(limit, 500))
        groups = relay.STORE.groups_of(device_id)
        if not groups:
            return OK, _ok(
                {
                    "candidates": [],
                    "cursor": after,
                    "server_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                    "window_minutes": relay.WINDOW_MINUTES,
                }
            )
        changed = await _run_db(lambda: CANDIDATE_STREAM.rebuild(relay.window_candidate_source()))
        data = CANDIDATE_STREAM.since(after, 500)
        visible = [c for c in data["candidates"] if c["source"]["group_openid"] in groups][:limit]
        cursor = visible[-1]["rev_seq"] if visible else after
        return OK, _ok(
            {
                "candidates": visible,
                "cursor": cursor,
                "server_time": data["server_time"],
                "window_minutes": data["window_minutes"],
                "changed": len(changed),
            }
        )

    if path == "/my/data":
        if method == "DELETE":
            groups = relay.STORE.groups_of(device_id)
            result = relay.STORE.forget_device(device_id)
            # 隐私：派生词表也一并处理——该群若已无别的设备订阅，连词表一起清
            cleared = 0
            for gid in groups:
                if not relay.STORE.subscribers_of(gid):
                    group_lexicon.STORE.forget(gid)
                    cleared += 1
            result["lexicon_groups_cleared"] = cleared
            return OK, _ok(result)
        return OK, _ok(relay.STORE.stats(device_id))

    if path == "/dev/ingest":
        # 联调用：伪造一条群消息进入中继窗口（需要 QQBOT_DEV_INGEST=1 + 有效设备身份）
        if not DEV_INGEST:
            return HTTPStatus.FORBIDDEN, _err(
                "dev_disabled", "测试注入未开启；启动服务时设 QQBOT_DEV_INGEST=1"
            )
        gid = _body_str(payload, "group_openid").strip()
        if not gid:
            return BAD_REQUEST, _err("bad_request", "缺少 group_openid")
        info = relay.ingest_group_message(
            group_openid=gid,
            sender=_body_str(payload, "sender") or "联调机器人",
            content=_body_str(payload, "content") or "这是一条联调测试消息",
            msg_id="dev_" + datetime.now().strftime("%H%M%S%f"),
            event_type="GROUP_MESSAGE_CREATE",
            group_label=_body_str(payload, "group_label"),
            attachments=payload.get("attachments"),
        )
        return OK, _ok(info)

    return HTTPStatus.NOT_FOUND, _err("not_found", f"未知接口 {path}")


async def handle_api(path: str, query: dict) -> tuple[int, dict]:
    try:
        if path == "/api/status":
            return HTTPStatus.OK, await api_status()
        if path == "/api/start":
            return HTTPStatus.OK, await api_start()
        if path == "/api/stop":
            return HTTPStatus.OK, await api_stop()
        if path == "/api/restart":
            return HTTPStatus.OK, await api_restart()
        if path == "/api/shutdown":
            # 先停机器人，再让控制台自己退出，避免留下孤儿进程
            asyncio.create_task(_graceful_shutdown("网页上点了「退出控制台」"))
            return HTTPStatus.OK, {"ok": True, "message": "控制台正在退出"}
        if path == "/api/heartbeat":
            watchdog.beat()
            return HTTPStatus.OK, {
                "ok": True,
                "enabled": watchdog.enabled,
                "timeout": watchdog.timeout,
            }
        if path == "/api/watchdog":
            # ?enabled=1 / ?enabled=0 / ?timeout=120
            raw = (query.get("enabled", [""])[0] or "").strip()
            if raw != "":
                watchdog.enabled = raw not in ("0", "false", "False", "no")
                if watchdog.enabled:
                    watchdog.beat()  # 开启时先记一次心跳，避免立刻触发
            raw_t = (query.get("timeout", [""])[0] or "").strip()
            if raw_t:
                try:
                    watchdog.timeout = max(20.0, min(float(raw_t), 1800.0))
                except ValueError:
                    pass
            await bot.logs.add(
                "[控制台] 网页关闭后自动停止：%s（超时 %d 秒）"
                % ("开启" if watchdog.enabled else "关闭", int(watchdog.timeout))
            )
            return HTTPStatus.OK, watchdog.status()
        if path == "/api/logs":
            return HTTPStatus.OK, await api_logs(query)
        if path == "/api/logs/clear":
            await bot.logs.clear()
            return HTTPStatus.OK, {"ok": True}
        if path == "/api/logs/download":
            return HTTPStatus.OK, {"path": str(LOG_FILE), "exists": LOG_FILE.exists()}
        if path == "/api/messages":
            return HTTPStatus.OK, await api_messages(query)
        if path == "/api/group_names":
            return HTTPStatus.OK, await api_group_names(query)
        if path == "/api/tables":
            return HTTPStatus.OK, await api_tables()
        if path == "/api/table":
            return HTTPStatus.OK, await api_table_rows(query)
        if path == "/api/db/open":
            return HTTPStatus.OK, await _run_db(_open_db_folder)
        return HTTPStatus.NOT_FOUND, {"error": f"未知接口 {path}"}
    except sqlite3.Error as exc:
        return HTTPStatus.INTERNAL_SERVER_ERROR, {"error": f"数据库错误: {exc}"}
    except Exception as exc:  # noqa: BLE001
        return HTTPStatus.INTERNAL_SERVER_ERROR, {"error": str(exc)}


async def _graceful_shutdown(reason: str = "收到退出指令") -> None:
    """给响应留出发送时间，然后停机器人并结束进程。"""
    await asyncio.sleep(0.6)
    await bot.shutdown()
    await bot.logs.add(f"[控制台] {reason}，控制台即将关闭")
    os._exit(0)


def _open_db_folder() -> dict:
    """在文件管理器里定位 bot.db（只定位，不自动打开，避免误操作）。"""
    return {"ok": True, "path": str(DB_PATH), "folder": str(DB_PATH.parent)}


# ---------------------------------------------------------------- 静态文件

MIME = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
}


def read_static(path: str) -> tuple[int, bytes, str]:
    rel = "index.html" if path in ("/", "") else path.lstrip("/")
    target = (WEB_DIR / rel).resolve()
    # 防止路径穿越
    if not str(target).startswith(str(WEB_DIR.resolve())) or not target.is_file():
        return HTTPStatus.NOT_FOUND, b"404 Not Found", "text/plain; charset=utf-8"
    return HTTPStatus.OK, target.read_bytes(), MIME.get(target.suffix, "application/octet-stream")


async def serve_file(writer: asyncio.StreamWriter, status: int, body: bytes, ctype: str) -> None:
    reason = HTTPStatus(status).phrase
    headers = (
        f"HTTP/1.1 {status} {reason}\r\n"
        f"Content-Type: {ctype}\r\n"
        f"Content-Length: {len(body)}\r\n"
        "Cache-Control: no-store\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "Access-Control-Allow-Headers: Content-Type, X-Device-Id, X-Device-Token, X-Relay-Key\r\n"
        "Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS\r\n"
        "Connection: close\r\n\r\n"
    )
    writer.write(headers.encode("utf-8") + body)
    await writer.drain()


async def serve_json(writer: asyncio.StreamWriter, status: int, payload: dict) -> None:
    body = json.dumps(payload, ensure_ascii=False, default=str).encode("utf-8")
    await serve_file(writer, status, body, "application/json; charset=utf-8")


def _console_authorized(headers: dict) -> bool:
    """控制台 HTTP Basic Auth 校验。

    未设置 QQBOT_CONSOLE_PASSWORD 时视为「不启用鉴权」（返回 True），
    这样纯本机使用不受影响；一旦设置，所有控制台路径都必须带正确的账号口令。
    """
    if not CONSOLE_PASSWORD:
        return True
    raw = (headers.get("authorization") or "").strip()
    if not raw.lower().startswith("basic "):
        return False
    try:
        decoded = base64.b64decode(raw[6:].strip()).decode("utf-8")
    except (ValueError, UnicodeDecodeError):
        return False
    user, _, pwd = decoded.partition(":")
    return hmac.compare_digest(user, CONSOLE_USER) and hmac.compare_digest(pwd, CONSOLE_PASSWORD)


async def serve_unauthorized(writer: asyncio.StreamWriter) -> None:
    """控制台需要登录时返回 401 + WWW-Authenticate，浏览器会弹原生登录框。"""
    body = b"401 Unauthorized - console login required"
    reason = HTTPStatus.UNAUTHORIZED.phrase
    headers = (
        f"HTTP/1.1 {HTTPStatus.UNAUTHORIZED} {reason}\r\n"
        "Content-Type: text/plain; charset=utf-8\r\n"
        f"Content-Length: {len(body)}\r\n"
        'WWW-Authenticate: Basic realm="cicad-console"\r\n'
        "Cache-Control: no-store\r\n"
        "Connection: close\r\n\r\n"
    )
    writer.write(headers.encode("utf-8") + body)
    await writer.drain()


async def handle_client(
    reader: asyncio.StreamReader, writer: asyncio.StreamWriter, public_only: bool = False
) -> None:
    try:
        request_line = await asyncio.wait_for(reader.readline(), timeout=10)
        if not request_line:
            return
        try:
            method, target, _ = request_line.decode("latin-1").split(" ", 2)
        except ValueError:
            await serve_file(writer, HTTPStatus.BAD_REQUEST, b"bad request", "text/plain")
            return
        method = method.upper()

        # 读完请求头（机器人通道需要用到请求头里的设备身份，以及 JSON 请求体）
        headers: dict[str, str] = {}
        while True:
            line = await asyncio.wait_for(reader.readline(), timeout=10)
            if line in (b"\r\n", b"\n", b""):
                break
            text = line.decode("latin-1", "replace")
            if ":" in text:
                key, _, value = text.partition(":")
                headers[key.strip().lower()] = value.strip()

        request_body = b""
        try:
            length = int(headers.get("content-length") or 0)
        except ValueError:
            length = 0
        if 0 < length <= MAX_BODY_BYTES:
            # 12MB：/parse 的截图走 base64（4/3 放大），1MB 不够一张截图
            request_body = await asyncio.wait_for(reader.readexactly(length), timeout=30)

        from urllib.parse import parse_qs, unquote, urlparse

        parsed = urlparse(target)
        path = unquote(parsed.path)
        query = parse_qs(parsed.query)

        if path.startswith("/api/"):
            relay_key = _relay_key(path)
            # 公开口不暴露联调注入口（它能把伪造消息写进中继窗口）
            if relay_key and not (public_only and relay_key == "/dev/ingest"):
                if relay_key == "/attachment":
                    # 附件过路：响应体是原始字节（不是 JSON），走单独的响应路
                    await serve_attachment(writer, method, query, headers)
                else:
                    try:
                        status, payload = await handle_relay_api(
                            relay_key, method, query, headers, request_body
                        )
                    except _AuthFail as exc:
                        status, payload = HTTPStatus.UNAUTHORIZED, exc.payload
                    except Exception as exc:  # noqa: BLE001
                        status, payload = (
                            HTTPStatus.INTERNAL_SERVER_ERROR,
                            _err("internal", str(exc)),
                        )
                    await serve_json(writer, status, payload)
            elif public_only:
                # 公开口只放行 /api/relay/*：控制台接口在这里一律「不存在」
                await serve_json(
                    writer, HTTPStatus.NOT_FOUND, _err("not_found", f"未知接口 {path}")
                )
            elif not _console_authorized(headers):
                await serve_unauthorized(writer)
            else:
                status, payload = await handle_api(path, query)
                await serve_json(writer, status, payload)
        elif public_only:
            # 公开口不提供网页 / 日志 / 数据库下载
            await serve_file(
                writer, HTTPStatus.NOT_FOUND, b"404 Not Found", "text/plain; charset=utf-8"
            )
        elif not _console_authorized(headers):
            await serve_unauthorized(writer)
        elif path == "/download/log":
            if LOG_FILE.exists():
                await serve_file(
                    writer,
                    HTTPStatus.OK,
                    LOG_FILE.read_bytes(),
                    "text/plain; charset=utf-8",
                )
            else:
                await serve_file(writer, HTTPStatus.NOT_FOUND, b"no log file", "text/plain")
        elif path == "/download/db":
            if DB_PATH.exists():
                await serve_file(
                    writer,
                    HTTPStatus.OK,
                    DB_PATH.read_bytes(),
                    "application/octet-stream",
                )
            else:
                await serve_file(writer, HTTPStatus.NOT_FOUND, b"no db file", "text/plain")
        else:
            status, body, ctype = read_static(path)
            await serve_file(writer, status, body, ctype)
    except (asyncio.TimeoutError, ConnectionResetError):
        pass
    except Exception:  # noqa: BLE001
        try:
            await serve_file(writer, HTTPStatus.INTERNAL_SERVER_ERROR, b"server error", "text/plain")
        except Exception:  # noqa: BLE001
            pass
    finally:
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:  # noqa: BLE001
            pass


# ---------------------------------------------------------------- 入口


async def main() -> None:
    if not WEB_DIR.exists():
        print(f"[错误] 找不到前端目录: {WEB_DIR}", file=sys.stderr)
        raise SystemExit(1)

    try:
        console_server = await asyncio.start_server(handle_client, HOST, PORT)
    except OSError as exc:
        if getattr(exc, "errno", None) in (48, 98, 10048):
            print("=" * 56)
            print(f"  端口 {PORT} 已被占用。")
            print("  控制台可能已经在运行了，直接打开下面这个地址即可：")
            print(f"    http://{HOST}:{PORT}")
            print("  如果确认没有在运行，请设置其他端口后重试，例如：")
            print("    set QQBOT_CONSOLE_PORT=8732")
            print("=" * 56)
            raise SystemExit(1) from None
        raise

    # 公开口：只放行 /api/relay/*，供内网穿透指向；控制台不在这个口上。
    public_server = None
    if PUBLIC_PORT and PUBLIC_PORT != PORT:
        try:
            public_server = await asyncio.start_server(
                functools.partial(handle_client, public_only=True), PUBLIC_HOST, PUBLIC_PORT
            )
        except OSError as exc:
            print(f"[警告] 公开口 {PUBLIC_HOST}:{PUBLIC_PORT} 启动失败：{exc}")

    console_url = f"http://{HOST}:{PORT}"

    print("=" * 56)
    print("  QQ 机器人控制台已启动")
    print(f"  控制台（本机）: {console_url}")
    if public_server is not None:
        print(f"  公开口（仅 /api/relay/*，穿透请指这里）: http://{PUBLIC_HOST}:{PUBLIC_PORT}")
    if not CONSOLE_PASSWORD:
        print("  ⚠ 未设置 QQBOT_CONSOLE_PASSWORD：控制台没有鉴权。")
        print("    请勿把控制台端口暴露到公网；穿透只应指向上面的公开口。")
    print("  按 Ctrl+C 退出（会自动停止机器人）")
    print("=" * 56)

    await bot.logs.add(f"[控制台] 控制台服务已就绪，监听 {console_url}")
    llm_worker.start()  # 启动后台解析线程（模型不可用时自动回退纯规则）
    watchdog.start()
    asyncio.create_task(lexicon_loop())  # 后台定期给每个群增量学领域词表
    asyncio.create_task(push_loop())     # 后台把新候选推到设备（Push Kit）

    if AUTOSTART_BOT:
        try:
            info = await bot.start()
            await bot.logs.add(
                "[控制台] 已按 QQBOT_AUTOSTART_BOT=1 自动启动机器人"
                + ("" if info.get("ok") else f"（{info.get('error')}）")
            )
        except Exception as exc:  # noqa: BLE001
            await bot.logs.add(f"[控制台] 自动启动机器人失败：{exc}", "stderr")

    servers = [console_server] if public_server is None else [console_server, public_server]
    try:
        await asyncio.gather(*(srv.serve_forever() for srv in servers))
    except asyncio.CancelledError:
        pass
    finally:
        for srv in servers:
            srv.close()
        await bot.shutdown()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n控制台已退出")
