/*
 * 三档（或 n 档）分段按钮 —— 全项目共用**一个**实现。
 *
 * ## 为什么必须抽成组件，而不是继续用 `@Builder`
 *
 * 原来有 4 个文件各自写了一份 `@Builder segment(text, selected, onTap)`，
 * 全部有同一个毛病：**点了没反应**。
 *
 * 根因是 ArkUI 的硬规则：`@Builder` 的**值参数不随状态刷新** ——
 * 传进去的 `selected` 只在首次构建时求值，状态变了以后 Builder 不会用新值重跑。
 * 实测证据：点设置页「主题色 → 青」前后两张截图 **SHA256 完全相同**。
 *
 * 改用 `@ComponentV2` + `@Param`：`@Param` 是**响应式**的，
 * 父组件传入的 `selectedIndex` 一变，本组件立刻重渲染，高亮跟着走。
 *
 * ## 用法
 *
 * ```
 * SegmentRow({
 *   options: ['普通', '重要', '紧急'],
 *   selectedIndex: this.priorityIndex,
 *   onSelect: (index: number) => { this.applyPriority(index); }
 * })
 * ```
 *
 * ⚠️ `selectedIndex` 要传**状态值**（`@Computed` 或直接读 `@Local`），
 * 不要传一次性算死的常量，否则依旧不会更新。
 */
import { Theme, ThemeStore } from '../utils/Theme';

/** 分段按钮高度（vp） */
const SEGMENT_HEIGHT_VP: number = 32;
/** 分段按钮之间的间距（vp） */
const SEGMENT_GAP_VP: number = 8;
/** 单颗按钮左右内边距（vp） */
const SEGMENT_SIDE_PADDING_VP: number = 12;

@ComponentV2
export struct SegmentRow {
  /** 档位文案（2~5 个为宜；再多请改用选择器弹窗） */
  @Require @Param options: string[];
  /** 当前选中下标；`-1` 表示一个都不选中（如"未设置"） */
  @Param selectedIndex: number = -1;
  /** 点了某一档 */
  @Event onSelect: (index: number) => void = () => {};
  /** 视觉个性化：选中态用 M3 primary / onPrimary（2026-10-19） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  build() {
    Row({ space: SEGMENT_GAP_VP }) {
      ForEach(this.options, (label: string, index: number) => {
        Text(label)
          .fontSize(Theme.FONT_BODY)
          .fontColor(this.selectedIndex === index
            ? this.themeStore.scheme.onSecondaryContainer
            : $r('sys.color.ohos_id_color_text_primary'))
          .height(SEGMENT_HEIGHT_VP)
          .padding({ left: SEGMENT_SIDE_PADDING_VP, right: SEGMENT_SIDE_PADDING_VP })
          .backgroundColor(this.selectedIndex === index
            ? this.themeStore.scheme.secondaryContainer
            : $r('sys.color.comp_background_secondary'))
          .borderRadius(SEGMENT_HEIGHT_VP / 2)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onSelect(index);
          })
          .accessibilityText(label)
      }, (label: string, index: number) => `${label}-${index}`)
    }
    .justifyContent(FlexAlign.Start)
  }
}
