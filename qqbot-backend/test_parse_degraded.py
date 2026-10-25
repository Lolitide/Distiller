# -*- coding: utf-8 -*-
"""回归：/parse 的降级标记（engine=rules 时 degraded=true）。

运行：.venv\\Scripts\\python.exe -X utf8 test_parse_degraded.py
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store_degraded.json"
_tmp.parent.mkdir(parents=True, exist_ok=True)
if _tmp.exists():
    _tmp.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_tmp)

import llm_parse  # noqa: E402

llm_parse.available = lambda: False  # 强制规则路径
import candidate_engine  # noqa: E402

candidate_engine._llm_thread = lambda cluster, base: None  # 不碰本机模型

import server  # noqa: E402
import relay  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


async def main() -> None:
    dev = relay.STORE.register_device("parse-degraded")
    headers = {"x-device-id": dev["device_id"], "x-device-token": dev["token"]}
    body = json.dumps({"text": "明天下午三点交社会实践材料", "source": "manual_text"}).encode()
    status, payload = await server.handle_relay_api("/parse", "POST", {}, headers, body)
    check("HTTP 200", status == 200, str(status))
    data = payload.get("data") or {}
    cand = data.get("candidate") or {}
    check("候选存在", bool(cand), str(data)[:120])
    check("engine=rules", cand.get("engine") == "rules", str(cand.get("engine")))
    check("candidate.degraded=true", cand.get("degraded") is True, str(cand.get("degraded")))
    check("顶层 degraded=true", data.get("degraded") is True, str(data.get("degraded")))


asyncio.run(main())
print()
if FAILS:
    print("FAILED:", FAILS)
    raise SystemExit(1)
print("ALL PASS")
