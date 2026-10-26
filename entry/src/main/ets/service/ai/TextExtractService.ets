/**
 * 端侧**实体抽取**（Natural Language Kit / `textProcessing.getEntity`）—— FE-36。
 *
 * 为什么要有它：粘贴进来的群消息现在**必须**先发给后端 `/parse` 才能出时间/地点；
 * 断网、没配服务器、后端没开时整条链路就断了。这一个服务补的是"机器在自己身上能读多少"：
 * 用系统自带的实体抽取把**时间**与**地点**抠出来，先填进确认表单，用户核对后保存。
 *
 * ## 三条硬约束（都来自官方，别凭记忆改）
 *
 *  · **文本 ≤ 1000 字符**（API 参考《实体抽取 · 约束与限制》：「文本长度：不超过1000字符」）
 *    → 长消息按 1000 字符**切片**，逐片抽取再把结果并起来（本文件的 `chunkText`）；
 *  · **该能力当前不支持模拟器**（同一篇文档的约束表首行）→ 模拟器上必然失败，
 *    所以下面所有失败都收敛成 `TextExtractResult`（不抛异常），由页面决定提示什么；
 *  · 实体类型只有 10 类：DATETIME / EMAIL / EXPRESS_NO / FLIGHT_NO / LOCATION / NAME /
 *    PHONE_NO / URL / VERIFICATION_CODE / ID_NO —— **没有「事项 / 作业 / 考试」**，
 *    所以这里只抽「时间 + 地点」，任务名仍然要用户填或由后端给（不编造）。
 *
 * ## 为什么用动态 `import()`
 *
 * 工程硬约束第 2 条：AI 能力（NLU / OCR / ASR）一律动态引入，禁止顶层静态 import ——
 * 模拟器镜像里没有这个 Kit，静态 import 会在模块加载阶段就把应用带崩。
 * 动态 import 把失败收敛成一次 reject，可以接住并降级。
 * ⚠️ 「动态 import 一个 `@kit.*` 说明符」官方本地文档没有直接示例（技能 `06-未取证清单` 有记录），
 *    但编译器认这个字面量（构建期就能解析），运行期在**真机**上是否成立仍需实测 —— 见 `docs/FE未实现项清单.md`。
 *
 * ## 时间怎么落到 `dueAt`（数据纪律：不编造）
 *
 * `jsonObject` 的 `time[]` 里给 `start`（如 `2026-10-30T18:00:00` / `2026-10-30` / `T08:00:00`）
 * 与 `startTimestamp`（毫秒）。只有**同时满足**下面三条才写 `dueAt`：
 *   ① `start` 是**完整年月日**（`YYYY-MM-DD` 开头）；② `startTimestamp > 0`；③ `isIllegal` 不是 `true`。
 * 只给了日期、没给时刻时，按**应用自己的既有约定**取当天 23:59（详情页到期选择器的默认值也是「当天 23:59」），
 * 并用 `allDay = true` 标出来。只有时刻没日期（`T08:00:00`）→ 时间戳留 0，只保留原话当 `dueText`。
 * 周期字段（`repeat`）**不消费**：官方只给了「不一定准确」的 `rrule` 与格式未公开的 `repeat`，
 * 拿它拼 `RepeatRule` 属于猜测（见 06-未取证清单同一族的条目）。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'TextExtract';

/** 官方硬上限：单次抽取文本不超过 1000 字符 */
const MAX_CHUNK_CHARS: number = 1000;
/** 一片最多切多少片（按 1000 字符算，10 片 = 1 万字；再长就只抽前 10 片，避免把引擎拖死） */
const MAX_CHUNKS: number = 10;
/** 找切片边界时最多往回看多少字符（尽量切在标点/换行上，不把实体切两半） */
const BOUNDARY_LOOKBACK: number = 120;
/** 切片边界的候选字符（按优先级从高到低依次尝试） */
const STRONG_BOUNDARIES: string[] = ['\n', '。', '！', '？', '；', '!', '?', ';'];
const WEAK_BOUNDARIES: string[] = ['，', '、', ',', ' ', '\t'];

/* ── 官方 `jsonObject` 的结构（字段名照 API 参考《jsonObject（Entity返回参数说明）》） ── */

/** 时间实体里 `time[]` 的一个元素（只取本服务用得到的字段） */
interface RawTimeItem {
  start?: string;
  suggestStart?: string;
  startTimestamp?: number;
  isIllegal?: boolean;
  isContainFuzzyTime?: boolean;
}

interface RawTimeRoot {
  time?: RawTimeItem[];
}

/** 地点实体里 `location[].coreLocation` 的组成元素 */
interface RawLocationCore {
  oriText?: string;
  value?: string;
}

interface RawLocationItem {
  coreLocation?: RawLocationCore;
}

interface RawLocationRoot {
  location?: RawLocationItem[];
}

/** 抽到的一段时间：`text` 是原话，`at` 是可用的时间戳（0 ＝ 没拿到可信时间） */
export class LocalTimeHint {
  /** 原文片段，如「本周五 18:00」——直接进 `Task.dueText`，是溯源依据 */
  text: string = '';
  /** 毫秒时间戳；`0` ＝ 没有可信时间（只有模糊时刻 / 只有时刻没日期 / 被标非法） */
  at: number = 0;
  /** 只给了日期、没给时刻（`at` 已按应用约定落到当天 23:59） */
  allDay: boolean = false;
}

/**
 * 端侧抽取的结果。**统一「成功 / 失败 + 错误码」**（工程硬约束第 10 条），
 * 不把异常抛给页面。
 */
export class TextExtractResult {
  /** 抽取本身是否跑成功（没找到实体也算成功，只是字段为空） */
  ok: boolean = false;
  /**
   * 失败原因码：
   *  · `empty`        —— 没有文本
   *  · `unsupported`  —— Kit 不可用（模拟器 / 系统缺能力）
   *  · `timeout`      —— 200
   *  · `param`        —— 401
   *  · `engine`       —— 1011200001（执行失败）
   *  · `service`      —— 1011200002（服务异常）
   *  · `no_entity`    —— 跑通了但一个实体都没抽到
   */
  code: string = '';
  /** 给人看的一句话（页面可直接 toast） */
  message: string = '';
  /** 抽这次用的文本（截图来源可能是 OCR 出来的文字），调用方可回填原文 */
  text: string = '';
  /** 时间（可能为空） */
  time: LocalTimeHint | undefined = undefined;
  /** 地点（可能为空） */
  place: string = '';
  /** 一共切了几片（>1 说明是长消息切片后抽的） */
  chunkCount: number = 0;
}

export class TextExtractService {
  /**
   * 抽取「时间 + 地点」。
   *
   * @param text 原始文本（可以是整段群消息，超过 1000 字符会自动切片）
   * @returns 永不抛异常的 `TextExtractResult`
   */
  static async extract(text: string): Promise<TextExtractResult> {
    const trimmed: string = (text || '').trim();
    const result: TextExtractResult = new TextExtractResult();
    result.text = trimmed;
    if (trimmed.length === 0) {
      result.code = 'empty';
      result.message = '没有可抽取的文本';
      return result;
    }

    const chunks: string[] = TextExtractService.chunkText(trimmed);
    result.chunkCount = chunks.length;

    let time: LocalTimeHint | undefined = undefined;
    let place: string = '';
    let worked: boolean = false;
    let failureCode: string = '';
    let failureMessage: string = '';

    for (let i = 0; i < chunks.length; i++) {
      const one: TextExtractChunk = await TextExtractService.extractChunk(chunks[i]);
      if (!one.ok) {
        // 任何一片失败都记下第一个失败原因；已抽到的部分仍然保留（长消息前面几片照样有用）
        if (failureCode.length === 0) {
          failureCode = one.code;
          failureMessage = one.message;
        }
        continue;
      }
      worked = true;
      if (time === undefined && one.time !== undefined) {
        time = one.time;
      }
      if (place.length === 0 && one.place.length > 0) {
        place = one.place;
      }
    }

    if (worked) {
      result.ok = true;
      result.time = time;
      result.place = place;
      if (time === undefined && place.length === 0) {
        result.code = 'no_entity';
        result.message = '本地没抽到时间或地点';
      }
      return result;
    }

    // Kit 不可用（部分真机/模拟器）时用本地规则兜底：至少把常见「明天下午三点」「文治书院」抽出来。
    const rule: TextExtractResult | undefined = TextExtractService.extractByRules(trimmed);
    if (rule !== undefined) {
      return rule;
    }

    result.ok = false;
    result.code = failureCode.length > 0 ? failureCode : 'unsupported';
    result.message = failureMessage.length > 0 ? failureMessage : '手机本地不支持实体抽取';
    return result;
  }

  /**
   * 规则兜底：不依赖任何 Kit。
   * 只抽「时间表达 + 带地名词尾的地点」，抽不到就返回 undefined，不猜任务名。
   */
  private static extractByRules(text: string): TextExtractResult | undefined {
    const result: TextExtractResult = new TextExtractResult();
    result.text = text;
    const place: string = TextExtractService.rulePlace(text);
    const time: LocalTimeHint | undefined = TextExtractService.ruleTime(text);
    if (place.length === 0 && time === undefined) {
      return undefined;
    }
    result.ok = true;
    result.code = 'local_rules';
    result.message = '端侧规则抽取（Natural Language Kit 不可用）';
    result.place = place;
    result.time = time;
    return result;
  }

  private static rulePlace(text: string): string {
    const match: RegExpMatchArray | null =
      text.match(/([\u4e00-\u9fa5]{2,10}(?:书院|校区|食堂|广场|公寓|教学楼|图书馆|体育馆|报告厅|会议室|教室|门口))/);
    return match !== null ? match[1] : '';
  }

  private static ruleTime(text: string): LocalTimeHint | undefined {
    const match: RegExpMatchArray | null = text.match(
      /(今天|明天|后天|大后天|本周[一二三四五六日天]|下周[一二三四五六日天])?\s*(上午|下午|晚上|中午|早上)?\s*([0-9]{1,2}|[一二三四五六七八九十]{1,3})\s*[点:：时]\s*(半|[0-9]{1,2}|[一二三四五六七八九十]{1,3})?/
    );
    const dateMatch: RegExpMatchArray | null = text.match(/([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*[日号]/);
    if (match === null && dateMatch === null) {
      return undefined;
    }
    const hint: LocalTimeHint = new LocalTimeHint();
    hint.text = match !== null ? match[0].trim() : (dateMatch !== null ? dateMatch[0] : '');
    let hour: number = -1;
    let minute: number = 0;
    if (match !== null) {
      hour = TextExtractService.cnNumber(match[3]);
      if (match[4] === '半') {
        minute = 30;
      } else if (match[4] !== undefined) {
        minute = TextExtractService.cnNumber(match[4]);
      }
      const period: string = match[2] !== undefined ? match[2] : '';
      if ((period === '下午' || period === '晚上') && hour < 12) {
        hour += 12;
      } else if (period === '中午' && hour < 11) {
        hour += 12;
      }
    }
    if (hour < 0 && dateMatch !== null) {
      hour = 23;
      minute = 59;
    }
    if (hour < 0) {
      return hint;
    }
    const now: Date = new Date();
    const target: Date = new Date(now.getTime());
    let hasDate: boolean = false;
    if (dateMatch !== null) {
      const month: number = Number(dateMatch[1]);
      const day: number = Number(dateMatch[2]);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        target.setMonth(month - 1, day);
        hasDate = true;
      }
    } else if (match !== null && match[1] !== undefined) {
      const token: string = match[1];
      let offset: number = 0;
      if (token === '明天') {
        offset = 1;
      } else if (token === '后天') {
        offset = 2;
      } else if (token === '大后天') {
        offset = 3;
      }
      if (offset > 0) {
        target.setDate(target.getDate() + offset);
        hasDate = true;
      } else if (token.startsWith('本周') || token.startsWith('下周')) {
        const weekdays: string = '一二三四五六日';
        const idx: number = weekdays.indexOf(token.charAt(2));
        if (idx >= 0) {
          const base: number = token.startsWith('本周') ? 0 : 7;
          const current: number = target.getDay() === 0 ? 6 : target.getDay() - 1;
          target.setDate(target.getDate() + base + idx - current);
          hasDate = true;
        }
      }
    }
    if (!hasDate) {
      // 只有时刻没有日期：只保留原话，不猜截止日
      return hint;
    }
    target.setHours(hour, minute, 0, 0);
    hint.at = target.getTime();
    hint.allDay = dateMatch === null && match !== null && match[3] === undefined;
    return hint;
  }

  /** 中文数字 1~59；失败返回 -1 */
  private static cnNumber(raw: string): number {
    if (/^[0-9]+$/.test(raw)) {
      return Number(raw);
    }
    const digits: string = '零一二三四五六七八九';
    if (raw === '十') {
      return 10;
    }
    if (raw.indexOf('十') >= 0) {
      const parts: string[] = raw.split('十');
      const tens: number = parts[0].length === 0 ? 1 : digits.indexOf(parts[0]);
      const ones: number = parts[1].length === 0 ? 0 : digits.indexOf(parts[1]);
      return tens >= 0 && ones >= 0 ? tens * 10 + ones : -1;
    }
    return raw.length === 1 ? digits.indexOf(raw) : -1;
  }

  /**
   * 抽一片（≤1000 字符）。**动态 import 只在这里发生**，失败即降级。
   */
  private static async extractChunk(chunk: string): Promise<TextExtractChunk> {
    const out: TextExtractChunk = new TextExtractChunk();
    let entities: TextExtractEntity[] = [];
    try {
      // 工程硬约束：AI 能力只能动态 import（说明符必须是**字面量**，否则编译期解析不到）。
      // ⚠️ 外面这层 `Promise.resolve` 不是为了业务：本机 CodeLinter 把 `import('@kit.*')` 的返回类型
      //    当成**非 Promise**（`@typescript-eslint/await-thenable` 报错），包一层后无论它到底是不是
      //    Promise 都能 `await` 到命名空间，也不需要在源码里禁用规则。
      const ns = await Promise.resolve(import('@kit.NaturalLanguageKit'));
      // 同一条 lint 口径：从动态 import 得到的命名空间上取到的成员，类型对 linter 是「未知」，
      // 直接 await 会被判成 await 非 Promise；包一层 Promise.resolve 既不改运行期语义，也能过检查。
      //
      // ⚠️ 这里**不能**写 `ns.textProcessing === undefined` 这种判空 —— ArkTS 报
      //   `Namespaces cannot be used as objects (arkts-no-ns-as-obj)`。
      // 实测（HarmonyOS 7.0.0 模拟器，2026-10-25）：动态 import 本身**不抛**，
      // 但 `ns.textProcessing` 是 `undefined`，链式调用抛 TypeError
      // `Cannot read property getEntity of undefined` → 交给下面的 catch 归到 `unsupported`。
      const list = await Promise.resolve(ns.textProcessing.getEntity(chunk, {
        // 官方建议：按需加载实体类型以提升性能 —— 这里只要时间与地点
        entityTypes: [ns.EntityType.DATETIME, ns.EntityType.LOCATION]
      }));
      if (list !== undefined && list !== null) {
        for (let i = 0; i < list.length; i++) {
          const entity = list[i];
          const one: TextExtractEntity = new TextExtractEntity();
          one.text = entity.text !== undefined ? entity.text : '';
          one.isDateTime = entity.type === ns.EntityType.DATETIME;
          one.isLocation = entity.type === ns.EntityType.LOCATION;
          one.json = entity.jsonObject !== undefined ? entity.jsonObject : '';
          entities.push(one);
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      // 设备/模拟器没有这个能力时，链式调用抛的是 **TypeError**（没有 `code`），
      // 实测 message 形如 `Cannot read property getEntity of undefined` —— 归到 `unsupported`，
      // 不要让它显示成一句看不懂的英文 TypeError。
      const msg: string = err.message !== undefined ? err.message : '';
      const missing: boolean = err.name === 'TypeError' || msg.indexOf('of undefined') >= 0;
      hilog.warn(DOMAIN, TAG, 'getEntity failed: missing=%{public}s code=%{public}s msg=%{public}s',
        String(missing), String(err.code), msg);
      out.ok = false;
      out.code = missing ? 'unsupported' : TextExtractService.mapErrorCode(err.code);
      out.message = missing ? '这台设备不支持本地实体抽取（模拟器通常不支持）'
        : TextExtractService.mapErrorMessage(err.code);
      return out;
    }

    out.ok = true;
    for (let i = 0; i < entities.length; i++) {
      const entity: TextExtractEntity = entities[i];
      if (entity.isDateTime && out.time === undefined) {
        const hint: LocalTimeHint | undefined = TextExtractService.readTime(entity);
        if (hint !== undefined) {
          out.time = hint;
        }
      } else if (entity.isLocation && out.place.length === 0) {
        const name: string = TextExtractService.readPlace(entity);
        if (name.length > 0) {
          out.place = name;
        }
      }
    }
    return out;
  }

  /** 时间实体 → `LocalTimeHint`；拿不到可用时间时**仍保留原话**（`dueText` 有用） */
  private static readTime(entity: TextExtractEntity): LocalTimeHint | undefined {
    const hint: LocalTimeHint = new LocalTimeHint();
    hint.text = entity.text;
    if (entity.json.length === 0) {
      return hint;
    }
    let root: RawTimeRoot;
    try {
      root = JSON.parse(entity.json) as RawTimeRoot;
    } catch (error) {
      return hint;
    }
    const items: RawTimeItem[] | undefined = root.time;
    if (items === undefined || items.length === 0) {
      return hint;
    }
    const item: RawTimeItem = items[0];
    if (item.isIllegal === true) {
      // 官方：「2月30号」这类会被自动改到 28/29 号并标非法 —— 这种时间不写 dueAt
      return hint;
    }
    const start: string = item.start !== undefined ? item.start : (item.suggestStart !== undefined ? item.suggestStart : '');
    const ts: number = item.startTimestamp !== undefined ? item.startTimestamp : 0;
    // ① 必须是完整年月日：只给了「2026-10」这种年月，落到月首会算成一条奇怪的截止时间
    const fullDate: boolean = TextExtractService.hasFullDate(start);
    if (!fullDate || ts <= 0) {
      return hint;
    }
    // ② 有没有精确时刻（`T` 后面是 HH:mm[:ss]）；`TM` 这种模糊时段不算
    const clock: boolean = TextExtractService.hasClock(start);
    if (clock) {
      hint.at = ts;
      return hint;
    }
    // ③ 只给日期 → 按应用约定取当天 23:59（详情页到期选择器的默认值也是这个口径）
    //    复用一个 Date 实例：这条路径可能被逐实体调用，lint 的 reuse-date-instances 规则会盯 new Date
    TextExtractService.dayProbe.setTime(ts);
    TextExtractService.dayProbe.setHours(23, 59, 0, 0);
    hint.at = TextExtractService.dayProbe.getTime();
    hint.allDay = true;
    return hint;
  }

  /** 「只给日期时取当天 23:59」用的可复用实例（单线程 UI，不会并发） */
  private static readonly dayProbe: Date = new Date(0);

  /** 地点实体 → 地点名：优先 `coreLocation.value`（去掉修饰词的核心地点），退回 `oriText` / 实体原文 */
  private static readPlace(entity: TextExtractEntity): string {
    if (entity.json.length > 0) {
      try {
        const root: RawLocationRoot = JSON.parse(entity.json) as RawLocationRoot;
        const items: RawLocationItem[] | undefined = root.location;
        if (items !== undefined && items.length > 0) {
          const core: RawLocationCore | undefined = items[0].coreLocation;
          if (core !== undefined) {
            const value: string = core.value !== undefined ? core.value.trim() : '';
            if (value.length > 0) {
              return value;
            }
            const ori: string = core.oriText !== undefined ? core.oriText.trim() : '';
            if (ori.length > 0) {
              return ori;
            }
          }
        }
      } catch (error) {
        // jsonObject 解析不了就退回实体原文
      }
    }
    return entity.text.trim();
  }

  /** `start` 是否是完整年月日（`YYYY-MM-DD` 开头） */
  private static hasFullDate(start: string): boolean {
    return /^\d{4}-\d{2}-\d{2}/.test(start);
  }

  /** `start` 里有没有精确时刻（`T` 后面必须是 `HH:mm`，`TM` / `T上午` 都不算） */
  private static hasClock(start: string): boolean {
    const idx: number = start.indexOf('T');
    if (idx < 0 || idx + 1 >= start.length) {
      return false;
    }
    return /^\d{1,2}:\d{2}/.test(start.substring(idx + 1));
  }

  /**
   * 切成 ≤1000 字符的片。
   *
   * 切片点优先落在**标点/换行**上（往回最多看 120 字符）：直接把 1000 字符硬切很容易把
   * 「10月30日 18:00 交到 A201」这样的实体切成两半，两边都抽不出来。
   */
  private static chunkText(text: string): string[] {
    const chunks: string[] = [];
    let rest: string = text;
    while (rest.length > 0 && chunks.length < MAX_CHUNKS) {
      if (rest.length <= MAX_CHUNK_CHARS) {
        chunks.push(rest);
        break;
      }
      const cut: number = TextExtractService.findCut(rest);
      chunks.push(rest.substring(0, cut));
      // 不用 trimStart（运行时支持面不确定）：直接抹掉开头空白
      rest = rest.substring(cut).replace(/^\s+/, '');
    }
    return chunks;
  }

  /** 找一个尽量"安全"的切点（返回切在第几个字符之后）；找不到就硬切 1000 */
  private static findCut(text: string): number {
    const from: number = Math.max(1, MAX_CHUNK_CHARS - BOUNDARY_LOOKBACK);
    for (let i = MAX_CHUNK_CHARS - 1; i >= from; i--) {
      const ch: string = text.charAt(i);
      if (STRONG_BOUNDARIES.indexOf(ch) >= 0) {
        return i + 1;
      }
    }
    for (let i = MAX_CHUNK_CHARS - 1; i >= from; i--) {
      const ch: string = text.charAt(i);
      if (WEAK_BOUNDARIES.indexOf(ch) >= 0) {
        return i + 1;
      }
    }
    return MAX_CHUNK_CHARS;
  }

  /** `BusinessError.code` → 本服务的错误码 */
  private static mapErrorCode(code: number): string {
    if (code === 200) {
      return 'timeout';
    }
    if (code === 401) {
      return 'param';
    }
    if (code === 1011200001) {
      return 'engine';
    }
    if (code === 1011200002) {
      return 'service';
    }
    return 'unsupported';
  }

  private static mapErrorMessage(code: number): string {
    if (code === 200) {
      return '本地抽取超时，请重试';
    }
    if (code === 401) {
      return '本地抽取参数不合法';
    }
    if (code === 1011200001) {
      return '本地抽取引擎执行失败';
    }
    if (code === 1011200002) {
      return '本地抽取服务异常';
    }
    return '这台设备/模拟器不支持本地实体抽取';
  }
}

/** 一片的抽取结果（内部用） */
class TextExtractChunk {
  ok: boolean = false;
  code: string = '';
  message: string = '';
  time: LocalTimeHint | undefined = undefined;
  place: string = '';
}

/** 把官方 `Entity` 拍平成内部结构（避免把 Kit 的类型带出本文件） */
class TextExtractEntity {
  text: string = '';
  json: string = '';
  isDateTime: boolean = false;
  isLocation: boolean = false;
}
