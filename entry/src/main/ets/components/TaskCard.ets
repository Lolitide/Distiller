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
import { HdsListItemCard, PrefixCustomBuilder, SuffixSwitch } from '@kit.UIDesignKit';
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

  @Builder
  prefixCircle() {
    SymbolGlyph(this.circleSymbol)
      .fontSize(24)
      .onClick(() => {
        this.onToggleComplete();
      })
  }

  build() {
    HdsListItemCard({
      cardBackgroundColor: $r('sys.color.ohos_id_color_card_bg'),
      prefixItem: new PrefixCustomBuilder((): void => {
        this.prefixCircle();
      }),
      textItem: {
        primaryText: { text: this.task.title },
        secondaryText: { text: this.dueLabel },
        description: { text: this.descriptionLabel }
      },
      suffixItem: this.remindSwitch
    })
  }
}
