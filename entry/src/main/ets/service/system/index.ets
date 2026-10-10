/**
 * service/system —— 系统能力子域
 *
 * 规划中的成员（见 docs/开发指南.md §9.1、§9.5）：
 *   ReminderService     提醒的统一出口
 *   NotificationService 通知授权（requestEnableNotification）
 *   PermissionService   权限申请与状态查询
 *
 * 纪律：提醒有两条实现路径（代理提醒 / 日历）。ReminderService 对外只暴露
 * 「发布、撤销、查询」三个动作，内部走哪条路径由它自己决定——页面与 ViewModel 里
 * 不许出现 `if (用了日历)` 这类分支。
 */
export {};
