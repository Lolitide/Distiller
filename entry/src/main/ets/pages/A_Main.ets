import { HdsNavigation, HdsTabs } from '@kit.UIDesignKit';
import { ComponentContent, UIContext } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MainTabBar } from '../components/MainTabBar';
import { MainTitleBar, settingsMenu, taskListMenu } from '../components/MainTitleBar';
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

  private openMoreMenu(): void {
    const uiContext = this.getUIContext();
    try {
      const contentNode: ComponentContent<UIContext> = this.currentIndex === 0
        ? new ComponentContent(uiContext, wrapBuilder(taskListMenu), uiContext)
        : new ComponentContent(uiContext, wrapBuilder(settingsMenu), uiContext);
      uiContext.getPromptAction()
        .openMenu(contentNode, { id: MainTitleBar.MORE_TARGET_ID })
        .then(() => {
          hilog.info(DOMAIN, TAG, '%{public}s', 'open more menu success');
        })
        .catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG, 'open more menu failed: %{public}s', JSON.stringify(err));
        });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'open more menu args error: %{public}d, %{public}s', err.code, err.message);
    }
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
        menu: MainTitleBar.moreMenu(() => {
          this.openMoreMenu();
        })
      }
    })
    .width('100%')
    .height('100%')
  }
}
