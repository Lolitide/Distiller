/*
 * 任务卡片的**副卡片**（设计稿 `任务子卡片.jpg`）：主卡片下方紧接的步骤区。
 *
 * 设计稿里副卡片原本是三块：打卡进度条（`1 / 4`）+ 步骤列表 + 折叠箭头。
 * **打卡移出 MVP 后只做后两块**（2026-10-17 与作者确认：「副卡片 = 步骤 + 勾选 + 折叠」）：
 *   · 步骤列表：每步一个圆圈（done=1 实心勾 / done=0 空圈）+ 一行文字；
 *   · 折叠：默认展开（与设计稿一致），点右侧箭头收起成一行摘要。
 *
 * 只做**展示 + 勾选**：新增/编辑/删除步骤在详情页（`TaskStepsSection`）里做，
 * 列表上再放一套编辑会让"点卡片进详情"和"点步骤改内容"抢同一个点击区。
 */
import { Task, TaskStep } from '../model';

/** 行高（vp）：比主卡片内的行矮，副卡片是"补充信息" */
const STEP_ROW_HEIGHT_VP: number = 36;
/** 圆圈直径（vp） */
const STEP_CIRCLE_SIZE_VP: number = 18;
/** 圆圈与文字间距（vp） */
const STEP_ICON_GAP_VP: number = 12;
/** 副卡片左右内边距（vp）：比主卡片小一档，做出"挂在主卡片下"的层次 */
const SUB_SIDE_PADDING_VP: number = 24;
/** 折叠箭头命中区（vp）：官方最小可点 40 */
const TOGGLE_HIT_SIZE_VP: number = 40;
/** 折叠箭头字号（vp） */
const TOGGLE_ICON_SIZE_VP: number = 16;

@ComponentV2
export struct TaskSubCard {
  @Require @Param task: Task;
  /** 点某一步的圆圈 → 由页面交给 store 改 `steps[i].done`（组件不碰数据） */
  @Event onToggleStep: (index: number) => void = () => {};

  /** 是否展开。默认展开，与设计稿一致 */
  @Local expanded: boolean = true;

  @Computed
  get steps(): TaskStep[] {
    const list: TaskStep[] | undefined = this.task.steps;
    return list === undefined ? [] : list;
  }

  @Computed
  get stepCount(): number {
    return this.steps.length;
  }

  @Computed
  get doneCount(): number {
    let done: number = 0;
    this.steps.forEach((step: TaskStep) => {
      if (step.done === 1) {
        done++;
      }
    });
    return done;
  }

  /** 收起时的一行摘要：「已完成 1 / 3 步」 */
  @Computed
  get summaryLabel(): string {
    return `已完成 ${this.doneCount} / ${this.stepCount} 步`;
  }

  @Computed
  get toggleSymbol(): Resource {
    return this.expanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down');
  }

  /** 已完成步骤的文字变灰（与主卡片完成态同一套语义色） */
  private stepColor(done: number): ResourceColor {
    return done === 1
      ? $r('sys.color.ohos_id_color_text_secondary')
      : $r('sys.color.ohos_id_color_text_primary');
  }

  private stepSymbol(done: number): Resource {
    return done === 1 ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.circle');
  }

  @Builder
  stepRow(index: number, step: TaskStep) {
    Row() {
      SymbolGlyph(this.stepSymbol(step.done))
        .fontSize(STEP_CIRCLE_SIZE_VP)
        .fontColor([step.done === 1
          ? $r('sys.color.icon_emphasize')
          : $r('sys.color.icon_secondary')])
        .margin({ right: STEP_ICON_GAP_VP })

      Text(step.content)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.stepColor(step.done))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .height(STEP_ROW_HEIGHT_VP)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onToggleStep(index);
    })
    .accessibilityText(step.content)
  }

  build() {
    Column() {
      Row() {
        if (this.expanded) {
          Text($r('app.string.subcard_steps_title'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .layoutWeight(1)
            .maxLines(1)
            .textAlign(TextAlign.Start)
        } else {
          Text(this.summaryLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .layoutWeight(1)
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }

        // 折叠箭头：命中区 40vp，图标 16vp
        SymbolGlyph(this.toggleSymbol)
          .fontSize(TOGGLE_ICON_SIZE_VP)
          .fontColor([$r('sys.color.icon_secondary')])
          .width(TOGGLE_HIT_SIZE_VP)
          .height(TOGGLE_HIT_SIZE_VP)
          .onClick(() => {
            this.expanded = !this.expanded;
          })
          .accessibilityText($r('app.string.subcard_toggle'))
      }
      .width('100%')
      .height(STEP_ROW_HEIGHT_VP)
      .alignItems(VerticalAlign.Center)

      if (this.expanded) {
        ForEach(this.steps, (step: TaskStep, index: number) => {
          this.stepRow(index, step)
        }, (step: TaskStep) => `${step.content}-${step.done}`)
      }
    }
    .width('100%')
    .padding({
      left: SUB_SIDE_PADDING_VP,
      right: $r('sys.float.padding_level8'),
      top: $r('sys.float.padding_level4'),
      bottom: $r('sys.float.padding_level4')
    })
    // 与主卡片同一个卡片白 + 圆角，视觉上是一张"挂上去"的子卡
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
