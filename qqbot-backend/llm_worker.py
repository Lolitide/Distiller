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
import os
import queue
import re
import threading
import time
from datetime import datetime
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
# 出队优先级：0 = 可执行事项（待办/通知/活动/出行计划）先跑，1 = 其余。
# 突发时先让用户真正会看到的东西出来，闲聊晚一点不影响体验。
_PRIO_ACTIONABLE = 0
_PRIO_OTHER = 1
_q: "queue.PriorityQueue[tuple[int, int, dict]]" = queue.PriorityQueue(maxsize=_QUEUE_MAX)
_seq_lock = threading.Lock()
_seq = 0
# 工作线程数：默认 1（8GB 显存下最稳）。Ollama 需 OLLAMA_NUM_PARALLEL>=N 才有真并行。
_WORKERS = max(1, min(4, int(os.environ.get("QQBOT_LLM_WORKERS", "1") or "1")))
_lock = threading.Lock()
_started = False
_enabled = False

# 运行指标（只增不减，供 /health 暴露；纯计数，不含任何消息内容）
_STATS: dict[str, int] = {
    "processed": 0,     # 出队处理条数
    "llm_calls": 0,     # 真正调用模型的次数
    "llm_none": 0,      # 模型返回 None（校验不过/超时）的次数
    "errors": 0,        # 解析抛异常次数
    "degraded": 0,      # 队列满、直接按规则处理的次数
    "prescreen_skipped": 0,  # 规则预筛直接判闲聊、没调模型的次数
    "last_ms": 0,       # 最近一条的处理耗时（毫秒）
}
_STATS_LOCK = threading.Lock()

# 规则预筛：明显闲聊直接跳过模型。默认开，`QQBOT_LLM_PRESCREEN=0` 一键关闭。
# 判据刻意保守（见 prescreen_skip 的注释）——宁可多调一次模型，也不漏待办。
_PRESCREEN_ON = (os.environ.get("QQBOT_LLM_PRESCREEN", "1") or "1").strip() != "0"
# 超过这个长度就不当"明显闲聊"（长消息更可能夹带信息）
_PRESCREEN_MAX_CHARS = 30

# 预筛额外排除项：规则 classify 有时把它们当闲聊，但实际是事项/活动。
# 例：「智慧社区签到签退码」「挑战网招新啦」「有无组队的，传智杯还缺一个人」。
# 刻意放在 llm_worker 而不是 pipeline_proto.classify —— 不动分级基线。
_PRESCREEN_ACTIONABLE_RE = re.compile(
    r"签到|签退|招新|纳新|收人|缺人|组队|拼车|转让|出售|收购|"
    r"讲座|宣讲|公开课|投票|问卷|填表|面试|培训|班会|集合|开会|领取|缴费|交费"
)


def _bump(**kw: int) -> None:
    with _STATS_LOCK:
        for k, v in kw.items():
            _STATS[k] = _STATS.get(k, 0) + v


def _set_stat(key: str, value: int) -> None:
    """`last_ms` 这类「最新值」用 set，不能用累加。"""
    with _STATS_LOCK:
        _STATS[key] = value


def stats() -> dict[str, Any]:
    """/health 用的运行快照。**只读计数，不含消息内容**。"""
    with _STATS_LOCK:
        snap: dict[str, Any] = dict(_STATS)
    snap["queue_depth"] = _q.qsize()
    snap["queue_max"] = _QUEUE_MAX
    snap["workers"] = _WORKERS
    snap["prescreen_on"] = _PRESCREEN_ON
    snap["available"] = llm_parse.available()
    snap["enabled"] = _enabled
    snap["model"] = llm_parse.MODEL
    # 许可证事实（本机 `ollama show qwen3.5:9b --license` 实测为 Apache-2.0）。
    # App「关于」页据此展示来源；不在这里猜测其它模型。
    snap["license"] = "Apache-2.0"
    return snap


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
    # 预热单独一个线程：多 worker 时不能每个都预热一遍（会同时载入几份模型）
    threading.Thread(target=_warmup, daemon=True, name="llm-warmup").start()
    for i in range(_WORKERS):
        threading.Thread(target=_run, daemon=True, name=f"llm-parse-{i}").start()
    log.info("解析工作线程已启动（workers=%d，Ollama 可用=%s）", _WORKERS, llm_parse.available())


def _warmup() -> None:
    try:
        if llm_parse.available():
            llm_parse.warmup()
    except Exception as exc:  # noqa: BLE001
        log.warning("模型预热失败：%s", exc)


def _priority_of(payload: dict) -> int:
    """入队时先粗判一次（复用规则分类），让可执行事项排在闲聊前面。"""
    try:
        kind = RULES.classify(RULES.normalize(payload.get("content") or ""))
    except Exception:  # noqa: BLE001
        return _PRIO_OTHER
    if kind in (RULES.EVENT_TODO, RULES.EVENT_NOTICE, RULES.EVENT_ACTIVITY, RULES.EVENT_PLAN):
        return _PRIO_ACTIONABLE
    return _PRIO_OTHER


def submit(payload: dict) -> None:
    """异步入队；队列满时直接按规则进窗口，保证不丢消息。"""
    global _seq
    with _seq_lock:
        _seq += 1
        seq = _seq
    try:
        _q.put_nowait((_priority_of(payload), seq, payload))
    except queue.Full:
        _bump(degraded=1)
        log.warning("解析队列已满，本条按规则处理")
        _store(payload, _rules_parse(payload))


# ---------------------------------------------------------------- 线程体


def _run() -> None:
    while True:
        _prio, _n, payload = _q.get()
        started = time.perf_counter()
        try:
            parse = _parse(payload)
        except Exception as exc:  # noqa: BLE001
            _bump(errors=1)
            log.warning("解析异常，回退规则：%s", exc)
            parse = None
        try:
            _store(payload, parse if parse is not None else _rules_parse(payload))
            _bump(processed=1)
            _set_stat("last_ms", int((time.perf_counter() - started) * 1000))
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


def prescreen_skip(text: str) -> bool:
    """明显闲聊 -> 真接跳过模型，交给规则。

    保守判据（四条全中才跳过）：
      1. 短消息（≤30 字）；长消息更可能夹带信息；
      2. 没有强任务词 / 任务搭配（记得、务必、提交作业…）；
      3. 没有通知词 / 出行词（报名、截止、比赛、返校…）；
      4. 规则解析不出时间（有时间表达就交给模型判断）。

    为什么这么小心：语料里 97.7% 不是待办，但"漏掉真待办"比"多调一次模型"代价高得多。
    预筛的收益必须用 `eval_prescreen.py` 在 236 条集上验证，`QQBOT_LLM_PRESCREEN=0` 可随时关闭。
    """
    if not _PRESCREEN_ON:
        return False
    t = (text or "").strip()
    if not t or len(t) > _PRESCREEN_MAX_CHARS:
        return False
    if RULES._TASK_STRONG_RE.search(t) or RULES._TASK_COLLOC_RE.search(t):
        return False
    if RULES._NOTICE_RE.search(t) or RULES._PLAN_RE.search(t):
        return False
    if _PRESCREEN_ACTIONABLE_RE.search(t):
        return False
    try:
        if RULES.parse_time(t, datetime.now()) is not None:
            return False
    except Exception:  # noqa: BLE001
        return False
    return RULES.classify(t) in (RULES.EVENT_CHAT, RULES.EVENT_IGNORE)


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
    # 明显闲聊也不值得调模型（预筛可关：QQBOT_LLM_PRESCREEN=0）。
    # 模型本来就不在线时不做预筛——反正也是走规则，白算一遍分类。
    model_ready = llm_parse.available()
    if model_ready and prescreen_skip(text):
        _bump(prescreen_skipped=1)
        return None
    base = RULES._parse_ts(payload.get("timestamp") or "")

    if model_ready:
        _bump(llm_calls=1)
        obj = llm_parse.extract(text)
        if obj is not None:
            return _from_llm(obj, text, payload, base)
        _bump(llm_none=1)
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
    # 单条消息最多一个动作，作为唯一子步骤（副卡片圆圈读 done）。
    # 超过 15 字的动作不放进 steps —— 那是整句原文，不是步骤。
    steps: list[dict[str, Any]] = []
    action = (ev.action or "").strip()
    if action and len(action) <= 15:
        steps.append({"content": action, "done": 0})
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
        "title": RULES.clip_title(ev.title),
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
