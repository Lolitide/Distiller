// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/组件布局/构建布局/容器断点_ContainerReader/arkts-layout-development-container-reader.md
// 依据：API参考/ArkUI_方舟UI框架/ArkTS组件/行列与堆叠/ContainerReader/ts-container-containerreader.md
// 依据：API参考/ArkUI_方舟UI框架/ArkTS组件/公共定义/枚举说明/ts-appendix-enums.md（WidthBreakpoint / HeightBreakpoint）
// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式状态管理/语法糖/语法_双向绑定/arkts-new-binding.md（!! 语法）
// 环境：HarmonyOS 6.0.2(22)；其中标注 26.0.0 的能力在本机未验证
// 说明：可直接抄进 entry/src/main/ets/ 的对应分层目录
//
// 落位：entry/src/main/ets/view/component/AdaptiveNoteCard.ets
//
// ★★★ 本文件全部内容依赖 API 26.0.0（HarmonyOS 7）。★★★
//     本项目 targetSdkVersion = compatibleSdkVersion = "6.0.2(22)"，因此：
//       · 在当前工程配置下这些 API 不会生效（官方：此变更已做版本隔离，仅在 targetSdkVersion ≥ 26.0.0 时生效）；
//       · 本机只有 6.0.2(22) 真机与已停止的模拟器，无 26.0.0 运行环境；
//       · 因此本文件的**运行时行为全部未验证**，仅编译期签名有取证。
//
// ============================================================================
// 取证块 1：接口签名与 ContainerReaderInfo 字段（原文逐字照抄）
// ============================================================================
//
// 来源 A = C:\Users\x2027\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\
//          行列与堆叠\ContainerReader\ts-container-containerreader.md
//
//   A:14    **起始版本：** 26.0.0
//   A:18    #### 子组件
//   A:18    「可以包含子组件。」
//   A:24    ContainerReader(value: ContainerReaderInfo)
//   A:26    「创建容器断点组件并配置容器读取参数。」
//   A:30    **模型约束：** 此接口仅可在Stage模型下使用。
//   A:32    **卡片能力：** 从API版本26.0.0开始，该接口支持在ArkTS卡片中使用。
//   A:34    **元服务API：** 从API版本26.0.0开始，该接口支持在元服务中使用。
//   A:36    **系统能力：** SystemCapability.ArkUI.ArkUI.Full
//   A:40-42 参数表
//     | 参数名 | 类型                                    | 必填 | 说明                                   |
//     | value  | [ContainerReaderInfo](#containerreaderinfo) | 是   | 容器读取配置选项，包含尺寸数据和断点配置。 |
//
//   A:44    #### ContainerReaderInfo
//   A:46    「定义ContainerReader组件的配置选项，用于指定容器尺寸读取和断点值获取的参数，
//            不能通过此参数改变组件尺寸和断点值。」
//   A:48    **起始版本：** 26.0.0
//   A:58-85 ContainerReaderInfo 字段表（名称 / 类型 / 只读 / 可选 / 说明）
//     | 名称             | 类型                                         | 只读 | 可选 | 说明 |
//     | size             | Size                                         | 否   | 否   | 获取到的当前ContainerReader组件的尺寸，用于布局分析和断点计算。
//     |                  |                                              |      |      | 说明：该参数支持!!双向绑定变量。绑定后组件尺寸值变化时，size绑定的变量值会自动更新。 |
//     | widthBreakpoint  | WidthBreakpoint                              | 否   | 是   | 容器的宽度断点，为获取到的当前ContainerReader组件的宽度断点枚举值。
//     |                  |                                              |      |      | 说明：该参数支持!!双向绑定变量。… |
//     | heightBreakpoint | HeightBreakpoint                             | 否   | 是   | 容器的高度断点，为获取到的当前ContainerReader组件在不同高宽比阈值下对应的高度断点枚举值。
//     |                  |                                              |      |      | 说明：该参数支持!!双向绑定变量。… |
//   → 必填只有 size；widthBreakpoint / heightBreakpoint 可选，但本项目要用断点，故两个都绑。
//
//   A:89    #### 属性
//   A:89    「除支持通用属性外，还支持以下属性：」
//   A:93    breakpointConfig(value?: BreakpointOptions)
//   A:95    「设置断点配置选项，定义触发不同布局行为的尺寸阈值。」
//   A:97    **起始版本：** 26.0.0
//   A:109-111 参数表
//     | 参数名 | 类型                                  | 必填 | 说明                                 |
//     | value  | [BreakpointOptions](#breakpointoptions) | 否   | 断点配置选项，包含宽度和高度的断点阈值数组。 |
//
//   A:113   #### BreakpointOptions
//   A:117   **起始版本：** 26.0.0
//   A:127-149 BreakpointOptions 字段表
//     | 名称   | 类型          | 只读 | 可选 | 说明 |
//     | width  | Array<number> | 否   | 是   | 宽度断点值数组。数组必须为单调递增数组。
//     |        |               |      |      | 默认值：[320, 600, 840, 1440]，单位vp，与窗口宽度断点默认值一致。
//     |        |               |      |      | 说明：最多可支持5个断点，即数组最大长度为4。 |
//     | height | Array<number> | 否   | 是   | 高度断点值数组，高度断点值是组件高度与宽度的比值。无单位。数组必须为单调递增数组。
//     |        |               |      |      | 默认值：[0.8, 1.2]，与窗口高度断点默认值一致。
//     |        |               |      |      | 说明：最多支持3个断点，即数组最大长度为2。 |
//
//   A:153   #### 事件: 「支持通用事件。」
//
// ============================================================================
// 取证块 2：使用约束（原文逐字照抄）
// ============================================================================
//
// 来源 B = C:\Users\x2027\.local\share\deveco-cli\docs\开发指南\ArkUI_方舟UI框架\
//          UI开发_ArkTS声明式开发范式\组件布局\构建布局\容器断点_ContainerReader\
//          arkts-layout-development-container-reader.md
//
//   B:4     「…从API版本26.0.0开始，允许开发者基于容器尺寸而非窗口尺寸实现自适应布局。
//            与传统的窗口断点相比，容器断点提供了更细粒度的布局控制能力…」
//   B:38    import {ContainerReader, ContainerReaderAttribute, Size} from '@kit.ArkUI';
//   B:36    「使用ContainerReader需要同时导入ContainerReaderAttribute，否则会导致编译报错。」
//           （A:165 / A:235 / A:312 等处重复同一句；这是本项目最容易踩的坑）
//   B:181   「ContainerReaderInfo的所有参数都必须通过状态变量进行双向绑定。」
//   B:183-190  正确用法
//     // 正确用法 - 使用!!触发双向绑定
//     @State containerSize: Size = { width: 0, height: 0 };
//     @State widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_MD;
//
//     ContainerReader({
//       size: this.containerSize!!,
//       widthBreakpoint: this.widthBp!!
//     })
//   B:192-196  错误用法1
//     // 错误用法1 - 未使用!!后缀，双向绑定不生效
//     ContainerReader({
//       size: this.containerSize,
//       widthBreakpoint: this.widthBp
//     })
//   B:198-204  错误用法2
//     // 错误用法2 - 使用非状态变量
//     const containerSize: Size = { width: 0, height: 0 };
//
//     ContainerReader({
//       size: containerSize,  // 必须是@State修饰的状态变量
//       widthBreakpoint: WidthBreakpoint.WIDTH_MD
//     })
//   B:208   「为防止在节点未尺寸测算前的生命周期中使用ContainerReader组件双向绑定的size状态变量，
//            需要给双向绑定状态变量一个初始值。」
//   B:210   「因此请确保，父容器有明确尺寸，含有ContainerReader组件的父容器不应依赖子节点确认自身大小，
//            ContainerReader组件不依赖自身子节点大小确认尺寸。」
//   B:218   「不能通过改变此处ContainerReaderInfo的size来试图设置ContainerReader尺寸。」
//   B:222   「断点数组必须为单调递增数组。其中，宽度断点最多支持5个，即数组最大长度为4；
//            高度断点最多支持3个，即数组最大长度为2。断点区间为左闭右开区间[breakpoint[i], breakpoint[i+1])。
//            宽度断点值单位为vp；高度断点值为组件高度与宽度的比值，无单位。」
//   B:226-230 异常处理规则表
//     | 异常情况                 | 处理方式                     |
//     | 数组大小超过最大数量。   | 使用系统默认断点。           |
//     | 数组非递增。             | 取递增结束的子数组。         |
//     | 数组中存在异常值（非数字等）。 | 跳过异常值，只处理有效值。 |
//   B:27-30 布局规格（父容器为 Flex/Row/Column 时撑满剩余空间；其他类型撑满父组件）
//   B:111  「当Flex、Row或Column容器中有多个ContainerReader子组件时，按开发者书写顺序第一个ContainerReader
//            会占满剩余空间，此时其余ContainerReader组件的主轴大小为0。但开发者可以通过layoutWeight属性
//            使多个ContainerReader平分剩余空间。」
//
// 来源 C = ts-appendix-enums.md（枚举成员，逐字）
//   C:2536-2542 WidthBreakpoint
//     | WIDTH_XS | 0 | 窗口宽度小于320vp。                                  |
//     | WIDTH_SM | 1 | 窗口宽度大于等于320vp，且小于600vp。                  |
//     | WIDTH_MD | 2 | 窗口宽度大于等于600vp，且小于840vp。                  |
//     | WIDTH_LG | 3 | 窗口宽度大于等于840vp，且小于1440vp。                 |
//     | WIDTH_XL | 4 | 窗口宽度大于等于1440vp。                              |
//   C:1212-1216 HeightBreakpoint
//     | HEIGHT_SM | 0 | 窗口高宽比小于0.8。              |
//     | HEIGHT_MD | 1 | 窗口高宽比大于等于0.8，且小于1.2。 |
//     | HEIGHT_LG | 2 | 窗口高宽比大于等于1.2。          |
//
// 来源 D = arkts-new-binding.md（!! 语法，逐字）
//   D:4     「在状态管理V1中，推荐使用$$实现系统组件的双向绑定。」
//   D:6     「在状态管理V2中，推荐使用!!语法糖统一处理双向绑定。」
//   D:10    「!!语法从API version 12开始支持。」
//   D:117   「!!运算符为系统组件提供TS变量的引用，使得TS变量和系统组件的内部状态保持同步。
//            添加方式是在变量名后添加，例如isShow!!。」
//   D:170   「当前!!双向绑定支持基础类型变量，当该变量使用@State等状态管理V1装饰器装饰，
//            或者@Local等状态管理V2装饰器装饰时，变量值的变化会触发UI刷新。」
//   D:113   「当使用3个或更多感叹号（!!!、!!!!、!!!!!等）时，不支持双向绑定功能。」
//
// 来源 E = C:\Users\x2027\.local\share\deveco-cli\docs\API参考\ArkUI_方舟UI框架\ArkTS组件\
//          空白与分隔\Divider\ts-basic-components-divider.md
//   （本文件宽容器分栏时用了 Divider 做竖线，故一并取证）
//   E:28-30 「#### 属性 / 除支持通用属性外，还支持以下属性：」
//   E:34    vertical(value: boolean)
//   E:36    「设置分割线的方向，支持attributeModifier动态设置属性方法。」
//   E:48-51 | value | boolean | 是 | 使用水平分割线还是垂直分割线。false：水平分割线；true：垂直分割线。 |
//   E:53    「默认值：false」
//   E:61    color(value: ResourceColor)
//   E:63    「设置分割线的颜色，支持attributeModifier动态设置属性方法。」
//   E:75-76 | value | ResourceColor | 是 | 分割线颜色。 |
//   E:88    strokeWidth(value: number | string)
//   → 本文件用 .vertical(true) + .color('#1A000000')，二者签名均已取证。
//
// 来源 F = arkts-apis-uimaterial.md「表1 特殊资源值对应的深浅色值」（本文件用的资源色出处）
//   F:318   | $r('sys.color.comp_background_secondary') | #19000000 | #19FFFFFF |
//   F:305   | $r('sys.color.font_primary')               | #E5000000 | #E5FFFFFF |
//   F:306   | $r('sys.color.font_secondary')             | #99000000 | #99FFFFFF |
//   → 用这些资源色而不是硬编码色值，才能自动跟随深浅色模式。
//
// ============================================================================
// 未取证清单
// ============================================================================
// [U1] 官方全部 ContainerReader 示例都用 V1 的 @State，没有一例用 V2 的 @Local；
//      B:202 的注释甚至直接写「必须是@State修饰的状态变量」。
//      本项目只允许 V2，故用 @Local。推断链：A:65/A:74/A:83「该参数支持!!双向绑定变量」
//      + D:170「!! 支持 @Local 等 V2 装饰器」+ B:181「必须通过状态变量双向绑定」。
//      → 这条推断**未取证**，所有 @Local 绑定行均以 // 未取证 标注，需在 26.0.0 环境实测。
// [U2] 「官方 import 行只列 ContainerReader / ContainerReaderAttribute / Size 三个名字，
//      而 WidthBreakpoint / HeightBreakpoint 未 import 直接使用」这一点，官方未作说明。
//      推断它们与 FlexAlign / FlexDirection / HorizontalAlign 一样属于 ArkUI 全局枚举。
//      → 未取证；若编译器报未定义，从 '@kit.ArkUI' 显式 import 二者。
// [U3] 26.0.0 全部运行时行为（容器尺寸回报时序、断点切换时机、嵌套 ContainerReader 的表现）。
//      本机无 26.0.0 环境，全部未验证。
// [U4] ContainerReader 在自定义组件（@ComponentV2 struct）内部的使用：
//      B:471-491 有 AdaptiveCard 的 V1 示例，但该示例内部只放了 Text，未演示「组件内二次布局」。
//      本文件的 AdaptiveNoteCard 属于对官方示例的形态扩展，未取证。

import { ContainerReader, ContainerReaderAttribute, Size } from '@kit.ArkUI';

// ---------------------------------------------------------------------------
// 断点阈值：本项目自定义（不用系统默认的 [320,600,840,1440]）
//
// 依据 A:129-136：width 为 Array<number>，默认 [320, 600, 840, 1440] vp，数组最大长度 4（最多 5 档）。
// 依据 B:222：宽度断点单位为 vp，区间左闭右开。
// 依据 B:226-230：数组非递增会被截断、超长会退回系统默认 —— 所以这里必须自己保证单调递增且长度 ≤ 4。
//
// 知了是单 phone 应用（deviceTypes ["phone"]），容器宽度大多落在 320~600vp 区间，
// 因此把阈值下压，让「窄/中/宽」三档在手机上也真的能被触发到：
//   < 320vp        → WIDTH_XS   极窄（分屏、小折叠外屏）
//   [320, 480)     → WIDTH_SM   常规手机竖屏
//   [480, 720)     → WIDTH_MD   大屏手机 / 展开态
//   >= 720vp       → WIDTH_LG   平板 / 悬停分栏
// 共 3 个阈值 → 4 档断点，长度 3 <= 4，合法。
// ---------------------------------------------------------------------------
const CARD_BREAKPOINTS: number[] = [320, 480, 720];

/** 卡片在窄容器下的内边距（vp） */
const PAD_NARROW: number = 12;
/** 卡片在宽容器下的内边距（vp） */
const PAD_WIDE: number = 20;

/**
 * 可复用的自适应笔记卡片 —— 按**自身容器**的宽度断点切换布局，
 * 而不是按窗口宽度断点切换。
 *
 * 关键差异：同一页里放两张宽度不同的卡片，它们会各自得到不同的断点值。
 * 用窗口断点（GridRow / WidthBreakpoint 监听窗口）做不到这一点。
 *
 * 落位：entry/src/main/ets/view/component/AdaptiveNoteCard.ets
 */
@ComponentV2
export struct AdaptiveNoteCard {
  // ---- 双向绑定状态变量：必须给初始值 ----
  // 依据 B:208「需要给双向绑定状态变量一个初始值」；
  //      A:60「获取到的当前ContainerReader组件的尺寸」→ 初值 0 是安全的未测算态。
  // 未取证 [U1]：官方示例用 @State，本项目用 @Local（V2）。
  @Local containerSize: Size = { width: 0, height: 0 };
  // 未取证 [U1]：同上。HeightBreakpoint 一并绑定，用于「超高容器」时收紧行高。
  @Local widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @Local heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_MD;

  // ---- 业务入参（V2：@Param + @Require 表示必传） ----
  @Require @Param title: string;
  @Require @Param summary: string;
  @Require @Param bullets: string[];
  /** 是否已蒸馏完成；未完成时卡片显示「处理中」 */
  @Param distilled: boolean = false;
  /** 点击回调，页面只做事件转发 */
  @Event onOpen: () => void = () => {};

  /**
   * 布局档位：由**容器**宽度断点决定，不看窗口。
   */
  private isNarrow(): boolean {
    return this.widthBp === WidthBreakpoint.WIDTH_XS || this.widthBp === WidthBreakpoint.WIDTH_SM;
  }

  /** 容器极窄时进一步压缩：标题与要点都降一号字 */
  private isTight(): boolean {
    return this.widthBp === WidthBreakpoint.WIDTH_XS;
  }

  /**
   * 容器内容高度不成比例地高（高宽比 >= 1.2）时，要点列表改用紧凑行距。
   * 依据 C:1216：HEIGHT_LG = 窗口高宽比 >= 1.2 —— 这里用在**容器**上。
   */
  private isTall(): boolean {
    return this.heightBp === HeightBreakpoint.HEIGHT_LG;
  }

  @Builder
  noteBody() {
    if (this.isNarrow()) {
      // ---- 窄容器：标题 → 摘要 → 要点，全部竖排 ----
      Column({ space: this.isTight() ? 6 : 10 }) {
        Text(this.title)
          .fontSize(this.isTight() ? 15 : 17)
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.summary)
          .fontSize(this.isTight() ? 12 : 14)
          .maxLines(this.isTall() ? 2 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        ForEach(this.bullets, (item: string, index: number) => {
          Row({ space: 6 }) {
            Text('·')
              .fontSize(this.isTight() ? 12 : 14)
            Text(item)
              .fontSize(this.isTight() ? 12 : 14)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
        }, (item: string, index: number) => `${index}-${item}`)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    } else {
      // ---- 宽容器：左「标题+摘要」 / 右「要点列表」左右分栏 ----
      Row({ space: 16 }) {
        Column({ space: 8 }) {
          Text(this.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(this.summary)
            .fontSize(14)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(3)
        .alignItems(HorizontalAlign.Start)

        Divider()
          .vertical(true)
          .height('100%')
          .color('#1A000000')

        Column({ space: 8 }) {
          ForEach(this.bullets, (item: string, index: number) => {
            Row({ space: 6 }) {
              Text('·')
                .fontSize(14)
              Text(item)
                .fontSize(14)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .width('100%')
          }, (item: string, index: number) => `${index}-${item}`)
        }
        .layoutWeight(2)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
  }

  build() {
    // 依据 B:36：必须同时 import ContainerReaderAttribute，否则编译报错（已在上方 import）。
    // 依据 A:18：ContainerReader 可以包含子组件。
    // 依据 B:27-30：父容器是 Column 时，ContainerReader 撑满父容器剩余空间。
    ContainerReader({
      // 依据 B:183-190 / A:65：!! 触发双向绑定。少了 !! 双向绑定不生效（B:192-196 错误用法1）。
      // 未取证 [U1]：@Local + !! 的组合在本组件上的行为未经 26.0.0 环境验证。
      size: this.containerSize!!,
      widthBreakpoint: this.widthBp!!,
      heightBreakpoint: this.heightBp!!
    }) {
      this.noteBody()
    }
    // 依据 A:129-136：自定义宽度阈值；数组单调递增且长度 3 <= 4。
    // 依据 B:222：单位 vp，左闭右开。
    .breakpointConfig({ width: CARD_BREAKPOINTS })
    .width('100%')
    .padding(this.isNarrow() ? PAD_NARROW : PAD_WIDE)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(this.isNarrow() ? 12 : 16)
    // 容器测试探针：真机验证时打开，确认断点确实跟随**容器**而非窗口变化。
    // 依据 A:60：size 是「获取到的当前ContainerReader组件的尺寸」。
    .onClick(() => {
      console.info(
        `[AdaptiveNoteCard] container=${this.containerSize.width}x${this.containerSize.height} ` +
        `wbp=${this.widthBp} hbp=${this.heightBp} narrow=${this.isNarrow()}`
      );
      this.onOpen();
    })
  }
}

/**
 * 页面：蒸馏结果卡片流。
 *
 * 分层：页面 → ViewModel → service → repository。
 * 本页只做渲染与事件转发；这里为最小可运行示例直接内联了静态数据，
 * 正式实现应从 ViewModel 取 ServiceResult<NoteCard[]>。
 *
 * 落位：entry/src/main/ets/pages/DistillPage.ets
 */
@Entry
@ComponentV2
struct DistillPage {
  @Local cards: string[] = ['一', '二', '三', '四', '五', '六'];

  build() {
    Column() {
      Text('本次蒸馏')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      List({ space: 12 }) {
        ForEach(this.cards, (label: string, index: number) => {
          ListItem() {
            // 演示容器级断点：同一页里两张卡片的容器宽度由外部决定，
            // 窄的那张走竖排，宽的那张走左右分栏 —— 与窗口宽度无关。
            AdaptiveNoteCard({
              title: `第 ${label} 张卡片`,
              summary: '把这一章压缩成三句话，先讲结论，再讲依据，最后讲它对你意味着什么。',
              bullets: ['结论：先给判断', '依据：来自原文第 3 节', '行动：明天试用一次'],
              distilled: true,
              onOpen: () => {
                // 页面只做事件转发，不写业务
                console.info(`[DistillPage] open card ${index}`);
              }
            })
            // 故意给不同宽度，用来验证「容器断点」与「窗口断点」的区别
            .width(index % 2 === 0 ? '100%' : '60%')
          }
        }, (label: string, index: number) => `${index}-${label}`)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16 })
      // 依据 B:111：多个 ContainerReader 时有 layoutWeight 才能平分剩余空间；
      // 这里每个 ContainerReader 都在自己的 ListItem 内，尺寸由 ListItem 决定，不涉及该规则。
      .cachedCount(4)
    }
    .width('100%')
    .height('100%')
  }
}

// ---------------------------------------------------------------------------
// 真机验证清单（26.0.0 环境到位后逐条跑）
//
// 1. 打开本页，日志确认 containerSize.width 随卡片宽度变化，而非随窗口宽度变化。
// 2. 把 index % 2 === 0 的卡片宽度从 '100%' 改成 '40%'，确认窄卡切到竖排、宽卡保持分栏。
// 3. 把 .breakpointConfig 去掉，确认退回系统默认阈值 [320,600,840,1440]（依据 A:132）。
// 4. 故意把 CARD_BREAKPOINTS 改成 [480, 320, 720]（非递增），确认只取递增子数组 [480]
//    （依据 B:228-229「取递增结束的子数组」）。
// 5. 故意把 CARD_BREAKPOINTS 改成 5 个元素，确认退回系统默认（依据 B:228「数组大小超过最大数量」）。
// 6. 故意去掉一处 !! 后缀，确认双向绑定失效、断点不再刷新（依据 B:192-196）。
// 7. 故意删掉 ContainerReaderAttribute 的 import，确认编译报错（依据 B:36）。
// ---------------------------------------------------------------------------
