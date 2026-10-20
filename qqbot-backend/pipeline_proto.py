"""信息整理原型：把群消息变成「事件对象」，而不是硬拼成一句话。

这是《信息总结方案》的可行性验证代码（纯 Python，无第三方依赖）。
用真实 bot.db 数据回测：`python -X utf8 test_pipeline.py`

设计要点（也是端侧 ArkTS 要照搬的三条）：
  1. **先分级再理解**：绝大多数群消息（数字、表情、寒暄）先被判为 ignore，
     根本不进后续链路 —— 这一步能砍掉 80% 以上的噪声。
  2. **不猜缺失字段**：槽位找不到就留空，绝不生成。宁可卡片少一行，
     也不要出现"AI 编了个时间"。
  3. **句子用模板拼，不让模型编**：输出 = 模板 × 槽位。措辞来自原话，
     语序来自模板，所以既通顺又不会幻觉。
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta

# 中文数字 -> 阿拉伯数字：借 cn2an（MIT, pure-python）而不是手搓。
# 做成**软依赖**：没装时回退下面的内置实现，服务照常跑。
try:
    import cn2an as _cn2an
except Exception:  # noqa: BLE001
    _cn2an = None

# ============================================================ 1. 预处理

# QQ 把表情下发成 <faceType=6,faceId="0",ext="eyJ0ZXh0IjoiIn0="> 这种标记，
# 直接入库会让消息看起来是"乱码"，必须先归一化。
_FACE_RE = re.compile(r"<faceType=(\d+),faceId=\"([^\"]*)\",ext=\"([^\"]*)\">")
_AT_RE = re.compile(r"<@!?[0-9A-Za-z]+>")
_URL_RE = re.compile(r"https?://\S+")

# 纯噪声：纯数字、单字符、纯标点
_NUMERIC_RE = re.compile(r"^[\d\s.,、。!！?？~～-]+$")

# 系统消息 / 拍一拍 / 加群提示：**不是人说的话**，必须整体判为噪声。
# 实测真实语料里有 4.8% 是这类（`XX加入了群聊`、`某某拍了拍你`），
# 不过滤会污染分级、抽取与新词挖掘。定义放这里当唯一真值源，其他模块复用。
_SYSTEM_RE = re.compile(
    r"加入了群聊|拍了拍|戳了戳|揉了揉|捏了捏|撤回了一条消息|"
    r"邀请.*加入|群主.*转让|设置了管理员|修改群名|发起了群投票|"
    r"你已添加|对方的QQ号|以上是打招呼的内容"
)


def normalize(raw: str) -> str:
    """把平台原始文本整理成可读文本：@ 转文字、表情转占位、去 URL。"""
    if not raw:
        return ""
    text = _AT_RE.sub("@某人", raw)
    text = _FACE_RE.sub(lambda m: _face_label(m.group(3)), text)
    text = _URL_RE.sub("[链接]", text)
    text = re.sub(r"[ \t]+", " ", text)
    return text.strip()


def _face_label(ext_b64: str) -> str:
    """表情的 ext 字段是 base64 的 {"text":"[偷笑]"}，解出来更可读。"""
    if not ext_b64:
        return "[表情]"
    try:
        import base64
        import json

        raw = ext_b64.strip()
        # 补足 padding（平台有时会省掉 "="），但别补成多余的
        pad = (-len(raw)) % 4
        data = json.loads(base64.b64decode(raw + "=" * pad).decode("utf-8"))
        label = str(data.get("text") or "").strip()
        return label if label.startswith("[") else (f"[{label}]" if label else "[表情]")
    except Exception:  # noqa: BLE001
        return "[表情]"


def is_noise(text: str) -> bool:
    """判断是否是"不值得整理"的消息。这是整个链路里最重要的一步过滤。"""
    t = (text or "").strip()
    if not t:
        return True
    if len(t) <= 1:
        return True
    if _NUMERIC_RE.match(t):
        return True
    # 系统消息 / 拍一拍：不是人说的话
    if _SYSTEM_RE.search(t):
        return True
    # 只剩表情/链接/@的
    stripped = re.sub(r"\[[^\]]*\]|@某人|\[链接\]", "", t).strip()
    if not stripped:
        return True
    # 纯字母缩写（ok / hh / vu / bb）
    if re.fullmatch(r"[A-Za-z]{1,4}", stripped):
        return True
    return False


# ============================================================ 2. 时间解析

_CN_DIGIT = {
    "零": 0, "〇": 0, "一": 1, "两": 2, "二": 2, "三": 3, "四": 4,
    "五": 5, "六": 6, "七": 7, "八": 8, "九": 9,
}
_CN_NUM_CHARS = "零〇一二两三四五六七八九十廿"

# 裸「X点」里不是时间的常见词（"一点"=稍微、"地点"、"特点"…）。
# 只在**没有**时段前缀、也没有"半/分"时才挡；"下午一点""一点半"仍然算时间。
_CLOCK_STOP = {
    "一点", "有点", "差点", "地点", "起点", "终点", "特点", "重点", "观点",
    "缺点", "优点", "焦点", "热点", "难点", "早点", "晚点", "快点", "慢点",
    "疑点", "卖点", "景点", "盘点", "顶点", "极点", "视点", "考点", "论点",
}


def _cn2int_fallback(s: str) -> int | None:
    """cn2an 不可用时的内置兜底（覆盖 0~99 的常见写法）。"""
    if s.isdigit():
        return int(s)
    if "十" in s:
        tens_part, _, ones_part = s.partition("十")
        tens = _CN_DIGIT.get(tens_part, 1) if tens_part else 1
        ones = _CN_DIGIT.get(ones_part, 0) if ones_part else 0
        return tens * 10 + ones
    if len(s) == 1:
        if s == "廿":
            return 20
        return _CN_DIGIT.get(s)
    return None


def _cn2int(s: str) -> int | None:
    """中文数字 -> int（0~59）："两"->2、"十一"->11、"二十三"->23、"廿"->20、"半"->30。

    群聊里「下午两点」「十一点」远比「14点」常见，不认中文数字会漏掉大量时间。
    优先用 cn2an（覆盖大数/大写/混合拼写），缺失时回退内置实现。
    """
    s = (s or "").strip()
    if not s:
        return None
    if s == "半":
        return 30
    if _cn2an is not None:
        for mode in ("strict", "normal", "smart"):
            try:
                value = _cn2an.cn2an(s, mode)
            except Exception:  # noqa: BLE001  （cn2an 对非法输入抛 ValueError）
                continue
            if isinstance(value, (int, float)) and float(value).is_integer():
                return int(value)
        return None
    return _cn2int_fallback(s)


@dataclass
class TimeSlot:
    """解析出的时间。**关键设计**：normalized 可能为空（不猜），
    但 text 一定保留原话，界面上永远显示原话。"""

    text: str                      # 原话，如 "后天"、"明晚"、"9点"
    normalized: str = ""           # 归一化，如 "2026-10-14"；无法确定时留空
    unresolved: bool = False       # 有信息但推不出确切日期（如 "下周"）
    source_date: str = ""          # 相对时间的推算基准（消息自己的时间）

    @property
    def display(self) -> str:
        if self.unresolved:
            return f"{self.text}（待确认具体日期）"
        if self.normalized and self.normalized != self.text:
            return f"{self.normalized}（{self.text}）"
        return self.text


_WEEKDAY = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "日": 7, "天": 7}


def parse_time(text: str, base: datetime) -> TimeSlot | None:
    """从文本里找时间表达。找不到返回 None（**不要**默认成"今天"）。"""
    t = text or ""

    # (a) 绝对日期 2026-10-20 / 10月20日 / 10/20
    m = re.search(r"(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})", t)
    if m:
        y, mo, d = (int(x) for x in m.groups())
        return TimeSlot(m.group(0), f"{y:04d}-{mo:02d}-{d:02d}", source_date=_d(base))
    m = re.search(r"(\d{1,2})[月/](\d{1,2})[日号]?", t)
    if m:
        mo, d = int(m.group(1)), int(m.group(2))
        if 1 <= mo <= 12 and 1 <= d <= 31:
            y = base.year if mo >= base.month else base.year + 1
            return TimeSlot(m.group(0), f"{y:04d}-{mo:02d}-{d:02d}", source_date=_d(base))

    # (a2) 点分日期 10.31 / 12.11（群里极常见；要求两侧不接数字，避免匹配到 3.14159 这类）
    m = re.search(r"(?<!\d)(\d{1,2})[.．](\d{1,2})(?!\d)", t)
    if m:
        mo, d = int(m.group(1)), int(m.group(2))
        if 1 <= mo <= 12 and 1 <= d <= 31:
            y = base.year if mo >= base.month else base.year + 1
            return TimeSlot(m.group(0), f"{y:04d}-{mo:02d}-{d:02d}", source_date=_d(base))

    # (b) 相对日：今天/明天/后天/大后天
    rel = {"大后天": 3, "后天": 2, "明天": 1, "明晚": 1, "今晚": 0, "今天": 0, "今早": 0}
    for word, delta in rel.items():
        if word in t:
            day = base + timedelta(days=delta)
            slot = TimeSlot(word, _d(day), source_date=_d(base))
            return _attach_clock(slot, t)
    # 单独一个"明"字（"明天"已覆盖）
    if re.search(r"明[天日]", t):
        slot = TimeSlot("明天", _d(base + timedelta(days=1)), source_date=_d(base))
        return _attach_clock(slot, t)

    # (c) 星期
    m = re.search(r"(下{0,2})(?:周|星期|礼拜)([一二三四五六日天])", t)
    if m:
        prefix, wd = m.group(1), m.group(2)
        target = _WEEKDAY[wd]
        delta = (target - base.isoweekday()) % 7
        delta = delta if delta else 7
        if prefix == "下":
            delta += 7
        elif prefix == "下下":
            delta += 14
        day = base + timedelta(days=delta)
        return _attach_clock(TimeSlot(m.group(0), _d(day), source_date=_d(base)), t)

    # (d) 只有"下周/下个月"这类，推不出确切日期 -> unresolved（不猜）
    m = re.search(r"下{1,2}(个)?(周|月|星期)", t)
    if m:
        return TimeSlot(m.group(0), unresolved=True, source_date=_d(base))
    m = re.search(r"月底|月底前|这个月|本月", t)
    if m:
        return TimeSlot(m.group(0), unresolved=True, source_date=_d(base))

    # (e) 只有时间点，没有日期（"9点"）
    clock = _find_clock(t)
    if clock:
        return TimeSlot(clock[0], source_date=_d(base))
    return None


_CLOCK_RE = re.compile(
    r"(?P<period>上午|早上|清晨|凌晨|中午|下午|晚上|傍晚)?\s*"
    r"(?P<hour>\d{1,2}|[" + _CN_NUM_CHARS + r"]{1,3})"
    r"\s*(?P<sep>[:：点])"          # 只认 点 / : / ：——**不认「时」**
    r"\s*(?P<minute>半|\d{1,2}|[" + _CN_NUM_CHARS + r"]{1,2})?"
    r"\s*(?P<unit>分)?"
)


def _find_clock(t: str) -> tuple[str, int, int] | None:
    """找 "9点"/"上午9点"/"下午3点半"/"15:30"/"下午两点"（支持中文数字）。

    **不把「时」当分隔符**：否则「一时」「小时」「同时」「随时」「暂时」「何时」
    这些普通词会被误判成时间（实测 `一时` 被当成 01:00，再经跨消息拼合放大成
    「12月11号一时」= 2026-12-11 01:00，把比赛的时间污染坏掉）。
    另外挡掉一批裸的「X点」歧义词（一点=稍微、地点、特点…）。
    """
    m = _CLOCK_RE.search(t or "")
    if not m:
        return None
    matched = m.group(0).strip()
    if matched in _CLOCK_STOP:      # 裸「一点/有点/地点…」不是时间
        return None
    hour = _cn2int(m.group("hour"))
    if hour is None:
        return None
    minute_raw = m.group("minute")
    minute = _cn2int(minute_raw) if minute_raw else 0
    if minute is None:
        minute = 0

    period = m.group("period") or ""
    if period in ("下午", "晚上", "傍晚") and hour < 12:
        hour += 12
    elif period in ("凌晨", "早上", "清晨") and hour == 12:
        hour = 0                      # 凌晨12点 = 0 点
    elif period == "中午" and hour < 6:
        hour += 12                    # 中午1点 = 13 点（中午12点保持 12）
    if hour > 23 or minute > 59:
        return None
    return matched, hour, minute


def _attach_clock(slot: TimeSlot, t: str) -> TimeSlot:
    """相对日 + 时间点 -> 合成一个完整时间（"明天上午9点"）。"""
    clock = _find_clock(t)
    if clock and slot.normalized:
        _, hour, minute = clock
        slot.normalized = f"{slot.normalized} {hour:02d}:{minute:02d}"
        slot.text = f"{slot.text}{clock[0]}"
    return slot


def _d(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d")


# ============================================================ 3. 分类 + 槽位

# 事件类型是**封闭枚举**，不是让模型自由发挥。每种类型有自己的槽位表。
EVENT_TODO = "待办"
EVENT_NOTICE = "通知"
EVENT_ACTIVITY = "活动"
EVENT_PLAN = "出行计划"
EVENT_CHAT = "闲聊"
EVENT_IGNORE = "忽略"

# 行为动作的触发词（用于"事件性"判断，也用于砍掉语气词）
_ACTION_HINTS = ("记得", "别忘", "要", "需要", "请", "交", "提交", "报名", "参加",
                 "开会", "上课", "考试", "买", "去", "来", "做", "完成", "准备",
                 "截止", "ddl", "DDL", "截止日期")
_NOTICE_HINTS = ("通知", "报名", "截止", "开始", "启动", "比赛", "大赛", "活动",
                 "招聘", "开放", "申请", "公布")
_PLAN_HINTS = ("去", "到", "出发", "坐车", "坐火车", "坐飞机", "旅游", "出差", "回")
_LEAD_FILLER = ("记得", "别忘了", "别忘", "要", "需要", "请", "麻烦", "应该", "可以",
                "一下", "尽快", "务必", "注意", "大家", "同学们", "我们", "我")

_VENUE_RE = re.compile(
    r"((?:教学楼|教室|图书馆|食堂|宿舍|操场|体育馆|会议室|实验室|报告厅|"
    r"大礼堂|活动中心|食堂|超市|火车站|机场|医院|梧桐苑|"
    r"\d+号楼|[\u4e00-\u9fa5]{2,3}楼|[\u4e00-\u9fa5]{2,3}馆|[\u4e00-\u9fa5]{2,3}苑))"
)
_PERSON_RE = re.compile(r"([\u4e00-\u9fa5]{2,4})(老师|同学|学长|学姐|导员|主任|班长|教授)")
_WHO_RE = re.compile(r"(全体|所有人|大家|各班|班委|组长|负责人)")

# 任务性信号：有这些词才值得进"待办"
_TASK_MARKERS = (
    "记得", "别忘了", "别忘", "要", "需要", "请", "务必", "尽快", "记得要",
    "截止", "ddl", "DDL", "交", "提交", "报名", "参加", "考试", "开会", "上课",
    "完成", "准备", "买", "做",
)
# 闲聊信号：出现这些，即使有任务词也降级为闲聊
_CHAT_MARKERS = (
    "那我", "干脆", "得了", "哈哈", "呵呵", "hh", "感觉", "好像", "是不是",
    "吗", "呢", "咋", "啥", "你们", "那你们", "了没", "有没有",
)


@dataclass
class Event:
    """整理出来的「事件对象」—— 注意它不是一句话，而是一组结构化字段。"""

    kind: str                              # 事件类型（封闭枚举）
    title: str = ""                        # 标题：优先用原话里的关键短句
    action: str = ""                       # 要做的事（原话里切出来的）
    time: TimeSlot | None = None
    place: str = ""
    who: str = ""
    deadline: str = ""
    confidence: float = 0.0                # 0~1，低于阈值前端要标"待确认"
    source_text: str = ""                  # **必须保留**：卡片要能回到原话
    sender: str = ""
    timestamp: str = ""
    msg_id: str = ""
    tags: list[str] = field(default_factory=list)

    @property
    def one_line(self) -> str:
        """由模板拼出的一句话（不是模型生成的）。"""
        return render_one_line(self)


# 任务性信号。**单独一个「要/交/请/做」不能算任务**——实测在 28 万条真实群聊里，
# 「要」命中 10047 次、「交」6798、「请」4832，绝大多数是「想要/主要/交流/请问/请客」。
# 所以改成：强任务词 + 需要搭配才算的词 两类。
_TASK_STRONG_RE = re.compile(r"记得|别忘|务必|尽快|截止|ddl", re.I)
_TASK_COLLOC_RE = re.compile(
    r"需要(?!的)|买|"
    r"要(?:去|来|到|交|买|做|说|参加|准备|完成|提交|提前|准时|报名|考试|上课|开会|联系|通知|带|用)|"
    r"请(?:提交|完成|注意|务必|及时|尽快|参加|填写|联系|查收|准时|自觉|各位|大家)|"
    r"(?:交|提交|上交|缴纳)[^，。！？\s]{0,3}(?:作业|报告|论文|材料|表格|表|钱|费|作品)|"
    r"记得(?:要|把|带|交|去|来)|别忘了|做(?:作业|题|实验|报告)"
)
# 通知类：`通知` 要加词边界（不能匹配「通知书」），去掉过泛的「开始」
_NOTICE_RE = re.compile(r"通知(?!书|栏|群|人)|报名|截止|启动|比赛|大赛|活动|招聘|开放|申请|公布")
# 出行计划：必须有**交通方式或明确的出行行为**（"都回家了" 这种状态句不算）
_PLAN_RE = re.compile(
    r"(?:坐|乘|搭|赶)[^，。！？]{0,3}(?:车|火车|飞机|高铁|地铁|船|航班)|旅游|出差|返校|出发"
)

# 以下枚举仅用于标签/统计（分类逻辑见 classify 的正则）
_TASK_MARKERS = (
    "记得", "别忘了", "别忘", "需要", "请", "务必", "尽快", "记得要",
    "截止", "ddl", "DDL", "交", "提交", "报名", "参加", "考试", "开会", "上课",
    "完成", "准备", "买", "做",
)
# 闲聊信号：出现这些，即使有任务词也降级为闲聊
_CHAT_MARKERS = (
    "那我", "干脆", "得了", "哈哈", "呵呵", "hh", "感觉", "好像", "是不是",
    "吗", "呢", "咋", "啥", "你们", "那你们", "了没", "有没有",
)


def classify(text: str) -> str:
    """粗分类。顺序很重要：先排除噪声与闲聊，再判断任务/通知。

    这里刻意保守：**宁可漏掉（判成闲聊），也不要误判成待办**。
    因为误判会让用户收到一条假提醒，比漏掉更伤信任。

    实测教训（28 万条真实群聊）：用「关键词 in text」判任务会让待办从预期的 ~1%
    膨胀到 8.9%，元凶是 `要/交/请` 这类高频字。现改为**强任务词 + 搭配词**两级判据。
    """
    t = (text or "").strip()
    if is_noise(t):
        return EVENT_IGNORE

    has_chat = any(m in t for m in _CHAT_MARKERS)
    # 疑问句基本不是待办（"几点停电"、"你们参加了吗"）
    is_question = bool(re.search(r"(吗|呢|\?|？|几点|什么时候|怎么|为什么)$", t))
    strong_task = bool(_TASK_STRONG_RE.search(t))

    if is_question and not strong_task:
        return EVENT_CHAT
    if has_chat and not strong_task:
        return EVENT_CHAT

    # 出行意图优先判断：这类句子往往没有"记得/需要"这类任务词，
    # 但信息量很高（时间 + 目的地 + 交通）。要求有明确交通方式或出行行为，避免
    # "都回家了/中午回家睡觉" 这种状态句被误判。
    if _PLAN_RE.search(t):
        return EVENT_PLAN

    if _NOTICE_RE.search(t):
        # "比赛你们参加了吗" 已被上面的闲聊拦住；这里是真的通知
        return EVENT_NOTICE
    if strong_task or _TASK_COLLOC_RE.search(t):
        return EVENT_TODO
    return EVENT_CHAT


# 通知类文案里的客套尾巴，抽完字段后要剪掉
_TAIL_NOISE = ("可以参加", "有兴趣的同学", "有兴趣的可以", "大家", "同学们",
               "可以看看", "注意一下", "有兴趣")


def _clean_action(s: str) -> str:
    out = s
    for w in _TAIL_NOISE:
        out = out.replace(w, "")
    out = re.sub(r"[，,。.、；;]{2,}", "，", out)
    out = re.sub(r"\s+", "", out)
    # 反复剪掉句尾的客套动词（"…报名，参加" -> "…报名"）
    for _ in range(3):
        before = out
        out = re.sub(r"[，,。.、；;]?\s*(可以)?(参加|参与|报名参加|看看|了解一下)$", "", out)
        if out == before:
            break
    return out.strip(" ，,。.、！!～~）)")


def _strip_filler(s: str) -> str:
    out = s
    for w in _LEAD_FILLER:
        out = out.replace(w, "")
    return out.strip(" ，,。.、！!～~")


_TIME_PATTERNS = (
    r"(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})[日号]?",
    r"(\d{1,2})[月/](\d{1,2})[日号]?",
    r"今天|明天|后天|大后天|今晚|明晚|今早",
    r"(下{0,2})(?:周|星期|礼拜)[一二三四五六日天]",
    _CLOCK_RE.pattern,
)


def _remove_time_and_place(text: str, place: str) -> str:
    """把时间表达与已抽出的地点从原文里抠掉，剩下的就是"要做的事"。

    用占位符替换而不是直接删除，避免把相邻的字粘在一起。
    """
    out = text
    # 「截止」这类字段标记词本身不是动作，先去掉（值由下面的日期规则去掉）
    out = re.sub(r"(?:截止日期|截止|ddl|DDL|deadline)", "", out)
    for pat in _TIME_PATTERNS:
        out = re.sub(pat, "", out)
    if place:
        out = out.replace(place, "")
    return out


def _find_known_place(text: str, places) -> str:
    """在文本里找**该群已知的地点词**（最长匹配优先）。

    词表来自 `group_lexicon.py` 的按群自学习结果（如某校的「康桥/梧桐/文治」）。
    本函数保持纯函数：不 import group_lexicon，由调用方把词表传进来，避免依赖环。
    """
    if not places:
        return ""
    best = ""
    for w in places:
        if w and len(w) > len(best) and w in text:
            best = w
    return best


def extract_slots(text: str, kind: str, base: datetime, extra_places=None) -> tuple[str, str, str, str]:
    """抽取 动作 / 地点 / 人物 / 截止。**找不到就留给调用方填空字符串**。

    ``extra_places``：该群自学习到的地点词表（可选）。通用正则认不出的校内地物
    （「康桥」「梧桐」「文治」）靠它兜住。
    """
    t = text or ""
    place = ""
    m = _VENUE_RE.search(t)
    if m:
        # 剪掉紧跟前面的方位/趋向动词（"记得来教学楼" -> "教学楼"）
        place = re.sub(r"^[来到去在往上下的了]", "", m.group(1))
    known = _find_known_place(t, extra_places)
    if known and len(known) >= len(place):
        place = known
    who = ""
    m = _PERSON_RE.search(t)
    if m:
        who = m.group(0)
    else:
        m = _WHO_RE.search(t)
        if m:
            who = m.group(1)

    action = _remove_time_and_place(t, place)
    if who:
        action = action.replace(who, "")
    action = _strip_filler(action)
    action = _clean_action(action)
    # 动作描述开头的趋向动词去掉（"来上课" -> "上课"、"去超市买" -> "超市买"）
    action = re.sub(r"^[来到去往]", "", action)
    action = re.sub(r"[，,。.、]{2,}", "，", action).strip(" ，,。.、！!～~）)")

    deadline = ""
    m = re.search(r"(?:截止日期|截止|ddl|DDL|deadline)\s*[:：]?\s*([^\s，,。.；;]{1,16})", t)
    if m:
        deadline = m.group(1)
    elif "之前" in t or "以前" in t:
        slot = parse_time(t, base)
        if slot:
            deadline = slot.text
    return action, place, who, deadline


# ---------------------------------------------------------------- 标题抽取
#
# 规则路径的标题**不能**直接拿 `action`（= 原文删掉时间/地点后的剩余串）：
# 删除发生在句子中段，剩下的是碎片——
#   「【重要通知】图书馆10月20日起闭馆改造」      -> 「【重通知】起闭馆改造」
#   「通知：本周五下午三点在A103开班会，请准时参加」 -> 「通知：本在A103开班会，准时」
# 这里改成**按分句取**：切句 -> 去掉句首/句尾的噪声 -> 丢掉纯时间/纯寒暄的分句 -> 拼回。
#
# 只影响 `title`，**不动 `action`**：后者是槽位，被 steps 与评测集使用，
# 它的行为挂在 29.6 万条语料基线旁边，不顺手改。

_TITLE_SEP_RE = re.compile(r"[，。；！？,;!?]")
_TITLE_HEAD_RE = re.compile(
    r"^(?:【[^】]{0,12}】|\[[^\]]{0,12}\]"
    r"|(?:重要|紧急|温馨|特别|最新)?通知\s*[:：]?"
    r"|关于|请|记得|别忘了|注意|提醒|友情提示\s*[:：]?"
    r"|@\S+\s*)"
)
_TITLE_TAIL_RE = re.compile(
    r"(?:请准时参加|请务必参加|请同学们?(?:准时)?参加|请知悉|请相互转告"
    r"|收到请回复|特此通知|谢谢(?:配合|大家)?|感谢配合|以上)[!！。.，,]*$"
)
_TITLE_PURE_TIME_RE = re.compile(
    r"^(?:(?:今天|明天|后天|大后天|昨天|本周|这周|下周|周末"
    r"|周[一二三四五六日天]|星期[一二三四五六日天]"
    r"|上午|下午|中午|晚上|早上|凌晨"
    r"|\d{1,2}月\d{1,2}[日号]|\d{1,2}[:：]\d{2}|\d{1,2}点(?:半|\d{1,2}分)?)"
    r"[、，,]?)+$"
)
_TITLE_MAX = 24


def extract_title(text: str, kind: str = "") -> str:
    """规则路径的标题：按**分句**取，不从句子中段裁剪。

    模型路径不走这里（模型自己产 `title`，本函数只服务规则回退与 `build_event`）。
    """
    s = (text or "").strip()
    if not s:
        return ""
    out = ""
    for raw in _TITLE_SEP_RE.split(s):
        c = raw.strip()
        if not c:
            continue
        # 句首噪声可能叠两层（「【通知】关于…」）
        for _ in range(2):
            c2 = _TITLE_HEAD_RE.sub("", c).strip(" ：:、-—~～")
            if c2 == c:
                break
            c = c2
        c = _TITLE_TAIL_RE.sub("", c).strip(" ：:、-—~～")
        if len(c) < 2:
            continue
        if _TITLE_PURE_TIME_RE.match(c):
            continue
        if _VENUE_RE.fullmatch(c):
            continue
        cand = c if not out else out + "，" + c
        if len(cand) > _TITLE_MAX:
            break
        out = cand
    if out:
        return out[:_TITLE_MAX]
    return s[:_TITLE_MAX]


def build_event(
    raw_text: str,
    sender: str = "",
    timestamp: str = "",
    msg_id: str = "",
    base: datetime | None = None,
    extra_places=None,
) -> Event:
    """把一条群消息变成事件对象。这是整条链路的主入口。

    ``extra_places``：该群自学习的地点词表（可选），用于抽校内地物。
    """
    text = normalize(raw_text)
    base_dt = base or _parse_ts(timestamp)
    kind = classify(text)

    if kind == EVENT_IGNORE:
        return Event(kind=EVENT_IGNORE, source_text=text, sender=sender,
                     timestamp=timestamp, msg_id=msg_id)

    time_slot = parse_time(text, base_dt)
    action, place, who, deadline = extract_slots(text, kind, base_dt, extra_places=extra_places)

    # 置信度：字段越全越可信；纯闲聊不参与后续流程
    conf = 0.35
    if time_slot:
        conf += 0.25 if not time_slot.unresolved else 0.10
    if action and len(action) >= 3:
        conf += 0.15
    if place:
        conf += 0.10
    if kind in (EVENT_TODO, EVENT_NOTICE):
        conf += 0.15
    conf = min(0.95, conf)
    if kind == EVENT_CHAT:
        conf = min(conf, 0.3)

    # 标题按分句取（见 extract_title 的说明）；不再用被中段裁剪过的 action
    title = extract_title(text, kind) or action or text
    title = title[:24]

    return Event(
        kind=kind,
        title=title,
        action=action or text,
        time=time_slot,
        place=place,
        who=who,
        deadline=deadline,
        confidence=round(conf, 2),
        source_text=text,
        sender=sender,
        timestamp=timestamp,
        msg_id=msg_id,
        tags=_tags(text, kind),
    )


def _tags(text: str, kind: str) -> list[str]:
    tags = []
    for word, tag in (
        ("作业", "课程"), ("实验", "课程"), ("考试", "考试"), ("比赛", "竞赛"),
        ("报名", "报名"), ("截止", "截止"), ("会议", "会议"), ("答辩", "答辩"),
        ("旅游", "出行"), ("火车", "出行"), ("停电", "生活"),
    ):
        if word in text and tag not in tags:
            tags.append(tag)
    if kind == EVENT_NOTICE and "通知" not in tags:
        tags.append("通知")
    return tags


def _parse_ts(ts: str) -> datetime:
    if not ts:
        return datetime.now()
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})", str(ts))
    if m:
        y, mo, d, h, mi = (int(x) for x in m.groups())
        return datetime(y, mo, d, h, mi)
    return datetime.now()


# ============================================================ 4. 模板成句

def render_one_line(ev: Event) -> str:
    """用模板把槽位拼成一句话。

    原则：**措辞全部来自原话/固定连接词，语序来自模板**。
    所以不会出现"AI 编了一句话"的情况；代价是字段少的时候句子短 —— 这是可接受的。

    实现细节：先把"动作文本"里已经单独成字段的**时间串和地点抠掉再拼**，
    否则会出现"来教学楼上课；地点：教学楼"这种重复。
    """
    if ev.kind in (EVENT_IGNORE, EVENT_CHAT):
        return ""

    t = ev.source_text or ""
    residual = _remove_time_and_place(t, ev.place)
    if ev.who:
        residual = residual.replace(ev.who, "")
    residual = _strip_filler(residual)
    residual = _clean_action(residual)
    residual = re.sub(r"\s+", "", residual).strip(" ，,。.、！!～~）)(（")

    if ev.kind == EVENT_PLAN:
        body = residual or ev.action
        line = f"计划{body}"
        if ev.place:
            line += f"；途经/目的地：{ev.place}"
    else:
        body = residual or ev.action
        if ev.kind == EVENT_NOTICE:
            line = f"通知：{body}"
        elif ev.kind == EVENT_TODO:
            line = body
        else:
            line = body

    parts = [line]
    if ev.time:
        parts.append(f"时间：{ev.time.display}")
    if ev.place and ev.kind != EVENT_PLAN:
        parts.append(f"地点：{ev.place}")
    if ev.who and ev.kind == EVENT_TODO:
        parts.append(f"对象：{ev.who}")
    if ev.deadline:
        parts.append(f"截止：{ev.deadline}")

    out = "；".join(p for p in parts if p and p.strip("；"))
    if ev.confidence < 0.5:
        out += "（字段不完整，建议人工确认）"
    return out


# ============================================================ 5. 按事件聚合

def cluster(events: list[Event], gap_minutes: int = 30) -> list[dict]:
    """把连续的相关消息聚成"一个事件"，这样零散的对话才读得懂。

    规则（简单、可解释、端侧秒级可算）：
      1. 只聚合非噪声事件；
      2. **必须共享标签或关键词**且在 gap_minutes 内 → 同一簇。
         刻意不用"同一发送者"当条件：同一个人连发几句无关的话，
         不该被拼成一个事件（实测会聚出"我是消息 + 消息"这种垃圾簇）；
      3. 每簇取信息量最大的一条当代表。
    """
    items = [e for e in events if e.kind not in (EVENT_IGNORE,) and e.source_text]
    items.sort(key=lambda e: _parse_ts(e.timestamp))

    clusters: list[dict] = []
    for ev in items:
        t = _parse_ts(ev.timestamp)
        kw = _keywords(ev.source_text)
        concepts = _concepts(ev.source_text)
        placed = False
        for c in clusters:
            last = _parse_ts(c["last_ts"])
            share_tag = bool(set(c["tags"]) & set(ev.tags))
            share_kw = bool(c["keywords"] & kw)
            # 同义归并后概念相同，也算「同一件事」（换个说法也能聚上）
            share_concept = bool(c["concepts"] & concepts)
            # 只有「共享标签/关键词/概念」才算同一件事。
            # 刻意不用「同一类型」当条件：那会让 30 分钟内所有同类型消息被拼成一坨。
            if (t - last) <= timedelta(minutes=gap_minutes) and (
                share_tag or share_kw or share_concept
            ):
                c["events"].append(ev)
                c["senders"].append(ev.sender)
                c["last_ts"] = ev.timestamp
                c["tags"] = list(dict.fromkeys(c["tags"] + ev.tags))
                c["keywords"] |= kw
                c["concepts"] |= concepts
                placed = True
                break
        if not placed:
            clusters.append(
                {
                    "events": [ev],
                    "senders": [ev.sender],
                    "last_ts": ev.timestamp,
                    "tags": list(ev.tags),
                    "keywords": kw,
                    "concepts": concepts,
                    "kind": ev.kind,
                }
            )

    out = []
    for c in clusters:
        best = max(
            c["events"],
            key=lambda e: (e.confidence, len(e.source_text)),
        )
        out.append(
            {
                "title": best.title,
                "one_line": best.one_line,
                "kind": best.kind,
                "count": len(c["events"]),
                "span": [c["events"][0].timestamp, c["last_ts"]],
                "senders": list(dict.fromkeys(c["senders"])),
                "tags": c["tags"],
                "events": c["events"],
                "confidence": best.confidence,
            }
        )
    return out


_STOPWORDS = set("的了是在有和就不都一个上也很到说要去你会着没有看好自己这我们他们可以什么怎么这个那个")

# 同义归并：把不同说法归到同一个「概念」，解决「换个说法就聚不上」的问题
_SYNONYM_GROUPS = [
    ["停电", "断电", "跳闸", "没电", "来电"],
    ["作业", "实验报告", "报告", "大作业"],
    ["考试", "测验", "期中考试", "期末考试", "补考"],
    ["报名", "报名表", "填报"],
    ["会议", "开会", "例会", "班会"],
    ["讲座", "分享会", "沙龙", "论坛"],
    ["招聘", "校招", "宣讲会", "宣讲", "实习"],
    ["火车", "高铁", "动车", "车站"],
    ["比赛", "竞赛", "大赛", "挑战赛"],
]


def _concepts(text: str) -> set[str]:
    """取文本里出现的「概念」（同义组归并后的代表词）。"""
    out: set[str] = set()
    t = text or ""
    for group in _SYNONYM_GROUPS:
        for w in group:
            if w in t:
                out.add(group[0])
                break
    return out


def _keywords(text: str, top: int = 4) -> set[str]:
    """极简关键词：中文按 2-4 字滑窗 + 去掉停用词。端侧不需要分词库也能用。"""
    t = re.sub(r"\[[^\]]*\]|@某人|\[链接\]|[^\u4e00-\u9fa5A-Za-z0-9]", "", text or "")
    grams: dict[str, int] = {}
    for n in (2, 3, 4):
        for i in range(len(t) - n + 1):
            g = t[i : i + n]
            if g in _STOPWORDS or any(ch in _STOPWORDS for ch in g):
                continue
            grams[g] = grams.get(g, 0) + 1
    ranked = sorted(grams.items(), key=lambda kv: (-kv[1], -len(kv[0])))
    return {g for g, _ in ranked[:top]}
