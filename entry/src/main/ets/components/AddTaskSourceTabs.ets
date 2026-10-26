import { ThemeStore } from '../utils/Theme';
/*
 * 「添加任务」的**来源选择**（截图 / 录音 / 文本）—— 胶囊型单选按钮组，**图标与文字同一行**。
 *
 * 需求方 2026-10-17：「用官方的 SegmentButtonV2 做一个图标文本按钮组…」→「先把图标和文字放一行吧」。
 *
 * 🔴 **为什么这里不用官方 `CapsuleSegmentButtonV2` 了（查证结论，不是偷懒）**
 * 官方 `SegmentButtonV2` 的选项（`SegmentButtonV2Item`）**同时给 `text` + `symbol`** 就是它说的「图文混合」，
 * 而图文混合的排版是**组件内部写死的上下两行**，没有任何横排开关：
 *  · 官方文档 `itemMinHeight` / `buttonMinHeight` 两处原文 —— 「只有纯文本或者纯图标选项时：
 *    `$r('sys.float.segment_button_v2_singleline_selected_height')`；**有图文混合的选项时：
 *    `$r('sys.float.segment_button_v2_doubleline_selected_height')`**」→ 一出现图文混合就自动换成**双行**档高；
 *  · 全部可配项（items / selectedIndex / itemSpace / itemFontSize / itemIconSize / itemSymbolFontSize /
 *    itemPadding / itemBorderRadius / … / backgroundSystemMaterial）里**没有**「图标与文字排列方向」这一项。
 * 所以「一行」只能用同样的官方 token 自绘一个胶囊按钮组。**要退回官方版**＝把 `build()` 里那段换成
 * `CapsuleSegmentButtonV2({ items: …, selectedIndex: …, $selectedIndex: … })`（items 用 `text`+`symbol`），
 * 其余（`AddTaskSource` 枚举、对外的 `@Param`/`@Event` 契约、`AddTaskSheet` 的接法）都不用动。
 *
 * 自绘但**不造视觉**：颜色/圆角/内外边距/高度全部取官方 SegmentButtonV2 自己用的那套 token ——
 *  · 轨道底板：`sys.color.segment_button_v2_tab_button_background` ＋
 *    圆角 `sys.float.segment_button_v2_background_corner_radius` ＋ 内边距 `sys.float.padding_level1`
 *    （＝官方 `buttonPadding` 默认值）；
 *  · 选中块：`sys.color.segment_button_v2_tab_selected_item_background` ＋
 *    圆角 `sys.float.segment_button_v2_selected_corner_radius`；
 *  · 选项内边距：上/下 `sys.float.padding_level2`、左/右 `sys.float.padding_level4`
 *    （＝官方 `itemPadding` 默认值）；
 *  · 选项高度：`sys.float.segment_button_v2_singleline_selected_height`（一行版就用**单行**档，不用双行档）；
 *  · 文字/图标色：选中 `sys.color.font_on_primary`、未选中 `sys.color.font_secondary`（＝官方 `Capsule*` 默认值）；
 *  · 字号 14fp、Symbol 字号 20、字重 `Medium`（＝官方 `itemFontSize` / `itemSymbolFontSize` / `itemFontWeight`
 *    的默认值，两个尺寸官方签名只吃 `number`/`LengthMetrics`，所以提成常量并在此标注出处）。
 *
 * 图标名都核过 SDK 的 `ets/build-tools/ets-loader/sysResource.js` 符号表：`screenshot` / `mic` / `doc_plaintext`。
 */
import { LengthMetrics } from '@kit.ArkUI';

/** 选项文字字号（fp）：＝官方 `SegmentButtonV2.itemFontSize` 默认值 14fp */
const ITEM_FONT_SIZE_FP: number = 14;

/** 选项 Symbol 图标字号（vp）：＝官方 `SegmentButtonV2.itemSymbolFontSize` 默认值 20fp */
const ITEM_SYMBOL_SIZE_VP: number = 20;

/** 图标与文字之间的间距（vp）：取官方 `sys.float.padding_level2`(4vp)，`Row` 的 `space` 只吃 number */
const ITEM_ICON_TEXT_GAP_VP: number = 4;

/** 一个来源选项的静态配置；下标顺序即 `AddTaskSource` 的取值 */
interface AddTaskSourceItem {
  source: AddTaskSource;
  symbol: Resource;
  label: Resource;
}

/**
 * 「添加任务」的三种来源入口，**取值就是按钮组的下标**（0/1/2）。
 * 顺序与需求方 2026-10-17 的口径一致：截图 → 录音 → 文本，默认第 0 个（截图）。
 *
 * 放这个文件而不是 `model/Models.ets`：它只描述**这个按钮组的选项顺序**，不是任务的业务字段
 * （任务侧的「来源通道」是 `model` 里的 `TaskSource`，另一件事，别混）。
 */
export enum AddTaskSource {
  SCREENSHOT = 0,
  VOICE = 1,
  TEXT = 2
}

@ComponentV2
export struct AddTaskSourceTabs {
  /** 视觉个性化：M3 primary（全局 MD3 化） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 当前选中项下标 —— **单向**从父组件来（选中态的唯一真源在 `AddTaskSheet`） */
  @Require @Param selectedIndex: number;
  /** 用户点了哪一项 —— 父组件据此改自己的状态；本组件不持有选中态 */
  @Event onSelect: (index: number) => void = () => {};

  private items: AddTaskSourceItem[] = [
    { source: AddTaskSource.SCREENSHOT, symbol: $r('sys.symbol.screenshot'), label: $r('app.string.source_screenshot') },
    { source: AddTaskSource.VOICE, symbol: $r('sys.symbol.mic'), label: $r('app.string.source_voice') },
    { source: AddTaskSource.TEXT, symbol: $r('sys.symbol.doc_plaintext'), label: $r('app.string.source_text') }
  ];

  /** 选中态判定：只依赖 `selectedIndex` 这个状态，所以 `@Builder` 里的分支会跟着重渲染 */
  private isSelected(index: number): boolean {
    return this.selectedIndex === index;
  }

  /** 选项文字/图标色：官方 `CapsuleSegmentButtonV2` 的默认值（选中反色、未选中次级） */
  private contentColor(index: number): ResourceColor {
    return this.isSelected(index) ? this.themeStore.scheme.onPrimary : $r('sys.color.font_secondary');
  }

  /**
   * 单个选项：**图标 + 文字同一行**。
   * 参数只传「不会变的静态配置 + 下标」，选中态在内部读 `this.selectedIndex`（`@Builder` 值参数不刷新，别把状态传进来）。
   */
  @Builder
  sourceItem(item: AddTaskSourceItem, index: number) {
    Row({ space: ITEM_ICON_TEXT_GAP_VP }) {
      SymbolGlyph(item.symbol)
        .fontSize(ITEM_SYMBOL_SIZE_VP)
        .fontColor([this.contentColor(index)])

      Text(item.label)
        .fontSize(ITEM_FONT_SIZE_FP)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.contentColor(index))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    // 三个选项均分轨道宽度
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    // 一行版官方档高：`segment_button_v2_singleline_selected_height`（双行是 `..._doubleline_...`）
    .height($r('sys.float.segment_button_v2_singleline_selected_height'))
    // 官方 `itemPadding` 默认值：上/下 `padding_level2`、左/右 `padding_level4`
    // ⚠️ 带 `start`/`end` 的重载吃 `LocalizedPadding`（字段是 `LengthMetrics`），所以要走 `LengthMetrics.resource`
    .padding({
      top: LengthMetrics.resource($r('sys.float.padding_level2')),
      bottom: LengthMetrics.resource($r('sys.float.padding_level2')),
      start: LengthMetrics.resource($r('sys.float.padding_level4')),
      end: LengthMetrics.resource($r('sys.float.padding_level4'))
    })
    .borderRadius($r('sys.float.segment_button_v2_selected_corner_radius'))
    // ⚠️ 必须用 **capsule** 那一档的底色：`..._tab_selected_item_background` 是「页签型」的白色底，
    // 配 `font_on_primary`(白字) 就成了白底白字（实测踩到过：`.cache/inline-1-default.png` 第一项是空白白块）。
    .backgroundColor(this.isSelected(index)
      // 2026-10-19 全局 MD3：选中块用 M3 primary（原来是官方胶囊蓝）
      ? this.themeStore.scheme.primary
      : Color.Transparent)
    .onClick(() => {
      this.onSelect(index);
    })
    .accessibilityText(item.label)
  }

  build() {
    // 轨道：官方胶囊底板（底色 + 大圆角 + `padding_level1` 内边距）
    Row() {
      ForEach(this.items, (item: AddTaskSourceItem, index: number) => {
        this.sourceItem(item, index);
      }, (item: AddTaskSourceItem) => `${item.source}`)
    }
    .width('100%')
    .padding($r('sys.float.padding_level1'))
    // 2026-10-25：轨道底色先是去掉系统冷灰（`segment_button_v2_capsule_button_background`），
    // 再按作者「改成列表页面 card 的 bg 取色」定成 `scheme.surfaceContainerLow` ——
    // 与任务卡片同一个 M3 角色（半模态面板仍是 `surface`，正好复刻"卡片浮在页面上"的层次）。
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius($r('sys.float.segment_button_v2_background_corner_radius'))
  }
}
