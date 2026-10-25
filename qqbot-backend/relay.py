"""机器人消息中继：把群消息按「用户订阅」定向分发给 App。

设计要点（与《机器人通道_开发指南.md》第 1、2 节一致）：

* **正文不落盘**。群消息只存在于 ``WINDOW`` 这个内存滚动窗口里，默认保留
  ``WINDOW_MINUTES`` 分钟；进程重启即清空。这是合规设计的核心：
  服务端没有全量消息表，也没有历史检索。
* **只落盘路由信息**。设备、绑定、订阅、配对码写进 ``relay_store.json``
  （一个 JSON 文件，原子替换写入），内容里**没有任何聊天正文**。
* **按订阅过滤**。App 用 ``?after=seq`` 拉增量时，只返回「属于该设备订阅的群」
  的消息；没订阅的群，服务端连返回都不会返回。

被 ``server.py``（HTTP 接口）和 ``botpy_main.py``（机器人进程）共同 import。
两个进程通过 ``relay_store.json`` 共享订阅表：机器人侧每次判订阅前会看文件
修改时间，变了就重新读，所以 App 改订阅后机器人最多迟 1 秒生效。
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import secrets
import threading
import time
import uuid
from collections import deque
from datetime import datetime
from pathlib import Path

import llm_worker  # 后台小模型/规则解析（不在此处启动线程，由 server.py 调用 start()）

BASE_DIR = Path(__file__).resolve().parent

# 内存消息窗口：App 离线超过这个时间，中间的消息就永久丢失（合规代价）
WINDOW_MINUTES = 30
WINDOW_MAX = 5000
# 首次同步最多返回多少条，避免一次把窗口全推给客户端
DEFAULT_LIMIT = 200
# 列表/汇总用的正文截断长度：App 的「群汇总」用它渲染，不要把原文整段展开
CONTENT_PREVIEW_LEN = int(os.environ.get("QQBOT_PREVIEW_LEN", "60"))
MAX_LIMIT = 500
# 配对码有效期
BIND_CODE_TTL = 300

STORE_PATH = Path(os.environ.get("QQBOT_RELAY_STORE", BASE_DIR / "relay_store.json"))

# 机器人进程(botpy_main.py)和控制台服务(server.py)是两个独立进程，各自有独立的内存
# WINDOW。机器人侧收到的群消息必须推给服务端进程，App 才能从服务端进程的
# /api/relay/messages 拉到。下面这套常量就是这条「机器人 → 控制台」内部推送通道。
_KEY_FILE = BASE_DIR / ".relay_key"


def _resolve_internal_key() -> str:
    """机器人进程与控制台服务共用的「内部推送密钥」。

    优先级：环境变量 ``QQBOT_RELAY_KEY`` → 本机 ``.relay_key`` 文件 → 随机生成并落盘。
    刻意**不再提供硬编码默认值**：该密钥用于阻止外网伪造群消息注入中继窗口，
    取值必须不可猜，且两个进程（botpy_main.py / server.py）必须拿到同一个值。
    """
    env = (os.environ.get("QQBOT_RELAY_KEY") or "").strip()
    if env:
        return env
    try:
        saved = _KEY_FILE.read_text(encoding="utf-8").strip()
        if saved:
            return saved
    except OSError:
        pass
    generated = secrets.token_hex(16)
    try:
        _KEY_FILE.write_text(generated, encoding="utf-8")
    except OSError:
        pass
    return generated


INTERNAL_RELAY_KEY = _resolve_internal_key()
INTERNAL_RELAY_PORT = int(os.environ.get("QQBOT_CONSOLE_PORT", "8730"))
INTERNAL_RELAY_URL = f"http://127.0.0.1:{INTERNAL_RELAY_PORT}/api/relay/internal/ingest"


def check_internal_key(value: str) -> bool:
    """校验机器人进程内部推送用的密钥，防止外网伪造消息进入中继窗口。"""
    return bool(value) and value == INTERNAL_RELAY_KEY


_lock = threading.RLock()


# ------------------------------------------------------------------ 内存窗口


class _Window:
    """内存滚动窗口：群消息按 seq 递增保存，超过 TTL 自动淘汰。"""

    def __init__(self, minutes: int = WINDOW_MINUTES, max_items: int = WINDOW_MAX):
        self.minutes = minutes
        self.max_items = max_items
        self._items: deque[dict] = deque(maxlen=max_items)
        self._by_msg_id: dict[str, int] = {}
        self._seq = 0

    def add(self, msg_id: str, payload: dict) -> int | None:
        """返回新分配的 seq；重复 msg_id 返回 None（去重）。"""
        with _lock:
            self._prune()
            if msg_id and msg_id in self._by_msg_id:
                return None
            self._seq += 1
            item = dict(payload)
            item["seq"] = self._seq
            item["_at"] = time.time()
            self._items.append(item)
            if msg_id:
                self._by_msg_id[msg_id] = self._seq
            return self._seq

    def since(self, after_seq: int, groups: set[str], limit: int = DEFAULT_LIMIT) -> list[dict]:
        """取 seq > after_seq 且属于 ``groups`` 的消息。"""
        with _lock:
            self._prune()
            out = [
                it
                for it in self._items
                if it["seq"] > after_seq and it["group_openid"] in groups
            ]
        return out[:limit]

    def max_seq(self) -> int:
        with _lock:
            return self._seq

    def by_msg_id(self, msg_id: str) -> dict | None:
        """按 msg_id 取窗口内单条消息（副本）；不在窗口（含超时淘汰）返回 None。

        附件过路（server.py 的 /attachment）专用：消息本体在 30 分钟窗口里，
        这里只做查找，不改变淘汰策略。seq 单调递增，从尾部反向扫，
        最近消息（绝大多数场景）一次就命中。
        """
        if not msg_id:
            return None
        with _lock:
            self._prune()
            seq = self._by_msg_id.get(msg_id)
            if seq is None:
                return None
            for it in reversed(self._items):
                cur = it.get("seq", 0)
                if cur == seq:
                    return dict(it)
                if cur < seq:
                    break
        return None

    def all_items(self) -> list[dict]:
        """窗口内**全部**消息（不按订阅过滤）。给候选引擎用：先全局聚类，
        再由调用方按设备订阅的群过滤候选，避免多设备各算一套 rev_seq。"""
        with _lock:
            self._prune()
            return list(self._items)

    def size(self) -> int:
        with _lock:
            self._prune()
            return len(self._items)

    def _prune(self) -> None:
        deadline = time.time() - self.minutes * 60
        while self._items and self._items[0]["_at"] < deadline:
            old = self._items.popleft()
            self._by_msg_id.pop(old.get("msg_id", ""), None)
        # deque 有 maxlen 自动截断，这里补一次索引清理
        if len(self._by_msg_id) > len(self._items) * 2 + 64:
            alive = {it.get("msg_id") for it in self._items}
            self._by_msg_id = {k: v for k, v in self._by_msg_id.items() if k in alive}


WINDOW = _Window()


# ------------------------------------------------------------------ 落盘路由表


def _now() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _new_id(prefix: str) -> str:
    return prefix + uuid.uuid4().hex[:20]


# 运营者白名单：命中即可看到全部群（通常是作者本人的 QQ 账号）。
# 多个 openid 用逗号/分号/空格分隔，来自环境变量或 .env 的 QQBOT_OPERATOR_OPENID。
def _operator_openids() -> set[str]:
    raw = _env_value("QQBOT_OPERATOR_OPENID")
    return {p.strip() for p in re.split(r"[,;\s]+", raw) if p.strip()}


def is_operator(user_openid: str) -> bool:
    return bool(user_openid) and user_openid in _operator_openids()


class RelayStore:
    """设备 / 绑定 / 订阅 / 配对码的落盘存储（**不含任何消息正文**）。"""

    def __init__(self, path: Path = STORE_PATH):
        self.path = Path(path)
        self._data: dict = self._empty()
        self._mtime: float = -1.0
        self.reload(force=True)

    def ensure_dir(self) -> None:
        """确保存储目录存在（默认路径下目录一定存在，但允许用环境变量改到别处）。"""
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            print(f"[中继] 无法创建目录 {self.path.parent}：{exc}")

    @staticmethod
    def _empty() -> dict:
        return {
            "version": 1,
            "devices": {},      # device_id -> {token_hash, name, created_at, last_seen}
            "bindings": {},     # device_id -> {user_openid, bound_at, source}
            "subscriptions": {},  # device_id -> {group_openid: {keywords, min_priority, mute, created_at}}
            "bind_codes": {},   # code -> {device_id, created_at, used}
            "grants": {},       # user_openid -> {group_openid: {granted_at}}（按人授权可见的群）
            # 设备级 Push Token（只用于发通知，不含任何消息内容）。
            # 归到「匿名设备标识」一类：它无法反查用户身份，也不含正文。
            "push_tokens": {},  # device_id -> {token, updated_at}
            # 设备级偏好（只有开关，不含任何内容）。
            # skip_self 默认 **True**：不把绑定用户自己发的群消息放进窗口/候选/推送。
            "prefs": {},        # device_id -> {"skip_self": bool}
        }

    # -- 读写 --------------------------------------------------------
    def reload(self, force: bool = False) -> None:
        with _lock:
            try:
                mtime = self.path.stat().st_mtime
            except OSError:
                if force:
                    self._data = self._empty()
                    self._mtime = -1.0
                return
            if not force and mtime == self._mtime:
                return
            try:
                raw = json.loads(self.path.read_text(encoding="utf-8"))
                if isinstance(raw, dict):
                    data = self._empty()
                    for key in data:
                        if isinstance(raw.get(key), dict):
                            data[key] = raw[key]
                    self._data = data
                    self._mtime = mtime
            except (OSError, ValueError) as exc:
                # 文件损坏时不要清空别人的数据，只记日志并继续用内存里的旧副本
                print(f"[中继] 读取 {self.path.name} 失败：{exc}")

    def _flush(self) -> None:
        with _lock:
            self.ensure_dir()
            tmp = self.path.with_suffix(".tmp")
            tmp.write_text(
                json.dumps(self._data, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            for _ in range(5):
                try:
                    os.replace(tmp, self.path)
                    break
                except PermissionError:  # Windows 上偶发被占用
                    time.sleep(0.05)
            self._mtime = self.path.stat().st_mtime

    # -- 设备 --------------------------------------------------------
    def register_device(self, name: str = "") -> dict:
        with _lock:
            self.reload()
            device_id = _new_id("dev_")
            token = secrets.token_urlsafe(24)
            self._data["devices"][device_id] = {
                "token_hash": _hash_token(token),
                "name": (name or "")[:40],
                "created_at": _now(),
                "last_seen": _now(),
            }
            self._flush()
        return {"device_id": device_id, "token": token}

    def auth(self, device_id: str, token: str) -> bool:
        with _lock:
            self.reload()
            dev = self._data["devices"].get(device_id or "")
            if not dev:
                return False
            if dev.get("token_hash") != _hash_token(token or ""):
                return False
            dev["last_seen"] = _now()
            self._flush()
            return True

    # -- 绑定 --------------------------------------------------------
    def mint_bind_code(self, device_id: str) -> dict:
        code = "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))
        with _lock:
            self.reload()
            # 清掉过期码
            now = time.time()
            self._data["bind_codes"] = {
                k: v
                for k, v in self._data["bind_codes"].items()
                if now - float(v.get("created_at", 0)) < BIND_CODE_TTL
            }
            self._data["bind_codes"][code] = {
                "device_id": device_id,
                "created_at": now,
                "used": False,
            }
            self._flush()
        return {
            "code": code,
            "expires_in": BIND_CODE_TTL,
            "hint": f"在 QQ 里私聊机器人，发送：绑定 {code}",
        }

    def bind_status(self, device_id: str) -> dict:
        with _lock:
            self.reload()
            b = self._data["bindings"].get(device_id)
        if not b:
            return {"bound": False}
        openid = str(b.get("user_openid") or "")
        return {
            "bound": True,
            "user_openid_tail": ("…" + openid[-4:]) if openid else "",
            "bound_at": b.get("bound_at"),
            "bound_at_ms": b.get("bound_at_ms"),
            "source": b.get("source"),
        }

    def bind_by_code(self, code: str, user_openid: str, source: str = "pair_code") -> dict:
        """机器人侧调用：用户在 QQ 单聊里发了配对码。"""
        code = (code or "").strip().upper()
        with _lock:
            self.reload()
            entry = self._data["bind_codes"].get(code)
            if not entry:
                return {"ok": False, "reason": "invalid_code"}
            if entry.get("used"):
                return {"ok": False, "reason": "used_code"}
            if time.time() - float(entry.get("created_at", 0)) > BIND_CODE_TTL:
                return {"ok": False, "reason": "expired_code"}
            device_id = entry.get("device_id")
            if not device_id or device_id not in self._data["devices"]:
                return {"ok": False, "reason": "unknown_device"}
            entry["used"] = True
            old = self._data["bindings"].get(device_id) or {}
            old_openid = str(old.get("user_openid") or "")
            self._data["bindings"][device_id] = {
                "user_openid": user_openid,
                "bound_at": _now(),
                "bound_at_ms": int(time.time() * 1000),
                "source": source,
            }
            # 换绑（换 QQ 号）：把旧号已获得的群授权复制给新号，
            # 否则新号没有 grant，订阅管理页会变空（群列表按 openid 授权过滤）。
            migrated = self._migrate_grants(old_openid, user_openid)
            self._flush()
        out = {"ok": True, "device_id": device_id, "user_openid": user_openid}
        if migrated:
            out["migrated_grants"] = migrated
        return out

    def _migrate_grants(self, old_openid: str, new_openid: str) -> int:
        """把 ``old_openid`` 的群授权复制给 ``new_openid``（同名/空值不动）。返回新增条数。"""
        if not old_openid or not new_openid or old_openid == new_openid:
            return 0
        old_grants = self._data["grants"].get(old_openid) or {}
        if not old_grants:
            return 0
        new_grants = self._data["grants"].setdefault(new_openid, {})
        migrated = 0
        for gid in old_grants:
            if gid not in new_grants:
                new_grants[gid] = {"granted_at": _now(), "migrated_from": old_openid}
                migrated += 1
        return migrated

    def unbind(self, device_id: str) -> None:
        with _lock:
            self.reload()
            self._data["bindings"].pop(device_id, None)
            self._flush()

    def devices_of_openid(self, user_openid: str) -> list[str]:
        """反查：这个 QQ 账号绑定了哪些设备（单聊里发「状态/解绑」时用）。"""
        if not user_openid:
            return []
        with _lock:
            self.reload()
            return [
                device_id
                for device_id, b in self._data["bindings"].items()
                if b.get("user_openid") == user_openid
            ]

    def unbind_by_openid(self, user_openid: str) -> int:
        """单聊里发「解绑」：删除该 QQ 账号的所有绑定关系，返回删除条数。"""
        with _lock:
            self.reload()
            targets = [
                device_id
                for device_id, b in self._data["bindings"].items()
                if b.get("user_openid") == user_openid
            ]
            for device_id in targets:
                self._data["bindings"].pop(device_id, None)
            if targets:
                self._flush()
            return len(targets)

    def bound_openid(self, device_id: str) -> str:
        """该设备绑定的 QQ openid；未绑定返回空串。"""
        with _lock:
            self.reload()
            b = self._data["bindings"].get(device_id) or {}
        return str(b.get("user_openid") or "")

    # -- 订阅 --------------------------------------------------------
    def subscribe(
        self,
        device_id: str,
        group_openid: str,
        keywords: str = "",
        min_priority: str = "all",
        mute: bool = False,
    ) -> dict:
        with _lock:
            self.reload()
            subs = self._data["subscriptions"].setdefault(device_id, {})
            subs[group_openid] = {
                "keywords": (keywords or "")[:200],
                "min_priority": min_priority if min_priority in ("all", "notice") else "all",
                "mute": bool(mute),
                "created_at": _now(),
            }
            self._flush()
        return {"subscribed": True, "group_openid": group_openid}

    def unsubscribe(self, device_id: str, group_openid: str) -> dict:
        with _lock:
            self.reload()
            subs = self._data["subscriptions"].get(device_id) or {}
            subs.pop(group_openid, None)
            self._data["subscriptions"][device_id] = subs
            self._flush()
        return {"subscribed": False, "group_openid": group_openid}

    def groups_of(self, device_id: str) -> set[str]:
        with _lock:
            self.reload()
            return set((self._data["subscriptions"].get(device_id) or {}).keys())

    def subscribers_of(self, group_openid: str) -> list[str]:
        """机器人侧调用：哪些设备订阅了这个群（用于日志与统计）。"""
        with _lock:
            self.reload()
            out = []
            for device_id, subs in self._data["subscriptions"].items():
                if group_openid in subs:
                    out.append(device_id)
            return out

    def subscription_rules(self, device_id: str, group_openid: str) -> dict:
        with _lock:
            self.reload()
            return ((self._data["subscriptions"].get(device_id) or {}).get(group_openid)) or {}

    # -- 群授权（隔离） ----------------------------------------------
    # 「机器人所在的群」是全体订阅者共享的一份列表（来自 bot.db）。为了不让任何人
    # 一进来就看到别人的群，服务端按 user_openid 维护一份「可见群」白名单：
    # 未绑定的设备看不到任何群；绑定的设备只看得到被授权（或用运营者白名单放行）的群。
    def granted_groups(self, user_openid: str) -> set[str]:
        if not user_openid:
            return set()
        with _lock:
            self.reload()
            return set((self._data["grants"].get(user_openid) or {}).keys())

    def grant(self, user_openid: str, group_openid: str) -> dict:
        if not user_openid or not group_openid:
            return {"granted": False, "reason": "missing_args"}
        with _lock:
            self.reload()
            groups = self._data["grants"].setdefault(user_openid, {})
            groups[group_openid] = {"granted_at": _now()}
            self._flush()
        return {"granted": True, "user_openid": user_openid, "group_openid": group_openid}

    def revoke(self, user_openid: str, group_openid: str) -> dict:
        with _lock:
            self.reload()
            groups = self._data["grants"].get(user_openid) or {}
            groups.pop(group_openid, None)
            self._data["grants"][user_openid] = groups
            self._flush()
        return {"granted": False, "user_openid": user_openid, "group_openid": group_openid}

    def visible_groups(self, device_id: str) -> set[str] | None:
        """该设备可见的群集合；``None`` 表示不设限（运营者）。

        * 未绑定 → 空集合（什么都看不到）
        * 运营者 → None（全部可见）
        * 其它   → 该 openid 被授权的群
        """
        openid = self.bound_openid(device_id)
        if not openid:
            return set()
        if is_operator(openid):
            return None
        return self.granted_groups(openid)

    def bindings_overview(self) -> list[dict]:
        """给运营者的总览：每台绑定设备对应的 QQ 账号、已授权与已订阅的群。"""
        with _lock:
            self.reload()
            out = []
            for device_id, b in self._data["bindings"].items():
                openid = str(b.get("user_openid") or "")
                dev = self._data["devices"].get(device_id) or {}
                out.append(
                    {
                        "device_id": device_id,
                        "name": dev.get("name") or "",
                        "user_openid": openid,
                        "user_openid_tail": ("…" + openid[-4:]) if openid else "",
                        "bound_at": b.get("bound_at"),
            "bound_at_ms": b.get("bound_at_ms"),
                        "subscriptions": sorted(
                            (self._data["subscriptions"].get(device_id) or {}).keys()
                        ),
                        "granted": sorted((self._data["grants"].get(openid) or {}).keys()),
                    }
                )
            return out

    def stats(self, device_id: str) -> dict:
        with _lock:
            self.reload()
            return {
                "device_count": 1 if device_id in self._data["devices"] else 0,
                "bindings": 1 if device_id in self._data["bindings"] else 0,
                "subscriptions": len(self._data["subscriptions"].get(device_id) or {}),
                "queue_items": WINDOW.size(),
                "skip_self": self.skip_self_of(device_id),
            }

    # -- 设备偏好 ----------------------------------------------------

    def set_skip_self(self, device_id: str, skip: bool) -> bool:
        """设置「不订阅自己发的消息」。默认 True。"""
        with _lock:
            self.reload()
            if not device_id or device_id not in self._data["devices"]:
                return False
            self._data.setdefault("prefs", {})[device_id] = {"skip_self": bool(skip)}
            self._flush()
            return True

    def skip_self_of(self, device_id: str) -> bool:
        """该设备的 skip_self（默认 **True**：不把自己发的消息当候选）。"""
        with _lock:
            self.reload()
            item = (self._data.get("prefs") or {}).get(device_id or "") or {}
            return bool(item.get("skip_self", True))

    def should_skip_self_message(self, sender_openid: str) -> bool:
        """这条消息是不是「某个开着 skip_self 的绑定用户」自己发的。

        入窗时就丢掉（而不是事后过滤）：候选流是全群共享的一份，
        事后再按设备过滤会让不同设备的 `rev_seq` 对不上。
        """
        if not sender_openid:
            return False
        with _lock:
            self.reload()
            prefs = self._data.get("prefs") or {}
            for device_id, binding in self._data["bindings"].items():
                if str(binding.get("user_openid") or "") != sender_openid:
                    continue
                if bool((prefs.get(device_id) or {}).get("skip_self", True)):
                    return True
        return False

    # -- 推送令牌 ----------------------------------------------------
    # 只存「设备 -> Push Token」，用于后台发通知；不含任何消息内容。

    def set_push_token(self, device_id: str, token: str) -> bool:
        """登记/更新设备的 Push Token（空串 = 注销）。"""
        with _lock:
            self.reload()
            if not device_id or device_id not in self._data["devices"]:
                return False
            tk = (token or "").strip()
            if not tk:
                self._data["push_tokens"].pop(device_id, None)
            else:
                self._data["push_tokens"][device_id] = {
                    "token": tk[:512],
                    "updated_at": _now(),
                }
            self._flush()
            return True

    def push_token_of(self, device_id: str) -> str:
        with _lock:
            self.reload()
            item = self._data["push_tokens"].get(device_id or "") or {}
            return str(item.get("token") or "")

    def push_tokens_of_group(self, group_openid: str) -> list[str]:
        """订阅了该群的所有设备的 Push Token（去重）。"""
        with _lock:
            self.reload()
            out: list[str] = []
            for device_id, subs in self._data["subscriptions"].items():
                if group_openid not in subs:
                    continue
                item = self._data["push_tokens"].get(device_id) or {}
                tk = str(item.get("token") or "")
                if tk and tk not in out:
                    out.append(tk)
            return out

    def push_targets_of_group(self, group_openid: str) -> list[tuple[str, str]]:
        """订阅了该群的设备 `(device_id, token)` 列表。

        与 `push_tokens_of_group` 的区别：这里带上 device_id，推送侧才能按
        「设备 + 候选」做冷却去重（防止同一事项反复弹通知）。
        """
        with _lock:
            self.reload()
            out: list[tuple[str, str]] = []
            seen: set[str] = set()
            for device_id, subs in self._data["subscriptions"].items():
                if group_openid not in subs:
                    continue
                item = self._data["push_tokens"].get(device_id) or {}
                tk = str(item.get("token") or "")
                if tk and tk not in seen:
                    seen.add(tk)
                    out.append((device_id, tk))
            return out

    def forget_device(self, device_id: str) -> dict:
        """一键删除该设备在服务端的全部数据。"""
        with _lock:
            self.reload()
            binding = self._data["bindings"].pop(device_id, None) or {}
            openid = str(binding.get("user_openid") or "")
            self._data["devices"].pop(device_id, None)
            self._data["subscriptions"].pop(device_id, None)
            self._data["push_tokens"].pop(device_id, None)
            (self._data.get("prefs") or {}).pop(device_id, None)
            self._data["bind_codes"] = {
                k: v
                for k, v in self._data["bind_codes"].items()
                if v.get("device_id") != device_id
            }
            # 该 openid 已无任何绑定设备时，连带清掉它的群授权，避免残留隐私数据
            if openid and not self.devices_of_openid(openid):
                self._data["grants"].pop(openid, None)
            self._flush()
        return {"deleted": True}


STORE = RelayStore()


# ------------------------------------------------------------------ 规则过滤


def _match_rules(payload: dict, rules: dict) -> bool:
    """按订阅规则判断这条消息是否该发给该设备。"""
    if not rules:
        return False
    keywords = str(rules.get("keywords") or "").strip()
    if keywords:
        words = [w.strip() for w in re.split(r"[,，\s]+", keywords) if w.strip()]
        content = str(payload.get("content") or "")
        if words and not any(w in content for w in words):
            return False
    if rules.get("min_priority") == "notice":
        content = str(payload.get("content") or "")
        if not re.search(
            r"通知|提醒|截止|报名|作业|考试|会议|答辩|提交|DDL|deadline|时间|地点",
            content,
            re.I,
        ):
            return False
    return True


# ------------------------------------------------------------------ 机器人侧入口


def _normalize_ts(raw) -> str:
    """把平台给的时间统一成 ``YYYY-MM-DD HH:MM:SS``。"""
    if not raw:
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    text = str(raw)
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})[T ](\d{2}:\d{2}:\d{2})", text)
    if m:
        return f"{m.group(1)}-{m.group(2)}-{m.group(3)} {m.group(4)}"
    return text[:19]


def ingest_group_message(
    group_openid: str,
    sender: str,
    content: str,
    msg_id: str = "",
    timestamp=None,
    event_type: str = "GROUP_MESSAGE_CREATE",
    group_label: str = "",
    sender_openid: str = "",
    attachments=None,
    mentions=None,
) -> dict:
    """机器人收到群消息时调用：写入内存窗口（不做任何落盘）。

    返回 ``{"seq": n, "subscribers": k}``；``seq`` 为 None 表示重复消息。
    """
    if not group_openid:
        return {"seq": None, "subscribers": 0, "reason": "no_group"}

    payload = {
        "group_openid": group_openid,
        # 群名优先用调用方给的；没有就查本地缓存（查不到不阻塞，前端会回退显示尾号）
        "group_label": group_label or (group_name(group_openid) or f"群 …{group_openid[-6:]}"),
        "sender": sender or "未知用户",
        "sender_openid": sender_openid or "",
        "content": content or "",
        "timestamp": _normalize_ts(timestamp),
        "msg_id": msg_id or "",
        "event_type": event_type,
        "attachments": list(attachments) if isinstance(attachments, (list, tuple)) else [],
        "mentions": list(mentions) if isinstance(mentions, (list, tuple)) else [],
    }
    subscribers = len(STORE.subscribers_of(group_openid))

    # 「不订阅自己发的消息」（设备默认开）：在**入窗之前**就丢掉。
    # 候选流是全群共享的一份，事后再按设备过滤会让不同设备的 rev_seq 对不上。
    if sender_openid and STORE.should_skip_self_message(sender_openid):
        return {"seq": None, "subscribers": subscribers, "reason": "self_skipped"}

    # 解析放到后台线程，避免拖慢机器人推送（推送侧 HTTP 超时只有 3 秒）。
    # worker 解析完再把消息放进窗口，这样 App 拉到的**第一条就带 parse**，
    # 不需要 App 侧做「二次更新」。worker 未启动时退回原来的同步路径。
    if llm_worker.enabled():
        llm_worker.submit(payload)
        return {"seq": 0, "subscribers": subscribers, "queued": True}

    seq = WINDOW.add(msg_id, payload)
    return {"seq": seq, "subscribers": subscribers}


def parse_bind_command(text: str) -> str:
    """从单聊文本里解析配对码：支持「绑定 7K3M9Q」「/bind 7K3M9Q」「7K3M9Q」。"""
    if not text:
        return ""
    m = re.search(r"(?:绑定|bind|/bind)\s*[:：]?\s*([A-Za-z0-9]{6})", text)
    if m:
        return m.group(1).upper()
    m = re.fullmatch(r"\s*([A-Za-z0-9]{6})\s*", text)
    return m.group(1).upper() if m else ""


# ------------------------------------------------------------------ App 侧查询


def window_since(device_id: str, after_seq: int, limit: int = DEFAULT_LIMIT) -> dict:
    """App 拉增量：只返回该设备**订阅过的群**的消息。"""
    groups = STORE.groups_of(device_id)
    limit = max(1, min(int(limit or DEFAULT_LIMIT), MAX_LIMIT))
    if not groups:
        return {
            "messages": [],
            "max_seq": WINDOW.max_seq(),
            "server_time": _now(),
            "window_minutes": WINDOW.minutes,
            "subscribed_groups": 0,
        }

    # 本设备绑定用户的 openid：用于标记「这条是不是你本人发的」，
    # 供 App 选择性隐藏自己的消息。同一账号在群消息(member_openid)与单聊(user_openid)
    # 下取值一致，可直接比较。
    self_openid = STORE.bound_openid(device_id)

    items = WINDOW.since(int(after_seq or 0), groups, limit=MAX_LIMIT)
    out = []
    for it in items:
        rules = STORE.subscription_rules(device_id, it["group_openid"])
        if not _match_rules(it, rules):
            continue
        out.append(
            {
                "seq": it["seq"],
                "group_openid": it["group_openid"],
                "group_label": it.get("group_label") or "",
                "sender": it.get("sender") or "",
                "content": it.get("content") or "",
                # 列表/汇总用的**截断正文**：App 的「群汇总」不要整段展开原文，
                # 用它渲染即可；需要全文时再单独取 content（控制台「完整正文」用）。
                "content_short": _short(it.get("content") or ""),
                "attachments": it.get("attachments") or [],
                "timestamp": it.get("timestamp") or "",
                "msg_id": it.get("msg_id") or "",
                "event_type": it.get("event_type") or "",
                "is_self": bool(self_openid) and (it.get("sender_openid") or "") == self_openid,
                # 后端解析结果（小模型优先、失败回退规则）；engine 标明来源，App 可据此决定是否再用端侧规则。
                # 用户改过的字段在这里**覆盖**上去（契约 §2.6：改的是下发值，不改历史）。
                "parse": apply_override(it.get("msg_id") or "", it.get("parse")),
            }
        )
        if len(out) >= limit:
            break
    return {
        "messages": out,
        "max_seq": WINDOW.max_seq(),
        "server_time": _now(),
        "window_minutes": WINDOW.minutes,
        "subscribed_groups": len(groups),
    }


def _short(text: str, limit: int = CONTENT_PREVIEW_LEN) -> str:
    """把正文截成列表用的短文本（超出加 …）。全角按 1 字算，够用。"""
    s = (text or "").replace("\n", " ").strip()
    return s if len(s) <= limit else s[:limit] + "…"


def attachment_meta_for_device(device_id: str, msg_id: str, index: int) -> dict | None:
    """附件过路（契约 §2.5）：按 msg_id 查第 index 个附件的**元数据**。

    与 ``window_since`` 同一套约束：
    * 消息必须在 30 分钟窗口内（过期即 404，找不回）；
    * 设备必须订阅了消息所在群（没订阅的群连元数据都不给）；
    * 只返回 url / content_type / filename / size——**字节不经过这里**，
      由 server.py 拉 QQ 并转发，全程内存、不落盘。
    """
    item = WINDOW.by_msg_id(msg_id)
    if item is None:
        return None
    if item.get("group_openid") not in STORE.groups_of(device_id):
        return None
    atts = item.get("attachments")
    if not isinstance(atts, list) or index < 0 or index >= len(atts):
        return None
    att = atts[index]
    if not isinstance(att, dict):
        return None
    url = str(att.get("url") or "").strip()
    if not url:
        return None
    try:
        size = int(att.get("size") or 0)
    except (TypeError, ValueError):
        size = 0
    return {
        "url": url,
        "content_type": str(att.get("content_type") or "") or "application/octet-stream",
        "filename": str(att.get("filename") or ""),
        "size": size,
    }


# ---------------- 用户对「待办」（消息级 parse）的人工修改（契约 §2.6） ----------------
#
# 用户改过的字段按 msg_id 存在**内存**里：消息过了 30 分钟窗口就没了，覆盖跟着失效——
# 所以它不会变成一份"用户数据落盘"，跟窗口本身同一套合规姿势。
# 只接受白名单字段；engine / confidence / timeNormalized 这些**派生**字段由程序算，
# 不允许用户直接写（时间改了由 server.py 调规则重算 timeNormalized）。
EDITABLE_PARSE_FIELDS = (
    "kind", "title", "summary", "action",
    "timeText", "place", "who", "deadline", "items", "tags",
)
_EDIT_TEXT_FIELDS = ("kind", "title", "summary", "action", "timeText", "place", "who", "deadline")
_EDIT_LIST_FIELDS = ("items", "tags")
_EDIT_TEXT_MAX = 200
_EDIT_LIST_MAX = 20
_EDIT_ITEM_MAX = 60

_MESSAGE_OVERRIDES: dict[str, dict] = {}


def normalize_parse_edits(fields) -> tuple[dict, str]:
    """校验并归一化用户提交的修改；返回 ``(干净字段, 错误信息)``（成功时错误为空串）。"""
    if not isinstance(fields, dict) or not fields:
        return {}, "fields 必须是非空对象"
    clean: dict = {}
    for key, value in fields.items():
        if key not in EDITABLE_PARSE_FIELDS:
            return {}, f"字段 {key} 不允许修改（可改：{'、'.join(EDITABLE_PARSE_FIELDS)}）"
        if key in _EDIT_TEXT_FIELDS:
            if not isinstance(value, str):
                return {}, f"{key} 必须是字符串"
            text = value.strip()
            if len(text) > _EDIT_TEXT_MAX:
                return {}, f"{key} 太长（上限 {_EDIT_TEXT_MAX} 字）"
            clean[key] = text
        elif key in _EDIT_LIST_FIELDS:
            if not isinstance(value, (list, tuple)):
                return {}, f"{key} 必须是字符串数组"
            items: list[str] = []
            for one in value:
                if not isinstance(one, str):
                    return {}, f"{key} 里只能放字符串"
                s = one.strip()
                if s:
                    items.append(s[:_EDIT_ITEM_MAX])
            if len(items) > _EDIT_LIST_MAX:
                return {}, f"{key} 条数太多（上限 {_EDIT_LIST_MAX}）"
            clean[key] = items
    return clean, ""


def message_editable_for_device(device_id: str, msg_id: str) -> dict | None:
    """这条消息这台设备能不能改：窗口内 + 已订阅该群（与 /attachment 同一套约束）。"""
    item = WINDOW.by_msg_id(msg_id)
    if item is None:
        return None
    if item.get("group_openid") not in STORE.groups_of(device_id):
        return None
    return item


def set_message_override(msg_id: str, fields: dict) -> dict:
    """写入/合并某条消息的人工修改，返回合并后的覆盖表。"""
    cur = dict(_MESSAGE_OVERRIDES.get(msg_id) or {})
    edited = set(cur.get("edited") or [])
    edited.update(fields.get("edited") or [])
    cur.update(fields)
    cur["edited"] = sorted(edited)
    _MESSAGE_OVERRIDES[msg_id] = cur
    return cur


def apply_override(msg_id: str, parse):
    """把人工修改合并到一条消息的 parse 上（没改过就原样返回）。"""
    ov = _MESSAGE_OVERRIDES.get(msg_id)
    if not ov:
        return parse
    merged = dict(parse or {})
    merged.update(ov)
    return merged


def message_override(msg_id: str) -> dict:
    """取某条消息的人工修改（测试/调试用）。"""
    return dict(_MESSAGE_OVERRIDES.get(msg_id) or {})


def clear_message_override(msg_id: str) -> None:
    """丢掉某条消息的人工修改（测试用；窗口淘汰时一并清理）。"""
    _MESSAGE_OVERRIDES.pop(msg_id, None)


class FeedbackStore:
    """候选反馈计数（契约 §2.3）：只统计 accept / dismiss 次数。

    **只存计数，不存任何正文/候选内容**——所以它是纯内存态、重启即清，
    不触碰「正文不落盘」的红线（AGENTS.md §3.1：不允许新增落盘数据）。
    计数用于两处轻量调节：
      * `/feedback` 之后，候选的 `priority` 会按该群该类型的 dismiss 率微调；
      * 推送时跳过「几乎总被忽略」的类型，减少打扰。
    另外提供 `drop_words` 通道：把用户手动删掉的词转给按群词表（AGENTS.md §3.1 要求）。
    """

    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._data: dict[str, dict[str, dict[str, int]]] = {}

    def record(self, group_openid: str, kind: str, action: str) -> None:
        with self._lock:
            g = self._data.setdefault(group_openid or "_", {})
            k = g.setdefault(kind or "_", {"accept": 0, "dismiss": 0})
            k[action] = int(k.get(action, 0)) + 1

    def dismiss_rate(self, group_openid: str, kind: str, min_sample: int = 10) -> float | None:
        """该群该类型的 dismiss 占比；样本不足返回 None（不做任何调整）。"""
        with self._lock:
            k = (self._data.get(group_openid or "_") or {}).get(kind or "_") or {}
            acc = int(k.get("accept", 0))
            dis = int(k.get("dismiss", 0))
        total = acc + dis
        if total < min_sample:
            return None
        return dis / total

    def stats(self) -> dict:
        with self._lock:
            total = {"accept": 0, "dismiss": 0}
            for g in self._data.values():
                for k in g.values():
                    total["accept"] += int(k.get("accept", 0))
                    total["dismiss"] += int(k.get("dismiss", 0))
            return {"groups": len(self._data), "totals": total}

    def forget(self, group_openid: str) -> None:
        with self._lock:
            self._data.pop(group_openid or "_", None)


FEEDBACK = FeedbackStore()





def window_candidate_source() -> list[dict]:
    """候选引擎的输入：窗口内全量消息（不做订阅过滤，由调用方按群过滤候选）。"""
    return WINDOW.all_items()


def window_stats() -> dict:
    return {
        "window_items": WINDOW.size(),
        "window_minutes": WINDOW.minutes,
        "max_seq": WINDOW.max_seq(),
    }


# ------------------------------------------------------------------ 群名解析
# 数据库里只有 group_openid（平台从不下发群名），而 App 的订阅页要显示人能看懂的名字。
# 这里按需向平台查 `GET /v2/groups/{openid}/info`（需要白名单权限），
# 结果缓存在内存 + 落盘到 group_names.json，两个进程（机器人 / 控制台服务）共享同一份。
#
# 查不到时**不报错**，一律回退成「群 …<openid尾号>」，不影响任何主流程。

_NAMES_PATH = Path(os.environ.get("QQBOT_GROUP_NAMES", BASE_DIR / "group_names.json"))
_names_lock = threading.RLock()
_names_cache: dict[str, str | None] = {}
_names_loaded_at = 0.0
_token_cache: dict = {"value": "", "expire_at": 0.0}
NAME_RETRY_SECONDS = 600  # 查询失败后多久允许重试同一个群


def _load_names(force: bool = False) -> None:
    global _names_loaded_at
    with _names_lock:
        try:
            mtime = _NAMES_PATH.stat().st_mtime
        except OSError:
            return
        if not force and mtime <= _names_loaded_at:
            return
        try:
            raw = json.loads(_NAMES_PATH.read_text(encoding="utf-8"))
            if isinstance(raw, dict):
                _names_cache.update(
                    {k: v for k, v in raw.items() if isinstance(v, (str, type(None)))}
                )
            _names_loaded_at = mtime
        except (OSError, ValueError) as exc:
            print(f"[群名] 读取 {_NAMES_PATH.name} 失败：{exc}")


def _save_names() -> None:
    with _names_lock:
        try:
            _NAMES_PATH.parent.mkdir(parents=True, exist_ok=True)
            _NAMES_PATH.write_text(
                json.dumps(_names_cache, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            _names_loaded_at = _NAMES_PATH.stat().st_mtime
        except OSError as exc:
            print(f"[群名] 写入 {_NAMES_PATH.name} 失败：{exc}")


def _env_value(name: str) -> str:
    """优先读环境变量，其次读同目录 .env（机器人进程可能没加载它）。"""
    value = (os.environ.get(name) or "").strip()
    if value:
        return value
    try:
        for raw in (BASE_DIR / ".env").read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            if key.strip() == name:
                return val.strip().strip("'\"")
    except OSError:
        pass
    return ""


def _access_token() -> str:
    now = time.time()
    token = str(_token_cache.get("value") or "")
    if token and now < float(_token_cache.get("expire_at") or 0):
        return token
    app_id = _env_value("QQBOT_APP_ID")
    secret = _env_value("QQBOT_SECRET") or _env_value("QQBOT_APP_SECRET")
    if not app_id or not secret:
        raise RuntimeError("没找到 QQBOT_APP_ID / QQBOT_SECRET")

    from urllib.request import Request, urlopen

    payload = json.dumps({"appId": app_id, "clientSecret": secret}).encode("utf-8")
    req = Request(
        "https://bots.qq.com/app/getAppAccessToken",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    token = str(data.get("access_token") or "")
    if not token:
        raise RuntimeError(f"平台没有返回 access_token：{data}")
    _token_cache["value"] = token
    _token_cache["expire_at"] = now + max(float(data.get("expires_in") or 7200) - 300, 60)
    return token


def _fetch_name(group_openid: str, token: str) -> str | None:
    """查单个群名；失败只打日志并返回 None（调用方会回退显示尾号）。"""
    from urllib.error import HTTPError
    from urllib.parse import quote
    from urllib.request import Request, urlopen

    url = f"https://api.bot.qq.com/v2/groups/{quote(group_openid, safe='')}/info"
    req = Request(
        url,
        headers={
            "Authorization": f"QQBot {token}",
            "X-Union-Appid": _env_value("QQBOT_APP_ID"),
            "Accept": "application/json",
        },
        method="GET",
    )
    try:
        with urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        name = str(data.get("group_name") or "").strip()
        if not name:
            print(f"[群名] {group_openid}: 返回里没有 group_name -> {data}")
        return name or None
    except HTTPError as exc:
        print(f"[群名] {group_openid}: HTTP {exc.code}")
        return None
    except Exception as exc:  # noqa: BLE001
        print(f"[群名] {group_openid}: 请求失败 {type(exc).__name__}: {exc}")
        return None


def group_name(group_openid: str) -> str | None:
    """取缓存的群名（不发起网络请求，供消息入库时用）。"""
    if not group_openid:
        return None
    _load_names()
    with _names_lock:
        return _names_cache.get(group_openid)


def group_label(group_openid: str) -> str:
    """给人看的展示名：有群名用群名，没有就用「群 + openid 尾号」。"""
    if not group_openid:
        return "未知群"
    name = group_name(group_openid)
    if name:
        return name
    tail = group_openid[-6:] if len(group_openid) > 6 else group_openid
    return f"群 …{tail}"


def resolve_group_names(ids: list[str], refresh: bool = False) -> dict:
    """按需向平台查询群名（失败/无权限则返回 None，由调用方回退）。"""
    _load_names(force=True)
    names: dict[str, str | None] = {}
    todo: list[str] = []
    now = time.time()
    with _names_lock:
        for gid in ids:
            if not gid:
                continue
            if not refresh and gid in _names_cache:
                names[gid] = _names_cache[gid]
            else:
                # 失败过的群 10 分钟内不重复查，避免每次刷新都打平台
                if _names_cache.get(gid + "__failed_at", 0) and not refresh:
                    if now - float(_names_cache.get(gid + "__failed_at") or 0) < NAME_RETRY_SECONDS:
                        names[gid] = _names_cache.get(gid)
                        continue
                todo.append(gid)

    if not todo:
        return {"names": names, "queried": 0, "error": None}

    error = None
    try:
        token = _access_token()
    except Exception as exc:  # noqa: BLE001
        error = f"取访问凭证失败：{exc}"
        for gid in todo:
            names[gid] = _names_cache.get(gid)
        return {"names": names, "queried": 0, "error": error}

    queried = 0
    for gid in todo[:50]:
        queried += 1
        name = _fetch_name(gid, token)
        with _names_lock:
            _names_cache[gid] = name
            if name:
                _names_cache.pop(gid + "__failed_at", None)
            else:
                _names_cache[gid + "__failed_at"] = time.time()
                if error is None:
                    error = "平台没返回群名（可能是机器人无权限或未在群内），先显示 openid 尾号"
        names[gid] = name
    _save_names()
    return {"names": names, "queried": queried, "error": error}

