import { HdsNavigation, HdsNavigationMenuContentOptions, HdsTabs } from '@kit.UIDesignKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MainTabBar } from '../components/MainTabBar';
import { MainTitleBar } from '../components/MainTitleBar';
import { A_TaskList } from './A_TaskList';
import { A_Settings } from './A_Settings';

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

  build() {
    HdsNavigation(this.navPathStack) {
      HdsTabs({ barPosition: BarPosition.End }) {
        TabContent() {
          A_TaskList()
        }
        .tabBar(MainTabBar.TASK_LIST)

        TabContent() {
          A_Settings()
        }
        .tabBar(MainTabBar.SETTINGS)
      }
      .vertical(false)
      .scrollable(false)
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      .onChange((index: number) => {
        this.currentIndex = index;
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
