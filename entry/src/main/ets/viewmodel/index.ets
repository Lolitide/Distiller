/**
 * viewmodel —— 每页一个 ViewModel
 *
 * 规划（见 docs/开发指南.md §9.4）：新代码用 ArkUI 状态管理 V2，
 * @ObservedV2 / @Trace 承载可观察字段，@Local / @Param / @Event 用于组件间传递。
 *
 * 纪律：页面只做渲染与事件转发；状态归属先想清楚再写。跨页共享状态在真正出现
 * 需求时再决定放哪——项目当前不建 state/ 目录。
 */
export {};
