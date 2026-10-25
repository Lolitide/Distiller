/**
 * 系统分享接收入口。
 *
 * 数据流：系统分享面板 → EntryAbility.onCreate/onNewWant → `systemShare.getSharedData(want)`
 * → 暂存到本类 → `A_Main` 监听并打开「添加任务」确认面。
 *
 * 规则：
 *  · 一次只取一条：优先图片，其次文本（系统不允许文本与文件混发）；
 *  · 后一次分享覆盖前一次尚未确认的草稿（与半模态的草稿语义一致）；
 *  · 解析失败只记录文案，由页面 toast，不在 Ability 层弹 UI。
 */
import { Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'ShareIntake';

export const SHARE_KIND_TEXT: string = 'text';
export const SHARE_KIND_IMAGE: string = 'image';

export class SharePayload {
  kind: string = SHARE_KIND_TEXT;
  text: string = '';
  uri: string = '';
  title: string = '';
}

export class ShareIntake {
  private static pending: SharePayload | undefined = undefined;
  private static listener: ((payload: SharePayload) => void) | undefined = undefined;
  private static lastError: string = '';

  static setListener(listener: (payload: SharePayload) => void): void {
    ShareIntake.listener = listener;
  }

  static clearListener(): void {
    ShareIntake.listener = undefined;
  }

  /** 冷启动时页面还没注册监听：先取走暂存值。 */
  static consumePending(): SharePayload | undefined {
    const payload: SharePayload | undefined = ShareIntake.pending;
    ShareIntake.pending = undefined;
    return payload;
  }

  static consumeError(): string {
    const message: string = ShareIntake.lastError;
    ShareIntake.lastError = '';
    return message;
  }

  /** 只处理系统分享（普通桌面启动的 want 不带 sendData，避免误报解析失败）。 */
  static async handleWant(want: Want): Promise<void> {
    if (want.action !== 'ohos.want.action.sendData') {
      return;
    }
    try {
      const data: systemShare.SharedData = await systemShare.getSharedData(want);
      const records: systemShare.SharedRecord[] = data.getRecords();
      let payload: SharePayload | undefined = undefined;
      for (let i = 0; i < records.length; i++) {
        const record: systemShare.SharedRecord = records[i];
        if (record.uri !== undefined && record.uri.length > 0 && record.utd.indexOf('image') >= 0) {
          const image: SharePayload = new SharePayload();
          image.kind = SHARE_KIND_IMAGE;
          image.uri = record.uri;
          image.title = record.title !== undefined ? record.title : '';
          payload = image;
          break;
        }
      }
      if (payload === undefined) {
        for (let i = 0; i < records.length; i++) {
          const record: systemShare.SharedRecord = records[i];
          if (record.content !== undefined && record.content.trim().length > 0) {
            const text: SharePayload = new SharePayload();
            text.kind = SHARE_KIND_TEXT;
            text.text = record.content;
            text.title = record.title !== undefined ? record.title : '';
            payload = text;
            break;
          }
        }
      }
      if (payload === undefined) {
        ShareIntake.lastError = '这条分享里没有可识别的内容';
        return;
      }
      ShareIntake.deliver(payload);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'getSharedData failed: %{public}d %{public}s', err.code, err.message);
      ShareIntake.lastError = '没读到分享内容，请重试或手动新建';
    }
  }

  private static deliver(payload: SharePayload): void {
    const listener: ((payload: SharePayload) => void) | undefined = ShareIntake.listener;
    if (listener === undefined) {
      ShareIntake.pending = payload;
      return;
    }
    // 已注册监听就立即消费，避免页面紧接着 consumePending 时重复打开。
    ShareIntake.pending = undefined;
    listener(payload);
  }
}
