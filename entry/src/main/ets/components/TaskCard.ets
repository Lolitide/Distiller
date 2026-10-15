/*
 * 卡片本体用官方 HdsListItemCard（@kit.UIDesignKit），未自造控件。
 * 两处例外说明：
 *   1. 圆圈：HdsListItemCard 的 PrefixIcon 没有 onClick（PrefixIconOptions 只有 iconSize / iconValue），
 *      点不动。要「点圆圈＝完成任务」只能走官方给的 A 区自定义内容口子 PrefixCustomBuilder，
 *      里面放官方 SymbolGlyph。
 *   2. 开关：用官方 SuffixSwitch（CheckOptions 里有 isCheck / onChange）。
 *
 * 右侧「响铃提醒」开关**按有没有 `remindAt` 决定显不显示**（需求方 2026-10-14）：
 * 没有提醒时间，开关本身就没意义，所以 `suffixItem` 直接传 `undefined`（官方约定 undefined ＝ 不显示 C 区）。
 */
import { HdsListItemCard, PrefixCustomBuilder, SuffixSwitch } from '@kit.UIDesignKit';
import { TextModifier } from '@kit.ArkUI';
import { Task, TaskStatus } from '../model';
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
   * 完成态整卡灰化：官方色阶的第三档。
   * 踩过：一开始用 `comp_background_gray`，它解析后是 `#f1f3f5`，**和页面背景
   * `ohos_id_color_sub_background`(#fff1f3f5) 一模一样** → 卡片一灰就等于融进背景、看不见了。
   * 官方浅色灰阶（真值查自预览器资源表）：`#f1f3f5`(页面) → `#e5e5ea`(gray_02) → `#d1d1d6`(gray_03)
   * → 取 `gray_03`，与卡片白 `#ffffff` 和页面灰都分得开；它有深色档（#3F4246 一带）。
   */
  @Computed
  get cardBackground(): Resource {
    return this.completed ? $r('sys.color.gray_03') : $r('sys.color.ohos_id_color_card_bg');
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

  /** 「响铃提醒」开关由 `reminderId` 派生（需求方 2026-10-14 定）：有值＝开 */
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

  @Builder
  prefixCircle() {
    // 圆圈尺寸：HDS 给卡片前缀图标的规格上限只有 24vp（IconSize.SYSTEM_ICON），
    // 需求方 2026-10-15 要求再大一档 → 借官方「圆形按钮图标」尺寸 token（28vp，视觉上大一圈）。
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
        secondaryText: { text: this.dueLabel, modifier: this.textModifier },
        description: { text: this.descriptionLabel, modifier: this.textModifier }
      },
      suffixItem: this.remindSwitch
    })
  }
}
