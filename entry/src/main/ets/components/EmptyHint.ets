/*
 * 空状态提示（独立组件，两个页面共用）：
 * 「官方风格图示 + 一句灰字」，用于**任务列表页的空态**与**搜索页的两种空态**
 * （需求方 2026-10-16：「没输入关键词的时候显示同样的表示无任务的图标」「搜不到结果 显示图标+无结果」）。
 *
 * 观感沿用需求方 2026-10-16 定下的那套：
 *  · 图示用**官方 Symbol `inbox`** 放大到 96vp（官方没有随 SDK 发"空状态插图"这类位图资源，
 *    `sys.media` 里没有 empty 类图，Symbol 是唯一能做到"官方风格"的图示）；
 *  · 颜色两处都取**比页面背景（#f1f3f5）更深的官方灰**：图示 `gray_03`(#d1d1d6)、
 *    文字 `ohos_id_color_text_tertiary`(#66182431)；
 *  · 以后要换真插图，把 `SymbolGlyph` 换成 `Image($r('app.media.xxx'))` 即可，布局不用动。
 */
import { LengthMetrics } from '@kit.ArkUI';

/** 图示尺寸（vp）：接近官方空状态插图的观感档位 */
const EMPTY_ICON_SIZE_VP: number = 96;

@ComponentV2
export struct EmptyHint {
  /**
   * 提示文案（只有一句话，图示是纯装饰）。
   * ⚠️ 类型必须是 `Resource`（不能写 `ResourceStr`）：`Text()` 的两个重载分别只吃 `string` 与 `Resource`，
   * 传联合类型 `ResourceStr` 会报「No overload matches this call」（编译实测）。
   */
  @Require @Param message: Resource;

  build() {
    Column() {
      SymbolGlyph($r('sys.symbol.inbox'))
        .fontSize(`${EMPTY_ICON_SIZE_VP}vp`)
        .fontColor([$r('sys.color.gray_03')])

      Text(this.message)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
        .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    // 图示是纯装饰，无障碍只播报那一句文案
    .accessibilityLevel('yes')
    .accessibilityText(this.message)
  }
}
