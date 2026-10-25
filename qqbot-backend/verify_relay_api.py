# -*- coding: utf-8 -*-
"""跑一遍中继接口的「人工可读」自检（后端需先启动）。

用法（在 qqbot-backend 下）：
    .venv\\Scripts\\python.exe -X utf8 verify_relay_api.py
    .venv\\Scripts\\python.exe -X utf8 verify_relay_api.py --base http://127.0.0.1:8730

它只注册一个临时设备、调用公开中继接口；不会读群消息、不会写业务数据到磁盘。
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request

FAILS: list[str] = []


def call(base: str, path: str, method: str = "GET", body: dict | None = None,
         headers: dict | None = None) -> tuple[int, dict]:
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(base + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8")
        try:
            return exc.code, json.loads(raw) if raw else {}
        except ValueError:
            return exc.code, {"raw": raw}


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://127.0.0.1:8730/api/relay")
    args = ap.parse_args()
    base = args.base.rstrip("/")

    print("=" * 70)
    print("1. 注册临时设备 / 健康检查")
    status, reg = call(base, "/device/register", "POST", {"name": "verify-cli"})
    check("注册 200", status == 200, status)
    data = reg.get("data") or {}
    device_id = str(data.get("device_id") or "")
    token = str(data.get("token") or "")
    check("拿到 device_id/token", bool(device_id and token))
    headers = {"x-device-id": device_id, "x-device-token": token}

    status, health = call(base, "/health")
    caps = (health.get("data") or {}).get("capabilities") or []
    check("health 200", status == 200, status)
    check("capabilities 含 candidates/parse/feedback", all(
        x in caps for x in ("candidates", "parse", "feedback")), caps)

    print("=" * 70)
    print("2. 鉴权：错误令牌必须返回 unauthorized")
    status, bad = call(base, "/my/data", headers={"x-device-id": device_id, "x-device-token": "bad"})
    check("错误令牌 401", status == 401, status)
    check("错误码可区分", (bad.get("error") or {}).get("code") == "unauthorized", bad)

    print("=" * 70)
    print("3. /bind/reset：清除本设备旧绑定")
    status, reset = call(base, "/bind/reset", "POST", {}, headers)
    check("reset 200", status == 200, status)
    check("bound=false", (reset.get("data") or {}).get("bound") is False, reset)

    print("=" * 70)
    print("4. /parse：文本解析与 degraded 字段")
    status, parsed = call(base, "/parse", "POST", {"text": "明天下午三点在文治书院开会", "source": "verify"}, headers)
    check("parse 200", status == 200, status)
    pdata = parsed.get("data") or {}
    check("有 candidate", isinstance(pdata.get("candidate"), dict))
    check("degraded 字段存在（bool）", "degraded" in pdata, pdata.get("degraded"))

    print("=" * 70)
    print("5. /my/prefs：设备偏好可写可读")
    status, pref = call(base, "/my/prefs", "POST", {"skip_self": False}, headers)
    check("prefs 写入 200", status == 200, status)
    status, my = call(base, "/my/data", headers=headers)
    check("skip_self=false 已生效", (my.get("data") or {}).get("skip_self") is False, my.get("data"))
    call(base, "/my/prefs", "POST", {"skip_self": True}, headers)

    print("=" * 70)
    print("6. /push/token：登记假令牌（不应抛异常）")
    status, push = call(base, "/push/token", "POST", {"token": "verify-fake-token"}, headers)
    check("push/token 200", status == 200, status)
    check("registered=true", (push.get("data") or {}).get("registered") is True, push)
    print("   push_ready =", (push.get("data") or {}).get("push_ready"),
          "（后端未配置服务账号时 false 是正常的）")

    print("=" * 70)
    print("7. /forward/pending：应返回空数组（没有转发时）")
    status, fwd = call(base, "/forward/pending", headers=headers)
    check("forward/pending 200", status == 200, status)
    check("items 是数组", isinstance((fwd.get("data") or {}).get("items"), list), fwd)

    print("=" * 70)
    if FAILS:
        print("失败项：", "；".join(FAILS))
        return 1
    print("ALL PASS（后端接口自检通过）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
