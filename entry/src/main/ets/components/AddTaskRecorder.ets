import { ThemeStore } from '../utils/Theme';
/*
 * 「添加任务 · 录音」内容区 —— **按住说话**（2026-10-22 接入 Core Speech Kit）。
 *
 * 交互：按住圆钮开始录音与识别，松手结束；识别结果实时写进 `draft.rawText`，
 * 之后可以点芯片行的「AI 预填」把文字整理成任务（名称/到期/提醒/重复/标签）。
 *
 * 三态：
 *  · IDLE      圆钮（mic）＋「按住说话」
 *  · RECORDING 圆钮变结束（红色）＋ 计时 mm:ss ＋「松开结束」，下方实时显示转写文字
 *  · DONE      回到麦克风 ＋「已转写」，下方保留识别文本
 *
 * 隐私：音频只在**本机**转文字（Core Speech Kit 离线识别），不上传音频；
 * 只有文字会在点「AI 预填」时发往后端。
 */
import { LengthMetrics } from '@kit.ArkUI';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';
import { ADD_TASK_CONTENT_HEIGHT_VP } from './AddTaskContentMetrics';
import { SpeechCallbacks, SpeechService } from '../service/ai/SpeechService';

/** 录音圆钮直径（vp）：48 → 44，给下面两行文字留高度 */
const RECORD_BUTTON_SIZE_VP: number = 44;
/** 计时刷新间隔（毫秒） */
const TIMER_INTERVAL_MS: number = 1000;
/** 圆钮与文字之间的间距（vp） */
const STACK_GAP_VP: number = 4;
/** 与截图/文本内容区同高 */
const RECORD_BOX_HEIGHT_VP: number = ADD_TASK_CONTENT_HEIGHT_VP;

enum RecordState {
  IDLE = 0,
  RECORDING = 1,
  DONE = 2
}

@ComponentV2
export struct AddTaskRecorder {
  @Local themeStore: ThemeStore = ThemeStore.instance();

  /** 表单草稿：转写结果写 `rawText`，时长写 `recordSeconds` */
  @Require @Param draft: AddTaskDraft;
  @Local state: RecordState = RecordState.IDLE;
  @Local seconds: number = 0;
  /** 手指是否还按着（异步申请权限期间可能已经松手） */
  private pressing: boolean = false;
  private timerId: number = -1;

  aboutToDisappear(): void {
    this.pressing = false;
    this.stopTimer();
    SpeechService.release();
  }

  private stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private startTimer(): void {
    this.stopTimer();
    this.timerId = setInterval(() => {
      this.seconds = this.seconds + 1;
    }, TIMER_INTERVAL_MS);
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      // toast 失败不影响主流程
    }
  }

  /** 动态申请麦克风权限（user_grant）；已有权限时系统直接返回授权结果 */
  private async ensureMicPermission(): Promise<boolean> {
    const context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      return false;
    }
    try {
      const at = abilityAccessCtrl.createAtManager();
      const list: Permissions[] = ['ohos.permission.MICROPHONE'];
      const result = await at.requestPermissionsFromUser(context, list);
      return result.authResults.length > 0
        && result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      const err = error as BusinessError;
      return false;
    }
  }

  /** 按下：授权 → 起录音与识别 → 起计时 */
  private async pressStart(): Promise<void> {
    if (this.state === RecordState.RECORDING) {
      return;
    }
    this.pressing = true;
    const granted: boolean = await this.ensureMicPermission();
    if (!this.pressing) {
      return; // 等权限弹窗期间已经松手
    }
    if (!granted) {
      this.toast('需要麦克风权限才能语音输入');
      return;
    }

    this.seconds = 0;
    this.draft.rawText = '';
    this.state = RecordState.RECORDING;
    this.startTimer();

    const callbacks: SpeechCallbacks = {
      onPartial: (text: string) => {
        this.draft.rawText = text;
      },
      onFinal: (text: string) => {
        this.stopTimer();
        this.state = RecordState.DONE;
        this.draft.recordSeconds = this.seconds;
        if (text.length > 0) {
          this.draft.rawText = text;
        } else {
          this.toast('没听清，请再说一次');
          this.state = RecordState.IDLE;
        }
      },
      onError: (message: string) => {
        this.stopTimer();
        this.state = RecordState.IDLE;
        this.toast(message);
      }
    };

    const started: boolean = await SpeechService.start(callbacks);
    if (!started) {
      this.stopTimer();
      this.state = RecordState.IDLE;
      return;
    }
    // 引擎启动期间松手了 → 立刻收尾
    if (!this.pressing) {
      await SpeechService.stop();
    }
  }

  /** 松手：停麦并让引擎出最终结果 */
  private pressEnd(): void {
    this.pressing = false;
    if (this.state !== RecordState.RECORDING) {
      return;
    }
    this.stopTimer();
    this.state = RecordState.DONE;
    SpeechService.stop();
  }

  private formatDuration(): string {
    const minutes: number = Math.floor(this.seconds / 60);
    const rest: number = this.seconds % 60;
    const mm: string = minutes < 10 ? `0${minutes}` : `${minutes}`;
    const ss: string = rest < 10 ? `0${rest}` : `${rest}`;
    return `${mm}:${ss}`;
  }

  @Computed
  get buttonSymbol(): Resource {
    return this.state === RecordState.RECORDING ? $r('sys.symbol.stop_circle_fill') : $r('sys.symbol.mic');
  }

  @Computed
  get buttonA11yText(): Resource {
    return this.state === RecordState.RECORDING
      ? $r('app.string.add_task_record_stop')
      : $r('app.string.add_task_record_start');
  }

  @Computed
  get stateLabel(): string {
    if (this.state === RecordState.RECORDING) {
      return this.formatDuration() + ' · 松开结束';
    }
    if (this.state === RecordState.DONE) {
      return '已转写';
    }
    return '按住说话';
  }

  build() {
    Column({ space: STACK_GAP_VP }) {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph(this.buttonSymbol)
          .fontSize($r('sys.float.ohos_id_min_circle_button_icon_size'))
          .fontColor([$r('sys.color.font_on_primary')])
      }
      .width(RECORD_BUTTON_SIZE_VP)
      .height(RECORD_BUTTON_SIZE_VP)
      .backgroundColor(this.state === RecordState.RECORDING
        ? $r('sys.color.ohos_id_color_warning')
        : this.themeStore.scheme.primary)
      .accessibilityText(this.buttonA11yText)
      // **按住说话**：Down 开始、Up/Cancel 结束（不用 onClick，避免"点一下录到底"）
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressStart();
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressEnd();
        }
      })

      Text(this.stateLabel)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))

      if (this.draft.rawText.length > 0) {
        Text(this.draft.rawText)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height(RECORD_BOX_HEIGHT_VP)
    .justifyContent(FlexAlign.Center)
    .padding({
      top: LengthMetrics.resource($r('sys.float.padding_level8')),
      bottom: LengthMetrics.resource($r('sys.float.padding_level8'))
    })
    .backgroundColor($r('sys.color.segment_button_v2_capsule_button_background'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }
}
