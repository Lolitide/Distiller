/**
 * 提醒/日历的「对账器」：把任务表里的**意图**（`alarm` / 到期时间）同步到系统句柄。
 *
 * 为什么不在每个编辑入口分别调用：任务可从卡片、详情、批量操作、同步等多处修改，
 * 逐个接线必漏。这里按任务表做一次对账，启动、保存、完成、删除后各跑一遍即可。
 */
import { bundleManager, common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Task, TaskAlarm, TaskStatus } from '../../model';
import { ReminderService } from './ReminderService';
import { CalendarService } from './CalendarService';

const DOMAIN: number = 0x0000;
const TAG: string = 'ReminderCoordinator';

export class ReminderCoordinator {
  /** 最近一次发布失败的提示（页面可读它显示 toast；为空表示没有错误） */
  static lastError: string = '';
  /** 最近一次失败的原始错误码（1700002 = 额度满；其余按权限/系统错误处理） */
  static lastErrorCode: number = 0;

  /**
   * 启动清理：撤销本应用**所有**有效提醒。
   * 反复重装/清数据会留下任务表里已无句柄的「幽灵提醒」，它们照样占 30 条额度，
   * 表现为只有几条任务却报 1700002。清空后由对账器按当前任务表重新发布。
   * 返回是否清理成功（失败就不要清空任务里的句柄，避免重复发布）。
   */
  static async cancelAll(): Promise<boolean> {
    try {
      const infos: reminderAgentManager.ReminderInfo[] = await reminderAgentManager.getAllValidReminders();
      for (let i = 0; i < infos.length; i++) {
        await ReminderService.cancel(infos[i].reminderId);
      }
      hilog.info(DOMAIN, TAG, 'cancelled %{public}d stale reminders', infos.length);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'cancelAll failed: %{public}d %{public}s', err.code, err.message);
      return false;
    }
  }

  static async reconcile(tasks: Task[], context: common.Context, onChanged: () => void): Promise<void> {
    const bundleName: string = bundleManager.getBundleInfoForSelfSync(0).name;
    let changed: boolean = false;
    ReminderCoordinator.lastError = '';
    ReminderCoordinator.lastErrorCode = 0;
    for (let i = 0; i < tasks.length; i++) {
      const task: Task = tasks[i];
      const want: boolean = ReminderCoordinator.shouldRemind(task);
      const target: number = ReminderService.fireTime(task);

      // 时刻变了（用户改提醒时间/改期）或还没发过 → 撤旧发新
      const needPublish: boolean = want
        && (task.reminderId === undefined || task.reminderAt !== target);
      if (needPublish) {
        if (task.reminderId !== undefined) {
          await ReminderService.cancel(task.reminderId);
          task.reminderId = undefined;
        }
        try {
          task.reminderId = await ReminderService.publish(task, bundleName);
          task.reminderAt = target;
          changed = true;
          ReminderCoordinator.lastError = '';
        } catch (error) {
          const err = error as BusinessError;
          // 配额满：回滚意图；权限/通知未开：保留意图，等用户开启后下一轮对账重试
          if (err.code === 1700002) {
            task.alarm = TaskAlarm.OFF;
          }
          ReminderCoordinator.lastError = ReminderCoordinator.errorText(err.code);
          ReminderCoordinator.lastErrorCode = err.code;
          hilog.warn(DOMAIN, TAG, 'publish failed for task %{public}d: %{public}d',
            task.id, err.code);
          changed = true;
        }
      } else if (!want && task.reminderId !== undefined) {
        await ReminderService.cancel(task.reminderId);
        task.reminderId = undefined;
        task.reminderAt = undefined;
        changed = true;
      }

      // 日历：有明确到期时间就写一条；完成/删除/过期的清掉
      const wantCalendar: boolean = ReminderCoordinator.shouldCalendar(task);
      if (wantCalendar && task.calendarEventId === undefined) {
        try {
          task.calendarEventId = await CalendarService.addEvent(context, task);
          changed = true;
        } catch (error) {
          const err = error as BusinessError;
          hilog.warn(DOMAIN, TAG, 'calendar add failed for task %{public}d: %{public}d',
            task.id, err.code);
        }
      } else if (!wantCalendar && task.calendarEventId !== undefined) {
        await CalendarService.deleteEvent(context, task.calendarEventId);
        task.calendarEventId = undefined;
        changed = true;
      }
    }
    if (changed) {
      onChanged();
    }
  }

  /** 任务被移出列表（批量删除）时，立即撤销系统句柄 —— 对账器看不到它了。 */
  static async cancelNow(task: Task, context: common.Context): Promise<void> {
    if (task.reminderId !== undefined) {
      await ReminderService.cancel(task.reminderId);
      task.reminderId = undefined;
    }
    if (task.calendarEventId !== undefined) {
      await CalendarService.deleteEvent(context, task.calendarEventId);
      task.calendarEventId = undefined;
    }
  }

  /** 需要响铃：开关开着、状态还在进行、且触发时刻还没过去 */
  private static shouldRemind(task: Task): boolean {
    if (task.alarm !== TaskAlarm.ON) {
      return false;
    }
    if (task.status !== TaskStatus.CONFIRMED && task.status !== TaskStatus.IN_PROGRESS) {
      return false;
    }
    const at: number = ReminderService.fireTime(task);
    return at > Date.now();
  }

  /** 需要写日历：有到期时间、状态仍有效 */
  private static shouldCalendar(task: Task): boolean {
    if (task.dueAt === undefined || task.dueAt <= 0) {
      return false;
    }
    return task.status === TaskStatus.CONFIRMED || task.status === TaskStatus.IN_PROGRESS;
  }

  private static errorText(code: number): string {
    if (code === 1700002) {
      return '提醒数量已达上限，请完成或删除一些任务';
    }
    return '提醒发布失败，请在系统设置里检查通知权限';
  }
}
