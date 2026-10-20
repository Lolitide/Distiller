# -*- coding: utf-8 -*-
"""集成自测：POST /api/relay/messages/update（用户改「待办」= 消息级 parse）。

运行：.venv\\Scripts\\python.exe -X utf8 test_message_update_api.py
不依赖 QQ、不依赖 Ollama：parse 直接构造后放进窗口，验证「改哪些字段、怎么校验、改完生效」。
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 沙箱内临时存储，别污染真实 relay_store.json
_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store_msgupdate.json"
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
GID_OTHER = "AAA451ACFDB0816E3233D1947DEAC821"

dev = relay.STORE.register_device("msg-update-api")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
relay.STORE.subscribe(DEVICE, GID)

BASE_PARSE = {
    "engine": "llm",
    "kind": "待办",
    "category": "教务",
    "title": "交作业",
    "action": "交实验报告",
    "summary": "周五前交实验报告。",
    "items": ["报告"],
    "sourceText": "周五前交实验报告",
    "timeText": "周五前",
    "timeNormalized": "",
    "timeUnresolved": False,
    "place": "",
    "who": "",
    "deadline": "",
    "confidence": 0.8,
    "tags": [],
}


def ingest(msg_id: str, gid: str, content: str, parse: dict | None) -> int | None:
    payload = {
        "group_openid": gid,
        "group_label": "测试群",
        "sender": "张三",
        "sender_openid": "u1",
        "content": content,
        "timestamp": "2026-10-15 19:00:00",
        "msg_id": msg_id,
        "event_type": "GROUP_MESSAGE_CREATE",
        "attachments": [],
        "mentions": [],
    }
    if parse is not None:
        payload["parse"] = dict(parse)
    return relay.WINDOW.add(msg_id, payload)


def post(body, headers: dict | None = None) -> tuple[int, dict]:
    try:
        return asyncio.run(
            server.handle_relay_api(
                "/messages/update",
                "POST",
                {},
                HEADERS if headers is None else headers,
                json.dumps(body).encode("utf-8"),
            )
        )
    except server._AuthFail as exc:
        # 真实分发路径也是这么转的（server.handle_client 里 except _AuthFail）
        return 401, exc.payload


def messages() -> list[dict]:
    status, payload = asyncio.run(server.handle_relay_api("/messages", "GET", {}, HEADERS, b""))
    assert status == 200, (status, payload)
    return payload["data"]["messages"]


def msg_by_id(mid: str) -> dict | None:
    for m in messages():
        if m["msg_id"] == mid:
            return m
    return None


print("=" * 78)
print("一、鉴权与参数校验")
print("=" * 78)

M1 = "msg_update_1"
ingest(M1, GID, "周五前交实验报告", BASE_PARSE)

status, payload = post({"msg_id": M1, "fields": {"kind": "通知"}},
                       {"x-device-id": "", "x-device-token": ""})
check("无鉴权 -> 401", status == 401, f"{status} {str(payload)[:80]}")

status, payload = asyncio.run(
    server.handle_relay_api("/messages/update", "GET", {}, HEADERS, b""))
check("非 POST -> 405", status == 405, str(status))

status, payload = post({"fields": {"kind": "通知"}})
check("缺 msg_id -> 400", status == 400 and payload.get("error", {}).get("code") == "bad_request",
      f"{status} {str(payload)[:80]}")

status, payload = post({"msg_id": M1})
check("缺 fields -> 400", status == 400, f"{status} {str(payload)[:80]}")

status, payload = post({"msg_id": M1, "fields": {}})
check("fields 为空 -> 400", status == 400, f"{status} {str(payload)[:80]}")

status, payload = post({"msg_id": M1, "fields": {"engine": "rules"}})
check("改派生字段（engine）-> 400 且提示可改字段",
      status == 400 and "engine" in str(payload), f"{status} {str(payload)[:100]}")

status, payload = post({"msg_id": M1, "fields": {"kind": 123}})
check("kind 非字符串 -> 400", status == 400, f"{status} {str(payload)[:80]}")

status, payload = post({"msg_id": M1, "fields": {"items": "报告"}})
check("items 非数组 -> 400", status == 400, f"{status} {str(payload)[:80]}")

print()
print("=" * 78)
print("二、窗口与订阅约束（与 /attachment 同一套）")
print("=" * 78)

status, payload = post({"msg_id": "not_in_window", "fields": {"kind": "通知"}})
check("消息不在窗口 -> 404", status == 404, f"{status} {str(payload)[:80]}")

M2 = "msg_update_other_group"
ingest(M2, GID_OTHER, "别的群的消息", BASE_PARSE)
status, payload = post({"msg_id": M2, "fields": {"kind": "通知"}})
check("群未订阅 -> 404（不给改）", status == 404, f"{status} {str(payload)[:80]}")

print()
print("=" * 78)
print("三、成功路径：改 kind / 摘要，并在 /messages 里生效")
print("=" * 78)

status, payload = post({"msg_id": M1, "fields": {"kind": "通知", "summary": "我来改的摘要"}})
data = payload.get("data") or {}
p = data.get("parse") or {}
check("改 kind+summary -> 200", status == 200, f"{status} {str(payload)[:80]}")
check("返回的 parse 已生效",
      p.get("kind") == "通知" and p.get("summary") == "我来改的摘要", str(p)[:120])
check("edited_fields 记录改了哪些", data.get("edited_fields") == ["kind", "summary"],
      str(data.get("edited_fields")))
check("派生字段没被动（engine 还在）", p.get("engine") == "llm", str(p.get("engine")))

m = msg_by_id(M1)
check("/messages 下发值也被覆盖",
      m is not None and m["parse"]["kind"] == "通知" and m["parse"]["summary"] == "我来改的摘要",
      str(m["parse"])[:120] if m else "None")

status, payload = post({"msg_id": M1, "fields": {"place": "主楼A103"}})
m = msg_by_id(M1)
check("二次修改是合并（kind 没被覆盖掉）",
      m is not None and m["parse"]["kind"] == "通知" and m["parse"]["place"] == "主楼A103",
      str(m["parse"])[:140] if m else "None")
check("edited 累积（kind/place/summary）",
      m is not None and (m["parse"].get("edited") or []) == ["kind", "place", "summary"],
      str(m["parse"].get("edited")) if m else "None")

status, payload = post({"msg_id": M1, "fields": {"tags": ["教务", "实验"]}})
m = msg_by_id(M1)
check("列表字段可改", m is not None and m["parse"]["tags"] == ["教务", "实验"],
      str(m["parse"].get("tags")) if m else "None")

M4 = "msg_update_untouched"
ingest(M4, GID, "周五前交实验报告", BASE_PARSE)
m = msg_by_id(M4)
check("没改过的消息 parse 原样（不误伤别的消息）",
      m is not None and m["parse"]["kind"] == "待办" and not m["parse"].get("edited"),
      str((m or {}).get("parse", {}).get("kind")))

print()
print("=" * 78)
print("四、时间：改 timeText 由**规则**重算归一化（不信客户端）")
print("=" * 78)

M3 = "msg_update_time"
ingest(M3, GID, "周五前交实验报告", BASE_PARSE)

status, payload = post({"msg_id": M3, "fields": {"timeText": "明天下午两点"}})
p = ((payload.get("data") or {}).get("parse") or {})
check("改 timeText -> 200", status == 200, f"{status} {str(payload)[:80]}")
check("timeNormalized 被重算成具体时刻",
      ":" in str(p.get("timeNormalized")) and p.get("timeUnresolved") is False,
      str(p.get("timeNormalized")))
check("timeText 保留用户原话", p.get("timeText") == "明天下午两点", str(p.get("timeText")))

status, payload = post({"msg_id": M3, "fields": {"timeText": "回头再说"}})
p = ((payload.get("data") or {}).get("parse") or {})
check("认不出的时间 -> normalized 留空、不猜",
      p.get("timeNormalized") == "" and p.get("timeUnresolved") is False,
      f"norm={p.get('timeNormalized')!r} unres={p.get('timeUnresolved')}")

print()
print("=" * 78)
print("五、路由注册与「不落盘」")
print("=" * 78)

check("/messages/update 已注册中继路由", "/messages/update" in server.RELAY_PATHS, None)
check("可改字段白名单里有 kind/summary/timeText/place",
      all(k in relay.EDITABLE_PARSE_FIELDS for k in ("kind", "summary", "timeText", "place")),
      str(relay.EDITABLE_PARSE_FIELDS))

store_text = _tmp.read_text(encoding="utf-8") if _tmp.exists() else ""
check("覆盖表没写进 relay_store.json（只在内存）",
      "我来改的摘要" not in store_text and M1 not in store_text, store_text[:60])

relay.STORE.forget_device(DEVICE)
print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
