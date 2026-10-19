/*
 * 卡片本体用官方 HdsListItemCard（@kit.UIDesignKit），未自造控件。
 * 三处例外说明：
 *   1. 圆圈：HdsListItemCard 的 PrefixIcon 没有 onClick（PrefixIconOptions 只有 iconSize / iconValue），
 *      点不动。要「点圆圈＝完成任务」只能走官方给的 A 区自定义内容口子 PrefixCustomBuilder，
 *      里面放官方 SymbolGlyph。
 *   2. 开关：用官方 SuffixSwitch（CheckOptions 里有 isCheck / onChange）。
 *   3. 文字块：走官方 `TextItemOptions.customBuilder`（**不是** `primaryText` + `TextModifier`）。
 *
 * ── 为什么文字块必须自定义（需求方 2026-10-16：「Card 的 primaryText 加粗；Card 的上下边距减小，
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
import { HdsListItemCard, PrefixCustomBuilder, SuffixCustomBuilder } from '@kit.UIDesignKit';
import { Task, TaskAlarm, TaskPriority, TaskStatus } from '../model';
import { TaskStatusIcon } from './TaskStatusIcon';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { ThemeStore } from '../utils/Theme';

/**
 * 卡片固定高度（vp）＝ **所有卡片同一个值**（需求方 2026-10-16 要求上下留白一致）。
 * 来历：改前三行卡 94.5vp / 两行卡 63vp，留白各是 22.5vp / 15.5vp；这里压到 76vp，
 * 三行卡留白降到 ~13vp，且 1/2/3 行的卡片**全是同一个高度、同一个留白**。
 * ⚠️ 已知代价：内容不足三行的卡片，文字会在卡内居中、上下会多出空白（这是"留白一致"的必然结果）。
 */
const CARD_HEIGHT_VP: number = 76;

/** 文字行距（vp）：HDS 原排版的行距实测 ≈20vp（标题）/ ≈16vp（副标题、描述），这里统一到 20vp 的下限档，避免挤压 */
const LINE_HEIGHT_VP: number = 20;

/* ── 第二行（标签胶囊 / 重要性标识 / 截止 / 重复）的尺寸 ── */
/** 第二行行高（vp）：比标题略矮，胶囊与圆圈在这个高度里居中 */
const SECOND_LINE_HEIGHT_VP: number = 18;
/** 第二行元素间距（vp） */
const SECOND_LINE_GAP_VP: number = 6;
/**
 * 卡片第二行「截止」列的**固定宽度**（vp）：2026-10-19 定。
 * 定宽 + 右对齐 → 所有卡片的截止文案右边缘落在同一条竖线上，
 * 不会因为「明天截止」和「10 天后截止」长短不同而左右跳动。
 */
/** 「XXX」槽宽度（vp）：定宽居中，14h / 3 天 / 已过期 都放得下 */
/**
 * tag 槽的固定宽度（vp）：约 4 个汉字 + 内边距。
 * 槽定宽是为了让后面的**重要性标识起点对齐**；胶囊本身仍按内容自适应。
 */
/**
 * 分隔点：第二行 tag 与后面内容之间的「·」（2026-10-19 第五次调整）。
 * 用全角间隔号而不是空格，视觉上更明确地把「分类」和「时间」分开。
 */
const INTERPUNCT: string = '·';
const TAG_SLOT_WIDTH_VP: number = 52;
/** 重复标识图标字号（vp）：第二行最后那个小图标 */
const REPEAT_ICON_SIZE_VP: number = 16;
/** 重复图标槽宽度（vp）：**始终占位**，这样有无重复铃铛位置都不动 */
const REPEAT_SLOT_WIDTH_VP: number = 28;
/** 铃铛图标字号（vp） */
const BELL_ICON_SIZE_VP: number = 20;
/** 铃铛可点区域边长（vp）：官方最小可点 40 */
const BELL_HIT_SIZE_VP: number = 40;
/** 标签胶囊左右内边距（vp） */
const TAG_CHIP_SIDE_PADDING_VP: number = 6;
/** 标签胶囊上下内边距（vp） */
const TAG_CHIP_VERTICAL_PADDING_VP: number = 1;
/** 标签胶囊圆角（vp）：取其高度的一半，做成完整胶囊 */
const TAG_CHIP_RADIUS_VP: number = 8;

/* ── 重要性标识（字段表 §2.1 的三态图形）── */
/** 圈内那个感叹号 */
const PRIORITY_MARK: string = '!';
/** 标识直径（vp）：与第二行行高同档，不撑高卡片 */
const PRIORITY_BADGE_SIZE_VP: number = 14;
/** 重要性占位圈的不透明度：够看出是个圈，又不至于抢眼（2026-10-19 第六次） */
const PRIORITY_PLACEHOLDER_OPACITY: number = 0.28;
/** 标识字号（vp）：圈内感叹号 */
const PRIORITY_BADGE_FONT_SIZE: number = 10;
/** 空心圈的描边宽度（vp） */
const PRIORITY_BADGE_BORDER_VP: number = 1.5;

@ComponentV2
export struct TaskCard {
  @Require @Param task: Task;
  /** 「数据 ＋ 编辑态」store：编辑态与勾选状态从这里读（卡片自己算，ForEach 不用重跑也能刷新） */
  @Require @Param store: TaskListStore;
  @Event onToggleComplete: () => void = () => {};
  @Event onRemindChange: (isOn: boolean) => void = () => {};
  /** 点整卡 → 交给页面去压任务详情页（卡片本身不知道路由） */
  @Event onOpen: () => void = () => {};

  /**
   * 视觉个性化（`utils/Theme.ets`）：卡片密度与主题色都从这里读。
   * 用 `AppStorageV2` 共享同一实例 → 设置页改完，返回列表立刻生效，不需要页面间传参。
   */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 是否处于编辑（多选）模式 */
  @Computed
  get editing(): boolean {
    return this.store.editing;
  }

  /** 这条任务有没有被勾上 */
  @Computed
  get selected(): boolean {
    return this.store.isSelected(this.task.id);
  }

  @Computed
  get completed(): boolean {
    return this.task.status === TaskStatus.COMPLETED;
  }

  /**
   * 卡片底色：**统一白底，完成态灰化**。
   *
   * ⚠️ 2026-10-17 按字段表 §2.1 改为图形标识后，这里**不再**按重要程度着色
   * （旧口径：普通白 / 重要浅黄 / 严重浅红 —— 已废弃，重要程度改由第二行的红圈/红实心圆表达）。
   *   统一白底 → `ohos_id_color_card_bg`（`#ffffffff`）
   *   完成   → `gray_03`（`#d1d1d6`，官方浅灰阶第三档）
   */
  @Computed
  get cardBackground(): Resource {
    if (this.completed) {
      return $r('sys.color.gray_03');
    }
    return $r('sys.color.ohos_id_color_card_bg');
  }

  /** 三行文字共用的颜色：完成态一起变灰（官方次级文字色），否则官方一级文字色 */
  @Computed
  get textColor(): ResourceColor {
    return this.completed ? $r('sys.color.ohos_id_color_text_secondary') : $r('sys.color.ohos_id_color_text_primary');
  }

  /**
   * 「响铃提醒」开关的状态。
   *
   * v1 字段表（第 16/18 项）明确：**`alarm` 是用户意图、开关读它**；`reminderId` 是"已发布的本地提醒句柄"，
   * 「为空而 `alarm=1` ⇒ 开关开了但未生效（如超 30 条报 1700002）」。
   * 所以这里改读 `alarm`（原来是从 `reminderId` 派生）—— 否则"提醒配额满了"时开关会莫名自己变灰。
   */
  @Computed
  get remindOn(): boolean {
    return this.task.alarm === TaskAlarm.ON;
  }

  /**
   * 右侧 C 区：**铃铛按钮**（2026-10-19 定：「每一项任务最右侧是是否启用提醒的铃铛按钮」）。
   *
   * 两处与旧实现的差别：
   *  1. 旧的是 `SuffixSwitch` 开关，现在是**图标按钮**（点一下切 `alarm`）；
   *  2. 旧的**只在 `remindAt` 有值时才显示**，现在**每一项都显示** ——
   *     没设提醒时间的任务走「设置页的默认提醒通道」（提前量），所以铃铛永远有意义。
   *
   * 图标：开＝`bell`（强调色）、关＝`bell_slash`（次级色）。
   * 用 `SuffixCustomBuilder` 自绘：官方 `SuffixIcon` 的选项里没有 `onClick`，点不动
   * （与左侧圆圈同一个坑，左侧走的是 `PrefixCustomBuilder`）。
   */
  /**
   * C 区：**重复图标 + 铃铛**。
   *
   * 2026-10-19 第二次调整：「重复性图标若有，放在通知按钮左边，不在任务名称一行，
   * 也不在 tag 那一行。**预留一块间距放它**」。
   * 所以这里是一个 Row：左边固定宽度的重复槽（没有重复也占位，避免铃铛左右跳动），
   * 右边是铃铛本体。整块仍走 `SuffixCustomBuilder`（官方的 `SuffixIcon` 没有 onClick）。
   */
  @Computed
  get suffixButtons(): SuffixCustomBuilder {
    return new SuffixCustomBuilder((): void => {
      this.suffixRow();
    });
  }

  @Builder
  suffixRow() {
    Row() {
      // 重复标识槽：**固定占位**（无重复时为空也不塌陷）
      Stack() {
        if (this.repeatLabel !== '') {
          SymbolGlyph($r('sys.symbol.repeat'))
            .fontSize(REPEAT_ICON_SIZE_VP)
            .fontColor([$r('sys.color.icon_secondary')])
        }
      }
      .width(REPEAT_SLOT_WIDTH_VP)
      .height(BELL_HIT_SIZE_VP)
      .accessibilityText(this.repeatLabel)

      this.bellGlyph()
    }
    .alignItems(VerticalAlign.Center)
  }

  /** 铃铛可点区域边长（vp）：官方最小可点 40，视觉 20、热区 40 */
  @Builder
  bellGlyph() {
    SymbolGlyph(this.remindOn ? $r('sys.symbol.bell') : $r('sys.symbol.bell_slash'))
      .fontSize(BELL_ICON_SIZE_VP)
      .fontColor([this.remindOn
        ? this.themeStore.accent.light
        : $r('sys.color.icon_tertiary')])
      .width(BELL_HIT_SIZE_VP)
      .height(BELL_HIT_SIZE_VP)
      .onClick(() => {
        // 点铃铛＝翻转用户意图（alarm 0/1）；真正的发布/撤销由 service/system 负责
        this.onRemindChange(!this.remindOn);
      })
      .accessibilityText(this.remindOn
        ? $r('app.string.card_bell_on')
        : $r('app.string.card_bell_off'))
  }

  /** 卡片第二行：截止信息（`在 HH:mm 截止`）。没有到期时间就为空，不占位 */
  @Computed
  get dueLabel(): string {
    return TaskListViewModel.dueLabel(this.task);
  }

  /**
  /** 卡片第二行：重复性标识（`每周一、二、四`）。非周期任务为空 */
  @Computed
  get repeatLabel(): string {
    return TaskListViewModel.repeatLabel(this.task);
  }

  /**
   * 第二行最左边那个胶囊要显示的文字（2026-10-19 第三次调整）：
   *
   *   ① 有标签 → 显示**第一个标签**（只显示 1 个，其余在详情页看）；
   *   ② 没有标签、但有类型 → 显示**类型名**（`category`，如「作业」「考试」）；
   *   ③ 两样都没有 → 空串，整块不渲染。
   *
   * 宽度**按字数自适应**（作者：「标签还是多少个字就多宽吧」），不再定宽 4 字。
   */
  @Computed
  get chipText(): string {
    const tags: string[] | undefined = this.task.tags;
    if (tags !== undefined && tags.length > 0) {
      return tags[0];
    }
    const category: string | undefined = this.task.category;
    return category === undefined ? '' : category;
  }

  /** 重要性标识是否占位：**0（普通）不占位**，不是"显示一个普通样式" */
  @Computed
  get showPriorityBadge(): boolean {
    return this.task.priority !== TaskPriority.NORMAL;
  }

  /** 严重（2）＝ 红色实心圆 + 白感叹号；重要（1）＝ 红色空心圈 + 红感叹号 */
  @Computed
  get prioritySolid(): boolean {
    return this.task.priority === TaskPriority.URGENT;
  }

  /** 自定义文字区之后，卡片的无障碍文本要自己拼（HDS 不再从 primaryText/description 取） */
  @Computed
  get accessibilityLabel(): string {
    const priorityText: string = this.showPriorityBadge
      ? `${TaskListViewModel.priorityLabel(this.task.priority)} ` : '';
    const repeatText: string = this.repeatLabel === '' ? '' : `${this.repeatLabel} `;
    return `${priorityText}${this.task.name} ${this.dueLabel} ${repeatText}`;
  }

  @Builder
  prefixCircle() {
    // 圆圈 / 方框勾选框的形态、颜色、无障碍文本都已经收进共用组件 `TaskStatusIcon`
    // （详情页标题前那个圆圈也是它，别在两处各写一遍）
    TaskStatusIcon({
      task: this.task,
      selectionMode: this.editing,
      selected: this.selected,
      onTap: () => {
        // 编辑态点它＝勾选/取消勾选；普通态点它＝完成/退回未完成（需求方 2026-10-14 定）
        if (this.editing) {
          this.store.toggleSelect(this.task.id);
          return;
        }
        this.onToggleComplete();
      }
    })
  }

  /**
   * 自定义文字区（官方 `TextItemOptions.customBuilder`）。
   *
   * **卡片只有两行**（字段表 §2，2026-10-17 定）：
   *   第 1 行 = 任务名（粗体）
   *   第 2 行 = **标签胶囊 → 重要性标识 → 截止信息 → 重复性标识**，四样依次排在同一行
   * 不再有「来源于 …」那第三行（`source` 按字段表只在详情页显示）。
   *
   * 空的部分**不占位**；卡片高度由 `CARD_HEIGHT_VP` 钉死，所以行内元素少了也不会变矮。
   */
  @Builder
  textBlock() {
    Column() {
      Text(this.task.name)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .lineHeight(`${LINE_HEIGHT_VP}vp`)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start)

      Row({ space: SECOND_LINE_GAP_VP }) {
        // ===== 第二行（2026-10-19 第三次调整）=====
        // ① tag：**几个字就多宽**（不再定宽 4 字）；没标签时显示**类型名**；
        //    两样都没有才空着（此时整行只剩重要性与截止）。
        // ② 重要性：固定槽（没有也占位），保持后面内容不左右跳。
        // ③④ 截止：「XXX」定宽居中 + 「后截止」固定文本，**去掉描边框、字号调大到 body2**
        //    （作者：「截止时间不需要加边框，这样字号太小了」）。
        // ⑤ 重复图标已移到 C 区（铃铛左边），第二行不再有它。

        // ① 标签槽：**槽定宽、胶囊自身自适应**（2026-10-19 第四次调整）
        //    作者原话：「tag 自身自适应，但 tag 占定宽位置，让重要性标识对齐」
        //    —— 所以外面这层 Row 是固定宽度（保证后面重要性标识起点一致），
        //    里面的胶囊按内容宽（2 字就是 2 字的宽），**左对齐**贴槽的起点。
        //    标签过长时在槽内省略，不会把后面的内容顶开。
        Row() {
          if (this.chipText !== '') {
            Text(this.chipText)
              .fontSize($r('sys.float.ohos_id_text_size_caption'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: TAG_SLOT_WIDTH_VP })
              .padding({
                left: TAG_CHIP_SIDE_PADDING_VP,
                right: TAG_CHIP_SIDE_PADDING_VP,
                top: TAG_CHIP_VERTICAL_PADDING_VP,
                bottom: TAG_CHIP_VERTICAL_PADDING_VP
              })
              .backgroundColor($r('sys.color.comp_background_secondary'))
              .borderRadius(TAG_CHIP_RADIUS_VP)
          }
        }
        .width(TAG_SLOT_WIDTH_VP)
        .justifyContent(FlexAlign.Start)
        .flexShrink(0)

        // ①-b 分隔点「·」（2026-10-19 第五次调整：「尝试用 · 分隔」）。
        //    放在 tag 槽之后；只有真的画了标签/类型才画点，否则整行会以孤零零一个点开头。
        if (this.chipText !== '') {
          Text(INTERPUNCT)
            .fontSize($r('sys.float.ohos_id_text_size_caption'))
            .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
            .maxLines(1)
            .flexShrink(0)
        }

        // ② 重要性标识：**固定槽，没有也占位**（作者：「如果没有预留空位」）。
        //    2026-10-19 第六次：「尝试给任务重要性标识的占位使用一个半透明的灰色的圆圈」——
        //    所以 0 档（普通）不再留白，画一个半透明灰圈，视觉上把"这一格是重要性"表达出来。
        Stack() {
          if (this.showPriorityBadge) {
            this.priorityBadge()
          } else {
            // 占位圈：灰底 + 低透明度，明显是"空位"而不是"没有内容"
            Row()
              .width(PRIORITY_BADGE_SIZE_VP)
              .height(PRIORITY_BADGE_SIZE_VP)
              .borderRadius(PRIORITY_BADGE_SIZE_VP / 2)
              .backgroundColor($r('sys.color.icon_tertiary'))
              .opacity(PRIORITY_PLACEHOLDER_OPACITY)
          }
        }
        .width(PRIORITY_BADGE_SIZE_VP)
        .height(PRIORITY_BADGE_SIZE_VP)
        .flexShrink(0)

        // ③ 截止文字：**整体自然显示**（作者：「后面的所有字（已过期 / 未定时 /
        //    xxx 后截止）直接显示就行」）—— 不再拆「XXX + 后截止」两段、也不再定宽居中。
        Text(this.dueLabel)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor(this.textColor)
          .maxLines(1)
          .flexShrink(1)

        // 右侧弹性空白：剩下的空间留给 C 区（重复槽 + 铃铛）
        Blank()
      }
      .width('100%')
      .height(`${SECOND_LINE_HEIGHT_VP}vp`)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 重要性标识（字段表 §2.1 的三态图形）。
   *   1 → 红色空心圈 + 红色感叹号
   *   2 → 红色实心圆 + 白色感叹号
   * 用 `Stack` + `Text('!')` 手绘：官方 Symbol 库里没有"圈内感叹号"这一族，
   * 且此处需要"空心/实心"两种描边，手绘比找 Symbol 更可控。红色统一取 `sys.color.warning`。
   */
  @Builder
  priorityBadge() {
    Stack() {
      Text(PRIORITY_MARK)
        .fontSize(PRIORITY_BADGE_FONT_SIZE)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.prioritySolid
          ? $r('sys.color.ohos_id_color_text_primary_contrary')
          : $r('sys.color.warning'))
    }
    .width(PRIORITY_BADGE_SIZE_VP)
    .height(PRIORITY_BADGE_SIZE_VP)
    .borderRadius(PRIORITY_BADGE_SIZE_VP / 2)
    .backgroundColor(this.prioritySolid ? $r('sys.color.warning') : Color.Transparent)
    .border({
      width: this.prioritySolid ? 0 : PRIORITY_BADGE_BORDER_VP,
      color: $r('sys.color.warning')
    })
    .flexShrink(0)
  }

  build() {
    HdsListItemCard({
      cardBackgroundColor: this.cardBackground,
      // 卡片高度随「设置 → 视觉个性化 → 卡片密度」变（标准 76 / 紧凑 64）
      cardHeight: this.themeStore.cardHeight,
      prefixItem: new PrefixCustomBuilder((): void => {
        this.prefixCircle();
      }),
      textItem: {
        customBuilder: (): void => {
          this.textBlock();
        }
      },
      // C 区：铃铛按钮（每一项都有，点它切 alarm）
      suffixItem: this.suffixButtons,
      accessibilityOptions: {
        accessibilityText: this.accessibilityLabel
      }
    })
    // 整卡可点 → 进任务详情（需求方 2026-10-16）。前缀圆圈与右侧开关各自有 onClick，
    // 点它们不会冒泡到这里，所以「点圆圈改完成状态」不会误开详情。
    .onClick(() => {
      this.onOpen();
    })
  }
}
