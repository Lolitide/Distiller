/*
 * TODO(需求方): 本文件在 `model/` 下，按 `docs/开发指南.md` §7.3 归架构。
 * 2026-10-16 按《任务字段表&idea更新》v1 定稿（28 字段）更新桶导出；请架构核对后同步建表语句。
 */

/**
 * model —— 数据结构与字段约定
 *
 * 规划（见 `任务字段表&idea更新.md` §1）
 *   Models.ets  已落地：Task（v1 定稿 28 字段）+ TaskStep + RepeatRule + 相关枚举
 *   待补：      BotTask  云端对象，只有十个字段，靠 clientTaskId（后端 candidate_id）与本机 Task 对齐
 *
 * 纪律：本层只放类型与常量，不放行为；字段名改动必须先改字段表。
 */
export {
  Task,
  TaskStep,
  RepeatRule,
  TaskStatus,
  TaskPriority,
  TaskLevel,
  TaskAlarm,
  TaskSource,
  RepeatFrequency,
  TASK_CATEGORY_PRESETS
} from './Models';
