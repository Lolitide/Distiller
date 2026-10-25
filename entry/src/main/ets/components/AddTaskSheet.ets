import { ThemeStore } from '../utils/Theme';
/*
 * 「添加任务」半模态（`bindSheet`）—— **内容区 ＋ 选项**都在这个文件里。
 *
 * 需求方 2026-10-17 的重构（原始需求：「点击底部页签的添加按钮后 显示一个 bindSheet 先完成这个功能」）：
 * 模板与组件化的约定见 `references/02-编码规约.md` §10 规则 5：弹层的**内容**是组件、**选项**是
 * 同一文件里的 `addTaskSheetOptions()`；页面 `pages/A_Main.ets` 只剩
 * `宿主.bindSheet(显隐, 内容 builder, addTaskSheetOptions())` 一行装配。
 *
 * 本轮新增（需求方 2026-10-17：「半模态右上角关闭按钮旁加一个保存按钮 任务名称没输入 按钮灰色
 * 输入后可点击 点击后创建一个任务」）：
 *  · **自己画标题行**：「添加任务」＋「保存」＋ 圆形关闭按钮。原来用系统 `SheetOptions.title`，
 *    标题区没法塞第三个元素，所以改成 `showClose: false` ＋ 自绘 —— 标题字号/字重用官方
 *    `sheet_title_text_font_size` / `sheet_title_font_weight`，与原系统标题一致；
 *  · **保存的灰/亮**看 `draft.canSave`（名称非空）；点了就 `draft.toTask()` 建任务、
 *    `store.addTask()` 落进列表、清空草稿、回调 `onSaved()` 让页面收起半模态并给反馈；
 *  · 表单状态**统一在 `AddTaskDraft`（`@ObservedV2`）** 里，按引用传给各子组件 —— 保存按钮在标题栏、
 *    要读全部字段，这一层必须收口（详见 `viewmodel/AddTaskDraft.ets` 顶部注释）。
 *
 * 下一步要接的：真录音（`AVRecorder` + 麦克风权限）、截图/录音的文字识别（`service/ai`，
 * 必须动态 `import()`，模拟器上静态引用会闪退）、以及落库（现在只进内存 store，`repository/` 还没接）。
 */
import { LengthMetrics } from '@kit.ArkUI';
import { Task } from '../model';
import { CandidateItem } from '../service/backend/BackendTypes';
import { ManualParseResult, ManualParseService } from '../service/cloud/ManualParseService';
import { DraftRepository } from '../repository/DraftRepository';
import { common } from '@kit.AbilityKit';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { TaskListStore } from '../viewmodel/TaskListStore';
import { TaskListViewModel } from '../viewmodel/TaskListViewModel';
import { AddTaskAttributeChips } from './AddTaskAttributeChips';
import { AddTaskNameInput } from './AddTaskNameInput';
import { AddTaskRecorder } from './AddTaskRecorder';
import { AddTaskScreenshotPicker } from './AddTaskScreenshotPicker';
import { AddTaskSource, AddTaskSourceTabs } from './AddTaskSourceTabs';
import { AddTaskTextInput } from './AddTaskTextInput';

/** 标题行左右内边距（vp）：与下面内容区对齐（官方 `padding_level8` = 16vp） */
const HEADER_SIDE_PADDING_VP: number = 16;

/**
 * 标题行右侧关闭按钮的**视觉**直径（vp）。
 * 需求方 2026-10-17：「把半模态那个添加任务和两个按钮的 header 有点高了 和最开始不太一样」——
 * 原来按 40vp 圆形按钮摆，整行被它撑高；这里降到 **32vp**（视觉与系统标题区那颗关闭按钮同档），
 * 命中区另外用 `responseRegion` 撑到 40vp，不会难点。
 */
const CLOSE_BUTTON_SIZE_VP: number = 32;

/** 关闭按钮的**命中区**边长（vp）：官方最小可点 40vp，视觉小一点、热区不变 */
const CLOSE_HIT_SIZE_VP: number = 40;

/** 「保存」的左右点击留白（vp）：纯文字按钮，热区靠 padding 撑 */
const SAVE_SIDE_PADDING_VP: number = 8;

@ComponentV2
export struct AddTaskSheet {
  /** 视觉个性化：M3 色系（全局 MD3 化，2026-10-19） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /**
   * 任务列表 store：保存时把新任务落进去（`addTask`），列表会自己重分组刷新。
   * 由页面 `A_Main` 传进来 —— 半模态是页面的一部分，store 也归页面持有。
   */
  @Require @Param store: TaskListStore;
  /** 保存成功后通知页面（收起半模态 ＋ 给一条 toast） */
  @Event onSaved: () => void = () => {};
  /** 点右上角关闭：同样由页面把显隐置回 false */
  @Event onClose: () => void = () => {};

  /**
   * 表单草稿（**唯一真源**）：来源页签、名称、日期/提醒/重复/重要程度/来源、标签、原文、截图、录音时长
   * 全在这里；子组件按引用读写它，保存按钮直接读它判断灰/亮并拼 `Task`。
   *
   * 2026-10-22：草稿改由 `A_Main` 持有（`@Param draft`），这样关闭半模态时
   * 页面层可以把它落盘，下次点「＋」继续编辑。
   */
  @Require @Param draft: AddTaskDraft;
  /** 大于 0 时自动触发一次 AI 预填（系统分享带入内容后使用） */
  @Param autoParseKey: number = 0;

  aboutToDisappear(): void {
    // 划掉半模态 / 切页导致销毁：把当前填写内容存起来（保存成功后会 clear）
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context !== undefined) {
      DraftRepository.save(context, this.draft);
    }
  }

  /** 点「重置」：二次确认后清空表单与本机草稿 */
  private confirmReset(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '重置表单',
      message: '会清空当前填写的内容（包括本机保存的草稿）。',
      buttons: [
        { text: $r('app.string.action_cancel'), color: $r('sys.color.ohos_id_color_text_primary') },
        { text: '重置', color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      this.draft.reset();
      const context: common.Context | undefined = this.getUIContext().getHostContext();
      if (context !== undefined) {
        DraftRepository.clear(context);
      }
      this.toast('已重置');
    });
  }

  /**
   * 标题行：标题 ＋ 「保存」 ＋ 圆形关闭。
   *
   * 为什么自己画（不用系统 `SheetOptions.title`）：要求是"保存按钮在关闭按钮旁边"，
   * 而系统标题区只有「标题 + 自带关闭」，塞不进第三个元素；`showClose` 关掉、两个按钮都自己摆最稳。
   *
   * ⚠️ 与"最开始"（系统标题那条）对齐的三个细节 —— 需求方 2026-10-17：
   * 「把半模态那个添加任务和两个按钮的 header 有点高了 和最开始不太一样」：
   *  · **标题字重**：`fontWeight($r('sys.float.sheet_title_font_weight'))` 传 `Resource` 时**没生效**
   *    （渲染成了常规字重，比系统标题"瘦"一截），改成显式 `FontWeight.Bold`；
   *  · **关闭按钮**要恢复官方的**浅灰圆形底**（原来被我写成透明底，视觉上就剩一个小叉）；
   *  · **整行的上下留白**恢复成系统标题那一档：上 `padding_level8`(16vp)、下 `padding_level8`(16vp)
   *    —— 上一版只留 4/8vp，标题贴着半模态顶边、分段按钮也紧跟着贴上来，
   *    实测「半模态顶 → 分段控件轨道」只有 **168px**，而系统标题那条是 **252px**（差 84px ≈ 27vp），
   *    所以看起来"跟最开始的节奏不一样"。改完应回到 ~240px 上下。
   */
  @Builder
  sheetHeader() {
    Row() {
      Text($r('app.string.action_add_task'))
        .fontSize($r('sys.float.sheet_title_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)

      // 重置：清空当前表单（红色，放在保存左边）
      Text('重置')
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .fontColor($r('sys.color.ohos_id_color_warning'))
        .padding({
          left: SAVE_SIDE_PADDING_VP,
          right: SAVE_SIDE_PADDING_VP,
          top: $r('sys.float.padding_level2'),
          bottom: $r('sys.float.padding_level2')
        })
        .margin({ right: 4 })
        .onClick(() => {
          this.confirmReset();
        })
        .accessibilityText('重置')

      // 保存：名称非空才亮（灰的时候点击无效）
      Text($r('app.string.action_save'))
        .fontSize($r('sys.float.ohos_id_text_size_button1'))
        .fontColor(this.draft.canSave
          ? this.themeStore.scheme.primary
          : $r('sys.color.ohos_id_color_text_tertiary'))
        .padding({
          left: SAVE_SIDE_PADDING_VP,
          right: SAVE_SIDE_PADDING_VP,
          top: $r('sys.float.padding_level2'),
          bottom: $r('sys.float.padding_level2')
        })
        .onClick(() => {
          this.save();
        })
        .accessibilityText($r('app.string.action_save'))

      // 关闭：官方那颗**浅灰圆形**按钮的造型（32vp 视觉 + 40vp 命中区）
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontColor([$r('sys.color.icon_secondary')])
      }
      .width(CLOSE_BUTTON_SIZE_VP)
      .height(CLOSE_BUTTON_SIZE_VP)
      .padding(0)
      // 2026-10-25：圆底从系统冷灰 `comp_background_secondary` 换成 M3 `surfaceContainerHigh`
      //（面板已是暖色 `scheme.surface`，冷灰圆底在暖底上偏蓝）。
      .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
      // 视觉 32vp、热区 40vp（官方最小可点尺寸）
      .responseRegion({
        x: -(CLOSE_HIT_SIZE_VP - CLOSE_BUTTON_SIZE_VP) / 2,
        y: -(CLOSE_HIT_SIZE_VP - CLOSE_BUTTON_SIZE_VP) / 2,
        width: CLOSE_HIT_SIZE_VP,
        height: CLOSE_HIT_SIZE_VP
      })
      .margin({ left: $r('sys.float.padding_level2') })
      .onClick(() => {
        this.onClose();
      })
      .accessibilityText($r('app.string.action_cancel'))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    // 上下各 16vp：与系统标题区的节奏一致（半模态顶 → 分段控件 ≈ 240px，见上面注释第 3 点）
    .padding({
      left: HEADER_SIDE_PADDING_VP,
      right: $r('sys.float.padding_level2'),
      top: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level8')
    })
  }

  /**
   * 保存：建任务 → 落进 store → 清空草稿 → 通知页面收起。
   * 名称空的时候直接返回（按钮虽然是"灰的"，但 `Text.onClick` 不像 `Button` 会自己拦点击，
   * 所以这里必须再判一次 —— 不然灰着的「保存」也能点出任务来）。
   */
  private save(): void {
    if (!this.draft.canSave) {
      return;
    }
    const task: Task = this.draft.toTask(this.store.nextTaskId());
    this.store.addTask(task);
    this.draft.reset();
    this.lowHintDismissed = false;
    this.onSaved();
  }

  @Local aiBusy: boolean = false;
  /** 用户点了「知道了」后本次不再显示低可信提示 */
  @Local lowHintDismissed: boolean = false;
  /** 解析失败：分类展示 + 重试/手动填写（FE-41） */
  @Local parseErrorCode: string = '';
  @Local parseErrorMsg: string = '';

  aboutToAppear(): void {
    if (this.autoParseKey > 0) {
      this.aiFill();
    }
  }

  @Monitor('autoParseKey')
  onAutoParseKeyChanged(): void {
    if (this.autoParseKey > 0) {
      this.aiFill();
    }
  }

  /**
   * AI 预填：文本/截图 → 后端 `/parse` → 把名称/时间/优先级/标签/地点填进草稿。
   * **只预填、不保存**；用户看过再点「保存」。
   */
  private async aiFill(): Promise<void> {
    if (this.aiBusy) {
      return;
    }
    if (this.draft.sourceTab === AddTaskSource.SCREENSHOT) {
      if (this.draft.imageUri.length === 0) {
        return;
      }
    } else if (this.draft.rawText.trim().length === 0) {
      return;
    }
    this.aiBusy = true;
    try {
      let result: ManualParseResult;
      if (this.draft.sourceTab === AddTaskSource.SCREENSHOT) {
        result = await ManualParseService.parseImage(this.draft.imageUri);
      } else {
        result = await ManualParseService.parseText(this.draft.rawText);
      }
      if (!result.ok || result.candidate === undefined) {
        this.parseErrorCode = result.code !== undefined ? result.code : 'unknown';
        this.parseErrorMsg = result.message.length > 0 ? result.message : '没能识别出任务内容';
        return;
      }
      this.parseErrorCode = '';
      this.parseErrorMsg = '';
      const candidate: CandidateItem = result.candidate;
      this.draft.applyParsed(candidate, this.store.remindLeadMinutes);
      if (result.link !== undefined && result.link.length > 0) {
        this.draft.linkUrl = result.link;
      }
      // 截图/文件来源：把 OCR/抽取后的文字补成原文，便于详情页「原文对照」
      if (result.text.length > 0 && this.draft.rawText.trim().length === 0) {
        this.draft.rawText = result.text;
      }
      const where: string = result.localOcr === true ? '已在手机本地识别文字，' : '';
      this.toast(where + '已自动填写，请确认后保存');
    } catch (error) {
      this.parseErrorCode = 'unknown';
      this.parseErrorMsg = '解析时出错了，请重试或手动填写';
    } finally {
      this.aiBusy = false;
    }
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      // toast 失败不影响主流程
    }
  }

  /** 解析失败的可执行文案（按错误码分类） */
  private parseErrorText(): string {
    if (this.parseErrorCode === 'no_server') {
      return '还没有配置服务器地址，先去设置里填上再解析。';
    }
    if (this.parseErrorCode === 'network') {
      return '连不上服务器，检查手机网络和服务器地址后重试。';
    }
    if (this.parseErrorCode === 'not_supported') {
      return '服务器没开图片识别，请改用文字输入，或手动填写。';
    }
    if (this.parseErrorCode === 'unauthorized') {
      return '设备身份失效，去设置里重新绑定后再解析。';
    }
    if (this.parseErrorCode === 'bad_response' || this.parseErrorCode === 'bad_json') {
      return '服务器返回异常，稍后重试；也可以直接手动填写。';
    }
    return this.parseErrorMsg.length > 0 ? this.parseErrorMsg : '没能识别出任务内容，请重试或手动填写。';
  }

  /** 解析失败卡：重试 / 手动填写（FE-41） */
  @Builder
  parseErrorCard() {
    Column({ space: 8 }) {
      Text('没能识别这段内容')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeStore.scheme.error)
      Text(this.parseErrorText())
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor(this.themeStore.scheme.onSurfaceVariant)
        .width('100%')
      Row({ space: 12 }) {
        Text(this.aiBusy ? '识别中…' : '重试')
          .fontSize(13)
          .fontColor(this.aiBusy ? this.themeStore.scheme.onSurfaceVariant : this.themeStore.scheme.primary)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
          .onClick(() => {
            if (!this.aiBusy) {
              this.aiFill();
            }
          })
        Text('手动填写')
          .fontSize(13)
          .fontColor(this.themeStore.scheme.onSurfaceVariant)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .backgroundColor(this.themeStore.scheme.surfaceContainerHigh)
          .onClick(() => {
            this.parseErrorCode = '';
            this.parseErrorMsg = '';
            setTimeout(() => {
              focusControl.requestFocus('addTaskNameInput');
            }, 0);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.themeStore.scheme.errorContainer)
    .borderRadius(12)
    .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })
  }

  /**
   * 解析结果里「没识别出来的字段」——按**当前草稿**现算（用户补上就消失）。
   * 与「低可信」是两件事：置信度可能不低，但某些字段确实空着。
   */
  @Computed
  get missingFieldText(): string {
    const fields: string[] = this.draft.missingHints();
    const names: string[] = [];
    for (let i = 0; i < fields.length; i++) {
      names.push(TaskListViewModel.missingFieldLabel(fields[i]));
    }
    return names.join('、');
  }

  /** 解析提示条要不要出现：低可信，或者有没识别出来的字段 */
  @Computed
  get showParseEvidence(): boolean {
    const low: boolean = this.draft.certainty > 0 && this.draft.certainty < 60;
    return low || this.missingFieldText.length > 0;
  }

  /** 解析依据：低可信提示 ＋ 未识别字段（确认闸的一部分：看得见「为什么这么填」） */
  @Builder
  parseEvidence() {
    Column({ space: 8 }) {
      if (!this.lowHintDismissed && this.showParseEvidence) {
        Row({ space: 8 }) {
          Text('!')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeStore.scheme.onErrorContainer)
            .width(18)
            .height(18)
            .textAlign(TextAlign.Center)
            .borderRadius(9)
            .backgroundColor(this.themeStore.scheme.errorContainer)
          Column({ space: 2 }) {
            Text(this.draft.certainty > 0 && this.draft.certainty < 60
              ? '低可信，请核对时间与地点'
              : '有些字段没识别出来，请补齐')
              .fontSize(13)
              .fontColor(this.themeStore.scheme.error)
            // 未识别字段清单（合并 FE-40 的 missing_fields 提示；按当前草稿现算）
            if (this.missingFieldText.length > 0) {
              Text('未识别：' + this.missingFieldText)
                .fontSize(11)
                .fontColor(this.themeStore.scheme.onSurfaceVariant)
            }
            if (this.draft.degraded) {
              Text('本次为规则降级解析，建议重新解析或手动补齐')
                .fontSize(11)
                .fontColor(this.themeStore.scheme.onSurfaceVariant)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text('重新解析')
            .fontSize(12)
            .fontColor(this.themeStore.scheme.primary)
            .onClick(() => {
              this.aiFill();
            })
          Text('知道了')
            .fontSize(12)
            .fontColor(this.themeStore.scheme.onSurfaceVariant)
            .onClick(() => {
              this.lowHintDismissed = true;
            })
        }
        .width('100%')
        .padding(10)
        .backgroundColor(this.themeStore.scheme.errorContainer)
        .borderRadius(12)
      }

    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })
  }

  build() {
    Column() {
      // 标题行：「添加任务」＋「保存」＋「关闭」（**固定**在顶部、不跟着滚）
      this.sheetHeader()

      /*
       * 正文整块可滚 —— 需求方 2026-10-17：「整个半模态不能滑动啊 如果用户添加的标签太多 就超出屏幕了」。
       * 半模态自己**不会**让内容滚动（官方原文：内容里有 List/Scroll 时要自己给滚动容器设 `nestedScroll`），
       * 所以这里套一层官方 `Scroll`：
       *  · 标题行留在 `Scroll` 外面（保存/关闭任何时候都点得到）；
       *  · `nestedScroll` 按官方《绑定半模态页面》的写法给 `PARENT_FIRST / SELF_FIRST`，
       *    这样"往上拖先扩挡位、再滚内容；往下拖先滚回顶部、再收挡位"的手感才和系统一致。
       */
      Scroll() {
        Column() {
          // 来源选择：官方胶囊型单选分段按钮（图标 + 文字 ×3）
          AddTaskSourceTabs({
            selectedIndex: this.draft.sourceTab,
            onSelect: (index: number) => {
              this.draft.sourceTab = index;
            }
          })

          // —— 内容区：跟着来源切（三块各自是一个组件，都在 components/ 下）——
          Column() {
            if (this.draft.sourceTab === AddTaskSource.SCREENSHOT) {
              // 选一张截图（系统相册 picker，选完就地预览）
              AddTaskScreenshotPicker({ draft: this.draft })
            } else if (this.draft.sourceTab === AddTaskSource.VOICE) {
              // 录音按钮 + 计时（**音频还没真录**，见 AddTaskRecorder 顶部注释）
              AddTaskRecorder({ draft: this.draft })
            } else {
              // 文本粘贴框（官方 TextArea，长按即可粘贴）
              AddTaskTextInput({ draft: this.draft })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          // ⚠️ 这里**不 `layoutWeight(1)`**：内容区按自身高度贴着按钮组，下面才是名称框与芯片行。
          .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })

          // 解析失败：分类错误卡 + 重试 / 手动填写
          if (this.parseErrorCode.length > 0) {
            this.parseErrorCard()
          }

          // 解析结果提示：低可信 / 未识别字段；原文不再重复展示（在任务详情页看，见 TaskRawTextCard）
          if (this.showParseEvidence) {
            this.parseEvidence()
          }

          // —— 任务名称输入框：三种来源共用（名称与来源无关），紧跟在内容区下面 ——
          AddTaskNameInput({ draft: this.draft })
            .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })

          // —— 属性芯片行：截止日期 / 提醒我 / 重复 / 重要程度 / 来源 / ＋添加标签 / AI 预填 ——
          // AI 预填与「＋ 添加标签」同一行、同一种动作芯片（不再单独占一行）。
          // 一行装不下由组件内部的 `Flex(wrap)` 自动换行；这里只留 16vp 上间距。
          AddTaskAttributeChips({
            draft: this.draft,
            aiBusy: this.aiBusy,
            showAi: true,
            lowConfidence: this.draft.certainty > 0 && this.draft.certainty < 60,
            onAiFill: () => {
              this.aiFill();
            }
          })
          .margin({ top: LengthMetrics.resource($r('sys.float.padding_level8')) })
        }
        .width('100%')
        // 滚动内容的留白：左右/下 `padding_level8`(16vp)，上 8vp（标题行自己带了下留白）。
        // ⚠️ 带 `start`/`end` 的重载吃 `LocalizedPadding`（字段是 `LengthMetrics`），所以要走 `LengthMetrics.resource`。
        .padding({
          top: LengthMetrics.resource($r('sys.float.padding_level4')),
          bottom: LengthMetrics.resource($r('sys.float.padding_level8')),
          start: LengthMetrics.resource($r('sys.float.padding_level8')),
          end: LengthMetrics.resource($r('sys.float.padding_level8'))
        })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      // 官方要求：半模态内容里的滚动容器要显式给嵌套滚动策略，否则拖挡位与滚内容会互相抢
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })
    }
    .width('100%')
    .height('100%')
    // 2026-10-25（作者：「添加任务 bindSheet 背景没有 md 取色」）：
    // 面板底色**只能由内容自己铺** —— `SheetOptions` 里没有 `backgroundColor` 字段
    // （见文件末尾 `addTaskSheetOptions` 的注释，已核对 SDK `common.d.ts` 的接口全字段）。
    // 这里用 M3 `surface`：与任务列表 / 设置 / 板板三页同色，半模态不再是一块冷白灰。
    .backgroundColor(this.themeStore.scheme.surface)
  }
}

/**
 * 半模态的选项 —— 跟内容组件放同一个文件（组件化约定：弹层的"内容 + 选项"是一件事）。
 *
 * 取值理由：
 *  · `height: SheetSize.MEDIUM` —— 官方「半屏」挡位；表单已经排满，暂时不需要多挡位跟手；
 *  · `preferType: SheetType.BOTTOM` —— 这是默认值，显式写出来把语义钉住
 *    （`SIDE` / `CONTENT_COVER` 是 API 20+ 的其它形态，用不上也不必用）；
 *  · `dragBar: true` —— 保留官方拖拽条（关掉半模态的一种手势）；
 *  · **`showClose: false` ＋ 不设 `title`** —— 标题行（含「保存」与关闭按钮）由内容自己画，
 *    见上面 `sheetHeader()` 的注释；系统关闭按钮会和自绘的那颗重复，所以关掉；
 *  · **`blurStyle: BlurStyle.NONE`** —— 不叠官方模糊材质，面板保持干净实色
 *    （官方 @default 就是 NONE，这里显式写出来把语义钉住，免得以后误加厚模糊把底色糊掉）。
 *
 * ⚠️ **`SheetOptions` 没有 `backgroundColor` 字段**（2026-10-25 核对 SDK
 * `openharmony/ets/component/common.d.ts` 的 `SheetOptions` 接口全字段：只有
 * `blurStyle` / `maskColor` / `radius` / `borderWidth|Color|Style` / `shadow` /
 * `systemMaterial`(26.0.0+，超本工程 target 22) 这些）。
 * 所以「面板底色」没法从选项里配 —— 只能由**内容自己铺满**：`AddTaskSheet` 根节点
 * `.height('100%')` + `.backgroundColor(scheme.surface)` 把系统默认的浅色面板整体盖住。
 */
export function addTaskSheetOptions(onDismiss?: () => void): SheetOptions {
  return {
    height: SheetSize.MEDIUM,
    preferType: SheetType.BOTTOM,
    dragBar: true,
    showClose: false,
    // 面板不叠模糊材质（默认值，显式钉住）
    blurStyle: BlurStyle.NONE,
    // 划掉 / 关闭都会走到这里：页面在这一刻把草稿落盘
    onDisappear: () => {
      if (onDismiss !== undefined) {
        onDismiss();
      }
    }
  };
}
