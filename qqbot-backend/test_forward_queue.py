# -*- coding: utf-8 -*-
"""「转发给机器人」内存队列回归：绑定设备 -> 入队 -> 一次性取走 -> 过期丢弃。"""
from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

_TMP = Path(__file__).resolve().parent / "_tmp_test"
_TMP.mkdir(parents=True, exist_ok=True)
_store = _TMP / "relay_store_forward.json"
if _store.exists():
    _store.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_store)

import relay  # noqa: E402
import server  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


dev = relay.STORE.register_device("forward-test")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
minted = relay.STORE.mint_bind_code(DEVICE)
bound = relay.STORE.bind_by_code(minted["code"], "user-forward-1")
check("设备绑定成功", bound.get("ok") is True, bound)

count = relay.enqueue_forward("user-forward-1", "明天下午三点在文治书院开会")
check("入队到 1 台设备", count == 1, count)

items = relay.take_forwards(DEVICE)
check("取到 1 条", len(items) == 1, items)
check("正文保持", items and items[0]["text"] == "明天下午三点在文治书院开会")
check("二次取走为空", relay.take_forwards(DEVICE) == [])

# 过期：直接改队列里那条的时间，再取应为空
relay.enqueue_forward("user-forward-1", "旧消息")
with relay._FORWARD_LOCK:
    for x in relay._FORWARDS.get(DEVICE, []):
        x["created_at"] = time.time() - relay._FORWARD_TTL - 1
check("超过 30 分钟丢弃", relay.take_forwards(DEVICE) == [])

# HTTP 端点：没转发时应返回空数组
status, payload = asyncio.run(
    server.handle_relay_api("/forward/pending", "GET", {}, HEADERS, b"")
)
check("GET /forward/pending 200", status == 200, status)
check("返回 items=[]", payload.get("data", {}).get("items") == [], payload)

print("=" * 60)
if FAILS:
    print("失败项：", "；".join(FAILS))
    sys.exit(1)
print("ALL PASS")
