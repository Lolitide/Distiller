/**
 * 知了 · 机器人通道 —— 接口类型定义（Types.ets）
 */

import { CampusEvent } from '../nlp/EventTypes';

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
}

export interface MessagesData {
  messages: ServeMessage[];
  max_seq: number;
  server_time: string;
  window_minutes: number;
  subscribed_groups: number;
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

export function toRobotMessages(remote: ServeMessage[]): RobotMessage[] {
  const out: RobotMessage[] = [];
  for (let i = 0; i < remote.length; i++) {
    const m: ServeMessage = remote[i];
    out.push({
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
    });
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

/** 该消息是否带图片附件。 */
export function hasImageAttachment(list: MessageAttachment[] | undefined): boolean {
  return firstImageUrl(list).length > 0;
}
