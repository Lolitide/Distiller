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
 * 3. **点击区＝整块分组头**（袁正锟 2026-10-15 的最终结论：「把整个 Header 区域都改成可点击的」）：
 *    点击处理挂在最外层 `Row` 上（连带它的 `padding` 一起进热区），右侧只留一个**纯展示**的 `SymbolGlyph`。
 *    · 图标字号：官方 token `sys.float.subheader_right_icon_size`（SubHeader 右侧图标尺寸，真值 24vp / 32vp）
 *    · 图标颜色：官方 `sys.color.icon_primary`
 *    · 无障碍文本挂在 `Row` 上（它是可交互元素），图标本身不再单独播报
 *    **这一改让前面几轮全部作废**：按钮多大、与文字块怎么对齐、怎么拉伸，都不再需要 ——
 *    点击区是整行，图标只是指示器（`Row` 的 `VerticalAlign.Center` 自然把图标与文字块居中对齐）。
 *    ⚠️ 两条不要重犯：①别给子节点写 `height('100%')`（auto 容器里会解析到外层约束，见 §2.7 #17）；
 *    ②要让子节点与兄弟同高只能用 `Flex`+`ItemAlign.Stretch`，`Row` 的 `VerticalAlign` 没有拉伸档（见 §2.7 #18）。
 */
import { LengthMetrics, SubHeader } from '@kit.ArkUI';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';

/**
 * 组头在列表里要**回收的上留白**（vp）：官方 `SubHeader` 在标题上方自带一段留白、**没给旋钮**
 * （参数表里只有标题/副标题/操作项，官方也不建议给它设通用属性），所以只能整块组头往上提。
 *
 * 实测（袁正锟 2026-10-16 那轮）：上组最后一张卡片 → 组头顶标题 = **14.6vp**（未回收时 24.5vp），
 * 与「卡片↔卡片 8.2vp」「组头→本组卡片 ~8vp」构成 8 / 8 / 14.6 的节奏。
 *
 * 导出成公共常量是因为**搜索页也要用同一套**（结果列表复用同一个组头组件，
 * 两个页面的组间距必须一致）。
 */
export const GROUP_HEADER_LIST_PULL_UP_VP: number = 10;

@ComponentV2
export struct TaskGroupHeader {
  @Require @Param group: TaskDayGroup;
  /**
   * 副标题的两个数**由页面算好传进来**（袁正锟 2026-10-16 加了顶部筛选 Chip 之后）：
   * 顶部筛选生效时，「未完成 x 项 / 共 y 项」应当只统计**当前筛选下可见的任务**，
   * 才和列表里真正显示的卡片一致 —— 这两个数页面自己知道，组对象只知道全量。
   */
  @Require @Param pendingCount: number;
  @Require @Param totalCount: number;
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

  /** 副标题：未完成 x 项 / 共 y 项（两个数由页面按当前筛选算好传进来） */
  @Computed
  get subtitleLabel(): Resource {
    return $r('app.string.group_progress', this.pendingCount, this.totalCount);
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

      // 纯展示用（底色透明的 Button 与它视觉上一致，所以直接用它更省事）
      SymbolGlyph(this.toggleSymbol)
        .fontSize($r('sys.float.subheader_right_icon_size'))
        .fontColor([$r('sys.color.icon_primary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
    // 整块分组头都可点（袁正锟 2026-10-15）：点击区＝整行，不用再纠结按钮多大、与文字块怎么对齐
    .accessibilityText(this.toggleAccessibility)
    .onClick(() => {
      this.onToggle();
    })
  }
}
