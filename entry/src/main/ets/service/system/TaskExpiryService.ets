/*
 * 系统侧「已过期」扫描 —— **唯一入口**。
 *
 * 为什么单开一个 service 而不是让调用方各自去摸 store：
 *  · 触发点有三处，且分属不同层：**启动**（`A_Main`）、**轮询**（`SyncService` 每 5 秒）、
 *    **用户改到期时间**（`TaskAttributeCard`）。三处都要同一套判定，否则哪天改了规则，
 *    总有一处忘了同步；
 *  · 判定的**写逻辑**仍然只在 `TaskListStore.syncExpiredStatus` 里（它负责
 *    「什么时候算过期 / 双向复活 / 关提醒 / 重新分组 / 落盘」）。本类只做转发与命名，
 *    不自己判断时间，也不写任何字段 —— 免得出现两份口径；
 *  · 以后接 `ReminderService` 时要"先撤销提醒再标过期"，那个动作也挂在这里，页面不用改。
 *
 * 纪律：`EXPIRED` 只有系统能写（`model/Models.ets` 的注释）；页面与详情页状态分段都**不能**选它。
 */
import { TaskListStore } from '../../viewmodel/TaskListStore';

export class TaskExpiryService {
  /**
   * 扫描一次：把「到期且未完成」的任务写成 `EXPIRED`，把「已过期但期限又被挪到将来」的改回 `CONFIRMED`。
   *
   * @param now 判定基准（毫秒）；默认当前时刻
   * @returns 状态被改写的条数（0 ＝ 没有任何变化）
   */
  static scanOnce(now: number = Date.now()): number {
    return TaskListStore.instance().syncExpiredStatus(now);
  }
}
