/*
 * 底部页签栏（独立组件）—— `HdsTabs` 容器、两个页签、悬浮样式、右侧圆形「添加」按钮都归这个文件。
 *
 * 布局（需求方 2026-10-16：「不用 minibar 了…改成左边页签、右边一个圆形的添加图标按钮…我们不需要它展开」，
 * 随后又要求「添加按钮能不能像左侧页签一样半透明质感」）：
 *   左＝官方悬浮页签栏（任务列表 / 设置），右＝**一颗圆形的「+」**，点一下只触发添加、不会展开/收起任何东西，
 *   并且**与左侧药丸同一层半透明材质**。
 *
 * 三件事都是实测定的，逐条记清楚，免得以后又被"看起来可以"的写法带偏：
 *
 * ① **右边那颗圆钮不能放迷你栏的内容里**。官方迷你栏没有"禁止展开"的开关（`HdsTabsMiniBar` 字段表里没有，
 *    控制器那三个 `apply*` 又是 6.1.0(23)），而且折叠/展开是**整套**的（`HdsTabsBarChangeMode.USER_CLICK`：
 *    「用户通过点击折叠的迷你栏或页签栏触发样式和宽度更新」）—— 实测把迷你栏宽度三档钉死 56vp + 初始 `EXPAND`，
 *    点一下**页签栏自己就塌成只剩图标的小圆**（`.cache/v3-02.png`）。
 *
 * ② **右侧仍然借迷你栏占一个槽位，但视觉全交给官方**。它一缺席，官方悬浮页签栏就把 200vp 的药丸**居中**
 *    （`.cache/v2-01.png`：药丸跑到屏幕中央、左边空一大块），而 `HdsTabsAttribute` 只继承 `CommonMethod`、
 *    没有任何"页签栏水平对齐"的口子 → 槽位必须留着。槽位里放**官方示例那套内容**（无底色图标格 + 文字，
 *    收起时被官方裁剪成只剩居中的「+」），这样槽位自己画出来的就是"跟随页签栏背景"的那层材质。
 *    ⚠️ 实测：槽位内容换成**空 `Column`** 时，同一层背景会渲染成灰的（(237,238,239)，比页面背景 (240,243,245) 还暗）；
 *    放官方那套内容才与左侧药丸一致（(247~249) vs 药丸 (249,250,251)）。所以这里刻意**不**用空占位。
 *
 * ③ **点击由叠在槽位正上方的透明 `Button` 接住**。它挡住下面槽位的命中测试 → 迷你栏那套折叠/展开永远收不到点击；
 *    它自己只干两件事：`onAdd()` 与无障碍文本。实测验过：点它前后两张截图除状态栏时钟外整屏零差异。
 *
 * 另记两条官方事实：
 *   · 迷你栏与页签栏样式是**互补**的：迷你栏 `EXPAND` ⇄ 页签栏 `COLLAPSE`。要"图标 + 文字"的完整药丸就得
 *     把迷你栏设成 `COLLAPSE`（设 `EXPAND` 反把药丸挤成小圆，见 `.cache/v4-01.png`）。
 *   · `barFloatingStyle` 整体标注 6.1.0(23)，在 target 6.0.2(22) 真机上按官方惯例**版本隔离、不生效**（未在 22 上验证）。
 *
 * 对外只暴露两个事件：页签切换、点「添加」。页面下标由外层持有（标题栏按钮要按页签变）。图标一律取官方 HarmonyOS Symbol。
 */
import { hdsMaterial, HdsBarStyle, HdsTabs } from '@kit.UIDesignKit';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { ThemeStore } from '../utils/Theme';
import { A_TaskList } from '../pages/A_TaskList';
import { A_Settings } from '../pages/A_Settings';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { showDeleteConfirmDialog } from '../utils/DeleteConfirmDialog';

/**
 * 悬浮页签栏距**底部安全区**的间距（vp）。`barFloatingStyle.barBottomMargin` 这个字段 API 只吃 `Length`。
 * 取值 **16vp ＝官方 `padding_level8`**，也就是官方《沉浸光感》最佳实践里给 `barBottomMargin` 的兜底值
 * （那份示例写的是 `naviIndicatorHeight > 0 ? naviIndicatorHeight : $r('sys.float.padding_level8')`）。
 * 需求方 2026-10-16：「把整个 TabBar 往下移动 有点高了」→ 原先照悬浮栏示例用了裸数字 28，压到官方这一档。
 * 右侧那颗圆钮的点击区要与页签栏落在同一条水平线，所以**两处共用这一个常量**，不会各写一个数而漂移。
 */
const BAR_BOTTOM_MARGIN: number = 16;

/**
 * 右侧圆形「添加」的直径（vp），同时是迷你栏槽位的宽度。
 * 取值＝官方页签栏高度 token `tab_bar_default_height`（56vp）——实测官方那颗圆钮直径 ≈54~56vp，同档。
 * 写成数字是因为 `HdsTabsMiniBar.miniBarWidth` 要参与 HDS 的宽度计算，只吃普通 `Length`。
 */
const ADD_BUTTON_SIZE: number = 56;

/*
 * 页签图标：**未选中用官方次级图标色、选中用 M3 primary**（2026-10-19）。
 *
 * 之前这两个 BottomTabBarStyle 是模块级常量、选中态用系统默认蓝，
 * 换主题色时导航栏高亮不会跟着变。改成 @Computed getter 后，
 * ccentIndex 一变就重新生成样式 —— 作者要求的「导航栏高亮着色」就是这一处。
 *
 * 注意 on-* 规则：图标色直接取 primary（不做底色搭配），没有跨角色混用问题。
 * 未选中态用官方 sys.color.icon_secondary（中性色仍走官方 token，见已确认的混合方案）。
 */

@ComponentV2
export struct MainTabBar {
  /**
   * 任务列表的 Scroller，由外层 `A_Main` 创建并透传给 `A_TaskList` 的 `List`；
   * 外层还要用它 `bindToScrollable`（标题栏跟手的前提），所以必须是同一个对象。
   */
  @Require @Param scroller: Scroller;
  /** 设置页的 Scroller（同上，给 indToScrollable 用，让大标题在设置页也跟手收缩） */
  @Require @Param settingsScroller: Scroller;
  /** 任务列表的「数据 ＋ 编辑态」store（页面持有、按引用共享）：底部这颗按钮按它切「添加 / 删除」 */
  @Require @Param store: TaskListStore;
  /** 当前页签下标，报给外层：标题栏按钮要按页签变（任务列表＝编辑+搜索；设置＝关于） */
  @Event onIndexChange: (index: number) => void = () => {};
  /** 右侧圆形按钮的「添加」 */
  @Event onAdd: () => void = () => {};
  /** 编辑态删完一批之后通知外层（带上删掉的条数，外层给 toast 反馈） */
  @Event onDeleteDone: (count: number) => void = () => {};

  /** 视觉个性化：M3 色系（导航栏高亮 = `primary`） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /**
   * 页签栏的渐变遮罩色（40% 透明）：**从 M3 `surfaceContainer` 派生**，不再写死。
   *
   * 之前这里是硬编码的 `'#66F1F3F5'`（官方示例里的冷灰蓝），所以不管主题色怎么换，
   * 页签栏永远是冷蓝灰 —— 与暖色主题拼在一起就是一道色块（作者 2026-10-19 截图标注）。
   * 官方 token 只有不透明 `ohos_id_color_sub_background` 和全透明两档、没有 40% 那档，
   * 所以从主题色算：`#66` ＋ `surfaceContainer` 的 RGB。
   */
  @Computed
  get barMaskColor(): string {
    const hex: string = this.themeStore.scheme.surfaceContainer;
    return `#66${hex.substring(1)}`;
  }

  /** 任务列表页签样式：未选中用官方次级图标色、**选中用 M3 `primary`** */
  @Computed
  get taskListTab(): BottomTabBarStyle {
    return new BottomTabBarStyle(
      {
        normal: new SymbolGlyphModifier($r('sys.symbol.list_checkmark'))
          .fontColor([$r('sys.color.icon_secondary')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.checkmark_circle_fill'))
          .fontColor([this.themeStore.scheme.primary])
      },
      // 2026-10-19 作者：「把字删掉即可」—— 页签**只留图标**。
      // 顺带解决了 `BottomTabBarStyle` 不开放 `selectedColor`、文字色永远是系统蓝的问题
      //（没有文字，自然没有这处不跟主题色）。
      ''
    );
  }

  /** 设置页签样式（同上） */
  @Computed
  get settingsTab(): BottomTabBarStyle {
    return new BottomTabBarStyle(
      {
        normal: new SymbolGlyphModifier($r('sys.symbol.gearshape'))
          .fontColor([$r('sys.color.icon_secondary')]),
        selected: new SymbolGlyphModifier($r('sys.symbol.gearshape_fill'))
          .fontColor([this.themeStore.scheme.primary])
      },
      ''
    );
  }

  /**
   * 右侧那颗圆钮当前的**图标**（需求方 2026-10-16：「Tabbar 里面的添加按钮变成删除按钮」）：
   * 普通态＝`plus`；编辑态＝`trash`（官方 Symbol 库里的 `trash`）。
   */
  @Computed
  get slotSymbol(): Resource {
    return this.store.editing ? $r('sys.symbol.trash') : $r('sys.symbol.plus');
  }

  /**
   * 图标颜色：普通态＝官方一级图标色；编辑态**没勾选任何任务时压成灰色的 `icon_tertiary`**、
   * 勾选后**高亮成警示红 `ohos_id_color_warning`**（删除是破坏性动作）。
   * （需求方 2026-10-16：「如果用户没有勾选任何一条任务 删除按钮灰色 勾选后按钮高亮可点击」）
   */
  @Computed
  get slotColor(): ResourceColor {
    if (!this.store.editing) {
      return $r('sys.color.icon_primary');
    }
    return this.store.canDelete ? $r('sys.color.ohos_id_color_warning') : $r('sys.color.icon_tertiary');
  }

  /** 展开态下那颗圆钮旁边的文字也要跟着换（收起态被官方裁剪，只露图标） */
  @Computed
  get slotLabel(): Resource {
    return this.store.editing ? $r('app.string.action_delete') : $r('app.string.action_add_task');
  }

  /**
   * 迷你栏槽位的内容 —— 照官方示例的结构：**无底色图标格 + 文字**，收起态被官方裁剪，只露出居中的图标。
   * 尺寸都用官方 token：格子 `titlebar_icon_background_height`(40vp) + 左右 `padding_level4`(8vp) → 收起态正好 56vp；
   * 图标 `subheader_right_icon_size`(24vp)；文字走官方字体阶梯 `body2`（比 `bottom_tab_text_size_normal` 大一号）。
   * 圆钮的**材质与图标都由它渲染**（`enableMiniBarBackground: true` ＝ 迷你栏背景跟随页签栏背景），
   * 我们的自绘件只负责点击（见 `addHitArea`），所以观感与左侧药丸完全同源。
   */
  @Builder
  rightSlotContent() {
    Row() {
      Column() {
        SymbolGlyph(this.slotSymbol)
          .fontSize($r('sys.float.subheader_right_icon_size'))
          .fontColor([this.slotColor])
      }
      .width($r('sys.float.titlebar_icon_background_height'))
      .height($r('sys.float.titlebar_icon_background_height'))
      .justifyContent(FlexAlign.Center)
      .margin({
        start: LengthMetrics.resource($r('sys.float.padding_level4')),
        end: LengthMetrics.resource($r('sys.float.padding_level4'))
      })

      Text(this.slotLabel)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
    }
    .height($r('sys.float.titlebar_icon_background_height'))
    .alignItems(VerticalAlign.Center)
    // 占满整条槽位：热区与裁剪才与官方示例一致（需求方 2026-10-15：「minibar 展开后整个 bar 都可以点击」）
    .width('100%')
  }

  /**
   * 叠在槽位正上方的**透明点击区**（常驻；点一下只触发添加，永不展开/收起）。
   * 只干两件事：① 接住点击 → `onAdd()`；② 按 ArkUI 默认命中测试规则**挡住它下面的槽位**，让官方那套折叠/展开收不到点击。
   * 视觉（材质 + 「+」）全在 `rightSlotContent` 里，所以这里**什么都不画**。
   *
   * ⚠️ 这里刻意用**空 `Column`** 而不是 `Button`：`Button` 自带一层画在按钮身下的默认"底"（阴影/样式），
   * 我们的底又是全透明的 → 那层会透出来把官方材质压灰。这是隔离实验量出来的（同一个槽位：
   * 叠 `Button` ＝ (235~237,238,239) 比页面背景还暗；叠空 `Column` ＝ (249,250,251)，与左侧药丸一致；
   * 期间还给 `Button` 试过 `backgroundColor(button_background_color_transparent)` 与
   * `.shadow({radius: 0, color: Transparent})`，都压不住那层）。代价：这颗"按钮"没有按压水波纹。
   */
  @Builder
  addHitArea() {
    Column()
      .width(ADD_BUTTON_SIZE)
      .height(ADD_BUTTON_SIZE)
      // 给个稳定 id：UI 自动化（`devecocli ui click --id`）与走查都要用它定位这颗按钮
      .id('addTaskButton')
      // 横向走本地化重载（`start`/`end`）：`right` 那一支只吃 `Length`、吃不了 `LengthMetrics`
      .margin({
        end: LengthMetrics.resource($r('sys.float.padding_level8')),
        bottom: LengthMetrics.vp(BAR_BOTTOM_MARGIN)
      })
      // 图标按钮没有文字，无障碍文本必须给（读屏要播报）；编辑态要说「删除」
      .accessibilityText(this.store.editing ? $r('app.string.action_delete') : $r('app.string.action_add_task'))
      .onClick(() => {
        // 普通态＝添加；编辑态＝删除（**一条没勾时点它不做事**，图标那一刻也是灰的）。
        // 编辑态**不直接删**，先弹官方警告弹窗让人确认（见 confirmDelete）。
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
   *
   * 弹窗本体走 `utils/DeleteConfirmDialog.showDeleteConfirmDialog` —— 与**详情页的步骤删除、
   * 删除任务**同一份实现（需求方 2026-10-17 要求三处样式一致）。原来这里给删除按钮加了
   * `style: DialogButtonStyle.HIGHLIGHT` + `defaultFocus: true`（高亮实心按钮），
   * 与详情页那份「红色警示文字」不一致，现已统一为后者。
   *
   * 🔴 **两个按钮之间那条灰色竖线去不掉**（需求方 2026-10-16：「弹窗去掉两个按钮之间的灰色竖线」）——
   * 已查证：`AlertDialogParam` 的**全部字段**里没有任何分隔线开关
   * （title / subtitle / message / autoCancel / cancel / alignment / offset / gridCount / maskRect /
   * showInSubWindow / isModal / backgroundColor / backgroundBlurStyle / backgroundEffect / onWillDismiss /
   * cornerRadius / transition / width / height / borderWidth / borderColor / borderStyle / shadow / textStyle /
   * enableHoverMode / hoverModeArea / onWillAppear / onDidAppear / onWillDisappear / onDidDisappear /
   * levelMode / levelUniqueId / immersiveMode / levelOrder / systemMaterial / primaryButton / secondaryButton /
   * buttons / buttonDirection），它是系统弹窗**固定样式**的一部分。
   * 也试过官方**高级组件 `ConfirmDialog`**（`import { ConfirmDialog } from '@kit.ArkUI'`，属于"组件化弹窗"）：
   * 那条竖线**照样有**，还多出一个没标签的空勾选圈 ✗ → 所以退回系统 `AlertDialog`。
   * 要真正去掉它，只剩"自己画弹窗内容"一条路（`openCustomDialog` + 自建 Column），
   * 代价是弹窗不再走官方样式 —— **已跟需求方说明，等他定**。
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
    // 页签栏在下、点击区在上（同处 BottomEnd）：点击区按默认命中测试规则会挡住它下面的迷你栏槽位 → 槽位收不到点击
    Stack({ alignContent: Alignment.BottomEnd }) {
      HdsTabs({ barPosition: BarPosition.End }) {
        TabContent() {
          A_TaskList({ scroller: this.scroller, store: this.store })
        }
        .tabBar(this.taskListTab)

        TabContent() {
          // 设置页要 store 只为一件事：「清空全部任务」。其余设置项与本机任务数据无关
          A_Settings({ store: this.store, scroller: this.settingsScroller })
        }
        .tabBar(this.settingsTab)
      }
      .vertical(false)
      .scrollable(false)
      .width('100%')
      .height('100%')
      .backgroundColor(this.themeStore.scheme.surfaceContainer)
      // —— 悬浮页签栏，逐项照官方示例 ——
      // barOverlap：TabBar 背后变模糊并叠加在 TabContent 之上（API 22 就能用）
      .barOverlap(true)
      .barFloatingStyle({
        barWidth: { smallWidth: 200, mediumWidth: 300, largeWidth: 400 },
        barBottomMargin: BAR_BOTTOM_MARGIN,
        // ⚠️ 示例的 mask 是 '#66F1F3F5'（40% 透明）。官方 token 只有不透明的
        // `ohos_id_color_sub_background`(#fff1f3f5) 和全透明的 `..._transparent`(#00ffffff)，
        // 没有 40% 那一档。为了「质感和官方一致」这里保留示例的字面值（已知偏离「不许裸色值」的约定）。
        // 2026-10-19 作者：「底部加上一段距离的渐变遮罩」——
        // 原来 maskHeight 92、且遮罩色与页面 surface 太接近，几乎看不出渐变；
        // 加高到 140，内容在栏下方有一段明显的淡出过渡。
        gradientMask: {
          maskColor: this.barMaskColor,
          maskHeight: 140
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        },
        // 右侧借它占位并**由它渲染那颗圆钮**（见文件头 ②③）：
        // · miniBarStyle 用 COLLAPSE —— 与页签栏互补，页签栏才是「图标 + 文字」的完整药丸；
        // · miniBarWidth 三档都钉成 56vp —— 万一状态被系统改掉（如旋转），也还是同样大小的圆钮、不会突然拉长；
        // · enableMiniBarBackground: true（官方默认）—— 圆钮那层半透明材质与左侧药丸同源。
        miniBar: {
          miniBarBuilder: () => {
            this.rightSlotContent();
          },
          miniBarStyle: HdsBarStyle.COLLAPSE,
          miniBarWidth: {
            smallWidth: ADD_BUTTON_SIZE,
            mediumWidth: ADD_BUTTON_SIZE,
            largeWidth: ADD_BUTTON_SIZE
          },
          enableMiniBarBackground: true
        }
      })
      .onChange((index: number) => {
        this.onIndexChange(index);
      })

      this.addHitArea()
    }
    .width('100%')
    .height('100%')
  }
}
