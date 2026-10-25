/**
 * 云同步：把后端候选拉成本机任务（**唯一能碰后端的运行期入口**）。
 *
 * 数据流：
 *   `GET /candidates?after=cursor` → 候选（簇级、已去重）
 *   → `GET /messages?after=0` 取窗口内原文（`source.msg_ids` 对回去，写进 `Task.rawText`）
 *   → `TaskListStore.upsertAll()`（按 `clientTaskId` 幂等）
 *   → `TaskRepository.save()`
 *
 * 隐私：原文只在「本机任务」里保留；候选与原文都**不会**再回传后端。
 */
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackendConfig } from '../backend/BackendConfig';
import { RelayApi } from '../backend/RelayApi';
import { candidateToTask } from '../backend/TaskMapper';
import { CandidateItem, ServeMessage, apiErrorMessage } from '../backend/BackendTypes';
import { TaskRepository } from '../../repository/TaskRepository';
import { TaskListStore } from '../../viewmodel/TaskListStore';
import { TaskExpiryService } from '../system/TaskExpiryService';
import { Task } from '../../model';
import { SyncStatus } from './SyncStatus';

const DOMAIN: number = 0x0000;
const TAG: string = 'SyncService';
const POLL_INTERVAL_MS: number = 5000;
/** 每 5 分钟检查一次群订阅（用户可能在 QQ 里新加了群） */
const SUB_CHECK_INTERVAL_MS: number = 300000;

export class SyncService {
  static lastError: string = '';
  static lastSyncAt: string = '';
  /** 后端是否已连上（设置页显示用） */
  static connected: boolean = false;
  /** 用户开关：关掉后不轮询、不注册身份 */
  static enabled: boolean = true;

  private static context: common.Context | undefined = undefined;
  private static timerId: number = -1;
  private static running: boolean = false;
  private static subsCheckedAt: number = 0;

  static init(context: common.Context): void {
    SyncService.context = context;
    BackendConfig.init(context);
    SyncStatus.instance().reset(SyncService.enabled);
  }

  /** 设置页开关：关闭立即停轮询；打开立刻拉一次 */
  static setEnabled(enabled: boolean): void {
    SyncService.enabled = enabled;
    if (!enabled) {
      SyncService.stop();
      SyncStatus.instance().disabled();
      return;
    }
    SyncStatus.instance().reset(true);
    SyncService.start();
    SyncService.syncOnce(true);
  }

  static hasIdentity(): boolean {
    return BackendConfig.hasIdentity();
  }

  /** 有设备身份就直接用；没有就注册一个（注册接口不需要鉴权） */
  private static async ensureIdentity(): Promise<boolean> {
    const context: common.Context | undefined = SyncService.context;
    if (context === undefined) {
      return false;
    }
    if (BackendConfig.hasIdentity()) {
      return true;
    }
    const res = await RelayApi.register('知了 App');
    if (!res.ok || res.data === undefined) {
      SyncService.lastError = res.ok ? '注册返回为空' : apiErrorMessage(res);
      return false;
    }
    BackendConfig.setIdentity(context, res.data.device_id, res.data.token);
    SyncService.subsCheckedAt = 0;
    return true;
  }

  /**
   * 把「可订阅且还没订阅」的群都订阅上。
   *
   * 为什么必须做：后端 `/candidates` 会按设备订阅的群过滤，没订阅 = 永远拿不到候选。
   * 绑定成功后自动订阅一次；之后每 5 分钟再对一次（用户在 QQ 里新加的群）。
   */
  static async ensureSubscribed(force: boolean = false): Promise<number> {
    const now: number = Date.now();
    if (!force && now - SyncService.subsCheckedAt < SUB_CHECK_INTERVAL_MS) {
      return 0;
    }
    SyncService.subsCheckedAt = now;
    const res = await RelayApi.groups();
    if (!res.ok || res.data === undefined) {
      return 0;
    }
    let added: number = 0;
    for (let i = 0; i < res.data.groups.length; i++) {
      const g = res.data.groups[i];
      if (g.subscribed || !g.bot_present) {
        continue;
      }
      const sub = await RelayApi.subscribe(g.group_openid);
      if (sub.ok) {
        added++;
      }
    }
    return added;
  }

  /** 供设置页调用：确保已有设备身份（没有就注册）。成功后可直接查 `/bind/status`。 */
  static async ensureDevice(): Promise<boolean> {
    return await SyncService.ensureIdentity();
  }

  /** 拉一次候选并落盘；返回新增（本机原来没有的）任务条数 */
  static async syncOnce(showBusy: boolean = false): Promise<number> {
    const context: common.Context | undefined = SyncService.context;
    if (context === undefined || SyncService.running) {
      return 0;
    }
    if (!SyncService.enabled) {
      SyncStatus.instance().disabled();
      return 0;
    }
    if (showBusy) {
      SyncStatus.instance().syncing();
    }
    SyncService.running = true;
    try {
      if (BackendConfig.baseUrl.length === 0) {
        SyncService.connected = false;
        SyncService.lastError = '未配置服务器地址';
        SyncStatus.instance().offline(SyncService.lastError);
        return 0;
      }
      if (!(await SyncService.ensureIdentity())) {
        SyncService.connected = false;
        SyncStatus.instance().offline(SyncService.lastError);
        return 0;
      }
      await SyncService.ensureSubscribed(false);

      const res = await RelayApi.candidates(BackendConfig.cursor, 200);
      if (!res.ok || res.data === undefined) {
        // 身份失效（BE-05）：清掉本机身份与绑定，停止轮询，等用户重新配对
        if (!res.ok && res.error !== undefined && res.error.code === 'unauthorized') {
          BackendConfig.clearIdentity(context, true);
          SyncService.lastError = '设备身份已失效，请在设置里重新绑定';
          SyncService.connected = false;
          SyncStatus.instance().offline(SyncService.lastError);
          SyncService.stop();
          return 0;
        }
        SyncService.lastError = res.ok ? '候选返回为空' : apiErrorMessage(res);
        SyncService.connected = false;
        SyncStatus.instance().offline(SyncService.lastError);
        return 0;
      }
      SyncService.connected = true;
      SyncService.lastError = '';
      SyncStatus.instance().online(SyncService.clock());

      const candidates: CandidateItem[] = res.data.candidates;
      if (candidates.length === 0) {
        BackendConfig.setCursor(context, res.data.cursor);
        SyncService.lastSyncAt = SyncService.clock();
        return 0;
      }

      // 原文：窗口内全部消息（<=200 条）建索引，只用于本机「原文对照」
      const rawTexts: Map<string, string> = await SyncService.loadRawTexts();

      const incoming: Task[] = [];
      for (let i = 0; i < candidates.length; i++) {
        const c: CandidateItem = candidates[i];
        incoming.push(candidateToTask(c, 0, SyncService.joinRaw(c, rawTexts)));
      }

      const store: TaskListStore = TaskListStore.instance();
      const added: number = store.upsertAll(incoming);
      // 新拉下来的候选可能「到手就已经过期」：立刻过一遍，别让它们以"未完成"的样子在列表里闪一下
      TaskExpiryService.scanOnce();
      BackendConfig.setCursor(context, res.data.cursor);
      TaskRepository.save(context, store.allTasks());
      SyncService.lastSyncAt = SyncService.clock();
      SyncStatus.instance().online(SyncService.lastSyncAt);
      hilog.info(DOMAIN, TAG, 'sync ok: %{public}d candidates, +%{public}d new',
        candidates.length, added);
      return added;
    } catch (error) {
      const err = error as Error;
      SyncService.lastError = err.message;
      SyncService.connected = false;
      SyncStatus.instance().offline(err.message);
      hilog.warn(DOMAIN, TAG, 'sync failed: %{public}s', err.message);
      return 0;
    } finally {
      SyncService.running = false;
    }
  }

  static start(): void {
    if (!SyncService.enabled) {
      return;
    }
    SyncService.stop();
    SyncService.timerId = setInterval(() => {
      // 先扫本地「已过期」（**不依赖网络**）：断网/没配服务器时，到期状态也要照常推进；
      // 再拉候选。两件事都是每 5 秒一轮，共用同一个 tick。
      TaskExpiryService.scanOnce();
      SyncService.syncOnce();
    }, POLL_INTERVAL_MS);
  }

  static stop(): void {
    if (SyncService.timerId >= 0) {
      clearInterval(SyncService.timerId);
      SyncService.timerId = -1;
    }
  }

  /** 绑定成功后调用：强制重新检查订阅并立刻同步一次 */
  static async refreshAfterBind(): Promise<void> {
    SyncService.subsCheckedAt = 0;
    await SyncService.ensureSubscribed(true);
    await SyncService.syncOnce();
  }

  // ---------------------------------------------------------------- 内部

  private static async loadRawTexts(): Promise<Map<string, string>> {
    const map: Map<string, string> = new Map<string, string>();
    const res = await RelayApi.messages(0, 200);
    if (!res.ok || res.data === undefined) {
      return map;
    }
    const list: ServeMessage[] = res.data.messages;
    for (let i = 0; i < list.length; i++) {
      if (list[i].content.length > 0) {
        map.set(list[i].msg_id, list[i].content);
      }
    }
    return map;
  }

  /** 把候选的 `source.msg_ids` 还原成原文（最多 5 条，用换行分隔） */
  private static joinRaw(c: CandidateItem, raw: Map<string, string>): string {
    const parts: string[] = [];
    for (let i = 0; i < c.source.msg_ids.length && parts.length < 5; i++) {
      const text: string | undefined = raw.get(c.source.msg_ids[i]);
      if (text !== undefined && text.length > 0 && parts.indexOf(text) < 0) {
        parts.push(text);
      }
    }
    return parts.join('\n');
  }

  private static clock(): string {
    const d: Date = new Date();
    const hh: string = d.getHours() < 10 ? '0' + d.getHours() : '' + d.getHours();
    const mm: string = d.getMinutes() < 10 ? '0' + d.getMinutes() : '' + d.getMinutes();
    return hh + ':' + mm;
  }
}
