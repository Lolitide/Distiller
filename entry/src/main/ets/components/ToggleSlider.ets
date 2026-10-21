/*
 * 二档（n 档）**滑动控件** —— 一个会滑动的白色滑块在两个选项之间移动。
 *
 * ## 为什么不用 `SegmentRow`
 *
 * `SegmentRow` 是"每个选项各自是一个胶囊"，选中态是**换底色**，没有滑动过程。
 * 作者 2026-10-19 要的是「标准、紧凑做成二档滑动控件」——
 * 一条轨道 + 一块会滑过去的滑块，读起来是一个开关而不是一组按钮。
 *
 * ## 为什么是 `@ComponentV2` 而不是 `@Builder`
 *
 * 本工程已经踩过多次：**`@Builder` 的值参数不随状态刷新**。
 * 这个控件必须跟着 `selectedIndex` 动滑块，所以用 `@Param`（响应式）。
 *
 * ## 用法
 *
 * ```
 * ToggleSlider({
 *   options: ['标准', '紧凑'],
 *   selectedIndex: this.themeStore.density,
 *   onSelect: (index: number) => { this.themeStore.density = index; }
 * })
 * ```
 */
import { Theme } from '../utils/Theme';

/** 控件高度（vp） */
const SLIDER_HEIGHT_VP: number = 30;
/** 单个选项格宽度（vp） */
const SLOT_WIDTH_VP: number = 52;
/** 滑块相对轨道的内缩（vp）：滑块比轨道矮一圈，才看得出是"嵌在里面" */
const THUMB_INSET_VP: number = 2;
/** 滑块滑动时长（毫秒） */
const SLIDE_ANIM_MS: number = 200;

@ComponentV2
export struct ToggleSlider {
  /** 选项文案：目前只有两档，多于 3 个请改用选择器弹窗 */
  @Require @Param options: string[];
  /** 当前选中下标 */
  @Param selectedIndex: number = 0;
  /** 点了某一档 */
  @Event onSelect: (index: number) => void = () => {};

  @Computed
  get trackWidth(): number {
    return SLOT_WIDTH_VP * this.options.length;
  }

  @Computed
  get thumbWidth(): number {
    return SLOT_WIDTH_VP - THUMB_INSET_VP * 2;
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      // ① 滑块（白色药丸）：位置跟着 selectedIndex 走，带滑动动画
      Row()
        .width(this.thumbWidth)
        .height(SLIDER_HEIGHT_VP - THUMB_INSET_VP * 2)
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .borderRadius((SLIDER_HEIGHT_VP - THUMB_INSET_VP * 2) / 2)
        .margin({ left: THUMB_INSET_VP })
        .offset({ x: this.selectedIndex * SLOT_WIDTH_VP })
        .animation({ duration: SLIDE_ANIM_MS, curve: Curve.FastOutSlowIn })
        // 滑块只是装饰，点击交给整条轨道
        .hitTestBehavior(HitTestMode.None)

      // ② 两档文字：压在滑块上面，选中那档用主文字色、另一档用次级色
      Row() {
        ForEach(this.options, (label: string, index: number) => {
          Text(label)
            .fontSize(Theme.FONT_CAPTION)
            .fontWeight(this.selectedIndex === index ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedIndex === index
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary'))
            .width(SLOT_WIDTH_VP)
            .height(SLIDER_HEIGHT_VP)
            .textAlign(TextAlign.Center)
            .accessibilityText(label)
        }, (label: string, index: number) => `${label}-${index}`)
      }
    }
    .width(this.trackWidth)
    .height(SLIDER_HEIGHT_VP)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(SLIDER_HEIGHT_VP / 2)
    .clip(true)
    .onClick((event: ClickEvent) => {
      // 点左半 = 第 0 档，点右半 = 第 1 档（按相对位置算，不依赖子节点热区）
      const ratio: number = event.x / this.trackWidth;
      const index: number = Math.min(this.options.length - 1,
        Math.max(0, Math.floor(ratio * this.options.length)));
      this.onSelect(index);
    })
  }
}
