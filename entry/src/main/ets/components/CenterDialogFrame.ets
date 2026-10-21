/*
 * M3 居中对话框外框 —— 给 `promptAction.openCustomDialog` 当内容容器用。
 *
 * ## 为什么单独抽一个"框"
 *
 * `openCustomDialog` 只负责把内容摆到屏幕中央（并给蒙层），**容器长相要自己画**。
 * 三处日期面板（详情页提醒/截止、添加任务到期）都需要同一副长相，所以抽出来。
 *
 * ## 长相按 M3 对话框规范（作者 2026-10-19 指定的设计语言）
 *
 *   · 容器色 `surface-container-high`（M3 elevation 3，浮起高于卡片）；
 *   · 圆角 **extra-large = 28vp**（M3 对话框专用）；
 *   · 内边距 **24vp**（M3 对话框标准）；
 *   · 不加大阴影 —— M3 优先用"色调抬升"表达高度，阴影只作辅助。
 *
 * ## 用法
 *
 * ```
 * openCustomDialog({
 *   builder: () => { this.dateTimeDialog() },
 *   alignment: DialogAlignment.Center,
 *   isModal: true
 * })
 *
 * @Builder dateTimeDialog() {
 *   CenterDialogFrame() {
 *     DateTimePickerBody({ ... })
 *   }
 * }
 * ```
 */
import { Theme, ThemeStore } from '../utils/Theme';

/** M3 对话框内边距（vp）：规范 24dp */
const DIALOG_PADDING_VP: number = 24;
/** 横向内边距（vp）：收窄到 16，给「年月日时分」五列滚轮腾地方 */
const DIALOG_PADDING_H_VP: number = 16;
/** M3 对话框圆角（vp）：shape scale 的 extra-large */
const DIALOG_RADIUS_VP: number = 28;
/** 对话框最小宽度（vp）：M3 规范 280dp */
const DIALOG_MIN_WIDTH_VP: number = 280;

@ComponentV2
export struct CenterDialogFrame {
  /** 内容（各个面板的具体 UI） */
  @BuilderParam content: () => void;
  /** 视觉个性化：容器色取 `surface-container-high` */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .constraintSize({ minWidth: DIALOG_MIN_WIDTH_VP })
    .padding({
      left: DIALOG_PADDING_H_VP,
      right: DIALOG_PADDING_H_VP,
      top: DIALOG_PADDING_VP,
      bottom: DIALOG_PADDING_VP
    })
    .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
    .borderRadius(DIALOG_RADIUS_VP)
    // 内容再宽也不许画出圆角外：窄窗口下五列滚轮会撑破弹窗宽度，
    // 加裁剪后只会被切在容器里，不会压在圆角外的背景上（作者图 3 箭头所指的那个现象）。
    .clip(true)
  }
}

/** 面板里的小标题（如「设置到期时间」）：M3 `titleMedium` 16/24 字重 500 */
@ComponentV2
export struct DialogTitle {
  @Require @Param text: ResourceStr;

  build() {
    Text(this.text)
      .fontSize(Theme.FONT_TITLE)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .width('100%')
      .maxLines(1)
      .textAlign(TextAlign.Start)
      .padding({ bottom: Theme.GAP_M })
  }
}
