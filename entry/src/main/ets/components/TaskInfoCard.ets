/*
 * 任务详情的「更多信息」卡 —— 承载字段表 v1 里标了**详情 ✅ 但此前没有任何渲染点**的 8 项：
 *
 *   `level` 难易程度 · `category` 类型 · `place` 地点
 *   `urls` 链接 · `certainty` 置信度 · `createdAt` 创建于 · `finishedAt` 完成于
 *
 * 造型取「标签–值」两列行（不再画图标圈）：这八项是**属性读数**，不是动作，
 * 左列固定文案、右列值，空值统一显示「未设置」，比一堆形状相近的 Symbol 更好读。
 *
 * 哪些能改：
 *   · `level` / `category` —— 走 `OptionPickerBody`（单列选择器），与元信息卡的「重要程度/来源」同一套；
 *   · `place`             —— 走 `TagInputBody`（单行文本输入），与「添加标签」同一套；
 *   · `certainty` / `createdAt` / `finishedAt` —— **只读**：置信度来自解析、两个时间戳由系统写
 *     （字段表：`createdAt` 非用户填；`finishedAt` 只有系统能写）。
 *   · `urls` —— 只读展示（多条用换行拼接）；手动增删链接留到下一轮。
 *
 * ⚠️ 与属性卡/元信息卡同一条坑：**所有文案直接读 `@Computed`，不抽成带值的 `@Builder`**。
 *    `@Builder` 的值参数不随状态刷新 —— 踩过：把 `levelLabel` 当参数传给行构件，
 *    改完难易程度后行里仍显示「未设置」（数据已改、界面不动）。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Task, TaskLevel, TASK_CATEGORY_PRESETS } from '../model';
import { OptionPickerBody } from './OptionPickerBody';
import { TagInputBody } from './TagInputBody';
import { Theme } from '../utils/Theme';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskInfoCard';

/** 行高（vp）：与元信息卡同档，视线扫过时不跳 */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp） */
const ROW_SIDE_PADDING_VP: number = 16;
/** 左列标签宽度（vp）：八行对齐成一条竖线 */
const LABEL_WIDTH_VP: number = 88;
/** 分隔线宽（vp） */
const DIVIDER_WIDTH_VP: number = 0.5;

/** 打开的是哪个面板 */
const SHEET_NONE: number = 0;
const SHEET_LEVEL: number = 1;
const SHEET_CATEGORY: number = 2;
const SHEET_PLACE: number = 3;

/** 难易程度选项（下标即 `TaskLevel` 的值：0 简单 / 1 中等 / 2 困难） */
const LEVEL_OPTIONS: string[] = ['简单', '中等', '困难'];
/** 三档分段按钮之间的间距（vp） */
const SEGMENT_GAP_VP: number = 8;
/** 分段按钮高度（vp） */
const SEGMENT_HEIGHT_VP: number = 32;

@ComponentV2
export struct TaskInfoCard {
  @Require @Param task: Task;

  /** 当前打开的面板 */
  @Local sheetKind: number = SHEET_NONE;
  /** 难易程度面板草稿 */
  @Local levelDraft: number = 0;
  /** 类型面板草稿 */
  @Local categoryDraft: number = 0;
  /** 地点 / 对象面板草稿 */
  @Local textDraft: string = '';

  /* ── 文案 ── */

  private labelText(label: Resource): string {
    try {
      const context = this.getUIContext().getHostContext();
      return context === undefined ? '' : context.resourceManager.getStringSync(label.id);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'resolve label failed: %{public}s', err.message);
      return '';
    }
  }

  @Computed
  get unsetText(): string {
    return this.labelText($r('app.string.info_unset'));
  }

  @Computed
  get levelLabel(): string {
    const level: TaskLevel | undefined = this.task.level;
    if (level === undefined) {
      return this.labelText($r('app.string.info_unset'));
    }
    if (level === TaskLevel.EASY) {
      return this.labelText($r('app.string.level_easy'));
    }
    if (level === TaskLevel.HARD) {
      return this.labelText($r('app.string.level_hard'));
    }
    return this.labelText($r('app.string.level_medium'));
  }

  @Computed
  get levelSet(): boolean {
    return this.task.level !== undefined;
  }

  @Computed
  get categoryLabel(): string {
    const value: string | undefined = this.task.category;
    return value === undefined || value === '' ? this.unsetText : value;
  }

  @Computed
  get categorySet(): boolean {
    const value: string | undefined = this.task.category;
    return value !== undefined && value !== '';
  }

  @Computed
  get placeLabel(): string {
    const value: string | undefined = this.task.place;
    return value === undefined || value === '' ? this.unsetText : value;
  }

  @Computed
  get placeSet(): boolean {
    const value: string | undefined = this.task.place;
    return value !== undefined && value !== '';
  }

  @Computed
  get urlsLabel(): string {
    const urls: string[] | undefined = this.task.urls;
    if (urls === undefined || urls.length === 0) {
      return this.unsetText;
    }
    return urls.join('\n');
  }

  @Computed
  get urlsSet(): boolean {
    const urls: string[] | undefined = this.task.urls;
    return urls !== undefined && urls.length > 0;
  }

  @Computed
  get certaintyLabel(): string {
    const value: number | undefined = this.task.certainty;
    return value === undefined ? this.unsetText : `${value}%`;
  }

  @Computed
  get certaintySet(): boolean {
    return this.task.certainty !== undefined;
  }

  @Computed
  get createdAtLabel(): string {
    return this.stampText(this.task.createdAt);
  }

  @Computed
  get finishedAtLabel(): string {
    return this.stampText(this.task.finishedAt);
  }

  @Computed
  get finishedVisible(): boolean {
    return this.task.finishedAt !== undefined;
  }

  /** `yyyy.MM.dd HH:mm`：详情页给精确时刻（卡片上才是"今天/明天"那种相对说法） */
  private stampText(timestamp: number | undefined): string {
    if (timestamp === undefined || timestamp <= 0) {
      return this.unsetText;
    }
    const date: Date = new Date(timestamp);
    const month: string = date.getMonth() + 1 < 10 ? `0${date.getMonth() + 1}` : `${date.getMonth() + 1}`;
    const day: string = date.getDate() < 10 ? `0${date.getDate()}` : `${date.getDate()}`;
    const hour: string = date.getHours() < 10 ? `0${date.getHours()}` : `${date.getHours()}`;
    const minute: string = date.getMinutes() < 10 ? `0${date.getMinutes()}` : `${date.getMinutes()}`;
    return `${date.getFullYear()}.${month}.${day} ${hour}:${minute}`;
  }

  /* ── 面板草稿种子与写回 ── */

  private openLevelSheet(): void {
    const level: TaskLevel | undefined = this.task.level;
    this.levelDraft = level === undefined ? TaskLevel.MEDIUM : level;
    this.sheetKind = SHEET_LEVEL;
  }

  private openCategorySheet(): void {
    const current: string | undefined = this.task.category;
    const index: number = current === undefined ? 0 : TASK_CATEGORY_PRESETS.indexOf(current);
    this.categoryDraft = index < 0 ? 0 : index;
    this.sheetKind = SHEET_CATEGORY;
  }

  private openPlaceSheet(): void {
    this.textDraft = this.task.place === undefined ? '' : this.task.place;
    this.sheetKind = SHEET_PLACE;
  }

  private closeSheet(): void {
    this.sheetKind = SHEET_NONE;
  }

  private confirmSheet(): void {
    if (this.sheetKind === SHEET_LEVEL) {
      this.task.level = this.levelDraft === 0
        ? TaskLevel.EASY
        : (this.levelDraft === 2 ? TaskLevel.HARD : TaskLevel.MEDIUM);
    } else if (this.sheetKind === SHEET_CATEGORY) {
      this.task.category = TASK_CATEGORY_PRESETS[this.categoryDraft];
    } else if (this.sheetKind === SHEET_PLACE) {
      const next: string = this.textDraft.trim();
      // 空串存 `undefined`：「没填」与「填了空白」在契约里不是一回事
      this.task.place = next === '' ? undefined : next;
    }
    this.sheetKind = SHEET_NONE;
  }

  @Computed
  get sheetTitle(): Resource {
    if (this.sheetKind === SHEET_CATEGORY) {
      return $r('app.string.picker_title_category');
    }
    return $r('app.string.picker_title_place');
  }

  /**
   * 难易程度在**三档分段按钮**里的选中下标（0 简单 / 1 中等 / 2 困难）。
   * 显式换算，不把枚举当数组下标用。
   */
  @Computed
  get levelIndex(): number {
    const level: TaskLevel | undefined = this.task.level;
    if (level === TaskLevel.EASY) {
      return 0;
    }
    if (level === TaskLevel.HARD) {
      return 2;
    }
    return 1;
  }

  /** 点三档分段：直接写回 `task.level`（不再走半模态） */
  private applyLevel(index: number): void {
    this.task.level = index === 0
      ? TaskLevel.EASY
      : (index === 2 ? TaskLevel.HARD : TaskLevel.MEDIUM);
  }

  /** 一颗三档分段按钮（`selected` 由调用点读 `@Computed` 求值，避免 @Builder 值参数不刷新的坑） */
  @Builder
  segment(text: string, selected: boolean, onTap: () => void) {
    Text(text)
      .fontSize(Theme.FONT_BODY)
      .fontColor(selected
        ? $r('sys.color.ohos_id_color_text_primary_contrary')
        : $r('sys.color.ohos_id_color_text_primary'))
      .height(SEGMENT_HEIGHT_VP)
      .padding({ left: Theme.GAP_M, right: Theme.GAP_M })
      .backgroundColor(selected
        ? $r('sys.color.ohos_id_color_emphasize')
        : $r('sys.color.comp_background_secondary'))
      .borderRadius(SEGMENT_HEIGHT_VP / 2)
      .textAlign(TextAlign.Center)
      .onClick(onTap)
      .accessibilityText(text)
  }

  /* ── 行（**值一律在 build 里直接读 `@Computed`**）── */

  @Builder
  rowLabel(label: Resource) {
    Text(label)
      .fontSize($r('sys.float.ohos_id_text_size_body1'))
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .width(LABEL_WIDTH_VP)
      .maxLines(1)
      .textAlign(TextAlign.Start)
  }

  @Builder
  rowDivider() {
    Divider()
      .strokeWidth(DIVIDER_WIDTH_VP)
      .color($r('sys.color.comp_divider'))
      .margin({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
  }

  @Builder
  sheetBody() {
    if (this.sheetKind === SHEET_LEVEL) {
      OptionPickerBody({
        options: LEVEL_OPTIONS,
        selectedIndex: this.levelDraft,
        onSelectedIndexChange: (index: number) => {
          this.levelDraft = index;
        },
        onCancel: () => {
          this.closeSheet();
        },
        onConfirm: () => {
          this.confirmSheet();
        }
      })
    } else if (this.sheetKind === SHEET_CATEGORY) {
      OptionPickerBody({
        options: TASK_CATEGORY_PRESETS,
        selectedIndex: this.categoryDraft,
        onSelectedIndexChange: (index: number) => {
          this.categoryDraft = index;
        },
        onCancel: () => {
          this.closeSheet();
        },
        onConfirm: () => {
          this.confirmSheet();
        }
      })
    } else {
      TagInputBody({
        text: this.textDraft,
        placeholder: $r('app.string.info_unset'),
        onTextChange: (text: string) => {
          this.textDraft = text;
        },
        onCancel: () => {
          this.closeSheet();
        },
        onConfirm: () => {
          this.confirmSheet();
        }
      })
    }
  }

  build() {
    Column() {
      // ① 难易程度（可改）
      Row() {
        this.rowLabel($r('app.string.info_level'))
        Scroll() {
          Text(this.levelLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.levelSet
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Start)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      // ①-b 难易程度：**三档内联分段按钮**（2026-10-19：「任务难易程度可用三档按钮直接设置」）。
      // 原来是点整行开半模态选轮，三档的东西开弹窗属于模态滥用。
      Row({ space: SEGMENT_GAP_VP }) {
        ForEach(LEVEL_OPTIONS, (label: string, index: number) => {
          this.segment(label, this.levelIndex === index, () => {
            this.applyLevel(index);
          })
        }, (label: string, index: number) => `${label}-${index}`)
      }
      .width('100%')
      .padding({
        left: ROW_SIDE_PADDING_VP,
        right: ROW_SIDE_PADDING_VP,
        bottom: Theme.GAP_M
      })
      .justifyContent(FlexAlign.Start)

      this.rowDivider()

      // ② 类型（可改）
      Row() {
        this.rowLabel($r('app.string.info_category'))
        Scroll() {
          Text(this.categoryLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.categorySet
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Start)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.openCategorySheet();
      })
      .bindSheet(this.sheetKind === SHEET_CATEGORY, this.sheetBody(), {
        title: { title: this.sheetTitle },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          this.sheetKind = SHEET_NONE;
        }
      })

      this.rowDivider()

      // ③ 地点（可改）
      Row() {
        this.rowLabel($r('app.string.info_place'))
        Scroll() {
          Text(this.placeLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.placeSet
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Start)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.openPlaceSheet();
      })
      .bindSheet(this.sheetKind === SHEET_PLACE, this.sheetBody(), {
        title: { title: this.sheetTitle },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          this.sheetKind = SHEET_NONE;
        }
      })

      this.rowDivider()

      // ⑤ 链接（只读，本轮不做增删）
      Row() {
        this.rowLabel($r('app.string.info_urls'))
        Scroll() {
          Text(this.urlsLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.urlsSet
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Start)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      this.rowDivider()

      // ⑥ 置信度（只读：来自解析）
      Row() {
        this.rowLabel($r('app.string.info_certainty'))
        Scroll() {
          Text(this.certaintyLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(this.certaintySet
              ? $r('sys.color.ohos_id_color_text_primary')
              : $r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Start)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      this.rowDivider()

      // ⑦ 创建于（只读：系统写）
      Row() {
        this.rowLabel($r('app.string.info_created'))
        Scroll() {
          Text(this.createdAtLabel)
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .maxLines(1)
            .textAlign(TextAlign.Start)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Start)
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      // ⑧ 完成于（只读：只有已完成的任务才有值）
      if (this.finishedVisible) {
        this.rowDivider()
        Row() {
          this.rowLabel($r('app.string.info_finished'))
          Scroll() {
            Text(this.finishedAtLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .align(Alignment.Start)
        }
        .width('100%')
        .height(ROW_HEIGHT_VP)
        .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
