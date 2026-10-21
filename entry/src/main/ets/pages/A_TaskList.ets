import { LengthMetrics } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Task } from '../model';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskSubCard } from '../components/TaskSubCard';
import { TaskStep } from '../model';
import { Theme, ThemeStore } from '../utils/Theme';
import { WindowInsets } from '../utils/WindowInsets';
import { GROUP_HEADER_LIST_PULL_UP_VP, TaskGroupHeader } from '../components/TaskGroupHeader';
import { EmptyHint } from '../components/EmptyHint';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';
import { TaskFilterChips } from '../components/TaskFilterChips';
import { ROUTE_TASK_DETAIL, NAV_STACK_KEY, TaskDetailParam } from '../viewmodel/TaskNavParams';
import { TaskListStore } from '../viewmodel/TaskListStore';

/**
 * 列表底部留白（vp）：让**最后一张卡片能滚到悬浮页签栏上方**，不被它压住。
 * 来历（需求方 2026-10-16：「页面拉到最底部 Tabbar 会挡住任务卡片」）：
 * `MainTabBar` 开了 `barOverlap(true)`，悬浮栏是**叠在内容之上**的，所以列表底部要让开它的高度。
 * 悬浮栏压住的正好是列表的可视区底部 —— 实测（截图量）栏顶在 y=2482、列表内容区底在 y=2734，
 * 即 **256px = 72vp ＝ 栏高 `tab_bar_default_height`(56vp) + 栏底距 `barBottomMargin`(16vp)**；
 * 再加一点呼吸 → 取 **80vp**。之前这里只有 `padding_level4`(8vp)，所以最后一张卡片会被压住。
 */
/**
 * Chip 行悬浮层的高度（vp）：一行 chip（40）+ 上下呼吸。
 * 列表里留出同样高度的空档，第一张卡片才不会钻到 chip 底下。
 */
const CHIPS_BAND_HEIGHT_VP: number = 52;

/**
 * Chip 行从「展开位」滑到「收起位」所对应的**滚动跨度**（vp）＝ 标题栏的高度差。
 *
 * 官方对 FREE 模式的原文（离线文档 `ui-design-hdsnavigation` §`HdsNavigationTitleMode`）：
 * 「FREE：**标题随着内容向上滚动而缩小**……未滚动状态，标题栏高度与 FULL 模式一致；
 *  滚动时，标题栏的最小高度与 MINI 模式一致。」
 * 也就是标题 **112vp → 56vp**，高度差正好 56vp；Chip 行的行程必须与它**逐像素相同**，
 * 两者才可能贴着一块儿走（见 `chipsTopVp`）。
 */
const CHIP_PIN_SPAN_VP: number = MainTitleBar.CONTENT_TOP_OFFSET_VP - MainTitleBar.SUB_PAGE_TITLE_BAR_VP;

const LIST_BOTTOM_CLEARANCE_VP: number = 156;

/**
 * ── Chip 行为沿革（别再退回"阈值 + 延迟 + 独立动画"那一版）──
 *
 * 2026-10-21 第一版：阈值 2vp 判收起 → 延迟 240ms → Chip 自己再动 160ms。
 * 那一版的前提是「HDS 大标题是状态驱动的收起动画、不是连续滚动量」，但**前提是错的**：
 * 官方文档写的是「FREE：标题随着内容向上滚动而缩小」（原文见 `CHIP_PIN_SPAN_VP`），
 * 也就是它跟滚动量走。于是用户看到的就是需求方这次报的现象：
 * 「页面上滑下滑的时候 mainTitle 和 Chips 不是一起运动的，很割裂」——
 * 标题跟着手指走，Chip 行却要等 240ms 才自己飘上去，两个动作各走各的。
 *
 * 现在：**Chip 行直接吃同一个滚动量**（见 `chipsTopVp`），与标题 1:1、逐像素同步，
 * 也不再需要阈值 / 延迟 / 时长这三个魔数。
 */
/**
 * Chip 行底边圆角（vp）—— 实验性（需求方 2026-10-21 第 3 条）：
 * 让"内容被裁切"的那条边看起来是**圆角矩形的下沿**，而不是一条刀切的直线
 *（参照他给的日历 App：内容面板上下沿是圆角）。实色背板给圆角后，卡片从两个底角落里
 * 露一点点出来，观感上就是"内容滑进一个有圆角的容器"，比硬边柔和。
 */
const CHIP_BAND_RADIUS_VP: number = 20;

/**
 * 底部渐变遮罩高度（vp）。
 *
 * 来历：HdsTabs 时代 `barFloatingStyle.gradientMask.maskHeight` 是 140
 *（2026-10-19 需求方：「底部加上一段距离的渐变遮罩」→ 当时从 92 加高到 140）。
 * 弃用 HdsTabs 后这层遮罩跟着没了，于是卡片在视口底边被齐切（2026-10-20 截图下方两个箭头），
 * 现在用自绘渐变恢复它。
 *
 * ⚠️ 取 **100** 而不是当时的 140：旧实现那层遮罩的 `maskColor` 只有 40% 不透明度，而这里是**实色**渐变，
 * 同样 140 会把滑到底的最后一张卡洗白（实测 `m4-list-end.png` 就是被洗白的样子）。
 * 100 刚好罩住胶囊（16~72vp）又不动到最后一张卡；配套把 `LIST_BOTTOM_CLEARANCE_VP` 从 80 提到 96，
 * 保证滚到底时最后一张卡整个落在遮罩之外。
 */
const BOTTOM_MASK_VP: number = 140;

/* ── 副卡片「堆叠」形态（2026-10-19 实验性 UI）── */

/**
 * 收起时露出的下边缘高度（vp）。
 * 按作者给的图：收起态**只保留一条很细的边缘线**，不承载内容 —— 从 12vp 收到 6vp。
 */
const STACK_LAYER_EDGE_VP: number = 6;
/**
 * 副卡片宽度（vp，百分比）：**展开态与收起态用同一个宽度**，按图约为主卡的 92%、居中。
 * 之前展开 100% / 收起 92%，切换时宽度会跳一下。
 */
const STACK_LAYER_WIDTH: string = '92%';
/**
 * 堆叠层与主卡片之间的缝隙（vp）。
 * 图里副卡片是**贴着主卡片下沿**长出来的，所以不再留缝（原来 4vp）。
 */
const STACK_LAYER_OFFSET_VP: number = 0;
/**
 * 主卡片自身的左右留白（vp）。
 * 副卡片必须先缩进同样的距离再取百分比，才是「主卡片的 92%」——
 * 直接写 `92%` 会按整屏宽度算，结果比主卡片还宽（实测 1214px vs 1208px）。
 */
const CARD_SIDE_MARGIN_VP: number = 16;
/** 长按判定时长（毫秒） */
const LONG_PRESS_MS: number = 500;
/** 副卡片展开/收起动画时长（毫秒）：2026-10-19 与作者确认 220ms + EaseOut */
const EXPAND_ANIM_MS: number = 220;
/** 分组展开时卡片淡入的时长（毫秒）：比副卡片略短，避免整组一起动显得拖沓 */
const GROUP_EXPAND_ANIM_MS: number = 180;
/**
 * 副卡片「冒出来」的起始纵向偏移（vp）：取它的高度，正好整个藏进主卡片底下。
 * 必须配 `translate({y})` —— 相对**自身位置**；用 `move(TransitionEdge.TOP)` 是相对
 * **窗口边缘**算的，实测会让卡片从屏幕最顶端飞下来。
 */
/**
 * 副卡片「冒出来」的起始纵向偏移（vp）——**已废弃**，改用容器高度裁切（见下方 `STACK_LAYER_EDGE_VP`）。
 * 保留注释说明为什么不再用平移：位移做不出"卡一直在底下被压着"的图层关系。
 */
const SUB_CARD_EMERGE_VP: number = 36;
/** 副卡片展开后的完整高度（vp）：与 `TaskSubCard` 里的 `SUB_CARD_HEIGHT_VP` 保持一致 */
const SUB_CARD_FULL_HEIGHT_VP: number = 36;
/**
 * 副卡片折叠态的不透明度 —— **已移到 `Theme.OPACITY_CARD_DIM`**。
 *
 * 移走原因：作者 2026-10-19 要求「同时更改 bg 颜色和 opacity」，
 * 底色和透明度是一组参数，应该和 `Theme.CARD_BG_DIM` 放在一起由 `TaskSubCard` 自己用
 * （页面只负责告诉它 `dimmed: true/false`）。
 */
/** 分组展开时每张卡片的起始纵向偏移（vp）：一小段落差即可，同样用 translate */
const CARD_ENTER_OFFSET_VP: number = 16;

@ComponentV2
export struct A_TaskList {
  /**
   * 列表的滚动控制器，**由外层传进来**（`A_Main` 创建 → `MainTabBar` → 这里）。
   * `HdsNavigation.bindToScrollable` 要绑同一个对象，标题栏的滚动联动才成立。
   */
  @Require @Param scroller: Scroller;
  /**
   * 「数据 ＋ 编辑态」store，同样由外层透传：分组数据从这里取（删除会改它），
   * 编辑态再传给每张卡片（圆圈 ↔ 方框勾选框）。
   */
  @Require @Param store: TaskListStore;

  /** 视觉个性化状态：卡片间距按密度档取值（紧凑档更紧） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 列表当前滚动量（vp）—— Chip 行悬浮层的位置就是由它推出来的（见 `chipsTopVp`） */
  @Local scrollVp: number = 0;

  /**
   * 状态栏高度（vp）：窗口全屏后页面铺到屏幕顶端，内容要让开这一截（见 utils/WindowInsets）。
   * 首帧取不到就按 0 处理（下一帧补上，不会跳得很明显）。
   */
  @Local statusBarVp: number = 0;

  aboutToAppear(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    WindowInsets.topPx(context).then((px: number) => {
      this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
    });
  }

  /**
   * Chip 行悬浮层的顶部位置（vp）—— **与标题收缩逐像素联动**。
   *
   * 作者 2026-10-19 的要求：「它应该上滑一段距离直到标题不再移动变化时停在那个位置，
   * 就像和标题的运动绑在一起」。2026-10-21 又要「mainTitle 和 Chips 一起运动，别割裂」。
   *
   * 为什么这样写就一定同步：
   *  · 官方说 FREE 模式的标题「随着内容向上滚动而缩小」，最小高度与 MINI 一致
   *    → 标题位移的跨度就是 `CHIP_PIN_SPAN_VP`（112−56 ＝ 56vp，见常量注释）；
   *  · Chip 行现在吃的是**同一个 `Scroller` 的同一个偏移量**（`scrollVp`），行程也正好是这 56vp；
   *  · 两边跨度和方向完全一致 → 无论 HDS 内部用线性还是缓动，Chip 行都贴着标题一起走，
   *    滚过 56vp 之后两者同时停住（Chip 行钉在 MINI 标题栏下沿），不会再有第二段动画。
   *
   * ⚠️ 不要再退回"到阈值就 animateTo"的写法：那是把一段跟手运动换成了两段独立动画，
   * 只要时长/延迟与 HDS 对不上，就必然出现"标题先没了、Chip 还在飘"的割裂感（本次要修的就是它）。
   */
  @Computed
  get chipsTopVp(): number {
    // 只在 [0, 56] 这一段跟手；继续下滑/回弹都不再移动（`Math.max` 顺带兜住橡皮筋回弹产生的负偏移）
    const progress: number = Math.min(Math.max(this.scrollVp, 0), CHIP_PIN_SPAN_VP);
    return MainTitleBar.CONTENT_TOP_OFFSET_VP - progress + this.statusBarVp;
  }

  /** 底部遮罩的两端色（`GradientDirection.Bottom`：第一项画在**上**边，所以上透下实） */
  @Computed
  get bottomMaskColors(): Array<[ResourceColor, number]> {
    const surface: string = this.themeStore.scheme.surface;
    // ⚠️ 不要退回「两档线性 alpha」（`[00, 0.0], [FF, 1.0]`）：8bit 线性 alpha 在深色内容上
    // 感知是"到最底下才突然变实"，需求方 2026-10-21 的原话是「淡出得太晚，内容到胶囊才淡」。
    // 这里给 6 档、把中段 alpha 抬快，淡出在胶囊上方就很明显了。
    const colors: Array<[ResourceColor, number]> = [
      // 关键：**胶囊上沿**约在遮罩高度的 0.49 处，那里必须有 ~55% 遮挡，否则可见区域（胶囊上方）
      // 全是 0~20% 的"看不见的渐变"，观感就是"到胶囊才淡"（需求方 2026-10-21 第 D 条）。
      // 括号里是 alpha 百分比：0x40=25%、0x8C=55%、0xCC=80%、0xEE=93%
      [Theme.withAlpha(surface, '00'), 0.0],
      [Theme.withAlpha(surface, '40'), 0.25],
      [Theme.withAlpha(surface, '8C'), 0.49],
      [Theme.withAlpha(surface, 'CC'), 0.70],
      [Theme.withAlpha(surface, 'EE'), 0.85],
      [Theme.withAlpha(surface, 'FF'), 1.0]
    ];
    return colors;
  }

  /**
   * 哪些任务的副卡片被**长按展开**了（存 task.id）。
   *
   * 放在页面这一层而不是 `TaskSubCard` 里：收起态根本不会创建副卡片组件
   * （只画一条露出的下边缘），状态必须活在它外面。
   */
  @Local expandedStepIds: number[] = [];

  /** 该任务有没有步骤（决定要不要画堆叠层） */
  private hasSteps(task: Task): boolean {
    const steps: TaskStep[] | undefined = task.steps;
    return steps !== undefined && steps.length > 0;
  }

  private isStepsExpanded(taskId: number): boolean {
    return this.expandedStepIds.indexOf(taskId) >= 0;
  }

  /**
   * 长按：展开/收起该任务的副卡片。
   *
   * 状态变更包在 `animateTo` 里（2026-10-19 作者要求「给展开、收起加上 animation」）：
   * V2 下的正确写法是 `this.getUIContext().animateTo({...}, () => { 改状态 })`
   * —— 直接调全局 `animateTo` 在 V2 里不保证生效（官方《AnimateTo使用迁移》有说明）。
   * 副卡片本身的进出场由 `TaskSubCard` 上的 `transition` 负责。
   */
  private toggleSteps(taskId: number): void {
    this.getUIContext().animateTo({
      duration: EXPAND_ANIM_MS,
      // 与副卡内部 `.animation()` 用同一条曲线，展开/收起手感一致
      curve: Curve.FastOutSlowIn
    }, () => {
      const next: number[] = this.expandedStepIds.slice();
      const index: number = next.indexOf(taskId);
      if (index >= 0) {
        next.splice(index, 1);
      } else {
        next.push(taskId);
      }
      this.expandedStepIds = next;
    });
  }

  // 说明：点圆圈（完成/退回）与拨「响铃提醒」开关这两个动作**已搬到 `TaskListStore`**
  // （`toggleComplete` / `setRemind`）—— 搜索页复用同一个 `TaskCard`，行为也必须是同一套。

  /**
   * 分组头。
   *
   * 外面套一层 `Column` 是为了加**分组头与卡片之间的间隔**：`ListItemGroup` 的 `space`/`spaceWidth`
   * 只管「列表项之间」，不含分组头，官方没给「头与首项之间」的选项。
   * `SubHeader` 自己不能设通用属性（官方文档明说会多生成 `__Common__` 节点，属性可能不生效），
   * 所以间隔只能加在外层的这层壳上。
   */
  @Builder
  groupHeader(group: TaskDayGroup) {
    Column() {
      TaskGroupHeader({
        group: group,
        // 计数按**当前筛选下可见的任务**算，跟列表里真正显示的内容一致
        pendingCount: this.store.visiblePendingCount(group),
        totalCount: this.store.visibleTasks(group).length,
        onToggle: () => {
          // 2026-10-19 第七次：分组**收起**之前是"啪"地消失（只有展开有动画）。
          // 包进 `animateTo` 后，组内卡片被移除时也会走 ListItem 上挂的 `transition`
          // 反向播放（淡出 + 上移），展开/收起两个方向就都有动效了。
          // 2026-10-20：改成走 store 的唯一入口 —— 它除了改状态还会**记住**这次选择
          // （需求方：「记住上次的展开状态」），直接写 `group.expanded` 的话重启就忘了。
          this.getUIContext().animateTo({
            duration: GROUP_EXPAND_ANIM_MS,
            curve: Curve.FastOutSlowIn
          }, () => {
            this.store.setGroupExpanded(group, !group.expanded);
          });
        }
      })
    }
    .width('100%')
    // ⚠️ 这里**刻意不再加下留白**（原来加的是 `padding_level8` = 16vp）。
    // 实测（把五个分组全部展开后逐像素量，`.cache/all1-padding.txt` + `.cache/all1-report.txt`）：
    //   卡片 ↔ 卡片（同组内）= **8.2vp**；组头副标题 → 本组第一张卡片 = **23.6vp**（＝ SubHeader 自带的 ~7.9vp 下留白 ＋ 我们这层 16vp）；
    //   上组最后一张卡片 → 组头顶标题 = **14.6vp**。
    // 也就是组头离**上面那组**比离**自己这组**还近 → 需求方 2026-10-16 说的「ListHeader 和下方卡片之间的间距是不是太大了…整体展开后协调嘛」。
    // 去掉这层下留白后，组头→本组卡片 ≈ SubHeader 自带的 ~8vp ≈ 卡片↔卡片的 8.2vp，
    // 而组与组之间仍是 14.6vp → **组头明确归属下面那一组**，节奏是 8 / 8 / 14.6。
    //
    // 需求方 2026-10-16 追加：「第一个 ListGroup 和 ChipGroup 的间距过大了」→ 上留白回收**对所有组生效**。
    // 原先第一组刻意不回收（那时它上面是标题栏让位区，属于「区块起点」）；现在页面最顶上是 Chip 行，
    // 第一组头也该贴着它 → 与组间间距同为 ~14.5vp。
    .margin({ top: -GROUP_HEADER_LIST_PULL_UP_VP })
  }

  /**
   * 一条都不可见（比如全选删光，或者筛选后没有匹配）—— 走空状态。
   * 判据取「当前筛选下可见的任务数」，所以删空和筛空都能落到这里。
   */
  @Computed
  get isEmpty(): boolean {
    return this.store.visibleCount === 0;
  }

  /**
   * 空状态（需求方 2026-10-16：「没有一项任务的时候 背景做一个官方那样的风格 一个图片表示无任务
   * 下面写无任务 都是比背景要深的灰色」）。
   *
   * · 图示用**官方 Symbol**（`inbox`）放大到 96vp —— 官方没有随 SDK 发"空状态插图"这种位图资源
   *   （`sys.media` 里没有 empty 类图），Symbol 是唯一能做到"官方风格"的图示；
   * · 颜色两处都取**比页面背景（`#f1f3f5`）更深的官方灰**：图示 `gray_03`(`#d1d1d6`)，
   *   文字 `ohos_id_color_text_tertiary`(`#66182431`)；
   * · ⚠️ **顶部 Chip 行必须一起保留**：筛选到一个都没有时如果把 Chip 行也藏了，用户就**回不到「全部」**了
   *   （实测踩到过：筛「已完成」再删掉那条 → Chip 行消失 → 卡在空筛选里）。
   *   所以这里自己拼「标题栏让位 + Chip 行 + 余下空间居中」，而不是整个列表都不渲染。
   */
  @Builder
  emptyState() {
    Column() {
      // 顶部让开标题栏（与列表首项同一段留白，保持一致）
      Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP + this.statusBarVp)

      // 顶部筛选 Chip 行（空态下也要在，否则回不去「全部」）
      TaskFilterChips({ store: this.store })

      // 图示 + 文案用**两个页面共用的** `EmptyHint` 组件（搜索页的两种空态也是它）
      EmptyHint({
        message: this.store.filteredEmpty
          ? $r('app.string.empty_filtered_task_list')
          : $r('app.string.empty_task_list')
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  taskList() {
    List({ scroller: this.scroller }) {
      // 顶部让开标题栏的这一段，**必须做成列表里的第一项**，不能用 `contentStartOffset`：
      // `contentStartOffset` 会把内容整体下移，`HdsNavigation` 按滚动偏移算「标题收缩进度」时起点被推后 →
      // 标题栏会一直保持展开，直到内容整整滚过标题栏高度才「啪」地收起来（实测：内容滚了 119vp 时标题仍是 112vp，
      // 再滚一点才变成 56vp），也就是需求方 2026-10-16 说的「mainTitle 向左上角移动的动画明显慢于页面上滑」。
      // 改成列表首项留白（＝官方示例 `Scroll { Column { Blank(标题栏高度) ... } }` 的写法）后，滚动偏移从第一像素
      // 就开始参与收缩计算 → 标题跟手。（`.cache/nb-report.txt` / `.cache/fn-report.txt` 是改前的量测记录。）
      ListItem() {
        // `Blank` 只能放进 Row/Column/Flex，所以这里用一行空 `Row` 撑出这段高度。
        // 无障碍不上报这个空项（否则读屏会播报一个空列表项）
        Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP + this.statusBarVp)
      }
      .accessibilityLevel('no')

      // 2026-10-19：Chip 行**不再作为普通列表项**（那样会随页面滑出屏幕）。
      // 改成 `build()` 里的**悬浮冻结层**，跟着标题一起上滑、标题收起后停住。
      // 这里只留出与它等高的空档，让第一张卡片从 Chip 行下方开始、不会钻到它底下。
      ListItem() {
        Row().width('100%').height(CHIPS_BAND_HEIGHT_VP)
      }
      .accessibilityLevel('no')

      ForEach(this.store.groups, (group: TaskDayGroup) => {
        // 当前筛选下这一组一条都没有 → 整组不渲染（组头也不出现）
        if (this.store.visibleTasks(group).length > 0) {
          ListItemGroup({
            header: this.groupHeader(group)
          }) {
            if (group.expanded) {
              ForEach(this.store.visibleTasks(group), (task: Task) => {
                ListItem() {
                  // 主卡片 + （有步骤时）副卡片的**堆叠形态**（2026-10-19 实验性 UI）：
                  //   · 收起态：主卡片下方只**露出小副卡片的下边缘**（一条略窄的圆角条），
                  //     让"这张卡底下还有东西"一眼可见，又不多占高度；
                  //   · 长按主卡片：把整张副卡片展开，列出步骤（每步可点圆圈勾选）。
                  // 展开状态放在页面这一层（`expandedStepIds`），因为副卡片自己已经不带开关了。
                  Column({ space: 0 }) {
                    Column() {
                      TaskCard({
                        task: task,
                        store: this.store,
                        onToggleComplete: () => {
                          this.store.toggleComplete(task);
                        },
                        onRemindChange: (isOn: boolean) => {
                          this.store.setRemind(task, isOn);
                        },
                        // 点整卡 → 压入任务详情页（编辑态下不跳，避免和多选冲突）
                        onOpen: () => {
                          if (this.store.editing) {
                            return;
                          }
                          AppStorage.get<NavPathStack>(NAV_STACK_KEY)
                            ?.pushPathByName(ROUTE_TASK_DETAIL, new TaskDetailParam(task, this.store));
                        }
                      })
                    }
                    .width('100%')
                    // 有步骤且处于收起态时，长按展开；再长按收起。
                    // 编辑态不响应（长按在多选模式下容易误触）
                    .gesture(
                      LongPressGesture({ repeat: false, duration: LONG_PRESS_MS })
                        .onAction(() => {
                          if (this.store.editing || !this.hasSteps(task)) {
                            return;
                          }
                          this.toggleSteps(task.id);
                        })
                    )

                    if (this.hasSteps(task)) {
                      // 副卡片：**始终是同一张卡**（作者：「半展开的和真正的其实是两个东西」）。
                      //
                      // 2026-10-19 第七次修正：上一版只让**容器高度**变，副卡自己贴底不动，
                      // 观感是"被裁短了"而不是"滑出来"（作者：「副卡的位置不带动的」）。
                      // 现在让**两个量同时动**：
                      //   · 外层容器高度：6vp ↔ 36vp（裁切窗口）
                      //   · 副卡 translateY：-(36-6) ↔ 0（它自己从主卡底下往上顶 / 往下沉）
                      // 两者同步 → 副卡的**位置真的在动**，从主卡底下滑出来。
                      // 阴影按作者反馈已去掉（「莫名其妙地边框阴影」）。
                      //
                      // ⚠️ 宽度：百分比相对**父容器**（整屏 1320px）算，直接写 92% 会比主卡还宽
                      //   （实测 1214px vs 1208px）。所以先左右各缩进 16vp（与主卡留白一致）再取 92%。
                      Column() {
                        Column() {
                          TaskSubCard({
                            task: task,
                            // 折叠时告诉副卡"你在主卡底下" → 它自己换暗底色 + 降透明度
                            //（作者 2026-10-19：「同时更改 bg 颜色和 opacity」）
                            dimmed: !this.isStepsExpanded(task.id),
                            onToggleStep: (index: number) => {
                              this.store.toggleStepDone(task, index);
                            }
                          })
                        }
                        .width(STACK_LAYER_WIDTH)
                        // 收起时把副卡整体上推 (36-6)=30vp，只留最下面一条在裁切窗口里
                        .translate({
                          y: this.isStepsExpanded(task.id)
                            ? 0
                            : -(SUB_CARD_FULL_HEIGHT_VP - STACK_LAYER_EDGE_VP)
                        })
                        .animation({ duration: EXPAND_ANIM_MS, curve: Curve.FastOutSlowIn })
                      }
                      .width('100%')
                      .padding({ left: CARD_SIDE_MARGIN_VP, right: CARD_SIDE_MARGIN_VP })
                      .height(this.isStepsExpanded(task.id) ? SUB_CARD_FULL_HEIGHT_VP : STACK_LAYER_EDGE_VP)
                      .clip(true)
                      .alignItems(HorizontalAlign.Center)
                      .animation({ duration: EXPAND_ANIM_MS, curve: Curve.FastOutSlowIn })
                      .accessibilityText($r('app.string.subcard_stacked_hint'))
                    }
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Center)
                  // 卡片之间的间距（2026-10-19 第五次调整）。
                  // ⚠️ `ListItemGroup.spaceWidth` 在本项目里**实测不生效**（`Resource` / 裸数字 /
                  //    `'12vp'` 三种写法都试过，两卡始终紧贴、间距 0px），所以改成给每项加下外边距。
                  .margin({ bottom: this.themeStore.listItemSpace })
                  // 分组展开/收起时，这一组里的**每张卡片**也做淡入（2026-10-19 第五次：
                  // 「为所有任务卡片展开时增加展开项的动画」）——
                  // `transition` 在 ListItem 内容被创建/销毁时自动播放，组收起来就是反向。
                  // ⚠️ 同样不能用 `move(TransitionEdge.TOP)`：那是相对**窗口边缘**的，
                  //    实测所有卡片从**屏幕最顶端**飞下来。这里用 `translate({y})` 只下移一小段。
                  .transition(
                    TransitionEffect.OPACITY
                      .combine(TransitionEffect.translate({ y: -CARD_ENTER_OFFSET_VP }))
                      .animation({ duration: GROUP_EXPAND_ANIM_MS, curve: Curve.FastOutSlowIn })
                  )
                }
              }, (task: Task) => `${task.id}`)
            }
          }
        }
      }, (group: TaskDayGroup) => `${group.sortValue}-${group.hasDate}`)
    }
    .width('100%')
    .height('100%')
    // 任务列表**不显示滚动条**（2026-10-19 定）。不设的话系统给默认滚动条，
    // 在悬浮页签栏旁边会多出一条竖线。
    .scrollBar(BarState.Off)
    // 让开悬浮页签栏的高度，否则最后一张卡片会被栏压住（见 LIST_BOTTOM_CLEARANCE_VP 的来历）
    .contentEndOffset(LIST_BOTTOM_CLEARANCE_VP)
    // 把滚动位置喂给 Chip 悬浮层：**每帧都赋值**，位置由 `chipsTopVp` 线性推出。
    // 这里不要再做"到阈值才改状态 + animateTo"的分支 —— 那会把一段跟手运动拆成两段独立动画，
    // 与 HDS 标题的节奏对不上就是"标题和 Chips 各走各的"（见 `chipsTopVp` 的说明）。
    .onDidScroll(() => {
      // 用 `UIContext.px2vp`，不用全局 `px2vp`（后者已标记废弃）
      this.scrollVp = this.getUIContext().px2vp(this.scroller.currentOffset().yOffset);
    })
  }

  build() {
    // 有任务＝列表；一条都没有＝官方风格的空状态（两者都是内容区的根，外面套 Stack 保证根节点是容器）
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isEmpty) {
        this.emptyState()
      } else {
        this.taskList()
      }

      if (!this.isEmpty) {
        // **底部渐变遮罩**（2026-10-20 恢复）：内容滑到胶囊/＋ 那一带时淡出，而不是在视口底边被齐切。
        // 结构与下面那层一样：外层铺满、内容靠底，`HitTestMode.None` 让滚动/点击穿透给下面的列表。
        Column() {
          Column()
            .width('100%')
            .height(BOTTOM_MASK_VP)
            .linearGradient({
              // Bottom = 从上向下：上面全透明 -> 底部实色页面（方向别写反，见 bottomMaskColors 的说明）
              direction: GradientDirection.Bottom,
              colors: this.bottomMaskColors
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .hitTestBehavior(HitTestMode.None)
      }

      // **Chip 行悬浮冻结层**（2026-10-19，作者要求；2026-10-21 第三轮改成**跟手连续**，见 `chipsTopVp`）：
      // 未滚动时贴在展开的标题栏下方；上滑时**按滚动量 1:1** 与标题一起上移；
      // 滚过 56vp（正好是标题 112→56 的高度差）后钉在 MINI 标题栏下沿不再动。
      // 底色用页面 `surface`，把从下面滚过的卡片挡住。
      //
      // ⚠️ 2026-10-20 取消全屏沉浸后，这一层的底色**从屏幕顶端（0）开始铺**，不再从标题栏收起线开始：
      // 官方 `HdsNavigation` 的标题栏背板在非沉浸布局下实测**只出模糊、不填色**（换
      // `GRADIENT_BLUR` / 关掉 `systemMaterialEffect` 都一样），于是大标题后面会透出滚动内容的
      // 「幽灵文字」，再往下又被这一层的实色边缘齐刷刷切断。
      // 把底色一路铺到顶端后：标题区与 Chip 行是同一块不透明底色，滚动内容只会被整体挡住。
      // 标题、右上角按钮由 `HdsNavigation` 画在这一层**上面**，不受影响。
      //
      // 2026-10-21 第 3 条（实验性）：把实色背板的**下沿做成圆角**。
      // 上一步（2026-10-20）这里接的是一条 20vp 的渐隐尾巴；需求方这次要的是
      // 「上下裁切的边缘是圆角矩形」——于是改成给背板 `borderRadius({bottomLeft, bottomRight})`：
      // 圆角之外的两个角会露出下面滑过的卡片，视觉上就是"内容正滑进一个带圆角的容器"，
      // 比渐隐更利落。底部那条边缘按他给的兜底方案仍用渐变遮罩（见上面那段）。
      if (!this.isEmpty) {
        Column() {
          TaskFilterChips({ store: this.store })
        }
        .width('100%')
        .padding({ top: this.chipsTopVp })
        .backgroundColor(this.themeStore.scheme.surface)
        .borderRadius({
          bottomLeft: CHIP_BAND_RADIUS_VP,
          bottomRight: CHIP_BAND_RADIUS_VP
        })
      }
    }
    .width('100%')
    .height('100%')
    // M3（2026-10-19）：内容区底色 = `surface`。
    // 设在 `A_Main` 的 HdsNavigation 上会被 HDS 自己的背景盖住（实测页面仍是冷灰），
    // 所以必须落在**真正铺满视口的这一层**上，卡片才能和它形成「深一档」的层次。
    .backgroundColor(this.themeStore.scheme.surface)
  }
}



