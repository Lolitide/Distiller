/**
 * 首次启动引导（FE-59）。
 *
 * 不做成独立路由页：由 `A_Main` 用全屏覆盖层显示，避免 EntryAbility 为「是否首次」决定
 * 首个页面（会让冷启动路径分叉）。三块内容对应三条通道，通知/日历默认关闭，用户点了才授权。
 */
import { common } from '@kit.AbilityKit';
import { ThemeStore } from '../utils/Theme';
import { NotificationService } from '../service/system/NotificationService';
import { CalendarService } from '../service/system/CalendarService';
import { WindowInsets } from '../utils/WindowInsets';

@ComponentV2
export struct A_Onboarding {
  @Event onFinish: () => void = () => {};
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 两条可选通道默认关闭：不点就不申请权限 */
  @Local notifyOn: boolean = false;
  @Local calendarOn: boolean = false;
  @Local busy: boolean = false;
  /** 状态栏让位：全屏窗口下引导页要自己避开通知栏 */
  @Local statusBarVp: number = 0;

  aboutToAppear(): void {
    this.statusBarVp = this.getUIContext().px2vp(WindowInsets.topPxCached());
    const ctx: common.Context | undefined = this.getUIContext().getHostContext();
    if (ctx !== undefined) {
      WindowInsets.topPx(ctx).then((px: number) => {
        if (px > 0) {
          this.statusBarVp = this.getUIContext().px2vp(px);
        }
      });
    }
  }

  private hostContext(): common.Context | undefined {
    return this.getUIContext().getHostContext();
  }

  private async toggleNotify(isOn: boolean): Promise<void> {
    if (!isOn) {
      this.notifyOn = false;
      return;
    }
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx === undefined || this.busy) {
      return;
    }
    this.busy = true;
    try {
      const enabled: boolean = await NotificationService.ensureEnabled(ctx as common.UIAbilityContext);
      this.notifyOn = enabled;
      if (!enabled) {
        this.toast('通知未开启，可稍后在设置里再打开');
      }
    } finally {
      this.busy = false;
    }
  }

  private async toggleCalendar(isOn: boolean): Promise<void> {
    if (!isOn) {
      this.calendarOn = false;
      return;
    }
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx === undefined || this.busy) {
      return;
    }
    this.busy = true;
    try {
      const granted: boolean = await CalendarService.ensurePermission(ctx as common.UIAbilityContext);
      this.calendarOn = granted;
      if (!granted) {
        this.toast('日历权限未开启，任务仍可用代理提醒');
      }
    } finally {
      this.busy = false;
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  @Builder
  notifyRow() {
    Row({ space: 10 }) {
      Column({ space: 2 }) {
        Text('通知提醒')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
        Text('到点弹通知/横幅；不开也能用日历兜底')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.notifyOn })
        .onChange((next: boolean) => {
          this.toggleNotify(next);
        })
    }
    .width('100%')
    .padding(14)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  calendarRow() {
    Row({ space: 10 }) {
      Column({ space: 2 }) {
        Text('系统日历')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
        Text('把任务写成「知了」日程；不写也不影响任务本身')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: this.calendarOn })
        .onChange((next: boolean) => {
          this.toggleCalendar(next);
        })
    }
    .width('100%')
    .padding(14)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      Column({ space: 8 }) {
        Text('欢迎使用知了')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
        Text('把群消息变成可执行的待办。先花半分钟看看数据边界与可选权限。')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 8, bottom: 16 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 6 }) {
            Text('数据边界')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Text('任务、备注、原文、草稿只存在本机；群消息原文只在服务器内存保留 30 分钟。'
              + '同步开启时只发送设备标识、绑定关系、群订阅与反馈计数，任务内容不会上传。')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .width('100%')
          .padding(14)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
          .borderRadius(14)

          Column() {
            Text('可选通道（默认关闭）')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width('100%')
              .padding({ left: 14, right: 14, top: 12, bottom: 4 })
            this.notifyRow()
            Divider()
            this.calendarRow()
          }
          .width('100%')
          .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
          .borderRadius(14)

          Column({ space: 6 }) {
            Text('服务器与绑定')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
            Text('服务器地址和 QQ 绑定可以稍后在「设置」里完成；不绑定也能手动添加任务。')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .width('100%')
          .padding(14)
          .alignItems(HorizontalAlign.Start)
          .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
          .borderRadius(14)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      Button({ type: ButtonType.Capsule, stateEffect: true }) {
        Text('开始使用')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor(this.themeStore.scheme.onPrimary)
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.themeStore.scheme.primary)
      .borderRadius(22)
      .margin({ top: 12, bottom: 20 })
      .onClick(() => {
        this.onFinish();
      })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 20,
      right: 20,
      top: this.statusBarVp + 12
    })
    .backgroundColor(this.themeStore.scheme.surface)
  }
}
