/**
 * 知了 · 图片内容识别（二维码/条形码 + OCR 文字）
 *
 * 图片消息的正文不在 content 里，需要按附件 URL 下载后识别：
 *   ① 先用 Scan Kit 的 detectBarcode 识别二维码/条形码（命中即用码值）；
 *   ② 未命中再交给 Core Vision Kit 的 textRecognition 做文字识别。
 * 两个能力都不支持模拟器；失败一律返回空结果，不抛异常、不阻塞主线。
 */

import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { textRecognition } from '@kit.CoreVisionKit';
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { withTimeout } from './AsyncUtil';
import { Store } from './Store';

const DOMAIN: number = 0x0000;
const TAG: string = 'ImageRecognizer';
/** 下载超时（QQ 图片 CDN 带有时效 rkey，需要及时取） */
const DOWNLOAD_TIMEOUT_MS: number = 12000;
/** 二维码识别超时 */
const QR_TIMEOUT_MS: number = 10000;
/** 文字识别超时 */
const OCR_TIMEOUT_MS: number = 15000;

/** 识别结果：kind 为 'qr'（二维码/条形码）、'text'（OCR 文字）或 'none'。 */
export interface ImageRecognizeResult {
  kind: string;
  text: string;
}

function none(): ImageRecognizeResult {
  return { kind: 'none', text: '' };
}

export class ImageRecognizer {
  /** 下载图片并识别：先二维码，再 OCR。任何失败都返回空结果。 */
  static async recognize(url: string): Promise<ImageRecognizeResult> {
    if (url.length === 0) {
      return none();
    }
    let source: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    const httpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 6000,
        readTimeout: DOWNLOAD_TIMEOUT_MS
      };
      const res: http.HttpResponse = await httpRequest.request(url, options);
      if (res.responseCode !== 200 || res.result === undefined) {
        hilog.warn(DOMAIN, TAG, 'image download failed code=%{public}d', res.responseCode);
        return none();
      }
      const buf: ArrayBuffer = res.result as ArrayBuffer;

      const qrText: string = await ImageRecognizer.decodeBarcode(buf);
      if (qrText.length > 0) {
        return { kind: 'qr', text: qrText };
      }

      source = image.createImageSource(buf);
      const decoding: image.DecodingOptions = { desiredPixelFormat: image.PixelMapFormat.RGBA_8888 };
      pixelMap = await source.createPixelMap(decoding);
      const visionInfo: textRecognition.VisionInfo = { pixelMap: pixelMap };
      const ocr: textRecognition.TextRecognitionResult | null =
        await withTimeout<textRecognition.TextRecognitionResult>(
          textRecognition.recognizeText(visionInfo), OCR_TIMEOUT_MS);
      if (ocr === null) {
        hilog.warn(DOMAIN, TAG, 'ocr timeout');
        return { kind: 'text', text: '' };
      }
      return { kind: 'text', text: ocr.value ?? '' };
    } catch (e) {
      const err = e as Error;
      hilog.warn(DOMAIN, TAG, 'recognize failed: %{public}s', err.message);
      return none();
    } finally {
      if (pixelMap !== undefined) {
        await pixelMap.release();
      }
      if (source !== undefined) {
        await source.release();
      }
      httpRequest.destroy();
    }
  }

  /**
   * 二维码/条形码识别。
   * detectBarcode.decode 只接受图片路径（另一个 decodeImage 只吃 NV21 原始像素），
   * 因此需要把字节短暂落到沙箱缓存目录，识别完立即删除。
   */
  private static async decodeBarcode(buf: ArrayBuffer): Promise<string> {
    const ctx = Store.getAppContext();
    if (ctx === null) {
      return '';
    }
    const path: string = ctx.cacheDir + '/scan_' + Date.now() + '.tmp';
    try {
      const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      try {
        fileIo.writeSync(file.fd, buf);
      } finally {
        fileIo.closeSync(file);
      }
      const scanOptions: scanBarcode.ScanOptions = { scanTypes: [scanCore.ScanType.ALL] };
      const inputImage: detectBarcode.InputImage = { uri: 'file://' + path };
      const results: scanBarcode.ScanResult[] | null =
        await withTimeout<scanBarcode.ScanResult[]>(
          detectBarcode.decode(inputImage, scanOptions), QR_TIMEOUT_MS);
      if (results === null || results.length === 0) {
        return '';
      }
      return results[0].originalValue ?? '';
    } catch (e) {
      const err = e as Error;
      hilog.warn(DOMAIN, TAG, 'barcode decode failed: %{public}s', err.message);
      return '';
    } finally {
      try {
        fileIo.unlinkSync(path);
      } catch (e2) {
        // 临时文件可能已被系统回收，忽略
      }
    }
  }
}
