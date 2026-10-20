# -*- coding: utf-8 -*-
"""知了 · 后端解析工作线程。

把「群消息 -> 结构化事件」放到后台线程做，**不阻塞机器人推送到中继的 3 秒超时**：
  1. relay.ingest_group_message 只把消息塞进队列就立刻返回；
  2. 本线程取出消息，先试小模型（llm_parse），校验不过或模型不可用时回退规则（pipeline_proto）；
  3. 解析结果写进 payload["parse"]，再放进 30 分钟窗口，App 拉到的第一条就带结构化结果。

安全边界（对齐《信息总结方案_端侧.md》）：
  - 模型字段值必须是原文子串（llm_parse 里已校验，不是就清空）；
  - 归一化时间由程序算，模型只给原文时间表达；
  - 模型完全不可用时行为与改造前一致（纯规则），不影响主流程。
"""

from __future__ import annotations

import logging
import queue
import threading
from typing import Any, Callable

import llm_parse
import pipeline_proto as RULES
import card_fields

try:
    import group_lexicon  # 按群自学习的地点词表（缺失也不影响主流程）
except Exception:  # noqa: BLE001
    group_lexicon = None

log = logging.getLogger("zhiliao.worker")

_QUEUE_MAX = 2000
_q: "queue.Queue[dict]" = queue.Queue(maxsize=_QUEUE_MAX)
_lock = threading.Lock()
_started = False
_enabled = False

# 主题分类（用户画像载体），模型给不出时的关键词兜底
_CATEGORY_HINTS: list[tuple[str, tuple[str, ...]]] = [
    ("教务", ("教务", "选课", "考试", "成绩", "实验", "作业", "课程", "讲座",
              "答辩", "学籍", "补考", "重修", "心理委员", "培训")),
    ("招聘", ("招聘", "实习", "校招", "内推", "简历", "岗位", "面试", "春招", "秋招", "兼职")),
    ("活动", ("活动", "比赛", "竞赛", "报名", "社团", "招新", "晚会", "演出", "志愿", "签到")),
    ("二手", ("二手", "出售", "转让", "收购", "闲置", "拼单", "租房", "转租")),
]


def enabled() -> bool:
    return _enabled


def start() -> None:
    """启动工作线程并预热模型。由 server.py 在服务就绪时调用。"""
    global _started, _enabled
    with _lock:
        if _started:
            return
        _started = True
        _enabled = True
    threading.Thread(target=_run, daemon=True, name="llm-parse").start()
    log.info("解析工作线程已启动（Ollama 可用=%s）", llm_parse.available())


def submit(payload: dict) -> None:
    """异步入队；队列满时直接按规则进窗口，保证不丢消息。"""
    try:
        _q.put_nowait(payload)
    except queue.Full:
        log.warning("解析队列已满，本条按规则处理")
        _store(payload, _rules_parse(payload))


# ---------------------------------------------------------------- 线程体


def _run() -> None:
    # 预热放在线程里，避免拖慢服务启动
    try:
        if llm_parse.available():
            llm_parse.warmup()
    except Exception as exc:  # noqa: BLE001
        log.warning("模型预热失败：%s", exc)

    while True:
        payload = _q.get()
        try:
            parse = _parse(payload)
        except Exception as exc:  # noqa: BLE001
            log.warning("解析异常，回退规则：%s", exc)
            parse = None
        try:
            _store(payload, parse if parse is not None else _rules_parse(payload))
        finally:
            _q.task_done()


def _store(payload: dict, parse: dict) -> None:
    """把结果挂到消息上，再放进中继窗口（延迟导入 relay 规避循环依赖）。"""
    import relay

    payload["parse"] = parse
    try:
        relay.WINDOW.add(payload.get("msg_id") or "", payload)
    except Exception as exc:  # noqa: BLE001
        log.warning("写入中继窗口失败：%s", exc)


# ---------------------------------------------------------------- 解析


def _places_of(payload: dict) -> list[str]:
    """取该群自学习到的地点词表（top-20，没有就返回空，行为与改造前一致）。"""
    if group_lexicon is None:
        return []
    gid = payload.get("group_openid") or ""
    if not gid:
        return []
    try:
        return group_lexicon.STORE.words_of_category(gid, "place", limit=20)
    except Exception as exc:  # noqa: BLE001
        log.warning("读取群地点词表失败：%s", exc)
        return []


def _parse(payload: dict) -> dict[str, Any] | None:
    content = payload.get("content") or ""
    if not content.strip():
        return None
    text = RULES.normalize(content)
    if not text:
        return None
    # 系统消息/拍一拍不值得调模型，直接交给规则判为「忽略」
    if RULES._SYSTEM_RE.search(text):
        return None
    base = RULES._parse_ts(payload.get("timestamp") or "")

    if llm_parse.available():
        obj = llm_parse.extract(text)
        if obj is not None:
            return _from_llm(obj, text, payload, base)
    return None


def _from_llm(obj: dict[str, Any], text: str, payload: dict, base) -> dict[str, Any]:
    kind: str = obj["kind"]

    # 归一化时间由程序算：优先用模型给的原文时间表达，推不出再退回整条正文
    slot = None
    time_text: str = obj.get("time_text") or ""
    if time_text:
        slot = RULES.parse_time(time_text, base)
        if slot is not None and not slot.unresolved and ":" not in slot.normalized:
            slot = RULES._attach_clock(slot, time_text)
        if slot is not None:
            slot.text = time_text        # 还原成校验过的原文子串（_attach_clock 会重组成非原文）
    if slot is None:
        slot = RULES.parse_time(text, base)

    action: str = obj.get("action") or ""
    title: str = (obj.get("title") or "").strip()[:24] or (action or text)[:22]
    conf = _confidence(kind, slot, action, obj.get("place") or "")
    # 地点：模型给的优先；模型没给就用该群自学习到的地点词表兜底
    place: str = obj.get("place") or RULES._find_known_place(text, _places_of(payload))

    ev = RULES.Event(
        kind=kind,
        title=title,
        action=action or text,
        time=slot,
        place=place,
        who=obj.get("who") or "",
        deadline=obj.get("deadline") or "",
        confidence=conf,
        source_text=text,
        sender=payload.get("sender") or "",
        timestamp=payload.get("timestamp") or "",
        msg_id=payload.get("msg_id") or "",
        tags=list(obj.get("tags") or []),
    )
    if kind in (RULES.EVENT_CHAT, RULES.EVENT_IGNORE):
        summary = ""
    else:
        model_summary = (obj.get("summary") or "").strip()
        # 模型一旦在结构化槽位（action/time/place/who/deadline）上编造过（被安全闸清空），
        # 就不再信任它润色的 summary —— 否则会出现「原文明天、总结写成后天」这类错误。
        # 这种情况下改用模板拼句：措辞仍全部来自原话。
        render_obj = dict(obj)
        if place:
            render_obj["place"] = place        # 群词表补的地点也来自原话，可安全进模板
        if model_summary and not obj.get("_nullified"):
            summary = model_summary
        else:
            summary = _render_llm(kind, title, slot, render_obj, conf)
    return _to_payload(ev, "llm", obj.get("category") or _category_of(text, kind),
                       summary, obj.get("items"))


def _rules_parse(payload: dict) -> dict[str, Any]:
    text = RULES.normalize(payload.get("content") or "")
    ev = RULES.build_event(
        payload.get("content") or "",
        sender=payload.get("sender") or "",
        timestamp=payload.get("timestamp") or "",
        msg_id=payload.get("msg_id") or "",
        extra_places=_places_of(payload),
    )
    return _to_payload(ev, "rules", _category_of(text, ev.kind))


def _confidence(kind: str, slot, action: str, place: str) -> float:
    conf = 0.5
    if slot is not None:
        conf += 0.10 if getattr(slot, "unresolved", False) else 0.25
    if action and len(action) >= 3:
        conf += 0.10
    if place:
        conf += 0.10
    if kind in (RULES.EVENT_TODO, RULES.EVENT_NOTICE):
        conf += 0.10
    conf = min(0.95, conf)
    if kind in (RULES.EVENT_CHAT, RULES.EVENT_IGNORE):
        conf = min(conf, 0.3)
    return round(conf, 2)


def _render_llm(kind: str, title: str, slot, obj: dict[str, Any], conf: float) -> str:
    """模板成句（槽位来自模型但已校验为原文子串）。

    刻意不复用 pipeline_proto.render_one_line：那条路会从整条正文里"抠掉时间和地点"，
    对长通知会抠得句子破碎（且 _strip_filler 会误删词内的"请"）。
    这里直接用已校验的 title/action + 槽位拼句，措辞仍全部来自原文。
    """
    if kind in (RULES.EVENT_CHAT, RULES.EVENT_IGNORE):
        return ""
    body = title or (obj.get("action") or "")
    parts: list[str] = [body] if body else []
    if slot is not None:
        parts.append("时间：" + slot.display)
    if obj.get("place"):
        parts.append("地点：" + str(obj["place"]))
    if obj.get("who") and kind == RULES.EVENT_TODO:
        parts.append("对象：" + str(obj["who"]))
    if obj.get("deadline"):
        parts.append("截止：" + str(obj["deadline"]))
    items = obj.get("items") or []
    if items:
        parts.append("需带/注意：" + "、".join(str(x) for x in items))
    out = "；".join(p for p in parts if p)
    if out and conf < 0.5:
        out += "（字段不完整，建议人工确认）"
    return out


def _category_of(text: str, kind: str) -> str:
    for cat, words in _CATEGORY_HINTS:
        for w in words:
            if w in text:
                return cat
    if kind in (RULES.EVENT_CHAT, RULES.EVENT_IGNORE):
        return "闲聊"
    return "教务"


def _to_payload(ev: RULES.Event, engine: str, category: str,
                summary: str | None = None,
                items: list[str] | None = None) -> dict[str, Any]:
    """转成下发给 App 的结构（字段名与 App CampusEvent / ParsedInfo 对应）。

    除了原有字段，还带上《任务字段表&idea更新》v1 的**卡片字段**
    （`priority` / `level` / `due_at` / `repeat` / `steps` / `certainty` …）。
    它们与候选流共用 `card_fields` 同一套规则——否则同一件事在「待办页」
    和「候选卡片」上会显示成两种样子。

    注意 `category` 仍是**消息主题**（教务/活动/招聘/二手/闲聊），
    与 `card_fields` 里的「作业/考试/活动/通知/其他」是两套口径，不要混。
    """
    its = list(items or [])
    text = ev.one_line if summary is None else summary
    # 单条消息最多一个动作，作为唯一子步骤（副卡片圆圈读 done）
    steps: list[dict[str, Any]] = []
    if (ev.action or "").strip():
        steps.append({"content": ev.action.strip(), "done": 0})
    cf = card_fields.card_fields(
        kind=ev.kind,
        title=ev.title,
        summary=text,
        time_text=ev.time.text if ev.time else "",
        time_normalized=ev.time.normalized if ev.time else "",
        place=ev.place,
        who=ev.who,
        items=its,
        tags=list(ev.tags),
        confidence=ev.confidence,
        steps=steps,
        repeat_source=ev.source_text,
        channel="bot",
    )
    # `card_fields.category` 是「作业/考试/活动/通知/其他」这套**任务类型**；
    # 下发字段里的 `category` 沿用既有的**消息主题**（教务/活动/招聘/二手/闲聊，
    # 已被 236 条评测集覆盖）。两者不混，任务类型由 App 侧按同规则算。
    cf.pop("category", None)
    return {
        "engine": engine,
        "kind": ev.kind,
        "category": category,
        "title": ev.title,
        "action": ev.action,
        "summary": text,
        "items": its,
        "sourceText": ev.source_text,
        "timeText": ev.time.text if ev.time else "",
        "timeNormalized": ev.time.normalized if ev.time else "",
        "timeUnresolved": bool(ev.time.unresolved) if ev.time else False,
        "place": ev.place,
        "who": ev.who,
        "deadline": ev.deadline,
        "confidence": ev.confidence,
        "tags": list(ev.tags),
        "steps": steps,
        **cf,
    }
