"""用真实 bot.db 数据回测 pipeline_proto.py，看它到底能不能用。

运行：.venv\\Scripts\\python.exe -X utf8 test_pipeline.py
"""

from __future__ import annotations

import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from pipeline_proto import (  # noqa: E402
    EVENT_CHAT,
    EVENT_IGNORE,
    EVENT_NOTICE,
    EVENT_PLAN,
    EVENT_TODO,
    build_event,
    cluster,
    normalize,
    parse_time,
)
from datetime import datetime  # noqa: E402

print("=" * 78)
print("一、预处理与噪声过滤（真实数据里 106 条有多少该被丢掉）")
print("=" * 78)

db = Path(__file__).resolve().parent / "bot.db"
conn = sqlite3.connect(db)
conn.row_factory = sqlite3.Row
rows = conn.execute(
    "SELECT sender_name, content, COALESCE(timestamp,created_at) t, msg_id "
    "FROM group_messages ORDER BY created_at"
).fetchall()
conn.close()

events = []
for r in rows:
    events.append(
        build_event(
            r["content"] or "",
            sender=r["sender_name"] or "",
            timestamp=r["t"] or "",
            msg_id=r["msg_id"] or "",
        )
    )

kinds: dict[str, int] = {}
for e in events:
    kinds[e.kind] = kinds.get(e.kind, 0) + 1
print(f"总消息 {len(events)} 条，分类结果：")
for k, v in sorted(kinds.items(), key=lambda kv: -kv[1]):
    print(f"   {k:6s} {v:4d} 条  ({v * 100 // len(events)}%)")
kept = len(events) - kinds.get(EVENT_IGNORE, 0)
print(f"\n→ 过滤掉噪声 {kinds.get(EVENT_IGNORE, 0)} 条，剩下 {kept} 条需要理解")

print()
print("=" * 78)
print("二、真正有信息的那几条，整理成了什么（这是给用户看的）")
print("=" * 78)

interesting = [e for e in events if e.kind in (EVENT_TODO, EVENT_NOTICE, EVENT_PLAN)]
for e in interesting:
    print(f"\n原话 : {e.source_text}")
    print(f"  [{e.kind}] 置信度 {e.confidence}")
    print(f"  一句话 : {e.one_line}")
    if e.time:
        print(f"  时间   : 原话={e.time.text!r} 归一化={e.time.normalized or '(未确定)'}"
              f" 待确认={e.time.unresolved}")
    print(f"  地点   : {e.place or '(未找到)'}")
    print(f"  人物   : {e.who or '(未找到)'}")
    print(f"  截止   : {e.deadline or '(未找到)'}")
    print(f"  标签   : {e.tags}")
    print(f"  ↳ 点开可回到原话：msg_id={e.msg_id[:24]}...")

print()
print("=" * 78)
print("三、事件聚合：把零散对话变成「一个事件」")
print("=" * 78)

for c in cluster(events):
    if c["kind"] == EVENT_CHAT and c["count"] < 2:
        continue
    span = c["span"]
    print(f"\n▸ 事件：{c['title']}  （{c['count']} 条消息，{c['kind']}）")
    print(f"  时间跨度：{span[0]} → {span[1]}")
    print(f"  涉及的人：{'、'.join(c['senders'])}")
    if c["tags"]:
        print(f"  标签    ：{c['tags']}")
    if c["one_line"]:
        print(f"  一句话  ：{c['one_line']}")

print()
print("=" * 78)
print("四、单点断言（防止回归）")
print("=" * 78)

FAILS = []


def check(label, cond, extra=""):
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


base = datetime(2026, 10, 12, 19, 53)

# 表情标记必须被归一化，否则前端看到的是乱码（ext 是真实数据里的一条）
check(
    "表情标记被解码",
    normalize('<faceType=4,faceId="",ext="eyJ0ZXh0IjoiW+WTh+Whnl0ifQ==">') == "[哇塞]",
    normalize('<faceType=4,faceId="",ext="eyJ0ZXh0IjoiW+WTh+Whnl0ifQ==">'),
)
check(
    "另一个表情也能解",
    normalize('<faceType=4,faceId="",ext="eyJ0ZXh0IjoiW+eVpeeVpeeVpV0ifQ==">') == "[略略略]",
    normalize('<faceType=4,faceId="",ext="eyJ0ZXh0IjoiW+eVpeeVpeeVpV0ifQ==">'),
)
check("纯数字是噪声", build_event("124124").kind == EVENT_IGNORE)
check("纯表情是噪声", build_event('<faceType=6,faceId="0",ext="eyJ0ZXh0IjoiIn0=">').kind == EVENT_IGNORE)
check("'ok' 是噪声", build_event("ok").kind == EVENT_IGNORE)
check("'bb' 是噪声", build_event("bb").kind == EVENT_IGNORE)

# 系统消息 / 拍一拍：不是人说的话，必须整体判为忽略（真实语料里占 4.8%）
for _t in ["熊永轩加入了群聊", "某某拍了拍你", "某人戳了戳你", "谁揉了揉你的头",
           "谁捏了捏你的脸", "你撤回了一条消息", "有人邀请小明加入了群聊"]:
    check(f"系统消息被忽略：{_t}", build_event(_t).kind == EVENT_IGNORE, build_event(_t).kind)
check("系统消息不是噪声反例（真实句子不受影响）",
      build_event("记得带准考证上学").kind != EVENT_IGNORE)

# 时间解析：该确定的确定，该留白的留白
s = parse_time("今天上午9点记得来教学楼上课", base)
check("今天上午9点 -> 当天", s and s.normalized == "2026-10-12 09:00", s and s.normalized)
s = parse_time("明天去超市买点吃的", base)
check("明天 -> 次日", s and s.normalized == "2026-10-13", s and s.normalized)
s = parse_time("后天先去火车站坐车", base)
check("后天 -> 第三天", s and s.normalized == "2026-10-14", s and s.normalized)
s = parse_time("下周三交作业", base)
check("下周三 -> 正确日期", s and s.normalized.startswith("2026-10-21"), s and s.normalized)
s = parse_time("下周交作业", base)
check("只写'下周'不猜日期", s and s.unresolved and s.normalized == "", s and s.display)
check("没写时间就不给时间", parse_time("去北京旅游", base) is None)

# 点分日期 vs 版本号（实测「版本1.2」曾被解析成 1 月 2 日，生成假截止时间）
s = parse_time("10.31 前交作业", base)
check("10.31 -> 点分日期", s and s.normalized == "2026-10-31", s and s.normalized)
check("版本1.2 不当日期", parse_time("版本1.2 已发布", base) is None,
      parse_time("版本1.2 已发布", base))
check("ver 2.0 不当日期", parse_time("升级到 ver 2.0", base) is None,
      parse_time("升级到 ver 2.0", base))
check("第1.2版 不当日期", parse_time("这是第1.2版", base) is None,
      parse_time("这是第1.2版", base))

# 「时」不能当时间分隔符：否则「一时/小时/同时/随时/暂时/何时」都会变成时间
from pipeline_proto import _find_clock  # noqa: E402

for _w in ["一时", "一小时", "同时", "随时", "暂时", "何时", "届时"]:
    check(f"『{_w}』不是时间", _find_clock(_w) is None, str(_find_clock(_w)))
for _w in ["地点", "有点", "一点", "特点", "重点", "早点", "快点"]:
    check(f"『{_w}』不是时间", _find_clock(_w) is None, str(_find_clock(_w)))
check("但『一点半』仍是时间", _find_clock("一点半") == ("一点半", 1, 30), str(_find_clock("一点半")))
check("『下午一点』仍是时间", _find_clock("下午一点") == ("下午一点", 13, 0), str(_find_clock("下午一点")))

# 中文数字时间：群聊里「下午两点」远比「14点」常见，不认中文数字会漏掉大量时间
from pipeline_proto import _find_clock  # noqa: E402

check("下午两点 -> 14 点", _find_clock("下午两点开打") == ("下午两点", 14, 0), _find_clock("下午两点开打"))
check("十一点 -> 11 点", _find_clock("十一点交作业") == ("十一点", 11, 0), _find_clock("十一点交作业"))
check("下午3点半 -> 15:30", _find_clock("下午3点半开会") == ("下午3点半", 15, 30), _find_clock("下午3点半开会"))
check("中午1点 -> 13 点", _find_clock("中午1点") == ("中午1点", 13, 0), _find_clock("中午1点"))
check("打3个小时 不是时间", _find_clock("打3个小时") is None, _find_clock("打3个小时"))
check("'几点' 不是时间", _find_clock("几点") is None, _find_clock("几点"))
s = parse_time("明天下午两点开打", base)
check("明天下午两点 -> 次日14:00", s and s.normalized == "2026-10-13 14:00", s and s.normalized)
s = parse_time("下午两点开打", base)
check("只有时刻不给日期", s is not None and s.normalized == "" and s.text == "下午两点", s and (s.text, s.normalized))

# 借 cn2an 做中文数字转换（软依赖）；缺失时要能回退，不能把服务带崩
import pipeline_proto as _pp  # noqa: E402

check("cn2an 已安装（生产环境）", _pp._cn2an is not None, str(_pp._cn2an))
check("9点30分 整段吃掉", _find_clock("9点30分到") == ("9点30分", 9, 30), _find_clock("9点30分到"))
check("晚上十点 -> 22 点", _find_clock("晚上十点") == ("晚上十点", 22, 0), _find_clock("晚上十点"))
check("下午两点半 -> 14:30", _find_clock("下午两点半") == ("下午两点半", 14, 30), _find_clock("下午两点半"))
check("廿 -> 20（cn2an 能力）", _pp._cn2int("廿") == 20, _pp._cn2int("廿"))

# 模拟没装 cn2an 的机器：内置兜底仍要认得出常见写法
_saved_cn2an = _pp._cn2an
_pp._cn2an = None
try:
    check("无 cn2an 时兜底：两点", _find_clock("下午两点") == ("下午两点", 14, 0), _find_clock("下午两点"))
    check("无 cn2an 时兜底：十一点", _find_clock("十一点") == ("十一点", 11, 0), _find_clock("十一点"))
    check("无 cn2an 时兜底：二十三分", _pp._cn2int_fallback("二十三") == 23, _pp._cn2int_fallback("二十三"))
finally:
    _pp._cn2an = _saved_cn2an

# 分类与槽位
e = build_event("今天上午9点记得来教学楼上课", "硫酸Cu", "2026-10-12T19:53:42+08:00", "m1", base)
check("记得...上课 -> 待办", e.kind == EVENT_TODO, e.kind)
check("地点抽到教学楼", e.place == "教学楼", e.place)
check("一句话包含时间与地点", "2026-10-12 09:00" in e.one_line and "教学楼" in e.one_line, e.one_line)

e = build_event("最近大学生职业规划大赛报名，有兴趣的同学可以参加", "硫酸Cu", "2026-10-12T20:03:24+08:00", "m2", base)
check("大赛报名 -> 通知", e.kind == EVENT_NOTICE, e.kind)
check("通知带标签", "竞赛" in e.tags or "报名" in e.tags, e.tags)

e = build_event("后天先去火车站坐车，再去北京旅游", "硫酸Cu", "2026-10-12T19:54:33+08:00", "m3", base)
check("坐车去旅游 -> 出行计划", e.kind == EVENT_PLAN, e.kind)

e = build_event("几点停电", "硫酸Cu", "2026-10-12T20:09:30+08:00", "m4", base)
check("疑问句 -> 闲聊（不生成待办）", e.kind == EVENT_CHAT, e.kind)
check("闲聊不给一句话", e.one_line == "", e.one_line)

e = build_event("最近那个比赛你们参加了吗", "硫酸Cu", "2026-10-12T20:08:54+08:00", "m5", base)
check("'参加了吗' 不被当成通知", e.kind == EVENT_CHAT, e.kind)

# 无来源结论是禁止的
e = build_event("明天去超市买点吃的", "硫酸Cu", "2026-10-12T19:54:03+08:00", "m6", base)
check("每条事件都带原话", e.source_text == "明天去超市买点吃的", e.source_text)
check("低置信度会提示人工确认", "请人工确认" in e.one_line or e.confidence >= 0.5, e.one_line)

# 群自学习的地点词表：通用正则认不出的校内地物，靠 extra_places 兜住
e = build_event("明天晚上康桥见", "硫酸Cu", "2026-10-12T19:53:42+08:00", "m_place", base)
check("无词表时：康桥 抽不出地点", e.place == "", e.place)
e = build_event("明天晚上康桥见", "硫酸Cu", "2026-10-12T19:53:42+08:00", "m_place2", base,
                extra_places=["康桥", "梧桐", "文治"])
check("有词表时：康桥 被抽为地点", e.place == "康桥", e.place)
e = build_event("在梧桐吃饭", "硫酸Cu", "2026-10-12T19:53:42+08:00", "m_place3", base,
                extra_places=["康桥", "梧桐"])
check("有词表时：梧桐 被抽为地点", e.place == "梧桐", e.place)
e = build_event("在康桥苑集合", "硫酸Cu", "2026-10-12T19:53:42+08:00", "m_place4", base,
                extra_places=["康桥"])
check("最长匹配：康桥苑 优先于 康桥", e.place == "康桥苑" or e.place == "康桥", e.place)
e = build_event("记得来教学楼上课", "硫酸Cu", "2026-10-12T19:53:42+08:00", "m_place5", base,
                extra_places=["康桥"])
check("词表不影响通用地点抽取", e.place == "教学楼", e.place)

# ---------------------------------------------------------------- 标题抽取（2026-10-17）
# 规则路径的标题按**分句**取，不再拿被中段裁剪过的 action（否则通知类会切成碎片）
for _text, _expect in [
    ("通知：本周五下午三点在A103开班会，请准时参加", "本周五下午三点在A103"),
    ("【重要通知】图书馆10月20日起闭馆改造", "图书馆10月20日起闭馆"),
    ("关于评选2026年优秀学生的通知", "评选2026年优秀学生"),
    ("明天下午两点开会", "明天下午两点开会"),
    ("记得明天下午两点在康桥苑开会", "明天下午两点在康桥苑开会"),
]:
    _t = _pp.extract_title(_text)
    check(f"标题按分句取：{_text[:14]}", _t.startswith(_expect), _t)
check("通知类标题不再是碎片（没有「重通知」）",
      "重通知" not in _pp.extract_title("【重要通知】图书馆10月20日起闭馆改造"),
      _pp.extract_title("【重要通知】图书馆10月20日起闭馆改造"))
check("标题不超过 12 字", len(_pp.extract_title("很长" * 30)) <= 12,
      len(_pp.extract_title("很长" * 30)))
check("长标题在标点处断开", _pp.clip_title("关于体质测试，请各班同学参加") == "关于体质测试",
      _pp.clip_title("关于体质测试，请各班同学参加"))
check("无标点时裁到 12 字", _pp.clip_title("关于组织2026年秋季学生体质健康测试") == "关于组织2026年秋季学",
      _pp.clip_title("关于组织2026年秋季学生体质健康测试"))
check("短标题原样返回", _pp.clip_title("开班会") == "开班会", _pp.clip_title("开班会"))
check("长标题去掉年份前缀", _pp.clip_title("2026年秋季学生体质健康测试") == "秋季学生体质健康测试",
      _pp.clip_title("2026年秋季学生体质健康测试"))
# 断点不许把常见词劈成单字（实测：…奖学金申请 -> …奖学金申）
check("不劈开「材料」", _pp.clip_title("关于国家励志奖学金申请材料的说明") == "关于国家励志奖学金申请",
      _pp.clip_title("关于国家励志奖学金申请材料的说明"))
check("不留下单字「申」",
      not _pp.clip_title("关于评选表彰优秀学生奖学金申请的通知").endswith("申"),
      _pp.clip_title("关于评选表彰优秀学生奖学金申请的通知"))
check("空文本 -> 空标题", _pp.extract_title("") == "", repr(_pp.extract_title("")))
# build_event 用的就是它（标题不再等于被裁剪的 action）
_e = build_event("【重要通知】图书馆10月20日起闭馆改造", "甲", "2026-10-12T19:53:42+08:00", "m_title1", base)
check("build_event 的 title 走分句抽取", _e.title.startswith("图书馆10月20日"), _e.title)

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
