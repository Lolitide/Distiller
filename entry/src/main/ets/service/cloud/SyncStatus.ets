/**
 * 同步状态的**可观察单例**。
 *
 * `SyncService` 原本用静态字段记 connected/lastError，页面订阅不到；这里把状态收进
 * `@ObservedV2`，列表页细条与设置页都读同一份，避免两处各记一套。
 */
export const SYNC_PHASE_IDLE: string = 'idle';
export const SYNC_PHASE_SYNCING: string = 'syncing';
export const SYNC_PHASE_ONLINE: string = 'online';
export const SYNC_PHASE_OFFLINE: string = 'offline';
export const SYNC_PHASE_DISABLED: string = 'disabled';

@ObservedV2
export class SyncStatus {
  private static shared: SyncStatus | undefined = undefined;

  static instance(): SyncStatus {
    if (SyncStatus.shared === undefined) {
      SyncStatus.shared = new SyncStatus();
    }
    return SyncStatus.shared;
  }

  @Trace phase: string = SYNC_PHASE_IDLE;
  @Trace message: string = '';
  @Trace lastSyncAt: string = '';

  reset(enabled: boolean): void {
    this.phase = enabled ? SYNC_PHASE_IDLE : SYNC_PHASE_DISABLED;
    this.message = '';
  }

  syncing(): void {
    this.phase = SYNC_PHASE_SYNCING;
    this.message = '正在同步…';
  }

  online(at: string): void {
    this.phase = SYNC_PHASE_ONLINE;
    this.message = '';
    this.lastSyncAt = at;
  }

  offline(message: string): void {
    this.phase = SYNC_PHASE_OFFLINE;
    this.message = message;
  }

  disabled(): void {
    this.phase = SYNC_PHASE_DISABLED;
    this.message = '同步已关闭';
  }

  get showsBanner(): boolean {
    return this.phase === SYNC_PHASE_SYNCING
      || this.phase === SYNC_PHASE_OFFLINE
      || this.phase === SYNC_PHASE_DISABLED;
  }
}
