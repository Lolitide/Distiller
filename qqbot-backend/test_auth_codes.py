# -*- coding: utf-8 -*-
"""回归：设备鉴权失败必须返回可区分的 unauthorized 错误码。

运行：.venv\\Scripts\\python.exe -X utf8 test_auth_codes.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store_auth.json"
_tmp.parent.mkdir(parents=True, exist_ok=True)
if _tmp.exists():
    _tmp.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_tmp)

import relay  # noqa: E402
import server  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


def expect_auth_fail(headers: dict) -> dict:
    try:
        server._auth(headers)
    except server._AuthFail as e:
        return e.payload
    return {}


payload = expect_auth_fail({})
check("缺头 -> unauthorized", (payload.get("error") or {}).get("code") == "unauthorized", str(payload))
check("缺头有可读文案", len(str((payload.get("error") or {}).get("message", ""))) > 0, str(payload))

dev = relay.STORE.register_device("auth-test")
payload = expect_auth_fail({"x-device-id": dev["device_id"], "x-device-token": "wrong"})
check("错 token -> unauthorized", (payload.get("error") or {}).get("code") == "unauthorized", str(payload))

got = server._auth({"x-device-id": dev["device_id"], "x-device-token": dev["token"]})
check("正确身份 -> 返回 device_id", got == dev["device_id"], got)

print()
if FAILS:
    print("FAILED:", FAILS)
    raise SystemExit(1)
print("ALL PASS")
