/*
 * 「添加任务 · 文本」内容区 —— 一块可以粘贴/输入任务原文的文本框。
 *
 * 袁正锟 2026-10-17：「…文本是一个文本粘贴框」。
 *
 * 为什么是 `TextArea`：官方 `TextArea` 自带**长按粘贴/选择/全选**这套系统能力，
 * 用户从群里复制一段话后，长按 → 粘贴即可；不需要我们自己读剪贴板（也就没有剪贴板权限的问题）。
 *
 * 半模态里的软键盘避让：`SheetOptions.keyboardAvoidMode` 官方默认值就是 `TRANSLATE_AND_SCROLL`
 * （API 13+ 才有这个字段），对"输入框贴着半模态上部"这种布局够用，所以本步**不覆盖默认值**；
 * 万一真机上看被键盘盖住，再显式设 `SheetKeyboardAvoidMode.RESIZE_ONLY`（见 `addTaskSheetOptions` 的注释）。
 *
 * 还没做的：这里只是拿到 `rawText`，之后要按结论走 `页面 → ViewModel → service/ai（动态 import）→ repository`
 * —— 抽取字段、落库、列表刷新都还没接。
 */
import { LengthMetrics } from '@kit.ArkUI';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';

/**
 * 文本框高度（vp）：取设计稿 `添加任务.svg` 里那块输入行（428 宽画板）高 **56**，
 * 但单行 56 放不下群里那种两三行原文，所以给 **120vp**（约 4~5 行）＋内部滚动。
 */
const TEXT_AREA_HEIGHT_VP: number = 120;

@ComponentV2
export struct AddTaskTextInput {
  /** 表单草稿：原文存 `draft.rawText`（保存时作为 `rawText` 落进任务） */
  @Require @Param draft: AddTaskDraft;

  build() {
    TextArea({ text: this.draft.rawText, placeholder: $r('app.string.add_task_text_hint') })
      .width('100%')
      .height(TEXT_AREA_HEIGHT_VP)
      // 字号/颜色走官方语义 token：正文 `body1`、占位用文字三级灰
      .fontSize($r('sys.float.ohos_id_text_size_body1'))
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .placeholderColor($r('sys.color.ohos_id_color_text_tertiary'))
      // 底色与「截图」那块占位区一致（袁正锟 2026-10-17：「内容区背景太灰了 和 button 那个背景灰一样吧」
      // → 用**来源按钮那条胶囊轨道的灰**，不用更深的 `comp_background_secondary`）
      .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
      .borderRadius($r('sys.float.corner_radius_level8'))
      // 内边距：袁正锟 2026-10-17「文本状态下的内容区 加点内边距吧」→ 从 `padding_level4`(8vp) 提到
      // `padding_level8`(16vp)，让占位文字与正文都离开边框。
      // （`padding` 的重载里没有 `LengthMetrics`，只吃 `Length` / `Padding` / `LocalizedPadding`，所以直接给 Resource）
      .padding({
        top: LengthMetrics.resource($r('sys.float.padding_level8')),
        bottom: LengthMetrics.resource($r('sys.float.padding_level8')),
        start: LengthMetrics.resource($r('sys.float.padding_level8')),
        end: LengthMetrics.resource($r('sys.float.padding_level8'))
      })
      .onChange((value: string) => {
        this.draft.rawText = value;
      })
  }
}
