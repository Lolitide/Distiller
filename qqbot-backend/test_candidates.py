# -*- coding: utf-8 -*-
"""candidate_engine.py 的自测：去重 + 聚类 + 综合总结 + 游标 upsert。

运行：.venv\\Scripts\\python.exe -X utf8 test_candidates.py

测试强制走**规则**路径（patch 掉 llm_parse.available），保证确定性；
模型可用时的路径由 llm_worker 的端到端测试覆盖。
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import llm_parse  # noqa: E402
import candidate_engine as CE  # noqa: E402

llm_parse.available = lambda: False  # 强制规则路径（不依赖 Ollama）

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


GID = "15B451ACFDB0816E3233D1947DEAC820"
LABEL = "HMOS 知了APP开发"


def msg(content: str, ts: str, mid: str, gid: str = GID, sender: str = "硫酸Cu") -> dict:
    return {
        "group_openid": gid,
        "group_label": LABEL,
        "sender": sender,
        "content": content,
        "timestamp": ts,
        "msg_id": mid,
    }


# ============================================================ ① 聚类（联合上下文）
print("=" * 78)
print("一、聚类：把「传智杯」三条零散对话合成**一条**候选")
print("=" * 78)

thread_msgs = [
    msg("比赛是定在后天", "2026-10-13 23:07:36", "dev_230736"),
    msg("啥比赛", "2026-10-13 23:07:48", "dev_230754", sender="Oliver"),
    msg("传智杯", "2026-10-13 23:07:58", "dev_230758", sender="Oliver"),
]
cands = CE.build_candidates(thread_msgs)
check("三条消息 -> 一条候选", len(cands) == 1, str(len(cands)))
c0 = cands[0] if cands else {}
check("聚类后 kind 不是闲聊", c0.get("kind") in ("待办", "通知", "活动", "出行计划"), c0.get("kind"))
check("source.count = 3", c0.get("source", {}).get("count") == 3, str(c0.get("source", {}).get("count")))
check(
    "source.msg_ids 收齐 3 条",
    c0.get("source", {}).get("msg_ids") == ["dev_230736", "dev_230754", "dev_230758"],
    str(c0.get("source", {}).get("msg_ids")),
)
check("涉及 2 个发送者", c0.get("source", {}).get("senders") == ["硫酸Cu", "Oliver"], str(c0.get("source", {}).get("senders")))
check("时间归一化：后天 -> 2026-10-15", c0.get("time_normalized") == "2026-10-15", c0.get("time_normalized"))
check("time_text 保留原话", c0.get("time_text") == "后天", c0.get("time_text"))
check("priority 在枚举内", c0.get("priority") in CE._PRIORITIES, c0.get("priority"))
check("candidate_id 形如 c_xxxxxx", str(c0.get("candidate_id", "")).startswith("c_") and len(c0.get("candidate_id", "")) == 8, c0.get("candidate_id"))
check("thread_id 以群尾号打头", str(c0.get("thread_id", "")).startswith("t_15B451_"), c0.get("thread_id"))
check("steps 是列表", isinstance(c0.get("steps"), list))
check("summary 非空", bool(c0.get("summary")))

# ---- 卡片字段（《任务字段表&idea更新》v1）----
check("level 在 0/1/2", c0.get("level") in (0, 1, 2), c0.get("level"))
check("category 是预设值", c0.get("category") in ("作业", "考试", "活动", "通知", "其他"),
      c0.get("category"))
check("channel = bot", c0.get("channel") == "bot", c0.get("channel"))
check("due_at 是毫秒时间戳",
      isinstance(c0.get("due_at"), int) and c0.get("due_at") > 1_600_000_000_000,
      c0.get("due_at"))
check("due_text 与 time_text 同一原话", c0.get("due_text") == c0.get("time_text"),
      f"{c0.get('due_text')} / {c0.get('time_text')}")
check("repeat 是规则数组", isinstance(c0.get("repeat"), list), str(c0.get("repeat")))
check("repeat_text 是字符串", isinstance(c0.get("repeat_text"), str), str(c0.get("repeat_text")))
check("certainty = confidence*100 取整",
      c0.get("certainty") == int(round(c0.get("confidence", 0) * 100)),
      f"{c0.get('certainty')} vs {c0.get('confidence')}")
check("missing_fields 是列表且只含三个合法名",
      isinstance(c0.get("missing_fields"), list)
      and set(c0.get("missing_fields")) <= {"place", "who", "dueAt"},
      str(c0.get("missing_fields")))
check("steps 元素形如 {content, done}", all(
    isinstance(s, dict) and "content" in s and s.get("done") in (0, 1)
    for s in (c0.get("steps") or [])
), str(c0.get("steps")))

# 不相关消息不应被聚到一起
print()
print("二、不该聚的错误：同群、30 分钟内但话题无关 -> 两条候选")
other = [
    msg("明天去超市买点吃的", "2026-10-13 20:00:00", "m_a"),
    msg("周五前交实验报告", "2026-10-13 20:05:00", "m_b"),
]
two = CE.build_candidates(other)
check("无关消息 -> 两条候选", len(two) == 2, str(len(two)))

# ============================================================ ② 去重
print()
print("三、去重：同群 10 分钟内完全重复 -> 只留一条候选")
dup = [
    msg("会议室改到A203", "2026-10-13 21:00:00", "d1"),
    msg("会议室改到A203", "2026-10-13 21:00:30", "d2"),
    msg("会议室改到A203", "2026-10-13 21:05:00", "d3"),
]
dups = CE.build_candidates(dup)
check("完全重复去重后只剩一条候选", len(dups) == 1, str(len(dups)))
check("去重后 count 仍统计原始条数", dups[0]["source"]["count"] == 3, str(dups[0]["source"]["count"]))
check("去重后 msg_ids 全保留", dups[0]["source"]["msg_ids"] == ["d1", "d2", "d3"], str(dups[0]["source"]["msg_ids"]))

# 噪声不进候选
print()
print("四、噪声（纯数字/表情/寒暄）不产生候选")
noise = [
    msg("124124", "2026-10-13 22:00:00", "n1"),
    msg("ok", "2026-10-13 22:00:10", "n2"),
    msg('<faceType=6,faceId="0",ext="">', "2026-10-13 22:00:20", "n3"),
]
check("噪声 -> 0 条候选", CE.build_candidates(noise) == [], str(len(CE.build_candidates(noise))))

# ============================================================ ③ 游标 upsert
print()
print("五、游标：候选被后续消息更新 -> 同 candidate_id、更大 rev_seq")
stream = CE.CandidateStream()
first = stream.rebuild(thread_msgs)
check("首轮下发 1 条", len(first) == 1, str(len(first)))
r1 = first[0]["rev_seq"]
check("首个 rev_seq > 0", r1 > 0, str(r1))

# 内容没变 -> 不重复下发
again = stream.rebuild(thread_msgs)
check("内容没变不重复下发", again == [], str(len(again)))

# 追加一条相关消息 -> 同 id、rev_seq 变大、count 变 4
thread_msgs2 = thread_msgs + [msg("传智杯是大学生比赛", "2026-10-13 23:08:30", "dev_230790", sender="Oliver")]
updated = stream.rebuild(thread_msgs2)
check("更新后下发 1 条", len(updated) == 1, str(len(updated)))
check("candidate_id 保持不变", updated[0]["candidate_id"] == first[0]["candidate_id"])
check("rev_seq 变大", updated[0]["rev_seq"] > r1, f"{r1} -> {updated[0]['rev_seq']}")
check("count 变为 4", updated[0]["source"]["count"] == 4, str(updated[0]["source"]["count"]))

snap = stream.since(0, 100)
check("since(0) 返回全部（按 id upsert 后的最新态）", len(snap["candidates"]) == 1, str(len(snap["candidates"])))
check("cursor = 最新 rev_seq", snap["cursor"] == updated[0]["rev_seq"], str(snap["cursor"]))
snap2 = stream.since(snap["cursor"], 100)
check("游标跑到底后无新增", snap2["candidates"] == [] and snap2["cursor"] == snap["cursor"])

# ---- 轮询闸：窗口没变就不再重算（防 rev_seq 无谓抖动 / 多设备看到不一致）----
print()
print("五·补、轮询闸：同一份窗口连续 rebuild 只算一次")
sig_msgs = [msg("周五下午三点开班会", "2026-10-13 22:00:00", "s1")]
stream2 = CE.CandidateStream()
first = stream2.rebuild(sig_msgs)
check("首次 rebuild 产出 1 条", len(first) == 1, str(len(first)))
again = stream2.rebuild(sig_msgs)
check("窗口没变 -> 返回空（不重算）", again == [], str(again))
check("cursor 不动", stream2.cursor == first[0]["rev_seq"],
      f"{stream2.cursor} vs {first[0]['rev_seq']}")
more = sig_msgs + [msg("周五下午三点开班会", "2026-10-13 22:01:00", "s2")]
third = stream2.rebuild(more)
check("窗口变了 -> 才重算", len(third) == 1, str(len(third)))
check("重算后 rev_seq 变大", third[0]["rev_seq"] > first[0]["rev_seq"],
      f"{first[0]['rev_seq']} -> {third[0]['rev_seq']}")
check("created_at 沿用首次的值", third[0]["created_at"] == first[0]["created_at"],
      f"{first[0]['created_at']} vs {third[0]['created_at']}")

# 指纹必须对「单条 parse 变了」敏感（模型重解析后要能触发重算）
changed_parse = [dict(sig_msgs[0])]
changed_parse[0]["parse"] = {"kind": "待办", "title": "换了个标题", "summary": "换了个标题",
                             "timeText": "", "timeNormalized": "", "place": "", "who": "",
                             "deadline": "", "items": [], "tags": [], "confidence": 0.5}
check("parse 变化会改变窗口指纹",
      CE._source_signature(sig_msgs) != CE._source_signature(changed_parse))

# ============================================================ ④ 字段契约
print()
print("六、候选字段齐备（对齐 04_API契约_v2_草案.md §5.2）")
required = {
    "candidate_id", "rev_seq", "thread_id", "kind", "priority", "title", "summary",
    "time_text", "time_normalized", "time_unresolved", "place", "who", "deadline",
    "items", "steps", "tags", "confidence", "engine", "source", "created_at",
    # 卡片字段（《任务字段表》v1）
    "level", "category", "channel", "due_at", "due_text", "repeat", "repeat_text",
    "certainty", "missing_fields",
}
missing = required - set(c0.keys())
check("候选字段无缺失", not missing, str(missing))
src_required = {"group_openid", "group_label", "senders", "msg_ids", "count", "first_ts", "last_ts"}
check("source 字段无缺失", not (src_required - set(c0.get("source", {}).keys())), str(src_required - set(c0.get("source", {}).keys())))

# ============================================================ ⑦ 同群硬约束
print()
print("七、聚类必须同群：跨群消息无论多像都不能合成一个候选")
GID2 = "AAAA1111BBBB2222CCCC3333DDDD4444"

# 7.1 两个群、文本完全相同、同一时刻 -> 各自一条候选（去重也不能跨群合并）
cross = [
    msg("会议室改到A203", "2026-10-13 23:30:00", "x1", gid=GID),
    msg("会议室改到A203", "2026-10-13 23:30:05", "x2", gid=GID2),
]
xc = CE.build_candidates(cross)
check("跨群同文 -> 两条候选（不合并）", len(xc) == 2, str(len(xc)))
check("两条候选分属不同群", {c["source"]["group_openid"] for c in xc} == {GID, GID2},
      str({c["source"]["group_openid"] for c in xc}))
check("跨群不共享 candidate_id", xc[0]["candidate_id"] != xc[1]["candidate_id"])

# 7.2 两个群共享关键词、间隔很近 -> 仍然各自一条
shared_kw = [
    msg("传智杯比赛报名截止", "2026-10-13 23:40:00", "y1", gid=GID),
    msg("传智杯比赛开始啦", "2026-10-13 23:40:30", "y2", gid=GID2),
]
sk = CE.build_candidates(shared_kw)
check("跨群共享关键词 -> 两条候选", len(sk) == 2, str(len(sk)))

# 7.3 指代关联不跨群：A 群问句、B 群应答 -> 应答不得并入 A 群
anaphora_cross = [
    msg("比赛是定在后天", "2026-10-13 23:50:00", "z1", gid=GID),
    msg("啥比赛", "2026-10-13 23:50:10", "z2", gid=GID),
    msg("传智杯", "2026-10-13 23:50:20", "z3", gid=GID2),
]
ac = CE.build_candidates(anaphora_cross)
check("跨群应答 -> 分成两条候选", len(ac) == 2, str(len(ac)))
grouped = {c["source"]["group_openid"]: c for c in ac}
check("A 群候选只含 A 群消息",
      grouped[GID]["source"]["msg_ids"] == ["z1", "z2"], str(grouped[GID]["source"]["msg_ids"]))
check("B 群候选只含 B 群消息",
      grouped[GID2]["source"]["msg_ids"] == ["z3"], str(grouped[GID2]["source"]["msg_ids"]))

# 7.4 多群交错时，同群的「问句 + 紧邻回答」仍要能聚上
interleaved = [
    msg("比赛是定在后天", "2026-10-13 23:55:00", "w1", gid=GID),
    msg("啥比赛", "2026-10-13 23:55:10", "w2", gid=GID),
    msg("另一个群的闲聊啊", "2026-10-13 23:55:20", "w3", gid=GID2),
    msg("传智杯", "2026-10-13 23:55:30", "w4", gid=GID),
]
il = CE.build_candidates(interleaved)
check("交错场景 -> 两条候选", len(il) == 2, str(len(il)))
ilg = {c["source"]["group_openid"]: c for c in il}
check("交错下 A 群三条仍聚成一簇",
      ilg[GID]["source"]["msg_ids"] == ["w1", "w2", "w4"], str(ilg[GID]["source"]["msg_ids"]))

# ============================================================ ⑧ 跨消息时间拼合
print()
print("八、时间拼合：一条给「明天」、另一条给「下午两点」-> 合成具体时刻")
fusion = [
    msg("明天是不是有比赛啊", "2026-10-14 09:14:01", "g1"),
    msg("传智杯", "2026-10-14 09:14:22", "g2"),
    msg("下午两点开打", "2026-10-14 09:15:21", "g3"),
]
f = CE.build_candidates(fusion)
check("三条聚成一条", len(f) == 1, str(len(f)))
check("日期 × 时刻已拼合", f and f[0]["time_normalized"] == "2026-10-15 14:00",
      f and f[0]["time_normalized"])
check("time_text 保留两段原话", f and f[0]["time_text"] == "明天下午两点", f and f[0]["time_text"])

# 黑话表必须进了两套 prompt（否则「开打」又会被理解成「打架」）
check("单条 prompt 含「开打」黑话", "开打" in llm_parse.SYSTEM)
check("簇级 prompt 含「开打」黑话", "开打" in llm_parse.THREAD_SYSTEM)

# ============================================================ ⑨ 不该因「通用标签」合并
print()
print("九、同类但无关的两条正式通知不能并成一条（通用标签泄漏）")
mixed = [
    msg("蓝桥杯比赛", "2026-10-14 17:48:49", "m1"),
    msg("啥时候的事", "2026-10-14 17:49:05", "m2"),
    msg("12月11号", "2026-10-14 17:49:27", "m3"),
    msg("各位同学：2025—2026学年奖学金评定工作已基本结束，相关获奖名单现公布在群内。"
        "首先，向获得各类奖学金的同学表示祝贺！希望大家珍惜荣誉、再接再厉。",
        "2026-10-14 17:50:40", "m4"),
]
mk = CE.build_candidates(mixed)
check("蓝桥杯 + 长通知 -> 两条候选", len(mk) == 2, str(len(mk)))
comp = [c for c in mk if "蓝桥杯" in (c["title"] + c["summary"])]
check("蓝桥杯那条拿到了时间", bool(comp) and comp[0]["time_normalized"] == "2026-12-11",
      comp[0]["time_normalized"] if comp else "无")
check("长通知没被吸进蓝桥杯簇", bool(comp) and comp[0]["source"]["count"] == 3,
      str(comp[0]["source"]["count"]) if comp else "")

# ============================================================ ⑩ 模型 summary 的保留策略
print()
print("十、模型的 summary 只在**真的复述编造值**时才丢弃")
_llm = CE.llm_parse
_real_extract = _llm.extract_thread
_real_available = _llm.available
try:
    _llm.available = lambda: True

    def _stub_ok(texts):
        # 模型只把 place 写错了（被安全闸清空），但 summary 里**没提**那个编造值
        return {
            "kind": "通知", "title": "本周五下午三点在A103开班会",
            "summary": "本周五下午三点在A103开班会，请准时参加。",
            "time_text": "本周五下午三点", "place": "", "who": "", "deadline": "",
            "items": [], "tags": [],
            "_nullified": ["place"], "_nullified_values": {"place": "五楼会议室"},
        }

    _llm.extract_thread = _stub_ok
    CE._LLM_CACHE.clear()
    c_ok = CE.build_candidates(
        [msg("本周五下午三点在A103开班会，请准时参加", "2026-10-13 22:00:00", "sum1")]
    )[0]
    check("槽位被清空但 summary 没复述 -> 保留模型 summary",
          c_ok["summary"] == "本周五下午三点在A103开班会，请准时参加。", c_ok["summary"])
    check("engine 仍是 llm", c_ok["engine"] == "llm", c_ok["engine"])

    def _stub_leak(texts):
        # 这次模型把编造的地点写进了 summary -> 必须丢弃，回退规则
        return {
            "kind": "通知", "title": "本周五下午三点在A103开班会",
            "summary": "地点在五楼会议室。",
            "time_text": "", "place": "", "who": "", "deadline": "",
            "items": [], "tags": [],
            "_nullified": ["place"], "_nullified_values": {"place": "五楼会议室"},
        }

    _llm.extract_thread = _stub_leak
    CE._LLM_CACHE.clear()
    c_leak = CE.build_candidates(
        [msg("本周五下午三点在A103开班会", "2026-10-13 22:00:00", "sum2")]
    )[0]
    check("summary 复述了编造值 -> 回退规则（不含该值）",
          "五楼会议室" not in c_leak["summary"], c_leak["summary"])
finally:
    _llm.extract_thread = _real_extract
    _llm.available = _real_available
    CE._LLM_CACHE.clear()

# ============================================================ ⑪ repeat 规则数组
print()
print("十一、repeat 规则数组（《任务字段表》§1.1，字段名对齐 calendarManager.RecurrenceRule）")
from card_fields import repeat_rules_of  # noqa: E402

rep_cases = [
    ("每周一、周二、周四要写高数作业", [{"frequency": 2, "daysOfWeek": [1, 2, 4]}]),
    ("每两周的周二", [{"frequency": 2, "interval": 2, "daysOfWeek": [2]}]),
    ("每3天", [{"frequency": 3, "interval": 3}]),
    ("每月15号交房租", [{"frequency": 1, "daysOfMonth": [15]}]),
    ("每年3月", [{"frequency": 0, "monthsOfYear": [3]}]),
    ("每天背单词", [{"frequency": 3}]),
]
for _text, _expect in rep_cases:
    _rules, _text_extra = repeat_rules_of(_text)
    check(f"repeat 解析：{_text}", _rules == _expect and _text_extra == "",
          f"{_rules} / {_text_extra!r}")

_rules, _ = repeat_rules_of("每月15号并且每周一")
check("同一任务可有两条规则（并集）", len(_rules) == 2, str(_rules))
check("两条规则的 frequency 分别是 WEEKLY/MONTHLY",
      sorted(r["frequency"] for r in _rules) == [1, 2], str(_rules))

# §1.1.3：表达不了的周期移出 MVP —— 不造规则，只留原话
for _text, _phrase in [("每个工作日打卡", "工作日"), ("每月最后一天交小组汇报", "每月最后一天")]:
    _rules, _extra = repeat_rules_of(_text)
    check(f"不进 MVP 的周期不造规则：{_text}", _rules == [] and _extra == _phrase,
          f"{_rules} / {_extra!r}")

check("没有周期 -> 空数组 + 空原话", repeat_rules_of("明天开会") == ([], ""))
# 字段名必须与官方 RecurrenceRule 同名（零翻译给日历）
check("规则字段名与官方同名",
      set(rep_cases[0][1][0].keys()) <= {"frequency", "interval", "daysOfWeek",
                                         "daysOfMonth", "monthsOfYear", "weeksOfMonth",
                                         "count", "expire", "dates"},
      str(rep_cases[0][1][0].keys()))

# ---------------------------------------------------------------- 跨簇去重
print()
print("十二、跨簇去重：同群同时间同地点同标题只留一条")
print("=" * 78)


def _cand(cid: str, title: str, place: str, t: str, count: int, conf: float = 0.8) -> dict:
    return {
        "candidate_id": cid, "title": title, "place": place, "time_normalized": t,
        "confidence": conf, "summary": title,
        "source": {"group_openid": "G1", "count": count},
    }


_dup = CE._dedupe_candidates([
    _cand("c1", "开班会", "教学楼", "2026-10-20", 1),
    _cand("c2", "开班会", "教学楼", "2026-10-20", 3),   # 来源更多 -> 保留它
])
check("重复只留一条", len(_dup) == 1, str([c["candidate_id"] for c in _dup]))
check("保留信息量更大的那条", _dup and _dup[0]["candidate_id"] == "c2",
      _dup and _dup[0]["candidate_id"])

_same_title_diff_day = CE._dedupe_candidates([
    _cand("d1", "开班会", "教学楼", "2026-10-20", 1),
    _cand("d2", "开班会", "教学楼", "2026-10-27", 1),
])
check("时间不同不合并", len(_same_title_diff_day) == 2,
      str(len(_same_title_diff_day)))

_diff_group = CE._dedupe_candidates([
    _cand("g1", "开班会", "教学楼", "2026-10-20", 1),
    {**_cand("g2", "开班会", "教学楼", "2026-10-20", 1),
     "source": {"group_openid": "G2", "count": 1}},
])
check("不同群不合并", len(_diff_group) == 2, str(len(_diff_group)))

_no_title = CE._dedupe_candidates([
    {"candidate_id": "n1", "title": "", "place": "", "time_normalized": "",
     "source": {"group_openid": "G1"}},
    {"candidate_id": "n2", "title": "", "place": "", "time_normalized": "",
     "source": {"group_openid": "G1"}},
])
check("没标题没地点不合并（没法判断）", len(_no_title) == 2, str(len(_no_title)))

print()
print("十三、同群两条无关通知不能被并成一条（体质测试 vs 积极分子）")
print("=" * 78)
_notice_a = msg(
    "关于2026年秋季学生体质健康测试的通知，请各班同学于10月25日前完成测试，地点在体育馆",
    "2026-10-20 10:00:00", "n_body_a")
_notice_b = msg(
    "关于确定第62期入党积极分子名单的通知，请各班同学于10月20日前确认信息，名单见附件",
    "2026-10-20 10:06:00", "n_body_b")
_split = CE.build_candidates([_notice_a, _notice_b])
check("两条不相干通知 -> 两条候选", len(_split) == 2,
      str([(c["title"], c["candidate_id"]) for c in _split]))
check("两条的标题不同", len(_split) == 2 and _split[0]["title"] != _split[1]["title"],
      str([c["title"] for c in _split]))
check("标题都不超过 12 字", all(len(c["title"]) <= 12 for c in _split),
      str([(c["title"], len(c["title"])) for c in _split]))

_merged_same = CE._dedupe_candidates([
    _cand("t1", "体质测试通知", "体育馆", "2026-10-25", 1),
    _cand("t2", "学生体质测试", "体育馆", "2026-10-25", 2),
])
check("标题相近的同一事件 -> 合并", len(_merged_same) == 1,
      str([c["candidate_id"] for c in _merged_same]))
check("合并保留信息量更大的", _merged_same and _merged_same[0]["candidate_id"] == "t2",
      _merged_same and _merged_same[0]["candidate_id"])

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
