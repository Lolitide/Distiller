/**
 * 端侧语音转文字（Core Speech Kit）。
 *
 * 为什么用它：按住说话 → 本机离线识别成文字 → 只把**文字**发给后端 /parse。
 * 音频不出手机，也不需要任何云端 ASR。
 *
 * 关键约束（来自官方文档）：
 *  · `writeAudio` 每次只能 640 或 1280 字节（16k/16bit/单声道 → 640B = 20ms）；
 *  · `startListening` 是异步起效的，必须等 `onStart` 之后再写音频（否则 1002200010）；
 *  · 引擎只支持中文、离线；模拟器不可用。
 */
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PrivacyConsent } from '../system/PrivacyConsent';

const DOMAIN: number = 0x0000;
const TAG: string = 'SpeechService';
const SESSION_ID: string = 'zhiliao_add_task';
/** 16k/16bit/单声道 = 32000 B/s → 640B 恰好 20ms */
const CHUNK_BYTES: number = 640;
const SAMPLE_RATE: number = 16000;

export interface SpeechCallbacks {
  /** 中间结果（边说边出） */
  onPartial: (text: string) => void;
  /** 最终结果（松手后） */
  onFinal: (text: string) => void;
  onError: (message: string) => void;
}

export class SpeechService {
  private static engine: speechRecognizer.SpeechRecognitionEngine | undefined = undefined;
  private static capturer: audio.AudioCapturer | undefined = undefined;
  private static running: boolean = false;
  private static ready: boolean = false;
  private static finalText: string = '';
  private static callbacks: SpeechCallbacks | undefined = undefined;

  /** 开始识别 + 录音；返回 false 表示没起来（权限/引擎/启动失败） */
  static async start(callbacks: SpeechCallbacks): Promise<boolean> {
    // 隐私授权门禁：撤回后不打开麦克风、不做语音转文字
    if (!PrivacyConsent.allowed()) {
      return false;
    }
    if (SpeechService.running) {
      return false;
    }
    SpeechService.callbacks = callbacks;
    SpeechService.finalText = '';
    SpeechService.ready = false;

    const engine: speechRecognizer.SpeechRecognitionEngine | undefined =
      await SpeechService.ensureEngine(callbacks);
    if (engine === undefined) {
      return false;
    }

    engine.setListener({
      onStart: (sessionId: string, eventMessage: string) => {
        SpeechService.ready = true;
      },
      onEvent: (sessionId: string, eventCode: number, eventMessage: string) => {
        // 不需要处理：只用 onResult / onComplete
      },
      onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
        const cb: SpeechCallbacks | undefined = SpeechService.callbacks;
        if (cb === undefined || result === undefined) {
          return;
        }
        if (result.isFinal) {
          SpeechService.finalText = SpeechService.finalText + result.result;
          cb.onPartial(SpeechService.finalText);
        } else {
          cb.onPartial(SpeechService.finalText + result.result);
        }
      },
      onComplete: (sessionId: string, eventMessage: string) => {
        const cb: SpeechCallbacks | undefined = SpeechService.callbacks;
        if (cb !== undefined) {
          cb.onFinal(SpeechService.finalText.trim());
        }
      },
      onError: (sessionId: string, errorCode: number, errorMessage: string) => {
        const cb: SpeechCallbacks | undefined = SpeechService.callbacks;
        hilog.warn(DOMAIN, TAG, 'asr error %{public}d: %{public}s', errorCode, errorMessage);
        if (cb !== undefined) {
          cb.onError('语音识别失败（' + errorCode + '）');
        }
      }
    });

    const params: speechRecognizer.StartParams = {
      sessionId: SESSION_ID,
      audioInfo: {
        audioType: 'pcm',
        sampleRate: SAMPLE_RATE,
        soundChannel: 1,
        sampleBit: 16
      }
    };
    try {
      engine.startListening(params);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'startListening failed: %{public}s', err.message);
      callbacks.onError('语音识别启动失败');
      return false;
    }

    // 等 onStart（最多 1.5s）——早于它写音频会报 1002200010
    const ready: boolean = await SpeechService.waitReady(1500);
    if (!ready) {
      callbacks.onError('语音识别没有就绪，请重试');
      return false;
    }

    const capturer: audio.AudioCapturer | undefined = await SpeechService.createCapturer();
    if (capturer === undefined) {
      callbacks.onError('麦克风不可用');
      return false;
    }
    SpeechService.capturer = capturer;
    SpeechService.running = true;
    SpeechService.pump(capturer, engine);
    return true;
  }

  /** 松手：停止录音并让引擎收尾（最终结果走 onFinal） */
  static async stop(): Promise<void> {
    if (!SpeechService.running && SpeechService.capturer === undefined) {
      return;
    }
    SpeechService.running = false;
    const capturer: audio.AudioCapturer | undefined = SpeechService.capturer;
    SpeechService.capturer = undefined;
    if (capturer !== undefined) {
      try {
        await capturer.stop();
      } catch (error) {
        // 已经停了
      }
      try {
        await capturer.release();
      } catch (error) {
        // 释放失败不影响结果
      }
    }
    const engine: speechRecognizer.SpeechRecognitionEngine | undefined = SpeechService.engine;
    if (engine !== undefined) {
      try {
        engine.finish(SESSION_ID);
      } catch (error) {
        const err = error as BusinessError;
        hilog.warn(DOMAIN, TAG, 'finish failed: %{public}s', err.message);
      }
    }
  }

  /** 页面销毁时兜底：停录音 + 释放引擎 */
  static async release(): Promise<void> {
    await SpeechService.stop();
    const engine: speechRecognizer.SpeechRecognitionEngine | undefined = SpeechService.engine;
    SpeechService.engine = undefined;
    SpeechService.callbacks = undefined;
    if (engine !== undefined) {
      try {
        engine.shutdown();
      } catch (error) {
        // 已销毁
      }
    }
  }

  // ---------------------------------------------------------------- 内部

  private static async ensureEngine(
    callbacks: SpeechCallbacks): Promise<speechRecognizer.SpeechRecognitionEngine | undefined> {
    if (SpeechService.engine !== undefined) {
      return SpeechService.engine;
    }
    const extra: Record<string, Object> = {
      'locate': 'CN',
      'recognizerMode': 'short'
    };
    const params: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: 1,
      extraParams: extra
    };
    try {
      SpeechService.engine = await speechRecognizer.createEngine(params);
      return SpeechService.engine;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'createEngine failed: %{public}d %{public}s', err.code, err.message);
      callbacks.onError('本机语音识别不可用');
      return undefined;
    }
  }

  private static async waitReady(timeoutMs: number): Promise<boolean> {
    const step: number = 50;
    let waited: number = 0;
    while (waited < timeoutMs) {
      if (SpeechService.ready) {
        return true;
      }
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), step);
      });
      waited += step;
    }
    return SpeechService.ready;
  }

  private static async createCapturer(): Promise<audio.AudioCapturer | undefined> {
    try {
      const streamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };
      const capturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };
      const capturer: audio.AudioCapturer = await audio.createAudioCapturer({
        streamInfo: streamInfo,
        capturerInfo: capturerInfo
      });
      await capturer.start();
      return capturer;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'createAudioCapturer failed: %{public}s', err.message);
      return undefined;
    }
  }

  /** 持续把 PCM 喂给识别引擎；`read(size, true)` 会阻塞到够 640 字节，天然按 20ms 节奏 */
  private static async pump(capturer: audio.AudioCapturer,
    engine: speechRecognizer.SpeechRecognitionEngine): Promise<void> {
    while (SpeechService.running) {
      try {
        const buffer: ArrayBuffer = await capturer.read(CHUNK_BYTES, true);
        if (!SpeechService.running) {
          break;
        }
        const bytes: Uint8Array = new Uint8Array(buffer);
        if (bytes.length >= CHUNK_BYTES) {
          engine.writeAudio(SESSION_ID, bytes.slice(0, CHUNK_BYTES));
        }
      } catch (error) {
        const err = error as BusinessError;
        hilog.warn(DOMAIN, TAG, 'pump stopped: %{public}s', err.message);
        break;
      }
    }
  }
}
