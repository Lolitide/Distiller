/*
 * 「添加任务」的**任务名称输入框** —— 放在内容区下方（三种来源都用同一个，名称与来源无关）。
 *
 * 袁正锟 2026-10-17：「下面加一个输入任务名称的输入框」。
 *
 * 外观与上面几块内容区**同一套官方 token**（底色＝来源按钮那条胶囊轨道的灰、圆角 `corner_radius_level8`），
 * 所以整张半模态的"块"看起来是一套东西。
 *
 * 高度取值：设计稿 `api/知了设计UI/添加任务.svg`（428 宽画板）里那行输入框高 **56**，
 * 换算到 360vp 手机屏约 47vp → 取整 **48vp**。官方没有"输入框高度"这类 token，故提成常量。
 *
 * 现在名称直接写进 **`AddTaskDraft`（表单草稿）**：标题栏上的「保存」按钮要用它判断灰/亮，
 * 所以它是"全表单共享的一份状态"，不再留在本组件内部。
 */
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';

/** 输入框高度（vp）：设计稿 56 / 428 宽画板 ≈ 47vp，取整 48 */
const NAME_INPUT_HEIGHT_VP: number = 48;



@ComponentV2
export struct AddTaskNameInput {
  /**
   * 表单草稿（`AddTaskSheet` `new` 出来、按引用传下来）：名称存 `draft.name`。
   * 这样标题栏上的「保存」按钮（也在 `AddTaskSheet` 里）能直接读到名称、判断灰/亮。
   */
  @Require @Param draft: AddTaskDraft;

  build() {
    TextInput({ text: this.draft.name, placeholder: $r('app.string.add_task_name_hint') })
      .width('100%')
      .height(NAME_INPUT_HEIGHT_VP)
      // 稳定 id：UI 自动化（`devecocli ui text --id`）与走查都要用它定位这个输入框
      .id('addTaskNameInput')
      // 字号/颜色走官方语义 token，与「文本」那块一致
      .fontSize($r('sys.float.ohos_id_text_size_body1'))
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .placeholderColor($r('sys.color.ohos_id_color_text_tertiary'))
      // 底色/圆角与其它内容区一致（`comp_background_secondary` 太深，这里统一用胶囊轨道的灰）
      .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
      .borderRadius($r('sys.float.corner_radius_level8'))
      // 左右内边距 16vp（`padding_level8`）：`Padding` 的字段是 `Length`，Resource 可直接用
      .padding({
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8')
      })
      // 任务名是单行短文本：不换行、回车即收起键盘
      .maxLines(1)
      .enterKeyType(EnterKeyType.Done)
      .onChange((value: string) => {
        this.draft.name = value;
      })
  }
}
