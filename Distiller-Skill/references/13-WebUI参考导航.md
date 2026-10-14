<!-- 手写文档（非生成物）：改这个文件本身，不会被 tools\build-references.ps1 覆盖 -->

# 13 · WebUI 参考导航（ArkWeb / Web 组件）

> **「WebUI」在本技能里特指 ArkWeb**（`@kit.ArkWeb` + `Web` 组件 + `WebviewController`），
> 不是泛指的"用 Web 技术做界面"，也不含元服务的 `AtomicServiceEnhancedWeb`、不含 NDK 侧的 ArkWeb C API 之外的其它 Web 容器。
> 本文里出现「WebUI」的地方，一律等同于「ArkWeb 混合开发」。

**回答什么**：想在鸿蒙应用里用 HTML/CSS/JS 搭界面或嵌网页 —— 从哪入手、官方文档里有什么。
**路径约定**：一律相对 `references\official\`。**逐条 `Test-Path` 验证过**：开发指南 61/61、API参考+最佳实践 54/54、FAQ 24/24。
> 这些命中数是**生成这份副本的那台机器**在 2026-10-12 核对的；文档库快照后来换成了 devecocli 1.3.4 的 `docs.zip`（md 14,686 篇），
> 你自己机器上的库路径与快照版本都可能不同 —— 判定方法见 `09-文档新鲜度与升级.md`。**改动本技能引用的路径后，务必重跑一次全量 `Test-Path`。**
**slug 陷阱**：简介 = `web-component-overview`，加载页面 = `web-page-loading-with-web-components`，术语 = `arkweb-glossary`；另有两篇用**下划线**而非连字符：`ArkWeb进程/web_component_process.md`、`使用网页多媒体/Web组件支持视频沉浸式全屏播放/web_full_screen.md`。

## 一、什么时候用这条路

官方定位（`official/开发指南/ArkWeb_方舟Web/ArkWeb简介/web-component-overview.md`）：Web 组件用于在应用中显示 Web 页面内容；场景 = 集成 Web 页面以降低开发成本 / 浏览器 / 小程序宿主。

| 维度 | 偏 ArkWeb | 偏原生 ArkUI |
| :-- | :-- | :-- |
| 前端资产 | 复用已有 Vue/React 页面（先 `npm run build`，再按本地或网络页面加载 —— `faqs-arkweb-38`） | 从零构建 |
| 迭代节奏 | 前端可独立改版、换离线包 | 与 HAP 发版绑定 |
| 交互深度 | 展示型 + 轻交互 | 手势族 / 同层渲染 / 沉浸光感 / 无障碍语义 / 动效连续性 |

| 成本项 | 事实 | 出处（相对 `official/`） |
| :-- | :-- | :-- |
| 权限 | 访问**在线**网页必须声明 `ohos.permission.INTERNET`（`module.json5` → `requestPermissions`） | `开发指南/ArkWeb_方舟Web/ArkWeb简介/web-component-overview.md` |
| 内存 | Web 组件依赖的 so ≈200 MB；页面级「几百兆到 1 GB」属正常 | `FAQ/Web框架/Web开发_ArkWeb/Web组件的内存占用与内存回收机制/faqs-arkweb-93.md` |
| 加载耗时 | 瓶颈 = 网络连接 / 资源加载 / JS 编译执行；优化项含预启动渲染进程、预解析预连接、预下载、预渲染、Code Cache、离线资源免拦截注入、资源拦截替换加速、JSBridge 优化、同层渲染 | `FAQ/Web框架/Web开发_ArkWeb/Web加载网页性能提升方式与使用场景总结/faqs-arkweb-185.md` |
| 内核 | 基于 Chromium；6.0 默认 M132（可回退 M114），目标 `6.0.2(22)` 落在该行；本 Kit 支持模拟器 | `开发指南/ArkWeb_方舟Web/ArkWeb简介/web-component-overview.md` |

## 二、导航 · 开发指南 `official/开发指南/ArkWeb_方舟Web/`（61 篇全覆盖）

行内路径省略上面这个前缀；`▸` 后面的路径再接该行给出的目录前缀。顺序即建议阅读顺序。

| # | 主题组 | 目录 / slug | 为什么读 |
| :-- | :-- | :-- | :-- |
| ① | 入门 / 术语 / 进程 | `ArkWeb简介/web-component-overview.md`、`ArkWeb术语/arkweb-glossary.md`、`ArkWeb进程/web_component_process.md` | 起点；能力范围、INTERNET 权限、Chromium 版本表 |
| ② | 生命周期 | `Web组件的生命周期/web-event-sequence.md` | onPageBegin/onPageEnd 时序，决定加载状态怎么摆 |
| ③ | 渲染与布局 | **`Web渲染和布局/`** ▸ `Web组件渲染模式/web-render-mode.md`、`Web组件大小自适应页面内容布局/web-fit-content.md`、`优化跳转至新Web组件过程中的页面闪烁现象/web-router-flash-optimization.md`、`获取网页内容高度/web-getpage-height.md` | 渲染模式选型；高度自适应与跳转闪烁 |
| ④ | 基本属性与事件 | **`设置基本属性和事件/`** ▸ `User-Agent开发指导/web-default-useragent.md`、`Web深色模式适配/web-set-dark-mode.md`、`管理Cookie及数据存储/web-cookie-and-data-storage-mgmt.md`、`使用隐私模式/web-incognito-mode.md`、`在新窗口中打开页面/web-open-in-new-window.md`、`管理位置权限/web-geolocation-permission.md`、`使用运动和方向传感器监测设备状态/web-sensor.md` | UA / Cookie / 深色模式是接 H5 必改三件事 |
| ⑤ | 加载与浏览记录 | **`管理网页加载与浏览记录/`** ▸ `使用Web组件加载页面/web-page-loading-with-web-components.md`、`管理页面跳转及浏览记录导航/web-redirection-and-browsing-history-mgmt.md`、`加速Web页面的访问/web-predictor.md`、`拦截Web组件发起的网络请求/web-scheme-handler.md`、`自定义页面请求响应/web-resource-interception-request-mgmt.md`、`设置Web组件前进后退缓存/web-set-back-forward-cache.md`、`Web组件在不同的窗口间迁移/web-component-migrate.md` | 加载页面是总入口（含 resource 协议加载本地资源） |
| ⑥ | 前端页面 JS 互调 | **`在应用中使用前端页面JavaScript/`** ▸ `前端页面调用应用侧函数/web-in-page-app-function-invoking.md`、`应用侧调用前端页面函数/web-in-app-frontend-page-function-invoking.md`、`建立应用侧与前端页面数据通道/web-app-page-data-channel.md`、`应用侧与前端页面的相互调用_C_C/arkweb-ndk-jsbridge.md`、`建立应用侧与前端页面数据通道_C_C/arkweb-ndk-page-data-channel.md` | JSBridge 主战场：Proxy 单向、WebMessagePort 双向，后两篇是 C/C++ 通道 |
| ⑦ | 同层渲染 | `同层渲染/同层渲染/web-same-layer.md`、`同层渲染原生组件/same-layer-rendering-native-component.md` | Web 嵌原生，把高性能组件换成系统组件 |
| ⑧ | 离线 Web 组件 | `使用离线Web组件/web-offline-mode.md` | 离线包与免拦截注入；本地资源跨域的正解入口 |
| ⑨ | 网页多媒体 | **`使用网页多媒体/`** ▸ `Web组件支持画中画/web-picture-in-picture.md`、`Web组件支持视频沉浸式全屏播放/web_full_screen.md`、`在Web中打开摄像头和麦克风/web-rtc.md`、`托管网页中的媒体播放/app-takeovers-web-media.md` | 全屏 / 画中画 / WebRTC / 媒体播放托管 |
| ⑩ | 文件上传下载 | **`管理网页文件上传与下载/`** ▸ `使用Web组件上传文件/web-file-upload.md`、`使用Web组件的下载能力/web-download.md` | 上传下载走应用侧代理，不是浏览器默认行为 |
| ⑪ | 网页交互 | **`管理网页交互/`** ▸ `Web组件对接软键盘/web-docking-softkeyboard.md`、`Web组件嵌套滚动/web-nested-scrolling.md`、`Web页面显示内容滚动/web-content-scrolling.md`、`使用Web组件的手势与应用交互/web-gesture.md`、`使用Web组件的拖拽功能与网页交互/web-drag.md`、`使用Web组件管理网页缩放/web-scale-zoom.md`、`使用Web组件显示网页弹框/web-dialog.md`、`Web组件焦点管理/web-focus.md`、`Web应用模拟点击检测/web-detect-simulated-click-risk-enhanced.md` | 软键盘 / 嵌套滚动 / 焦点是三大高频缺陷区 |
| ⑫ | 网页内容处理 | **`处理网页内容/`** ▸ `使用Web组件菜单处理网页内容/web-menu.md`、`使用Web组件与系统剪贴板交互处理网页内容/web-clipboard.md`、`使用Web组件保存前端页面为PDF/web-createpdf.md`、`使用Web组件打印前端页面/web-print.md`、`使用Web组件的PDF文档预览能力/web-pdf-preview.md`、`使用Web组件的智能分词能力/web-data-detector.md`、`网页中安全区域计算和避让适配/web-safe-area-insets.md` | 菜单 / 剪贴板 / PDF；末篇管挖孔与状态栏避让 |
| ⑬ | 调试维测 | **`Web调试维测/`** ▸ `使用DevTools工具调试前端页面/web-debugging-with-devtools.md`、`定位与解决Web白屏问题/web-white-screen.md`、`使用Crashpad收集Web组件崩溃信息/web-crashpad.md`、`使用Hypium实现ArkWeb自动化测试/web-hypium-autotests.md` | 白屏一律先读 `web-white-screen` |
| ⑭ | 网络与隐私安全 | **`管理Web组件的网络安全与隐私/`** ▸ `解决Web组件本地资源跨域问题/web-cross-origin.md`、`使用Web组件的广告过滤功能/web-adsblock.md`、`使用智能防跟踪功能/web-intelligent-tracking-prevention.md`、`坚盾守护模式/web-secure-shield-mode.md` | 本地资源跨域是离线方案必踩；后三篇为合规常问项 |
| ⑮ | 浏览器扩展通信 | `使用WebNativeMessagingExtensionAbility组件实现浏览器扩展和应用通信场景/web-native-messaging.md` | 仅做浏览器 / 扩展宿主才需要 |

### API 参考 `official/API参考/ArkWeb_方舟Web/`（101 篇，4 棵子树）

| 子树 | 关键入口（前缀 = `API参考/ArkWeb_方舟Web/`） | 为什么读 |
| :-- | :-- | :-- |
| `ArkTS_组件/Web/` 属性与事件 | `ArkTS_组件/Web/组件描述/arkts-basic-components-web.md`、`ArkTS_组件/Web/属性/arkts-basic-components-web-attributes.md`、`ArkTS_组件/Web/事件/arkts-basic-components-web-events.md`、`ArkTS_组件/Web/Enums/arkts-basic-components-web-e.md`、`ArkTS_组件/Web/Types/arkts-basic-components-web-t.md` | Web 组件属性/事件/枚举的单一真值源，写 `.ets` 先查这里 |
| `ArkTS_组件/Web/` 回调类 | `ArkTS_组件/Web/Class_WebController/arkts-basic-components-web-webcontroller.md`、`ArkTS_组件/Web/Class_JsResult/arkts-basic-components-web-jsresult.md`、`ArkTS_组件/Web/Class_WebResourceRequest/arkts-basic-components-web-webresourcerequest.md`、`ArkTS_组件/Web/Class_WebResourceResponse/arkts-basic-components-web-webresourceresponse.md` | 写 JSProxy / 拦截时逐个对签名 |
| `ArkTS_API/ohos_web_webview_Webview_/` | `ArkTS_API/ohos_web_webview_Webview_/模块描述/arkts-apis-webview.md`、`ArkTS_API/ohos_web_webview_Webview_/Class_WebviewController/arkts-apis-webview-webviewcontroller.md`、`ArkTS_API/ohos_web_webview_Webview_/Class_WebCookieManager/arkts-apis-webview-webcookiemanager.md`、`ArkTS_API/ohos_web_webview_Webview_/Interface_WebMessagePort/arkts-apis-webview-webmessageport.md`、`ArkTS_API/ohos_web_webview_Webview_/Class_WebSchemeHandler/arkts-apis-webview-webschemehandler.md`、`ArkTS_API/ohos_web_netErrorList_ArkWeb网络协议栈错误列表_/arkts-apis-neterrorlist.md`、`错误码/Webview错误码/errorcode-webview.md` | 命令式接口全量：UA / Cookie / 缓存 / 拦截 / 端口通信；末两篇查网络栈错误与 17100001 等错误码 |
| `C_API/` | `C_API/模块/Web/capi-web.md`、`C_API/头文件/native_interface_arkweb_h/capi-native-interface-arkweb-h.md`、`C_API/头文件/arkweb_type_h/capi-arkweb-type-h.md`、`C_API/头文件/arkweb_scheme_handler_h/capi-arkweb-scheme-handler-h.md` | 仅 NAPI / C++ 侧 JSBridge 需要；纯 ArkTS 项目可整树跳过 |

### 最佳实践与性能 / 稳定性（相对 `official/`，优先看这三篇）

| 主题 | 文件 | 为什么读 |
| :-- | :-- | :-- |
| Hybrid 架构与同层渲染 | `最佳实践/ArkWeb/ArkWeb渲染框架适配/bpta-arkweb_rendering_framework.md`、`最佳实践/ArkWeb/同层渲染原生组件/bpta-render-web-using-same-layer-render.md` | 官方对 Hybrid 的定义：Ark 进程 + Webview 进程 + JSBridge；组件鸿蒙化走同层渲染 |
| 加载性能优化 | `最佳实践/性能场景优化案例/Web性能优化/Web加载性能优化/bpta-web-develop-optimization.md`、`最佳实践/性能分析/Web加载完成时延分析/bpta-web-completion-delay-analysis.md`、`最佳实践/性能分析/Web帧率问题分析/bpta-web-frame-rate-performance-analysis.md` | 预启动 / 预连接 / 预渲染 / Code Cache 完整清单 + 首屏耗时与卡顿的定量方法；`faqs-arkweb-185` 指向它们 |
| 安全、拦截、跨域、跳转、冻屏 | `最佳实践/ArkWeb组件安全开发/bpta-arkweb-component-security.md`、`最佳实践/ArkWeb/Web组件拦截能力的使用/bpta-web-interceptor.md`、`最佳实践/ArkWeb/Web页面跨域解决方案/bpta-cross-domain-solutions-for-web-pages.md`、`最佳实践/程序框架/Web和应用的跳转与拉起/bpta-web-app-jump-and-pull-up.md`、`最佳实践/稳定性分析/稳定性故障模式说明/应用冻屏故障模式说明/ArkWeb_GPU进程卡死故障模式说明/bpta-arkweb-gpu-freeze.md` | JSProxy 暴露面基线；拦截接口选型；本地+网络混用跨域；网页 ↔ 应用双向跳转；Web 冻屏官方归因 |

## 三、导航 · FAQ `official/FAQ/Web框架/Web开发_ArkWeb/`（163 篇，挑 16 篇）

目录名 = 问题原文（部分字符被替换成 `_`），文件名是 `faqs-arkweb-<编号>.md`。**注意最新那篇 slug 不是数字**：`faqs-arkweb-kit-new-00001.md`。

| 主题 | 目录 / slug（前缀 = `FAQ/Web框架/Web开发_ArkWeb/`） | 为什么读 |
| :-- | :-- | :-- |
| Vue/React 支持 | `Web组件对H5页面_常用框架VUE_React的页面支持情况_包括本地和网络端的页面/faqs-arkweb-38.md` | 明确「支持」；`npm run build` 后按本地/网络页面加载 |
| Vue/React 适配做法 | `如何实现Web和Webview对前端常用框架_如Vue_React_的适配/faqs-arkweb-35.md` | 上面那篇的动手版 |
| H5 适配总指导 | `H5适配HarmonyOS开发指导/faqs-arkweb-179.md` | 搬既有 H5 过来的 checklist |
| 加载性能全表 | `Web加载网页性能提升方式与使用场景总结/faqs-arkweb-185.md` | 各优化项收益与适用场景对照，选型阶段最值一篇 |
| 内存占用与回收 | `Web组件的内存占用与内存回收机制/faqs-arkweb-93.md` | so ≈200MB 与 `trimMemoryByPressureLevel` 的原始口径 |
| 白屏（通例） | `如何解决Web加载H5页面时出现的白屏问题/faqs-arkweb-174.md` | 白屏第一入口 |
| 白屏（内嵌定位） | `如何调试定位应用内嵌H5白屏问题/faqs-arkweb-kit-new-00001.md` | 最新一篇，专治内嵌场景 |
| 白屏（现象定位） | `Web组件加载某个页面_出现白屏_页面显示不出来_如何解决和定位/faqs-arkweb-19.md` | 按现象分支的排查树 |
| 离线加载白屏 | `如何解决webview离线加载白屏问题/faqs-arkweb-56.md` | 走离线包方案必读 |
| 第三方内核 | `是否支持使用第三方的webview内核/faqs-arkweb-49.md` | 决定选型边界：能不能换内核 |
| 动态创建性能 | `动态创建web组件应该在什么场景下使用_性能如何/faqs-arkweb-52.md` | 静态声明 vs 动态创建 |
| 首屏后滑动卡顿 | `如何解决Web组件首次加载完网页立即滑动发生明显卡顿问题/faqs-arkweb-134.md` | 冷启动后立刻滑动 |
| 改高度卡顿 | `Web组件频繁改变高度卡顿/faqs-arkweb-140.md` | 高度跟随内容变化的代价 |
| JSBridge vs 端口 | `WebView中_双向交互可以使用JSBridge技术_也可以使用端口通信技术_这两者有什么区别/faqs-arkweb-11.md` | 互调方案二选一的判据 |
| JSProxy 权限报错 | `Web组件使用JavaScriptProxy注入JsBridge对象时_Jsb_Permission_Denied报错如何解决/faqs-arkweb-160.md` | 注入 JSBridge 时必踩 |
| 浮层被遮挡 / 触摸穿透 | `如何解决应用侧浮层被Web遮挡及触摸事件穿透问题/faqs-arkweb-198.md` | Web 与 ArkUI 弹层共存时的层级与事件 |

按需另查：`Web组件的请求拦截接口使用场景总结/faqs-arkweb-195.md`、`如何实现Web组件在折叠屏上分栏展示/faqs-arkweb-194.md`、`系统目前是否支持webrtc的功能_规格是什么/faqs-arkweb-64.md`、`通过网页拉起摄像头_麦克风实现拍照_录音录像_视频通话和拉起图库等功能/faqs-arkweb-131.md`、`Web组件如何正确设置User-Agent/faqs-arkweb-123.md`、`H5网页中Cookie跨域场景及解决方案/faqs-arkweb-186.md`。

## 四、项目相关：Distiller 要不要用

**结论：不用。** Distiller 是纯原生 ArkUI（状态管理 V2）的单一 `entry` 模块应用，界面全为 `.ets`，没有 H5 资产要复用，也没有前端独立发版需求 —— 这条路是**参考 / 兜底路线，不是主路径**。

| 判断项 | 结论 | 依据 |
| :-- | :-- | :-- |
| 现状 | 项目不使用 Web 组件；本文全部内容是文档取证，非实测 | `references/project/` 与项目 README |
| 三方依赖 | 走 ArkWeb 似乎不必新增 `oh-package.json5` 依赖（官方示例 `import { webview } from '@kit.ArkWeb'`）；但引入 H5 工程会把 npm/webpack 工具链带进来 | `FAQ/Web框架/Web开发_ArkWeb/Web组件对H5页面_常用框架VUE_React的页面支持情况_包括本地和网络端的页面/faqs-arkweb-38.md` + 推断 |
| 权限 | 若加载**在线**页面，须在 `module.json5` 增 `ohos.permission.INTERNET` | `开发指南/ArkWeb_方舟Web/ArkWeb简介/web-component-overview.md` |
| 内存预算 | 须按 so ≈200MB、页面级几百兆～1 GB 重做评估 | `FAQ/Web框架/Web开发_ArkWeb/Web组件的内存占用与内存回收机制/faqs-arkweb-93.md` |
| HAP 体积预算 | **未取证** —— 没有官方数字 | 见文末 |
| 何时回头评估 | 仅当出现「必须复用既有 H5」或「需要 Web 端热更新」时 | 判断，非官方口径 |

## 未取证

1. **HAP 体积增量**：没有官方数字说明引入 Web 组件 / Web 引擎会让 HAP 增重多少；`web-component-overview.md` 只提权限、内核版本、模拟器，未提体积。
2. **`@kit.ArkWeb` 是否随 SDK 提供、无需 `oh-package.json5` 声明**：官方示例 `import { webview } from '@kit.ArkWeb'` 作旁证。
   **本次补证（部分）**：生成副本的机器上，SDK 根 `…\sdk\default\openharmony\ets\kits\@kit.ArkWeb.d.ts` **确实存在** —— 即该 Kit 桶文件**由 SDK 自带，不需要 `oh-package.json5`**（`hms\ets\kits\` 下没有它，未命中）。**残留未取证**：这只在那台机器的 SDK（`sdk-pkg.json` 报 `apiVersion "26"` / `26.0.0.32` Beta2）上核过，**目标 `6.0.2(22)` 对应的 SDK 里是否同样自带，未核**。
   > **顺带纠正一条旧判定**：本文早先写「未定位到 HarmonyOS SDK 目录（`%LOCALAPPDATA%\Huawei\Sdk` 等候选路径均不存在）」—— 那句说的是**生成副本的那台机器** —— **而这个判定是错的**，SDK 根目录找得到：判据是 `sdk\default\sdk-pkg.json`，**完整探法与两个实测坑见 `01-项目基线.md` §1.1**（那台机器上它在 `…\DevEco Studio\sdk\default`，而 `$env:DEVECO_SDK_HOME` 并不指向它）。
3. **端到端可行性**：**生成副本时没在任何机器上跑过 ArkWeb 代码**，本文内容**全部是文档取证，无实测结论**。
4. **官方的 Hybrid vs 原生决策树**：不存在。官方只给 Hybrid 的架构与实现方式（`bpta-arkweb_rendering_framework.md`），§一 的选型判断是本文综合文档得出的，不是官方结论。
5. **FAQ 163 篇的完整覆盖**：只挑了 22 篇，其余仅凭目录名（= 问题原文）判断相关性，未逐篇阅读。
6. **FAQ 正文里的 `developer.huawei.com` 外链**：`faqs-arkweb-185` 等大量外链到 `developer.huawei.com/consumer/cn/doc/best-practices/...`，那些页面是 JS-only SPA，无法抓正文（观察记录见 `14-FlutterUI参考导航.md`）；本文一律改用本地已落盘的同名 `bpta-*.md`。
