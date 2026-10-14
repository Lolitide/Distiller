// 依据：API参考/ArkUI_方舟UI框架/ArkTS_API/UI界面/ohos_arkui_uiMaterial_系统材质_/arkts-apis-uimaterial.md
// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/沉浸光感/arkts-immersive-light-sense.md
// 依据：API参考/ArkUI_方舟UI框架/ArkTS组件/通用属性/视效与模糊/图像效果/ts-universal-attributes-image-effect.md（systemMaterial 通用属性）
// 环境：HarmonyOS 6.0.2(22)；其中标注 26.0.0 的能力在本机未验证
// 说明：可直接抄进 entry/src/main/ets/ 的对应分层目录
//
// 落位：entry/src/main/ets/pages/ReaderPage.ets（沉浸光感版阅读页示例）
//
// ★★★ 本文件全部内容依赖 API 26.0.0（HarmonyOS 7）。★★★
//     本项目 targetSdkVersion = compatibleSdkVersion = "6.0.2(22)"。
//     官方原文（沉浸光感指南 L54）：「使用此能力前，需要确保应用的 targetAPIVersion 不低于 26.0.0。」
//     本机只有 6.0.2(22) 真机与已停止的模拟器，因此本文件**运行时行为全部未验证**，
//     仅接口签名、枚举成员、参数默认值有取证。
//
// ============================================================================
// 取证块 1：模块导入与类/枚举/接口签名（原文逐字照抄）
// ============================================================================
//
// 来源 A = C:\Users\x2027\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS_API\
//          UI界面\ohos_arkui_uiMaterial_系统材质_\arkts-apis-uimaterial.md
//
//   A:1     @ohos.arkui.uiMaterial (系统材质)
//   A:8     **起始版本：** 26.0.0
//   A:12    import { uiMaterial } from '@kit.ArkUI';
//
//   A:14    #### ImmersiveMaterial
//   A:16    「沉浸式材质类，继承自Material。」
//   A:22    constructor(options?: ImmersiveOptions)
//   A:26    **起始版本：** 26.0.0
//   A:28    **模型约束：** 此接口仅可在Stage模型下使用。
//   A:30    **元服务API：** 从API版本26.0.0开始，该接口支持在元服务中使用。
//   A:32    **系统能力：** SystemCapability.ArkUI.ArkUI.Full
//   A:41    options 默认值（逐字）：
//           「默认值参考ImmersiveOptions接口各参数的默认值，即
//             {style:uiMaterial.ImmersiveStyle.REGULAR, materialColor:undefined, colorInvert:false,
//              applyShadow:true, interactive:false, lightEffect:undefined}。」
//
//   A:45    #### Material
//   A:47    「系统材质对象基类。」
//   A:49    **起始版本：** 26.0.0
//   A:55    **卡片能力：** 从API版本26.0.0开始，该接口支持在ArkTS卡片中使用。
//   A:61    static get empty(): Material
//   A:63    「返回空材质对象，用于组件单独关闭沉浸式系统材质效果。使用方式为uiMaterial.Material.empty。」
//   A:65    「在enable模式下，可通过设置systemMaterial(uiMaterial.Material.empty)来单独关闭某个组件的
//            沉浸式系统材质效果。如果组件未支持组件级沉浸式系统材质接口，则无法通过此方法关闭材质效果。」
//   A:77-79 返回值表
//     | 类型     | 说明                         |
//     | Material | 返回空材质对象，表示无材质效果。 |
//
//   A:81    #### MaterialType
//   A:93-95 枚举成员表
//     | 名称      | 值 | 说明 |
//     | IMMERSIVE | 2  | 沉浸式材质类型。仅用于MaterialInfo接口的type属性标识当前配置的材质类型，
//     |           |    | 不映射到底层功能。实际材质效果通过ImmersiveMaterial类实现。 |
//
//   A:97    #### MaterialState
//   A:99    「材质使能状态枚举，表示应用级沉浸式系统材质配置的状态。」
//   A:109-113 枚举成员表（逐字）
//     | 名称    | 值 | 说明 |
//     | DEFAULT | 0  | 默认模式。弹出框Dialog、即时反馈（Toast）、AlphabetIndexer 在组件本身未设置背景颜色、
//     |         |    | 模糊参数和阴影参数时默认开启沉浸式系统材质；Text 设置 copyOption 后长按或双击触发的
//     |         |    | 文本菜单默认开启沉浸式系统材质；其他组件由应用主动设置。 |
//     | ENABLE  | 1  | 使能模式。…此模式下，沉浸式系统材质样式生效的优先级高于组件本身设置的背景色、模糊、
//     |         |    | 阴影和边框样式。其他组件需开发者主动设置。 |
//     | DISABLE | 2  | 禁用模式。所有组件禁止开启沉浸式系统材质，即使主动为组件设置沉浸式系统材质参数也不会生效。 |
//
//   A:115   #### MaterialInfo
//   A:127-130 字段表
//     | 名称  | 类型                              | 只读 | 可选 | 说明 |
//     | state | MaterialState                     | 否   | 否   | 材质使能状态配置。 |
//     | type  | MaterialType                      | 否   | 否   | 材质类型标识，表示当前配置对应的材质类型。该值仅用于类型标识，不映射到底层功能。 |
//
//   A:132   #### uiMaterial.getMaterialInfo
//   A:134   getMaterialInfo(): MaterialInfo
//   A:136   「获取当前应用的材质配置信息。返回的配置信息来自应用在module.json5中配置的metadata。」
//
//   A:152   #### ImmersiveStyle
//   A:154   「沉浸式材质样式枚举。不同的材质样式对应不同的材质参数，主要包括材质的模糊程度、高光效果等。」
//   A:164-170 枚举成员表（逐字）
//     | 名称        | 值 | 说明 |
//     | ULTRA_THIN  | 0  | 超薄样式。材质层超薄，具有很强的透明效果。 |
//     | THIN        | 1  | 薄样式。材质层薄，具有较强的透明效果。 |
//     | REGULAR     | 2  | 常规样式。材质层的厚度常规。 |
//     | THICK       | 3  | 厚样式。材质层厚，模糊效果较强。 |
//     | ULTRA_THICK | 4  | 超厚样式。材质层超厚，模糊效果很强。 |
//
//   A:172   #### LightEffectOptions
//   A:174   「沉浸式材质的光感交互反馈配置。用于自定义反馈光感的颜色。」
//   A:184-191 字段表
//     | 名称  | 类型          | 只读 | 可选 | 说明 |
//     | color | ResourceColor | 否   | 是   | 自定义交互反馈光感的颜色。默认值：Color.White |
//
//   A:193   #### ImmersiveOptions
//   A:205-295 字段表（逐字，含默认值）
//     | 名称          | 类型                              | 只读 | 可选 | 说明 |
//     | style         | ImmersiveStyle                    | 否   | 是   | 材质样式。不同样式对应不同的材质参数，影响材质的厚度。
//     |               |                                   |      |      | 说明：该参数仅对高算力和中算力设备的显示效果生效。默认值：uiMaterial.ImmersiveStyle.REGULAR |
//     | materialColor | ResourceColor                     | 否   | 是   | 材质层赋色。…默认值：undefined
//     |               |                                   |      |      | 说明：该参数对所有档位的算力设备的显示效果生效。 |
//     | colorInvert   | boolean                           | 否   | 是   | 设置了材质对象的节点的子树是否自动适配材质到背景色的反色。
//     |               |                                   |      |      | 若为false，则不会自动反色。若为true，则只有材质参数足够薄时才会自动反色。
//     |               |                                   |      |      | 说明：该参数仅对高算力和中算力设备的显示效果生效。默认值：false |
//     | applyShadow   | boolean                           | 否   | 是   | 是否添加材质的阴影效果。…默认值：true
//     |               |                                   |      |      | 说明：该参数对所有档位的算力设备的显示效果生效。 |
//     | interactive   | boolean                           | 否   | 是   | 是否启用交互形变效果。…默认值：false
//     |               |                                   |      |      | 说明：该参数对所有档位的算力设备的显示效果生效。 |
//     | lightEffect   | LightEffectOptions | null         | 否   | 是   | 光感交互反馈效果参数。当该参数为null时，禁用光感交互反馈效果。
//     |               |                                   |      |      | 说明：该参数对所有档位的算力设备的显示效果生效。默认值：undefined，不设置光感交互反馈效果。 |
//
// ============================================================================
// 取证块 2：systemMaterial 通用属性与 SystemUiMaterial 类型（原文逐字照抄）
// ============================================================================
//
// 来源 B = C:\Users\x2027\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\
//          通用属性\视效与模糊\图像效果\ts-universal-attributes-image-effect.md
//
//   B:1779  #### systemMaterial
//   B:1781  systemMaterial(material: SystemUiMaterial | undefined): T
//   B:1783  「设置组件的系统材质。不同系统材质对应不同的属性影响效果，该接口可以影响背景色backgroundColor、
//            边框颜色borderColor、边框宽度borderWidth、阴影shadow、材质层滤镜materialFilter效果…」
//   B:1788-1789 属性冲突（逐字）
//     · 先设置backgroundColor属性后设置systemMaterial属性：backgroundColor属性被覆盖。在高算力和中算力设备上，
//       背景色属性被清空为透明色；在低算力设备上，材质自带的背景色效果覆盖了先设置的backgroundColor属性。
//     · 先设置systemMaterial属性后设置backgroundColor属性：systemMaterial属性影响的背景色效果被覆盖，
//       背景色属性生效为后设置的backgroundColor属性的颜色。
//   B:1806 参数表
//     | 名称     | 类型                                  | 必填 | 说明 |
//     | material | SystemUiMaterial | undefined          | 是   | 组件的系统材质对象。设置为undefined时恢复为无材质的效果… |
//   B:1814  #### SystemUiMaterial
//   B:1816  type SystemUiMaterial = import('../api/@ohos.arkui.uiMaterial').default.Material
//   → 这就是「systemMaterial 只吃 uiMaterial.Material」的类型依据：
//     SystemUiMaterial 就是 @ohos.arkui.uiMaterial 的默认导出的 Material。
//
// ============================================================================
// 取证块 3：开启方式与约束（原文逐字照抄）
// ============================================================================
//
// 来源 C = C:\Users\x2027\.local\share\deveco-cli\docs\开发指南\ArkUI_方舟UI框架\
//          UI开发_ArkTS声明式开发范式\沉浸光感\arkts-immersive-light-sense.md
//
//   C:54    「通过在module.json5中配置metadata，可以全局控制应用内沉浸式系统材质的开启状态。
//            其中，name字段需为"ohos.arkui.UIMaterial.state"，value字段可以为default、enable和disable。
//            使用此能力前，需要确保应用的targetAPIVersion不低于26.0.0。该配置仅在entry类型的module中生效。」
//   C:56-69 配置示例（逐字）
//     {
//       "module": {
//         "name": "entry",
//         "type": "entry",
//         // ...
//         "metadata": [{
//           "name": "ohos.arkui.UIMaterial.state",
//           "value": "enable"
//         }],
//         // ...
//       }
//     }
//   C:71    「MaterialState提供应用级沉浸式系统材质配置的三种状态DEFAULT、ENABLE和DISABLE，
//            即对应json5配置中的三个value枚举值。」
//   C:135   「所有支持通用属性的组件，均支持通过systemMaterial通用属性设置沉浸式系统材质。」
//   C:479   「在ENABLE模式下，部分组件会默认开启沉浸式系统材质。如需单独关闭某个组件的沉浸式系统材质，
//            可以设置uiMaterial.Material.empty。」
//   C:519   「如果需要全局禁用所有组件的沉浸式系统材质，可在module.json5中将metadata的value设置为"disable"。」
//   C:677   「对于通过通用属性systemMaterial设置材质的场景，建议将systemMaterial放在其他样式属性之后设置，
//            这样可以确保材质效果优先级正确；通过组件options参数设置材质时则无需关注设置顺序。」
//   C:679   「对于所有设置了沉浸式系统材质的组件，不建议同时设置背景色、背景模糊、阴影和边框样式。」
//   C:695-701 自动反色（逐字要点）
//     「开启colorInvert后，组件子节点中的文字颜色会自动适配材质到背景色的反色，确保文字始终可读。说明如下：
//       · 自动反色仅在材质足够薄时生效，材质样式为THIN或ULTRA_THIN。
//       · 自动反色与系统沉浸光感的强弱配置相关，材质越薄、沉浸光感越强，越容易符合反色要求。
//       · 自动反色仅对通过资源接口设置的颜色值生效，包括Text组件的fontColor、Button组件的fontColor …」
//   C:764   「ArkUI：支持Button、Column、Row等ArkUI组件设置沉浸光感视效，及自定义材质样式、交互形变、
//            光感反馈等效果。」
//
// ============================================================================
// 未取证清单
// ============================================================================
// [U1] 26.0.0 全部运行时表现：材质在高/中/低算力设备上的实际观感、交互形变幅度、
//      光感反馈轨迹、深浅色模式下的差异。本机无 26.0.0 环境，全部未验证。
// [U2] 「本项目 targetSdkVersion 提升到 26.0.0 后，getMaterialInfo() 返回值是否立刻变为 ENABLE」
//      未取证。C:54 只说明 metadata 需要 targetAPIVersion >= 26.0.0，没有说明版本不足时
//      getMaterialInfo() 返回什么（是 DEFAULT 还是抛错）。代码因此只做「读回来是什么就按什么渲染」，
//      不假设版本不足时会怎样。
// [U3] MaterialInfo 在应用运行期是否会因系统设置（沉浸光感强弱）变化而改变，
//      未取证。A:136 说「返回的配置信息来自应用在module.json5中配置的metadata」——
//      metadata 是静态的，故本文件只在构造时读一次，不做轮询。
// [U4] 「NavDestination / Navigation 的标题栏」是否属于 C:75 列表里支持应用级材质的组件，
//      未取证（C:75 列表里没有 Navigation/NavDestination）。本文件因此只对 Column / Button /
//      Text 三个明确列举的组件用材质。
// [U5] systemMaterial 与 borderRadius 的相互影响未在文档中说明。官方示例对圆角容器
//      （Column 328x56 borderRadius 28）直接叠加材质，本文件照此写法，效果未验证。

import { uiMaterial } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 知了阅读页在沉浸光感下的三种材质档位。
 * 用本项目自己的语义名包住官方枚举，避免枚举值散落在各个 build() 里。
 *
 * 选用依据 C:19-25 的「适用场景」列：
 *   ULTRA_THIN → 需要高度透明的背景，如浮动工具栏
 *   THIN       → 需要较强透明度的场景，如搜索框
 *   REGULAR    → 通用场景
 *   THICK      → 需要较强模糊背景的场景，如菜单
 *   ULTRA_THICK→ 需要完全模糊背景的场景，如弹窗
 */
@ObservedV2
export class MaterialPalette {
  /** 正文卡片：通用场景 → REGULAR（依据 A:168） */
  @Trace cardStyle: uiMaterial.ImmersiveStyle = uiMaterial.ImmersiveStyle.REGULAR;
  /** 底部浮动操作条：高度透明 → ULTRA_THIN（依据 A:166） */
  @Trace toolbarStyle: uiMaterial.ImmersiveStyle = uiMaterial.ImmersiveStyle.ULTRA_THIN;
  /** 主按钮：较强透明度 → THIN（依据 A:167） */
  @Trace actionStyle: uiMaterial.ImmersiveStyle = uiMaterial.ImmersiveStyle.THIN;

  /**
   * 正文卡片材质。
   * colorInvert = true 的依据：C:695-701，薄材质下文字自动反色保证可读性。
   * 但 REGULAR 不在「THIN 或 ULTRA_THIN」之列，故卡片**不开** colorInvert，
   * 而是显式给出 fontColor（见 build()），避免依赖未生效的反色。
   */
  cardMaterial(): uiMaterial.Material {
    return new uiMaterial.ImmersiveMaterial({
      style: this.cardStyle
      // colorInvert 保持默认 false（依据 A:41 默认值表）
      // applyShadow 保持默认 true（依据 A:41）
    });
  }

  /** 浮动工具条材质：极薄 + 自动反色 + 交互形变 */
  toolbarMaterial(): uiMaterial.Material {
    return new uiMaterial.ImmersiveMaterial({
      style: this.toolbarStyle,
      // 依据 C:699「自动反色仅在材质足够薄时生效，材质样式为THIN或ULTRA_THIN」
      colorInvert: true,
      // 依据 A:278-280「是否启用交互形变效果…默认值：false」
      interactive: true,
      // 依据 A:287-293：lightEffect 传 { color: undefined } 表示用默认白色（A:189 默认值 Color.White）
      // 传 null 则禁用光感交互反馈（A:289）
      lightEffect: { color: undefined }
    });
  }

  /** 主按钮材质：薄 + 交互形变 + 自定义光感颜色 */
  actionMaterial(): uiMaterial.Material {
    return new uiMaterial.ImmersiveMaterial({
      style: this.actionStyle,
      colorInvert: true,
      interactive: true,
      // 依据 A:186-189：LightEffectOptions.color 为 ResourceColor，默认 Color.White。
      // 用系统资源色而非硬编码色值 —— 依据 A:297-326「表1 特殊资源值对应的深浅色值」，
      // 只有特殊资源值才享受深浅色自适应。
      lightEffect: { color: $r('sys.color.font_on_primary') },
      // 依据 A:265-273：applyShadow=true 时材质阴影固定生效，优先于 shadow 通用属性。
      // 浮动条上不希望再叠一层通用阴影，故显式关掉。
      applyShadow: false
    });
  }
}

/**
 * 阅读页（沉浸光感示例）。
 *
 * 分层：页面 → ViewModel → service → repository。
 * 本页只做渲染；材质对象的构造放在 MaterialPalette（可提升到 ViewModel），
 * 页面只负责把材质挂到组件上。
 */
@Entry
@ComponentV2
struct ReaderPage {
  /**
   * 材质使能状态。
   * 依据 A:136「返回的配置信息来自应用在module.json5中配置的metadata」——
   * metadata 是静态配置，运行期不会变，故只读一次（不在 build() 里调）。
   * 未取证 [U2]：targetSdkVersion < 26.0.0 时该调用的返回/行为。
   */
  private materialInfo: uiMaterial.MaterialInfo = uiMaterial.getMaterialInfo();

  private palette: MaterialPalette = new MaterialPalette();

  /** 正文内容（示例用静态数据；正式实现从 ViewModel 取） */
  @Local paragraphs: string[] = [
    '先给结论：把一章压成三句话，比读三遍更有效。',
    '依据来自原文第三节：提取动作本身就是一次再编码。',
    '行动项：今天挑一节试一次，写完再回看。'
  ];

  /** 是否在本页手动关闭材质（演示 uiMaterial.Material.empty） */
  @Local materialOff: boolean = false;

  /**
   * 依据 A:111-113：DEFAULT 下其他组件要应用主动设置；DISABLE 下设置也不生效。
   * 因此只有 ENABLE 才渲染材质分支，避免在 DISABLE 下白写一遍代码还看不出区别。
   */
  private materialEnabled(): boolean {
    return this.materialInfo.state === uiMaterial.MaterialState.ENABLE && !this.materialOff;
  }

  /**
   * 把「当前该用哪个材质对象」收敛成一个方法。
   * 三态：ENABLE 且未手动关 → 真材质；ENABLE 且手动关 → Material.empty（依据 A:61-65）；
   * 其他（DEFAULT / DISABLE）→ undefined（依据 B:1806「设置为undefined时恢复为无材质的效果」）。
   */
  private pick(material: uiMaterial.Material): uiMaterial.Material | undefined {
    if (!this.materialEnabled()) {
      // 依据 A:65：只有 enable 模式下才可以用 empty 单独关闭。
      // DEFAULT/DISABLE 下用 undefined 走「无材质」路径（B:1806）。
      return this.materialInfo.state === uiMaterial.MaterialState.ENABLE
        ? uiMaterial.Material.empty
        : undefined;
    }
    return material;
  }

  build() {
    Stack() {
      // 材质需要背景内容才有通透观感（官方示例一律垫一张图）
      Image($r('app.media.reader_bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Column({ space: 16 }) {
        // ---- 顶部状态条：把 getMaterialInfo() 的结果摊开，便于真机验证 ----
        Column({ space: 4 }) {
          Text(`state = ${this.materialInfo.state}`)
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
          Text(`type = ${this.materialInfo.type}`)
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
          Text(`切换状态见 module.json5 的 metadata: ohos.arkui.UIMaterial.state`)
            .fontSize(11)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .width('100%')
        .padding(12)

        // ---- 正文卡片：systemMaterial 挂在 Column 上 ----
        Column({ space: 12 }) {
          ForEach(this.paragraphs, (text: string, index: number) => {
            Text(text)
              .fontSize(16)
              // 依据 C:679「不建议同时设置背景色、背景模糊、阴影和边框样式」
              // → 这里只设字体色，不设 backgroundColor / border / shadow。
              // 依据 C:695-701：REGULAR 不触发自动反色，所以必须显式给颜色。
              .fontColor($r('sys.color.font_primary'))
              .width('100%')
          }, (text: string, index: number) => `${index}-${text}`)
        }
        .width('100%')
        .padding(20)
        .borderRadius(20)
        // 依据 C:677「建议将systemMaterial放在其他样式属性之后设置」
        // → 这一行必须是本链式调用的最后一个样式属性。
        .systemMaterial(this.pick(this.palette.cardMaterial()))

        // ---- 底部浮动操作条：极薄 + 交互形变 + 光感反馈 ----
        Row({ space: 12 }) {
          Button('上一节')
            .fontSize(14)
            .fontColor($r('sys.color.font_primary'))
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            .systemMaterial(this.pick(this.palette.toolbarMaterial()))

          Button('标记重点')
            .fontSize(14)
            .fontColor($r('sys.color.font_on_primary'))
            .backgroundColor(Color.Transparent)
            .layoutWeight(1)
            // 依据 C:234「Column交互形变示例」与 C:208「光感交互反馈示例」
            .systemMaterial(this.pick(this.palette.actionMaterial()))
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(24)

        // ---- 逃生开关：演示 Material.empty ----
        Button(this.materialOff ? '恢复系统材质' : '关闭本页材质')
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.materialOff = !this.materialOff;
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
  }
}

// ============================================================================
// 配套的 module.json5 片段（依据 C:54、C:56-69、C:519）
//
// 注意三件事：
//   1. name 必须**逐字**为 "ohos.arkui.UIMaterial.state"；
//   2. value 只能是 default / enable / disable；
//   3. 该配置**仅在 entry 类型的 module 中生效**（本项目正是单模块 entry，符合）。
//   4. 使用前需要 targetAPIVersion >= 26.0.0 —— 本项目当前是 6.0.2(22)，
//      所以这段配置现在加上去也不会生效。**未取证 [U2]**。
//
// {
//   "module": {
//     "name": "entry",
//     "type": "entry",
//     "metadata": [{
//       "name": "ohos.arkui.UIMaterial.state",
//       "value": "enable"
//     }]
//   }
// }
//
// ============================================================================
// 真机验证清单（26.0.0 环境到位后逐条跑）
//
// 1. 加上上面的 metadata（value: "enable"），启动本页，确认顶部 state 打印为 1(ENABLE)。
// 2. 把 value 改成 "disable"，确认 state 打印为 2、所有组件无材质（依据 A:113）。
// 3. 删掉 metadata，确认 state 打印为 0(DEFAULT)、Column/Button 无材质（依据 A:111）。
// 4. 分别在高/中/低算力设备上截图，比对 ImmersiveStyle 五档的差异（依据 A:18）。
// 5. 点击「关闭本页材质」，确认三个组件材质消失且**不报错**（依据 A:61-65）。
// 6. 长按浮动条按钮，确认有交互形变与光感跟随（依据 A:276-286）。
// 7. 切换到深色模式，确认材质与 $r('sys.color.*') 文字色都自适应（依据 C:681-691）。
// 8. 故意把 systemMaterial 提到 padding 之前，比对优先级是否变化（依据 C:677）。
// ============================================================================
