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
import { HdsListItemCard, PrefixCustomBuilder, SuffixCustomBuilder } from '@kit.UIDesignKit';
import { Task, TaskAlarm, TaskPriority, TaskStatus } from '../model';
import { TaskStatusIcon } from './TaskStatusIcon';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { DueParts, TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { ThemeStore } from '../utils/Theme';

/**
 * 卡片固定高度（vp）＝ **所有卡片同一个值**（袁正锟 2026-10-16 要求上下留白一致）。
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
/** 标签槽宽度（vp）：按 4 个汉字宽算，文字居中；没标签也占住这个宽度（2026-10-19 效果图） */
const TAG_CHIP_WIDTH_VP: number = 60;
/** 「XXX」槽宽度（vp）：定宽居中，14h / 3 天 / 已过期 都放得下 */
const DUE_VALUE_WIDTH_VP: number = 48;
/** 截止胶囊左右内边距（vp） */
const DUE_CHIP_SIDE_PADDING_VP: number = 6;
/** 截止胶囊描边宽度（vp） */
const DUE_CHIP_BORDER_VP: number = 1;
/** 「XXX」与「后截止」之间的间距（vp） */
const DUE_SUFFIX_GAP_VP: number = 2;
/** 重复标识图标字号（vp）：第二行最后那个小图标 */
const REPEAT_ICON_SIZE_VP: number = 16;
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
  @Computed
  get bellButton(): SuffixCustomBuilder {
    return new SuffixCustomBuilder((): void => {
      this.bellGlyph();
    });
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
   * 截止文案拆两段：`value` 进定宽居中槽、`suffix` 是固定的「后截止」。
   * 拆开是为了让「后截止」三个字**永远落在同一横向位置**（2026-10-19 效果图）。
   */
  @Computed
  get dueParts(): DueParts {
    return TaskListViewModel.dueParts(this.task);
  }

  /** 卡片第二行：重复性标识（`每周一、二、四`）。非周期任务为空 */
  @Computed
  get repeatLabel(): string {
    return TaskListViewModel.repeatLabel(this.task);
  }

  /**
   * 卡片第二行的标签胶囊：**只显示 1 个**（2026-10-19 定：「标签胶囊仅显示 1 个 tag，
   * 不做多个的区分，所有的标签可以显示在详情页里」）。
   * 因此**不再折出 `+n` 计数徽标** —— 那会看起来像"还有别的标签要区分"，与"只显示一个"的意图相反；
   * 全部标签在详情页的 `TaskTagsCard` 里逐条列出。
   */
  @Computed
  get tagChipList(): string[] {
    const tags: string[] | undefined = this.task.tags;
    if (tags === undefined || tags.length === 0) {
      return [];
    }
    return [tags[0]];
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
        // 编辑态点它＝勾选/取消勾选；普通态点它＝完成/退回未完成（袁正锟 2026-10-14 定）
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
        // ===== 固定槽位对齐（2026-10-19 作者效果图）=====
        // 第二行从左到右是**五个固定宽度的槽**，内容居中：
        //   ① tag（按 4 个字定宽） ② 重要性 ③ 「XXX」 ④ 「后截止」 ⑤ 重复图标
        // 每个槽**没有内容也占住宽度**，所以所有卡片纵向严格对齐，不会因为
        // 「有/没有标签」「14h/3天/已过期」而左右错位。

        // ① 标签：定宽 4 字、文字居中；没有标签也画一个透明占位
        Text(this.tagChipList.length > 0 ? this.tagChipList[0] : '')
          .fontSize($r('sys.float.ohos_id_text_size_caption'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .width(TAG_CHIP_WIDTH_VP)
          .backgroundColor(this.tagChipList.length > 0
            ? $r('sys.color.comp_background_secondary')
            : Color.Transparent)
          .borderRadius(TAG_CHIP_RADIUS_VP)
          .padding({ top: TAG_CHIP_VERTICAL_PADDING_VP, bottom: TAG_CHIP_VERTICAL_PADDING_VP })
          .flexShrink(0)

        // ② 重要性标识：**固定槽**（没有也占位）。0 档画透明占位，1/2 档画红圈
        Stack() {
          if (this.showPriorityBadge) {
            this.priorityBadge()
          }
        }
        .width(PRIORITY_BADGE_SIZE_VP)
        .height(PRIORITY_BADGE_SIZE_VP)
        .flexShrink(0)

        // ③④ 截止：**一个定宽描边框**，里面左槽居中放「XXX」、右接固定的「后截止」。
        // 框宽固定（XXX 槽 48vp + 固定文本），所以所有卡片的框右边缘对齐、文字位置也不跳。
        Row({ space: DUE_SUFFIX_GAP_VP }) {
          // ③「XXX」定宽居中（今天 / 明天 / 后天 / 3 天 / 14h / 已过期）
          Text(this.dueParts.value)
            .fontSize($r('sys.float.ohos_id_text_size_caption'))
            .fontColor(this.textColor)
            .maxLines(1)
            .textAlign(TextAlign.Center)
            .width(DUE_VALUE_WIDTH_VP)
            .flexShrink(0)

          // ④「后截止」固定文本；已过期/未定时间时为空，但框仍在（保持对齐）
          Text(this.dueParts.suffix)
            .fontSize($r('sys.float.ohos_id_text_size_caption'))
            .fontColor(this.textColor)
            .maxLines(1)
            .textAlign(TextAlign.Start)
            .flexShrink(0)
        }
        .padding({
          left: DUE_CHIP_SIDE_PADDING_VP,
          right: DUE_CHIP_SIDE_PADDING_VP,
          top: TAG_CHIP_VERTICAL_PADDING_VP,
          bottom: TAG_CHIP_VERTICAL_PADDING_VP
        })
        .border({
          width: DUE_CHIP_BORDER_VP,
          color: $r('sys.color.comp_divider')
        })
        .borderRadius(TAG_CHIP_RADIUS_VP)
        .flexShrink(0)
        // 完全没有截止信息时把框隐藏（但 `Visibility.Hidden` 仍占位，不影响后续槽位对齐）
        .visibility(this.dueParts.value === '' ? Visibility.Hidden : Visibility.Visible)

        // ⑤ 重复性标识：最后一个小图标（没有也占位）
        Stack() {
          if (this.repeatLabel !== '') {
            SymbolGlyph($r('sys.symbol.repeat'))
              .fontSize(REPEAT_ICON_SIZE_VP)
              .fontColor([$r('sys.color.icon_secondary')])
              .accessibilityText(this.repeatLabel)
          }
        }
        .width(REPEAT_ICON_SIZE_VP)
        .height(REPEAT_ICON_SIZE_VP)
        .flexShrink(0)

        // 右侧弹性空白：把剩下的空间都留给铃铛
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
      suffixItem: this.bellButton,
      accessibilityOptions: {
        accessibilityText: this.accessibilityLabel
      }
    })
    // 整卡可点 → 进任务详情（袁正锟 2026-10-16）。前缀圆圈与右侧开关各自有 onClick，
    // 点它们不会冒泡到这里，所以「点圆圈改完成状态」不会误开详情。
    .onClick(() => {
      this.onOpen();
    })
  }
}
