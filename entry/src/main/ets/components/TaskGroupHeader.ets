/*
 * 组头 = 官方 SubHeader（系统预置 UI 组件库，@kit.ArkUI）负责「标题 + 副标题」的官方排版。
 *
 * 两个官方坑（都不是写法问题，是组件限制）：
 *
 * 1. **展开/收起按钮不能放在 SubHeader 的 `operationItem` 里**：该参数**没有装饰器**
 *    （官方 API 表「装饰器类型」栏是 `-`，而 primaryTitle / secondaryTitle / operationType 是 `@Prop`），
 *    按 ArkUI V1 规矩，未加装饰器的子组件参数只初始化一次、父组件更新不同步 → 图标永远停在初始态。
 *    所以按钮用官方 SymbolGlyph 放在 SubHeader 外侧。依据：`docs/开发指南.md` §四 规则 3。
 *
 * 2. **不能用 `titleBuilder`**：用了它 `secondaryTitle` 会一起不显示（实测副标题完全不渲染；
 *    官方文档没写这条覆盖关系）。所以标题必须走 `primaryTitle`。
 *    而标题是「今天/明天/周几」加「MM月DD日」两段拼成一句，`$r()` 的实参不能是另一个 Resource，
 *    拼不了 —— 于是按官方《避免硬编码与拼接》的做法，把 9 种组合各做成一条带 `%d` 占位的资源。
 *    依据：`开发指南/Localization_Kit.../提升可翻译性/避免硬编码与拼接/l10n-hard-coding-concatenate`。
 *
 * 3. **按钮**（袁正锟 2026-10-15 的收敛结论）：
 *    用**官方 `Button` 图标按钮**承载：`Button({ type: ButtonType.Circle, stateEffect: true }) { SymbolGlyph(...) }`。
 *    —— 点击区由**按钮自己**定，比在 `SymbolGlyph` 上想办法可靠（前三次分别试过 `.padding()`、`responseRegion`、
 *    `.height('100%')`，前两个"看不出效果"、第三个把图标撑成整屏高）。
 *    · 图标字号：官方 token `sys.float.subheader_right_icon_size`（SubHeader 右侧图标尺寸，真值 24vp / 32vp）
 *    · 图标颜色：官方 `sys.color.icon_primary`（按钮默认字色是白的，不显式设会看不见）
 *    · 按钮尺寸：**正方形，边长也用 `subheader_right_icon_size`** —— 这样它**不会比标题+副标题那一块还高**，
 *      再靠外层的 `VerticalAlign.Center` 自动与文字块的水平线重合。
 *      ※ 起初用 `titlebar_icon_background_height`(=40vp) 做边长，袁正锟反馈「按钮比左侧 titleLabel 还高」，
 *      所以要"和 title+subtitle 整块重合"就不能让按钮高过文字块 —— 实测这是最稳的做法。
 *    · 按钮底色：官方 `sys.color.button_background_color_transparent`（保持分组头原样，只留按压水波纹）
 *    ⚠️ **不要再给子节点写 `height('100%')`**：容器高度 auto 时百分比会解析到外层约束上（见 §2.7 #17）。
 */
import { LengthMetrics, SubHeader } from '@kit.ArkUI';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';

@ComponentV2
export struct TaskGroupHeader {
  @Require @Param group: TaskDayGroup;
  @Event onToggle: () => void = () => {};

  /** 左：标题 = 「今天/明天/周几 · MM月DD日」，走带占位的资源，不做字符串拼接 */
  @Computed
  get titleLabel(): Resource {
    if (!this.group.hasDate) {
      return $r('app.string.group_undated');
    }
    if (this.group.dayOffset === 0) {
      return $r('app.string.group_title_today', this.group.month, this.group.day);
    }
    if (this.group.dayOffset === 1) {
      return $r('app.string.group_title_tomorrow', this.group.month, this.group.day);
    }
    return this.weekdayTitle(this.group.weekdayIndex);
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

  /** 0=周日 … 6=周六。资源名不能运行时拼接（§2.3 坑 1），只能逐个列 */
  private weekdayTitle(index: number): Resource {
    if (index === 0) {
      return $r('app.string.group_title_weekday_sun', this.group.month, this.group.day);
    }
    if (index === 1) {
      return $r('app.string.group_title_weekday_mon', this.group.month, this.group.day);
    }
    if (index === 2) {
      return $r('app.string.group_title_weekday_tue', this.group.month, this.group.day);
    }
    if (index === 3) {
      return $r('app.string.group_title_weekday_wed', this.group.month, this.group.day);
    }
    if (index === 4) {
      return $r('app.string.group_title_weekday_thu', this.group.month, this.group.day);
    }
    if (index === 5) {
      return $r('app.string.group_title_weekday_fri', this.group.month, this.group.day);
    }
    return $r('app.string.group_title_weekday_sat', this.group.month, this.group.day);
  }

  build() {
    Row() {
      Column() {
        SubHeader({
          primaryTitle: this.titleLabel,
          secondaryTitle: this.subtitleLabel
        })
      }
      .layoutWeight(1)

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph(this.toggleSymbol)
          .fontSize($r('sys.float.subheader_right_icon_size'))
          .fontColor([$r('sys.color.icon_primary')])
      }
      .width($r('sys.float.subheader_right_icon_size'))
      .height($r('sys.float.subheader_right_icon_size'))
      .backgroundColor($r('sys.color.button_background_color_transparent'))
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
