/**
 * 任务领域模型（**v1 定稿 28 字段**）。
 *
 * 口径来源：`任务字段表&idea更新.md`（2026-10-16 v1 定稿）。本次**只更新接口契约**，
 * 文档 §2 的卡片/副卡片视觉改版（两行布局、重要性图形、截止文案新规则、副卡片进度条）**尚未做**。
 *
 * v1 的三条收口裁定（照文档原文）：
 *  1. **时间一律 int 毫秒时间戳** —— 原 `creatDate`/`creatTime`/`ddlDate`/`ddlTime`/`finishDate`/`finishTime`
 *     六个字符串字段合并为 `createdAt` / `dueAt` / `finishedAt`；界面上的「2026.10.16」「19:00」「今天截止」
 *     **全部由渲染层算出，不落库**。
 *  2. **派生字段不落库** —— `isDone` / `hasSubTask` / `isRep` 由 `status` 与数组字段推出，避免双真值源。
 *  3. **打卡型任务移出 MVP** —— `ddlCheck` / `isCheck` 不进契约、不留空壳列。
 *
 * JSON 数组类字段（`repeat` / `tags` / `steps` / `urls` / `missingFields`）在**本机契约里是强类型数组**；
 * 字段表里写的"string（JSON 数组）"是**存储形态**，与数组互转由 repository 负责。
 *
 * 纪律：本层只放类型与常量，不放行为；字段名改动必须同步字段表。
 */

/** 状态（0~5）。**已过期（4）只有系统能写** */
export enum TaskStatus {
  PENDING_CONFIRM = 0,
  CONFIRMED = 1,
  IN_PROGRESS = 2,
  COMPLETED = 3,
  EXPIRED = 4,
  DELETED = 5
}

/** 重要性（0/1/2）。卡片上那个红圈就是它 */
export enum TaskPriority {
  NORMAL = 0,
  IMPORTANT = 1,
  URGENT = 2
}

/** 难易程度（0/1/2）。**卡片不显示，只参与排序**（同档内难的先动手） */
export enum TaskLevel {
  EASY = 0,
  MEDIUM = 1,
  HARD = 2
}

/** 是否提醒（0/1）：**用户意图**，卡片右侧开关读它 */
export enum TaskAlarm {
  OFF = 0,
  ON = 1
}

/**
 * 来源通道（枚举）：`paste` / `share` / `bot` / `voice` / `manual`。
 * 只用于筛查来源，**不用于显示** —— 显示用 `Task.originDetail`（如群名「HMOS 知了APP开发」）。
 */
export enum TaskSource {
  PASTE = 'paste',
  SHARE = 'share',
  BOT = 'bot',
  VOICE = 'voice',
  MANUAL = 'manual'
}

/**
 * 重复频率：**整数语义、与官方 `calendarManager.RecurrenceFrequency` 取值一致**
 * （`YEARLY=0` `MONTHLY=1` `WEEKLY=2` `DAILY=3`）。
 * ⚠️ 不要用字符串周期名 —— 官方只有这四档，「每月最后一天 / 仅工作日 / 调休」都表达不了（字段表 §1.1.3）。
 */
export enum RepeatFrequency {
  YEARLY = 0,
  MONTHLY = 1,
  WEEKLY = 2,
  DAILY = 3
}

/**
 * 一条重复规则。**字段名与官方 `calendarManager.RecurrenceRule` 逐字段同名**
 * （只有 `frequency` 对应官方的 `recurrenceFrequency`），这样「任务 → 日历日程」那一步零翻译。
 *
 * 为什么是**数组**（`Task.repeat`）：一条任务可能同时有不同频率的规则
 * （如「每月 15 号」+「每周一」），单条 `RecurrenceRule` 装不下；
 * **命中任意一条即算今天要做（并集）**，显示时多条之间用「；」分隔。
 */
export class RepeatRule {
  /** 必填。0 每年 / 1 每月 / 2 每周 / 3 每天 */
  frequency: RepeatFrequency = RepeatFrequency.WEEKLY;
  /** 每 N 个周期一次；不填 / ≤1 ＝ 每 1 个周期（「每两周的周二」＝ `frequency: WEEKLY, interval: 2, daysOfWeek: [2]`） */
  interval?: number;
  /** 一周里的第几天：**1~7 ＝ 周一~周日**（官方 range [1,7]） */
  daysOfWeek?: number[];
  /** 一个月里的第几天：1~31（官方原文：当月没有 29/30/31 号时这几个值无效） */
  daysOfMonth?: number[];
  /** 一年里的第几月：1~12 */
  monthsOfYear?: number[];
  /** 一个月里的第几周：1~5 */
  weeksOfMonth?: number[];
  /** 重复次数上限；不填 ＝ 不限 */
  count?: number;
  /** 重复截止日（毫秒时间戳） */
  expire?: number;
  /** **本机扩展，官方没有**：装"规则表达不了"的周期。⚠️ MVP 不产出它（预留） */
  dates?: number[];
}

/**
 * 子任务 / 步骤。`done` 存 **0/1**（不是 boolean）—— 与落库形态一致。
 * 文档 §2.4 的副卡片（步骤列表 + 每步圆圈 + 折叠）尚未做。
 */
export class TaskStep {
  /** 步骤内容 */
  content: string = '';
  /** 是否完成：0 未完成 / 1 已完成 */
  done: number = 0;
}

/**
 * 任务（v1 定稿 28 字段，注释里的序号与字段表一致）。
 *
 * 用 `@ObservedV2` + `@Trace`：卡片上点圆圈、拨开关都是**直接改字段**，靠这套装饰器刷新界面。
 * 非用户填的字段（`id` / `clientTaskId` / `status` 初始值 / `createdAt` / `certainty` 等）
 * 由 repository / 解析层提供。
 */
@ObservedV2
export class Task {
  /** 1. 本机自增主键，非用户填；提醒的 `notificationId` 由它确定性映射 */
  id: number = 0;
  /** 2. 幂等键：跨端对齐用，值取后端候选的 `candidate_id`；同一候选重复拉取按同一条处理 */
  @Trace clientTaskId?: string;
  /** 3. 状态，见 `TaskStatus`；「已过期」只有系统能写 */
  @Trace status: TaskStatus = TaskStatus.PENDING_CONFIRM;
  /** 4. 任务名，**必填** */
  @Trace name: string = '';
  /** 5. 备注（总结）：**只放给人看的总结**，原文不放这里（原文见 `rawText`） */
  @Trace note?: string;
  /** 6. 原文：「原文对照」的唯一依据，永久保留、**永不上云** */
  @Trace rawText?: string;
  /** 7. 平台原始返回：调解析规则的唯一依据，**永不上云** */
  @Trace rawJson?: string;
  /** 8. 截止时刻（毫秒），可为空 */
  @Trace dueAt?: number;
  /** 9. 截止原文：如「本周五」「下周一截止」，来自后端 `time_text` */
  @Trace dueText?: string;
  /** 10. 地点 */
  @Trace place?: string;
  /** 11. 对象：谁的事。后端保证是原文子串 */
  @Trace who?: string;
  /** 12. 创建时刻（毫秒），**必填**、非用户填 */
  @Trace createdAt: number = 0;
  /** 13. 完成时刻（毫秒）：未完成时为空；**完成态卡片显示的就是它** */
  @Trace finishedAt?: number;
  /** 14. 重要性（0/1/2），见 `TaskPriority` */
  @Trace priority: TaskPriority = TaskPriority.NORMAL;
  /** 15. 难易程度（0/1/2），见 `TaskLevel`；卡片不显示，**只参与排序** */
  @Trace level?: TaskLevel;
  /** 16. 是否提醒：**用户意图**，卡片右侧开关读它 */
  @Trace alarm: TaskAlarm = TaskAlarm.OFF;
  /** 17. 提醒时刻（毫秒）：按设置页「提醒提前量」从 `dueAt` 算得；**为空则不给开关** */
  @Trace remindAt?: number;
  /** 18. 提醒句柄：已发布的本地提醒键，撤销用它。**为空而 `alarm=1` ⇒ 开关开了但未生效**（如超 30 条报 1700002） */
  @Trace reminderId?: number;
  /** 18.0.1 这个句柄对应的响铃时刻（改提醒时间后要重发；`reminderId` 存在但时刻不同即过期句柄） */
  @Trace reminderAt?: number;
  /** 18.1 系统日历事件句柄（Calendar Kit 写入后回填；删除/完成时撤销） */
  @Trace calendarEventId?: number;
  /** 18.2 用户是否改过内容字段：为 true 时 5 秒轮询不再覆盖 name/note/dueAt/place/priority（FE-79） */
  @Trace userEdited?: boolean;
  /** 19. 重复规则**数组**（元素见 `RepeatRule`）；命中任一条即算今天要做（并集） */
  @Trace repeat?: RepeatRule[];
  /** 20. 规则外的补充原话：只在规则表达不了时兜底（如「每学期第 3 周交」） */
  @Trace repeatText?: string;
  /** 21. 来源通道（枚举），见 `TaskSource` */
  @Trace source?: TaskSource;
  /** 22. 来源展示名：如群名「HMOS 知了APP开发」。只用于显示，**不参与筛选** */
  @Trace originDetail?: string;
  /** 23. 类型：预设「作业 / 考试 / 活动 / 通知 / 其他」，也可自定义 */
  @Trace category?: string;
  /** 24. 标签（**数组**，界面按数组渲染若干胶囊位，不是单个字符串） */
  @Trace tags?: string[];
  /** 25. 子任务 / 步骤：元素 `{ content, done }`，`done` 存 0/1 */
  @Trace steps?: TaskStep[];
  /** 26. 链接：文档 / 图片 / 网址统一放这里，详情页展示 */
  @Trace urls?: string[];
  /**
   * 26b. 扫码得到的直达链接（二维码/条形码内容是 URL 时写入）。
   * 与 `urls` 分开：`urls` 存本机图片/文件，这个用于详情页「打开链接」。
   */
  @Trace linkUrl?: string;
  /** 27. 置信度（0~100 整数）：后端给 0~1 浮点，由映射层换算成整数 */
  @Trace certainty?: number;
  /** 28. 缺失字段名：由 `place` / `who` / `dueAt` 是否为空推出（「缺失不猜测」的工程形式） */
  @Trace missingFields?: string[];
  /** 29. 待确认状态里是否已看过（真机红点；普通待办不用） */
  @Trace pendingSeen?: boolean;
  /** 30. 待确认来源：group / forward / image（普通待办不用） */
  @Trace pendingSource?: string;
}

/** 类型（`category`）预设：作业 / 考试 / 活动 / 通知 / 其他；也可自定义（字段表 §1 第 23 项） */
export const TASK_CATEGORY_PRESETS: string[] = ['作业', '考试', '活动', '通知', '其他'];

/**
 * **低可信阈值**（0~100 整数）：`Task.certainty` 低于它就算「低可信」，界面要提示用户核对。
 *
 * 取 **60** 的理由（口径写在这里，只有这一个地方能改）：
 *  · 后端给的是簇级解析置信度，实测样本分三档：< 60 基本是「实体抽歪了」的一批，
 *    60~80 是「大致对、细节要靠人看」，> 80 才是能直接信任的；
 *  · Mock 里刻意留了 30 / 58 / 62 三个点（`mock/MockTasks.ets`），60 正好把 30、58 标出来、62 不标 ——
 *    换成 50 就只有 30 会亮，换到 70 连 62 也一起亮，这两种都与"人看一眼就够"不符。
 *
 * ⚠️ 本常量在**三处**生效，改一处即可：卡片角标（`TaskCard`）、详情「置信度 / 地点」行
 *    （`TaskInfoCard`）、添加任务的 AI 预填提示（`AddTaskSheet.parseEvidence` 与到期 chip）。
 *    判定本身只走 `TaskListViewModel.isLowCertainty`。
 */
export const LOW_CERTAINTY_THRESHOLD: number = 60;
