/**
 * 后台代理提醒（Reminder Agent）封装。
 *
 * 纪律：
 *  · 只有这里能调 `publishReminder` / `cancelReminder`；
 *  · `alarm` 是用户意图，`reminderId` 是系统句柄 —— 发布成功才写句柄，失败要回滚意图；
 *  · 单应用有效提醒有上限（约 30 条），超额会报 1700002，调用方要给出可执行提示。
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Task } from '../../model';

const DOMAIN: number = 0x0000;
const TAG: string = 'ReminderService';
const ABILITY_NAME: string = 'EntryAbility';

export class ReminderService {
  /** 发布：返回系统句柄。失败抛错，由调用方回滚 `alarm` 并提示。 */
  static async publish(task: Task, bundleName: string): Promise<number> {
    const at: number = ReminderService.fireTime(task);
    if (at <= 0) {
      throw new Error('缺少提醒时间');
    }
    const d: Date = new Date(at);
    const request: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: d.getFullYear(),
        month: d.getMonth() + 1,
        day: d.getDate(),
        hour: d.getHours(),
        minute: d.getMinutes(),
        second: 0
      },
      title: task.name,
      content: task.note !== undefined && task.note.length > 0 ? task.note : '任务要开始啦',
      notificationId: task.id,
      wantAgent: {
        pkgName: bundleName,
        abilityName: ABILITY_NAME
      }
    };
    const id: number = await reminderAgentManager.publishReminder(request);
    hilog.info(DOMAIN, TAG, 'published reminder %{public}d for task %{public}d', id, task.id);
    return id;
  }

  /** 撤销：失败只记日志（任务已经在本地删掉/完成，不能因此阻塞用户操作）。 */
  static async cancel(reminderId: number): Promise<void> {
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      hilog.info(DOMAIN, TAG, 'cancelled reminder %{public}d', reminderId);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'cancelReminder %{public}d failed: %{public}d %{public}s',
        reminderId, err.code, err.message);
    }
  }

  /** 实际响铃时刻：优先 `remindAt`；若提前量已过但还没到期，就改在到期时刻响。 */
  static fireTime(task: Task): number {
    const now: number = Date.now();
    if (task.remindAt !== undefined && task.remindAt > now) {
      return task.remindAt;
    }
    if (task.dueAt !== undefined && task.dueAt > now) {
      return task.dueAt;
    }
    return 0;
  }
}
