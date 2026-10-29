/**
 * 手动添加的「AI 预填」：把文本/截图交给后端 `/parse`，拿回一条候选。
 *
 * 为什么放这里而不是页面：读图、base64、错误文案都在这一层收口，
 * 页面只负责「点按钮 → 拿结果 → 填进草稿」。
 *
 * 隐私：`/parse` 是**无状态**的（不落盘、不进窗口/候选流）；图片只在本进程内存里转一次 base64。
 */
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RelayApi } from '../backend/RelayApi';
import { apiErrorMessage, CandidateItem } from '../backend/BackendTypes';
import { OcrService } from '../ai/OcrService';
import { PrivacyConsent } from '../system/PrivacyConsent';

const DOMAIN: number = 0x0000;
const TAG: string = 'ManualParse';
/** 单张图上限：后端那边也是 8MB base64（约 6MB 原图） */
const MAX_IMAGE_BYTES: number = 6 * 1024 * 1024;
/** 后端 file_b64 上限 4MB（base64），原始文件留余量 */
const MAX_FILE_BYTES: number = 3 * 1024 * 1024;

export interface ManualParseResult {
  ok: boolean;
  message: string;
  /** 只有 ok=true 时有值 */
  candidate?: CandidateItem;
  /** 后端合并后的文本（文本/OCR/文件抽取）；可用于回填原文 */
  text: string;
  /** 截图是否在**端侧**识别（图片没离开手机）；用于给用户一句更准确的提示 */
  localOcr?: boolean;
  /** 二维码/条形码里读到的 URL（详情页要能点开） */
  link?: string;
  /** 失败原因码（no_server/network/not_supported/...），用于页面分类提示 */
  code?: string;
}

export class ManualParseService {
  /** 撤回隐私授权后统一的拒绝结果（AI / 云功能与基础功能分隔） */
  private static denied(): ManualParseResult {
    return {
      ok: false,
      message: '已撤回隐私授权，AI 解析不可用；可在「设置 → 关于 → 隐私说明」里重新授权',
      text: '',
      code: 'privacy'
    };
  }

  static async parseText(text: string): Promise<ManualParseResult> {
    if (!PrivacyConsent.allowed()) {
      return ManualParseService.denied();
    }
    const trimmed: string = (text || '').trim();
    if (trimmed.length === 0) {
      return { ok: false, message: '先输入或粘贴一段内容', text: '' };
    }
    const res = await RelayApi.parseText(trimmed, 'manual_text');
    if (!res.ok || res.data === undefined) {
      return { ok: false, message: apiErrorMessage(res), text: '', code: res.error !== undefined ? res.error.code : 'unknown' };
    }
    return { ok: true, message: '', candidate: res.data.candidate, text: res.data.text };
  }

  static async parseImage(uri: string): Promise<ManualParseResult> {
    // 截图解析链路既走端侧 OCR 也走服务端模型，撤回后整条链路一起停
    if (!PrivacyConsent.allowed()) {
      return ManualParseService.denied();
    }
    if ((uri || '').length === 0) {
      return { ok: false, message: '先选一张截图', text: '' };
    }

    // ① 先认二维码/条形码：如果是 URL，直接做成带链接的任务
    //    （把 URL 丢给模型没有意义，还会浪费一次调用）
    const code: string = await OcrService.detectBarcode(uri);
    if (code.length > 0 && ManualParseService.isHttpUrl(code)) {
      return {
        ok: true,
        message: '',
        candidate: ManualParseService.linkCandidate(code),
        text: code,
        localOcr: true,
        link: code
      };
    }

    // ② 优先在**端侧** OCR：图片不出手机，只把文字发给后端，
    //    这样后端没有多模态模型也能用，流量也更小。
    const localText: string = await OcrService.recognizeUri(uri);
    if (localText.length > 0) {
      const local = await RelayApi.parseText(localText, 'manual_screenshot');
      if (local.ok && local.data !== undefined) {
        return {
          ok: true,
          message: '',
          candidate: local.data.candidate,
          text: local.data.text.length > 0 ? local.data.text : localText,
          localOcr: true
        };
      }
      // 端侧识别成功但后端抽取失败：把文字带回去，用户至少能手动改
      return { ok: false, message: apiErrorMessage(local), text: localText, localOcr: true, code: local.error !== undefined ? local.error.code : 'unknown' };
    }

    // ③ 端侧识别不到（模拟器/图片太糊/非文字）：回退到后端多模态 OCR
    const base64: string = ManualParseService.readBase64(uri, MAX_IMAGE_BYTES);
    if (base64.length === 0) {
      return { ok: false, message: '读不到这张图片，请重新选择', text: '' };
    }
    const res = await RelayApi.parseImage(base64, 'manual_screenshot');
    if (!res.ok || res.data === undefined) {
      return { ok: false, message: apiErrorMessage(res), text: '', code: res.error !== undefined ? res.error.code : 'unknown' };
    }
    return { ok: true, message: '', candidate: res.data.candidate, text: res.data.text, localOcr: false };
  }

  /** 转发文件 → base64 → 后端抽取文本 → 候选（不落盘；过大时返回可读提示） */
  static async parseFile(uri: string, fileName: string): Promise<ManualParseResult> {
    if (!PrivacyConsent.allowed()) {
      return ManualParseService.denied();
    }
    if ((uri || '').length === 0 || (fileName || '').length === 0) {
      return { ok: false, message: '读不到这个文件', text: '' };
    }
    const base64: string = ManualParseService.readBase64(uri, MAX_FILE_BYTES);
    if (base64.length === 0) {
      return { ok: false, message: '文件读不到或超过 3MB，请换一个文件', text: '' };
    }
    const res = await RelayApi.parseFile(base64, fileName, 'manual_file');
    if (!res.ok || res.data === undefined) {
      return {
        ok: false,
        message: apiErrorMessage(res),
        text: '',
        code: res.error !== undefined ? res.error.code : 'unknown'
      };
    }
    return { ok: true, message: '', candidate: res.data.candidate, text: res.data.text };
  }

  private static isHttpUrl(text: string): boolean {
    const lower: string = text.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  /** 扫码得到 URL 时构造一条最小候选（标题固定「扫码链接」，链接另存到 Task.linkUrl） */
  private static linkCandidate(url: string): CandidateItem {
    return {
      candidate_id: 'qr_' + Date.now(),
      rev_seq: 0,
      thread_id: '',
      kind: '待办',
      priority: 'normal',
      level: 0,
      category: '其他',
      channel: 'manual',
      due_at: 0,
      due_text: '',
      repeat: [],
      repeat_text: '',
      certainty: 100,
      missing_fields: ['dueAt', 'place', 'who'],
      title: '扫码链接',
      summary: url,
      time_text: '',
      time_normalized: '',
      time_unresolved: false,
      place: '',
      who: '',
      deadline: '',
      items: [],
      steps: [],
      tags: [],
      confidence: 1,
      engine: 'rules',
      source: {
        group_openid: '',
        group_label: '扫码',
        senders: [],
        msg_ids: [],
        count: 1,
        first_ts: '',
        last_ts: ''
      },
      created_at: ''
    };
  }

  /** 读文件 → base64；失败返回空串（页面据此提示换图） */
  private static readBase64(uri: string, maxBytes: number): string {
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat: fileIo.Stat = fileIo.statSync(file.fd);
      if (stat.size <= 0 || stat.size > maxBytes) {
        return '';
      }
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      const readLen: number = fileIo.readSync(file.fd, buffer);
      if (readLen <= 0) {
        return '';
      }
      const bytes: Uint8Array = new Uint8Array(buffer.slice(0, readLen));
      return new util.Base64Helper().encodeToStringSync(bytes);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'read file failed: %{public}s', err.message);
      return '';
    } finally {
      if (file !== undefined) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          // 关不掉不影响结果
        }
      }
    }
  }
}
