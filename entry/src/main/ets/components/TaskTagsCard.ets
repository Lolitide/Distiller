/*
 * 任务详情的「标签」卡（需求方 2026-10-17 的设计图）：
 * 每条标签一行（圆形图标 + 标签名 + 右侧 ×），**最后固定一行「＋ 添加标签」**。
 *
 * 造型与上面两张卡同一套（白卡 + 蓝实心圆图标 + 官方文字/分割线 token）。
 *
 * 添加方式**与上面「步骤」那块同一套**（需求方 2026-10-17：「添加标签的输入和上面步骤的输入一样
 * 不要选择器」）：点「＋ 添加标签」→ 那一行**就地变成内联输入框**并自动抢焦点，回车（或失焦）提交，
 * 提交后仍留一行空输入框可以接着加；空着就收起成「＋ 添加标签」。**没有弹窗、没有面板、没有选择器。**
 * 做法照抄 `TaskStepsSection`：`TextInputStyle.Default` + 透明背板 + 无下划线/边框 + `focusBox` 关掉，
 * 与「任务名 / 步骤」的内联输入观感一致。
 *
 * 数据口径：读写 `Task.tags`（字段表第 24 项，**字符串数组**）。
 *  - 加：去空白后**去重**追加；`tags` 是 `@Trace` 数组，必须**整体换新数组**才会刷新；
 *  - 删：过滤掉该条；删到空数组时这张卡只剩「添加标签」一行（不显示任何占位文案）；
 *  - 标签也参与列表顶部的筛选 Chip（`TaskListStore.chips` 由所有任务的标签长出来），
 *    加/删会让 Chip 行跟着变；删掉某标签的最后一条时，`effectiveFilter` 会兜底回「全部」。
 */
import { ColorMetrics, LengthMetrics } from '@kit.ArkUI';
import { Task } from '../model';

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
/** 右侧「删除」按钮点击热区直径（vp） */
const CLEAR_BUTTON_SIZE_VP: number = 40;
/** 内联输入框的组件 id：出现时用它抢焦点（`focusControl.requestFocus`） */
const TAG_DRAFT_ID: string = 'tagDraftInput';
/** 原地修改已有标签时输入框 id 的前缀（实际 id 是 `前缀-下标`） */
const TAG_EDIT_ID: string = 'tagEditInput';

@ComponentV2
export struct TaskTagsCard {
  /** 要编辑的任务（`@ObservedV2`，改 `tags` 后卡片与列表都会跟着刷新） */
  @Require @Param task: Task;

  /** 是否正在输入新标签（＝最后那一行是输入框而不是「＋ 添加标签」） */
  @Local adding: boolean = false;
  /** 新标签的草稿 */
  @Local draft: string = '';
  /** 正在**原地修改**的已有标签下标；-1 ＝ 没有（与步骤那块同一套） */
  @Local editingIndex: number = -1;
  /** 原地修改的草稿 */
  @Local editDraft: string = '';
  /**
   * 输入框控制器（新增行与原地修改共用 —— 同一时刻只有一个输入框在编辑）。
   * 用途：进入编辑态时把**光标放到文本末尾**，而不是默认框选全文（与步骤、改名同一套）。
   */
  private inputController: TextInputController = new TextInputController();

  /** 现有标签（`tags` 允许为空/未填，这里统一成数组，`build()` 里不用再判空） */
  @Computed
  get tags(): string[] {
    const own: string[] | undefined = this.task.tags;
    return own === undefined ? [] : own;
  }

  /** 点「＋ 添加标签」：就地给出一行空输入框（焦点由输入框自己的 `onAppear` 抢，更可靠） */
  private startAdd(): void {
    this.draft = '';
    this.adding = true;
  }

  /**
   * 提交草稿（回车 / 失焦都走这里）：
   *  · 空串 / 纯空白 → **收起**成「＋ 添加标签」；
   *  · 与已有标签重名 → 不重复添加，但**留在输入态**（可以接着打下一个）；
   *  · 正常 → 追加到末尾，**留在输入态**并清空草稿（与步骤那块「提交后还留一行空输入」一致）。
   */
  private commitDraft(): void {
    const trimmed: string = this.draft.trim();
    if (trimmed.length === 0) {
      this.adding = false;
      return;
    }
    const own: string[] = this.tags;
    if (own.indexOf(trimmed) < 0) {
      const next: string[] = own.slice();
      next.push(trimmed);
      // 整体换新数组：`@Trace` 数组只有换引用才会通知界面
      this.task.tags = next;
    }
    this.draft = '';
    this.adding = true;
  }

  /** 删掉某条标签（同样整体换新数组） */
  private removeTag(tag: string): void {
    const next: string[] = this.tags.filter((each: string) => each !== tag);
    this.task.tags = next;
  }

  /** 点已有标签的文字 → 进入**原地修改**（与步骤同一套，需求方 2026-10-17：「Tag 也像 step 一样点击可以修改」） */
  private beginTagEdit(index: number, tag: string): void {
    this.editDraft = tag;
    this.editingIndex = index;
  }

  /**
   * 提交原地修改（回车 / 失焦都走这里）：
   *  · 空白 → **保留原文**（不把标签改空；要删就点右侧 ×）；
   *  · 改动后会与**别的**标签重名 → 保留原文，不制造重复项；
   *  · 正常 → 替换该下标。整段都用**整体换新数组**，`@Trace` 才会刷新。
   */
  private commitTagEdit(): void {
    const index: number = this.editingIndex;
    if (index < 0) {
      return;
    }
    this.editingIndex = -1;
    const text: string = this.editDraft.trim();
    const own: string[] = this.tags;
    if (text.length === 0 || text === own[index]) {
      return;
    }
    for (let i = 0; i < own.length; i++) {
      if (i !== index && own[i] === text) {
        return;
      }
    }
    const next: string[] = own.slice();
    next[index] = text;
    this.task.tags = next;
  }

  /** 官方蓝实心圆 + 白色字形（与属性卡、元信息卡同一个造型） */
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

  /** 每行右侧的「删掉这一条标签」按钮 */
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
   * 空标签行（最后那一行）：**内联输入框**，不是弹窗。
   * 一出现就抢焦点 → 点「＋ 添加标签」之后**直接可以打字**，不用点第二下。
   * 其余属性照抄 `TaskStepsSection.draftRow()`：内联样式（无背板、无下划线、无焦点框）。
   */
  @Builder
  draftRow() {
    Row() {
      this.iconCircle($r('sys.symbol.plus'))

      TextInput({ text: this.draft, placeholder: $r('app.string.tag_add'), controller: this.inputController })
        .id(TAG_DRAFT_ID)
        .onAppear(() => {
          focusControl.requestFocus(TAG_DRAFT_ID);
        })
        .onFocus(() => {
          // 推到下一帧再设光标：立刻设会被框架"聚焦后默认处理"覆盖（踩过）
          setTimeout(() => {
            this.inputController.caretPosition(this.draft.length);
          }, 0);
        })
        // 不要外面的焦点蓝框，只留光标
        .focusBox({ strokeWidth: LengthMetrics.vp(0), strokeColor: ColorMetrics.rgba(0, 0, 0, 0) })
        .layoutWeight(1)
        .margin({ left: ICON_TEXT_GAP_VP })
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
        // 与「改名 / 步骤」同一个做法：否则会留一道输入框背板
        .style(TextInputStyle.Default)
        // ⚠️ 这里填**卡片白**而不是页面灰：步骤那块输入框落在页面灰底上才用 sub_background，
        // 这张卡是白卡，用页面灰会露出一条灰带（需求方 2026-10-17 截图可见）
        .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
        .showUnderline(false)
        .borderWidth(0)
        .borderRadius(0)
        .padding(0)
        .maxLines(1)
        .enterKeyType(EnterKeyType.Done)
        .onChange((value: string) => {
          this.draft = value;
        })
        .onSubmit(() => {
          this.commitDraft();
        })
        .onBlur(() => {
          // 没填就收回成「＋ 添加标签」；填了就落成正式标签并再留一行
          this.commitDraft();
        })
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /** 没在输入时那一行：＋ 添加标签（点它换成上面的内联输入框） */
  @Builder
  addRow() {
    Row() {
      Row() {
        this.iconCircle($r('sys.symbol.plus'))
        // 与上面几条标签行同一套：过长不换行、不省略号截断，可左右滑动
        Scroll() {
          Text($r('app.string.tag_add'))
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            // 灰色（需求方 2026-10-17）：与「未设置提醒 / 未知来源」同一个「这是动作、不是已有值」的观感
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
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
        this.startAdd();
      })
    }
    .width('100%')
    .height(ROW_HEIGHT_VP)
    .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
    .alignItems(VerticalAlign.Center)
  }

  /*
   * ⚠️ 与另两张卡同一条坑：文案写在 `build()` 里直接读状态/`@Computed`，
   * 不抽成带值的 `@Builder`（值参数不随状态刷新）。
   */
  build() {
    Column() {
      // ① 已有标签：一条一行，**点文字就地改名**、右侧 × 删掉这一条
      ForEach(this.tags, (tag: string, index: number) => {
        Row() {
          Row() {
            this.iconCircle($r('sys.symbol.bookmark'))
            if (this.editingIndex === index) {
              // 原地改：与步骤/任务名同一套内联输入（无背板、无下划线、关掉焦点框），出现即抢焦点
              TextInput({ text: this.editDraft, controller: this.inputController })
                .id(`${TAG_EDIT_ID}-${index}`)
                .onAppear(() => {
                  focusControl.requestFocus(`${TAG_EDIT_ID}-${index}`);
                })
                .onFocus(() => {
                  // 推到下一帧再设光标：立刻设会被框架"聚焦后默认处理"覆盖，变成全选
                  setTimeout(() => {
                    this.inputController.caretPosition(this.editDraft.length);
                  }, 0);
                })
                .focusBox({ strokeWidth: LengthMetrics.vp(0), strokeColor: ColorMetrics.rgba(0, 0, 0, 0) })
                .layoutWeight(1)
                .margin({ left: ICON_TEXT_GAP_VP })
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .style(TextInputStyle.Default)
                // 卡片是白的，输入框也填卡片白，否则会露一条灰带（踩过）
                .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
                .showUnderline(false)
                .borderWidth(0)
                .borderRadius(0)
                .padding(0)
                .maxLines(1)
                .enterKeyType(EnterKeyType.Done)
                .onChange((value: string) => {
                  this.editDraft = value;
                })
                .onSubmit(() => {
                  this.commitTagEdit();
                })
                .onBlur(() => {
                  // 空白保留原文、重名也保留原文（见 commitTagEdit），然后退出编辑
                  this.commitTagEdit();
                })
            } else {
              // 展示态：过长不换行、不省略号截断，装进横向 Scroll 可左右滑动看全文
              Scroll() {
                Text(tag)
                  .fontSize($r('sys.float.ohos_id_text_size_body1'))
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                  .maxLines(1)
                  .textAlign(TextAlign.Start)
                  // 点文字 → 进原地修改
                  .onClick(() => {
                    this.beginTagEdit(index, tag);
                  })
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .layoutWeight(1)
              .margin({ left: ICON_TEXT_GAP_VP })
              .align(Alignment.Start)
            }
          }
          .layoutWeight(1)
          .height('100%')
          .alignItems(VerticalAlign.Center)

          this.clearButton(() => {
            this.removeTag(tag);
          })
        }
        .width('100%')
        .height(ROW_HEIGHT_VP)
        .padding({ left: ROW_SIDE_PADDING_VP, right: ROW_SIDE_PADDING_VP })
        .alignItems(VerticalAlign.Center)

        this.rowDivider()
      }, (tag: string) => tag)

      // ② 最后一行：平时是「＋ 添加标签」，点开后**就地变成内联输入框**
      if (this.adding) {
        this.draftRow()
      } else {
        this.addRow()
      }
    }
    .width('100%')
    // 卡片白：与另两张卡、列表卡片同一个官方 token
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
