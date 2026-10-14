/*
 * 组头 = 官方 SubHeader（系统预置 UI 组件库，@kit.ArkUI）负责「标题 + 副标题」的官方排版。
 *
 * 为什么展开/收起按钮**不在** SubHeader 里：
 *   SubHeader 的 `operationItem` 参数**没有装饰器**（官方 API 文档「装饰器类型」栏是 `-`，
 *   而 primaryTitle / secondaryTitle / operationType 都是 `@Prop`），
 *   按 ArkUI V1 的规矩，未加装饰器的子组件参数只在初始化时赋一次，父组件后续更新不会同步 ——
 *   所以放在 operationItem 里的图标永远停在初始态，做不出「点一下换图标」。
 *   按钮因此改用官方 SymbolGlyph 放在 SubHeader 外侧的同一行。
 *   依据：`docs/开发指南.md` §四 规则 3 —— 官方件做不了时用 ArkUI 基础组件，并在文件头注明。
 */
import { LengthMetrics, SubHeader } from '@kit.ArkUI';
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

  /** 右：展开 / 收起两个图标。展开态朝上，收起态朝下 */
  @Computed
  get toggleSymbol(): Resource {
    return this.group.expanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down');
  }

  /** 图标按钮没有文字，必须给无障碍文本（否则读屏选中时不播报） */
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
    Row() {
      Column() {
        SubHeader({
          secondaryTitle: this.subtitleLabel,
          titleBuilder: () => {
            this.titleArea();
          }
        })
      }
      .layoutWeight(1)

      SymbolGlyph(this.toggleSymbol)
        .accessibilityText(this.toggleAccessibility)
        .onClick(() => {
          this.onToggle();
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
  }
}
