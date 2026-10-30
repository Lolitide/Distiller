/**
 * 把「转发给机器人」的文件下载到应用缓存，交给 `/parse` 抽取文本。
 *
 * 只处理用户主动转发的一个文件；文件落在 cacheDir，随系统清理，不进入相册/不上云。
 * QQ 附件 URL 有时效；失败返回空串，由调用方降级成「文件消息（未识别）」。
 */
import { common } from '@kit.AbilityKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PrivacyConsent } from '../system/PrivacyConsent';

const DOMAIN: number = 0x0000;
const TAG: string = 'ForwardFile';

export class ForwardFileService {
  private static extensionOf(fileName: string): string {
    const lower: string = fileName.toLowerCase();
    const dot: number = lower.lastIndexOf('.');
    if (dot < 0 || dot === lower.length - 1) {
      return '.bin';
    }
    const ext: string = lower.substring(dot);
    if (ext.length > 10 || ext.indexOf('/') >= 0 || ext.indexOf('\\') >= 0) {
      return '.bin';
    }
    return ext;
  }

  static async download(context: common.Context, url: string, fileName: string): Promise<string> {
    if (!PrivacyConsent.allowed() || url.length === 0) {
      return '';
    }
    const req: http.HttpRequest = http.createHttp();
    try {
      const res: http.HttpResponse = await req.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      if (res.responseCode !== 200) {
        hilog.warn(DOMAIN, TAG, 'download status %{public}d', res.responseCode);
        return '';
      }
      const bytes: ArrayBuffer = res.result as ArrayBuffer;
      if (bytes.byteLength === 0) {
        return '';
      }
      const path: string = context.cacheDir + '/forward-file-' + Date.now()
        + ForwardFileService.extensionOf(fileName);
      const file: fileIo.File = fileIo.openSync(path,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, bytes);
      } finally {
        fileIo.closeSync(file);
      }
      return fileUri.getUriFromPath(path);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'download failed: %{public}d %{public}s', err.code, err.message);
      return '';
    } finally {
      req.destroy();
    }
  }
}
