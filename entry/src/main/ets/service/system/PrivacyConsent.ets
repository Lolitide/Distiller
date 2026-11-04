/*
 * 隐私授权门禁（`service/system/PrivacyConsent.ets`）。
 *
 * ## 为什么有两个口径（2026-11-03 AGC 审核整改）
 *
 * AGC 审核驳回：「应用出现两个隐私弹窗，影响用户体验…您已接入平台隐私托管服务，建议您删除自行构建的
 * 隐私声明弹窗，防止应用首次打开时，出现多次弹出隐私弹窗的情形」
 * （官方 FAQ：`FAQ/应用市场服务_AppGallery_Kit/如何解决首次运行弹出两个隐私政策弹窗的问题/faqs-appgallery-84`）。
 *
 * 于是口径拆成两层，**不再自己弹隐私声明**：
 *
 *   1. **平台托管层**（真正的隐私声明同意记录）
 *      本应用在 AGC 勾选了「标准化隐私声明托管服务」，首次打开由**系统标准弹窗**征得同意。官方原文
 *      （`开发指南/AppGallery_Kit_应用市场服务/隐私管理服务/store-privacy`）：
 *      「如果在应用/元服务中使用了标准化隐私声明托管服务，则首次打开应用/元服务，会默认显示标准化
 *      隐私弹窗，**请勿在应用/元服务中自行实现弹窗展示隐私声明**，否则发布审核将被驳回。」
 *      本文件用 `@kit.AppGalleryKit` 的 `privacyManager` 查询/撤销这份记录：
 *        · 撤回 → `disableService()`：撤销签署记录，下次打开会重新弹系统标准弹窗；
 *        · 重新授权 → `requestAppPrivacyConsent()`：由系统拉起**标准化隐私弹框**，不由我们画。
 *
 *   2. **本地门禁层**（`@Trace granted`，持久化在 `SettingsRepository` 的 `privacy_consent`）
 *      AI / 云能力的开关。撤回后仍然可用（最基本功能，纯本机）：
 *      任务列表 / 详情 / 手写增删改、本地提醒（`ReminderCoordinator`）、通知、日历写入、导入导出。
 *      撤回后一律拒绝（AI 与云相关）：
 *      云同步轮询（`SyncService`）、Push 令牌上报（`PushRegistrar`）、采纳/忽略回传（`FeedbackService`）、
 *      服务端解析（`ManualParseService`）、转发图片下载（`ForwardImageService`）、
 *      端侧 OCR / 语音识别 / 实体抽取（`OcrService` / `SpeechService` / `TextExtractService`）。
 *
 * ## 默认值
 *
 * `privacy_consent` 默认 **true**：老用户升级上来不会被锁；新装用户的隐私声明同意由系统标准弹窗显式取得
 * （未同意就进不了应用内容），所以应用内不必再问第二遍。
 *
 * ## 平台接口兜底
 *
 * `隐私管理服务` **暂不支持模拟器**，`hdc` 装上来的调试包也不带托管信息 —— 这两种情况下接口抛
 * `1006700003`（The application does not use privacy manager service）。此时一律退化为「只改本地门禁」，
 * 不阻塞、不崩、不弹错，只是不再有平台侧记录可撤销。
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { privacyManager } from '@kit.AppGalleryKit';
import { SettingsRepository } from '../../repository/SettingsRepository';

const DOMAIN: number = 0x0000;
const TAG: string = 'PrivacyConsent';

/** 未接入隐私管理服务（模拟器 / 调试包 / 未勾选托管）时接口抛的错误码 */
const ERR_NOT_USING_PRIVACY_MANAGER: number = 1006700003;

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

  /** 本地门禁：是否允许调用 AI / 云能力（隐私声明的同意记录在平台托管侧） */
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
   * 设置本地门禁状态（只写本地，不碰平台托管记录）。
   * 需要在平台侧也生效时用 `revoke()` / `requestConsent()`。
   *
   * @returns 是否成功落盘
   */
  static async setGranted(context: common.Context, granted: boolean): Promise<boolean> {
    const ok: boolean = await SettingsRepository.setPrivacyConsent(context, granted);
    PrivacyConsent.instance().granted = granted;
    hilog.info(DOMAIN, TAG, 'privacy consent = %{public}s (saved=%{public}s)', String(granted), String(ok));
    return ok;
  }

  /**
   * **撤回**：撤销平台托管侧的签署记录（官方 `disableService()`）+ 关掉本地 AI/云门禁。
   *
   * 撤销后再次打开应用会重新弹出系统标准隐私弹窗（官方原文：「撤销同意记录后再次打开应用/元服务
   * 会重新弹出标准化隐私弹框」）。
   *
   * @returns 平台侧是否真的撤销了；false 表示未接入托管服务（模拟器/调试包）或调用失败，只关了本地
   */
  static async revoke(context: common.Context): Promise<boolean> {
    let platformRevoked: boolean = false;
    try {
      privacyManager.disableService();
      platformRevoked = true;
      hilog.info(DOMAIN, TAG, 'disableService succeeded: platform consent record revoked');
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'disableService failed: %{public}d, %{public}s', err.code, err.message);
    }
    await PrivacyConsent.setGranted(context, false);
    return platformRevoked;
  }

  /**
   * **重新授权**：托管场景下由**系统**拉起标准化隐私弹框（官方 `requestAppPrivacyConsent`），
   * 用户同意后恢复本地 AI/云门禁 —— 应用自己**不画**任何隐私声明弹窗。
   *
   * 未接入隐私管理服务时（错误码 1006700003：模拟器 / `hdc` 调试包）退化为直接打开本地门禁，
   * 因为那种环境里根本没有平台记录可签，不能让用户卡在「点了没反应」。
   *
   * @returns 当前是否已同意
   */
  static async requestConsent(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const result: privacyManager.ConsentResult = await privacyManager.requestAppPrivacyConsent(context);
      const agreed: boolean = PrivacyConsent.agreedIn(result.results);
      await PrivacyConsent.setGranted(context, agreed);
      return agreed;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'requestAppPrivacyConsent failed: %{public}d, %{public}s', err.code, err.message);
      if (err.code === ERR_NOT_USING_PRIVACY_MANAGER) {
        await PrivacyConsent.setGranted(context, true);
        return true;
      }
      // 其他错误（用户取消、内部错误…）：不改授权状态，保持原样
      return PrivacyConsent.allowed();
    }
  }

  /**
   * **冷启动对齐**：平台签署记录为「已同意」而本地门禁关着时，恢复本地门禁。
   *
   * 为什么需要：撤回/重签可能发生在应用之外（系统标准弹窗、应用市场里的隐私设置），本地那份
   * `privacy_consent` 会与平台记录脱节。
   *
   * 为什么**只往「已同意」方向恢复、不反着关**：系统标准隐私弹窗可能在 `onCreate` 之后才弹，
   * 那一瞬间 `getAppPrivacyResult()` 还是「未同意」，反着同步会把 AI / 云能力误关掉一整个会话。
   * 「撤回」只认用户在本应用设置页的显式动作（`revoke()` 自己会关）。
   */
  static async syncFromPlatform(context: common.Context): Promise<void> {
    try {
      const platformAgreed: boolean | undefined = PrivacyConsent.platformAgreed();
      if (platformAgreed !== true || PrivacyConsent.instance().granted) {
        return;
      }
      hilog.info(DOMAIN, TAG, 'platform consent record is agreed, restore local gate');
      await PrivacyConsent.setGranted(context, true);
    } catch (error) {
      // 对齐失败不影响启动（本地值即兜底）
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'syncFromPlatform failed: %{public}s', err.message);
    }
  }

  /**
   * 查询平台托管侧的隐私声明签署状态。
   *
   * @returns true=已同意 / false=未同意 / undefined=未接入隐私管理服务（模拟器、调试包），无从判断
   */
  private static platformAgreed(): boolean | undefined {
    try {
      const results: privacyManager.AppPrivacyResult[] = privacyManager.getAppPrivacyResult();
      return PrivacyConsent.agreedIn(results);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'getAppPrivacyResult failed: %{public}d, %{public}s', err.code, err.message);
      return undefined;
    }
  }

  /** 从签署结果里取「隐私声明」那一条的结论（用户协议那条不算） */
  private static agreedIn(results: privacyManager.AppPrivacyResult[]): boolean {
    for (let i: number = 0; i < results.length; i++) {
      const item: privacyManager.AppPrivacyResult = results[i];
      if (item.type === privacyManager.AppPrivacyType.PRIVACY_AGREEMENT) {
        return item.result === privacyManager.AppPrivacyResultType.FULL_MODE_AGREED;
      }
    }
    return false;
  }
}
