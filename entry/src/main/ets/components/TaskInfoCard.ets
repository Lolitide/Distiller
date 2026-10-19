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
 *   · `level` / `category` / `place` —— **全部行内直改**（三档分段 / 预设胶囊 / 输入框），
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
import { Task, TaskLevel, TaskPriority, TASK_CATEGORY_PRESETS } from '../model';
import { SegmentRow } from './SegmentRow';
import { PopupSelector } from './PopupSelector';
import { OptionPickerBody } from './OptionPickerBody';
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

/** 难易程度选项（下标即 `TaskLevel` 的值：0 简单 / 1 中等 / 2 困难） */
const LEVEL_OPTIONS: string[] = ['简单', '中等', '困难'];
/** 重要性选项（下标即 TaskPriority 的值：0 普通 / 1 重要 / 2 紧急） */
const PRIORITY_OPTIONS: string[] = ['普通', '重要', '紧急'];
/** 三档分段按钮之间的间距（vp） */
const SEGMENT_GAP_VP: number = 8;
/** 分段按钮高度（vp） */
const SEGMENT_HEIGHT_VP: number = 32;
/** 类型胶囊高度（vp） */
const CHIP_HEIGHT_VP: number = 28;
/** 类型胶囊间距（vp） */
const CHIP_GAP_VP: number = 6;

@ComponentV2
export struct TaskInfoCard {
  @Require @Param task: Task;

  /** 类型选择器是否打开 */
  @Local categorySheetOpen: boolean = false;
  /** 类型选择器的草稿下标（-1 ＝ 未设置） */
  @Local categoryDraft: number = -1;

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

  /** 重要性在分段按钮里的选中下标（0 普通 / 1 重要 / 2 紧急），显式换算不拿枚举当数组下标 */
  @Computed
  get priorityIndex(): number {
    if (this.task.priority === TaskPriority.URGENT) {
      return 2;
    }
    if (this.task.priority === TaskPriority.IMPORTANT) {
      return 1;
    }
    return 0;
  }

  private applyPriority(index: number): void {
    if (index === 2) {
      this.task.priority = TaskPriority.URGENT;
    } else if (index === 1) {
      this.task.priority = TaskPriority.IMPORTANT;
    } else {
      this.task.priority = TaskPriority.NORMAL;
    }
  }

  /* ── 类型选择器（5 档一行放不下，按作者裁定改用弹窗）── */

  private openCategorySheet(): void {
    const current: string | undefined = this.task.category;
    const index: number = current === undefined ? -1 : TASK_CATEGORY_PRESETS.indexOf(current);
    this.categoryDraft = index;
    this.categorySheetOpen = true;
  }

  @Builder
  categorySheet() {
    OptionPickerBody({
      options: TASK_CATEGORY_PRESETS,
      selectedIndex: this.categoryDraft,
      onSelectedIndexChange: (index: number) => {
        this.categoryDraft = index;
      },
      onCancel: () => {
        this.categorySheetOpen = false;
      },
      onConfirm: () => {
        if (this.categoryDraft >= 0 && this.categoryDraft < TASK_CATEGORY_PRESETS.length) {
          this.task.category = TASK_CATEGORY_PRESETS[this.categoryDraft];
        }
        this.categorySheetOpen = false;
      }
    })
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

  build() {
    Column() {
      // ① 重要性（可改）—— 与难易程度**同一张卡、同一行式**（2026-10-19 作者要求：
      //    「任务重要性、难易程度这俩放一块」，并且**不要**再与"来源"混在一张卡里）。
      //    标题 + 三档按钮**并排一行**，不再"上面显示当前值、下面再来一排按钮"。
      //    2026-10-19 第二次调整：三档不再铺成按钮，改成**锚定浮窗**
      //    （作者：「信息重要性的选项，改成图二所示的浮窗组件」）—— 点这一行弹选项、当前项打勾。
      Row({ space: Theme.GAP_M }) {
        this.rowLabel($r('app.string.info_priority'))
        PopupSelector({
          label: '',
          value: PRIORITY_OPTIONS[this.priorityIndex],
          options: PRIORITY_OPTIONS,
          selectedIndex: this.priorityIndex,
          onSelect: (index: number) => {
            this.applyPriority(index);
          }
        })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      this.rowDivider()

      // ② 难易程度（可改）：同样"标题 + 三档按钮"一行
      Row({ space: Theme.GAP_M }) {
        this.rowLabel($r('app.string.info_level'))
        SegmentRow({
          options: LEVEL_OPTIONS,
          selectedIndex: this.levelIndex,
          onSelect: (index: number) => {
            this.applyLevel(index);
          }
        })
        Blank()
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

      this.rowDivider()

      // ③ 类型：**点一行弹选择器**（2026-10-19 作者裁定：
      //    「类型」5 档一行放不下，改成弹窗选择；并且不再重复显示当前值 + 胶囊两遍）
      Row() {
        this.rowLabel($r('app.string.info_category'))
        Text(this.categoryLabel)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.End)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(Theme.FONT_CAPTION)
          .fontColor([$r('sys.color.icon_tertiary')])
          .margin({ left: Theme.GAP_S })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.openCategorySheet();
      })

      this.rowDivider()

      // ③ 地点（可改）
      Row() {
        this.rowLabel($r('app.string.info_place'))
        // 地点：**行内输入框**（2026-10-19：「多数字段可直接点击文本进行编辑」）。
        // 原来点一行开半模态再输入，两步变一步。
        TextInput({ text: this.task.place === undefined ? '' : this.task.place, placeholder: this.unsetText })
          .id('placeInput')
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
          .backgroundColor(Color.Transparent)
          .borderRadius(0)
          .layoutWeight(1)
          .height(ROW_HEIGHT_VP)
          .maxLines(1)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value: string) => {
            // 边打边写回：空串存 undefined（「没填」与「填了空白」在契约里不是一回事）
            const next: string = value.trim();
            this.task.place = next === '' ? undefined : next;
          })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)

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
    // 类型选择器：5 档一行放不下，按作者裁定改用弹窗
    .bindSheet(this.categorySheetOpen, this.categorySheet(), {
      title: { title: $r('app.string.info_category') },
      preferType: SheetType.CENTER,
      height: SheetSize.FIT_CONTENT,
      showClose: false,
      dragBar: false,
      onDisappear: () => {
        this.categorySheetOpen = false;
      }
    })
  }
}
