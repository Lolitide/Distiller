# -*- coding: utf-8 -*-
"""卡片字段（《任务字段表&idea更新》v1，2026-10-16）—— 纯规则、无 IO、不落盘。

为什么单开一个模块：**两条链路都要用同一套结果**——
  * 候选流：`candidate_engine._build_candidate` 产出候选卡片；
  * 消息级解析：`llm_worker._to_payload` 产出下发给 App 的 `parse`。
如果各算各的，同一件事在「待办页」和「详情页」上显示的
重要性 / 截止 / 重复 / 步骤就会不一致。

**不能放在 `candidate_engine` 里**：它 `import llm_worker`，
而 `llm_worker` 也要用这些函数——放那儿就是循环导入。

明确**不在这里产**的两个字段 —— 它们是用户意图，只属于端侧：
  `alarm`（要不要提醒）、`remindAt`（按设置页「提醒提前量」从 dueAt 算）。
"""

from __future__ import annotations

import re
from datetime import datetime
from typing import Any

import pipeline_proto as RULES

# 与 candidate_engine 的 priority 枚举一致（urgent/high/normal/later）。
# App 的映射层把它换算成 Task.priority 的 0 普通 / 1 重要 / 2 紧急。
PRIORITIES: tuple[str, ...] = ("urgent", "high", "normal", "later")

# 难易程度：0 易 / 1 中 / 2 难
LEVELS: tuple[int, ...] = (0, 1, 2)

# ---------------------------------------------------------------- 重复规则
#
# 2026-10-17 字段表把 `repeat` 从「字符串枚举」改成**规则数组**：
# 元素字段名与官方 `calendarManager.RecurrenceRule` **逐字段同名**，
# 这样「把任务变成日历日程」那一步零翻译（字段表 §1.1.1）。
#
# MVP 支持：每天 / 每 N 天 / 每周某几天 / 每 N 周 / 每月某号 / 每年某月 / 多条并存。
# **不产出**（字段表 §1.1.3 明确移出 MVP）：每月最后一天、仅工作日、调休 ——
# 这三类只把原话放进 `repeat_text`，不生成规则。

FREQ_YEARLY = 0
FREQ_MONTHLY = 1
FREQ_WEEKLY = 2
FREQ_DAILY = 3

FREQUENCIES: tuple[int, ...] = (FREQ_YEARLY, FREQ_MONTHLY, FREQ_WEEKLY, FREQ_DAILY)

_CN_DIGITS = {"一": 1, "二": 2, "两": 2, "三": 3, "四": 4,
              "五": 5, "六": 6, "七": 7, "八": 8, "九": 9}
_WEEKDAY_OF = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "日": 7, "天": 7}

_RE_DAILY = re.compile(r"每(?:隔)?([一二两三四五六七八九十\d]+)?\s*(?:天|日)")
_RE_WEEKLY = re.compile(r"每(?:隔)?([一二两三四五六七八九十\d]+)?\s*(?:周|星期|礼拜)")
# 周几序列：每周一三五 / 每周一、三、五 / 周一、二
_RE_WEEKDAYS = re.compile(
    r"(?:周|星期|礼拜)([一二三四五六日天](?:[、,和及\s]*[一二三四五六日天])*)"
)
_RE_MONTHLY = re.compile(
    r"每(?:隔)?([一二两三四五六七八九十\d]+)?\s*(?:个)?月(?:的)?\s*"
    r"([一二三四五六七八九十\d]{1,2})\s*[日号]"
)
_RE_YEARLY = re.compile(
    r"每(?:隔)?([一二两三四五六七八九十\d]+)?\s*年(?:的)?\s*"
    r"([一二两三四五六七八九十\d]{1,2})\s*月"
)
# 能认出周期、但规则表达不了 —— 只留原话（字段表 §1.1.3）
_RE_UNEXPRESSIBLE = re.compile(r"工作日|每(?:个)?学期|每月(?:的)?最后一天|月末|月底")


def _num(token: str | None) -> int:
    """把「两 / 三 / 15 / 十二」这类数量词变成 int；认不出返回 0。"""
    t = (token or "").strip()
    if not t:
        return 0
    if t.isdigit():
        return int(t)
    if t == "十":
        return 10
    if t.startswith("十"):
        return 10 + _CN_DIGITS.get(t[1:], 0)
    if t.endswith("十"):
        return _CN_DIGITS.get(t[:-1], 0) * 10
    if "十" in t:
        a, _, b = t.partition("十")
        return _CN_DIGITS.get(a, 0) * 10 + _CN_DIGITS.get(b, 0)
    return _CN_DIGITS.get(t, 0)


def _weekdays_in(text: str) -> list[int]:
    """抓出「周几」序列，映射成 1~7（周一=1 … 周日=7，与官方一致）。"""
    out: set[int] = set()
    for m in _RE_WEEKDAYS.finditer(text or ""):
        for ch in m.group(1):
            day = _WEEKDAY_OF.get(ch)
            if day:
                out.add(day)
    return sorted(out)


def repeat_rules_of(text: str) -> tuple[list[dict[str, Any]], str]:
    """从原文里认重复规则，返回 ``(repeat, repeat_text)``。

    ``repeat`` 是**规则数组**（字段名同官方 `RecurrenceRule`）；
    ``repeat_text`` 只在**规则表达不了**时兜底（字段表 #20）。
    命中任意一条规则即算当天要做（并集），所以可能返回多条。
    """
    s = (text or "").strip()
    if not s:
        return [], ""

    # 先认「能看出周期但表达不了」的：移出 MVP，只留原话，不造规则
    m = _RE_UNEXPRESSIBLE.search(s)
    if m:
        return [], m.group(0)[:12]

    rules: list[dict[str, Any]] = []

    m = _RE_DAILY.search(s)
    if m:
        interval = _num(m.group(1))
        rule: dict[str, Any] = {"frequency": FREQ_DAILY}
        if interval > 1:
            rule["interval"] = interval
        rules.append(rule)

    m = _RE_WEEKLY.search(s)
    if m:
        interval = _num(m.group(1))
        rule = {"frequency": FREQ_WEEKLY}
        if interval > 1:
            rule["interval"] = interval
        days = _weekdays_in(s)
        if days:
            rule["daysOfWeek"] = days
        rules.append(rule)

    m = _RE_MONTHLY.search(s)
    if m:
        day = _num(m.group(2))
        rule = {"frequency": FREQ_MONTHLY}
        if 1 <= day <= 31:
            rule["daysOfMonth"] = [day]
        rules.append(rule)

    m = _RE_YEARLY.search(s)
    if m:
        month = _num(m.group(2))
        rule = {"frequency": FREQ_YEARLY}
        if 1 <= month <= 12:
            rule["monthsOfYear"] = [month]
        rules.append(rule)

    return rules, ""


def _parse_dt(value: str) -> datetime | None:
    """把 ``2026-10-17`` / ``2026-10-17 19:00`` 解析成本地 datetime；认不出 None。"""
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}))?", (value or "").strip())
    if not m:
        return None
    y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
    h = int(m.group(4)) if m.group(4) else 0
    mi = int(m.group(5)) if m.group(5) else 0
    try:
        return datetime(y, mo, d, h, mi)
    except ValueError:
        return None


def _priority(kind: str, time_normalized: str, now: datetime) -> str:
    """重要性的规则算法（App 映射成 0/1/2 显示为那个红圈）。"""
    if kind in (RULES.EVENT_CHAT, RULES.EVENT_IGNORE):
        return "later"
    dt = _parse_dt(time_normalized)
    if dt is None:
        return "normal"
    delta = dt - now
    if delta.total_seconds() <= 24 * 3600:
        return "urgent"
    if delta.total_seconds() <= 3 * 24 * 3600:
        return "high"
    return "normal"


def _due_at_ms(time_normalized: str) -> int:
    """``time_normalized``（'2026-10-17 19:00'）-> 毫秒时间戳；认不出返回 0。

    归一化串是**本地墙钟**，所以 ``timestamp()`` 直接换算即可。
    """
    dt = _parse_dt(time_normalized)
    if dt is None:
        return 0
    return int(dt.timestamp() * 1000)


def _category_of(kind: str, tags: list[str], text: str) -> str:
    """预设类型：作业 / 考试 / 活动 / 通知 / 其他（字段表 #23）。

    只做**可解释**的规则归类；用户可在 App 里改成自定义值。
    注意：这与消息级解析里既有的 `parse.category`（教务/活动/招聘/二手/闲聊）
    是**两套东西**——后者是消息主题、已被 236 条评测集覆盖，不要混用。
    """
    if kind == RULES.EVENT_NOTICE:
        return "通知"
    if kind == RULES.EVENT_ACTIVITY:
        return "活动"
    s = " ".join([str(t) for t in (tags or [])] + [text or ""])
    if re.search(r"考试|测验|期末|期中|补考|四六级", s):
        return "考试"
    if re.search(r"作业|报告|论文|实验|大作业|提交|DDL", s, re.I):
        return "作业"
    return "其他"


def _missing_fields(place: str, who: str, due_at: int) -> list[str]:
    """「缺失不猜测」的工程形式：只报卡片/详情真正要用的那三个。"""
    out: list[str] = []
    if not (place or "").strip():
        out.append("place")
    if not (who or "").strip():
        out.append("who")
    if due_at <= 0:
        out.append("dueAt")
    return out


def _level_of(steps: list[dict[str, Any]], items: list[str]) -> int:
    """难易程度 0 易 / 1 中 / 2 难（字段表 #15，只参与排序、卡片不显示）。

    模型不参与（没有评测集支撑"难度"判断，不编造）；用一条可解释的规则：
    步骤 + 需带物品越多，越像要费劲的事。用户可在 App 里改。
    """
    n = len(steps) + len([x for x in (items or []) if x])
    if n >= 4:
        return 2
    if n == 0:
        return 0
    return 1


def card_fields(
    *,
    kind: str,
    title: str,
    summary: str,
    time_text: str,
    time_normalized: str,
    place: str,
    who: str,
    items: list[str],
    tags: list[str],
    confidence: float,
    steps: list[dict[str, Any]],
    repeat_source: str,
    channel: str,
    now: datetime | None = None,
) -> dict[str, Any]:
    """一次算出卡片需要的全部派生字段。

    ``channel`` 取 ``bot`` / ``manual`` / ``paste`` / ``share`` / ``voice``。
    """
    now = now or datetime.now()
    due_at = _due_at_ms(time_normalized)
    repeat, repeat_text = repeat_rules_of(repeat_source)
    return {
        "priority": _priority(kind, time_normalized, now),
        "level": _level_of(steps, items),
        "category": _category_of(kind, tags, f"{title} {summary}"),
        "channel": channel,
        "due_at": due_at,
        "due_text": time_text,
        "repeat": repeat,
        "repeat_text": repeat_text,
        "certainty": int(round(float(confidence or 0) * 100)),
        "missing_fields": _missing_fields(place, who, due_at),
    }
