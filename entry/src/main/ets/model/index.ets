/*
 * TODO(袁正锟): 本文件在 `model/` 下，按 `docs/开发指南.md` §7.3 归谢忠宇。
 * 2026-10-14 只加了 Models.ets 的桶导出，未动原有规划；请谢忠宇核对。
 */

/**
 * model —— 数据结构与字段约定
 *
 * 规划（见 docs/开发指南.md §9.2）
 *   Models.ets  已落地：Task  用户可填的任务字段契约 + TaskStep + 相关枚举与预设
 *   待补：      BotTask  云端对象，只有十个字段，靠 client_task_id 与本机 Task 对齐
 *
 * 纪律：本层只放类型与常量，不放行为；字段名改动必须同步 §9.2 那张表。
 */
export {
  Task,
  TaskStep,
  TaskRepeat,
  TaskUrgency,
  TASK_SOURCE_PRESETS,
  TASK_CATEGORY_PRESETS
} from './Models';
