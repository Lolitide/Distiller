/*
 * 主题真值源（`utils/Theme.ets`）。
 *
 * 技能硬约束第 5 条：**页面里不许出现裸色值 / 裸尺寸，一切取值来自本文件**。
 * 所以本文件是**唯一允许写字面量的地方**，其余组件要么用这里导出的常量，
 * 要么用官方语义 token（`$r('sys.color.*')`，它自带深色模式变体）。
 *
 * 两块内容：
 *  1. `Theme` —— 不随用户变化的**设计令牌**（间距 / 圆角 / 字号 / 卡片尺寸），纯常量。
 *  2. `ThemeStore` —— 随用户在设置页变化的**视觉个性化**（主题色 / 卡片密度）。
 *     用 `@ObservedV2` + `@Trace` 承载，靠 `AppStorageV2.connect` 跨页共享，
 *     这是官方《arkts-new-appstoragev2》给 V2 的跨页共享做法
 *     （`AppStorageV2.connect<Type>(Type, key, () => new Type())`）。
 *
 * ⚠️ 本文件只负责**视觉取值**，不碰数据、不碰业务。
 */
import { AppStorageV2 } from '@kit.ArkUI';

/* ─────────────────────────── 一、设计令牌 ─────────────────────────── */

export class Theme {
  /* 间距（vp）：4 的倍数，与官方 `padding_level*` 同一套节奏 */
  static readonly GAP_XS: number = 4;
  static readonly GAP_S: number = 8;
  static readonly GAP_M: number = 12;
  static readonly GAP_L: number = 16;
  static readonly GAP_XL: number = 24;

  /* 圆角（vp） */
  static readonly RADIUS_CARD: number = 16;
  static readonly RADIUS_CHIP: number = 8;

  /* 正文字号（vp） */
  static readonly FONT_TITLE: number = 16;
  static readonly FONT_BODY: number = 14;
  static readonly FONT_CAPTION: number = 12;

  /* 行高（vp） */
  static readonly LINE_BODY: number = 22;
  static readonly LINE_CAPTION: number = 18;

  /* 可点热区（vp）：官方最小可点 40 */
  static readonly HIT_MIN: number = 40;

  /* 卡片尺寸（vp）：密度档位不同取值不同，见 `cardHeight()` */
  static readonly CARD_HEIGHT_STANDARD: number = 76;
  static readonly CARD_HEIGHT_COMPACT: number = 64;

  /* 列表项间距（vp） */
  static readonly LIST_ITEM_SPACE: number = 8;

  /* 分组标题相对卡片的左内缩（vp） */
  static readonly SECTION_TITLE_INSET: number = 4;
}

/* ─────────────────────────── 二、主题色档位 ─────────────────────────── */

/**
 * 主题色档位。
 *
 * 只有**一处**需要真色值：铃铛开启态、选中态这类"强调"。其余仍走官方语义 token，
 * 这样深色模式自动跟随（官方 token 每档都有 dark 变体，我们自己写的字面量没有）。
 * 因此这里的色值只用于**强调用途**，不做大面积背景。
 */
export class AccentOption {
  /** 设置页显示的名字 */
  readonly label: string;
  /** 浅色模式下的强调色 */
  readonly light: string;
  /** 深色模式下的强调色（浅一些，保证对比度） */
  readonly dark: string;

  constructor(label: string, light: string, dark: string) {
    this.label = label;
    this.light = light;
    this.dark = dark;
  }
}

/** 三档主题色：官方蓝 / 青 / 橙。**字面量集中在这里**，别处不许再写 */
export const ACCENT_OPTIONS: AccentOption[] = [
  new AccentOption('默认蓝', '#0A59F7', '#5E8BFF'),
  new AccentOption('青', '#0F9D9D', '#3FC7C7'),
  new AccentOption('橙', '#E07B00', '#FFA53D')
];

/** 卡片密度：标准 / 紧凑 */
export const DENSITY_STANDARD: number = 0;
export const DENSITY_COMPACT: number = 1;

/* ─────────────────────────── 三、可变的主题状态 ─────────────────────────── */

/** AppStorageV2 的 key：同一个 key 全应用共享一份 */
const THEME_KEY: string = 'distiller-theme';

@ObservedV2
export class ThemeStore {
  /** 主题色档位（`ACCENT_OPTIONS` 的下标） */
  @Trace accentIndex: number = 0;
  /** 卡片密度（`DENSITY_STANDARD` / `DENSITY_COMPACT`） */
  @Trace density: number = DENSITY_STANDARD;

  /** 取全应用共享的实例（第一次调用时创建） */
  static instance(): ThemeStore {
    const store: ThemeStore | undefined =
      AppStorageV2.connect(ThemeStore, THEME_KEY, () => new ThemeStore());
    return store!;
  }

  /** 当前档位对应的强调色（浅色/深色两套字面量由官方主题解析，这里给出资源无关的取值） */
  get accent(): AccentOption {
    const index: number = this.accentIndex;
    return ACCENT_OPTIONS[index < 0 || index >= ACCENT_OPTIONS.length ? 0 : index];
  }

  /** 当前密度下的卡片高度（vp） */
  get cardHeight(): number {
    return this.density === DENSITY_COMPACT
      ? Theme.CARD_HEIGHT_COMPACT
      : Theme.CARD_HEIGHT_STANDARD;
  }
}
