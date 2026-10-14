# Flutter Samples

## 介绍

本仓库基于 Flutter 官方 [samples](https://github.com/flutter/samples/) 进行拓展，提供 OpenHarmony 平台适配示例及配套文档，覆盖应用开发、平台能力接入与工程实践。开发者可通过本仓库快速了解 OpenHarmony Flutter 开发流程，并参考示例实现细节进行实践与验证。

## 文档

### 快速入门

- [Flutter OH 框架介绍](./docs/ohos/getting-started/overview.md)
- [Flutter OH 架构介绍](./docs/ohos/getting-started/architecture.md)
- [Flutter OH 工程目录结构](./docs/ohos/getting-started/project-structure.md)
- [Flutter OH 开发环境搭建指导](./docs/ohos/getting-started/flutter-oh-env-setup.md)
- [Flutter OH Engine构建指导](./docs/ohos/getting-started/flutter-oh-engine-build-guide.md)
- [OpenHarmony 设备运行指导](./docs/ohos/getting-started/openharmony-device-guide.md)
- [Flutter OH 开发板运行指南](./docs/ohos/getting-started/flutter-device-board-guide.md)
- [FVM (Flutter Version Management) 使用指导](./docs/ohos/getting-started/fvm-introduction.md)
- [Flutter OH 版本说明](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)
- [Flutter OH 版本升级指导](./docs/ohos/version/flutter-oh-upgrade-guide.md)
- [Flutter OH 3.35 升级指导](./docs/ohos/version/flutter-3.35-openharmony-upgrade-guide.md)

### 应用开发

- [Flutter OH 核心对象简介](./docs/ohos/app-development/flutter-oh-core-objects.md)
- [核心对象架构原理说明](./docs/ohos/app-development/core-object-architecture.md)
- [Flutter OH 应用生命周期](./docs/ohos/app-development/flutter-oh-app-lifecycle.md)
- [Flutter AppModule启动生命周期回调指南](./docs/ohos/app-development/app-module-lifecycle-callbacks.md)
- [OpenHarmony应用集成Flutter指导](./docs/ohos/app-development/ohos-integrate-flutter.md)
- [Flutter OH 应用构建与运行指导](./docs/ohos/app-development/flutter-oh-app-build-guide.md)
- [使用hvigor插件方式编译flutter项目](./docs/ohos/app-development/hvigor-plugin-build.md)
- [Flutter应用接入OpenHarmony平台指导](./docs/ohos/app-development/flutter-ohos-integration.md)
- [Flutter Engine 异步创建与销毁说明文档](./docs/ohos/app-development/flutter-engine-async.md)
- [Flutter分栏功能（平行视界）接入指导](./docs/ohos/app-development/flutter-split-view-integration.md)

### 混合开发

- [如何使用 FlutterPage](./docs/ohos/hybrid-development/using-flutter-page.md)
- [如何使用混合开发添加跳转 FlutterEntry](./docs/ohos/hybrid-development/using-flutter-entry.md)
- [如何使用混合开发 module](./docs/ohos/hybrid-development/using-module.md)
- [如何使用多引擎 FlutterEngineGroup](./docs/ohos/hybrid-development/using-flutter-engine-group.md)
- [如何使用FlutterEnginePreload](./docs/ohos/hybrid-development/using-flutter-engine-preload.md)
- [如何使用Flutter与OpenHarmony通信 FlutterChannel](./docs/ohos/hybrid-development/using-flutter-channel.md)
- [如何使用PlatformView](./docs/ohos/hybrid-development/using-platform-view.md)
- [PlatformView同层渲染方案适配切换指导](./docs/ohos/hybrid-development/platform-view-same-layer-rendering.md)
- [如何导入自渲染内容](./docs/ohos/hybrid-development/import-custom-rendered-content.md)
- [Flutter OH 多引擎场景开发指导](./docs/ohos/hybrid-development/flutter-oh-multi-engine-dev-guide.md)

### 插件与三方库

- [识别Flutter三方库是否需要适配OpenHarmony](./docs/ohos/plugin-and-package/flutter-library-ohos-check.md)
- [Flutter三方库适配OpenHarmony平台指导](./docs/ohos/plugin-and-package/ohos-flutter-lib-adaptation.md)
- [OpenHarmony平台已适配三方库](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md#1openharmony%E5%B9%B3%E5%8F%B0%E5%B7%B2%E9%80%82%E9%85%8D%E4%B8%89%E6%96%B9%E5%BA%93)
- [开发 Flutter Plugin](./docs/ohos/plugin-and-package/developing-plugin.md)
- [开发 Dart Package](./docs/ohos/plugin-and-package/developing-package.md)
- [开发FFI plugin](./docs/ohos/plugin-and-package/developing-an-ffi-plugin.md)
- [更新Flutter插件项目结构](./docs/ohos/plugin-and-package/update-flutter-plugin-structure.md)

### 渲染引擎

- [Impeller与Skia渲染引擎切换指导](./docs/ohos/rendering-engine/rendering-engine-switching.md)
- [如何使用LTPO功能](./docs/ohos/rendering-engine/using-ltpo.md)
- [Flutter OHOS外接纹理适配简介](./docs/ohos/rendering-engine/flutter-external-texture.md)
- [Flutter OHOS外接纹理第一帧（背景）自定义](./docs/ohos/rendering-engine/flutter-external-texture-first-frame.md)
- [Flutter OHOS渲染流程与异常诊断指导](./docs/ohos/rendering-engine/rendering-pipeline-and-exception-diagnosis-guide.md)

### 性能调优

- [性能分析定界(OpenHarmony平台)指南](./docs/ohos/performance/perf-delimitation-guide.md)
- [性能分析第一步-梳理线程顺序](./docs/ohos/performance/perf-analysis-threads-sequence.md)
- [性能分析-帧渲染跟踪](./docs/ohos/performance/perf-frame-rendering-tracking.md)
- [性能分析-滑动响应时延](./docs/ohos/performance/perf-sliding-response-time.md)
- [性能调优-图片加载](./docs/ohos/performance/perf-tuning-image-loading.md)
- [性能调优-内存分析与优化实践](./docs/ohos/performance/perf-tuning-memory-analysis.md)
- [性能调优-毕昇编译器开启PGO](./docs/ohos/performance/perf-tuning-bisheng-pgo.md)
- [性能优化-预加载渲染管线](./docs/ohos/performance/perf-optimization-preload-render-pipeline.md)

### 降负载和功耗优化

- [负载优化-LTPO智能刷新](./docs/ohos/power-consumption/power-consumption-ltpo.md)
- [负载优化-0脏区跳过渲染](./docs/ohos/power-consumption/power-consumption-skip-dirty-region.md)
- [负载优化-遮挡剔除](./docs/ohos/power-consumption/power-consumption-occlusion-culling.md)
- [负载优化-页面不可见时暂停绘制](./docs/ohos/power-consumption/power-consumption-eliminate-redundant-drawing.md)

### 调试调测

- [Flutter OH 调试指导](./docs/ohos/debugging/README.md)
- [Flutter OH 热重载操作指导](./docs/ohos/debugging/hot-reload-guide.md)
- [调试 Dart 代码](./docs/ohos/debugging/debugging-dart-code.md)
- [原生代码断点调试](./docs/ohos/debugging/native-arkts-debugging-guide.md)
- [调试 OpenHarmony 应用/服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ohos-debugging-app-0000001545729889-V2)
- [解析 Flutter 相关的 cppcrash 堆栈](./docs/ohos/debugging/flutter-cppcrash-stack-analysis.md)
- [Dart 堆栈符号化](./docs/ohos/debugging/dart-stack-symbolization.md)
- [内存泄漏与稳定性排查](./docs/ohos/debugging/memory-and-stability-troubleshooting.md)

### 问题定位

- [DFX 问题定位导航](./docs/ohos/troubleshooting/dfx/README.md)

### 场景化案例

- [应用上架与启动闪退案例](./docs/ohos/cases/app-release-crash-case.md)
- [登录接入场景案例](./docs/ohos/cases/huawei-id-login-case.md)
- [Flutter module 调试案例](./docs/ohos/cases/module-debugging-case.md)
- [Flutter_OHOS_ICU升级问题及解决方案](./docs/ohos/cases/icu-upgrade-case.md)
- [多设备响应式DPI指导](./docs/ohos/cases/multi-device-responsive-dpi-guide.md)
- [引入插件失效问题场景案例](./docs/ohos/cases/plugin-missing-after-release-build-case.md)
- [webview拉起支付白屏场景案例](./docs/ohos/cases/webview-white-screen-case.md)

### FAQ

- [环境搭建问题](./docs/ohos/faq/README.md#environment-setup)
- [Engine编译问题](./docs/ohos/faq/README.md#engine-compilation)
- [应用编译构建问题](./docs/ohos/faq/README.md#app-build)
- [签名与发布问题](./docs/ohos/faq/README.md#signing-and-release)
- [代码开发问题](./docs/ohos/faq/README.md#code-development)
- [三方库与插件适配问题](./docs/ohos/faq/README.md#plugin-adaptation)
- [渲染引擎与UI问题](./docs/ohos/faq/README.md#rendering-and-ui)
- [运行相关问题](./docs/ohos/faq/README.md#runtime-issues)
- [Crash分析与调试问题](./docs/ohos/faq/README.md#crash-and-debug)
- [权限与安全问题](./docs/ohos/faq/README.md#permission-and-security)

### API参考

- [Flutter适配层API](./docs/ohos/api-reference/README.md)

### 示例代码

- [flutter_samples](https://gitcode.com/CPF-Flutter/flutter_samples)

## 示例

新增OpenHarmony平台示例：

| 仓库名 | 依赖路径 | 描述 |
| ----- | ------ | ---- |
| [flutter_music_player](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/flutter_music_player) | flutter_music_player | 本示例展示了一个音乐播放器模型，具有自动播放、拖拽进度条等功能 |
| [flutter_smart_agriculture](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/flutter_smart_agriculture) | flutter_smart_agriculture | 智慧农场 |
| [multiple_flutters_ohos](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/add_to_app/multiple_flutters) | add_to_app/multiple_flutters/multiple_flutters_ohos | FlutterEngineGroup多引擎使用示例，可监听生命周期 |
| [animation_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/animation_demo) | ohos/animation_demo | 交错动画（Staggered Animation）示例，演示位移、旋转和颜色变化 |
| [async_engine_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/async_engine_demo) | ohos/async_engine_demo | Engine 异步创建与销毁相关示例 |
| [async_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/async_test) | ohos/async_test | 异步调用demo |
| [asynchronous](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/asynchronous) | ohos/asynchronous | Dart/Flutter 异步编程示例（async/await、FutureBuilder、Stream、Completer 等） |
| [automated_testing_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/automated_testing_demo) | ohos/automated_testing_demo | 自动化测试示例（Widget 测试、集成测试、Hypium 原生测试） |
| [cached_network_image_sample](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/cached_network_image_sample) | ohos/cached_network_image_sample | cached_network_image 插件加载与缓存网络图片示例 |
| [cached_video_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/cached_video_demo) | ohos/cached_video_demo | 双播加缓存短视频播放demo |
| [channel_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/channel_demo) | ohos/channel_demo | 通道测试demo，可查看EventChannel/MethodChannel/BasicMessageChannel方法的返回值 |
| [clock_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/clock_test) | ohos/clock_test | 计时器demo，可计时，查看历史计时记录和一些详细数据 |
| [dio_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/dio_test) | ohos/dio_test | 测试demo合集 |
| [event_bus_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/event_bus_test) | ohos/event_bus_test | 事件驱动demo |
| [floor_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/floor_test) | ohos/floor_test | floor SQLite ORM 本地数据库读写示例 |
| [flutter_huawei_login](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_huawei_login) | ohos/flutter_huawei_login | 华为账号一键登录集成示例（PlatformView + MethodChannel） |
| [flutter_it_image](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_it_image) | ohos/flutter_it_image | 图片自渲染/纹理展示方案示例 |
| [flutter_it_preload](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_it_preload) | ohos/flutter_it_preload | 引擎预加载（Preload）后进入 FlutterPage 示例 |
| [flutter_ohos_theme_fontsizescale](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_ohos_theme_fontsizescale) | ohos/flutter_ohos_theme_fontsizescale | 跟随系统主题与字体/色彩适配的 Tab 应用示例 |
| [flutter_page_sample1](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_page_sample1) | ohos/flutter_page_sample1 | route路由页面跳转demo |
| [flutter_page_sample2](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_page_sample2) | ohos/flutter_page_sample2 | FlutterEntry的使用示例 |
| [flutter-pag](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter-pag) | ohos/flutter-pag | PAG 动画组件，采用外接纹理技术实现 |
| [flutter_svg_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_svg_test) | ohos/flutter_svg_test | svg图片demo |
| [flutter_typical_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_typical_demo) | ohos/flutter_typical_demo | 整合 Flutter 典型场景 Demo（微信朋友圈等） |
| [flutter_webview_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/flutter_webview_demo) | ohos/flutter_webview_demo | webview_flutter 与 go_router、国际化集成示例 |
| [gesture_intercept_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/gesture_intercept_demo) | ohos/gesture_intercept_demo | 嵌套 ListView 手势与滚动冲突场景示例 |
| [hmrouter_flutter_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/hmrouter_flutter_demo) | ohos/hmrouter_flutter_demo | HMRouter 与 Flutter 双向参数传递示例 |
| [http_parser_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/http_parser_test) | ohos/http_parser_test | http解析demo |
| [http_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/http_test) | ohos/http_test | http网页请求 demo |
| [js_dart_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/js_dart_demo) | ohos/js_dart_demo | WebView 内 JS 与 Flutter/Dart 双向通信示例 |
| [list_view_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/performance/list_view_demo) | ohos/performance/list_view_demo | 长列表性能优化示例（懒加载、分页、Provider） |
| [load_native_resource_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/load_native_resource_demo) | ohos/load_native_resource_demo | 从原生资源（rawfile、媒体库）加载图片与视频示例 |
| [localtion_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/localtion_demo) | ohos/localtion_demo | 获取定位demo |
| [logging_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/logging_test) | ohos/logging_test | 日志记录 demo |
| [multi_products](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/multi_products) | ohos/multi_products | 多 Product/Flavor 打包配置示例 |
| [multidevice_adaption_sample_flutter](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/multidevice_adaption_sample_flutter) | ohos/multidevice_adaption_sample_flutter | 多设备适配一多能力示例 |
| [multiple_flutters_predraw](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/multiple_flutters_predraw) | ohos/multiple_flutters_predraw | 多 Engine/EntryPoint 及引擎预绘制（predraw）示例 |
| [node_test_server](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/node_test_server) | ohos/node_test_server | 配合自动化测试的 Node 测试服务 |
| [ohos_flutter_photoviewpicker](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/ohos_flutter_photoviewpicker) | ohos/ohos_flutter_photoviewpicker | 系统相册自定义图片选择器示例 |
| [ohos_sqlite3_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/ohos_sqlite3_demo) | ohos/ohos_sqlite3_demo | sqlite3 Dart 包直接操作 SQLite 示例 |
| [ohos_themeAdaptation](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/ohos_themeAdaptation) | ohos/ohos_themeAdaptation | 跟随系统深浅色主题自适配示例 |
| [opengl_for_soft_decoding](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/opengl_for_soft_decoding) | ohos/opengl_for_soft_decoding | 软解码场景 MethodChannel + Texture + OpenGL 渲染示例 |
| [path_drawing_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/path_drawing_test) | ohos/path_drawing_test | 路径绘制demo |
| [path_parsing_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/path_parsing_test) | ohos/path_parsing_test | path_parsing 包 SVG 路径解析测试示例 |
| [petitparser_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/petitparser_test) | ohos/petitparser_test | petitparser 组合式解析器库回归测试示例 |
| [pictures_provider_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/pictures_provider_demo) | ohos/pictures_provider_demo | 获取图片demo |
| [picker_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/picker_demo) | ohos/picker_demo | MethodChannel 调用原生选择器（日期、时间、文件、相册等）示例 |
| [platform_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/platform_demo) | ohos/platform_demo | 自定义 PlatformView 双向通信示例 |
| [platform_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/platform_test) | ohos/platform_test | 平台调用demo |
| [platformchannel_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/platformchannel_demo) | ohos/platformchannel_demo | 平台多项功能接口测试demo |
| [provider_partrefresh](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/provider_partrefresh) | ohos/provider_partrefresh | Provider 局部刷新（Part Refresh）示例 |
| [rxdart_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/rxdart_test) | ohos/rxdart_test | rxdart demo，提供了一系列用于处理异步事件和数据流的工具 |
| [scrollview_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/scrollview_demo) | ohos/scrollview_demo | CustomScrollView 与 Sliver 折叠头图效果示例 |
| [split_view_sample](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/split_view_sample) | ohos/split_view_sample | 分栏功能 8 种路由方案测试示例 |
| [sqflite_helper](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/sqflite_helper) | ohos/sqflite_helper | sqflite_helper 插件示例 |
| [sqflite_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/sqflite_test) | ohos/sqflite_test | sqflite 数据库能力专项测试示例 |
| [string_scanner_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/string_scanner_test) | ohos/string_scanner_test | 字符扫描demo |
| [test_uni_links](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/test_uni_links) | ohos/test_uni_links | 深度链接/URL Scheme 示例 |
| [testcamera](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testcamera) | ohos/testcamera | 相机调用demo |
| [testchat](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testchat) | ohos/testchat | 聊天场景demo |
| [testpicture](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testpicture) | ohos/testpicture | 图片展示demo |
| [tuple_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/tuple_test) | ohos/tuple_test | tuple demo，测试元组类型生产的参数 |
| [uuid_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/uuid_test) | ohos/uuid_test | uuid demo |
| [vector_math_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/vector_math_test) | ohos/vector_math_test | 向量匹配demo |
| [video_full_screen](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/video_full_screen) | ohos/video_full_screen | video_player 与 chewie 视频全屏播放示例 |
| [websocket_demo](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/websocket_demo) | ohos/websocket_demo | WebSocket 调试客户端示例 |
| [xml_test](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/xml_test) | ohos/xml_test | xml 包解析、构建、查询等回归测试示例 |

## 快速开始

```bash
# 1. 克隆仓库
git clone https://gitcode.com/CPF-Flutter/flutter_samples.git

# 2. 进入示例目录
cd flutter_samples/ohos/animation_demo

# 3. 运行
flutter run
```

## 问题交流

- 问题反馈：欢迎在 [Flutter框架仓库](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) 以及各个Flutter三方库提交issue。
