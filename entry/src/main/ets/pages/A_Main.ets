import { HdsNavigation, HdsNavigationMenuContentOptions } from '@kit.UIDesignKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MainTabBar } from '../components/MainTabBar';
import { MainTitleBar } from '../components/MainTitleBar';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Main';

@Entry
@ComponentV2
struct A_Main {
  private navPathStack: NavPathStack = new NavPathStack();
  /**
   * 任务列表的滚动控制器：在这里创建（照官方示例：Scroller 由页面持有），
   * 一路透传 `MainTabBar → A_TaskList` 给 `List` 用，再交给 `HdsNavigation.bindToScrollable`。
   */
  private taskListScroller: Scroller = new Scroller();
  @Local currentIndex: number = 0;

  @Computed
  get navTitle(): ResourceStr {
    return this.currentIndex === 0 ? $r('app.string.tab_task_list') : $r('app.string.tab_settings');
  }

  /**
   * 右上角按钮**随页签变**：任务列表＝编辑 + 搜索（两个图标按钮），设置＝关于（一个）。
   * 官方 `HdsNavigation` 是**函数式组件**（`HdsNavigationInterface`），`titleBar` 参数会随重渲染更新，
   * 所以这里用 `@Computed` 依赖 `currentIndex` 就能换来换去。
   */
  @Computed
  get navMenu(): HdsNavigationMenuContentOptions {
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

  private onEdit(): void {
    this.toast($r('app.string.menu_edit'));
  }

  private onSearch(): void {
    this.toast($r('app.string.menu_search'));
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
        onIndexChange: (index: number) => {
          this.currentIndex = index;
        },
        onAdd: () => {
          this.onAdd();
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
