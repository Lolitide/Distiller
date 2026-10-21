/*
 * 官方**单列文本选择器**面板（`TextPicker` ＋ 底部取消/确定），给 `bindSheet` 当 body 用。
 *
 * 袁正锟 2026-10-17：「下面做重复 选择器同样参考任务详情里面的重复选择器」——
 * 详情页那套（`TaskAttributeCard.repeatSheet()`）是官方 `TextPicker` + 底部「取消 / 确定」，
 * 这里抽成可复用组件（与 `DateTimePickerBody` 同构，底部条共用 `PickerFooter`）。
 *
 * 草稿由**父组件**持有（`@Param selectedIndex` 进来、`@Event onSelectedIndexChange` 出去）：
 * 选择器跟手改的是草稿，点「确定」才落库。
 */
import { PickerFooter } from './PickerFooter';

@ComponentV2
export struct OptionPickerBody {
  /** 选项文案（**已经是字符串**：`TextPicker.range` 只吃字符串数组） */
  @Require @Param options: string[];
  /** 当前草稿下标 */
  @Require @Param selectedIndex: number;
  /** 草稿下标变了 */
  @Event onSelectedIndexChange: (index: number) => void = () => {};
  /** 点「取消」 */
  @Event onCancel: () => void = () => {};
  /** 点「确定」 */
  @Event onConfirm: () => void = () => {};

  build() {
    Column() {
      TextPicker({ range: this.options, selected: this.selectedIndex })
        .width('100%')
        .onChange((value: string | string[], index: number | number[]) => {
          // 单列选择器运行时 index 一定是 number；先收窄再上报
          if (typeof index === 'number') {
            this.onSelectedIndexChange(index);
          }
        })

      PickerFooter({
        onCancel: () => {
          this.onCancel();
        },
        onConfirm: () => {
          this.onConfirm();
        }
      })
    }
    .width('100%')
  }
}
