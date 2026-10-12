import { notificationManager } from '@kit.NotificationKit';
import { Config } from '../common/Config';
import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { Discovery } from '../common/Discovery';
import { MessagesData, RobotMessage, toRobotMessages } from '../common/Types';

const NET_FAIL_THRESHOLD: number = 3;
const REDISCOVER_COOLDOWN_MS: number = 30000;

export class PollService {
  private static timerId: number = -1;
  private static running: boolean = false;
  private static netFailCount: number = 0;
  private static discovering: boolean = false;
  private static lastDiscoveryAt: number = 0;
  static lastSyncAt: string = '';
  static lastError: string = '';

  static start(): void {
    PollService.stop();
    const hasSubs: boolean = Store.getSubs().length > 0;
    const interval: number = hasSubs ? Config.pollIntervalMs : Config.idlePollIntervalMs;
    PollService.timerId = setInterval(() => {
      PollService.tick();
    }, interval);
    PollService.tick();
  }

  static stop(): void {
    if (PollService.timerId >= 0) {
      clearInterval(PollService.timerId);
      PollService.timerId = -1;
    }
  }

  private static async tick(): Promise<void> {
    if (PollService.running) {
      return;
    }
    if (!Store.hasIdentity()) {
      return;
    }
    PollService.running = true;
    try {
      await PollService.sync();
      PollService.lastError = '';
    } catch (e) {
      PollService.lastError = '连接中断，正在重试';
    } finally {
      PollService.running = false;
    }
  }

  static async sync(): Promise<number> {
    if (!Store.hasIdentity()) {
      return 0;
    }
    const after: number = Store.getMaxSeq();
    const res = await ApiClient.get<MessagesData>('/api/relay/messages?after=' + after + '&limit=200');
    if (!res.ok) {
      const code: string = res.error?.code ?? '';
      if (code === 'unauthorized') {
        Store.clearIdentity();
        AppStorage.setOrCreate<boolean>('needOnboarding', true);
      }
      if (code === 'network') {
        PollService.netFailCount++;
        PollService.maybeRediscover();
      } else {
        PollService.netFailCount = 0;
      }
      throw new Error(res.error?.message ?? '拉取消息失败');
    }
    PollService.netFailCount = 0;
    const data: MessagesData = res.data ?? { messages: [], max_seq: after, server_time: '', window_minutes: 30, subscribed_groups: 0 };
    const added: number = PollService.merge(data);
    PollService.lastSyncAt = new Date().toTimeString().substring(0, 8);
    AppStorage.setOrCreate<number>('msgVersion', (AppStorage.get<number>('msgVersion') ?? 0) + 1);
    if (added > 0) {
      PollService.notifyNew(added);
    }
    return added;
  }

  private static maybeRediscover(): void {
    if (PollService.netFailCount < NET_FAIL_THRESHOLD) {
      return;
    }
    if (PollService.discovering) {
      return;
    }
    const now: number = Date.now();
    if (now - PollService.lastDiscoveryAt < REDISCOVER_COOLDOWN_MS) {
      return;
    }
    PollService.discovering = true;
    PollService.lastDiscoveryAt = now;
    PollService.rediscover();
  }

  private static async rediscover(): Promise<void> {
    try {
      const found: string = await Discovery.autoFind();
      if (found.length > 0 && found !== Config.baseUrl) {
        Store.setBaseUrl(found);
        PollService.lastError = '';
      }
    } catch (e) {
      // 发现失败，保持原地址继续重试
    } finally {
      PollService.discovering = false;
    }
  }

  private static merge(data: MessagesData): number {
    const existing: RobotMessage[] = Store.getMessages();
    const existingIds: string[] = [];
    for (let i = 0; i < existing.length; i++) {
      existingIds.push(existing[i].msg_id);
    }
    const remote: RobotMessage[] = toRobotMessages(data.messages);
    const merged: RobotMessage[] = [];
    for (let j = 0; j < remote.length; j++) {
      const m: RobotMessage = remote[j];
      if (existingIds.indexOf(m.msg_id) < 0) {
        merged.push(m);
      }
    }
    if (merged.length > 0) {
      const combined: RobotMessage[] = merged.concat(existing);
      let finalList: RobotMessage[] = combined;
      if (combined.length > 500) {
        finalList = combined.slice(0, 500);
      }
      Store.saveMessages(finalList);
    }
    Store.setMaxSeq(data.max_seq);
    return PollService.notifiableCount(merged);
  }

  /** 计入「收到 N 条新消息」提示的条数：隐藏开关打开时，自己发的消息不提醒。 */
  private static notifiableCount(list: RobotMessage[]): number {
    if (!Store.getHideSelf()) {
      return list.length;
    }
    let n = 0;
    for (let i = 0; i < list.length; i++) {
      if (list[i].is_self !== true) {
        n++;
      }
    }
    return n;
  }

  private static async notifyNew(count: number): Promise<void> {
    AppStorage.setOrCreate<string>('newMsgBanner', '收到 ' + count + ' 条新消息');
    try {
      const req: notificationManager.NotificationRequest = {
        id: 1,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: { title: '知了', text: '收到 ' + count + ' 条新消息', additionalText: '' }
        }
      };
      await notificationManager.publish(req);
    } catch (e) {
      console.error('通知失败，降级为页面内提示');
    }
  }
}
