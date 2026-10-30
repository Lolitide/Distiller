/*
 * AI 生成内容 · 显式标识条（2026-10-29 合规改造）。
 *
 * 依据《人工智能生成合成内容标识办法》第四条 / 第七条与华为 AGC 要求：
 * 文本标识必须同时含「AI / 人工智能」与「生成 / 合成」两个要素，且要显示在生成内容附近。
 *
 * 用法：任务详情页在属性卡上方挂一条；添加任务半模态在 AI 生成完成后挂一条。
 * 样式刻意弱化（小字号 + 容器底色），但不隐藏 —— 它是合规要求的常驻标识，不是提示气泡。
 */
import { ThemeStore } from '../utils/Theme';

/** 标识条左右内边距（vp） */
const BAR_PADDING_VP: number = 10;

@ComponentV2
export struct AiLabelBar {
  /**
   * 角标文字，默认「AI生成」。
   * 保持成 `ResourceStr` 而不是写死字符串：以后要出多语种只改资源。
   */
  @Param badge: ResourceStr = $r('app.string.ai_badge');
  /** 说明文字，默认「以下内容由 AI 生成，仅供参考，请核对后使用」 */
  @Param message: ResourceStr = $r('app.string.ai_notice');
  @Local themeStore: ThemeStore = ThemeStore.instance();

  build() {
    Row({ space: 8 }) {
      // 角标：深蓝底 + 浅色字（2026-10-29 需求方：「背景得是深蓝，不是黑色」）。
      // 用 M3 语义色 `primary / onPrimary` 而不是写死色值：换主题色时它跟着变，且与页面底色始终有对比。
      Text(this.badge)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeStore.scheme.onPrimary)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(this.themeStore.scheme.primary)
        .borderRadius(6)
        .maxLines(1)

      Text(this.message)
        .fontSize(12)
        .fontColor(this.themeStore.scheme.onSurfaceVariant)
        .lineHeight('17vp')
        .flexShrink(1)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    // 去掉浅色背景框（2026-10-29 需求方）：只留角标与一行说明，直接铺在页面底色上
    // 上留白在 10vp 基础上再收 5vp（2026-10-29 需求方）
    .padding({ top: BAR_PADDING_VP - 5, bottom: BAR_PADDING_VP })
    // 整行居中（2026-10-29 需求方：「那一行要居中」）
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}
