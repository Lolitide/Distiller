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

    this.setImmersiveWindow(windowStage);

    windowStage.loadContent('pages/A_Main', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /**
   * 全屏沉浸窗口（做法参考 MoMo/EntryAbility.setImmersiveWindow）：
   * 布局扩到安全区外 + 系统栏透明 + 内容深色（我们只做亮色主题）。
   */
  private setImmersiveWindow(windowStage: window.WindowStage): void {
    try {
      windowStage.getMainWindow().then((w: window.Window) => {
        w.setWindowLayoutFullScreen(true);
        w.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: Theme.STATUS_BAR_CONTENT,
          navigationBarContentColor: Theme.STATUS_BAR_CONTENT
        });
        // 把状态栏高度（px）存进 AppStorage：全屏后页面整体上移了这么多，
        // 各页面的标题栏占位要补回来，否则内容会顶到标题上。
        const area = w.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate<number>('statusBarHeightPx', area.topRect.height);
        hilog.info(DOMAIN, 'testTag', 'Immersive window configured, statusBar=%{public}d', area.topRect.height);
      }).catch((e: Error) => {
        hilog.warn(DOMAIN, 'testTag', 'setImmersiveWindow failed: %{public}s', e.message);
      });
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', 'setImmersiveWindow exception');
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