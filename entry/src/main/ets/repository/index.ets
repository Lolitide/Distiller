/**
 * repository —— 本机数据的唯一入口
 *
 * 规划：合并为单文件 Repositories.ets，基于 relationalStore 与 preferences：
 *   TaskRepository       任务的增删改查与状态流转
 *   SettingsRepository   提醒提前量、解析方式、云端同步开关等首选项
 *
 * 纪律：页面与 ViewModel 不许直接开数据库；service/cloud/ 也只从本层读写，
 * 保证云端数据落盘前一定过本层的字段校验。
 */
export {};
