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
import { SettingsRepository } from '../repository/SettingsRepository';

const DOMAIN: number = 0x0000;
const TAG: string = 'A_Main';

@Entry
@ComponentV2
struct A_Main {
  private navPathStack: NavPathStack = new NavPathStack();
  /**
   * 任务列表的滚动控制器：在这里创建（照官方示例：Scroller 由页面持有），
   * 一路透传 `MainTabBar → A_TaskList` 给 `List` 用，再交给 `HdsNavigation.bindToScrollable`。
   */
  private taskListScroller: Scroller = new Scroller();

  /**
   * 设置页的 Scroller：**必须也绑到 indToScrollable**。
   * 不绑的话，导航栏的大标题只在任务列表里跟着收缩；切到设置页滚动时
   * 标题会**原样压在内容上**（实测：滑到中间时「设置」两个大字盖住「提醒提前量」卡片）。
   */
  private settingsScroller: Scroller = new Scroller();
  /**
   * 任务列表的「数据 ＋ 编辑态」store：页面持有、按引用透传（`@ObservedV2` 必须 `new` 出来才可观测）。
   * 编辑态要同时被导航栏（取消/全选）、底部悬浮栏（添加↔删除）、每张卡片（圆圈↔方框勾选框）读到，
   * 挂在页面这一层最省事，也不用把状态在几层组件之间来回搬。
   */
  private store: TaskListStore = new TaskListStore();
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

  /** 视觉个性化：M3 色系（页面底色取 surface） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

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
    return this.currentIndex === 0 ? $r('app.string.tab_task_list') : $r('app.string.tab_settings');
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
      onSaved: () => {
        // 保存成功：收起半模态 + 给一条反馈（列表那边会自己重分组刷新）
        this.addSheetShown = false;
        this.toast($r('app.string.task_saved'));
      },
      onClose: () => {
        this.addSheetShown = false;
      }
    })
  }

  build() {
    HdsNavigation(this.navPathStack) {
      // 底部页签栏（HdsTabs 容器 + 两个页签 + 悬浮样式 + 迷你栏）整个在 components/MainTabBar.ets 里
      MainTabBar({
        scroller: this.taskListScroller,
        settingsScroller: this.settingsScroller,
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
    // —— 标题栏跟手：官方要求把导航组件与可滚动容器绑起来 ——
    // 官方原文：「6.0.0(20)及以上版本，推荐使用 bindToScrollable、bindToNestedScrollable 属性绑定导航组件和
    // 可滚动容器组件后，再使用导航组件滚动相关的功能，从而获得更优的体验」；
    // `HdsNavigationTitleMode.FREE` 的官方说明也写着「推荐搭配 bindToScrollable/bindToNestedScrollable 体验更佳的联动效果」。
    .bindToScrollable([this.taskListScroller, this.settingsScroller])
    // 设置页用**小标题**：它在 FREE（大标题）下没有可靠的滚动联动，
    // 实测滚到中间时「设置」两个大字会直接压在卡片上（任务列表没这问题）。
    // 任务列表保持 FREE（大标题 + 跟手收缩）。
    .titleMode(this.currentIndex === 0 ? HdsNavigationTitleMode.FREE : HdsNavigationTitleMode.MINI)
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
    .bindSheet(this.addSheetShown!!, this.addTaskSheet(), addTaskSheetOptions())
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
  }
}
