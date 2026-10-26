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
import { M3Scheme } from './M3Palette';

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

  /**
   * 弹窗标题字号（vp）：比正文大一档、加粗 —— 与系统半模态的抬头（详情页「设置重复」那个
   * 底部面板）观感对齐。之前用的是 16vp Medium，和面板里的正文（14vp）几乎一样大，
   * 弹窗看起来"没有标题"（需求方 2026-10-27：「字号、排版未统一」）。
   */
  static readonly FONT_DIALOG_TITLE: number = 20;

  /* 行高（vp） */
  static readonly LINE_BODY: number = 22;
  static readonly LINE_CAPTION: number = 18;

  /* 可点热区（vp）：官方最小可点 40 */
  static readonly HIT_MIN: number = 40;

  /*
   * 卡片尺寸（vp）：密度档位不同取值不同，见 `cardHeight()`。
   * 2026-10-19 第五次调整：整体压矮（标准 76→68、紧凑 64→58），
   * 让上下留白变少、一屏能多看一条。
   * 2026-10-19 第八次：「紧凑再紧凑些」→ 紧凑 58 → 52（标准保持 68 不动）。
   */
  static readonly CARD_HEIGHT_STANDARD: number = 68;
  static readonly CARD_HEIGHT_COMPACT: number = 52;

  /* 卡片内两行文字的行高（vp）：紧凑档跟着卡一起收 */
  static readonly LINE_TITLE_STANDARD: number = 20;
  static readonly LINE_TITLE_COMPACT: number = 18;
  static readonly LINE_SECOND_STANDARD: number = 18;
  static readonly LINE_SECOND_COMPACT: number = 15;

  /* 副卡片（子任务条）高度（vp） */
  static readonly SUB_CARD_HEIGHT_STANDARD: number = 36;
  static readonly SUB_CARD_HEIGHT_COMPACT: number = 28;

  /* 列表项间距（vp）：2026-10-19 第五次调整 8→12，卡片之间适当留白 */
  static readonly LIST_ITEM_SPACE: number = 12;
  /* 紧凑档的卡片间距（vp）：矮卡配小间距才连贯 */
  static readonly LIST_ITEM_SPACE_COMPACT: number = 8;

  /* 分组标题相对卡片的左内缩（vp） */
  static readonly SECTION_TITLE_INSET: number = 4;

  /**
   * 卡片阴影色（rgba 字面量）。
   *
   * 这是本文件**允许出现字面量**的又一处：`shadow()` 的 `color` 参数需要具体的
   * `ResourceColor`，官方语义 token 里没有"卡片投影"这一档。
   * 用在「压在主卡片底下、只露一条边的副卡片」上，让它和主卡片有层次区分。
   */
  static readonly SHADOW_COLOR: string = 'rgba(0, 0, 0, 0.16)';
  /** 副卡片阴影参数（vp） */
  static readonly SHADOW_RADIUS: number = 8;
  static readonly SHADOW_OFFSET_Y: number = 2;

  /**
   * **悬浮件**投影（底部页签胶囊 / 右下「＋」用）。2026-10-21 需求方：「为底部页签增加阴影」。
   *
   * 比卡片阴影（`SHADOW_RADIUS` 8 / 0.16）更散更浅：悬浮件体积大、离页面远，
   * 用「大半径 + 低透明度」才有浮起来的感觉，小半径会像描边。
   */
  static readonly FLOATING_SHADOW_COLOR: string = 'rgba(0, 0, 0, 0.14)';
  static readonly FLOATING_SHADOW_RADIUS: number = 24;
  static readonly FLOATING_SHADOW_OFFSET_Y: number = 8;

  /**
   * 副卡片**折叠态**的底色：比卡片白暗一层（半透明黑叠在页面底色上）。
   *
   * 与 `OPACITY_CARD_DIM` 一起用 —— 作者 2026-10-19：「同时更改 bg 颜色和 opacity」。
   * 只降 opacity 的话白色还是会偏亮；只换底色的话文字会太抢眼。
   * 仍然放在本文件，因为这是 `backgroundColor` 需要的具体色值。
   */
  static readonly CARD_BG_DIM: string = 'rgba(0, 0, 0, 0.06)';
  /** 副卡片折叠态的整体不透明度（与上面的底色叠加） */
  static readonly OPACITY_CARD_DIM: number = 0.62;

  /** 副卡片展开/收起动画时长（毫秒）：与页面里的高度动画保持一致 */
  static readonly ANIM_EXPAND_MS: number = 220;

  /** 状态栏/导航条内容色（深色，亮色主题下才看得清） */
  static readonly STATUS_BAR_CONTENT: string = '#1A1A1A';

  /**
   * 给一个 `#RRGGBB` 主题色拼上 alpha，得到 `#AARRGGBB`。
   *
   * 用途：**渐隐遮罩**（`linearGradient`）要把主题色做成「透明 → 实色」的两端，
   * 而 `linearGradient.colors` 只吃具体色值字符串，没法用 `opacity` 叠出来。
   * 这里拼的是**透明度前缀**、不是新颜色 —— 色相仍来自 `scheme.surface`，
   * 所以不违反「色值只有 Theme.ets 一个来源」的约定。
   *
   * 例：`Theme.withAlpha('#F3F7FF', '00')` → `'#00F3F7FF'`（全透明）。
   */
  static withAlpha(color: string, alpha: string): string {
    return `#${alpha}${color.substring(1)}`;
  }
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

  /**
   * 当前主题色对应的 **M3 整套语义色**（2026-10-19）。
   *
   * 颜色体系走的是已确认的**混合方案**：
   *   · 主题色系（primary / secondary / tertiary / surface / surface-container-* …）
   *     由 `M3Scheme` 从**种子色**按 tone 派生，所以整套颜色天生协调；
   *   · 中性文字、图标、分隔线仍用官方 `sys.color.*`（它们自带深色变体、也符合 HDS 规范）。
   *
   * `@Computed` → `accentIndex` 一变，所有读它的组件自动重算重绘。
   */
  @Computed
  get scheme(): M3Scheme {
    const index: number = this.accentIndex < 0 || this.accentIndex >= ACCENT_OPTIONS.length
      ? 0 : this.accentIndex;
    return new M3Scheme(ACCENT_OPTIONS[index].light);
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

  /**
   * 以下四个 getter 让「紧凑」不只是一个更矮的卡片框，而是**整套尺寸都收**。
   *
   * 2026-10-19 作者：「标准就现在这样，紧凑再紧凑些，某些控件可适当缩小调整」——
   * 只改 `cardHeight` 的话，卡变小了但里面的文字行高、副卡片、间距还是标准档的，
   * 会挤成一坨。所以把这些也按密度分档。
   */

  /** 标题行行高（vp） */
  get lineHeight(): number {
    return this.density === DENSITY_COMPACT ? Theme.LINE_TITLE_COMPACT : Theme.LINE_TITLE_STANDARD;
  }

  /** 卡片第二行行高（vp） */
  get secondLineHeight(): number {
    return this.density === DENSITY_COMPACT
      ? Theme.LINE_SECOND_COMPACT
      : Theme.LINE_SECOND_STANDARD;
  }

  /** 副卡片（子任务条）高度（vp） */
  get subCardHeight(): number {
    return this.density === DENSITY_COMPACT
      ? Theme.SUB_CARD_HEIGHT_COMPACT
      : Theme.SUB_CARD_HEIGHT_STANDARD;
  }

  /** 卡片之间的间距（vp）：紧凑档也收紧，否则矮卡+大间距会显得更松 */
  get listItemSpace(): number {
    return this.density === DENSITY_COMPACT
      ? Theme.LIST_ITEM_SPACE_COMPACT
      : Theme.LIST_ITEM_SPACE;
  }
}
