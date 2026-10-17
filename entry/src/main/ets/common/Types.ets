/**
 * 知了 · 机器人通道 —— 接口类型定义（Types.ets）
 */

import { CampusEvent, CandidateStep, LEVEL_MEDIUM } from '../nlp/EventTypes';
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

  // ---- 卡片字段（《任务字段表&idea更新》v1；后端 card_fields 产出）----
  /** urgent / high / normal / later —— 映射层换算成 0/1/2 */
  priority?: string;
  /** 0 易 / 1 中 / 2 难 */
  level?: number;
  /** bot / manual / paste / share / voice */
  channel?: string;
  /** 截止时刻（毫秒）；0 = 没有 */
  dueAt?: number;
  /** 截止原话（等于 timeText） */
  dueText?: string;
  /** none / day / week / month / year / workingDay */
  repeat?: string;
  /** 重复周期原话 */
  repeatText?: string;
  /** 置信度 ×100（0~100） */
  certainty?: number;
  /** 缺失字段名：place / who / dueAt */
  missingFields?: string[];
  /** 子步骤（副卡片） */
  steps?: CandidateStep[];
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
  /** 子步骤：`{content, done}`（《任务字段表》#25） */
  steps: CandidateStep[];
  tags: string[];
  confidence: number;
  engine: string;
  source: ParseCandidateSource;
  created_at: string;
  // ---- 卡片字段（《任务字段表&idea更新》v1）----
  level?: number;
  category?: string;
  channel?: string;
  due_at?: number;
  due_text?: string;
  repeat?: string;
  repeat_text?: string;
  certainty?: number;
  missing_fields?: string[];
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
  /** 卡片那个完成圆圈：true = 已完成（对应 Task.status = 3） */
  done?: boolean;
  /** 完成时刻（毫秒）；未完成时为空 */
  doneAt?: number;
  /** 提醒开关（**用户意图**，只存本机）。有 dueAt 才给开关 */
  alarm?: boolean;
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

// ============================================================ 用户画像（只存本机）

/**
 * 画像词条的类别。
 *
 * **必须与后端 `profile_summarize.KINDS` 逐字一致**——后端返回的 kind 落不进这里
 * 就会被 `toProfileKind` 归到「关注点」。
 */
export enum ProfileKind {
  /** 关注点：竞赛 / 考研 / 社团 */
  INTEREST = 'interest',
  /** 常去地点：康桥苑 / 主楼A103 */
  PLACE = 'place',
  /** 身份线索：书院 / 专业 / 年级 */
  ROLE = 'role',
  /** 作息：晚上 / 周末 */
  SCHEDULE = 'schedule',
  /** 提醒偏好：从用户自己的操作里总结出来的 */
  PREFERENCE = 'preference'
}

/** 后端 `POST /api/relay/profile` 返回的一条词条（端侧再补 id/时间/来源等本地字段） */
export interface ProfileEntryRaw {
  kind: string;
  term: string;
  weight: number;
  /** 出现次数（端侧统计出来的，后端原样回传） */
  evidence: number;
  /** 由**规则**生成的说明（如「出现 12 次」），不是模型编的 */
  reason: string;
}

/** `POST /api/relay/profile` 的响应 data */
export interface ProfileData {
  entries: ProfileEntryRaw[];
  /** 'llm'（模型归纳）| 'rules'（规则回退） */
  engine: string;
}

/**
 * 一条画像词条（**只存在这台手机上**）。
 *
 * 落盘内容只有「词 + 计数 + 类别 + 权重」，**不含任何聊天原话**——
 * 与按群词表（`group_lexicon`）同一套口径。
 */
export interface ProfileEntry {
  /** 'p_' + kind + '_' + term，幂等：同一个词重复分析不会变成两条 */
  id: string;
  kind: ProfileKind;
  term: string;
  /** 0~100，越大越能代表这个人 */
  weight: number;
  evidence: number;
  firstTs: number;
  lastTs: number;
  /** 'rules' | 'llm' | 'manual' */
  source: string;
  reason: string;
  /** 用户手动加的：AI 更新时只刷权重，绝不改词、绝不删 */
  manual: boolean;
}

/** 一条素材词：**只有词和数字，没有原话**。这是出端侧的唯一形态。 */
export interface ProfileTerm {
  kind: string;
  term: string;
  count: number;
}

/** 画像素材的行为计数（全是数字/枚举串，不含内容） */
export interface ProfileCounters {
  /** 采集到的「我自己发的」消息条数 */
  selfMsgs: number;
  /** 其中被判定为待办/通知/活动/出行计划的条数 */
  todoCount: number;
  /** 被忽略过的条数 */
  dismissCount: number;
  /** 最活跃时段，如 '21:00-23:00'；算不出为空串 */
  activeHours: string;
}

/** 送给后端做归纳的素材包（`POST /api/relay/profile`） */
export interface ProfileMaterial {
  terms: ProfileTerm[];
  counters: ProfileCounters;
}

/** `POST /api/relay/profile` 的请求体 */
export interface ProfileBody {
  material: ProfileMaterial;
  max_entries: number;
}

/** 画像导出文件（换手机时用户自己搬运；导入时当**不可信输入**逐字段校验） */
export interface ProfileExport {
  version: number;
  exported_at: string;
  entries: ProfileEntry[];
}

export function toProfileKind(raw: string): ProfileKind {
  if (raw === 'place') {
    return ProfileKind.PLACE;
  }
  if (raw === 'role') {
    return ProfileKind.ROLE;
  }
  if (raw === 'schedule') {
    return ProfileKind.SCHEDULE;
  }
  if (raw === 'preference') {
    return ProfileKind.PREFERENCE;
  }
  return ProfileKind.INTEREST;
}

export function profileKindLabel(k: ProfileKind): string {
  if (k === ProfileKind.PLACE) {
    return '常去地点';
  }
  if (k === ProfileKind.ROLE) {
    return '身份线索';
  }
  if (k === ProfileKind.SCHEDULE) {
    return '作息';
  }
  if (k === ProfileKind.PREFERENCE) {
    return '提醒偏好';
  }
  return '关注点';
}

/** 词条的稳定 id：同一个 (类别, 词) 永远得到同一个 id。 */
export function profileEntryId(kind: ProfileKind, term: string): string {
  return 'p_' + kind + '_' + term;
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
    tags: p.tags,
    // ---- 卡片字段（映射层换算）----
    priority: priorityToInt(p.priority ?? ''),
    level: p.level ?? LEVEL_MEDIUM,
    dueAt: (p.dueAt !== undefined && p.dueAt > 0) ? p.dueAt : dueAtOf(p.timeNormalized),
    repeat: p.repeat ?? 'none',
    repeatText: p.repeatText ?? '',
    steps: p.steps ?? [],
    certainty: p.certainty ?? Math.round((p.confidence ?? 0) * 100),
    missingFields: p.missingFields ?? [],
    channel: p.channel ?? 'bot',
    category: p.category
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
    tags: c.tags,
    priority: priorityToInt(c.priority ?? ''),
    level: c.level ?? LEVEL_MEDIUM,
    dueAt: (c.due_at !== undefined && c.due_at > 0) ? c.due_at : dueAtOf(c.time_normalized),
    repeat: c.repeat ?? 'none',
    repeatText: c.repeat_text ?? '',
    steps: c.steps ?? [],
    certainty: c.certainty ?? Math.round((c.confidence ?? 0) * 100),
    missingFields: c.missing_fields ?? [],
    channel: c.channel ?? 'manual',
    category: c.category
  };
  return ev;
}

// ============================================================ 卡片字段（映射层）
//
// 口径见 `HM_Cicada/任务字段表/任务字段表&idea更新.md` v1。
// 后端给的是「规则值」，这里做**展示层的换算**：
//   priority 字符串 -> 三态红圈 / confidence -> 0~100 / time_normalized -> 毫秒戳。

/** 后端 priority（urgent/high/normal/later）-> 0 普通 / 1 重要 / 2 紧急。 */
export function priorityToInt(raw: string): number {
  if (raw === 'urgent') {
    return 2;
  }
  if (raw === 'high') {
    return 1;
  }
  return 0;
}

/**
 * `time_normalized` -> 毫秒时间戳（认不出返回 0，与后端的 `due_at` 同口径）。
 *
 * 只有日期（`2026-10-17`）时按**当天 23:59:59** 算——否则零点一过就显示"已过期"，
 * 而"今天截止"显然应该指今天的结束。
 */
export function dueAtOf(timeNormalized: string): number {
  const s: string = (timeNormalized ?? '').trim();
  if (s.length < 10) {
    return 0;
  }
  const hasClock: boolean = s.length >= 16;
  const iso: string = hasClock
    ? s.substring(0, 10) + 'T' + s.substring(11, 16) + ':00'
    : s.substring(0, 10) + 'T23:59:59';
  const t: number = Date.parse(iso);
  return Number.isNaN(t) ? 0 : t;
}

/**
 * 卡片的截止文案（**由 dueAt 与当前时间算出，不落库**）。
 *
 * | 剩余      | 文案            |
 * | ≥24h 今天 | `今天截止`      |
 * | ≥24h 明天 | `明天截止`      |
 * | ≥24h 后天 | `后天截止`      |
 * | ≥24h n 天 | `n 天后截止`    |
 * | <24h      | `__h 后截止`    |
 * | 已过      | `已过期`        |
 *
 * **卡片上不显示时分**（宽度放不下，且与"n 天后截止"并列会互相打架）；
 * 精确时刻只在详情页出现。
 */
export function dueLabel(dueAt: number, nowMs: number): string {
  if (dueAt <= 0) {
    return '';
  }
  const diff: number = dueAt - nowMs;
  if (diff <= 0) {
    return '已过期';
  }
  const HOUR: number = 3600 * 1000;
  if (diff < 24 * HOUR) {
    const h: number = Math.max(1, Math.ceil(diff / HOUR));
    return h + 'h 后截止';
  }
  const a: Date = new Date(nowMs);
  const b: Date = new Date(dueAt);
  const dayA: number = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
  const dayB: number = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());
  const days: number = Math.round((dayB - dayA) / (24 * HOUR));
  if (days <= 0) {
    return '今天截止';
  }
  if (days === 1) {
    return '明天截止';
  }
  if (days === 2) {
    return '后天截止';
  }
  return days + '天后截止';
}

/** 重复周期的展示文案（优先用原文，如「每周一三五」）。 */
export function repeatLabel(repeat: string, repeatText: string): string {
  if (repeat.length === 0 || repeat === 'none') {
    return '';
  }
  if (repeatText.length > 0) {
    return repeatText;
  }
  if (repeat === 'day') {
    return '每天';
  }
  if (repeat === 'week') {
    return '每周';
  }
  if (repeat === 'month') {
    return '每月';
  }
  if (repeat === 'year') {
    return '每年';
  }
  if (repeat === 'workingDay') {
    return '工作日';
  }
  return '';
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
