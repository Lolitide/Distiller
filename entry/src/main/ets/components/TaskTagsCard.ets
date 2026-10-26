/*
 * 任务详情的「标签」卡（需求方 2026-10-17 的设计图）：
 * 每条标签一行（圆形图标 + 标签名 + 右侧 ×），**最后固定一行「＋ 添加标签」**，
 * 再往下是**「类型」那一行**（需求方 2026-10-27：「把『类型』置于『添加标签』下一个」，
 * 由 `TaskCategoryRow` 负责渲染 —— 标签与类型同属"分类与标记"）。
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
 *
 * 2026-10-27 追加（需求方：「添加标签时不能选择已有标签」）：本卡片在「输入行出现 **且** 光标在
 * 这一行里」时，通过 `onPickerVisibleChange` 通知页面在**输入法上方**挂出 `TagSuggestBar`
 * （所有已创建标签横向排布、点选即加入本任务、长按变删除）。所以这里要守两件事：
 *  ① 选择条的显隐必须跟着**焦点**走，不能只看"输入行还在" —— 内联输入本来就会留一行空输入等你
 *     接着打，焦点被挪走（点「添加步骤」、收起键盘）时条子必须立刻让位；
 *  ② 加 / 删一律走 `TaskListStore.addTagTo / removeTagFrom`，与选择条共用同一套写入口。
 */
import { ColorMetrics, LengthMetrics } from '@kit.ArkUI';
import { Task } from '../model';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { TaskCategoryRow } from './TaskCategoryRow';
import { ThemeStore } from '../utils/Theme';

/** 圆形图标直径（vp） */
const ICON_CIRCLE_SIZE_VP: number = 32;
/** 圆内字形尺寸（vp） */
const ICON_GLYPH_SIZE_VP: number = 20;
/**
 * 每行标签的行高（vp）。
 *
 * 为什么导出：详情页在「已有标签选择条」上点选一个标签后，本卡就**多/少一行**，
 * 而页面那条 `Scroll` 的滚动位置不会跟着变 —— 输入行会被顶出可视区（实测：键盘弹着时
 * 连点两个标签，第三行就把「添加标签」那行推到条子底下去了）。
 * 所以页面要按这个值把滚动位置也挪同样多，让输入行**留在原地**。
 */
export const TAG_ROW_HEIGHT_VP: number = 56;
/** 行左右内边距（vp）：官方 `padding_level8` */
const ROW_SIDE_PADDING_VP: number = 16;
/** 圆形图标与文案之间的间距（vp） */
const ICON_TEXT_GAP_VP: number = 12;
/** 右侧「删除」按钮点击热区直径（vp） */
const CLEAR_BUTTON_SIZE_VP: number = 40;
/** 内联输入框的组件 id：出现时用它抢焦点（`focusControl.requestFocus`） */
export const TAG_DRAFT_INPUT_ID: string = 'tagDraftInput';
/** 原地修改已有标签时输入框 id 的前缀（实际 id 是 `前缀-下标`） */
const TAG_EDIT_ID: string = 'tagEditInput';

@ComponentV2
export struct TaskTagsCard {
  /** 视觉个性化：图标圈用 M3 primary / onPrimary */
  @Local themeStore: ThemeStore = ThemeStore.instance();
  /** 要编辑的任务（`@ObservedV2`，改 `tags` 后卡片与列表都会跟着刷新） */
  @Require @Param task: Task;
  /**
   * 任务 store —— 加 / 删标签一律走它的写入口（`addTagTo` / `removeTagFrom`），
   * 不再在卡片里各自 `task.tags = next`：详情页那条「已有标签选择条」也要改标签，
   * 两处各写一份"去空白 / 去重 / 换新数组"迟早漂移（见 `TaskListStore` 里的说明）。
   */
  @Require @Param store: TaskListStore;

  /**
   * 本次是否正在「添加标签」（＝最后一行是内联输入框而不是「＋ 添加标签」）。
   * 只是"输入行存不存在"；**光标在不在这一行里**看 `draftFocused`。
   *
   * ⚠️ 别只看它来决定页面那条「已有标签选择条」的显隐：实测点「添加步骤」把焦点挪走后，
   * `adding` 仍然是 true（内联输入本来就会留一行空输入等你接着打），
   * 条子就会孤零零挂在键盘位置上方 —— 必须再加上 `draftFocused`（见 `notifyPickerSession`）。
   */
  @Local adding: boolean = false;
  /** 内联输入框**当前是否获焦**（键盘是否还站在它这边） */
  @Local draftFocused: boolean = false;
  /**
   * 页面上那条「已有标签选择条」该不该显示 —— 由 `adding && draftFocused` 合成后通知页面。
   *
   * 为什么不干脆让页面自己算：`adding` / 焦点都是本组件的内部状态，页面只有通过事件才知道。
   */
  @Event onPickerVisibleChange: (visible: boolean) => void = () => {};

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

  /**
   * 切换「正在添加」态：**唯一的写入口**（每次都同步通知页面）。
   * 选择条的显隐跟着它（＋焦点）走，所以别处不要再直接写 `this.adding = ...`。
   */
  private setAdding(value: boolean): void {
    if (this.adding === value) {
      return;
    }
    this.adding = value;
    this.notifyPickerSession();
  }

  /**
   * 把"该不该显示已有标签选择条"算出来告诉页面：**输入行在 ＋ 光标在里面**两个都成立才算。
   * 任何一处状态变了都要调它（`setAdding` / `onFocus` / `onBlur`）。
   */
  private notifyPickerSession(): void {
    this.onPickerVisibleChange(this.adding && this.draftFocused);
  }

  /** 点「＋ 添加标签」：就地给出一行空输入框（焦点由输入框自己的 `onAppear` 抢，更可靠） */
  private startAdd(): void {
    this.draft = '';
    this.setAdding(true);
  }

  /**
   * 提交草稿（回车 / 失焦都走这里）：
   *  · 空串 / 纯空白 → **收起**成「＋ 添加标签」（选择条跟着收起）；
   *  · 与已有标签重名 → 不重复添加，但**留在输入态**（可以接着打下一个）；
   *  · 正常 → 追加到末尾，**留在输入态**并清空草稿（与步骤那块「提交后还留一行空输入」一致）。
   */
  private commitDraft(): void {
    const trimmed: string = this.draft.trim();
    if (trimmed.length === 0) {
      this.setAdding(false);
      return;
    }
    // 去重与"整体换新数组"都在 store 里（它已经有的标签不会重复加）
    this.store.addTagTo(this.task, trimmed);
    this.draft = '';
    this.setAdding(true);
  }

  /** 删掉某条标签（同样走 store：整体换新数组，`@Trace` 才会通知界面） */
  private removeTag(tag: string): void {
    this.store.removeTagFrom(this.task, tag);
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
        .fill(this.themeStore.scheme.primary)
      SymbolGlyph(icon)
        .fontSize(ICON_GLYPH_SIZE_VP)
        .fontColor([this.themeStore.scheme.onPrimary])
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
        .id(TAG_DRAFT_INPUT_ID)
        .onAppear(() => {
          focusControl.requestFocus(TAG_DRAFT_INPUT_ID);
        })
        .onFocus(() => {
          // 光标进了这一行 → 键盘在它这边 → 可以让页面挂出已有标签选择条
          this.draftFocused = true;
          this.notifyPickerSession();
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
        // ⚠️ 这里必须填**卡片自身的底色**而不是页面底色：填页面色会在卡里露出一条色带
        //（需求方 2026-10-17 截图可见）。2026-10-21 起卡片底色是 M3 `surface-container-low`，
        // 所以输入框也跟着取同一个色，二者永远一致。
        .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
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
          // 光标走了（点了别处 / 键盘收起）→ 选择条立刻让位，再决定输入行收不收起
          this.draftFocused = false;
          this.notifyPickerSession();
          // 没填就收回成「＋ 添加标签」；填了就落成正式标签并再留一行
          this.commitDraft();
        })
    }
    .width('100%')
    .height(TAG_ROW_HEIGHT_VP)
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
    .height(TAG_ROW_HEIGHT_VP)
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
            // 图标用「标签」那个 symbol（需求方 2026-10-27：与下面「类型」那一行的图标**互换**，
            // 标签行从 `bookmark` 换成 `label`）
            this.iconCircle($r('sys.symbol.label'))
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
                // 输入框填卡片底色（M3 `surface-container-low`），否则会露一条色带（踩过）
                .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
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
        .height(TAG_ROW_HEIGHT_VP)
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

      // ③ 「类型」：需求方 2026-10-27「把『类型』置于『添加标签』下一个」——
      //    从「更多信息」卡整行搬到本卡最后（标签与类型同属"分类与标记"）。
      //    上面那条分隔线与标签行之间同一套（越过图标圆再起），所以看起来就是本卡的第 n 行。
      this.rowDivider()
      TaskCategoryRow({ task: this.task })
    }
    .width('100%')
    // 卡片底 = M3 `surface-container-low`：与设置页卡片、元信息卡、属性卡同一档（别再退回系统纯白）
    .backgroundColor(this.themeStore.scheme.surfaceContainerLow)
    .borderRadius($r('sys.float.ohos_id_corner_radius_card'))
    .clip(true)
  }
}
