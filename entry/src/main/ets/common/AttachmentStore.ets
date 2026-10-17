/**
 * 知了 · 附件端侧持久化（AttachmentStore）
 *
 * 为什么必须落盘：服务端只在**内存**留 30 分钟窗口（`relay.py` 的 `WINDOW`），
 * 窗口一过 `/api/relay/attachment` 就 404，图片和文件**都找不回**。
 * README §五 的硬边界写得很清楚：「App 取回后**必须存本机**」。
 *
 * 设计要点：
 *   - 落 `filesDir/attachments/<群>/<msg_id>_<序号>`。**故意不带后缀**：真实文件名由
 *     消息里的 `filename` 决定，预览/保存时再按原名复制出去。这样路径是
 *     (群, msg_id, index) 的**纯函数**，不需要额外维护索引表——文件系统本身就是索引，
 *     存在性用 `accessSync` 探。少一份要与文件系统同步的状态，就少一类 bug。
 *   - 用 `filesDir` 而不是 `cacheDir`：后者会被系统回收。
 *   - 先写 `<name>.part` 再 `renameSync`，避免半个文件被当成「已下载」。
 *   - 读取一律「**先本地、后后端**」；本地命中就不再打后端。
 *   - 全程在**端侧沙箱**，后端仍然 30 分钟不落盘——正合"不存用户任何信息"。
 */

import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Config } from './Config';
import { ApiClient } from './ApiClient';
import { Store } from './Store';
import { MessageAttachment, RobotMessage } from './Types';

const DOMAIN: number = 0x0000;
const TAG: string = 'AttachmentStore';

/** 每拍最多处理几条**消息**的附件（群里短时涌入 50 条时不会打满带宽） */
const MAX_MSGS_PER_TICK: number = 5;
/** 同一条附件连续失败多少次就不再重试（窗口过期后是永久 404，反复打没意义） */
const MAX_RETRY: number = 3;
/** 淘汰后保留的比例（删到上限的 80%，避免每有新增就触发一轮淘汰） */
const TRIM_KEEP_RATIO: number = 0.8;
/** 拉单条附件的超时 */
const FETCH_TIMEOUT_MS: number = 30000;

/** 待落盘的一条附件 */
interface AttachmentTarget {
  index: number;
  url: string;
}

/** 磁盘上的一个附件文件（淘汰排序用） */
interface AttachmentFile {
  path: string;
  size: number;
  mtime: number;
}

export class AttachmentStore {
  /** 待处理消息队列：本轮没处理完留到下一拍接着来 */
  private static queue: RobotMessage[] = [];
  /** 正在下载的 key（msg_id_index），避免并发重复 */
  private static inflight: Set<string> = new Set<string>();
  /** 失败次数（key -> n） */
  private static failures: Map<string, number> = new Map<string, number>();
  private static pumping: boolean = false;

  // ------------------------------------------------------------ 路径

  private static rootDir(): string {
    const ctx: Context | null = Store.getAppContext();
    if (ctx === null) {
      return '';
    }
    return ctx.filesDir + '/attachments';
  }

  /** 去掉文件名里的不安全字符（msg_id / 群号来自服务端，不能直接拼路径）。 */
  private static safeName(raw: string): string {
    const s: string = raw.length > 0 ? raw : '_';
    let out: string = '';
    for (let i = 0; i < s.length; i++) {
      const c: string = s.charAt(i);
      const ok: boolean = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
        || (c >= '0' && c <= '9') || c === '.' || c === '_' || c === '-';
      out += ok ? c : '_';
    }
    return out;
  }

  private static groupDir(groupOpenid: string): string {
    const root: string = AttachmentStore.rootDir();
    if (root.length === 0) {
      return '';
    }
    return root + '/' + AttachmentStore.safeName(groupOpenid);
  }

  /** 附件在本机的落盘路径；拿不到应用上下文时返回空串。 */
  static localPathOf(groupOpenid: string, msgId: string, index: number): string {
    const dir: string = AttachmentStore.groupDir(groupOpenid);
    if (dir.length === 0 || msgId.length === 0) {
      return '';
    }
    return dir + '/' + AttachmentStore.safeName(msgId) + '_' + index;
  }

  // ------------------------------------------------------------ 探测 / 读取

  static hasLocal(groupOpenid: string, msgId: string, index: number): boolean {
    const p: string = AttachmentStore.localPathOf(groupOpenid, msgId, index);
    if (p.length === 0) {
      return false;
    }
    try {
      return fileIo.accessSync(p);
    } catch (e) {
      return false;
    }
  }

  /** 读本机已落盘的附件字节；没有/读失败返回 null。 */
  static readLocal(groupOpenid: string, msgId: string, index: number): ArrayBuffer | null {
    const p: string = AttachmentStore.localPathOf(groupOpenid, msgId, index);
    if (p.length === 0) {
      return null;
    }
    let f: fileIo.File | undefined = undefined;
    try {
      f = fileIo.openSync(p, fileIo.OpenMode.READ_ONLY);
      const size: number = fileIo.statSync(f.fd).size;
      if (size <= 0) {
        return null;
      }
      const buf: ArrayBuffer = new ArrayBuffer(size);
      fileIo.readSync(f.fd, buf);
      return buf;
    } catch (e) {
      return null;
    } finally {
      if (f !== undefined) {
        try {
          fileIo.closeSync(f);
        } catch (e2) {
          // 关闭失败：fd 由系统回收
        }
      }
    }
  }

  // ------------------------------------------------------------ 写入

  private static ensureDir(dir: string): void {
    try {
      if (!fileIo.accessSync(dir)) {
        fileIo.mkdirSync(dir, true);
      }
    } catch (e) {
      // 并发创建时可能已被别人建好，忽略
    }
  }

  /** 原子落盘：先写 `.part` 再改名，避免半个文件被当成「已下载」。 */
  private static writeAtomic(dir: string, path: string, buf: ArrayBuffer): boolean {
    AttachmentStore.ensureDir(dir);
    const tmp: string = path + '.part';
    let f: fileIo.File | undefined = undefined;
    try {
      f = fileIo.openSync(tmp,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(f.fd, buf);
      fileIo.closeSync(f);
      f = undefined;
      fileIo.renameSync(tmp, path);
      return true;
    } catch (e) {
      if (f !== undefined) {
        try {
          fileIo.closeSync(f);
        } catch (e2) {
          // 同上
        }
      }
      try {
        fileIo.unlinkSync(tmp);
      } catch (e3) {
        // 临时文件可能没建成，忽略
      }
      hilog.warn(DOMAIN, TAG, 'writeAtomic failed: %{public}s', path);
      return false;
    }
  }

  /** 把已经拿到的字节直接落盘（调用方已有字节时用，省一次 IO 往返）。 */
  static saveBytes(groupOpenid: string, msgId: string, index: number, buf: ArrayBuffer): boolean {
    if (buf.byteLength === 0) {
      return false;
    }
    const dir: string = AttachmentStore.groupDir(groupOpenid);
    const path: string = AttachmentStore.localPathOf(groupOpenid, msgId, index);
    if (dir.length === 0 || path.length === 0) {
      return false;
    }
    return AttachmentStore.writeAtomic(dir, path, buf);
  }

  /**
   * 确保这条附件已落盘：本地有就直接返回；否则**先走后端 `/attachment` 过路**，
   * 再退回消息里带的直链。返回是否已落盘。
   */
  static async ensureSaved(groupOpenid: string, msgId: string, index: number,
    remoteUrl: string): Promise<boolean> {
    if (msgId.length === 0) {
      return false;
    }
    if (AttachmentStore.hasLocal(groupOpenid, msgId, index)) {
      return true;
    }
    let buf: ArrayBuffer | null = null;
    const viaServer: boolean = ApiClient.deviceId.length > 0 && msgId.indexOf('local_') !== 0;
    if (viaServer) {
      const api: string = '/api/relay/attachment?msg_id=' + msgId + '&index=' + index;
      buf = await ApiClient.getBytes(api, FETCH_TIMEOUT_MS);
    }
    if ((buf === null || buf.byteLength === 0) && remoteUrl.length > 0
      && remoteUrl.indexOf('file://') !== 0) {
      buf = await ApiClient.getBytesFrom(remoteUrl, FETCH_TIMEOUT_MS);
    }
    if (buf === null || buf.byteLength === 0) {
      return false;
    }
    return AttachmentStore.saveBytes(groupOpenid, msgId, index, buf);
  }

  // ------------------------------------------------------------ 调度

  /** 这条附件值不值得落盘：图片 + 文件。语音/音视频先不做（留 TODO）。 */
  static shouldPersist(a: MessageAttachment): boolean {
    const url: string = a.url ?? '';
    if (url.length === 0 || url.indexOf('file://') === 0) {
      return false; // 本机已有副本（手动添加的），不必再存
    }
    const ct: string = (a.content_type ?? '').toLowerCase();
    if (ct.indexOf('voice') >= 0 || ct.indexOf('audio/') === 0 || ct.indexOf('video/') === 0) {
      return false;
    }
    if (ct.indexOf('image/') === 0) {
      return true;
    }
    return (a.filename ?? '').length > 0;
  }

  private static targetsOf(m: RobotMessage): AttachmentTarget[] {
    const out: AttachmentTarget[] = [];
    const list: MessageAttachment[] | undefined = m.attachments;
    if (list === undefined || m.msg_id.length === 0) {
      return out;
    }
    for (let i = 0; i < list.length; i++) {
      if (!AttachmentStore.shouldPersist(list[i])) {
        continue;
      }
      const t: AttachmentTarget = { index: i, url: list[i].url ?? '' };
      out.push(t);
    }
    return out;
  }

  /**
   * 把新到的消息排进落盘队列。**不阻塞调用方**（轮询 tick 不能等下载）。
   * 每拍只处理 `MAX_MSGS_PER_TICK` 条消息，剩下的留到下一拍。
   */
  static enqueue(list: RobotMessage[]): void {
    for (let i = 0; i < list.length; i++) {
      if (AttachmentStore.targetsOf(list[i]).length > 0) {
        AttachmentStore.queue.push(list[i]);
      }
    }
    AttachmentStore.pump();
  }

  private static async pump(): Promise<void> {
    if (AttachmentStore.pumping) {
      return;
    }
    AttachmentStore.pumping = true;
    let handled: number = 0;
    try {
      while (AttachmentStore.queue.length > 0 && handled < MAX_MSGS_PER_TICK) {
        const m: RobotMessage | undefined = AttachmentStore.queue.shift();
        if (m === undefined) {
          break;
        }
        handled++;
        if (Store.getMessages().length === 0) {
          continue; // 用户刚清空了本机数据，别再往盘上写
        }
        const targets: AttachmentTarget[] = AttachmentStore.targetsOf(m);
        for (let i = 0; i < targets.length; i++) {
          const key: string = m.msg_id + '_' + targets[i].index;
          if (AttachmentStore.inflight.has(key)) {
            continue;
          }
          const fails: number = AttachmentStore.failures.get(key) ?? 0;
          if (fails >= MAX_RETRY) {
            continue;
          }
          AttachmentStore.inflight.add(key);
          const ok: boolean = await AttachmentStore.ensureSaved(
            m.group_openid, m.msg_id, targets[i].index, targets[i].url);
          AttachmentStore.inflight.delete(key);
          if (ok) {
            AttachmentStore.failures.delete(key);
          } else {
            AttachmentStore.failures.set(key, fails + 1);
          }
        }
      }
    } catch (e) {
      const err = e as Error;
      hilog.warn(DOMAIN, TAG, 'pump failed: %{public}s', err.message);
    } finally {
      AttachmentStore.pumping = false;
    }
    if (handled > 0) {
      AttachmentStore.trim();
    }
  }

  // ------------------------------------------------------------ 占用 / 清理

  private static collect(): AttachmentFile[] {
    const out: AttachmentFile[] = [];
    const root: string = AttachmentStore.rootDir();
    if (root.length === 0) {
      return out;
    }
    let groups: string[] = [];
    try {
      groups = fileIo.listFileSync(root);
    } catch (e) {
      return out; // 目录还不存在
    }
    for (let g = 0; g < groups.length; g++) {
      const dir: string = root + '/' + groups[g];
      let names: string[] = [];
      try {
        names = fileIo.listFileSync(dir);
      } catch (e) {
        continue;
      }
      for (let i = 0; i < names.length; i++) {
        const p: string = dir + '/' + names[i];
        try {
          const st: fileIo.Stat = fileIo.statSync(p);
          if (st.isDirectory()) {
            continue;
          }
          const f: AttachmentFile = { path: p, size: st.size, mtime: st.mtime };
          out.push(f);
        } catch (e2) {
          // 文件刚好被清理，跳过
        }
      }
    }
    return out;
  }

  /** 附件总占用（字节）。 */
  static totalBytes(): number {
    const files: AttachmentFile[] = AttachmentStore.collect();
    let n: number = 0;
    for (let i = 0; i < files.length; i++) {
      n += files[i].size;
    }
    return n;
  }

  /** 落盘文件条数（设置页展示用）。 */
  static count(): number {
    return AttachmentStore.collect().length;
  }

  /** 超过上限时按 mtime 最旧优先删到 80%。 @returns 删掉的条数 */
  static trim(): number {
    const limit: number = Config.attachmentLimitBytes;
    let total: number = AttachmentStore.totalBytes();
    if (total <= limit) {
      return 0;
    }
    const files: AttachmentFile[] = AttachmentStore.collect();
    files.sort((a: AttachmentFile, b: AttachmentFile): number => a.mtime - b.mtime);
    const target: number = limit * TRIM_KEEP_RATIO;
    let removed: number = 0;
    for (let i = 0; i < files.length && total > target; i++) {
      try {
        fileIo.unlinkSync(files[i].path);
        total -= files[i].size;
        removed++;
      } catch (e) {
        // 删不掉就跳过（下一次再试）
      }
    }
    if (removed > 0) {
      hilog.info(DOMAIN, TAG, 'trim removed=%{public}d remain=%{public}d', removed, total);
    }
    return removed;
  }

  /** 清掉某个群的全部附件（退订/清空该群时用）。 */
  static deleteGroup(groupOpenid: string): void {
    const dir: string = AttachmentStore.groupDir(groupOpenid);
    if (dir.length === 0) {
      return;
    }
    try {
      fileIo.rmdirSync(dir);
    } catch (e) {
      // 目录不存在或已被清理
    }
  }

  /** 清掉全部附件（跟"清空本机消息"一起走，保证端侧不留残留）。 */
  static deleteAll(): void {
    const root: string = AttachmentStore.rootDir();
    if (root.length === 0) {
      return;
    }
    try {
      fileIo.rmdirSync(root);
    } catch (e) {
      // 目录不存在或已被清理
    }
    AttachmentStore.queue = [];
    AttachmentStore.inflight.clear();
    AttachmentStore.failures.clear();
  }
}
