import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Store } from '../common/Store';
import { PollService } from '../service/PollService';
import { PushService } from '../service/PushService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    Store.init(this.context);
    EntryAbility.takeWant(want);
    // Push 的消息接收**必须在这里同步注册**（官方要求：不要放在 await 之后）
    PushService.listen(this);
  }

  /** 点通知时应用已在运行，走这里 */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    EntryAbility.takeWant(want);
  }

  /**
   * 通知带过来的 msgId → 存进 AppStorage，由 HomePage 负责跳详情页。
   *
   * 为什么不在这里直接 pushUrl：冷启动时窗口/UIContext 还没准备好，
   * 交给已经加载好的页面做跳转最稳（HomePage 的 @Watch）。
   */
  private static takeWant(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return;
    }
    const raw: Object | undefined = params['msgId'];
    if (raw !== undefined && typeof raw === 'string' && (raw as string).length > 0) {
      AppStorage.setOrCreate<string>('pendingMsgId', raw as string);
      hilog.info(DOMAIN, 'testTag', 'takeWant msgId=%{public}s', raw as string);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    PollService.start();
    // 通知授权不在这里申请：onForeground 可能早于窗口就绪，弹不出框还会把
    // 「本进程已问过」的开关用掉。改由 HomePage.refreshNotifyState() 在页面里申请。
    // 拿 Push Token 上报后端（后台通知用）；没有设备身份时会自动跳过
    PushService.register();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    PollService.stop();
  }
}