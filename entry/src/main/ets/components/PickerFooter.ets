/*
 * 选择器面板底部那一条「取消 / 确定」—— 日期时间面板、单列文本面板共用。
 *
 * 抽出来是因为 `DateTimePickerBody` 与 `OptionPickerBody` 都要这一条，
 * 不抽就得两份（`references/02-编码规约.md` §10 规则 3：长得像就必须是同一个组件）。
 *
 * 造型照官方弹窗：等分、中间一条竖细分割线、纯文字、强调色。
 * ⚠️ 高度/竖线**必须给普通数字**（vp）：给 `LengthMetrics` 不生效 —— 整条 Row 会撑满、
 * 竖线被拉长、按钮被挤出屏幕（这一坑在 `DateTimePickerBody` 顶部注释里记了实测）。
 */
/** 底部条高度（vp）：48vp ＝ 官方可点高度 */
const FOOTER_HEIGHT_VP: number = 48;

/** 中间竖细线长度（vp） */
const FOOTER_DIVIDER_VP: number = 20;

@ComponentV2
export struct PickerFooter {
  /** 点「取消」 */
  @Event onCancel: () => void = () => {};
  /** 点「确定」 */
  @Event onConfirm: () => void = () => {};

  build() {
    Row() {
      Text($r('app.string.action_cancel'))
        .layoutWeight(1)
        .height(FOOTER_HEIGHT_VP)
        .textAlign(TextAlign.Center)
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          this.onCancel();
        })

      Divider()
        .vertical(true)
        .height(FOOTER_DIVIDER_VP)
        .color($r('sys.color.comp_divider'))

      Text($r('app.string.action_confirm'))
        .layoutWeight(1)
        .height(FOOTER_HEIGHT_VP)
        .textAlign(TextAlign.Center)
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          this.onConfirm();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }
}
