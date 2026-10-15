/**
 * 知了 · 机器人通道 —— 接口类型定义（Types.ets）
 */

import { CampusEvent } from '../nlp/EventTypes';
import { TimeSlot } from '../nlp/TimeParser';

// ============================================================ 统一响应包

export interface ApiError {
  code: string;
  message: string;
}

export interface ApiResult<T> {
  ok: boolean;
  data?: T;
  error?: ApiError;
}

// ============================================================ 各接口的 data

/** GET /api/relay/health */
export interface HealthWindow {
  window_items: number;
  window_minutes: number;
  max_seq: number;
}

export interface HealthData {
  ok: boolean;
  version: string;
  /** v2 能力协商：2 = 支持候选流/反馈；缺省表示老后端（v1） */
  api_version?: number;
  /** 已实现并验证过的能力，如 ["candidates", "feedback"]；缺省视为空 */
  capabilities?: string[];
  time: string;
  bot_running: boolean;
  window: HealthWindow;
}

/** POST /api/relay/device/register */
export interface RegisterData {
  device_id: string;
  token: string;
}

/** POST /api/relay/bind/code */
export interface BindCodeData {
  code: string;
  expires_in: number;
  hint: string;
}

/** GET /api/relay/bind/status */
export interface BindStatusData {
  bound: boolean;
  user_openid_tail?: string;
  bound_at?: string;
  source?: string;
}

/** GET /api/relay/groups */
export interface GroupItem {
  group_openid: string;
  label: string;
  message_count: number;
  last_message_at?: string;
  has_name: boolean;
  subscribed: boolean;
  bot_present: boolean;
}

export interface GroupsData {
  groups: GroupItem[];
}

/** POST /api/relay/subscribe / unsubscribe */
export interface SubscribeData {
  subscribed: boolean;
  group_openid: string;
}

/** 消息附件（图片等）。服务端随消息下发；图片正文靠这个 URL 取回后做 OCR。 */
export interface MessageAttachment {
  content_type?: string;
  filename?: string;
  url?: string;
  height?: number;
  width?: number;
  size?: number;
  voice_wav_url?: string;
  asr_refer_text?: string;
}

/**
 * 后端解析结果（`/api/relay/messages` 里每条消息的可选字段 `parse`）。
 *
 * 后端用小模型（Ollama）优先、失败回退规则，字段值都校验过「必须是原文子串」，
 * 所以不会出现编造的时间/地点。App 拿到它就直接用，**不再跑端侧规则**（端侧规则保留为兜底）。
 */
export interface ServeParse {
  /** 来源：'llm'（后端小模型）| 'rules'（后端规则回退） */
  engine: string;
  kind: string;
  category: string;
  title: string;
  action: string;
  /** 模板拼出的结构化一句话（不是模型自由生成） */
  summary: string;
  /** 后端已归一化的正文（表情/@ 已还原），可直接当「原话」展示 */
  sourceText: string;
  timeText: string;
  timeNormalized: string;
  timeUnresolved: boolean;
  place: string;
  who: string;
  deadline: string;
  /** 需带物品 / 关键注意事项（每条都是原文子串） */
  items: string[];
  confidence: number;
  tags: string[];
}

/** GET /api/relay/messages?after=<seq>&limit=<n> */
export interface ServeMessage {
  seq: number;
  group_openid: string;
  group_label: string;
  sender: string;
  content: string;
  timestamp: string;
  msg_id: string;
  event_type: string;
  /** 是否为本机绑定用户本人发的消息（服务端据 sender_openid 判定） */
  is_self?: boolean;
  /** 附件列表；图片消息的 content 为空，正文在附件 URL 里 */
  attachments?: MessageAttachment[];
  /** 后端结构化解析结果；缺省表示后端未开启解析，App 走端侧规则兜底 */
  parse?: ServeParse;
}

export interface MessagesData {
  messages: ServeMessage[];
  max_seq: number;
  server_time: string;
  window_minutes: number;
  subscribed_groups: number;
}

/** POST /api/relay/feedback（契约 §2.3：候选动作回传，后端只记计数、不存内容） */
export interface FeedbackBody {
  candidate_id: string;
  action: string;
  group_openid: string;
  kind: string;
  edited_fields: string[];
}

/** POST /api/relay/feedback 的响应 */
export interface FeedbackData {
  recorded: boolean;
  candidate_id: string;
  action: string;
  edited_fields: string[];
  dropped_words: string[];
}

/** /parse 候选的来源块（手动添加场景：group_openid/msg_ids 恒空） */
export interface ParseCandidateSource {
  group_openid: string;
  group_label: string;
  senders: string[];
  msg_ids: string[];
  count: number;
  first_ts: string;
  last_ts: string;
}

/** POST /api/relay/parse 响应里的候选（m_ 前缀临时值，后端不入候选流） */
export interface ParseCandidate {
  candidate_id: string;
  rev_seq: number;
  thread_id: string;
  kind: string;
  priority: string;
  title: string;
  summary: string;
  time_text: string;
  time_normalized: string;
  time_unresolved: boolean;
  place: string;
  who: string;
  deadline: string;
  items: string[];
  steps: string[];
  tags: string[];
  confidence: number;
  engine: string;
  source: ParseCandidateSource;
  created_at: string;
}

/** POST /api/relay/parse 的响应 data */
export interface ParseData {
  candidate: ParseCandidate;
  /** 实际参与解析的合并文本（OCR/文件抽取与 text 按序拼接），回显到可编辑框 */
  text: string;
}

/** GET /api/relay/my/data */
export interface MyData {
  device_count: number;
  bindings: number;
  subscriptions: number;
  queue_items: number;
}

/** DELETE /api/relay/my/data */
export interface DeletedData {
  deleted: boolean;
}

// ============================================================ 请求体

export interface RegisterBody {
  name: string;
}

export interface BindCodeBody {
}

export interface SubscribeBody {
  group_openid: string;
  keywords: string;
  min_priority: string;
  mute: boolean;
}

export interface UnsubscribeBody {
  group_openid: string;
}

// ============================================================ 本地模型

/** 解析出的单个实体（只保留展示所需字段，避免依赖 Kit 枚举做序列化） */
export interface ParsedEntity {
  /** 'datetime' | 'location' | 'name' | 'phoneNo' | 'url' | 'email' 等 */
  type: string;
  /** 实体原文 */
  text: string;
}

/** 消息类别（对应「知了调研」用户画像里给定的类别载体） */
export const CATEGORIES: string[] = ['教务', '活动', '招聘', '二手', '闲聊'];

/** 解析结果缓存：parsedAt 非空表示已尝试解析（失败也会写，避免反复重试） */
export interface ParsedInfo {
  parsedAt: string;
  parseOk: boolean;
  category: string;
  summary: string;
  entities: ParsedEntity[];
  /** 图片消息经识别得到的文字；非图片消息为空串 */
  imageText?: string;
  /** 图片识别来源：'qr'（二维码/条形码）或 'text'（OCR） */
  imageKind?: string;
  /** 图片识别文字的压缩摘要（整屏 OCR 直接展示会是一堵墙） */
  imageSummary?: string;
  /** T0–T2 整理出的事件对象（结构化字段 + 原话） */
  event?: CampusEvent;
}

/** 存进本机的消息：服务端字段 + 本地状态字段 + 本地解析字段 */
export interface RobotMessage extends ServeMessage {
  read: boolean;
  handled: boolean;
  /** 用户明确「忽略」的消息：列表不再展示，数据保留（回传过 dismiss 后的本地态） */
  dismissed?: boolean;
  parsedAt?: string;
  parseOk?: boolean;
  category?: string;
  summary?: string;
  entities?: ParsedEntity[];
  /** 图片消息识别出来的文字（二维码码值或 OCR 文字） */
  imageText?: string;
  /** 图片识别来源：'qr' / 'text' */
  imageKind?: string;
  /** 图片识别文字的压缩摘要 */
  imageSummary?: string;
  /** T0–T2 整理出的事件对象 */
  event?: CampusEvent;
}

/** 本地订阅缓存 */
export interface LocalSubscription {
  group_openid: string;
  label: string;
  keywords: string;
  min_priority: string;
  mute: boolean;
  enabled: boolean;
}

/** 页面跳转参数 */
export interface DetailParams {
  msgId: string;
}

// ============================================================ 解析辅助函数

export function parseApi<T>(text: string): ApiResult<T> {
  let obj: ApiResult<T> | null = null;
  try {
    obj = JSON.parse(text) as ApiResult<T>;
  } catch (e) {
    obj = null;
  }
  if (obj === null || typeof obj.ok !== 'boolean') {
    const err: ApiResult<T> = { ok: false, error: { code: 'bad_response', message: '服务端返回格式不对' } };
    return err;
  }
  return obj;
}

/** 后端 parse -> 端侧 CampusEvent（字段已由后端保证是原文子串，这里只做搬运）。 */
function serverEvent(m: RobotMessage, p: ServeParse): CampusEvent {
  let slot: TimeSlot | null = null;
  if (p.timeText.length > 0) {
    slot = {
      text: p.timeText,
      normalized: p.timeNormalized,
      unresolved: p.timeUnresolved,
      sourceDate: ''
    };
  }
  const ev: CampusEvent = {
    kind: p.kind,
    title: p.title,
    action: p.action,
    time: slot,
    place: p.place,
    who: p.who,
    deadline: p.deadline,
    items: p.items ?? [],
    confidence: p.confidence,
    sourceText: p.sourceText.length > 0 ? p.sourceText : m.content,
    sender: m.sender,
    timestamp: m.timestamp,
    msgId: m.msg_id,
    tags: p.tags
  };
  return ev;
}

/** /parse 候选 → 端侧 CampusEvent（手动添加场景；字段由后端校验过是原文子串）。 */
export function parseCandidateToEvent(c: ParseCandidate, sourceText: string,
  msgId: string, ts: string): CampusEvent {
  let slot: TimeSlot | null = null;
  if (c.time_text.length > 0) {
    slot = {
      text: c.time_text,
      normalized: c.time_normalized,
      unresolved: c.time_unresolved,
      sourceDate: ''
    };
  }
  const ev: CampusEvent = {
    kind: c.kind,
    title: c.title,
    action: '',
    time: slot,
    place: c.place,
    who: c.who,
    deadline: c.deadline,
    items: c.items,
    confidence: c.confidence,
    sourceText: sourceText,
    sender: '我',
    timestamp: ts,
    msgId: msgId,
    tags: c.tags
  };
  return ev;
}

export function toRobotMessages(remote: ServeMessage[]): RobotMessage[] {
  const out: RobotMessage[] = [];
  for (let i = 0; i < remote.length; i++) {
    const m: ServeMessage = remote[i];
    const msg: RobotMessage = {
      seq: m.seq,
      group_openid: m.group_openid,
      group_label: m.group_label,
      sender: m.sender,
      content: m.content,
      timestamp: m.timestamp,
      msg_id: m.msg_id,
      event_type: m.event_type,
      is_self: m.is_self === true,
      attachments: m.attachments ?? [],
      read: false,
      handled: false
    };
    // 后端已解析：直接采用，并置 parsedAt 让端侧 ParseService 跳过这条（端侧规则只作兜底）
    const p: ServeParse | undefined = m.parse;
    if (p !== undefined) {
      msg.category = p.category;
      msg.summary = p.summary;
      msg.event = serverEvent(msg, p);
      msg.entities = [];
      msg.parseOk = true;
      msg.parsedAt = new Date().toISOString();
    }
    out.push(msg);
  }
  return out;
}

export function formatTime(timestamp: string): string {
  if (!timestamp || timestamp.length < 16) {
    return timestamp;
  }
  const now: Date = new Date();
  const today: string = `${now.getFullYear()}-${pad2(now.getMonth() + 1)}-${pad2(now.getDate())}`;
  const datePart: string = timestamp.substring(0, 10);
  const timePart: string = timestamp.substring(11, 16);
  return datePart === today ? timePart : `${timestamp.substring(5, 10)} ${timePart}`;
}

function pad2(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

/** 当前时间的 'YYYY-MM-DD HH:mm:ss'（手动添加的本地消息用同一格式的时间戳）。 */
export function nowTimestamp(): string {
  const now: Date = new Date();
  return now.getFullYear() + '-' + pad2(now.getMonth() + 1) + '-' + pad2(now.getDate())
    + ' ' + pad2(now.getHours()) + ':' + pad2(now.getMinutes()) + ':' + pad2(now.getSeconds());
}

/** 取第一条图片附件的 URL；没有图片返回空串。 */
export function firstImageUrl(list: MessageAttachment[] | undefined): string {
  if (list === undefined) {
    return '';
  }
  for (let i = 0; i < list.length; i++) {
    const ct: string = list[i].content_type ?? '';
    const url: string = list[i].url ?? '';
    if (ct.indexOf('image/') === 0 && url.length > 0) {
      return url;
    }
  }
  return '';
}

/**
 * 取第一条图片附件在数组中的下标（`/attachment?index=` 要的就是它）；没有图片返回 -1。
 * 注意：服务端按同一顺序存 attachments，所以这里的下标与后端一致。
 */
export function firstImageIndex(list: MessageAttachment[] | undefined): number {
  if (list === undefined) {
    return -1;
  }
  for (let i = 0; i < list.length; i++) {
    const ct: string = list[i].content_type ?? '';
    const url: string = list[i].url ?? '';
    if (ct.indexOf('image/') === 0 && url.length > 0) {
      return i;
    }
  }
  return -1;
}

/** 该消息是否带图片附件。 */
export function hasImageAttachment(list: MessageAttachment[] | undefined): boolean {
  return firstImageUrl(list).length > 0;
}

/** 体积展示（0/未知 -> 空串）。旧后端可能把 size 序列化成字符串，这里统一兜 de。 */
export function formatBytes(size: number | undefined): string {
  if (size === undefined || !Number.isFinite(size) || size <= 0) {
    return '';
  }
  if (size < 1024) {
    return size + 'B';
  }
  if (size < 1024 * 1024) {
    return Math.round(size / 1024) + 'KB';
  }
  return (size / (1024 * 1024)).toFixed(1) + 'MB';
}

/**
 * 第一个**非图片**附件（文件）在数组中的下标；没有返回 -1。
 *
 * 为什么需要它：QQ 群里的「文件」消息 **content 为空**、正文全在 attachments 里
 * （content_type=file、filename、size、url）。只认 image/* 的话，这类消息在列表里
 * 就是一行空白——这就是 2026-10-15 报的 bug。
 */
export function firstFileIndex(list: MessageAttachment[] | undefined): number {
  if (list === undefined) {
    return -1;
  }
  for (let i = 0; i < list.length; i++) {
    const ct: string = list[i].content_type ?? '';
    if (ct.indexOf('image/') === 0 || ct.indexOf('voice') >= 0 || ct.indexOf('audio/') === 0) {
      continue;
    }
    const name: string = list[i].filename ?? '';
    const url: string = list[i].url ?? '';
    if (name.length > 0 || url.length > 0) {
      return i;
    }
  }
  return -1;
}

/** 该附件是不是本机沙箱里的文件（手动添加时存下来的副本）。 */
export function isLocalAttachment(a: MessageAttachment | undefined): boolean {
  if (a === undefined) {
    return false;
  }
  return (a.url ?? '').indexOf('file://') === 0;
}

/** 文件附件的展示标签（如「文件：朗读文章.docx（26KB）」）；没有文件返回空串。 */
export function fileAttachmentLabel(list: MessageAttachment[] | undefined): string {
  if (list === undefined) {
    return '';
  }
  const idx: number = firstFileIndex(list);
  if (idx < 0) {
    return '';
  }
  const name: string = list[idx].filename ?? '';
  const shown: string = name.length > 0 ? name : '未命名文件';
  const size: string = formatBytes(list[idx].size);
  return size.length > 0 ? '文件：' + shown + '（' + size + '）' : '文件：' + shown;
}

/**
 * POST /api/relay/messages/update：用户对「待办」（消息级 parse）的修改。
 * 只列**可改**字段——engine / confidence / timeNormalized 等派生字段由后端算，不接受改写。
 */
export interface MessageEditFields {
  kind?: string;
  title?: string;
  summary?: string;
  action?: string;
  timeText?: string;
  place?: string;
  who?: string;
  deadline?: string;
  items?: string[];
  tags?: string[];
}

/** POST /api/relay/messages/update 的响应：返回覆盖后的完整 parse。 */
export interface MessageUpdateData {
  msg_id: string;
  parse: ServeParse;
  edited_fields: string[];
}

/**
 * 用户改完后用新的 parse 重建端侧事件对象（本机立即生效，不必等下次轮询）。
 * 只动这一条消息自身。
 */
export function applyParsedEvent(msg: RobotMessage): void {
  const p: ServeParse | undefined = msg.parse;
  if (p === undefined) {
    return;
  }
  msg.event = serverEvent(msg, p);
}

/** 把用户输入的一行文本拆成数组（中英文逗号 / 顿号 / 分号 / 空白都当分隔符）。 */
export function splitListInput(text: string): string[] {
  const normalized: string = text.replace(/[，、；;]/g, ',').replace(/\s+/g, ',');
  const parts: string[] = normalized.split(',');
  const out: string[] = [];
  for (let i = 0; i < parts.length; i++) {
    const s: string = parts[i].trim();
    if (s.length > 0) {
      out.push(s);
    }
  }
  return out;
}

/** 数组拼成可编辑的一行（与 splitListInput 互逆）。 */
export function joinListInput(list: string[] | undefined): string {
  return (list ?? []).join('、');
}

/**
 * 后端存不下（窗口过了 / 未订阅）时，在本机把用户的修改合并进原 parse，
 * 保证「用户改了就一定生效」。时间原话改了就把归一化清空——不猜、不留旧值。
 */
export function mergeLocalParse(base: ServeParse | undefined, f: MessageEditFields): ServeParse {
  const next: ServeParse = {
    engine: base?.engine ?? '',
    kind: base?.kind ?? '',
    category: base?.category ?? '',
    title: base?.title ?? '',
    action: base?.action ?? '',
    summary: base?.summary ?? '',
    sourceText: base?.sourceText ?? '',
    timeText: base?.timeText ?? '',
    timeNormalized: base?.timeNormalized ?? '',
    timeUnresolved: base?.timeUnresolved ?? false,
    place: base?.place ?? '',
    who: base?.who ?? '',
    deadline: base?.deadline ?? '',
    items: base?.items ?? [],
    confidence: base?.confidence ?? 0,
    tags: base?.tags ?? []
  };
  if (f.kind !== undefined && f.kind.length > 0) {
    next.kind = f.kind;
  }
  if (f.title !== undefined) {
    next.title = f.title;
  }
  if (f.summary !== undefined) {
    next.summary = f.summary;
  }
  if (f.action !== undefined) {
    next.action = f.action;
  }
  if (f.place !== undefined) {
    next.place = f.place;
  }
  if (f.who !== undefined) {
    next.who = f.who;
  }
  if (f.deadline !== undefined) {
    next.deadline = f.deadline;
  }
  if (f.items !== undefined) {
    next.items = f.items;
  }
  if (f.tags !== undefined) {
    next.tags = f.tags;
  }
  if (f.timeText !== undefined) {
    if (f.timeText !== next.timeText) {
      // 时间原话变了但端上没有后端那套归一化规则：清空旧值，宁缺勿错（后端在线时由它重算）
      next.timeNormalized = '';
      next.timeUnresolved = false;
    }
    next.timeText = f.timeText;
  }
  return next;
}
