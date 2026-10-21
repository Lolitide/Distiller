import { ThemeStore } from '../utils/Theme';
/*
 * 「添加任务 · 录音」内容区 —— 一个圆形录音按钮 ＋ 计时。
 *
 * 需求方 2026-10-17：「…录音是录音组件」。
 *
 * 三态（本地状态机，`RecordState`）：
 *  · IDLE    圆钮（`sys.symbol.mic`）＋「点击开始录音」
 *  · RECORDING 圆钮变结束（`sys.symbol.stop_circle_fill`，红色 `ohos_id_color_warning`）＋ 计时 `mm:ss` ＋「正在录音」
 *  · DONE    回到麦克风图标 ＋「已录 mm:ss」＋「点击重新录音」
 *
 * 🔴 **本步只做了交互与计时骨架，音频还没有真的录**：
 * 真录音要走 `AVRecorder`（`@kit.MediaKit`）＋ **`ohos.permission.MICROPHONE`** 动态授权
 * （权限申请按纪律收口在 `service/system/`，而且 `module.json5` 要加 `requestPermissions`），
 * 那是下一步单独一条；届时这里的 `start()/finish()` 只把 `setInterval` 换成录音服务的回调，
 * 界面不用改。**所以现在计时跑起来并不代表录到了声音**，演示前请注意这一点。
 *
 * 另外：录音文件将来走 `service/ai` 的语音识别（Core Speech Kit，**不支持模拟器、必须动态 import**）。
 */
import { LengthMetrics } from '@kit.ArkUI';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { ADD_TASK_CONTENT_HEIGHT_VP } from './AddTaskContentMetrics';

/**
 * 录音圆钮直径（vp）：需求方 2026-10-17「按钮改小一点吧」→ 从 64 降到 **48**。
 * 官方没有"录音按钮"这类 token，48vp 仍大于最小可点尺寸（≥40vp），也放得下 28vp 图标。
 */
const RECORD_BUTTON_SIZE_VP: number = 48;

/** 计时刷新间隔（毫秒）：1 秒 */
const TIMER_INTERVAL_MS: number = 1000;

/** 圆钮与文字之间的间距（vp）：＝官方 `sys.float.padding_level4`(4vp)，`Column({space})` 只吃 number */
const STACK_GAP_VP: number = 4;

/**
 * 内容盒高度（vp）—— **修两件事**：
 *
 * ①「点录音后内容区突然撑大」（需求方 2026-10-17）：原来 idle 一行字、录音时两行字，高度跟着跳；
 *    现在 idle 不显示文字、录音/结束最多一行，且盒子高度**钉死**（48 按钮 ＋ 4 间距 ＋ 24 单行
 *    ＋ 上下 `padding_level8`×2 = 108，120 里头绰绰有余），三态一样高。
 * ②「录音的内容区和截图、文本的内容区不一样高」（需求方 2026-10-17）：原来这里是
 *    `constraintSize({minHeight: 112})`，而另外两块是 **120**，于是录音那格天生矮 8vp。
 *    现在三块统一吃 `ADD_TASK_CONTENT_HEIGHT_VP`，且都用**固定高度**（不是 minHeight）。
 */
const RECORD_BOX_HEIGHT_VP: number = ADD_TASK_CONTENT_HEIGHT_VP;

/** 录音状态机 */
enum RecordState {
  IDLE = 0,
  RECORDING = 1,
  DONE = 2
}

@ComponentV2
export struct AddTaskRecorder {
  /** 视觉个性化：M3 色系（全局 MD3 化，2026-10-19） */
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 表单草稿：录音时长记到 `draft.recordSeconds`（保存时作为这一项的痕迹） */
  @Require @Param draft: AddTaskDraft;
  @Local state: RecordState = RecordState.IDLE;
  /** 已计时秒数（录音态每秒 +1） */
  @Local seconds: number = 0;
  /** 计时器 id；-1 ＝ 没在跑 */
  private timerId: number = -1;

  aboutToDisappear(): void {
    // 半模态被关掉/切走时必须停表，否则定时器会一直跑
    this.stopTimer();
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** 开始：清计时 → 进入录音态 → 起表（真录音接入后在这里调录音服务） */
  private start(): void {
    this.seconds = 0;
    this.draft.recordSeconds = 0;
    this.state = RecordState.RECORDING;
    this.stopTimer();
    this.timerId = setInterval(() => {
      this.seconds = this.seconds + 1;
    }, TIMER_INTERVAL_MS);
  }

  /** 结束：停表 → 进入完成态 → 把时长交给草稿（真录音接入后在这里 stop + 落盘） */
  private finish(): void {
    this.stopTimer();
    this.state = RecordState.DONE;
    this.draft.recordSeconds = this.seconds;
  }

  /** 秒 → `mm:ss`（纯数字格式化，不是文案，所以不走资源） */
  private formatDuration(): string {
    const minutes: number = Math.floor(this.seconds / 60);
    const rest: number = this.seconds % 60;
    const mm: string = minutes < 10 ? `0${minutes}` : `${minutes}`;
    const ss: string = rest < 10 ? `0${rest}` : `${rest}`;
    return `${mm}:${ss}`;
  }

  /** 按钮图标：录音中＝结束、其余＝麦克风（都是官方 Symbol 库里的名字） */
  @Computed
  get buttonSymbol(): Resource {
    return this.state === RecordState.RECORDING ? $r('sys.symbol.stop_circle_fill') : $r('sys.symbol.mic');
  }

  /** 按钮的无障碍文本（图标按钮必须给，读屏要播报） */
  @Computed
  get buttonA11yText(): Resource {
    return this.state === RecordState.RECORDING
      ? $r('app.string.add_task_record_stop')
      : $r('app.string.add_task_record_start');
  }

  /**
   * 按钮下方那行字 —— **idle 态不显示**（需求方 2026-10-17：「把点击开始录音的文字去了吧」），
   * 录音中显示计时、结束后显示「已录 mm:ss」，**最多一行**（这样内容盒高度不跳，见 `RECORD_BOX_MIN_HEIGHT_VP`）。
   * 「点击重新录音」那句也一并去掉：按钮图标本身就会变回来，不用再提示。
   */
  @Computed
  get stateLabel(): Resource | string | undefined {
    if (this.state === RecordState.RECORDING) {
      return this.formatDuration();
    }
    if (this.state === RecordState.DONE) {
      return $r('app.string.add_task_record_done', this.formatDuration());
    }
    return undefined;
  }

  build() {
    // 需求方 2026-10-17：「把录音按钮放入内容区 不要占满整个半模态页面 下面还有东西」——
    // 所以这里**不再撑满**（原来 `.height('100%')` + 垂直居中，按钮飘在半模态正中），
    // 改成和「截图 / 文本」两块**同一套内容区外观**（同底色 + 同圆角 + 内边距），高度由内容撑开，
    // 贴在来源按钮组下方，下面留给以后的东西（转写文本 / 提交按钮）。
    Column({ space: STACK_GAP_VP }) {
      // 圆形按钮：官方 Button 圆形档，**底色交给按钮默认主题色**（蓝），图标用官方 on-primary（白）——
      // 之前给的是透明底 + 灰底，压在浅灰内容区上几乎看不见轮廓。
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph(this.buttonSymbol)
          .fontSize($r('sys.float.ohos_id_min_circle_button_icon_size'))
          .fontColor([$r('sys.color.font_on_primary')])
      }
      .width(RECORD_BUTTON_SIZE_VP)
      .height(RECORD_BUTTON_SIZE_VP)
      // 录音中用警示红（结束是"中断"动作），其余走按钮默认主题色
      .backgroundColor(this.state === RecordState.RECORDING
        ? $r('sys.color.ohos_id_color_warning')
        : this.themeStore.scheme.primary)
      .onClick(() => {
        if (this.state === RecordState.RECORDING) {
          this.finish();
        } else {
          this.start();
        }
      })
      .accessibilityText(this.buttonA11yText)

      if (this.stateLabel !== undefined) {
        Text(this.stateLabel)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
      }
    }
    .width('100%')
    // 三块内容区**同一个固定高度**（见 `ADD_TASK_CONTENT_HEIGHT_VP`）：idle（没有文字）也占同样高度，
    // 点录音时不会撑大，也不会比「截图 / 文本」那两块矮一截。
    .height(RECORD_BOX_HEIGHT_VP)
    .justifyContent(FlexAlign.Center)
    // 内容区外观与「截图 / 文本」两块一致（底色＝来源按钮那条胶囊轨道的灰）
    .padding({
      top: LengthMetrics.resource($r('sys.float.padding_level8')),
      bottom: LengthMetrics.resource($r('sys.float.padding_level8'))
    })
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }
}
