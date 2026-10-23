/**
 * 任务仓储：本机任务的唯一落盘出口（preferences 单键 JSON）。
 *
 * 为什么是 preferences 而不是 relationalStore：本工程现有全部持久化（主题、展开状态）
 * 都走 `SettingsRepository` 的 preferences；任务量在几百条量级，单键 JSON 足够，
 * 且不用引入建表迁移。字段仍是 `Task` 的 28 字段原样，不改口径。
 *
 * 纪律：页面不直接读写本层；`TaskListStore` 改完内存态后调 `save` / `load`。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  RepeatFrequency,
  RepeatRule,
  Task,
  TaskAlarm,
  TaskLevel,
  TaskPriority,
  TaskSource,
  TaskStatus,
  TaskStep
} from '../model';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskRepository';
const STORE_NAME: string = 'distiller_tasks';
const K_TASKS: string = 'tasks_json';

/**
 * 旧版本（2026-10-17 `refactor: 接口字段对齐` 之前）落盘的字段名。
 *
 * 为什么要保留这张"旧键表"：`preferences` 里的 `tasks_json` **不会因为 App 升级自动清空**，
 * 而那次重构把 `title` → `name`、`detail` → `note`。旧 JSON 在新版里读出来
 * `raw.name` 是 `undefined`，`revive` 又只是原样搬运，于是 **`undefined` 流进了 `Task` 模型**
 * （`Task.name` 声明成 `string`，编译器管不到 JSON 里缺键）。
 * 后果链（2026-10-23 实测）：搜索页 `matches()` 对 `task.name` 调 `.toLowerCase()`
 * → `TypeError: Cannot read property toLowerCase of undefined`
 * → 异常发生在 `@Monitor` 里 → 框架按 RuntimeError 杀进程 → **一输入字符就闪退**。
 *
 * 所以旧键必须**在这里读出来并迁移**，而不是丢给界面去兜底。
 * （旧 `repeat` 是数字枚举 `TaskRepeat`，新版是 `RepeatRule[]`；语义换算容易猜错，
 *  这里只保证不崩、不猜——旧任务的重复规则会读成空，需要用户在详情页重设。）
 */
interface LegacyTaskJson {
  title?: string;
  detail?: string;
}

export class TaskRepository {
  private static store: preferences.Preferences | undefined = undefined;

  private static ensure(context: common.Context): preferences.Preferences | undefined {
    if (TaskRepository.store !== undefined) {
      return TaskRepository.store;
    }
    try {
      TaskRepository.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      return TaskRepository.store;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getPreferencesSync failed: %{public}s', err.message);
      return undefined;
    }
  }

  static load(context: common.Context): Task[] {
    const store: preferences.Preferences | undefined = TaskRepository.ensure(context);
    if (store === undefined) {
      return [];
    }
    let raw: string = '[]';
    try {
      const value: preferences.ValueType = store.getSync(K_TASKS, '[]');
      raw = typeof value === 'string' ? value : '[]';
    } catch (error) {
      return [];
    }
    try {
      const list: Object[] = JSON.parse(raw) as Object[];
      const out: Task[] = [];
      for (let i = 0; i < list.length; i++) {
        // 同一个原始 JSON 对象，一份按新契约读、一份按旧键名读（见 `LegacyTaskJson`）
        out.push(TaskRepository.revive(list[i] as Task, list[i] as LegacyTaskJson));
      }
      return out;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'tasks_json 解析失败，按空列表处理');
      return [];
    }
  }

  static save(context: common.Context, tasks: Task[]): void {
    const store: preferences.Preferences | undefined = TaskRepository.ensure(context);
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(K_TASKS, JSON.stringify(tasks));
      store.flushSync();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'save failed: %{public}s', err.message);
    }
  }

  static clear(context: common.Context): void {
    TaskRepository.save(context, []);
  }

  /**
   * JSON.parse 出来的是**普通对象**，直接塞给 `@ObservedV2` 的列表不会刷新界面
   * （深层字段不在观测范围）。所以必须重建为 `Task` / `TaskStep` / `RepeatRule` 实例。
   *
   * 🔴 这里是**数据进模型的唯一闸口**，所以"缺字段"必须在这里就被消灭：
   * 旧版 JSON 缺 `name` / `note` 键（见 `LegacyTaskJson`），若原样搬运，
   * `Task.name` 就会是 `undefined`，界面上表现为空标题，搜索页则直接 `TypeError` 闪退。
   *
   * @param raw    按当前契约读（缺键时值为 `undefined`）
   * @param legacy 按旧版键名读（`title` / `detail`）
   */
  private static revive(raw: Task, legacy: LegacyTaskJson): Task {
    const task: Task = new Task();
    task.id = TaskRepository.numberOr(raw.id, 0);
    task.clientTaskId = raw.clientTaskId;
    task.status = raw.status;
    // 名字：新键 `name` → 旧键 `title` → 空串（缺失不编造，但与"undefined"划清界限）
    task.name = TaskRepository.firstNonEmpty(raw.name, legacy.title);
    // 备注：新键 `note` → 旧键 `detail`；两边都没有就保持"没有"（可选字段，不塞空串）
    const note: string | undefined = TaskRepository.firstNonEmpty(raw.note, legacy.detail);
    if (note !== undefined) {
      task.note = note;
    }
    task.rawText = raw.rawText;
    task.rawJson = raw.rawJson;
    task.dueAt = raw.dueAt;
    task.dueText = raw.dueText;
    task.place = raw.place;
    task.who = raw.who;
    task.createdAt = TaskRepository.numberOr(raw.createdAt, 0);
    task.finishedAt = raw.finishedAt;
    task.priority = raw.priority;
    task.level = raw.level;
    task.alarm = raw.alarm;
    task.remindAt = raw.remindAt;
    task.reminderId = raw.reminderId;
    task.repeatText = raw.repeatText;
    task.source = raw.source;
    task.originDetail = raw.originDetail;
    task.category = raw.category;
    task.certainty = raw.certainty;

    if (Array.isArray(raw.tags)) {
      task.tags = raw.tags.slice();
    }
    if (Array.isArray(raw.urls)) {
      task.urls = raw.urls.slice();
    }
    if (Array.isArray(raw.missingFields)) {
      task.missingFields = raw.missingFields.slice();
    }
    if (Array.isArray(raw.steps)) {
      const steps: TaskStep[] = [];
      for (let i = 0; i < raw.steps.length; i++) {
        const step: TaskStep = new TaskStep();
        step.content = TaskRepository.stringOr(raw.steps[i].content, '');
        step.done = raw.steps[i].done === 1 ? 1 : 0;
        steps.push(step);
      }
      task.steps = steps;
    }
    // 旧版的 `repeat` 是数字枚举（`TaskRepeat`），迁移不猜语义 → 只认数组形态，其余读成"没有规则"
    if (Array.isArray(raw.repeat)) {
      const rules: RepeatRule[] = [];
      for (let i = 0; i < raw.repeat.length; i++) {
        const r: RepeatRule = new RepeatRule();
        r.frequency = raw.repeat[i].frequency as RepeatFrequency;
        r.interval = raw.repeat[i].interval;
        r.daysOfWeek = raw.repeat[i].daysOfWeek;
        r.daysOfMonth = raw.repeat[i].daysOfMonth;
        r.monthsOfYear = raw.repeat[i].monthsOfYear;
        r.weeksOfMonth = raw.repeat[i].weeksOfMonth;
        r.count = raw.repeat[i].count;
        r.expire = raw.repeat[i].expire;
        r.dates = raw.repeat[i].dates;
        rules.push(r);
      }
      task.repeat = rules;
    }
    // 枚举兜底：历史数据/后端异常值不要污染界面
    if (task.status === undefined) {
      task.status = TaskStatus.PENDING_CONFIRM;
    }
    if (task.priority === undefined) {
      task.priority = TaskPriority.NORMAL;
    }
    if (task.level === undefined) {
      task.level = TaskLevel.EASY;
    }
    if (task.alarm === undefined) {
      task.alarm = TaskAlarm.OFF;
    }
    if (task.source === undefined) {
      // 旧版 `source` 是自由文本（如「QQ」），枚举里没有这个值也不算错：
      // `TaskMetaCard.channelLabel` 会把枚举外的取值原样显示，所以这里只补"完全没有"的情况
      task.source = TaskSource.BOT;
    }
    return task;
  }

  /** 取第一个"有内容"的字符串：全都没有返回空串。`undefined` 永远不出现在结果里 */
  private static firstNonEmpty(primary: string | undefined, fallback: string | undefined): string {
    if (primary !== undefined && primary.length > 0) {
      return primary;
    }
    if (fallback !== undefined && fallback.length > 0) {
      return fallback;
    }
    return '';
  }

  private static stringOr(value: string | undefined, fallback: string): string {
    return value === undefined ? fallback : value;
  }

  private static numberOr(value: number | undefined, fallback: number): number {
    return value === undefined ? fallback : value;
  }
}
