/**
 * 知了 · 机器人通道 —— 接口类型定义（Types.ets）
 */

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

/** 存进本机的消息：服务端字段 + 两个本地状态字段 */
export interface RobotMessage extends ServeMessage {
  read: boolean;
  handled: boolean;
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
