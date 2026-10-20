# -*- coding: utf-8 -*-
"""Push Kit 接入：Token 上报接口 + 服务账号 JWT 签名。

跑法（在 qqbot-backend 下）：
    .venv\\Scripts\\python.exe -X utf8 test_push_api.py

覆盖：
  一、未配置服务账号时**不谎报** push 能力
  二、POST /api/relay/push/token：登记 / 按群查 / 注销 / 参数校验
  三、服务账号 JWT：header/payload 字段 + PS256 签名能被公钥验证
  四、配置好服务账号后 capabilities 出现 push；发送失败不抛异常
"""

from __future__ import annotations

import asyncio
import base64
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

_TMP = Path(__file__).resolve().parent / "_tmp_test"
_TMP.mkdir(parents=True, exist_ok=True)
_store = _TMP / "relay_store_push.json"
if _store.exists():
    _store.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_store)
_lex = _TMP / "group_lexicon_push.json"
if _lex.exists():
    _lex.unlink()
os.environ["QQBOT_GROUP_LEXICON"] = str(_lex)
# 一开始**不配**服务账号
os.environ.pop("QQBOT_PUSH_SA", None)
os.environ.pop("QQBOT_PUSH_SA_JSON", None)

import push_sender  # noqa: E402
import relay  # noqa: E402
import server  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


def b64d(s: str) -> bytes:
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


GID = "15B451ACFDB0816E3233D1947DEAC820"
dev = relay.STORE.register_device("push-api")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
relay.STORE.subscribe(DEVICE, GID)


def call(path: str, query: dict | None = None) -> dict:
    status, payload = asyncio.run(
        server.handle_relay_api(path, "GET", query or {}, HEADERS, b"")
    )
    assert status == 200, (status, payload)
    return payload["data"]


def post(path: str, body: dict) -> tuple[int, dict]:
    return asyncio.run(
        server.handle_relay_api(path, "POST", {}, HEADERS, json.dumps(body).encode("utf-8"))
    )


# ---------------------------------------------------------------- 一、不谎报
print("=" * 78)
print("一、未配置服务账号：capabilities 不含 push")
print("=" * 78)
health = call("/health")
caps = health.get("capabilities") or []
check("push 不在能力位里", "push" not in caps, str(caps))
check("configured() 为 False", push_sender.configured() is False)
check("send 空 token 直接失败（不抛异常）",
      push_sender.send("", "t", "b")[0] is False)
check("未配置时发送失败但不抛异常",
      push_sender.send("tok", "t", "b")[0] is False)

# ---------------------------------------------------------------- 二、Token 接口
print()
print("二、POST /api/relay/push/token")
print("=" * 78)
status, payload = post("/push/token", {"token": "tok_abc"})
check("上报成功", status == 200 and payload["data"]["registered"] is True,
      f"{status} {str(payload)[:100]}")
check("push_ready=False（还没配服务账号）", payload["data"]["push_ready"] is False,
      str(payload["data"]))
check("token 落库", relay.STORE.push_token_of(DEVICE) == "tok_abc",
      relay.STORE.push_token_of(DEVICE))
check("按群能查到该设备的 token",
      relay.STORE.push_tokens_of_group(GID) == ["tok_abc"],
      str(relay.STORE.push_tokens_of_group(GID)))
check("没订阅的群查不到", relay.STORE.push_tokens_of_group("OTHER_GROUP") == [])

status, _ = post("/push/token", {"token": ""})
check("空串 = 注销", status == 200 and relay.STORE.push_token_of(DEVICE) == "",
      relay.STORE.push_token_of(DEVICE))

status, payload = asyncio.run(server.handle_relay_api("/push/token", "GET", {}, HEADERS, b""))
check("GET 被拒", status == 400, str(status))

# ---------------------------------------------------------------- 三、JWT
print()
print("三、服务账号 JWT（PS256）")
print("=" * 78)
from cryptography.hazmat.primitives import hashes, serialization  # noqa: E402
from cryptography.hazmat.primitives.asymmetric import padding, rsa  # noqa: E402

_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
_pem = _key.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.NoEncryption(),
).decode("utf-8")
ACC = {
    "project_id": "101653523865357174",
    "key_id": "key_123",
    "sub_account": "sub_456",
    "private_key": _pem,
    "token_uri": "https://oauth-login.cloud.huawei.com/oauth2/v3/token",
}
jwt = push_sender.build_jwt(ACC, now=1_700_000_000)
h, p, s = jwt.split(".")
header = json.loads(b64d(h))
claims = json.loads(b64d(p))
check("header.alg = PS256", header.get("alg") == "PS256", str(header))
check("header.typ = JWT", header.get("typ") == "JWT", str(header))
check("header.kid = key_id", header.get("kid") == "key_123", str(header))
check("payload.iss = sub_account", claims.get("iss") == "sub_456", str(claims))
check("payload.aud = token_uri",
      claims.get("aud") == ACC["token_uri"], str(claims))
check("payload.iat 是传入时刻", claims.get("iat") == 1_700_000_000, str(claims))
check("payload.exp = iat + 3600", claims.get("exp") == 1_700_003_600, str(claims))
try:
    _key.public_key().verify(
        b64d(s),
        f"{h}.{p}".encode("ascii"),
        padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.DIGEST_LENGTH),
        hashes.SHA256(),
    )
    signed_ok = True
except Exception as exc:  # noqa: BLE001
    signed_ok = False
    print("   verify error:", exc)
check("签名可用公钥验签（PS256）", signed_ok)

# ---------------------------------------------------------------- 四、配置后
print()
print("四、配置服务账号后：capabilities 出现 push")
print("=" * 78)
os.environ["QQBOT_PUSH_SA_JSON"] = json.dumps(ACC)
push_sender._ACCOUNT = None          # 清缓存，让它重读环境变量
push_sender._ACCOUNT_STAMP = ""
check("configured() 变 True", push_sender.configured() is True)
caps2 = call("/health").get("capabilities") or []
check("capabilities 含 push", "push" in caps2, str(caps2))

# 真发一次会打到华为网关，这里只验证「不抛异常 + 返回 (bool, 说明)」
ok, detail = push_sender.send("not-a-real-token", "t", "b")
check("发送返回 (bool, 说明) 且不抛异常", ok is False and bool(detail), detail)

os.environ.pop("QQBOT_PUSH_SA_JSON", None)
relay.STORE.forget_device(DEVICE)

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
