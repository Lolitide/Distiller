/*
 * 「添加任务」半模态的**表单草稿**（ViewModel 层）。
 *
 * 为什么要有这个类（需求方 2026-10-17：「半模态右上角关闭按钮旁加一个保存按钮…点击后创建一个任务」）：
 * 表单的各个字段原本散在五个子组件里（名称在 `AddTaskNameInput`、日期/提醒/重复/重要程度/来源/标签在
 * `AddTaskAttributeChips`、原文在 `AddTaskTextInput`、截图 URI 在 `AddTaskScreenshotPicker`…），
 * 而**保存按钮在 `AddTaskSheet` 的标题栏上** —— 它得能读到全部字段才能拼出一个 `Task`。
 * 于是按 V2 的官方式样做成 **`@ObservedV2` 对象 + `@Trace` 字段**：`AddTaskSheet` `new` 一个实例，
 * **按引用**传给各子组件（⚠️ 官方 FAQ：`@ObservedV2` 的类必须 `new` 出来才可观测）。
 * 这样既不把状态在几层之间搬来搬去，也没有"两处各存一份"的漂移风险。
 *
 * 字段口径与 UI 一一对应：
 *   · `name`        —— 任务名（**必填**，为它挂着「保存」的灰/亮）
 *   · `sourceTab`   —— 来源页签（0 截图 / 1 录音 / 2 文本，见 `AddTaskSource`）
 *   · `dueAt` / `remindAt` —— 毫秒时间戳，`0` ＝ 未设置（与 chips 里的哨兵一致）
 *   · `repeatIndex` / `priorityIndex` / `sourceIndex` —— 档位下标，`-1` ＝ 该字段未设置（来源可空）
 *   · `tags` / `rawText` / `imageUri` / `recordSeconds` —— 标签、原文、截图、录音时长
 */
import { RepeatFrequency, RepeatRule, Task, TaskAlarm, TaskPriority, TaskSource, TaskStatus } from '../model';

/** 「未设置」的哨兵（时间戳不可能为 0；档位取不到就是 -1） */
const UNSET_NUMBER: number = 0;
const UNSET_INDEX: number = -1;

/**
 * 重复档位 → 契约里的 `RepeatFrequency`（顺序与 chips / 详情页的 `REPEAT_OPTIONS` 一致：
 * 不重复 / 每天 / 每周 / 每月 / 每年）。
 */
const REPEAT_NONE_INDEX: number = 0;

/** 重要程度档位 → `TaskPriority`（0 普通 / 1 重要 / 2 紧急） */
const PRIORITY_NORMAL_INDEX: number = 0;

/** 来源档位 → `TaskSource`（顺序与详情页 `SOURCE_VALUES` 一致：粘贴 / 分享 / 机器人 / 语音 / 手动） */
const SOURCE_VALUES: TaskSource[] = [
  TaskSource.PASTE,
  TaskSource.SHARE,
  TaskSource.BOT,
  TaskSource.VOICE,
  TaskSource.MANUAL
];

@ObservedV2
export class AddTaskDraft {
  /** 任务名（**必填**） */
  @Trace name: string = '';
  /** 来源页签：0 截图 / 1 录音 / 2 文本 */
  @Trace sourceTab: number = 0;
  /** 截止时刻（毫秒；`0` ＝ 未设置） */
  @Trace dueAt: number = UNSET_NUMBER;
  /** 提醒时刻（毫秒；`0` ＝ 未设置） */
  @Trace remindAt: number = UNSET_NUMBER;
  /** 重复档位：0 不重复 / 1 每天 / 2 每周 / 3 每月 / 4 每年 */
  @Trace repeatIndex: number = REPEAT_NONE_INDEX;
  /** 重要程度档位：0 普通 / 1 重要 / 2 紧急（必填，默认普通） */
  @Trace priorityIndex: number = PRIORITY_NORMAL_INDEX;
  /** 来源档位：`-1` ＝ 未设置 */
  @Trace sourceIndex: number = UNSET_INDEX;
  /** 标签（用户输入的自由文本） */
  @Trace tags: string[] = [];
  /** 文本来源的原文 */
  @Trace rawText: string = '';
  /** 截图的 URI（系统 picker 给的那条） */
  @Trace imageUri: string = '';
  /** 录音时长（秒，目前只是 UI 计时，音频还没真录） */
  @Trace recordSeconds: number = 0;

  /** 名称非空才能保存（「保存」按钮的灰/亮看它） */
  get canSave(): boolean {
    return this.name.trim().length > 0;
  }

  /**
   * 把草稿拼成一个契约里的 `Task`（字段表 28 项）。
   *
   * · `id` 由调用方（`TaskListStore`）给，保证自增唯一；
   * · `status` 走 `CONFIRMED`（用户手动建的任务自己就是确认过的，不是待确认的候选）；
   * · `rawText` / `rawJson`：原文**必存**（「原文对照」的依据、永不上云）；`rawJson` 手动建的没有来源 JSON，
   *   用一段最小的自描述 JSON 兜住"必存"这条；
   * · `dueText` / `repeatText` 等"来源原话"字段手动建的时候没有 → 不写（不编造）；
   * · `missingFields` 按契约推出：缺 location / who / dueAt 时记名字（「缺失不猜测」的工程形式）；
   * · 提醒的 `reminderId` 先不写 —— 那是 `service/system/ReminderService` 发布后回填的句柄，
   *   页面/VM 里不许凭空造（`alarm` 只表达**用户意图**）。
   */
  toTask(id: number): Task {
    const task: Task = new Task();
    task.id = id;
    task.name = this.name.trim();
    task.status = TaskStatus.CONFIRMED;
    task.createdAt = Date.now();
    task.priority = this.priorityToEnum();
    task.alarm = this.remindAt === UNSET_NUMBER ? TaskAlarm.OFF : TaskAlarm.ON;
    task.rawText = this.rawPayload();
    task.rawJson = this.rawJsonPayload();
    if (this.dueAt !== UNSET_NUMBER) {
      task.dueAt = this.dueAt;
    }
    if (this.remindAt !== UNSET_NUMBER) {
      task.remindAt = this.remindAt;
    }
    const rules: RepeatRule[] = this.repeatRules();
    if (rules.length > 0) {
      task.repeat = rules;
    }
    if (this.sourceIndex !== UNSET_INDEX && this.sourceIndex < SOURCE_VALUES.length) {
      task.source = SOURCE_VALUES[this.sourceIndex];
    }
    if (this.tags.length > 0) {
      task.tags = this.tags;
    }
    const urls: string[] = [];
    if (this.imageUri.length > 0) {
      urls.push(this.imageUri);
    }
    if (urls.length > 0) {
      task.urls = urls;
    }
    const missing: string[] = [];
    if (task.dueAt === undefined) {
      missing.push('dueAt');
    }
    if (task.source === undefined) {
      missing.push('source');
    }
    task.missingFields = missing;
    return task;
  }

  /** 草稿归零（保存成功后调用，下次打开半模态是干净的） */
  reset(): void {
    this.name = '';
    this.sourceTab = 0;
    this.dueAt = UNSET_NUMBER;
    this.remindAt = UNSET_NUMBER;
    this.repeatIndex = REPEAT_NONE_INDEX;
    this.priorityIndex = PRIORITY_NORMAL_INDEX;
    this.sourceIndex = UNSET_INDEX;
    this.tags = [];
    this.rawText = '';
    this.imageUri = '';
    this.recordSeconds = 0;
  }

  /** 档位 → `TaskPriority`（显式分支，不拿枚举当数组下标） */
  private priorityToEnum(): TaskPriority {
    if (this.priorityIndex === 2) {
      return TaskPriority.URGENT;
    }
    if (this.priorityIndex === 1) {
      return TaskPriority.IMPORTANT;
    }
    return TaskPriority.NORMAL;
  }

  /**
   * 档位 → 单条 `RepeatRule`（与详情页 `applyRepeat` 同一口径）：
   * 「每周 / 每月 / 每年」需要锚点，锚点优先用**截止日**、没有就用今天。
   * 「不重复」返回空数组（契约里 `repeat` 为空＝不重复）。
   */
  private repeatRules(): RepeatRule[] {
    if (this.repeatIndex === REPEAT_NONE_INDEX) {
      return [];
    }
    const anchor: Date = new Date(this.dueAt !== UNSET_NUMBER ? this.dueAt : Date.now());
    const rule: RepeatRule = new RepeatRule();
    // `frequency` 用**官方整数值**（YEARLY=0 / MONTHLY=1 / WEEKLY=2 / DAILY=3）
    if (this.repeatIndex === 1) {
      rule.frequency = RepeatFrequency.DAILY;
    } else if (this.repeatIndex === 2) {
      rule.frequency = RepeatFrequency.WEEKLY;
      rule.daysOfWeek = [toDaysOfWeek(anchor)];
    } else if (this.repeatIndex === 3) {
      rule.frequency = RepeatFrequency.MONTHLY;
      rule.daysOfMonth = [anchor.getDate()];
    } else {
      rule.frequency = RepeatFrequency.YEARLY;
      rule.monthsOfYear = [anchor.getMonth() + 1];
    }
    return [rule];
  }

  /** 「原文」：文本来源就是粘贴的那段；截图/录音来源先落一句可读的占位（原文以后由 OCR/ASR 补） */
  private rawPayload(): string {
    if (this.rawText.trim().length > 0) {
      return this.rawText.trim();
    }
    if (this.sourceTab === 0 && this.imageUri.length > 0) {
      return this.imageUri;
    }
    if (this.sourceTab === 1 && this.recordSeconds > 0) {
      return `${this.recordSeconds}s`;
    }
    return this.name.trim();
  }

  /** 「平台原始返回」：手动建的任务没有平台 JSON，存一段最小的自描述（契约要求该字段必存） */
  private rawJsonPayload(): string {
    return `{"origin":"manual","sourceTab":${this.sourceTab}}`;
  }
}

/** `Date.getDay()`（0=周日…6=周六）→ 契约里的 `daysOfWeek`（**1~7 ＝ 周一~周日**） */
function toDaysOfWeek(date: Date): number {
  const weekday: number = date.getDay();
  return weekday === 0 ? 7 : weekday;
}
