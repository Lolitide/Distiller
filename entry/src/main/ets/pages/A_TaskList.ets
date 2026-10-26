import { LengthMetrics, SubHeader } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Task, TaskPriority, TaskStatus } from '../model';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskSubCard } from '../components/TaskSubCard';
import { TaskStep } from '../model';
import { Theme, ThemeStore } from '../utils/Theme';
import { WindowInsets } from '../utils/WindowInsets';
import { GROUP_HEADER_LIST_PULL_UP_VP, TaskGroupHeader } from '../components/TaskGroupHeader';
import { EmptyHint } from '../components/EmptyHint';
import { TaskDayGroup, TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { TaskFilterChips } from '../components/TaskFilterChips';
import { ROUTE_TASK_DETAIL, NAV_STACK_KEY, TaskDetailParam } from '../viewmodel/TaskNavParams';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { SyncService } from '../service/cloud/SyncService';
import {
  SyncStatus,
  SYNC_PHASE_SYNCING,
  SYNC_PHASE_OFFLINE,
  SYNC_PHASE_DISABLED
} from '../service/cloud/SyncStatus';

/**
 * 列表底部留白（vp）：让**最后一张卡片能滚到悬浮页签栏上方**，不被它压住。
 * 来历（需求方 2026-10-16：「页面拉到最底部 Tabbar 会挡住任务卡片」）：
 * `MainTabBar` 开了 `barOverlap(true)`，悬浮栏是**叠在内容之上**的，所以列表底部要让开它的高度。
 * 悬浮栏压住的正好是列表的可视区底部 —— 实测（截图量）栏顶在 y=2482、列表内容区底在 y=2734，
 * 即 **256px = 72vp ＝ 栏高 `tab_bar_default_height`(56vp) + 栏底距 `barBottomMargin`(16vp)**；
 * 再加一点呼吸 → 取 **80vp**。之前这里只有 `padding_level4`(8vp)，所以最后一张卡片会被压住。
 */
/**
 * Chip 行悬浮层**实际占的高度**（vp）—— 列表里要留出同样高的空档，第一张卡片才不会钻到 Chip 底下。
 *
 * 2026-10-21 修正（需求方：「第一个 listGroup 和 ChipsGroup 之间的间隔有点大，调小一些」）：
 * 原来写的是 **52**（注释记作「一行 chip 40 + 上下呼吸」），但官方 `ChipGroup` 的真实高度没有 40 ——
 * 布局探针实测（模拟器，密度 3.5）：
 *   · `chipGroupPadding.top` 8vp → Chip 行 158.9~186.9（**28vp**）→ `chipGroupPadding.bottom` 1vp；
 *   · 合计 **37vp**，比 52 少了 15vp → 这 15vp 就变成"Chip 背板下面的一段死空档"，
 *     观感正是"第一个分组离 Chips 太远"。
 * 现在取 **38**（实测 37 向上取整 1vp 兜底，避免组头被背板圆角下沿压住）。
 * ⚠️ 改这个值会同时改变「Chips ↔ 第一个分组」的间隔，且必须与下面的 `CHIPS_BAND_BOTTOM_GAP_VP` 一起看：
 *    列表首项让位 = 本值 + 底边距，两者之和就是背板下沿的位置。
 */
const CHIPS_BAND_HEIGHT_VP: number = 38;

/**
 * Chip 行**下方**的留白（vp）—— 2026-10-21 需求方：「给任务列表页的 Chips 组加上底边距吧」。
 *
 * 加在冻结层的 `padding.bottom` 上，**不是**给 Chip 组件自己加外边距：这块留白必须与上面同色，
 * 卡片才算"从 Chip 组下方开始"；否则卡片会紧贴 Chip 的胶囊边，甚至从 Chip 底下钻出来。
 *
 * 取值官方 `padding_level4` = 8vp（Chip 行自身还有 1vp 的 `chipGroupPadding.bottom`，视觉合计约 9vp）。
 * ⚠️ 它同时要加进列表首项的让位高度（`CHIPS_BAND_HEIGHT_VP + 本值`），两处必须一起改，
 * 否则空档对不上：留少了第一张卡片会被背板压住，留多了会多出一条空隙。
 */
const CHIPS_BAND_BOTTOM_GAP_VP: number = 8;

/*
 * ── 2026-10-25：Chip 行**回归静态**，不再跟标题栏联动 ──
 *
 * 需求方：「把任务列表的导航栏也改成设置页那样 mainTitle 固定的吧 不需要动画 老有问题」。
 * 主页标题栏因此从 `FREE`（大标题，随内容上滚缩到 56vp）改成 **`MINI`（固定 56vp）**，
 * 于是原来那套「Chip 行吃滚动量、与标题 1:1 同步上移、滚过 56vp 钉住」的机制**整体作废**：
 *   · 标题不动了，Chip 行也就没有"要跟的对象"；
 *   · 之前反复出问题（标题与 Chips 割裂 / 各走各的）的根源就是**两个独立的运动要像素级对齐**，
 *     现在把其中一个运动去掉，这类 bug 从结构上消失，而不是再调一次阈值/延迟。
 *
 * 所以下面三处一并删掉了：`CHIP_PIN_SPAN_VP`（行程 56vp）、`scrollVp`（每帧滚动量）、
 * `List.onDidScroll`（把滚动量喂给 Chip 层）。`chipsTopVp` 现在是一个**常量位置**。
 */

const LIST_BOTTOM_CLEARANCE_VP: number = 156;

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
   * 页面自己要用它（列表 `List` 绑定 + 需要时读 `currentOffset()`）；2026-10-25 标题栏改成
   * 固定 MINI 后，它**不再**交给 `HdsNavigation.bindToScrollable` 做标题联动。
   */
  @Require @Param scroller: Scroller;
  /**
   * 「数据 ＋ 编辑态」store，同样由外层透传：分组数据从这里取（删除会改它），
   * 编辑态再传给每张卡片（圆圈 ↔ 方框勾选框）。
   */
  @Require @Param store: TaskListStore;
  /** 同步状态细条：离线/重试中/同步中 */
  private syncStatus: SyncStatus = SyncStatus.instance();

  /** 视觉个性化状态：卡片间距按密度档取值（紧凑档更紧） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

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
   * Chip 行悬浮层的顶部位置（vp）—— **固定值**，贴在 MINI 标题栏下沿。
   *
   * 2026-10-25 之前这里是 `112 - 滚动量 + 状态栏`：标题栏是 FREE（大标题会缩），Chip 行要跟它
   * 1:1 同速上移，滚过 56vp 再钉住 —— 两段运动要对齐，反复出现「标题和 Chips 各走各的」。
   * 现在标题栏改成 MINI（固定 56vp），没有要跟的对象了，这里退化成纯常量：
   * **标题栏高度 + 状态栏高度**，取不到状态栏时按 0（下一帧补上）。
   */
  @Computed
  get chipsTopVp(): number {
    return MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp;
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
  /** 待确认消息卡是否展开 */
  @Local pendingExpanded: boolean = true;

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
  /** 一键加入演示任务：4 种 tag（通知 ×2 / 作业 / 考试 / 活动），创建时间与 ddl 都错开 */
  private addSampleTasks(): void {
    const now: number = Date.now();
    const hour: number = 3600000;
    const list: Task[] = [];
    list.push(this.makeSampleTask('sample-notice-library', '图书馆临时闭馆通知',
      '因设备检修，今晚 18:00 后闭馆，请提前借还书', '通知', '通知',
      now - 19 * hour, now + 3 * hour));
    list.push(this.makeSampleTask('sample-notice-course', '选课系统维护通知',
      '选课系统本周六 00:00-06:00 维护，期间无法选课', '通知', '通知',
      now - 15 * hour, now + 26 * hour));
    list.push(this.makeSampleTask('sample-homework-practice', '提交社会实践材料',
      '把实践报告和照片打包交给辅导员', '作业', '作业',
      now - 11 * hour, now + 50 * hour));
    list.push(this.makeSampleTask('sample-exam-math', '复习高等数学',
      '重点看极限、导数和积分应用，做两套真题', '考试', '考试',
      now - 7 * hour, now + 74 * hour));
    list.push(this.makeSampleTask('sample-activity-club', '社团招新摆摊',
      '下午三点到东广场集合，带好宣传物料', '活动', '活动',
      now - 3 * hour, now + 98 * hour));
    this.store.upsertAll(list);
  }

  private makeSampleTask(key: string, name: string, note: string, tag: string, category: string,
    createdAt: number, dueAt: number): Task {
    const task: Task = new Task();
    task.clientTaskId = key;
    task.name = name;
    task.note = note;
    task.category = category;
    task.tags = [tag];
    task.status = TaskStatus.CONFIRMED;
    task.priority = TaskPriority.NORMAL;
    task.createdAt = createdAt;
    task.dueAt = dueAt;
    task.dueText = this.sampleDueText(dueAt);
    return task;
  }

  private sampleDueText(ms: number): string {
    const d: Date = new Date(ms);
    const hh: string = d.getHours() < 10 ? `0${d.getHours()}` : `${d.getHours()}`;
    const mm: string = d.getMinutes() < 10 ? `0${d.getMinutes()}` : `${d.getMinutes()}`;
    return `${d.getMonth() + 1}月${d.getDate()}日 ${hh}:${mm}`;
  }

  @Builder
  emptyState() {
    Column() {
      // 顶部让开标题栏（与列表首项同一段留白，保持一致）
      Row().width('100%').height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)

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

  /** 待确认消息组头：与「今天/明天」同一个 SubHeader，展开/收起同一条动画 */
  @Builder
  pendingHeader() {
    Row({ space: 8 }) {
      Column() {
        SubHeader({
          primaryTitle: '待确认消息',
          secondaryTitle: this.store.pendingList.length + ' 条待确认'
        })
      }
      .layoutWeight(1)

      // 「数字 + 红点」放在展开箭头左边
      if (this.store.pendingUnseenCount() > 0) {
        Row({ space: 4 }) {
          Column()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor(this.themeStore.scheme.error)
          Text(String(this.store.pendingUnseenCount()))
            .fontSize(12)
            .fontColor(this.themeStore.scheme.error)
        }
      }

      SymbolGlyph(this.pendingExpanded ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
        .fontSize($r('sys.float.subheader_right_icon_size'))
        .fontColor([$r('sys.color.icon_primary')])
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ end: LengthMetrics.resource($r('sys.float.padding_level8')) })
    .onClick(() => {
      this.getUIContext().animateTo({
        duration: GROUP_EXPAND_ANIM_MS,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.pendingExpanded = !this.pendingExpanded;
      });
    })
  }

  /** 待确认子卡片：直接复用普通任务卡容器，只换前缀/右侧图标与第二行文案 */
  @Builder
  pendingCard(task: Task) {
    TaskCard({
      task: task,
      store: this.store,
      pendingMode: true,
      onOpen: () => {
        this.store.markPendingSeen(task);
        AppStorage.get<NavPathStack>(NAV_STACK_KEY)
          ?.pushPathByName(ROUTE_TASK_DETAIL, new TaskDetailParam(task, this.store, true));
      }
    })
  }

  /** 同步状态细条（离线 / 同步中 / 已关闭），离线可点重试 */
  @Builder
  syncBanner() {
    Row({ space: 8 }) {
      Text(this.syncStatus.phase === SYNC_PHASE_SYNCING
        ? '正在同步…'
        : (this.syncStatus.phase === SYNC_PHASE_DISABLED
          ? '云端同步已关闭，可在设置里开启'
          : '离线，数据可能不是最新'))
        .fontSize(12)
        .fontColor(this.syncStatus.phase === SYNC_PHASE_OFFLINE
          ? this.themeStore.scheme.error
          : this.themeStore.scheme.onSurfaceVariant)
        .maxLines(1)
        .layoutWeight(1)
      if (this.syncStatus.phase === SYNC_PHASE_OFFLINE) {
        Text('重试')
          .fontSize(12)
          .fontColor(this.themeStore.scheme.primary)
          .onClick(() => {
            SyncService.syncOnce(true);
          })
      }
    }
    .width('100%')
    .height(36)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.syncStatus.phase === SYNC_PHASE_OFFLINE
      ? this.themeStore.scheme.errorContainer
      : this.themeStore.scheme.surfaceContainerHigh)
    .borderRadius(10)
  }

  @Builder
  taskList() {
    List({ scroller: this.scroller }) {
      // 顶部让开**固定标题栏**的这一段（MINI = 56vp + 状态栏）。做成列表里的第一项而不是
      // `contentStartOffset`：留白做成项，滚动内容就从这里往下排，不需要再跟导航组件做什么联动
      //（2026-10-25 标题栏改 MINI 后，原来那段「必须做成首项，否则 HDS 收缩进度算不准」的理由已不存在，
      //  但**首项留白**这个写法本身仍是官方示例的口径，保留不动、也不引入新风险）。
      ListItem() {
        // `Blank` 只能放进 Row/Column/Flex，所以这里用一行空 `Row` 撑出这段高度。
        // 无障碍不上报这个空项（否则读屏会播报一个空列表项）
        Row().width('100%').height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + this.statusBarVp)
      }
      .accessibilityLevel('no')

      // Chip 行**不是列表项**（那样会随页面滑出屏幕），它是 `build()` 里的**悬浮冻结层**，
      // 位置固定在标题栏下沿（见 `chipsTopVp`）。
      // 这里留出「Chip 行等高 + 它下方的 `CHIPS_BAND_BOTTOM_GAP_VP`」的空档，
      // 让第一张卡片正好从背板下沿之下开始（少留＝被背板压住，多留＝多一条缝）。
      ListItem() {
        Row().width('100%').height(CHIPS_BAND_HEIGHT_VP + CHIPS_BAND_BOTTOM_GAP_VP)
      }
      .accessibilityLevel('no')

      if (this.store.pendingList.length > 0) {
        ListItemGroup({
          header: this.pendingHeader()
        }) {
          if (this.pendingExpanded) {
            ForEach(this.store.pendingTasks(), (task: Task) => {
              ListItem() {
                Column() {
                  this.pendingCard(task)
                }
                .width('100%')
              }
              .width('100%')
              // 与普通任务卡一致的卡片间距（左右由 HDS 卡片自身留白，不重复加）
              .margin({ bottom: this.themeStore.listItemSpace })
              // 展开/收起时与普通分组同一套淡入 + 下移
              .transition(
                TransitionEffect.OPACITY
                  .combine(TransitionEffect.translate({ y: -CARD_ENTER_OFFSET_VP }))
                  .animation({ duration: GROUP_EXPAND_ANIM_MS, curve: Curve.FastOutSlowIn })
              )
            }, (task: Task) => 'pending-' + task.id)
          }
        }
        .margin({ top: -GROUP_HEADER_LIST_PULL_UP_VP })
      }

      if (this.syncStatus.showsBanner) {
        ListItem() {
          Row() {
            this.syncBanner()
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 6 })
        }
      }

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
    // 2026-10-25：这里原来有个 `.onDidScroll(...)`，把每帧滚动量写进 `scrollVp` 供 Chip 层跟着标题上移。
    // 标题栏改成固定 MINI 之后不再需要 —— 删掉顺带省掉每帧一次 `@Local` 写入引起的重算。
  }

  build() {
    // 有任务＝列表；一条都没有＝官方风格的空状态（两者都是内容区的根，外面套 Stack 保证根节点是容器）
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isEmpty && this.store.pendingList.length === 0) {
        this.emptyState()
      } else {
        this.taskList()
      }

      if (!this.isEmpty || this.store.pendingList.length > 0) {
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

      // **Chip 行悬浮冻结层**（2026-10-19 起）：现在**位置固定**，贴在 MINI 标题栏下沿
      //（2026-10-25 标题栏改固定小标题后，它不再跟滚动量走，见 `chipsTopVp`）。
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
      if (!this.isEmpty || this.store.pendingList.length > 0) {
        Column() {
          TaskFilterChips({ store: this.store })
        }
        .width('100%')
        // 底边距加在**背板自己的 padding** 上：这块留白与背板同色，卡片从它下沿滚进去
        //（见 `CHIPS_BAND_BOTTOM_GAP_VP`；列表首项的让位高度要同步加上这个值）
        .padding({ top: this.chipsTopVp, bottom: CHIPS_BAND_BOTTOM_GAP_VP })
        .backgroundColor(this.themeStore.scheme.surface)
        .borderRadius({
          bottomLeft: CHIP_BAND_RADIUS_VP,
          bottomRight: CHIP_BAND_RADIUS_VP
        })
      }

      // 样例入口：右下角小胶囊，一键塞演示任务（4 种 tag、创建时间与 ddl 都错开）。
      // 反复点击按 `clientTaskId` 幂等合并，不会堆出重复卡片。
      Column() {
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text('样例')
            .fontSize(12)
            .fontColor(this.themeStore.scheme.onSecondaryContainer)
        }
        .height(28)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.themeStore.scheme.secondaryContainer)
        .id('sampleTasksButton')
        .onClick(() => {
          this.addSampleTasks();
        })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.End)
      .padding({ right: 20, bottom: 96 })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
    // M3（2026-10-19）：内容区底色 = `surface`。
    // 设在 `A_Main` 的 HdsNavigation 上会被 HDS 自己的背景盖住（实测页面仍是冷灰），
    // 所以必须落在**真正铺满视口的这一层**上，卡片才能和它形成「深一档」的层次。
    .backgroundColor(this.themeStore.scheme.surface)
  }
}



