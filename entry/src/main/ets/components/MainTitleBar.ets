/*
 * 标题栏（`HdsNavigation` 的 titleBar）配置：模糊样式 + 右上角按钮。
 *
 * 右上角**不用下拉菜单**了（需求方 2026-10-15：「右上角编辑和搜索用两个按钮替代，不需要用选项按钮」）：
 * 官方 `menu.value` 本来就支持**内联多项**（最多 3 个，超出才折叠成「更多」），所以
 * 「任务列表＝编辑 + 搜索两个图标按钮」「设置＝关于一个图标按钮」直接列出来即可。
 * 这样也删掉了原来那套 `componentId` + `promptAction.openMenu` + 自建 `Menu/MenuItem` 的复杂度。
 * 图标一律取官方 HarmonyOS Symbol。
 *
 * ── 2026-10-20 修「对官方组件重绘了，不许重绘」（需求方截图标注，任务列表 + 设置页两个右上角按钮）──
 * 症状：未滚动时右上角是**深灰圆 + 深色图标**，图标几乎看不见（取色实测：圆 #292929、图标 #3A3C3B）。
 * 根因有两条，都在这个文件里：
 *  1. **图标色被我们自己刷了**：之前每个菜单项的 `icon` 都写成
 *     `new SymbolGlyphModifier($r('sys.symbol.x')).fontColor([Theme.STATUS_BAR_CONTENT])`，
 *     而 `Theme.STATUS_BAR_CONTENT` 是**深色** `#1A1A1A`。HDS 在「未滚动」态给图标垫的底
 *     是它自己的**深色**半透圆（immersive 那套「提亮压暗」），它**期待白色图标** → 深底压深图标。
 *     官方示例（《设置标题栏沉浸式样式》）写的是 `icon: $r('sys.symbol.search_things')`——
 *     **直接给 symbol 资源，颜色交给 HDS**。`IconType = ResourceStr | SymbolGlyphModifier | PixelMap`
 *     （HdsNavigation 文档 `IconType` 一节），所以这里改回裸 `$r()`，不再自己刷色 = 不重绘。
 *  2. **圆底配错了字段**：`HdsTitleBarContentStyle` 里右上角菜单读的是 `menuStyle`，
 *     `backIconStyle` 只管**返回箭头**。之前只配了 `backIconStyle`（本页 `hideBackButton(true)`，
 *     根本用不上），`menuStyle` 一直是 HDS 默认值 → 所以圆底没被我们统一过。
 *     现在两态（`originalStyle` / `scrollEffectStyle`）都显式给 `menuStyle`，观感一致。
 *
 * ── 2026-10-20 修「顶部透出滚动内容」（需求方截图标注，任务列表滚动时）──
 * 标题栏背板原来是 `#F2`+surface（95% 半透），且「未滚动态→滚动态」之间有一段**线性过渡窗口**
 * （`blurEffectiveStartOffset` / `blurEffectiveEndOffset` 之间），窗口里背板是半透的。
 * 于是滚动初期，底下的卡片会以「幽灵文字」从标题栏透出来，再往下又是 Chip 行**实色**背板 →
 * 一段虚一段实。现在：过渡窗口收到 8vp（`PLATE_SOLID_OFFSET_VP`）、背板改**完全不透明**的 `surface`，
 * 滚动一开始顶部就是实色，与 Chip 行背板接成一整块（同系统「设置 / 备忘录」的做法）。
 */
import {
  HdsNavigationIconItemStyle,
  HdsNavigationMenuContentOptions,
  HdsNavigationMenuItemOptions,
  ScrollEffectType,
  TextStyleMode,
  TitleBarStyleOptions
} from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';

export class MainTitleBar {
  /**
   * 内容区顶部要空出来的高度（vp）。
   *
   * 来历：`HdsNavigation` 的标题栏是**浮层**，尾随闭包里的内容从容器顶部开始，所以内容必须自己让开。
   * 112 这个数出自 HdsNavigation 文档 `HdsNavigationTitleMode` 枚举说明的原文：
   * 「FULL：只有主标题时，标题栏高度为 112vp；同时有主标题和副标题时，标题栏高度为 138vp」。
   * 我们标题栏只有主标题（`mainTitle`）、且未改 `titleMode`（默认 FREE，未滚动时高度与 FULL 一致）→ 取 112。
   * 若以后加了副标题，这里要改成 138。
   */
  static readonly CONTENT_TOP_OFFSET_VP: number = 112;

  /**
   * **二级页**（`HdsNavDestination`）标题栏的高度（vp）。
   *
   * 官方原文：`titleMode` 默认 `MINI`，「MINI：固定为小标题模式。标题栏高度为 56vp」。
   * 与本文件上面那个 112 是两回事：那是主页 `HdsNavigation` 的 FREE 档。
   *
   * ⚠️ 这只是**标题栏自己**的高度，**不含状态栏**。窗口是全屏的
   * （`EntryAbility.setupWindow` → `setWindowLayoutFullScreen(true)`），而 `HdsNavDestination` 只把
   * 标题栏自己让开状态栏、**内容区仍从窗口顶端开始** —— 所以页面里内容顶部让白必须写成
   * 「状态栏高度 + 本值」，见 `B_TaskDetail` / `B_Search` 的 `statusBarVp`。
   * 2026-10-21 实测证据（Mate 90 Pro 模拟器，密度 3.5）：`HdsTitleBar` y=137→332px
   * （=状态栏 39.1vp + 标题栏 56vp），而内容 `Scroll` y=196px（=只让了 56vp）→ 大标题压在小标题上。
   */
  static readonly SUB_PAGE_TITLE_BAR_VP: number = 56;

  /**
   * 标题栏「从透明过渡到实色背板」的滚动距离（vp）。
   *
   * 官方 `blurEffectiveEndOffset` 的默认值（SDK `@hms.hds.hdsBaseComponent.d.ets` L1353-1354 原文）是
   * 「`LengthMetrics.vp(8)` for COMMON_BLUR mode and GRADIENT_BLUR mode, `LengthMetrics.vp(56)` for
   * GRADUAL_BLUR mode」——**`IMMERSIVE_GRADIENT_BLUR` 没有单独声明默认值（未取证）**。
   * 不管默认是哪一档，这里都显式钉 8vp：手指一动（8vp ≈ 一行字的一半）背板就到位，
   * 不给「半透过渡窗口」留机会（需求方截图标注那处：滚动时顶部透出底下的卡片）。
   */
  static readonly PLATE_SOLID_OFFSET_VP: number = 56;

  /**
   * 图标圆底的半透暖色（与标题栏背板同源，只是这里要透一点，压住滚动内容又不抢眼）。
   * `#F2` = 95% 不透明，`surface.substring(1)` 取 6 位 RGB —— 与页面/背板同一个色相。
   */
  static iconPlate(surface: string): string {
    return `#F2${surface.substring(1)}`;
  }

  /**
   * 标题栏样式（**只配置官方字段，不自己画**）。
   *
   * 传入的是 M3 `surface` 与 `onSurface`，两处推导：
   *  · 标题栏背板（`scrollEffectStyle.backgroundStyle.backgroundColor`）= `surface` **不透明**，
   *    滚起来就与页面上方的 Chip 行背板连成一块实色（历史原因见文件头 2026-10-20 那一段）；
   *  · 右上角图标圆底（`menuStyle` / `backIconStyle.backgroundColor`）= 同源 95% 半透暖色。
   *
   * ⚠️ 两套 `contentStyle` 都要给 `menuStyle`：`originalStyle` 是「未滚动」，`scrollEffectStyle` 是
   * 「滚动后」。只给一套的话两态观感不一致（历史踩坑：未滚动是深色圆、滚动后变浅色圆）。
   * 也别再用 `SymbolGlyphModifier.fontColor()` 刷图标色 —— 那是「重绘官方组件」，
   * 图标色统一走这里的 `iconColor`（已与需求方 2026-10-20 确认按这个方案改）。
   */
  static style(surface: string, onSurface: ResourceColor): TitleBarStyleOptions {
    const plate: string = MainTitleBar.iconPlate(surface);
    const menuStyle: HdsNavigationIconItemStyle = {
      backgroundColor: plate,
      iconColor: onSurface,
      // 2026-10-20 补：编辑态右上角是**纯文字**按钮（取消 / 全选），它吃 `textColor` 而不是 `iconColor`。
      // 只配 `iconColor` 时 HDS 的默认 `textColor` 在「未滚动」态是浅色（它假设沉浸深底），
      // 取消沉浸后压在我们浅色页面上就是**白字看不见**（实测：两个字只剩一圈淡淡药丸轮廓）。
      textColor: onSurface
    };
    return {
      // 2026-10-20 取消全屏沉浸后换成 `GRADIENT_BLUR`：
      //  · 官方对它的定位原文是「渐变模糊……**此方式适用于列表型非沉浸式场景**」，正是本页；
      //  · `IMMERSIVE_GRADIENT_BLUR` 是给沉浸图文场景的，实测在**非沉浸布局**下只出模糊、**背板不填色**
      //    （截图可见标题后面透出模糊的卡片文字），而且它是 6.1.0(23) 的 API，本来就超 target 22。
      //  · `GRADIENT_BLUR` 起始 6.0.0(20)，在 target 6.0.2(22) 内，风险表里那一行 🔴 也一并消掉。
      //
      // ⚠️ `enableScrollEffect` 必须为 **true**（2026-10-20 晚回滚）：
      // 它是「标题随滚动跟手收缩」的驱动。关掉之后实测标题栏**一动就瞬间收到 56vp**
      //（滚动 ~16vp 时标题栏已经是 55.7vp，而 Chip 行还在按 1:1 往下滑到 ~60vp），
      // 于是 Chip 行和标题的滑动动画完全对不上 —— 正是需求方 2026-10-20 第 1 条反馈。
      // 背板透明度不再是问题：滚动区上方那块不透明底色由 `A_TaskList` 的 Chip 冻结层负责
      //（它一路铺到屏幕顶端），HDS 自己的背板画不画都无所谓了。
      scrollEffectOpts: {
        scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
        enableScrollEffect: true,
        // 过渡窗压到 8vp：滚动一开始背板样式就到位，不留给内容「幽灵式透出」的机会
        blurEffectiveStartOffset: LengthMetrics.vp(0),
        blurEffectiveEndOffset: LengthMetrics.vp(MainTitleBar.PLATE_SOLID_OFFSET_VP)
      },
      // 唯一的样式：**不透明背板** + 深色文字/图标
      originalStyle: {
        backgroundStyle: {
          backgroundColor: surface,
          maskExtraHeight: 56.0
        },
        contentStyle: {
          titleStyle: { mainTitleColor: onSurface },
          menuStyle: menuStyle,
          backIconStyle: { backgroundColor: plate, iconColor: onSurface }
        }
      },
      // `scrollEffectStyle` 留一份同样的配置：万一以后有人把 `enableScrollEffect` 打开，两态也不会打架
      scrollEffectStyle: {
        backgroundStyle: {
          backgroundColor: surface,
          maskExtraHeight: 56.0
        },
        contentStyle: {
          titleStyle: { mainTitleColor: onSurface },
          menuStyle: menuStyle,
          backIconStyle: { backgroundColor: plate, iconColor: onSurface }
        }
      }
      // 2026-10-20：`systemMaterialEffect`（沉浸光感材质，6.1.0(23)+）**删掉** ——
      // 它是「沉浸」那套的材质，取消全屏沉浸后不再适用；而且它是 6.1.0(23) 的 API，超 target 22。
    };
  }

  /**
   * 任务列表页的右上角：**两个内联图标按钮**（多选 / 搜索），不是下拉。
   * （需求方 2026-10-15：「右上角编辑和搜索用两个按钮替代，不需要用选项按钮」）
   * 官方 `menu.value` 最多内联显示 3 项，所以 2 项就是两个按钮，不会折叠成「更多」。
   *
   * 图标（都是官方 HarmonyOS Symbol）：
   *  · 多选：**`checkmark_square_on_square`**（方框上叠一个勾选框）。
   *    ⚠️ 原来用的是 `square_and_pencil`（方框+笔），需求方 2026-10-16：「换一个吧 要表示那种多选删除
   *    而不是表示成修改卡片内容」—— 那个图标读起来是"编辑内容"，而这个跟卡片上真正出现的勾选框同族
   *    （卡片的勾选态是 `checkmark_square_fill`），语义对得上。无障碍文案也一并改成「多选」。
   *  · 搜索：`magnifyingglass`。
   *
   * ⚠️ 图标**只给 symbol 资源**，不要再包 `SymbolGlyphModifier.fontColor(...)`：颜色归 HDS 的
   * `style.contentStyle.menuStyle.iconColor` 管（需求方 2026-10-20：「对官方组件重绘了，不许重绘」）。
   */
  static taskListMenu(onEdit: () => void, onSearch: () => void): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: $r('app.string.menu_multi_select'),
            icon: $r('sys.symbol.checkmark_square_on_square'),
            isEnabled: true,
            action: onEdit
          }
        },
        {
          content: {
            label: $r('app.string.menu_search'),
            icon: $r('sys.symbol.magnifyingglass'),
            isEnabled: true,
            action: onSearch
          }
        }
      ]
    };
  }

  /** 设置页的右上角：**单个「关于」图标按钮**（官方 Symbol `info_circle`），同样不是下拉 */
  static settingsMenu(onAbout: () => void): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: $r('app.string.menu_about'),
            icon: $r('sys.symbol.info_circle'),
            isEnabled: true,
            action: onAbout
          }
        }
      ]
    };
  }

  /**
   * 任务详情（二级页）的右上角：**响铃 + 删除**两个图标按钮（需求方 2026-10-17）。
   *
   * · 响铃**只在有提醒时间时出现** —— 与列表卡片那条规则完全对齐（`TaskCard.remindSwitch`
   *   也是「`remindAt` 为空就整个不显示」），否则单独一个铃铛会指向一个不存在的提醒；
   * · 图标反映**用户意图** `alarm`（字段表第 16 项）：开＝铃铛 `bell`、关＝带斜杠 `bell_slash`；
   *   点它走 `TaskListStore.setRemind` —— 与卡片 Switch **同一个写入口**，两边永远一致；
   * · 删除放最后一位（官方 `menu.value` 最多内联 3 项，2 项不会折叠成「更多」）。
   *
   * 参数：`hasRemind = remindAt !== undefined`、`remindOn = alarm === ON`。
   */
  static detailMenu(hasRemind: boolean, remindOn: boolean,
    onToggleRemind: () => void, onDelete: () => void): HdsNavigationMenuContentOptions {
    const items: HdsNavigationMenuItemOptions[] = [];
    if (hasRemind) {
      items.push({
        content: {
          label: remindOn ? $r('app.string.action_remind_off') : $r('app.string.action_remind_on'),
          icon: remindOn ? $r('sys.symbol.bell') : $r('sys.symbol.bell_slash'),
          isEnabled: true,
          action: onToggleRemind
        }
      });
    }
    items.push({
      content: {
        label: $r('app.string.action_delete_task'),
        icon: $r('sys.symbol.trash'),
        isEnabled: true,
        action: onDelete
      }
    });
    return { value: items };
  }

  /**
   * **编辑（多选）模式**的右上角：两个**纯文字**按钮 —— 取消 / 全选
   * （需求方 2026-10-16：「导航栏右上角两个按钮变成取消和全选」）。
   *
   * 纯文字项的官方写法：给 `label` + `type: TextStyleMode.NORMAL`、**不给 `icon`**（§2.4 实测可行）。
   * 注意这里仍然是**内联两项**（官方 `menu.value` 最多内联 3 项），不会折叠成「更多」。
   */
  static editModeMenu(onCancel: () => void, onSelectAll: () => void): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: $r('app.string.action_cancel'),
            type: TextStyleMode.NORMAL,
            isEnabled: true,
            action: onCancel
          }
        },
        {
          content: {
            label: $r('app.string.action_select_all'),
            type: TextStyleMode.NORMAL,
            isEnabled: true,
            action: onSelectAll
          }
        }
      ]
    };
  }
}
