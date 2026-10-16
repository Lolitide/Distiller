/*
 * 卡片本体用官方 HdsListItemCard（@kit.UIDesignKit），未自造控件。
 * 三处例外说明：
 *   1. 圆圈：HdsListItemCard 的 PrefixIcon 没有 onClick（PrefixIconOptions 只有 iconSize / iconValue），
 *      点不动。要「点圆圈＝完成任务」只能走官方给的 A 区自定义内容口子 PrefixCustomBuilder，
 *      里面放官方 SymbolGlyph。
 *   2. 开关：用官方 SuffixSwitch（CheckOptions 里有 isCheck / onChange）。
 *   3. 文字块：走官方 `TextItemOptions.customBuilder`（**不是** `primaryText` + `TextModifier`）。
 *
 * ── 为什么文字块必须自定义（袁正锟 2026-10-16：「Card 的 primaryText 加粗；Card 的上下边距减小，
 *    但是所有卡片的上下边距保持一致」）────────────────────────────────────────────
 * ① **加粗**：`TextOptions` 只有 `text` + `modifier` 两个字段，而 `TextModifier.fontWeight` 实测**压不动**
 *    HDS 卡片自己的字重（#91/#92 两轮 Bold/Bolder 都无效果，最后被撤回）。HDS 的 `TextItemOptions.customBuilder`
 *    是官方给的"自定义文字区"口子，优先级高于其它文字接口 —— 换成自己画的 `Text` 后 `fontWeight` 一定生效。
 * ② **上下留白一致**：`HdsListItemCardOptions` **没有内边距字段**（#76 已查尽：只有 cardHeight / cardPrefixMargin /
 *    cardSuffixMargin / cardBorderRadius …）。卡片高度原本由内容行数决定 → 实测三行卡 94.5vp、两行卡 63vp、
 *    文字到卡片边的留白 22.5vp vs 15.5vp，**每张都不一样**。要"所有卡片留白一致"只能把高度钉死：
 *    设 `cardHeight` 后每张卡同高，文字在卡内居中 → 上下留白对每张卡都是同一个值。
 */
// ⚠️ 这里必须显式导入 HDS 的 `TextOptions`：ArkUI 在 `component/text.d.ts` 里也有一个**全局**同名接口，
// 不导入就会解析到那个，赋给 HdsListItemCard 的 textItem 时报「no properties in common」。
import { HdsListItemCard, PrefixCustomBuilder, SuffixSwitch } from '@kit.UIDesignKit';
import { Task, TaskPriority, TaskStatus } from '../model';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';

/**
 * 卡片固定高度（vp）＝ **所有卡片同一个值**（袁正锟 2026-10-16 要求上下留白一致）。
 * 来历：改前三行卡 94.5vp / 两行卡 63vp，留白各是 22.5vp / 15.5vp；这里压到 76vp，
 * 三行卡留白降到 ~13vp，且 1/2/3 行的卡片**全是同一个高度、同一个留白**。
 * ⚠️ 已知代价：内容不足三行的卡片，文字会在卡内居中、上下会多出空白（这是"留白一致"的必然结果）。
 */
const CARD_HEIGHT_VP: number = 76;

/** 文字行距（vp）：HDS 原排版的行距实测 ≈20vp（标题）/ ≈16vp（副标题、描述），这里统一到 20vp 的下限档，避免挤压 */
const LINE_HEIGHT_VP: number = 20;

@ComponentV2
export struct TaskCard {
  @Require @Param task: Task;
  @Event onToggleComplete: () => void = () => {};
  @Event onRemindChange: (isOn: boolean) => void = () => {};

  @Computed
  get completed(): boolean {
    return this.task.status === TaskStatus.COMPLETED;
  }

  /** 未完成＝虚线圆，已完成＝带勾的圆。两个都是官方 Symbol 库里的名字 */
  @Computed
  get circleSymbol(): Resource {
    return this.completed ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.circle_dashed');
  }

  /**
   * 卡片底色用**重要程度**表达（袁正锟 2026-10-15：「description 里面的重要程度不显示了，
   * 改成普通卡片白色 / 重要黄色 / 严重红色」）＋ 完成态灰化。
   *
   * **优先级：完成态灰化 > 重要程度色**（做完的卡片统一灰掉，不再按轻重着色）。
   * 配色**全部取官方 token**（真值查自预览器资源表）：
   *   普通 → `ohos_id_color_card_bg`（`#ffffffff` 卡片白）
   *   重要 → `ohos_id_color_palette_aux11`（`#fff5dc62` 浅黄）—— ⚠️ 官方**没有"黄色"语义色**，
   *          这是官方调色板里最贴的暖色（属已知偏离：语义 token 用不了，借调色板 token）
   *   严重 → `comp_background_warning_secondary`（`#FDD9D9` 浅红）—— 官方语义色里 `alert`=橙(`#ff7500`)、
   *          `warning`=红(`#fa2a2d`)，两者都是饱和色、当整片卡面太重，故取「警示背景**次级色**」
   *   完成 → `gray_03`（`#d1d1d6`）
   */
  @Computed
  get cardBackground(): Resource {
    if (this.completed) {
      return $r('sys.color.gray_03');
    }
    if (this.task.priority === TaskPriority.URGENT) {
      return $r('sys.color.comp_background_warning_secondary');
    }
    if (this.task.priority === TaskPriority.IMPORTANT) {
      return $r('sys.color.ohos_id_color_palette_aux11');
    }
    return $r('sys.color.ohos_id_color_card_bg');
  }

  /** 三行文字共用的颜色：完成态一起变灰（官方次级文字色），否则官方一级文字色 */
  @Computed
  get textColor(): ResourceColor {
    return this.completed ? $r('sys.color.ohos_id_color_text_secondary') : $r('sys.color.ohos_id_color_text_primary');
  }

  /** 圆圈的官方图标色：完成态也用次级图标色一起灰掉 */
  @Computed
  get circleColor(): ResourceColor {
    return this.completed ? $r('sys.color.icon_secondary') : $r('sys.color.icon_primary');
  }

  /** 「响铃提醒」开关由 `reminderId` 派生（袁正锟 2026-10-14 定）：有值＝开 */
  @Computed
  get remindOn(): boolean {
    return this.task.reminderId !== undefined;
  }

  /** 有提醒时间才给开关；没有就整个 C 区不显示 */
  @Computed
  get remindSwitch(): SuffixSwitch | undefined {
    if (this.task.remindAt === undefined) {
      return undefined;
    }
    return new SuffixSwitch({
      isCheck: this.remindOn,
      onChange: (isOn: boolean) => {
        this.onRemindChange(isOn);
      }
    });
  }

  /** 副标题：在 HH:mm 截止 */
  @Computed
  get dueLabel(): string {
    return TaskListViewModel.dueLabel(this.task);
  }

  /** 描述行：优先级链取前两项 */
  @Computed
  get descriptionLabel(): string {
    return TaskListViewModel.descriptionLabel(this.task, new Date());
  }

  /** 自定义文字区之后，卡片的无障碍文本要自己拼（HDS 不再从 primaryText/description 取） */
  @Computed
  get accessibilityLabel(): string {
    return `${this.task.title} ${this.dueLabel} ${this.descriptionLabel}`;
  }

  @Builder
  prefixCircle() {
    // 圆圈尺寸：HDS 给卡片前缀图标的规格上限只有 24vp（IconSize.SYSTEM_ICON），
    // 袁正锟 2026-10-15 要求再大一档 → 借官方「圆形按钮图标」尺寸 token（28vp，视觉上大一圈）。
    SymbolGlyph(this.circleSymbol)
      .fontSize($r('sys.float.ohos_id_min_circle_button_icon_size'))
      .fontColor([this.circleColor])
      .onClick(() => {
        this.onToggleComplete();
      })
  }

  /**
   * 自定义文字区（官方 `TextItemOptions.customBuilder`）。
   * 标题**加粗**用官方 `FontWeight.Bold`；三行都限一行 + 省略号，避免长文本把固定高度的卡片撑破。
   * 副标题 / 描述**空的时候不渲染**（袁正锟 2026-10-14 定：空的不占行）—— 卡片高度由 `CARD_HEIGHT_VP` 钉死，
   * 所以行数少了不会让卡片变矮、留白也不会跟着变。
   */
  @Builder
  textBlock() {
    Column() {
      Text(this.task.title)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .lineHeight(`${LINE_HEIGHT_VP}vp`)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start)

      if (this.dueLabel !== '') {
        Text(this.dueLabel)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.textColor)
          .lineHeight(`${LINE_HEIGHT_VP}vp`)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
      }

      if (this.descriptionLabel !== '') {
        Text(this.descriptionLabel)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.textColor)
          .lineHeight(`${LINE_HEIGHT_VP}vp`)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    HdsListItemCard({
      cardBackgroundColor: this.cardBackground,
      cardHeight: CARD_HEIGHT_VP,
      prefixItem: new PrefixCustomBuilder((): void => {
        this.prefixCircle();
      }),
      textItem: {
        customBuilder: (): void => {
          this.textBlock();
        }
      },
      suffixItem: this.remindSwitch,
      accessibilityOptions: {
        accessibilityText: this.accessibilityLabel
      }
    })
  }
}
