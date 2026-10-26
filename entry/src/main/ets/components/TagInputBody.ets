/*
 * 文本输入面板（`TextInput` ＋ 底部取消/确定），给 `openCustomDialog` 的居中弹窗当 body 用。
 *
 * 需求方 2026-10-17：「＋ 添加标签」点它弹一个输入框填标签名。
 * 与 `DateTimePickerBody` / `OptionPickerBody` / `RepeatRuleEditor` 同构，底部条共用 `PickerFooter`；
 * 草稿由**父组件**持有（`@Param text` 进来、`@Event onTextChange` 出去），点「确定」才落库。
 *
 * 2026-10-27 排版统一（需求方：「弹窗的字号（标题、正文）、字重、排版、间距调整得更合适、统一」）：
 *  · 输入框**不再自己加左右 16vp 内边距** —— 弹窗外框 `CenterDialogFrame` 已经给了 16vp，
 *    再叠一层的话标题在 16vp、输入框却从 32vp 起，左缘对不齐（与「设置重复」「设置到期时间」两个弹窗
 *    同一处毛病，一起改掉了）；
 *  · 输入框字号/高度/圆角与 `DateTimePickerBody` 的手动输入框**取同一套**
 *    （`Theme.FONT_BODY` 14vp / 44vp 高 / `Theme.RADIUS_CHIP` 圆角 / `comp_background_secondary` 背板）；
 *  · 上下内边距去掉：标题下方已有 16vp，输入框下只留 12vp 到操作条。
 */
import { PickerFooter } from './PickerFooter';
import { Theme } from '../utils/Theme';

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
      TextInput({ text: this.text, placeholder: this.placeholder })
        .width('100%')
        // 稳定 id：UI 自动化（`devecocli ui text --id`）要用它定位
        .id('tagNameInput')
        // 与日期面板的手动输入框同一套尺寸/字号/圆形背板
        .height(Theme.HIT_MIN + Theme.GAP_S)
        .fontSize(Theme.FONT_BODY)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(Theme.RADIUS_CHIP)
        .padding({ left: Theme.GAP_M, right: Theme.GAP_M })
        .maxLines(1)
        .enterKeyType(EnterKeyType.Done)
        // 输入框与操作条之间留 12vp；不要再给顶部留白（标题下方已经是 16vp）
        .margin({ bottom: Theme.GAP_M })
        .onChange((value: string) => {
          this.onTextChange(value);
        })
        // 回车＝确定（与其它输入框的手感一致）
        .onSubmit(() => {
          this.onConfirm();
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
