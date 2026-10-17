import { notificationManager } from '@kit.NotificationKit';
import { Config } from '../common/Config';
import { ApiClient } from '../common/ApiClient';
import { Store } from '../common/Store';
import { ParseService } from '../common/ParseService';
import { AttachmentStore } from '../common/AttachmentStore';
import { MessagesData, RobotMessage, toRobotMessages } from '../common/Types';
import { CampusEvent, isActionable } from '../nlp/EventTypes';
import { NotificationService } from './NotificationService';

const NET_FAIL_THRESHOLD: number = 3;

export class PollService {
  private static timerId: number = -1;
  private static running: boolean = false;
  private static netFailCount: number = 0;
  /** 本轮新合并进来的消息（通知「新待办」用） */
  private static lastMerged: RobotMessage[] = [];
  /**
   * 「新到但还没解析出 event」的消息 id。
   * 解析是异步的且可能正忙（parsePending 有 busy 保护），所以一个 id 可能要跨几轮
   * 才能等到 event；留在这里下一轮再试，避免"这一轮没解析完就永远不通知"。
   */
  private static awaiting: string[] = [];
  /** 已经弹过通知的 msg_id（内存态，重启后靠 awaiting 为空天然不补发） */
  private static notified: Set<string> = new Set<string>();
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
    // 每轮都跑：awaiting 里可能有上一轮「还没解析出来」的待办，要接着重试
    const fired: number = await PollService.notifyTodos();
    if (added > 0 && fired === 0) {
      PollService.notifyNew(added);
    }
    return added;
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
    PollService.lastMerged = merged;
    Store.setMaxSeq(data.max_seq);
    // 后台异步解析新消息（端侧 NL Kit），不阻塞本轮轮询
    ParseService.parsePending();
    // 附件**必须**趁 30 分钟窗口还在时落盘：窗口一过后端就 404，图片/文件都找不回。
    // 同样是后台异步 + 每拍限流，绝不阻塞轮询。
    AttachmentStore.enqueue(merged);
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

  /**
   * 把「新到的待办」弹到通知栏（点击直达详情）。
   *
   * 事件对象是端侧异步解析出来的，所以：
   *   1. 先把本轮新消息记进 `awaiting`，再等一次解析；
   *   2. 能弹的弹掉、`awaiting` 里剩下的留到下一轮再试（消息本身还在本地，不丢）。
   * @returns 本轮弹出去的条数；0 表示没有待办，调用方退回「收到 N 条新消息」
   */
  private static async notifyTodos(): Promise<number> {
    for (let i = 0; i < PollService.lastMerged.length; i++) {
      const id: string = PollService.lastMerged[i].msg_id;
      if (PollService.notified.has(id) || PollService.awaiting.indexOf(id) >= 0) {
        continue;
      }
      PollService.awaiting.push(id);
    }
    if (PollService.awaiting.length === 0) {
      return 0;
    }
    await ParseService.parsePending();

    let fired: number = 0;
    const keep: string[] = [];
    for (let j = 0; j < PollService.awaiting.length; j++) {
      const msgId: string = PollService.awaiting[j];
      const fresh: RobotMessage | undefined = PollService.freshById(msgId);
      if (fresh === undefined) {
        continue; // 消息被清掉了，不再等
      }
      const ev: CampusEvent | undefined = fresh.event;
      if (ev === undefined) {
        keep.push(msgId); // 还没解析出来，下一轮再试
        continue;
      }
      PollService.notified.add(msgId);
      if (!isActionable(ev.kind)) {
        continue; // 闲聊/忽略：不弹，也不再等
      }
      const title: string = ev.title.length > 0 ? ev.title : '新待办';
      const src: string = ev.sourceText.length > 0 ? ev.sourceText : fresh.content;
      await NotificationService.notifyTodo(msgId, '待办 · ' + title, src);
      fired++;
    }
    PollService.awaiting = keep;
    return fired;
  }

  /** 重新读存储里的这条消息——merged 里那份是**解析前**的，没有 event。 */
  private static freshById(msgId: string): RobotMessage | undefined {
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        return list[i];
      }
    }
    return undefined;
  }

  private static async notifyNew(count: number): Promise<void> {
    AppStorage.setOrCreate<string>('newMsgBanner', '收到 ' + count + ' 条新消息');
    try {
      const req: notificationManager.NotificationRequest = {
        id: 1,
        // 渠道类型必须给：默认渠道不支持横幅（见 NotificationService 里的说明）
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
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
