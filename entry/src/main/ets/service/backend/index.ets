/**
 * service/backend —— bot 中继的契约子域
 *
 * 这里放的是「约定」不是「实现」：bot 侧与云函数的字段约定、消息模板、
 * 与手机侧对齐的 client_task_id 生成规则。见 docs/开发指南.md §6.3。
 *
 * 纪律：本目录不产生运行期 ArkTS 实现，页面与 ViewModel 都不引用它。
 * 字段约定一旦改动，云端对象、bot 侧解析、手机侧拉取三处必须同时改。
 */
export {};
