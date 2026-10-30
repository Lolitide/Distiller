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
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
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
const SCHEMA_VERSION: number = 3;

/** 文件存储的信封：版本号 + 任务数组（便于以后迁移） */
interface TaskFile {
  version: number;
  tasks: Object[];
}

/**
 * 落盘用的**普通对象**。
 *
 * 为什么不能直接 `JSON.stringify(task)`：`Task` 是 `@ObservedV2`，属性会被写成
 * `__ob_name` / `__ob_dueAt` 这类内部键，下次 `JSON.parse` 回来 `raw.name` 是 undefined
 * —— 任务全变空壳、重启后看起来全丢了（2026-10-24 真机实测）。
 */
interface TaskPlain {
  id: number;
  clientTaskId?: string;
  status: number;
  name: string;
  note?: string;
  rawText?: string;
  rawJson?: string;
  dueAt?: number;
  dueText?: string;
  place?: string;
  who?: string;
  createdAt: number;
  finishedAt?: number;
  priority: number;
  level?: number;
  alarm: number;
  remindAt?: number;
  reminderId?: number;
  reminderAt?: number;
  calendarEventId?: number;
  calendarSignature?: string;
  userEdited?: boolean;
  aiLabelHidden?: boolean;
  repeat?: RepeatRule[];
  repeatText?: string;
  source?: TaskSource;
  originDetail?: string;
  category?: string;
  tags?: string[];
  steps?: TaskStep[];
  urls?: string[];
  linkUrl?: string;
  certainty?: number;
  missingFields?: string[];
  pendingSeen?: boolean;
  pendingSource?: string;
  trashKind?: string;
}

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
    // ① 主存储：应用沙箱文件（preferences 单值有 8KB 上限，任务一多就静默写失败 → 重启全丢）
    const fileText: string = TaskRepository.readFile(context);
    if (fileText.length > 0) {
      return TaskRepository.parseTasks(fileText);
    }
    // ② 首次升级：把旧 preferences 里的任务迁到文件，之后不再用 preferences 存任务
    const migrated: string = TaskRepository.migrateFromPrefs(context);
    if (migrated.length > 0) {
      TaskRepository.writeFile(context, migrated);
      return TaskRepository.parseTasks(migrated);
    }
    return [];
  }

  private static filePath(context: common.Context): string {
    return context.filesDir + '/tasks.json';
  }

  private static readFile(context: common.Context): string {
    const path: string = TaskRepository.filePath(context);
    try {
      if (!fileIo.accessSync(path)) {
        return '';
      }
      const stat: fileIo.Stat = fileIo.statSync(path);
      if (stat.size <= 0) {
        return '';
      }
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      try {
        fileIo.readSync(file.fd, buffer);
      } finally {
        fileIo.closeSync(file);
      }
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      return decoder.decodeToString(new Uint8Array(buffer));
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'read tasks file failed: %{public}s', err.message);
      return '';
    }
  }

  private static writeFile(context: common.Context, text: string): void {
    const path: string = TaskRepository.filePath(context);
    try {
      const file: fileIo.File = fileIo.openSync(path,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, text);
      } finally {
        fileIo.closeSync(file);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'write tasks file failed: %{public}s', err.message);
    }
  }

  /** 旧 preferences（schema=2）迁移：读到就包成新文件格式返回；读不到返回空串 */
  private static migrateFromPrefs(context: common.Context): string {
    const store: preferences.Preferences | undefined = TaskRepository.ensure(context);
    if (store === undefined) {
      return '';
    }
    try {
      const version: preferences.ValueType = store.getSync(K_SCHEMA, 0);
      if (version !== 2) {
        return '';
      }
      const value: preferences.ValueType = store.getSync(K_TASKS, '[]');
      const raw: string = typeof value === 'string' ? value : '[]';
      const tasks: Object[] = JSON.parse(raw) as Object[];
      if (tasks.length === 0) {
        return '';
      }
      hilog.info(DOMAIN, TAG, 'migrating %{public}d tasks from preferences', tasks.length);
      return JSON.stringify({ version: SCHEMA_VERSION, tasks: tasks });
    } catch (error) {
      return '';
    }
  }

  private static parseTasks(text: string): Task[] {
    try {
      // 兼容旧文件：@ObservedV2 的属性曾以 `__ob_` 前缀落盘，这里先还原成普通键名
      const clean: string = text.split('"__ob_').join('"');
      const parsed: TaskFile = JSON.parse(clean) as TaskFile;
      const list: Object[] = parsed.tasks !== undefined ? parsed.tasks : [];
      const out: Task[] = [];
      for (let i = 0; i < list.length; i++) {
        const task: Task = TaskRepository.revive(list[i] as Task, list[i] as LegacyTaskJson);
        if (TaskRepository.isUsable(task)) {
          out.push(task);
        }
      }
      hilog.info(DOMAIN, TAG, 'loaded %{public}d tasks', out.length);
      return out;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'tasks file parse failed');
      return [];
    }
  }

  /** Task → 普通对象（只取契约字段，避免 `__ob_` 内部键进文件） */
  private static toPlain(task: Task): TaskPlain {
    const plain: TaskPlain = {
      id: task.id,
      status: task.status,
      name: task.name,
      createdAt: task.createdAt,
      priority: task.priority,
      alarm: task.alarm
    };
    if (task.clientTaskId !== undefined) {
      plain.clientTaskId = task.clientTaskId;
    }
    if (task.note !== undefined) {
      plain.note = task.note;
    }
    if (task.rawText !== undefined) {
      plain.rawText = task.rawText;
    }
    if (task.rawJson !== undefined) {
      plain.rawJson = task.rawJson;
    }
    if (task.dueAt !== undefined) {
      plain.dueAt = task.dueAt;
    }
    if (task.dueText !== undefined) {
      plain.dueText = task.dueText;
    }
    if (task.place !== undefined) {
      plain.place = task.place;
    }
    if (task.who !== undefined) {
      plain.who = task.who;
    }
    if (task.finishedAt !== undefined) {
      plain.finishedAt = task.finishedAt;
    }
    if (task.level !== undefined) {
      plain.level = task.level;
    }
    if (task.remindAt !== undefined) {
      plain.remindAt = task.remindAt;
    }
    if (task.reminderId !== undefined) {
      plain.reminderId = task.reminderId;
    }
    if (task.reminderAt !== undefined) {
      plain.reminderAt = task.reminderAt;
    }
    if (task.calendarEventId !== undefined) {
      plain.calendarEventId = task.calendarEventId;
    }
    if (task.calendarSignature !== undefined) {
      plain.calendarSignature = task.calendarSignature;
    }
    if (task.userEdited !== undefined) {
      plain.userEdited = task.userEdited;
    }
    if (task.aiLabelHidden !== undefined) {
      plain.aiLabelHidden = task.aiLabelHidden;
    }
    if (task.repeat !== undefined) {
      plain.repeat = task.repeat;
    }
    if (task.repeatText !== undefined) {
      plain.repeatText = task.repeatText;
    }
    if (task.source !== undefined) {
      plain.source = task.source;
    }
    if (task.originDetail !== undefined) {
      plain.originDetail = task.originDetail;
    }
    if (task.category !== undefined) {
      plain.category = task.category;
    }
    if (task.tags !== undefined) {
      plain.tags = task.tags;
    }
    if (task.steps !== undefined) {
      plain.steps = task.steps;
    }
    if (task.urls !== undefined) {
      plain.urls = task.urls;
    }
    if (task.linkUrl !== undefined) {
      plain.linkUrl = task.linkUrl;
    }
    if (task.certainty !== undefined) {
      plain.certainty = task.certainty;
    }
    if (task.missingFields !== undefined) {
      plain.missingFields = task.missingFields;
    }
    if (task.pendingSeen !== undefined) {
      plain.pendingSeen = task.pendingSeen;
    }
    if (task.pendingSource !== undefined) {
      plain.pendingSource = task.pendingSource;
    }
    if (task.trashKind !== undefined) {
      plain.trashKind = task.trashKind;
    }
    return plain;
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
    const plain: TaskPlain[] = [];
    for (let i = 0; i < tasks.length; i++) {
      plain.push(TaskRepository.toPlain(tasks[i]));
    }
    const text: string = JSON.stringify({ version: SCHEMA_VERSION, tasks: plain });
    TaskRepository.writeFile(context, text);
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
    task.reminderAt = raw.reminderAt;
    task.calendarEventId = raw.calendarEventId;
    task.calendarSignature = raw.calendarSignature;
    task.userEdited = raw.userEdited;
    task.aiLabelHidden = raw.aiLabelHidden;
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
    task.linkUrl = raw.linkUrl;
    if (Array.isArray(raw.missingFields)) {
      task.missingFields = raw.missingFields.slice();
    }
    if (raw.pendingSeen === true) {
      task.pendingSeen = true;
    }
    if (typeof raw.pendingSource === 'string') {
      task.pendingSource = raw.pendingSource;
    }
    if (typeof raw.trashKind === 'string') {
      task.trashKind = raw.trashKind;
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
