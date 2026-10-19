/*
 * 任务卡片的**副卡片**（设计稿 `任务子卡片.jpg` → 2026-10-19 第二版草图 `3E0AFCE0….png`）。
 *
 * ## 形态（按最新草图）
 *
 * 收起时列表里只画**主卡片下方露出的一条窄边**（在 `A_TaskList` 里画，不在本组件）。
 * 长按主卡片后展开本组件，**只占一行**，草图标注「高度 < 主卡片的一半」：
 *
 *   [○ 步骤文字 ……………………… 1/3]
 *
 *   · 左圆圈：点它＝把**这一步**标记完成（完成后再点＝退回）；
 *   · 中间：**当前这一步**的正文（不是把所有步骤铺开）；
 *   · 右侧 `1/3`：已完成 / 总步骤数。
 *
 * 「只显示当前一步」是刻意的：卡片上能一眼看出"下一步要干什么"，完整步骤列表在详情页
 * （`TaskStepsSection`，那里可以增删改）。全铺开会把列表撑得很长，与草图的高度约束矛盾。
 *
 * 「当前一步」＝**第一个未完成的步骤**；全部完成时显示最后一步（便于退回）。
 */
import { Task, TaskStep } from '../model';
import { Theme, ThemeStore } from '../utils/Theme';

/**
 * 整条副卡片的高度（vp）：草图要求「< 主卡片的一半」。
 * 主卡片标准 76vp / 紧凑 64vp → 一半是 38 / 32vp，这里取 **36vp**（行 32 + 上下各 2）。
 */
const SUB_CARD_HEIGHT_VP: number = 36;
/** 圆圈直径（vp） */
const STEP_CIRCLE_SIZE_VP: number = 18;
/** 圆圈与文字间距（vp） */
const STEP_ICON_GAP_VP: number = 12;
/** 左右内边距（vp）：比主卡片小一档，做出"挂在主卡片下"的层次 */
const SUB_SIDE_PADDING_VP: number = 24;

@ComponentV2
export struct TaskSubCard {
  @Require @Param task: Task;
  /**
   * 是否处于「折叠在被主卡底下」的状态（2026-10-19 第七次调整）。
   *
   * 为 true 时：底色换成更暗的一层 + 整体降不透明度 → 露出来的那条边读作
   * 「一张沉在暗处的卡」，而不是靠 `shadow()`（后者按组件外框画，会摊成光晕）。
   */
  @Param dimmed: boolean = false;
  /** 点圆圈 → 由页面交给 store 切换该步的完成态（组件不碰数据） */
  @Event onToggleStep: (index: number) => void = () => {};
  /** 视觉个性化状态：副卡片高度按密度档取值（紧凑档更矮） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

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

  /**
   * 要展示的那一步的下标：**第一个未完成的**；全完成时用最后一步。
   * 没有步骤时返回 -1（正常不会出现 —— 调用方只在 steps 非空时才挂本组件）。
   */
  @Computed
  get currentIndex(): number {
    const list: TaskStep[] = this.steps;
    for (let i = 0; i < list.length; i++) {
      if (list[i].done !== 1) {
        return i;
      }
    }
    return list.length === 0 ? -1 : list.length - 1;
  }

  @Computed
  get currentStep(): TaskStep | undefined {
    const index: number = this.currentIndex;
    return index < 0 ? undefined : this.steps[index];
  }

  /** 右侧进度：`1/3` */
  @Computed
  get progressLabel(): string {
    return `${this.doneCount}/${this.stepCount}`;
  }

  build() {
    Row() {
      // 左圆圈：实心勾表示这一步已完成，空圈表示未完成；点它切换
      SymbolGlyph(this.currentStep !== undefined && this.currentStep.done === 1
        ? $r('sys.symbol.checkmark_circle_fill')
        : $r('sys.symbol.circle'))
        .fontSize(STEP_CIRCLE_SIZE_VP)
        .fontColor([this.currentStep !== undefined && this.currentStep.done === 1
          ? this.themeStore.scheme.primary
          : $r('sys.color.icon_secondary')])
        .margin({ right: STEP_ICON_GAP_VP })
        .onClick(() => {
          if (this.currentIndex >= 0) {
            this.onToggleStep(this.currentIndex);
          }
        })

      // 当前这一步的正文
      Text(this.currentStep === undefined ? '' : this.currentStep.content)
        .fontSize(Theme.FONT_CAPTION)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      // 右侧进度 1/3
      Text(this.progressLabel)
        .fontSize(Theme.FONT_CAPTION)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
        .margin({ left: Theme.GAP_S })
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(this.themeStore.subCardHeight)
    .padding({ left: SUB_SIDE_PADDING_VP, right: SUB_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
    // 与主卡片同一个卡片白；折叠态换成**更暗的一层底色**
    .backgroundColor(this.dimmed
      ? Theme.CARD_BG_DIM
      : $r('sys.color.ohos_id_color_card_bg'))
    // 折叠态再叠一层**整体降透明度**（作者：「同时更改 bg 颜色和 opacity」）
    .opacity(this.dimmed ? Theme.OPACITY_CARD_DIM : 1)
    // **上面两个圆角为 0**（2026-10-19）：
    // 上面那半截是"缩在主卡片底下"的，做圆角反而会露出缝隙，
    // 只保留下面两个圆角 → 看上去就是一张从主卡底下钻出来的卡。
    .borderRadius({
      topLeft: 0,
      topRight: 0,
      bottomLeft: Theme.RADIUS_CARD,
      bottomRight: Theme.RADIUS_CARD
    })
    .clip(true)
    // 底色/透明度随折叠状态平滑过渡（与页面里的高度动画同一个时长/曲线）
    .animation({ duration: Theme.ANIM_EXPAND_MS, curve: Curve.FastOutSlowIn })
    .accessibilityText(`${this.currentStep === undefined ? '' : this.currentStep.content} ${this.progressLabel}`)
  }
}
