# -*- coding: utf-8 -*-
"""集成自测：GET /api/relay/attachment（附件过路：窗口内按 msg_id+index 转发，不落盘）。

运行：.venv\\Scripts\\python.exe -X utf8 test_attachment_api.py
不依赖 QQ：解析/缓存/鉴权用打桩验证；拉取层（_fetch_attachment_bytes）
用本地 aiohttp 桩服务器走真网络路径（真 QQ 直链属未取证项，另行真机联调）。
"""

from __future__ import annotations

import asyncio
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 沙箱内临时存储，别污染真实 relay_store.json
_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store_attachment.json"
_tmp.parent.mkdir(parents=True, exist_ok=True)
if _tmp.exists():
    _tmp.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_tmp)

import llm_parse  # noqa: E402

llm_parse.available = lambda: False  # 强制规则路径，避免依赖本机模型

import relay  # noqa: E402
import server  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


GID = "15B451ACFDB0816E3233D1947DEAC820"
GID_OTHER = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"  # 故意不订阅的群

dev = relay.STORE.register_device("attachment-api")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
relay.STORE.subscribe(DEVICE, GID)  # 只订阅 GID；GID_OTHER 不订阅


def ingest(msg_id: str, gid: str, attachments: list) -> dict:
    return relay.ingest_group_message(
        group_openid=gid,
        sender="张三",
        content="看图",
        msg_id=msg_id,
        attachments=attachments,
    )


ATT_A = {"url": "https://example.com/a.png", "content_type": "image/png",
         "filename": "a.png", "size": 100}
ATT_B = {"url": "https://example.com/b.jpg", "content_type": "image/jpeg",
         "filename": "b.jpg", "size": 200}
ATT_C = {"url": "https://example.com/c.gif", "content_type": "image/gif",
         "filename": "c.gif", "size": 300}
ATT_D = {"url": "https://example.com/d.png", "content_type": "image/png",
         "filename": "d.png", "size": 400}

ingest("m_one", GID, [ATT_A])
ingest("m_two", GID, [ATT_B, ATT_C])
ingest("m_other_group", GID_OTHER, [ATT_D])
ingest("m_no_att", GID, [])


def resolve(query: dict, headers: dict | None = None, method: str = "GET"):
    """直调处理逻辑（不经过 writer），返回 (status, error_payload, body, ctype)。

    headers 传空 dict 表示「不带鉴权」——注意不能写 `headers or HEADERS`，
    空 dict 是 falsy 会被真凭据顶掉。
    """
    return asyncio.run(
        server.resolve_attachment(method, query, HEADERS if headers is None else headers)
    )


FETCH_CALLS: list[str] = []

# 真拉取函数留一份：三、四节打桩，五节恢复后走真 aiohttp 路径
_REAL_FETCH = server._fetch_attachment_bytes


async def _fake_fetch(url: str):
    FETCH_CALLS.append(url)
    return ("image/png", b"\x89PNG\r\n\x1a\nFAKE:" + url.encode("utf-8"))


async def _boom_fetch(url: str):
    raise RuntimeError("connection refused")


# ---------------------------------------------------------------- 一、鉴权与参数
print("=" * 78)
print("一、鉴权与参数校验")
print("=" * 78)

status, payload, body, _ = resolve({"msg_id": ["m_one"]}, headers={})
check("无鉴权 -> 401", status == 401 and payload["error"]["code"] == "unauthorized",
      str((status, payload)))

status, payload, body, _ = resolve({"msg_id": ["m_one"]}, method="POST")
check("非 GET -> 405", status == 405, str(status))

status, payload, body, _ = resolve({})
check("缺 msg_id -> 400", status == 400 and payload["error"]["code"] == "bad_request",
      str((status, payload)))

status, payload, body, _ = resolve({"msg_id": ["m_one"], "index": ["x"]})
check("index 非整数 -> 400", status == 400, str(status))

# ---------------------------------------------------------------- 二、窗口/订阅/附件
print()
print("二、窗口与订阅约束（与 /messages 同一套纪律）")
print("=" * 78)

status, payload, body, _ = resolve({"msg_id": ["m_ghost"]})
check("消息不在窗口 -> 404", status == 404 and payload["error"]["code"] == "not_found",
      str((status, payload)))

status, payload, body, _ = resolve({"msg_id": ["m_other_group"]})
check("群未订阅 -> 404（不给元数据）", status == 404, str(status))

status, payload, body, _ = resolve({"msg_id": ["m_no_att"], "index": ["0"]})
check("消息无附件 -> 404", status == 404, str(status))

status, payload, body, _ = resolve({"msg_id": ["m_one"], "index": ["9"]})
check("index 越界 -> 404", status == 404, str(status))

# ---------------------------------------------------------------- 三、成功路径 + 短缓存
print()
print("三、成功路径 + 90 秒短缓存（同附件只打一次桩/QQ）")
print("=" * 78)

server._att_cache.clear()
server._att_cache_bytes = 0
FETCH_CALLS.clear()
server._fetch_attachment_bytes = _fake_fetch  # 打桩拉取层

status, payload, body, ctype = resolve({"msg_id": ["m_one"], "index": ["0"]})
check("成功 -> 200", status == 200 and payload == {}, str((status, payload)))
check("返回字节与 content_type",
      body == b"\x89PNG\r\n\x1a\nFAKE:https://example.com/a.png" and ctype == "image/png",
      str((ctype, body if isinstance(body, bytes) else b"")[:60]))
check("拉取次数 = 1", len(FETCH_CALLS) == 1, str(FETCH_CALLS))

resolve({"msg_id": ["m_one"], "index": ["0"]})
check("同附件二次请求命中缓存", len(FETCH_CALLS) == 1, str(FETCH_CALLS))

status, payload, body, ctype = resolve({"msg_id": ["m_two"], "index": ["1"]})
check("多附件按 index 取（第二个）",
      status == 200 and body == b"\x89PNG\r\n\x1a\nFAKE:https://example.com/c.gif",
      str((status, body if isinstance(body, bytes) else b"")[:60]))

# 手动把缓存时间戳改成过去，模拟 90 秒过期
url_a = ATT_A["url"]
server._att_cache[url_a] = (time.monotonic() - 9999.0, "image/png", b"old")
before = len(FETCH_CALLS)
status, payload, body, _ = resolve({"msg_id": ["m_one"], "index": ["0"]})
check("缓存过期后重新拉取", len(FETCH_CALLS) == before + 1 and status == 200,
      str((len(FETCH_CALLS), status)))

# 上限逐出：塞 20 个小条目，条数不应超过 16
for i in range(20):
    server._att_cache_put(f"https://example.com/e{i}.png", "image/png", b"x")
check("缓存条数上限逐出", len(server._att_cache) <= server.ATTACHMENT_CACHE_MAX_ITEMS,
      str(len(server._att_cache)))
check("缓存字节账目非负", server._att_cache_bytes >= 0, str(server._att_cache_bytes))

# ---------------------------------------------------------------- 四、拉取失败降级
print()
print("四、拉取失败降级（QQ 直链未取证：统一 502，闸不卡死）")
print("=" * 78)

server._fetch_attachment_bytes = _boom_fetch
status, payload, body, _ = resolve({"msg_id": ["m_two"], "index": ["0"]})
check("拉取失败 -> 502 fetch_failed",
      status == 502 and payload["error"]["code"] == "fetch_failed",
      str((status, payload)))

server._fetch_attachment_bytes = _fake_fetch
status, payload, body, _ = resolve({"msg_id": ["m_two"], "index": ["0"]})
check("失败后恢复（闸不卡死）", status == 200, str(status))

# ---------------------------------------------------------------- 五、真 aiohttp 拉取路径
print()
print("五、_fetch_attachment_bytes 真 aiohttp 路径（本地桩服务器）")
print("=" * 78)


async def _real_fetch_tests() -> None:
    from aiohttp import web

    async def handler(request: web.Request) -> web.StreamResponse:
        tail = request.match_info["tail"]
        if tail == "ok.png":
            return web.Response(body=b"\x89PNG-REAL", content_type="image/png")
        if tail == "big-declared.png":
            # Content-Length 直接声明超过 12MB：客户端应拒绝读
            return web.Response(
                body=b"a" * (server.ATTACHMENT_MAX_BYTES + 1),
                content_type="image/png",
            )
        if tail == "big-stream.png":
            # 分块编码（无 Content-Length），流里超过 12MB：客户端应中途截断
            resp = web.StreamResponse(status=200)
            await resp.prepare(request)
            chunk = b"a" * (64 * 1024)
            written = 0
            try:
                while written <= server.ATTACHMENT_MAX_BYTES:
                    await resp.write(chunk)
                    written += len(chunk)
                await resp.write_eof()
            except (ConnectionResetError, ConnectionError):
                pass  # 客户端断开是预期行为（它已在中途截断）
            return resp
        raise web.HTTPNotFound()

    app = web.Application()
    app.router.add_get("/{tail:.*}", handler)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "127.0.0.1", 0)
    await site.start()
    port = runner.addresses[0][1]
    base = f"http://127.0.0.1:{port}"

    try:
        ctype, blob = await _REAL_FETCH(f"{base}/ok.png")
        check("真拉取：正常返回", blob == b"\x89PNG-REAL" and ctype == "image/png",
              str((ctype, blob)))

        try:
            await _REAL_FETCH(f"{base}/404.png")
            check("真拉取：非 200 抛错", False, "没有抛异常")
        except RuntimeError as exc:
            check("真拉取：非 200 抛错", "HTTP 404" in str(exc), str(exc))

        try:
            await _REAL_FETCH(f"{base}/big-declared.png")
            check("真拉取：声明超 12MB 拒绝转发", False, "没有抛异常")
        except RuntimeError as exc:
            check("真拉取：声明超 12MB 拒绝转发", "拒绝转发" in str(exc), str(exc))

        try:
            await _REAL_FETCH(f"{base}/big-stream.png")
            check("真拉取：流式超 12MB 中途截断", False, "没有抛异常")
        except RuntimeError as exc:
            check("真拉取：流式超 12MB 中途截断", "中途截断" in str(exc), str(exc))
    finally:
        await runner.cleanup()


asyncio.run(_real_fetch_tests())

# ---------------------------------------------------------------- 六、路由注册与能力位
print()
print("六、路由注册与能力位（真机验证后才声明）")
print("=" * 78)

check("/attachment 已注册中继路由", "/attachment" in server.RELAY_PATHS,
      str(sorted(server.RELAY_PATHS)))

status, health = asyncio.run(server.handle_relay_api("/health", "GET", {}, {}, b""))
caps = (health.get("data") or {}).get("capabilities") or []
check("attachment 能力位已声明（真机已验图片/文件）", "attachment" in caps, str(caps))

relay.STORE.forget_device(DEVICE)

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
