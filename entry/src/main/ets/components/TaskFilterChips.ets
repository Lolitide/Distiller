/*
 * 页面顶部的**筛选 Chip 行**（独立组件）—— 官方 `ChipGroup` 及其芯片项、横向滚动、文案解析、
 * 选中态分发全部收在这个文件里。页面（`A_TaskList`）只写一行 `TaskFilterChips({ store: this.store })`。
 *
 * 为什么值得单独一个组件（袁正锟 2026-10-16：「把 Chip 和 ChipGroup 单独做成组件 不要全部放到 A_TaskList.ets 里面
 * 遵循一切页面元素都组件化」）：这一块本身有五件事要处理 —— 芯片列表的推导、资源文案解成字符串、
 * 选中下标与筛选键互转、横向滚动容器、以及官方 `ChipGroup` 的两处坑（见下）。全塞页面里会把它淹掉。
 *
 * 官方 API 两处坑（都已实测，别再踩）：
 *  1. **`ChipGroup` 自己不滚动** —— 官方文档里没有任何滚动/溢出参数，超出屏幕会被裁掉。
 *     按官方示例的做法在外面套一层**横向 `Scroll`**（`ScrollDirection.Horizontal` + `BarState.Off`）才有「水平滑动选择」。
 *  2. **`LabelOptions.text` 只吃 `string`**（官方 d.ts 写的就是 `text: string`，不吃 `Resource`）——
 *     固定项的 `$r()` 资源必须先 `resourceManager.getStringSync(id)` 解成字符串；
 *     标签项本来就是用户数据（纯字符串），原样用。
 *  另：`BarState` / `EdgeEffect` / `ScrollDirection` 是**全局枚举，不能从 `@kit.ArkUI` 导入**（导了会报 not exported）。
 */
import { ChipGroup, ChipGroupItemOptions, ChipSize } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TaskFilterChip, TaskListStore } from '../viewmodel/TaskListStore';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskFilterChips';

@ComponentV2
export struct TaskFilterChips {
  /**
   * 任务列表 store：芯片列表（固定项 + 标签项及其排序）与「当前筛选键」都从它读，
   * 点选后再写回去（`applyFilter`，顺便给标签项记一次点击次数用于自动排序）。
   */
  @Require @Param store: TaskListStore;

  /** 芯片列表：转成官方 `ChipGroup` 要的 `ChipGroupItemOptions[]` */
  @Computed
  get chipItems(): ChipGroupItemOptions[] {
    const items: ChipGroupItemOptions[] = [];
    this.store.chips.forEach((chip: TaskFilterChip) => {
      items.push({ label: { text: this.labelText(chip.label) } });
    });
    return items;
  }

  /** 当前选中的芯片下标（官方 `selectedIndexes`；单选模式，所以只给一个） */
  @Computed
  get selectedIndexes(): number[] {
    // 用 `effectiveFilter` 而不是 `activeFilter`：芯片随任务增删变化，某个标签芯片消失时
    // 筛选键要立刻表现得像「全部」，否则选中态会和列表内容对不上（见 store 里 `effectiveFilter` 的说明）
    const chips: TaskFilterChip[] = this.store.chips;
    const key: string = this.store.effectiveFilter;
    for (let i = 0; i < chips.length; i++) {
      if (chips[i].key === key) {
        return [i];
      }
    }
    return [0];
  }

  /**
   * 把芯片文案统一成 `string`：标签项本来就是字符串；固定项是 `$r()` 资源，
   * 用 `resourceManager.getStringSync` 同步解析（官方 `ChipGroup` 只收字符串）。
   */
  private labelText(label: ResourceStr): string {
    if (typeof label === 'string') {
      return label;
    }
    try {
      const context = this.getUIContext().getHostContext();
      return context === undefined ? '' : context.resourceManager.getStringSync((label as Resource).id);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve chip label failed: %{public}s', err.message);
      return '';
    }
  }

  build() {
    Scroll() {
      ChipGroup({
        items: this.chipItems,
        itemStyle: {
          size: ChipSize.SMALL,
          backgroundColor: $r('sys.color.ohos_id_color_button_normal'),
          fontColor: $r('sys.color.ohos_id_color_text_primary'),
          selectedBackgroundColor: $r('sys.color.ohos_id_color_emphasize'),
          selectedFontColor: $r('sys.color.ohos_id_color_text_primary_contrary')
        },
        selectedIndexes: this.selectedIndexes,
        multiple: false,
        chipGroupSpace: { itemSpace: 8 },
        chipGroupPadding: { top: 8, bottom: 8 },
        onChange: (activated: Array<number>) => {
          if (activated.length === 0) {
            return;
          }
          const chips: TaskFilterChip[] = this.store.chips;
          const index: number = activated[0];
          if (index >= 0 && index < chips.length) {
            this.store.applyFilter(chips[index].key);
          }
        }
      })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .edgeEffect(EdgeEffect.Spring)
  }
}
