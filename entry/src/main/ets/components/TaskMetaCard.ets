/*
 * 任务详情的「元信息」卡（袁正锟 2026-10-17 的设计图）。
 *
 * 造型与上面那张属性卡**同一套**（白卡 + 蓝实心圆图标 + 行内文案 + 右侧 ×），
 * 因为同一页里两张卡不能长成两个样子；图上的淡紫配色是设计稿风格，落到工程里仍走官方 token。
 *
 * 卡里放什么（按图 + 字段表）：
 *  ① **重要程度** → `Task.priority`（字段表第 14 项，0 普通 / 1 重要 / 2 紧急）；
 *  ② **来源** → `Task.originDetail`（第 22 项，来源**展示名**，如群名「微信」「班级群」），
 *     没有展示名时退回 `Task.source`（第 21 项，通道枚举）的中文。
 *  ③ 「预计耗时」**先不做**（袁正锟 2026-10-17 裁定）：v1 定稿的 28 字段里没有它
 *     （第 2 周的表里有，定稿时删了，见 `TaskListViewModel` 里那条「v1 起没有预计耗时字段」的注释）。
 *     要做的话得先给契约加字段（如 `estimatedMinutes`）并同步字段表，不是页面能自己造的。
 *
 * 交互与属性卡一致（袁正锟 2026-10-17 定）：**点行 → 官方文本选择器，点 × → 清除这一项**。
 */
import { Task, TaskPriority, TaskSource } from '../model';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { OptionPickerBody } from './OptionPickerBody';

/** 圆形图标直径（vp） */
const ICON_CIRCLE_SIZE_VP: number = 32;
/** 圆内字形尺寸（vp） */
const ICON_GLYPH_SIZE_VP: number = 20;
/** 行高（vp） */
const ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp）：官方 `padding_level8` */
const ROW_SIDE_PADDING_VP: number = 16;
/** 圆形图标与文案之间的间距（vp） */
const ICON_TEXT_GAP_VP: number = 12;
/** 右侧「清除」按钮点击热区直径（vp） */
const CLEAR_BUTTON_SIZE_VP: number = 40;
/**
 * 重要程度三档。**顺序与 `TaskPriority` 的取值一致**（0 普通 / 1 重要 / 2 紧急），
 * 但下标换算走 `prioritySeedIndex` / `applyPriority` 里的显式分支，不直接拿枚举当数组下标 ——
 * ArkTS 里把枚举当数字下标用属于容易踩的行为，写成分支最稳。
 */
const PRIORITY_OPTIONS: string[] = ['普通', '重要', '紧急'];
/** 来源通道五档：文案与 `SOURCE_VALUES` **一一对应**，改一边必须改另一边 */
const SOURCE_OPTIONS: string[] = ['粘贴', '分享', '机器人', '语音', '手动'];
const SOURCE_VALUES: TaskSource[] = [TaskSource.PASTE, TaskSource.SHARE, TaskSource.BOT, TaskSource.VOICE, TaskSource.MANUAL];

@ComponentV2
export struct TaskMetaCard {
  /** 要编辑的任务（`@ObservedV2`，改字段两张卡与列表都会跟着刷新） */
  @Require @Param task: Task;

  /* 两个选择器面板的开关与草稿档位（袁正锟 2026-10-17：「给每个选择器加上 title」）。
   * 草稿只在点「确定」时写回任务 —— 滑到一半点「取消」不该改数据。 */
  @Local prioritySheetOpen: boolean = false;
  @Local priorityDraftIndex: number = 0;
  @Local sourceSheetOpen: boolean = false;
  @Local sourceDraftIndex: number = 0;

  /*
   * 这张卡**不需要** `TaskListStore`：分组是按天分（`groupByDay` 里只按 `taskTime` 排），
   * 重要程度与来源都不改变任务落在哪一天，也不改变组内顺序（现在的排序只看提醒/截止时间）。
   * TODO(袁正锟): 若以后按字段表 §2.3 把「priority 降序 → level 降序」加进组内排序，
   * 那改 priority 就得 `store.refreshGroups(task.id)`，这里要把 store 传进来。
   */

  /** 重要程度文案：直接复用列表那套中文（`TaskListViewModel.priorityLabel`），两处口径不会跑偏 */
  @Computed
  get priorityLabel(): ResourceStr {
    return TaskListViewModel.priorityLabel(this.task.priority);
  }

  /**
   * 来源文案：**优先展示名**（`originDetail`，如「微信」「班级群」），
   * 没有才退回通道中文（粘贴/分享/机器人/语音/手动），两者都没有就是「未知来源」。
   *
   * 为什么这样排：字段表第 21 项明确写着 `source`「**不用于显示**」——
   * 显示看第 22 项 `originDetail`（群名这类更具体的信息）。通道只是在展示名缺失时兜底。
   */
  @Computed
  get sourceLabel(): ResourceStr {
    const detail: string | undefined = this.task.originDetail;
    if (detail !== undefined && detail.length > 0) {
      return `来源于 ${detail}`;
    }
    const channel: string | undefined = this.channelLabel();
    if (channel === undefined) {
      return $r('app.string.attr_no_source');
    }
    return `来源于 ${channel}`;
  }

  /** 来源是不是「有值」（没值时文案用灰色，与属性卡同一套观感） */
  @Computed
  get sourceSet(): boolean {
    const detail: string | undefined = this.task.originDetail;
    if (detail !== undefined && detail.length > 0) {
      return true;
    }
    return this.task.source !== undefined;
  }

  /** 通道枚举 → 中文；没有通道返回 `undefined` */
  private channelLabel(): string | undefined {
    const own: TaskSource | undefined = this.task.source;
    if (own === undefined) {
      return undefined;
    }
    for (let i = 0; i < SOURCE_VALUES.length; i++) {
      if (SOURCE_VALUES[i] === own) {
        return SOURCE_OPTIONS[i];
      }
    }
    // 枚举里没有的取值（后端将来加通道）：退回原样显示，别把来源整行变成「未知」
    return `${own}`;
  }

  /**
   * 点「重要程度」行 → **带标题的选择器面板**（抬头「设置重要程度」）。
   *
   * 为什么不是 `showTextPickerDialog`：官方固定样式弹窗的 options 里**没有 title 字段**
   * （本机 SDK `text_picker.d.ts` 全量 grep 无 `title`），要抬头只能自己搭壳 ——
   * 用官方 `bindSheet` 的 `SheetOptions.title`，里面放官方 `TextPicker`，与属性卡那三个同一套做法。
   *
   * ⚠️ 手机（宽度 < 600vp）上官方只支持「底部 / 全屏」两种半模态样式，`SheetType.CENTER` 不生效，
   * 所以这里落地就是**底部面板**；写 `preferType: CENTER` 只为平板/2in1 上自动居中
   * （出处：API 参考《半模态转场》`preferType` 的「宽度 < 600vp：底部、全屏」那条）。
   */
  private openPrioritySheet(): void {
    this.priorityDraftIndex = this.prioritySeedIndex();
    this.prioritySheetOpen = true;
  }

  /** 关掉重要程度面板（草稿丢弃） */
  private closePrioritySheet(): void {
    this.prioritySheetOpen = false;
  }

  /** 重要程度面板「确定」 */
  private confirmPriority(): void {
    this.applyPriority(this.priorityDraftIndex);
    this.prioritySheetOpen = false;
  }

  /** 选择器打开时停在当前档位 */
  private prioritySeedIndex(): number {
    const current: TaskPriority = this.task.priority;
    if (current === TaskPriority.URGENT) {
      return 2;
    }
    if (current === TaskPriority.IMPORTANT) {
      return 1;
    }
    return 0;
  }

  /** 写回重要程度。`priority` 没有空值态（字段表第 14 项是 0/1/2 必填档位），所以「清除」＝回到普通 */
  private applyPriority(index: number): void {
    if (index === 2) {
      this.task.priority = TaskPriority.URGENT;
      return;
    }
    if (index === 1) {
      this.task.priority = TaskPriority.IMPORTANT;
      return;
    }
    this.task.priority = TaskPriority.NORMAL;
  }

  /** 清重要性 → 回到「普通」 */
  private clearPriority(): void {
    this.task.priority = TaskPriority.NORMAL;
  }

  /** 点「来源」行 → **带标题的选择器面板**（抬头「设置来源」），里面是官方 `TextPicker` */
  private openSourceSheet(): void {
    this.sourceDraftIndex = this.sourceSeedIndex();
    this.sourceSheetOpen = true;
  }

  /** 关掉来源面板（草稿丢弃） */
  private closeSourceSheet(): void {
    this.sourceSheetOpen = false;
  }

  /** 来源面板「确定」 */
  private confirmSource(): void {
    this.applySource(this.sourceDraftIndex);
    this.sourceSheetOpen = false;
  }

  /** 选择器打开时停在当前通道那一档；没有通道就停在第一档 */
  private sourceSeedIndex(): number {
    const own: TaskSource | undefined = this.task.source;
    if (own === undefined) {
      return 0;
    }
    for (let i = 0; i < SOURCE_VALUES.length; i++) {
      if (SOURCE_VALUES[i] === own) {
        return i;
      }
    }
    return 0;
  }

  /**
   * 写回来源通道，**并把旧的展示名清掉**。
   *
   * 为什么要清：`originDetail` 是**上一次解析出来的具体来源**（「语音记录」「班级群」这种）。
   * 用户手动把通道改成「分享」之后，还挂着「语音记录」就等于同一行里自相矛盾
   * （而且 `originDetail` 优先显示，不清的话用户会觉得「点了没反应」）。
   * 清掉后这行会退回到通道中文（如「来源于 分享」），改动是可见的。
   */
  private applySource(index: number): void {
    this.task.source = SOURCE_VALUES[index];
    this.task.originDetail = undefined;
  }

  /** 清来源：通道与展示名一起清（这一行整体变成「未知来源」灰字） */
  private clearSource(): void {
    this.task.source = undefined;
    this.task.originDetail = undefined;
  }

  /** 官方蓝实心圆 + 白色字形（与属性卡同一个造型） */
  @Builder
  iconCircle(icon: Resource) {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(ICON_CIRCLE_SIZE_VP)
        .height(ICON_CIRCLE_SIZE_VP)
        .fill($r('sys.color.ohos_id_color_emphasize'))
      SymbolGlyph(icon)
        .fontSize(ICON_GLYPH_SIZE_VP)
        .fontColor([$r('sys.color.ohos_id_color_text_primary_contrary')])
    }
  }

  /** 每行右侧的「清除这一项」按钮 */
  @Builder
  clearButton(onClear: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor([$r('sys.color.icon_secondary')])
    }
    .width(CLEAR_BUTTON_SIZE_VP)
    .height(CLEAR_BUTTON_SIZE_VP)
    .padding(0)
    .backgroundColor(Color.Transparent)
    .accessibilityText($r('app.string.action_clear_attribute'))
    .onClick(() => {
      onClear();
    })
  }

  @Builder
  rowDivider() {
    Divider()
      .color($r('sys.color.comp_divider'))
      .strokeWidth(0.5)
      .margin({ left: ROW_SIDE_PADDING_VP + ICON_CIRCLE_SIZE_VP + ICON_TEXT_GAP_VP })
  }

  /**
   * 重要程度面板内容 —— **复用 `components/OptionPickerBody.ets`**（官方 `TextPicker` ＋ 共用底部条）。
   * 原来这里内联了一份 `TextPicker` + `sheetFooter`，与「添加任务」那边的面板各写一遍；
   * 按 `references/02-编码规约.md` §10 规则 3，长得像就必须是同一个组件。
   */
  @Builder
  prioritySheet() {
    OptionPickerBody({
      options: PRIORITY_OPTIONS,
      selectedIndex: this.priorityDraftIndex,
      onSelectedIndexChange: (index: number) => {
        this.priorityDraftIndex = index;
      },
      onCancel: () => {
        this.closePrioritySheet();
      },
      onConfirm: () => {
        this.confirmPriority();
      }
    })
  }

  /** 来源面板内容 —— 同一个 `OptionPickerBody`，选项换成五档通道 */
  @Builder
  sourceSheet() {
    OptionPickerBody({
      options: SOURCE_OPTIONS,
      selectedIndex: this.sourceDraftIndex,
      onSelectedIndexChange: (index: number) => {
        this.sourceDraftIndex = index;
      },
      onCancel: () => {
        this.closeSourceSheet();
      },
      onConfirm: () => {
        this.confirmSource();
      }
    })
  }

  /*
   * ⚠️ 与属性卡同一条坑：文案**直接写在 `build()` 里读 `@Computed`**，
   * 不抽成带值的 `@Builder`（`@Builder` 的值参数不随状态刷新，点了选择器界面不更新）。
   */
  build() {
    Column() {
      // ① 重要程度
      Row() {
        Row() {
          this.iconCircle($r('sys.symbol.star'))
          // 两行文案统一「过长不换行、不用省略号截断」，装进横向 Scroll 可左右滑动看全文
          // （袁正锟 2026-10-17：「都统一成横向滑动」；与属性卡、标签同一套做法）
          Scroll() {
            Text(this.priorityLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              // 「普通」也是有效档位，所以这一行**没有灰色未设置态**
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .margin({ left: ICON_TEXT_GAP_VP })
          .align(Alignment.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // 重要程度：带标题的面板（抬头「设置重要程度」）
          this.openPrioritySheet();
        })

        this.clearButton(() => {
          this.clearPriority();
        })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .bindSheet(this.prioritySheetOpen, this.prioritySheet(), {
        title: { title: $r('app.string.picker_title_priority') },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          this.prioritySheetOpen = false;
        }
      })

      this.rowDivider()

      // ② 来源
      Row() {
        Row() {
          this.iconCircle($r('sys.symbol.link'))
          Scroll() {
            Text(this.sourceLabel)
              .fontSize($r('sys.float.ohos_id_text_size_body1'))
              .fontColor(this.sourceSet
                ? $r('sys.color.ohos_id_color_text_primary')
                : $r('sys.color.ohos_id_color_text_secondary'))
              .maxLines(1)
              .textAlign(TextAlign.Start)
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .margin({ left: ICON_TEXT_GAP_VP })
          .align(Alignment.Start)
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          // 来源：带标题的面板（抬头「设置来源」）
          this.openSourceSheet();
        })

        this.clearButton(() => {
          this.clearSource();
        })
      }
      .width('100%')
      .height(ROW_HEIGHT_VP)
      .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
      .alignItems(VerticalAlign.Center)
      .bindSheet(this.sourceSheetOpen, this.sourceSheet(), {
        title: { title: $r('app.string.picker_title_source') },
        preferType: SheetType.CENTER,
        height: SheetSize.FIT_CONTENT,
        showClose: false,
        dragBar: false,
        onDisappear: () => {
          this.sourceSheetOpen = false;
        }
      })
    }
    .width('100%')
    // 卡片白：与属性卡、列表卡片同一个官方 token
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
