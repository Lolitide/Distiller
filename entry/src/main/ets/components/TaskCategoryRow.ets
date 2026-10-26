/*
 * 任务详情里的「类型」行（独立组件，需求方 2026-10-27）。
 *
 * 需求方原话：「把『类型』置于『添加标签』下一个」——
 * 于是它从「更多信息」卡（`TaskInfoCard`）整行搬到了**标签卡的最后一行**：
 * 「标签」和「类型」本来就是同一类东西（分类与标记），排在一起比压在页面底部那堆
 * 只读读数（置信度、创建于、完成于）里顺手得多。
 *
 * 造型跟着标签卡走：**圆形图标 + 小标题 + 五档胶囊按钮**，行高 / 左右内边距与上面几行一致；
 * 五档（作业 / 考试 / 活动 / 通知 / 其他）在 360vp 宽度下放不下，所以按钮组外面套**横向 `Scroll`**，
 * 能放下时左对齐，放不下时左右滑 —— 与任务名 / 步骤 / 链接同一套做法。
 *
 * 数据：`Task.category`（字符串，取值域 `TASK_CATEGORY_PRESETS`），点一下直接写回，
 * `Task` 是 `@ObservedV2`，本行与列表页都会跟着刷新。
 */
import { TASK_CATEGORY_PRESETS, Task } from '../model';
import { SegmentRow } from './SegmentRow';
import { ThemeStore } from '../utils/Theme';

/** 圆形图标直径（vp）：与标签卡其它行同一档 */
const ICON_CIRCLE_SIZE_VP: number = 32;
/** 圆内字形尺寸（vp） */
const ICON_GLYPH_SIZE_VP: number = 20;
/** 行高（vp） */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp）：与标签卡其它行一致 */
const ROW_SIDE_PADDING_VP: number = 16;
/** 图标与后面文案之间的间距（vp） */
const ICON_TEXT_GAP_VP: number = 12;
/** 「类型」小标题与按钮组之间的间距（vp） */
const LABEL_GAP_VP: number = 12;

@ComponentV2
export struct TaskCategoryRow {
  /** 视觉个性化：图标圈用 M3 primary / onPrimary（与标签卡同一个造型） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 要改的任务（`@ObservedV2`，改 `category` 后本行与列表都会跟着刷新） */
  @Require @Param task: Task;

  /** 当前类型在预设里的下标；没设置 → -1（一颗都不选中） */
  @Computed
  get categoryIndex(): number {
    const value: string | undefined = this.task.category;
    if (value === undefined || value === '') {
      return -1;
    }
    return TASK_CATEGORY_PRESETS.indexOf(value);
  }

  /** 点某一颗：直接写回 `task.category` */
  private applyCategory(index: number): void {
    if (index >= 0 && index < TASK_CATEGORY_PRESETS.length) {
      this.task.category = TASK_CATEGORY_PRESETS[index];
    }
  }

  /** 官方蓝实心圆 + 白色字形（与标签卡、属性卡、元信息卡同一个造型） */
  @Builder
  iconCircle(icon: Resource) {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(ICON_CIRCLE_SIZE_VP)
        .height(ICON_CIRCLE_SIZE_VP)
        .fill(this.themeStore.scheme.primary)
      SymbolGlyph(icon)
        .fontSize(ICON_GLYPH_SIZE_VP)
        .fontColor([this.themeStore.scheme.onPrimary])
    }
  }

  build() {
    Row() {
      // 图标：与上面「标签」那几行的图标**互换**（需求方 2026-10-27）——
      // 标签行改用 `label`（标签形），本行改用 `bookmark`（书签形）。
      this.iconCircle($r('sys.symbol.bookmark'))

      Text($r('app.string.info_category'))
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(1)
        .margin({ left: ICON_TEXT_GAP_VP })

      // 五档按钮：放不下就横向滑（`SegmentRow` 的选中态是响应式的，改了立刻高亮）
      Scroll() {
        SegmentRow({
          options: TASK_CATEGORY_PRESETS,
          selectedIndex: this.categoryIndex,
          onSelect: (index: number) => {
            this.applyCategory(index);
          }
        })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .margin({ left: LABEL_GAP_VP })
      .align(Alignment.Start)
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }
}
