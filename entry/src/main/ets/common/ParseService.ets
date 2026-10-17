/**
 * 知了 · 消息解析服务（端侧，走 Natural Language Kit + Core Vision Kit OCR）
 *
 * 依据「知了调研.md」：
 *   - 实体抽取 / 分词 / OCR 都不支持模拟器 -> 所有调用 try/catch 降级，失败只标 parseOk=false，不影响主流程；
 *   - 实体抽取文本长度不超过 1000 字符 -> sliceText 切片后逐段抽取并合并；
 *   - 事项判断没有现成能力 -> 交给 ParseRules 的本地关键词规则；
 *   - 图片消息 content 为空 -> 按附件 URL 下载后 OCR，识别出的文字作为解析输入。
 */

import { EntityType, textProcessing } from '@kit.NaturalLanguageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Store } from './Store';
import { ParsedEntity, ParsedInfo, RobotMessage, firstImageUrl, firstImageIndex } from './Types';
import { classifyCategory } from './ParseRules';
import { ImageRecognizer, ImageRecognizeResult } from './ImageRecognizer';
import { ApiClient } from './ApiClient';
import { AttachmentStore } from './AttachmentStore';
import { withTimeout } from './AsyncUtil';
import { buildEvent, eventOneLine } from '../nlp/EventBuilder';
import { CampusEvent } from '../nlp/EventTypes';
import { summarizeRecognizedText } from '../nlp/MessageNormalizer';

const DOMAIN: number = 0x0000;
const TAG: string = 'ParseService';
/** Natural Language Kit 单次输入上限（字符） */
const NLP_MAX_CHARS: number = 1000;
/** 每拍最多解析的条数，避免长列表一次性阻塞 */
const PARSE_BATCH: number = 20;
/** 图片识别文字的摘要最大长度（字符） */
const IMAGE_SUMMARY_MAX_CHARS: number = 40;
/** 单次 NL Kit 调用超时（毫秒），超时按失败降级，避免卡死解析队列 */
const NLP_TIMEOUT_MS: number = 8000;

export class ParseService {
  private static busy: boolean = false;

  /** 已经按需跑过 NL Kit 的消息（同一次进程内不重复跑）。 */
  private static nlpDone: Set<string> = new Set<string>();

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
    let result: textProcessing.Entity[] | null = null;
    try {
      result = await withTimeout<textProcessing.Entity[]>(textProcessing.getEntity(chunk, config), NLP_TIMEOUT_MS);
    } catch (e) {
      result = null; // Kit 抛异常：视同超时，由 parseOne 统一降级
    }
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
    let segs: textProcessing.WordSegment[] | null = null;
    try {
      segs = await withTimeout<textProcessing.WordSegment[]>(textProcessing.getWordSegment(chunk), NLP_TIMEOUT_MS);
    } catch (e) {
      segs = null; // Kit 抛异常：视同超时，分词降级为空
    }
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
   * 识别消息里的图片附件。
   *
   * 取字节的顺序：**① 本机落盘的副本 → ② 后端 `/attachment` 过路 → ③ 端上直连**。
   * ① 是 2026-10 加的：轮询时已趁 30 分钟窗口把附件存到沙箱（AttachmentStore），
   * 所以窗口过期后**照样能识别**；② 是没存过时的补救，取到就顺手落盘；
   * ③ 只在前两者都失败时兜底（QQ CDN 直链带时效 rkey，端上直连常常失败）。
   */
  private static async recognizeImage(msg: RobotMessage, imageUrl: string): Promise<ImageRecognizeResult> {
    const idx: number = firstImageIndex(msg.attachments);
    if (idx >= 0 && msg.msg_id.length > 0 && msg.msg_id.indexOf('local_') !== 0) {
      let buf: ArrayBuffer | null = AttachmentStore.readLocal(msg.group_openid, msg.msg_id, idx);
      if (buf === null && ApiClient.deviceId.length > 0) {
        const path: string = '/api/relay/attachment?msg_id=' + msg.msg_id + '&index=' + idx;
        buf = await ApiClient.getBytes(path, 20000);
        if (buf !== null) {
          AttachmentStore.saveBytes(msg.group_openid, msg.msg_id, idx, buf);
        }
      }
      if (buf !== null) {
        return await ImageRecognizer.recognizeBytes(buf);
      }
    }
    return await ImageRecognizer.recognize(imageUrl);
  }

  /**
   * 解析单条消息；任何异常都降级为 parseOk=false，绝不向上抛出。
   *
   * @param withNlp   是否跑 Natural Language Kit（实体 + 分词）。批处理不跑，详情页按需跑。
   * @param nlpOnly   **只补实体**：不重新识别图片、也不产出 event/summary。
   *                  后端已经给过 `parse` 的消息必须走这个模式 —— 否则端侧规则会把
   *                  后端更好的总结与卡片字段（priority/dueAt/repeat/steps）覆盖掉。
   */
  static async parseOne(msg: RobotMessage, withNlp: boolean,
    nlpOnly: boolean = false): Promise<ParsedInfo> {
    const at: string = new Date().toISOString();
    // 图片识别结果早就落过库，nlpOnly 时直接复用，不再下载/识别
    let imageText: string = msg.imageText ?? '';
    let imageKind: string = msg.imageKind ?? '';
    try {
      let content: string = msg.content;
      if (!nlpOnly) {
        const imageUrl: string = firstImageUrl(msg.attachments);
        if (imageUrl.length > 0) {
          const rec: ImageRecognizeResult = await ParseService.recognizeImage(msg, imageUrl);
          imageKind = rec.kind;
          imageText = rec.text;
          if (imageText.trim().length > 0) {
            // 图文同时存在时两者都保留：原正文在前，识别结果在后
            content = content.trim().length > 0 ? content + '\n' + imageText : imageText;
          }
        }
      }
      // NL Kit（实体抽取 + 分词）**只在详情页按需跑**（withNlp === true）。
      // 它唯一的消费方是详情页那个实体列表，放进「每条消息都跑」的批处理里是用错场景：
      // 既贵（每条约 3 次 Kit 调用 + 逐片超时）又没人看（HomePage.entityListFor 是死代码）。
      let entities: ParsedEntity[] = [];
      let nounWords: string[] = [];
      if (withNlp) {
        const chunks: string[] = ParseService.sliceText(content);
        for (let c = 0; c < chunks.length; c++) {
          const part: ParsedEntity[] = await ParseService.extractEntities(chunks[c]);
          for (let i = 0; i < part.length; i++) {
            entities.push(part[i]);
          }
        }
        try {
          const first: string = chunks.length > 0 ? chunks[0] : content;
          nounWords = await ParseService.extractNounWords(first);
        } catch (e) {
          nounWords = [];
        }
      }
      // T0–T2：把正文整理成事件对象（分级过滤 + 槽位抽取 + 模板成句）
      const ev: CampusEvent = buildEvent(content, msg.sender, msg.timestamp, msg.msg_id);
      // 图片识别出来的整屏文字先压成摘要再展示，避免界面变成一堵墙
      const imageSummary: string = imageText.length > 0
        ? summarizeRecognizedText(imageText, IMAGE_SUMMARY_MAX_CHARS) : '';
      const info: ParsedInfo = {
        parsedAt: at,
        parseOk: true,
        // 类别：用户画像的载体（教务/活动/招聘/二手/闲聊）
        category: classifyCategory(content, nounWords),
        // 摘要：由事件模板拼出的一句话（不是模型生成的）
        summary: eventOneLine(ev),
        entities: entities,
        imageText: imageText,
        imageKind: imageKind,
        imageSummary: imageSummary,
        event: ev
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
        entities: [],
        imageText: imageText,
        imageKind: imageKind,
        imageSummary: ''
      };
      return failed;
    }
  }

  /**
   * 只跑 NL Kit 实体抽取（按需场景：手动添加任务页的实体标签）。
   * 任何失败（模拟器不支持/超时）都降级为空数组、绝不向上抛——
   * 规则解析出的结构化事件不能被 Kit 的失败拖垮。
   */
  static async entitiesOf(text: string): Promise<ParsedEntity[]> {
    try {
      const chunks: string[] = ParseService.sliceText(text);
      const out: ParsedEntity[] = [];
      for (let c = 0; c < chunks.length; c++) {
        const part: ParsedEntity[] = await ParseService.extractEntities(chunks[c]);
        for (let i = 0; i < part.length; i++) {
          out.push(part[i]);
        }
      }
      return out;
    } catch (e) {
      return [];
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
        infos.push(await ParseService.parseOne(m, false));   // 批处理不跑 NL Kit
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

  /** 强制重新解析指定消息（详情页「重新解析」）。跑满 NL Kit。 */
  static async reparse(msgId: string): Promise<boolean> {
    const snapshot: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < snapshot.length; i++) {
      if (snapshot[i].msg_id === msgId) {
        ParseService.nlpDone.add(msgId);
        // 后端已解析过 -> **只补实体**。用端侧规则重算会把后端更好的
        // summary 覆盖成「通知：标题」、还会把 event 上的卡片字段抹掉。
        const nlpOnly: boolean = snapshot[i].parse !== undefined;
        const info: ParsedInfo = await ParseService.parseOne(snapshot[i], true, nlpOnly);
        ParseService.commit([msgId], [info], nlpOnly);
        return true;
      }
    }
    return false;
  }

  /**
   * 详情页进入时调用：只对**这一条**跑一次 NL Kit（实体 + 分词），跑过就不重复。
   * 批处理已不再跑 NL Kit，所以实体列表靠这里按需补上。
   */
  static async ensureNlp(msgId: string): Promise<boolean> {
    if (msgId.length === 0 || ParseService.nlpDone.has(msgId)) {
      return false;
    }
    return await ParseService.reparse(msgId);
  }

  /**
   * 把解析结果按 msg_id 合并回最新的本地列表后再落库。
   * 解析期间轮询可能写入新消息，直接保存快照会把这些新消息覆盖掉，因此必须重新读取。
   */
  private static commit(ids: string[], infos: ParsedInfo[], nlpOnly: boolean = false): void {
    const fresh: RobotMessage[] = Store.getMessages();
    let changed: boolean = false;
    for (let i = 0; i < fresh.length; i++) {
      const idx: number = ids.indexOf(fresh[i].msg_id);
      if (idx >= 0) {
        ParseService.apply(fresh[i], infos[idx], nlpOnly);
        changed = true;
      }
    }
    if (changed) {
      Store.saveMessages(fresh);
      ParseService.bumpVersion();
    }
  }

  private static apply(msg: RobotMessage, info: ParsedInfo, nlpOnly: boolean): void {
    // 实体永远更新（详情页要的就是它）
    msg.entities = info.entities;
    if (nlpOnly) {
      // 只补实体：**不动** parsedAt / summary / category / event。
      // 后端已经给过的 summary 与卡片字段必须原样保留。
      return;
    }
    msg.parsedAt = info.parsedAt;
    msg.parseOk = info.parseOk;
    msg.category = info.category;
    msg.summary = info.summary;
    msg.imageText = info.imageText ?? '';
    msg.imageKind = info.imageKind ?? '';
    msg.imageSummary = info.imageSummary ?? '';
    msg.event = info.event;
  }

  private static bumpVersion(): void {
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
  }
}
