/*
 * TODO(需求方): 本文件在 `model/` 下，按 `docs/开发指南.md` §7.3 归架构。
 * 2026-10-14 由需求方口述任务字段，先落成契约草稿；请架构核对后再并入 §9.2 的字段表
 * （本机 Task 表 / 云端 BotTask 对齐），并把我这边与 §9.2 的差异一并处置。
 */

/**
 * 任务字段契约（需求方 2026-10-14 口述）
 *
 * 只装**用户在确认页能填的字段**。持久化字段（`id` / `status` / `raw_text` / `raw_json` /
 * `confidence` / `missing_fields` / `created_at` / `updated_at` / `reminder_id`）不在本契约里，
 * 仍按 `docs/开发指南.md` §9.2 由 repository 附加。
 *
 * 纪律：本层只放类型与常量，不放行为。字段名改动必须同步 §9.2 那张表。
 */

/** 重复：不重复 / 每 1 天 / 每 1 周 / 每 1 个月 / 自定义 */
export enum TaskRepeat {
  NONE = 0,
  DAILY = 1,
  WEEKLY = 2,
  MONTHLY = 3,
  CUSTOM = 4
}

/** 紧急程度。需求方目前只定了「紧急」，其余档位未定（0 / 1 预留给待定的较低档位） */
export enum TaskUrgency {
  URGENT = 2
}

/** 来源的预设项；选「自定义」时由用户自填文本，故字段类型是 string 而不是枚举 */
export const TASK_SOURCE_PRESETS: string[] = ['QQ', '微信'];

/** 类型的预设项；同上，「自定义」由用户自填 */
export const TASK_CATEGORY_PRESETS: string[] = ['作业', '考试'];

/** 步骤，可选，用户可以添加若干条 */
export interface TaskStep {
  content: string;
}

/** 任务 */
export interface Task {
  /** 任务名称，**必填** */
  title: string;
  /** 步骤，可选 */
  steps?: TaskStep[];
  /** 提醒时间，可选。界面按 MM月DD日周几 HH:mm 选，存毫秒时间戳 */
  remindAt?: number;
  /** 重复，可选 */
  repeat?: TaskRepeat;
  /** 重复选「自定义」时用户自填的原文，可选 */
  repeatText?: string;
  /** 预计耗时，可选。单位：小时（界面按 HH小时 填） */
  estimatedHours?: number;
  /** 紧急程度，可选 */
  urgency?: TaskUrgency;
  /** 来源，可选。取值见 TASK_SOURCE_PRESETS，也可为自定义文本 */
  source?: string;
  /** 类型，可选。取值见 TASK_CATEGORY_PRESETS，也可为自定义文本 */
  category?: string;
  /** 标签，可选，自定义 */
  tags?: string[];
  /** 备注，可选，纯文本 */
  note?: string;
}
