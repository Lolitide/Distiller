/*
 * 搜索框（独立组件，遵循"一切页面元素都组件化"）。
 *
 * 用**官方 `Search` 组件**（不是自拼 TextInput + 图标）：官方对它的定位原文是
 * 「搜索框组件，支持搜索图标、清除按钮、搜索按钮、placeholder 提示文本、自定义键盘等功能配置，
 * 适用于浏览器的搜索内容输入框、应用内搜索等场景」—— 搜索图标、有字时的清除按钮都是它自带的，
 * 高度/圆角/底色也走官方默认，只定高度；**左右留白由外层容器给**（见下方 build 前的说明）。
 *
 * 对外只暴露两个事件（数据流向上的口子），不自己存"结果"：
 *  · `onChange` 每次输入变化都给出去（以后做实时联想用）；
 *  · `onSubmit` 用户按键盘搜索键/回车时给出去（以后做真正搜索用）。
 */
/** 搜索框高度（vp）：与官方默认一致（Search 默认高度就是 40vp），显式写出来便于以后统一调 */
const SEARCH_FIELD_HEIGHT_VP: number = 40;

@ComponentV2
export struct SearchField {
  /** 输入内容变化 */
  @Event onChange: (text: string) => void = () => {};
  /** 提交（键盘搜索键 / 回车） */
  @Event onSubmit: (text: string) => void = () => {};

  /** 受控输入：自己存一份文本，`onChange` 时同步（`Search` 支持 $$ / !! 双向绑定，
   *  但这里保持"显式受控"，以后要在输入时过滤/联想时不用改结构） */
  @Local text: string = '';

  private controller: SearchController = new SearchController();

  /**
   * ⚠️ **左右留白不在这个组件里加**：`Search` 是 `width('100%')`，再给它配 `.margin()` 就是
   * 「100% + 边距」溢出，边距会被吃掉 —— 实测药丸左右各 0vp、直接贴屏幕两边
   * （袁正锟 2026-10-16：「为什么贴到屏幕两边了」）。留白由**外层容器**用 `padding` 给
   * （见 `B_Search`，取官方 `padding_level8` ＝ 16vp，与页面其它内容一致）。
   */
  build() {
    Search({
      value: this.text,
      placeholder: $r('app.string.search_hint'),
      controller: this.controller
    })
      .width('100%')
      .height(SEARCH_FIELD_HEIGHT_VP)
      // 默认就带左侧搜索图标与有字时的清除按钮，这里不覆盖
      .onChange((value: string) => {
        this.text = value;
        this.onChange(value);
      })
      .onSubmit((value: string) => {
        this.onSubmit(value);
      })
  }
}
