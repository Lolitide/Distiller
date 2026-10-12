import { preferences } from '@kit.ArkData';
import { Config } from './Config';
import { ApiClient } from './ApiClient';
import { RobotMessage, GroupItem, LocalSubscription } from './Types';

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

export class Store {
  private static pref: preferences.Preferences | null = null;
  private static appContext: Context | null = null;

  static init(context: Context): void {
    Store.appContext = context;
    if (Store.pref === null) {
      const options: preferences.Options = { name: STORE_NAME };
      Store.pref = preferences.getPreferencesSync(context, options);
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
    return Store.pref.getSync(key, def) as string;
  }

  private static putString(key: string, value: string): void {
    if (Store.pref === null) {
      return;
    }
    Store.pref.putSync(key, value);
    Store.pref.flushSync();
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
    return Store.pref.getSync(K_HIDE_SELF, false) as boolean;
  }

  static setHideSelf(value: boolean): void {
    if (Store.pref === null) {
      return;
    }
    Store.pref.putSync(K_HIDE_SELF, value);
    Store.pref.flushSync();
  }

  static getPending(): RobotMessage[] {
    const raw: string = Store.getString(K_PENDING, '[]');
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
  }
}
