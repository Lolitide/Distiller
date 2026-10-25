# -*- coding: utf-8 -*-
"""知了 · v2 候选管道：群消息 -> 候选任务（去重 + 聚类 + 综合总结）。

对应契约：
  * 《04_API契约_v2_草案.md》§2 / §3 / §5.1 / §5.2
  * 《05_API接口文档.md》§2.1（candidates）

本模块**只做功能**，不含 HTTP 接口 —— `/api/relay/candidates` 的路由留给
`server.py` 后续接入（用户当前要求：先做功能，先不管 API）。

三步走（契约 §3）：
  ① 去重（dedup）：同群 + 10 分钟内、文本完全相同或关键词高度相似 -> 合并为一条，
     其余并入 ``source.msg_ids``，``confidence`` 取最高。
  ② 聚类（联合上下文）：同群 + 相邻间隔 ≤ 30min，且**共享标签/关键词/概念/实体**
     或满足**指代关联**（问句 + 紧邻回答）-> 同一 ``Thread``。
  ③ 综合总结：对整簇（而非单条）调小模型产出**一条**候选；模型不可用时回退规则。
     单条解析结果（``message["parse"]``）作为兜底/兜底字段来源。

隐私：与 v1 一致 —— 候选只活在内存 30 分钟窗口内，本模块不落盘。
"""

from __future__ import annotations

import hashlib
import json
import logging
import re
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any

import llm_parse
import llm_worker
import pipeline_proto as RULES
# 卡片字段（《任务字段表》v1）的规则实现放在 card_fields ——
# 消息级解析（llm_worker）与候选流必须用同一套，而 candidate_engine 已 import
# llm_worker，反向引用会成环，所以抽成独立模块。
from card_fields import (
    PRIORITIES as _PRIORITIES,
    _category_of,
    _due_at_ms,
    _level_of,
    _missing_fields,
    _priority,
    repeat_rules_of,
)

log = logging.getLogger("zhiliao.candidate")

# ---------------------------------------------------------------- 常量

THREAD_GAP_MINUTES = 30     # 同簇最大相邻间隔（与窗口一致）
DUP_GAP_MINUTES = 10        # 去重时间窗
SIM_THRESHOLD = 0.6         # 关键词 Jaccard 相似度阈值（近似重复）
SUMMARY_MAX = 120           # 综合总结长度上限
MAX_MSG_IDS = 20            # 单个候选最多保留多少条来源 msg_id
CONV_GAP_MINUTES = 5        # 「对话连续性」窗：同群 5 分钟内的问答接续
SHORT_TEXT_LEN = 10         # 多短算「对话短句」（用于接续判断）
CONV_MAX_LEN = 25           # 超过这个长度就不算"口语短句"了（长通知自己成簇）

KIND_TODO = RULES.EVENT_TODO
KIND_NOTICE = RULES.EVENT_NOTICE
KIND_ACTIVITY = RULES.EVENT_ACTIVITY
KIND_PLAN = RULES.EVENT_PLAN
KIND_CHAT = RULES.EVENT_CHAT
KIND_IGNORE = RULES.EVENT_IGNORE

# 有实际内容、值得进「任务列表」的类型
_ACTIONABLE = (KIND_TODO, KIND_NOTICE, KIND_ACTIVITY, KIND_PLAN)

_PRIORITIES = ("urgent", "high", "normal", "later")

# 簇级模型的缓存（键 = 簇文本指纹）：见 `_llm_thread`
_LLM_CACHE: dict[str, tuple[float, dict | None]] = {}
_LLM_CACHE_MAX = 512
_LLM_FAIL_TTL = 60.0

# 问句信号（用于「指代关联」：问句 + 紧邻回答 归入同一簇）
_QUESTION_RE = re.compile(r"(吗|呢|咋|啥|几点|什么时候|怎么|为什么|是不是|有没有|[?？])\s*$")
_QUESTION_WORDS = ("咋", "啥", "几点", "什么时候", "怎么", "为什么", "是不是", "有没有")


# ============================================================ 内部模型


@dataclass
class _Msg:
    """一条归一化后的群消息。"""

    msg_id: str
    group_openid: str
    group_label: str
    sender: str
    raw: str
    text: str            # 归一化文本
    timestamp: str
    parse: dict          # 结构化解析结果（llm 优先 / rules 兜底）

    @property
    def kind(self) -> str:
        return str(self.parse.get("kind") or KIND_CHAT)

    @property
    def confidence(self) -> float:
        try:
            return float(self.parse.get("confidence") or 0.0)
        except (TypeError, ValueError):
            return 0.0

    @property
    def ts(self) -> datetime:
        return RULES._parse_ts(self.timestamp)


@dataclass
class _Unit:
    """去重后的「逻辑消息」：文本相同/近似的多条消息合到这里。"""

    group_openid: str
    group_label: str
    msgs: list[_Msg] = field(default_factory=list)

    @property
    def rep(self) -> _Msg:
        """代表消息：置信度最高、文本最长的一条。"""
        return max(self.msgs, key=lambda m: (m.confidence, len(m.text)))

    @property
    def texts(self) -> list[str]:
        out: list[str] = []
        for m in self.msgs:
            if m.text and m.text not in out:
                out.append(m.text)
        return out

    @property
    def msg_ids(self) -> list[str]:
        return [m.msg_id for m in self.msgs if m.msg_id]

    @property
    def senders(self) -> list[str]:
        return list(dict.fromkeys(m.sender for m in self.msgs if m.sender))

    @property
    def first_ts(self) -> str:
        return self.msgs[0].timestamp

    @property
    def last_ts(self) -> str:
        return self.msgs[-1].timestamp


@dataclass
class _Cluster:
    """话题簇（Thread）。"""

    group_openid: str
    group_label: str
    units: list[_Unit] = field(default_factory=list)
    tags: set[str] = field(default_factory=set)
    keywords: set[str] = field(default_factory=set)
    concepts: set[str] = field(default_factory=set)
    entities: set[str] = field(default_factory=set)
    last_is_question: bool = False   # 簇尾那条是不是问句
    has_question: bool = False       # 簇里出现过问句（用于对话连续性）

    @property
    def last_ts(self) -> str:
        return self.units[-1].last_ts

    @property
    def msgs(self) -> list[_Msg]:
        return [m for u in self.units for m in u.msgs]

    def absorb(self, unit: _Unit) -> None:
        self.units.append(unit)
        self.tags |= _tags_of(unit.rep)
        self.keywords |= _keywords_of(_joined(unit))
        self.concepts |= RULES._concepts(_joined(unit))
        self.entities |= _entities_of(unit.rep)
        self.last_is_question = _is_question(unit.rep.text)
        self.has_question = self.has_question or self.last_is_question


# ============================================================ 小工具


def _joined(unit: _Unit) -> str:
    return " ".join(unit.texts)


def _tags_of(msg: _Msg) -> set[str]:
    """取消息的标签用于**聚类**。

    过滤掉「通用标签」：`_tags()` 会给每条通知都加一个 "通知" 标签，
    若拿它参与相似度判断，任意两条不相干的正式通知都会因共享 "通知" 被并成一条
    （实测：蓝桥杯讨论 与 奖学金报名通知 被合并）。所以聚类只用**具体标签**。
    """
    generic = {"通知", KIND_TODO, KIND_NOTICE, KIND_ACTIVITY, KIND_PLAN, KIND_CHAT, KIND_IGNORE}
    return {str(t) for t in (msg.parse.get("tags") or []) if t and str(t) not in generic}


def _keywords_of(text: str) -> set[str]:
    return RULES._keywords(text)


def _entities_of(msg: _Msg) -> set[str]:
    """聚类用的实体：**只用地点**。

    刻意不含 `timeText`（两条无关通知同属「今天/本周」是常态），
    也不含 `who`：规则抽出来的 who 在校园通知里几乎都是「请各班同学」这种泛称，
    两条毫不相干的公文会因此被并成一条（实测：体质测试 + 积极分子名单）。
    具体人物的接续由关键词/问答规则负责。
    """
    p = msg.parse
    out: set[str] = set()
    place = str(p.get("place") or "").strip()
    if len(place) >= 2:
        out.add(place)
    return out


def _kw_merge_signal(a: set[str], b: set[str]) -> bool:
    """关键词是否强到足以判定「说的是同一件事」。

    `_keywords` 是 2~4 字滑窗的 top-4，两条无关的中文通知几乎必然共享
    「通知/同学/各班同」这类片段 —— 之前「共享任意一个关键词就合并」
    就是这么把「体质测试」和「积极分子」并成一条的。
    现在只认两种强证据：**共享 4 字片段**，或整体 Jaccard ≥0.5。
    3 字片段（如「各班同」）不算——它太容易同时出现在两条公文里。
    """
    inter = a & b
    if not inter:
        return False
    if any(len(k) >= 4 for k in inter):
        return True
    return _jaccard(a, b) >= 0.5


def _is_question(text: str) -> bool:
    t = (text or "").strip()
    if not t:
        return False
    if _QUESTION_RE.search(t):
        return True
    return any(w in t for w in _QUESTION_WORDS)


def _jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    inter = len(a & b)
    if not inter:
        return 0.0
    return inter / len(a | b)


def _now() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def _hash6(*parts: str) -> str:
    raw = "\u0001".join(parts).encode("utf-8")
    return hashlib.sha1(raw).hexdigest()[:6]


def _ensure_parse(payload: dict) -> dict:
    """取消息的结构化解析：已有 ``parse`` 直接用，否则按规则现算（绝不编造）。"""
    existing = payload.get("parse")
    if isinstance(existing, dict) and existing.get("kind"):
        return existing
    return llm_worker._rules_parse(payload)


def _to_msg(payload: dict) -> _Msg:
    content = payload.get("content") or ""
    return _Msg(
        msg_id=str(payload.get("msg_id") or ""),
        group_openid=str(payload.get("group_openid") or ""),
        group_label=str(payload.get("group_label") or ""),
        sender=str(payload.get("sender") or ""),
        raw=content,
        text=RULES.normalize(content),
        timestamp=str(payload.get("timestamp") or ""),
        parse=_ensure_parse(payload),
    )


# ============================================================ ① 去重


def _dedup(msgs: list[_Msg]) -> list[_Unit]:
    """同群 + ``DUP_GAP_MINUTES`` 内、文本相同或关键词高度相似 -> 合成一个 _Unit。"""
    units: list[_Unit] = []
    by_group: dict[str, list[_Msg]] = {}
    for m in msgs:
        by_group.setdefault(m.group_openid, []).append(m)

    for group_openid, group_msgs in by_group.items():
        group_msgs.sort(key=lambda m: m.ts)
        seen: list[_Unit] = []
        for m in group_msgs:
            placed = False
            # 只和该群最近的一个 unit 比（消息已按时间排序，更早的间隔只会更大）
            if seen:
                prev = seen[-1]
                gap = abs((m.ts - prev.msgs[-1].ts).total_seconds())
                if gap <= DUP_GAP_MINUTES * 60:
                    same_text = bool(m.text) and m.text in prev.texts
                    similar = _jaccard(_keywords_of(m.text), _keywords_of(_joined(prev))) >= SIM_THRESHOLD
                    if same_text or similar:
                        prev.msgs.append(m)
                        placed = True
            if not placed:
                seen.append(_Unit(group_openid, m.group_label or "", [m]))
        units.extend(seen)
    return units


# ============================================================ ② 聚类


def _cluster(units: list[_Unit]) -> list[_Cluster]:
    """同群 + 间隔 ≤ ``THREAD_GAP_MINUTES`` + 共享信号/实体/对话连续性 -> 同一簇。

    **硬约束：一个簇只能来自一个群。** 两道保证：
      1. 下面 `c.group_openid != unit.group_openid` 一律跳过（信号/实体/连续性检查之前）；
      2. 新建簇时用 `unit.group_openid`，簇的群号从此固定。
    因此跨群消息无论文本多像、间隔多近，都不可能并入同一个候选。

    归并规则（满足其一即并入）：
      A. 共享标签 / 关键词 / 概念 / 实体；
      B. **紧邻问答**：同群最近簇刚问了句、这条不是问句 -> 视作回答并进来；
      C. **对话连续性**（``CONV_GAP_MINUTES`` 内，解决多轮问答）：
         - 这条是问句 -> 接上该群最近簇（追问）；
         - 这条是短句且最近簇里出现过问句 -> 视作应答/补充并进来。
    """
    ordered = sorted(units, key=lambda u: u.rep.ts)
    clusters: list[_Cluster] = []
    # 每个群「最后一个簇」——下面 B / C 只在**同群内**成立，
    # 多群交错时也不会把 A 群的回答塞进 B 群的簇。
    last_by_group: dict[str, _Cluster] = {}

    for unit in ordered:
        rep = unit.rep
        t = rep.ts
        gid = unit.group_openid
        kw = _keywords_of(_joined(unit))
        concepts = RULES._concepts(_joined(unit))
        tags = _tags_of(rep)
        entities = _entities_of(rep)
        question = _is_question(rep.text)

        target: _Cluster | None = None
        # A) 共享信号（同群、30 分钟内）。判据刻意保守：只要"像同一个话题"就并，
        #    会把同一小时内两条互不相干的通知并成一条（实测：体质测试 + 积极分子名单）。
        for c in clusters:
            if c.group_openid != gid:
                continue
            gap = abs((t - RULES._parse_ts(c.last_ts)).total_seconds())
            if gap > THREAD_GAP_MINUTES * 60:
                continue
            same_tag: bool = bool(c.tags & tags)
            same_kw: bool = _kw_merge_signal(c.keywords, kw)
            # 概念要共享 **2 个以上**：只共享「教务」这种大类的两条通知不是一件事
            same_concept: bool = len(c.concepts & concepts) >= 2
            same_entity: bool = bool(c.entities & entities)
            if same_tag or same_kw or same_concept or same_entity:
                target = c
                break

        # B / C) 与「该群最近簇」的对话连续性
        # 只对**口语短句/疑问句**生效：长段落（正式通知、长公告）不该被闲聊簇吸进来，
        # 否则「蓝桥杯讨论」和「奖学金通知」会被并成一条候选。
        if target is None and (question or len(rep.text) <= CONV_MAX_LEN):
            last = last_by_group.get(gid)
            if last is not None:
                gap = abs((t - RULES._parse_ts(last.last_ts)).total_seconds())
                if gap <= CONV_GAP_MINUTES * 60:
                    if last.last_is_question and not question:
                        target = last            # B) 紧邻回答
                    elif question:
                        target = last            # C) 追问
                    elif len(rep.text) <= CONV_MAX_LEN and last.has_question:
                        target = last            # C) 短句应答/补充

        if target is None:
            c = _Cluster(gid, unit.group_label or "")
            c.absorb(unit)
            clusters.append(c)
            target = c
        else:
            target.absorb(unit)
        last_by_group[gid] = target
    return clusters


# ============================================================ ③ 综合总结


def _pick_rep_unit(cluster: _Cluster) -> _Unit:
    """代表 unit：优先「有实义」的类型，再看置信度与文本长度。"""

    def score(u: _Unit) -> tuple[int, float, int]:
        actionable = 1 if u.rep.kind in _ACTIONABLE else 0
        return (actionable, u.rep.confidence, len(u.rep.text))

    return max(cluster.units, key=score)


def _thread_texts(cluster: _Cluster) -> list[str]:
    """整簇的去重文本（用于送模型 + 兜底拼接）。"""
    out: list[str] = []
    for u in cluster.units:
        for t in u.texts:
            if t and t not in out:
                out.append(t)
    return out


def _rule_summary(cluster: _Cluster, best: _Unit, time_note: str = "") -> str:
    """规则兜底总结：只用**已抽出的结构化字段**拼，不把原文整段贴回来。

    旧实现会把簇内最长的 1~2 条原文追加进 summary，结果「总结」变成
    「标题；时间；原文」三段，标题本身又已含原文片段 —— 用户看到的是一段
    重复的原文，等同于"没有总结"。原文本来就有 `sourceText` 单独下发，
    不需要塞进 summary。

    只有在**一个结构化字段都没有**时（单条消息、抽取全空）才退到最长原文。
    """
    p = best.rep.parse
    base = str(p.get("summary") or "").strip()
    parts: list[str] = []
    if base:
        parts.append(base)
    if time_note and time_note not in base:
        parts.append("时间：" + time_note)
    place = str(p.get("place") or "").strip()
    if place and place not in base:
        parts.append("地点：" + place)
    who = str(p.get("who") or "").strip()
    if who and who not in base and who not in place:
        parts.append("对象：" + who)
    if not parts:
        texts = [t for t in _thread_texts(cluster) if len(t) >= 4]
        if texts:
            parts.append(max(texts, key=len))
    return "；".join(parts)[:SUMMARY_MAX]


def _rule_steps(cluster: _Cluster) -> list[dict[str, Any]]:
    """可执行子步骤：取簇内各条的动作，去重、限量。

    形态按《任务字段表》#25：元素是 ``{content, done}``（``done`` 存 0/1），
    副卡片「每个 Step 前面的圆圈」读它。新抽出来的步骤一律未完成。
    """
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for u in sorted(cluster.units, key=lambda x: x.rep.ts):
        rep = u.rep
        if rep.kind not in _ACTIONABLE:
            continue
        action = str(rep.parse.get("action") or "").strip()
        # 规则兜底也不能把整句原文当步骤：超过 15 字的一律丢弃
        # （实测「入党积极分子公示名单…」这类公文会被整段抄成一步）
        if len(action) > 15:
            continue
        if action and action not in seen:
            seen.add(action)
            out.append({"content": action, "done": 0})
    # 编号列表兜底：模型没给 steps 时，至少把「1. xxx 2. xxx / ①②」拆出来。
    # 只在这种显式编号里做，避免把普通长句切成步骤。
    if not out:
        for u in sorted(cluster.units, key=lambda x: x.rep.ts):
            text = str(u.rep.text or "")
            for m in re.finditer(r"(?:^|\n)\s*(?:\d{1,2}[.、)]|[①②③④⑤⑥])\s*([^\n；;]{2,20})", text):
                content = m.group(1).strip()
                if content and content not in seen:
                    seen.add(content)
                    out.append({"content": content[:15], "done": 0})
            if len(out) >= 5:
                break
    return out[:5]


def _merge_tags(cluster: _Cluster, best: _Unit) -> list[str]:
    out = list(best.rep.parse.get("tags") or [])
    for u in cluster.units:
        for t in (u.rep.parse.get("tags") or []):
            if t not in out:
                out.append(t)
    return out[:8]


def _merge_items(cluster: _Cluster, best: _Unit) -> list[str]:
    out: list[str] = []
    for u in cluster.units:
        for it in (u.rep.parse.get("items") or []):
            if it and it not in out:
                out.append(it)
    if not out:
        out = list(best.rep.parse.get("items") or [])
    return out[:5]


def _thread_kind(cluster: _Cluster, best: _Unit) -> str:
    """整簇的类型 = 代表 unit 的类型；若代表是闲聊但簇里有实义消息，取实义的。"""
    if best.rep.kind in _ACTIONABLE:
        return best.rep.kind
    for u in cluster.units:
        if u.rep.kind in _ACTIONABLE:
            return u.rep.kind
    return best.rep.kind


def _anchor(cluster: _Cluster) -> str:
    """簇锚点文本：按时间第一条有文本的消息（用于稳定 id）。"""
    for u in sorted(cluster.units, key=lambda x: x.rep.ts):
        if u.texts:
            return u.texts[0]
    return ""


def _candidate_id(cluster: _Cluster) -> str:
    """稳定幂等 ID：锚定「同群 + 簇首条文本」，后续消息并入时保持不变。"""
    return "c_" + _hash6(cluster.group_openid, _anchor(cluster))


def _thread_id(cluster: _Cluster) -> str:
    # 群标识取 openid **前 6 位**（与契约示例 t_15B451_9 一致）
    head = cluster.group_openid[:6] if cluster.group_openid else "unknown"
    return "t_" + head + "_" + _hash6(cluster.group_openid, _anchor(cluster))


def _llm_thread(cluster: _Cluster, base: datetime) -> dict[str, Any] | None:
    """对整簇调小模型；不可用/校验不过返回 None（调用方回退规则）。

    带缓存：``/candidates`` 是轮询接口，每轮都会重算候选；没有缓存就会对**没变过的簇**
    反复调模型。成功结果按「簇文本」缓存下来（长期有效），失败只缓存 60 秒避免重试风暴。
    """
    texts = _thread_texts(cluster)
    key = hashlib.sha1("\u0001".join(texts).encode("utf-8")).hexdigest()
    now = time.time()
    hit = _LLM_CACHE.get(key)
    if hit is not None:
        ts, obj = hit
        if obj is not None or now - ts < _LLM_FAIL_TTL:
            return obj
    if not llm_parse.available():
        return None
    try:
        obj = llm_parse.extract_thread(texts)
    except Exception as exc:  # noqa: BLE001
        log.warning("簇级模型抽取失败，回退规则：%s", exc)
        obj = None
    _LLM_CACHE[key] = (now, obj)
    if len(_LLM_CACHE) > _LLM_CACHE_MAX:
        for k in list(_LLM_CACHE)[: len(_LLM_CACHE) - _LLM_CACHE_MAX]:
            _LLM_CACHE.pop(k, None)
    return obj


def _time_fields(
    time_text: str,
    base: datetime,
    fallback: _Msg,
    cluster: _Cluster | None = None,
) -> tuple[str, str, bool]:
    """返回 (time_text, time_normalized, time_unresolved)。归一化一律由程序算。

    把「模型给的时间 / 代表消息的时间 / 整簇各条消息」放在一起解析，并做
    **日期 × 时刻拼合**：一条说「明天」、另一条说「下午两点」时合成
    `2026-10-15 14:00` —— 多轮对话里时间常被拆在不同消息里。
    """
    p = fallback.parse
    sources: list[str] = []
    for text in ((time_text or ""), str(p.get("timeText") or "")):
        text = text.strip()
        if text and text not in sources:
            sources.append(text)
    if cluster is not None:
        for text in _thread_texts(cluster):
            if text not in sources:
                sources.append(text)

    date_slot: RULES.TimeSlot | None = None
    clock: tuple[str, int, int] | None = None
    for text in sources:
        s = RULES.parse_time(text, base)
        if s is None:
            continue
        if s.unresolved:
            if date_slot is None:
                date_slot = s
            continue
        if s.normalized and ":" in s.normalized:
            return s.text, s.normalized, False          # 已经精确到时刻，直接用
        if s.normalized:
            if date_slot is None:
                date_slot = s
            continue
        if clock is None and s.text:
            clock = RULES._find_clock(text)             # 只有时刻（如「下午两点」）

    if date_slot is not None and date_slot.normalized:
        if clock is not None:
            return (date_slot.text + clock[0],
                    f"{date_slot.normalized} {clock[1]:02d}:{clock[2]:02d}", False)
        return date_slot.text, date_slot.normalized, False
    if date_slot is not None and date_slot.unresolved:
        return date_slot.text, "", True
    if clock is not None:
        return clock[0], "", False
    return "", str(p.get("timeNormalized") or ""), bool(p.get("timeUnresolved") or False)


def _place_of(cluster: _Cluster, best: _Unit, model_place: str = "") -> str:
    """整簇找地点：地点常被拆在**另一条消息**里。

    实测：`咱们下一次社团培训是啥时候呀` + `美工部是10.31下午两点到六点` + `具体是在哪呢`
    + `主楼A103` —— 代表消息没有地点，地点在最后一条。只取代表消息的 place 就会丢掉它。
    取整簇里最长的非空地点（越长越具体：`主楼A103` 优于 `主楼`）。
    """
    if model_place:
        return model_place
    found = str(best.rep.parse.get("place") or "")
    for u in cluster.units:
        p = str(u.rep.parse.get("place") or "")
        if len(p) > len(found):
            found = p
    return found


def _build_from_llm(
    cluster: _Cluster,
    best: _Unit,
    obj: dict[str, Any],
    base: datetime,
) -> dict[str, Any]:
    kind = str(obj.get("kind") or best.rep.kind)
    time_text, time_norm, time_unres = _time_fields(str(obj.get("time_text") or ""), base, best.rep, cluster)
    conf = min(0.95, best.rep.confidence + 0.05) if len(cluster.msgs) >= 3 else best.rep.confidence
    # 模型给的 tags 已是原文子串校验过的；没有才用规则合并的标签
    model_tags = [str(t) for t in (obj.get("tags") or []) if t]
    # 安全闸清空的槽位。旧逻辑是「只要有槽位被清空，就**整段丢弃**模型的 summary」，
    # 结果一个字段写错就连累整段总结 —— 用户看到的是规则拼接（曾经是原文重复三遍），
    # 观感就是"没有总结"。现在只在 summary **真的复述了那个编造值**时才不信它。
    nullified = list(obj.get("_nullified") or [])
    nullified_values = obj.get("_nullified_values") or {}
    summary = str(obj.get("summary") or "").strip()[:SUMMARY_MAX]
    if not summary:
        summary = _rule_summary(cluster, best, time_note=time_text)
    elif nullified:
        flat_summary = re.sub(r"\s+", "", summary)
        leaked = [v for v in nullified_values.values()
                  if v and re.sub(r"\s+", "", str(v)) in flat_summary]
        if leaked:
            log.info("summary 复述了被清空的编造值 %s，回退规则总结", leaked)
            summary = _rule_summary(cluster, best, time_note=time_text)
    model_steps: list[dict[str, Any]] = []
    for s in (obj.get("steps") or [])[:5]:
        content = str(s).strip()
        if content:
            model_steps.append({"content": content[:15], "done": 0})
    return {
        "kind": kind,
        "title": (str(obj.get("title") or "").strip()[:24] or str(best.rep.parse.get("title") or "")[:24]),
        "summary": summary,
        "steps": model_steps,
        "time_text": time_text,
        "time_normalized": time_norm,
        "time_unresolved": time_unres,
        "place": _place_of(cluster, best, str(obj.get("place") or "")),
        "who": str(obj.get("who") or best.rep.parse.get("who") or ""),
        "deadline": str(obj.get("deadline") or best.rep.parse.get("deadline") or ""),
        "items": list(obj.get("items") or _merge_items(cluster, best))[:5],
        "tags": model_tags[:8] or _merge_tags(cluster, best),
        "confidence": round(conf, 2),
        "engine": "llm",
        "degraded": False,
    }


def _build_from_rules(cluster: _Cluster, best: _Unit, base: datetime) -> dict[str, Any]:
    p = best.rep.parse
    time_text, time_norm, time_unres = _time_fields(str(p.get("timeText") or ""), base, best.rep, cluster)
    return {
        "kind": _thread_kind(cluster, best),
        "title": str(p.get("title") or "")[:24],
        "summary": _rule_summary(cluster, best, time_note=time_text),
        "time_text": time_text,
        "time_normalized": time_norm,
        "time_unresolved": time_unres,
        "place": _place_of(cluster, best, str(p.get("place") or "")),
        "who": str(p.get("who") or ""),
        "deadline": str(p.get("deadline") or ""),
        "items": _merge_items(cluster, best),
        "tags": _merge_tags(cluster, best),
        "confidence": round(best.rep.confidence, 2),
        "engine": "rules",
        "degraded": True,
    }


def _build_candidate(cluster: _Cluster, now: datetime) -> dict[str, Any] | None:
    best = _pick_rep_unit(cluster)
    base = RULES._parse_ts(cluster.units[0].first_ts)

    obj = _llm_thread(cluster, base)
    core = _build_from_llm(cluster, best, obj, base) if obj else _build_from_rules(cluster, best, base)

    if core["kind"] == KIND_IGNORE:
        return None
    # 标题统一收口到 12 字（模型可能给长句；规则路径已在 extract_title 里裁过）
    core["title"] = RULES.clip_title(str(core.get("title") or ""))

    msgs = cluster.msgs
    senders = list(dict.fromkeys(m.sender for m in msgs if m.sender))
    msg_ids = [m.msg_id for m in msgs if m.msg_id][:MAX_MSG_IDS]
    timestamps = [m.timestamp for m in msgs if m.timestamp]

    # 步骤优先用模型总结的（有逻辑、按先后顺序）；模型没给才退回「抽动作」
    steps = core.get("steps") or _rule_steps(cluster)
    if not steps:
        steps = _rule_steps(cluster)
    due_at = _due_at_ms(core["time_normalized"])
    repeat, repeat_text = repeat_rules_of(best.rep.text)

    return {
        "candidate_id": _candidate_id(cluster),
        "rev_seq": 0,
        "thread_id": _thread_id(cluster),
        "kind": core["kind"],
        "priority": _priority(core["kind"], core["time_normalized"], now),
        # ---- 卡片字段（《任务字段表》v1）----
        "level": _level_of(steps, core["items"]),
        "category": _category_of(core["kind"], core["tags"], core["title"] + core["summary"]),
        "channel": "bot",
        "due_at": due_at,
        "due_text": core["time_text"],
        "repeat": repeat,
        "repeat_text": repeat_text,
        "certainty": int(round(core["confidence"] * 100)),
        "missing_fields": _missing_fields(core["place"], core["who"], due_at),
        # ------------------------------------
        "title": core["title"],
        "summary": core["summary"],
        "time_text": core["time_text"],
        "time_normalized": core["time_normalized"],
        "time_unresolved": core["time_unresolved"],
        "place": core["place"],
        "who": core["who"],
        "deadline": core["deadline"],
        "items": core["items"],
        "steps": steps,
        "tags": core["tags"],
        "confidence": core["confidence"],
        "engine": core["engine"],
        "degraded": bool(core.get("degraded", core.get("engine") != "llm")),
        "source": {
            "group_openid": cluster.group_openid,
            "group_label": cluster.group_label,
            "senders": senders,
            "msg_ids": msg_ids,
            "count": len(msgs),
            "first_ts": timestamps[0] if timestamps else "",
            "last_ts": timestamps[-1] if timestamps else "",
        },
        "created_at": now.strftime("%Y-%m-%d %H:%M:%S"),
    }


# ============================================================ 对外入口


def _norm_key(text: str) -> str:
    """去掉空白与标点，用于跨簇合并时的"同一个标题"判断。"""
    return re.sub(r"[\s，。！？、,.!?:：；;《》“”‘’()（）\[\]【】…—\-]", "", text or "")


def _richness(c: dict) -> tuple[int, float, int]:
    """信息量：来源消息越多越可信；同分再看置信度与摘要长度。"""
    src = c.get("source") or {}
    return (int(src.get("count") or 0), float(c.get("confidence") or 0), len(str(c.get("summary") or "")))


def _lcs_len(a: str, b: str) -> int:
    """最长公共子串长度（标题很短，O(n*m) 足够）。"""
    if not a or not b:
        return 0
    best = 0
    prev = [0] * (len(b) + 1)
    for i in range(1, len(a) + 1):
        cur = [0] * (len(b) + 1)
        for j in range(1, len(b) + 1):
            if a[i - 1] == b[j - 1]:
                cur[j] = prev[j - 1] + 1
                if cur[j] > best:
                    best = cur[j]
        prev = cur
    return best


def _title_similar(a: str, b: str) -> bool:
    """两个（已去标点的）标题是否像同一件事。

    用于跨簇合并：模型两次生成的标题未必逐字相同
    （「体质测试通知」vs「学生体质测试」），只比相等会漏合并、留下重复卡片。
    用最长公共子串判定：≥4 字且覆盖较短标题的 60% 以上。
    """
    if not a or not b:
        return False
    if a == b:
        return True
    if len(a) >= 4 and len(b) >= 4 and (a in b or b in a):
        return True
    lcs = _lcs_len(a, b)
    return lcs >= 4 and lcs >= int(0.6 * min(len(a), len(b)))


def _same_event(a: dict, b: dict) -> bool:
    gid_a = str((a.get("source") or {}).get("group_openid") or "")
    gid_b = str((b.get("source") or {}).get("group_openid") or "")
    if gid_a != gid_b:
        return False
    t_a = str(a.get("time_normalized") or "")
    t_b = str(b.get("time_normalized") or "")
    if t_a and t_b and t_a != t_b:
        return False
    p_a = _norm_key(str(a.get("place") or ""))
    p_b = _norm_key(str(b.get("place") or ""))
    if p_a and p_b and p_a != p_b:
        return False
    title_a = _norm_key(str(a.get("title") or ""))
    title_b = _norm_key(str(b.get("title") or ""))
    return _title_similar(title_a, title_b)


def _dedupe_candidates(items: list[dict]) -> list[dict]:
    """同一群 + 同一时间 + 同一地点 + **相近标题**的候选只留一条。

    为什么需要：同一件事被拆到两个簇（比如隔了半小时又有人补一句），
    会变成两张几乎一样的卡片。保留信息量更大（来源消息更多）的那条。
    标题用相似度而不是逐字相等——模型每次生成的标题会有措辞差异。
    只看标题/地点都不够——「开会」每天都有，所以**时间不同不合并**。
    """
    out: list[dict] = []
    for c in items:
        title = _norm_key(str(c.get("title") or ""))
        place = _norm_key(str(c.get("place") or ""))
        if not title and not place:
            out.append(c)  # 没标题没地点，无法判断重复，保持原样
            continue
        merged = False
        for i in range(len(out)):
            if _same_event(out[i], c):
                if _richness(c) > _richness(out[i]):
                    out[i] = c
                merged = True
                break
        if not merged:
            out.append(c)
    return out


def build_candidates(messages: list[dict]) -> list[dict]:
    """把一批群消息（窗口内容）算成候选列表（未分配 rev_seq）。

    ``messages`` 是 relay 窗口里的原始 payload（含 ``parse`` 字段）。
    纯函数、无副作用，便于单测与回测。
    """
    msgs = [_to_msg(m) for m in messages if (m.get("content") or "").strip()]
    units = [u for u in _dedup(msgs) if u.rep.kind != KIND_IGNORE]
    clusters = _cluster(units)
    now = datetime.now()

    out: list[dict] = []
    for c in clusters:
        cand = _build_candidate(c, now)
        if cand is not None:
            out.append(cand)
    out = _dedupe_candidates(out)
    out.sort(key=lambda c: (c["source"]["first_ts"], c["candidate_id"]))
    return out


def build_manual_candidate(text: str, source: str = "manual",
                           now: datetime | None = None) -> dict[str, Any]:
    """无状态抽取（``POST /api/relay/parse``）：手动输入的文本 -> 一条候选。

    与窗口候选（``build_candidates``）的区别：
      * ``candidate_id`` 是临时值（``m_`` 前缀），**不入 CandidateStream**，
        前端建 Task 时忽略；同文本幂等（重复解析返回同一 id）；
      * ``source.msg_ids`` 为空——手动输入没有原话可回溯；
      * kind=忽略 一律改判 闲聊：用户手动输入的内容不该被当噪声丢掉，
        「像不像任务」由前端展示层提示（仍可保存为低优先级待办）；
      * 相对时间（明天/后天）以**当前时刻**为基准归一化，不是消息时间。

    隐私：只处理、不存储——文本不进窗口、不落盘；簇级模型缓存
    （``_LLM_CACHE``）只在内存里、按内容指纹索引，与窗口候选同级别。
    """
    now = now or datetime.now()
    text = (text or "").strip()
    if not text:
        return {}

    ts = now.strftime("%Y-%m-%d %H:%M:%S")
    payload = {
        "msg_id": "",
        "group_openid": "manual",
        "group_label": "手动添加",
        "sender": "我",
        "content": text,
        "timestamp": ts,
    }
    msg = _to_msg(payload)
    unit = _Unit(msg.group_openid, msg.group_label, [msg])
    cluster = _Cluster(msg.group_openid, msg.group_label)
    cluster.absorb(unit)

    obj = _llm_thread(cluster, now)
    core = _build_from_llm(cluster, unit, obj, now) if obj else _build_from_rules(cluster, unit, now)
    if core["kind"] == KIND_IGNORE:
        core["kind"] = KIND_CHAT

    # 手动输入的先验与群消息不同：用户是**特意**输入的，判成闲聊等于把明示的
    # 任务当噪声丢掉（群聊分类器为 28 万条语料校准过、刻意保守，「去康桥苑开会」
    # 因为「开会」没搭配「要/记得」会被判闲聊）。规则路径给出闲聊时再给两级
    # 宽松判据：含任务词（开会/交/报名…）或有明确时间表达 -> 待办；
    # LLM 路径按语义分类，不在此列。纯「哈哈哈」仍保持闲聊。
    if core["engine"] == "rules" and core["kind"] == KIND_CHAT:
        if any(m in text for m in RULES._TASK_MARKERS) or RULES.parse_time(text, now):
            core["kind"] = KIND_TODO
    # 与窗口候选同一口径：标题不超过 12 字
    core["title"] = RULES.clip_title(str(core.get("title") or ""))

    steps = _rule_steps(cluster)
    due_at = _due_at_ms(core["time_normalized"])
    repeat, repeat_text = repeat_rules_of(text)

    return {
        "candidate_id": "m_" + _hash6(text),
        "rev_seq": 0,
        "thread_id": "",
        "kind": core["kind"],
        "priority": _priority(core["kind"], core["time_normalized"], now),
        # ---- 卡片字段（《任务字段表》v1）----
        "level": _level_of(steps, core["items"]),
        "category": _category_of(core["kind"], core["tags"], core["title"] + core["summary"]),
        "channel": "manual",
        "due_at": due_at,
        "due_text": core["time_text"],
        "repeat": repeat,
        "repeat_text": repeat_text,
        "certainty": int(round(core["confidence"] * 100)),
        "missing_fields": _missing_fields(core["place"], core["who"], due_at),
        # ------------------------------------
        "title": core["title"],
        "summary": core["summary"],
        "time_text": core["time_text"],
        "time_normalized": core["time_normalized"],
        "time_unresolved": core["time_unresolved"],
        "place": core["place"],
        "who": core["who"],
        "deadline": core["deadline"],
        "items": core["items"],
        "steps": steps,
        "tags": core["tags"],
        "confidence": core["confidence"],
        "engine": core["engine"],
        "degraded": bool(core.get("degraded", core.get("engine") != "llm")),
        # 手动来源没有群：group_openid 为空；通道（manual / manual_text /
        # manual_image / manual_file…）放 group_label，前端据此填 Task.sourceKind
        "source": {
            "group_openid": "",
            "group_label": source,
            "senders": ["我"],
            "msg_ids": [],
            "count": 1,
            "first_ts": ts,
            "last_ts": ts,
        },
        "created_at": ts,
    }


_FINGERPRINT_KEYS = (
    "kind", "priority", "level", "category", "channel", "due_at", "due_text",
    "repeat", "repeat_text", "certainty", "missing_fields",
    "title", "summary", "time_text", "time_normalized",
    "time_unresolved", "place", "who", "deadline", "items", "steps", "tags",
    "confidence", "engine", "source",
)


def _fingerprint(c: dict) -> str:
    payload = {k: c.get(k) for k in _FINGERPRINT_KEYS}
    return json.dumps(payload, ensure_ascii=False, sort_keys=True)


def _source_signature(messages: list[dict]) -> str:
    """窗口内容的指纹：只要它没变，候选就不可能变，没必要重算。

    为什么需要这道闸：`/candidates` 是**轮询**接口（每台设备每 5 秒一次）。
    没有它，每次请求都会重跑「去重 + 聚类 + 簇级模型」，而 `build_candidates`
    里的 `now = datetime.now()` 会让 `priority` / `created_at` 随每次请求漂移，
    指纹一变就 `rev_seq + 1` —— 多台设备看到同一条候选在不同时刻被"更新"
    （表现出来就是：同一个消息，不同用户/不同时间看到的总结/字段疑似不一样）。

    指纹只覆盖**会影响候选结果**的输入：msg_id、正文、单条 parse。
    不含 `seq`（顺序由 msg_id/时间决定）与任何当前时间。
    """
    h = hashlib.sha1()
    for m in sorted(messages, key=lambda x: str(x.get("msg_id") or "")):
        h.update(str(m.get("msg_id") or "").encode("utf-8"))
        h.update(b"\x01")
        h.update(str(m.get("content") or "").encode("utf-8"))
        h.update(b"\x02")
        h.update(
            json.dumps(m.get("parse") or {}, ensure_ascii=False, sort_keys=True).encode("utf-8")
        )
        h.update(b"\x03")
    return h.hexdigest()


class CandidateStream:
    """候选流：维护 ``candidate_id -> candidate``，按 ``rev_seq`` 单调递增下发。

    契约 §5.1 的游标语义：
      * 同一 ``candidate_id`` 被后续消息**更新**时重新下发，并带更大的 ``rev_seq``；
      * 内容没变的候选**不重复下发**（不浪费游标）；
      * App 按 ``candidate_id`` upsert，``cursor`` 取本次返回里最大的 ``rev_seq``。

    本类不落盘，只活在内存中（对齐 v1 的 30 分钟窗口合规姿势）。
    """

    def __init__(self) -> None:
        self._by_id: dict[str, dict] = {}
        self._rev = 0
        # 上一次算候选时的窗口指纹（见 `_source_signature`）
        self._sig: str = ""
        # `_run_db` 是 `asyncio.to_thread`：两台设备同时轮询会并发进 rebuild，
        # 没有锁的话 `_by_id` / `_rev` 会被交错改写（同一候选分配两个 rev_seq）。
        self._lock = threading.Lock()

    @property
    def cursor(self) -> int:
        return self._rev

    def rebuild(self, messages: list[dict]) -> list[dict]:
        """用最新窗口内容重算候选，返回**本次发生变化**的候选（已带 rev_seq）。

        **窗口没变就直接返回空**：轮询接口不该每次都重算 + 重调模型。
        这条闸同时保证了「同一时刻所有设备看到的是同一份候选」。
        """
        sig = _source_signature(messages)
        with self._lock:
            if sig == self._sig:
                return []
            # 先算、成功了再记指纹：算挂了下一轮还能重试
            fresh = build_candidates(messages)
            self._sig = sig
            return self._apply(fresh)

    def _apply(self, fresh: list[dict]) -> list[dict]:
        changed: list[dict] = []
        alive: set[str] = set()
        for c in fresh:
            cid = c["candidate_id"]
            alive.add(cid)
            old = self._by_id.get(cid)
            if old is not None and _fingerprint(old) == _fingerprint(c):
                continue
            self._rev += 1
            c["rev_seq"] = self._rev
            if old is not None:
                c["created_at"] = old.get("created_at") or c["created_at"]
            self._by_id[cid] = c
            changed.append(c)
        # 窗口淘汰后消失的候选，同步清理，避免一直下发陈旧数据
        for cid in [k for k in self._by_id if k not in alive]:
            self._by_id.pop(cid, None)
        return changed

    def since(self, after: int = 0, limit: int = 100) -> dict:
        """增量拉取（等价于 ``GET /candidates?after=&limit=`` 的数据部分）。"""
        limit = max(1, min(int(limit or 100), 500))
        items = sorted(self._by_id.values(), key=lambda c: c["rev_seq"])
        out = [c for c in items if c["rev_seq"] > int(after or 0)][:limit]
        cursor = out[-1]["rev_seq"] if out else int(after or 0)
        return {
            "candidates": out,
            "cursor": cursor,
            "server_time": _now(),
            "window_minutes": THREAD_GAP_MINUTES,
        }


# ---------------------------------------------------------------- 演示

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    import sqlite3
    from pathlib import Path

    db = Path(__file__).resolve().parent / "bot.db"
    conn = sqlite3.connect(db)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT sender_name, content, COALESCE(timestamp,created_at) t, msg_id, group_openid "
        "FROM group_messages ORDER BY created_at"
    ).fetchall()
    conn.close()

    sample = [
        {
            "group_openid": r["group_openid"] or "g_test",
            "group_label": "测试群",
            "sender": r["sender_name"] or "",
            "content": r["content"] or "",
            "timestamp": r["t"] or "",
            "msg_id": r["msg_id"] or "",
        }
        for r in rows
    ]
    print("输入消息：", len(sample), "条")
    for c in build_candidates(sample):
        print(f"\n▸ {c['candidate_id']}  [{c['kind']}/{c['priority']}]  {c['title']}")
        print(f"   总结：{c['summary']}")
        print(f"   时间：{c['time_normalized'] or '(未确定)'}  来源：{c['source']['count']} 条 {c['source']['msg_ids']}")
