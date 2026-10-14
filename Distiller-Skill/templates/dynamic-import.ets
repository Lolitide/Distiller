// 依据：开发指南/ArkTS_方舟编程语言/ArkTS运行时/ArkTS模块化/动态加载/arkts-dynamic-import.md
// 依据：开发指南/ArkTS_方舟编程语言/ArkTS运行时/ArkTS模块化/延迟加载_lazy_import/arkts-lazy-import.md
// 环境：HarmonyOS 6.0.2(22)；其中标注 26.0.0 的能力在本机未验证
// 说明：可直接抄进 entry/src/main/ets/ 的对应分层目录
//
// 落位：entry/src/main/ets/service/KitGateway.ets
// 依赖：entry/src/main/ets/common/ServiceResult.ets（templates/service-result.ets）
//
// ============================================================================
// 取证块：动态 import 的官方写法（原文逐字照抄，附来源文件与行号）
// ============================================================================
//
// 来源 A = C:\Users\x2027\.local\share\deveco-cli\docs\开发指南\ArkTS_方舟编程语言\
//          ArkTS运行时\ArkTS模块化\动态加载\arkts-dynamic-import.md
//
//   A:114-116  常量动态 import 模块名 + then 回调，回调入参类型写作 ESObject
//     import('myhar').then((ns: ESObject) => {
//       console.info('DynamicImport ns.add(3, 5) = %d', ns.add(3, 5));
//     })
//
//   A:118-122  await 形式（必须在 async 函数内）
//     // 可使用 await 处理动态import (必须在 async 函数内使用)
//     async function asyncDynamicImport() {
//       let ns = await import('myhar');
//       console.info('DynamicImport ns.add(3, 5) = %d', ns.add(3, 5));
//     }
//
//   A:260-262  动态 import API 模块时，用 ns.default 取默认导出
//     import('@ohos.curves').then((ns: ESObject) => {
//       ns.default.springMotion(0.555, 0.75, 0.001).interpolate(1);
//     });
//
//   A:83-86    规格表「API」行（动态 import 支持哪些说明符，官方只列了这三类）
//     | API | 动态import @system.* | - |
//     | API | 动态import @ohos.*   | - |
//     | API | 动态import @arkui-x.*| - |
//
//   A:277      常量动态 import 参与编译期依赖解析；变量动态 import 需要额外 runtimeOnly 配置
//     「在编译期，静态import和常量动态import可以被打包工具rollup及其插件识别解析，加入依赖树中，
//       参与编译流程，最终生成方舟字节码。但是，如果是变量动态import，该变量值可能需要进行运算或
//       外部传入才能得到，在编译态无法解析其内容，也就无法加入编译。」
//
//   A:534      通过变量动态 import 加载 API 时无需配置 runtimeOnly。
//
// 来源 B = C:\Users\x2027\.local\share\deveco-cli\docs\开发指南\ArkTS_方舟编程语言\
//          ArkTS运行时\ArkTS模块化\延迟加载_lazy_import\arkts-lazy-import.md
//
//   B:97   lazy-import 与动态加载的区别表 · 「语法示例」行 · 动态加载列
//     let A = await import("./A");
//
//   B:110-112  区别表剩余行
//     | 使用位置             | 代码块/运行逻辑中使用 | 需要写在源码开头 |
//     | 是否可以运行时拼接   | 是                    | 否               |
//     | 加载时序             | 异步                  | 同步             |
//
//   B:129  语法规格表：证明 "@kit.SomeKit" 是合法的模块说明符（用于 import lazy 语法）
//     | import lazy { KitClass } from "@kit.SomeKit"; | "@kit.SomeKit" | "KitClass" | "KitClass" | API 12 |
//
// 来源 C（BusinessError 定义）= D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default\
//          openharmony\ets\api\@ohos.base.d.ts
//   C:116  export interface BusinessError<T = void> extends Error {
//   C:126      code: number;
//   C:137      data?: T;
//
// ============================================================================
// 未取证清单（本项目落地前必须补证，不要默认它们成立）
// ============================================================================
// [U1] import('@kit.CoreVisionKit') / import('@kit.NaturalLanguageKit') / import('@kit.CoreSpeechKit')
//      没有任何本地文档给出「动态 import 一个 @kit.*」的示例：
//        · 来源 A 的规格表（A:83-86）只列了 @system.* / @ohos.* / @arkui-x.*；
//        · 来源 B:129 只证明 "@kit.*" 可以作为模块说明符出现在 import 语句里。
//      → 本文件把 @kit.* 的字面量写在 import() 里（机制取自 A:114），
//        但「@kit.* 能否被动态 import」这一条本身未取证，三处 import 行均以 // 未取证 标注。
// [U2] 各 Kit 命名空间里的精确成员名（如 ns.textRecognition / ns.textProcessing /
//      ns.speechRecognizer）。本地文档里这些名字都出现在 **静态** import 的按名解构里，
//      没有文档演示「从动态 import 的命名空间对象上取成员」。
//      → 代码用 ESObject 承接命名空间、运行时取成员，并在取值处标注 未取证。
// [U3] 模拟器缺少 Kit 时 import() 的**具体**失败形态（reject 的 error.code 取值）。
//      → 代码只做「失败即降级」，不硬编码某个错误码去判定「Kit 不存在」。
// [U4] 26.0.0 相关能力在本机无运行时证据（本机只有 6.0.2(22) 真机与已停止的模拟器）。

import { BusinessError } from '@kit.BasicServicesKit';
import { ServiceError, ServiceResult, ServiceStatus, success, failure, fromBusinessError, ERROR_CODE_UNKNOWN }
  from '../common/ServiceResult';

/**
 * 本项目用到的 AI Kit 能力标识。
 * 用数字枚举：官方 API 文档中的枚举一律是数字枚举，未见字符串枚举样例。
 */
export enum KitId {
  NLU = 0, // 自然语言理解，@kit.NaturalLanguageKit
  OCR = 1, // 通用文字识别，@kit.CoreVisionKit
  ASR = 2  // 语音识别，@kit.CoreSpeechKit
}

/**
 * 「Kit 不可用」的降级专用错误码。属于本项目自定义码段，
 * 不占用系统 BusinessError.code 空间。
 */
export const ERROR_CODE_KIT_UNAVAILABLE: number = 20001;

/**
 * 加载失败时给调用方的降级建议。
 * 页面据此决定「隐藏入口 / 退化为手动输入 / 提示用户」。
 */
export enum DegradeStrategy {
  HIDE_ENTRY = 0,  // 入口直接隐藏，不给用户看到失败
  MANUAL_INPUT = 1,// 退化为手动输入
  TOAST_ONLY = 2   // 仅提示，保留入口
}

// ---------------------------------------------------------------------------
// 三个「常量表达式」动态 import 加载器
//
// 关键约束：说明符必须写成**字面量**，不能经由变量传入。
//   依据 A:277 —— 变量动态 import 编译期无法解析，必须在 build-profile.json5 里
//   额外配 runtimeOnly（A:299-310）才会被打进产物。
//   依据 A:534 —— 变量动态 import 加载 API 时无需 runtimeOnly；
//   但常量字面量最稳妥，本文件因此全部使用字面量，无需任何 runtimeOnly 配置。
//
// 为什么必须是动态 import 而不是顶层静态 import：
//   模拟器镜像里可能不含这些 Kit，顶层静态 import 会在模块加载阶段直接崩，页面都进不去。
//   动态 import 把失败收敛成一次 reject，可以被 try/catch 接住并降级。
// ---------------------------------------------------------------------------

/** 自然语言理解：分词 / 实体抽取 */
export function loadNluNamespace(): Promise<ESObject> {
  // 未取证 [U1]：@kit.* 的动态 import 写法未被任何本地文档演示，
  //             机制照搬 A:114 的常量动态 import，说明符是否为动态 import 所接受需在真机验证。
  return import('@kit.NaturalLanguageKit');
}

/** 基础视觉：通用文字识别（OCR） */
export function loadOcrNamespace(): Promise<ESObject> {
  // 未取证 [U1]：同 loadNluNamespace。
  return import('@kit.CoreVisionKit');
}

/** 基础语音：语音识别（ASR） */
export function loadAsrNamespace(): Promise<ESObject> {
  // 未取证 [U1]：同 loadNluNamespace。
  return import('@kit.CoreSpeechKit');
}

function loadByKitId(kit: KitId): Promise<ESObject> {
  switch (kit) {
    case KitId.NLU:
      return loadNluNamespace();
    case KitId.OCR:
      return loadOcrNamespace();
    case KitId.ASR:
      return loadAsrNamespace();
    default:
      return Promise.reject(new Error('KitId not supported'));
  }
}

/**
 * AI Kit 统一入口（service 层）。
 *
 * 分层约定：页面 → ViewModel → service（本文件）→ repository。
 * 页面永远不直接 import Kit，只消费 ServiceResult。
 *
 * 三条对外承诺：
 *   1. 永不抛异常——所有失败都变成 ServiceResult.status === FAILURE；
 *   2. 命名空间只加载一次并缓存，重复调用不重复走模块解析；
 *   3. 失败时附带 DegradeStrategy，调用方无需自己判断该藏入口还是该退化。
 */
export class KitGateway {
  /** key = KitId 的数字值，value = 已解析的 Kit 命名空间 */
  private static readonly namespaceCache: Map<number, ESObject> = new Map<number, ESObject>();
  /** 记录每个 Kit 的失败次数，供后续做熔断（当前只统计不熔断） */
  private static readonly failureCount: Map<number, number> = new Map<number, number>();

  /**
   * 取 Kit 命名空间。失败返回 FAILURE + ERROR_CODE_KIT_UNAVAILABLE。
   */
  static async namespace(kit: KitId): Promise<ServiceResult<ESObject>> {
    const cached: ESObject | undefined = KitGateway.namespaceCache.get(kit as number);
    if (cached !== undefined) {
      return success<ESObject>(cached);
    }

    try {
      const ns: ESObject = await loadByKitId(kit);
      // 未取证 [U3]：这里不校验 ns 的形态，只按「能 await 出来即视为可用」处理。
      // 真正的成员名校验由调用方在取成员时完成。
      KitGateway.namespaceCache.set(kit as number, ns);
      return success<ESObject>(ns);
    } catch (error) {
      const times: number = (KitGateway.failureCount.get(kit as number) ?? 0) + 1;
      KitGateway.failureCount.set(kit as number, times);

      // 官方 catch 写法：error as BusinessError（依据见 service-result.ets 取证块）
      const be: BusinessError = error as BusinessError;
      const mapped: ServiceError = fromBusinessError(be, ERROR_CODE_KIT_UNAVAILABLE, 'AI Kit 不可用');
      // 把「import 阶段失败」和「Kit 内部调用失败」区分开，方便日志排查
      const degraded: ServiceError = {
        code: ERROR_CODE_KIT_UNAVAILABLE,
        message: `${mapped.message} (kit=${kit}, attempts=${times})`,
        cause: mapped.cause
      };
      return failure<ESObject>(degraded);
    }
  }

  /** 指定 Kit 是否可用。用于页面决定是否渲染某个入口。 */
  static async isAvailable(kit: KitId): Promise<boolean> {
    const r: ServiceResult<ESObject> = await KitGateway.namespace(kit);
    return r.status === ServiceStatus.SUCCESS;
  }

  /** 取某个 Kit 的降级策略。 */
  static degradeStrategyFor(kit: KitId): DegradeStrategy {
    switch (kit) {
      case KitId.NLU:
        // 分词/实体抽取失败 → 让用户自己输入关键词
        return DegradeStrategy.MANUAL_INPUT;
      case KitId.OCR:
        // 拍书识别失败 → 不给用户看到 OCR 入口
        return DegradeStrategy.HIDE_ENTRY;
      case KitId.ASR:
        // 语音输入失败 → 保留麦克风入口并提示，用户可重试
        return DegradeStrategy.TOAST_ONLY;
      default:
        return DegradeStrategy.HIDE_ENTRY;
    }
  }

  /** 清空缓存。仅在明确需要重新探测 Kit（例如用户手动重试）时调用。 */
  static reset(): void {
    KitGateway.namespaceCache.clear();
    KitGateway.failureCount.clear();
  }
}

// ---------------------------------------------------------------------------
// 一个具体的业务 wrapper：抽取关键词。
// 演示 service 层如何把「动态 import + 降级」包成一个对 ViewModel 友好的函数。
// ---------------------------------------------------------------------------

export interface KeywordExtraction {
  readonly keywords: string[];
  /** true 表示走了降级路径（未真正调用 NLU），keywords 来自本地兜底规则 */
  readonly degraded: boolean;
}

/** 本地兜底：无 NLU 时按空白/标点切分，保证功能不整体失效。 */
function localFallbackKeywords(text: string): string[] {
  const parts: string[] = text.split(/[\s,，。;；:：!！?？\n]+/);
  const out: string[] = [];
  for (let i = 0; i < parts.length; i++) {
    const w: string = parts[i].trim();
    if (w.length > 0 && out.indexOf(w) < 0) {
      out.push(w);
    }
  }
  return out;
}

/**
 * 抽取关键词。
 * 成功 → ServiceResult.success({ keywords, degraded: false })
 * Kit 不可用 → ServiceResult.success({ keywords: 兜底结果, degraded: true })
 *              注意：降级成功仍然算 SUCCESS，业务能继续；只有既无 Kit 又无文本时才 FAILURE。
 */
export async function extractKeywords(text: string): Promise<ServiceResult<KeywordExtraction>> {
  if (text.length === 0) {
    return failure<KeywordExtraction>({
      code: ERROR_CODE_UNKNOWN,
      message: '文本为空，无法抽取关键词'
    });
  }

  const nsResult: ServiceResult<ESObject> = await KitGateway.namespace(KitId.NLU);
  if (nsResult.status === ServiceStatus.FAILURE) {
    // 降级路径：不把失败抛给页面，而是给出「降级成功」的结果
    return success<KeywordExtraction>({
      keywords: localFallbackKeywords(text),
      degraded: true
    });
  }

  const ns: ESObject = nsResult.value!;
  try {
    // 未取证 [U2]：从动态 import 得到的命名空间上取成员的具体写法。
    // 本地文档只演示了静态 `import { textProcessing } from '@kit.NaturalLanguageKit'`，
    // 没有演示从 ns 上取 textProcessing，故此处成员名待真机确认。
    const textProcessing: ESObject = ns.textProcessing;
    if (textProcessing === undefined || textProcessing === null) {
      return success<KeywordExtraction>({
        keywords: localFallbackKeywords(text),
        degraded: true
      });
    }
    // 未取证 [U2]：分词接口的调用形态（静态写法为 textProcessing.getWordSegmentation(...)），
    //             动态命名空间下的调用与返回值形状需补证。
    const seg: ESObject = textProcessing.getWordSegmentation(text);
    const keywords: string[] = [];
    // 保守处理：拿不到结构化结果就走兜底，不猜返回结构
    if (Array.isArray(seg)) {
      for (let i = 0; i < seg.length; i++) {
        const item: ESObject = seg[i];
        if (typeof item === 'string') {
          keywords.push(item as string);
        }
      }
    }
    if (keywords.length === 0) {
      return success<KeywordExtraction>({
        keywords: localFallbackKeywords(text),
        degraded: true
      });
    }
    return success<KeywordExtraction>({ keywords: keywords, degraded: false });
  } catch (error) {
    const be: BusinessError = error as BusinessError;
    const mapped: ServiceError = fromBusinessError(be, ERROR_CODE_KIT_UNAVAILABLE, 'NLU 调用失败');
    // Kit 加载成功但调用失败 → 依然降级，不打断用户
    console.error(`[KitGateway] extractKeywords degraded: ${mapped.code} ${mapped.message}`);
    return success<KeywordExtraction>({
      keywords: localFallbackKeywords(text),
      degraded: true
    });
  }
}
