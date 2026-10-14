/*
 * UI Design Kit 无对应组件：HDS 没有「列表分组头」。
 * 组头用官方 ArkUI 的「系统预置 UI 组件库」SubHeader（@kit.ArkUI）承载
 * 「标题 + 副标题 + 右侧按钮」，未自造任何控件。
 */
import { OperationType, SubHeader } from '@kit.ArkUI';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';

const WEEKDAY_LABELS: Resource[] = [
  $r('app.string.weekday_sun'),
  $r('app.string.weekday_mon'),
  $r('app.string.weekday_tue'),
  $r('app.string.weekday_wed'),
  $r('app.string.weekday_thu'),
  $r('app.string.weekday_fri'),
  $r('app.string.weekday_sat')
];

@ComponentV2
export struct TaskGroupHeader {
  @Require @Param group: TaskDayGroup;
  @Event onToggle: () => void = () => {};

  /** 左：今天 / 明天 / 周几 */
  @Computed
  get dayLabel(): Resource {
    if (this.group.dayOffset === 0) {
      return $r('app.string.group_today');
    }
    if (this.group.dayOffset === 1) {
      return $r('app.string.group_tomorrow');
    }
    return WEEKDAY_LABELS[this.group.weekdayIndex];
  }

  /** 左：MM月DD日 */
  @Computed
  get monthDayLabel(): Resource {
    return $r('app.string.date_month_day', this.group.month, this.group.day);
  }

  /** 副标题：未完成 x 项 / 共 y 项 */
  @Computed
  get subtitleLabel(): Resource {
    return $r('app.string.group_progress', this.group.pendingCount, this.group.totalCount);
  }

  /** 右：展开 / 收起。展开态是向上箭头，收起态是向下箭头 */
  @Computed
  get toggleSymbol(): Resource {
    return this.group.expanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down');
  }

  /** 右下角图标没有文字，必须给无障碍文本 */
  @Computed
  get toggleAccessibility(): Resource {
    return this.group.expanded ? $r('app.string.group_collapse') : $r('app.string.group_expand');
  }

  @Builder
  titleArea() {
    if (this.group.hasDate) {
      Row() {
        Text(this.dayLabel)
        Text($r('app.string.group_title_sep'))
        Text(this.monthDayLabel)
      }
    } else {
      Text($r('app.string.group_undated'))
    }
  }

  build() {
    SubHeader({
      secondaryTitle: this.subtitleLabel,
      titleBuilder: () => {
        this.titleArea();
      },
      operationType: OperationType.ICON_GROUP,
      operationItem: [{
        value: this.toggleSymbol,
        action: () => {
          this.onToggle();
        },
        accessibilityText: this.toggleAccessibility
      }]
    })
  }
}
