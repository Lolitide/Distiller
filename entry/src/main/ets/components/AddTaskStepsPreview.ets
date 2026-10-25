/*
 * 「添加任务 · 解析出的子任务」预览块（FE-77）。
 *
 * 为什么需要这一块：解析（后端 `/parse`）会把群消息拆成若干子任务，`AddTaskDraft.applyParsed()`
 * **原样**收进 `draft.steps`（不校验、不去重、不改写措辞 —— 这是验收口径），保存时一并落库。
 * 但确认表单里以前**一条都不显示**：用户点完「AI 预填」只看到任务名，根本不知道自己将保存几条子任务
 * （验收里的「子任务数量/内容不可控」正是这个）。
 *
 * 这一块只做三件事：
 *  ① 显示条数（`N 条`），让数量可见；
 *  ② 逐条显示内容（只读，最多两行，避免一条超长把半模态撑爆）；
 *  ③ 允许**逐条删除** —— 「可控」不能只靠看得见，得能去掉误解析的那条。
 *     ⚠️ 只删用户主动点的；**不做自动去重/截断**，否则就违背"原样落库"的口径。
 */
import { TaskStep } from '../model';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { Theme, ThemeStore } from '../utils/Theme';

@ComponentV2
export struct AddTaskStepsPreview {
  /** 表单草稿：直接读 `draft.steps`（`applyParsed` 写进来、`toTask` 原样带走） */
  @Require @Param draft: AddTaskDraft;
  /** 视觉个性化：M3 色系 */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 删掉第 index 条（用户动作，非自动校验）；用新数组赋值触发 V2 刷新 */
  private removeAt(index: number): void {
    if (index < 0 || index >= this.draft.steps.length) {
      return;
    }
    const next: TaskStep[] = [];
    for (let i = 0; i < this.draft.steps.length; i++) {
      if (i !== index) {
        next.push(this.draft.steps[i]);
      }
    }
    this.draft.steps = next;
  }

  @Builder
  stepRow(step: TaskStep, index: number) {
    Row({ space: 8 }) {
      // 序号用浅色小字，别喧宾夺主
      Text(`${index + 1}`)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width(20)
        .textAlign(TextAlign.End)
      Text(step.content)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      // 删除：解析偶尔会把"通知类"句子也算进来，给用户一个去掉的出口
      SymbolGlyph($r('sys.symbol.xmark_circle'))
        .fontSize(Theme.FONT_CAPTION)
        .fontColor([$r('sys.color.icon_tertiary')])
        .onClick(() => {
          this.removeAt(index);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 6, bottom: 6 })
  }

  build() {
    // 没有子任务就整块不渲染（不占位、不显示"0 条"）
    if (this.draft.steps.length > 0) {
      Column() {
        Row({ space: 6 }) {
          Text('子任务')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .fontWeight(FontWeight.Medium)
          Text(`${this.draft.steps.length} 条`)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeStore.scheme.primary)
          Blank()
          Text('解析原样保留')
            .fontSize($r('sys.float.ohos_id_text_size_caption'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 条数多时最多撑 3 条的高度再滚动，别把整个半模态推走
        Scroll() {
          Column() {
            ForEach(this.draft.steps, (step: TaskStep, index: number) => {
              this.stepRow(step, index)
            }, (step: TaskStep, index: number) => `${index}-${step.content}`)
          }
          .width('100%')
        }
        .width('100%')
        .constraintSize({ maxHeight: 168 })
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
        .margin({ top: 4 })
      }
      .width('100%')
      .padding(12)
      .borderRadius(Theme.RADIUS_CARD)
      .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
      .alignItems(HorizontalAlign.Start)
    }
  }
}
