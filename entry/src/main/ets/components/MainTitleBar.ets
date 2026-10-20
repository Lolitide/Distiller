/*
 * 标题栏（`HdsNavigation` 的 titleBar）配置：模糊样式 + 右上角按钮。
 *
 * 右上角**不用下拉菜单**了（袁正锟 2026-10-15：「右上角编辑和搜索用两个按钮替代，不需要用选项按钮」）：
 * 官方 `menu.value` 本来就支持**内联多项**（最多 3 个，超出才折叠成「更多」），所以
 * 「任务列表＝编辑 + 搜索两个图标按钮」「设置＝关于一个图标按钮」直接列出来即可。
 * 这样也删掉了原来那套 `componentId` + `promptAction.openMenu` + 自建 `Menu/MenuItem` 的复杂度。
 * 图标一律取官方 HarmonyOS Symbol。
 */
import {
  hdsMaterial,
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
   * 标题栏样式。
   *
   * ⚠️ 2026-10-19 修「滚动后顶部一条深灰渐变、状态栏被压暗」：
   * `scrollEffectType: GRADIENT_BLUR`（滚动到一定偏移后标题栏浮起并做渐变模糊）
   * 本身就是要的效果，但那层**背板默认是深色的**，叠在暖色页面上就是一条脏灰色带、
   * 还把状态栏文字压得看不清。
   *
   * `HdsNavigationBackgroundStyle.backgroundColor` 能指定背板色，
   * 所以这里把它做成**带参方法**，由调用方传入当前主题的 `scheme.surface`，
   * 背板与页面同色、只保留模糊 —— 这才是「能隐约看到内容」的观感。
   *
   * 原来是 `static readonly STYLE`（常量拿不到主题色），改成静态方法。
   */
  static style(background: string, onSurface: ResourceColor): TitleBarStyleOptions {
    return {
      // 沉浸式渐变模糊（参考 MoMo/components/MoMoBasePage）
      scrollEffectOpts: {
        scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
      },
      // 未滚动态：标题栏透明，只给深色文字/图标
      originalStyle: {
        contentStyle: {
          titleStyle: { mainTitleColor: onSurface },
          backIconStyle: { iconColor: onSurface }
        }
      },
      // 滚动后：M3 暖色半透背板 + 深色文字/图标。
      // ⚠️ 两套 contentStyle 都要显式给色，否则默认是白字压浅底、看不清。
      scrollEffectStyle: {
        backgroundStyle: {
          backgroundColor: background,
          maskExtraHeight: 56.0
        },
        contentStyle: {
          titleStyle: { mainTitleColor: onSurface },
          backIconStyle: { iconColor: onSurface }
        }
      },
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      }
    };
  }

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
   * 任务详情（二级页）的右上角：**响铃 + 删除**两个图标按钮（袁正锟 2026-10-17）。
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
