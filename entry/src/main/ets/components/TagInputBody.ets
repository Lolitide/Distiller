/*
 * 文本输入面板（`TextInput` ＋ 底部取消/确定），给 `bindSheet` 当 body 用。
 *
 * 需求方 2026-10-17：「＋ 添加标签」（六颗 chip 的最后一块）—— 点它弹一个输入框填标签名。
 * 与 `DateTimePickerBody` / `OptionPickerBody` 同构，底部条共用 `PickerFooter`；
 * 草稿由**父组件**持有（`@Param text` 进来、`@Event onTextChange` 出去），点「确定」才落库。
 *
 * ⚠️ 输入框的左右留白**用外层 `Row` 的 `padding`，不要给 `TextInput` 自己加 `margin`**：
 * 第一版写的是 `.margin({ left: $r(...), right: $r(...) })`，实测**没生效**、输入框仍然贴着半模态两边
 * （需求方 2026-10-17：「半模态的添加标签的文本输入框贴到两边了」，`.cache/tag-3-input.png`）——
 * 外层 `Row` 撑满 + `padding` 是稳的写法，也不会连带把底部那条「取消/确定」挤窄（它是 `Column` 的另一个子节点）。
 */
import { PickerFooter } from './PickerFooter';

@ComponentV2
export struct TagInputBody {
  /** 当前草稿文本（父组件持有） */
  @Require @Param text: string;
  /** 输入框的占位提示 */
  @Require @Param placeholder: Resource;
  /** 草稿变了 */
  @Event onTextChange: (text: string) => void = () => {};
  /** 点「取消」 */
  @Event onCancel: () => void = () => {};
  /** 点「确定」 */
  @Event onConfirm: () => void = () => {};

  build() {
    Column() {
      // 外层 Row 只负责「左右留白 + 让输入框占满剩余宽度」
      Row() {
        TextInput({ text: this.text, placeholder: this.placeholder })
          .width('100%')
          // 稳定 id：UI 自动化（`devecocli ui text --id`）要用它定位
          .id('tagNameInput')
          // 输入框自己的内边距（文字与边框的距离）：官方 `padding_level8`
          .padding({
            left: $r('sys.float.padding_level8'),
            right: $r('sys.float.padding_level8')
          })
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius($r('sys.float.corner_radius_level8'))
          .maxLines(1)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value: string) => {
            this.onTextChange(value);
          })
          // 回车＝确定（与其它输入框的手感一致）
          .onSubmit(() => {
            this.onConfirm();
          })
      }
      .width('100%')
      .padding({
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8')
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
    .padding({ top: $r('sys.float.padding_level8'), bottom: $r('sys.float.padding_level8') })
  }
}
