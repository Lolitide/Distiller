# -*- coding: utf-8 -*-
"""POST /api/relay/profile · 用户画像词条归纳 —— 功能 + **隐私** 断言。

跑法（在 qqbot-backend 下）：
    .venv\\Scripts\\python.exe -X utf8 test_profile_api.py

覆盖：
  一、/health 能力位
  二、规则路径（模型不在线）：排序 / 权重归一化 / reason 由规则生成
  三、参数校验与边界（空素材、非法 kind、次数非正、GET、缺 material）
  四、**安全闸**：模型编造的词一律丢弃，只留素材里有的词
  五、模型产出过薄 -> 回退规则
  六、**隐私红线**：窗口不变、候选流不变、**工作目录无新增文件**
  七、响应里不含素材之外的任何词（不编造）
"""

from __future__ import annotations

import asyncio
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 沙箱内临时存储，别污染真实 relay_store.json / group_lexicon.json
_TMP = Path(__file__).resolve().parent / "_tmp_test"
_TMP.mkdir(parents=True, exist_ok=True)
_store = _TMP / "relay_store_profile.json"
if _store.exists():
    _store.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_store)
_lex = _TMP / "group_lexicon_profile.json"
if _lex.exists():
    _lex.unlink()
os.environ["QQBOT_GROUP_LEXICON"] = str(_lex)

import llm_parse  # noqa: E402
llm_parse.available = lambda: False  # 默认强制规则路径，不依赖本机模型

import profile_summarize  # noqa: E402
import relay  # noqa: E402
import server  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


GID = "15B451ACFDB0816E3233D1947DEAC820"

dev = relay.STORE.register_device("profile-api")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
relay.STORE.subscribe(DEVICE, GID)


def call(path: str, query: dict | None = None) -> dict:
    status, payload = asyncio.run(
        server.handle_relay_api(path, "GET", query or {}, HEADERS, b"")
    )
    assert status == 200, (status, payload)
    return payload["data"]


def post(path: str, body: dict, headers: dict | None = None) -> tuple[int, dict]:
    return asyncio.run(
        server.handle_relay_api(path, "POST", {}, headers or HEADERS,
                                json.dumps(body).encode("utf-8"))
    )


def dir_snapshot() -> list[str]:
    """后端目录下的文件清单（排除 __pycache__），用于"没落盘"的断言。"""
    root = Path(__file__).resolve().parent
    out: list[str] = []
    for p in root.rglob("*"):
        if "__pycache__" in p.parts or p.is_dir():
            continue
        out.append(str(p.relative_to(root)))
    return sorted(out)


# 素材：**只有词和数字**，没有任何聊天原话（这就是画像素材的契约）
MATERIAL = {
    "terms": [
        {"kind": "schedule", "term": "晚上", "count": 12},
        {"kind": "interest", "term": "传智杯", "count": 9},
        {"kind": "place", "term": "康桥苑", "count": 7},
        {"kind": "interest", "term": "蓝桥杯", "count": 6},
        {"kind": "role", "term": "仲英书院", "count": 5},
    ],
    "counters": {"selfMsgs": 120, "todoCount": 4},
}

# ---------------------------------------------------------------- 一、能力位
print("=" * 78)
print("一、/health 能力位：profile 常驻（规则回退永远可用，与模型无关）")
print("=" * 78)
health = call("/health")
caps = health.get("capabilities") or []
check("capabilities 含 profile", "profile" in caps, str(caps))
check("api_version = 2", health.get("api_version") == 2, str(health.get("api_version")))

# ---------------------------------------------------------------- 二、规则路径
print()
print("二、模型不在线 -> 规则：按次数排序 + 权重归一化 + reason 由规则生成")
print("=" * 78)
before_window = relay.window_stats()
before_candidates = call("/candidates", {"after": ["0"]})
before_files = dir_snapshot()

status, payload = post("/profile", {"material": MATERIAL, "max_entries": 10})
check("状态 200", status == 200, str(status))
data = payload.get("data") or {}
check("engine = rules（模型不在线）", data.get("engine") == "rules", str(data.get("engine")))
entries = data.get("entries") or []
check("产出 5 条（去重后与素材同数）", len(entries) == 5, str(len(entries)))
check("第 1 条是素材里次数最高的词", entries[0].get("term") == "晚上", str(entries[0]))
check("最高频词权重 100", entries[0].get("weight") == 100, str(entries[0].get("weight")))
check("权重按相对最高频归一化（9/12 -> 75）", entries[1].get("weight") == 75, str(entries[1]))
check("weight 单调不增",
      all(entries[i]["weight"] >= entries[i + 1]["weight"] for i in range(len(entries) - 1)),
      str([e["weight"] for e in entries]))
check("reason 是规则生成的事实描述", entries[0].get("reason") == "出现 12 次",
      str(entries[0].get("reason")))
check("evidence 回传次数", entries[0].get("evidence") == 12, str(entries[0].get("evidence")))
check("kind 原样保留", entries[2].get("kind") == "place", str(entries[2].get("kind")))

# ---------------------------------------------------------------- 三、参数校验
print()
print("三、参数校验与边界")
print("=" * 78)
status, payload = post("/profile", {})
check("缺 material -> 400 bad_request",
      status == 400 and payload.get("error", {}).get("code") == "bad_request",
      f"{status} {str(payload)[:100]}")

status, payload = post("/profile", {"material": "not-a-dict"})
check("material 不是对象 -> 400", status == 400, str(status))

status, payload = asyncio.run(server.handle_relay_api("/profile", "GET", {}, HEADERS, b""))
check("GET /profile -> 400", status == 400, str(status))

status, payload = post("/profile", {"material": {"terms": []}})
check("空素材 -> 200 且 entries 为空", status == 200 and payload["data"]["entries"] == [],
      f"{status} {str(payload)[:100]}")

status, payload = post("/profile", {"material": {"terms": "nope"}})
check("terms 不是数组 -> 200 且空（不 500）",
      status == 200 and payload["data"]["entries"] == [], str(status))

status, payload = post("/profile", {"material": {"terms": [
    {"kind": "不存在的类", "term": "马拉松", "count": 3},
    {"term": "没有kind", "count": 2},
]}})
ents = payload["data"]["entries"]
check("非法 kind 归到 interest", all(e["kind"] == "interest" for e in ents), str(ents))
check("缺 kind 也能收（不丢词）", len(ents) == 2, str(len(ents)))

status, payload = post("/profile", {"material": {"terms": [
    {"kind": "interest", "term": "零次词", "count": 0},
    {"kind": "interest", "term": "空词", "count": 5},
    {"kind": "interest", "term": "   ", "count": 3},
    {"kind": "interest", "term": "正常词", "count": 4},
]}})
terms = [e["term"] for e in payload["data"]["entries"]]
check("次数非正的词丢弃", "零次词" not in terms, str(terms))
check("空白词丢弃", len(terms) == 2 and "正常词" in terms, str(terms))

status, payload = post("/profile", {"material": MATERIAL, "max_entries": 2})
check("max_entries 生效", len(payload["data"]["entries"]) == 2,
      str(len(payload["data"]["entries"])))
status, payload = post("/profile", {"material": MATERIAL, "max_entries": 9999})
check("max_entries 超上限被夹到 60（不爆炸）",
      len(payload["data"]["entries"]) <= 60, str(len(payload["data"]["entries"])))

# ---------------------------------------------------------------- 四、安全闸
print()
print("四、安全闸：模型编造的词一律丢弃（词必须出自素材）")
print("=" * 78)
llm_parse.available = lambda: True  # 假装模型在线


def stub_chat(messages, schema=None, **kwargs) -> str:
    return json.dumps({"entries": [
        {"kind": "interest", "term": "传智杯", "weight": 90},      # 素材里有 -> 留
        {"kind": "place", "term": "康桥苑", "weight": 300},        # 越界权重 -> 留但夹到 100
        {"kind": "interest", "term": "喜欢打篮球", "weight": 88},  # **编造** -> 丢
        {"kind": "interest", "term": "竞赛", "weight": 85},        # 上位词，素材里没有 -> 丢
        {"kind": "role", "time": "仲英书院"},                      # 缺 term -> 丢
        {"kind": "bad-kind", "term": "蓝桥杯", "weight": 70},      # kind 非法 -> 丢
        {"kind": "interest", "term": "传智杯", "weight": 60},      # 重复 -> 只留一次
        {"kind": "interest", "term": "晚上", "weight": 40},        # 留
        {"kind": "role", "term": "仲英书院", "weight": 30},        # 留
        {"kind": "place", "term": "蓝桥杯", "weight": 20},         # 留（重新归类，词合法）
    ]})


llm_parse.chat = stub_chat
status, payload = post("/profile", {"material": MATERIAL, "max_entries": 10})
data = payload["data"]
check("engine = llm", data.get("engine") == "llm", str(data.get("engine")))
got = [(e["term"], e["kind"], e["weight"]) for e in data["entries"]]
terms = [g[0] for g in got]
check("素材里的词保留", "传智杯" in terms, str(terms))
check("**编造词被丢弃**（喜欢打篮球）", "喜欢打篮球" not in terms, str(terms))
check("**上位词被丢弃**（竞赛）", "竞赛" not in terms, str(terms))
check("缺 term 的条目丢弃", all(t != "" for t in terms), str(terms))
check("重复词只留一条", len(terms) == len(set(terms)), str(terms))
check("越界权重被夹到 100", [w for t, k, w in got if t == "康桥苑"] == [100], str(got))
check("reason 仍由规则生成（模型说了不算）",
      all(e["reason"].startswith("出现 ") for e in data["entries"]),
      str([e["reason"] for e in data["entries"]]))
check("按 weight 降序", [w for t, k, w in got] == sorted([w for t, k, w in got], reverse=True),
      str([w for t, k, w in got]))

# ---------------------------------------------------------------- 五、过薄回退
print()
print("五、模型产出过薄 -> 回退规则（不给用户一个空空如也的画像）")
print("=" * 78)
llm_parse.chat = lambda messages, schema=None, **kw: json.dumps(
    {"entries": [{"kind": "interest", "term": "传智杯", "weight": 50}]})
status, payload = post("/profile", {"material": MATERIAL, "max_entries": 10})
check("只有 1 条有效 -> engine 退回 rules", payload["data"]["engine"] == "rules",
      str(payload["data"]["engine"]))
check("退回后条目数回到规则水平", len(payload["data"]["entries"]) == 5,
      str(len(payload["data"]["entries"])))

llm_parse.chat = lambda messages, schema=None, **kw: "这不是 json"
status, payload = post("/profile", {"material": MATERIAL, "max_entries": 10})
check("模型返回非 JSON -> 回退 rules", payload["data"]["engine"] == "rules",
      str(payload["data"]["engine"]))

llm_parse.chat = lambda messages, schema=None, **kw: None
status, payload = post("/profile", {"material": MATERIAL, "max_entries": 10})
check("模型调用失败 -> 回退 rules", payload["data"]["engine"] == "rules",
      str(payload["data"]["engine"]))

llm_parse.available = lambda: False

# ---------------------------------------------------------------- 七、不编造
print()
print("六、响应里只出现素材里有的词（规则与模型两条路径都不编造）")
print("=" * 78)
vocab_terms = {t["term"] for t in MATERIAL["terms"]}
status, payload = post("/profile", {"material": MATERIAL, "max_entries": 10})
for e in payload["data"]["entries"]:
    check(f"词 '{e['term']}' 出自素材", e["term"] in vocab_terms, e["term"])

# ---------------------------------------------------------------- 六、隐私
print()
print("七、隐私红线：只处理、不存储（窗口/候选流/磁盘均不变）")
print("=" * 78)
after_window = relay.window_stats()
check("窗口消息数不变", after_window == before_window, f"{before_window} -> {after_window}")
after_candidates = call("/candidates", {"after": ["0"]})
# 只比**候选流本体**：`server_time` 是秒级时间戳，两次调用跨秒就会不等（测试抖动）
check("候选流不变",
      after_candidates.get("candidates") == before_candidates.get("candidates")
      and after_candidates.get("cursor") == before_candidates.get("cursor"),
      f"{len(before_candidates['candidates'])} -> {len(after_candidates['candidates'])}")
after_files = dir_snapshot()
check("**工作目录无新增文件**（不落盘）", after_files == before_files,
      f"新增 {sorted(set(after_files) - set(before_files))}")

# 素材里没有的内容，服务端也无从泄漏：响应体里不含任何句子形态的长串
blob = json.dumps(payload, ensure_ascii=False)
check("响应体里没有长句（素材本身就不含正文）", "\n" not in blob and len(blob) < 2000,
      str(len(blob)))

relay.STORE.forget_device(DEVICE)

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
