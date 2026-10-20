"""relay.py 的逻辑自测：中继窗口、订阅过滤、绑定流程、去重、窗口过期。

运行：.venv\\Scripts\\python.exe -X utf8 test_relay.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 用工作区内的临时文件，避免污染真实的 relay_store.json（沙箱只允许写工作区）
_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store.json"
_tmp.parent.mkdir(parents=True, exist_ok=True)
if _tmp.exists():
    _tmp.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_tmp)

import relay  # noqa: E402

FAILS = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + extra) if extra else ''}")
    if not cond:
        FAILS.append(label)


# ---------------------------------------------------------------- 配对码解析
check("parse '绑定 7K3M9Q'", relay.parse_bind_command("绑定 7K3M9Q") == "7K3M9Q")
check("parse '/bind ab12cd'", relay.parse_bind_command("/bind ab12cd") == "AB12CD")
check("parse '  7k3m9q '", relay.parse_bind_command("  7k3m9q ") == "7K3M9Q")
check("parse 无关文本", relay.parse_bind_command("你好啊") == "")
check("parse 解绑不误判", relay.parse_bind_command("解绑") == "")

# ---------------------------------------------------------------- 设备与鉴权
dev = relay.STORE.register_device("pytest")
device_id, token = dev["device_id"], dev["token"]
check("注册返回 device_id/token", bool(device_id) and bool(token))
check("正确令牌鉴权通过", relay.STORE.auth(device_id, token) is True)
check("错误令牌鉴权失败", relay.STORE.auth(device_id, "bad-token") is False)
check("未知设备鉴权失败", relay.STORE.auth("dev_nope", token) is False)

# ---------------------------------------------------------------- 绑定流程
code = relay.STORE.mint_bind_code(device_id)["code"]
check("配对码 6 位", len(code) == 6, code)
check("未绑定时 bound=False", relay.STORE.bind_status(device_id)["bound"] is False)
bad = relay.STORE.bind_by_code("ZZZZZZ", "user_openid_A")
check("错误配对码被拒", bad["ok"] is False and bad["reason"] == "invalid_code")
ok = relay.STORE.bind_by_code(code, "user_openid_A")
check("正确配对码绑定成功", ok["ok"] is True)
check("绑定后 bound=True", relay.STORE.bind_status(device_id)["bound"] is True)
check(
    "只返回 openid 尾号",
    relay.STORE.bind_status(device_id)["user_openid_tail"] == "…id_A",
    relay.STORE.bind_status(device_id)["user_openid_tail"],
)
again = relay.STORE.bind_by_code(code, "user_openid_B")
check("配对码一次性", again["ok"] is False and again["reason"] == "used_code")
check("反查设备数=1", len(relay.STORE.devices_of_openid("user_openid_A")) == 1)

# ---------------------------------------------------------------- 中继窗口与订阅过滤
GID = "15B451ACFDB0816E3233D1947DEAC820"
OTHER = "AAAA1111BBBB2222CCCC3333DDDD4444"

r0 = relay.ingest_group_message(GID, "同学A", "周五前交实验报告", msg_id="m1")
check("消息进入窗口", r0["seq"] == 1, str(r0))
check("未订阅时订阅设备数=0", r0["subscribers"] == 0)
before = relay.window_since(device_id, 0)
check("未订阅拉不到消息", before["messages"] == [])
check("未订阅时 subscribed_groups=0", before["subscribed_groups"] == 0)

relay.STORE.subscribe(device_id, GID)
after = relay.window_since(device_id, 0)
check("订阅后能拉到消息", len(after["messages"]) == 1, str(len(after["messages"])))
check("消息字段完整", after["messages"][0]["content"] == "周五前交实验报告")
check("返回 max_seq", after["max_seq"] == 1)

relay.ingest_group_message(OTHER, "同学B", "另一个群的闲聊", msg_id="m2")
got = relay.window_since(device_id, 0)
check("只返回订阅群的消息", [m["msg_id"] for m in got["messages"]] == ["m1"])

relay.ingest_group_message(GID, "同学C", "会议室改到A203", msg_id="m3")
inc = relay.window_since(device_id, 1)
check(
    "增量只返回新消息",
    [m["msg_id"] for m in inc["messages"]] == ["m3"],
    str([m["msg_id"] for m in inc["messages"]]),
)

dup = relay.ingest_group_message(GID, "同学C", "会议室改到A203", msg_id="m3")
check("重复 msg_id 不入窗口", dup["seq"] is None, str(dup))

relay.STORE.subscribe(device_id, GID, keywords="作业,报告")
kw = relay.window_since(device_id, 0)
check("关键词命中保留", any("实验报告" in m["content"] for m in kw["messages"]))
check("关键词未命中被过滤", not any("会议室" in m["content"] for m in kw["messages"]))
relay.STORE.subscribe(device_id, GID)

relay.STORE.subscribe(device_id, GID, min_priority="notice")
relay.ingest_group_message(GID, "同学D", "哈哈哈哈水群", msg_id="m4")
notice = relay.window_since(device_id, 0)
check("notice 规则过滤闲聊", not any("水群" in m["content"] for m in notice["messages"]))
relay.STORE.subscribe(device_id, GID)

# ---------------------------------------------------------------- 统计与倒排
stats = relay.STORE.stats(device_id)
check("统计：订阅数=1", stats["subscriptions"] == 1, str(stats))
check("统计：绑定数=1", stats["bindings"] == 1)
subs = relay.STORE.subscribers_of(GID)
check("倒排：该群有 1 台设备订阅", subs == [device_id], str(subs))
check("倒排：另一个群无人订阅", relay.STORE.subscribers_of(OTHER) == [])

# ---------------------------------------------------------------- 窗口过期
saved_minutes = relay.WINDOW.minutes
relay.WINDOW.minutes = 0
expired = relay.window_since(device_id, 0)
check("窗口过期后拉不到消息", expired["messages"] == [], str(len(expired["messages"])))
relay.WINDOW.minutes = saved_minutes

# ---------------------------------------------------------------- 落盘内容不含正文
raw = _tmp.read_text(encoding="utf-8")
check("落盘文件不含消息正文", "周五前交实验报告" not in raw and "水群" not in raw)
check("落盘文件含订阅关系", GID in raw)   # 注意：必须在 forget_device 之前检查

# ---------------------------------------------------------------- 一键删除（放最后）
relay.STORE.forget_device(device_id)
check("删除设备后鉴权失败", relay.STORE.auth(device_id, token) is False)
check("删除后订阅清空", relay.STORE.groups_of(device_id) == set())
check("删除后绑定清空", relay.STORE.bind_status(device_id)["bound"] is False)

# ---------------------------------------------------------------- 解绑（按 openid）
dev2 = relay.STORE.register_device("pytest2")
code2 = relay.STORE.mint_bind_code(dev2["device_id"])["code"]
relay.STORE.bind_by_code(code2, "user_openid_C")
check("解绑前有绑定", len(relay.STORE.devices_of_openid("user_openid_C")) == 1)
removed = relay.STORE.unbind_by_openid("user_openid_C")
check("解绑返回 1 条", removed == 1, str(removed))
check("解绑后绑定为空", relay.STORE.devices_of_openid("user_openid_C") == [])

# ---------------------------------------------------------------- 群隔离（绑定门槛 + 白名单）
import asyncio  # noqa: E402
import json  # noqa: E402

import server  # noqa: E402  （复用本文件已设定的 QQBOT_RELAY_STORE）

# 让 /groups 只认下面这两条“机器人所在的群”，避免依赖真实 bot.db
server._known_groups_sync = lambda: [
    {"group_openid": GID, "c": 3, "last_at": "2026-10-11 18:00:00"},
    {"group_openid": OTHER, "c": 1, "last_at": "2026-10-11 18:00:00"},
]

iso = relay.STORE.register_device("iso")
iso_id, iso_token = iso["device_id"], iso["token"]
check("未绑定：看不到任何群", server.api_relay_groups(iso_id)["groups"] == [])

code_iso = relay.STORE.mint_bind_code(iso_id)["code"]
relay.STORE.bind_by_code(code_iso, "openid_iso")
check("已绑定但未授权：仍然看不到群", server.api_relay_groups(iso_id)["groups"] == [])

relay.STORE.grant("openid_iso", GID)
shown = [g["group_openid"] for g in server.api_relay_groups(iso_id)["groups"]]
check("授权后只看到被授权的群", shown == [GID], str(shown))


async def _subscribe(device_id: str, token: str, gid: str):
    headers = {"x-device-id": device_id, "x-device-token": token}
    body = json.dumps({"group_openid": gid}).encode("utf-8")
    return await server.handle_relay_api("/subscribe", "POST", {}, headers, body)


st_deny, payload_deny = asyncio.run(_subscribe(iso_id, iso_token, OTHER))
check("未授权群订阅被拒", st_deny == 403 and payload_deny["ok"] is False)
st_ok, payload_ok = asyncio.run(_subscribe(iso_id, iso_token, GID))
check("已授权群订阅通过", st_ok == 200 and payload_ok["data"]["subscribed"] is True)

os.environ["QQBOT_OPERATOR_OPENID"] = "openid_iso"
op_shown = [g["group_openid"] for g in server.api_relay_groups(iso_id)["groups"]]
check("运营者白名单放行全部群", set(op_shown) == {GID, OTHER}, str(op_shown))
os.environ.pop("QQBOT_OPERATOR_OPENID", None)

relay.STORE.revoke("openid_iso", GID)
check("撤销后不再可见", relay.STORE.granted_groups("openid_iso") == set())

relay.STORE.grant("openid_iso", GID)
relay.STORE.forget_device(iso_id)
check("一键删除后授权一并清空", relay.STORE.granted_groups("openid_iso") == set())

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
