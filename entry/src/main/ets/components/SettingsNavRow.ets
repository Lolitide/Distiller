/*
 * 设置页「左标签 + 右值 + 可点」的一行。
 *
 * ## 为什么必须做成组件，而不能继续用 `@Builder navRow(label, value, kind)`
 *
 * 这是本工程反复踩的坑：**ArkUI 的 `@Builder` 值参数不随状态刷新**。
 * 之前那一行右侧的值是用 `@Builder navRow(..., value: string, ...)` 传进去的，
 * 于是出现了作者 2026-10-19 报的 bug：
 *
 *   > 选项选择完之后并不会显示为已选内容
 *
 * 实测复现：设置页选「紧凑」→ 任务列表的卡片高度**确实**从 68vp 变成 58vp（功能生效了），
 * 但设置页那一行右侧仍然显示「标准」—— 因为 `value` 是 Builder 的值参数，
 * `this.themeStore.density` 变了它也不会重跑。
 *
 * 改成 `@ComponentV2` + `@Param`（响应式）后，父组件传入的值一变就重渲染。
 *
 * ## 用法
 *
 * ```
 * SettingsNavRow({
 *   label: '提醒提前量',
 *   value: this.remindLeadLabel,
 *   onTap: () => { this.openSheet(SHEET_REMIND_LEAD); }
 * })
 * ```
 */
import { Theme } from '../utils/Theme';

/** 行高（vp） */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 左列标签宽度（vp）：几行共用同一宽度，右侧值才能对齐 */
const LABEL_WIDTH_VP: number = 108;

@ComponentV2
export struct SettingsNavRow {
  @Require @Param label: ResourceStr;
  /** 右侧当前值：**必须是响应式的状态值**，不能传一次性的常量 */
  @Param value: string = '';
  @Event onTap: () => void = () => {};

  build() {
    Row() {
      Text(this.label)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width(LABEL_WIDTH_VP)
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Text(this.value)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.End)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(Theme.FONT_CAPTION)
        .fontColor([$r('sys.color.icon_tertiary')])
        .margin({ left: Theme.GAP_S })
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onTap();
    })
  }
}
