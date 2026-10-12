/**
 * 知了 · 消息解析服务（端侧，走 Natural Language Kit）
 *
 * 依据「知了调研.md」：
 *   - 实体抽取 / 分词都不支持模拟器 -> 所有调用 try/catch 降级，失败只标 parseOk=false，不影响主流程；
 *   - 实体抽取文本长度不超过 1000 字符 -> sliceText 切片后逐段抽取并合并；
 *   - 事项判断没有现成能力 -> 交给 ParseRules 的本地关键词规则。
 */

import { EntityType, textProcessing } from '@kit.NaturalLanguageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Store } from './Store';
import { ParsedEntity, ParsedInfo, RobotMessage } from './Types';
import { buildSummary, classifyCategory } from './ParseRules';

const DOMAIN: number = 0x0000;
const TAG: string = 'ParseService';
/** Natural Language Kit 单次输入上限（字符） */
const NLP_MAX_CHARS: number = 1000;
/** 每拍最多解析的条数，避免长列表一次性阻塞 */
const PARSE_BATCH: number = 20;
/** 列表摘要最大字数 */
const SUMMARY_MAX_CHARS: number = 24;
/** 单次 NL Kit 调用超时（毫秒），超时按失败降级，避免卡死解析队列 */
const NLP_TIMEOUT_MS: number = 8000;

export class ParseService {
  private static busy: boolean = false;

  /** 按句读边界把长文本切成不超过 NLP_MAX_CHARS 的片段。 */
  static sliceText(text: string): string[] {
    const chunks: string[] = [];
    if (text.length === 0) {
      return chunks;
    }
    if (text.length <= NLP_MAX_CHARS) {
      chunks.push(text);
      return chunks;
    }
    const segments: string[] = ParseService.splitSegments(text);
    let buf: string = '';
    for (let i = 0; i < segments.length; i++) {
      const seg: string = segments[i];
      if (seg.length > NLP_MAX_CHARS) {
        if (buf.length > 0) {
          chunks.push(buf);
          buf = '';
        }
        for (let p = 0; p < seg.length; p += NLP_MAX_CHARS) {
          chunks.push(seg.substring(p, Math.min(p + NLP_MAX_CHARS, seg.length)));
        }
        continue;
      }
      if (buf.length + seg.length > NLP_MAX_CHARS) {
        if (buf.length > 0) {
          chunks.push(buf);
        }
        buf = seg;
      } else {
        buf += seg;
      }
    }
    if (buf.length > 0) {
      chunks.push(buf);
    }
    return chunks;
  }

  private static splitSegments(text: string): string[] {
    const segs: string[] = [];
    let start: number = 0;
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ch === '。' || ch === '！' || ch === '？' || ch === '\n' || ch === '!' || ch === '?') {
        segs.push(text.substring(start, i + 1));
        start = i + 1;
      }
    }
    if (start < text.length) {
      segs.push(text.substring(start));
    }
    return segs;
  }

  private static typeToString(t: EntityType): string {
    if (t === EntityType.DATETIME) {
      return 'datetime';
    }
    if (t === EntityType.LOCATION) {
      return 'location';
    }
    if (t === EntityType.NAME) {
      return 'name';
    }
    if (t === EntityType.PHONE_NO) {
      return 'phoneNo';
    }
    if (t === EntityType.URL) {
      return 'url';
    }
    if (t === EntityType.EMAIL) {
      return 'email';
    }
    if (t === EntityType.EXPRESS_NO) {
      return 'expressNo';
    }
    if (t === EntityType.FLIGHT_NO) {
      return 'flightNo';
    }
    if (t === EntityType.VERIFICATION_CODE) {
      return 'verificationCode';
    }
    if (t === EntityType.ID_NO) {
      return 'idNo';
    }
    return '';
  }

  private static async extractEntities(chunk: string): Promise<ParsedEntity[]> {
    const config: textProcessing.EntityConfig = {
      entityTypes: [EntityType.DATETIME, EntityType.LOCATION, EntityType.NAME,
        EntityType.PHONE_NO, EntityType.URL, EntityType.EMAIL]
    };
    const result: textProcessing.Entity[] | null =
      await ParseService.withTimeout<textProcessing.Entity[]>(textProcessing.getEntity(chunk, config), NLP_TIMEOUT_MS);
    if (result === null) {
      throw new Error('nlp entity timeout');
    }
    const out: ParsedEntity[] = [];
    for (let i = 0; i < result.length; i++) {
      const e: textProcessing.Entity = result[i];
      const kind: string = ParseService.typeToString(e.type);
      if (kind.length > 0 && e.text.length > 0) {
        out.push({ type: kind, text: e.text });
      }
    }
    return out;
  }

  private static async extractNounWords(chunk: string): Promise<string[]> {
    const segs: textProcessing.WordSegment[] | null =
      await ParseService.withTimeout<textProcessing.WordSegment[]>(textProcessing.getWordSegment(chunk), NLP_TIMEOUT_MS);
    if (segs === null) {
      return [];
    }
    const out: string[] = [];
    for (let i = 0; i < segs.length; i++) {
      const tag: string = segs[i].wordTag;
      if (tag.length > 0 && tag.charAt(0) === 'n') {
        out.push(segs[i].word);
      }
    }
    return out;
  }

  /**
   * 给 NL Kit 调用加超时保护：该能力在部分设备/模拟器上可能不返回，
   * 不加超时会把 parsePending 的 busy 标志永久锁死，导致所有消息停在「解析中」。
   */
  private static async withTimeout<T>(p: Promise<T>, ms: number): Promise<T | null> {
    let timerId: number = -1;
    const timer: Promise<T | null> = new Promise<T | null>((resolve: (value: T | null) => void) => {
      timerId = setTimeout(() => {
        resolve(null);
      }, ms);
    });
    const result: T | null = await Promise.race<T | null>([p, timer]);
    if (timerId >= 0) {
      clearTimeout(timerId);
    }
    return result;
  }

  /** 解析单条正文；任何异常都降级为 parseOk=false，绝不向上抛出。 */
  static async parseOne(content: string): Promise<ParsedInfo> {
    const at: string = new Date().toISOString();
    try {
      const chunks: string[] = ParseService.sliceText(content);
      const entities: ParsedEntity[] = [];
      for (let c = 0; c < chunks.length; c++) {
        const part: ParsedEntity[] = await ParseService.extractEntities(chunks[c]);
        for (let i = 0; i < part.length; i++) {
          entities.push(part[i]);
        }
      }
      let nounWords: string[] = [];
      try {
        const first: string = chunks.length > 0 ? chunks[0] : content;
        nounWords = await ParseService.extractNounWords(first);
      } catch (e) {
        nounWords = [];
      }
      const info: ParsedInfo = {
        parsedAt: at,
        parseOk: true,
        category: classifyCategory(content, nounWords),
        summary: buildSummary(content, SUMMARY_MAX_CHARS),
        entities: entities
      };
      return info;
    } catch (e) {
      const err = e as Error;
      hilog.warn(DOMAIN, TAG, 'parseOne failed, degrade to raw content: %{public}s', err.message);
      const failed: ParsedInfo = {
        parsedAt: at,
        parseOk: false,
        category: '',
        summary: '',
        entities: []
      };
      return failed;
    }
  }

  /** 尚未解析的消息条数。 */
  private static pendingCount(): number {
    const list: RobotMessage[] = Store.getMessages();
    let n: number = 0;
    for (let i = 0; i < list.length; i++) {
      const at: string | undefined = list[i].parsedAt;
      if (at === undefined || at.length === 0) {
        n++;
      }
    }
    return n;
  }

  /** 批量解析尚未解析的消息（最新优先，每拍上限 PARSE_BATCH 条）。 */
  static async parsePending(): Promise<number> {
    const pending: number = ParseService.pendingCount();
    if (pending === 0) {
      return 0;
    }
    if (ParseService.busy) {
      hilog.warn(DOMAIN, TAG, 'parsePending skipped(busy) pending=%{public}d', pending);
      return 0;
    }
    hilog.info(DOMAIN, TAG, 'parsePending begin pending=%{public}d', pending);
    ParseService.busy = true;
    try {
      const snapshot: RobotMessage[] = Store.getMessages();
      const ids: string[] = [];
      const infos: ParsedInfo[] = [];
      for (let i = 0; i < snapshot.length; i++) {
        if (ids.length >= PARSE_BATCH) {
          break;
        }
        const m: RobotMessage = snapshot[i];
        if (m.parsedAt !== undefined && m.parsedAt.length > 0) {
          continue;
        }
        infos.push(await ParseService.parseOne(m.content));
        ids.push(m.msg_id);
        hilog.info(DOMAIN, TAG, 'parseOne done ok=%{public}s id=%{public}s',
          String(infos[infos.length - 1].parseOk), m.msg_id);
      }
      if (ids.length > 0) {
        ParseService.commit(ids, infos);
        hilog.info(DOMAIN, TAG, 'parsePending committed=%{public}d', ids.length);
      }
      return ids.length;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'parsePending failed');
      return 0;
    } finally {
      ParseService.busy = false;
    }
  }

  /** 强制重新解析指定消息（详情页「重新解析」）。 */
  static async reparse(msgId: string): Promise<boolean> {
    const snapshot: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < snapshot.length; i++) {
      if (snapshot[i].msg_id === msgId) {
        const info: ParsedInfo = await ParseService.parseOne(snapshot[i].content);
        ParseService.commit([msgId], [info]);
        return true;
      }
    }
    return false;
  }

  /**
   * 把解析结果按 msg_id 合并回最新的本地列表后再落库。
   * 解析期间轮询可能写入新消息，直接保存快照会把这些新消息覆盖掉，因此必须重新读取。
   */
  private static commit(ids: string[], infos: ParsedInfo[]): void {
    const fresh: RobotMessage[] = Store.getMessages();
    let changed: boolean = false;
    for (let i = 0; i < fresh.length; i++) {
      const idx: number = ids.indexOf(fresh[i].msg_id);
      if (idx >= 0) {
        ParseService.apply(fresh[i], infos[idx]);
        changed = true;
      }
    }
    if (changed) {
      Store.saveMessages(fresh);
      ParseService.bumpVersion();
    }
  }

  private static apply(msg: RobotMessage, info: ParsedInfo): void {
    msg.parsedAt = info.parsedAt;
    msg.parseOk = info.parseOk;
    msg.category = info.category;
    msg.summary = info.summary;
    msg.entities = info.entities;
  }

  private static bumpVersion(): void {
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
  }
}
