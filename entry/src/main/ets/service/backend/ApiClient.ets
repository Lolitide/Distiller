/**
 * 极简 HTTP 客户端：只做「发请求 + 解析统一响应包 + 带上设备身份」。
 *
 * 契约（见 05_API接口文档 §0）：
 *   · 除 `/health` 与 `/device/register` 外都要 `X-Device-Id` + `X-Device-Token`；
 *   · 响应统一 `{"ok":true,"data":...}` / `{"ok":false,"error":{code,message}}`；
 *   · 出错不抛到页面层 —— 一律折成 `ApiResult`，页面只判断 `res.ok`。
 */
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackendConfig } from './BackendConfig';
import { ApiResult } from './BackendTypes';

const DOMAIN: number = 0x0000;
const TAG: string = 'ApiClient';
const CONNECT_TIMEOUT: number = 8000;
const READ_TIMEOUT: number = 25000;

export class ApiClient {
  static async get<T>(path: string): Promise<ApiResult<T>> {
    return await ApiClient.request<T>(http.RequestMethod.GET, path, '');
  }

  static async post<T>(path: string, body: Record<string, Object>): Promise<ApiResult<T>> {
    return await ApiClient.request<T>(http.RequestMethod.POST, path, JSON.stringify(body));
  }

  static async del<T>(path: string): Promise<ApiResult<T>> {
    return await ApiClient.request<T>(http.RequestMethod.DELETE, path, '');
  }

  private static async request<T>(method: http.RequestMethod, path: string,
    body: string): Promise<ApiResult<T>> {
    const url: string = BackendConfig.baseUrl + path;
    if (BackendConfig.baseUrl.length === 0) {
      return {
        ok: false,
        error: { code: 'no_server', message: '还没有填写服务器地址' }
      };
    }
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (BackendConfig.deviceId.length > 0) {
      headers['X-Device-Id'] = BackendConfig.deviceId;
    }
    if (BackendConfig.token.length > 0) {
      headers['X-Device-Token'] = BackendConfig.token;
    }

    const req: http.HttpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method,
        header: headers,
        connectTimeout: CONNECT_TIMEOUT,
        readTimeout: READ_TIMEOUT,
        expectDataType: http.HttpDataType.STRING
      };
      if (body.length > 0) {
        options.extraData = body;
      }
      const resp: http.HttpResponse = await req.request(url, options);
      const text: string = typeof resp.result === 'string' ? resp.result : '';
      return ApiClient.parse<T>(text, resp.responseCode);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'request failed %{public}s: %{public}s', path, err.message);
      return {
        ok: false,
        error: { code: 'network', message: '连不上服务器，请检查地址与网络：' + err.message }
      };
    } finally {
      req.destroy();
    }
  }

  /** 把响应文本折成 ApiResult；HTTP 4xx/5xx 但 body 是标准错误包时保留后端错误码 */
  private static parse<T>(text: string, status: number): ApiResult<T> {
    if (text.length === 0) {
      return { ok: false, error: { code: 'bad_response', message: '服务器没有返回内容' } };
    }
    try {
      const parsed: ApiResult<T> = JSON.parse(text) as ApiResult<T>;
      if (parsed === null || typeof parsed !== 'object' || parsed.ok === undefined) {
        return { ok: false, error: { code: 'bad_response', message: '服务器返回格式不对' } };
      }
      return parsed;
    } catch (error) {
      return {
        ok: false,
        error: { code: 'bad_json', message: '服务器返回的不是 JSON（HTTP ' + status + '）' }
      };
    }
  }
}
