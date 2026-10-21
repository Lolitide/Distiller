/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Theme, ThemeStore } from '../utils/Theme';
import { SettingsRepository } from '../repository/SettingsRepository';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  /** 主窗口句柄：切后台/回前台要复原、重刷系统栏颜色（见 `onBackground` / `onForeground`） */
  private mainWindow: window.Window | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // **首帧之前**把用户个性化设置读进来（同步），否则冷启动会「先默认色、再跳个性化」闪一下
    this.preloadThemeSettings();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  /**
   * 冷启动同步预读主题色与卡片密度（2026-10-21 修「冷启动主题色闪现」）。
   *
   * 时机很重要：这里是 `onCreate`，UI 还没创建 ⇒ 首帧就是用户上次选的配色，不会闪。
   * 之后 `A_Main.syncTheme()` 仍会异步再读一遍（值相同，等于无事发生），留着当兜底。
   */
  private preloadThemeSettings(): void {
    const theme: ThemeStore = ThemeStore.instance();
    theme.accentIndex = SettingsRepository.getThemeAccentSync(this.context, theme.accentIndex);
    theme.density = SettingsRepository.getDensitySync(this.context, theme.density);
    hilog.info(DOMAIN, 'testTag', 'Preloaded theme: accent=%{public}d, density=%{public}d',
      theme.accentIndex, theme.density);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.setupWindow(windowStage);

    windowStage.loadContent('pages/A_Main', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /**
   * 窗口设置。
   *
   * ⚠️ 2026-10-20 **取消全屏沉浸**（需求方：「为了让页面更加简洁，取消全屏沉浸的状态栏和底部导航栏处的沉浸显示」）：
   * 原来是 `setWindowLayoutFullScreen(true)` + 系统栏透明色（内容铺到状态栏/手势条底下）。
   * 现在改成 `false` —— 页面布局区**不再**伸进系统栏，状态栏与底部导航条回到系统自己的区域，
   * 内容不会再从它们底下穿过。系统栏图标仍要深色（页面是亮色），所以只给 `*ContentColor`，不给背景色；
   * 背景色由 `A_Main.applyWindowTheme()` 在主题加载后统一刷成 M3 `surface`（避免顶部露出白条）。
   *
   * 顺带删掉了 `AppStorage['statusBarHeightPx']` + 三个页面的 `sbVp` 补偿：
   * 那是给「布局伸进状态栏」补回来的高度，取消沉浸后**布局区已自动让开状态栏**，再补就成了双倍留白。
   */
  private setupWindow(windowStage: window.WindowStage): void {
    try {
      windowStage.getMainWindow().then((w: window.Window) => {
        this.mainWindow = w;
        // 2026-10-21（需求方：「启动时状态栏提前显示的色块 / 展示浮窗时不变暗的色块 / 能去掉吗」）：
        // **窗口全屏**，但**不再由窗口刷系统栏底色**。
        // 之前 `setWindowSystemBarProperties({statusBarColor})` 是**窗口级**绘制 —— 它不在 ArkUI 内容树里，
        // 所以 ① 窗口一创建就先画出来（早于页面首帧，看着像"凭空一块色"）
        //     ② 弹半模态的蒙层盖不到它（周围都变暗、就这一条亮着）。
        // 现在底色改由**页面自己画**（`A_Main` 根节点上的底面 + `expandSafeArea` 铺进系统栏），
        // 于是它和页面同生同灭、也跟着蒙层一起变暗；这里只保留系统栏**图标/文字**的深色。
        w.setWindowLayoutFullScreen(true);
        w.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: Theme.STATUS_BAR_CONTENT,
          navigationBarContentColor: Theme.STATUS_BAR_CONTENT
        });
        hilog.info(DOMAIN, 'testTag', 'Window configured (full-screen, page-painted bars)');
      }).catch((e: Error) => {
        hilog.warn(DOMAIN, 'testTag', 'setupWindow failed: %{public}s', e.message);
      });
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', 'setupWindow exception');
    }
  }
  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    this.mainWindow = undefined;
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }}