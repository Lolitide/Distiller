/*
 * M3 **胶囊分段组** —— 全项目共用的"n 选一"控件，取色与「添加任务」的
 * 截图 / 录音 / 文本 那一组**完全一致**（需求方 2026-10-27：「把这个改成和添加任务里面的
 * 截图、录音、文本一样的 md 取色组件」）。
 *
 * ## 取色来源（不自己造视觉）
 *
 * 颜色/圆角/内边距/高度全部沿用官方 `CapsuleSegmentButtonV2` 的那套 token，
 * 与 `AddTaskSourceTabs` 里已验证过的那一版逐项对齐：
 *
 *  · 轨道底板：`scheme.surfaceContainerLow`（M3，与任务卡片同一个角色）＋
 *    圆角 `sys.float.segment_button_v2_background_corner_radius` ＋ 内边距 `sys.float.padding_level1`；
 *  · 选中块：`scheme.primary` 底 ＋ `scheme.onPrimary` 字/图标（全局 MD3 化后的口径）；
 *  · 未选中：透明底 ＋ `sys.color.font_secondary`；
 *  · 选项高度：`sys.float.segment_button_v2_singleline_selected_height`（一行版档高）；
 *  · 选项内边距：上/下 `padding_level2`、左/右 `padding_level4`（＝官方 `itemPadding` 默认值）。
 *
 * ## 与 `AddTaskSourceTabs` 的关系
 *
 * 那里是"三个带图标的来源页签"，这里是通用版：**图标可选**、宽度可均分也可按内容收缩。
 * `AddTaskSourceTabs` 现在直接复用本组件（保证两处视觉永远一致），
 * 设置页的「卡片密度」等纯文字分段也用它。
 *
 * ⚠️ 仍然遵守本工程踩过多次的硬规则：**选中态用 `@Param` 传进来**（响应式），
 * 不要用 `@Builder` 的值参数传 `selected` —— 那样点了不会刷新。
 */
import { LengthMetrics } from '@kit.ArkUI';
import { ThemeStore } from '../utils/Theme';

/** 选项文字字号（fp）：＝官方 `SegmentButtonV2.itemFontSize` 默认值 14fp */
const ITEM_FONT_SIZE_FP: number = 14;

/** 选项 Symbol 图标字号（vp）：＝官方 `SegmentButtonV2.itemSymbolFontSize` 默认值 20fp */
const ITEM_SYMBOL_SIZE_VP: number = 20;

/** 图标与文字之间的间距（vp）：官方 `sys.float.padding_level2`(4vp)，`Row` 的 `space` 只吃 number */
const ITEM_ICON_TEXT_GAP_VP: number = 4;

/** 一个分段选项：`key` 只用于 `ForEach` 的稳定标识 */
export interface M3SegmentOption {
  key: string;
  /** 显示文案（可以是字符串或资源） */
  label: ResourceStr;
  /**
   * 读屏文案（**纯字符串**）。
   *
   * ⚠️ 必须单独给一个 `string`：`accessibilityText` 只有 `(value: string)` 与 `(text: Resource)`
   * 两个重载，传 `ResourceStr`（`string | Resource`）会报 `No overload matches this call`
   * （2026-10-27 实测踩到）。所以显示用 `label`、读屏用 `a11y`，两者内容通常相同。
   */
  a11y: string;
  /** 可选：给了就画"图标 + 文字一行"，不给就是纯文字 */
  symbol?: Resource;
}

@ComponentV2
export struct M3SegmentGroup {
  /** 视觉个性化：M3 primary / surfaceContainerLow */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 选项列表 */
  @Require @Param options: M3SegmentOption[];
  /** 当前选中下标（响应式；唯一真源在父组件） */
  @Require @Param selectedIndex: number;
  /** 点了某一项 */
  @Event onSelect: (index: number) => void = () => {};
  /** 是否撑满父容器宽度（放在列表行右半边时传 `false`） */
  @Param fillWidth: boolean = true;
  /** 各项是否均分宽度；`false` 时按各自内容宽度排（纯文字两档用这个） */
  @Param equalWidth: boolean = true;
  /**
   * 是否放在**卡片上**（`scheme.surfaceContainerLow` 那层底）。
   *
   * 轨道默认用 `surfaceContainerLow` —— 在半模态面板（`surface`）上刚好浮起来一层；
   * 但设置页那种卡片本身就是 `surfaceContainerLow`，轨道会与之同色、整条看不见
   * （2026-10-27 实机截图确认）。所以放在卡片上时轨道要抬高一层到 `surfaceContainerHigh`。
   */
  @Param onCard: boolean = false;

  /** 选中态判定：只依赖 `selectedIndex`，状态一变整组重渲染 */
  private isSelected(index: number): boolean {
    return this.selectedIndex === index;
  }

  /** 文字/图标色：选中反色（`onPrimary`），未选中次级文字色 */
  private contentColor(index: number): ResourceColor {
    return this.isSelected(index)
      ? this.themeStore.scheme.onPrimary
      : $r('sys.color.font_secondary');
  }

  build() {
    // 轨道：官方胶囊底板（M3 底 + 大圆角 + `padding_level1` 内边距）
    Row() {
      ForEach(this.options, (item: M3SegmentOption, index: number) => {
        Row({ space: item.symbol !== undefined ? ITEM_ICON_TEXT_GAP_VP : 0 }) {
          if (item.symbol !== undefined) {
            SymbolGlyph(item.symbol)
              .fontSize(ITEM_SYMBOL_SIZE_VP)
              .fontColor([this.contentColor(index)])
          }
          Text(item.label)
            .fontSize(ITEM_FONT_SIZE_FP)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.contentColor(index))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        // 均分宽度 vs 按内容宽度
        .layoutWeight(this.equalWidth ? 1 : 0)
        .justifyContent(FlexAlign.Center)
        // 一行版官方档高
        .height($r('sys.float.segment_button_v2_singleline_selected_height'))
        // 官方 `itemPadding` 默认值：上/下 `padding_level2`、左/右 `padding_level4`
        // ⚠️ 带 `start`/`end` 的重载吃 `LocalizedPadding`（字段是 `LengthMetrics`）
        .padding({
          top: LengthMetrics.resource($r('sys.float.padding_level2')),
          bottom: LengthMetrics.resource($r('sys.float.padding_level2')),
          start: LengthMetrics.resource($r('sys.float.padding_level4')),
          end: LengthMetrics.resource($r('sys.float.padding_level4'))
        })
        .borderRadius($r('sys.float.segment_button_v2_selected_corner_radius'))
        .backgroundColor(this.isSelected(index) ? this.themeStore.scheme.primary : Color.Transparent)
        .onClick(() => {
          this.onSelect(index);
        })
        .accessibilityText(item.a11y)
      }, (item: M3SegmentOption) => item.key)
    }
    // 均分时撑满；按内容宽度时让轨道自己收缩
    .width(this.fillWidth ? '100%' : undefined)
    .padding($r('sys.float.padding_level1'))
    // 轨道底色：面板上（半模态 `surface`）用 `surfaceContainerLow`，与任务卡片同角色；
    // 卡片上再抬一档到 `surfaceContainerHigh`，否则与卡片同色、轨道看不见
    .backgroundColor(this.onCard
      ? this.themeStore.scheme.surfaceContainerHigh
      : this.themeStore.scheme.surfaceContainerLow)
    .borderRadius($r('sys.float.segment_button_v2_background_corner_radius'))
  }
}
