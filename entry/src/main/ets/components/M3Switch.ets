/*
 * MD3 风格的开关（`Toggle` + `ToggleType.Switch` 的**统一取色**）。
 *
 * ## 为什么要有这个组件
 *
 * `Toggle` 的选中态默认取官方强调色 `sys.color.ohos_id_color_emphasize`（系统蓝，见 SDK
 * `component/toggle.d.ts` 里 `selectedColor` 的 Default value 注释）。而本工程的强调色是
 * `ThemeStore.scheme`（M3 从种子色派生，见 `utils/M3Palette.ets`）—— 于是设置页换成橙/青主题后，
 * 开关还是蓝的（2026-10-25 作者报的问题）。
 *
 * 修法不是「在两个用到处各补两行属性」，而是把 Switch 收成这一个组件：
 * **全工程要开关就只用它**，这样"所有开关跟随主题"是结构性保证，
 * 以后新增的开关不会再漏取色（与 `ToggleSlider` / `SegmentRow` / `SearchField` 同一套组件化口径）。
 *
 * ## 颜色口径（M3 Switch）
 *
 *   · 选中轨道   = `primary`
 *   · 未选中轨道 = `surfaceContainerHighest`
 *   · 滑块       = 选中 `onPrimary` / 未选中 `outline`
 *     （M3 的 off 态滑块是**描边灰**，不是白；官方默认 `ohos_id_color_foreground_contrary` 纯白
 *      压在浅色轨道上几乎看不见，所以这里显式给）
 *
 * ## API 出处（SDK `component/toggle.d.ts`，已核实，不凭记忆）
 *
 *   · `selectedColor(value: ResourceColor): ToggleAttribute`   @since 8   仅作用于**选中**轨道
 *   · `switchStyle(value: SwitchStyle): ToggleAttribute`       @since 12  `SwitchStyle` 字段：
 *     `pointRadius` / `unselectedColor` / `pointColor` / `trackBorderRadius`
 *
 * ⚠️ `SwitchStyle` **没有 `trackColor`** —— 选中轨道只能走 `selectedColor`，两者要一起写才完整。
 * 工程 `targetSdkVersion` 是 `6.0.2(22)` ≥ 12，`switchStyle` 可用。
 */
import { ThemeStore } from '../utils/Theme';

@ComponentV2
export struct M3Switch {
  /** 当前是否打开。**由数据决定**：用户点一下只发事件，状态不在这里改（失败要能回滚） */
  @Require @Param isOn: boolean;
  /** 用户切换了：父组件据此写数据 / 打接口 */
  @Event onToggle: (isOn: boolean) => void = () => {};

  /** 视觉个性化：M3 色系（与页面同一份主题实例） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /**
   * 注意这里**不设 width / height**：尺寸沿用官方 Switch 默认档，
   * 这样把它替换进已有的 `Toggle` 位置时布局一模一样，只换颜色。
   *
   * 滑块色随开/关变 —— `switchStyle` 的 `pointColor` 不区分状态，所以按 `isOn` 传值。
   */
  build() {
    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
      .selectedColor(this.themeStore.scheme.primary)
      .switchStyle({
        unselectedColor: this.themeStore.scheme.surfaceContainerHighest,
        pointColor: this.isOn ? this.themeStore.scheme.onPrimary : this.themeStore.scheme.outline
      })
      .onChange((isOn: boolean) => {
        this.onToggle(isOn);
      })
  }
}
