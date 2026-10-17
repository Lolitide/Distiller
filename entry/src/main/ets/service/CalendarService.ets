/**
 * 日历服务：把一条待办**一键写进系统日历**（Calendar Kit）。
 *
 * 做法：申请 READ/WRITE_CALENDAR → 取**默认日历账户**（`getCalendar()`，不用自己建账户）
 * → `addEvent()` 创建日程。写进去之后系统日历会按它自己的提醒设置提醒。
 *
 * 注意：时间用后端归一化过的 `time.normalized`（形如 `2026-10-16 14:00`），
 * 解析不出时间就**不写**（宁可不写，也不写一条没有时间的日程）。
 */

import { abilityAccessCtrl, common, Permissions, PermissionRequestResult } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CampusEvent } from '../nlp/EventTypes';

const DOMAIN: number = 0x0000;
const TAG: string = 'CalendarService';
const CAL_PERMISSIONS: Permissions[] =
  ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
/** 日程默认时长：1 小时（后端只给「开始时间」，没有结束时间） */
const DEFAULT_DURATION_MS: number = 60 * 60 * 1000;
/** 默认时刻：只有日期没有时刻时，落到当天 9:00 */
const DEFAULT_HOUR: number = 9;

export interface CalendarResult {
  ok: boolean;
  message: string;
}

export class CalendarService {
  /**
   * 归一化时间串 → 毫秒时间戳。
   * 认 `2026-10-16`、`2026-10-16 14:00`、`2026-10-16T14:00`；认不出返回 -1。
   */
  static toMillis(normalized: string): number {
    const m: RegExpMatchArray | null =
      normalized.match(/^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}))?/);
    if (m === null) {
      return -1;
    }
    const y: string = m[1] ?? '';
    const mo: string = m[2] ?? '';
    const dd: string = m[3] ?? '';
    const hh: string = m[4] ?? '';
    const mi: string = m[5] ?? '';
    if (y.length === 0 || mo.length === 0 || dd.length === 0) {
      return -1;
    }
    const d: Date = new Date(
      Number(y),
      Number(mo) - 1,
      Number(dd),
      hh.length > 0 ? Number(hh) : DEFAULT_HOUR,
      mi.length > 0 ? Number(mi) : 0,
      0,
      0
    );
    return d.getTime();
  }

  /** 申请日历读写权限（用户授权后返回 true）。 */
  static async ensurePermission(ctx: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const res: PermissionRequestResult = await atManager.requestPermissionsFromUser(ctx, CAL_PERMISSIONS);
      const results: number[] = res.authResults ?? [];
      if (results.length === 0) {
        return false;
      }
      for (let i = 0; i < results.length; i++) {
        if (results[i] !== 0) {
          return false;
        }
      }
      return true;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'request calendar permissions failed: %{public}s', e.message);
      return false;
    }
  }

  /**
   * 把一条待办写进默认日历。返回值直接给 UI 提示用。
   * @param sourceText 消息原文（标题/描述兜底）
   */
  static async writeEvent(ctx: common.UIAbilityContext, ev: CampusEvent,
    sourceText: string): Promise<CalendarResult> {
    const start: number = CalendarService.toMillis(ev.time?.normalized ?? '');
    if (start < 0) {
      return { ok: false, message: '这条待办没有可用的时间，先补上时间再写日历' };
    }
    const granted: boolean = await CalendarService.ensurePermission(ctx);
    if (!granted) {
      return { ok: false, message: '没拿到日历权限：到「设置 → 应用 → 知了 → 权限」里允许「日历」' };
    }
    try {
      const mgr: calendarManager.CalendarManager = calendarManager.getCalendarManager(ctx);
      const cal: calendarManager.Calendar = await mgr.getCalendar();
      const title: string = ev.title.length > 0
        ? ev.title
        : (sourceText.length > 0 ? sourceText : '知了待办');
      const event: calendarManager.Event = {
        title: title,
        type: calendarManager.EventType.NORMAL,
        startTime: start,
        endTime: start + DEFAULT_DURATION_MS
      };
      if (ev.place.length > 0) {
        // Event.location 不是字符串，是 Location 对象（{ location, longitude?, latitude? }）
        const loc: calendarManager.Location = { location: ev.place };
        event.location = loc;
      }
      const desc: string = ev.sourceText.length > 0 ? ev.sourceText : sourceText;
      if (desc.length > 0) {
        event.description = desc;
      }
      const id: number = await cal.addEvent(event);
      hilog.info(DOMAIN, TAG, 'addEvent ok id=%{public}d title=%{public}s', id, title);
      return { ok: true, message: '已写入系统日历（日程 id ' + id + '）' };
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'addEvent failed: code=%{public}d msg=%{public}s', e.code, e.message);
      return { ok: false, message: '写入日历失败：' + e.message };
    }
  }
}
