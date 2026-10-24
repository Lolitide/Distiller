/**
 * 后端候选 → 本机 `Task`（28 字段）的唯一映射层。
 *
 * 口径（对齐《任务字段表》v1）：
 *   · 时间一律毫秒；`due_at` 后端已算好，优先用它，没有才用 `time_normalized`
 *   · `priority` 四档字符串 → 三档 `TaskPriority`；`later` 归 NORMAL（界面没有第四档）
 *   · `level` 0/1/2 直接对应 `TaskLevel`；只参与排序，不显示
 *   · `certainty` 后端 0~100，直接用（不是 0~1）
 *   · `repeat` 字段名与官方 `RecurrenceRule` 同名，数组直接搬
 *   · `rawText` / `rawJson` 永久保留、永不上云；原文由 SyncService 从 `/messages` 取
 */
import {
  RepeatRule,
  RepeatFrequency,
  Task,
  TaskLevel,
  TaskPriority,
  TaskSource,
  TaskStatus,
  TaskStep
} from '../../model';
import { CandidateItem, RepeatRuleDto, ServeParse, StepDto } from './BackendTypes';

/** 后端时间串（"2026-10-13 23:07:59"）→ 毫秒；解析不了返回 0 */
export function parseBackendTime(text: string): number {
  const s: string = (text || '').trim();
  if (s.length < 10) {
    return 0;
  }
  const iso: string = s.replace(' ', 'T');
  const t: number = Date.parse(iso);
  return Number.isNaN(t) ? 0 : t;
}

function priorityOf(value: string): TaskPriority {
  if (value === 'urgent') {
    return TaskPriority.URGENT;
  }
  if (value === 'high') {
    return TaskPriority.IMPORTANT;
  }
  return TaskPriority.NORMAL;
}

function levelOf(value: number | undefined): TaskLevel {
  if (value === 2) {
    return TaskLevel.HARD;
  }
  if (value === 1) {
    return TaskLevel.MEDIUM;
  }
  return TaskLevel.EASY;
}

function repeatOf(rules: RepeatRuleDto[] | undefined): RepeatRule[] {
  const out: RepeatRule[] = [];
  if (rules === undefined) {
    return out;
  }
  for (let i = 0; i < rules.length; i++) {
    const dto: RepeatRuleDto = rules[i];
    const rule: RepeatRule = new RepeatRule();
    rule.frequency = dto.frequency as RepeatFrequency;
    if (dto.interval !== undefined) {
      rule.interval = dto.interval;
    }
    if (dto.daysOfWeek !== undefined) {
      rule.daysOfWeek = dto.daysOfWeek;
    }
    if (dto.daysOfMonth !== undefined) {
      rule.daysOfMonth = dto.daysOfMonth;
    }
    if (dto.monthsOfYear !== undefined) {
      rule.monthsOfYear = dto.monthsOfYear;
    }
    if (dto.weeksOfMonth !== undefined) {
      rule.weeksOfMonth = dto.weeksOfMonth;
    }
    if (dto.count !== undefined) {
      rule.count = dto.count;
    }
    if (dto.expire !== undefined) {
      rule.expire = dto.expire;
    }
    if (dto.dates !== undefined) {
      rule.dates = dto.dates;
    }
    out.push(rule);
  }
  return out;
}

function stepsOf(steps: StepDto[] | undefined): TaskStep[] {
  const out: TaskStep[] = [];
  if (steps === undefined) {
    return out;
  }
  for (let i = 0; i < steps.length; i++) {
    const step: TaskStep = new TaskStep();
    step.content = steps[i].content;
    step.done = steps[i].done === 1 ? 1 : 0;
    out.push(step);
  }
  return out;
}

/**
 * 候选 → 本机任务。
 *
 * @param id       本机自增主键
 * @param rawText  原文（由 `source.msg_ids` 从 `/messages` 拼出来；取不到就空着）
 */
export function candidateToTask(c: CandidateItem, id: number, rawText: string): Task {
  const task: Task = new Task();
  task.id = id;
  task.clientTaskId = c.candidate_id;
  // 没有「确认页」的版本里直接进已确认，否则列表会按待确认态显示
  task.status = TaskStatus.CONFIRMED;
  // 三档兜底：title → summary → 占位名，避免存进本机后变成没有名称的空壳卡片
  const title: string = typeof c.title === 'string' ? c.title.trim() : '';
  const summary: string = typeof c.summary === 'string' ? c.summary.trim() : '';
  task.name = title.length > 0 ? title : (summary.length > 0 ? summary : '未命名事项');
  task.note = summary;
  task.rawText = rawText;
  task.rawJson = JSON.stringify(c);
  task.createdAt = parseBackendTime(c.created_at) || Date.now();
  task.priority = priorityOf(c.priority);
  task.level = levelOf(c.level);

  const due: number = c.due_at !== undefined && c.due_at > 0 ? c.due_at : 0;
  if (due > 0) {
    task.dueAt = due;
  }
  const dueText: string = (c.due_text !== undefined && c.due_text.length > 0)
    ? c.due_text : c.time_text;
  if (dueText.length > 0) {
    task.dueText = dueText;
  }
  if (c.place.length > 0) {
    task.place = c.place;
  }
  if (c.who.length > 0) {
    task.who = c.who;
  }
  if (c.category !== undefined && c.category.length > 0) {
    task.category = c.category;
  }
  if (c.tags.length > 0) {
    task.tags = c.tags;
  }
  const steps: TaskStep[] = stepsOf(c.steps);
  if (steps.length > 0) {
    task.steps = steps;
  }
  const repeat: RepeatRule[] = repeatOf(c.repeat);
  if (repeat.length > 0) {
    task.repeat = repeat;
  }
  if (c.repeat_text !== undefined && c.repeat_text.length > 0) {
    task.repeatText = c.repeat_text;
  }
  if (c.certainty !== undefined && c.certainty > 0) {
    task.certainty = Math.round(c.certainty);
  } else {
    task.certainty = Math.round(c.confidence * 100);
  }
  if (c.missing_fields !== undefined && c.missing_fields.length > 0) {
    task.missingFields = c.missing_fields;
  }
  task.source = TaskSource.BOT;
  task.originDetail = c.source.group_label;
  return task;
}

/**
 * 消息级解析 → 任务（「手动添加」走 `/parse` 时用；与候选共用同一套字段口径）。
 * `parse` 里没有 `created_at` / `missing_fields`，由调用方补。
 */
export function parseToTask(p: ServeParse, id: number, rawText: string,
  originLabel: string): Task {
  const candidate: CandidateItem = {
    candidate_id: 'local_' + id,
    rev_seq: 0,
    thread_id: '',
    kind: p.kind,
    priority: p.priority !== undefined ? p.priority : 'normal',
    level: p.level,
    category: p.category,
    channel: p.channel !== undefined ? p.channel : 'manual',
    due_at: p.dueAt,
    due_text: p.dueText,
    repeat: p.repeat,
    repeat_text: p.repeatText,
    certainty: p.certainty,
    missing_fields: p.missingFields,
    title: p.title,
    summary: p.summary,
    time_text: p.timeText,
    time_normalized: p.timeNormalized,
    time_unresolved: p.timeUnresolved,
    place: p.place,
    who: p.who,
    deadline: p.deadline,
    items: p.items,
    steps: p.steps !== undefined ? p.steps : [],
    tags: p.tags,
    confidence: p.confidence,
    engine: p.engine,
    source: {
      group_openid: '',
      group_label: originLabel,
      senders: [],
      msg_ids: [],
      count: 1,
      first_ts: '',
      last_ts: ''
    },
    created_at: ''
  };
  const task: Task = candidateToTask(candidate, id, rawText);
  task.source = TaskSource.MANUAL;
  task.createdAt = Date.now();
  return task;
}
