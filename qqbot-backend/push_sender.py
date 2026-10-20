# -*- coding: utf-8 -*-
"""华为 Push Kit 云侧发送（开发者服务器 -> 华为 Push 网关 -> 设备）。

鉴权用**服务账号 JWT（PS256）**，不是 OAuth2 —— 官方明确「HarmonyOS 5 及以上
系统版本推送不再支持 OAuth 2.0 开放鉴权方式」。

JWT 结构（出处：`开发指南/Push_Kit_推送服务/端云调试/基于服务账号生成鉴权令牌`）：

    header  = {"kid": 服务账号.key_id, "typ": "JWT", "alg": "PS256"}
    payload = {"aud": 服务账号.token_uri, "iss": 服务账号.sub_account,
               "iat": 现在, "exp": iat + 3600}
    signature = PS256(私钥, base64url(header) + "." + base64url(payload))

发送接口（出处：`REST_API/场景化消息推送/请求体结构说明`）：

    POST https://push-api.cloud.huawei.com/v1/{projectId}/messages:send
    Authorization: Bearer <JWT>
    push-type: 0            # 0 = Alert（通知消息）
    body: { payload: { notification: { title, body } }, target: { token } }

**隐私**：推送的标题/正文会经过华为网关。用 `QQBOT_PUSH_INCLUDE_TEXT=0`
可以改成只推「有新提醒」、不带任何内容（`server.py` 的推送循环读这个开关）。

配置（都不进仓库）：
  * `QQBOT_PUSH_SA`      —— 服务账号 JSON 的文件路径（推荐）
  * `QQBOT_PUSH_SA_JSON` —— 或者直接给 JSON 字符串
  * `QQBOT_PUSH_CATEGORY`—— 可选，`notification.category`（如 IM / MARKETING）；
                            不填就不下发该字段，避免撞上未申请的「场景化权益」
"""

from __future__ import annotations

import base64
import json
import logging
import os
import time
import urllib.error
import urllib.request
from typing import Any

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

log = logging.getLogger("push")

PUSH_URL_V3 = "https://push-api.cloud.huawei.com/v3/{project}/messages:send"
# 服务账号 JSON 里的 token_uri 一般就是它；留作兜底（文件里 token_uri 为空时用）
DEFAULT_AUD = "https://oauth-login.cloud.huawei.com/oauth2/v3/token"
HTTP_TIMEOUT = 10.0

_ACCOUNT: dict[str, Any] | None = None
_ACCOUNT_STAMP: str = ""
_JWT_CACHE: dict[str, Any] = {"token": "", "exp": 0}


# ---------------------------------------------------------------- 配置


def _read_account() -> dict[str, Any] | None:
    """读服务账号：优先文件路径，其次内联 JSON。"""
    path = (os.environ.get("QQBOT_PUSH_SA") or "").strip()
    raw = ""
    if path:
        try:
            raw = open(path, "r", encoding="utf-8").read()
        except OSError as exc:
            log.warning("读服务账号文件失败：%s", exc)
            return None
    else:
        raw = (os.environ.get("QQBOT_PUSH_SA_JSON") or "").strip()
    if not raw:
        return None
    try:
        obj = json.loads(raw)
    except ValueError as exc:
        log.warning("服务账号 JSON 解析失败：%s", exc)
        return None
    if not isinstance(obj, dict):
        return None
    if not (obj.get("key_id") and obj.get("private_key") and obj.get("sub_account")):
        log.warning("服务账号缺少 key_id / private_key / sub_account")
        return None
    return obj


def account() -> dict[str, Any] | None:
    """带缓存地读服务账号（文件 mtime 变了会重读）。"""
    global _ACCOUNT, _ACCOUNT_STAMP
    path = (os.environ.get("QQBOT_PUSH_SA") or "").strip()
    stamp = ""
    if path:
        try:
            st = os.stat(path)
            stamp = f"{path}:{st.st_mtime_ns}"
        except OSError:
            stamp = f"{path}:missing"
    else:
        stamp = "inline"
    if _ACCOUNT is not None and stamp == _ACCOUNT_STAMP:
        return _ACCOUNT
    _ACCOUNT = _read_account()
    _ACCOUNT_STAMP = stamp
    return _ACCOUNT


def api_url() -> str:
    """推送接口 URL：**v3 + 项目ID**。

    这是实测唯一能成功的一组（2026-10-17）：
      * `v3/{项目ID}` -> `80000000 Success` ✅
      * `v3/{APPID}`  -> `80300002 无权限`
      * `v1/{项目ID}` -> `80300002 无权限`
      * `v1/{APPID}`  -> `80300010 token count ...`
    另外服务账号必须是**项目级**的（开发者级的密钥签出的 JWT 在这个项目上没有推送权限）。
    """
    acc = account() or {}
    project = str(acc.get("project_id") or os.environ.get("QQBOT_PUSH_PROJECT_ID") or "")
    return PUSH_URL_V3.format(project=project)


def configured() -> bool:
    """是否具备推送能力（服务账号 + 项目ID）。"""
    acc = account()
    if acc is None:
        return False
    return bool(str(acc.get("project_id") or os.environ.get("QQBOT_PUSH_PROJECT_ID") or ""))


# ---------------------------------------------------------------- JWT


def _b64(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def build_jwt(acc: dict[str, Any], now: int | None = None) -> str:
    """按官方 PS256 规则签服务账号 JWT。``now`` 只给测试用（固定时间戳）。"""
    iat = int(now if now is not None else time.time())
    header = {"kid": str(acc["key_id"]), "typ": "JWT", "alg": "PS256"}
    payload = {
        "aud": str(acc.get("token_uri") or DEFAULT_AUD),
        "iss": str(acc["sub_account"]),
        "iat": iat,
        "exp": iat + 3600,
    }
    signing_input = (
        _b64(json.dumps(header, separators=(",", ":"), ensure_ascii=False).encode("utf-8"))
        + "."
        + _b64(json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8"))
    )
    pem = str(acc["private_key"]).replace("\\n", "\n")
    key = serialization.load_pem_private_key(pem.encode("utf-8"), password=None)
    signature = key.sign(
        signing_input.encode("ascii"),
        padding.PSS(mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.DIGEST_LENGTH),
        hashes.SHA256(),
    )
    return signing_input + "." + _b64(signature)


def _auth_header() -> str | None:
    """复用 1 小时内的 JWT（官方建议有效期 3600 秒，期间可复用）。"""
    acc = account()
    if acc is None:
        return None
    now = int(time.time())
    if _JWT_CACHE.get("token") and int(_JWT_CACHE.get("exp") or 0) > now + 60:
        return str(_JWT_CACHE["token"])
    try:
        token = build_jwt(acc, now)
    except Exception as exc:  # noqa: BLE001
        log.warning("签 JWT 失败：%s", exc)
        return None
    _JWT_CACHE["token"] = token
    _JWT_CACHE["exp"] = now + 3600
    return token


# ---------------------------------------------------------------- 发送


def send(token: str, title: str, body: str, *, test: bool = False) -> tuple[bool, str]:
    """给一台设备发一条通知消息。返回 ``(是否成功, 说明)``。

    成功判据是响应体 ``code == "80000000"``（官方云侧业务响应码）。
    任何失败都**不抛异常**——推送失败不该拖垮主流程。
    """
    token = (token or "").strip()
    if not token:
        return False, "空 token"
    auth = _auth_header()
    acc = account()
    if auth is None or acc is None:
        return False, "未配置服务账号"
    url = api_url()
    if "{project}" in url:
        return False, "缺少项目ID"

    # 官方《请求体参数说明》里 category / title / body / clickAction 全是**必选**。
    # 默认 WORK（工作事项提醒）——与自分类权益申请的类别一致，有横幅和铃声；
    # 若权益被驳回，用 QQBOT_PUSH_CATEGORY=MARKETING 退回资讯营销类（静默、限 2~5 条/天）。
    category = (os.environ.get("QQBOT_PUSH_CATEGORY") or "WORK").strip().upper()
    notification: dict[str, Any] = {
        "category": category,
        "title": title or "知了",
        "body": body or "",
        "clickAction": {"actionType": 0},
    }
    payload: dict[str, Any] = {
        "payload": {"notification": notification},
        # 参数表里 target.token 的类型是 **Array[String]**，不是单个字符串
        "target": {"token": [token]},
    }
    if test:
        payload["pushOptions"] = {"testMessage": True}

    req = urllib.request.Request(
        url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer " + auth,
            "push-type": "0",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as resp:
            raw = resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        detail = exc.read()[:160].decode("utf-8", "replace")
        log.warning("push http %s: %s", exc.code, detail)
        return False, f"HTTP {exc.code}: {detail}"
    except Exception as exc:  # noqa: BLE001
        log.warning("push failed: %s", exc)
        return False, str(exc)

    try:
        obj = json.loads(raw)
    except ValueError:
        return False, raw[:120]
    code = str(obj.get("code") or "")
    if code == "80000000":
        return True, code
    log.warning("push rejected: %s", raw[:200])
    return False, code or raw[:120]
