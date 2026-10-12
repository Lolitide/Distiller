/**
 * 知了 · 共用小部件
 * EntityIcon：把实体类型（时间/地点/人名/电话/链接/邮箱）渲染成系统 Symbol 图标。
 * 图标名取自本机 SDK 的 previewer resources.txt，均为真实存在的 sys.symbol 资源。
 */

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
