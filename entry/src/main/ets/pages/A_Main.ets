import { HdsNavigation, HdsNavigationMenuContentOptions, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Theme, ThemeStore } from '../utils/Theme';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AddTaskSheet, addTaskSheetOptions } from '../components/AddTaskSheet';
import { MainTabBar } from '../components/MainTabBar';
import { MainTitleBar } from '../components/MainTitleBar';
import { NAV_STACK_KEY, ROUTE_SEARCH } from '../viewmodel/TaskNavParams';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { DraftRepository } from '../repository/DraftRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { SyncService } from '../service/cloud/SyncService';
import { PushRegistrar } from '../service/cloud/PushRegistrar';
import { NotificationService } from '../service/system/NotificationService';
import { BackendConfig } from '../service/backend/BackendConfig';
import { RelayApi } from '../service/backend/RelayApi';
import { ForwardPendingData, ForwardItem } from '../service/backend/BackendTypes';
import { ShareIntake, SharePayload, SHARE_KIND_IMAGE } from '../service/share/ShareIntake';
import { AddTaskSource } from '../components/AddTaskSourceTabs';
import { A_Onboarding } from './A_Onboarding';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Main';

@Entry
@ComponentV2
struct A_Main {
  private navPathStack: NavPathStack = new NavPathStack();

  /**
   * 任务列表的滚动控制器：在这里创建（照官方示例：Scroller 由页面持有），
   * 一路透传 `MainTabBar → A_TaskList` 给 `List` 用。
   *
   * 2026-10-25：标题栏改成固定 MINI 后，它**不再**交给 `HdsNavigation.bindToScrollable`；
   * 同批删掉了 `settingsScroller`（设置页从未读过它，它当时只是为了被绑上去）。
   */
  private taskListScroller: Scroller = new Scroller();

  /**
   * 任务列表的「数据 ＋ 编辑态」store：页面持有、按引用透传（`@ObservedV2` 必须 `new` 出来才可观测）。
   * 编辑态要同时被导航栏（取消/全选）、底部悬浮栏（添加↔删除）、每张卡片（圆圈↔方框勾选框）读到，
   * 挂在页面这一层最省事，也不用把状态在几层组件之间来回搬。
   */
  private store: TaskListStore = TaskListStore.instance();
  @Local currentIndex: number = 0;
  /**
   * 「添加任务」半模态（`bindSheet`）的显隐（需求方 2026-10-17：「点击底部页签的添加按钮后
   * 显示一个 bindSheet 先完成这个功能」）。
   *
   * 为什么这个状态挂在**页面**而不是 `MainTabBar` 里那颗圆形按钮上：
   *  · 半模态"严格和宿主节点绑定"（官方原文），挂在页面根节点上宿主不会因页签切换/迷你栏折叠被重建；
   *  · 底部栏只管发 `onAdd` 事件（它已经这么做了），显隐归页面，以后表单要读写 `store` 也顺理成章。
   *
   * 为什么传参写 `!!` 而不是 `$$`：`$$` 是**状态管理 V1** 的语法；本项目一律用 V2，
   * 官方《语法糖 · !!语法：双向绑定》里 `bindSheet` 的 `isShow` 从 **API 18** 起支持 `!!`
   * （本项目 target 6.0.2(22) ≥ 18 ✓）。只有双向绑定，用户**拖拽 / 点蒙层**关掉半模态时
   * 这个变量才会自动回到 `false` —— 否则会出现"界面关了、变量还是 true，再点一次拉不起来"。
   */
  @Local addSheetShown: boolean = false;
  /** 「添加任务」的草稿：由页面持有，关闭半模态时落盘、下次点「＋」恢复 */
  private addDraft: AddTaskDraft = new AddTaskDraft();
  /** 分享带入内容后自增，AddTaskSheet 据此自动解析；0 表示普通新建 */
  @Local shareParseKey: number = 0;
  /** 首次启动引导 */
  @Local showOnboarding: boolean = false;

  /** 视觉个性化：M3 色系（页面底色取 surface） */
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 提醒/日历对账定时器（分钟级就够） */
  private reminderTimer: number = -1;
  /** 通知引导弹窗每次启动只弹一次，避免每分钟对账重复打扰 */
  @Local notificationGuideShown: boolean = false;

  /**
   * 把导航栈放进 `AppStorage`：点卡片进详情这件事发生在 `A_TaskList`（以及搜索页的 `B_Search`）里，
   * 官方《Navigation 页面路由》的方式一就是「使用 AppStorage 存储与获取」——
   * 比把 `NavPathStack` 一层层往下传（`A_Main → MainTabBar → A_TaskList`）干净。
   */
  aboutToAppear(): void {
    AppStorage.setOrCreate<NavPathStack>(NAV_STACK_KEY, this.navPathStack);
    this.syncRemindLead();
    this.syncTheme();
    this.syncGroupExpand();
    this.startBackend();
    this.setupShare();
    this.setupOnboarding();
  }

  /** 首次启动：没看过引导就全屏覆盖；不阻塞列表初始化 */
  private setupOnboarding(): void {
    if (this.shareParseKey > 0) {
      // 从分享冷启动：先处理分享，引导留到下次普通启动
      return;
    }
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    SettingsRepository.getFirstLaunchDone(context).then((done: boolean) => {
      if (!done && this.shareParseKey === 0) {
        this.showOnboarding = true;
      }
    });
  }

  /** 从 QQ/其他 App 回到前台：取走「转发给机器人」的文本 */
  onPageShow(): void {
    this.pullForwarded();
    // 热启动分享/冷启动竞态兜底：若监听没接住，这里再取一次
    const pending: SharePayload | undefined = ShareIntake.consumePending();
    if (pending !== undefined) {
      this.openShare(pending);
    }
    const shareError: string = ShareIntake.consumeError();
    if (shareError.length > 0) {
      this.toast(shareError);
    }
  }

  private async pullForwarded(): Promise<void> {
    if (!BackendConfig.hasIdentity() || BackendConfig.baseUrl.length === 0 || this.showOnboarding) {
      return;
    }
    const res = await RelayApi.forwardPending();
    if (!res.ok || res.data === undefined) {
      return;
    }
    const data: ForwardPendingData = res.data;
    if (data.items.length === 0) {
      return;
    }
    const latest: ForwardItem = data.items[data.items.length - 1];
    this.addDraft.reset();
    this.addDraft.sourceTab = AddTaskSource.TEXT;
    this.addDraft.rawText = latest.text;
    this.shareParseKey = Date.now();
    this.addSheetShown = true;
    if (data.items.length > 1) {
      this.toast('收到 ' + data.items.length + ' 条转发，已打开最新一条');
    }
  }

  private finishOnboarding(): void {
    this.showOnboarding = false;
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      SettingsRepository.setFirstLaunchDone(context);
    }
  }

  /** 分享接收：热启动走监听，冷启动先取暂存；同一次分享只消费一次 */
  private setupShare(): void {
    ShareIntake.setListener((payload: SharePayload) => {
      this.openShare(payload);
    });
    const pending: SharePayload | undefined = ShareIntake.consumePending();
    if (pending !== undefined) {
      this.openShare(pending);
    }
    const error: string = ShareIntake.consumeError();
    if (error.length > 0) {
      this.toast(error);
    }
  }

  /** 把分享内容放进「添加任务」确认面，并自动触发一次解析 */
  private openShare(payload: SharePayload): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      DraftRepository.clear(context);
    }
    this.addDraft.reset();
    if (payload.kind === SHARE_KIND_IMAGE) {
      this.addDraft.sourceTab = AddTaskSource.SCREENSHOT;
      this.addDraft.imageUri = payload.uri;
    } else {
      this.addDraft.sourceTab = AddTaskSource.TEXT;
      this.addDraft.rawText = payload.text;
    }
    this.shareParseKey = Date.now();
    this.addSheetShown = true;
  }

  /**
   * 接后端：读本机任务 → 启动同步（每 5 秒拉一次候选）。
   *
   * 顺序不能反：`store.init` 先把上次落盘的任务读回来（离线也有内容），
   * 再由 `SyncService` 增量 upsert —— 直接等网络会让首帧空列表闪一下。
   */
  private startBackend(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    // `store.init` 内部已经跑过一次「已过期」扫描（FE-29：`syncExpiredStatus`），
    // 所以这里不用再单独扫一遍；之后由下面这个 60 秒定时器 + `SyncService` 的 5 秒 tick 持续兜住。
    this.store.init(context);
    this.store.setReminderFailureListener((message: string, code: number) => {
      this.onReminderFailure(message, code);
    });
    // 通知权限只在用户主动打开开关时申请（首次引导/设置页）；启动不再弹系统框
    // 提醒/日历对账：启动先清掉系统里残留的「幽灵提醒」再重建，之后每分钟一次
    this.store.resetStaleReminders();
    this.reminderTimer = setInterval(() => {
      this.store.expireOverdue();
      this.store.reconcileReminders();
    }, 60000);
    SyncService.init(context);
    SettingsRepository.getSyncEnabled(context).then((enabled: boolean) => {
      // 关掉同步就不轮询；打开会立即拉一次
      SyncService.setEnabled(enabled);
      if (enabled) {
        // FE-76：同步开着才去取 Push Token 并上报（`push_ready` 由后端告诉）
        PushRegistrar.register();
      }
    });
  }

  aboutToDisappear(): void {
    SyncService.stop();
    if (this.reminderTimer >= 0) {
      clearInterval(this.reminderTimer);
      this.reminderTimer = -1;
    }
  }

  /**
   * 把持久化的**分组展开状态**读回 store（2026-10-20，需求方：「记住上次的展开状态」）。
   *
   * 与 `syncTheme` 同一个理由放在根页面：`TaskListStore` 是页面持有的内存态，
   * 用户上次收起/展开了哪几天，重启后要在这里恢复；只写在 `A_TaskList` 里的话
   * 首帧就会闪一下「默认展开」（读盘是异步的）。
   */
  private async syncGroupExpand(): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    await this.store.syncGroupExpand(context);
  }

  /**
   * 把持久化的**主题色与卡片密度**读回 `ThemeStore`（2026-10-19）。
   *
   * ⚠️ 必须放在**根页面**而不是设置页：`ThemeStore` 是内存态，用户上次选的橙色
   * 重启后要靠这里恢复。只写在 `A_Settings.aboutToAppear` 里的话，
   * 用户停在任务列表页时根本不会执行 → 主题永远是默认蓝（实测踩过）。
   */
  private async syncTheme(): Promise<void> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const accent: number = await SettingsRepository.getThemeAccent(context, this.themeStore.accentIndex);
    const density: number = await SettingsRepository.getDensity(context, this.themeStore.density);
    if (accent !== this.themeStore.accentIndex) {
      this.themeStore.accentIndex = accent;
    }
    if (density !== this.themeStore.density) {
      this.themeStore.density = density;
    }
  }

  /**
   * 把设置页的「提醒提前量」读进 store（2026-10-19）。
   *
   * 铃铛开关直接在列表卡片上改 `alarm`，而 `remindAt` 要按提前量算 —— 计算在
   * `TaskListStore.setRemind` 里，它需要这个值。页签来回切会重新走 `aboutToAppear`，
   * 所以用户改完设置回到列表时立刻生效。
   */
  private async syncRemindLead(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    const minutes: number = await SettingsRepository.getRemindLead(context);
    this.store.remindLeadMinutes = minutes;
  }

  @Computed
  get navTitle(): ResourceStr {
    if (this.currentIndex === 0) {
      return $r('app.string.tab_task_list');
    }
    if (this.currentIndex === 1) {
      return $r('app.string.tab_banban');
    }
    return $r('app.string.tab_settings');
  }

  /**
   * 右上角按钮**随页签与编辑态变**：
   * · 普通态 —— 任务列表＝编辑 + 搜索（两个图标按钮），设置＝关于（一个）；
   * · **编辑态 —— 取消 / 全选（两个纯文字按钮）**（需求方 2026-10-16）。
   * 官方 `HdsNavigation` 是**函数式组件**（`HdsNavigationInterface`），`titleBar` 参数会随重渲染更新，
   * 所以这里用 `@Computed` 依赖 `currentIndex` 与 `store.editing` 就能换来换去。
   */
  @Computed
  get navMenu(): HdsNavigationMenuContentOptions {
    if (this.store.editing) {
      return MainTitleBar.editModeMenu(() => {
        this.store.exitEdit();
      }, () => {
        this.store.selectAll();
      });
    }
    if (this.currentIndex === 0) {
      return MainTitleBar.taskListMenu(() => {
        this.onEdit();
      }, () => {
        this.onSearch();
      });
    }
    if (this.currentIndex === 1) {
      return MainTitleBar.emptyMenu();
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

  /** 提醒发布失败：额度满直接说清楚；其余按「通知没开」引导到系统设置 */
  private onReminderFailure(message: string, code: number): void {
    this.toast(message);
    if (code !== 1700002) {
      this.showNotificationGuide();
    }
  }

  /** 通知未开启的引导（每次启动只弹一次；「去开启」直接跳系统通知管理） */
  private showNotificationGuide(): void {
    if (this.notificationGuideShown) {
      return;
    }
    this.notificationGuideShown = true;
    try {
      this.getUIContext().showAlertDialog({
        title: '通知未开启',
        message: '任务到点不会提醒。去系统设置打开「知了」的通知，并允许横幅。',
        primaryButton: {
          value: '暂不',
          action: () => {
          }
        },
        secondaryButton: {
          value: '去开启',
          fontColor: $r('sys.color.ohos_id_color_emphasize'),
          action: () => {
            const context: common.Context | undefined = this.getUIContext().getHostContext();
            if (context !== undefined) {
              NotificationService.openSettings(context as common.UIAbilityContext);
            }
          }
        }
      });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'show notification guide failed: %{public}d, %{public}s', err.code, err.message);
    }
  }

  /** 右上角「编辑」：进入多选模式（卡片的圆圈变方框勾选框、右上角变取消/全选、底部添加变删除） */
  private onEdit(): void {
    this.store.enterEdit();
  }

  private onSearch(): void {
    // 点导航栏的「搜索」→ 把搜索页压入导航栈（二级页**从右侧滑进来**是导航栈 push 的默认行为）。
    // 页面本身在 `router_map.json` 里注册（官方系统路由表），所以这里只要路由名；
    // **把任务 store 一起带过去**，搜索页搜的就是列表这一份数据（不是副本）。
    this.navPathStack.pushPathByName(ROUTE_SEARCH, this.store);
  }

  private onAbout(): void {
    this.toast($r('app.string.menu_about'));
  }

  /**
   * 底部页签右侧圆形「＋」→ **拉起「添加任务」半模态**（需求方 2026-10-17）。
   * 半模态的内容区在 `components/AddTaskSheet.ets`，标题在下面的 `bindSheet` 选项里给。
   * 原来这里是一句 toast 占位，本轮被真正的半模态取代。
   */
  private onAdd(): void {
    this.shareParseKey = 0;
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      // 恢复上次没填完的草稿（没有/损坏就保持空表单）
      DraftRepository.load(context, this.addDraft);
    }
    this.addSheetShown = true;
  }

  /**
   * 半模态的**内容 builder** —— 只是一行装配（组件化约定：页面里的 `@Builder` 只做「喂系统接口」的适配，
   * 不含任何视觉结构）。内容与选项都在 `components/AddTaskSheet.ets`。
   *
   * store 必须传进去：保存时要 `store.addTask()` 把新任务落进列表（半模态是页面的一部分，store 归页面持有）。
   */
  @Builder
  addTaskSheet() {
    AddTaskSheet({
      store: this.store,
      draft: this.addDraft,
      autoParseKey: this.shareParseKey,
      onSaved: () => {
        // 保存成功：清掉本机草稿 → 收起半模态 + 给一条反馈
        const context: common.Context | undefined = this.getUIContext().getHostContext();
        if (context !== undefined) {
          DraftRepository.clear(context);
        }
        this.addSheetShown = false;
        this.toast($r('app.string.task_saved'));
      },
      onClose: () => {
        this.addSheetShown = false;
      }
    })
  }

  build() {
    Stack() {
      HdsNavigation(this.navPathStack) {
      // 底部页签栏（HdsTabs 容器 + 两个页签 + 悬浮样式 + 迷你栏）整个在 components/MainTabBar.ets 里
      MainTabBar({
        scroller: this.taskListScroller,
        store: this.store,
        onIndexChange: (index: number) => {
          this.currentIndex = index;
        },
        onAdd: () => {
          this.onAdd();
        },
        onDeleteDone: (count: number) => {
          // 卡片消失本身就是反馈，再补一句 toast 说明删了几条
          this.toast($r('app.string.deleted_count', count));
        }
      })
    }
    // 2026-10-25：三个页签**一律用 HDS 标题栏 + 固定小标题（MINI）**。
    //  · 板板页原来 `.hideTitleBar(true)` + 页面自绘标题行 → 标题字号/左右内边距/高度都和设置页差一点；
    //  · 任务列表原来用 `FREE`（大标题随内容收缩）→ 作者：「改成设置页那样 mainTitle 固定的吧，
    //    不需要动画，老有问题」。
    // 现在三页同一套 `MainTitleBar.style` + 同一个 `titleMode`，标题位置**完全不动**。
    //
    // 连带删掉的：`.bindToScrollable([...])`。官方只说 FREE 模式「推荐搭配 bindToScrollable/
    // bindToNestedScrollable 体验更佳的联动效果」（`HdsNavigationTitleMode` 枚举说明）——
    // 那是**标题收缩联动**的驱动；MINI 是「固定为小标题模式」，没有要联动的量。
    // 留着它只会让导航组件白订阅滚动事件，所以三页都 MINI 之后一并去掉。
    .titleMode(HdsNavigationTitleMode.MINI)
    .hideBackButton(true)
    .titleBar({
      // 2026-10-21 窗口改回**全屏**（见 EntryAbility.setupWindow），所以这里必须恢复 `true`：
      // 让 HDS 自己把标题栏让开状态栏高度，内容区也随之从状态栏下方开始。
      //（反例记在这：非全屏布局下写 `true` 会把状态栏高度叠第二遍 —— TitleBar 变成 151vp、大标题压到 Chip 行上。）
      avoidLayoutSafeArea: true,
      style: MainTitleBar.style(this.themeStore.scheme.surface, this.themeStore.scheme.onSurface),
      content: {
        title: { mainTitle: this.navTitle },
        menu: this.navMenu
      }
    })
    // —— 「添加任务」半模态（需求方 2026-10-17）——
    // 挂在**导航根节点**上：半模态"严格和宿主节点绑定"（官方原文），这个节点在本页生命周期里
    // 不会重建，所以页签切换、迷你栏折叠都影响不到它。第一个参数必须是 `!!` 双向绑定（见 `addSheetShown`）。
    // 官方另有一条要留意：宿主节点还没上树就把 isShow 置 true，半模态不生效 ——
    // 本页的宿主是常驻的导航根节点，不存在这个问题。
    // **内容与选项都不在这里**：`AddTaskSheet()` 是内容、`addTaskSheetOptions()` 是挡位/标题/关闭按钮，
    // 两者都在 `components/AddTaskSheet.ets` 里（组件化约定见 `references/02-编码规约.md` §10 规则 5）。
    .bindSheet(this.addSheetShown!!, this.addTaskSheet(), addTaskSheetOptions(() => {
      // 半模态收起（划掉 / 关闭 / 保存后）都落一次草稿：
      // 保存成功时草稿已被 reset + clear，这里存的是空表单，不影响下次。
      const context: common.Context | undefined = this.getUIContext().getHostContext();
      if (context !== undefined) {
        DraftRepository.save(context, this.addDraft);
      }
    }))
    // M3（2026-10-19）：页面底色 = `surface` —— 很淡、带一丝主题色；
    // 卡片用 `surface-container-low`（tone 更低一档），层次靠色调表达而不是描边/重阴影。
    .backgroundColor(this.themeStore.scheme.surface)
    // 2026-10-21（需求方：「状态栏色块能去掉吗」）：系统栏那片底色改由**页面自己画**。
    // `expandSafeArea` 把这一层的**绘制区域**铺进状态栏/导航条，于是：
    //  · 它跟着页面一起出现（不会在首帧之前"凭空空一块色"）；
    //  · 弹半模态/弹窗时它和页面一起被蒙层压暗（不再是"周围都暗、就那一条亮"）；
    //  · 颜色本来就跟主题 `surface` 走。
    // 代价：这一层也铺到了系统栏底下（布局随之扩展），所以内容要让开 —— 顶部交给
    // `titleBar.avoidLayoutSafeArea: true`，底部由 `MainTabBar` 的悬浮层留 16vp + 安全区。
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')

      // 首次启动引导：全屏覆盖，完成后写 first_launch_done 不再出现
      if (this.showOnboarding) {
        A_Onboarding({
          onFinish: () => {
            this.finishOnboarding();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeStore.scheme.surface)
  }
}
