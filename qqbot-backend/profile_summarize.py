# -*- coding: utf-8 -*-
"""用户画像 · 词条归纳（**无状态**：只处理、不存储）。

为什么单开一个模块，而不是塞进 ``llm_parse``：

* **输入不是聊天正文**。端侧先把「用户自己发过的话」统计成
  「词 + 次数 + 类别」的词频表再发来——素材里**本来就没有原话**，
  所以这里即使出 bug 也不可能泄漏聊天内容。
* **安全闸的语义不同**。``llm_parse`` 的闸是「字段必须是原文子串」；
  画像的闸是「**词必须出自给定词表**」——模型只能挑词、合并、排序，
  **不能发明新词条**（例如素材里只有「传智杯」，它不许写成「喜欢参加竞赛」）。

隐私红线的落实（与 ``/parse`` 同级，见 ``test_profile_api.py``）：

* 不写任何文件、不落盘；
* 不进 30 分钟窗口（``relay.WINDOW``）；
* 不进候选流（``candidate_engine.CandidateStream``）。
"""

from __future__ import annotations

import json
import logging
from typing import Any

import llm_parse

log = logging.getLogger("profile")

# 画像词条的五类。端侧 ``ProfileKind`` 必须与此一致。
KINDS = ("interest", "place", "role", "schedule", "preference")

KIND_LABELS = {
    "interest": "关注点",
    "place": "常去地点",
    "role": "身份线索",
    "schedule": "作息",
    "preference": "提醒偏好",
}

# 端侧词表可能很大（一个活跃同学几百个词），只把词频最高的这些交给模型——
# 既压 prompt 长度，也天然过滤长尾噪声。
MAX_VOCAB = 80

# 词条条数的上下限（请求体里可以调，但不允许无上限膨胀）
MIN_ENTRIES = 1
MAX_ENTRIES = 60

_SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "entries": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "kind": {"type": "string", "enum": list(KINDS)},
                    "term": {"type": "string"},
                    "weight": {"type": "integer"},
                },
                "required": ["kind", "term", "weight"],
            },
        }
    },
    "required": ["entries"],
}


# ---------------------------------------------------------------- 素材规整


def _despace(s: str) -> str:
    """去掉所有空白后再比较。

    模型可能把词写成带空格的形式（``传智杯 比赛``），
    直接按原样比对会误判成"词不在词表里"而丢条目。中文里空格不承载语义。
    """
    return "".join((s or "").split())


def _to_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def build_vocab(material: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """把请求里的词频表规整成 ``{去空白词: {term, kind, count}}``。

    只做**信任边界的清洗**：非词条形状的条目直接丢，非法 kind 归到 interest，
    次数非正的丢（端侧偶发 0 值时不该占位置）。没有任何内容落盘。
    """
    out: dict[str, dict[str, Any]] = {}
    terms = material.get("terms")
    if not isinstance(terms, list):
        return out
    for it in terms:
        if not isinstance(it, dict):
            continue
        term = str(it.get("term") or "").strip()
        if not term:
            continue
        kind = str(it.get("kind") or "").strip()
        if kind not in KINDS:
            kind = "interest"
        count = _to_int(it.get("count"))
        if count <= 0:
            continue
        key = _despace(term)
        if not key:
            continue
        cur = out.get(key)
        if cur is None or count > cur["count"]:
            out[key] = {"term": term, "kind": kind, "count": count}
    return out


def _ranked(vocab: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(vocab.values(), key=lambda v: -v["count"])


# ---------------------------------------------------------------- 规则回退


def _entry(term: str, kind: str, count: int, weight: int) -> dict[str, Any]:
    """词条的统一形状。

    ``reason`` **由规则生成**、不下发给模型，模型也就无从编造它——
    它只陈述"出现 N 次"这个端侧统计出来的事实。
    """
    return {
        "kind": kind,
        "term": term,
        "weight": weight,
        "evidence": count,
        "reason": f"出现 {count} 次",
    }


def by_rules(vocab: dict[str, dict[str, Any]], max_entries: int) -> list[dict[str, Any]]:
    """规则回退：按出现次数排序，权重按"相对最高频"归一化到 0-100。

    这条路径**永远可用**（不依赖模型），也是模型的兜底与对照基线。
    """
    items = _ranked(vocab)[:max_entries]
    if not items:
        return []
    top = items[0]["count"]
    out: list[dict[str, Any]] = []
    for v in items:
        weight = max(1, round(100 * v["count"] / top)) if top > 0 else 1
        out.append(_entry(v["term"], v["kind"], v["count"], weight))
    return out


# ---------------------------------------------------------------- 模型归纳


def _system_prompt(max_entries: int) -> str:
    kinds = " / ".join(f"{k}（{KIND_LABELS[k]}）" for k in KINDS)
    return (
        "你在为一个 QQ 群消息助手建立**某位用户**的画像。\n"
        "\n"
        "给你的素材是：这个人在各个群里**自己发出**的消息中，"
        "由端侧统计出来的**词频表**——每项是「词 × 出现次数」，已按粗类别分组。"
        "**素材里没有聊天原话，只有词和数字。**\n"
        "\n"
        "你的任务：从这些词里挑出最能代表这个人的若干**画像词条**，按重要程度排序。\n"
        "\n"
        "硬性规则（违反的条目会被程序直接丢弃）：\n"
        f"1. `term` **必须是素材里出现过的那几个字，逐字复制**。"
        f"**绝对不要发明新词，也不要归纳出上位词**——"
        f"素材里只有「传智杯」「蓝桥杯」时，就写「传智杯」，**不要**写「竞赛」。\n"
        f"2. `kind` 只能取这五个之一：{kinds}。\n"
        "3. `weight` 是 0-100 的整数，表示「这个词对描述这个人有多重要」："
        "出现次数越多、词越具体/越专属，权重越高；"
        "而「今天」「哈哈」「好的」这类人人都说的泛词，权重给低。\n"
        "4. 近义的词**只保留最具代表性的一个**（仍然必须是素材里的词）。\n"
        f"5. 最多输出 {max_entries} 条，按 weight 从高到低排列。\n"
        "\n"
        "只输出 JSON，不要解释、不要加任何其它文字。"
    )


def _digest(vocab: dict[str, dict[str, Any]], material: dict[str, Any]) -> str:
    """把素材拼成给模型看的紧凑文本（按类别分组，词频高的在前）。"""
    items = _ranked(vocab)[:MAX_VOCAB]
    by_kind: dict[str, list[str]] = {}
    for v in items:
        by_kind.setdefault(v["kind"], []).append(f"{v['term']}×{v['count']}")

    lines: list[str] = []
    counters = material.get("counters")
    if isinstance(counters, dict) and counters:
        parts: list[str] = []
        for k, val in counters.items():
            if isinstance(val, (int, float, str)) and not isinstance(val, bool):
                parts.append(f"{k}={val}")
        if parts:
            lines.append("行为计数：" + "，".join(parts))
    for kind in KINDS:
        if kind in by_kind:
            lines.append(f"{kind}（{KIND_LABELS[kind]}）：" + "，".join(by_kind[kind]))
    lines.append("")
    lines.append(f"请据此输出不超过 {len(items)} 条的画像词条 JSON。")
    return "\n".join(lines)


def clamp_max_entries(value: Any) -> int:
    n = _to_int(value, 40)
    return max(MIN_ENTRIES, min(n, MAX_ENTRIES))


def sanitize_entries(
    raw: Any, vocab: dict[str, dict[str, Any]], max_entries: int
) -> list[dict[str, Any]]:
    """**安全闸**：只留下「词确实出自素材词表」的条目，其余一律丢弃。

    这是本模块唯一挡在模型与用户之间的东西，所以宁可严：
    ``term`` 去空白后必须能在词表里查到（大小写敏感，中文不受影响）；
    命中的话回填**端侧原始写法**，保证展示的就是用户自己的词。
    """
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    if not isinstance(raw, list):
        return out
    for it in raw:
        if not isinstance(it, dict):
            continue
        kind = str(it.get("kind") or "").strip()
        if kind not in KINDS:
            continue
        key = _despace(str(it.get("term") or ""))
        src = vocab.get(key)
        if src is None:
            log.info("profile reject (not in vocab): %r", it.get("term"))
            continue
        if key in seen:
            continue
        seen.add(key)
        weight = max(0, min(100, _to_int(it.get("weight"))))
        out.append(_entry(src["term"], kind, src["count"], weight))
    out.sort(key=lambda e: -e["weight"])
    return out[:max_entries]


def summarize(material: dict[str, Any], max_entries: int = 40) -> dict[str, Any]:
    """把词频表归纳成画像词条。返回 ``{"entries": [...], "engine": "llm"|"rules"}``。

    * 没有素材 / 模型不在线 → 规则；
    * 模型在线 → 归纳，但产物要过词表闸；**留下的条目不到规则的一半**时
      判为"模型基本没干活"，退回规则（避免给用户一个空空如也的画像）。
    """
    top = clamp_max_entries(max_entries)
    vocab = build_vocab(material if isinstance(material, dict) else {})
    fallback = by_rules(vocab, top)
    if not vocab or not llm_parse.available():
        return {"entries": fallback, "engine": "rules"}

    text = llm_parse.chat(
        [
            {"role": "system", "content": _system_prompt(top)},
            {"role": "user", "content": _digest(vocab, material)},
        ],
        schema=_SCHEMA,
    )
    if not text:
        return {"entries": fallback, "engine": "rules"}

    try:
        obj = json.loads(text)
    except Exception as exc:
        log.warning("profile bad json: %s", exc)
        return {"entries": fallback, "engine": "rules"}
    if not isinstance(obj, dict):
        return {"entries": fallback, "engine": "rules"}

    entries = sanitize_entries(obj.get("entries"), vocab, top)
    if len(entries) * 2 < len(fallback):
        log.info("profile llm too thin (%d < half of %d), fallback", len(entries), len(fallback))
        return {"entries": fallback, "engine": "rules"}
    return {"entries": entries, "engine": "llm"}
