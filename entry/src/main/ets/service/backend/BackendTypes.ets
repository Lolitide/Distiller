/**
 * service/backend —— 与 `qqbot-backend` 的线上契约（snake_case 原样，不改名）。
 *
 * 为什么保留 snake_case：后端 JSON 就是这些名字（见 `机器人通道_交付文档/05_API接口文档.md`），
 * 映射成本机 28 字段 `Task` 的工作统一放在 `TaskMapper` 里，DTO 这一层不做改名。
 *
 * 纪律：本文件只放类型；不发请求、不读存储。
 */

export interface ApiErrBody {
  code: string;
  message: string;
}

export interface ApiOk<T> {
  ok: true;
  data: T;
}

export interface ApiErr {
  ok: false;
  error: ApiErrBody;
}

/**
 * 统一响应包。
 *
 * ⚠️ 用「单接口 + 可选字段」而不是 `ApiOk<T> | ApiErr` 联合类型：
 * 当前 ArkTS 版本对泛型联合的收窄不完整（`if (!res.ok)` 之后仍报
 * `Property 'error' does not exist`）。单接口形态下用 `res.data` / `res.error`
 * 配合可选链即可，编译与运行都稳。
 */
export interface ApiResult<T> {
  ok: boolean;
  data?: T;
  error?: ApiErrBody;
}

/** 取错误文案（`ApiResult` 不保证有 error 时给个兜底） */
export function apiErrorMessage<T>(res: ApiResult<T>): string {
  const message: string | undefined = res.error !== undefined ? res.error.message : undefined;
  return message !== undefined && message.length > 0 ? message : '请求失败';
}

// ---------------------------------------------------------------- 健康检查

export interface HealthWindow {
  window_items: number;
  window_minutes: number;
  max_seq: number;
}

export interface HealthData {
  ok: boolean;
  version: string;
  api_version?: number;
  capabilities?: string[];
  time: string;
  bot_running: boolean;
  window: HealthWindow;
}

// ---------------------------------------------------------------- 设备 / 绑定 / 群

export interface RegisterData {
  device_id: string;
  token: string;
}

export interface BindCodeData {
  code: string;
  expires_in: number;
  hint: string;
}

export interface BindStatusData {
  bound: boolean;
  user_openid_tail?: string;
  bound_at?: string;
  /** 绑定时刻（毫秒）：用于区分「旧绑定」与「本次新绑定」 */
  bound_at_ms?: number;
  source?: string;
}

export interface GroupItemDto {
  group_openid: string;
  label: string;
  message_count: number;
  last_message_at?: string;
  has_name: boolean;
  subscribed: boolean;
  bot_present: boolean;
}

export interface GroupsData {
  groups: GroupItemDto[];
}

export interface SubscribeData {
  subscribed: boolean;
  group_openid: string;
}

// ---------------------------------------------------------------- 候选

/** 重复规则：字段名与官方 `calendarManager.RecurrenceRule` 同名（后端已对齐） */
export interface RepeatRuleDto {
  frequency: number;
  interval?: number;
  daysOfWeek?: number[];
  daysOfMonth?: number[];
  monthsOfYear?: number[];
  weeksOfMonth?: number[];
  count?: number;
  expire?: number;
  dates?: number[];
}

/** 子步骤：`done` 存 0/1 */
export interface StepDto {
  content: string;
  done: number;
}

export interface MessageAttachmentDto {
  url?: string;
  filename?: string;
  content_type?: string;
  size?: number;
  kind?: string;
}

/** 消息级解析（`/messages` 的 `parse`；字段与 App `CampusEvent` 对应） */
export interface ServeParse {
  engine: string;
  kind: string;
  category: string;
  title: string;
  action: string;
  summary: string;
  items: string[];
  sourceText: string;
  timeText: string;
  timeNormalized: string;
  timeUnresolved: boolean;
  place: string;
  who: string;
  deadline: string;
  confidence: number;
  tags: string[];
  steps?: StepDto[];
  priority?: string;
  level?: number;
  dueAt?: number;
  dueText?: string;
  repeat?: RepeatRuleDto[];
  repeatText?: string;
  certainty?: number;
  missingFields?: string[];
  channel?: string;
}

export interface ServeMessage {
  seq: number;
  group_openid: string;
  group_label: string;
  sender: string;
  content: string;
  timestamp: string;
  msg_id: string;
  event_type: string;
  is_self?: boolean;
  attachments?: MessageAttachmentDto[];
  parse?: ServeParse;
}

export interface MessagesData {
  messages: ServeMessage[];
  max_seq: number;
  server_time: string;
  window_minutes: number;
  subscribed_groups: number;
}

export interface CandidateSource {
  group_openid: string;
  group_label: string;
  senders: string[];
  msg_ids: string[];
  count: number;
  first_ts: string;
  last_ts: string;
}

/** 候选：任务列表的唯一数据源（后端已做去重 + 聚类 + 综合总结） */
export interface CandidateItem {
  candidate_id: string;
  rev_seq: number;
  thread_id: string;
  kind: string;
  priority: string;
  level?: number;
  category?: string;
  channel?: string;
  due_at?: number;
  due_text?: string;
  repeat?: RepeatRuleDto[];
  repeat_text?: string;
  certainty?: number;
  missing_fields?: string[];
  title: string;
  summary: string;
  time_text: string;
  time_normalized: string;
  time_unresolved: boolean;
  place: string;
  who: string;
  deadline: string;
  items: string[];
  steps: StepDto[];
  tags: string[];
  confidence: number;
  engine: string;
  /** 是否规则降级（engine=rules）；前端据此提示「降级解析」 */
  degraded?: boolean;
  source: CandidateSource;
  created_at: string;
}

export interface CandidatesData {
  candidates: CandidateItem[];
  cursor: number;
  server_time: string;
  window_minutes: number;
  changed?: number;
}

/** POST /parse 的返回：一条候选 + 抽取用的合并文本（文本/OCR/文件抽取后的结果） */
export interface ParseData {
  candidate: CandidateItem;
  text: string;
  /** 规则降级标记（后端 engine=rules） */
  degraded?: boolean;
}

// ---------------------------------------------------------------- 其它

export interface MyData {
  device_count: number;
  bindings: number;
  subscriptions: number;
  queue_items: number;
  /** 「不订阅自己发的消息」当前值（服务端默认 true） */
  skip_self?: boolean;
}

export interface DeletedData {
  deleted: boolean;
}

export interface PushTokenData {
  registered: boolean;
  push_ready: boolean;
}

export interface FeedbackBody {
  candidate_id: string;
  action: string;
  group_openid: string;
  kind: string;
}
