import { ThemeStore } from '../utils/Theme';
/*
 * 搜索页（**二级页**，按 §9.1 用 `B_` 前缀）。
 *
 * 现状（需求方 2026-10-16 三步走）：
 *  ① 「点导航栏的搜索按钮 → 滑入一个二级页 → 能返回」✓；
 *  ② 加搜索框 ✓（官方 `Search` 组件，抽在 `components/SearchField.ets`）；
 *  ③ **搜索功能** ✓：结果**直接复用列表页那套组件**（`TaskGroupHeader` + `TaskCard` + 同一套组间距常量），
 *     并按需求方的要求做三种状态：
 *       · 没输关键词 → 与列表页空态同样的图示，「点击搜索框开始」
 *       · 有关键词但一条没命中 → 同样图示，「无结果」
 *       · 有命中 → 分组卡片列表
 *
 * 用官方 **`HdsNavDestination`**（HDS 的导航子页面容器）而不是普通 `NavDestination`：
 * 它是 HDS 导航根容器的子页容器（`HdsNavigation.navDestination(builder)` 要构造的就是它）。
 * 进/退场是导航栈 push/pop 的默认转场，不需要自己写动画。
 *
 * 数据来源：**任务列表的同一个 store**（由 `A_Main` 通过 `pushPathByName` 的 param 传进来），
 * 所以搜索看到的就是列表里的那份数据，不是复制品。
 */
import { HdsNavDestination } from '@kit.UIDesignKit';
import { KeyboardAvoidMode } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WindowInsets } from '../utils/WindowInsets';
import { MainTitleBar } from '../components/MainTitleBar';
import { EmptyHint } from '../components/EmptyHint';
import { SearchField } from '../components/SearchField';
import { GROUP_HEADER_LIST_PULL_UP_VP, TaskGroupHeader } from '../components/TaskGroupHeader';
import { TaskCard } from '../components/TaskCard';
import { Task } from '../model';
import { TaskDayGroup } from '../viewmodel/TaskListViewModel';
import { NAV_STACK_KEY, ROUTE_TASK_DETAIL, TaskDetailParam } from '../viewmodel/TaskNavParams';
import { SearchState, TaskSearchViewModel } from '../viewmodel/TaskSearchViewModel';
import { TaskListStore } from '../viewmodel/TaskListStore';

/*
 * 二级页标题栏高度（vp）—— 数值现归 `MainTitleBar.SUB_PAGE_TITLE_BAR_VP`（详情页也用它，一处真值源）。
 *
 * `HdsNavDestination` 的 `titleMode` **默认就是 MINI**（官方原文：「默认值：HdsNavDestinationTitleMode.MINI。」），
 * MINI 的高度官方写作「**MINI：固定为小标题模式。标题栏高度为 56vp**」。
 *
 * 🔴 不能照抄主页的 `MainTitleBar.CONTENT_TOP_OFFSET_VP`(112) —— 那是 `HdsNavigation`（主页）
 * FREE 模式的高度，二级页只有 56vp；用 112 会让整页内容凭空低 56vp
 * （需求方 2026-10-16：「为什么这么靠下」）。
 *
 * 🔴 **56vp 只是标题栏自己**，还不含状态栏：窗口全屏后二级页内容区从窗口顶端起算，
 * 标题栏却已被 HDS 让开状态栏 → 只留 56vp 会让搜索框压到标题文字上。
 * 让白要写「`SUB_PAGE_TITLE_BAR_VP` + `statusBarVp`」（2026-10-21 布局探针实测，见 `syncStatusBarHeight`）。
 */

/** 搜索框与标题栏之间的额外间距（vp）：**故意留 0**，间距交给组件自己的内边距（与 List 页面同一约定） */
const SEARCH_FIELD_TOP_GAP_VP: number = 0;

const DOMAIN: number = 0x0000;
const TAG: string = 'B_Search';

/**
 * 二级页的实例化方法 —— **官方系统路由表要的就是它**（`router_map.json` 里的 `buildFunction`）。
 * `param` 是 `A_Main` 压栈时带过来的任务 store。
 */
@Builder
export function SearchPageBuilder(name: string, param: Object) {
  B_Search({ store: param as TaskListStore });
}

@ComponentV2
export struct B_Search {
  /** 视觉个性化：M3 色系（搜索页底色 = surface） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 任务数据源：**列表页同一个 store**（搜的是同一份数据，不是副本） */
  @Require @Param store: TaskListStore;

  /** 搜索框里的关键词 */
  @Local query: string = '';

  /**
   * 状态栏高度（vp）：窗口全屏后内容区从窗口顶端起算，要先让开这一截（见 `syncStatusBarHeight`）。
   * 首帧从缓存同步取，所以正常情况下不会有 0 → 39vp 的跳变。
   */
  @Local statusBarVp: number = 0;

  /**
   * 让**软键盘压缩页面**而不是只把页面上抬。
   *
   * 官方把页面避让模式分成三种（`KeyboardAvoidMode`，默认 `OFFSET`）：OFFSET 是「页面上抬」，
   * 但官方明确写了「**当输入光标距离屏幕底部的高度大于键盘高度时，page 不会抬起**」——
   * 我们搜索框在顶部、光标离底很远，所以默认模式下键盘一弹，页面纹丝不动，
   * 居中的「无结果」文案正好被键盘盖住（实测截图 `.cache/s-none.png`）。
   * `RESIZE` 是「压缩页面大小」，官方说明「页面中设置百分比宽高的组件会跟随页面压缩」——
   * 正好让空态在**键盘之上**的可见区域里重新居中。
   *
   * 这是**页面级**设置，所以离开搜索页要**还原**成默认的 OFFSET，别影响别的页面。
   */
  aboutToAppear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    this.syncStatusBarHeight();
  }

  /**
   * 状态栏高度（vp）—— 内容顶部让白的**第一截**（2026-10-21 修「搜索页导航栏和内容重合」）。
   *
   * 与详情页**同一个坑、同一套解法**，证据也在那边记着（`B_TaskDetail.syncStatusBarHeight`）：
   * 窗口全屏（`setWindowLayoutFullScreen(true)`），`HdsNavDestination` 只让标题栏自己避开状态栏，
   * 内容区仍从窗口顶端 y=0 起算 → 只让 56vp 时搜索框会压到「搜索」小标题上。
   *
   * 先读同步缓存（首帧就正确、进场动画不跳），再异步刷新兜底（转屏/折叠态会变）。
   */
  private syncStatusBarHeight(): void {
    this.statusBarVp = this.getUIContext().px2vp(WindowInsets.topPxCached());
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    WindowInsets.topPx(context).then((px: number) => {
      this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
    });
  }

  aboutToDisappear(): void {
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET);
  }

  /**
   * 结果分组。
   *
   * ⚠️ 刻意用 `@Local` ＋ `@Monitor` 而不是 `@Computed`：`@Computed` 每次依赖变化都会**重算**，
   * 于是每次重算都产生**全新的 `TaskDayGroup` 对象** → 用户折叠过的分组会被"重新展开"，
   * 分组头的展开状态根本留不住。改成只在**关键词变化时**重算一次，之后（点圆圈改状态、折叠展开）
   * 都在同一批分组对象上发生，靠 `@Trace` 自己刷新。
   */
  @Local results: TaskDayGroup[] = [];

  /**
   * 关键词一变就重算结果。
   *
   * 🔴 这个方法是 `@Monitor`（V2），**它里面抛出的异常不会被"某个组件渲染失败"消化掉**：
   * 框架把它当 RuntimeError 上报，进程直接退出。2026-10-23 的闪退正是这么来的 ——
   * `task.name` 是本机旧数据里的 `undefined`，`matches()` 里的 `.toLowerCase()` 一抛，
   * 用户看到的就是"输入第一个字符，App 消失"。
   *
   * 根因已在两处修掉（`TaskRepository.revive` 做旧字段迁移、`TaskSearchViewModel.text` 做空值归一）。
   * 这里再留一道护栏：搜索是**纯查询**，真出问题就退化成"没有结果"并写错误日志，
   * 而不是把整个 App 带走。**异常必须记日志**，不许静默吞掉（否则真 bug 会藏起来）。
   */
  @Monitor('query')
  onQueryChanged(): void {
    try {
      this.results = TaskSearchViewModel.search(this.store.allTasks(), this.query, new Date());
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'search failed: %{public}s', err.message);
      this.results = [];
    }
  }

  /** 当前该显示哪一种状态（没输关键词 / 有结果 / 无结果） */
  @Computed
  get state(): SearchState {
    return TaskSearchViewModel.state(this.results, this.query);
  }

  /** 居中占位的空态（图示 + 一句话），与列表页空态同一个组件 */
  @Builder
  hint(message: Resource) {
    EmptyHint({ message: message })
      .layoutWeight(1)
  }

  /** 分组头：与列表页同一个组件、同一套间距常量（搜索页没有筛选，所以计数就是组内全量） */
  @Builder
  groupHeader(group: TaskDayGroup) {
    Column() {
      TaskGroupHeader({
        group: group,
        pendingCount: group.pendingCount,
        totalCount: group.totalCount,
        onToggle: () => {
          group.expanded = !group.expanded;
        }
      })
    }
    .width('100%')
    .margin({ top: -GROUP_HEADER_LIST_PULL_UP_VP })
  }

  /**
   * 搜索结果列表：**结构照列表页那条 List** —— 同样的 `ListItemGroup` + `TaskGroupHeader` + `TaskCard`，
   * 同样的 `spaceWidth`（`padding_level4`）与同样的组头上留白回收量。
   * 差异只有两条：① 结果里所有分组默认展开；② 搜索页没有悬浮页签栏，所以不需要底部让位。
   */
  @Builder
  resultList() {
    List() {
      ForEach(this.results, (group: TaskDayGroup) => {
        ListItemGroup({
          header: this.groupHeader(group),
          spaceWidth: $r('sys.float.padding_level4')
        }) {
          if (group.expanded) {
            ForEach(group.tasks, (task: Task) => {
              ListItem() {
                TaskCard({
                  task: task,
                  store: this.store,
                  // 与列表页同一套行为（已完成撤销记忆也在 store 里）
                  onToggleComplete: () => {
                    this.store.toggleComplete(task);
                  },
                  onRemindChange: (isOn: boolean) => {
                    this.store.setRemind(task, isOn);
                  },
                  // 搜索结果里点整卡也进详情（压到同一个导航栈上，返回后回到搜索页）
                  onOpen: () => {
                    AppStorage.get<NavPathStack>(NAV_STACK_KEY)
                      ?.pushPathByName(ROUTE_TASK_DETAIL, new TaskDetailParam(task, this.store));
                  }
                })
              }
            }, (task: Task) => `${task.id}`)
          }
        }
      }, (group: TaskDayGroup) => `${group.sortValue}-${group.hasDate}`)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  build() {
    HdsNavDestination() {
      // 2026-10-21 与详情页同一处修：`HdsNavDestination` 内容区让开底部安全区，
      // 它自己那层默认白底铺到窗口最底 → 手势条那一带露白条。
      // 补一层**只负责颜色**的底色（expandSafeArea 铺进安全区），内容层保持让开。
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.themeStore.scheme.surface)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .hitTestBehavior(HitTestMode.None)

      Column() {        // 顶部让开**状态栏 + 二级页自己的标题栏**（MINI = 56vp，两截都要补）
        Row().width('100%')
          .height(MainTitleBar.SUB_PAGE_TITLE_BAR_VP + SEARCH_FIELD_TOP_GAP_VP + this.statusBarVp)

        // 左右留白放在**外层容器**上（与页面其它内容同一档：官方 `padding_level8` = 16vp）。
        // ⚠️ 不能给 `Search` 自己配 `.margin()`：它是 width('100%')，100% + 边距会溢出、边距被吃掉
        //    → 实测药丸左右各 0vp、直接贴屏边（需求方 2026-10-16：「为什么贴到屏幕两边了」）。
        Row() {
          SearchField({
            onChange: (text: string) => {
              this.query = text;
            }
          })
        }
        .width('100%')
        .padding({
          left: $r('sys.float.padding_level8'),
          right: $r('sys.float.padding_level8')
        })

        // —— 三种状态 ——
        if (this.state === SearchState.IDLE) {
          // 还没输关键词
          this.hint($r('app.string.search_idle_hint'))
        } else if (this.state === SearchState.NO_RESULT) {
          // 有关键词但一条没命中
          this.hint($r('app.string.search_no_result'))
        } else {
          this.resultList()
        }
      }
      .width('100%')
      .height('100%')
      // 2026-10-20 取消全屏沉浸：布局区已自动让开状态栏，
      // 原来的 `.padding({ top: this.sbVp })` 与 `.expandSafeArea(...)` 一并删掉（否则是双倍留白）。
      // 2026-10-19 全局 MD3：底色从系统浅蓝 `ohos_id_color_sub_background`(#f1f3f5)
      // 换成 M3 `surface` —— 与任务列表 / 设置 / 详情页同一套色系
      //（原先这里是为了跟主页 HdsTabs 容器那层灰对齐，现在主页也走 M3 了）。
      .backgroundColor(this.themeStore.scheme.surface)
      }
      .width('100%')
      .height('100%')
    }    // 标题栏沿用主页面那套官方风格（`MainTitleBar.style`），观感与首页一致
    // 2026-10-21：入参从「#F2+surface 半透背板」改成「surface 实色背板」（背板与图标圆底在 style() 内推导），
    // 这样滚动时标题栏与 Chip 行接成一整块实色，内容不再从顶部透出。
    .titleBar({
      // 2026-10-21 窗口改回全屏：必须 `true`，否则二级页标题栏会顶到状态栏底下（与主页同一口径）
      avoidLayoutSafeArea: true,
      style: MainTitleBar.style(this.themeStore.scheme.surface, this.themeStore.scheme.onSurface),
      content: {
        title: { mainTitle: $r('app.string.title_search') }
      }
    })
    // 默认就带返回图标，这里显式写出来（官方示例也是这么写的）
    .hideBackButton(false)
  }
}
