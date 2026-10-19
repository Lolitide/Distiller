/*
 * 锚定浮窗选择器 —— 点一行，在**这一行下面弹出一个小菜单**，当前项打勾。
 *
 * 作者 2026-10-19：「设置中的提醒提前量、解析方式，添加任务中的设置重复、来源、信息重要性，
 * 改成图二所示的浮窗组件（和图二的内容无关）」——
 * 图二是系统日历里点「重复」后紧贴该行弹出的竖排菜单，不是整屏底部面板。
 *
 * ## 为什么用 `bindPopup` 而不是 `bindSheet`
 *
 * `bindSheet` 是**底部面板**（手机上一律贴底、带遮罩、整屏宽），和参考图完全不是一个东西；
 * `bindPopup` 是**锚定浮窗**：贴着宿主控件弹、宽度随内容、点外部自动收起 —— 正是图二。
 *
 * ## M3 长相
 *
 *   · 容器色 `surface-container-high`（M3 菜单 = elevation 3）；
 *   · 圆角 16vp（M3 shape scale 的 large，菜单常用档）；
 *   · 每项高 48vp（M3 最小触摸目标）、文字 `bodyLarge`；
 *   · 选中项在右侧打勾，同时用 `primary` 着色 —— 不只靠颜色传达状态（无障碍要求）。
 *
 * ## 用法
 *
 * ```
 * PopupSelector({
 *   label: '提醒提前量',
 *   value: this.remindLeadLabel(this.remindLead),
 *   options: [...],
 *   selectedIndex: this.remindLeadDraft,
 *   onSelect: (i: number) => { this.applyRemindLead(...); }
 * })
 * ```
 */
import { Theme, ThemeStore } from '../utils/Theme';

/** 每项高度（vp）：M3 最小触摸目标 48 */
const ITEM_HEIGHT_VP: number = 48;
/** 浮窗圆角（vp）：M3 shape large */
const POPUP_RADIUS_VP: number = 16;
/** 浮窗内边距（vp）：4 的倍数 */
const POPUP_PADDING_VP: number = 8;
/** 行高（vp）：与设置页其它行一致 */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 左列标签宽度（vp） */
const LABEL_WIDTH_VP: number = 108;

@ComponentV2
export struct PopupSelector {
  /** 左侧标签 */
  @Require @Param label: ResourceStr;
  /** 右侧当前值（响应式，`@Param` 会跟着刷新） */
  @Param value: string = '';
  /** 选项文案 */
  @Require @Param options: string[];
  /** 当前选中下标 */
  @Param selectedIndex: number = -1;
  /** 选了某一项（组件只上报，写回由调用方负责） */
  @Event onSelect: (index: number) => void = () => {};

  /** 浮窗显隐 */
  @Local shown: boolean = false;
  @Local themeStore: ThemeStore = ThemeStore.instance();

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
      this.shown = true;
    })
    .bindPopup(this.shown, {
      builder: this.menu(),
      placement: Placement.Bottom,
      // 贴着宿主行左边缘弹，宽度随内容
      popupColor: this.themeStore.scheme.surfaceContainerHigh,
      radius: POPUP_RADIUS_VP,
      enableArrow: false,
      focusable: true,
      onStateChange: (event) => {
        // 点外部 / 返回键收起时把状态同步回来，否则下次点行弹不出来
        if (!event.isVisible) {
          this.shown = false;
        }
      }
    })
  }

  @Builder
  menu() {
    Column() {
      ForEach(this.options, (option: string, index: number) => {
        Row() {
          Text(option)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .layoutWeight(1)
            .maxLines(1)
            .textAlign(TextAlign.Start)

          if (this.selectedIndex === index) {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(Theme.FONT_BODY)
              .fontColor([this.themeStore.scheme.primary])
              .margin({ left: Theme.GAP_S })
          }
        }
        .width('100%')
        .height(ITEM_HEIGHT_VP)
        .padding({ left: Theme.GAP_M, right: Theme.GAP_M })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.shown = false;
          this.onSelect(index);
        })
        .accessibilityText(option)
      }, (option: string, index: number) => `${option}-${index}`)
    }
    .width(200)
    .padding(POPUP_PADDING_VP)
    .alignItems(HorizontalAlign.Start)
  }
}
