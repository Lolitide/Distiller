/*
 * 设置页（一级页，底部页签第二个）。
 *
 * ## 2026-10-19 第二版重做（作者反馈）
 *
 * 上一版被批「滥用按钮」：密度、提前量、解析方式全铺成一排按钮。
 * 这一版按作者的原话改：
 *   · **主题色** → 三个**颜色圆点**（不写色名）；
 *   · **卡片密度 / 提醒提前量 / 解析方式** → **点一行弹选择器**，不再铺按钮；
 *   · 权限管理补齐 **通知 / 日历 / 订阅消息管理** 三项（先占位，如实标未接入）；
 *   · 修「滑到底看不全」：`Scroll` 加 `contentEndOffset`，最后一项不再被页签栏压住；
 *   · 修「大标题压住内容」：让位段做成内容首项，与任务列表同一套。
 *
 * 取值纪律：颜色/间距/字号来自 `utils/Theme.ets` 或官方语义 token。
 */
import { common } from '@kit.AbilityKit';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import {
  ACCENT_OPTIONS,
  AccentOption,
  DENSITY_COMPACT,
  DENSITY_STANDARD,
  Theme,
  ThemeStore
} from '../utils/Theme';
import {
  DEFAULT_REMIND_LEAD,
  SettingsRepository
} from '../repository/SettingsRepository';
import { OptionPickerBody } from '../components/OptionPickerBody';
import { SettingsNavRow } from '../components/SettingsNavRow';
import { PopupSelector } from '../components/PopupSelector';
import { ToggleSlider } from '../components/ToggleSlider';
// 开关统一走 M3 取色的组件（`Toggle` 默认取系统蓝，见 M3Switch 顶部注释）
import { M3Switch } from '../components/M3Switch';
import { Task } from '../model';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { TaskExportViewModel } from '../viewmodel/TaskExportViewModel';
import { TaskExportResult, TaskExportService } from '../service/system/TaskExportService';
import { WindowInsets } from '../utils/WindowInsets';
import { BackendConfig } from '../service/backend/BackendConfig';
import { RelayApi } from '../service/backend/RelayApi';
import { apiErrorMessage, GroupItemDto } from '../service/backend/BackendTypes';
import { SyncService } from '../service/cloud/SyncService';
import { NotificationService } from '../service/system/NotificationService';
import { PermissionEvents } from '../service/system/PermissionEvents';
import { TaskRepository } from '../repository/TaskRepository';
import { notificationManager } from '@kit.NotificationKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Settings';

/** 行高（vp） */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 左列标签宽度（vp） */
const LABEL_WIDTH_VP: number = 108;
/** 分组之间留白（vp） */
const SECTION_GAP_VP: number = 16;
/** 页面左右留白（vp） */
const PAGE_SIDE_PADDING_VP: number = 16;
/**
 * 让开浮层标题栏的高度（vp）：与任务列表同一个来历 —— 把这一段做成**内容首项**，
 * 标题才会跟着滚动收缩；用固定 `padding-top` 的话，滚起来大字会压在内容上（上一版就是这么坏的）。
 */
const TITLE_CLEARANCE_VP: number = 64;
/** 让开悬浮页签栏（vp）：与 `A_TaskList.LIST_BOTTOM_CLEARANCE_VP` 同值 */
const BOTTOM_CLEARANCE_VP: number = 80;

/**
 * 底部渐变遮罩高度（vp）：与 A_TaskList.BOTTOM_MASK_VP 同值同理由 ——
 * 弃用 HdsTabs 后 gradientMask 跟着没了，内容会在视口底边被齐切（2026-10-20 截图下方两个箭头）。
 * 取 100 而不是当时的 140，理由见 `A_TaskList.BOTTOM_MASK_VP`（实色渐变比旧的 40% 遮罩强，140 会洗白最后一项）。
 */
const BOTTOM_MASK_VP: number = 140;
/** 分隔线宽（vp） */
const DIVIDER_WIDTH_VP: number = 0.5;
/** 分组标题内缩 / 与卡片间距（vp） */
const SECTION_TITLE_INSET_VP: number = 4;
const SECTION_TITLE_GAP_VP: number = 8;
/** 主题色圆点直径（vp） */
const ACCENT_DOT_SIZE_VP: number = 28;
/**
 * 主题色选中时，叠加在色板上的「白圈」与色板边缘之间的间距（vp）。
 * 白圈直径 = 色板直径 − 2×本值 → 它比按钮小一圈，色板只剩一道色环。
 */
const ACCENT_SELECT_RING_VP: number = 5;

/** 提醒提前量的可选档（分钟）：0 ＝ 到点提醒 */
const REMIND_LEAD_OPTIONS: number[] = [0, 5, 15, 30, 60];
/** 卡片密度的档位文案 */
const DENSITY_OPTIONS: string[] = ['标准', '紧凑'];

/** 当前打开的选择器（卡片密度已改成页内滑动控件，不再走弹窗） */
const SHEET_NONE: number = 0;
const SHEET_REMIND_LEAD: number = 2;
const SHEET_GROUPS: number = 4;

@ComponentV2
export struct A_Settings {
  /** 任务 store：清空任务 + 提醒提前量同步 */
  @Require @Param store: TaskListStore;

  // 2026-10-25：原来这里还有一个 `@Require @Param scroller: Scroller`，唯一的用途是交给
  // `HdsNavigation.bindToScrollable` 做「大标题随滚动收缩」。三个页签统一改成固定 MINI 标题后
  // 那条绑定已删除、本页也从未读过这个 scroller，于是把它一并去掉（死参数会误导后来的人）。

  /** 视觉个性化状态（跨页共享，见 utils/Theme.ets） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /**
   * 底部遮罩的两端色（`GradientDirection.Bottom`：第一项画在**上**边，所以上透下实）。
   * 与 `A_TaskList.bottomMaskColors` 同一套算法，色相都取当前主题的 `surface`。
   */
  @Computed
  get bottomMaskColors(): Array<[ResourceColor, number]> {
    const surface: string = this.themeStore.scheme.surface;
    const colors: Array<[ResourceColor, number]> = [
      // 与 `A_TaskList.bottomMaskColors` 同一套 6 档色标（理由见那里：胶囊上沿要有 ~55% 遮挡）
      [Theme.withAlpha(surface, '00'), 0.0],
      [Theme.withAlpha(surface, '40'), 0.25],
      [Theme.withAlpha(surface, '8C'), 0.49],
      [Theme.withAlpha(surface, 'CC'), 0.70],
      [Theme.withAlpha(surface, 'EE'), 0.85],
      [Theme.withAlpha(surface, 'FF'), 1.0]
    ];
    return colors;
  }

  /**
   * 状态栏高度（vp）：窗口全屏后页面铺到屏幕顶端，内容要让开这一截（见 utils/WindowInsets）。
   */
  @Local statusBarVp: number = 0;

  @Local remindLead: number = DEFAULT_REMIND_LEAD;

  /* ── 后端连接（2026-10-21 对接 qqbot-backend）── */
  /** 输入框里的服务器地址（保存后才写进 `BackendConfig`） */
  @Local backendUrl: string = '';
  /** 连接状态文案（已连接 / 失败原因） */
  @Local backendState: string = '未连接';
  @Local backendBusy: boolean = false;
  /** 「导出任务」那一行的格式菜单显隐（FE-60） */
  @Local exportMenuShown: boolean = false;
  /** 绑定状态与配对码 */
  @Local bound: boolean = false;
  @Local bindCode: string = '';
  @Local bindHint: string = '';
  /** 配对码已过期：显示「重新生成」而不是继续倒计时 */
  @Local bindExpired: boolean = false;
  /** 配对码剩余秒数（每 2 秒减一次，用于界面倒计时） */
  @Local bindLeftSec: number = 0;
  /** 云端同步开关（关闭即停止轮询） */
  @Local syncEnabled: boolean = true;
  private bindTimer: number = -1;
  /** 本次「去绑定/重新绑定」的开始时间（用于忽略旧 bound_at） */
  private bindStartedAt: number = 0;
  /** 绑定轮询剩余次数（按后端 expires_in 算，过期就停并提示重新生成） */
  private bindPollLeft: number = 0;

  /* ── 权限管理（通知 / 日历 / 订阅消息）── */
  @Local notifyAllowed: boolean = false;
  @Local calendarAllowed: boolean = false;
  /** 已订阅的群数；-1 表示还没查 */
  @Local subscribedCount: number = -1;
  /** 群列表（选择性订阅用；只列机器人真正在的群） */
  @Local groupList: GroupItemDto[] = [];
  @Local groupsLoading: boolean = false;
  /** 不订阅自己发的消息（服务端默认 true） */
  @Local skipSelf: boolean = true;

  /** 当前打开的选择器 */
  @Local sheetKind: number = SHEET_NONE;
  /**
   * 半模态显隐（与 `sheetKind` 分开）。
   * 必须用 `!!` 双向绑定：只传 `sheetKind !== NONE` 这种**表达式**时，
   * 在内容里改状态不会同步回系统 sheet，表现为「点完成、遮罩不消失」。
   */
  @Local sheetShown: boolean = false;
  /** 选择器草稿 */
  @Local remindLeadDraft: number = DEFAULT_REMIND_LEAD;

  aboutToAppear(): void {
    this.loadSettings();
    this.loadBackend();
    this.loadPermissions();
    this.loadSyncEnabled();
    // 引导页里授权通知/日历后，这里没有重新走生命周期，靠广播刷新
    PermissionEvents.setListener(() => {
      this.loadPermissions();
    });
    // 窗口全屏后页面铺到屏幕顶端，顶部让位要补上状态栏高度（见 utils/WindowInsets）
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      WindowInsets.topPx(context).then((px: number) => {
        this.statusBarVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
      });
    }
  }

  aboutToDisappear(): void {
    PermissionEvents.clearListener();
  }

  /* ── 权限管理 ── */

  /**
   * 读三项状态。
   *
   * ⚠️ 拆成三个独立方法，是因为「同步订阅」只需要刷新订阅数：
   * 之前它调整个 `loadPermissions()`，会把日历权限重新查一遍；
   * 而 `checkAccessToken` 只要失败一次就把 `calendarAllowed` 写成 false，
   * 于是出现「点同步按钮，日历权限从已授权掉回未授权」。
   * 现在的原则：**查询失败不改变已有状态**（网络/上下文异常 ≠ 权限被收回）。
   */
  private async loadPermissions(): Promise<void> {
    await this.loadNotifyPermission();
    await this.loadCalendarPermission();
    await this.loadSubscriptionCount();
  }

  private async loadNotifyPermission(): Promise<void> {
    try {
      this.notifyAllowed = await notificationManager.isNotificationEnabled();
    } catch (error) {
      // 读不到保持原值，不擅自改判
    }
  }

  /**
   * 查日历写权限。
   *
   * ⚠️ `checkAccessTokenSync` 的第一个参数是 **accessTokenId**，不是 uid
   * （拿 uid 去查永远返回 DENIED —— 这就是"授权了还显示未授权"的根因）。
   * accessTokenId 由 `bundleManager.getBundleInfoForSelfSync().appInfo` 取。
   */
  private async loadCalendarPermission(): Promise<void> {
    try {
      const flags: number = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
      const info = bundleManager.getBundleInfoForSelfSync(flags);
      const at = abilityAccessCtrl.createAtManager();
      // 用异步 checkAccessToken：同步版在本机实测会把已授权的日历读成 DENIED
      const status: abilityAccessCtrl.GrantStatus =
        await at.checkAccessToken(info.appInfo.accessTokenId, 'ohos.permission.WRITE_CALENDAR');
      this.calendarAllowed = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'check calendar permission failed: %{public}s', err.message);
      // 查不到就保持当前显示（不把已授权误刷成未授权）
    }
  }

  private async loadSubscriptionCount(): Promise<void> {
    const groups = await RelayApi.groups();
    if (groups.ok && groups.data !== undefined) {
      let count: number = 0;
      for (let i = 0; i < groups.data.groups.length; i++) {
        if (groups.data.groups[i].subscribed) {
          count++;
        }
      }
      this.subscribedCount = count;
    } else {
      this.subscribedCount = -1;
    }
  }

  /** 读设备偏好（目前只有「不订阅自己的消息」，默认 true） */
  private async loadPrefs(): Promise<void> {
    if (!SyncService.hasIdentity()) {
      this.skipSelf = true;
      return;
    }
    const res = await RelayApi.myData();
    if (res.ok && res.data !== undefined && res.data.skip_self !== undefined) {
      this.skipSelf = res.data.skip_self;
    }
  }

  /** 开关「不订阅自己的消息」：先乐观更新，失败再回滚 */
  private async setSkipSelf(on: boolean): Promise<void> {
    this.skipSelf = on;
    const res = await RelayApi.setPrefs(on);
    if (!res.ok) {
      this.skipSelf = !on;
      this.toast('保存失败：' + apiErrorMessage(res));
    }
  }

  /** 打开「选择订阅的群」：拉 `/groups`，只列机器人真正在的群 */
  private async openGroupSheet(): Promise<void> {
    if (!this.bound) {
      this.toast('请先绑定 QQ');
      return;
    }
    this.sheetKind = SHEET_GROUPS;
    this.sheetShown = true;
    this.groupsLoading = true;
    const res = await RelayApi.groups();
    this.groupsLoading = false;
    if (!res.ok || res.data === undefined) {
      this.groupList = [];
      this.toast('加载群列表失败：' + apiErrorMessage(res));
      return;
    }
    const visible: GroupItemDto[] = [];
    for (let i = 0; i < res.data.groups.length; i++) {
      if (res.data.groups[i].bot_present) {
        visible.push(res.data.groups[i]);
      }
    }
    this.groupList = visible;
  }

  /** 勾/取消某个群的订阅（立刻打接口，失败回滚这一行） */
  private async toggleGroup(g: GroupItemDto, on: boolean): Promise<void> {
    const res = on
      ? await RelayApi.subscribe(g.group_openid)
      : await RelayApi.unsubscribe(g.group_openid);
    if (!res.ok) {
      this.toast('操作失败：' + apiErrorMessage(res));
      // 回滚：把这一行换回原状态（整数组换新，确保 Toggle 刷新）
      const rollback: GroupItemDto[] = [];
      for (let i = 0; i < this.groupList.length; i++) {
        rollback.push(this.groupList[i]);
      }
      this.groupList = rollback;
      return;
    }
    const next: GroupItemDto[] = [];
    for (let i = 0; i < this.groupList.length; i++) {
      const item: GroupItemDto = this.groupList[i];
      if (item.group_openid !== g.group_openid) {
        next.push(item);
        continue;
      }
      next.push({
        group_openid: item.group_openid,
        label: item.label,
        message_count: item.message_count,
        last_message_at: item.last_message_at,
        has_name: item.has_name,
        subscribed: on,
        bot_present: item.bot_present
      });
    }
    this.groupList = next;
    await this.loadSubscriptionCount();
  }

  /** 点「去开启」：弹出系统通知授权框（用户拒绝时保持未授权，不重复骚扰） */
  private async requestNotifyPermission(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    try {
      await notificationManager.requestEnableNotification(context as common.UIAbilityContext);
      this.notifyAllowed = await notificationManager.isNotificationEnabled();
      this.toast(this.notifyAllowed ? '通知已开启' : '未获得通知权限，可到系统设置里开启');
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'requestEnableNotification failed: %{public}s', err.message);
      this.toast('打开通知授权失败，请到系统设置里开启');
    }
  }

  /** 点「去授权」：申请日历读写权限（user_grant，系统弹框） */
  private async requestCalendarPermission(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    try {
      const permissionList: Permissions[] = [
        'ohos.permission.READ_CALENDAR',
        'ohos.permission.WRITE_CALENDAR'
      ];
      const at = abilityAccessCtrl.createAtManager();
      const result = await at.requestPermissionsFromUser(context, permissionList);
      // authResults 与 permissionList 同序：用 **写日历**（下标 1）判断，别再取 [0]（那是读）
      const granted: boolean = result.authResults.length > 1
        && result.authResults[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      this.calendarAllowed = granted;
      // 授权结果以 authResults 为准：不要紧接着再查一次，
      // 系统落权限有延迟，立刻查可能还是 DENIED，会把刚显示的"已授权"刷回去。
      this.toast(granted ? '日历权限已开启' : '未获得日历权限，写日历会失败');
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'requestPermissionsFromUser failed: %{public}s', err.message);
      this.toast('申请日历权限失败：' + err.message);
    }
  }

  /** 订阅消息：把"可订阅但还没订阅"的群补上（等同于 QQ 群里加了新群后自动纳入） */
  private async syncSubscriptions(): Promise<void> {
    if (!this.bound) {
      this.toast('请先绑定 QQ');
      return;
    }
    const added: number = await SyncService.ensureSubscribed(true);
    await SyncService.syncOnce();
    // 只刷新订阅数：**不要**顺手重查通知/日历权限（那会把已授权状态误刷成未授权）
    await this.loadSubscriptionCount();
    this.toast(added > 0 ? '已订阅 ' + added + ' 个群' : '订阅已是最新');
  }

  /** 读服务器地址 + 探测连接 + 查绑定状态 */
  private async loadBackend(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    BackendConfig.init(context);
    this.backendUrl = BackendConfig.baseUrl;
    // 先用本地缓存，网络回来后再以接口为准 —— 避免"切出去切回来就显示未绑定"
    this.bound = BackendConfig.bound;
    await this.refreshConnection(false);
    await this.loadPrefs();
  }

  /**
   * 探测连接并刷新绑定状态。
   * @param showBusy 是否显示"连接中"（点按钮时 true，进页面时 false）
   */
  private async refreshConnection(showBusy: boolean): Promise<boolean> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return false;
    }
    if (showBusy) {
      this.backendBusy = true;
      this.backendState = '正在连接…';
    }
    if (BackendConfig.baseUrl.length === 0) {
      this.backendState = '未配置服务器地址';
      this.backendBusy = false;
      return false;
    }
    const health = await RelayApi.health();
    if (!health.ok || health.data === undefined) {
      this.backendState = '未连接：' + apiErrorMessage(health);
      this.backendBusy = false;
      return false;
    }
    const hd = health.data;
    this.backendState = '已连接 · ' + hd.version
      + (hd.api_version !== undefined ? ' · v' + hd.api_version : '');

    // 有设备身份才能查绑定；没有就顺手注册一个
    await SyncService.ensureDevice();
    const status = await RelayApi.bindStatus();
    if (status.ok && status.data !== undefined) {
      this.bound = status.data.bound;
      BackendConfig.setBound(context, this.bound);
    }
    // status 失败时保持本地缓存值（网络抖动不等于解绑）

    this.backendBusy = false;
    return true;
  }

  /**
   * 「连接」按钮：保存地址 + 立刻尝试连接。
   *
   * 只有**地址变了**才清设备身份（旧 token 不能拿去打新服务器，且旧服务器的绑定对新服务器无意义）；
   * 地址没变时保留身份与绑定状态 —— 这是"重连后显示未绑定"的根因。
   */
  private async connectServer(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    const oldUrl: string = BackendConfig.baseUrl;
    const next: string = this.backendUrl.trim().replace(/\/+$/, '');
    if (next.length === 0) {
      this.toast('请先填写服务器地址');
      return;
    }
    BackendConfig.setBaseUrl(context, next);
    this.backendUrl = BackendConfig.baseUrl;
    const changed: boolean = oldUrl !== BackendConfig.baseUrl;
    if (changed) {
      BackendConfig.clearIdentity(context, true);
      this.bound = false;
      SyncService.stop();
    }

    const ok: boolean = await this.refreshConnection(true);
    if (!ok) {
      this.toast('连接失败，请检查地址与后端是否已启动');
      return;
    }
    await SyncService.syncOnce();
    SyncService.start();
    this.toast('已连接：' + BackendConfig.baseUrl);
  }

  /** 生成配对码并开始轮询绑定结果（2 秒 × 60 次） */
  private async startBind(): Promise<void> {
    if (this.bindCode.length > 0) {
      return;
    }
    // 重新绑定**不动旧绑定**：只记下开始时间，轮询时用 bound_at 判断是不是这次新绑的。
    // 这样用户点取消，原来的绑定仍然有效。
    this.bindStartedAt = Date.now();
    const res = await RelayApi.bindCode();
    if (!res.ok || res.data === undefined) {
      this.toast('生成配对码失败：' + (res.ok ? '返回为空' : apiErrorMessage(res)));
      return;
    }
    this.bindCode = res.data.code;
    this.bindHint = res.data.hint;
    this.bindExpired = false;
    this.bindLeftSec = res.data.expires_in;
    this.bindPollLeft = Math.max(1, Math.ceil(res.data.expires_in / 2));
    this.bindTimer = setInterval(() => {
      if (this.bindPollLeft <= 0) {
        this.cancelBind();
        this.bindCode = '';
        this.bindExpired = true;
        this.bindLeftSec = 0;
        this.toast('配对码已过期，请重新生成');
        return;
      }
      this.bindPollLeft--;
      this.bindLeftSec = Math.max(0, this.bindLeftSec - 2);
      this.checkBind();
    }, 2000);
  }

  private async checkBind(): Promise<void> {
    const res = await RelayApi.bindStatus();
    if (!res.ok || res.data === undefined || !res.data.bound) {
      return;
    }
    // 旧绑定也会返回 bound=true：必须拿到「本次开始之后」的绑定时刻才算成功；
    // 拿不到时刻（旧数据/解析失败）一律忽略，避免一生成码就自动成功。
    const boundAt: number = res.data.bound_at_ms !== undefined
      ? res.data.bound_at_ms : this.parseBoundAt(res.data.bound_at);
    if (boundAt <= 0 || boundAt < this.bindStartedAt - 2000) {
      return;
    }
    this.bound = true;
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx !== undefined) {
      BackendConfig.setBound(ctx, true);
    }
    this.bindCode = '';
    this.bindLeftSec = 0;
    this.bindExpired = false;
    if (this.bindTimer >= 0) {
      clearInterval(this.bindTimer);
      this.bindTimer = -1;
    }
    this.toast('绑定成功，正在同步群消息');
    await this.autoSubscribeAll();
    await SyncService.refreshAfterBind();
  }

  /**
   * 绑定成功后：默认订阅机器人所在的所有群，并弹出群选择列表（全部勾选）。
   * 用户可以在这里取消不想订阅的群；订阅失败不影响绑定本身。
   */
  private async autoSubscribeAll(): Promise<void> {
    const first = await RelayApi.groups();
    if (!first.ok || first.data === undefined) {
      return;
    }
    const visible: GroupItemDto[] = [];
    for (let i = 0; i < first.data.groups.length; i++) {
      const g: GroupItemDto = first.data.groups[i];
      if (!g.bot_present) {
        continue;
      }
      visible.push(g);
      if (!g.subscribed) {
        await RelayApi.subscribe(g.group_openid);
      }
    }
    if (visible.length === 0) {
      this.toast('机器人还没加入任何群，先在 QQ 群里把它拉进去');
      return;
    }
    // 重新拉一次，让开关显示后端真实状态（全部已订阅）
    const second = await RelayApi.groups();
    if (second.ok && second.data !== undefined) {
      const fresh: GroupItemDto[] = [];
      for (let i = 0; i < second.data.groups.length; i++) {
        if (second.data.groups[i].bot_present) {
          fresh.push(second.data.groups[i]);
        }
      }
      this.groupList = fresh;
    } else {
      this.groupList = visible;
    }
    this.refreshSubscribedCount();
    this.sheetKind = SHEET_GROUPS;
    this.sheetShown = true;
  }

  /** 从当前 groupList 统计已订阅数，更新「订阅消息管理」行 */
  private refreshSubscribedCount(): void {
    let count: number = 0;
    for (let i = 0; i < this.groupList.length; i++) {
      if (this.groupList[i].subscribed) {
        count++;
      }
    }
    this.subscribedCount = count;
  }

  /** 后端 `bound_at` 是本地时间字符串 `YYYY-MM-DD HH:mm:ss`；解析失败返回 0（按旧逻辑处理） */
  private parseBoundAt(text: string | undefined): number {
    if (text === undefined || text.length === 0) {
      return 0;
    }
    const ms: number = Date.parse(text.replace(' ', 'T'));
    return Number.isNaN(ms) ? 0 : ms;
  }

  private cancelBind(): void {
    this.bindCode = '';
    this.bindLeftSec = 0;
    if (this.bindTimer >= 0) {
      clearInterval(this.bindTimer);
      this.bindTimer = -1;
    }
    // 取消重新绑定：旧绑定没有被解掉，保持原来的状态
  }

  /** 复制配对码到剪贴板（用户要粘贴到 QQ 私聊里发给机器人） */
  private async copyBindCode(): Promise<void> {
    if (this.bindCode.length === 0) {
      return;
    }
    try {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.bindCode);
      await pasteboard.getSystemPasteboard().setData(data);
      this.toast('配对码已复制');
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'copy bind code failed: %{public}s', err.message);
      this.toast('复制失败：' + err.message);
    }
  }

  /** 打开系统通知管理（横幅/锁屏/声音都在这里） */
  private openNotificationSettings(): void {
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx === undefined) {
      return;
    }
    NotificationService.openSettings(ctx as common.UIAbilityContext);
  }

  private replayOnboarding(): void {
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx === undefined) {
      return;
    }
    SettingsRepository.setFirstLaunchDone(ctx, false);
    this.toast('下次启动会显示启动引导');
  }

  private async loadSyncEnabled(): Promise<void> {    const ctx: common.Context | undefined = this.hostContext();
    if (ctx === undefined) {
      return;
    }
    this.syncEnabled = await SettingsRepository.getSyncEnabled(ctx, true);
  }

  private onSyncToggle(isOn: boolean): void {
    this.syncEnabled = isOn;
    const ctx: common.Context | undefined = this.hostContext();
    if (ctx === undefined) {
      return;
    }
    SettingsRepository.setSyncEnabled(ctx, isOn);
    SyncService.setEnabled(isOn);
    this.toast(isOn ? '云端同步已开启' : '云端同步已关闭，不再拉取群消息');
  }

  /** 云端字段清单：与隐私说明同一口径，不把「本机数据」混进来 */
  private showCloudFields(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '会离开手机的字段',
      message: '同步开启时，App 会向你的服务器发送：设备标识、绑定关系、群订阅、'
        + '采纳/忽略反馈计数、Push 令牌（未接入则没有）。'
        + '\n\n服务器只临时保存群消息原文（内存 30 分钟，不落盘）。'
        + '\n\n任务名称、备注、原文、草稿、画像只存在本机；原文不会回传。',
      buttons: [{ text: '知道了', color: this.themeStore.scheme.primary }]
    });
  }

  /** 隐私说明：只讲本机存什么、什么会离开手机 */
  private showPrivacy(): void {    this.getUIContext().getPromptAction().showDialog({
      title: '隐私说明',
      message: '任务、备注、原文、草稿只存在本机。'
        + '同步开启时只向服务器发送设备标识、绑定关系、群订阅与采纳/忽略计数。'
        + '群消息原文由服务器临时保留 30 分钟（仅内存、不落盘），不会回传。'
        + '可随时在「删除服务端数据」中清空云端记录。',
      buttons: [{ text: '知道了', color: this.themeStore.scheme.primary }]
    });
  }
  private deleteServerData(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '删除服务端数据',
      message: '会删除这台设备在服务端的绑定、订阅与推送令牌，并清空本机任务。确定吗？',
      buttons: [
        { text: $r('app.string.action_cancel'), color: $r('sys.color.ohos_id_color_text_primary') },
        { text: $r('app.string.action_delete'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then(async (result) => {
      if (result.index !== 1) {
        return;
      }
      const context: common.Context | undefined = this.hostContext();
      if (context === undefined) {
        return;
      }
      await RelayApi.deleteMyData();
      BackendConfig.clearIdentity(context, true);
      BackendConfig.setBound(context, false);
      TaskRepository.clear(context);
      SyncService.stop();
      this.store.init(context);
      this.bound = false;
      this.backendState = '已清空，可重新绑定';
      this.toast('已删除');
    });
  }

  private hostContext(): common.Context | undefined {
    return this.getUIContext().getHostContext();
  }

  private async loadSettings(): Promise<void> {
    const context: common.Context | undefined = this.hostContext();
    if (context === undefined) {
      return;
    }
    this.remindLead = await SettingsRepository.getRemindLead(context);
    this.store.remindLeadMinutes = this.remindLead;
    // 视觉效果持久化（2026-10-19）：主题色与卡片密度重启后要记住
    this.themeStore.accentIndex = await SettingsRepository.getThemeAccent(context, this.themeStore.accentIndex);
    this.themeStore.density = await SettingsRepository.getDensity(context, this.themeStore.density);
  }

  /* ── 文案 ── */

  /** 提醒提前量的文案数组（PopupSelector 要整组文案） */
  @Computed
  get remindLeadOptionLabels(): string[] {
    return REMIND_LEAD_OPTIONS.map((minutes: number) => this.remindLeadLabel(minutes));
  }

  private remindLeadLabel(minutes: number): string {
    if (minutes === 0) {
      return '到点提醒';
    }
    if (minutes === 60) {
      return '提前 1 小时';
    }
    return `提前 ${minutes} 分钟`;
  }

  /** 版本号从安装包读，不写死 */
  @Computed
  get versionLabel(): string {
    try {
      const info: bundleManager.BundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      return info.versionName === undefined ? '—' : info.versionName;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'read version failed: %{public}s', err.message);
      return '—';
    }
  }

  /* ── 写入 ── */

  private applyRemindLead(minutes: number): void {
    this.remindLead = minutes;
    // 同步给 store：列表铃铛按它算 remindAt（页签切换不会重跑 aboutToAppear，必须直接写）
    this.store.remindLeadMinutes = minutes;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setRemindLead(context, minutes);
    }
  }

  /** 切换主题色：先改内存（界面立刻变色），再异步落盘 */
  private applyAccent(index: number): void {
    this.themeStore.accentIndex = index;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setThemeAccent(context, index);
    }
  }

  /** 切换卡片密度：同上 */
  private applyDensity(index: number): void {
    this.themeStore.density = index;
    const context: common.Context | undefined = this.hostContext();
    if (context !== undefined) {
      SettingsRepository.setDensity(context, index);
    }
  }

  /* ── 选择器 ── */

  private openSheet(kind: number): void {
    if (kind === SHEET_REMIND_LEAD) {
      const index: number = REMIND_LEAD_OPTIONS.indexOf(this.remindLead);
      this.remindLeadDraft = index < 0 ? 0 : index;
    }
    this.sheetKind = kind;
    this.sheetShown = true;
  }

  private closeSheet(): void {
    // 群列表关闭时刷新「订阅消息管理」的计数（一键订阅/勾选后都走这里）
    if (this.sheetKind === SHEET_GROUPS) {
      this.loadSubscriptionCount();
    }
    // 只收显隐；`sheetKind` 留到 onDisappear 再清，避免内容先消失、遮罩留一层
    this.sheetShown = false;
  }

  private confirmSheet(): void {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      this.applyRemindLead(REMIND_LEAD_OPTIONS[this.remindLeadDraft]);
    }
    this.sheetKind = SHEET_NONE;
  }

  @Computed
  get sheetTitle(): ResourceStr {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      return '提醒提前量';
    }
    return '选择订阅的群';
  }

  @Builder
  sheetBody() {
    if (this.sheetKind === SHEET_REMIND_LEAD) {
      OptionPickerBody({
        options: [
          this.remindLeadLabel(0), this.remindLeadLabel(5), this.remindLeadLabel(15),
          this.remindLeadLabel(30), this.remindLeadLabel(60)
        ],
        selectedIndex: this.remindLeadDraft,
        onSelectedIndexChange: (index: number) => {
          this.remindLeadDraft = index;
        },
        onCancel: () => {
          this.closeSheet();
        },
        onConfirm: () => {
          this.confirmSheet();
        }
      })
    } else if (this.sheetKind === SHEET_GROUPS) {
      this.groupSheetBody()
    }
  }

  /** 选择性订阅：列出机器人所在的群，逐群开关 */
  @Builder
  groupSheetBody() {
    Column({ space: 10 }) {
      if (this.groupsLoading) {
        Row({ space: 8 }) {
          LoadingProgress().width(24).height(24)
          Text('加载中…')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .height(80)
        .justifyContent(FlexAlign.Center)
      } else if (this.groupList.length === 0) {
        Text('还没有发现群消息。先在群里 @机器人 发一条，或点下面的「一键订阅」。')
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .padding({ top: 8, bottom: 8 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.groupList, (g: GroupItemDto) => {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text(g.label)
                    .fontSize($r('sys.float.ohos_id_text_size_body1'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(g.subscribed ? '已订阅' : '未订阅')
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                M3Switch({
                  isOn: g.subscribed,
                  onToggle: (isOn: boolean) => {
                    this.toggleGroup(g, isOn);
                  }
                })
              }
              .width('100%')
              .height(56)
              .padding({ left: 8, right: 8 })
              .alignItems(VerticalAlign.Center)
            }, (g: GroupItemDto) => g.group_openid + (g.subscribed ? '1' : '0'))
          }
          .width('100%')
        }
        .constraintSize({ maxHeight: 420 })
        .scrollBar(BarState.Off)
      }

      Row({ space: 10 }) {
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text('一键订阅')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeStore.scheme.onPrimaryContainer)
        }
        .height(34)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.themeStore.scheme.primaryContainer)
        .borderRadius(17)
        .onClick(() => {
          this.syncSubscriptions();
        })

        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Text('完成')
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeStore.scheme.onPrimary)
        }
        .height(34)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.themeStore.scheme.primary)
        .borderRadius(17)
        .onClick(() => {
          this.closeSheet();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  /* ── 数据清理 ── */

  private toast(message: ResourceStr): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'toast failed: %{public}s', err.message);
    }
  }

  /**
   * 导出菜单（FE-60）：点「导出任务」那一行弹出。
   * 三种口径按"给人看 / 给机器看 / 贴到别处"分：CSV 白名单列、JSON 完整（含原文）、复制到剪贴板。
   */
  @Builder
  exportMenu() {
    Column() {
      Text('CSV（表格，不含原文）')
        .width('100%')
        .height(ROW_HEIGHT_VP)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .textAlign(TextAlign.Start)
        .onClick(() => {
          this.exportMenuShown = false;
          this.exportTasks('csv');
        })
      Text('JSON（完整，含原文）')
        .width('100%')
        .height(ROW_HEIGHT_VP)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .textAlign(TextAlign.Start)
        .onClick(() => {
          this.exportMenuShown = false;
          this.exportTasks('json');
        })
      Text('复制到剪贴板（CSV）')
        .width('100%')
        .height(ROW_HEIGHT_VP)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .textAlign(TextAlign.Start)
        .onClick(() => {
          this.exportMenuShown = false;
          this.exportToClipboard();
        })
    }
    .width(240)
    .padding(8)
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 导出到文件：`csv` / `json`。
   *
   * 走 `TaskExportViewModel`（拼文本）→ `TaskExportService`（系统保存面板 + 落盘），
   * 页面只管"拿结果报一句话"。用户取消保存时**不提示**（不是失败）。
   */
  private async exportTasks(ext: string): Promise<void> {
    const tasks: Task[] = this.store.allTasks();
    if (tasks.length === 0) {
      this.toast('没有可导出的任务');
      return;
    }
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const csv: boolean = ext === 'csv';
    const content: string = csv ? TaskExportViewModel.buildCsv(tasks) : TaskExportViewModel.buildJson(tasks);
    const fileName: string = TaskExportViewModel.fileName(ext);
    const suffix: string = csv ? 'CSV|.csv' : 'JSON|.json';
    const result: TaskExportResult = await TaskExportService.saveFile(context, fileName, suffix, content);
    if (result.cancelled) {
      return;
    }
    if (result.ok) {
      this.toast(`已导出 ${tasks.length} 条任务` + (csv ? '（CSV）' : '（JSON，含原文）'));
      return;
    }
    this.toast(result.message.length > 0 ? result.message : '导出失败');
  }

  /** 导出到剪贴板（CSV 口径：白名单列，不把原文贴出去） */
  private async exportToClipboard(): Promise<void> {
    const tasks: Task[] = this.store.allTasks();
    if (tasks.length === 0) {
      this.toast('没有可导出的任务');
      return;
    }
    const content: string = TaskExportViewModel.buildCsv(tasks);
    const result: TaskExportResult = await TaskExportService.copyToClipboard(content);
    if (result.ok) {
      this.toast(`已复制 ${tasks.length} 条任务（CSV）到剪贴板`);
      return;
    }
    this.toast(result.message.length > 0 ? result.message : '复制失败');
  }

  private clearAllTasks(): void {    const total: number = this.store.totalCount;
    if (total === 0) {
      this.toast($r('app.string.settings_clear_empty'));
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.settings_clear_tasks'),
      message: $r('app.string.settings_clear_confirm'),
      buttons: [
        { text: $r('app.string.action_cancel'), color: $r('sys.color.ohos_id_color_text_primary') },
        { text: $r('app.string.action_delete'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index !== 1) {
        return;
      }
      const ids: number[] = [];
      this.store.allTasks().forEach((task: Task) => {
        ids.push(task.id);
      });
      let removed: number = 0;
      ids.forEach((id: number) => {
        if (this.store.deleteTask(id)) {
          removed++;
        }
      });
      this.toast($r('app.string.settings_clear_done', removed));
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'clear dialog failed: %{public}d, %{public}s', error.code, error.message);
    });
  }

  /* ── 视图构件 ── */

  @Builder
  sectionTitle(title: ResourceStr) {
    Text(title)
      .fontSize(Theme.FONT_CAPTION)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .width('100%')
      .padding({ left: SECTION_TITLE_INSET_VP, bottom: SECTION_TITLE_GAP_VP })
      .textAlign(TextAlign.Start)
  }

  @Builder
  rowDivider() {
    Divider()
      .strokeWidth(DIVIDER_WIDTH_VP)
      .color($r('sys.color.comp_divider'))
      .margin({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
  }

  /** 「左标签 + 右说明」的只读行（未接入项用） */
  @Builder
  infoRow(label: ResourceStr, value: string) {
    Row() {
      Text(label)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.Start)
      Text(value)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 卡片密度：**二档滑动控件**（2026-10-19 作者要求）。
   *
   * 之前是「点一行 → 弹选择器 → 再点确定」，两个动作才改一个二选一的开关；
   * 而且右侧那行值因为 `@Builder` 值参数不刷新，选完还显示旧值。
   * 现在一行内直接滑动切换，值也由 `@Param` 响应式驱动。
   */
  @Builder
  densityRow() {
    Row() {
      Text('卡片密度')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width(LABEL_WIDTH_VP)
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Blank()

      ToggleSlider({
        options: DENSITY_OPTIONS,
        selectedIndex: this.themeStore.density,
        onSelect: (index: number) => {
          this.applyDensity(index);
        }
      })
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /** 主题色：三个**颜色圆点**，不写色名（2026-10-19 作者要求） */
  @Builder
  accentDots() {
    Row() {
      Text('主题色')
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textAlign(TextAlign.Start)

      Row({ space: Theme.GAP_M }) {
        ForEach(ACCENT_OPTIONS, (option: AccentOption, index: number) => {
          Stack() {
            // 色板本体：整圆（这一个就是"按钮"）
            Row()
              .width(ACCENT_DOT_SIZE_VP)
              .height(ACCENT_DOT_SIZE_VP)
              .backgroundColor(option.light)
              .borderRadius(ACCENT_DOT_SIZE_VP / 2)

            // 选中态：**一个略小于按钮的白圈**（2026-10-19 作者要求）。
            // 之前是给外圈加深色描边，跟色板本身的形状打架；
            // 现在在色板上叠一个居中的白色实心圆，色板只剩一道色环，
            // 一眼能看出当前选的是哪一个，也不遮挡颜色本身。
            if (this.themeStore.accentIndex === index) {
              Row()
                .width(ACCENT_DOT_SIZE_VP - ACCENT_SELECT_RING_VP * 2)
                .height(ACCENT_DOT_SIZE_VP - ACCENT_SELECT_RING_VP * 2)
                .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
                .borderRadius((ACCENT_DOT_SIZE_VP - ACCENT_SELECT_RING_VP * 2) / 2)
                .transition(TransitionEffect.OPACITY.animation({ duration: 150 }))
            }
          }
          .width(Theme.HIT_MIN)
          .height(Theme.HIT_MIN)
          .onClick(() => {
            this.applyAccent(index);
          })
          .accessibilityText(option.label)
        }, (option: AccentOption, index: number) => `${option.label}-${index}`)
      }
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    // 外面套一层 Stack：底部要叠一条渐变遮罩（内容淡出而不是被齐切）
    Stack({ alignContent: Alignment.Bottom }) {
    Column() {
      // **让位放在 Scroll 外面**（2026-10-19 修「滚动后内容压在标题上」）：
      // 原来这段占位是 Scroll 的**内容首项**，滚动时它会带着正文一起上移，
      // 正文就钻到标题栏/状态栏区域、与「设置」叠字（实测状态栏变成 8:1提醒提前量）。
      // 放到外面后，**滚动视口本身**从标题栏下方开始，正文永远进不了标题区。
      Row().width('100%').height(TITLE_CLEARANCE_VP + this.statusBarVp)

      Scroll() {
      Column() {

        // ① 视觉个性化
        this.sectionTitle('视觉个性化')
        Column() {
          this.accentDots()
          this.rowDivider()
          // 卡片密度：**二档滑动控件**（2026-10-19 作者要求，不再弹选择器）
          this.densityRow()
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ② 通知个性化
        Column() {
          this.sectionTitle('通知个性化')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          // 2026-10-19：改成**锚定浮窗**（图二样式），不再是整屏底部面板
          PopupSelector({
            label: '提醒提前量',
            value: this.remindLeadLabel(this.remindLead),
            options: this.remindLeadOptionLabels,
            selectedIndex: REMIND_LEAD_OPTIONS.indexOf(this.remindLead),
            onSelect: (index: number) => {
              this.applyRemindLead(REMIND_LEAD_OPTIONS[index]);
            }
          })
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ③ 权限管理：通知 / 日历 / 订阅消息（先占位，如实标未接入）
        Column() {
          this.sectionTitle('权限管理')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          Row({ space: 8 }) {
            Text('通知权限')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
            Text(this.notifyAllowed ? '已开启' : '未开启')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text(this.notifyAllowed ? '已开启' : '去开启')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                // 「已开启」＝**状态**，取色与任务列表 ChipGroup 里**选中 chip** 同一套 M3 角色
                // （`secondaryContainer` 底 + `onSecondaryContainer` 字，见 components/TaskFilterChips.ets 的
                //  `itemStyle.selectedBackgroundColor / selectedFontColor`）；原来用的 `primaryContainer`
                // 在蓝主题下是一块很亮的青色，比旁边的文字抢眼太多（作者 2026-10-25 截图指出）。
                // 「去开启」是**动作**，仍用 `primary` 实底，保持可点的视觉引导。
                .fontColor(this.notifyAllowed
                  ? this.themeStore.scheme.onSecondaryContainer
                  : this.themeStore.scheme.onPrimary)
            }
            .height(34)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.notifyAllowed
              ? this.themeStore.scheme.secondaryContainer
              : this.themeStore.scheme.primary)
            .borderRadius(17)
            .onClick(() => {
              if (!this.notifyAllowed) {
                this.requestNotifyPermission();
              }
            })
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          this.rowDivider()

          Row({ space: 8 }) {
            Text('日历权限')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
            Text(this.calendarAllowed ? '已授权' : '未授权')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text(this.calendarAllowed ? '已授权' : '去授权')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                // 同「通知权限」：已授权＝状态 → 与 ChipGroup 选中 chip 同色（secondaryContainer / onSecondaryContainer）
                .fontColor(this.calendarAllowed
                  ? this.themeStore.scheme.onSecondaryContainer
                  : this.themeStore.scheme.onPrimary)
            }
            .height(34)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.calendarAllowed
              ? this.themeStore.scheme.secondaryContainer
              : this.themeStore.scheme.primary)
            .borderRadius(17)
            .onClick(() => {
              if (!this.calendarAllowed) {
                this.requestCalendarPermission();
              }
            })
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          this.rowDivider()

          Row({ space: 8 }) {
            Text('订阅消息管理')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
            Text(!this.bound
              ? '未绑定 QQ'
              : (this.subscribedCount < 0 ? '未连接' : '已订阅 ' + this.subscribedCount + ' 个群'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text('选择群')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(this.bound
                  ? this.themeStore.scheme.onPrimary
                  : this.themeStore.scheme.onSurfaceVariant)
            }
            .height(34)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.bound
              ? this.themeStore.scheme.primary
              : this.themeStore.scheme.surfaceContainerHigh)
            .borderRadius(17)
            .onClick(() => {
              if (this.bound) {
                this.openGroupSheet();
              } else {
                this.toast('请先绑定 QQ');
              }
            })
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          this.rowDivider()

          // 「不订阅自己的消息」：服务端在**入窗之前**丢掉本人消息，默认开
          Row({ space: 8 }) {
            Column({ space: 2 }) {
              Text('不订阅自己的消息')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Text('屏蔽用户自己在群中发送的信息')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .maxLines(2)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            M3Switch({
              isOn: this.skipSelf,
              onToggle: (isOn: boolean) => {
                this.setSkipSelf(isOn);
              }
            })
          }
          .width('100%')
          .height(64)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ④ 后端连接（qqbot-backend）
        Column() {
          this.sectionTitle('后端连接')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          Row({ space: 8 }) {
            Text('服务器')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width(64)
            TextInput({ text: this.backendUrl, placeholder: 'http://192.0.2.10:8730' })
              .layoutWeight(1)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .onChange((value: string) => {
                this.backendUrl = value;
              })
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text(this.backendBusy ? '连接中…' : '连接')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(this.backendBusy
                  ? this.themeStore.scheme.onSurfaceVariant
                  : this.themeStore.scheme.onPrimary)
            }
            .height(34)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.backendBusy
              ? this.themeStore.scheme.surfaceContainerHigh
              : this.themeStore.scheme.primary)
            .borderRadius(17)
            .onClick(() => {
              if (!this.backendBusy) {
                this.connectServer();
              }
            })
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          this.rowDivider()
          // ⚠️ 这里不能复用 `infoRow(...)`：`@Builder` 的值参数不参与刷新，
          // 状态变化后仍显示初始的「未连接」。必须直接读 `@Local` 字段。
          Row() {
            Text('连接状态')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.Start)
            Text(this.backendState)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor(this.backendState.startsWith('已连接')
                ? this.themeStore.scheme.primary
                : $r('sys.color.ohos_id_color_text_secondary'))
              .maxLines(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          this.rowDivider()
          Row({ space: 8 }) {
            Text('绑定 QQ')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
            Text(this.bound ? '已绑定' : '未绑定')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text(this.bound ? '重新绑定' : '去绑定')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(this.bindCode.length === 0
                  ? this.themeStore.scheme.onPrimary
                  : this.themeStore.scheme.onSurfaceVariant)
            }
            .height(34)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.bindCode.length === 0
              ? this.themeStore.scheme.primary
              : this.themeStore.scheme.surfaceContainerHigh)
            .borderRadius(17)
            .onClick(() => {
              if (this.bindCode.length === 0) {
                this.startBind();
              }
            })
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          if (this.bindCode.length > 0) {
            Column({ space: 6 }) {
              Text(this.bindCode)
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .letterSpacing(4)
              Text(this.bindHint)
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .textAlign(TextAlign.Center)
              Text('剩余 ' + this.bindLeftSec + ' 秒')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(this.themeStore.scheme.onSurfaceVariant)
              Row({ space: 10 }) {
                Button({ type: ButtonType.Capsule, stateEffect: true }) {
                  Text('复制配对码')
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontColor(this.themeStore.scheme.onPrimary)
                }
                .height(32)
                .padding({ left: 14, right: 14 })
                .backgroundColor(this.themeStore.scheme.primary)
                .borderRadius(16)
                .onClick(() => {
                  this.copyBindCode();
                })

                Button({ type: ButtonType.Capsule, stateEffect: true }) {
                  Text('取消')
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .fontColor(this.themeStore.scheme.primary)
                }
                .height(32)
                .padding({ left: 14, right: 14 })
                .backgroundColor(Color.Transparent)
                .border({ width: 1, color: this.themeStore.scheme.outline })
                .borderRadius(16)
                .onClick(() => {
                  this.cancelBind();
                })
              }
            }
            .width('100%')
            .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP, bottom: 12 })
            .alignItems(HorizontalAlign.Center)
          }

          if (this.bindExpired && this.bindCode.length === 0) {
            Column({ space: 8 }) {
              Text('配对码已过期，请重新生成')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor(this.themeStore.scheme.onSurfaceVariant)
              Button({ type: ButtonType.Capsule, stateEffect: true }) {
                Text('重新生成')
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .fontColor(this.themeStore.scheme.onPrimary)
              }
              .height(32)
              .padding({ left: 16, right: 16 })
              .backgroundColor(this.themeStore.scheme.primary)
              .borderRadius(16)
              .onClick(() => {
                this.startBind();
              })
            }
            .width('100%')
            .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP, bottom: 12 })
            .alignItems(HorizontalAlign.Center)
          }

          this.rowDivider()
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑤ 云端数据：字段清单 + 同步开关 + 整包删除
        Column() {
          this.sectionTitle('云端数据')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          Row({ space: 8 }) {
            Column({ space: 2 }) {
              Text('云端同步')
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
              Text('关闭后不再拉取群消息候选')
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // ⚠️ 必须用 `M3Switch`，不能写裸 `Toggle`：`Toggle` 的选中轨道默认取
            // `ohos_id_color_emphasize`（系统蓝），换了主题色也不会变（2026-10-25 作者截图指出）。
            // 这一行是合并 `feature/mvp-completion` 时带进来的裸 Toggle，已纠正。
            M3Switch({
              isOn: this.syncEnabled,
              onToggle: (isOn: boolean) => {
                this.onSyncToggle(isOn);
              }
            })
            .id('syncEnabledToggle')
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)

          this.rowDivider()
          Row({ space: 8 }) {
            Text('会离开手机的字段')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
            Text('查看')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor(this.themeStore.scheme.primary)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.showCloudFields();
          })

          this.rowDivider()
          Row() {
            Text('删除服务端数据')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_warning'))
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.deleteServerData();
          })
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑤ 解析
        Column() {
          this.sectionTitle('解析')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          // 本工程**没有端侧解析**：群消息的标题/摘要全部由后端 /candidates 产出
          // （Qwen 模型，失败回退规则拼接）。之前那个三档选择器是旧方案遗留，
          // 「端侧优先」在这里是假的，已去掉。
          this.infoRow('解析方式', '服务端（Qwen 模型）')
          Row() {
            Text('群消息由后端解析后下发；本机只负责展示与排序，不做本地抽取。')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP, bottom: 12 })
          }
          .width('100%')
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑤ 数据
        Column() {
          this.sectionTitle('数据')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          // 「导出任务」：点一下弹格式菜单（FE-60）。CSV/JSON 走系统保存面板，剪贴板走 pasteboard
          Row({ space: 8 }) {
            Text('导出任务')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.Start)
            Text('CSV / JSON / 剪贴板')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .maxLines(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(Theme.FONT_CAPTION)
              .fontColor([$r('sys.color.icon_tertiary')])
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.exportMenuShown = true;
          })
          .bindPopup(this.exportMenuShown, {
            builder: this.exportMenu(),
            placement: Placement.Bottom,
            popupColor: this.themeStore.scheme.surfaceContainerHigh,
            radius: 16,
            enableArrow: false,
            focusable: true,
            onStateChange: (event) => {
              if (!event.isVisible) {
                this.exportMenuShown = false;
              }
            }
          })

          this.rowDivider()

          Row() {
            Text($r('app.string.settings_clear_tasks'))
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_warning'))
              .layoutWeight(1)
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.clearAllTasks();
          })
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // ⑥ 关于
        Column() {
          this.sectionTitle('关于')
        }
        .margin({ top: SECTION_GAP_VP })

        Column() {
          this.infoRow('版本', this.versionLabel)
          this.rowDivider()
          Row() {
            Text('隐私说明')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
            Text('查看')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor(this.themeStore.scheme.primary)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.showPrivacy();
          })

          this.rowDivider()
          Row() {
            Text('重新查看启动引导')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
            Text('下次启动')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.replayOnboarding();
          })

          this.rowDivider()
          Row() {
            Text('通知与横幅设置')
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
            Text('去开启')
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor(this.themeStore.scheme.primary)
          }
          .width('100%')
          .height(ROW_HEIGHT_VP)
          .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.openNotificationSettings();
          })

          this.rowDivider()
          this.infoRow('提醒状态', this.store.reminderError.length > 0 ? this.store.reminderError : '正常')
        }
        .width('100%')
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
        .borderRadius(Theme.RADIUS_CARD)
        .clip(true)

        // 底部让开悬浮页签栏：不留这段的话最后一项会被压住（上一版就是漏了它）
        Row().width('100%').height(BOTTOM_CLEARANCE_VP)
      }
      .width('100%')
      .padding({ left: PAGE_SIDE_PADDING_VP, right: PAGE_SIDE_PADDING_VP })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    // M3：设置页底色 = `surface`（与任务列表一致）。
    // ⚠️ 这里原来**后面还有一句** `.backgroundColor($r('sys.color.ohos_id_color_sub_background'))`
    // —— 后写者生效，把 surface 覆盖成了系统浅蓝，导致设置页底色与暖色主题不搭
    //（作者 2026-10-19 截图箭头指的就是这块）。已删掉那一句。
    .backgroundColor(this.themeStore.scheme.surface)
    .scrollBar(BarState.Off)
    // 2026-10-19 作者：「设置页滑动怎么没有像任务页一样的回弹效果」——
    // 任务页的 List 有 `EdgeEffect.Spring`，这里漏了，补上。
    .edgeEffect(EdgeEffect.Spring)
    .layoutWeight(1)
    // 2026-10-19 设置页调研：**底部要让开悬浮页签栏**。
    // 任务页有 `LIST_BOTTOM_CLEARANCE_VP`(80)，设置页漏了 →
    // 实测「云端同步（未接入）」「关于」被底部胶囊压住一半（截图 CA1-settings-audit.png）。
    .contentEndOffset(80)
    .align(Alignment.Top)
    .width('100%')
    .layoutWeight(1)
    .bindSheet(this.sheetShown!!, this.sheetBody(), {
      title: { title: this.sheetTitle },
      // 列表型用底部半模态（从底部起、内容顶对齐）；只有选择器用居中卡片
      preferType: this.sheetKind === SHEET_GROUPS ? SheetType.BOTTOM : SheetType.CENTER,
      height: SheetSize.FIT_CONTENT,
      showClose: false,
      dragBar: false,
      onDisappear: () => {
        this.sheetShown = false;
        this.sheetKind = SHEET_NONE;
      }
    })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeStore.scheme.surface)
    // 2026-10-20 取消全屏沉浸：原来这里还有一行 `.expandSafeArea([SYSTEM], [BOTTOM])`，
    // 让底色铺到手势条底下。现在页面不再伸进系统栏，底部那截交给系统栏背景色（`A_Main.applyWindowTheme`）。

    // **底部渐变遮罩**：与任务列表同一套做法，内容滑到胶囊/＋ 那一带时淡出
    Column()
      .width('100%')
      .height(BOTTOM_MASK_VP)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: this.bottomMaskColors
      })
      .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
  }
}
