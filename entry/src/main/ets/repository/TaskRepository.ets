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
const K_SCHEMA: string = 'tasks_schema';
/**
 * 本机任务存储版本。
 * 字段结构变化（或发现旧测试数据是空壳）时 +1 —— 升级后第一次启动会**清空旧数据**，
 * 避免旧 schema 的半截任务被 revive 成空卡片。
 */
const SCHEMA_VERSION: number = 2;

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

    // ① 版本闸：旧 schema 的数据直接清掉（这次就是为了解决「重装后残留空壳日程」）
    let version: number = 0;
    try {
      const v: preferences.ValueType = store.getSync(K_SCHEMA, 0);
      version = typeof v === 'number' ? v : 0;
    } catch (error) {
      version = 0;
    }
    if (version !== SCHEMA_VERSION) {
      try {
        store.putSync(K_TASKS, '[]');
        store.putSync(K_SCHEMA, SCHEMA_VERSION);
        store.flushSync();
      } catch (error) {
        // 清不掉也不阻塞启动
      }
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
      const list: Task[] = JSON.parse(raw) as Task[];
      const out: Task[] = [];
      for (let i = 0; i < list.length; i++) {
        const task: Task = TaskRepository.revive(list[i]);
        // ② 扔掉空壳：没有名称、没有备注、没有原文、也没有 ddl 的，一律不加载
        if (TaskRepository.isUsable(task)) {
          out.push(task);
        }
      }
      return out;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'tasks_json 解析失败，按空列表处理');
      return [];
    }
  }

  /** 空壳判定：至少要有「名称 / 备注 / 原文 / ddl」之一，否则就是没信息的残留 */
  private static isUsable(task: Task): boolean {
    const name: string = task.name !== undefined ? task.name.trim() : '';
    const note: string = task.note !== undefined ? task.note.trim() : '';
    const raw: string = task.rawText !== undefined ? task.rawText.trim() : '';
    const hasDue: boolean = task.dueAt !== undefined && task.dueAt > 0;
    return name.length > 0 || note.length > 0 || raw.length > 0 || hasDue;
  }

  static save(context: common.Context, tasks: Task[]): void {
    const store: preferences.Preferences | undefined = TaskRepository.ensure(context);
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(K_TASKS, JSON.stringify(tasks));
      store.putSync(K_SCHEMA, SCHEMA_VERSION);
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
   */
  private static revive(raw: Task): Task {
    const task: Task = new Task();
    task.id = raw.id;
    task.clientTaskId = raw.clientTaskId;
    task.status = raw.status;
    task.name = raw.name;
    task.note = raw.note;
    task.rawText = raw.rawText;
    task.rawJson = raw.rawJson;
    task.dueAt = raw.dueAt;
    task.dueText = raw.dueText;
    task.place = raw.place;
    task.who = raw.who;
    task.createdAt = raw.createdAt;
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

    if (raw.tags !== undefined) {
      task.tags = raw.tags.slice();
    }
    if (raw.urls !== undefined) {
      task.urls = raw.urls.slice();
    }
    task.linkUrl = raw.linkUrl;
    if (raw.missingFields !== undefined) {
      task.missingFields = raw.missingFields.slice();
    }
    if (raw.steps !== undefined) {
      const steps: TaskStep[] = [];
      for (let i = 0; i < raw.steps.length; i++) {
        const step: TaskStep = new TaskStep();
        step.content = raw.steps[i].content;
        step.done = raw.steps[i].done === 1 ? 1 : 0;
        steps.push(step);
      }
      task.steps = steps;
    }
    if (raw.repeat !== undefined) {
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
      task.source = TaskSource.BOT;
    }
    return task;
  }
}
