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
        onIndexChange: (index: number) => {
          this.currentIndex = index;
        },
        onAdd: () => {
          this.onAdd();
        }
      })
    }
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
