/*
 * 任务详情的「原文」卡 —— **把生成这条任务的那段原话显示出来**（字段表第 6 项 `rawText`）。
 *
 * 为什么需要它：`rawText` 从契约第一天就是「必存、永不上云」的字段，写入点也有三处
 * （`TaskMapper` 拉候选时写、`AddTaskDraft.toTask` 手建时写、`TaskListStore.mergeIncoming` 同步时补），
 * 但**全仓没有任何组件读过它** —— 用户能看到的只有解析结果，看不到"机器是从哪句话里读出来的"，
 * 也就没法核对「原文说周五，怎么变成了周三」这类错。这张卡就是那个"对照"。
 *
 * 造型：复用「备注」卡那一套（M3 `surface-container-low` 底 + 官方卡片圆角 + 16vp 内边距），
 * 但**只读**：正文用 `Text` 而不是 `TextArea`，所以
 *   · 不可编辑 —— 原文是溯源字段，改了就失去对照意义（要改的话是"重新解析"，不是手改原文）；
 *   · 可**长按选中/复制**（官方 `copyOption`），右上角另给一颗「复制」按钮（整段一键进剪贴板）；
 *   · 太长时默认**折叠**成 4 行（超出显示省略号），点「展开」看全文 —— 原文常见是整段群消息，
 *     展开状态不落盘（离开详情页就回到折叠，页面不会被一条长文压得很长）。
 *
 * 空值：`rawText` 为空/全空白时**整张卡不渲染**（`B_TaskDetail` 里已用 `if` 判过）。
 */
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Task } from '../model';
import { Theme, ThemeStore } from '../utils/Theme';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskRawTextCard';

/** 卡片内边距（vp）：与备注卡一致（官方 `padding_level8`） */
const CARD_PADDING_VP: number = 16;
/** 标题行与正文之间的间距（vp） */
const HEADER_GAP_VP: number = 8;
/** 折叠时显示的行数：整段群消息常见的长度下，4 行足以让用户认出"是不是这条" */
const COLLAPSE_MAX_LINES: number = 4;
/** 展开后的最大行数：给一个足够大的值（`maxLines` 没有"不限"的写法，只能给个大数） */
const EXPANDED_MAX_LINES: number = 200;
/** 超过这么多字符才显示「展开/收起」（短原文一眼看完，不需要交互） */
const COLLAPSE_THRESHOLD_CHARS: number = 80;
/** 标题图标尺寸（vp） */
const TITLE_ICON_SIZE_VP: number = 16;
/** 复制按钮的热区（vp）：官方最小可点 40 */
const COPY_HIT_VP: number = 40;

@ComponentV2
export struct TaskRawTextCard {
  /** 要展示原文的任务（`@ObservedV2`：`rawText` 变了会跟着刷新，例如重新解析之后） */
  @Require @Param task: Task;

  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 是否展开全文（只在本次浏览里有效，不落盘） */
  @Local expanded: boolean = false;

  /** 原文（去空判过：空串走「不渲染」分支） */
  @Computed
  get rawText(): string {
    const text: string | undefined = this.task.rawText;
    return text === undefined ? '' : text;
  }

  /** 长到需要折叠/展开吗 */
  @Computed
  get longText(): boolean {
    return this.rawText.length > COLLAPSE_THRESHOLD_CHARS;
  }

  /** 正文最多显示几行：折叠态 4 行，展开态给个大数 */
  @Computed
  get maxLines(): number {
    return this.expanded ? EXPANDED_MAX_LINES : COLLAPSE_MAX_LINES;
  }

  /**
   * 整段原文进系统剪贴板（官方 `pasteboard`）。
   *
   * 与正文的 `copyOption`（长按选中某一段再复制）互补：这里是一键复制**全部**，
   * 用户要粘到别处（比如回群里对一下）时不用先精确选中。
   */
  private async copyAll(): Promise<void> {
    try {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.rawText);
      await pasteboard.getSystemPasteboard().setData(data);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.raw_text_copied') });
    } catch (error) {
      // 复制失败不该影响页面：记日志、给一句提示就够
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'copy raw text failed: %{public}s', err.message);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.raw_text_copy_failed') });
    }
  }

  build() {
    Column() {
      // ① 标题行：「原文」＋ 展开/收起 ＋ 复制
      Row({ space: Theme.GAP_S }) {
        SymbolGlyph($r('sys.symbol.doc_text'))
          .fontSize(TITLE_ICON_SIZE_VP)
          .fontColor([$r('sys.color.icon_secondary')])

        Text($r('app.string.raw_text_title'))
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)

        Blank()

        if (this.longText) {
          Text(this.expanded ? $r('app.string.raw_text_collapse') : $r('app.string.raw_text_expand'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontColor(this.themeStore.scheme.primary)
            .maxLines(1)
            .padding({ left: Theme.GAP_S, right: Theme.GAP_S })
            .onClick(() => {
              this.expanded = !this.expanded;
            })
            .accessibilityText(this.expanded
              ? $r('app.string.raw_text_collapse')
              : $r('app.string.raw_text_expand'))
        }

        // 复制：整段进剪贴板（正文本身也支持长按选中复制）
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.doc_text_on_doc_text'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor([$r('sys.color.icon_secondary')])
        }
        .width(COPY_HIT_VP)
        .height(COPY_HIT_VP)
        .padding(0)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.copyAll();
        })
        .accessibilityText($r('app.string.raw_text_copy'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: HEADER_GAP_VP })

      // ② 正文：只读文本（长按可选中/复制），超长折叠 + 省略号
      Text(this.rawText)
        .width('100%')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .lineHeight(`${Theme.LINE_BODY}vp`)
        .maxLines(this.maxLines)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        // 原文里常有长 URL / 无空格的串：允许任意位置断行，否则会横向溢出卡片
        .wordBreak(WordBreak.BREAK_ALL)
        // 长按可选、可复制（官方 `copyOption`；`LocalDevice` 才进系统剪贴板）
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(CARD_PADDING_VP)
    // 与备注卡、标签卡同一档：M3 `surface-container-low` + 官方卡片圆角
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
