import { ThemeStore } from '../utils/Theme';
/*
 * 任务状态图标（独立组件，卡片与详情页共用）。
 *
 * 两个形态：
 *  · **普通态**：未完成＝虚线圆 `circle_dashed`，已完成＝带勾的圆 `checkmark_circle`
 *    （需求方 2026-10-14 定；详情页标题前的圆圈就是它 —— 2026-10-16：「名称前把 Card 的 prefixItem 里面的圆圈带上」）；
 *  · **选择态**：方框勾选框，未选 `square`、已选 `checkmark_square_fill`（多选模式用）。
 *
 * 颜色全取官方 token：已完成为 `icon_secondary`（灰）、未完成为 `icon_primary`、
 * 选择态勾上用 `ohos_id_color_emphasize`（品牌蓝）。
 * 尺寸借官方「圆形按钮图标」token（28vp）—— HDS 卡片前缀图标的上限只有 24vp，这里是要大一圈的观感。
 */
import { Task, TaskPriority, TaskStatus } from '../model';

@ComponentV2
export struct TaskStatusIcon {
  /** 视觉个性化：M3 色系（全局 MD3 化，2026-10-19） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 该图标代表的任务 */
  @Require @Param task: Task;
  /** 是否选择态（多选模式）。默认普通态 */
  @Param selectionMode: boolean = false;
  /** 选择态下是否已选中 */
  @Param selected: boolean = false;
  /** 点它：普通态＝完成/退回；选择态＝勾选/取消。由页面决定具体做什么 */
  @Event onTap: () => void = () => {};

  @Computed
  get completed(): boolean {
    return this.task.status === TaskStatus.COMPLETED;
  }

  @Computed
  get symbol(): Resource {
    if (this.selectionMode) {
      return this.selected ? $r('sys.symbol.checkmark_square_fill') : $r('sys.symbol.square');
    }
    return this.completed ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.circle_dashed');
  }

  @Computed
  get color(): ResourceColor {
    if (this.selectionMode) {
      return this.selected ? this.themeStore.scheme.primary : $r('sys.color.icon_primary');
    }
    return this.completed ? $r('sys.color.icon_secondary') : $r('sys.color.icon_primary');
  }

  /** 无障碍文本：选择态说"选择/取消选择"，普通态说"标记完成/取消完成" */
  @Computed
  get accessibilityLabel(): Resource {
    if (this.selectionMode) {
      return this.selected ? $r('app.string.action_deselect_task') : $r('app.string.action_select_task');
    }
    return this.completed ? $r('app.string.action_uncomplete_task') : $r('app.string.action_complete_task');
  }

  build() {
    SymbolGlyph(this.symbol)
      .fontSize($r('sys.float.ohos_id_min_circle_button_icon_size'))
      .fontColor([this.color])
      .accessibilityText(this.accessibilityLabel)
      .onClick(() => {
        this.onTap();
      })
  }
}
