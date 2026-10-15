import { HdsNavigation, HdsNavigationMenuContentOptions, HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MainTabBar } from '../components/MainTabBar';
import { MainTitleBar } from '../components/MainTitleBar';
import { A_TaskList } from './A_TaskList';
import { A_Settings } from './A_Settings';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Main';

@Entry
@ComponentV2
struct A_Main {
  private navPathStack: NavPathStack = new NavPathStack();
  @Local currentIndex: number = 0;

  @Computed
  get navTitle(): ResourceStr {
    return this.currentIndex === 0 ? $r('app.string.tab_task_list') : $r('app.string.tab_settings');
  }

  /**
   * 右上角按钮**随页签变**：任务列表＝编辑 + 搜索（两个图标按钮），设置＝关于（一个）。
   * 官方 `HdsNavigation` 是**函数式组件**（`HdsNavigationInterface`），`titleBar` 参数会随重渲染更新，
   * 所以这里用 `@Computed` 依赖 `currentIndex` 就能换来换去。
   */
  @Computed
  get navMenu(): HdsNavigationMenuContentOptions {
    if (this.currentIndex === 0) {
      return MainTitleBar.taskListMenu(() => {
        this.onEdit();
      }, () => {
        this.onSearch();
      });
    }
    return MainTitleBar.settingsMenu(() => {
      this.onAbout();
    });
  }

  /**
   * 迷你栏内容：**居中的「+」图标格 + 「添加任务」文字**（袁正锟 2026-10-15：
   * 「minibar 收起的时候是图标（居中），展开后显示图标和「添加任务」，质感和官方一致」）。
   *
   * 结构**照官方示例**：示例里首个元素就是
   * `Column() { Image(...).width(40).height(40) }.width(48).height(48).justifyContent(FlexAlign.Center).margin({left:4,right:4})`
   * —— 一个居中的图标格。迷你栏收起时会被裁剪到只剩这一格（`enableMiniBarClip` 默认 true），
   * 所以**收起态看到的就是居中的图标**；展开后连后面的文字一起显示。
   *
   * 尺寸用官方 token：格子 `titlebar_icon_background_height`(40vp)、图标 `subheader_right_icon_size`(24/32vp)、
   * 文字 `bottom_tab_text_size_normal`（底部页签文字字号）。
   */
  @Builder
  miniBarBuilder() {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize($r('sys.float.subheader_right_icon_size'))
      }
      .width($r('sys.float.titlebar_icon_background_height'))
      .height($r('sys.float.titlebar_icon_background_height'))
      .justifyContent(FlexAlign.Center)
      .margin({
        start: LengthMetrics.resource($r('sys.float.padding_level4')),
        end: LengthMetrics.resource($r('sys.float.padding_level4'))
      })

      Text($r('app.string.action_add_task'))
        .fontSize($r('sys.float.bottom_tab_text_size_normal'))
    }
    .height($r('sys.float.titlebar_icon_background_height'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onAdd();
    })
  }

  /** 统一的 toast 反馈（菜单项/图标按钮无文字，点了要给可见反馈） */
  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'show toast failed: %{public}d, %{public}s', err.code, err.message);
    }
  }

  private onEdit(): void {
    this.toast($r('app.string.menu_edit'));
  }

  private onSearch(): void {
    this.toast($r('app.string.menu_search'));
  }

  private onAbout(): void {
    this.toast($r('app.string.menu_about'));
  }

  /** 迷你栏里的「添加任务」。真实新增流程未做，先给可见反馈 */
  private onAdd(): void {
    this.toast($r('app.string.action_add_task'));
  }

  build() {
    HdsNavigation(this.navPathStack) {
      HdsTabs({ barPosition: BarPosition.End }) {
        TabContent() {
          A_TaskList()
        }
        .tabBar(MainTabBar.TASK_LIST)

        TabContent() {
          A_Settings()
        }
        .tabBar(MainTabBar.SETTINGS)
      }
      .vertical(false)
      .scrollable(false)
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      // —— 悬浮页签栏 + 迷你栏，逐项照官方示例 ——
      // barOverlap：TabBar 背后变模糊并叠加在 TabContent 之上（API 22 就能用）
      .barOverlap(true)
      .barFloatingStyle({
        barWidth: { smallWidth: 200, mediumWidth: 300, largeWidth: 400 },
        barBottomMargin: 28,
        // ⚠️ 示例的 mask 是 '#66F1F3F5'（40% 透明）。官方 token 只有不透明的
        // `ohos_id_color_sub_background`(#fff1f3f5) 和全透明的 `..._transparent`(#00ffffff)，
        // 没有 40% 那一档。为了「质感和官方一致」这里保留示例的字面值（已知偏离「不许裸色值」的约定）。
        gradientMask: {
          maskColor: '#66F1F3F5',
          maskHeight: 92
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        },
        miniBar: {
          miniBarBuilder: () => {
            this.miniBarBuilder();
          }
        }
      })
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .hideBackButton(true)
    .titleBar({
      style: MainTitleBar.STYLE,
      content: {
        title: { mainTitle: this.navTitle },
        menu: this.navMenu
      }
    })
    .width('100%')
    .height('100%')
  }
}
