/**
 * 任务列表页的 ViewModel
 *
 * 只做「把任务按天分好组」和「卡片上的文案怎么拼」这两件展示逻辑，不碰存储、不碰系统能力。
 *
 * 分组规则（需求方 2026-10-14 定）：**`dueAt` 优先，回退 `remindAt`；两个都没填的进「未安排日期」组**。
 * 副标题的两个数（同上确认）：**未完成 x 项 / 共 y 项**。
 * 展开状态（同上确认）：**默认只展开「今天」**。
 * 描述行（同上确认）：按 **提醒时间 > 重要程度 > 耗时 > 来源 > 标签 > 备注** 取**前两项**，用 ` · ` 拼。
 */
import { Task, TaskPriority, TaskStatus } from '../model';

const DAY_MS: number = 24 * 60 * 60 * 1000;
const HOUR_MS: number = 60 * 60 * 1000;
const MINUTE_MS: number = 60 * 1000;

/** 描述行最多拼两项（需求方：`xxx · xxx`） */
const DESCRIPTION_MAX_PARTS: number = 2;

/** 重要程度的中文（直接显示原词，需求方 2026-10-14 定） */
const PRIORITY_LABELS: string[] = ['普通', '重要', '紧急'];

/*
 * TODO(界面): 下面这些文案按规矩该进 `resources/base/element/string.json`。
 * 没进的原因：描述行是「两个片段拼成一句」，而资源之间不能互相嵌套
 * （`$r()` 的实参只能是 string / number，不能是另一个 Resource），
 * 所以先在 ViewModel 里用常量拼字符串。要改成资源，得把描述行换成 Span 拼接，
 * 或用 resourceManager 把资源解成字符串。
 */
const TIME_SUFFIX: string = ' 截止';
const TIME_PREFIX: string = '在 ';
const REMIND_PREFIX: string = '响铃还有 ';
const REMIND_HOUR_UNIT: string = ' 小时 ';
const REMIND_MINUTE_UNIT: string = ' 分钟';
const ESTIMATED_PREFIX: string = '预计耗时 ';
const ESTIMATED_UNIT: string = ' 小时';
const SOURCE_PREFIX: string = '来源于 ';
const TAG_SEPARATOR: string = '、';
const DESCRIPTION_SEPARATOR: string = ' · ';
const TIME_SEPARATOR: string = ':';

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
  /** 按天分组。已删除的任务不进时间线（§9.3） */
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
        if (a.hasDate !== b.hasDate) {
          return a.hasDate ? -1 : 1;
        }
        return a.sortValue - b.sortValue;
      });
  }

  /** 卡片副标题：「在 HH:mm 截止」。没有到期时间就返回空串（副标题不显示） */
  static dueLabel(task: Task): string {
    const due: number | undefined = task.dueAt;
    if (due === undefined) {
      return '';
    }
    return `${TIME_PREFIX}${TaskListViewModel.hhmm(due)}${TIME_SUFFIX}`;
  }

  /** 卡片描述行：按 提醒时间 > 重要程度 > 耗时 > 来源 > 标签 > 备注 取前两项，用 ` · ` 拼 */
  static descriptionLabel(task: Task, now: Date): string {
    const parts: string[] = [];

    const remind: number | undefined = task.remindAt;
    if (remind !== undefined && remind > now.getTime()) {
      parts.push(TaskListViewModel.remindCountdown(remind, now));
    }
    if (parts.length < DESCRIPTION_MAX_PARTS) {
      parts.push(PRIORITY_LABELS[task.priority]);
    }
    const estimated: number | undefined = task.estimatedHours;
    if (parts.length < DESCRIPTION_MAX_PARTS && estimated !== undefined) {
      parts.push(`${ESTIMATED_PREFIX}${estimated}${ESTIMATED_UNIT}`);
    }
    const source: string | undefined = task.source;
    if (parts.length < DESCRIPTION_MAX_PARTS && source !== undefined) {
      parts.push(`${SOURCE_PREFIX}${source}`);
    }
    const tags: string[] | undefined = task.tags;
    if (parts.length < DESCRIPTION_MAX_PARTS && tags !== undefined && tags.length > 0) {
      parts.push(tags.join(TAG_SEPARATOR));
    }
    const detail: string | undefined = task.detail;
    if (parts.length < DESCRIPTION_MAX_PARTS && detail !== undefined) {
      parts.push(detail);
    }

    return parts.join(DESCRIPTION_SEPARATOR);
  }

  /** 提醒倒计时：响铃还有 HH 小时 mm 分钟 */
  static remindCountdown(remindAt: number, now: Date): string {
    const diff: number = remindAt - now.getTime();
    const hours: number = Math.floor(diff / HOUR_MS);
    const minutes: number = Math.floor((diff % HOUR_MS) / MINUTE_MS);
    return `${REMIND_PREFIX}${hours}${REMIND_HOUR_UNIT}${minutes}${REMIND_MINUTE_UNIT}`;
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
