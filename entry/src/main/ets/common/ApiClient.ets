import { http } from '@kit.NetworkKit';
import { Config } from './Config';
import { ApiResult, parseApi } from './Types';

export class ApiClient {
  static deviceId: string = '';
  static token: string = '';

  private static headers(): Record<string, string> {
    const h: Record<string, string> = { 'Content-Type': 'application/json' };
    if (ApiClient.deviceId.length > 0) {
      h['X-Device-Id'] = ApiClient.deviceId;
    }
    if (ApiClient.token.length > 0) {
      h['X-Device-Token'] = ApiClient.token;
    }
    return h;
  }

  private static async request<T>(method: string, path: string, body?: Object,
    readTimeoutMs?: number): Promise<ApiResult<T>> {
    const httpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method === 'GET' ? http.RequestMethod.GET :
          (method === 'DELETE' ? http.RequestMethod.DELETE : http.RequestMethod.POST),
        header: ApiClient.headers(),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: readTimeoutMs ?? 8000
      };
      if (body !== undefined) {
        options.extraData = JSON.stringify(body);
      }
      const res: http.HttpResponse = await httpRequest.request(Config.baseUrl + path, options);
      const text: string = res.result as string;
      return parseApi<T>(text);
    } catch (e) {
      const err: ApiResult<T> = {
        ok: false,
        error: { code: 'network', message: '连不上服务器，请检查与电脑是否在同一 Wi-Fi，且防火墙已放行 8730 端口' }
      };
      return err;
    } finally {
      httpRequest.destroy();
    }
  }

  static get<T>(path: string): Promise<ApiResult<T>> {
    return ApiClient.request<T>('GET', path);
  }

  static post<T>(path: string, body: Object, readTimeoutMs?: number): Promise<ApiResult<T>> {
    return ApiClient.request<T>('POST', path, body, readTimeoutMs);
  }

  static del<T>(path: string): Promise<ApiResult<T>> {
    return ApiClient.request<T>('DELETE', path);
  }

  /**
   * 拉原始字节（`/attachment` 的响应体是附件本身，不是 JSON）。
   * 失败（连不上 / 非 200 / 窗口过期 404 / QQ 拉取失败 502）一律返回 null。
   */
  static async getBytes(path: string, readTimeoutMs?: number): Promise<ArrayBuffer | null> {
    const httpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: ApiClient.headers(),
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 5000,
        readTimeout: readTimeoutMs ?? 20000
      };
      const res: http.HttpResponse = await httpRequest.request(Config.baseUrl + path, options);
      if (res.responseCode !== 200 || res.result === undefined) {
        return null;
      }
      return res.result as ArrayBuffer;
    } catch (e) {
      return null;
    } finally {
      httpRequest.destroy();
    }
  }
}
