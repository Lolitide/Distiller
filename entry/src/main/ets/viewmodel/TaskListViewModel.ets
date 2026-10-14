/**
 * 任务列表页的 ViewModel
 *
 * 只做「把任务按天分好组」这件展示逻辑，不碰存储、不碰系统能力。
 * 分组规则（需求方 2026-10-14 定）：**`dueAt` 优先，回退 `remindAt`；两个都没填的进「未安排日期」组**。
 * 副标题的两个数（同上确认）：**未完成 x 项 / 共 y 项**。
 * 展开状态（同上确认）：**默认只展开「今天」**。
 */
import { Task, TaskStatus } from '../model';

const DAY_MS: number = 24 * 60 * 60 * 1000;

/** 一天的分组。`@ObservedV2` 是为了让「展开/收起」与任务增删能被界面观察到 */
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
  /** 组内未完成项数（`COMPLETED` 之外都算未完成） */
  pendingCount: number = 0;
  /** 组内总项数 */
  totalCount: number = 0;
  @Trace expanded: boolean = false;
  @Trace tasks: Task[] = [];
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
      group.totalCount = group.tasks.length;
      let pending: number = 0;
      group.tasks.forEach((task: Task) => {
        if (task.status !== TaskStatus.COMPLETED) {
          pending++;
        }
      });
      group.pendingCount = pending;
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
}
