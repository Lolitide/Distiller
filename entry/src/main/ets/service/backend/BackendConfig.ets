/**
 * 后端连接配置：服务器地址 + 设备身份 + 候选游标（全部只存本机 preferences）。
 *
 * 隐私边界：这里只存「你用哪台服务器」「这台设备的令牌」「拉到哪个游标」，
 * **不存任何聊天正文**（正文由 TaskRepository 存，删除任务时一起清）。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'BackendConfig';
const STORE_NAME: string = 'distiller_backend';

const K_BASE_URL: string = 'base_url';
const K_DEVICE_ID: string = 'device_id';
const K_TOKEN: string = 'token';
const K_CURSOR: string = 'cursor';
const K_BOUND: string = 'bound';

/**
 * 固定服务器地址：设置在代码里，设置页不再暴露输入框/服务器行。
 * 换环境时只改这一处。
 */
export const DEFAULT_BASE_URL: string = 'https://pipiwoof.tail27705d.ts.net';

export class BackendConfig {
  /** 当前生效的服务器地址（`ApiClient` 直接读它） */
  static baseUrl: string = DEFAULT_BASE_URL;
  /** 设备身份；为空表示还没注册 */
  static deviceId: string = '';
  static token: string = '';
  /** 候选游标（`rev_seq`）：下次 `/candidates?after=` 用它 */
  static cursor: number = 0;
  /**
   * 上次确认过的绑定状态（缓存）。
   * 为什么要缓存：`/bind/status` 需要设备身份且要联网；切页/断网时如果只看接口，
   * 会把"其实还绑着"显示成"未绑定"。所以以接口为准，失败时回退到这份缓存。
   */
  static bound: boolean = false;

  private static store: preferences.Preferences | undefined = undefined;

  private static ensure(context: common.Context): preferences.Preferences | undefined {
    if (BackendConfig.store !== undefined) {
      return BackendConfig.store;
    }
    try {
      BackendConfig.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      return BackendConfig.store;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getPreferencesSync failed: %{public}s', err.message);
      return undefined;
    }
  }

  /** 冷启动读一次（`EntryAbility.onCreate` 或 `A_Main.aboutToAppear`） */
  static init(context: common.Context): void {
    const store: preferences.Preferences | undefined = BackendConfig.ensure(context);
    if (store === undefined) {
      return;
    }
    try {
      const rawBase: preferences.ValueType = store.getSync(K_BASE_URL, '');
      const storedBase: string = typeof rawBase === 'string' ? rawBase : '';
      BackendConfig.baseUrl = DEFAULT_BASE_URL;
      // 服务器已改为代码内固定值：旧地址（含空地址）的设备身份属于旧服务器，清掉重注册。
      if (storedBase !== DEFAULT_BASE_URL) {
        BackendConfig.clearIdentity(context, true);
        BackendConfig.put(context, K_BASE_URL, DEFAULT_BASE_URL);
      }

      const id: preferences.ValueType = store.getSync(K_DEVICE_ID, '');
      BackendConfig.deviceId = typeof id === 'string' ? id : '';

      const tk: preferences.ValueType = store.getSync(K_TOKEN, '');
      BackendConfig.token = typeof tk === 'string' ? tk : '';

      const cur: preferences.ValueType = store.getSync(K_CURSOR, 0);
      BackendConfig.cursor = typeof cur === 'number' ? cur : 0;

      const bound: preferences.ValueType = store.getSync(K_BOUND, false);
      BackendConfig.bound = typeof bound === 'boolean' ? bound : false;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'read config failed: %{public}s', err.message);
    }
  }

  static hasIdentity(): boolean {
    return BackendConfig.deviceId.length > 0 && BackendConfig.token.length > 0;
  }

  static setBaseUrl(context: common.Context, url: string): void {
    const cleaned: string = url.trim().replace(/\/+$/, '');
    // 允许为空：用户清空地址 = 断开连接，不再回填示例地址
    BackendConfig.baseUrl = cleaned;
    BackendConfig.put(context, K_BASE_URL, BackendConfig.baseUrl);
  }

  static setIdentity(context: common.Context, deviceId: string, token: string): void {
    BackendConfig.deviceId = deviceId;
    BackendConfig.token = token;
    BackendConfig.put(context, K_DEVICE_ID, deviceId);
    BackendConfig.put(context, K_TOKEN, token);
  }

  static setCursor(context: common.Context, cursor: number): void {
    BackendConfig.cursor = cursor;
    BackendConfig.put(context, K_CURSOR, cursor);
  }

  /** 换服务器 / 清空本机数据时用：身份与游标一起清，避免拿旧 token 打新服务器 */
  static setBound(context: common.Context, bound: boolean): void {
    BackendConfig.bound = bound;
    BackendConfig.put(context, K_BOUND, bound);
  }

  /**
   * 清身份。
   * @param clearBinding 换服务器时传 true（旧服务器上的绑定对新服务器没有意义）；
   *   只是重连同一台服务器时传 false，否则会把"已绑定"误清成"未绑定"。
   */
  static clearIdentity(context: common.Context, clearBinding: boolean = false): void {
    BackendConfig.deviceId = '';
    BackendConfig.token = '';
    BackendConfig.cursor = 0;
    BackendConfig.put(context, K_DEVICE_ID, '');
    BackendConfig.put(context, K_TOKEN, '');
    BackendConfig.put(context, K_CURSOR, 0);
    if (clearBinding) {
      BackendConfig.setBound(context, false);
    }
  }

  private static put(context: common.Context, key: string, value: preferences.ValueType): void {
    const store: preferences.Preferences | undefined = BackendConfig.ensure(context);
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(key, value);
      store.flushSync();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'write %{public}s failed: %{public}s', key, err.message);
    }
  }
}
