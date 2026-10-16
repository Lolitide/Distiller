import { HdsNavigation, HdsNavigationMenuContentOptions } from '@kit.UIDesignKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MainTabBar } from '../components/MainTabBar';
import { MainTitleBar } from '../components/MainTitleBar';
import { TaskListStore } from '../viewmodel/TaskListStore';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Main';

/** 二级页路由名：`HdsNavigation.navDestination` 的 builder 按它分发（现在只有搜索页） */
const ROUTE_SEARCH: string = 'SearchPage';

@Entry
@ComponentV2
struct A_Main {
  private navPathStack: NavPathStack = new NavPathStack();
  /**
   * 任务列表的滚动控制器：在这里创建（照官方示例：Scroller 由页面持有），
   * 一路透传 `MainTabBar → A_TaskList` 给 `List` 用，再交给 `HdsNavigation.bindToScrollable`。
   */
  private taskListScroller: Scroller = new Scroller();
  /**
   * 任务列表的「数据 ＋ 编辑态」store：页面持有、按引用透传（`@ObservedV2` 必须 `new` 出来才可观测）。
   * 编辑态要同时被导航栏（取消/全选）、底部悬浮栏（添加↔删除）、每张卡片（圆圈↔方框勾选框）读到，
   * 挂在页面这一层最省事，也不用把状态在几层组件之间来回搬。
   */
  private store: TaskListStore = new TaskListStore();
  @Local currentIndex: number = 0;

  @Computed
  get navTitle(): ResourceStr {
    return this.currentIndex === 0 ? $r('app.string.tab_task_list') : $r('app.string.tab_settings');
  }

  /**
   * 右上角按钮**随页签与编辑态变**：
   * · 普通态 —— 任务列表＝编辑 + 搜索（两个图标按钮），设置＝关于（一个）；
   * · **编辑态 —— 取消 / 全选（两个纯文字按钮）**（袁正锟 2026-10-16）。
   * 官方 `HdsNavigation` 是**函数式组件**（`HdsNavigationInterface`），`titleBar` 参数会随重渲染更新，
   * 所以这里用 `@Computed` 依赖 `currentIndex` 与 `store.editing` 就能换来换去。
   */
  @Computed
  get navMenu(): HdsNavigationMenuContentOptions {
    if (this.store.editing) {
      return MainTitleBar.editModeMenu(() => {
        this.store.exitEdit();
      }, () => {
        this.store.selectAll();
      });
    }
    if (this.currentIndex === 0) {
      return MainTitleBar.taskListMenu(() => {
        this.onEdit();
      }, () => {
        this.onSearch();
      });
    }
    return MainTitleBar.settingsMenu(() => {
      this.onAbout();
    });
  }

  /** 统一的 toast 反馈（菜单项/图标按钮无文字，点了要给可见反馈） */
  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'show toast failed: %{public}d, %{public}s', err.code, err.message);
    }
  }

  /** 右上角「编辑」：进入多选模式（卡片的圆圈变方框勾选框、右上角变取消/全选、底部添加变删除） */
  private onEdit(): void {
    this.store.enterEdit();
  }

  private onSearch(): void {
    // 点导航栏的「搜索」→ 把搜索页压入导航栈（二级页**从右侧滑进来**是导航栈 push 的默认行为）。
    // 页面本身在 `router_map.json` 里注册（官方系统路由表），所以这里只要路由名；
    // **把任务 store 一起带过去**，搜索页搜的就是列表这一份数据（不是副本）。
    this.navPathStack.pushPathByName(ROUTE_SEARCH, this.store);
  }

  private onAbout(): void {
    this.toast($r('app.string.menu_about'));
  }

  /** 迷你栏里的「添加任务」。真实新增流程未做，先给可见反馈 */
  private onAdd(): void {
    this.toast($r('app.string.action_add_task'));
  }

  build() {
    HdsNavigation(this.navPathStack) {
      // 底部页签栏（HdsTabs 容器 + 两个页签 + 悬浮样式 + 迷你栏）整个在 components/MainTabBar.ets 里
      MainTabBar({
        scroller: this.taskListScroller,
        store: this.store,
        onIndexChange: (index: number) => {
          this.currentIndex = index;
        },
        onAdd: () => {
          this.onAdd();
        },
        onDeleteDone: (count: number) => {
          // 卡片消失本身就是反馈，再补一句 toast 说明删了几条
          this.toast($r('app.string.deleted_count', count));
        }
      })
    }
    // —— 标题栏跟手：官方要求把导航组件与可滚动容器绑起来 ——
    // 官方原文：「6.0.0(20)及以上版本，推荐使用 bindToScrollable、bindToNestedScrollable 属性绑定导航组件和
    // 可滚动容器组件后，再使用导航组件滚动相关的功能，从而获得更优的体验」；
    // `HdsNavigationTitleMode.FREE` 的官方说明也写着「推荐搭配 bindToScrollable/bindToNestedScrollable 体验更佳的联动效果」。
    .bindToScrollable([this.taskListScroller])
    .hideBackButton(true)
    .titleBar({
      style: MainTitleBar.STYLE,
      content: {
        title: { mainTitle: this.navTitle },
        menu: this.navMenu
      }
    })
    .width('100%')
    .height('100%')
  }
}
