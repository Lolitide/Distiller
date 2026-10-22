/*
 * 底部页签栏 —— **自绘**的悬浮胶囊 + 右下角悬浮「＋」（2026-10-20 重写）。
 *
 * ── 为什么不再用官方 `HdsTabs`（需求方 2026-10-20：「把 hdstsbs 的底部页签弃用并让页签支持主题取色」）──
 * 1. **取色取不动**：`HdsTabs` 的页签样式走官方 `BottomTabBarStyle`，它不开放选中态底色/文字色，
 *    悬浮态那层浅灰背板（实测 `#F1F3F5`，系统冷灰 `ohos_id_color_sub_background`）也没有任何官方字段能改
 *    —— AI 上一轮把 `systemMaterialEffect.materialType = NONE`、`barBackgroundColor(...)` 两个官方旋钮
 *    都试过，底色一位数都没变（结论记在 `docs/99-附录-取证台账.md` §15）。
 *    现在整条栏自己画，选中态直接用 M3 `primary`、未选中用 `onSurfaceVariant`，跟着主题色走。
 * 2. **形态要变**：页签收成一颗悬浮胶囊，右侧那颗「＋」独立悬浮在屏幕右下方（不再借官方迷你栏占位）。
 *
 * ── 结构 ──
 *   Stack（底对齐）
 *    ├─ `Tabs`（`.barHeight(0)` —— 只借用它的内容容器，官方页签栏整条隐掉，页面状态不被重建）
 *    └─ 底部悬浮层：`Row { 胶囊; Blank; ＋ }`，与胶囊同一底边距
 *
 * ── 与「取消全屏沉浸」的配合（2026-10-20 同批改动）──
 * 页面不再伸进系统栏，所以**不用**再算底部避让区高度（上一版那 28vp 补偿已删）：
 * 悬浮层距布局底边 16vp ＝ 距底部安全区 16vp，`barFloatingStyle` 那套 API 也一并不再依赖。
 *
 * 对外只暴露三个事件：页签切换、点「＋」（普通态＝添加 / 编辑态＝删除）、删除完成回调。
 */
import { curves } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WindowInsets } from '../utils/WindowInsets';
import { ThemeStore } from '../utils/Theme';
import { Theme } from '../utils/Theme';
import { A_TaskList } from '../pages/A_TaskList';
import { A_Settings } from '../pages/A_Settings';
import { C_Banban } from '../pages/C_Banban';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { showDeleteConfirmDialog } from '../utils/DeleteConfirmDialog';

/** 胶囊高度（vp）：与官方页签栏高度 token `tab_bar_default_height` 同档 */
const BAR_HEIGHT: number = 56;
/** 胶囊宽度（vp）：官方悬浮页签栏的 small 档 */
const BAR_WIDTH: number = 200;
/** 右侧「＋」直径（vp）：与胶囊同高，两个控件底边对齐时视觉最稳 */
const FAB_SIZE: number = 56;
/**
 * 悬浮层距布局底边 / 左右边的间距（vp）。
 * 取官方 `padding_level8`(16vp)：布局区取消沉浸后已经让开了底部手势安全区，
 * 这 16vp 就是纯呼吸量，不再需要额外补避让区。
 */
const BAR_MARGIN: number = 16;

/* ── 点击动效参数（2026-10-21 需求方：「点击按钮时图标的动画，包括点击增加按钮的弹性反馈动画」）── */

/** 页签图标点击时的放大倍数：幅度小一点，太大像“抖” */
const TAB_BOUNCE_SCALE: number = 1.22;
/** 弹大阶段时长（毫秒）：短、用 `Curve.Sharp` 冲出去 */
const TAB_BOUNCE_UP_MS: number = 120;
/** 回弹阶段时长（毫秒）：长一点 + 弹簧曲线，收尾带轻微过冲 */
const TAB_BOUNCE_BACK_MS: number = 260;
/** 「＋」按下压到的缩放：0.9 就够，太小会显得掉进屏幕 */
const FAB_PRESS_SCALE: number = 0.9;
/** 按下 / 松手两段时长（毫秒） */
const FAB_PRESS_MS: number = 90;
const FAB_RELEASE_MS: number = 320;

@ComponentV2
export struct MainTabBar {
  /**
   * 任务列表的 Scroller，由外层 `A_Main` 创建并透传给 `A_TaskList` 的 `List`；
   * 外层还要用它 `bindToScrollable`（标题栏跟手的前提），所以必须是同一个对象。
   */
  @Require @Param scroller: Scroller;
  /** 设置页的 Scroller（同上，给 `bindToScrollable` 用） */
  @Require @Param settingsScroller: Scroller;
  /** 任务列表的「数据 ＋ 编辑态」store：右侧按钮按它切「添加 / 删除」 */
  @Require @Param store: TaskListStore;
  /** 当前页签下标，报给外层：标题栏按钮与标题模式要按页签变 */
  @Event onIndexChange: (index: number) => void = () => {};
  /** 右侧圆形按钮的「添加」 */
  @Event onAdd: () => void = () => {};
  /** 编辑态删完一批之后通知外层（带上删掉的条数，外层给 toast 反馈） */
  @Event onDeleteDone: (count: number) => void = () => {};

  /** 视觉个性化：M3 色系（选中态 = `primary`） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 正在做点击弹动的页签下标（-1 ＝ 没有）与它此刻的缩放值 */
  @Local bounceIndex: number = -1;
  @Local bounceScale: number = 1;

  /** 「＋」按下时的整体缩放（弹性反馈用） */
  @Local fabScale: number = 1;

  /**
   * 底部手势条/导航栏高度（vp）。
   * 窗口全屏后页面铺到屏幕物理底，悬浮层要自己让开这一截，否则又会贴住手势条。
   */
  @Local bottomInsetVp: number = 0;

  aboutToAppear(): void {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    WindowInsets.bottomPx(context).then((px: number) => {
      this.bottomInsetVp = px > 0 ? this.getUIContext().px2vp(px) : 0;
    });
  }

  /**
   * 当前页签下标：**由本组件自己持有**。
   * 原来这个状态在 `HdsTabs` 里，页签栏一自绘就没了，只能自己管：
   *  · 点胶囊 → 改 `index` → `Tabs(index)` 跟着切内容；
   *  · 同时 `onIndexChange` 报给外层（标题文字、FREE/MINI 标题模式靠它）。
   */
  @Local index: number = 0;

  /** 右侧那颗按钮当前的图标：普通态＝`plus`；编辑态＝`trash` */
  @Computed
  get slotSymbol(): Resource {
    return this.store.editing ? $r('sys.symbol.trash') : $r('sys.symbol.plus');
  }

  /**
   * 图标颜色：普通态＝主题 `primary`（这也是「页签支持主题取色」的另一半，
   * 见文件头 1：编辑态的删除按钮沿用旧规则 —— 没勾选时压成 `onSurfaceVariant`、勾选后变警示红）。
   */
  @Computed
  get slotColor(): ResourceColor {
    if (!this.store.editing) {
      return this.themeStore.scheme.primary;
    }
    return this.store.canDelete ? $r('sys.color.ohos_id_color_warning') : this.themeStore.scheme.onSurfaceVariant;
  }

  /** 右侧按钮的无障碍文案（图标按钮没有文字，读屏靠它） */
  @Computed
  get slotLabel(): Resource {
    return this.store.editing ? $r('app.string.action_delete') : $r('app.string.action_add_task');
  }

  /**
   * 胶囊里的一个页签。
   *
   * `selected` 不用传参、直接读 `this.index`：V2 下 `@Builder` 的值参数不会触发刷新，
   * 而读 `@Local` 会被记进依赖里 —— 点一下页签，两个图标一起换色就是这么来的。
   */
  @Builder
  tabItem(tabIndex: number, symbolNormal: Resource, symbolSelected: Resource, label: Resource) {
    Column() {
      SymbolGlyph(this.index === tabIndex ? symbolSelected : symbolNormal)
        .fontSize($r('sys.float.subheader_right_icon_size'))
        // 选中＝主题色实心，未选中＝次级文字色描边（M3 的 tab 就是靠形状 + 颜色两级区分）
        .fontColor([this.index === tabIndex
          ? this.themeStore.scheme.primary
          : this.themeStore.scheme.onSurfaceVariant])
        // 点击时弹一下：只有被点中的那个页签会放大（`bounceIndex` 记的是下标）
        .scale({
          x: this.bounceIndex === tabIndex ? this.bounceScale : 1,
          y: this.bounceIndex === tabIndex ? this.bounceScale : 1
        })
    }
    .width(BAR_WIDTH / 3)
    .height(BAR_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .accessibilityText(label)
    .onClick(() => {
      // 点已选中的页签也照样给一次弹性反馈（只是不切页），否则点了没反应像坏了
      this.playTabBounce(tabIndex);
      if (this.index === tabIndex) {
        return;
      }
      this.index = tabIndex;
      this.onIndexChange(tabIndex);
    })
  }

  /**
   * 页签图标的点击弹性动画（需求方 2026-10-21：「点击按钮时图标的动画」）。
   *
   * 用 `keyframeAnimateTo` 一次描述两段（先弹大、再回弹到原尺寸），
   * 而不是连着调两次 `animateTo` —— 后者两段的起点会被第二段的闭包覆盖，弹不回原尺寸。
   * 弹簧参数 `springMotion(0.32, 0.72)` 是官方给出的「跟手 + 轻微过冲」那一档。
   */
  private playTabBounce(tabIndex: number): void {
    this.bounceIndex = tabIndex;
    this.bounceScale = 1;
    this.getUIContext().keyframeAnimateTo({ iterations: 1 }, [
      {
        duration: TAB_BOUNCE_UP_MS,
        curve: Curve.Sharp,
        event: () => {
          this.bounceScale = TAB_BOUNCE_SCALE;
        }
      },
      {
        duration: TAB_BOUNCE_BACK_MS,
        curve: curves.springMotion(0.32, 0.72),
        event: () => {
          this.bounceScale = 1;
        }
      }
    ]);
  }

  /** 悬浮胶囊（三个页签：任务列表 / 板板 / 设置） */
  @Builder
  tabPill() {
    Row() {
      // 未选中图标取的是「选中图标的未填充版」：与右侧设置页签同一套规则
      // （`gearshape` / `gearshape_fill`），M3 的页签只靠「描边 → 实心」的形状差区分，
      // 所以不再用另一个 glyph（原来这里是不成套的 `list_checkmark`）。
      this.tabItem(0, $r('sys.symbol.checkmark_circle'), $r('sys.symbol.checkmark_circle_fill'),
        $r('app.string.tab_task_list'))
      // 板板：带 ddl 任务的甘特视图（放在任务与设置之间）
      this.tabItem(1, $r('sys.symbol.calendar'), $r('sys.symbol.calendar'),
        $r('app.string.tab_banban'))
      this.tabItem(2, $r('sys.symbol.gearshape'), $r('sys.symbol.gearshape_fill'),
        $r('app.string.tab_settings'))
    }
    .width(BAR_WIDTH)
    .height(BAR_HEIGHT)
    .borderRadius(BAR_HEIGHT / 2)
    // 底色取 M3 的「高一层容器色」：比页面 `surface` 深一档，悬浮感靠它 + 阴影，不靠描边
    .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
    // 2026-10-21 需求方：「为底部页签增加阴影」→ 换成更散更浅的悬浮投影（见 Theme.FLOATING_SHADOW_*）
    .shadow({
      radius: Theme.FLOATING_SHADOW_RADIUS,
      color: Theme.FLOATING_SHADOW_COLOR,
      offsetY: Theme.FLOATING_SHADOW_OFFSET_Y
    })
  }

  /**
   * 右下角悬浮「＋」。
   *
   * 普通态＝添加；编辑态＝删除（**一条没勾时点它不做事**，图标那一刻也是灰的）。
   * 编辑态**不直接删**，先弹官方警告弹窗让人确认（见 `confirmDelete`）。
   */
  @Builder
  fabButton() {
    Column() {
      SymbolGlyph(this.slotSymbol)
        .fontSize($r('sys.float.subheader_right_icon_size'))
        .fontColor([this.slotColor])
    }
    .width(FAB_SIZE)
    .height(FAB_SIZE)
    .borderRadius(FAB_SIZE / 2)
    .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
    .justifyContent(FlexAlign.Center)
    // 悬浮投影（与左侧胶囊同一档，见 Theme.FLOATING_SHADOW_*）
    .shadow({
      radius: Theme.FLOATING_SHADOW_RADIUS,
      color: Theme.FLOATING_SHADOW_COLOR,
      offsetY: Theme.FLOATING_SHADOW_OFFSET_Y
    })
    // 按下的整体缩放：按下压到 0.9、松手用弹簧弹回 —— 需求方 2026-10-21：「点击增加按钮的弹性反馈动画」
    .scale({ x: this.fabScale, y: this.fabScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.getUIContext().animateTo({ duration: FAB_PRESS_MS, curve: Curve.FastOutSlowIn }, () => {
          this.fabScale = FAB_PRESS_SCALE;
        });
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.getUIContext().animateTo({
          duration: FAB_RELEASE_MS,
          curve: curves.springMotion(0.35, 0.7)
        }, () => {
          this.fabScale = 1;
        });
      }
    })
    // 给个稳定 id：UI 自动化（`devecocli ui click --id`）与走查都要用它定位这颗按钮
    .id('addTaskButton')
    .accessibilityText(this.slotLabel)
    .onClick(() => {
      if (this.store.editing) {
        if (this.store.canDelete) {
          this.confirmDelete();
        }
        return;
      }
      this.onAdd();
    })
  }

  /**
   * 删除前先确认（需求方 2026-10-16：「给删除按钮加上 AlertDialog 用户确认删除后才能删除」）。
   * 弹窗本体走 `utils/DeleteConfirmDialog.showDeleteConfirmDialog`，与详情页的步骤删除、删除任务同一份实现。
   */
  private confirmDelete(): void {
    const count: number = this.store.selectedCount;
    if (count === 0) {
      return;
    }
    showDeleteConfirmDialog(this.getUIContext(), $r('app.string.action_delete'),
      $r('app.string.delete_confirm_message', count), () => {
        const removed: number = this.store.deleteSelected();
        if (removed > 0) {
          this.onDeleteDone(removed);
        }
      });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 内容容器：`barHeight(0)` 把官方页签栏整条隐掉，只留 TabContent 的切页能力；
      // 这样两个页面在切页时不会被销毁重建（滚动位置、临时展开态都还在）。
      // ⚠️ 不能改成 `if (index === 0) ... else ...`：那样切一次页就重建一次页面，列表滚动位置会跳回顶部。
      Tabs({ barPosition: BarPosition.End, index: this.index }) {
        TabContent() {
          A_TaskList({ scroller: this.scroller, store: this.store })
        }

        TabContent() {
          C_Banban({ store: this.store })
        }

        TabContent() {
          // 设置页要 store 只为一件事：「清空全部任务」
          A_Settings({ store: this.store, scroller: this.settingsScroller })
        }
      }
      .barHeight(0)
      .scrollable(false)
      .animationDuration(0)
      .onChange((index: number) => {
        // 只同步状态，不回调 `onIndexChange`（点页签那条路径已经报过了，避免重复通知外层）
        this.index = index;
      })
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeStore.scheme.surface)

      // 底部悬浮层：胶囊贴左、＋贴右，二者同底边
      Row() {
        this.tabPill()
        Blank()
        this.fabButton()
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
      .padding({ left: BAR_MARGIN, right: BAR_MARGIN, bottom: BAR_MARGIN + this.bottomInsetVp })
      // 中间那段空白**不能挡列表滚动**：只在两个实体控件上接事件，别处穿透给下面的列表
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%')
    .height('100%')
  }
}

