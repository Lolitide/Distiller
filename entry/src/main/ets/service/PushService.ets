/**
 * 知了 · Push Kit 接入（**后台通知的唯一通路**）
 *
 * 为什么需要它：HarmonyOS 不允许普通应用在后台长跑轮询（依据见
 * `方案与约定/06_后端能力与AI-Kit分工.md` §7），所以「App 在后台/被杀时也能
 * 收到提醒」只能靠云侧推送：后端 → 华为 Push 网关 → 设备。
 *
 * 客户端只做三件事：
 *   1. `receiveMessage(...)` 注册接收——必须在 `onCreate` 里、**任何 await 之前**
 *      调用（官方要求，否则可能影响消息接收）；
 *   2. `getToken()` 拿本机 Push Token，上报后端；
 *   3. `on('tokenUpdate')` 监听 Token 变更并重新上报
 *      （重装、清数据、跨地区都会让 Token 变）。
 *
 * 失败一律静默：没有推送时 App 在前台仍然完全可用，只是后台收不到通知。
 */

import { pushService } from '@kit.PushKit';
import { UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { PushTokenData } from '../common/Types';

const DOMAIN: number = 0x0000;
const TAG: string = 'PushService';

export class PushService {
  private static listening: boolean = false;
  /** 已经成功上报过的 token（避免每次进前台都重复 POST） */
  private static reported: string = '';

  /**
   * 注册接收 + Token 变更监听。**必须同步调用**（不要放在 await 之后）。
   * 参数是 **UIAbility 实例**（`pushService` 要它做消息分发），不是 Context。
   * 重复调用安全。
   */
  static listen(ability: UIAbility): void {
    if (PushService.listening) {
      return;
    }
    PushService.listening = true;
    try {
      pushService.receiveMessage('DEFAULT', ability, () => {
        // App 在前台收到推送：把列表刷一下即可（后台时系统自己弹通知）
        AppStorage.setOrCreate<number>('msgVersion',
          (AppStorage.get<number>('msgVersion') ?? 0) + 1);
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'receiveMessage failed');
    }
    try {
      pushService.on('tokenUpdate', ability, (token: string) => {
        PushService.reported = '';
        PushService.report(token);
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'on(tokenUpdate) failed');
    }
  }

  /** 取 Token 并上报（进前台时调一次即可；没有设备身份时跳过）。 */
  static async register(): Promise<void> {
    if (!Store.hasIdentity()) {
      return;
    }
    try {
      const token: string = await pushService.getToken();
      if (token.length > 0 && token !== PushService.reported) {
        await PushService.report(token);
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'getToken failed');
    }
  }

  /** 注销（换绑/清空本机数据时调，避免旧设备继续收推送）。 */
  static async unregister(): Promise<void> {
    PushService.reported = '';
    await PushService.report('');
  }

  private static async report(token: string): Promise<void> {
    if (!Store.hasIdentity()) {
      return;
    }
    const body: Record<string, Object> = { 'token': token };
    const res = await ApiClient.post<PushTokenData>('/api/relay/push/token', body);
    if (res.ok) {
      PushService.reported = token;
    }
    hilog.info(DOMAIN, TAG, 'report token ok=%{public}s', String(res.ok));
  }
}
