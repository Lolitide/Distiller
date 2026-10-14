// 依据：API参考/ArkWeb_方舟Web/ArkTS_组件/Web/属性/arkts-basic-components-web-attributes.md（javaScriptProxy 属性）
// 依据：API参考/ArkWeb_方舟Web/ArkTS_组件/Web/Interfaces_其他/arkts-basic-components-web-i.md（JavaScriptProxy 接口）
// 依据：开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/前端页面调用应用侧函数/web-in-page-app-function-invoking.md
// 依据：开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/应用侧调用前端页面函数/web-in-app-frontend-page-function-invoking.md
// 依据：开发指南/ArkWeb_方舟Web/在应用中使用前端页面JavaScript/建立应用侧与前端页面数据通道/web-app-page-data-channel.md
// 依据：API参考/ArkWeb_方舟Web/ArkTS_API/ohos_web_webview_Webview_/Class_WebviewController/arkts-apis-webview-webviewcontroller.md
// 环境：HarmonyOS 6.0.2(22)；其中标注 26.0.0 的能力在本机未验证
// 说明：可直接抄进 entry/src/main/ets/ 的对应分层目录
//
// 落位：
//   · entry/src/main/ets/view/bridge/ReaderJsBridge.ets  ← 本文件的 bridge 类部分
//   · entry/src/main/ets/pages/ReaderWebPage.ets         ← 本文件的页面部分
//   · entry/src/main/resources/rawfile/reader.html       ← 本文件末尾的 HTML（原样存盘）
//
// 分层说明：页面 → ViewModel → service → repository。
//   ArkWeb 的 Web 组件属于 View 层，可以出现在页面里；
//   但页面**不直接**做业务处理 —— JS 桥接对象只把前端来的调用转发给 service，
//   自身不碰文件、网络、数据库。
//
// ============================================================================
// 取证块 1：javaScriptProxy —— 精确的属性名与参数（原文逐字照抄）
// ============================================================================
//
// 来源 A = C:\Users\x2027\.local\share\deveco-cli\docs\API参考\ArkWeb_方舟Web\ArkTS_组件\Web\属性\
//          arkts-basic-components-web-attributes.md
//
//   A:140   #### javaScriptProxy
//   A:142   javaScriptProxy(javaScriptProxy: JavaScriptProxy)
//   A:144   「将javaScriptProxy中的ArkTS对象注册到Web组件中，该对象将使用JavaScriptProxy中指定的名称
//            注册到网页的所有框架中，包括所有iframe，这使得JavaScript可以调用javaScriptProxy中
//            ArkTS对象的方法。当属性没有显式调用时，默认不将javaScriptProxy中的ArkTS对象注册到Web组件中。」
//   A:148   「javaScriptProxy接口需要和deleteJavaScriptRegister9+接口配合使用，防止内存泄漏。」
//   A:150   「javaScriptProxy对象的所有参数不支持更新。」
//   A:152   「注册javaScriptProxy对象时，同步与异步列表请至少选择一项不为空，可同时注册两类方法。」
//   A:154   「此接口只支持注册一个对象，若需要注册多个对象请使用registerJavaScriptProxy9+。」
//   A:162-165 参数表（逐字）
//     | 参数名          | 类型                                        | 必填 | 说明 |
//     | javaScriptProxy | [JavaScriptProxy](#javascriptproxy12)        | 是   | 传入undefined或null时不将javaScriptProxy中的ArkTS对象注册到Web组件中。 |
//   → 属性名就是 `javaScriptProxy`（全小写 j 开头，无驼峰），入参是一个 **JavaScriptProxy 对象**，
//     不是在属性上平铺若干参数。这是最容易记错的地方。
//
// 来源 B = C:\Users\x2027\.local\share\deveco-cli\docs\API参考\ArkWeb_方舟Web\ArkTS_组件\Web\
//          Interfaces_其他\arkts-basic-components-web-i.md
//
//   B:748   #### JavaScriptProxy12+
//   B:750   「定义要注入的JavaScript对象。」
//   B:752   **系统能力：** SystemCapability.Web.Webview.Core
//   B:754-768 字段表（逐字，含「只读」「可选」两列）
//     | 名称            | 类型                                          | 只读 | 可选 | 说明 |
//     | object          | object                                        | 否   | 否   | 参与注册的对象。只能声明方法，不能声明属性。 |
//     | name            | string                                        | 否   | 否   | 注册对象的名称，与window中调用的对象名一致。 |
//     | methodList      | Array<string>                                 | 否   | 否   | 参与注册的应用侧JavaScript对象的同步方法。 |
//     | controller      | WebController | WebviewController             | 否   | 否   | 控制器。从API version 9开始，WebController不再维护，建议使用WebviewController替代。 |
//     | asyncMethodList12+ | Array<string>                              | 否   | 是   | 参与注册的应用侧JavaScript对象的异步方法。异步方法无法获取返回值。 |
//     | permission12+   | string                                        | 否   | 是   | json字符串，默认为空，通过该字符串配置JSBridge的权限管控，
//     |                 |                                               |      |      | 可以定义object、method一级的url白名单。
//     |                 |                                               |      |      | JavaScriptProxy的permission参数支持resource/http/https协议，不支持file协议。 |
//   → 必填四个：object / name / methodList / controller；可选两个：asyncMethodList / permission。
//   → B:756 有一条容易忽略的硬限制：「只能声明方法，不能声明属性。」
//
// 来源 C = ...\前端页面调用应用侧函数\web-in-page-app-function-invoking.md
//   C:8     「注册应用侧代码有两种方式，一种在Web组件初始化调用，使用javaScriptProxy()接口。
//            另外一种在Web组件初始化完成后调用，使用registerJavaScriptProxy()接口。
//            两种方式都需要和deleteJavaScriptRegister接口配合使用，防止内存泄漏。」
//   C:14-15 import { webview } from '@kit.ArkWeb';
//           import { BusinessError } from '@kit.BasicServicesKit';
//   C:17-24 class TestClass {
//             constructor() { }
//             test(): string { return 'ArkTS Hello World!'; }
//           }
//   C:46-64 Web组件加载本地index.html页面
//             Web({ src: $rawfile('index1.html'), controller: this.webviewController})
//               // 将对象注入到web端
//               .javaScriptProxy({
//                 object: this.testObj,
//                 name: 'testObjName',
//                 methodList: ['test'],
//                 controller: this.webviewController,
//                 // 可选参数
//                 asyncMethodList: [],
//                 permission: '{"javascriptProxyPermission":{...}}'
//               })
//   C:255-271 index1.html（前端触发应用侧代码，逐字）
//             <!-- index1.html -->
//             <!DOCTYPE html>
//             <html>
//             <body>
//             <button type="button" onclick="callArkTS()">Click Me!</button>
//             <p id="demo"></p>
//             <script>
//                 function callArkTS() {
//                     let str = testObjName.test();
//                     document.getElementById("demo").innerHTML = str;
//                     console.info('ArkTS Hello World! :' + str);
//                 }
//             </script>
//             </body>
//             </html>
//   C:198-253 permission 是一个 JSON 字符串，结构为
//             { "javascriptProxyPermission": { "urlPermissionList": [...], "methodList": [...] } }
//             其中 scheme 精确匹配不能为空、host 精确匹配不能为空、port 精确匹配为空不检查、
//             path 前缀匹配为空不检查。
//
// ============================================================================
// 取证块 2：应用侧调用前端函数 —— runJavaScript（原文逐字照抄）
// ============================================================================
//
// 来源 D = ...\应用侧调用前端页面函数\web-in-app-frontend-page-function-invoking.md
//   D:4     「应用侧可以通过runJavaScript()和runJavaScriptExt()方法调用前端页面的JavaScript相关函数。」
//   D:6     「runJavaScript()和runJavaScriptExt()在参数类型上有以下差异：runJavaScriptExt()支持string和
//            ArrayBuffer类型参数，而runJavaScript()仅支持string类型参数。」
//   D:59    this.webviewController.runJavaScript('htmlTestParam(param)');
//   D:64    this.webviewController.runJavaScript('htmlTest()');
//   D:69-70 this.webviewController.runJavaScript(
//             `function changeColor(){document.getElementById('text').style.color = 'red'}`);
//   D:51    webview.WebviewController.setWebDebuggingAccess(true);
//
// 来源 E = ...\Class_WebviewController\arkts-apis-webview-webviewcontroller.md
//   E:1347  runJavaScript(script: string, callback : AsyncCallback<string>): void
//   E:1440  runJavaScript(script: string): Promise<string>
//   E:1532  runJavaScriptExt(script: string | ArrayBuffer, callback : AsyncCallback<JsMessageExt>): void
//   E:1752  runJavaScriptExt(script: string | ArrayBuffer): Promise<JsMessageExt>
//   E:1138  registerJavaScriptProxy(jsObject: object, name: string, methodList: Array<string>,
//                                    asyncMethodList?: Array<string>, permission?: string): void
//   E:1964  deleteJavaScriptRegister(name: string): void
//   E:2373  createWebMessagePorts(isExtentionType?: boolean): Array<WebMessagePort>
//   E:2420  postMessage(name: string, ports: Array<WebMessagePort>, uri: string): void
//
// 来源 F = ...\建立应用侧与前端页面数据通道\web-app-page-data-channel.md
//   F:4     「前端页面和应用侧之间可以用createWebMessagePorts()接口创建消息端口来实现两端的通信。」
//   F:37-40 1、创建两个消息端口。 this.ports = this.controller.createWebMessagePorts();
//           2、在应用侧的消息端口(如端口1)上注册回调事件。
//           this.ports[1].onMessageEvent((result: webview.WebMessage) => { ... })
//   F:58    3、将另一个消息端口(如端口0)发送到HTML侧，由HTML侧保存并使用。
//           this.controller.postMessage('__init_port__', [this.ports[0]], '*');
//   F:72    4、使用应用侧的端口给另一个已经发送到html的端口发送消息。
//           this.ports[1].postMessageEvent(this.sendFromEts);
//   F:86    5、关闭端口。 this.ports[0].close();
//   F:163   「检查传递的数据类型是否正确，WebMessage支持的数据类型有string和ArrayBuffer。」
//   F:176-178 「onControllerAttached与javaScriptOnDocumentStart的执行顺序是什么？
//              javaScriptOnDocumentStart在onControllerAttached之后执行。」
//
// 来源 G = ...\ohos_arkui_uiMaterial_系统材质_\arkts-apis-uimaterial.md「表1 特殊资源值对应的深浅色值」
//   （本文件用的 $r('sys.color.*') 出自此表；用资源色而非硬编码色值才能跟随深浅色模式）
//   G:303   | $r('sys.color.warning')         | #FFE84026 | #FFD94838 |
//   G:306   | $r('sys.color.font_secondary')  | #99000000 | #99FFFFFF |
//
// ============================================================================
// 未取证清单
// ============================================================================
// [U1] javaScriptProxy 在「应用侧注册了带 @Param/@Local 的组件实例方法」时的行为未取证。
//      B:756 只说 object「只能声明方法，不能声明属性」；文档没有说明传入一个 struct 实例
//      （而非普通 class 实例）是否可行。本文件因此用普通 class，照抄 C:17-24 的形态。
// [U2] asyncMethodList 中异步方法的**具体调用形态与返回值处理**未取证。
//      B:760 只说「异步方法无法获取返回值」。本文件因此只把确定无返回值的通知类方法
//      放进 asyncMethodList，需要返回值的一律放 methodList（同步）。
// [U3] permission 字段的**拒授权行为**（拒绝时前端 window 上是否还存在该对象、
//      调用时报什么错）未取证。C:198-253 只给了 JSON 结构，没有给拒授权后的表现。
//      本文件因此在示例里**不用** permission（保持可选参数缺省，即不做 url 白名单管控），
//      并在注释里给出该字段的完整结构供后续启用。
// [U4] runJavaScript 返回值 string 的**包装形式**未取证（Promise<string> 里的字符串是
//      求值结果本身，还是被 JSON 包装过）。E:1440 只给了签名。
//      本文件因此只用 runJavaScript 做「副作用调用」（触发前端函数），不解析其返回值。
// [U5] 26.0.0 相关能力在本机未验证（本文件未使用任何 26.0.0 API，此处仅为一致性声明）。

import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 应用侧要注入到前端的对象 —— 即 javaScriptProxy 的 object 字段。
 *
 * 三条硬约束（来自取证块 1）：
 *   1. B:756「只能声明方法，不能声明属性」→ 本类只有方法，没有 public 字段；
 *   2. A:150「javaScriptProxy对象的所有参数不支持更新」→ 这里的方法必须是**幂等**的、
 *      不依赖构造后被替换的状态；页面的当前状态通过 setContext 显式推进来也可以，
 *      但注意对象本身不会被重新注册；
 *   3. C:8 / A:148：必须配 deleteJavaScriptRegister，否则内存泄漏。
 *
 * 分层：本类只做「前端调用 → service」的转发与数据整形，不碰系统能力。
 */
export class ReaderJsBridge {
  /** 当前文档 id。前端只传「相对位置」，由应用侧决定落到哪篇文档上。 */
  private docId: string = '';
  /** 选中态变化回调，由页面注入 */
  private onSelection: (start: number, end: number, text: string) => void = () => {};
  /** 滚动位置回调 */
  private onScroll: (ratio: number) => void = () => {};

  setContext(docId: string,
    onSelection: (start: number, end: number, text: string) => void,
    onScroll: (ratio: number) => void): void {
    this.docId = docId;
    this.onSelection = onSelection;
    this.onScroll = onScroll;
  }

  /**
   * 同步方法（放进 methodList）：回传应用侧信息给前端。
   * 照抄 C:21-23 的签名形态：同步方法直接 return。
   *
   * 注意：WebView 的对象注入是在**子线程**语义下调用的，长耗时操作会卡住渲染，
   * 因此这里只做内存读。
   */
  getDocId(): string {
    return this.docId;
  }

  /** 同步方法：前端取「应用侧的主题色」，避免前端硬编码两套颜色。 */
  getThemeMode(): string {
    // 正式实现应来自 ViewModel / AppStorage；此处返回占位值
    return 'light';
  }

  /**
   * 前端 → 应用侧：选中文本发生变化。
   * 放 methodList（同步）：需要让前端拿到「是否被接受」的即时反馈。
   */
  onSelectionChange(start: number, end: number, text: string): boolean {
    if (end <= start) {
      return false;
    }
    // 只转发，不做业务
    this.onSelection(start, end, text);
    return true;
  }

  /**
   * 前端 → 应用侧：滚动位置变化。高频调用。
   * 未取证 [U2]：放进 asyncMethodList 的调用形态与错误处理未取证。
   * 因此这里仍放 methodList，但在页面侧做节流。
   */
  onScrollChange(ratio: number): void {
    this.onScroll(ratio);
  }

  /**
   * 前端 → 应用侧：请求应用侧打开一张蒸馏卡片。
   * 返回 true 表示已受理；真正的业务由 service 层完成，前端不等待结果。
   */
  requestOpenCard(cardId: string): boolean {
    if (cardId.length === 0) {
      return false;
    }
    // 正式实现：service.distill.openCard(this.docId, cardId)
    console.info(`[ReaderJsBridge] requestOpenCard doc=${this.docId} card=${cardId}`);
    return true;
  }

  /** 前端 → 应用侧：前端发生不可恢复的错误，记日志即可。 */
  reportFrontendError(message: string): void {
    console.error(`[ReaderJsBridge] frontend error: ${message}`);
  }
}

/**
 * 阅读页：Web 渲染正文 + 双向 JS 桥。
 *
 * 落位：entry/src/main/ets/pages/ReaderWebPage.ets
 *
 * 桥的两条方向：
 *   · 前端 → 应用侧：javaScriptProxy 注册 window.distiller（见 build 里的 .javaScriptProxy）
 *   · 应用侧 → 前端：webviewController.runJavaScript(...)
 */
@Entry
@ComponentV2
struct ReaderWebPage {
  private webviewController: webview.WebviewController = new webview.WebviewController();

  /**
   * 注入到前端的桥对象。
   *
   * 为什么**不用** @Local/@State：
   *   A:150「javaScriptProxy对象的所有参数不支持更新」—— 注册后不会再读取新的对象引用，
   *   加状态装饰器只会造成「改了 UI 以为桥也改了」的误解。官方示例用 @State 是因为那是 V1 写法，
   *   并不代表需要响应式。
   */
  private bridge: ReaderJsBridge = new ReaderJsBridge();

  // ---- 页面状态（全部 V2） ----
  @Local docTitle: string = '被蒸馏的文章';
  @Local selectionText: string = '';
  @Local scrollPercent: number = 0;
  @Local lastError: string = '';

  /** 节流用的上一次上报时间戳（ms） */
  private lastScrollReport: number = 0;

  aboutToAppear(): void {
    // 依据 D:51 开启 Web 调试（开发期开，发布前关）
    webview.WebviewController.setWebDebuggingAccess(true);

    // 把回调注入桥对象。注意桥对象本身不会被重新注册（A:150），
    // 所以回调走「方法调用」而不是「替换对象」。
    this.bridge.setContext(
      'doc-001',
      (start: number, end: number, text: string) => {
        this.selectionText = text;
        // 正式实现：转发给 service，由 service 决定是否落库
      },
      (ratio: number) => {
        const now: number = Date.now();
        // 前端每次滚动都回调，这里做 200ms 节流，避免高频刷新 UI
        if (now - this.lastScrollReport < 200) {
          return;
        }
        this.lastScrollReport = now;
        this.scrollPercent = Math.round(ratio * 100);
      }
    );
  }

  aboutToDisappear(): void {
    // 依据 A:148 / C:8：「javaScriptProxy接口需要和deleteJavaScriptRegister接口配合使用，
    // 防止内存泄漏。」名称必须与注册时的 name 完全一致。
    try {
      this.webviewController.deleteJavaScriptRegister('distiller');
    } catch (error) {
      // 官方 catch 写法：error as BusinessError（见 web-in-page-app-function-invoking.md:40-43）
      const be: BusinessError = error as BusinessError;
      console.error(`[ReaderWebPage] deleteJavaScriptRegister failed: ${be.code} ${be.message}`);
    }
  }

  /**
   * 应用侧 → 前端：高亮某个蒸馏片段。
   *
   * 依据 D:59/D:64：runJavaScript 的入参是**一段 JS 源码字符串**，
   * 所以应用侧是在「生成并执行代码」，不是「调用一个函数名」。
   * 依据 E:1440：返回 Promise<string>；本方法不解析返回值（未取证 [U4]），
   * 只把执行失败记下来。
   *
   * 参数拼接注意：字符串直接拼进 JS 源码有注入风险，必须经过 JSON.stringify。
   */
  private highlightInFrontend(cardId: string, color: string): void {
    // JSON.stringify 保证 id/color 作为 JS 字面量被安全嵌入
    const script: string =
      `window.__distiller && window.__distiller.highlight(${JSON.stringify(cardId)}, ${JSON.stringify(color)});`;
    this.webviewController.runJavaScript(script)
      .then((result: string) => {
        console.info(`[ReaderWebPage] highlight ok: ${result}`);
      })
      .catch((err: BusinessError) => {
        this.lastError = `高亮失败 ${err.code}`;
        console.error(`[ReaderWebPage] highlight failed: ${err.code} ${err.message}`);
      });
  }

  /** 应用侧 → 前端：让前端滚到指定比例 */
  private scrollFrontendTo(ratio: number): void {
    const script: string = `window.__distiller && window.__distiller.scrollTo(${ratio});`;
    this.webviewController.runJavaScript(script).catch((err: BusinessError) => {
      console.error(`[ReaderWebPage] scrollTo failed: ${err.code} ${err.message}`);
    });
  }

  build() {
    Column() {
      // ---- 顶部状态条：把桥的两个方向都摊开，便于真机验证 ----
      Column({ space: 4 }) {
        Text(this.docTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')
        Text(`滚动 ${this.scrollPercent}%　选中：${this.selectionText.length > 0 ? this.selectionText : '（无）'}`)
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'))
          .width('100%')
        if (this.lastError.length > 0) {
          Text(this.lastError)
            .fontSize(12)
            .fontColor($r('sys.color.warning'))
            .width('100%')
        }
      }
      .width('100%')
      .padding(12)

      // ---- 应用侧 → 前端 的两个按钮 ----
      Row({ space: 8 }) {
        Button('高亮第 1 张卡片')
          .fontSize(12)
          .onClick(() => {
            this.highlightInFrontend('card-1', '#FFB300');
          })
        Button('滚到 50%')
          .fontSize(12)
          .onClick(() => {
            this.scrollFrontendTo(0.5);
          })
        Button('回顶部')
          .fontSize(12)
          .onClick(() => {
            this.scrollFrontendTo(0);
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 8 })

      // ---- Web 组件 + 注入桥 ----
      Web({ src: $rawfile('reader.html'), controller: this.webviewController })
        .width('100%')
        .layoutWeight(1)
        // 依据 C:46-64：Web 组件初始化时注册。属性名是 javaScriptProxy（全小写 j）。
        // 依据 B:754-768：JavaScriptProxy 的必填四字段 object / name / methodList / controller。
        .javaScriptProxy({
          object: this.bridge,             // 只能含方法，不能含属性（B:756）
          name: 'distiller',               // = 前端 window.distiller
          // 同步方法列表，前端可直接拿返回值
          methodList: [
            'getDocId',
            'getThemeMode',
            'onSelectionChange',
            'onScrollChange',
            'requestOpenCard',
            'reportFrontendError'
          ],
          controller: this.webviewController,
          // 依据 A:152：「同步与异步列表请至少选择一项不为空」—— methodList 已非空。
          // 本示例的 asyncMethodList 保持空数组；若要把 reportFrontendError 改成异步，
          // 未取证 [U2]，需先补证异步方法的调用形态。
          asyncMethodList: []
          // 依据 A:162-165 / B:761-764：permission 是可选 JSON 字符串，用于 url 白名单。
          // 未取证 [U3]：拒授权后的表现未取证，故本示例不启用。
          // 启用时的完整结构（来源 C:200-253）：
          //   {
          //     "javascriptProxyPermission": {
          //       "urlPermissionList": [            // Object级权限，匹配则所有Method都授权
          //         { "scheme": "resource", "host": "rawfile", "port": "", "path": "" }
          //       ],
          //       "methodList": [
          //         { "methodName": "getDocId",
          //           "urlPermissionList": [
          //             { "scheme": "resource", "host": "rawfile", "port": "", "path": "" }
          //           ] }
          //       ]
          //     }
          //   }
          // 注意（B:764）：「JavaScriptProxy的permission参数支持resource/http/https协议，不支持file协议。」
        })
        .onPageEnd(() => {
          // 兜底：页面每次加载完，应用侧主动把主题推一次，
          // 避免前端在 document 刚就绪时拿到过期值。
          const script: string =
            `window.__distiller && window.__distiller.setTheme(${JSON.stringify('light')});`;
          this.webviewController.runJavaScript(script).catch((err: BusinessError) => {
            console.error(`[ReaderWebPage] setTheme failed: ${err.code} ${err.message}`);
          });
        })
    }
    .width('100%')
    .height('100%')
  }
}

// ============================================================================
// 前端页面：entry/src/main/resources/rawfile/reader.html
// 原样另存为独立文件；这里以注释形式保留全文，便于对照两端的契约。
//
// <!-- reader.html -->
// <!DOCTYPE html>
// <html>
// <head>
//   <meta charset="utf-8">
//   <meta name="viewport" content="width=device-width, initial-scale=1.0">
//   <title>reader</title>
//   <style>
//     body { font: 16px/1.7 -apple-system, "HarmonyOS Sans", sans-serif; margin: 0; padding: 16px; }
//     p { margin: 0 0 16px; }
//     .hl { background: #FFB300; border-radius: 3px; }
//     #bar { position: fixed; left: 0; right: 0; bottom: 0; padding: 8px 16px;
//            background: rgba(0,0,0,.06); font-size: 12px; }
//   </style>
// </head>
// <body>
//   <div id="content">
//     <p id="p1">先给结论：把一章压成三句话，比读三遍更有效。</p>
//     <p id="p2">依据来自原文第三节：提取动作本身就是一次再编码。</p>
//     <p id="p3">行动项：今天挑一节试一次，写完再回看。</p>
//   </div>
//   <div id="bar">
//     应用侧文档 id：<span id="docId">-</span>
//     ｜ 主题：<span id="theme">-</span>
//     ｜ 最后受理的卡片：<span id="lastCard">-</span>
//   </div>
//
//   <script>
//     // ---------------------------------------------------------------------
//     // 应用侧提供的对象挂载在 window.distiller（名字 = javaScriptProxy 的 name 字段）
//     // ---------------------------------------------------------------------
//     function bridgeReady() {
//       return typeof window.distiller !== 'undefined' && window.distiller !== null;
//     }
//
//     // ---- 前端 → 应用侧：同步方法，直接拿返回值（对应 methodList） ----
//     function pullAppState() {
//       if (!bridgeReady()) {
//         document.getElementById('docId').textContent = 'bridge 未注入';
//         return;
//       }
//       // getDocId() 是同步方法，返回值即 ArkTS 的 string
//       document.getElementById('docId').textContent = window.distiller.getDocId();
//       document.getElementById('theme').textContent = window.distiller.getThemeMode();
//     }
//
//     // ---- 前端 → 应用侧：把选中文本回传 ----
//     document.addEventListener('selectionchange', function () {
//       if (!bridgeReady()) { return; }
//       var sel = window.getSelection();
//       if (!sel || sel.rangeCount === 0) { return; }
//       var text = sel.toString();
//       if (text.length === 0) { return; }
//       // onSelectionChange(start, end, text) -> boolean
//       var accepted = window.distiller.onSelectionChange(sel.anchorOffset, sel.focusOffset, text);
//       if (!accepted) {
//         console.info('selection rejected by app');
//       }
//     });
//
//     // ---- 前端 → 应用侧：滚动比例。高频，应用侧有节流 ----
//     window.addEventListener('scroll', function () {
//       if (!bridgeReady()) { return; }
//       var doc = document.documentElement;
//       var max = doc.scrollHeight - doc.clientHeight;
//       var ratio = max > 0 ? doc.scrollTop / max : 0;
//       window.distiller.onScrollChange(ratio);
//     });
//
//     // ---- 前端 → 应用侧：点段落时请求应用侧打开对应蒸馏卡片 ----
//     document.querySelectorAll('p').forEach(function (p, i) {
//       p.addEventListener('click', function () {
//         if (!bridgeReady()) { return; }
//         var cardId = 'card-' + (i + 1);
//         var ok = window.distiller.requestOpenCard(cardId);
//         if (ok) {
//           document.getElementById('lastCard').textContent = cardId;
//         }
//       });
//     });
//
//     // ---- 前端 → 应用侧：错误上报 ----
//     window.addEventListener('error', function (e) {
//       if (bridgeReady()) {
//         window.distiller.reportFrontendError(String(e.message));
//       }
//     });
//
//     // ---------------------------------------------------------------------
//     // 应用侧 → 前端：由 runJavaScript 调用的入口。
//     // 注意：应用侧执行的是 JS **源码字符串**，所以这些函数必须挂在 window 上。
//     // ---------------------------------------------------------------------
//     window.__distiller = {
//       // 高亮某张卡片对应的段落
//       highlight: function (cardId, color) {
//         var index = parseInt(String(cardId).replace('card-', ''), 10);
//         var p = document.getElementById('p' + index);
//         if (!p) { return false; }
//         p.classList.add('hl');
//         if (color) { p.style.background = color; }
//         // 顺带回传一次，让应用侧知道高亮生效了
//         if (bridgeReady()) {
//           window.distiller.onScrollChange(0);
//         }
//         return true;
//       },
//       // 滚到指定比例
//       scrollTo: function (ratio) {
//         var doc = document.documentElement;
//         var max = doc.scrollHeight - doc.clientHeight;
//         doc.scrollTop = max * ratio;
//         return doc.scrollTop;
//       },
//       // 主题（应用侧在 onPageEnd 里推一次）
//       setTheme: function (mode) {
//         document.body.dataset.theme = mode;
//         document.getElementById('theme').textContent = mode;
//         return true;
//       }
//     };
//
//     // 页面就绪后主动拉一次应用侧状态
//     pullAppState();
//   </script>
// </body>
// </html>
//
// ============================================================================
// 高吞吐场景的替代方案：数据通道（来源 F）
//
// javaScriptProxy 适合「前端调应用侧的函数」；如果两端要**持续大量**互推数据
// （例如前端把整篇正文的分词结果按块推给应用侧），应该改用 MessagePort：
//
//   // 应用侧（依据 F:37-58）
//   this.ports = this.controller.createWebMessagePorts();
//   this.ports[1].onMessageEvent((result: webview.WebMessage) => {
//     if (typeof (result) === 'string') { /* string */ }
//     else if (result instanceof ArrayBuffer) { /* ArrayBuffer */ }
//   });
//   this.controller.postMessage('__init_port__', [this.ports[0]], '*');
//
//   // 应用侧发消息（依据 F:72）
//   this.ports[1].postMessageEvent(this.sendFromEts);
//
//   // 用完关闭（依据 F:86）
//   this.ports[0].close();
//
//   // 前端（依据 F:118-154）
//   window.addEventListener('message', function (event) {
//     if (event.data === '__init_port__') { h5Port = event.ports[0]; /* ... */ }
//   });
//   function PostMsgToEts(data) { h5Port.postMessage(data); }
//
// 两条限制（依据 F:163、F:176-178）：
//   · WebMessage 支持的数据类型只有 string 和 ArrayBuffer；
//     要传对象必须先 JSON.stringify（前端侧用 JSON.stringify，应用侧用 JSON.parse）。
//   · javaScriptOnDocumentStart 在 onControllerAttached **之后**执行。
//
// 建议的分工：
//   · 函数调用 / 少量控制信令 → javaScriptProxy + runJavaScript（本文件主体）
//   · 大块数据 / 流式推送     → MessagePort
// ============================================================================

// ============================================================================
// 真机验证清单（本项目只有 6.0.2(22) 真机）
//
// 1. 打开阅读页，确认底部状态条上「应用侧文档 id」显示 doc-001，
//    说明 javaScriptProxy 注入成功（若显示「bridge 未注入」则 name/object 有问题）。
// 2. 在正文里选中一段文字，确认顶部状态条的「选中：」实时更新（前端 → 应用侧）。
// 3. 上下滚动，确认「滚动 N%」更新，且没有明显掉帧（说明节流生效）。
// 4. 点击「高亮第 1 张卡片」，确认第 1 段背景变黄（应用侧 → 前端）。
//    同时观察日志里 highlight ok 的输出。
// 5. 点击「滚到 50%」「回顶部」，确认正文真的滚动。
// 6. 点击正文第 2 段，确认底部「最后受理的卡片」显示 card-2。
// 7. 连点 20 次「高亮第 1 张卡片」，确认无内存持续增长（deleteJavaScriptRegister 生效）。
// 8. 按返回键离开本页，确认 aboutToDisappear 里 deleteJavaScriptRegister 不抛异常。
// 9. 用 DevTools 调试验证通道：依据 C:833-841，打开 web 调试后可在 DevTools 里
//    看到注入的对象与方法列表。
// 10. 故意把 name 从 'distiller' 改成 'distillerX' 但前端仍调 window.distiller，
//     确认前端报 "bridge 未注入"（验证 name 与 window 对象名必须一致）。
// 11. 故意把某个方法从 methodList 里删掉但前端仍调用，
//     确认该调用失败（验证 methodList 是白名单而不是自动发现）。
// ============================================================================
