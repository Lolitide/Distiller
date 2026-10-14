/**
 * T2 时间解析：把中文时间表达归一化。
 *
 * 关键设计：
 *   - normalized 可能为空 —— **推不出确切日期就不猜**（如「下周」）；
 *   - text 永远保留原话，界面上显示 `2026-10-14（后天）`；
 *   - 相对时间的基准是**消息自己的时间戳**，不是当前时间（否则补看历史消息会算错）。
 */

/** 年-月-日（用 UTC 做日期运算，避免时区/夏令时影响） */
export interface Ymd {
  y: number;
  mo: number;
  d: number;
}

export interface TimeSlot {
  /** 原话，如「后天」「明晚」「9点」 */
  text: string;
  /** 归一化结果，如 2026-10-14；无法确定时为空串 */
  normalized: string;
  /** 有信息但推不出确切日期（如「下周」） */
  unresolved: boolean;
  /** 相对时间的推算基准（消息自己的日期） */
  sourceDate: string;
}

export function ymdToUtc(d: Ymd): Date {
  return new Date(Date.UTC(d.y, d.mo - 1, d.d));
}

export function formatYmd(d: Ymd): string {
  const mo: string = d.mo < 10 ? '0' + d.mo : '' + d.mo;
  const dd: string = d.d < 10 ? '0' + d.d : '' + d.d;
  return d.y + '-' + mo + '-' + dd;
}

export function addDays(d: Ymd, n: number): Ymd {
  const dt = new Date(Date.UTC(d.y, d.mo - 1, d.d + n));
  return { y: dt.getUTCFullYear(), mo: dt.getUTCMonth() + 1, d: dt.getUTCDate() };
}

/** ISO 星期：周一=1 … 周日=7 */
export function isoWeekday(d: Ymd): number {
  const dow: number = ymdToUtc(d).getUTCDay();
  return dow === 0 ? 7 : dow;
}

/** 从消息时间戳取基准日期；取不到就用当前日期。 */
export function ymdFromTimestamp(ts: string): Ymd {
  const m: RegExpExecArray | null = /(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})/.exec(ts);
  if (m !== null) {
    return { y: parseInt(m[1], 10), mo: parseInt(m[2], 10), d: parseInt(m[3], 10) };
  }
  const now = new Date();
  return { y: now.getFullYear(), mo: now.getMonth() + 1, d: now.getDate() };
}

/** 时间戳 -> 毫秒，用于比较两条消息的间隔（忽略时区，同一群内足够）。 */
export function tsToMillis(ts: string): number {
  const m: RegExpExecArray | null = /(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?/.exec(ts);
  if (m === null) {
    return 0;
  }
  const sec: number = m[6] !== undefined ? parseInt(m[6], 10) : 0;
  return Date.UTC(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10),
    parseInt(m[4], 10), parseInt(m[5], 10), sec);
}

export function timeSlotDisplay(slot: TimeSlot): string {
  if (slot.unresolved) {
    return slot.text + '（待确认具体日期）';
  }
  if (slot.normalized.length > 0 && slot.normalized !== slot.text) {
    return slot.normalized + '（' + slot.text + '）';
  }
  return slot.text;
}

interface Clock {
  text: string;
  hour: number;
  minute: number;
}

/** 中文数字 -> 数字（0~59）："两"->2、"十一点"->11、"二十三"->23、"廿"->20、"半"->30。 */
function cn2int(s: string): number {
  if (s.length === 0) {
    return -1;
  }
  if (s === '半') {
    return 30;
  }
  if (/^\d+$/.test(s)) {
    return parseInt(s, 10);
  }
  const digit: Record<string, number> = {
    '零': 0, '〇': 0, '一': 1, '两': 2, '二': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9
  };
  if (s.indexOf('十') >= 0) {
    const i: number = s.indexOf('十');
    const tensPart: string = s.substring(0, i);
    const onesPart: string = s.substring(i + 1);
    const tens: number = tensPart.length === 0 ? 1 : (digit[tensPart] ?? -1);
    const ones: number = onesPart.length === 0 ? 0 : (digit[onesPart] ?? -1);
    if (tens < 0 || ones < 0) {
      return -1;
    }
    return tens * 10 + ones;
  }
  if (s === '廿') {
    return 20;
  }
  return s.length === 1 ? (digit[s] ?? -1) : -1;
}

/** 裸「X点」里不是时间的常见词（"一点"=稍微、"地点"、"特点"…）。与后端 _CLOCK_STOP 一致。 */
const CLOCK_STOP: string[] = [
  '一点', '有点', '差点', '地点', '起点', '终点', '特点', '重点', '观点',
  '缺点', '优点', '焦点', '热点', '难点', '早点', '晚点', '快点', '慢点',
  '疑点', '卖点', '景点', '盘点', '顶点', '极点', '视点', '考点', '论点'
];

/**
 * 找「9点」「上午9点」「下午3点半」「15:30」「下午两点」「十一点」。
 * 分隔符只认 `点 / : / ：`（**不认「时」**：否则「一时/小时/同时/随时」都会被当成时间）。
 */
function findClock(t: string): Clock | null {
  const re: RegExp = /(上午|早上|清晨|中午|下午|晚上|傍晚)?\s*(\d{1,2}|[零〇一二两三四五六七八九十廿]{1,3})\s*([:：点])\s*(半|\d{1,2}|[零〇一二两三四五六七八九十]{1,2})?\s*(分)?/;
  const m: RegExpExecArray | null = re.exec(t);
  if (m === null) {
    return null;
  }
  const matched: string = m[0].trim();
  if (CLOCK_STOP.indexOf(matched) >= 0) {
    return null;   // 裸「一点/地点/特点…」不是时间
  }
  let hour: number = cn2int(m[2]);
  if (hour < 0) {
    return null;
  }
  const minute: number = m[4] !== undefined ? cn2int(m[4]) : 0;
  if (minute < 0) {
    return null;
  }
  const period: string = m[1] ?? '';
  if ((period === '下午' || period === '晚上' || period === '傍晚') && hour < 12) {
    hour += 12;
  } else if ((period === '凌晨' || period === '早上' || period === '清晨') && hour === 12) {
    hour = 0;
  } else if (period === '中午' && hour < 6) {
    hour += 12;
  }
  if (hour > 23 || minute > 59) {
    return null;
  }
  return { text: matched, hour: hour, minute: minute };
}

function two(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

/** 相对日 + 时间点 -> 合成完整时间（「明天上午9点」）。 */
function attachClock(slot: TimeSlot, t: string): TimeSlot {
  const clock: Clock | null = findClock(t);
  if (clock !== null && slot.normalized.length > 0) {
    slot.normalized = slot.normalized + ' ' + two(clock.hour) + ':' + two(clock.minute);
    slot.text = slot.text + clock.text;
  }
  return slot;
}

interface RelDay {
  word: string;
  delta: number;
}

/** 顺序有意义：「大后天」要排在「后天」前面。 */
const REL_DAYS: RelDay[] = [
  { word: '大后天', delta: 3 },
  { word: '后天', delta: 2 },
  { word: '明天', delta: 1 },
  { word: '明晚', delta: 1 },
  { word: '今晚', delta: 0 },
  { word: '今天', delta: 0 },
  { word: '今早', delta: 0 }
];

const WEEKDAY: Map<string, number> = new Map<string, number>([
  ['一', 1], ['二', 2], ['三', 3], ['四', 4], ['五', 5], ['六', 6], ['日', 7], ['天', 7]
]);

function slotOf(text: string, normalized: string, base: Ymd): TimeSlot {
  return { text: text, normalized: normalized, unresolved: false, sourceDate: formatYmd(base) };
}

/**
 * 从文本里找时间表达。找不到返回 null —— **不要**默认成「今天」。
 */
export function parseTime(text: string, base: Ymd): TimeSlot | null {
  const t: string = text;

  // (a) 绝对日期：2026-10-20 / 2026年10月20日
  let m: RegExpExecArray | null = /(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})/.exec(t);
  if (m !== null) {
    const y: number = parseInt(m[1], 10);
    const mo: number = parseInt(m[2], 10);
    const d: number = parseInt(m[3], 10);
    return slotOf(m[0], formatYmd({ y: y, mo: mo, d: d }), base);
  }
  // (a2) 10月20日 / 10/20（按当前日期判断年份）
  m = /(\d{1,2})[月/](\d{1,2})[日号]?/.exec(t);
  if (m !== null) {
    const mo: number = parseInt(m[1], 10);
    const d: number = parseInt(m[2], 10);
    if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
      const y: number = mo >= base.mo ? base.y : base.y + 1;
      return slotOf(m[0], formatYmd({ y: y, mo: mo, d: d }), base);
    }
  }

  // (a3) 点分日期 10.31 / 12.11（群里极常见）：两侧不接数字，避免匹配 3.14159
  m = /(?<!\d)(\d{1,2})[.．](\d{1,2})(?!\d)/.exec(t);
  if (m !== null) {
    const mo: number = parseInt(m[1], 10);
    const d: number = parseInt(m[2], 10);
    if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
      const y: number = mo >= base.mo ? base.y : base.y + 1;
      return slotOf(m[0], formatYmd({ y: y, mo: mo, d: d }), base);
    }
  }

  // (b) 相对日：今天/明天/后天/大后天/今晚/明晚/今早
  for (let i = 0; i < REL_DAYS.length; i++) {
    const rd: RelDay = REL_DAYS[i];
    if (t.indexOf(rd.word) >= 0) {
      const day: Ymd = addDays(base, rd.delta);
      return attachClock(slotOf(rd.word, formatYmd(day), base), t);
    }
  }
  if (/明[天日]/.test(t)) {
    const day: Ymd = addDays(base, 1);
    return attachClock(slotOf('明天', formatYmd(day), base), t);
  }

  // (c) 星期：周三 / 下周三 / 下下周三
  m = /(下{0,2})(?:周|星期|礼拜)([一二三四五六日天])/.exec(t);
  if (m !== null) {
    const prefix: string = m[1];
    const target: number = WEEKDAY.get(m[2]) ?? 1;
    let delta: number = (target - isoWeekday(base)) % 7;
    delta = delta !== 0 ? delta : 7;
    if (prefix === '下') {
      delta += 7;
    } else if (prefix === '下下') {
      delta += 14;
    }
    const day: Ymd = addDays(base, delta);
    return attachClock(slotOf(m[0], formatYmd(day), base), t);
  }

  // (d) 只有「下周 / 下个月 / 月底」这类，推不出确切日期 -> 不猜
  m = /下{1,2}(个)?(周|月|星期)/.exec(t);
  if (m !== null) {
    return { text: m[0], normalized: '', unresolved: true, sourceDate: formatYmd(base) };
  }
  m = /月底前|月底|这个月|本月/.exec(t);
  if (m !== null) {
    return { text: m[0], normalized: '', unresolved: true, sourceDate: formatYmd(base) };
  }

  // (e) 只有时间点，没有日期（「9点」）
  const clock: Clock | null = findClock(t);
  if (clock !== null) {
    return { text: clock.text, normalized: '', unresolved: false, sourceDate: formatYmd(base) };
  }
  return null;
}
