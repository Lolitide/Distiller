import { preferences } from '@kit.ArkData';
import { Config } from './Config';
import { ApiClient } from './ApiClient';
import { RobotMessage, GroupItem, LocalSubscription, ProfileEntry } from './Types';

const STORE_NAME = 'zhiliao_store';
const K_DEVICE_ID = 'device_id';
const K_TOKEN = 'token';
const K_MAX_SEQ = 'max_seq';
const K_MESSAGES = 'messages_json';
const K_GROUPS = 'groups_json';
const K_SUBS = 'subs_json';
const K_BASE_URL = 'base_url';
const K_BOUND_TAIL = 'bound_openid_tail';
const K_PENDING = 'pending_parse_json';
const K_HIDE_SELF = 'hide_self';
const K_PROFILE = 'profile_json';
const K_PROFILE_AT = 'profile_at';

export class Store {
  private static pref: preferences.Preferences | null = null;
  private static appContext: Context | null = null;

  static init(context: Context): void {
    Store.appContext = context;
    if (Store.pref === null) {
      const options: preferences.Options = { name: STORE_NAME };
      try {
        Store.pref = preferences.getPreferencesSync(context, options);
      } catch (e) {
        Store.pref = null; // 初始化失败：后续读写全部退化为默认值
      }
    }
    const base: string = Store.getString(K_BASE_URL, '');
    if (base.length > 0) {
      Config.baseUrl = base;
    }
    ApiClient.deviceId = Store.getString(K_DEVICE_ID, '');
    ApiClient.token = Store.getString(K_TOKEN, '');
  }

  private static getString(key: string, def: string): string {
    if (Store.pref === null) {
      return def;
    }
    try {
      return Store.pref.getSync(key, def) as string;
    } catch (e) {
      return def;
    }
  }

  private static putString(key: string, value: string): void {
    if (Store.pref === null) {
      return;
    }
    try {
      Store.pref.putSync(key, value);
      Store.pref.flushSync();
    } catch (e) {
      // 写入/落盘失败：本次持久化丢失，不影响内存态
    }
  }

  /** 应用上下文：图片识码/OCR 需要它来读写沙箱临时文件。 */
  static getAppContext(): Context | null {
    return Store.appContext;
  }

  static hasIdentity(): boolean {
    return Store.getString(K_DEVICE_ID, '').length > 0 && Store.getString(K_TOKEN, '').length > 0;
  }

  static getDeviceId(): string {
    return Store.getString(K_DEVICE_ID, '');
  }

  static getToken(): string {
    return Store.getString(K_TOKEN, '');
  }

  static setIdentity(deviceId: string, token: string): void {
    Store.putString(K_DEVICE_ID, deviceId);
    Store.putString(K_TOKEN, token);
    ApiClient.deviceId = deviceId;
    ApiClient.token = token;
  }

  static clearIdentity(): void {
    Store.putString(K_DEVICE_ID, '');
    Store.putString(K_TOKEN, '');
    ApiClient.deviceId = '';
    ApiClient.token = '';
  }

  static getBaseUrl(): string {
    return Store.getString(K_BASE_URL, Config.baseUrl);
  }

  static setBaseUrl(value: string): void {
    Store.putString(K_BASE_URL, value);
    Config.baseUrl = value;
  }

  static getMaxSeq(): number {
    const s: string = Store.getString(K_MAX_SEQ, '0');
    const n: number = Number(s);
    return Number.isNaN(n) ? 0 : n;
  }

  static setMaxSeq(v: number): void {
    Store.putString(K_MAX_SEQ, String(v));
  }

  static getMessages(): RobotMessage[] {
    const raw: string = Store.getString(K_MESSAGES, '[]');
    try {
      return JSON.parse(raw) as RobotMessage[];
    } catch (e) {
      return [];
    }
  }

  static saveMessages(list: RobotMessage[]): void {
    Store.putString(K_MESSAGES, JSON.stringify(list));
  }

  static getGroups(): GroupItem[] {
    const raw: string = Store.getString(K_GROUPS, '[]');
    try {
      return JSON.parse(raw) as GroupItem[];
    } catch (e) {
      return [];
    }
  }

  static saveGroups(list: GroupItem[]): void {
    Store.putString(K_GROUPS, JSON.stringify(list));
  }

  static getSubs(): LocalSubscription[] {
    const raw: string = Store.getString(K_SUBS, '[]');
    try {
      return JSON.parse(raw) as LocalSubscription[];
    } catch (e) {
      return [];
    }
  }

  static saveSubs(list: LocalSubscription[]): void {
    Store.putString(K_SUBS, JSON.stringify(list));
  }

  static getBoundTail(): string {
    return Store.getString(K_BOUND_TAIL, '');
  }

  static setBoundTail(tail: string): void {
    Store.putString(K_BOUND_TAIL, tail);
  }

  static getHideSelf(): boolean {
    if (Store.pref === null) {
      return false;
    }
    try {
      return Store.pref.getSync(K_HIDE_SELF, false) as boolean;
    } catch (e) {
      return false;
    }
  }

  static setHideSelf(value: boolean): void {
    if (Store.pref === null) {
      return;
    }
    try {
      Store.pref.putSync(K_HIDE_SELF, value);
      Store.pref.flushSync();
    } catch (e) {
      // 同 putString：失败即丢本次写入
    }
  }

  // ---------------------------------------------------------------- 用户画像
  //
  // 画像词条**只存在这台手机上**（preferences 单键 JSON），随「清空本机数据」一起删。
  // 落盘内容只有「词 + 计数 + 类别 + 权重」，不含任何聊天原话。
  // 后端只在分析那一次看到「词频表」，不留存（见 profile_summarize.py）。

  static getProfile(): ProfileEntry[] {
    const raw: string = Store.getString(K_PROFILE, '[]');
    try {
      return JSON.parse(raw) as ProfileEntry[];
    } catch (e) {
      return [];
    }
  }

  static saveProfile(list: ProfileEntry[]): void {
    Store.putString(K_PROFILE, JSON.stringify(list));
  }

  static clearProfile(): void {
    Store.putString(K_PROFILE, '[]');
    Store.putString(K_PROFILE_AT, '0');
  }

  /** 上次分析画像的时刻（毫秒）；0 表示还没分析过。 */
  static getProfileAt(): number {
    const n: number = Number(Store.getString(K_PROFILE_AT, '0'));
    return Number.isNaN(n) ? 0 : n;
  }

  static setProfileAt(v: number): void {
    Store.putString(K_PROFILE_AT, String(v));
  }

  static getPending(): RobotMessage[] {    const raw: string = Store.getString(K_PENDING, '[]');
    try {
      return JSON.parse(raw) as RobotMessage[];
    } catch (e) {
      return [];
    }
  }

  static markAsTaskSource(msg: RobotMessage): void {
    const pending: RobotMessage[] = Store.getPending();
    pending.push(msg);
    Store.putString(K_PENDING, JSON.stringify(pending));
  }

  /** 头部插入一条本地消息（手动添加任务）。msg_id 用 local_ 前缀，不会与服务端消息撞车。 */
  static addMessage(msg: RobotMessage): void {
    const list: RobotMessage[] = Store.getMessages();
    Store.saveMessages([msg].concat(list));
  }

  /** 标记用户「忽略」的消息：列表不再展示，数据保留。 */
  static setDismissed(msgId: string): void {
    const list: RobotMessage[] = Store.getMessages();
    for (let i = 0; i < list.length; i++) {
      if (list[i].msg_id === msgId) {
        list[i].dismissed = true;
      }
    }
    Store.saveMessages(list);
  }

  static clearMessages(): void {
    Store.putString(K_MESSAGES, '[]');
    Store.putString(K_MAX_SEQ, '0');
  }

  static clearAll(): void {
    Store.clearIdentity();
    Store.putString(K_MESSAGES, '[]');
    Store.putString(K_GROUPS, '[]');
    Store.putString(K_SUBS, '[]');
    Store.putString(K_MAX_SEQ, '0');
    Store.putString(K_BOUND_TAIL, '');
    Store.putString(K_PENDING, '[]');
    Store.putString(K_PROFILE, '[]');
    Store.putString(K_PROFILE_AT, '0');
  }
}
