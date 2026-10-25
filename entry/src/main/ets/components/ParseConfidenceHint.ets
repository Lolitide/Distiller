/*
 * 「AI 预填结果」提示条 —— 添加任务半模态里，**把低可信 / 没识别出来的字段直接标给用户**。
 *
 * 为什么要有它：`AddTaskDraft.applyParsed()` 把候选填进表单之后，界面只说一句
 * 「已自动填写，请确认后保存」，而**候选自带的 `certainty`（0~100）与 `missing_fields` 一个字都没显示**——
 * 用户没法知道"机器对这条有多少把握、哪几项是猜的"；存下来的任务更是连 `certainty` 都丢了
 * （`toTask()` 之前不写它）。本组件 + `AddTaskDraft` 的那几处改动补的就是这一段。
 *
 * 显示规则（只在 AI 预填过之后出现；手动建的一份空表单不挂提示条，见 `AddTaskDraft.hasParseHint`）：
 *   · 第一行：置信度 —— **低于阈值（`LOW_CERTAINTY_THRESHOLD`＝60）** 才用警示色 +「请核对」，
 *     高于阈值只是一句中性说明，不制造焦虑；
 *   · 第二行：**未识别：地点、对象**（按当前草稿现算，用户补上就消失；见 `AddTaskDraft.missingHints()`）。
 *
 * 口径限制（界面上的话不能超过事实）：后端的置信度是**整条候选一个数**，契约里没有
 * "每个字段各自的置信度"（`CandidateItem` 只有 `certainty` + `missing_fields`）。
 * 所以这里只能整体提示 + 列出"哪些字段没识别出来"，**不能**声称"地点这一项置信度低"。
 */
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { Theme, ThemeStore } from '../utils/Theme';

/** 提示条图标尺寸（vp）：与卡片上那颗低可信角标同档 */
const HINT_ICON_SIZE_VP: number = 16;
/** 提示条圆角（vp）：M3 小容器（比卡片 16 小一档，读起来是"卡片里的一个块"） */
const HINT_RADIUS_VP: number = 12;
/** 图标与首行文字的视觉微调（vp）：图标比文字矮一点，往下压 2vp 才对齐首行墨迹 */
const HINT_ICON_TOP_OFFSET_VP: number = 2;

@ComponentV2
export struct ParseConfidenceHint {
  /** 表单草稿（`@ObservedV2`）：置信度、缺失字段、以及各可编辑字段都从它现读，所以提示会跟着改 */
  @Require @Param draft: AddTaskDraft;

  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 置信度低于阈值 → 警示色 +「请核对」 */
  @Computed
  get low(): boolean {
    return TaskListViewModel.isLowCertainty(this.draft.certainty);
  }

  /** 有没有"未识别"的字段（有才渲染第二行） */
  @Computed
  get hasMissing(): boolean {
    return this.draft.missingHints().length > 0;
  }

  /**
   * 第一行：置信度。
   * · 有值：`AI 预填，置信度 42，请核对` / `AI 预填，置信度 88`
   * · 没值（后端没给）：只说 `AI 预填，请核对` —— **不编一个数出来**
   */
  @Computed
  get certaintyText(): ResourceStr {
    const value: number = this.draft.certainty;
    if (value < 0) {
      return $r('app.string.parse_hint_title_only');
    }
    return this.low
      ? $r('app.string.parse_hint_certainty_low', value)
      : $r('app.string.parse_hint_certainty_ok', value);
  }

  /** 第二行：`未识别：地点、对象`（只在这一行真要渲染时才算，见 build 里的 `if`） */
  @Computed
  get missingText(): ResourceStr {
    const fields: string[] = this.draft.missingHints();
    const names: string[] = [];
    for (let i = 0; i < fields.length; i++) {
      names.push(TaskListViewModel.missingFieldLabel(fields[i]));
    }
    return $r('app.string.parse_hint_missing', names.join('、'));
  }

  build() {
    Row({ space: Theme.GAP_S }) {
      // 低可信＝警示三角/圆圈；只是"AI 预填说明"＝中性 info 图标
      SymbolGlyph(this.low ? $r('sys.symbol.exclamationmark_circle') : $r('sys.symbol.info_circle'))
        .fontSize(HINT_ICON_SIZE_VP)
        .fontColor([this.low ? $r('sys.color.warning') : this.themeStore.scheme.onSecondaryContainer])
        .flexShrink(0)
        .margin({ top: HINT_ICON_TOP_OFFSET_VP })

      Column({ space: Theme.GAP_XS / 2 }) {
        Text(this.certaintyText)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.low
            ? $r('sys.color.warning')
            : this.themeStore.scheme.onSecondaryContainer)
          .width('100%')
          .textAlign(TextAlign.Start)

        if (this.hasMissing) {
          Text(this.missingText)
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .fontColor(this.themeStore.scheme.onSecondaryContainer)
            .opacity(0.8)
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    // 内边距 8vp（官方 `padding_level4`）：提示条是**块**不是行，四周都要有气口
    .padding({
      left: Theme.GAP_S,
      right: Theme.GAP_S,
      top: Theme.GAP_S,
      bottom: Theme.GAP_S
    })
    // M3 容器色：与属性 chip 的轨道同族（浅底深字），不抢「保存」的视线
    .backgroundColor(this.themeStore.scheme.secondaryContainer)
    .borderRadius(HINT_RADIUS_VP)
  }
}
