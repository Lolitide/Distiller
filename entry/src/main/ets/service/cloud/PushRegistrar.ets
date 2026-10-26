/**
 * service/cloud · PushRegistrar —— 把本机 **Push Token 上报给应用服务器**（FE-76 的后半段）。
 *
 * 链路：`PushTokenService.getToken()`（端侧，Push Kit）→ `RelayApi.pushToken()`
 *       → `POST /api/relay/push/token` → 返回 `{ registered, push_ready }`。
 * 于是验收项里的「后端 `push_ready=true`，可由服务端下发提醒」就有了可观测的证据：
 * `PushStatus.pushReady` + 设置页那一行。
 *
 * 为什么分两步、且错误要分开显示：端侧取不到 token（没开权益 / 没签名 / 模拟器）与
 * 上报失败（没连服务器 / 后端还没准备好）是**完全不同的修法**，混成一句"推送不可用"没法排查。
 *
 * 触发时机：App 启动、且云端同步开着的时候试一次（`A_Main.startBackend`）；
 * 用户在设置页点「重试」也会再走一遍。做成**幂等**：同一台设备重复上报同一个 token 是允许的。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackendConfig } from '../backend/BackendConfig';
import { RelayApi } from '../backend/RelayApi';
import { ApiResult, PushTokenData, apiErrorMessage } from '../backend/BackendTypes';
import { PushTokenResult, PushTokenService } from '../system/PushTokenService';
import { PushStatus } from './PushStatus';
import { SyncService } from './SyncService';

const TAG: string = 'PushRegistrar';

export class PushRegistrar {
  /** 防重入：启动与"重试"可能同时进来 */
  private static running: boolean = false;

  /**
   * 取 token 并上报一次。
   *
   * @returns 是否走到「服务端可下发」（`push_ready=true`）
   */
  static async register(): Promise<boolean> {
    const status: PushStatus = PushStatus.instance();
    if (PushRegistrar.running) {
      return status.pushReady;
    }
    PushRegistrar.running = true;
    try {
      // ① 没有服务器地址 → 连上报的地址都没有，直接标"未启用"
      if (BackendConfig.baseUrl.length === 0) {
        status.unavailable('未配置服务器地址');
        return false;
      }
      // ② **先取端侧 token**（不需要网络）：这一步失败是"产品前置条件"问题
      //    （AGC 没开推送权益 / 没重签 / 模拟器不支持），比"连不上服务器"更值得先说清楚
      const tokenRes: PushTokenResult = await PushTokenService.getToken();
      if (!tokenRes.ok) {
        status.failed(tokenRes.message, tokenRes.advice);
        return false;
      }
      // ③ 设备身份：/push/token 需要鉴权，没身份就先注册一个（复用同步那条链路，不另造）
      const hasIdentity: boolean = await SyncService.ensureDevice();
      if (!hasIdentity) {
        status.failed('设备身份未就绪（连不上服务器？）');
        return false;
      }
      // ④ 上报
      const res: ApiResult<PushTokenData> = await RelayApi.pushToken(tokenRes.token);
      if (!res.ok || res.data === undefined) {
        status.failed('上报失败：' + apiErrorMessage(res));
        return false;
      }
      if (res.data.push_ready) {
        status.ready(tokenRes.token, res.data.registered);
        return true;
      }
      status.registeredOnly(tokenRes.token, res.data.registered);
      return false;
    } catch (error) {
      hilog.warn(0x0000, TAG, 'register failed: %{public}s', String(error));
      status.failed('上报异常，稍后重试');
      return false;
    } finally {
      PushRegistrar.running = false;
    }
  }
}
