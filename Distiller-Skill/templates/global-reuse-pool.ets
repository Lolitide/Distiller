// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/全局复用_集中化的组件回收与复用/arkts-global-reuse-pool.md
// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式基本语法/自定义组件/自定义组件复用/ReusableV2装饰器_V2组件复用/arkts-new-reusablev2.md
// 依据：开发指南/ArkUI_方舟UI框架/UI开发_ArkTS声明式开发范式/学习UI范式状态管理/状态管理V1-V2迁移指导/状态管理V1向V2迁移场景/组件复用迁移/arkts-v1-v2-migration-reusable.md
// 环境：HarmonyOS 6.0.2(22)；其中标注 26.0.0 的能力在本机未验证
// 说明：可直接抄进 entry/src/main/ets/ 的对应分层目录
//
// 落位：entry/src/main/ets/pages/DistillListPage.ets
//
// ★ 版本分层（重要）★
//   · @ReusableV2 本身：起始 API 18（来源 B:L10）—— 本项目 6.0.2(22) 可用。
//   · 全局复用池（reusePool / poolAccepts / freezeWhenInactive / getReusePool /
//     getReusableInfo / preRender）：起始 API 26.0.0（来源 A:L10）——
//     **本机未验证**。本文件的 List / WaterFlow 部分是 6.0.2(22) 可跑的，
//     全局复用池的配置与探针部分是 26.0.0 才生效的。
//
// ============================================================================
// 问题 1 的明确回答：文档是否区分 V1 @Reusable 与 V2 @ReusableV2？—— 区分，而且区分得很细
// ============================================================================
//
// 是，文档明确区分。逐条取证：
//
// (1) 来源 A:L4 开头就把两者并列：
//     「…允许开发者在任意自定义组件上配置针对指定@Reusable/@ReusableV2复用组件的复用池…」
//     来源 A:L28（默认复用池定义）同样并列：「使用@Reusable或@ReusableV2声明的复用组件…」
//
// (2) 来源 A:L34-42 的「默认复用池与全局复用池的能力对比」表里有一行专门讲 V1/V2：
//     | 类别        | 默认复用池 | 全局复用池 |
//     | V1 与 V2 混合 | 不支持     | poolAccepts可同时包含@Reusable复用组件和@ReusableV2复用组件。 |
//
// (3) 来源 A:L170 poolAccepts 说明：
//     「全局复用池接纳的可复用组件的数组，可以同时包含@Reusable和@ReusableV2装饰的自定义组件。」
//     来源 A:L225「poolAccepts的成员必须是@Reusable或@ReusableV2装饰的自定义组件…」
//
// (4) 来源 B:L19 给出两者**行为上的硬差异**：
//     「…但与@Reusable不同的是，aboutToReuse没有入参。」
//     来源 B:L362「与@Reusable不同的是，@ReusableV2在复用前会重置组件中的状态变量以及相关的
//     @Computed、@Monitor的内容。」
//     来源 C:L29「aboutToReuse生命周期在组件复用V2中进行了优化，去除了参数的同时，
//     在复用前会自动重置各状态变量…无需开发者在aboutToReuse中手动赋值回初始值。」
//
// (5) 来源 C:L6-8 有正式的迁移对照表：
//     | V1装饰器名称 | V2装饰器名称   |
//     | @Reusable    | @ReusableV2    |
//     来源 C:L83 另有属性级对照：reuseId 属性 → reuse 属性。
//
// (6) 来源 B:L113-116 的混用矩阵（节选，逐字）：
//     | 混用支持关系 | V1普通组件 | V2普通组件 | V1复用组件 | V2复用组件 |
//     | V1普通组件   | 支持       | 支持       | 支持       | 不支持，编译报错 |
//     | V2普通组件   | 支持       | 支持       | 不支持，编译告警，实际使用子组件不创建 | 支持 |
//     | V1复用组件   | 支持       | 支持，需要使用API version 18及以上的SDK… | 支持 | 不支持，编译报错 |
//     | V2复用组件   | 支持       | 支持       | 不支持，编译报错 | 支持 |
//
// ---------------------------------------------------------------------------
// 问题 2 的明确回答：V2-only 工程该用哪个？—— @ReusableV2，唯一选项，没有第二个
// ---------------------------------------------------------------------------
//   · 来源 B:L18「@ReusableV2仅能装饰V2的自定义组件，即@ComponentV2装饰的自定义组件。
//     并且仅能将@ReusableV2装饰的自定义组件作为V2自定义组件的子组件使用。」
//   · 来源 B:L114（上表第 2 行第 3 列）：「V2普通组件」当父、「V1复用组件」当子 →
//     **不支持，编译告警，实际使用子组件不创建**。
//     本项目是 V2-only（所有组件都是 @ComponentV2），所以 @Reusable 不只是「没必要」，
//     而是会直接导致子组件不被创建 —— 属于功能性故障，不是风格问题。
//   · 来源 C:L18 的迁移规则也是单向的：「将@Reusable装饰的子自定义组件迁移为@ReusableV2装饰。」
//   → 结论：本项目只用 @ReusableV2。本文件不出现 @Reusable。
//
// ============================================================================
// 取证块：全局复用池 API（原文逐字照抄）
// ============================================================================
//
// 来源 A = C:\Users\x2027\.local\share\deveco-cli\docs\开发指南\ArkUI_方舟UI框架\
//          UI开发_ArkTS声明式开发范式\学习UI范式基本语法\自定义组件\自定义组件复用\
//          全局复用_集中化的组件回收与复用\arkts-global-reuse-pool.md
//
//   A:10    「全局复用池功能从API版本26.0.0开始支持。」
//   A:12    「该功能可从API版本26.0.0开始在元服务中使用。」
//   A:36    「全局复用池通过在@Component或@ComponentV2中配置reusePool和poolAccepts开启。」
//   A:123-127  适配全局复用能力的示例（逐字）
//     @Entry
//     @ComponentV2({
//       reusePool: 'shared', // 配置全局复用池模式，使能全局复用能力
//       poolAccepts: [ReusableComponent], // 配置全局复用池接纳名称为ReusableComponent的自定义组件
//       freezeWhenInactive: false // 组件冻结默认配置
//     })
//     struct Index {
//   A:165-178  装饰器参数表（逐字）
//     @Component/@ComponentV2配置参数：
//     | 参数              | 类型                                    | 必填 | 说明 |
//     | reusePool         | ReusePoolOwnership                      | 否   | 如果使用全局复用功能，该参数的值必须为"shared"或"perInstance"。
//     |                   |                                         |      | 决定此组件类的所有实例是共享单个复用池还是每个实例拥有自己的池。 |
//     | poolAccepts       | Function[]                              | 否   | 全局复用池接纳的可复用组件的数组，可以同时包含@Reusable和@ReusableV2装饰的自定义组件。 |
//     | freezeWhenInactive| boolean                                 | 是   | 配置自定义组件支持组件冻结。true：开启组件冻结，false：不开启组件冻结。… |
//   A:184   「"shared"：拥有@Component/@ComponentV2类的所有实例共享单个复用池实例。」
//   A:200   「"perInstance"：拥有@Component/@ComponentV2的每个实例都有自己的复用池实例。
//            复用池的生命周期与其拥有组件实例的生命周期相同。」
//   A:204   「建议开发者配置shared所有权。这样可以获得更好的复用率和更低的内存占用。」
//   A:210-219  接口说明表（逐字）
//     | 接口 | 说明 |
//     | UIUtils.getCustomComponentContext(this).getReusePool() | 获取当前组件的IReusePool。
//     |                                                          | 如果该组件或其上层组件未配置全局复用池，则返回undefined。 |
//     | IReusePool.getReusableInfo(reusableComp, reuseId?)       | 检索池中给定可复用组件类型的回收实例信息。支持按reuseId查询。 |
//     | IReusePool.preRender(builder, n)                         | 调度空闲任务以预创建可复用组件并在首次使用前将其放入复用池。 |
//     | IReusableInfo.count                                      | 池中当前回收的组件数（只读）。 |
//     | IReusableInfo.maxCount                                   | 允许的最大回收组件数。设置此项可控制缓存大小。 |
//     | IReusableInfo.reuseId                                    | 全局复用池基于reuseId分区存放复用组件，该分区对应的reuseId（只读）。 |
//   A:221-241  使用限制（逐字，逐条对本文件有约束）
//     · reusePool和poolAccepts参数必须同时提供。仅指定其中一个会导致编译错误。
//     · poolAccepts必须是非空数组，否则会导致编译报错。poolAccepts的成员必须是@Reusable或
//       @ReusableV2装饰的自定义组件，使用普通（不可复用）组件、@Builder函数或非组件类会导致编译错误。
//     · reusePool和poolAccepts配置仅在@Component和@ComponentV2上支持。在@CustomDialog上不受支持。
//     · @Component和@ComponentV2在配置reusePool和poolAccepts启用全局复用的同时，
//       需要额外配置freezeWhenInactive参数…
//     · getReusableInfo和preRender仅在全局复用池实例上可用。它们不能在默认复用池的自定义组件上使用。
//     · 将IReusableInfo.maxCount设置为小于当前count的值会导致异步清除。在延迟期间，
//       count可能暂时超过maxCount。
//     · 使用preRender预渲染但不被任何池接受的组件会被创建并立即销毁。仅预渲染池配置为接受的组件。
//     · 使用"shared"所有权时，只要拥有组件类的任何实例存在，池就会持续存在。…
//       使用maxCount来控制内存使用。
//     · 建议不要在aboutToRecycle中修改会触发重新渲染的状态变量，因为组件此时正从UI树中移除。
//     · 由于ArkTS语法限制，poolAccepts参数配置的自定义组件，必须在poolAccepts上方的代码中有定义
//       或者从其他文件导入。如果在poolAccepts传入的组件在下方定义，则会编译报错，
//       报错消息是"Class '...' used before its declaration."。   ← 本文件据此调整了结构体顺序
//   A:491   import { UIUtils, IReusableInfo } from '@kit.ArkUI';
//   A:596   const pool = UIUtils.getCustomComponentContext(this).getReusePool();
//   A:601   const ret = pool.getReusableInfo(comp);
//   A:625   ret.maxCount = 0;   // maxCount赋值为0时会释放复用池中的组件。
//   A:664   getReusableInfo(GlobalChild): count=0, maxCount=100   ← maxCount 默认 100
//   A:783   TestChild({ label: 'A' }).reuse({ reuseId: () => 'A' })
//   A:982   pool!.preRender(new WrappedBuilder<[]>(preRenderBuilder.bind(this)), 1)
//             .then(() => { console.info('ReusableComponent preRender completes'); });
//
// 来源 B = ...\ReusableV2装饰器_V2组件复用\arkts-new-reusablev2.md
//   B:10    「从API version 18开始，可以使用@ReusableV2装饰@ComponentV2装饰的自定义组件。」
//   B:18    @ReusableV2 只能装饰 @ComponentV2，且只能作为 V2 自定义组件的子组件
//   B:19    「…aboutToRecycle和aboutToReuse的生命周期…但与@Reusable不同的是，aboutToReuse没有入参。」
//   B:20    「在回收阶段，会递归地调用所有子组件的aboutToRecycle回调（即使子组件未被标记可复用）；
//            在复用阶段，会递归地调用所有子组件的aboutToReuse回调…」
//   B:22    「…在复用时自动重置组件内状态变量的值、重新计算组件内@Computed以及与之相关的@Monitor。」
//   B:55-59 .reuse 用法（逐字）
//     ReusableV2Component().reuse({ reuseId: () => 'reuseComponent' }) // 使用'reuseComponent'作为reuseId
//     ReusableV2Component().reuse({ reuseId: () => '' }) // 使用空字符串将默认使用组件名'ReusableV2Component'作为reuseId
//     ReusableV2Component() // 未指定reuseId将默认使用组件名'ReusableV2Component'作为reuseId
//   B:120   「V2的复用组件当前不支持直接用于Repeat的template中，但是可以用在template中的V2自定义组件中。」
//   B:673   「Repeat组件懒加载场景中，将会优先使用Repeat组件的缓存池，正常滑动场景、更新场景不涉及组件的回收与复用。
//            当Repeat的缓存池需要扩充时将会向自定义组件要求新的子组件，此时如果复用池中有可复用的节点，将会进行复用。」
//   B:675   「通过配置Repeat组件VirtualScrollOptions的reusable属性为false，可以关闭Repeat组件自身的复用能力。
//            此时，滑动场景、更新场景均会触发@ReusableV2的回收与复用。」
//   B:708-720  List + Repeat 懒加载示例（逐字骨架）
//     List({ space: 10 }) {
//       Repeat(this.simpleList)
//         .virtualScroll()
//         .each((obj: RepeatItem<number>) => {
//           ListItem() { Column() { ReusableV2Component({ num: obj.item }) } }
//             .width('100%')
//         })
//     }.height('50%')
//     .cachedCount(2)
//   B:368-370 复用前状态变量重置规则表（逐字）
//     | 装饰器    | 重置方法 |
//     | @Local    | 直接使用定义时的初始值重新赋值。 |
//     | @Param    | 如果有外部传入则使用外部传入值重新赋值，否则用本地初始值重新赋值。
//     |           | 注意：@Once装饰的变量同样会被重置初始化一次。 |
//     | @Event    | 如果有外部传入则使用外部传入值重新赋值，否则用本地初始值重新赋值。… |
//
// 来源 D = ...\组件复用迁移\arkts-v1-v2-migration-reusable.md
//   D:542-556  WaterFlow + Repeat 懒加载示例（逐字骨架）
//     WaterFlow({ scroller: this.scroller }) {
//       Repeat(this.dataSource)
//         .virtualScroll()
//         .each((ri) => {
//           FlowItem() {
//             ReusableV2FlowItem({ item: ri.item })
//           }.onAppear(() => { … })
//         })
//     }.margin({ left: 160, top: 10 })
//
// 来源 E = ...\ohos_arkui_uiMaterial_系统材质_\arkts-apis-uimaterial.md「表1 特殊资源值对应的深浅色值」
//   （本文件用的 $r('sys.color.*') 全部出自此表，用资源色才能跟随深浅色模式）
//   E:301   | $r('sys.color.brand')                      | #FF0A59F7 | #FF317AF7 |
//   E:304   | $r('sys.color.font_on_primary')            | #FFFFFFFF | #FFFFFFFF |
//   E:307   | $r('sys.color.font_tertiary')              | #66000000 | #66FFFFFF |
//   E:318   | $r('sys.color.comp_background_secondary')  | #19000000 | #19FFFFFF |
//
// ============================================================================
// 未取证清单
// ============================================================================
// [U1] 「全局复用池 + List/Repeat」这个组合未被任何本地文档演示过。已取证的两个半边是：
//        · 全局复用池的示例（A:250-336、A:391-425、A:587-656）全部用 if 分支切换来触发回收/复用；
//        · List/WaterFlow + @ReusableV2 的示例（B:708-720、D:542-556）没有配置全局复用池。
//      本文件把两者组合，理由是 A:18「框架会向上遍历组件树，为回收和复用操作查找接受指定可复用
//      组件类型的全局复用池」并未限定触发方式，但**这条组合本身未取证**。
//      26.0.0 环境到位后必须实测：List 滑动时 aboutToRecycle/aboutToReuse 是否真的打到全局池上。
// [U2] 全局复用池的全部运行时行为（26.0.0）。本机无 26.0.0 环境。
// [U3] poolAccepts 里传「从其他文件 import 进来的 @ReusableV2 组件」的写法（A:241 允许），
//      本文件为了单文件可读性选择「定义在上方」，未演示 import 形式。
// [U4] Repeat 的 VirtualScrollOptions.reusable 与全局复用池同时存在时的优先级未取证
//      （B:675 只说明 reusable=false 会让滑动也触发 @ReusableV2 回收/复用）。
// [U5] IReusableInfo 的完整字段集未取证。A:217-219 只列了 count / maxCount / reuseId 三个，
//      本文件只用这三个，不假设还有其他字段。

import { UIUtils, IReusableInfo } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

// ---------------------------------------------------------------------------
// 数据模型（V2：@ObservedV2 + @Trace）
// ---------------------------------------------------------------------------
@ObservedV2
export class DistillCard {
  @Trace id: string = '';
  @Trace title: string = '';
  /** 'text' | 'image' | 'link' —— 用字符串而不是枚举，便于直接来自后端 */
  @Trace kind: string = 'text';
  @Trace summary: string = '';
  @Trace starred: boolean = false;
  /** 卡片高度系数，供 WaterFlow 布局用 */
  @Trace weight: number = 1;

  constructor(id: string, title: string, summary: string, kind: string, weight: number) {
    this.id = id;
    this.title = title;
    this.summary = summary;
    this.kind = kind;
    this.weight = weight;
  }
}

// ===========================================================================
// 顺序要求（依据 A:241）
//   poolAccepts 引用的自定义组件，必须在 poolAccepts 出现**之前**定义或 import，
//   否则编译报错 "Class '...' used before its declaration."
//   → 所以下面三个 @ReusableV2 组件全部定义在使用它们的页面之前。
// ===========================================================================

/**
 * 可复用的蒸馏卡片。
 *
 * @ReusableV2 而不是 @Reusable —— 本项目 V2-only（理由见文件头的「问题 2」）。
 */
@ReusableV2
@ComponentV2
export struct ReusableCard {
  // 依据 B:369：@Param 有外部传入则用外部传入值重置；本卡片的入参是必传的，用 @Require。
  @Require @Param card: DistillCard;

  // 依据 B:368：@Local 在复用前会被重置回定义时的初始值 —— 所以「展开态」这类
  // 瞬时 UI 状态放 @Local 是安全的，不会把上一张卡片的展开态带到下一张。
  @Local expanded: boolean = false;

  aboutToAppear(): void {
    console.info(`[ReusableCard] aboutToAppear id=${this.card.id}`);
  }

  // 依据 B:19：@ReusableV2 的 aboutToReuse **没有入参**（这点与 V1 @Reusable 不同，
  // V1 的签名是 aboutToReuse(params: ESObject)，见 D:42）。
  aboutToReuse(): void {
    // 依据 A:239：不要在这里改会触发重新渲染的状态变量（组件正从 UI 树中移除）。
    // 依据 B:22：复用前状态变量已被自动重置，无需在这里手动赋回初值。
    console.info(`[ReusableCard] aboutToReuse id=${this.card.id}`);
  }

  aboutToRecycle(): void {
    console.info(`[ReusableCard] aboutToRecycle id=${this.card.id}`);
  }

  aboutToDisappear(): void {
    console.info(`[ReusableCard] aboutToDisappear id=${this.card.id}`);
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.card.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.card.starred ? '★' : '☆')
          .fontSize(16)
          .onClick(() => {
            // @Trace 字段可直接改，UI 自动刷新
            this.card.starred = !this.card.starred;
          })
      }
      .width('100%')

      Text(this.card.summary)
        .fontSize(14)
        .maxLines(this.expanded ? 100 : 2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      if (this.card.kind === 'image') {
        // 形态不同的卡片共用一个复用组件；用 reuseId 分区避免串味（依据 A:783）
        Text('［含图卡片］')
          .fontSize(12)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .width('100%')
    .padding(12)
    // 颜色取自 uiMaterial 文档「表1 特殊资源值对应的深浅色值」（L316-319 有 comp_background_secondary），
    // 用资源色而非硬编码色值，才能跟随深浅色模式。
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(12)
    .onClick(() => {
      this.expanded = !this.expanded;
    })
  }
}

/**
 * 高亮卡片：与 ReusableCard 是**不同类型**的复用组件，
 * 用同一个全局复用池接纳（依据 A:170 数组可含多个成员）。
 */
@ReusableV2
@ComponentV2
export struct HighlightCard {
  @Require @Param card: DistillCard;

  aboutToReuse(): void {
    console.info(`[HighlightCard] aboutToReuse id=${this.card.id}`);
  }

  build() {
    Column({ space: 6 }) {
      Text('重点')
        .fontSize(11)
        .fontColor($r('sys.color.font_on_primary'))
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor($r('sys.color.brand'))
        .borderRadius(4)
      Text(this.card.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      Text(this.card.summary)
        .fontSize(14)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(12)
  }
}

/**
 * 列表页：Distiller 的蒸馏结果卡片流。
 *
 * 全局复用池配置在这个页面上（依据 A:36「通过在@Component或@ComponentV2中配置」）。
 *
 * 三条硬约束，逐条对应：
 *   1. reusePool 与 poolAccepts 必须同时给出，且 poolAccepts 非空（依据 A:223、A:225）；
 *   2. 必须同时给出 freezeWhenInactive（依据 A:229）；
 *   3. poolAccepts 里的组件必须在**上方**定义（依据 A:241）—— 本文件已按此排序。
 */
@Entry
@ComponentV2({
  // 依据 A:184/A:200：'shared' = 该类所有实例共享一个池；'perInstance' = 每实例一个池。
  // 依据 A:204：官方建议用 shared，复用率更高、内存占用更低。
  reusePool: 'shared',
  // 依据 A:170：数组可以同时接纳多种 @ReusableV2 组件。
  // 依据 A:225：成员必须都是 @Reusable 或 @ReusableV2 装饰的自定义组件，非空。
  poolAccepts: [ReusableCard, HighlightCard],
  // 依据 A:229：配置 reusePool/poolAccepts 时必须额外给出这个参数。
  // 依据 A:172：true 开启组件冻结，false 不开启。本页内容不需要后台刷新，用 false。
  freezeWhenInactive: false
})
struct DistillListPage {
  @Local cards: DistillCard[] = [];
  @Local onlyHighlight: boolean = false;
  /** 'list' | 'waterflow' —— 演示两种容器都能吃到同一个全局复用池 */
  @Local layoutMode: string = 'list';

  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 造 60 条静态数据（正式实现应从 ViewModel 取 ServiceResult<DistillCard[]>）
    for (let i = 0; i < 60; i++) {
      const kind: string = i % 5 === 0 ? 'image' : (i % 3 === 0 ? 'link' : 'text');
      this.cards.push(new DistillCard(
        `c${i}`,
        `第 ${i + 1} 张卡片`,
        '把这一节压成三句话：先给判断，再给依据，最后给一个今天就能做的动作。',
        kind,
        1 + (i % 4) * 0.5
      ));
    }
  }

  // -------------------------------------------------------------------------
  // 全局复用池探针（依据 A:210-219）
  // 仅在 26.0.0 上可用；在 6.0.2(22) 上 getReusePool() 预期返回 undefined。
  // -------------------------------------------------------------------------

  /** 打印当前页全局复用池里各复用组件的缓存量 */
  inspectPool(): void {
    const pool = UIUtils.getCustomComponentContext(this).getReusePool();
    if (!pool) {
      // 依据 A:214：「如果该组件或其上层组件未配置全局复用池，则返回undefined。」
      console.info('[Pool] no global reuse pool (expected on < 26.0.0)');
      return;
    }
    this.logInfo('ReusableCard', ReusableCard);
    this.logInfo('HighlightCard', HighlightCard);
  }

  private logInfo(name: string, comp: Function): void {
    const pool = UIUtils.getCustomComponentContext(this).getReusePool();
    if (!pool) {
      return;
    }
    const ret = pool.getReusableInfo(comp);
    // 依据 A:801-813：不带 reuseId 查询时，返回的是**数组**（每个 reuseId 分区一项，
    // 外加一项 reuseId: undefined）；带 reuseId 时返回单个对象；
    // 查询不存在的 reuseId 也返回单个对象（count:0）。
    if (ret === undefined) {
      console.info(`[Pool] getReusableInfo(${name}): undefined`);
    } else if (Array.isArray(ret)) {
      const arr: IReusableInfo[] = ret as IReusableInfo[];
      console.info(`[Pool] getReusableInfo(${name}): Array[${arr.length}]`);
      arr.forEach((info: IReusableInfo, i: number) => {
        console.info(`[Pool]   [${i}] count=${info.count}, maxCount=${info.maxCount}, reuseId=${info.reuseId}`);
      });
    } else {
      const one: IReusableInfo = ret as IReusableInfo;
      console.info(`[Pool] getReusableInfo(${name}): count=${one.count}, maxCount=${one.maxCount}, reuseId=${one.reuseId}`);
    }
  }

  /**
   * 通过 maxCount 控制缓存上限。
   * 依据 A:218「允许的最大回收组件数。设置此项可控制缓存大小。」
   * 依据 A:233「将IReusableInfo.maxCount设置为小于当前count的值会导致异步清除。
   *            在延迟期间，count可能暂时超过maxCount。」
   */
  capPool(name: string, comp: Function, cap: number): void {
    const pool = UIUtils.getCustomComponentContext(this).getReusePool();
    if (!pool) {
      return;
    }
    const ret = pool.getReusableInfo(comp);
    if (ret && !Array.isArray(ret)) {
      (ret as IReusableInfo).maxCount = cap;
      console.info(`[Pool] ${name}.maxCount -> ${cap}`);
    }
  }

  @Builder
  cardItem(card: DistillCard) {
    // 依据 A:783 / B:55-59：用 .reuse({ reuseId: () => '...' }) 给复用组件分区。
    // 相同 reuseId 的实例才会互相复用；不同形态的卡片用不同 reuseId 避免布局串味。
    if (card.starred) {
      HighlightCard({ card: card })
        .reuse({ reuseId: () => 'highlight' })
    } else if (card.kind === 'image') {
      ReusableCard({ card: card })
        .reuse({ reuseId: () => 'card-with-image' })
    } else {
      ReusableCard({ card: card })
        .reuse({ reuseId: () => 'card-plain' })
    }
  }

  // 注意：**不要把这个 @Builder 命名为 `toolbar`**。`toolbar` 是 CustomComponent 基类的保留成员
  // （`toolbar(value: CustomBuilder): CommonAttribute`），用 @Builder 覆盖会得到 2416/2345 类型错误：
  //   Property 'toolbar' in type 'X' is not assignable to the same property in base type 'CustomComponent'.
  //   Type '() => void' is not assignable to type '(value: CustomBuilder) => CommonAttribute'.
  // 这是 mcp__deveco__check 在 2026-10-12 实际报出来的，不是推测。
  @Builder
  topToolbar() {
    Row({ space: 8 }) {
      Button('切换布局')
        .fontSize(12)
        .onClick(() => {
          this.layoutMode = this.layoutMode === 'list' ? 'waterflow' : 'list';
        })
      Button('探测复用池')
        .fontSize(12)
        .onClick(() => {
          this.inspectPool();
        })
      Button('上限压到 5')
        .fontSize(12)
        .onClick(() => {
          this.capPool('ReusableCard', ReusableCard, 5);
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  }

  build() {
    Column() {
      this.topToolbar()

      if (this.layoutMode === 'list') {
        // ---- List + Repeat 懒加载（骨架依据 B:708-720） ----
        List({ space: 10 }) {
          Repeat(this.cards)
            // 依据 B:673：Repeat 懒加载场景优先用 Repeat 自己的缓存池；
            // 依据 B:675：把 reusable 设为 false 才会让滑动也走 @ReusableV2 的回收/复用。
            // 未取证 [U4]：与全局复用池同时存在时的优先级。
            .virtualScroll()
            .each((ri: RepeatItem<DistillCard>) => {
              ListItem() {
                this.cardItem(ri.item)
              }
              .width('100%')
            })
        }
        .width('100%')
        .layoutWeight(1)
        // 依据 B:720：cachedCount 控制 Repeat 自身缓存数量，与全局复用池是两套缓存。
        .cachedCount(4)
      } else {
        // ---- WaterFlow + Repeat（骨架依据 D:542-556） ----
        WaterFlow({ scroller: this.scroller }) {
          Repeat(this.cards)
            .virtualScroll()
            .each((ri: RepeatItem<DistillCard>) => {
              FlowItem() {
                this.cardItem(ri.item)
              }
              .width('100%')
            })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .width('100%')
        .layoutWeight(1)
        .cachedCount(4)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12 })
  }
}

// ============================================================================
// 预渲染（依据 A:212、A:216、A:944-1051）
// 在首次使用前把复用组件塞进池子，加快首屏。
// 完整骨架（逐字来自 A:969-986）：
//
//   @Builder
//   function preRenderBuilder() {
//     ReusableComponent()
//   }
//
//   @Entry
//   @ComponentV2({ reusePool: 'shared', poolAccepts: [ReusableComponent], freezeWhenInactive: false })
//   struct Index {
//     aboutToAppear() {
//       const pool = UIUtils.getCustomComponentContext(this).getReusePool();
//       pool!.preRender(new WrappedBuilder<[]>(preRenderBuilder.bind(this)), 1)
//         .then(() => {
//           console.info('ReusableComponent preRender completes');
//         });
//     }
//   }
//
// 两条限制（依据 A:235、A:1051）：
//   · 使用preRender预渲染但不被任何池接受的组件会被创建并立即销毁。仅预渲染池配置为接受的组件。
//   · 预渲染期间不会从全局池中复用组件；复用池仅接受新创建的实例。
//
// 本项目落地时的注意点：preRenderBuilder 只能创建**无必传 @Param** 的组件，
// 否则参数无处传入。ReusableCard 的 card 是 @Require @Param，因此不能直接预渲染；
// 若要预渲染，需要再造一个参数全可选的@ReusableV2 壳组件，或把 card 改成默认值可选。
// 未取证 [U5]：@Require @Param 与 preRender 的组合行为，文档未说明。
// ============================================================================

// ============================================================================
// 真机验证清单
//
// 【6.0.2(22) 可跑的部分】
// 1. 打开本页，滑动列表，日志应出现 ReusableCard aboutToRecycle / aboutToReuse。
// 2. 点击「探测复用池」，预期打印 `[Pool] no global reuse pool (expected on < 26.0.0)`
//    （依据 A:214，未配置/不支持的组件返回 undefined）。
// 3. 切换布局到 WaterFlow，确认复用行为一致。
// 4. 展开某张卡片再滑走，滚回来确认展开态被重置为 false（依据 B:368 @Local 重置规则）。
//
// 【26.0.0 才生效的部分 —— 本机未验证 [U2]】
// 5. 点击「探测复用池」，预期打印 count / maxCount / reuseId（依据 A:664，maxCount 默认 100）。
// 6. 点击「上限压到 5」，确认 count 异步收敛到 5（依据 A:233）。
// 7. 快速滑出再滑回，确认 aboutToReuse 而不是 aboutToAppear（跨父组件复用成功）。
// 8. 把 reusePool 改成 'perInstance'，重复第 7 步，对比复用率差异。
// 9. 把 poolAccepts 清空或删掉 reusePool，确认**编译报错**（依据 A:223、A:225）。
// 10. 把 ReusableCard 的定义移到 DistillerListPage **下方**，确认编译报错
//     "Class 'ReusableCard' used before its declaration."（依据 A:241）。
// ============================================================================
