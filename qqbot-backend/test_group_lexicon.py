# -*- coding: utf-8 -*-
"""group_lexicon.py 的自测：按群学词、自动归类、落盘不含正文、手动删词。

运行：.venv\\Scripts\\python.exe -X utf8 test_group_lexicon.py
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

_tmp_dir = Path(__file__).resolve().parent / "_tmp_test"
_tmp_dir.mkdir(parents=True, exist_ok=True)
_store_path = _tmp_dir / "group_lexicon_test.json"
if _store_path.exists():
    _store_path.unlink()
# 让全局 STORE 指向沙箱文件：llm_worker 读的也是同一个 STORE
os.environ["QQBOT_GROUP_LEXICON"] = str(_store_path)

import group_lexicon as GL  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


def msg(content: str) -> dict:
    return {"content": content, "sender": "甲", "group_openid": "GID", "timestamp": "2026-10-14 10:00:00"}


# ---------------------------------------------------------------- 学词 + 归类
print("=" * 78)
print("一、从群语料学出领域词，并按上下文自动归类")
print("=" * 78)

corpus = []
# 地点：康桥（左邻趋向动词 / 右邻"苑/见/食堂"）
# 注意同时包含句首与句中：真实语料里专名既会在句首，也会有多种左邻
for t in ["明天去康桥吃饭", "我在康桥等你", "到康桥了没", "康桥苑今天开门", "晚上康桥见",
          "一起康桥吃饭吧", "路过康桥拍一张", "从康桥走回宿舍", "先去康桥再去梧桐", "康桥食堂几点开",
          "康桥那边人多吗", "我康桥的朋友说的", "说是康桥要修路", "这会儿康桥开门没",
          "康桥门口等你"] * 3:
    corpus.append(msg(t))
# 组织：挑战网
for t in ["挑战网招新了", "挑战网社团报名", "加入挑战网社团", "挑战网的报名表",
          "想进挑战网", "挑战网部门介绍", "挑战网欢迎新生", "挑战网是啥组织",
          "听说挑战网很牛", "我挑战网的学长", "要不加挑战网", "挑战网那边怎么说"] * 3:
    corpus.append(msg(t))
# 通用词：高频但无地点/组织上下文 —— 必须被排除
for t in ["这个可以有的啦", "可以可以随便吧", "或者这样也行", "已经好了", "老师说了什么"] * 20:
    corpus.append(msg(t))
# 系统消息 —— 不应贡献任何词
for t in ["某某加入了群聊", "熊永轩拍了拍你", "某人戳了戳你", "谁揉了揉你的头"] * 10:
    corpus.append(msg(t))

terms = GL.learn_group_terms(corpus)
print("  学到:", json.dumps({k: (v["cat"], v["count"]) for k, v in terms.items()}, ensure_ascii=False))

check("学到「康桥」", "康桥" in terms, str(list(terms)[:10]))
check("康桥 归为 place", terms.get("康桥", {}).get("cat") == "place", terms.get("康桥"))
check("学到「挑战网」", "挑战网" in terms, str(list(terms)[:10]))
check("挑战网 归为 org", terms.get("挑战网", {}).get("cat") == "org", terms.get("挑战网"))
check("通用词「可以」被排除", "可以" not in terms)
check("通用词「或者」被排除", "或者" not in terms)
check("通用词「已经」被排除", "已经" not in terms)
check("系统消息不贡献词", not any("拍了拍" in w or "戳了戳" in w for w in terms))

# ---------------------------------------------------------------- 落盘（只存词）
print()
print("=" * 78)
print("二、落盘内容只有词与计数，绝不含聊天正文")
print("=" * 78)

store = GL.STORE   # 与 llm_worker 共用同一个（沙箱）STORE
added = store.merge("GID_15B451", terms)
check("merge 返回新增词数 > 0", added > 0, str(added))
check("再次 merge 不重复计数", store.merge("GID_15B451", terms) == 0)

raw = _store_path.read_text(encoding="utf-8")
check("落盘文件存在且非空", len(raw) > 10)
check("落盘不含正文原句", "明天去康桥吃饭" not in raw and "挑战网招新了" not in raw)
check("落盘含词", "康桥" in raw and "挑战网" in raw)
data = json.loads(raw)
check("结构为 groups -> 词 -> {count,cat}", data["groups"]["GID_15B451"]["康桥"]["cat"] == "place")

check("按类别取词", "康桥" in store.words_of_category("GID_15B451", "place"))
check("未学的群返回空", store.terms("GID_NOPE") == {})

# ---------------------------------------------------------------- 多群隔离
print()
print("=" * 78)
print("三、词表按群隔离；手动删词；一键清除")
print("=" * 78)

other = []
for t in ["紫荆食堂好吃", "去紫荆吃饭", "紫荆门口集合", "在紫荆等你", "从紫荆走过去",
          "紫荆那边有超市", "紫荆广场见", "想去紫荆逛逛"] * 4:
    other.append(msg(t))
store.merge("GID_OTHER", GL.learn_group_terms(other))
check("别的群学到自己的词", "紫荆" in store.words_of_category("GID_OTHER", "place"), str(store.terms("GID_OTHER")))
check("A 群看不到 B 群的词", "紫荆" not in store.terms("GID_15B451"))
check("B 群看不到 A 群的词", "康桥" not in store.terms("GID_OTHER"))

check("手动删词成功", store.drop("GID_15B451", "康桥") is True)
check("删后不再有该词", "康桥" not in store.terms("GID_15B451"))
check("删不存在的词返回 False", store.drop("GID_15B451", "不存在") is False)

store.forget("GID_15B451")
check("一键清除后该群词表为空", store.terms("GID_15B451") == {})
check("清除不影响别的群", "紫荆" in store.words_of_category("GID_OTHER", "place"))

st = store.stats()
check("stats 统计群数与词数", st["groups"] == 1 and st["terms"] >= 1, str(st))

# ---------------------------------------------------------------- 接进地点抽取
print()
print("=" * 78)
print("四、学到的地点词表接进抽取链路（llm_worker）")
print("=" * 78)

import llm_parse  # noqa: E402
llm_parse.available = lambda: False  # 走规则路径
import llm_worker  # noqa: E402

GID_BIG = "GID_PLACE"
store.merge(GID_BIG, GL.learn_group_terms(corpus))   # 康桥 已学为 place
check("该群词表里有 康桥", "康桥" in store.words_of_category(GID_BIG, "place"))

payload = {
    "group_openid": GID_BIG,
    "sender": "甲",
    "content": "记得明天晚上康桥见",
    "timestamp": "2026-10-14 10:00:00",
    "msg_id": "pm1",
}
parsed = llm_worker._rules_parse(payload)
check("「记得明天晚上康桥见」抽出 place=康桥", parsed.get("place") == "康桥", str(parsed.get("place")))
check("时间也抽到了", parsed.get("timeNormalized") == "2026-10-15", str(parsed.get("timeNormalized")))
check("summary 提到康桥", "康桥" in (parsed.get("summary") or ""), parsed.get("summary"))

# 纯闲聊句（无任务词）不给 summary，但**地点照样抽到**——这正是词表的价值
chat = dict(payload, content="明天晚上康桥见")
parsed_chat = llm_worker._rules_parse(chat)
check("闲聊句也抽到 place=康桥", parsed_chat.get("place") == "康桥", str(parsed_chat.get("place")))
check("闲聊句按设计不给 summary", (parsed_chat.get("summary") or "") == "", repr(parsed_chat.get("summary")))

# 别的群没学过 -> 抽不出（隔离）
payload_other = dict(payload, group_openid="GID_NOLEX")
parsed_other = llm_worker._rules_parse(payload_other)
check("未学过的群抽不出 康桥", parsed_other.get("place") == "", str(parsed_other.get("place")))

# 通用地点不受词表影响
payload_generic = dict(payload, content="记得来教学楼上课")
check("通用地点仍正常", llm_worker._rules_parse(payload_generic).get("place") == "教学楼")

# ---------------------------------------------------------------- 在线增量学习
print()
print("=" * 78)
print("五、在线增量学习（learn_from_window）")
print("=" * 78)

window = []
for t in ["明天去康桥吃饭", "康桥苑今天开门", "康桥食堂几点开", "康桥门口等你", "我去康桥"] * 8:
    window.append({"group_openid": "GID_ONLINE", "content": t, "sender": "甲"})
# 另一个群，消息太少 -> 不该学（低于 min_messages）
window.append({"group_openid": "GID_TINY", "content": "紫荆食堂好吃", "sender": "乙"})

added = GL.learn_from_window(window, store=store, min_messages=20)
check("在线学习返回该群新增词数", added.get("GID_ONLINE", 0) >= 1, str(added))
check("学到的词进了词表", "康桥" in store.words_of_category("GID_ONLINE", "place"))
check("消息太少的群不学", "GID_TINY" not in added)

# 重复学习不应无限增长
added2 = GL.learn_from_window(window, store=store, min_messages=20)
check("重复学习不重复计数", added2.get("GID_ONLINE", 0) == 0, str(added2))

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
