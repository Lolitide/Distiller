import { ThemeStore } from '../utils/Theme';
/*
 * 「添加任务」的**来源选择**（截图 / 录音 / 文本）—— 胶囊型单选按钮组，**图标与文字同一行**。
 *
 * 需求方 2026-10-17：「用官方的 SegmentButtonV2 做一个图标文本按钮组…」→「先把图标和文字放一行吧」。
 *
 * 🔴 **为什么这里不用官方 `CapsuleSegmentButtonV2`（查证结论，不是偷懒）**
 * 官方 `SegmentButtonV2` 的选项（`SegmentButtonV2Item`）**同时给 `text` + `symbol`** 就是它说的「图文混合」，
 * 而图文混合的排版是**组件内部写死的上下两行**，没有任何横排开关：
 *  · 官方文档 `itemMinHeight` / `buttonMinHeight` 两处原文 —— 「只有纯文本或者纯图标选项时：
 *    `$r('sys.float.segment_button_v2_singleline_selected_height')`；**有图文混合的选项时：
 *    `$r('sys.float.segment_button_v2_doubleline_selected_height')`」→ 一出现图文混合就自动换成**双行**档高；
 *  · 全部可配项里**没有**「图标与文字排列方向」这一项。
 * 所以「一行」只能用同样的官方 token 自绘。
 *
 * ## 2026-10-27：视觉搬进共用组件 `M3SegmentGroup`
 *
 * 需求方要求设置页的「卡片密度」也用「和这里一样的 md 取色」——
 * 于是把这一套轨道 / 选中块 / 档高的取色抽到 `components/M3SegmentGroup.ets`，
 * 本组件只保留「来源枚举 + 三个选项的图标文案」这一层，**视觉与设置页那张二档控件完全同源**。
 * 要调整配色请改 `M3SegmentGroup`，不要在两边各写一套。
 */
import { M3SegmentGroup, M3SegmentOption } from './M3SegmentGroup';

/**
 * 「添加任务」的三种来源入口，**取值就是按钮组的下标**（0/1/2）。
 * 顺序与需求方 2026-10-17 的口径一致：截图 → 录音 → 文本，默认第 0 个（截图）。
 *
 * 放这个文件而不是 `model/Models.ets`：它只描述**这个按钮组的选项顺序**，不是任务的业务字段
 * （任务侧的「来源通道」是 `model` 里的 `TaskSource`，另一件事，别混）。
 */
export enum AddTaskSource {
  SCREENSHOT = 0,
  VOICE = 1,
  TEXT = 2
}

@ComponentV2
export struct AddTaskSourceTabs {
  /** 视觉个性化：M3 primary（全局 MD3 化） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 当前选中项下标 —— **单向**从父组件来（选中态的唯一真源在 `AddTaskSheet`） */
  @Require @Param selectedIndex: number;
  /** 用户点了哪一项 —— 父组件据此改自己的状态；本组件不持有选中态 */
  @Event onSelect: (index: number) => void = () => {};

  /**
   * 三个来源选项（图标名都核过 SDK 的 `sysResource.js` 符号表：
   * `screenshot` / `mic` / `doc_plaintext`）。
   *
   * 做成实例字段而不是每次 build 现拼：`@Param` 收到新数组引用会触发重渲染，
   * 现拼会导致每次刷新都多一轮（虽然幂等，但没必要）。
   */
  private items: M3SegmentOption[] = [
    {
      key: 'screenshot',
      symbol: $r('sys.symbol.screenshot'),
      label: $r('app.string.source_screenshot'),
      a11y: '截图'
    },
    {
      key: 'voice',
      symbol: $r('sys.symbol.mic'),
      label: $r('app.string.source_voice'),
      a11y: '录音'
    },
    {
      key: 'text',
      symbol: $r('sys.symbol.doc_plaintext'),
      label: $r('app.string.source_text'),
      a11y: '文本'
    }
  ];

  build() {
    // 三个选项均分轨道宽度（`equalWidth` 默认 true），撑满整行
    M3SegmentGroup({
      options: this.items,
      selectedIndex: this.selectedIndex,
      onSelect: (index: number) => {
        this.onSelect(index);
      }
    })
  }
}
