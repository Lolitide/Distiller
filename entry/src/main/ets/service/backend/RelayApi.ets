/**
 * 中继接口（`/api/relay/*`）的薄封装：一个方法对应一个端点。
 *
 * 只有这里知道 URL；页面与 ViewModel 不许拼路径。
 */
import { ApiClient } from './ApiClient';
import {
  ApiResult,
  BindCodeData,
  BindStatusData,
  CandidatesData,
  DeletedData,
  FeedbackBody,
  ForwardAckData,
  ForwardPendingData,
  GroupsData,
  HealthData,
  MessagesData,
  MyData,
  ParseData,
  PushTokenData,
  RegisterData,
  SubscribeData
} from './BackendTypes';

const BASE: string = '/api/relay';

export class RelayApi {
  static async health(): Promise<ApiResult<HealthData>> {
    return await ApiClient.get<HealthData>(BASE + '/health');
  }

  static async register(name: string): Promise<ApiResult<RegisterData>> {
    return await ApiClient.post<RegisterData>(BASE + '/device/register', { 'name': name });
  }

  static async bindCode(): Promise<ApiResult<BindCodeData>> {
    return await ApiClient.post<BindCodeData>(BASE + '/bind/code', {});
  }

  static async bindStatus(): Promise<ApiResult<BindStatusData>> {
    return await ApiClient.get<BindStatusData>(BASE + '/bind/status');
  }

  /** 重新绑定前清掉旧绑定（否则刚生成新码就会被旧 bound=true 判成功） */
  static async resetBind(): Promise<ApiResult<Record<string, Object>>> {
    return await ApiClient.post<Record<string, Object>>(BASE + '/bind/reset', {});
  }

  static async groups(): Promise<ApiResult<GroupsData>> {
    return await ApiClient.get<GroupsData>(BASE + '/groups');
  }

  static async subscribe(groupOpenid: string): Promise<ApiResult<SubscribeData>> {
    return await ApiClient.post<SubscribeData>(BASE + '/subscribe',
      { 'group_openid': groupOpenid });
  }

  static async unsubscribe(groupOpenid: string): Promise<ApiResult<SubscribeData>> {
    return await ApiClient.post<SubscribeData>(BASE + '/unsubscribe',
      { 'group_openid': groupOpenid });
  }

  static async messages(after: number, limit: number): Promise<ApiResult<MessagesData>> {
    return await ApiClient.get<MessagesData>(
      BASE + '/messages?after=' + after + '&limit=' + limit);
  }

  static async candidates(after: number, limit: number): Promise<ApiResult<CandidatesData>> {
    return await ApiClient.get<CandidatesData>(
      BASE + '/candidates?after=' + after + '&limit=' + limit);
  }

  /**
   * 手动添加：文本 → 候选（无状态，不落盘）。
   * `source` 只用于后端标记通道（manual / screenshot…），不参与解析。
   */
  static async parseText(text: string, source: string): Promise<ApiResult<ParseData>> {
    return await ApiClient.post<ParseData>(BASE + '/parse', {
      'text': text,
      'source': source
    });
  }

  /** 手动添加：截图 → 后端多模态 OCR → 候选（`capabilities` 不含 `ocr` 时返回 501） */
  static async parseImage(imageB64: string, source: string): Promise<ApiResult<ParseData>> {
    return await ApiClient.post<ParseData>(BASE + '/parse', {
      'image_b64': imageB64,
      'source': source
    });
  }

  static async feedback(body: FeedbackBody): Promise<ApiResult<Record<string, Object>>> {
    return await ApiClient.post<Record<string, Object>>(BASE + '/feedback', {
      'candidate_id': body.candidate_id,
      'action': body.action,
      'group_openid': body.group_openid,
      'kind': body.kind
    });
  }

  static async myData(): Promise<ApiResult<MyData>> {
    return await ApiClient.get<MyData>(BASE + '/my/data');
  }

  static async deleteMyData(): Promise<ApiResult<DeletedData>> {
    return await ApiClient.del<DeletedData>(BASE + '/my/data');
  }

  static async pushToken(token: string): Promise<ApiResult<PushTokenData>> {
    return await ApiClient.post<PushTokenData>(BASE + '/push/token', { 'token': token });
  }

  /**
   * 设备偏好：不订阅自己发的消息（默认 true）。
   * 服务端在**入窗之前**就丢掉本人消息，所以候选/推送都不会包含它。
   */
  static async setPrefs(skipSelf: boolean): Promise<ApiResult<Record<string, Object>>> {
    return await ApiClient.post<Record<string, Object>>(BASE + '/my/prefs',
      { 'skip_self': skipSelf });
  }

  /** 查看「转发给机器人」的队列（不消费；本地入库成功后再 ack） */
  static async forwardPending(): Promise<ApiResult<ForwardPendingData>> {
    return await ApiClient.get<ForwardPendingData>(BASE + '/forward/pending');
  }

  /** 确认已入库，删除服务端队列项（纯内存 30 分钟 TTL） */
  static async ackForwards(ids: string[]): Promise<ApiResult<ForwardAckData>> {
    return await ApiClient.post<ForwardAckData>(BASE + '/forward/ack', { 'ids': ids });
  }
}
