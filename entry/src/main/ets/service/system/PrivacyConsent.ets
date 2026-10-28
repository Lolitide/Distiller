/*
 * 隐私授权门禁（`service/system/PrivacyConsent.ets`）。
 *
 * ## 为什么需要它
 *
 * 2026-10-27 需求方：「隐私说明、隐私政策未合规撰写，且应放至独立页面，用官方的规范，
 * 且支持用户撤回，撤回后可使用最基本功能，与所有 AI、云相关功能分隔」。
 *
 * 于是把「用户有没有同意《隐私政策》」做成**一条可撤回的状态**，并在**所有 AI / 云能力的入口**检查它：
 *
 *   · 撤回后**仍然可用**（最基本功能，纯本机）：
 *     任务列表 / 详情 / 手写增删改、本地提醒（`ReminderCoordinator`）、通知、日历写入、导入导出。
 *   · 撤回后**一律拒绝**（AI 与云相关）：
 *     云同步轮询（`SyncService`）、Push 令牌上报（`PushRegistrar`）、采纳/忽略回传（`FeedbackService`）、
 *     服务端解析（`ManualParseService`）、转发图片下载（`ForwardImageService`）、
 *     端侧 OCR / 语音识别 / 实体抽取（`OcrService` / `SpeechService` / `TextExtractService`）。
 *
 * ## 状态口径
 *
 * · 持久化在 `SettingsRepository`（`privacy_consent`），**默认 true**：老用户升级上来不会被锁；
 *   新装用户在首次启动引导里必须勾选《隐私政策》才能点「开始使用」，那份同意是显式取得的。
 * · 内存里的值是 `@Trace granted` 的单例，设置页/隐私政策页读它刷新文案。
 * · `allowed()` 是给服务层用的**同步**判定：服务层拿不到 context 时按内存值判断，
 *   内存值在 `EntryAbility` 启动时就已灌好（`Prime` 见 `load`）。
 */
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { SettingsRepository } from '../../repository/SettingsRepository';

const DOMAIN: number = 0x0000;
const TAG: string = 'PrivacyConsent';

@ObservedV2
export class PrivacyConsent {
  private static shared: PrivacyConsent | undefined = undefined;

  /** 全局单例（`@Trace granted` 的变化会驱动设置页/隐私页刷新） */
  static instance(): PrivacyConsent {
    if (PrivacyConsent.shared === undefined) {
      PrivacyConsent.shared = new PrivacyConsent();
    }
    return PrivacyConsent.shared;
  }

  /** 用户当前是否已同意《隐私政策》 */
  @Trace granted: boolean = true;

  /**
   * 启动时灌一次内存值（`EntryAbility` 里调；也可以重复调，幂等）。
   * 页面/服务层后续一律用 `allowed()` 同步判定，不再各读一次首选项。
   */
  static async load(context: common.Context): Promise<void> {
    const granted: boolean = await SettingsRepository.getPrivacyConsent(context);
    PrivacyConsent.instance().granted = granted;
  }

  /** **服务层门禁**：是否允许调用 AI / 云能力。同步、无副作用 */
  static allowed(): boolean {
    return PrivacyConsent.instance().granted;
  }

  /**
   * 设置授权状态（撤回 / 重新授权）。
   *
   * @returns 是否成功落盘
   */
  static async setGranted(context: common.Context, granted: boolean): Promise<boolean> {
    const ok: boolean = await SettingsRepository.setPrivacyConsent(context, granted);
    PrivacyConsent.instance().granted = granted;
    hilog.info(DOMAIN, TAG, 'privacy consent = %{public}s (saved=%{public}s)', String(granted), String(ok));
    return ok;
  }
}
