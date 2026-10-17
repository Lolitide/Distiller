/*
 * 任务详情里的「步骤」块（袁正锟 2026-10-16 给的 4 张交互图）。
 *
 * 四态（与图一一对应）：
 *  图一 没有步骤        → 一行 `＋ 添加步骤`（蓝色）
 *  图二 点了「添加步骤」 → 下面多一行**空步骤**：空心圆 ＋ 灰色提示「添加步骤」，光标已就位
 *  图三 输入内容后回车   → 该步骤成为正式一行（圆＋文字＋右侧 ⋮），**下面再给一行空步骤**（提示「下一步」）
 *  图四 那行空步骤没填   → 收回，变成 `＋ 下一步`（蓝色）；即永远不留悬空的空行
 *
 * 颜色全部用官方语义 token：蓝＝`icon_emphasize`/`font_emphasize`，灰＝`icon_secondary`/`font_secondary`，
 * 正文＝`font_primary`，完成的步骤文字＝`font_tertiary`，分割线＝`comp_divider`。
 * 数据落在 `Task.steps`（v1 契约第 25 项，元素 `{content, done}`，`done` 存 0/1）。
 */
import { ColorMetrics, LengthMetrics } from '@kit.ArkUI';
import { Task, TaskStep } from '../model';

/** 圆圈尺寸（vp）：比卡片前缀（28vp）**小一档** —— 袁正锟 2026-10-16：「前面的图标小一档」 */
const ICON_SIZE_TEMPLATE: string = '24vp';

/** 行高（vp）：够放一行文字 + 圆圈 */
const STEP_ROW_HEIGHT_VP: number = 44;

/** 圆圈与文字之间的间距（vp）：官方 `padding_level8` = 16 —— 与"加号对齐圆圈、文字对齐文字"的图一致 */
const ICON_TEXT_GAP_VP: number = 16;

/** 空步骤输入框的组件 id：`startAdd()` 用它抢焦点（`focusControl.requestFocus`） */
const STEP_DRAFT_ID: string = 'taskStepDraftInput';

/** 原地修改已有步骤时，输入框 id 的前缀（实际 id 是 `前缀-下标`） */
const STEP_EDIT_ID: string = 'taskStepEditInput';

@ComponentV2
export struct TaskStepsSection {
  /** 步骤属于这个任务；直接改 `task.steps`（`@Trace`，卡片/详情都会跟着刷新） */
  @Require @Param task: Task;

  /** 是否正在输入新步骤（图二/图三的那一行） */
  @Local adding: boolean = false;
  /** 新步骤的草稿 */
  @Local draft: string = '';
  /** 正在**原地修改**的已有步骤下标；-1 ＝ 没有 */
  @Local editingIndex: number = -1;
  /** 原地修改的草稿 */
  @Local stepDraft: string = '';

  /**
   * 输入框控制器（草稿行与原地修改共用 —— 同一时刻只会有一个输入框在编辑）。
   * 用途：进入编辑态时把**光标放到文本末尾**，而不是默认框选全文
   * （袁正锟 2026-10-16：「编辑状态不要默认全选 光标在文本最后就行了」）。
   */
  private inputController: TextInputController = new TextInputController();

  /** 抢焦点 + 光标落到文本末尾（`focusBox` 已经关掉，所以不会出现外面那个蓝框） */
  private focusWithCaretAtEnd(componentId: string, text: string): void {
    focusControl.requestFocus(componentId);
    this.inputController.caretPosition(text.length);
  }

  /** 点已有步骤的文本 → 进入原地修改（袁正锟 2026-10-16） */
  private beginStepEdit(index: number, content: string): void {
    this.stepDraft = content;
    this.editingIndex = index;
  }

  /** 提交原地修改：空白则**保留原文**（不把步骤内容删空），然后退出编辑 */
  private commitStepEdit(): void {
    const index: number = this.editingIndex;
    if (index < 0) {
      return;
    }
    const text: string = this.stepDraft.trim();
    if (text.length > 0) {
      const next: TaskStep[] = this.steps.slice();
      const old: TaskStep = next[index];
      const updated: TaskStep = new TaskStep();
      updated.content = text;
      updated.done = old.done;
      next[index] = updated;
      this.task.steps = next;
    }
    this.editingIndex = -1;
  }

  /** 现有步骤（`steps` 是可选的，这里统一成数组） */
  @Computed
  get steps(): TaskStep[] {
    const list: TaskStep[] | undefined = this.task.steps;
    return list === undefined ? [] : list;
  }

  /** 空行里的提示：还没有步骤时是「添加步骤」（图二），已有步骤时是「下一步」（图三） */
  @Computed
  get draftHint(): Resource {
    return this.steps.length === 0 ? $r('app.string.action_add_step') : $r('app.string.step_hint_next');
  }

  /** 没有输入行时那颗按钮的文字：同上逻辑（图一 / 图四） */
  @Computed
  get addLabel(): Resource {
    return this.steps.length === 0 ? $r('app.string.action_add_step') : $r('app.string.step_hint_next');
  }

  /** 点「添加步骤 / 下一步」：给出一行空步骤，并**直接进入输入态**（不用点第二下） */
  private startAdd(): void {
    this.draft = '';
    this.adding = true;
    // 抢焦点放在输入框自己的 `onAppear` 里（见 draftRow）—— 定时器比渲染还快，不可靠
  }

  /**
   * 提交这行草稿：
   *  · 有内容 → 追加成正式步骤，并**继续给下一行**（图三）；
   *  · 没内容 → 直接收回成按钮（图四：不留悬空空行）。
   */
  private commitDraft(): void {
    const text: string = this.draft.trim();
    if (text.length === 0) {
      this.adding = false;
      return;
    }
    const next: TaskStep[] = this.steps.slice();
    const created: TaskStep = new TaskStep();
    created.content = text;
    created.done = 0;
    next.push(created);
    // 整体换数组：`@Trace` 对"换引用"的观测最稳
    this.task.steps = next;
    this.draft = '';
    this.adding = true;
  }

  /** 点步骤的圆圈：切换完成（`done` 存 0/1） */
  private toggleStep(index: number): void {
    const next: TaskStep[] = this.steps.slice();
    const target: TaskStep = next[index];
    const updated: TaskStep = new TaskStep();
    updated.content = target.content;
    updated.done = target.done === 1 ? 0 : 1;
    next[index] = updated;
    this.task.steps = next;
  }

  /** 删除某一步（**已经确认过**才调它） */
  private removeStep(index: number): void {
    const next: TaskStep[] = this.steps.slice();
    next.splice(index, 1);
    this.task.steps = next;
  }

  /**
   * 点末尾垃圾桶 → 先弹官方警告弹窗，确认后才真的删（袁正锟 2026-10-16）。
   * 与任务删除确认同一个写法：`UIContext.showAlertDialog`（`AlertDialog.show` 从 API 18 起已废弃）。
   */
  private confirmRemoveStep(index: number): void {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.action_delete_step'),
      message: $r('app.string.delete_step_confirm'),
      primaryButton: {
        value: $r('app.string.action_cancel'),
        action: () => {
          // 取消：什么都不做
        }
      },
      secondaryButton: {
        enabled: true,
        defaultFocus: true,
        style: DialogButtonStyle.HIGHLIGHT,
        value: $r('app.string.action_delete'),
        action: () => {
          this.removeStep(index);
        }
      }
    });
  }

  /** 步骤行左侧的圆圈：未完成＝空心圆，已完成＝实心带勾 */
  @Builder
  stepCircle(done: number, index: number) {
    SymbolGlyph(done === 1 ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.circle'))
      .fontSize(ICON_SIZE_TEMPLATE)
      .fontColor([done === 1 ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_secondary')])
      .accessibilityText(done === 1
        ? $r('app.string.action_uncomplete_task')
        : $r('app.string.action_complete_task'))
      .onClick(() => {
        this.toggleStep(index);
      })
  }

  /** 已提交的步骤行：圆圈 ＋ 文字（点一下即可原地改）＋ 末尾垃圾桶 */
  @Builder
  stepRow(step: TaskStep, index: number) {
    Row() {
      this.stepCircle(step.done, index)

      // 文字/输入框**包在一个 layoutWeight(1) 的容器里**：这样进入修改态时，
      // 输入框不会按自己的内容宽度收缩、把末尾的删除图标拖到文字后面
      // （袁正锟 2026-10-16：「修改状态的话 后面那个删除图标会贴到文本框后面 固定到末尾」）。
      Row() {
        if (this.editingIndex === index) {
          // 原地改：同一个字号/颜色，内联输入（无背板），出现即抢焦点 —— 与任务名同一套
          TextInput({ text: this.stepDraft, controller: this.inputController })
            .id(`${STEP_EDIT_ID}-${index}`)
            // 出现即抢焦点；`onFocus` 里再把光标顶到末尾（避免默认全选）
            .onAppear(() => {
              focusControl.requestFocus(`${STEP_EDIT_ID}-${index}`);
            })
            .onFocus(() => {
              // 推到下一帧再设光标（立刻设会被框架的"聚焦后默认处理"覆盖）
              setTimeout(() => {
                this.inputController.caretPosition(this.stepDraft.length);
              }, 0);
            })
            // 不要外面的焦点蓝框，只留光标（袁正锟 2026-10-16）
            .focusBox({ strokeWidth: LengthMetrics.vp(0), strokeColor: ColorMetrics.rgba(0, 0, 0, 0) })
            .width('100%')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .style(TextInputStyle.Default)
            // 背景不要纯白，与页面底色一致（袁正锟 2026-10-16）
            .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
            .showUnderline(false)
            .borderWidth(0)
            .borderRadius(0)
            .padding(0)
            .maxLines(1)
            .enterKeyType(EnterKeyType.Done)
            .onChange((value: string) => {
              this.stepDraft = value;
            })
            .onSubmit(() => {
              this.commitStepEdit();
            })
            .onBlur(() => {
              this.commitStepEdit();
            })
        } else {
          Text(step.content)
            .width('100%')
            .fontSize($r('sys.float.ohos_id_text_size_body1'))
            .fontColor(step.done === 1
              ? $r('sys.color.ohos_id_color_text_tertiary')
              : $r('sys.color.ohos_id_color_text_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
            // 点文本 → 原地进入修改状态（袁正锟 2026-10-16）
            .onClick(() => {
              this.beginStepEdit(index, step.content);
            })
        }
      }
      .layoutWeight(1)
      .margin({ left: ICON_TEXT_GAP_VP })
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)

      // 末尾图标：**直接是删除**（不再是「更多」菜单）—— 袁正锟 2026-10-16：「后面的更多换成删除」
      // 尺寸与前面的完成圆圈**同一个常量**（袁正锟 2026-10-16：「删除图标和前面的完成图标一样大小」）
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(ICON_SIZE_TEMPLATE)
        .fontColor([$r('sys.color.icon_secondary')])
        .accessibilityText($r('app.string.action_delete_step'))
        .padding(8)
        // 点它先弹官方确认框，确认后才删（袁正锟 2026-10-16）
        .onClick(() => {
          this.confirmRemoveStep(index);
        })
    }
    .width('100%')
    .height(STEP_ROW_HEIGHT_VP)
    .alignItems(VerticalAlign.Center)
  }

  /** 空步骤行（图二/图三）：圆圈 ＋ 可直接输入的内联输入框（提示文字随状态变） */
  @Builder
  draftRow() {
    Row() {
      SymbolGlyph($r('sys.symbol.circle'))
        .fontSize(ICON_SIZE_TEMPLATE)
        .fontColor([$r('sys.color.icon_secondary')])

      TextInput({ text: this.draft, placeholder: this.draftHint, controller: this.inputController })
        .id(STEP_DRAFT_ID)
        // 一出现就抢焦点 → 点「添加步骤 / 下一步」之后**直接可以打字**，不用点第二下
        // （袁正锟 2026-10-16：「点击后自动进入输入状态 不要点两下」）
        .onAppear(() => {
          focusControl.requestFocus(STEP_DRAFT_ID);
        })
        // 空行没有内容，光标自然在末尾；这里统一走同一个控制器，切行时不会跑到别处
        .onFocus(() => {
          setTimeout(() => {
            this.inputController.caretPosition(this.draft.length);
          }, 0);
        })
        // 不要外面的焦点蓝框，只留光标（袁正锟 2026-10-16）
        .focusBox({ strokeWidth: LengthMetrics.vp(0), strokeColor: ColorMetrics.rgba(0, 0, 0, 0) })
        .layoutWeight(1)
        .margin({ left: ICON_TEXT_GAP_VP })
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .placeholderColor($r('sys.color.ohos_id_color_text_secondary'))
        // 与"改名"同一个做法：内联样式（无背板、无下划线），不然会出现一道遮罩
        .style(TextInputStyle.Default)
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
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
          // 没填就收回成「添加步骤 / 下一步」按钮（图四）；填了就落成正式步骤
          this.commitDraft();
        })
    }
    .width('100%')
    .height(STEP_ROW_HEIGHT_VP)
    .alignItems(VerticalAlign.Center)
  }

  /** 蓝色「＋ 添加步骤 / ＋ 下一步」按钮（图一 / 图四） */
  @Builder
  addButton() {
    Row() {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(ICON_SIZE_TEMPLATE)
        .fontColor([$r('sys.color.icon_emphasize')])

      Text(this.addLabel)
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontColor($r('sys.color.font_emphasize'))
        .margin({ left: ICON_TEXT_GAP_VP })
    }
    .width('100%')
    .height(STEP_ROW_HEIGHT_VP)
    .alignItems(VerticalAlign.Center)
    .accessibilityText(this.addLabel)
    .onClick(() => {
      this.startAdd();
    })
  }

  build() {
    Column() {
      ForEach(this.steps, (step: TaskStep, index: number) => {
        this.stepRow(step, index)
        Divider()
          .color($r('sys.color.comp_divider'))
          .strokeWidth(0.5)
      }, (step: TaskStep, index: number) => `${index}-${step.content}-${step.done}`)

      if (this.adding) {
        this.draftRow()
      } else {
        this.addButton()
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
