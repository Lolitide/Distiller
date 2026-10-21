/*
 * M3 亮色配色引擎 —— 从**一个种子色**推出 Material Design 3 的整套语义色角色。
 *
 * ## 为什么需要它
 *
 * 作者 2026-10-19 要求主题色不只改"强调色"，还要带出**一整套色系**：
 * 背景色很淡、卡片色略深于背景色、高亮按钮/标签/导航/图标都用同一套色。
 * 这正是 M3 的 tonal palette 思路：所有颜色都由**同一个种子色**按不同的 tone（亮度）
 * 派生，所以它们天生协调。
 *
 * ## 算法说明（近似，不是完整 HCT）
 *
 * 官方 M3 用 HCT（CAM16 色相/彩度 + L* 亮度）。完整实现要几千行矩阵运算，不适合放进 UI 层。
 * 这里用**足够接近的近似**：
 *   1. 把种子色转到线性光空间，算出它的相对亮度 Y；
 *   2. 按目标 tone（L*）反算目标 Y，把 RGB 按比例缩放到该亮度 —— 色相基本保持不变；
 *   3. 用「向同亮度的灰混合」来调 chroma：0 = 纯灰，1 = 保持种子饱和度。
 *
 * 对**表面色（surface / surface-container-*）**用极低 chroma（0.05~0.10），
 * 于是它们是"几乎中性、但带一丝主题色味道"的浅色 —— 与 M3 的实际观感一致。
 *
 * ## 已确认的范围（作者 2026-10-19）
 *
 *   · 颜色体系：**混合** —— 主题色系自建，中性文字/图标/分隔线继续用 `sys.color.*`；
 *   · **只做亮色**，暗色留待后续；
 *   · 触摸热区 40vp、行高 22/18 等**保留现状**，与 M3 的偏离在 `Theme.ets` 里标注。
 */

/** 十六进制颜色 → 0~1 的 RGB 三元组 */
function hexToRgb01(hex: string): number[] {
  const clean: string = hex.startsWith('#') ? hex.substring(1) : hex;
  const value: number = parseInt(clean, 16);
  return [
    ((value >> 16) & 0xFF) / 255,
    ((value >> 8) & 0xFF) / 255,
    (value & 0xFF) / 255
  ];
}

/** 0~1 的 RGB → 十六进制（带 #） */
function rgb01ToHex(rgb: number[]): string {
  let out: string = '#';
  for (let i = 0; i < 3; i++) {
    const v: number = Math.round(Math.min(1, Math.max(0, rgb[i])) * 255);
    const part: string = v.toString(16).toUpperCase();
    out += part.length === 1 ? `0${part}` : part;
  }
  return out;
}

/** sRGB 分量 → 线性光分量 */
function srgbToLinear(c: number): number {
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

/** 线性光分量 → sRGB 分量 */
function linearToSrgb(c: number): number {
  return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

/** 线性 RGB 的相对亮度 Y */
function luminance(linearRgb: number[]): number {
  return 0.2126 * linearRgb[0] + 0.7152 * linearRgb[1] + 0.0722 * linearRgb[2];
}

/** L*（tone，0~100）→ 相对亮度 Y */
function lstarToY(tone: number): number {
  const t: number = Math.min(100, Math.max(0, tone));
  if (t <= 8) {
    return t / 903.3;
  }
  const fy: number = (t + 16) / 116;
  return fy * fy * fy;
}

/**
 * 由种子色派生指定 tone / chroma 的颜色。
 *
 * @param seed 种子色（`#RRGGBB`）
 * @param tone 目标亮度 L*（0 黑 ~ 100 白）
 * @param chroma 彩度保留比例：0 = 同亮度纯灰，1 = 保持种子色的饱和度
 */
export function toneColor(seed: string, tone: number, chroma: number): string {
  const linear: number[] = hexToRgb01(seed).map(srgbToLinear);
  const currentY: number = luminance(linear);
  const targetY: number = lstarToY(tone);
  // 按亮度比例缩放：色相不变，只改明暗
  const scale: number = currentY > 0.00001 ? targetY / currentY : 0;
  const scaled: number[] = linear.map((c: number) => c * scale);
  // 向同亮度灰靠近，控制彩度
  const out: number[] = scaled.map((c: number) => targetY + (c - targetY) * chroma);
  return rgb01ToHex(out.map(linearToSrgb));
}

/** 色相旋转（度）：tertiary 与 primary 拉开色相用 */
function rotateHue(seed: string, degrees: number): string {
  const rgb: number[] = hexToRgb01(seed);
  const r: number = rgb[0];
  const g: number = rgb[1];
  const b: number = rgb[2];
  const max: number = Math.max(r, g, b);
  const min: number = Math.min(r, g, b);
  const l: number = (max + min) / 2;
  const d: number = max - min;

  let h: number = 0;
  let s: number = 0;
  if (d > 0.00001) {
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max === r) {
      h = ((g - b) / d) % 6;
    } else if (max === g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h *= 60;
  }

  const nh: number = ((h + degrees) % 360 + 360) % 360;
  const c: number = (1 - Math.abs(2 * l - 1)) * s;
  const x: number = c * (1 - Math.abs((nh / 60) % 2 - 1));
  const m: number = l - c / 2;
  let rr: number = 0;
  let gg: number = 0;
  let bb: number = 0;
  if (nh < 60) {
    rr = c; gg = x; bb = 0;
  } else if (nh < 120) {
    rr = x; gg = c; bb = 0;
  } else if (nh < 180) {
    rr = 0; gg = c; bb = x;
  } else if (nh < 240) {
    rr = 0; gg = x; bb = c;
  } else if (nh < 300) {
    rr = x; gg = 0; bb = c;
  } else {
    rr = c; gg = 0; bb = x;
  }
  return rgb01ToHex([rr + m, gg + m, bb + m]);
}

/**
 * M3 语义色角色（亮色）。
 *
 * 命名与官方 M3 一致（`--md-sys-color-*` 去掉前缀），
 * **任何 `on-*` 只能配它对应的底色**，不允许跨角色混搭。
 */
export class M3Scheme {
  /** 主色系 */
  readonly primary: string;
  readonly onPrimary: string;
  readonly primaryContainer: string;
  readonly onPrimaryContainer: string;
  /** 次色系 */
  readonly secondary: string;
  readonly onSecondary: string;
  readonly secondaryContainer: string;
  readonly onSecondaryContainer: string;
  /** 强调色系 */
  readonly tertiary: string;
  readonly onTertiary: string;
  readonly tertiaryContainer: string;
  readonly onTertiaryContainer: string;
  /** 错误色系（固定红，不随主题） */
  readonly error: string;
  readonly onError: string;
  readonly errorContainer: string;
  readonly onErrorContainer: string;
  /** 表面 */
  readonly surface: string;
  readonly surfaceDim: string;
  readonly surfaceBright: string;
  readonly onSurface: string;
  /** 表面容器（高度越高 tone 越低） */
  readonly surfaceContainerLowest: string;
  readonly surfaceContainerLow: string;
  readonly surfaceContainer: string;
  readonly surfaceContainerHigh: string;
  readonly surfaceContainerHighest: string;
  /** 变体与描边 */
  readonly surfaceVariant: string;
  readonly onSurfaceVariant: string;
  readonly outline: string;
  readonly outlineVariant: string;
  /** 反向 */
  readonly inverseSurface: string;
  readonly inverseOnSurface: string;
  readonly inversePrimary: string;
  /** 种子色本身（用于设置页色板显示） */
  readonly seed: string;

  constructor(seed: string) {
    this.seed = seed;

    // ── 主色系：直接用种子色的色相与饱和度，只在 tone 上分档 ──
    this.primary = toneColor(seed, 40, 1.0);
    this.onPrimary = toneColor(seed, 100, 0.08);
    this.primaryContainer = toneColor(seed, 90, 0.85);
    this.onPrimaryContainer = toneColor(seed, 10, 0.85);

    // ── 次色系：同色相、低饱和（M3 里 secondary 是 primary 的"安静"版本）──
    this.secondary = toneColor(seed, 40, 0.32);
    this.onSecondary = toneColor(seed, 100, 0.08);
    this.secondaryContainer = toneColor(seed, 90, 0.42);
    this.onSecondaryContainer = toneColor(seed, 10, 0.42);

    // ── 强调色系：色相偏移（M3 的 tertiary 与 primary 拉出区分）──
    const tertiarySeed: string = rotateHue(seed, 60);
    this.tertiary = toneColor(tertiarySeed, 40, 1.0);
    this.onTertiary = toneColor(tertiarySeed, 100, 0.08);
    this.tertiaryContainer = toneColor(tertiarySeed, 90, 0.85);
    this.onTertiaryContainer = toneColor(tertiarySeed, 10, 0.85);

    // ── 错误色：M3 baseline 固定值 ──
    this.error = '#BA1A1A';
    this.onError = '#FFFFFF';
    this.errorContainer = '#FFDAD6';
    this.onErrorContainer = '#410002';

    // ── 表面：**极低 chroma**，得到"很淡但带一丝主题色"的浅色 ──
    //    作者要求「背景色很淡，卡片色略深于背景色」→ 正是这几个 tone 的关系。
    this.surface = toneColor(seed, 98, 0.06);
    this.surfaceDim = toneColor(seed, 87, 0.08);
    this.surfaceBright = toneColor(seed, 98, 0.06);
    this.onSurface = toneColor(seed, 10, 0.30);

    this.surfaceContainerLowest = toneColor(seed, 100, 0.04);
    this.surfaceContainerLow = toneColor(seed, 96, 0.07);
    this.surfaceContainer = toneColor(seed, 94, 0.08);
    this.surfaceContainerHigh = toneColor(seed, 92, 0.09);
    this.surfaceContainerHighest = toneColor(seed, 90, 0.10);

    this.surfaceVariant = toneColor(seed, 90, 0.12);
    this.onSurfaceVariant = toneColor(seed, 30, 0.30);
    this.outline = toneColor(seed, 50, 0.22);
    this.outlineVariant = toneColor(seed, 80, 0.16);

    this.inverseSurface = toneColor(seed, 20, 0.22);
    this.inverseOnSurface = toneColor(seed, 95, 0.10);
    this.inversePrimary = toneColor(seed, 80, 0.85);
  }
}
