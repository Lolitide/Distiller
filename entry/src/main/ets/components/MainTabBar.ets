/*
 * 底部页签栏（独立组件）—— `HdsTabs` 容器、两个页签、悬浮样式、迷你栏都归这个文件。
 *
 * · 页签栏：任务列表 / 设置（两个真正的页面）
 * · 迷你栏：居中的「+」图标格 + 「添加任务」文字；收起时被裁剪到只剩图标格（所以看到的是居中图标），
 *   展开后连文字一起显示 —— 结构照官方示例。
 * · 悬浮观感：`barOverlap`（API 22 可用）+ `barFloatingStyle`（含 `hdsMaterial` 光感材质，标注 6.1.0(23)）。
 * · 对外只暴露两个事件：页签切换、点「添加任务」。页面下标由外层持有（标题栏按钮要按页签变）。
 * 图标一律取官方 HarmonyOS Symbol。
 */
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { A_TaskList } from '../pages/A_TaskList';
import { A_Settings } from '../pages/A_Settings';

const TASK_LIST_TAB: BottomTabBarStyle = new BottomTabBarStyle(
  { normal: new SymbolGlyphModifier($r('sys.symbol.list_checkmark')) },
  $r('app.string.tab_task_list')
);

const SETTINGS_TAB: BottomTabBarStyle = new BottomTabBarStyle(
  { normal: new SymbolGlyphModifier($r('sys.symbol.gearshape')) },
  $r('app.string.tab_settings')
);

@ComponentV2
export struct MainTabBar {
  /** 当前页签下标，报给外层：标题栏按钮要按页签变（任务列表＝编辑+搜索；设置＝关于） */
  @Event onIndexChange: (index: number) => void = () => {};
  /** 迷你栏里的「添加任务」 */
  @Event onAdd: () => void = () => {};

  /**
   * 迷你栏内容：**居中的「+」图标格 + 「添加任务」文字**。
   * 结构照官方示例（示例首个元素即 `Column(){icon}.width(48).height(48).justifyContent(FlexAlign.Center)`）：
   * 收起时被 `enableMiniBarClip`（默认 true）裁到只剩这一格 → 看到的是**居中图标**；展开后连文字一起显示。
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
        // 袁正锟 2026-10-15：「这个字体再大一号」。
        // `bottom_tab_text_size_normal` 只有 12vp（没有更大的同族档），所以改用官方**字体阶梯**里上一档：
        // `ohos_id_text_size_body3`(12/14/13fp) ≈ 原来的档位，往上一档就是 `ohos_id_text_size_body2`(14/16/15fp)。
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
    }
    .height($r('sys.float.titlebar_icon_background_height'))
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onAdd();
    })
  }

  build() {
    HdsTabs({ barPosition: BarPosition.End }) {
      TabContent() {
        A_TaskList()
      }
      .tabBar(TASK_LIST_TAB)

      TabContent() {
        A_Settings()
      }
      .tabBar(SETTINGS_TAB)
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
      // 不设 miniBarStyle：默认就是**收起态**，对应「收起的时候是图标」
      miniBar: {
        miniBarBuilder: () => {
          this.miniBarBuilder();
        }
      }
    })
    .onChange((index: number) => {
      this.onIndexChange(index);
    })
  }
}
