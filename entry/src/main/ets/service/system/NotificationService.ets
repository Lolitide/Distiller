/**
 * 通知权限（含横幅）引导：
 *  · `requestEnableNotification` 只能弹一次授权框，被拒后要引导到系统设置；
 *  · 横幅开关在系统「通知管理」里，用 `openNotificationSettingsWithResult` 打开。
 *
 * 代理提醒（Reminder Agent）在通知未开启时发布失败，所以这一步要在启动时做一次。
 */
import { common } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'NotificationService';

export class NotificationService {
  /** 首次启动检查；未开启就弹系统授权框。返回最终是否已开启。 */
  static async ensureEnabled(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const enabled: boolean = await notificationManager.isNotificationEnabled();
      if (enabled) {
        return true;
      }
      await notificationManager.requestEnableNotification(context);
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'requestEnableNotification failed: %{public}d %{public}s', err.code, err.message);
      return false;
    }
  }

  /** 打开系统通知管理（可开关横幅/锁屏/声音）；用户关掉授权后从这里引导。 */
  static async openSettings(context: common.UIAbilityContext): Promise<void> {
    try {
      await notificationManager.openNotificationSettingsWithResult(context);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'openNotificationSettings failed: %{public}d %{public}s', err.code, err.message);
    }
  }
}
