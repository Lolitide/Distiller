/**
 * 知了 · 候选反馈回传（契约 §2.3：POST /api/relay/feedback）。
 *
 * 后端只记 accept/dismiss 计数、不存任何内容（relay.FeedbackStore，纯内存）。
 * App 侧原则：
 *   1. 本地动作（转待办/忽略）先行，反馈异步回传——失败不阻塞本地体验、不打扰重试；
 *   2. 只在后端 /health 的 capabilities 含 "feedback" 时才发（能力协商，05 文档 §2.4）；
 *   3. 老后端 / 探测失败 → 静默跳过，功能降级但不出错。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { FeedbackBody, FeedbackData, HealthData, RobotMessage } from '../common/Types';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedbackService';
/** /health 能力探测结果的缓存时长（毫秒），避免每次反馈都打一遍 health */
const CAP_TTL_MS: number = 300000;

export const ACTION_ACCEPT: string = 'accept';
export const ACTION_DISMISS: string = 'dismiss';

export class FeedbackService {
  /** 最近一次 /health 拿到的 capabilities（null = 还没探测过） */
  private static caps: string[] | null = null;
  private static capsAt: number = 0;

  /** 后端是否声明支持 /feedback；结果按 CAP_TTL_MS 缓存。 */
  static async canFeedback(): Promise<boolean> {
    const nowMs: number = Date.now();
    if (FeedbackService.caps !== null && nowMs - FeedbackService.capsAt < CAP_TTL_MS) {
      return FeedbackService.caps.indexOf('feedback') >= 0;
    }
    const res = await ApiClient.get<HealthData>('/api/relay/health');
    if (res.ok && res.data !== undefined) {
      FeedbackService.caps = res.data.capabilities ?? [];
    } else if (FeedbackService.caps === null) {
      // 探测失败且没有历史缓存：视为不支持，静默降级
      FeedbackService.caps = [];
    }
    FeedbackService.capsAt = nowMs;
    return FeedbackService.caps.indexOf('feedback') >= 0;
  }

  /**
   * 回传一次用户动作（accept/dismiss）。本地 UI 不必等待结果：
   * 返回值只用于日志/调试，false 不代表本地动作失败。
   */
  static async send(msg: RobotMessage, action: string, editedFields: string[] = []): Promise<boolean> {
    if (!Store.hasIdentity()) {
      return false;
    }
    const allowed: boolean = await FeedbackService.canFeedback();
    if (!allowed) {
      hilog.info(DOMAIN, TAG, 'feedback skipped: capability not advertised');
      return false;
    }
    const body: FeedbackBody = {
      candidate_id: msg.msg_id,
      action: action,
      group_openid: msg.group_openid,
      kind: msg.event?.kind ?? msg.category ?? '',
      edited_fields: editedFields
    };
    const res = await ApiClient.post<FeedbackData>('/api/relay/feedback', body);
    if (res.ok) {
      hilog.info(DOMAIN, TAG, 'feedback sent: %{public}s %{public}s', action, msg.msg_id);
      return true;
    }
    hilog.warn(DOMAIN, TAG, 'feedback failed: %{public}s', res.error?.message ?? 'unknown');
    return false;
  }
}
