/**
 * 知了 · 共用小部件
 * EntityIcon：把实体类型（时间/地点/人名/电话/链接/邮箱）渲染成系统 Symbol 图标。
 * 图标名取自本机 SDK 的 previewer resources.txt，均为真实存在的 sys.symbol 资源。
 * safeToast / safePush / safeReplace：showToast 与路由跳转会抛异常（DevEco 要求显式处理），
 * 失败时没有可补救的动作，记日志后静默——统一收口，避免每个调用点重复 try-catch。
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const UI_DOMAIN: number = 0x0000;
const UI_TAG: string = 'SafeUi';

/** showToast 包装：失败仅记日志（页面跳转/销毁瞬间调用是常态）。 */
export function safeToast(ui: UIContext, message: string): void {
  try {
    ui.getPromptAction().showToast({ message: message });
  } catch (e) {
    const err = e as Error;
    hilog.warn(UI_DOMAIN, UI_TAG, 'showToast failed: %{public}s', err.message);
  }
}

/** router.pushUrl 包装：失败留在当前页。params 可选（详情页跳转带参数）。 */
export function safePush(ui: UIContext, url: string, params?: Object): void {
  try {
    if (params === undefined) {
      ui.getRouter().pushUrl({ url: url });
    } else {
      ui.getRouter().pushUrl({ url: url, params: params });
    }
  } catch (e) {
    const err = e as Error;
    hilog.warn(UI_DOMAIN, UI_TAG, 'pushUrl failed: %{public}s %{public}s', url, err.message);
  }
}

/** router.replaceUrl 包装：失败留在当前页。 */
export function safeReplace(ui: UIContext, url: string): void {
  try {
    ui.getRouter().replaceUrl({ url: url });
  } catch (e) {
    const err = e as Error;
    hilog.warn(UI_DOMAIN, UI_TAG, 'replaceUrl failed: %{public}s %{public}s', url, err.message);
  }
}

export interface EntityIconParams {
  type: string;
  size: number;
  color: string;
}

@Builder
export function EntityIcon(params: EntityIconParams) {
  if (params.type === 'datetime') {
    SymbolGlyph($r('sys.symbol.clock')).fontSize(params.size).fontColor([params.color])
  } else if (params.type === 'location') {
    SymbolGlyph($r('sys.symbol.pin')).fontSize(params.size).fontColor([params.color])
  } else if (params.type === 'name') {
    SymbolGlyph($r('sys.symbol.person')).fontSize(params.size).fontColor([params.color])
  } else if (params.type === 'phoneNo') {
    SymbolGlyph($r('sys.symbol.phone')).fontSize(params.size).fontColor([params.color])
  } else if (params.type === 'url') {
    SymbolGlyph($r('sys.symbol.link')).fontSize(params.size).fontColor([params.color])
  } else if (params.type === 'email') {
    SymbolGlyph($r('sys.symbol.envelope')).fontSize(params.size).fontColor([params.color])
  } else {
    SymbolGlyph($r('sys.symbol.circle')).fontSize(params.size).fontColor([params.color])
  }
}
