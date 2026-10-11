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

  private static async request<T>(method: string, path: string, body?: Object): Promise<ApiResult<T>> {
    const httpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method === 'GET' ? http.RequestMethod.GET :
          (method === 'DELETE' ? http.RequestMethod.DELETE : http.RequestMethod.POST),
        header: ApiClient.headers(),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: 8000
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

  static post<T>(path: string, body: Object): Promise<ApiResult<T>> {
    return ApiClient.request<T>('POST', path, body);
  }

  static del<T>(path: string): Promise<ApiResult<T>> {
    return ApiClient.request<T>('DELETE', path);
  }
}
