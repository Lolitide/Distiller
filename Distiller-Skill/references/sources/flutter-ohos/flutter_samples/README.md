# Flutter OH 文档索引

## 快速入门

| 文档名 | 说明 |
|---|---|
| [Flutter OH 框架介绍](./getting-started/overview.md) | 框架介绍 |
| [Flutter OH 架构介绍](./getting-started/architecture.md) | 架构介绍 |
| [Flutter OH 工程目录结构](./getting-started/project-structure.md) | 工程目录结构 |
| [Flutter OH 开发环境搭建指导](./getting-started/flutter-oh-env-setup.md) | 开发环境搭建（DevEco Studio 安装、模拟器配置） |
| [Flutter OH Engine 构建指导](./getting-started/flutter-oh-engine-build-guide.md) | Flutter OH Engine 构建指导 |
| [OpenHarmony 设备运行指导](./getting-started/openharmony-device-guide.md) | 真机设备运行 Flutter 应用步骤 |
| [Flutter OH 开发板运行指南](./getting-started/flutter-device-board-guide.md) | RK3568 等开发板上运行 Flutter 应用 |
| [FVM (Flutter Version Management) 使用指导](./getting-started/fvm-introduction.md) | 用 FVM 在同一开发机管理多个 Flutter OH 版本，按项目锁定分支/tag |

## 应用开发

| 文档名 | 说明 |
|---|---|
| [Flutter-OH核心对象简介](./app-development/flutter-oh-core-objects.md) | 介绍 Flutter OH 核心对象职责与协作关系 |
| [核心对象架构原理说明](./app-development/core-object-architecture.md) | 解析五大核心对象架构原理与生命周期协同 |
| [Flutter-OH应用生命周期](./app-development/flutter-oh-app-lifecycle.md) | 两种集成方式的生命周期时序流程 |
| [Flutter App/Module启动生命周期回调指南](./app-development/app-module-lifecycle-callbacks.md) | 启动生命周期回调机制与最佳实践 |
| [OpenHarmony应用集成Flutter指导](./app-development/ohos-integrate-flutter.md) | OpenHarmony 应用集成 Flutter 模块指导 |
| [Flutter OH 应用构建与运行指导](./app-development/flutter-oh-app-build-guide.md) | 应用构建、签名配置及 Impeller 开关设置 |
| [使用hvigor插件方式编译flutter项目](./app-development/hvigor-plugin-build.md) | Hvigor 插件编译 Flutter 项目方式 |
| [Flutter 应用 OpenHarmony 接入指导](./app-development/flutter-ohos-integration.md) | 已有 Flutter 应用适配 OpenHarmony 平台指导 |
| [Flutter Engine 异步创建与销毁说明文档](./app-development/flutter-engine-async.md) | Flutter Engine 异步创建与销毁能力的使用说明 |
| [Flutter 分栏功能（平行视界）接入指导](./app-development/flutter-split-view-integration.md) | Flutter 分栏功能接入，支持折叠屏等设备 |

## 混合开发

| 文档名 | 说明 |
|---|---|
| [如何使用 FlutterPage](./hybrid-development/using-flutter-page.md) | 使用 FlutterPage 组件嵌入 Flutter 页面 |
| [如何使用混合开发添加跳转 FlutterEntry](./hybrid-development/using-flutter-entry.md) | 使用 FlutterEntry 实现原生与 Flutter 页面混合开发 |
| [如何使用 Flutter Channel](./hybrid-development/using-flutter-channel.md) | Flutter 与 OpenHarmony 通过 Channel 机制双向通信 |
| [如何使用 PlatformView](./hybrid-development/using-platform-view.md) | 在 Flutter 中嵌入 OpenHarmony 原生 PlatformView |
| [PlatformView 同层渲染方案适配切换指导](./hybrid-development/platform-view-same-layer-rendering.md) | PlatformView 同层渲染方案适配切换 |
| [如何使用多引擎 FlutterEngineGroup](./hybrid-development/using-flutter-engine-group.md) | 使用 FlutterEngineGroup 管理多个引擎实例 |
| [FlutterEnginePreload 使用指南](./hybrid-development/using-flutter-engine-preload.md) | FlutterEnginePreload 预加载与预绘制机制 |
| [Flutter OH 多引擎场景开发指导](./hybrid-development/flutter-oh-multi-engine-dev-guide.md) | Flutter OH 多引擎场景开发指导 |
| [如何使用混合开发 module](./hybrid-development/using-module.md) | 原生工程引用 flutter_module 子模块进行混合开发 |
| [如何导入自渲染内容到 Flutter](./hybrid-development/import-custom-rendered-content.md) | 通过外接纹理导入 Native 自渲染内容到 Flutter |

## 插件与三方库

| 文档名 | 说明 |
|---|---|
| [识别 Flutter 三方库是否需要适配 OpenHarmony](./plugin-and-package/flutter-library-ohos-check.md) | 识别 Flutter 三方库是否需要适配 OpenHarmony |
| [Flutter 三方库适配 OpenHarmony 平台指导](./plugin-and-package/ohos-flutter-lib-adaptation.md) | Flutter 三方库适配 OpenHarmony 平台完整流程 |
| [开发 Flutter Plugin](./plugin-and-package/developing-plugin.md) | 开发支持 ohos 平台的 Flutter 原生插件 |
| [开发 Dart Package](./plugin-and-package/developing-package.md) | 开发纯 Dart 的 Flutter Package |
| [开发FFI plugin](./plugin-and-package/developing-an-ffi-plugin.md) | 开发支持 ohos 平台的 FFI 插件 |
| [更新Flutter插件项目结构](./plugin-and-package/update-flutter-plugin-structure.md) | 将插件 ohos 目录从 project 结构更新为 module 结构 |
| [OpenHarmony 平台已适配三方库](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md#1openharmony%E5%B9%B3%E5%8F%B0%E5%B7%B2%E9%80%82%E9%85%8D%E4%B8%89%E6%96%B9%E5%BA%93) | OpenHarmony 平台已适配三方库清单 |

## 渲染引擎

| 文档名 | 说明 |
|---|---|
| [Flutter OH Impeller 与 Skia 渲染引擎切换指南](./rendering-engine/rendering-engine-switching.md) | Impeller 与 Skia 渲染引擎切换方法 |
| [Flutter OHOS 外接纹理适配简介](./rendering-engine/flutter-external-texture.md) | 视频/相机/图片纹理注册流程 |
| [Flutter OHOS 外接纹理第一帧（背景）自定义](./rendering-engine/flutter-external-texture-first-frame.md) | 自定义外接纹理首帧背景 |
| [如何使用 LTPO 功能](./rendering-engine/using-ltpo.md) | 屏幕动态帧率适配 |
| [Flutter OHOS 渲染流程与异常诊断教程](./rendering-engine/rendering-pipeline-and-exception-diagnosis-guide.md) | 渲染流程分析与异常诊断方法 |

## 性能调优

| 文档名 | 说明 |
|---|---|
| [性能分析定界指南](./performance/perf-delimitation-guide.md) | 如何定位性能问题所属模块 |
| [性能分析第一步-梳理线程顺序](./performance/perf-analysis-threads-sequence.md) | 介绍 Flutter 渲染相关线程及其顺序 |
| [性能分析-帧渲染跟踪](./performance/perf-frame-rendering-tracking.md) | 单帧追踪方法，用于分析卡顿/丢帧 |
| [性能分析-滑动响应时延](./performance/perf-sliding-response-time.md) | 滑动场景的 trace 分析与时延优化 |
| [性能调优-图片加载](./performance/perf-tuning-image-loading.md) | 图片预加载、缓存等优化手段 |
| [性能调优-内存分析与优化实践](./performance/perf-tuning-memory-analysis.md) | HarmonyOS 上 Flutter 应用的内存分析方法 |
| [性能调优-毕昇编译器开PGO](./performance/perf-tuning-bisheng-pgo.md) | 利用毕昇编译器 PGO 提升运行性能 |
| [性能优化-预加载渲染管线](./performance/perf-optimization-preload-render-pipeline.md) | 解决页面转场白屏问题 |
| [性能调优索引](./performance/README.md) | 性能调优详细索引（含环境配置说明） |

## 降负载和功耗优化

| 文档名 | 说明 |
|---|---|
| [LTPO 降负载方案](./power-consumption/power-consumption-ltpo.md) | LTPO 智能刷新：在交互时提升帧率，空闲时回落低功耗档位。 |
| [0 脏区跳过渲染](./power-consumption/power-consumption-skip-dirty-region.md) | 0 脏区跳过渲染：页面无变化时直接跳过后续绘制和提交。 |
| [简单遮挡剔除](./power-consumption/power-consumption-occlusion-culling.md) | Impeller 简单遮挡剔除：丢弃被纯色覆盖的无效绘制命令。 |
| [页面不可见时暂停绘制](./power-consumption/power-consumption-eliminate-redundant-drawing.md) | 页面不可见时暂停绘制：防止 WebView / PlatformView 产生冗余绘制。 |
| [Flutter OH 降负载和功耗优化](./power-consumption/README.md) | 降负载和功耗优化详细索引 |

## 调试与排查

| 文档名 | 说明 |
|---|---|
| [Flutter OH 热重载操作指导](./debugging/hot-reload-guide.md) | Debug 模式下使用热重载 / 热重启快速预览 Dart 代码变更 |
| [调试 Dart 代码](./debugging/debugging-dart-code.md) | 使用 VS Code / Android Studio / DevEco Studio 调试 Dart 代码 |
| [原生代码断点调试](./debugging/native-arkts-debugging-guide.md) | 使用 DevEco Studio 调试 ArkTS / Native 代码 |
| [调试 OpenHarmony 应用/服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ohos-debugging-app-0000001545729889-V2) | OpenHarmony 官方文档：调试应用/服务 |
| [解析 Flutter 相关的 cppcrash 堆栈](./debugging/flutter-cppcrash-stack-analysis.md) | 使用 llvm-addr2line 解析 Flutter 相关的 CppCrash 堆栈 |
| [Dart 堆栈符号化](./debugging/dart-stack-symbolization.md) | 使用 flutter symbolize 工具还原 Release/Profile 模式堆栈 |
| [内存泄漏与稳定性排查](./debugging/memory-and-stability-troubleshooting.md) | 卡顿丢帧、ArkTS / Native 内存泄漏分析 |
| [调试指导索引](./debugging/README.md) | 调试指导详细索引 |

## 问题定位

| 文档名 | 说明 |
|---|---|
| [DFX 问题定位导航](./troubleshooting/dfx/README.md) | 基于 HarmonyOS DFX 能力（HiAppEvent/HiLog/HiCollie/HiTrace）的问题诊断方法论 |
| [崩溃定位](./troubleshooting/dfx/dfx-crash.md) | 应用闪退、崩溃（Native/Dart/ETS 异常）问题定位 |
| [卡死冻屏定位](./troubleshooting/dfx/dfx-appfreeze.md) | 应用卡死、无响应、冻屏问题定位 |
| [卡顿丢帧定位](./troubleshooting/dfx/dfx-performance.md) | 界面卡顿、滑动不流畅、丢帧问题定位 |
| [内存/GPU 定位](./troubleshooting/dfx/dfx-memory.md) | OOM、黑屏、渲染异常等内存与 GPU 问题定位 |
| [日志抓取](./troubleshooting/dfx/dfx-logging.md) | 日志抓取、过滤与查看方法 |
| [DFX 事件目录](./troubleshooting/dfx/dfx-hiappevent.md) | HiAppEvent 上报的全部 DFX 事件及参数目录 |
| [卡顿与时延深度分析](./troubleshooting/dfx/dfx-jank-latency.md) | 滑动卡顿丢帧与时延问题深度分析 |
| [负载与功耗定位](./troubleshooting/dfx/dfx-power-load.md) | 负载异常与功耗问题定位 |
| [外接纹理问题定位](./troubleshooting/dfx/dfx-texture.md) | 外接纹理问题定位 |
| [多设备适配问题定位](./troubleshooting/dfx/dfx-multi-device.md) | 多设备适配问题定位 |
| [滑动卡顿问题介绍](./troubleshooting/dfx/dfx-sliding-introduction.md) | Flutter 滑动卡顿与掉帧问题概念介绍 |
| [点击响应和完成时延介绍](./troubleshooting/dfx/dfx-latency-introduction.md) | Flutter 点击响应和完成时延分析介绍 |
| [问题定位索引](./troubleshooting/README.md) | DFX 问题定位总索引 |

## FAQ

| 文档名 | 说明 |
|---|---|
| [环境搭建问题](./faq/README.md#environment-setup) | SDK 配置、模拟器、长路径、跨平台复制等环境问题 |
| [Engine 编译问题](./faq/README.md#engine-compilation) | Flutter OH Engine 编译环境推荐版本与产物生成 |
| [应用编译构建问题](./faq/README.md#app-build) | 编译报错、依赖冲突、so 包未打入、跨磁盘等问题 |
| [签名与发布问题](./faq/README.md#signing-and-release) | 自动签名、Release 构建异常、debug 版 har 上线闪退 |
| [代码开发问题](./faq/README.md#code-development) | 平台判断、资源获取、折叠屏适配、启动闪退等 |
| [三方库与插件适配问题](./faq/README.md#plugin-adaptation) | 插件同步失败、依赖冲突、MissingPluginException 等 |
| [渲染引擎与 UI 问题](./faq/README.md#rendering-and-ui) | WebView 拉伸、折叠屏、启动页闪动、Impeller 锯齿等 |
| [运行相关问题](./faq/README.md#runtime-issues) | 运行时错误、白屏闪退、安全避让区异常等 |
| [Crash 分析与调试问题](./faq/README.md#crash-and-debug) | 引擎调试、启动闪退、可复现 demo 提供等 |
| [权限与安全问题](./faq/README.md#permission-and-security) | 权限声明位置、权限场景、功能与权限对照表 |
| [常见问题索引](./faq/README.md) | 常见问题详细索引 |

## 场景化案例

| 文档名 | 说明 |
|---|---|
| [应用上架与启动闪退场景案例](./cases/app-release-crash-case.md) | 应用发布邀请测试或正式上架启动闪退问题的分析与解决方案 |
| [登录接入场景案例](./cases/huawei-id-login-case.md) | Flutter 接入华为账号一键登录的集成实践 |
| [Flutter module 调试案例](./cases/module-debugging-case.md) | Flutter module 调试中线程合并导致断点阻塞 UI 线程引发崩溃 |
| [Flutter OHOS ICU 文件升级问题与解决方案](./cases/icu-upgrade-case.md) | OHOS ICU 库大版本升级后的兼容性问题与解决方案 |
| [Flutter 多设备自适应 DPI 指导文档](./cases/multi-device-responsive-dpi-guide.md) | 多设备自适应 DPI 的核心策略、断点系统、布局适配与最佳实践 |
| [引入插件失效问题场景案例](./cases/plugin-missing-after-release-build-case.md) | APP release 打包发布后插件丢失问题的分析与解决方案 |
| [webview 拉起支付白屏场景案例](./cases/webview-white-screen-case.md) | webview 拉起支付白屏（自定义 scheme）问题的分析与解决方案 |
| [场景化案例索引](./cases/README.md) | 场景化案例详细索引 |

## 示例代码

| 文档名 | 说明 |
|---|---|
| [flutter_samples](https://gitcode.com/CPF-Flutter/flutter_samples) | Flutter 示例代码仓库 |

## API 参考

| 文档名 | 说明 |
|---|---|
| [Flutter OHOS 适配层 API 接口说明](./api-reference/flutter-ohos-api-guide.md) | FlutterAbility、FlutterEntry、FlutterEngine、FlutterView 等核心类 API 使用说明 |
| [Flutter 适配层 API](./api-reference/README.md) | API 总览（按源码路径生成的逐类参考索引） |

## 版本说明

| 文档名 | 说明 |
|---|---|
| [Flutter OH 版本说明](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md) | 版本演进规划和分支策略 |
| [Flutter OH 版本升级指导](./version/flutter-oh-upgrade-guide.md) | Flutter OH 版本升级指导 |
| [Flutter 3.35 OpenHarmony 升级指导](./version/flutter-3.35-openharmony-upgrade-guide.md) | Flutter 3.35 OpenHarmony 升级指导 |

## AI Skills

| 文档名 | 说明 |
|---|---|
| [AI Skills](./skills/README.md) | Flutter OHOS 文档配套 AI 技能索引（崩溃分析、性能诊断等） |
