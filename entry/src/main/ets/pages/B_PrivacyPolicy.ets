/*
 * 《隐私政策》独立页面（**二级页**，2026-10-27）。
 *
 * 需求方原话：「隐私说明、隐私政策未合规撰写，且应放至独立页面，用官方的规范，
 * 且支持用户撤回，撤回后可使用最基本功能，与所有 AI、云相关功能分隔」。
 *
 * 于是：
 *   · **独立页面**（不再是一个居中弹窗）—— 弹窗里塞不下一篇合规的隐私政策；
 *   · **按官方审核要求的结构撰写**（AGC 元数据审核：需包含收集个人信息的**目的、方式、范围**，
 *     需提供中文版、需易于访问和阅读 —— 所以做到正文 14vp / 行高 22vp、分节带小标题、段落留白）；
 *   · **支持撤回**：底部一颗「撤回隐私授权」，撤回后 AI 与云相关能力全部停用
 *     （`service/system/PrivacyConsent.ets` 里的门禁），本地基础功能不受影响；
 *   · **与 AI / 云功能分隔**：政策里把「只在本机」和「会上传到服务器」两类逐条分开写，
 *     撤回只影响后者与 AI 能力。
 *
 * 入口：设置 → 关于 → 隐私说明（`A_Settings.openPrivacyPage()`）。
 * 路由：`resources/base/profile/router_map.json` 里注册为 `PrivacyPolicyPage`。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { PrivacyConsent } from '../service/system/PrivacyConsent';
import { SyncService } from '../service/cloud/SyncService';
import { SettingsRepository } from '../repository/SettingsRepository';
import { Theme, ThemeStore } from '../utils/Theme';
import { PrivacyPolicyText } from '../components/PrivacyPolicyText';

/** 正文与标题之间的留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 内容左右留白（vp）：官方 `padding_level8` */
const SIDE_PADDING_VP: number = 16;

/** 二级页的实例化方法 —— 官方系统路由表要的就是它（`router_map.json` 的 `buildFunction`） */
@Builder
export function PrivacyPolicyPageBuilder(name: string, param: Object) {
  B_PrivacyPolicy();
}

@ComponentV2
export struct B_PrivacyPolicy {
  /** 视觉个性化：M3 色系（与设置页同一档 `surface`） */
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 授权状态（单例的 `@Trace` 字段，撤回后本页立刻变文案） */
  @Local consent: PrivacyConsent = PrivacyConsent.instance();
  /** 状态栏高度（vp）：窗口全屏后内容从窗口顶端起算，要先让开这一截 */
  @Local statusBarVp: number = 0;

  aboutToAppear(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    WindowInsets.topPx(context).then((px: number) => {
      this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
    });
  }

  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      // toast 失败不影响主流程
    }
  }

  /** 撤回 / 重新授权：落盘并联动同步运行态 */
  private async applyConsent(granted: boolean): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await PrivacyConsent.setGranted(context, granted);
    if (!granted) {
      // 撤回后立刻停掉同步；SyncService 自己也有一层 consent 门禁，这里是双保险。
      SyncService.setEnabled(false);
      await SettingsRepository.setSyncEnabled(context, false);
      this.toast('已撤回授权：AI 与云端功能已停用，本机基础功能仍可用');
      return;
    }
    // 重新授权后 SyncService 会按 consent 恢复；设置页已没有「云端同步」开关。
    SyncService.setEnabled(true);
    this.toast('已重新授权，AI 解析与云端同步已恢复');
  }

  /** 撤回前二次确认（撤回是"立即生效 + 影响功能"的动作，必须确认） */
  private confirmWithdraw(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '撤回隐私授权',
      message: '撤回后，云端同步、服务端解析、语音转文字、OCR、实体抽取与推送上报都会停用；'
        + '手动增删改任务、本地提醒、通知、日历写入、导入导出不受影响。\n\n'
        + '随时可以在本页重新授权。',
      buttons: [
        { text: '取消', color: $r('sys.color.ohos_id_color_text_primary') },
        { text: '撤回', color: this.themeStore.scheme.error }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.applyConsent(false);
      }
    }).catch(() => {
      // 弹窗失败：什么也不做（不能因为弹窗挂了就把授权撤掉）
    });
  }

  /** 授权状态条：一眼看出当前是否已同意，以及撤回会失去什么 */
  @Builder
  consentBanner() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        SymbolGlyph(this.consent.granted
          ? $r('sys.symbol.checkmark_circle_fill')
          : $r('sys.symbol.exclamationmark_circle'))
          .fontSize(18)
          .fontColor([this.consent.granted ? this.themeStore.scheme.primary : this.themeStore.scheme.error])
        Text(this.consent.granted ? '当前状态：已同意本政策' : '当前状态：已撤回授权')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.consent.granted
            ? $r('sys.color.ohos_id_color_text_primary')
            : this.themeStore.scheme.error)
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.consent.granted
        ? '同意后，云端同步、服务端解析、语音转文字、OCR、实体抽取与推送上报才会工作。'
        : 'AI 与云端功能已停用；手动增删改任务、本地提醒、通知、日历写入、导入导出仍然可用。')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(Theme.GAP_L)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius(Theme.RADIUS_CARD)
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 只负责颜色的底色层：把手势条那一带也刷成 `surface`（与详情页/搜索页同一处修）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeStore.scheme.surface)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .hitTestBehavior(HitTestMode.None)

        Column() {
          // 顶部让开「状态栏 + 二级页标题栏（MINI = 56vp）」
          Row().width('100%').height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)

          Scroll() {
            Column({ space: SECTION_GAP_VP }) {
              // 抬头：生效/更新日期（合规要求可追溯到版本）
              Column({ space: 4 }) {
                Text('生效日期：2026 年 10 月 27 日')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .width('100%')
                Text('更新日期：2026 年 10 月 29 日    版本：v1.1')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)

              this.consentBanner()

              // 正文与首次启动引导的隐私页共用同一份文案（components/PrivacyPolicyText.ets）
              PrivacyPolicyText()

              // 撤回 / 重新授权（页面底部，与正文分开，避免误触）
              Column({ space: 8 }) {
                if (this.consent.granted) {
                  Button({ type: ButtonType.Capsule, stateEffect: true }) {
                    Text('撤回隐私授权')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontColor(this.themeStore.scheme.error)
                  }
                  .height(44)
                  .width('100%')
                  .backgroundColor(this.themeStore.scheme.errorContainer)
                  .onClick(() => {
                    this.confirmWithdraw();
                  })
                  .accessibilityText('撤回隐私授权')
                } else {
                  Button({ type: ButtonType.Capsule, stateEffect: true }) {
                    Text('重新同意本政策')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontColor(this.themeStore.scheme.onPrimary)
                  }
                  .height(44)
                  .width('100%')
                  .backgroundColor(this.themeStore.scheme.primary)
                  .onClick(() => {
                    this.applyConsent(true);
                  })
                  .accessibilityText('重新同意本政策')
                }

                Text('撤回与重新授权都只影响 AI 与云端能力，不影响你本机已有的任务。')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding({ top: Theme.GAP_L, bottom: Theme.GAP_XL })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({ left: SIDE_PADDING_VP, right: SIDE_PADDING_VP, bottom: Theme.GAP_XL })
          }
          .layoutWeight(1)
          .width('100%')
          .align(Alignment.Top)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
    }
    .titleBar({
      avoidLayoutSafeArea: true,
      style: MainTitleBar.style(this.themeStore.scheme.surface, this.themeStore.scheme.onSurface),
      content: {
        title: { mainTitle: '隐私政策' }
      }
    })
    .hideBackButton(false)
  }
}
