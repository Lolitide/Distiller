/**
 * service/system · PushTokenService —— 取/删 **Push Token**（Push Kit 端侧）。
 *
 * FE-76 的前半段：`pushService.getToken()` 拿到这台设备上本应用的推送令牌（112 字符左右），
 * 后半段（上报给应用服务器）在 `service/cloud/PushRegistrar.ets`。
 *
 * ## 为什么动态 `import()`
 *
 * 与 AI 三件套同一条纪律：端侧 Kit 在模拟器上可能整块不可用，**静态 import 会把风险提前到模块加载阶段**；
 * 动态引入把"这台设备没有这个能力"收敛成一次可捕获的失败，页面/设置页照样能显示状态。
 *
 * ## 官方事实（`@hms.core.push.pushService.d.ts` + 《pushService（推送服务基础能力）》）
 *
 *  · `pushService.getToken(): Promise<string>` —— `@since 4.0.0(10)`，无需任何权限声明；
 *  · 错误码（官方表，逐个对着写的，别自己编）：
 *      1000900001 系统内部错误 / 1000900008 连不上推送服务 / 1000900009 推送服务内部错误 /
 *      1000900010 应用身份非法（签名或 AGC 配置与包名对不上）/ 1000900011 网络不可用 /
 *      1000900012 **推送权益未开通**（AGC「增长 > 推送服务」没开）/ 1000900013 跨数据处理地不允许 /
 *      1000900014 **设备不支持取 token**（模拟器大多是这个）
 *  · 前置条件（《开通推送服务》）：
 *      ① 在 AGC 给这个项目**开通推送服务**；
 *      ② 用**已开通推送权益后重新申请的 Profile** 签名（调试证书同样要重签）——
 *         本仓库 `signingConfigs: []`、产物是 unsigned，所以在真机上装的那份**必须另配签名**才会拿到 token；
 *      ③ 从 HarmonyOS NEXT Developer Beta2 起**不需要**再配 Client ID / 公钥指纹（所以 `module.json5` 不用加 metadata）。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { pushService } from '@kit.PushKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'PushTokenService';

/* 官方错误码（取 token 会抛这些） */
const ERR_SYSTEM: number = 1000900001;
const ERR_CONNECT: number = 1000900008;
const ERR_SERVICE: number = 1000900009;
const ERR_IDENTITY: number = 1000900010;
const ERR_NETWORK: number = 1000900011;
const ERR_RIGHTS: number = 1000900012;
const ERR_LOCATION: number = 1000900013;
const ERR_UNSUPPORTED: number = 1000900014;

/** 取 token 的结果（成功 / 失败 + 官方错误码，不抛异常） */
export class PushTokenResult {
  ok: boolean = false;
  /** 成功时的 Push Token（约 112 字符） */
  token: string = '';
  /** 失败时的官方错误码（0 ＝ 没出错） */
  code: number = 0;
  /** 状态行用的**短标签**（如「推送权益未开通」） */
  message: string = '';
  /** 「怎么修」的长句（放不进状态行，只在 toast / 日志里用） */
  advice: string = '';
}

export class PushTokenService {
  /**
   * 取本机 Push Token。
   *
   * 建议调用时机（官方原话「建议在应用启动时调用，并及时上报」）：App 启动拿到设备身份之后；
   * 退出账号 / 换账号时官方建议先 `deleteToken()` 再重新取 —— 本工程没有账号体系，暂不涉及。
   */
  static async getToken(): Promise<PushTokenResult> {
    const result: PushTokenResult = new PushTokenResult();
    try {
      // 常量说明符的动态 import：编译期就能解析依赖；运行期失败也只是一次 reject
      // 静态 import：系统 Kit 的动态 import 在部分真机上会得到空命名空间
      // （实测 `ns.pushService` 为 undefined，报 1000900014），所以这里静态解析。
      const token = await Promise.resolve(pushService.getToken());
      const text: string = token !== undefined && token !== null ? token : '';
      if (text.length === 0) {
        result.code = ERR_SYSTEM;
        result.message = PushTokenService.mapMessage(ERR_SYSTEM);
        result.advice = PushTokenService.mapAdvice(ERR_SYSTEM);
        return result;
      }
      result.ok = true;
      result.token = text;
      return result;
    } catch (error) {
      const err = error as BusinessError;
      const msg: string = err.message !== undefined ? err.message : '';
      // 设备/模拟器上没有 Push Kit 时，`ns.pushService` 是 undefined，抛的是 TypeError（没有 code）
      const missing: boolean = err.name === 'TypeError' || msg.indexOf('of undefined') >= 0;
      const code: number = missing ? ERR_UNSUPPORTED : err.code;
      hilog.warn(DOMAIN, TAG, 'getToken failed: code=%{public}d missing=%{public}s msg=%{public}s',
        code, String(missing), msg);
      result.ok = false;
      result.code = code;
      result.message = PushTokenService.mapMessage(code);
      result.advice = PushTokenService.mapAdvice(code);
      return result;
    }
  }

  /** 官方错误码 → 状态行上的**短标签**（≤12 字，保证设置页一行放得下） */
  static mapMessage(code: number): string {
    if (code === ERR_CONNECT) {
      return '连不上推送服务';
    }
    if (code === ERR_SERVICE) {
      return '推送服务异常';
    }
    if (code === ERR_IDENTITY) {
      return '签名或 AGC 不匹配';
    }
    if (code === ERR_NETWORK) {
      return '网络不可用';
    }
    if (code === ERR_RIGHTS) {
      return '推送权益未开通';
    }
    if (code === ERR_LOCATION) {
      return '数据处理地不一致';
    }
    if (code === ERR_UNSUPPORTED) {
      return '设备不支持推送';
    }
    return '取令牌失败';
  }

  /** 官方错误码 → **怎么修**（只在点重试后的 toast / 日志里用，状态行放不下） */
  static mapAdvice(code: number): string {
    if (code === ERR_RIGHTS) {
      return '去 AGC「增长 > 推送服务」开通，再用重新申请的 Profile 重签';
    }
    if (code === ERR_IDENTITY) {
      return '核对包名与 AGC 应用是否一致，并用该应用的 Profile 重签';
    }
    if (code === ERR_UNSUPPORTED) {
      return '模拟器不支持；换真机 + 已开通推送的签名包';
    }
    if (code === ERR_CONNECT) {
      return '检查网络后重试';
    }
    if (code === ERR_NETWORK) {
      return '连上网络后重试';
    }
    if (code === ERR_LOCATION) {
      return '在 AGC「项目设置 > 数据处理位置」里对齐';
    }
    return '';
  }
}
