/*
 * TODO(袁正锟): 本文件在 `model/` 下，按 `docs/开发指南.md` §7.3 归谢忠宇。
 * 2026-10-14 由袁正锟口述任务字段，先落成契约草稿；请谢忠宇核对后同步 §9.2 那张表
 * （本机 Task 表 / 云端 BotTask 对齐）。
 */

/**
 * 任务字段契约（袁正锟 2026-10-14 口述）
 *
 * 这份契约**就是最终落库的字段**（袁正锟 2026-10-14 明确），同时兼作 UI 的 Mock 数据形状。
 * 与 `docs/开发指南.md` §9.2 的列名对应关系逐个写在字段注释里。
 *
 * 不在本契约里的持久化字段（`id` / `status` / `raw_text` / `raw_json` / `confidence` /
 * `missing_fields` / `created_at` / `updated_at` / `reminder_id`）仍按 §9.2 由 repository 附加。
 *
 * 纪律：本层只放类型与常量，不放行为；字段名改动必须同步 §9.2 那张表。
 */
/** 重复：不重复 / 每 1 天 / 每 1 周 / 每 1 个月 / 自定义 */
export enum TaskRepeat {
  NONE = 0,
  DAILY = 1,
  WEEKLY = 2,
  MONTHLY = 3,
  CUSTOM = 4
}

/** 紧急程度。取值照 `docs/开发指南.md` §9.2 的 `priority` 列注释：0 普通 / 1 重要 / 2 紧急 */
export enum TaskPriority {
  NORMAL = 0,
  IMPORTANT = 1,
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
  /** 任务名称，**必填**。对应 §9.2 的 `title` */
  title: string;
  /** 步骤，可选。§9.2 没有对应列 */
  steps?: TaskStep[];
  /** 到期时间，可选。界面按 MM月DD日周几 选（只到日，不带时分），存毫秒时间戳。对应 §9.2 的 `due_at` */
  dueAt?: number;
  /** 提醒时间，可选。界面按 MM月DD日周几 HH:mm 选，存毫秒时间戳。对应 §9.2 的 `remind_at` */
  remindAt?: number;
  /** 重复，可选。对应 §9.2 的 `repeat` */
  repeat?: TaskRepeat;
  /** 重复选「自定义」时用户自填的原文，可选。与 `repeat` 同列 */
  repeatText?: string;
  /** 预计耗时，可选，单位小时（界面按 HH小时 填）。§9.2 没有对应列 */
  estimatedHours?: number;
  /** 紧急程度，**必填**（§9.2 是 `NOT NULL`）。对应 §9.2 的 `priority` */
  priority: TaskPriority;
  /** 来源通道，可选。对应 §9.2 的 `source`；取值见 TASK_SOURCE_PRESETS，也可为自定义文本 */
  source?: string;
  /** 类型，可选。§9.2 没有对应列；取值见 TASK_CATEGORY_PRESETS，也可为自定义文本 */
  category?: string;
  /** 标签，可选，自定义。§9.2 没有对应列 */
  tags?: string[];
  /** 备注，可选，纯文本。对应 §9.2 的 `detail` */
  detail?: string;
}
