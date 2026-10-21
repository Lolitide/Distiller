/**
 * 首选项仓储 —— 设置页那几项偏好的持久化出口。
 *
 * 为什么单开一个文件而不塞进 `repository/index.ets`：那个文件是**规划占位**（归袁正锟，将来合并成
 * `Repositories.ets`），直接在里面堆实现会和他的建表工作冲突。这里是新增文件、只做首选项，
 * 合并时整文件搬过去即可。
 *
 * 纪律（与本项目其它层一致）：
 *   · 页面不直接调 `preferences`，只经本层；
 *   · 读写都是异步（`getPreferences` / `put` / `flush` 官方签名都是 Promise），失败不抛到页面层，
 *     统一吞成"保持当前值"并打日志 —— 首选项读失败不该让设置页白屏。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'SettingsRepository';

/** 首选项文件名（应用私有 preferences 目录下） */
const STORE_NAME: string = 'distiller_settings';
/** 提醒提前量（分钟）：0 ＝ 不提前，即按截止时刻提醒 */
const KEY_REMIND_LEAD: string = 'remind_lead_minutes';
/** 解析方式：见 `ParseMode` */
const KEY_PARSE_MODE: string = 'parse_mode';
/** 主题色档位（`ACCENT_OPTIONS` 的下标）：2026-10-19 起持久化 */
const KEY_THEME_ACCENT: string = 'theme_accent_index';
/** 卡片密度（`DENSITY_STANDARD` / `DENSITY_COMPACT`）：2026-10-19 起持久化 */
const KEY_DENSITY: string = 'card_density';
/**
 * 任务列表各分组的展开状态：`Array<string>`，每项形如 `<组键>:1|0`（1＝展开）。
 * 组键见 `TaskDayGroup.persistKey`（有日期＝当天 0 点时间戳，无日期＝`undated`）。
 * 2026-10-20 起持久化（袁正锟：「记住上次的展开状态」）。
 */
const KEY_GROUP_EXPANDED: string = 'task_group_expanded';

/** 默认提醒提前量：0 分钟（到点提醒） */
export const DEFAULT_REMIND_LEAD: number = 0;

/**
 * 解析方式。
 *   · `AUTO`   —— 端侧优先，端侧抽不动再走服务端（默认）
 *   · `LOCAL`  —— 只用端侧（不外发任何文本）
 *   · `SERVER` —— 只用服务端（解析质量好，但文本会离开手机）
 * 三档对应开题报告「权限克制 + 用户可见的数据边界」；具体哪条链路由 `service/ai` 与 `service/cloud` 落实。
 */
export enum ParseMode {
  AUTO = 0,
  LOCAL = 1,
  SERVER = 2
}

/** 默认解析方式：自动 */
export const DEFAULT_PARSE_MODE: number = ParseMode.AUTO;

export class SettingsRepository {
  /** 缓存句柄：`getPreferences` 每次都会回到文件，缓存一次即可 */
  private static store: preferences.Preferences | undefined = undefined;

  private static async ensure(context: common.Context): Promise<preferences.Preferences | undefined> {
    if (SettingsRepository.store !== undefined) {
      return SettingsRepository.store;
    }
    try {
      SettingsRepository.store = await preferences.getPreferences(context, STORE_NAME);
      return SettingsRepository.store;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getPreferences failed: %{public}d, %{public}s', err.code, err.message);
      return undefined;
    }
  }

  /** 读提醒提前量（分钟）。读不到就返回默认值，不抛异常 */
  static async getRemindLead(context: common.Context): Promise<number> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return DEFAULT_REMIND_LEAD;
    }
    try {
      const value: preferences.ValueType = await store.get(KEY_REMIND_LEAD, DEFAULT_REMIND_LEAD);
      return typeof value === 'number' ? value : DEFAULT_REMIND_LEAD;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getRemindLead failed: %{public}s', err.message);
      return DEFAULT_REMIND_LEAD;
    }
  }

  /** 写提醒提前量。**写完必须 flush**，否则只在内存里、杀进程就丢 */
  static async setRemindLead(context: common.Context, minutes: number): Promise<boolean> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return false;
    }
    try {
      await store.put(KEY_REMIND_LEAD, minutes);
      await store.flush();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'setRemindLead failed: %{public}s', err.message);
      return false;
    }
  }

  /** 读解析方式 */
  static async getParseMode(context: common.Context): Promise<number> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return DEFAULT_PARSE_MODE;
    }
    try {
      const value: preferences.ValueType = await store.get(KEY_PARSE_MODE, DEFAULT_PARSE_MODE);
      return typeof value === 'number' ? value : DEFAULT_PARSE_MODE;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getParseMode failed: %{public}s', err.message);
      return DEFAULT_PARSE_MODE;
    }
  }

  /** 写解析方式 */
  static async setParseMode(context: common.Context, mode: number): Promise<boolean> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return false;
    }
    try {
      await store.put(KEY_PARSE_MODE, mode);
      await store.flush();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'setParseMode failed: %{public}s', err.message);
      return false;
    }
  }

  /* ── 视觉个性化：主题色与卡片密度（2026-10-19 起持久化）── */

  /**
   * 读主题色档位。读不到返回 `fallback`（调用方传当前值，避免一上来就被重置成 0）。
   */
  static async getThemeAccent(context: common.Context, fallback: number): Promise<number> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return fallback;
    }
    try {
      const value: preferences.ValueType = await store.get(KEY_THEME_ACCENT, fallback);
      return typeof value === 'number' ? value : fallback;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getThemeAccent failed: %{public}s', err.message);
      return fallback;
    }
  }

  /** 写主题色档位 */
  static async setThemeAccent(context: common.Context, index: number): Promise<boolean> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return false;
    }
    try {
      await store.put(KEY_THEME_ACCENT, index);
      await store.flush();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'setThemeAccent failed: %{public}s', err.message);
      return false;
    }
  }

  /** 读卡片密度 */
  static async getDensity(context: common.Context, fallback: number): Promise<number> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return fallback;
    }
    try {
      const value: preferences.ValueType = await store.get(KEY_DENSITY, fallback);
      return typeof value === 'number' ? value : fallback;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getDensity failed: %{public}s', err.message);
      return fallback;
    }
  }

  /** 写卡片密度 */
  static async setDensity(context: common.Context, density: number): Promise<boolean> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return false;
    }
    try {
      await store.put(KEY_DENSITY, density);
      await store.flush();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'setDensity failed: %{public}s', err.message);
      return false;
    }
  }

  /* ── 冷启动同预读（2026-10-21 修「冷启动主题色从默认闪到个性化」）── */

  /**
   * **同步**读主题色档位 —— 只在 `EntryAbility.onCreate`（UI 还没创建）里用。
   *
   * 为什么必须同步：异步版 `getThemeAccent` 走 `await`，等它回来时首帧已经按默认色画完了，
   * 于是冷启动会"先默认蓝、再跳橙"闪一下（袁正锟 2026-10-21 报的 bug）。
   * `preferences.getPreferencesSync` + `Preferences.getSync`（均 @since 10）能在**首帧之前**读到值。
   * 读失败/没存过 → 返回 `fallback`，调用方传当前值即可。
   */
  static getThemeAccentSync(context: common.Context, fallback: number): number {
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context, { name: STORE_NAME });
      const value: preferences.ValueType = store.getSync(KEY_THEME_ACCENT, fallback);
      return typeof value === 'number' ? value : fallback;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getThemeAccentSync failed: %{public}s', err.message);
      return fallback;
    }
  }

  /** **同步**读卡片密度（同上，只给冷启动用） */
  static getDensitySync(context: common.Context, fallback: number): number {
    try {
      const store: preferences.Preferences = preferences.getPreferencesSync(context, { name: STORE_NAME });
      const value: preferences.ValueType = store.getSync(KEY_DENSITY, fallback);
      return typeof value === 'number' ? value : fallback;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getDensitySync failed: %{public}s', err.message);
      return fallback;
    }
  }

  /* ── 任务列表分组展开状态（2026-10-20 起持久化）── */

  /**
   * 读各分组的展开状态。
   *
   * 返回**原始条目**数组（`<组键>:1|0`），解析与「套到哪些组上」归 `TaskListStore` ——
   * 本层只认「一个字符串数组」，不认识分组，避免仓储层反过来依赖 ViewModel 的组结构。
   * 读不到／格式不对一律返回空数组（＝全部按默认展开规则走），不抛异常。
   */
  static async getGroupExpanded(context: common.Context): Promise<string[]> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return [];
    }
    try {
      const empty: string[] = [];
      const value: preferences.ValueType = await store.get(KEY_GROUP_EXPANDED, empty);
      return Array.isArray(value) ? value as string[] : [];
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getGroupExpanded failed: %{public}s', err.message);
      return [];
    }
  }

  /** 写各分组的展开状态（整份覆盖）。**写完必须 flush**，否则只在内存里、杀进程就丢 */
  static async setGroupExpanded(context: common.Context, entries: string[]): Promise<boolean> {
    const store: preferences.Preferences | undefined = await SettingsRepository.ensure(context);
    if (store === undefined) {
      return false;
    }
    try {
      await store.put(KEY_GROUP_EXPANDED, entries);
      await store.flush();
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'setGroupExpanded failed: %{public}s', err.message);
      return false;
    }
  }
}
