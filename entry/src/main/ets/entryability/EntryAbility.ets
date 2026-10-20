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
import { Theme } from '../utils/Theme';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
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
   * ⚠️ 2026-10-20 **取消全屏沉浸**（袁正锟：「为了让页面更加简洁，取消全屏沉浸的状态栏和底部导航栏处的沉浸显示」）：
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
        w.setWindowLayoutFullScreen(false);
        w.setWindowSystemBarProperties({
          statusBarContentColor: Theme.STATUS_BAR_CONTENT,
          navigationBarContentColor: Theme.STATUS_BAR_CONTENT
        });
        hilog.info(DOMAIN, 'testTag', 'Window configured (non-immersive)');
      }).catch((e: Error) => {
        hilog.warn(DOMAIN, 'testTag', 'setupWindow failed: %{public}s', e.message);
      });
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', 'setupWindow exception');
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}