/**
 * 系统日历（Calendar Kit）：把任务写成「知了」日历账户下的日程，作为代理提醒的兜底。
 *
 * 只做三件事：建应用专属账户、写一条日程、删一条日程。
 * 失败不阻断任务保存 —— 提醒仍由代理提醒负责，日历只是多一层可见性。
 */
import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';
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
      await manager.requestPermissionsFromUser(context,
        ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR']);
      // 不能只看 request 的 authResults（有些系统版本已授权时返回空数组，会被误判成功）：
      // 再向令牌服务逐个确认，设置页读到的必须是同一份真实状态。
      const info = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT | bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const tokenId: number = info.appInfo.accessTokenId;
      const readStatus: abilityAccessCtrl.GrantStatus =
        await manager.checkAccessToken(tokenId, 'ohos.permission.READ_CALENDAR');
      const writeStatus: abilityAccessCtrl.GrantStatus =
        await manager.checkAccessToken(tokenId, 'ohos.permission.WRITE_CALENDAR');
      hilog.info(DOMAIN, TAG, 'calendar grant read=%{public}d write=%{public}d', readStatus, writeStatus);
      if (readStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        || writeStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.warn(DOMAIN, TAG, 'calendar permission not granted');
        return false;
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
    const manager: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
    const calendar: calendarManager.Calendar = await CalendarService.ensureCalendar(manager);
    const id: number = await calendar.addEvent(CalendarService.buildEvent(task));
    hilog.info(DOMAIN, TAG, 'calendar event %{public}d added for task %{public}d', id, task.id);
    return id;
  }

  /** 更新已有日程：任务改名 / 改期 / 改备注 / 改提前量后调用，避免日历里留下旧内容。 */
  static async updateEvent(context: common.Context, task: Task, eventId: number): Promise<void> {
    const manager: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
    const calendar: calendarManager.Calendar = await CalendarService.ensureCalendar(manager);
    const event: calendarManager.Event = CalendarService.buildEvent(task);
    event.id = eventId;
    await calendar.updateEvent(event);
    hilog.info(DOMAIN, TAG, 'calendar event %{public}d updated for task %{public}d', eventId, task.id);
  }

  private static buildEvent(task: Task): calendarManager.Event {
    const start: number = CalendarService.startTime(task);
    if (start <= 0) {
      throw new Error('缺少到期时间');
    }
    const event: calendarManager.Event = {
      title: task.name,
      type: calendarManager.EventType.NORMAL,
      startTime: start,
      endTime: start + EVENT_MINUTES * 60 * 1000,
      description: task.note !== undefined ? task.note : ''
    };
    // 日历提醒提前量：按「写入日历那一刻离 DDL 还有多久」分档，
    // 和 App 里的软件提醒（用户设置的提醒时间）是两套独立机制。
    const lead: number = CalendarService.autoLeadMinutes(task);
    if (lead >= 0) {
      event.reminderTime = [lead];
    }
    return event;
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

  /**
   * 日历提醒提前量（分钟）：以**写入日历的那一刻**到 DDL 的剩余时间分档。
   *   剩余 < 6h             → 不提醒（返回 -1）
   *   6h ≤ 剩余 < 12h        → 提前 2h
   *   12h ≤ 剩余 < 36h      → 提前 6h
   *   36h ≤ 剩余 < 3 天      → 提前 12h
   *   3 天 ≤ 剩余 < 7 天     → 提前 1 天
   *   7 天 ≤ 剩余 < 14 天    → 提前 3 天
   *   14 天 ≤ 剩余 < 40 天   → 提前 7 天
   *   其余（≥ 40 天）        → 提前 14 天
   *
   * 提前量不会超过剩余时间（否则提醒点会落在过去、日历不会响）；
   * 已经过期的任务不写提醒（返回 -1）。
   */
  private static autoLeadMinutes(task: Task): number {
    if (task.dueAt === undefined || task.dueAt <= 0) {
      return -1;
    }
    const now: number = Date.now();
    const remainingMs: number = task.dueAt - now;
    if (remainingMs <= 0) {
      return -1;
    }
    const hour: number = 60 * 60 * 1000;
    const day: number = 24 * hour;
    // 离 DDL 不足 6 小时：时间太紧，系统日历不再提醒（软件提醒仍按用户设置执行）
    if (remainingMs < 6 * hour) {
      return -1;
    }
    let leadMs: number;
    if (remainingMs < 12 * hour) {
      leadMs = 2 * hour;
    } else if (remainingMs < 36 * hour) {
      leadMs = 6 * hour;
    } else if (remainingMs < 3 * day) {
      leadMs = 12 * hour;
    } else if (remainingMs < 7 * day) {
      leadMs = 1 * day;
    } else if (remainingMs < 14 * day) {
      leadMs = 3 * day;
    } else if (remainingMs < 40 * day) {
      leadMs = 7 * day;
    } else {
      leadMs = 14 * day;
    }
    // 不超过剩余时间，避免提醒落在过去
    const lead: number = Math.round(Math.min(leadMs, remainingMs) / 60000);
    return Math.max(0, lead);
  }
}
