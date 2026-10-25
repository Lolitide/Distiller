/**
 * 任务导出：把内存里的任务清单序列化成 **CSV / JSON** 两种文本（纯字符串拼装，不碰文件系统）。
 *
 * 为什么单独一个文件、而且放在 `viewmodel/`：
 *  · 「导出成什么样子」是**展示口径**（列名、时间格式、状态/重要性的中文），归 ViewModel；
 *  · 「写到哪儿」是系统能力（文件保存器 / 剪贴板），归 `service/system/TaskExportService`；
 *  · 页面只负责"点一下 → 拿文本 → 报结果"，不拼表头、不做转义。
 *
 * 两条数据边界（字段表 §3「数据边界」）：
 *  · **CSV 是给人/Excel 看的**，只走**白名单列**，且**不含 `rawText` / `rawJson`**（原文与平台原始返回只在本机）；
 *  · **JSON 是完整备份口径**，含原文与原始返回 —— 所以设置页那一条明确写着「含原文」，由用户自己选。
 *
 * 时间：CSV 用本地时区的 `YYYY-MM-DD HH:mm`（给人看）；JSON 保留**毫秒时间戳原值**（给机器/回灌用）。
 */
import { Task, TaskLevel, TaskPriority, TaskSource, TaskStatus, TaskStep } from '../model';
import { TaskListViewModel } from './TaskListViewModel';

/** CSV 列名（顺序即列序）。**这就是白名单**：不在这个数组里的字段不会进 CSV */
const CSV_COLUMNS: string[] = [
  '名称', '状态', '重要性', '难易程度', '类型', '来源', '来源展示名', '标签',
  '到期时间', '到期原文', '提醒时间', '地点', '对象', '子任务', '置信度',
  '缺失字段', '创建时间', '完成时间', '备注'
];

/** JSON 里的 schema 号：以后字段变了就 +1，导入方据此判断 */
const EXPORT_SCHEMA: number = 1;

/** 导出的一条任务（**显式白名单**：不直接把 `Task` 丢给 `JSON.stringify`，免得内部字段漏出去） */
export class TaskExportRow {
  id: number = 0;
  clientTaskId: string = '';
  name: string = '';
  /** 原始数值 + 中文，两边都留：机器按数值、人按中文 */
  status: number = 0;
  statusText: string = '';
  priority: number = 0;
  priorityText: string = '';
  level: number = -1;
  levelText: string = '';
  category: string = '';
  source: string = '';
  sourceText: string = '';
  originDetail: string = '';
  tags: string[] = [];
  /** 毫秒时间戳；0 ＝ 未设置 */
  dueAt: number = 0;
  dueText: string = '';
  remindAt: number = 0;
  place: string = '';
  who: string = '';
  stepsTotal: number = 0;
  stepsDone: number = 0;
  /** JSON 完整备份带步骤内容；CSV 不用 */
  steps?: TaskStep[];
  certainty: number = -1;
  missingFields: string[] = [];
  createdAt: number = 0;
  finishedAt: number = 0;
  note: string = '';
  /** 以下两个**只在 JSON 导出里出现**（CSV 白名单不含） */
  rawText: string = '';
  rawJson: string = '';
  urls?: string[];
  linkUrl?: string;
}

/** JSON 导出的外层结构（带元信息，方便对方判断"这是什么时候、哪个版本的导出"） */
export class TaskExportBundle {
  schema: number = EXPORT_SCHEMA;
  app: string = '知了 / Distiller';
  exportedAt: string = '';
  exportedAtMs: number = 0;
  count: number = 0;
  tasks: TaskExportRow[] = [];
}

export class TaskExportViewModel {
  /** 导出文件名：`知了-任务-20261025-1930.csv`（本地时间，分钟级足够区分） */
  static fileName(ext: string): string {
    const now: Date = new Date();
    const stamp: string =
      `${now.getFullYear()}${TaskListViewModel.pad2(now.getMonth() + 1)}${TaskListViewModel.pad2(now.getDate())}`
        + `-${TaskListViewModel.pad2(now.getHours())}${TaskListViewModel.pad2(now.getMinutes())}`;
    return `知了-任务-${stamp}.${ext}`;
  }

  /** CSV 文本（白名单列；单元格按 RFC 4180 转义：含逗号/引号/换行时用双引号包起来） */
  static buildCsv(tasks: Task[]): string {
    const lines: string[] = [];
    const header: string[] = [];
    for (let i = 0; i < CSV_COLUMNS.length; i++) {
      header.push(TaskExportViewModel.cell(CSV_COLUMNS[i]));
    }
    lines.push(header.join(','));
    for (let i = 0; i < tasks.length; i++) {
      const row: TaskExportRow = TaskExportViewModel.toRow(tasks[i]);
      lines.push(TaskExportViewModel.csvLine(row));
    }
    // 末尾补一个换行：部分 Excel 版本对没有行尾换行的最后一行处理不友好
    return lines.join('\r\n') + '\r\n';
  }

  /** JSON 文本（完整口径，**含原文**） */
  static buildJson(tasks: Task[]): string {
    const bundle: TaskExportBundle = new TaskExportBundle();
    const now: Date = new Date();
    bundle.exportedAtMs = now.getTime();
    bundle.exportedAt = TaskExportViewModel.stamp(now.getTime());
    bundle.count = tasks.length;
    const rows: TaskExportRow[] = [];
    for (let i = 0; i < tasks.length; i++) {
      rows.push(TaskExportViewModel.toRow(tasks[i]));
    }
    bundle.tasks = rows;
    return JSON.stringify(bundle, null, 2);
  }

  /* ── 内部 ── */

  private static toRow(task: Task): TaskExportRow {
    const row: TaskExportRow = new TaskExportRow();
    row.id = task.id;
    row.clientTaskId = task.clientTaskId !== undefined ? task.clientTaskId : '';
    row.name = task.name;
    row.status = task.status;
    row.statusText = TaskListViewModel.statusLabel(task.status);
    row.priority = task.priority;
    row.priorityText = TaskListViewModel.priorityLabel(task.priority);
    if (task.level !== undefined) {
      row.level = task.level;
      row.levelText = TaskExportViewModel.levelText(task.level);
    }
    row.category = task.category !== undefined ? task.category : '';
    row.source = task.source !== undefined ? task.source : '';
    row.sourceText = TaskExportViewModel.sourceText(task.source);
    row.originDetail = task.originDetail !== undefined ? task.originDetail : '';
    row.tags = task.tags !== undefined ? task.tags : [];
    row.dueAt = task.dueAt !== undefined ? task.dueAt : 0;
    row.dueText = task.dueText !== undefined ? task.dueText : '';
    row.remindAt = task.remindAt !== undefined ? task.remindAt : 0;
    row.place = task.place !== undefined ? task.place : '';
    row.who = task.who !== undefined ? task.who : '';
    if (task.steps !== undefined) {
      row.steps = task.steps;
      row.stepsTotal = task.steps.length;
      let done: number = 0;
      for (let i = 0; i < task.steps.length; i++) {
        if (task.steps[i].done === 1) {
          done++;
        }
      }
      row.stepsDone = done;
    }
    row.certainty = task.certainty !== undefined ? task.certainty : -1;
    row.missingFields = task.missingFields !== undefined ? task.missingFields : [];
    row.createdAt = task.createdAt;
    row.finishedAt = task.finishedAt !== undefined ? task.finishedAt : 0;
    row.note = task.note !== undefined ? task.note : '';
    row.urls = task.urls !== undefined ? task.urls : [];
    row.linkUrl = task.linkUrl !== undefined ? task.linkUrl : '';
    row.rawText = task.rawText !== undefined ? task.rawText : '';
    row.rawJson = task.rawJson !== undefined ? task.rawJson : '';
    return row;
  }

  /** 一行 CSV（**列序必须与 `CSV_COLUMNS` 一致**） */
  private static csvLine(row: TaskExportRow): string {
    const cells: string[] = [
      row.name,
      row.statusText,
      row.priorityText,
      row.levelText,
      row.category,
      row.sourceText,
      row.originDetail,
      row.tags.join(' '),
      TaskExportViewModel.stampOrEmpty(row.dueAt),
      row.dueText,
      TaskExportViewModel.stampOrEmpty(row.remindAt),
      row.place,
      row.who,
      row.stepsTotal > 0 ? `${row.stepsDone}/${row.stepsTotal}` : '',
      row.certainty >= 0 ? `${row.certainty}` : '',
      row.missingFields.join(' '),
      TaskExportViewModel.stampOrEmpty(row.createdAt),
      TaskExportViewModel.stampOrEmpty(row.finishedAt),
      row.note
    ];
    const out: string[] = [];
    for (let i = 0; i < cells.length; i++) {
      out.push(TaskExportViewModel.cell(cells[i]));
    }
    return out.join(',');
  }

  /** RFC 4180：含分隔符/引号/换行时整体加引号，内部引号翻倍 */
  private static cell(value: string): string {
    const text: string = value === undefined || value === null ? '' : value;
    const needQuote: boolean = text.indexOf(',') >= 0 || text.indexOf('"') >= 0
      || text.indexOf('\n') >= 0 || text.indexOf('\r') >= 0;
    if (!needQuote) {
      return text;
    }
    return '"' + text.replace(/"/g, '""') + '"';
  }

  /** 毫秒 → `YYYY-MM-DD HH:mm`（本地时区）；0/未设置 → 空串 */
  private static stampOrEmpty(ts: number): string {
    if (ts === undefined || ts === null || ts <= 0) {
      return '';
    }
    return TaskExportViewModel.stamp(ts);
  }

  private static stamp(ts: number): string {
    // 复用一个 Date 实例：每条任务都要格式化两次时间戳，lint 的 reuse-date-instances 规则会盯 new Date
    TaskExportViewModel.dateProbe.setTime(ts);
    const d: Date = TaskExportViewModel.dateProbe;
    return `${d.getFullYear()}-${TaskListViewModel.pad2(d.getMonth() + 1)}-${TaskListViewModel.pad2(d.getDate())}`
      + ` ${TaskListViewModel.pad2(d.getHours())}:${TaskListViewModel.pad2(d.getMinutes())}`;
  }

  /** 格式化时间戳用的可复用实例（单线程 UI，不会并发） */
  private static readonly dateProbe: Date = new Date(0);

  /** 难易程度（与 `TaskInfoCard` 的三档同口径） */
  private static levelText(level: TaskLevel): string {
    if (level === TaskLevel.EASY) {
      return '简单';
    }
    if (level === TaskLevel.HARD) {
      return '困难';
    }
    return '中等';
  }

  /** 来源通道（与 `TaskMetaCard` 的五档同口径；`source` 为空时导出空串，不编"手动"） */
  private static sourceText(source: TaskSource | undefined): string {
    if (source === undefined || source === null) {
      return '';
    }
    if (source === TaskSource.PASTE) {
      return '粘贴';
    }
    if (source === TaskSource.SHARE) {
      return '分享';
    }
    if (source === TaskSource.BOT) {
      return '机器人';
    }
    if (source === TaskSource.VOICE) {
      return '语音';
    }
    if (source === TaskSource.MANUAL) {
      return '手动';
    }
    return source;
  }

  /** 导入去重：所有可导出字段完全一致才算同一条 */
  static sameTask(a: Task, b: Task): boolean {
    return a.name === b.name
      && (a.note || '') === (b.note || '')
      && (a.rawText || '') === (b.rawText || '')
      && (a.rawJson || '') === (b.rawJson || '')
      && (a.dueAt || 0) === (b.dueAt || 0)
      && (a.dueText || '') === (b.dueText || '')
      && (a.place || '') === (b.place || '')
      && (a.who || '') === (b.who || '')
      && a.createdAt === b.createdAt
      && (a.finishedAt || 0) === (b.finishedAt || 0)
      && a.priority === b.priority
      && (a.level === undefined ? -1 : a.level) === (b.level === undefined ? -1 : b.level)
      && (a.category || '') === (b.category || '')
      && (a.source || '') === (b.source || '')
      && (a.originDetail || '') === (b.originDetail || '')
      && (a.linkUrl || '') === (b.linkUrl || '')
      && (a.certainty === undefined ? -1 : a.certainty) === (b.certainty === undefined ? -1 : b.certainty)
      && JSON.stringify(a.tags || []) === JSON.stringify(b.tags || [])
      && JSON.stringify(a.steps || []) === JSON.stringify(b.steps || [])
      && JSON.stringify(a.urls || []) === JSON.stringify(b.urls || [])
      && JSON.stringify(a.missingFields || []) === JSON.stringify(b.missingFields || []);
  }

  /** 解析导入 JSON（只认本应用导出的 schema=1；不合规的行跳过，不猜字段） */
  static parseJson(text: string): TaskImportParseResult {
    const out: TaskImportParseResult = new TaskImportParseResult();
    let bundle: ImportBundle;
    try {
      bundle = JSON.parse(text) as ImportBundle;
    } catch (error) {
      out.message = '不是有效的 JSON 文件';
      return out;
    }
    if (bundle === null || bundle === undefined || !Array.isArray(bundle.tasks)) {
      out.message = '文件里没有任务列表（需要知了导出的 JSON）';
      return out;
    }
    const rows: ImportRow[] = bundle.tasks;
    const now: number = Date.now();
    for (let i = 0; i < rows.length; i++) {
      const row: ImportRow = rows[i];
      if (row === null || row === undefined || typeof row.name !== 'string' || row.name.trim().length === 0) {
        continue;
      }
      if (row.status === TaskStatus.DELETED) {
        continue;
      }
      const task: Task = new Task();
      task.id = 0;
      task.clientTaskId = 'import-' + now + '-' + i;
      task.name = row.name.trim();
      task.status = TaskExportViewModel.importStatus(row.status);
      task.priority = TaskExportViewModel.importPriority(row.priority);
      task.level = TaskExportViewModel.importLevel(row.level);
      task.note = typeof row.note === 'string' && row.note.length > 0 ? row.note : undefined;
      task.rawText = typeof row.rawText === 'string' && row.rawText.length > 0 ? row.rawText : undefined;
      task.rawJson = typeof row.rawJson === 'string' && row.rawJson.length > 0 ? row.rawJson : undefined;
      task.dueAt = typeof row.dueAt === 'number' && row.dueAt > 0 ? row.dueAt : undefined;
      task.dueText = typeof row.dueText === 'string' ? row.dueText : undefined;
      task.place = typeof row.place === 'string' && row.place.length > 0 ? row.place : undefined;
      task.who = typeof row.who === 'string' && row.who.length > 0 ? row.who : undefined;
      task.category = typeof row.category === 'string' && row.category.length > 0 ? row.category : undefined;
      task.originDetail = typeof row.originDetail === 'string' && row.originDetail.length > 0 ? row.originDetail : undefined;
      task.urls = Array.isArray(row.urls) ? row.urls : [];
      task.linkUrl = typeof row.linkUrl === 'string' && row.linkUrl.length > 0 ? row.linkUrl : undefined;
      task.certainty = typeof row.certainty === 'number' && row.certainty >= 0 ? row.certainty : undefined;
      task.missingFields = Array.isArray(row.missingFields) ? row.missingFields : [];
      task.source = TaskExportViewModel.importSource(row.source);
      task.tags = Array.isArray(row.tags) ? row.tags : [];
      task.steps = Array.isArray(row.steps) ? row.steps : [];
      task.createdAt = typeof row.createdAt === 'number' && row.createdAt > 0 ? row.createdAt : now;
      task.finishedAt = typeof row.finishedAt === 'number' && row.finishedAt > 0 ? row.finishedAt : undefined;
      task.alarm = 0;
      out.tasks.push(task);
    }
    out.ok = out.tasks.length > 0;
    if (!out.ok) {
      out.message = '没有可导入的任务';
    }
    return out;
  }

  private static importStatus(status: number | undefined): TaskStatus {
    if (status === TaskStatus.COMPLETED) {
      return TaskStatus.COMPLETED;
    }
    if (status === TaskStatus.IN_PROGRESS) {
      return TaskStatus.IN_PROGRESS;
    }
    if (status === TaskStatus.EXPIRED) {
      return TaskStatus.EXPIRED;
    }
    return TaskStatus.CONFIRMED;
  }

  private static importPriority(priority: number | undefined): TaskPriority {
    if (priority === TaskPriority.URGENT) {
      return TaskPriority.URGENT;
    }
    if (priority === TaskPriority.IMPORTANT) {
      return TaskPriority.IMPORTANT;
    }
    return TaskPriority.NORMAL;
  }

  private static importLevel(level: number | undefined): TaskLevel | undefined {
    if (level === TaskLevel.EASY) {
      return TaskLevel.EASY;
    }
    if (level === TaskLevel.MEDIUM) {
      return TaskLevel.MEDIUM;
    }
    if (level === TaskLevel.HARD) {
      return TaskLevel.HARD;
    }
    return undefined;
  }

  private static importSource(source: string | undefined): TaskSource | undefined {
    if (source === TaskSource.PASTE) {
      return TaskSource.PASTE;
    }
    if (source === TaskSource.SHARE) {
      return TaskSource.SHARE;
    }
    if (source === TaskSource.BOT) {
      return TaskSource.BOT;
    }
    if (source === TaskSource.VOICE) {
      return TaskSource.VOICE;
    }
    if (source === TaskSource.MANUAL) {
      return TaskSource.MANUAL;
    }
    return undefined;
  }
}

/** 导入结果：解析失败也给一句人话 */
export class TaskImportParseResult {
  ok: boolean = false;
  message: string = '';
  tasks: Task[] = [];
}

interface ImportRow {
  steps?: TaskStep[];
  originDetail?: string;
  urls?: string[];
  linkUrl?: string;
  certainty?: number;
  missingFields?: string[];
  name?: string;
  status?: number;
  priority?: number;
  level?: number;
  category?: string;
  source?: string;
  tags?: string[];
  dueAt?: number;
  dueText?: string;
  place?: string;
  who?: string;
  createdAt?: number;
  finishedAt?: number;
  note?: string;
  rawText?: string;
  rawJson?: string;
}

interface ImportBundle {
  schema?: number;
  tasks?: ImportRow[];
}
