# -*- coding: utf-8 -*-
"""集成自测：/api/relay/candidates（去重+聚类）与 /health 能力位，走真实的 relay 窗口。

运行：.venv\\Scripts\\python.exe -X utf8 test_candidates_api.py
不依赖 QQ、不依赖 Ollama（强制规则路径）。
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 沙箱内临时存储，别污染真实 relay_store.json
_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store_candidates.json"
_tmp.parent.mkdir(parents=True, exist_ok=True)
if _tmp.exists():
    _tmp.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_tmp)
# 词表也指到沙箱，避免 /my/data 的清除逻辑动到真实 group_lexicon.json
_lex = Path(__file__).resolve().parent / "_tmp_test" / "group_lexicon_api.json"
if _lex.exists():
    _lex.unlink()
os.environ["QQBOT_GROUP_LEXICON"] = str(_lex)

import llm_parse  # noqa: E402
llm_parse.available = lambda: False  # 强制规则路径，避免依赖本机模型

import relay  # noqa: E402
import group_lexicon  # noqa: E402
import server  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


GID = "15B451ACFDB0816E3233D1947DEAC820"
OTHER = "AAAA1111BBBB2222CCCC3333DDDD4444"

dev = relay.STORE.register_device("cand-api")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
relay.STORE.subscribe(DEVICE, GID)


def call(path: str, query: dict | None = None) -> dict:
    status, payload = asyncio.run(
        server.handle_relay_api(path, "GET", query or {}, HEADERS, b"")
    )
    assert status == 200, (status, payload)
    return payload["data"]


# ---------------------------------------------------------------- /health 能力位
print("=" * 78)
print("一、/health 里声明 v2 能力（api_version + capabilities）")
print("=" * 78)
health = call("/health")
check("api_version = 2", health.get("api_version") == 2, str(health.get("api_version")))
check("capabilities 含 candidates", "candidates" in (health.get("capabilities") or []),
      str(health.get("capabilities")))
check("capabilities 含 feedback（已实现）", "feedback" in (health.get("capabilities") or []),
      str(health.get("capabilities")))
check("capabilities 含 parse（已实现）", "parse" in (health.get("capabilities") or []),
      str(health.get("capabilities")))
check("模型不可用时不谎报 ocr", "ocr" not in (health.get("capabilities") or []),
      str(health.get("capabilities")))

# 运行指标：只读计数（排障用），不许含消息内容
llm = health.get("llm") or {}
check("health 含 llm 指标", isinstance(llm, dict) and "queue_depth" in llm, str(llm))
check("llm 指标带 model 名", str(llm.get("model") or "") != "", str(llm.get("model")))
check("llm 指标有计数项", all(k in llm for k in ("processed", "llm_calls", "degraded")), str(llm))
push = health.get("push") or {}
check("health 含 push 指标", isinstance(push, dict) and "sent" in push, str(push))
check("push 指标带 ready", "ready" in push, str(push))

# ---------------------------------------------------------------- 空窗口
print()
print("二、空窗口返回空候选与回原游标")
print("=" * 78)
empty = call("/candidates", {"after": ["0"]})
check("空窗口候选为空", empty["candidates"] == [], str(len(empty["candidates"])))
check("空窗口 cursor 回原值", empty["cursor"] == 0, str(empty["cursor"]))

# ---------------------------------------------------------------- 注入真实对话
print()
print("三、注入「传智杯」多轮对话 -> 一条候选")
print("=" * 78)
DIALOG = [
    ("歪歪歪", "2026-10-14 09:13:43"),
    ("明天是不是有比赛啊", "2026-10-14 09:14:01"),
    ("好像是", "2026-10-14 09:14:06"),
    ("有啥", "2026-10-14 09:14:14"),
    ("传智杯比赛", "2026-10-14 09:14:22"),
    ("几点的", "2026-10-14 09:14:57"),
    ("早上9点就开好像是说", "2026-10-14 09:15:07"),
    ("不是下午8", "2026-10-14 09:15:27"),
]
for i, (content, ts) in enumerate(DIALOG):
    relay.ingest_group_message(GID, "硫酸Cu", content, msg_id=f"e2e_{i}", timestamp=ts)

first = call("/candidates", {"after": ["0"]})
check("8 条 -> 1 条候选", len(first["candidates"]) == 1, str(len(first["candidates"])))
cand = first["candidates"][0] if first["candidates"] else {}
check("来源 count = 8", cand.get("source", {}).get("count") == 8, str(cand.get("source", {}).get("count")))
check("kind 不是闲聊", cand.get("kind") in ("待办", "通知", "活动", "出行计划"), cand.get("kind"))
check("时间跨消息拼合到 2026-10-15 09:00", cand.get("time_normalized") == "2026-10-15 09:00",
      cand.get("time_normalized"))
check("cursor > 0", first["cursor"] > 0, str(first["cursor"]))

# 内容没变：再拉一次不应重发（rev_seq 未变 -> after=cursor 后为空）
again = call("/candidates", {"after": [str(first["cursor"])]})
check("游标跑到底无新增", again["candidates"] == [], str(len(again["candidates"])))

# ---------------------------------------------------------------- upsert
print()
print("四、追加相关消息 -> 同 candidate_id、rev_seq 变大")
print("=" * 78)
relay.ingest_group_message(GID, "Oliver", "传智杯是大学生比赛", msg_id="e2e_x", timestamp="2026-10-14 09:15:50")
upd = call("/candidates", {"after": [str(first["cursor"])]})
check("增量下发 1 条", len(upd["candidates"]) == 1, str(len(upd["candidates"])))
check("candidate_id 不变", upd["candidates"][0]["candidate_id"] == cand.get("candidate_id"))
check("rev_seq 变大", upd["candidates"][0]["rev_seq"] > cand.get("rev_seq"),
      f"{cand.get('rev_seq')} -> {upd['candidates'][0]['rev_seq']}")
check("count 变 9", upd["candidates"][0]["source"]["count"] == 9, str(upd["candidates"][0]["source"]["count"]))

# ---------------------------------------------------------------- 群隔离
print()
print("五、候选按设备订阅的群过滤")
print("=" * 78)
relay.ingest_group_message(OTHER, "他人", "别的群也有比赛通知", msg_id="other_1", timestamp="2026-10-14 09:16:00")
mine = call("/candidates", {"after": ["0"]})
check("只看到自己订阅群的候选",
      all(c["source"]["group_openid"] == GID for c in mine["candidates"]),
      str([c["source"]["group_openid"] for c in mine["candidates"]]))
check("别的群的候选被过滤掉", len(mine["candidates"]) == 1, str(len(mine["candidates"])))

relay.STORE.forget_device(DEVICE)

# ---------------------------------------------------------------- 词表随一键删除一起清
print()
print("六、派生词表跟着 /my/data 一起清（隐私）")
print("=" * 78)
dev2 = relay.STORE.register_device("cand-api-2")
D2, T2 = dev2["device_id"], dev2["token"]
H2 = {"x-device-id": D2, "x-device-token": T2}
relay.STORE.subscribe(D2, GID)
group_lexicon.STORE.merge(GID, {"康桥": {"count": 9, "cat": "place", "score": 9}})
check("清除前词表里有该群", "康桥" in group_lexicon.STORE.words_of_category(GID, "place"))

st, payload = asyncio.run(server.handle_relay_api("/my/data", "DELETE", {}, H2, b""))
data = payload["data"]
check("DELETE /my/data 成功", st == 200 and data.get("deleted") is True, str(data))
check("返回清了多少个群的词表", data.get("lexicon_groups_cleared") == 1, str(data.get("lexicon_groups_cleared")))
check("该群词表已被清空", group_lexicon.STORE.terms(GID) == {}, str(group_lexicon.STORE.terms(GID)))

# ---------------------------------------------------------------- 反馈（契约 §2.3）
print()
print("七、POST /api/relay/feedback（候选接受/忽略 + 手动删词）")
print("=" * 78)

dev3 = relay.STORE.register_device("cand-api-3")
D3, T3 = dev3["device_id"], dev3["token"]
H3 = {"x-device-id": D3, "x-device-token": T3}
relay.STORE.subscribe(D3, GID)


def post(path: str, body: dict, headers: dict) -> tuple[int, dict]:
    return asyncio.run(server.handle_relay_api(path, "POST", {}, headers, json.dumps(body).encode("utf-8")))


status, payload = post("/feedback", {"candidate_id": "c_abc123", "action": "accept", "kind": "待办",
                                     "group_openid": GID}, H3)
check("accept 返回 recorded", status == 200 and payload["data"]["recorded"] is True, str(payload))
check("回显 candidate_id", payload["data"]["candidate_id"] == "c_abc123")

status, payload = post("/feedback", {"candidate_id": "c_abc123", "action": "dismiss", "kind": "闲聊",
                                     "group_openid": GID}, H3)
check("dismiss 也能记录", status == 200 and payload["data"]["action"] == "dismiss", str(payload))
check("计数被记录", relay.FEEDBACK.stats()["totals"] == {"accept": 1, "dismiss": 1},
      str(relay.FEEDBACK.stats()))

status, payload = post("/feedback", {"candidate_id": "c_x", "action": "maybe"}, H3)
check("非法 action -> 400", status == 400, str(status))
status, payload = post("/feedback", {"action": "accept"}, H3)
check("缺 candidate_id -> 400", status == 400, str(status))

# drop_words：把用户手动删掉的词同步给按群词表
group_lexicon.STORE.merge(GID, {"蔷薇": {"count": 5, "cat": "other", "score": 5},
                                "不同": {"count": 4, "cat": "place", "score": 4}})
check("删词前词表里有 不同", "不同" in group_lexicon.STORE.terms(GID), str(list(group_lexicon.STORE.terms(GID))))
status, payload = post("/feedback", {"candidate_id": "c_abc123", "action": "dismiss",
                                     "group_openid": GID, "drop_words": ["不同", "不存在"]}, H3)
check("drop_words 生效", payload["data"]["dropped_words"] == ["不同"], str(payload["data"]["dropped_words"]))
check("词表里已没有 不同", "不同" not in group_lexicon.STORE.terms(GID))
check("没被删的词仍在", "蔷薇" in group_lexicon.STORE.terms(GID))

health2 = call("/health")
check("capabilities 现在含 feedback", "feedback" in (health2.get("capabilities") or []),
      str(health2.get("capabilities")))

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
