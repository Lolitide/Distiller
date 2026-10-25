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
import {
  RepeatFrequency,
  RepeatRule,
  Task,
  TaskAlarm,
  TaskPriority,
  TaskSource,
  TaskStatus,
  TaskStep
} from '../model';
import { CandidateItem, RepeatRuleDto } from '../service/backend/BackendTypes';

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

/** 草稿快照（落盘用；字段与表单一一对应，不含任何后端数据） */
interface DraftStepSnapshot {
  content: string;
  done: number;
}

interface DraftRepeatSnapshot {
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

interface DraftSnapshot {
  name: string;
  sourceTab: number;
  dueAt: number;
  remindAt: number;
  repeatIndex: number;
  repeatDaysOfWeek: number[];
  repeatInterval: number;
  priorityIndex: number;
  sourceIndex: number;
  tags: string[];
  rawText: string;
  imageUri: string;
  recordSeconds: number;
  place: string;
  who: string;
  category: string;
  dueText: string;
  repeatText: string;
  linkUrl: string;
  /** AI 预填的置信度（0 ＝ 非解析来源）；随草稿落盘，关掉半模态再打开提示还在 */
  certainty?: number;
  /** 后端声明的缺失字段（`missing_fields`） */
  missingFields?: string[];
  /** 本次预填是否来自规则降级（后端 engine=rules） */
  degraded?: boolean;
  /** 用户是否已手动确认过到期时间 */
  timeReviewed?: boolean;
  steps: DraftStepSnapshot[];
  repeat?: DraftRepeatSnapshot;
}

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
  /**
   * 「每周」时选中的星期，取值 1~7（**1 ＝ 周一**，与官方 `RecurrenceRule.daysOfWeek` 同序）。
   *
   * 空数组 ＝ **跟随截止日那一天**（老口径）：用户只选「每周」不选具体星期时，
   * 用截止日落在的星期当锚点，不至于录出一条"没有星期"的每周规则。
   */
  @Trace repeatDaysOfWeek: number[] = [];
  /** 「每周」时的间隔：每 N 周重复一次，最小 1。1 ＝ 每周（与 `daysOfWeek` 组合即「每周一、二、四」） */
  @Trace repeatInterval: number = 1;
  /**
   * `RepeatRuleEditor` 产出的**完整规则**（2026-10-19）。
   *
   * 有了它之后 `repeatRules()` 直接返回这一条，不再靠 `repeatIndex` 推；
   * `repeatDaysOfWeek` / `repeatInterval` 保留为老口径的兜底（编辑器之前的实现仍可能走到）。
   * `undefined` ＝ 不重复。
   */
  @Trace repeatRule: RepeatRule | undefined = undefined;
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

  /* ── AI 预填带来的字段（表单上没有输入框，但 Task 里有，别丢） ── */
  @Trace place: string = '';
  @Trace who: string = '';
  @Trace category: string = '';
  @Trace dueText: string = '';
  @Trace repeatText: string = '';
  /** 扫码得到的直达链接（二维码/条形码是 URL 时） */
  @Trace linkUrl: string = '';
  /** 解析置信度 0~100（0 = 非解析来源）；低于阈值时表单提示「低可信」 */
  @Trace certainty: number = 0;
  /** 本次预填是否来自规则降级（后端 engine=rules） */
  @Trace degraded: boolean = false;
  /** 用户已手动确认过到期时间：低可信提示不再标在时间字段上 */
  @Trace timeReviewed: boolean = false;
  @Trace steps: TaskStep[] = [];

  /**
   * 后端声明的 `missing_fields`（原样保留，用于**溯源**与"后端认定缺了什么"的提示）。
   *
   * 界面上的「未识别」清单**不直接读它** —— 用 `missingHints()` 按**当前草稿**现算：
   * 用户在表单里把到期时间补上之后，那条提示就该消失，而不是继续挂着后端当初的结论。
   */
  @Trace parsedMissing: string[] = [];

  /** 名称非空才能保存（「保存」按钮的灰/亮看它） */
  get canSave(): boolean {
    return this.name.trim().length > 0;
  }

  /**
   * 表单里该提示「没识别出来」的字段（**按当前草稿现算**，顺序固定：到期 → 地点 → 对象 → 来源）。
   *
   * 为什么现算而不是照后端 `missing_fields` 抄：后端那份是"解析那一刻"的结论；
   * 用户在表单里补了到期时间/来源之后，提示要跟着消失，否则会显示一句已经不成立的话。
   * 后端声明里**我们认不出来的字段名**仍原样带进来（不吞），交给 `TaskListViewModel.missingFieldLabel` 兜底显示。
   */
  missingHints(): string[] {
    const fields: string[] = [];
    if (this.dueAt === UNSET_NUMBER) {
      fields.push('dueAt');
    }
    if (this.place.length === 0) {
      fields.push('place');
    }
    if (this.who.length === 0) {
      fields.push('who');
    }
    if (this.sourceIndex === UNSET_INDEX) {
      fields.push('source');
    }
    for (let i = 0; i < this.parsedMissing.length; i++) {
      const field: string = this.parsedMissing[i];
      if (fields.indexOf(field) < 0 && field !== 'dueAt' && field !== 'place'
        && field !== 'who' && field !== 'source') {
        fields.push(field);
      }
    }
    return fields;
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
    if (this.place.length > 0) {
      task.place = this.place;
    }
    if (this.who.length > 0) {
      task.who = this.who;
    }
    if (this.category.length > 0) {
      task.category = this.category;
    }
    if (this.dueText.length > 0) {
      task.dueText = this.dueText;
    }
    if (this.repeatText.length > 0) {
      task.repeatText = this.repeatText;
    }
    if (this.linkUrl.length > 0) {
      task.linkUrl = this.linkUrl;
    }
    // 置信度：AI 预填过才带（`0` ＝ 不是解析来源；手动建的任务没有"可信度"这回事，留 undefined）
    if (this.certainty > 0) {
      task.certainty = this.certainty;
    }
    if (this.steps.length > 0) {
      task.steps = this.steps;
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
    if (this.place.length === 0) {
      missing.push('place');
    }
    if (this.who.length === 0) {
      missing.push('who');
    }
    /*
     * 再把**后端当初声明、而 `toTask` 自己验证不了**的缺失字段接上（如 `category` / `tags`）。
     *
     * 「缺失不猜测」的另一面是**不许悄悄抹掉解析层给出的结论**：
     * 上面四项按最终任务的真实字段重算（用户填了就不算缺），
     * 认不出的字段名则原样保留 —— 真要在详情页展示 `missingFields` 时才不会凭空少几条。
     */
    for (let i = 0; i < this.parsedMissing.length; i++) {
      const field: string = this.parsedMissing[i];
      if (missing.indexOf(field) >= 0 || this.fieldFilled(field)) {
        continue;
      }
      missing.push(field);
    }
    task.missingFields = missing;
    return task;
  }

  /** 某个「后端声明缺失」的字段，在当前草稿里是否已经补上了（只判表单里能编辑的那几个） */
  private fieldFilled(field: string): boolean {
    if (field === 'category') {
      return this.category.length > 0;
    }
    if (field === 'tags') {
      return this.tags.length > 0;
    }
    return false;
  }

  /**
   * 用后端 `/parse` 的候选**预填**表单。只填能确认的字段，不覆盖用户已输入的标签。
   *
   * @param remindLeadMinutes 用户设置的提醒提前量（来自设置页）；AI 给了到期时间时，
   *   按这个提前量落「提醒我」芯片，而不是写死 30 分钟。
   */
  applyParsed(c: CandidateItem, remindLeadMinutes: number = 30): void {
    const title: string = c.title.length > 0 ? c.title : c.summary;
    if (title.length > 0) {
      this.name = title;
    }
    if (c.due_at !== undefined && c.due_at > 0) {
      this.dueAt = c.due_at;
      const leadMs: number = Math.max(0, remindLeadMinutes) * 60 * 1000;
      this.remindAt = c.due_at - leadMs;
    }
    if (c.due_text !== undefined && c.due_text.length > 0) {
      this.dueText = c.due_text;
    } else if (c.time_text.length > 0) {
      this.dueText = c.time_text;
    }
    this.priorityIndex = c.priority === 'urgent' ? 2 : (c.priority === 'high' ? 1 : 0);

    if (c.place.length > 0) {
      this.place = c.place;
    }
    if (c.who.length > 0) {
      this.who = c.who;
    }
    if (c.category !== undefined && c.category.length > 0) {
      this.category = c.category;
    }
    this.certainty = c.certainty !== undefined ? Math.round(c.certainty) : Math.round(c.confidence * 100);
    this.degraded = c.degraded === true;
    this.timeReviewed = false;

    const mergedTags: string[] = this.tags.slice();
    for (let i = 0; i < c.tags.length; i++) {
      if (mergedTags.indexOf(c.tags[i]) < 0) {
        mergedTags.push(c.tags[i]);
      }
    }
    this.tags = mergedTags;

    if (c.steps !== undefined && c.steps.length > 0) {
      const steps: TaskStep[] = [];
      for (let i = 0; i < c.steps.length; i++) {
        const step: TaskStep = new TaskStep();
        step.content = c.steps[i].content;
        step.done = 0;
        steps.push(step);
      }
      this.steps = steps;
    }

    if (c.repeat !== undefined && c.repeat.length > 0) {
      const dto: RepeatRuleDto = c.repeat[0];      const rule: RepeatRule = new RepeatRule();
      rule.frequency = dto.frequency as RepeatFrequency;
      rule.interval = dto.interval !== undefined ? dto.interval : 1;
      if (dto.daysOfWeek !== undefined) {
        rule.daysOfWeek = dto.daysOfWeek;
        this.repeatDaysOfWeek = dto.daysOfWeek;
      }
      if (dto.daysOfMonth !== undefined) {
        rule.daysOfMonth = dto.daysOfMonth;
      }
      if (dto.monthsOfYear !== undefined) {
        rule.monthsOfYear = dto.monthsOfYear;
      }
      this.repeatRule = rule;
      // 芯片上的档位文案与规则对齐（顺序：0 不重复 / 1 每天 / 2 每周 / 3 每月 / 4 每年）
      if (dto.frequency === RepeatFrequency.DAILY) {
        this.repeatIndex = 1;
      } else if (dto.frequency === RepeatFrequency.WEEKLY) {
        this.repeatIndex = 2;
      } else if (dto.frequency === RepeatFrequency.MONTHLY) {
        this.repeatIndex = 3;
      } else {
        this.repeatIndex = 4;
      }
    }
    if (c.repeat_text !== undefined && c.repeat_text.length > 0) {
      this.repeatText = c.repeat_text;
    }

    /*
     * 置信度 ＋ 缺失字段（后端 `/parse` 的同一次返回里就有，**以前这里一个字都没读**）。
     *  · `certainty` 是 0~100 整数；缺省时退回 `confidence`（0~1）—— 与 `TaskMapper.candidateToTask`
     *    同一套换算，免得"同一个候选"在列表里显示一个数、在表单里显示另一个；
     *  · `missing_fields` 原样存下（提示用现算的 `missingHints()`，这里只做溯源）。
     */
    if (c.certainty !== undefined && c.certainty > 0) {
      this.certainty = Math.round(c.certainty);
    } else if (c.confidence !== undefined) {
      this.certainty = Math.round(c.confidence * 100);
    } else {
      this.certainty = 0;
    }
    this.parsedMissing = c.missing_fields !== undefined ? c.missing_fields.slice() : [];
  }

  /** 草稿归零（保存成功后调用，下次打开半模态是干净的） */
  reset(): void {    this.name = '';
    this.sourceTab = 0;
    this.dueAt = UNSET_NUMBER;
    this.remindAt = UNSET_NUMBER;
    this.repeatIndex = REPEAT_NONE_INDEX;
    this.repeatDaysOfWeek = [];
    this.repeatInterval = 1;
    this.priorityIndex = PRIORITY_NORMAL_INDEX;
    this.sourceIndex = UNSET_INDEX;
    this.tags = [];
    this.rawText = '';
    this.imageUri = '';
    this.recordSeconds = 0;
    this.place = '';
    this.who = '';
    this.category = '';
    this.dueText = '';
    this.repeatText = '';
    this.linkUrl = '';
    this.certainty = 0;
    this.degraded = false;
    this.timeReviewed = false;
    this.parsedMissing = [];
    this.steps = [];
    this.repeatRule = undefined;
  }

  /** 序列化草稿（落盘用）：只存表单字段，不含任何后端数据/身份信息 */
  toJson(): string {
    const steps: DraftStepSnapshot[] = [];
    for (let i = 0; i < this.steps.length; i++) {
      steps.push({ content: this.steps[i].content, done: this.steps[i].done });
    }
    let repeat: DraftRepeatSnapshot | undefined = undefined;
    const rule: RepeatRule | undefined = this.repeatRule;
    if (rule !== undefined) {
      repeat = {
        frequency: rule.frequency,
        interval: rule.interval,
        daysOfWeek: rule.daysOfWeek,
        daysOfMonth: rule.daysOfMonth,
        monthsOfYear: rule.monthsOfYear,
        weeksOfMonth: rule.weeksOfMonth,
        count: rule.count,
        expire: rule.expire,
        dates: rule.dates
      };
    }
    const snapshot: DraftSnapshot = {
      name: this.name,
      sourceTab: this.sourceTab,
      dueAt: this.dueAt,
      remindAt: this.remindAt,
      repeatIndex: this.repeatIndex,
      repeatDaysOfWeek: this.repeatDaysOfWeek,
      repeatInterval: this.repeatInterval,
      priorityIndex: this.priorityIndex,
      sourceIndex: this.sourceIndex,
      tags: this.tags,
      rawText: this.rawText,
      imageUri: this.imageUri,
      recordSeconds: this.recordSeconds,
      place: this.place,
      who: this.who,
      category: this.category,
      dueText: this.dueText,
      repeatText: this.repeatText,
      linkUrl: this.linkUrl,
      certainty: this.certainty,
      missingFields: this.parsedMissing,
      degraded: this.degraded,
      timeReviewed: this.timeReviewed,
      steps: steps,
      repeat: repeat
    };
    return JSON.stringify(snapshot);
  }

  /**
   * 从落盘的 JSON 恢复草稿。
   * 解析失败（旧版本/文件损坏）返回 false，调用方按空草稿处理，不阻塞添加。
   */
  loadJson(raw: string): boolean {
    if ((raw || '').length === 0) {
      return false;
    }
    try {
      const s: DraftSnapshot = JSON.parse(raw) as DraftSnapshot;
      this.name = s.name !== undefined ? s.name : '';
      this.sourceTab = s.sourceTab !== undefined ? s.sourceTab : 0;
      this.dueAt = s.dueAt !== undefined ? s.dueAt : UNSET_NUMBER;
      this.remindAt = s.remindAt !== undefined ? s.remindAt : UNSET_NUMBER;
      this.repeatIndex = s.repeatIndex !== undefined ? s.repeatIndex : REPEAT_NONE_INDEX;
      this.repeatDaysOfWeek = s.repeatDaysOfWeek !== undefined ? s.repeatDaysOfWeek : [];
      this.repeatInterval = s.repeatInterval !== undefined ? s.repeatInterval : 1;
      this.priorityIndex = s.priorityIndex !== undefined ? s.priorityIndex : PRIORITY_NORMAL_INDEX;
      this.sourceIndex = s.sourceIndex !== undefined ? s.sourceIndex : UNSET_INDEX;
      this.tags = s.tags !== undefined ? s.tags : [];
      this.rawText = s.rawText !== undefined ? s.rawText : '';
      this.imageUri = s.imageUri !== undefined ? s.imageUri : '';
      this.recordSeconds = s.recordSeconds !== undefined ? s.recordSeconds : 0;
      this.place = s.place !== undefined ? s.place : '';
      this.who = s.who !== undefined ? s.who : '';
      this.category = s.category !== undefined ? s.category : '';
      this.dueText = s.dueText !== undefined ? s.dueText : '';
      this.repeatText = s.repeatText !== undefined ? s.repeatText : '';
      this.linkUrl = s.linkUrl !== undefined ? s.linkUrl : '';
      // 旧草稿（这些字段之前没存）→ 按"不是 AI 预填"处理，低可信提示不出现，与改造前行为一致
      this.certainty = s.certainty !== undefined ? s.certainty : 0;
      this.parsedMissing = s.missingFields !== undefined ? s.missingFields : [];
      this.degraded = s.degraded === true;
      this.timeReviewed = s.timeReviewed === true;

      const steps: TaskStep[] = [];
      if (s.steps !== undefined) {
        for (let i = 0; i < s.steps.length; i++) {
          const step: TaskStep = new TaskStep();
          step.content = s.steps[i].content;
          step.done = s.steps[i].done === 1 ? 1 : 0;
          steps.push(step);
        }
      }
      this.steps = steps;

      const r: DraftRepeatSnapshot | undefined = s.repeat;
      if (r !== undefined) {
        const rule: RepeatRule = new RepeatRule();
        rule.frequency = r.frequency as RepeatFrequency;
        rule.interval = r.interval;
        rule.daysOfWeek = r.daysOfWeek;
        rule.daysOfMonth = r.daysOfMonth;
        rule.monthsOfYear = r.monthsOfYear;
        rule.weeksOfMonth = r.weeksOfMonth;
        rule.count = r.count;
        rule.expire = r.expire;
        rule.dates = r.dates;
        this.repeatRule = rule;
      } else {
        this.repeatRule = undefined;
      }
      return true;
    } catch (error) {
      return false;
    }
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

  /** 编辑器回填用：把当前规则交出去（没有就是 undefined） */
  firstRepeatRule(): RepeatRule | undefined {
    const edited: RepeatRule | undefined = this.repeatRule;
    if (edited !== undefined) {
      return edited;
    }
    const rules: RepeatRule[] = this.repeatRules();
    return rules.length === 0 ? undefined : rules[0];
  }

  /**
   * 编辑器确定：写入完整规则。`undefined` ＝ 不重复。
   * 同时把 `repeatIndex` 对齐到频率档位，保证芯片行与旧路径读到的档位不错位。
   */
  applyRepeatRule(rule: RepeatRule | undefined): void {
    this.repeatRule = rule;
    if (rule === undefined) {
      this.repeatIndex = REPEAT_NONE_INDEX;
      this.repeatDaysOfWeek = [];
      this.repeatInterval = 1;
      return;
    }
    if (rule.frequency === RepeatFrequency.DAILY) {
      this.repeatIndex = 1;
    } else if (rule.frequency === RepeatFrequency.WEEKLY) {
      this.repeatIndex = 2;
    } else if (rule.frequency === RepeatFrequency.MONTHLY) {
      this.repeatIndex = 3;
    } else {
      this.repeatIndex = 4;
    }
  }

  /**
   * 档位 → 单条 `RepeatRule`（与详情页 `applyRepeat` 同一口径）。
   *
   * 「每周」优先用**用户选的星期** `repeatDaysOfWeek`（支持「每周一、二、四」这种多天规则）；
   * 没选具体星期时才回退到「截止日落在的那一天」。
   * 「每月 / 每年」仍用截止日当锚点（本版不给选几号/几月，字段表 §1.1 的核心诉求是星期）。
   * 「不重复」返回空数组（契约里 `repeat` 为空＝不重复）。
   */
  repeatRules(): RepeatRule[] {
    // ① 编辑器给过完整规则就用它（支持每周多天 / 每月月初月中月末 / 间隔）
    const edited: RepeatRule | undefined = this.repeatRule;
    if (edited !== undefined) {
      return [edited];
    }
    // ② 老口径：按 `repeatIndex` 档位推（编辑器出现之前的面板仍走这条）
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
      // 用户选了具体星期就用它（可多天）；没选就跟随截止日
      rule.daysOfWeek = this.repeatDaysOfWeek.length > 0
        ? this.repeatDaysOfWeek.slice()
        : [toDaysOfWeek(anchor)];
      // interval 只在 >1 时写：官方原文「不填或取 0/1 都表示每 1 个周期」，写 1 是冗余
      if (this.repeatInterval > 1) {
        rule.interval = this.repeatInterval;
      }
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
