/**
 * 采纳 / 忽略回传：把用户对候选的判断交给后端（只记计数，不传正文）。
 *
 * 后端 `/feedback` 需要 `candidate_id + group_openid + kind`；
 * 本机任务里 `candidate_id` = `clientTaskId`，群号与 kind 从候选原始 JSON（`rawJson`）里取。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RelayApi } from '../backend/RelayApi';
import { Task } from '../../model';

const DOMAIN: number = 0x0000;
const TAG: string = 'FeedbackService';

interface RawFeedbackSource {
  group_openid?: string;
}

interface RawFeedbackCandidate {
  kind?: string;
  source?: RawFeedbackSource;
}

export class FeedbackService {
  /** action: accept / dismiss；失败只记日志，不影响本地任务操作。 */
  static async send(task: Task, action: string): Promise<boolean> {
    const candidateId: string = task.clientTaskId !== undefined ? task.clientTaskId : '';
    if (candidateId.length === 0) {
      return false;
    }
    let kind: string = '';
    let groupOpenid: string = '';
    const raw: string = task.rawJson !== undefined ? task.rawJson : '';
    if (raw.length > 0) {
      try {
        const parsed: RawFeedbackCandidate = JSON.parse(raw) as RawFeedbackCandidate;
        kind = parsed.kind !== undefined ? parsed.kind : '';
        if (parsed.source !== undefined && parsed.source.group_openid !== undefined) {
          groupOpenid = parsed.source.group_openid;
        }
      } catch (error) {
        // rawJson 不是候选对象（手动任务）→ 不发反馈
        return false;
      }
    }
    try {
      const res = await RelayApi.feedback({
        candidate_id: candidateId,
        action: action,
        group_openid: groupOpenid,
        kind: kind
      });
      return res.ok;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'feedback failed: %{public}d %{public}s', err.code, err.message);
      return false;
    }
  }
}
