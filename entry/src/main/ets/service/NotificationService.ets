/**
 * 通知服务：把「新待办」推到通知栏，**点击直达该条消息的详情页**。
 *
 * 为什么必须带 wantAgent：不带的话点击通知只会回到 App 首页（系统拿不到"要看哪条"）。
 * 这里把目标消息的 msg_id 塞进 want 的 parameters，EntryAbility 收到后转成
 * AppStorage('pendingMsgId')，由 HomePage 负责跳转（见 EntryAbility / HomePage）。
 */

import { notificationManager } from '@kit.NotificationKit';
import { common, wantAgent, WantAgent, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'NotificationService';
/** 与 AppScope/app.json5 的 bundleName 一致 */
const BUNDLE_NAME: string = 'com.example.cicada';
const ABILITY_NAME: string = 'EntryAbility';

export class NotificationService {
  /** 本进程内是否已经问过一次（requestEnableNotification 非首次不会弹窗） */
  private static asked: boolean = false;

  /** 当前是否已授权（查询失败按未授权处理）。 */
  static async isEnabled(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'isNotificationEnabled failed: %{public}s', e.message);
      return false;
    }
  }

  /**
   * **显式申请**（用户点了「去开启 ›」）：不受 `asked` 限制，每次都真的去调。
   *
   * 为什么必须绕过 `asked`：`asked` 是「本进程自动问过一次」的防打扰开关，
   * 而自动那次是在 App 启动早期调的（UI 可能还没就绪，弹不出来），
   * 用它挡住**用户主动点击**就会变成"点了一点反应都没有、只跳系统设置"。
   *
   * 平台限制仍在：**用户拒过一次后这个接口不再弹窗**，这时返回 false，
   * 由调用方退到 `openSettings()`。
   */
  static async request(ctx: common.UIAbilityContext): Promise<boolean> {
    if (await NotificationService.isEnabled()) {
      return true;
    }
    try {
      await notificationManager.requestEnableNotification(ctx);
      hilog.info(DOMAIN, TAG, 'requestEnableNotification done (explicit)');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      if (e.code === 1600004) {
        hilog.warn(DOMAIN, TAG, 'user refused notification (1600004)');
      } else {
        hilog.warn(DOMAIN, TAG, 'requestEnableNotification failed: code=%{public}d msg=%{public}s',
          e.code, e.message);
      }
    }
    return await NotificationService.isEnabled();
  }

  /**
   * 自动申请（进首页时试一次）：先查再申请，**本次进程只问一次**。
   *
   * 三个必须知道的机制（`开发指南 · 请求通知授权`）：
   *   1. `requestEnableNotification` **只在首次**弹窗；之后再调，无论有没有权限都直接成功；
   *   2. **用户拒绝过一次后，这个接口再也弹不出来** → 补救只能用 `openSettings()`；
   *   3. 用户拒绝时抛错误码 **1600004**。
   */
  static async ensureEnabled(ctx: common.UIAbilityContext): Promise<boolean> {
    if (await NotificationService.isEnabled()) {
      return true;
    }
    if (NotificationService.asked) {
      return false; // 本次进程已经自动问过，别重复打扰
    }
    NotificationService.asked = true;
    return await NotificationService.request(ctx);
  }

  /**
   * 被拒之后的补救入口：拉起**通知管理弹窗**让用户自己打开，返回最终授权状态。
   * （拒过一次后 requestEnableNotification 不再弹，这条是唯一正路。）
   */
  static async openSettings(ctx: common.UIAbilityContext): Promise<boolean> {
    try {
      await notificationManager.openNotificationSettingsWithResult(ctx);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'openNotificationSettings failed: %{public}s', e.message);
    }
    return await NotificationService.isEnabled();
  }

  /**
   * 弹一条「新待办」通知。
   * @param msgId 目标消息 id（点击后跳它的详情页）
   * @param title 通知标题
   * @param text  通知正文
   */
  static async notifyTodo(msgId: string, title: string, text: string): Promise<void> {
    try {
      const params: Record<string, Object> = { 'msgId': msgId };
      const want: Want = {
        bundleName: BUNDLE_NAME,
        abilityName: ABILITY_NAME,
        parameters: params
      };
      const info: wantAgent.WantAgentInfo = {
        wants: [want],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: NotificationService.idOf(msgId),
        actionFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
      };
      const agent: WantAgent = await wantAgent.getWantAgent(info);
      const req: notificationManager.NotificationRequest = {
        id: NotificationService.idOf(msgId),
        // 必须指定渠道类型！官方文档：默认渠道**不支持横幅**，只有
        // SOCIAL_COMMUNICATION / SERVICE_INFORMATION 才会弹横幅。
        // 待办属于「服务提醒」，用 SERVICE_INFORMATION（渠道不存在会自动创建）。
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: text,
            additionalText: ''
          }
        },
        wantAgent: agent
      };
      await notificationManager.publish(req);
      hilog.info(DOMAIN, TAG, 'published todo notification msgId=%{public}s', msgId);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'publish failed: code=%{public}d msg=%{public}s', e.code, e.message);
    }
  }

  /** 用 msgId 派生稳定的通知 id：同一条待办重复通知会覆盖，不刷屏。 */
  private static idOf(msgId: string): number {
    let h: number = 0;
    for (let i = 0; i < msgId.length; i++) {
      h = (h * 31 + msgId.charCodeAt(i)) % 100000;
    }
    return h + 1000;
  }
}
