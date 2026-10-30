/**
 * 首次启动引导（FE-59）。
 *
 * 不做成独立路由页：由 `A_Main` 用全屏覆盖层显示，避免 EntryAbility 为「是否首次」决定
 * 首个页面（会让冷启动路径分叉）。三块内容对应三条通道，通知/日历默认关闭，用户点了才授权。
 */
import { common } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemeStore } from '../utils/Theme';
import { NotificationService } from '../service/system/NotificationService';
import { CalendarService } from '../service/system/CalendarService';
import { PermissionEvents } from '../service/system/PermissionEvents';
import { PrivacyConsent } from '../service/system/PrivacyConsent';
import { WindowInsets } from '../utils/WindowInsets';
import { M3Switch } from '../components/M3Switch';
import { PrivacyPolicyText } from '../components/PrivacyPolicyText';
import { RelayApi } from '../service/backend/RelayApi';
import { apiErrorMessage } from '../service/backend/BackendTypes';
import { BackendConfig } from '../service/backend/BackendConfig';

const DOMAIN: number = 0x0000;
const TAG: string = 'Onboarding';
/** QQ 官方「创建机器人」链接（浏览器直接打开会跳转失败，需在 QQ 内打开） */
const BOT_CREATE_URL: string = 'https://q.qq.com/qqbot/openclaw/login.html';

@ComponentV2
export struct A_Onboarding {
  @Event onFinish: () => void = () => {
  };
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 两条可选通道默认关闭：不点就不申请权限 */
  @Local notifyOn: boolean = false;
  @Local calendarOn: boolean = false;
  @Local busy: boolean = false;
  /**
   * 当前页（2026-10-29 需求方：首次启动内容太多，拆成两页 + ←→ 分页器）：
   *  0 = 数据边界 + 同意隐私政策；1 = 可选权限（通知 / 日历）与后续配置说明。
   * 必须先在 0 页同意，才能翻到 1 页申请权限。
   */
  @Local page: number = 0;
  /** 是否正在全屏查看《隐私政策》（就地用 contentCover 打开，不离开引导流程） */
  @Local privacyShown: boolean = false;
  /** 第 3 页：QQ Bot 绑定状态（与设置页共用 BackendConfig） */
  @Local bound: boolean = false;
  @Local boundAppId: string = '';
  @Local byobAppId: string = '';
  @Local byobSecret: string = '';
  @Local byobBusy: boolean = false;
  @Local byobError: string = '';
  /** 状态栏让位：全屏窗口下引导页要自己避开通知栏 */
  @Local statusBarVp: number = 0;

  aboutToAppear(): void {
    this.bound = BackendConfig.bound;
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

  /**
   * 打开《隐私政策》：用 `bindContentCover` 就地全屏展示。
   * 不能走路由 push —— 引导是全屏覆盖层，push 出来的页面会被盖住，看起来像「点了没反应」。
   */
  private openPrivacyPolicy(): void {
    this.privacyShown = true;
  }

  /**
   * 点「开始使用」：**先落隐私授权**再通知宿主收起引导。
   *
    * 合规要点：点第 1 页「同意」时已经落盘 `privacy_consent = true`（见 `persistConsent`）；
    * 这里再写一次是幂等兜底。
    */
  private async finish(): Promise<void> {
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx !== undefined) {
      await PrivacyConsent.setGranted(ctx, true);
    }
    this.onFinish();
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
      // 设置页可能已在后台挂载：通知它重新查权限
      PermissionEvents.notifyChanged();
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
      PermissionEvents.notifyChanged();
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  /** 能不能翻到下一页：所有页都可前进（第 1 页点「同意」本身就是授权动作） */
  private canGoNext(): boolean {
    return true;
  }

  /** 「同意 / 继续 / 开始」：翻到下一页；最后一页才真正结束引导 */
  private goNext(): void {
    if (!this.canGoNext()) {
      return;
    }
    if (this.page < 2) {
      // 第 1 页点「同意」时就把隐私授权落盘，后面第 3 页的绑定接口才能正常工作
      if (this.page === 0) {
        this.persistConsent();
      }
      // 只靠页面容器的 transition 播放转场；
      // **不能**把状态变更包进 animateTo —— 那会把新页里的开关也纳入属性动画，
      // 导致轨道颜色从深到浅过渡（2026-10-29 需求方）。
      this.page = this.page + 1;
      return;
    }
    this.finish();
  }

  /** 页 1 点「同意」即落盘（finish 里还会再写一次，幂等） */
  private persistConsent(): void {
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx !== undefined) {
      PrivacyConsent.setGranted(ctx, true);
    }
  }

  private goPrev(): void {
    if (this.page > 0) {
      this.page = this.page - 1;
    }
  }

  /** 「取消」：直接退出应用（首次启动还没同意隐私政策，不进入任何业务页面） */
  private exitApp(): void {
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx !== undefined) {
      (ctx as common.UIAbilityContext).terminateSelf();
    }
  }

  /** 复制 QQ 官方「创建机器人」链接（浏览器直接打开会跳转失败，需在 QQ 内打开） */
  private async copyBotCreateLink(): Promise<void> {
    try {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, BOT_CREATE_URL);
      await pasteboard.getSystemPasteboard().setData(data);
      this.toast('链接已复制，请到 QQ 里粘贴打开');
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'copy bot create link failed: %{public}s', err.message);
      this.toast('复制失败：' + err.message);
    }
  }

  /** BYOB：把用户自建 Bot 的 AppID / AppSecret 交给后端托管 */
  private async submitByob(): Promise<void> {
    if (this.byobBusy) {
      return;
    }
    const appId: string = this.byobAppId.trim();
    const secret: string = this.byobSecret.trim();
    if (!/^\d{5,20}$/.test(appId)) {
      this.byobError = 'AppID 应为 5–20 位数字';
      return;
    }
    if (secret.length < 8) {
      this.byobError = 'AppSecret 长度不正确';
      return;
    }
    this.byobBusy = true;
    this.byobError = '';
    const res = await RelayApi.registerTenant(appId, secret);
    if (!res.ok || res.data === undefined) {
      this.byobError = apiErrorMessage(res);
      this.byobBusy = false;
      return;
    }
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx !== undefined) {
      BackendConfig.setBound(ctx, true);
    }
    this.bound = true;
    this.boundAppId = appId;
    this.byobBusy = false;
    this.byobSecret = '';
    const nickname: string = res.data.bot_nickname !== undefined && res.data.bot_nickname.length > 0
      ? res.data.bot_nickname : appId;
    this.toast('绑定成功，现在把消息转发给「' + nickname + '」');
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

      // 开关统一走 M3Switch（裸 Toggle 会用系统蓝，不跟主题色）
      M3Switch({
        isOn: this.notifyOn,
        onToggle: (next: boolean) => {
          this.toggleNotify(next);
        }
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

      // 同上：M3Switch，跟随主题色
      M3Switch({
        isOn: this.calendarOn,
        onToggle: (next: boolean) => {
          this.toggleCalendar(next);
        }
      })
    }
    .width('100%')
    .padding(14)
    .alignItems(VerticalAlign.Center)
  }

  private pageTitle(): string {
    if (this.page === 0) {
      return '欢迎使用知了';
    }
    if (this.page === 1) {
      return '按需开启权限';
    }
    return '绑定 QQ Bot';
  }

  private pageSubtitle(): string {
    if (this.page === 0) {
      return '先了解数据边界并同意隐私政策，再决定是否开启可选权限';
    }
    if (this.page === 1) {
      return '可开启通知和日历权限。当有新的待办生成时，让知了及时通知你，并帮忙写进日历';
    }
    return '把重要群消息、截图或文件转发给 Bot，可将事项自动总结收进 APP，无需手动添加 ';
  }

  @Builder
  pageDots() {
    // 当前页圆点用主题主色（深色），另一页用浅色轨道色
    Row({ space: 6 }) {
      Column()
        .width(this.page === 0 ? 18 : 8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.page === 0
          ? this.themeStore.scheme.primary
          : this.themeStore.scheme.outlineVariant)
        .animation({ duration: 160, curve: Curve.EaseOut })
      Column()
        .width(this.page === 1 ? 18 : 8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.page === 1
          ? this.themeStore.scheme.primary
          : this.themeStore.scheme.outlineVariant)
        .animation({ duration: 160, curve: Curve.EaseOut })
      Column()
        .width(this.page === 2 ? 18 : 8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.page === 2
          ? this.themeStore.scheme.primary
          : this.themeStore.scheme.outlineVariant)
        .animation({ duration: 160, curve: Curve.EaseOut })
    }
  }

  /** 全屏政策正文（带返回按钮），用于首次启动时就地阅读 */
  @Builder
  privacyCover() {
    Column() {
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(20)
            .fontColor([this.themeStore.scheme.onSurface])
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .accessibilityText('返回')
        .onClick(() => {
          this.privacyShown = false;
        })

        Text('隐私政策')
          .fontSize($r('sys.float.titlebar_title_primary_size'))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)

        // 右侧留白，让标题视觉居中（与左侧返回键同宽）
        Row().width(40).height(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 12 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 4 }) {
            Text('生效日期：2026 年 10 月 27 日')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width('100%')
            Text('更新日期：2026 年 10 月 29 日    版本：v1.1')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          PrivacyPolicyText()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, bottom: 32 })
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.statusBarVp })
    .backgroundColor(this.themeStore.scheme.surface)
  }

  build() {
    Column() {
      Column({ space: 8 }) {
        Text(this.pageTitle())
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
        Text(this.pageSubtitle())
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 8, bottom: 16 })

      if (this.page === 0) {
        // ── 第 1 页：中间 logo，底部数据边界 + 隐私政策同意 ──
        // 不走 Scroll：logo 用 layoutWeight 吃掉中间空间，两张卡片自然贴底
        Column() {
          // 中间 logo：吃掉剩余空间并居中
          Column() {
            Column() {
              // 图片自带较大透明留白，所以画布比底板略大，让中间的 Z 看起来更饱满。
              // 图片里白色 Z 的视觉重心比画布中心略偏右/上，补一个小位移把它摆正。
              Image($r('app.media.foreground'))
                .width(110)
                .height(110)
                .objectFit(ImageFit.Contain)
                .translate({ x: 1, y: -2 })
            }
            .width(100)
            .height(100)
            .borderRadius(22)
            .backgroundColor(this.themeStore.scheme.primary)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .shadow({ radius: 10, color: '#22000000', offsetY: 4 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column({ space: 12 }) {
            Column({ space: 6 }) {
              Text('数据边界')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Text('APP 中的任务、备注、原文、草稿只存在本机。开启云端同步后，只会发送设备标识、绑定关系与反馈计数，'
                + '任务内容不会上传到服务器')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .width('100%')
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
            .borderRadius(14)

            // 隐私政策同意：点下方「同意」即视为同意，不再单独放勾选框（与同意按钮语义重复）。
            // 随时可以在「设置 → 关于 → 隐私说明」的独立页面里撤回。
            // 撤回后 AI 与云端能力停用，本机基础功能（手动增删改、提醒、通知、日历、导入导出）照常。
            Column({ space: 8 }) {
              Text() {
                Span('点击下方「同意」即表示你已阅读并同意')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                Span('《隐私政策》')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor(this.themeStore.scheme.primary)
                  .onClick(() => {
                    this.openPrivacyPolicy();
                  })
                Span(
                  '，同意使用云端同步与 AI 解析相关功能')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
            .borderRadius(14)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .transition(TransitionEffect.OPACITY
          .combine(TransitionEffect.scale({ x: 0.98, y: 0.98 }))
          .animation({ duration: 220, curve: Curve.FastOutSlowIn }))
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.page === 1) {
              // ── 第 2 页：可选权限（通知 / 日历） ──
              Column({ space: 12 }) {
                Column() {
                  Text('可选通道（默认关闭）')
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    .width('100%')
                    .padding({
                      left: 14,
                      right: 14,
                      top: 12,
                      bottom: 4
                    })
                  this.notifyRow()
                  Divider()
                  this.calendarRow()
                }
                .width('100%')
                .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
                .borderRadius(14)

              }
              .width('100%')
              .transition(TransitionEffect.OPACITY
                .combine(TransitionEffect.scale({ x: 0.98, y: 0.98 }))
                .animation({ duration: 220, curve: Curve.FastOutSlowIn }))
            } else {
              // ── 第 3 页：绑定 QQ Bot（可绑定，也可直接开始跳过） ──
              Column({ space: 12 }) {


                // 转发内容的数据处理说明：只在绑定/使用 Bot 的场景下出现，不占用第 1 页
                Column({ space: 6 }) {
                  Text('关于转发内容')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  Text('在 QQ 把文字、截图或文件转发给 Bot 后，内容会在服务器内存中短暂中转（最长 30 分钟）'
                    + '用于 AI 总结信息，并生成待你确认的待办。')
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }
                .width('100%')
                .padding(14)
                .alignItems(HorizontalAlign.Start)
                .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
                .borderRadius(14)

                Column({ space: 10 }) {
                  Text('绑定 QQ Bot')
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .width('100%')

                  if (this.bound) {
                    Row({ space: 6 }) {
                      SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                        .fontSize(18)
                        .fontColor([this.themeStore.scheme.primary])
                      Text(this.boundAppId.length > 0 ? '已绑定 Bot：' + this.boundAppId : '已绑定 Bot')
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .fontColor($r('sys.color.ohos_id_color_text_primary'))
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                  } else {
                    Text('1. 先创建一个 QQ 机器人')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .width('100%')
                    Text('点按钮复制创建链接，然后到 QQ 里粘贴打开')
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                      .width('100%')
                    Text(BOT_CREATE_URL)
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .fontColor(this.themeStore.scheme.primary)
                      .copyOption(CopyOptions.LocalDevice)
                      .width('100%')
                    Button({ type: ButtonType.Capsule, stateEffect: true }) {
                      Text('复制创建链接')
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .fontColor(this.themeStore.scheme.primary)
                    }
                    .height(36)
                    .padding({ left: 16, right: 16 })
                    .backgroundColor(Color.Transparent)
                    .border({ width: 1, color: this.themeStore.scheme.outline })
                    .borderRadius(18)
                    .onClick(() => {
                      this.copyBotCreateLink();
                    })

                    Text('2. 填入机器人凭据')
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .fontColor($r('sys.color.ohos_id_color_text_primary'))
                      .width('100%')
                      .margin({ top: 4 })
                    TextInput({ text: this.byobAppId, placeholder: 'AppID（机器人 ID）' })
                      .height(44)
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .padding({ left: 12, right: 12 })
                      .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
                      .borderRadius(12)
                      .maxLength(20)
                      .onChange((value: string) => {
                        this.byobAppId = value;
                        this.byobError = '';
                      })
                    TextInput({ text: this.byobSecret, placeholder: 'AppSecret' })
                      .height(44)
                      .fontSize($r('sys.float.ohos_id_text_size_body1'))
                      .padding({ left: 12, right: 12 })
                      .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
                      .borderRadius(12)
                      .type(InputType.Password)
                      .maxLength(128)
                      .onChange((value: string) => {
                        this.byobSecret = value;
                        this.byobError = '';
                      })

                    if (this.byobError.length > 0) {
                      Text(this.byobError)
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .fontColor($r('sys.color.ohos_id_color_warning'))
                        .width('100%')
                    }

                    Button({ type: ButtonType.Capsule, stateEffect: true }) {
                      Text(this.byobBusy ? '绑定中…' : '绑定')
                        .fontSize($r('sys.float.ohos_id_text_size_body2'))
                        .fontColor(this.themeStore.scheme.onPrimary)
                    }
                    .width('100%')
                    .height(36)
                    .backgroundColor(this.themeStore.scheme.primary)
                    .borderRadius(18)
                    .enabled(!this.byobBusy)
                    .onClick(() => {
                      this.submitByob();
                    })
                  }

                }
                .width('100%')
                .padding(14)
                .alignItems(HorizontalAlign.Start)
                .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
                .borderRadius(14)
              }
              .width('100%')
              .transition(TransitionEffect.OPACITY
                .combine(TransitionEffect.scale({ x: 0.98, y: 0.98 }))
                .animation({ duration: 220, curve: Curve.FastOutSlowIn }))
            }
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
      }

      // 页码圆点（←→ 按钮已按需求删除，导航交给下面两个按钮）
      Row() {
        this.pageDots()
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4, bottom: 10 })

      // 第 1 页：取消（退出 App） / 同意（进入第 2 页）
      // 第 2 页：返回（上一页） / 继续（进入第 3 页）
      // 第 3 页：返回（上一页） / 开始（结束引导进入任务列表，不绑 Bot 也可开始）
      Row({ space: 12 }) {
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text(this.page === 0 ? '取消' : '返回')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
        }
        .layoutWeight(1)
        .height(44)
        .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
        .borderRadius(22)
        .onClick(() => {
          if (this.page === 0) {
            this.exitApp();
          } else {
            this.goPrev();
          }
        })

        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text(this.page === 0 ? '同意' : (this.page === 1 ? '继续' : '开始'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.canGoNext()
              ? this.themeStore.scheme.onPrimary
              : $r('sys.color.ohos_id_color_text_secondary'))
        }
        .layoutWeight(1)
        .height(44)
        // 第 1 页未勾选隐私政策时变灰且点不动（合规：先取得同意再处理个人信息）
        .enabled(this.canGoNext())
        .backgroundColor(this.canGoNext()
          ? this.themeStore.scheme.primary
          : this.themeStore.scheme.surfaceContainerHighest)
        .borderRadius(22)
        .onClick(() => {
          this.goNext();
        })
      }
      .width('100%')
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 20,
      right: 20,
      top: this.statusBarVp + 30
    })
    .backgroundColor(this.themeStore.scheme.surface)
    // 隐私政策就地全屏打开：不离开引导流程，返回后勾选状态仍在
    .bindContentCover(this.privacyShown, this.privacyCover(), {
      modalTransition: ModalTransition.DEFAULT,
      onDisappear: () => {
        this.privacyShown = false;
      }
    })
  }
}
