/**
 * 任务列表页的 ViewModel
 *
 * 只做「把任务按天分好组」和「卡片上的文案怎么拼」这两件展示逻辑，不碰存储、不碰系统能力。
 *
 * 分组规则（需求方 2026-10-14 定）：**`dueAt` 优先，回退 `remindAt`；两个都没填的进「未安排日期」组**。
 * 组的排列（需求方 2026-10-17 追加）：**「未安排日期」排最前**，其后按日期升序（见 `groupByDay` 的排序）。
 * 副标题的两个数（同上确认）：**未完成 x 项 / 共 y 项**。
 * 展开状态（同上确认）：**默认只展开「今天」**。
 * 描述行（同上确认）：按 **提醒时间 > 耗时 > 来源 > 标签 > 备注** 取**第一项**（只一行）。
 *   ⚠️ 这条链的顺序需求方 2026-10-15 说「**优先级待商榷**」，本轮不动，等他定了再调。
 *   其中「提醒时间」那一段（`响铃还有 HH 小时 mm 分钟`）**只在「响铃提醒」开关是开的时候才出现**
 *   （开关关掉＝`reminderId` 为空，倒计时就不显示；需求方 2026-10-14）。
 *   **「重要程度」已从这条链里移除**（需求方 2026-10-15：「description 里面的重要程度不显示了」）——
 *   它改用**卡片底色**表达，见 `components/TaskCard.ets` 的 `cardBackground`。
 */
import { RepeatFrequency, RepeatRule, Task, TaskAlarm, TaskPriority, TaskStatus } from '../model';

const DAY_MS: number = 24 * 60 * 60 * 1000;
const HOUR_MS: number = 60 * 60 * 1000;

/**
 * 截止文案（字段表 §2.2）。**卡片第二行**用这套相对说法；
 * 详情页的「到期」行走它自己的绝对格式（`TaskAttributeCard.dueLabel`），两处不混用。
 *
 * 文案按项目惯例该进 `string.json`，但这里是「数字 + 单位 + 后缀」动态拼句，
 * 而 `$r()` 的实参只能是 string / number、资源之间不能嵌套，故暂用常量拼（改资源要先换成 Span 拼接）。
 */
const DUE_TODAY: string = '今天截止';
const DUE_TOMORROW: string = '明天截止';
const DUE_DAY_AFTER: string = '后天截止';
const DUE_IN_DAYS_SUFFIX: string = ' 天后截止';
const DUE_IN_HOURS_SUFFIX: string = 'h 后截止';
const DUE_OVERDUE: string = '已过期';
const DUE_NO_TIME: string = '未定时间';
/** 「后截止」这三个字：卡片上要单独成段，位置固定，不随前面的数字长短左右跳 */
const DUE_AFTER_SUFFIX: string = '后截止';

/**
 * 截止文案的两段（见 `TaskListViewModel.dueParts`）。
 * `value` 放定宽居中的槽，`suffix` 是固定文本（`后截止` / `截止` / 空）。
 */
export class DueParts {
  readonly value: string;
  readonly suffix: string;

  constructor(value: string, suffix: string) {
    this.value = value;
    this.suffix = suffix;
  }
}
const TIME_SEPARATOR: string = ':';

/** 重要程度的中文（直接显示原词，需求方 2026-10-14 定） */
const PRIORITY_LABELS: string[] = ['普通', '重要', '紧急'];

/* ── 重复标识文案（`repeatLabel` 用）── */
/** 1~7 ＝ 周一~周日。取值顺序与官方 `RecurrenceRule.daysOfWeek` 一致（第 1 天是周一） */
const WEEKDAY_SHORT_CN: string[] = ['一', '二', '三', '四', '五', '六', '日'];
/** 同一条规则内的多天/多月用顿号 */
const WEEKDAY_JOIN: string = '、';
/** 多条规则之间用分号：它们表示**并集**（命中任一即今天要做），逗号会看成同一规则内的并列 */
const REPEAT_RULE_SEPARATOR: string = '；';
/** 「每 N 周/月/年」的前缀 */
const EVERY_PREFIX: string = '每';
/** 每天（interval ≤ 1 时不说「每 1 天」） */
const EVERY_DAY: string = '每天';

/** 一天的分组。`@ObservedV2` 是为了让「展开/收起」与任务变更能被界面观察到 */
@ObservedV2
export class TaskDayGroup {
  /** 排序键：当天 0 点的时间戳；「未安排日期」组为 0 */
  sortValue: number = 0;
  /** 有没有日期。false ＝ 「未安排日期」组 */
  hasDate: boolean = false;
  /** 与今天的整日差：0 今天 / 1 明天 / 2 及以后更远 / 负数 已过去 */
  dayOffset: number = 0;
  /** 0=周日 … 6=周六。仅 hasDate 时有意义 */
  weekdayIndex: number = 0;
  /** 1-12。仅 hasDate 时有意义 */
  month: number = 1;
  /** 1-31。仅 hasDate 时有意义 */
  day: number = 1;
  @Trace expanded: boolean = false;
  @Trace tasks: Task[] = [];

  /** 组内总项数。做成 getter：任务增删或状态一变，组头副标题自动跟着变 */
  get totalCount(): number {
    return this.tasks.length;
  }

  /** 组内未完成项数（`COMPLETED` 之外都算未完成） */
  get pendingCount(): number {
    let pending: number = 0;
    this.tasks.forEach((task: Task) => {
      if (task.status !== TaskStatus.COMPLETED) {
        pending++;
      }
    });
    return pending;
  }
}

/** 任务的「那一天」用的时间戳；两个都没填返回 -1 */
function taskTime(task: Task): number {
  const due: number | undefined = task.dueAt;
  if (due !== undefined) {
    return due;
  }
  const remind: number | undefined = task.remindAt;
  if (remind !== undefined) {
    return remind;
  }
  return -1;
}

function startOfDay(date: Date): number {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

function findOrCreate(groups: TaskDayGroup[], dayStart: number, todayStart: number): TaskDayGroup {
  for (let i = 0; i < groups.length; i++) {
    const exist: TaskDayGroup = groups[i];
    if (exist.hasDate && exist.sortValue === dayStart) {
      return exist;
    }
  }
  const created: TaskDayGroup = new TaskDayGroup();
  created.hasDate = true;
  created.sortValue = dayStart;
  created.dayOffset = Math.round((dayStart - todayStart) / DAY_MS);
  const date: Date = new Date(dayStart);
  created.weekdayIndex = date.getDay();
  created.month = date.getMonth() + 1;
  created.day = date.getDate();
  created.expanded = created.dayOffset === 0;
  groups.push(created);
  return created;
}

export class TaskListViewModel {
  /**
   * 按天分组。已删除的任务不进时间线（§9.3）。
   *
   * 组的顺序：**「未安排日期」在最前**，其后按日期升序（需求方 2026-10-17）。
   * 两处列表（任务列表页 / 搜索页）共用这一份分组结果，所以排序只在这里定一次。
   */
  static groupByDay(tasks: Task[], today: Date): TaskDayGroup[] {
    const todayStart: number = startOfDay(today);
    const undated: TaskDayGroup = new TaskDayGroup();
    const groups: TaskDayGroup[] = [undated];

    tasks.forEach((task: Task) => {
      if (task.status === TaskStatus.DELETED) {
        return;
      }
      const ts: number = taskTime(task);
      if (ts < 0) {
        undated.tasks.push(task);
        return;
      }
      findOrCreate(groups, startOfDay(new Date(ts)), todayStart).tasks.push(task);
    });

    groups.forEach((group: TaskDayGroup) => {
      group.tasks.sort((a: Task, b: Task) => taskTime(a) - taskTime(b));
    });

    return groups
      .filter((group: TaskDayGroup) => group.totalCount > 0)
      .sort((a: TaskDayGroup, b: TaskDayGroup) => {
        // 「未安排日期」组**排最前**（需求方 2026-10-17：「任务列表页面把未安排日期放到最上面」）。
        // 它没有日期可比，所以不能参与时间线排序 —— 要么最前、要么最后，现在定的是最前：
        // 没定日期的任务最需要用户先处理，放顶上免得沉在长列表末尾。
        if (a.hasDate !== b.hasDate) {
          return a.hasDate ? 1 : -1;
        }
        return a.sortValue - b.sortValue;
      });
  }

  /**
   * 卡片第二行的**截止文案**（字段表 §2.2 定稿的六种说法，2026-10-17 按规范改）：
   *
   *   ≥24h，整日差 0 天 → `今天截止`；1 天 → `明天截止`；2 天 → `后天截止`；n 天 → `n 天后截止`
   *   < 24h            → `__h 后截止`
   *   已过 / 状态为已过期 → `已过期`
   *   已完成            → **不显示剩余**（返回空串，第二行只剩标签与性质）
   *
   * 旧实现是「在 HH:mm 截止」，在第二行要同时装「标签胶囊＋重要性标识＋截止＋重复标识」时**放不下**，
   * 且与字段表 §2.2 不符，故改。
   *
   * `now` 由调用方传入（不在这里取 `Date.now()`），这样单测与走查能对准同一份 mock。
   */
  static dueLabel(task: Task, now: Date = new Date()): string {
    if (task.status === TaskStatus.COMPLETED) {
      return '';
    }
    const due: number | undefined = task.dueAt;
    if (due === undefined) {
      // 没有确切时间就退回原文表述（如「本周五」）；连原文都没有才说「未定时间」
      const text: string | undefined = task.dueText;
      return text === undefined || text === '' ? DUE_NO_TIME : text;
    }
    if (task.status === TaskStatus.EXPIRED || due <= now.getTime()) {
      return DUE_OVERDUE;
    }
    const remain: number = due - now.getTime();
    if (remain < DAY_MS) {
      return `${Math.floor(remain / HOUR_MS)}${DUE_IN_HOURS_SUFFIX}`;
    }
    const offset: number = TaskListViewModel.wholeDayOffset(due, now.getTime());
    if (offset === 0) {
      return DUE_TODAY;
    }
    if (offset === 1) {
      return DUE_TOMORROW;
    }
    if (offset === 2) {
      return DUE_DAY_AFTER;
    }
    return `${offset}${DUE_IN_DAYS_SUFFIX}`;
  }

  /**
   * 截止文案**拆成两段**，供卡片第二行做「固定槽位对齐」（2026-10-19 作者效果图）。
   *
   * 为什么要拆：`3 天后截止` / `14h 后截止` / `已过期` 的**可变部分**长度不同，
   * 整串渲染时「后截止」三个字的位置会跟着左右跳。拆开后：
   *   · `value` 放进**定宽居中**的槽（`14h` / `3 天` / `今天` / `已过期`）；
   *   · `suffix`（`后截止` / `截止`）单独一个固定文本，永远落在同一横向位置。
   *
   * 「已过期」按作者裁定：**value 直接是「已过期」，suffix 为空**。
   */
  static dueParts(task: Task, now: Date = new Date()): DueParts {
    const label: string = TaskListViewModel.dueLabel(task, now);
    if (label === '') {
      return new DueParts('', '');
    }
    if (label === DUE_OVERDUE || label === DUE_NO_TIME) {
      return new DueParts(label, '');
    }
    if (label === DUE_TODAY) {
      return new DueParts('今天', '截止');
    }
    if (label === DUE_TOMORROW) {
      return new DueParts('明天', '截止');
    }
    if (label === DUE_DAY_AFTER) {
      return new DueParts('后天', '截止');
    }
    // `N 天后截止` / `Nh 后截止`：把「后截止」剥出来，前面就是可变段
    const suffix: string = DUE_AFTER_SUFFIX;
    if (label.endsWith(suffix)) {
      return new DueParts(label.substring(0, label.length - suffix.length).trim(), suffix);
    }
    // 后端给的 `dueText` 原话（如「本周五截止」）：整体当可变段，不硬拆
    return new DueParts(label, '');
  }

  /** 两个时刻相差几个整日（按**自然日**算，不是按 24h 除）；due 早于 now 时为负 */
  static wholeDayOffset(due: number, now: number): number {
    const dueDate: Date = new Date(due);
    const nowDate: Date = new Date(now);
    const dueStart: number = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate()).getTime();
    const nowStart: number = new Date(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate()).getTime();
    return Math.round((dueStart - nowStart) / DAY_MS);
  }

  /**
   * 重复标识文案（字段表 §2「第二行 → 重复性标识」）。
   *
   * 由 `repeat` 规则**生成**，不读 `repeatText`（规则是唯一真值源，手写原话会与规则漂移）；
   * `repeatText` 只在规则表达不了时兜底（如「每学期第 3 周交」）。
   *
   * 例：`{ WEEKLY, daysOfWeek: [1,2,4] }` → `每周一、二、四`
   *     `{ WEEKLY, interval: 2, daysOfWeek: [2] }` → `每 2 周的周二`
   *     `{ DAILY, interval: 3 }` → `每 3 天`
   *     `{ MONTHLY, daysOfMonth: [15] }` → `每月 15 号`
   * 多条规则用「；」连接（并集语义）。
   */
  static repeatLabel(task: Task): string {
    const rules: RepeatRule[] | undefined = task.repeat;
    const custom: string | undefined = task.repeatText;
    if (rules === undefined || rules.length === 0) {
      return custom === undefined ? '' : custom;
    }
    const labels: string[] = [];
    rules.forEach((rule: RepeatRule) => {
      const one: string = TaskListViewModel.oneRepeatLabel(rule);
      if (one !== '') {
        labels.push(one);
      }
    });
    const joined: string = labels.join(REPEAT_RULE_SEPARATOR);
    if (joined === '') {
      return custom === undefined ? '' : custom;
    }
    return custom === undefined || custom.length === 0 ? joined : `${joined}（${custom}）`;
  }

  /** 单条规则 → 中文说法。识别不了时返回空串 */
  static oneRepeatLabel(rule: RepeatRule): string {
    const interval: number = rule.interval === undefined ? 1 : rule.interval;
    // 「每」必须有：每 1 周要说「每周一」，不能只说「周一」（那是"这周一"的意思）。
    // interval > 1 时把数字夹在「每」和单位之间，**空格在数字两侧**：`每 2 周周二`，
    // 而不是 `每2 周二`（踩过：空格放错位置，卡片上读起来像两个词）。
    const every: string = interval > 1 ? `${EVERY_PREFIX} ${interval} ` : EVERY_PREFIX;
    const weekdays: number[] | undefined = rule.daysOfWeek;
    const monthDays: number[] | undefined = rule.daysOfMonth;
    const months: number[] | undefined = rule.monthsOfYear;
    const dates: number[] | undefined = rule.dates;

    if (rule.frequency === RepeatFrequency.WEEKLY) {
      const base: string = `${every}周`;
      if (weekdays === undefined || weekdays.length === 0) {
        return base;
      }
      const names: string[] = [];
      weekdays.forEach((day: number) => {
        const name: string = TaskListViewModel.weekdayLabel(day);
        if (name !== '') {
          names.push(name);
        }
      });
      if (names.length === 0) {
        return base;
      }
      // 拼法分两种，别混：
      //   interval = 1 → 「每周一、二、四」（base 已含「周」，直接接日子）
      //   interval > 1 → 「每 2 周**的**周二」（不加「的」会读成「每 2 周周二」，语义黏在一起）
      const tail: string = names.join(WEEKDAY_JOIN);
      return interval > 1 ? `${base}的周${tail}` : `${base}${tail}`;
    }
    if (rule.frequency === RepeatFrequency.DAILY) {
      return interval > 1 ? `${every}天` : EVERY_DAY;
    }
    if (rule.frequency === RepeatFrequency.MONTHLY) {
      const base: string = `${every}月`;
      if (monthDays !== undefined && monthDays.length > 0) {
        const days: string[] = [];
        monthDays.forEach((day: number) => {
          days.push(`${day}`);
        });
        return `${base}${days.join(WEEKDAY_JOIN)} 号`;
      }
      // 「月末」在规则里表达不了，存的是 `dates`（未来若干个月的当月最后一天）。
      // 这里必须**单独认出来**：否则月末规则会和"只说了每月、没说哪天"一样显示成「每月」，
      // 用户看不出自己选的是月末。
      if (dates !== undefined && dates.length > 0) {
        return `${base}月末`;
      }
      return base;
    }
    // YEARLY
    const base: string = `${every}年`;
    if (months !== undefined && months.length > 0) {
      const list: string[] = [];
      months.forEach((month: number) => {
        list.push(`${month} 月`);
      });
      return `${base}${list.join(WEEKDAY_JOIN)}`;
    }
    return base;
  }

  /** 1~7 → 「一」~「日」。越界返回空串（官方原文：range [1,7]，对应周一到周日） */
  static weekdayLabel(day: number): string {
    if (day < 1 || day > 7) {
      return '';
    }
    return WEEKDAY_SHORT_CN[day - 1];
  }

  /** 毫秒时间戳 → 补零的 HH:mm */
  static hhmm(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return `${TaskListViewModel.pad2(date.getHours())}${TIME_SEPARATOR}${TaskListViewModel.pad2(date.getMinutes())}`;
  }

  static pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  /** 重要程度的中文原词 */
  static priorityLabel(priority: TaskPriority): string {
    return PRIORITY_LABELS[priority];
  }
}
