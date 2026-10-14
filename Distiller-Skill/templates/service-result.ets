// 依据：openharmony/ets/api/@ohos.base.d.ts（BusinessError 定义处）
// 依据：openharmony/ets/kits/@kit.BasicServicesKit.d.ts（BusinessError 再导出，官方示例用的就是这里的 import 路径）
// 依据：开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/前端页面调用应用侧函数/web-in-page-app-function-invoking.md（官方 catch 写法）
// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/arkts-immersive-light-sense.md（官方 catch 写法 · 第二处）
// 环境：HarmonyOS 6.0.2(22)；其中标注 26.0.0 的能力在本机未验证
// 说明：可直接抄进 entry/src/main/ets/ 的对应分层目录
//
// 落位：entry/src/main/ets/common/ServiceResult.ets
//
// ============================================================================
// 取证块 A：BusinessError 到底在哪 —— 三个候选文件的实际核查结果
// ============================================================================
//
// 【结论】BusinessError 的**定义处**是 @ohos.base.d.ts；@kit.BasicServicesKit.d.ts 只是**再导出**；
//        @ohos.app.ability.common.d.ts 里**没有** BusinessError（已 grep，0 命中）。
//        本项目统一从 '@kit.BasicServicesKit' 导入，理由是官方示例全部这么写（见取证块 B）。
//
// A1) 定义处 = D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default\openharmony\ets\api\@ohos.base.d.ts
//   A1:105-115  注释块（节选）
//     /**
//      * Defines the error parameter.
//      *
//      * @typedef BusinessError [since 6 - 11]
//      * @typedef BusinessError<T = void> [since 12]
//      * @syscap SystemCapability.Base
//      * @since 6
//      */
//   A1:116      export interface BusinessError<T = void> extends Error {
//   A1:117-125  /** Error code returned when the API fails to be called. ... @since 6 */
//   A1:126          code: number;
//   A1:127-136  /** Error message returned when the API fails to be called. If this parameter is left empty,
//                    the error object does not contain additional data. ... @since 9 */
//   A1:137          data?: T;
//   A1:138      }
//   → 注意：A1:126 是 code: number（必填），A1:137 是 data?: T（可选）。
//          message 来自 extends Error，不是本接口自己声明的字段。
//
// A2) 再导出 = ...\openharmony\ets\kits\@kit.BasicServicesKit.d.ts
//   A2:24   import { AsyncCallback, BusinessError, Callback, ErrorCallback } from '@ohos.base';
//   A2:59   export { AsyncCallback, Battery, ..., BusinessError, Callback, ... };
//
// A3) 反例 = ...\openharmony\ets\api\@ohos.app.ability.common.d.ts
//   grep "BusinessError" → No matches found（该文件不导出 BusinessError，不要从这里 import）
//
// ============================================================================
// 取证块 B：官方 catch 写法（原文逐字照抄）
// ============================================================================
//
// 来源 B = ...\开发指南\ArkWeb_方舟Web\在应用中使用前端页面JavaScript\前端页面调用应用侧函数\
//          web-in-page-app-function-invoking.md
//   B:15    import { BusinessError } from '@kit.BasicServicesKit';
//   B:36-44
//     Button('deleteJavaScriptRegister')
//       .onClick(() => {
//         try {
//           this.webviewController.deleteJavaScriptRegister('testObjName');
//           this.webviewController.refresh();
//         } catch (error) {
//           console.error(
//             `ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
//         }
//       })
//
// 来源 C = ...\开发指南\ArkUI_方舟UI框架\UI开发_ArkTS声明式开发范式\沉浸光感\arkts-immersive-light-sense.md
//   C:260   import { PromptAction, uiMaterial } from '@kit.ArkUI';
//   C:261   import { BusinessError } from '@kit.BasicServicesKit';
//   C:282-286
//     } catch (error) {
//       let message = (error as BusinessError).message;
//       let code = (error as BusinessError).code;
//       console.error(`showToast args error code is ${code}, message is ${message}`);
//     };
//   → 两处官方示例都是 `catch (error)` 后 `error as BusinessError`，取 .code 与 .message。
//     本文件 fromBusinessError() 即固化这一写法，避免每个 service 各写一遍。
//
// ============================================================================
// 未取证清单
// ============================================================================
// [U1] ArkTS 对「接口 readonly 字段 + 对象字面量初始化」的具体支持边界未逐条取证。
//      已取证的相关点：官方文档用对象字面量初始化接口/类实例（web-in-page-app-function-invoking.md:367
//      `let st: Student = { name: "jeck", age: "12" };`），且 ?? / ?. / ! 三个运算符
//      在官方代码中有用例（arkts-v1-v2-migration-reusable.md:44 用 ??；arkts-global-reuse-pool.md:982
//      用 ! ；容器断点指南用 ?.）。若编译器对 readonly 字面量报错，去掉 readonly 即可，语义不变。
// [U2] 「import() 失败时 reject 的 error 一定满足 BusinessError 形状」未取证。
//      fromBusinessError() 因此对任意 error 都做形状探测，不假设一定有 code。

/**
 * 服务调用状态。
 * 用数字枚举：官方 API 文档中的枚举一律是数字枚举（如 MaterialState DEFAULT=0/ENABLE=1/DISABLE=2）。
 */
export enum ServiceStatus {
  SUCCESS = 0,
  FAILURE = 1
}

/** 兜底错误码：既非系统 BusinessError 也非本项目自定义码段时使用。 */
export const ERROR_CODE_UNKNOWN: number = 10000;

/**
 * 服务层统一错误对象。
 * 与 BusinessError 的区别：ServiceError 是**纯数据**，可安全跨层传递、可序列化、可打日志；
 * BusinessError 是系统异常对象。service 层负责把后者翻译成前者。
 */
export interface ServiceError {
  /** 错误码。系统错误沿用 BusinessError.code；本项目自定义码从 20000 起。 */
  readonly code: number;
  /** 面向开发者的错误描述，不直接展示给用户。 */
  readonly message: string;
  /** 可选：原始异常信息，仅用于日志。不要交给 UI。 */
  readonly cause?: string;
}

/**
 * 服务层统一返回契约。
 *
 * 判定方式（唯一正确姿势）：
 *   const r: ServiceResult<T> = await doSomething();
 *   if (r.status === ServiceStatus.SUCCESS) { 用 r.value! }
 *   else { 用 r.error! }
 *
 * 约定：
 *   · service 层**永不抛异常**，所有失败都转成 FAILURE（唯一例外是程序员错误，如参数为 null）。
 *   · 降级成功算 SUCCESS（值里带 degraded 标记），只有彻底做不了才算 FAILURE。
 */
export interface ServiceResult<T> {
  readonly status: ServiceStatus;
  /** status === SUCCESS 时有效 */
  readonly value?: T;
  /** status === FAILURE 时有效 */
  readonly error?: ServiceError;
}

/** 构造成功结果。 */
export function success<T>(value: T): ServiceResult<T> {
  return { status: ServiceStatus.SUCCESS, value: value };
}

/** 构造失败结果。 */
export function failure<T>(error: ServiceError): ServiceResult<T> {
  return { status: ServiceStatus.FAILURE, error: error };
}

/** 成功则返回 value，失败则返回 fallback。用于「失败也不影响主流程」的位置。 */
export function valueOr<T>(result: ServiceResult<T>, fallback: T): T {
  if (result.status === ServiceStatus.SUCCESS && result.value !== undefined) {
    return result.value;
  }
  return fallback;
}

/** 成功则返回 true。 */
export function isSuccess<T>(result: ServiceResult<T>): boolean {
  return result.status === ServiceStatus.SUCCESS;
}

/**
 * 把 catch 到的任意异常翻译成 ServiceError。
 *
 * 为什么形参类型写 Object 而不是 BusinessError：
 *   未取证 [U2] —— 动态 import() 失败、第三方库 reject、手写 throw new Error() 都不保证是 BusinessError。
 *   声明成 BusinessError 会诱导调用方不判断，反而埋雷。
 *
 * @param error          catch 到的原始异常
 * @param fallbackCode   探测不出 code 时使用的错误码（建议传本项目自定义码）
 * @param fallbackMessage 探测不出 message 时使用的描述
 */
export function fromBusinessError(
  error: Object,
  fallbackCode: number = ERROR_CODE_UNKNOWN,
  fallbackMessage: string = '未知错误'
): ServiceError {
  if (error === null || error === undefined) {
    return { code: fallbackCode, message: fallbackMessage, cause: 'error is null/undefined' };
  }

  // 1) 探测 message：BusinessError extends Error，message 来自 Error
  let message: string = fallbackMessage;
  const maybeMessage: ESObject = (error as ESObject).message;
  if (typeof maybeMessage === 'string' && (maybeMessage as string).length > 0) {
    message = maybeMessage as string;
  }

  // 2) 探测 code：BusinessError.code 是必填 number，但非 BusinessError 对象没有此字段
  let code: number = fallbackCode;
  const maybeCode: ESObject = (error as ESObject).code;
  if (typeof maybeCode === 'number') {
    code = maybeCode as number;
  }

  // 3) 原始描述：优先 Error.stack 之外的可读文本，仅入日志
  let cause: string = '';
  const maybeName: ESObject = (error as ESObject).name;
  if (typeof maybeName === 'string') {
    cause = maybeName as string;
  }
  if (cause.length === 0) {
    cause = message;
  }

  return { code: code, message: message, cause: cause };
}

/**
 * 把 ServiceError 变成可以直接 showToast 的一句话。
 * 只暴露 code 与 message，不泄露 cause（可能含路径等内部信息）。
 */
export function toUserMessage(error: ServiceError): string {
  if (error.code === ERROR_CODE_UNKNOWN) {
    return error.message;
  }
  return `${error.message}（${error.code}）`;
}

/**
 * repository 层可选的辅助：包住一个可能抛异常的系统 API 调用。
 * 与 try/catch 手写相比，保证「永不抛」这一条约定不被漏掉。
 *
 * 用法：
 *   return guard(() => repository.readNote(id));
 *   或
 *   return await guardAsync(() => repository.readNote(id));
 */
export function guard<T>(fn: () => T, fallbackCode: number = ERROR_CODE_UNKNOWN,
  fallbackMessage: string = '操作失败'): ServiceResult<T> {
  try {
    return success<T>(fn());
  } catch (error) {
    // 官方 catch 写法：error as BusinessError（见取证块 B）
    const be: BusinessError = error as BusinessError;
    return failure<T>(fromBusinessError(be, fallbackCode, fallbackMessage));
  }
}

/** guard 的异步版本。 */
export async function guardAsync<T>(fn: () => Promise<T>, fallbackCode: number = ERROR_CODE_UNKNOWN,
  fallbackMessage: string = '操作失败'): Promise<ServiceResult<T>> {
  try {
    const v: T = await fn();
    return success<T>(v);
  } catch (error) {
    const be: BusinessError = error as BusinessError;
    return failure<T>(fromBusinessError(be, fallbackCode, fallbackMessage));
  }
}
