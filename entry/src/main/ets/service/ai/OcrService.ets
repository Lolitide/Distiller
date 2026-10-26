/**
 * 端侧文字识别（Core Vision Kit）。
 *
 * 为什么要有这一层：截图添加任务时，先在本机把图上的字认出来，
 * 只把**文字**发给后端做结构化抽取 —— 图片不出手机、省流量，
 * 也不要求后端部署多模态模型。
 *
 * 约束：
 *  · Core Vision Kit 的 OCR 在模拟器上不可用（真机才有效）；
 *  · 任何失败都返回空串，由调用方决定是否回退到「上传图片给后端 OCR」。
 */
import { image } from '@kit.ImageKit';
import { textRecognition } from '@kit.CoreVisionKit';
import { fileIo } from '@kit.CoreFileKit';
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PrivacyConsent } from '../system/PrivacyConsent';

const DOMAIN: number = 0x0000;
const TAG: string = 'OcrService';
/** 与后端 /parse 的单图上限对齐（6MB 原图） */
const MAX_IMAGE_BYTES: number = 6 * 1024 * 1024;

export class OcrService {
  /**
   * 识别二维码/条形码，返回码值（没有就空串）。
   * 用 Scan Kit 的 detectBarcode；picker 给的 uri 本身就能直接传（不落临时文件）。
   */
  static async detectBarcode(uri: string): Promise<string> {
    // 隐私授权门禁：撤回后所有端侧识别一并停用（AI 能力与基础功能分隔）
    if (!PrivacyConsent.allowed()) {
      return '';
    }
    if ((uri || '').length === 0) {
      return '';
    }
    try {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL]
      };
      const input: detectBarcode.InputImage = { uri: uri };
      const results: scanBarcode.ScanResult[] = await detectBarcode.decode(input, options);
      if (results === undefined || results === null || results.length === 0) {
        return '';
      }
      const value: string | undefined = results[0].originalValue;
      return value !== undefined ? value.trim() : '';
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'barcode decode failed: %{public}s', err.message);
      return '';
    }
  }

  /** 识别本地文件（系统 picker 给的 uri）里的文字；失败返回空串 */
  static async recognizeUri(uri: string): Promise<string> {
    // 隐私授权门禁：撤回后所有端侧识别一并停用（AI 能力与基础功能分隔）
    if (!PrivacyConsent.allowed()) {
      return '';
    }
    if ((uri || '').length === 0) {
      return '';
    }
    let buffer: ArrayBuffer | undefined = undefined;
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat: fileIo.Stat = fileIo.statSync(file.fd);
      if (stat.size <= 0 || stat.size > MAX_IMAGE_BYTES) {
        return '';
      }
      const raw: ArrayBuffer = new ArrayBuffer(stat.size);
      const readLen: number = fileIo.readSync(file.fd, raw);
      if (readLen <= 0) {
        return '';
      }
      buffer = raw.slice(0, readLen);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'read image failed: %{public}s', err.message);
      return '';
    } finally {
      if (file !== undefined) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          // 关闭失败不影响识别
        }
      }
    }
    return await OcrService.recognizeBuffer(buffer);
  }

  /** 识别内存里的图片字节 */
  static async recognizeBuffer(buffer: ArrayBuffer): Promise<string> {
    let source: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      source = image.createImageSource(buffer);
      const options: image.DecodingOptions = {
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      pixelMap = await source.createPixelMap(options);
      const visionInfo: textRecognition.VisionInfo = { pixelMap: pixelMap };
      const result: textRecognition.TextRecognitionResult =
        await textRecognition.recognizeText(visionInfo);
      const text: string = result.value !== undefined ? result.value : '';
      return text.trim();
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'ocr failed: %{public}s', err.message);
      return '';
    } finally {
      if (pixelMap !== undefined) {
        await pixelMap.release();
      }
      if (source !== undefined) {
        await source.release();
      }
    }
  }
}
