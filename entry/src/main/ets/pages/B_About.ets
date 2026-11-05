/*
 * 《关于》独立页面（二级页，2026-11-05）。
 *
 * 需求方：设置页的「关于」原来是三行（版本 / 隐私说明 / 重新查看启动引导），
 * 现在合并成设置里的一行「知了与隐私说明 >」，点进来是本页；
 * 本页版式参照 QQ 关于页：顶部应用图标 + 白色信息卡（三行 = 合并前那三行）+ 底部备案号。
 *
 * 备案号「陕ICP备2026032183号」可点，跳 https://beian.miit.gov.cn（工信部备案查询）。
 *
 * 路由：`resources/base/profile/router_map.json` 注册为 `AboutPage`。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { SettingsRepository } from '../repository/SettingsRepository';
import { Theme, ThemeStore } from '../utils/Theme';
import { NAV_STACK_KEY, ROUTE_PRIVACY_POLICY } from '../viewmodel/TaskNavParams';

const DOMAIN: number = 0x0000;
const TAG: string = 'B_About';
/** 信息卡行高（vp）：与设置页其它行保持一致 */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 卡片左右留白（vp） */
const CARD_SIDE_MARGIN_VP: number = 16;
/** 图标区顶部留白（vp）：需求方 2026-11-05 再要求「logo 和三行都往下移一些」 */
const ICON_TOP_VP: number = 96;
/** 备案号左侧图标与文字间距 / 图标尺寸（vp） */
const ICP_ICON_GAP_VP: number = 6;
const ICP_ICON_SIZE_VP: number = 14;
/** 分隔线粗细（与设置页一致） */
const DIVIDER_WIDTH_VP: number = 0.5;
/** 备案号一行的可点击高度（vp）：≥48 才满足最小触控区 */
const ICP_ROW_HEIGHT_VP: number = 48;
/** 备案号（与 AGC / 工信部备案信息一致，改动前先核对备案回执）：前缀灰色、号码蓝色 */
const ICP_PREFIX: string = 'ICP备案号：';
const ICP_NUMBER: string = '陕ICP备2026032183号';
/** 备案号距底部的留白（vp）：需求方要求整体上移一些 */
const ICP_BOTTOM_GAP_VP: number = 32;
const ICP_URL: string = 'https://beian.miit.gov.cn';

/** 二级页实例化方法 —— 官方系统路由表要的就是它（`router_map.json` 的 `buildFunction`） */
@Builder
export function AboutPageBuilder() {
  B_About();
}

@ComponentV2
export struct B_About {
  @Local themeStore: ThemeStore = ThemeStore.instance();
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

  /** 版本号从安装包读，不写死 */
  @Computed
  get versionLabel(): string {
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      return info.versionName === undefined ? '—' : info.versionName;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'read version failed: %{public}s', err.message);
      return '—';
    }
  }

  /** 隐私说明：跳独立页（可阅读全文、撤回/重新授权） */
  private openPrivacyPage(): void {
    AppStorage.get<NavPathStack>(NAV_STACK_KEY)?.pushPathByName(ROUTE_PRIVACY_POLICY, '');
  }

  /** 重新查看启动引导：只置标记，下次冷启动时展示 */
  private replayOnboarding(): void {
    const ctx: common.Context | undefined = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    SettingsRepository.setFirstLaunchDone(ctx, false);
    this.toast('下次启动会显示启动引导');
  }

  /** 备案号 → 工信部备案查询（系统浏览器） */
  private openIcp(): void {
    const ctx: common.Context | undefined = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const abilityCtx: common.UIAbilityContext = ctx as common.UIAbilityContext;
    abilityCtx.openLink(ICP_URL, { appLinkingOnly: false }).catch((error: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'open icp link failed: %{public}s', error.message);
      this.toast('打不开备案查询页，请手动访问 beian.miit.gov.cn');
    });
  }

  /** 行间分隔线：完全对齐设置页（`Divider` + 0.5vp `comp_divider` + 左右各缩进 16vp） */
  @Builder
  rowDivider() {
    Divider()
      .strokeWidth(DIVIDER_WIDTH_VP)
      .color($r('sys.color.comp_divider'))
      .margin({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
  }

  @Builder
  chevron() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(Theme.ICON_CHEVRON)
      .fontColor([$r('sys.color.icon_secondary')])
  }

  /** 信息卡（三行 = 合并前的 版本 / 隐私说明 / 重新查看启动引导） */
  @Builder
  aboutCard() {
    Column() {
      // ① 当前版本：只读展示，不给箭头
      Row() {
        Text('当前版本')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
        Text(this.versionLabel)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      this.rowDivider()

      // ② 隐私说明 → 独立页面
      Row({ space: 8 }) {
        Text('隐私说明')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
        this.chevron()
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.openPrivacyPage();
      })

      this.rowDivider()

      // ③ 重新查看启动引导：置标记，下次启动展示
      Row({ space: 8 }) {
        Text('重新查看启动引导')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
        this.chevron()
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.replayOnboarding();
      })
    }
    .width('100%')
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius(Theme.RADIUS_CARD)
    .clip(true)
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        // 只负责颜色的底色层：手势条那一带也刷成 `surface`
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeStore.scheme.surface)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .hitTestBehavior(HitTestMode.None)

        Column() {
          // 顶部让开「状态栏 + 二级页标题栏（MINI = 56vp）」
          Row().width('100%').height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)

          // 应用图标（参照 QQ 关于页：图标居中、与卡片留出呼吸空间）
          // 用分层图标（蓝底 + 白色 Z）合成，`startIcon.png` 是透明的白 Z，单独铺在白底上会看不见
          Column() {
            Stack() {
              Image($r('app.media.background'))
                .width(88)
                .height(88)
                .objectFit(ImageFit.Cover)
              Image($r('app.media.foreground'))
                .width(88)
                .height(88)
                .objectFit(ImageFit.Cover)
            }
            .width(88)
            .height(88)
            .borderRadius(20)
            .clip(true)
          }
          .width('100%')
          .padding({ top: ICON_TOP_VP, bottom: 32 })
          .alignItems(HorizontalAlign.Center)

          // 2026-11-05 需求方：「三行按钮应该放在屏幕正中间」——用上下两段弹性留白把卡片顶到屏幕中部
          // （上留白 : 下留白 ≈ 1:7 是按 2760px 屏实测调的：卡片中心落在屏幕正中）
          Row().width('100%').layoutWeight(1)

          Column() {
            this.aboutCard()
          }
          .width('100%')
          .padding({ left: CARD_SIDE_MARGIN_VP, right: CARD_SIDE_MARGIN_VP })

          Row().width('100%').layoutWeight(7)

          // 底部备案号（可点 → 工信部备案查询）
          // 2026-11-05 需求方：「用这种格式：ICP备案号：......，最左侧最好加一个公安局的 icon」
          // 2026-11-05 需求方：「向上移动一些，'陕ICP备...' 这一串要标成蓝色」
          Row({ space: ICP_ICON_GAP_VP }) {
            SymbolGlyph($r('sys.symbol.seal_shield_fill'))
              .fontSize(ICP_ICON_SIZE_VP)
              .fontColor([$r('sys.color.icon_secondary')])
            Text() {
              Span(ICP_PREFIX)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              Span(ICP_NUMBER)
                .fontColor(this.themeStore.scheme.primary)
            }
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
          }
          .width('100%')
          .height(ICP_ROW_HEIGHT_VP)
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: ICP_BOTTOM_GAP_VP })
          .onClick(() => {
            this.openIcp();
          })
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
        title: { mainTitle: '关于' }
      }
    })
    .hideBackButton(false)
  }
}
