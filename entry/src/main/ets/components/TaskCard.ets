/*
 * 卡片本体用官方 HdsListItemCard（@kit.UIDesignKit），未自造控件。
 * 两处例外说明：
 *   1. 圆圈：HdsListItemCard 的 PrefixIcon 没有 onClick（PrefixIconOptions 只有 iconSize / iconValue），
 *      点不动。要「点圆圈＝完成任务」只能走官方给的 A 区自定义内容口子 PrefixCustomBuilder，
 *      里面放官方 SymbolGlyph。
 *   2. 开关：用官方 SuffixSwitch（CheckOptions 里有 isCheck / onChange）。
 *
 * 右侧「响铃提醒」开关**按有没有 `remindAt` 决定显不显示**（袁正锟 2026-10-14）：
 * 没有提醒时间，开关本身就没意义，所以 `suffixItem` 直接传 `undefined`（官方约定 undefined ＝ 不显示 C 区）。
 */
// ⚠️ 这里必须显式导入 HDS 的 `TextOptions`：ArkUI 在 `component/text.d.ts` 里也有一个**全局**同名接口，
// 不导入就会解析到那个，赋给 HdsListItemCard 的 textItem 时报「no properties in common」。
import { HdsListItemCard, PrefixCustomBuilder, SuffixSwitch, TextOptions } from '@kit.UIDesignKit';
import { TextModifier } from '@kit.ArkUI';
import { Task, TaskPriority, TaskStatus } from '../model';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';

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

  /** 完成态三行文字一起变灰：官方次级文字色 */
  @Computed
  get textModifier(): TextModifier {
    return new TextModifier().fontColor(
      this.completed ? $r('sys.color.ohos_id_color_text_secondary') : $r('sys.color.ohos_id_color_text_primary')
    );
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

  /** 副标题：在 HH:mm 截止。**空的时候传 undefined 而不是空串**，避免白占一行高度 */
  @Computed
  get secondaryTextOptions(): TextOptions | undefined {
    if (this.dueLabel === '') {
      return undefined;
    }
    return { text: this.dueLabel, modifier: this.textModifier };
  }

  /** 描述行：优先级链取前两项。**空的时候不传**，同上 */
  @Computed
  get descriptionOptions(): TextOptions | undefined {
    if (this.descriptionLabel === '') {
      return undefined;
    }
    return { text: this.descriptionLabel, modifier: this.textModifier };
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

  build() {
    HdsListItemCard({
      cardBackgroundColor: this.cardBackground,
      prefixItem: new PrefixCustomBuilder((): void => {
        this.prefixCircle();
      }),
      textItem: {
        primaryText: { text: this.task.title, modifier: this.textModifier },
        secondaryText: this.secondaryTextOptions,
        description: this.descriptionOptions
      },
      suffixItem: this.remindSwitch
    })
  }
}
