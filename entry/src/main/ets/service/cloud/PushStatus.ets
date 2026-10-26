/**
 * 推送通道的**可观察单例**（与 `SyncStatus` / `TaskListStore` 同一套 V2 写法）。
 *
 * 为什么要单独一份状态：取 token（端侧）与上报 `/push/token`（云端）是两段，失败原因完全不同
 * （推送权益没开 / 没签名 / 设备不支持 / 服务器没连上）。设置页那一行要能**说清是哪一段卡住**，
 * 不能只显示"推送未就绪"。
 */
export const PUSH_PHASE_IDLE: string = 'idle';
/** 本机已拿到 token，且后端回了 push_ready=true —— 服务端可以下发提醒了 */
export const PUSH_PHASE_READY: string = 'ready';
/** 端侧取到了 token，但后端还没准备好下发（push_ready=false） */
export const PUSH_PHASE_REGISTERED: string = 'registered';
/** 端侧或云端失败（`message` 里是哪一段） */
export const PUSH_PHASE_FAILED: string = 'failed';
/** 没配服务器 / 没设备身份 —— 根本没开始 */
export const PUSH_PHASE_UNAVAILABLE: string = 'unavailable';

@ObservedV2
export class PushStatus {
  private static shared: PushStatus | undefined = undefined;

  static instance(): PushStatus {
    if (PushStatus.shared === undefined) {
      PushStatus.shared = new PushStatus();
    }
    return PushStatus.shared;
  }

  /** 见上面的 PUSH_PHASE_* */
  @Trace phase: string = PUSH_PHASE_IDLE;
  /** 给人看的一句话（状态行直接显示它） */
  @Trace message: string = '未上报';
  /** 「怎么修」的长句（状态行放不下，点重试时 toast 出来） */
  @Trace advice: string = '';
  /** 本机 Push Token（只在内存里；不做任何持久化） */
  @Trace token: string = '';
  /** 后端 `registered`：这台设备的令牌已登记 */
  @Trace registered: boolean = false;
  /** 后端 `push_ready`：服务端具备下发能力（验收项要的就是它） */
  @Trace pushReady: boolean = false;
  /** 最后一次尝试的时间（HH:mm），设置页显示"什么时候试过" */
  @Trace updatedAt: string = '';

  /** 没配服务器 / 没身份：连"取 token"都不用试 */
  unavailable(reason: string): void {
    this.phase = PUSH_PHASE_UNAVAILABLE;
    this.message = reason;
    this.pushReady = false;
    this.updatedAt = PushStatus.now();
  }

  /** 端侧或云端失败（`message` 是状态行短标签，`advice` 是"怎么修"的长句） */
  failed(reason: string, advice: string = ''): void {
    this.phase = PUSH_PHASE_FAILED;
    this.message = reason;
    this.advice = advice;
    this.pushReady = false;
    this.updatedAt = PushStatus.now();
  }

  /** token 已上报，但后端说还不能下发 */
  registeredOnly(token: string, registered: boolean): void {
    this.phase = PUSH_PHASE_REGISTERED;
    this.token = token;
    this.registered = registered;
    this.pushReady = false;
    this.message = '令牌已上报，服务端尚未开启下发';
    this.updatedAt = PushStatus.now();
  }

  /** 完全就绪：服务端可以按令牌下发提醒了 */
  ready(token: string, registered: boolean): void {
    this.phase = PUSH_PHASE_READY;
    this.token = token;
    this.registered = registered;
    this.pushReady = true;
    this.message = '已就绪，服务端可下发提醒';
    this.updatedAt = PushStatus.now();
  }

  /** 设置页那一行右侧显示的短标签 */
  get label(): string {
    if (this.phase === PUSH_PHASE_READY) {
      return '已就绪';
    }
    if (this.phase === PUSH_PHASE_REGISTERED) {
      return '已上报';
    }
    if (this.phase === PUSH_PHASE_FAILED) {
      return '未就绪';
    }
    if (this.phase === PUSH_PHASE_UNAVAILABLE) {
      return '未启用';
    }
    return '未上报';
  }

  private static now(): string {
    const d: Date = new Date();
    const hh: string = d.getHours() < 10 ? '0' + d.getHours() : '' + d.getHours();
    const mm: string = d.getMinutes() < 10 ? '0' + d.getMinutes() : '' + d.getMinutes();
    return hh + ':' + mm;
  }
}
