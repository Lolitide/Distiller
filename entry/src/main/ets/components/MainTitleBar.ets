/*
 * UI Design Kit 无对应组件：本文件用 ArkUI 基础组件 Menu / MenuItem 承载
 * 「图标上绑定自定义 menu」的菜单内容（HDS 只提供 menu.value 自带菜单项，
 * 不给自定义菜单内容）。其余一律用 @kit.UIDesignKit 的 HdsNavigation。
 */
import { HdsNavigationMenuContentOptions, ScrollEffectType, TitleBarStyleOptions } from '@kit.UIDesignKit';
import { LengthMetrics, UIContext } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'MainTitleBar';
const MENU_WIDTH: number = 224;

function showItemToast(uiContext: UIContext, message: ResourceStr): void {
  try {
    uiContext.getPromptAction().showToast({ message: message });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, 'show toast failed: %{public}d, %{public}s', err.code, err.message);
  }
}

@Builder
export function taskListMenu(uiContext: UIContext) {
  Menu() {
    MenuItem({ content: $r('app.string.menu_edit') })
      .onClick(() => {
        showItemToast(uiContext, $r('app.string.menu_edit'));
      })
    MenuItem({ content: $r('app.string.menu_search') })
      .onClick(() => {
        showItemToast(uiContext, $r('app.string.menu_search'));
      })
  }
  .width(MENU_WIDTH)
  .menuItemDivider({ strokeWidth: LengthMetrics.px(1), color: $r('sys.color.comp_divider') })
}

@Builder
export function settingsMenu(uiContext: UIContext) {
  Menu() {
    MenuItem({ content: $r('app.string.menu_about') })
      .onClick(() => {
        showItemToast(uiContext, $r('app.string.menu_about'));
      })
  }
  .width(MENU_WIDTH)
  .menuItemDivider({ strokeWidth: LengthMetrics.px(1), color: $r('sys.color.comp_divider') })
}

export class MainTitleBar {
  static readonly MORE_TARGET_ID: string = 'mainTitleBarMore';

  static readonly STYLE: TitleBarStyleOptions = {
    scrollEffectOpts: {
      enableScrollEffect: true,
      scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
      blurEffectiveStartOffset: LengthMetrics.vp(0),
      blurEffectiveEndOffset: LengthMetrics.vp(20)
    },
    scrollEffectStyle: {
      backgroundStyle: { maskExtraHeight: 56.0 }
    }
  };

  static moreMenu(onMore: () => void): HdsNavigationMenuContentOptions {
    return {
      value: [{
        content: {
          label: $r('app.string.action_more'),
          icon: $r('sys.symbol.more'),
          isEnabled: true,
          componentId: MainTitleBar.MORE_TARGET_ID,
          action: onMore
        }
      }]
    };
  }
}
