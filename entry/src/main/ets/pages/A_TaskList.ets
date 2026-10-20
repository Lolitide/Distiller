import { LengthMetrics } from '@kit.ArkUI';
import { Task } from '../model';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskSubCard } from '../components/TaskSubCard';
import { TaskStep } from '../model';
import { Theme, ThemeStore } from '../utils/Theme';
import { GROUP_HEADER_LIST_PULL_UP_VP, TaskGroupHeader } from '../components/TaskGroupHeader';
import { EmptyHint } from '../components/EmptyHint';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';
import { TaskFilterChips } from '../components/TaskFilterChips';
import { ROUTE_TASK_DETAIL, NAV_STACK_KEY, TaskDetailParam } from '../viewmodel/TaskNavParams';
import { TaskListStore } from '../viewmodel/TaskListStore';

/**
 * 列表底部留白（vp）：让**最后一张卡片能滚到悬浮页签栏上方**，不被它压住。
 * 来历（袁正锟 2026-10-16：「页面拉到最底部 Tabbar 会挡住任务卡片」）：
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
/** 标题栏收起后的高度（vp）：HdsNavigation 的 MINI 档 */
const TITLE_BAR_COLLAPSED_VP: number = 56;

const LIST_BOTTOM_CLEARANCE_VP: number = 80;

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

  /** 列表当前滚动量（vp）：用来让 Chip 行跟着标题一起上滑 */
  @Local scrollVp: number = 0;

  /**
   * Chip 行悬浮层的顶部位置（vp）。
   *
   * 作者 2026-10-19：「它应该上滑一段距离直到标题不再移动变化时停在那个位置，
   * 就像和标题的运动绑在一起」。
   *
   * 标题栏从 `CONTENT_TOP_OFFSET_VP`(112) 收到 `TITLE_BAR_COLLAPSED_VP`(56)，
   * 收起过程正好消耗 56vp 的滚动量；Chip 行用同样的起点与同样的收缩距离，
   * 到 56vp 后 `max` 把它钉住 —— 视觉上就是和标题同步移动、然后一起停住。
   */
  @Computed
  get chipsTopVp(): number {
    const expanded: number = MainTitleBar.CONTENT_TOP_OFFSET_VP + this.sbVp;
    const collapsed: number = TITLE_BAR_COLLAPSED_VP + this.sbVp;
    return Math.max(collapsed, expanded - Math.max(0, this.scrollVp));
  }

  /** 状态栏高度（vp）：全屏沉浸后页面整体上移了这么多，标题栏占位要补回来 */
  @Computed
  get sbVp(): number {
    return px2vp(AppStorage.get<number>('statusBarHeightPx') ?? 0);
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
          this.getUIContext().animateTo({
            duration: GROUP_EXPAND_ANIM_MS,
            curve: Curve.FastOutSlowIn
          }, () => {
            group.expanded = !group.expanded;
          });
        }
      })
    }
    .width('100%')
    // ⚠️ 这里**刻意不再加下留白**（原来加的是 `padding_level8` = 16vp）。
    // 实测（把五个分组全部展开后逐像素量，`.cache/all1-padding.txt` + `.cache/all1-report.txt`）：
    //   卡片 ↔ 卡片（同组内）= **8.2vp**；组头副标题 → 本组第一张卡片 = **23.6vp**（＝ SubHeader 自带的 ~7.9vp 下留白 ＋ 我们这层 16vp）；
    //   上组最后一张卡片 → 组头顶标题 = **14.6vp**。
    // 也就是组头离**上面那组**比离**自己这组**还近 → 袁正锟 2026-10-16 说的「ListHeader 和下方卡片之间的间距是不是太大了…整体展开后协调嘛」。
    // 去掉这层下留白后，组头→本组卡片 ≈ SubHeader 自带的 ~8vp ≈ 卡片↔卡片的 8.2vp，
    // 而组与组之间仍是 14.6vp → **组头明确归属下面那一组**，节奏是 8 / 8 / 14.6。
    //
    // 袁正锟 2026-10-16 追加：「第一个 ListGroup 和 ChipGroup 的间距过大了」→ 上留白回收**对所有组生效**。
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
   * 空状态（袁正锟 2026-10-16：「没有一项任务的时候 背景做一个官方那样的风格 一个图片表示无任务
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
      Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP + this.sbVp)

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
      // 再滚一点才变成 56vp），也就是袁正锟 2026-10-16 说的「mainTitle 向左上角移动的动画明显慢于页面上滑」。
      // 改成列表首项留白（＝官方示例 `Scroll { Column { Blank(标题栏高度) ... } }` 的写法）后，滚动偏移从第一像素
      // 就开始参与收缩计算 → 标题跟手。（`.cache/nb-report.txt` / `.cache/fn-report.txt` 是改前的量测记录。）
      ListItem() {
        // `Blank` 只能放进 Row/Column/Flex，所以这里用一行空 `Row` 撑出这段高度。
        // 无障碍不上报这个空项（否则读屏会播报一个空列表项）
        Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP + this.sbVp)
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
    // 把滚动量喂给 Chip 悬浮层，让它跟标题一起上滑（见 `chipsTopVp`）
    .onDidScroll(() => {
      this.scrollVp = px2vp(this.scroller.currentOffset().yOffset);
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

      // **Chip 行悬浮冻结层**（2026-10-19，作者要求）：
      // 未滚动时贴在展开的标题栏下方；上滑时与标题同步上移；
      // 标题收到 MINI 档后停在那个位置不再动。
      // 底色用页面 `surface`，把从下面滚过的卡片挡住。
      if (!this.isEmpty) {
        Column() {
          TaskFilterChips({ store: this.store })
        }
        .width('100%')
        // 底色从**标题栏收起线**开始铺，而不是从 chip 本身开始：
        // 否则标题与 chip 之间那条缝仍会透出滚动的内容（实测能看到「未安排日期」的上半截）。
        // 用 padding 把上方那段补成同色，chip 的视觉位置仍由 `chipsTopVp` 决定。
        .margin({ top: TITLE_BAR_COLLAPSED_VP + this.sbVp })
        .padding({ top: Math.max(0, this.chipsTopVp - (TITLE_BAR_COLLAPSED_VP + this.sbVp)) })
        .backgroundColor(this.themeStore.scheme.surface)
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
