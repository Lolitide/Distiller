/**
 * 系统日历（Calendar Kit）：把任务写成「知了」日历账户下的日程，作为代理提醒的兜底。
 *
 * 只做三件事：建应用专属账户、写一条日程、删一条日程。
 * 失败不阻断任务保存 —— 提醒仍由代理提醒负责，日历只是多一层可见性。
 */
import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Task } from '../../model';

const DOMAIN: number = 0x0000;
const TAG: string = 'CalendarService';
const ACCOUNT_NAME: string = '知了';
const EVENT_MINUTES: number = 30;

export class CalendarService {
  /** 首次引导里单独申请日历权限；默认不申请，用户点开关才调。 */
  static async ensurePermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const result = await manager.requestPermissionsFromUser(context,
        ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']);
      for (let i = 0; i < result.authResults.length; i++) {
        if (result.authResults[i] !== 0) {
          return false;
        }
      }
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'request calendar permission failed: %{public}d %{public}s',
        err.code, err.message);
      return false;
    }
  }

  private static account: calendarManager.CalendarAccount = {
    name: ACCOUNT_NAME,
    type: calendarManager.CalendarType.LOCAL,
    displayName: ACCOUNT_NAME
  };

  /** 写入日程，返回系统事件 id（调用方回填到 Task.calendarEventId）。 */
  static async addEvent(context: common.Context, task: Task): Promise<number> {
    const start: number = CalendarService.startTime(task);
    if (start <= 0) {
      throw new Error('缺少到期时间');
    }
    const manager: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
    const calendar: calendarManager.Calendar = await CalendarService.ensureCalendar(manager);
    const event: calendarManager.Event = {
      title: task.name,
      type: calendarManager.EventType.NORMAL,
      startTime: start,
      endTime: start + EVENT_MINUTES * 60 * 1000,
      description: task.note !== undefined ? task.note : ''
    };
    // 提前量（分钟）：日历在「到点前 N 分钟」提醒，和 App 的提醒提前量一致
    const lead: number = CalendarService.leadMinutes(task);
    if (lead >= 0) {
      event.reminderTime = [lead];
    }
    const id: number = await calendar.addEvent(event);
    hilog.info(DOMAIN, TAG, 'calendar event %{public}d added for task %{public}d', id, task.id);
    return id;
  }

  /** 删除日程：失败只记日志。 */
  static async deleteEvent(context: common.Context, eventId: number): Promise<void> {
    try {
      const manager: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
      const calendar: calendarManager.Calendar = await CalendarService.ensureCalendar(manager);
      await calendar.deleteEvent(eventId);
      hilog.info(DOMAIN, TAG, 'calendar event %{public}d deleted', eventId);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'deleteEvent %{public}d failed: %{public}d %{public}s',
        eventId, err.code, err.message);
    }
  }

  private static async ensureCalendar(manager: calendarManager.CalendarManager): Promise<calendarManager.Calendar> {
    try {
      return await manager.getCalendar(CalendarService.account);
    } catch (error) {
      return await manager.createCalendar(CalendarService.account);
    }
  }

  /** 日程起点：到期时刻（日程本身）；提前量放在 reminderTime 里 */
  private static startTime(task: Task): number {
    return task.dueAt !== undefined ? task.dueAt : 0;
  }

  /** 提前量（分钟）：remindAt 比 dueAt 早多少；提前量已过就 0（到点提醒） */
  private static leadMinutes(task: Task): number {
    if (task.dueAt === undefined || task.dueAt <= 0) {
      return -1;
    }
    if (task.remindAt === undefined || task.remindAt <= 0) {
      return 0;
    }
    const base: number = task.remindAt > Date.now() ? task.remindAt : task.dueAt;
    return Math.max(0, Math.round((task.dueAt - base) / 60000));
  }
}
