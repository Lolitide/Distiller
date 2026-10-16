/*
 * 标题栏（`HdsNavigation` 的 titleBar）配置：模糊样式 + 右上角按钮。
 *
 * 右上角**不用下拉菜单**了（袁正锟 2026-10-15：「右上角编辑和搜索用两个按钮替代，不需要用选项按钮」）：
 * 官方 `menu.value` 本来就支持**内联多项**（最多 3 个，超出才折叠成「更多」），所以
 * 「任务列表＝编辑 + 搜索两个图标按钮」「设置＝关于一个图标按钮」直接列出来即可。
 * 这样也删掉了原来那套 `componentId` + `promptAction.openMenu` + 自建 `Menu/MenuItem` 的复杂度。
 * 图标一律取官方 HarmonyOS Symbol。
 */
import { HdsNavigationMenuContentOptions, ScrollEffectType, TextStyleMode, TitleBarStyleOptions } from '@kit.UIDesignKit';
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

  static readonly STYLE: TitleBarStyleOptions = {
    scrollEffectOpts: {
      enableScrollEffect: true,
      scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
      blurEffectiveStartOffset: LengthMetrics.vp(0),
      blurEffectiveEndOffset: LengthMetrics.vp(20)
    },
    scrollEffectStyle: {
      backgroundStyle: { maskExtraHeight: 56.0 }
    }
  };

  /**
   * 任务列表页的右上角：**两个内联图标按钮**（多选 / 搜索），不是下拉。
   * （袁正锟 2026-10-15：「右上角编辑和搜索用两个按钮替代，不需要用选项按钮」）
   * 官方 `menu.value` 最多内联显示 3 项，所以 2 项就是两个按钮，不会折叠成「更多」。
   *
   * 图标（都是官方 HarmonyOS Symbol）：
   *  · 多选：**`checkmark_square_on_square`**（方框上叠一个勾选框）。
   *    ⚠️ 原来用的是 `square_and_pencil`（方框+笔），袁正锟 2026-10-16：「换一个吧 要表示那种多选删除
   *    而不是表示成修改卡片内容」—— 那个图标读起来是"编辑内容"，而这个跟卡片上真正出现的勾选框同族
   *    （卡片的勾选态是 `checkmark_square_fill`），语义对得上。无障碍文案也一并改成「多选」。
   *  · 搜索：`magnifyingglass`。
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
   * **编辑（多选）模式**的右上角：两个**纯文字**按钮 —— 取消 / 全选
   * （袁正锟 2026-10-16：「导航栏右上角两个按钮变成取消和全选」）。
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
