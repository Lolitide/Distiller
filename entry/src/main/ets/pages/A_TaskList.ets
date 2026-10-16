import { LengthMetrics } from '@kit.ArkUI';
import { Task, TaskStatus } from '../model';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskCard } from '../components/TaskCard';
import { TaskGroupHeader } from '../components/TaskGroupHeader';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';
import { TaskFilterChips } from '../components/TaskFilterChips';
import { TaskListStore } from '../viewmodel/TaskListStore';

/**
 * 组头「上留白回收」量（vp）：官方 `SubHeader` 在标题上方自带一段留白，**官方没给这个留白的旋钮**
 * （`SubHeader` 的参数表里只有标题/副标题/操作项，且官方不建议给它设通用属性）。
 * 实测「上一张卡片底边 → 下一个组标题墨迹顶」= **87px = 24.5vp**，袁正锟 2026-10-16 觉得偏大
 * （「减小每一天任务组之间的间距 有点大了」）→ 用**负上边距**把整块组头往上提，把这段压到 ≈14.5vp。
 * ⚠️ 已知偏离：这是"绕着官方组件调间距"，不是官方给的旋钮（区别于 §四 规则 6 的"不硬改组件"——
 * 这里没有改 `SubHeader` 内部，只是调整它外面的间距）。
 */
const GROUP_HEADER_PULL_UP_VP: number = 10;

/**
 * 列表底部留白（vp）：让**最后一张卡片能滚到悬浮页签栏上方**，不被它压住。
 * 来历（袁正锟 2026-10-16：「页面拉到最底部 Tabbar 会挡住任务卡片」）：
 * `MainTabBar` 开了 `barOverlap(true)`，悬浮栏是**叠在内容之上**的，所以列表底部要让开它的高度。
 * 悬浮栏压住的正好是列表的可视区底部 —— 实测（截图量）栏顶在 y=2482、列表内容区底在 y=2734，
 * 即 **256px = 72vp ＝ 栏高 `tab_bar_default_height`(56vp) + 栏底距 `barBottomMargin`(16vp)**；
 * 再加一点呼吸 → 取 **80vp**。之前这里只有 `padding_level4`(8vp)，所以最后一张卡片会被压住。
 */
const LIST_BOTTOM_CLEARANCE_VP: number = 80;

/** 空状态图示的尺寸（vp）：官方没有随 SDK 发空状态插图，用官方 Symbol 放大到接近插图的观感档位 */
const EMPTY_ICON_SIZE_VP: number = 96;

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
   * 记「完成前是什么状态」，供再点一次圆圈时回退（袁正锟 2026-10-14：再点恢复未完成状态）。
   * 放在页面是因为 `Task` 契约里没有这个字段 —— 它是 UI 的撤销记忆，不该进落库字段。
   * 页面重建会丢（丢了就回退到 `CONFIRMED`）。
   */
  private statusBeforeCompleted: Map<number, TaskStatus> = new Map();

  /** 点圆圈：未完成 → 完成（同时关掉响铃提醒）；已完成 → 退回完成前的状态，并把响铃提醒重新打开 */
  private toggleComplete(task: Task): void {
    if (task.status === TaskStatus.COMPLETED) {
      const previous: TaskStatus | undefined = this.statusBeforeCompleted.get(task.id);
      task.status = previous === undefined ? TaskStatus.CONFIRMED : previous;
      this.statusBeforeCompleted.delete(task.id);
      // 退回未完成时把响铃提醒重新打开（袁正锟 2026-10-14）。
      // 有提醒时间的任务才有开关，所以只在这种情况置值；置 -1 是占位的假提醒键，
      // TODO(袁正锟): 真接 ReminderService 后要改成「发布提醒」并拿服务返回的键。
      if (task.remindAt !== undefined) {
        task.reminderId = -1;
      }
      return;
    }
    this.statusBeforeCompleted.set(task.id, task.status);
    task.status = TaskStatus.COMPLETED;
    // 完成时自动关掉响铃提醒：开关由 reminderId 派生，清空即关
    task.reminderId = undefined;
  }

  /**
   * 拨「响铃提醒」开关。开关状态由 `reminderId` 派生，所以这里就是给它置值 / 清空。
   * TODO(袁正锟): 真接 `service/system/ReminderService` 后，这里要改成调用「发布提醒 / 撤销提醒」，
   * `reminderId` 由服务返回，不许再在页面里凭空造。
   */
  private setRemind(task: Task, isOn: boolean): void {
    task.reminderId = isOn ? -1 : undefined;
  }

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
    // 也就是组头离**上面那组**比离**自己这组**还近 → 袁正锟 2026-10-16 说的「ListHeader 和下方卡片之间的间距是不是太大了…整体展开后协调嘛」。
    // 去掉这层下留白后，组头→本组卡片 ≈ SubHeader 自带的 ~8vp ≈ 卡片↔卡片的 8.2vp，
    // 而组与组之间仍是 14.6vp → **组头明确归属下面那一组**，节奏是 8 / 8 / 14.6。
    //
    // 袁正锟 2026-10-16 追加：「第一个 ListGroup 和 ChipGroup 的间距过大了」→ 上留白回收**对所有组生效**。
    // 原先第一组刻意不回收（那时它上面是标题栏让位区，属于「区块起点」）；现在页面最顶上是 Chip 行，
    // 第一组头也该贴着它 → 与组间间距同为 ~14.5vp。
    .margin({ top: -GROUP_HEADER_PULL_UP_VP })
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
      Row().width('100%').height(MainTitleBar.CONTENT_TOP_OFFSET_VP)

      // 顶部筛选 Chip 行（空态下也要在，否则回不去「全部」）
      TaskFilterChips({ store: this.store })

      Column() {
        SymbolGlyph($r('sys.symbol.inbox'))
          .fontSize(`${EMPTY_ICON_SIZE_VP}vp`)
          .fontColor([$r('sys.color.gray_03')])

        Text(this.store.filteredEmpty ? $r('app.string.empty_filtered_task_list') : $r('app.string.empty_task_list'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      // 图示是纯装饰，无障碍只播报那一句文案
      .accessibilityLevel('yes')
      .accessibilityText(this.store.filteredEmpty
        ? $r('app.string.empty_filtered_task_list')
        : $r('app.string.empty_task_list'))
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
                  TaskCard({
                    task: task,
                    store: this.store,
                    onToggleComplete: () => {
                      this.toggleComplete(task);
                    },
                    onRemindChange: (isOn: boolean) => {
                      this.setRemind(task, isOn);
                    }
                  })
                }
              }, (task: Task) => `${task.id}`)
            }
          }
        }
      }, (group: TaskDayGroup) => `${group.sortValue}-${group.hasDate}`)
    }
    .width('100%')
    .height('100%')
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
