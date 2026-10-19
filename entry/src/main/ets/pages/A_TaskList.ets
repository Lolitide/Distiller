import { LengthMetrics } from '@kit.ArkUI';
import { Task } from '../model';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskSubCard } from '../components/TaskSubCard';
import { TaskStep } from '../model';
import { Theme } from '../utils/Theme';
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
const LIST_BOTTOM_CLEARANCE_VP: number = 80;

/* ── 副卡片「堆叠」形态（2026-10-19 实验性 UI）── */

/** 收起时露出的下边缘高度（vp）：只为示意底下还压着一张卡，不承载内容 */
const STACK_LAYER_EDGE_VP: number = 12;
/** 堆叠层宽度：比主卡片窄一点，才读得出是压在底下 */
const STACK_LAYER_WIDTH: string = '92%';
/** 堆叠层与主卡片之间的缝隙（vp） */
const STACK_LAYER_OFFSET_VP: number = 4;
/** 长按判定时长（毫秒） */
const LONG_PRESS_MS: number = 500;

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

  /** 长按：展开/收起该任务的副卡片 */
  private toggleSteps(taskId: number): void {
    const next: number[] = this.expandedStepIds.slice();
    const index: number = next.indexOf(taskId);
    if (index >= 0) {
      next.splice(index, 1);
    } else {
      next.push(taskId);
    }
    this.expandedStepIds = next;
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
          group.expanded = !group.expanded;
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
      Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP)

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
        Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP)
      }
      .accessibilityLevel('no')

      // 页面最顶上那一排筛选 Chip（在第一项让位区之后，所以它正好贴在标题栏下方）
      ListItem() {
        TaskFilterChips({ store: this.store })
      }

      ForEach(this.store.groups, (group: TaskDayGroup) => {
        // 当前筛选下这一组一条都没有 → 整组不渲染（组头也不出现）
        if (this.store.visibleTasks(group).length > 0) {
          ListItemGroup({
            header: this.groupHeader(group),
            spaceWidth: $r('sys.float.padding_level4')
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
                      if (this.isStepsExpanded(task.id)) {
                        // 展开态：完整副卡片
                        Column() {
                          TaskSubCard({
                            task: task,
                            onToggleStep: (index: number) => {
                              this.store.toggleStepDone(task, index);
                            }
                          })
                        }
                        .width('100%')
                        .margin({ top: STACK_LAYER_OFFSET_VP })
                      } else {
                        // 收起态：只露一条下边缘，宽度略窄 → 读作"底下压着一张小卡"
                        Row()
                          .width(STACK_LAYER_WIDTH)
                          .height(STACK_LAYER_EDGE_VP)
                          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                          .borderRadius({
                            bottomLeft: Theme.RADIUS_CARD,
                            bottomRight: Theme.RADIUS_CARD
                          })
                          .margin({ top: STACK_LAYER_OFFSET_VP })
                          .accessibilityText($r('app.string.subcard_stacked_hint'))
                      }
                    }
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Center)
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
  }

  build() {
    // 有任务＝列表；一条都没有＝官方风格的空状态（两者都是内容区的根，外面套 Stack 保证根节点是容器）
    Stack() {
      if (this.isEmpty) {
        this.emptyState()
      } else {
        this.taskList()
      }
    }
    .width('100%')
    .height('100%')
  }
}
