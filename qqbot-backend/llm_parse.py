# -*- coding: utf-8 -*-
"""知了 · 后端小模型解析层（Ollama + qwen3:4b，受约束 JSON 抽取）。

设计依据是《信息总结方案_端侧.md》§1.C / §5，三条硬约束：
  1. 模型只输出 JSON，字段值只能来自封闭枚举；
  2. 每个字段值必须是**原文里逐字出现的子串**，抽不到就空串，禁止编造；
  3. 结果必须校验，校验不过整体丢弃 -> 由调用方回退到规则（pipeline_proto）。

只用标准库（urllib），不新增 pip 依赖。
"""

from __future__ import annotations

import json
import logging
import os
import re
import threading
import time
import urllib.error
import urllib.request
from typing import Any

log = logging.getLogger("zhiliao.llm")

OLLAMA_BASE = "http://127.0.0.1:11434"
OLLAMA_CHAT = OLLAMA_BASE + "/api/chat"
OLLAMA_TAGS = OLLAMA_BASE + "/api/tags"

MODEL = "qwen3.5:9b"
TIMEOUT = 30          # 单次推理超时（秒）；首次加载模型可能接近上限
WARMUP_TIMEOUT = 180  # 预热超时：9b 约 7GB，首次载入显存可能远超 30s
NUM_CTX = 8192       # 长通知较多，上下文给足，避免输入被截断导致"总结不全"
NUM_PREDICT = 600    # 摘要最长 120 字，留足输出余量（默认值偏小会把 JSON 截断）
KEEP_ALIVE = "30m"

# 与 App 侧 nlp/EventTypes.ets、Types.ets 对齐的封闭枚举
KINDS = ["待办", "通知", "活动", "出行计划", "闲聊", "忽略"]
CATEGORIES = ["教务", "活动", "招聘", "二手", "闲聊"]

# 校园/游戏黑话：小模型最容易栽在这一步（实测 qwen3:4b 把「开打」理解成「打架/战斗」）。
# 只用于**理解**消息语义，不据此改写原文。
_SLANG = """

常见黑话（只用于理解语义，不要把下面的解释写进输出）：
- 开打 / 开黑 / 上号 / 开盘 = 开始比赛或开始打游戏，**不是打架、冲突、战斗**
- 组队 / 求带 / 有无组队的 = 找人一起参加比赛或游戏
- 歪歪歪 / 在吗 / 有人吗 = 打招呼，不是要办的事
- 传智杯 / 蓝桥杯 / 挑战杯 = 比赛名称
- ddl / 截止 = 提交期限"""

# 参与「原文子串」硬校验的字段：这些是结构化/会触发提醒的字段，必须可回原文核对。
# title 与 summary 不在此列——它们允许模型自然润色（用户要求"别太生硬"）。
_SUBSTRING_FIELDS = ("action", "time_text", "place", "who", "deadline")

# 这些 kind 至少要有一个有效字段，否则视为"没抽到"-> 回退规则
_ACTIONABLE = ("待办", "通知", "活动", "出行计划")

SCHEMA: dict[str, Any] = {
    "type": "object",
    "properties": {
        "kind": {"type": "string", "enum": KINDS},
        "category": {"type": "string", "enum": CATEGORIES},
        "title": {"type": "string"},
        "action": {"type": "string"},
        "time_text": {"type": "string"},
        "place": {"type": "string"},
        "who": {"type": "string"},
        "deadline": {"type": "string"},
        "summary": {"type": "string"},
        "items": {"type": "array", "items": {"type": "string"}},
        "steps": {"type": "array", "items": {"type": "string"}},
        "tags": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["kind", "category", "title", "action", "time_text", "place", "who", "deadline",
                 "summary"],
}

SYSTEM = """你是消息整理助手。先判断这条 QQ 群消息属于哪一类，再抽取结构化字段，并写一句自然通顺的总结。
输出 JSON。

先把消息归类到 kind（六选一）：
- 待办：要某个人去做的事，常含“记得/别忘/需要/请/务必/尽快/截止/登记/交/买”。
  例：“明天去超市买点吃的”“周五前交实验报告”
- 通知：面向大家的正式告知，常含“通知/报名/截止/比赛/大赛/讲座/培训”。
  例：“心理委员培训改为6月3日下午2:30在主楼D104”
- 活动：社团招新、晚会、汇演等可参加的活动。例：“挑战网招新”
- 出行计划：含交通方式或目的地。例：“后天先去火车站坐车，再去北京旅游”
- 闲聊：疑问、吐槽、水群。例：“没签到签退咋办”“应该没办法了”
- 忽略：**只用于**纯数字、纯表情、纯寒暄（“好的”“在吗”“？”）。
  只要消息里有要做的事、明确的时间或地点，就归到上面 4 类之一，不要用忽略。

字段要求：
1. kind 只能是：待办 / 通知 / 活动 / 出行计划 / 闲聊 / 忽略
2. 【结构化字段】action / time_text / place / who / deadline 的值必须是原文里【逐字出现】的一段，
   不许改写、不许补全；原文里没有就输出空字符串。这五个会用于日历/提醒，必须能被原文核对。
3. time_text 填原文里的时间表达（如“明天上午9点”“周五前”），不要做任何换算
4. category 只能是：教务 / 活动 / 招聘 / 二手 / 闲聊（消息主题，与 kind 独立）
5. title 是【4~16 字】的标题，要概括**这条消息在讲什么事**（什么事项），
   例如“综测安排”“奖学金公示”“上课地点变更”“四六级考试提醒”。规则：
   - 原文有通知名/文件名（《…》）时，从里面提炼主题；
   - **禁止**用地点、人名、时间、单个字当标题
     （“东21-121办公室门口”“补”“各位同学”都是错的）；
   - 不得编造原文没有的信息；实在写不出就输出空字符串
6. summary 是自然连贯的总结（**不超过 120 字**），是给用户看的主体，**要写全**。
   可以润色、连词成句、调整语序，不要只是把原文碎片用分号拼起来。
   尽量覆盖：**什么事、什么时间、面向谁、要做什么、需要交/带什么、有哪些注意事项与限定**，
   不要漏掉重要信息（例如“请认真对待”“不再重新核算前面的时间段”“成绩截至某日”“逾期不予受理”）。
   但**不得改写或新增原文里的时间、地点、数字、人名**，也不能自己补充原文没说的判断。
7. items 是原文里提到的【必须携带/准备的物品、材料，以及关键注意事项】，
   例如“准考证”“身份证”“电池”；每条必须逐字取自原文、不超过 14 字，最多 5 条；
   原文没提就输出空数组 []
8. steps 是完成这件事的**执行步骤**：0~3 条，每条不超过 15 字，按先后顺序；
   只写具体动作（如“确认报名时间”“准备身份证”），不要重复标题；
   原文没有足够信息就输出 []，**不要编造条件**
只输出 JSON，不要输出解释。"""

# 簇（Thread）级 prompt：一次看多行文本，产出**一条**综合候选。
# 用于 v2「去重 + 聚类 + 综合总结」（见 04_API契约_v2_草案.md §3.3）。
THREAD_SYSTEM = """你是消息整理助手。下面给你的是**同一个话题簇**里的多条 QQ 群消息（每行一条，可能有人先提问、有人补充）。
请把它们当成**一件事**来理解，只输出**一条**综合结果，JSON 格式。

先把这件事归类到 kind（六选一）：
- 待办：要某个人去做的事（记得/别忘/需要/请/务必/尽快/截止/交/买）
- 通知：面向大家的正式告知（通知/报名/截止/比赛/大赛/讲座/培训）
- 活动：可参加的社团活动、比赛、招新、晚会
- 出行计划：含交通方式或目的地
- 闲聊：纯水群，没有可执行信息
- 忽略：只用于纯数字、纯表情、纯寒暄

字段要求：
1. kind 只能是：待办 / 通知 / 活动 / 出行计划 / 闲聊 / 忽略
2. 【结构化字段】action / time_text / place / who / deadline 的值必须是**输入多行文本里逐字出现**的一段，
   不许改写、不许补全；文本里没有就输出空字符串。
3. time_text 填原文里的时间表达（如“后天”“明天上午9点”“周五前”），不做任何换算
4. category 只能是：教务 / 活动 / 招聘 / 二手 / 闲聊
5. title 是【4~16 字】的标题，概括**整簇在讲什么事**；跨消息补齐的信息要用上
   （例如“比赛是定在后天” + “啥比赛” + “传智杯” → 标题「传智杯比赛」）。
   禁止用地点、人名、时间、单个字当标题；不得编造，写不出就输出空字符串
6. summary 是**综合总结**（不超过 120 字），把整簇信息合成一句通顺的话
   （例“传智杯比赛在后天举行。”）。可以润色、连词成句，但**不得改写或新增原文里的
   时间、地点、数字、人名**，也不能补充原文没说的判断。
7. items 是原文里提到的必须携带/准备的物品、材料与关键注意事项，逐字取自原文、每条≤14字、最多5条；没有就输出 []
8. steps 是完成这件事的**执行步骤**：2~5 条，每条不超过 15 字，按先后顺序；
   只写具体动作（如“确认报名时间”“准备身份证”“提交申请表”），不要重复标题、
   不要照抄整句原文；原文信息不足就输出 []，**不要编造原文没有的条件**
只输出 JSON，不要输出解释。"""

# 两套 prompt 共用同一份黑话表
SYSTEM += _SLANG
THREAD_SYSTEM += _SLANG


# ---------------------------------------------------------------- prompt 变体（A/B）
# 现用 prompt 是照 Qwen3 的指令风格写的。换模型（实测 qwen3.5:4b）时它对「忽略」的
# 边界理解不同、更激进地把短闲聊判成「忽略」。这里提供一份「tuned」变体用于对比，
# 默认仍是 base，不影响生产。

def _patch(text: str, pairs: tuple) -> str:
    for old, new in pairs:
        if old not in text:
            log.warning("prompt patch 未命中：%r", old[:24])
            continue
        text = text.replace(old, new)
    return text


_SINGLE_TUNED = _patch(SYSTEM, (
    ("只要消息里有要做的事、明确的时间或地点，就归到上面 4 类之一，不要用忽略。",
     "只要这句话在表达意思（吐槽、问候、感慨、提问、邀约都算），**一律用「闲聊」**。\n"
     "    **「忽略」仅用于没有任何内容的输入**：纯数字、纯表情、纯标点、单独一个字母缩写。\n"
     "    拿不准的时候，用「闲聊」，不要用「忽略」。"),
    ("- 通知：面向大家的正式告知，常含“通知/报名/截止/比赛/大赛/讲座/培训”。",
     "- 通知：面向**一群人**的通告/安排/变更，常含“通知/报名/截止/比赛/大赛/讲座/培训”。\n"
     "  只针对**某个人**的具体差事 → 待办；面向群体的告知 → 通知。"),
))

_THREAD_TUNED = _patch(THREAD_SYSTEM, (
    ("- 忽略：只用于纯数字、纯表情、纯寒暄",
     "- 忽略：**仅用于没有任何内容的输入**（纯数字、纯表情、纯标点）；\n"
     "  只要在表达意思（哪怕只是吐槽/问候/感慨），就用「闲聊」，拿不准也用「闲聊」"),
))

# 少样本示例（few-shot）。
# 教训：第一版只放了"有实义"的例子（10 条里 7 条是通知/待办/活动），模型学到的不是边界，
# 而是**"大多数消息都有实义"这个先验** —— 闲聊→待办从 8 条涨到 14 条。
# 所以这一版**按真实分布配比**（实测语料 80% 是闲聊），闲聊/忽略占多数，
# 并且优先放**当前真正被判错的那几条**（它们是"看起来像任务、其实是闲聊"的硬样本）。
_FEWSHOT = """

以下是几条示例，照着它的判断口径（注意边界），但不要照抄内容。
注意：群里**大多数消息都是闲聊**，不要看到一点像任务的字眼就判成待办/通知。

输入：我们是团员证，申请书，入团申请书全部塞档案袋里
输出：{"kind":"闲聊","title":"","summary":""}

输入：有一个自己做实验当场交
输出：{"kind":"闲聊","title":"","summary":""}

输入：如果找不到的话可以问问教官或辅导员，军训配件一般可以现场额外补买的
输出：{"kind":"闲聊","title":"","summary":""}

输入：感觉今年冬天来得挺早的
输出：{"kind":"闲聊","title":"","summary":""}

输入：下午两点开打
输出：{"kind":"闲聊","title":"","time_text":"下午两点","summary":""}

输入：124124
输出：{"kind":"忽略","title":"","summary":""}

输入：军训服明天在宿舍楼下发
输出：{"kind":"通知","title":"发军训服","time_text":"明天","place":"宿舍","summary":"明天在宿舍楼下发军训服。"}

输入：记得带准考证和收音机电池
输出：{"kind":"待办","title":"带准考证和收音机电池","items":["准考证","收音机电池"],"summary":"记得带准考证和收音机电池。"}

输入：有无组队的，传智杯还缺一个人
输出：{"kind":"活动","title":"传智杯组队","summary":"传智杯还缺一个人，有人组队吗。"}
"""

PROMPT_VARIANTS: dict[str, tuple[str, str]] = {
    "base": (SYSTEM, THREAD_SYSTEM),
    "tuned": (_SINGLE_TUNED, _THREAD_TUNED),
    "fs": (_SINGLE_TUNED + _FEWSHOT, _THREAD_TUNED + _FEWSHOT),
}


def set_prompt(name: str) -> bool:
    """切换 prompt 变体（A/B 评测用）。返回是否切换成功。"""
    global SYSTEM, THREAD_SYSTEM
    if name not in PROMPT_VARIANTS:
        return False
    SYSTEM, THREAD_SYSTEM = PROMPT_VARIANTS[name]
    return True


# 环境变量可覆盖；**默认用 tuned**（实测 base/tuned 对 qwen3:4b 与 qwen3.5 都更好或持平）
set_prompt(os.environ.get("QQBOT_LLM_PROMPT", "tuned").strip())

# ---------------------------------------------------------------- 健康检查缓存

_health_lock = threading.Lock()
_health_ok = False
_health_at = 0.0
_HEALTH_TTL = 30.0


def _ping() -> bool:
    try:
        with urllib.request.urlopen(OLLAMA_TAGS, timeout=2) as resp:
            return int(getattr(resp, "status", 200)) == 200
    except Exception:
        return False


def available() -> bool:
    """Ollama 是否可用（30 秒缓存，避免每条消息都探活）。"""
    global _health_ok, _health_at
    now = time.time()
    with _health_lock:
        if now - _health_at < _HEALTH_TTL:
            return _health_ok
    ok = _ping()
    with _health_lock:
        _health_ok = ok
        _health_at = now
    return ok


# ---------------------------------------------------------------- 调用与校验


def _post(body: dict[str, Any], timeout: float = TIMEOUT) -> dict[str, Any]:
    req = urllib.request.Request(
        OLLAMA_CHAT,
        data=json.dumps(body, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def extract(text: str, system: str | None = None, evidence_title: bool = False) -> dict[str, Any] | None:
    """对**已归一化**的文本做抽取；校验通过返回 dict，否则 None（调用方回退规则）。

    ``system``：不传则用当前生效的 prompt 变体（见 ``set_prompt``）。
    ``evidence_title``：簇级抽取时置 True —— 标题若为原文子串也算「抽到了」的证据
    （多轮对话里结构化槽位常为空，但标题/总结已足够有价值）。
    """
    if system is None:
        system = SYSTEM
    if not text or not text.strip():
        return None

    base_body: dict[str, Any] = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": text},
        ],
        "stream": False,
        "format": SCHEMA,
        "keep_alive": KEEP_ALIVE,
        "options": {"temperature": 0, "num_ctx": NUM_CTX, "num_predict": NUM_PREDICT},
    }

    data: dict[str, Any] | None = None
    for with_think in (True, False):
        body = dict(base_body)
        if with_think:
            body["think"] = False        # Qwen3 关闭思考链（新版 Ollama 支持）
        try:
            data = _post(body)
            break
        except urllib.error.HTTPError as exc:
            if with_think and exc.code in (400, 404, 422):
                continue                  # 老版本不认 think 参数，去掉重试一次
            log.warning("llm http error: %s", exc)
            return None
        except Exception as exc:
            log.warning("llm request failed: %s", exc)
            return None

    if data is None:
        return None

    try:
        content = (data.get("message") or {}).get("content") or ""
        obj = json.loads(content)
    except Exception as exc:
        log.warning("llm bad json: %s", exc)
        return None

    if not isinstance(obj, dict):
        return None
    return validate(obj, text, evidence_title=evidence_title)


def chat(
    messages: list[dict[str, Any]],
    schema: dict[str, Any] | None = None,
    timeout: float = TIMEOUT,
    num_predict: int = NUM_PREDICT,
) -> str | None:
    """通用单轮调用（供画像归纳等其它模块复用）。

    与 ``extract`` 共用同一套「think 参数不被支持就去掉重试一次」的兼容逻辑，
    但**不做任何校验**：安全闸由调用方按自己的语义定
    （画像的闸是「词必须出自给定词表」，不是「原文子串」，见 ``profile_summarize``）。

    返回模型正文；模型不可用 / 请求失败 / 返回空 一律 None。
    """
    base_body: dict[str, Any] = {
        "model": MODEL,
        "messages": messages,
        "stream": False,
        "keep_alive": KEEP_ALIVE,
        "options": {"temperature": 0, "num_ctx": NUM_CTX, "num_predict": num_predict},
    }
    if schema is not None:
        base_body["format"] = schema

    for with_think in (True, False):
        body = dict(base_body)
        if with_think:
            body["think"] = False
        try:
            data = _post(body, timeout)
            return (data.get("message") or {}).get("content") or ""
        except urllib.error.HTTPError as exc:
            if with_think and exc.code in (400, 404, 422):
                continue
            log.warning("llm chat http error: %s", exc)
            return None
        except Exception as exc:
            log.warning("llm chat failed: %s", exc)
            return None
    return None


def _despace(s: str) -> str:
    """去掉所有空白字符。用于「原文子串」校验的鲁棒比较。

    有的模型（实测 qwen3.5）会把数字写成 `10 月 20 日`、`下午 2 点`，
    直接做子串比较会失败、把整条抽取丢掉。中文里空格不承载语义，去掉后比较即可。
    """
    return re.sub(r"\s+", "", s or "")


def validate(obj: dict[str, Any], source: str, evidence_title: bool = False) -> dict[str, Any] | None:
    """安全闸：枚举 + 原文子串。

    比《方案》原文更稳一点：某个字段不是原文子串时**只清空该字段**，而不是整条丢弃。
    这样"永远不可能显示编造内容"的性质不变（编造值一律被清空），
    但不会因为一个字段写错就丢掉整次抽取。整条无有效字段时才回退规则。

    返回的 dict 里带两个内部键（都不会下发给 App）：
      * ``_nullified``：被清空的槽位**名**列表；
      * ``_nullified_values``：槽位名 -> 被清空的原值（去空白后），
        供上层判断 summary 有没有**真的复述**编造值——一个槽位写错不该连累整段总结。
    """
    kind = obj.get("kind")
    if kind not in KINDS:
        log.info("llm reject: kind=%r", kind)
        return None

    out: dict[str, Any] = {"kind": kind}
    kept = 0
    nullified: list[str] = []
    nullified_values: dict[str, str] = {}
    src_flat = _despace(source)
    for key in _SUBSTRING_FIELDS:
        value = str(obj.get(key) or "").strip()
        # 去空白后再比（模型可能写成 "10 月 20 日"），保留去空白后的值
        flat = _despace(value)
        if flat and flat in src_flat:
            out[key] = flat
            kept += 1
        else:
            if value:
                log.info("llm nullify: %s=%r 不是原文子串", key, value)
                nullified.append(key)
                # 留一份「被清空的原值」：上层用它判断 summary 有没有**真的复述**编造值。
                # 一个槽位写错不该连累整段总结（否则用户看到的就是"没有总结"）。
                nullified_values[key] = flat[:24]
            out[key] = ""

    # 自然语言字段：允许模型润色、连词成句，不做子串校验（只截断长度，防超长撑爆界面）
    title = str(obj.get("title") or "").strip()
    if len(title) < 2:            # 单字标题（如“补”）无意义 -> 置空，交给调用方回退
        title = ""
    if evidence_title and title and _despace(title) in src_flat:
        kept += 1                 # 标题逐字来自原文，也算「抽到了」的证据
    out["title"] = title[:24]

    summary = str(obj.get("summary") or "").strip()

    # 有实义的事件至少要留下一点有效信息，否则等于没抽到 -> 回退规则。
    #
    # 但 `title` / `summary` 是**自然语言字段**（允许润色，不做子串校验）：
    # 短通知（「紧急停水通知」）根本没有时间/地点，结构化槽位必然为空，
    # 模型也常把 title 留空（原文本身就是标题）。
    # 旧判据只看槽位，会把这类整条丢掉 → 回退规则 → 总结退化成标题本身，
    # 用户看到的就是"通知没有总结"。**只要有总结（或标题），就保留这次抽取。**
    if kind in _ACTIONABLE and kept == 0 and not summary and not title:
        log.info("llm reject: kind=%s 无有效字段", kind)
        return None

    out["_nullified"] = nullified
    out["_nullified_values"] = nullified_values

    # items：需带物品 / 注意事项，同样只保留原文子串（编造的一律丢弃）
    items: list[str] = []
    items_raw = obj.get("items")
    if isinstance(items_raw, list):
        for t in items_raw:
            flat = _despace(str(t or ""))
            if flat and flat in src_flat and flat not in items:
                items.append(flat[:14])
    out["items"] = items[:5]

    # steps：执行步骤是"总结"，不要求原文子串；但要去空、去重、限长限量，
    # 防止模型写成长段落或者复读标题。
    steps: list[str] = []
    steps_raw = obj.get("steps")
    if isinstance(steps_raw, list):
        for s in steps_raw[:6]:
            t = _despace(str(s or "")).strip(" ：:、-—~～")
            if len(t) < 2 or t in steps:
                continue
            steps.append(t[:15])
    out["steps"] = steps[:5]

    out["summary"] = summary[:160]

    category = obj.get("category")
    out["category"] = category if category in CATEGORIES else ""

    tags_raw = obj.get("tags")
    tags: list[str] = []
    if isinstance(tags_raw, list):
        for t in tags_raw:
            flat = _despace(str(t or ""))
            if flat and flat in src_flat and flat not in tags:
                tags.append(flat[:12])
    out["tags"] = tags[:5]
    return out


def extract_thread(texts: list[str]) -> dict[str, Any] | None:
    """对**一个话题簇**（多条消息）做综合总结；校验通过返回一条 dict，否则 None。

    与 ``extract`` 的区别只有两点：
      1. 用 ``THREAD_SYSTEM``（要求跨行补齐信息、输出一条）；
      2. 原文子串校验的基准是**多行拼接后的整段文本**（逐字仍可核对）。
    """
    lines = [t.strip() for t in texts if t and t.strip()]
    if not lines:
        return None
    joined = "\n".join(lines)
    return extract(joined, system=THREAD_SYSTEM, evidence_title=True)


def warmup() -> bool:
    """启动时预热：把模型提前加载进显存，避免第一条消息超时。

    用 ``WARMUP_TIMEOUT``（180s）：9b 约 7GB，首次载入可能远超普通请求的 30s。
    """
    try:
        _post({
            "model": MODEL,
            "messages": [{"role": "user", "content": "你好"}],
            "stream": False,
            "keep_alive": KEEP_ALIVE,
            "think": False,
            "options": {"num_predict": 1},
        }, timeout=WARMUP_TIMEOUT)
        return True
    except Exception as exc:  # noqa: BLE001
        log.warning("warmup failed: %s", exc)
        return False


# ---------------------------------------------------------------- 图片 OCR（多模态）
# 给「手动添加任务 · 截图来源」（POST /api/relay/parse 的 image_b64）用：
# 本地多模态模型离线识别图片文字，零新依赖、不出网。
# 思路与 ocr_images.py（标注工具）一致，但作为服务内函数复用本模块的模型配置。

OCR_TIMEOUT = 120  # OCR 超时：多模态首次加载 7GB 可能远超普通推理的 30s

OCR_PROMPT = (
    "请提取这张图片里的**所有可见文字**，按从上到下、从左到右的顺序逐行输出。"
    "要求：只输出文字本身，不要解释、不要总结、不要加标题；保留数字与符号。"
    "如果图中没有任何文字，只输出「无文字」。"
)


def ocr_image(b64: str, timeout: float = OCR_TIMEOUT) -> str:
    """本地多模态模型 OCR。失败、超时或图中无文字一律返回空串（调用方回退端侧 OCR）。

    ``b64`` 是图片的 base64（不带 ``data:`` 前缀；带也会被去掉）。
    """
    if not b64:
        return ""
    if b64.startswith("data:"):        # 容错：前端可能传 data URI
        b64 = b64.split(",", 1)[-1]
    body: dict[str, Any] = {
        "model": MODEL,
        "messages": [{"role": "user", "content": OCR_PROMPT, "images": [b64]}],
        "stream": False,
        "think": False,
        "options": {"temperature": 0, "num_predict": 700},
    }
    data: dict[str, Any] | None = None
    for _ in range(2):
        try:
            data = _post(body, timeout=timeout)
            break
        except urllib.error.HTTPError as exc:
            if "think" in body and exc.code in (400, 404, 422):
                body.pop("think", None)   # 老版本 Ollama 不认 think 参数，去掉重试一次
                continue
            log.warning("ocr http error: %s", exc)
            return ""
        except Exception as exc:  # noqa: BLE001
            log.warning("ocr request failed: %s", exc)
            return ""
    if data is None:
        return ""
    try:
        text = ((data.get("message") or {}).get("content") or "").strip()
    except Exception:  # noqa: BLE001
        return ""
    if not text or text == "无文字":
        return ""
    return text


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    import pipeline_proto as R

    samples = [
        ("Pea", "【通知】原定5月27日下午2:30主D104的心理委员培训，改为6月3日周三下午2:30在主楼D104，全体参加，不能参加者提前向辅导员请假。"),
        ("Oliver", "智慧社区签到签退码，请心理委员转发给各班同学一下"),
        ("郑源旭", "没签到签退咋办😯"),
        ("硫酸Cu", "明天去超市买点吃的"),
    ]
    print("ollama available:", available())
    print("warmup:", warmup())
    for name, raw in samples:
        text = R.normalize(raw)
        out = extract(text)
        engine = "LLM " if out else "RULES"
        payload = out if out else {"kind": R.classify(text)}
        print(f"[{engine}] {name}: {json.dumps(payload, ensure_ascii=False)}")
