/**
 * model —— 数据结构与字段约定
 *
 * 规划：合并为单文件 Models.ets，装 docs/开发指南.md §9.2 的字段约定：
 *   Task  本机任务表（含 raw_text / raw_json，这两个字段永远不上云）
 *   BotTask  云端对象，只有十个字段，靠 client_task_id 与本机 Task 对齐
 *
 * 纪律：本层只放类型与常量，不放行为；字段名改动必须同步 §9.2 那张表。
 */
export {};
