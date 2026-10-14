# Flutter OH Documentation Index

## Getting Started

| Document | Description |
|---|---|
| [Flutter OH Framework Introduction](./getting-started/overview.en.md) | Framework introduction |
| [Flutter OH Architecture Introduction](./getting-started/architecture.en.md) | Architecture introduction |
| [Flutter OH Project Directory Structure](./getting-started/project-structure.en.md) | Project directory structure |
| [Flutter OH Development Environment Setup Guide](./getting-started/flutter-oh-env-setup.en.md) | Development environment setup (DevEco Studio installation, emulator configuration) |
| [Flutter OH Engine Build Guide](./getting-started/flutter-oh-engine-build-guide.en.md) | Flutter OH Engine build guide |
| [OpenHarmony Device Running Guide](./getting-started/openharmony-device-guide.en.md) | Steps for running Flutter apps on real devices |
| [Flutter OH Development Board Running Guide](./getting-started/flutter-device-board-guide.en.md) | Running Flutter apps on RK3568 and other development boards |
| [FVM (Flutter Version Management) Usage Guide](./getting-started/fvm-introduction.en.md) | Manage multiple Flutter OH versions on the same dev machine with FVM, pinning a branch/tag per project |

## App Development

| Document | Description |
|---|---|
| [Flutter-OH Core Objects Introduction](./app-development/flutter-oh-core-objects.en.md) | Introduces the responsibilities of Flutter OH core objects and how they collaborate |
| [Core Objects Architecture Principles](./app-development/core-object-architecture.en.md) | Explains the architecture principles of the five core objects and their lifecycle coordination |
| [Flutter-OH App Lifecycle](./app-development/flutter-oh-app-lifecycle.en.md) | Lifecycle sequences for the two integration modes |
| [Flutter App/Module Launch Lifecycle Callback Guide](./app-development/app-module-lifecycle-callbacks.en.md) | Launch lifecycle callback mechanism and best practices |
| [OpenHarmony App Flutter Integration Guide](./app-development/ohos-integrate-flutter.en.md) | Guide for integrating a Flutter module into an OpenHarmony app |
| [Flutter OH App Build and Run Guide](./app-development/flutter-oh-app-build-guide.en.md) | App build, signing configuration, and Impeller toggle settings |
| [Building Flutter Projects with the hvigor Plugin](./app-development/hvigor-plugin-build.en.md) | Building Flutter projects with the Hvigor plugin |
| [Flutter App OpenHarmony Integration Guide](./app-development/flutter-ohos-integration.en.md) | Guide for adapting an existing Flutter app to the OpenHarmony platform |
| [Flutter Engine Asynchronous Creation and Destruction](./app-development/flutter-engine-async.en.md) | Using the Flutter Engine asynchronous creation and destruction capability |
| [Flutter Split View (Parallel View) Integration Guide](./app-development/flutter-split-view-integration.en.md) | Flutter split view integration, supporting foldables and other devices |

## Hybrid Development

| Document | Description |
|---|---|
| [How to Use FlutterPage](./hybrid-development/using-flutter-page.en.md) | Embedding Flutter pages with the FlutterPage component |
| [How to Add FlutterEntry Navigation in Hybrid Development](./hybrid-development/using-flutter-entry.en.md) | Using FlutterEntry for hybrid development of native and Flutter pages |
| [How to Use Flutter Channel](./hybrid-development/using-flutter-channel.en.md) | Bidirectional communication between Flutter and OpenHarmony via the Channel mechanism |
| [How to Use PlatformView](./hybrid-development/using-platform-view.en.md) | Embedding OpenHarmony native PlatformViews in Flutter |
| [PlatformView Same-Layer Rendering Adaptation Switching Guide](./hybrid-development/platform-view-same-layer-rendering.en.md) | Switching the PlatformView same-layer rendering adaptation |
| [How to Use the Multi-Engine FlutterEngineGroup](./hybrid-development/using-flutter-engine-group.en.md) | Managing multiple engine instances with FlutterEngineGroup |
| [FlutterEnginePreload Usage Guide](./hybrid-development/using-flutter-engine-preload.en.md) | FlutterEnginePreload preload and predraw mechanism |
| [Flutter OH Multi-Engine Scenario Development Guide](./hybrid-development/flutter-oh-multi-engine-dev-guide.en.md) | Flutter OH multi-engine scenario development guide |
| [How to Use a Module in Hybrid Development](./hybrid-development/using-module.en.md) | Referencing the flutter_module submodule from a native project for hybrid development |
| [How to Import Self-Rendered Content into Flutter](./hybrid-development/import-custom-rendered-content.en.md) | Importing native self-rendered content into Flutter via external textures |

## Plugins and Third-Party Libraries

| Document | Description |
|---|---|
| [Identifying Whether a Flutter Third-Party Library Requires OpenHarmony Adaptation](./plugin-and-package/flutter-library-ohos-check.en.md) | Identifying whether a Flutter third-party library needs OpenHarmony adaptation |
| [Flutter Third-Party Library OpenHarmony Platform Adaptation Guide](./plugin-and-package/ohos-flutter-lib-adaptation.en.md) | Complete workflow for adapting a Flutter third-party library to the OpenHarmony platform |
| [Developing a Flutter Plugin](./plugin-and-package/developing-plugin.en.md) | Developing Flutter native plugins that support the ohos platform |
| [Developing a Dart Package](./plugin-and-package/developing-package.en.md) | Developing pure Dart Flutter Packages |
| [Developing an FFI Plugin](./plugin-and-package/developing-an-ffi-plugin.en.md) | Developing FFI plugins that support the ohos platform |
| [Updating the Flutter Plugin Project Structure](./plugin-and-package/update-flutter-plugin-structure.en.md) | Updating the plugin's ohos directory from the project structure to the module structure |
| [OpenHarmony Platform Adapted Third-Party Libraries](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md#1openharmony%E5%B9%B3%E5%8F%B0%E5%B7%B2%E9%80%82%E9%85%8D%E4%B8%89%E6%96%B9%E5%BA%93) | List of third-party libraries already adapted for the OpenHarmony platform |

## Rendering Engine

| Document | Description |
|---|---|
| [Flutter OH Impeller and Skia Rendering Engine Switching Guide](./rendering-engine/rendering-engine-switching.en.md) | How to switch between the Impeller and Skia rendering engines |
| [Flutter OHOS External Texture Adaptation Introduction](./rendering-engine/flutter-external-texture.en.md) | Texture registration flow for video/camera/images |
| [Flutter OHOS External Texture First Frame (Background) Customization](./rendering-engine/flutter-external-texture-first-frame.en.md) | Customizing the first-frame background of external textures |
| [How to Use the LTPO Feature](./rendering-engine/using-ltpo.en.md) | Adaptive dynamic screen refresh rate |
| [Flutter OHOS Rendering Pipeline and Exception Diagnosis Tutorial](./rendering-engine/rendering-pipeline-and-exception-diagnosis-guide.en.md) | Rendering pipeline analysis and exception diagnosis methods |

## Performance Tuning

| Document | Description |
|---|---|
| [Performance Analysis Demarcation Guide](./performance/perf-delimitation-guide.en.md) | How to locate the module responsible for a performance issue |
| [Performance Analysis Step 1: Sorting Out the Thread Sequence](./performance/perf-analysis-threads-sequence.en.md) | Introduces Flutter rendering-related threads and their order |
| [Performance Analysis - Frame Rendering Tracking](./performance/perf-frame-rendering-tracking.en.md) | Single-frame tracing methods for analyzing jank/frame drops |
| [Performance Analysis - Swipe Response Latency](./performance/perf-sliding-response-time.en.md) | Trace analysis and latency optimization for scrolling scenarios |
| [Performance Tuning - Image Loading](./performance/perf-tuning-image-loading.en.md) | Optimization techniques such as image preloading and caching |
| [Performance Tuning - Memory Analysis and Optimization Practices](./performance/perf-tuning-memory-analysis.en.md) | Memory analysis methods for Flutter apps on HarmonyOS |
| [Performance Tuning - Enabling PGO with the BiSheng Compiler](./performance/perf-tuning-bisheng-pgo.en.md) | Improving runtime performance with the BiSheng compiler PGO |
| [Performance Optimization - Preloading the Render Pipeline](./performance/perf-optimization-preload-render-pipeline.en.md) | Solving white-screen issues during page transitions |
| [Performance Tuning Index](./performance/README.en.md) | Detailed performance tuning index (including environment configuration) |

## Load Reduction and Power Optimization

| Document | Description |
|---|---|
| [LTPO Load Reduction Solution](./power-consumption/power-consumption-ltpo.en.md) | LTPO smart refresh: raises the frame rate during interaction and falls back to a low-power tier when idle. |
| [0 Dirty Region Render Skipping](./power-consumption/power-consumption-skip-dirty-region.en.md) | 0 dirty region render skipping: skips subsequent drawing and submission when the page has no changes. |
| [Simple Occlusion Culling](./power-consumption/power-consumption-occlusion-culling.en.md) | Impeller simple occlusion culling: discards invalid draw commands covered by solid color. |
| [Pausing Drawing When the Page Is Invisible](./power-consumption/power-consumption-eliminate-redundant-drawing.en.md) | Pausing drawing when the page is invisible: prevents redundant drawing from WebView / PlatformView. |
| [Flutter OH Load Reduction and Power Optimization](./power-consumption/README.en.md) | Detailed index for load reduction and power optimization |

## Debugging

| Document | Description |
|---|---|
| [Flutter OH Hot Reload Operation Guide](./debugging/hot-reload-guide.en.md) | Use hot reload / hot restart in Debug mode to quickly preview Dart code changes |
| [Debugging Dart Code](./debugging/debugging-dart-code.en.md) | Debug Dart code with VS Code / Android Studio / DevEco Studio |
| [Native Code Breakpoint Debugging](./debugging/native-arkts-debugging-guide.en.md) | Debug ArkTS / Native code with DevEco Studio |
| [Debugging OpenHarmony Apps/Services](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2/ohos-debugging-app-0000001545729889-V2) | Official OpenHarmony documentation: debugging apps/services |
| [Analyzing Flutter-Related CppCrash Stacks](./debugging/flutter-cppcrash-stack-analysis.en.md) | Use llvm-addr2line to analyze Flutter-related CppCrash stacks |
| [Dart Stack Symbolization](./debugging/dart-stack-symbolization.en.md) | Use the flutter symbolize tool to restore Release/Profile mode stacks |
| [Memory Leaks and Stability Troubleshooting](./debugging/memory-and-stability-troubleshooting.en.md) | Jank/frame drop and ArkTS / Native memory leak analysis |
| [Debugging Guide Index](./debugging/README.en.md) | Detailed debugging guide index |

## Troubleshooting

| Document | Description |
|---|---|
| [DFX Troubleshooting Navigation](./troubleshooting/dfx/README.en.md) | Problem diagnosis methodology based on HarmonyOS DFX capabilities (HiAppEvent/HiLog/HiCollie/HiTrace) |
| [Crash Locating](./troubleshooting/dfx/dfx-crash.en.md) | Locating app crashes (Native/Dart/ETS exceptions) |
| [App Freeze Locating](./troubleshooting/dfx/dfx-appfreeze.en.md) | Locating app freezes, unresponsiveness, and frozen screens |
| [Jank and Frame Drop Locating](./troubleshooting/dfx/dfx-performance.en.md) | Locating UI jank, unsmooth scrolling, and frame drops |
| [Memory/GPU Locating](./troubleshooting/dfx/dfx-memory.en.md) | Locating memory and GPU issues such as OOM, black screens, and rendering anomalies |
| [Log Capture](./troubleshooting/dfx/dfx-logging.en.md) | Log capture, filtering, and viewing methods |
| [DFX Event Catalog](./troubleshooting/dfx/dfx-hiappevent.en.md) | Full catalog of DFX events and parameters reported through HiAppEvent |
| [Jank and Latency In-Depth Analysis](./troubleshooting/dfx/dfx-jank-latency.en.md) | In-depth analysis of scrolling jank, frame drops, and latency issues |
| [Load and Power Consumption Locating](./troubleshooting/dfx/dfx-power-load.en.md) | Locating load anomalies and power consumption issues |
| [External Texture Issue Locating](./troubleshooting/dfx/dfx-texture.en.md) | Locating external texture issues |
| [Multi-Device Adaptation Issue Locating](./troubleshooting/dfx/dfx-multi-device.en.md) | Locating multi-device adaptation issues |
| [Sliding Jank Introduction](./troubleshooting/dfx/dfx-sliding-introduction.en.md) | Concepts of Flutter scrolling jank and frame drops |
| [Tap Response and Completion Latency Introduction](./troubleshooting/dfx/dfx-latency-introduction.en.md) | Introduction to Flutter tap response and completion latency analysis |
| [Troubleshooting Index](./troubleshooting/README.en.md) | Master index for DFX troubleshooting |

## FAQ

| Document | Description |
|---|---|
| [Environment Setup Issues](./faq/README.en.md#environment-setup) | Environment issues: SDK configuration, emulator, long paths, cross-platform copying |
| [Engine Compilation Issues](./faq/README.en.md#engine-compilation) | Recommended build environment versions and artifact generation for the Flutter OH Engine |
| [App Build Issues](./faq/README.en.md#app-build) | Build errors, dependency conflicts, missing so packaging, cross-disk issues |
| [Signing and Release Issues](./faq/README.en.md#signing-and-release) | Auto signing, Release build anomalies, debug har crashing after release |
| [Code Development Issues](./faq/README.en.md#code-development) | Platform checks, resource access, foldable adaptation, startup crashes |
| [Third-Party Library and Plugin Adaptation Issues](./faq/README.en.md#plugin-adaptation) | Plugin sync failures, dependency conflicts, MissingPluginException, etc. |
| [Rendering Engine and UI Issues](./faq/README.en.md#rendering-and-ui) | WebView stretching, foldables, splash flicker, Impeller jagged edges |
| [Runtime Issues](./faq/README.en.md#runtime-issues) | Runtime errors, white-screen crashes, safe-area anomalies |
| [Crash Analysis and Debugging Issues](./faq/README.en.md#crash-and-debug) | Engine debugging, startup crashes, providing reproducible demos |
| [Permission and Security Issues](./faq/README.en.md#permission-and-security) | Where to declare permissions, permission scenarios, feature-permission mapping table |
| [FAQ Index](./faq/README.en.md) | Detailed FAQ index |

## Scenario-Based Cases

| Document | Description |
|---|---|
| [App Release and Launch Crash Case](./cases/app-release-crash-case.en.md) | Analysis and solutions for launch crashes after releasing an app to invite testing or official release |
| [Login Integration Case](./cases/huawei-id-login-case.en.md) | Integration practice for adding HUAWEI ID one-tap login to Flutter |
| [Flutter Module Debugging Case](./cases/module-debugging-case.en.md) | Crash caused by thread merging during Flutter module debugging, where breakpoints block the UI thread |
| [Flutter OHOS ICU File Upgrade Issues and Solutions](./cases/icu-upgrade-case.en.md) | Compatibility issues and solutions after a major OHOS ICU library upgrade |
| [Flutter Multi-Device Adaptive DPI Guide](./cases/multi-device-responsive-dpi-guide.en.md) | Core strategies, breakpoint system, layout adaptation, and best practices for multi-device adaptive DPI |
| [Plugin Missing After Import Case](./cases/plugin-missing-after-release-build-case.en.md) | Analysis and solutions for plugins missing after an APP release build |
| [WebView Payment White Screen Case](./cases/webview-white-screen-case.en.md) | Analysis and solutions for the webview payment white screen (custom scheme) issue |
| [Scenario-Based Cases Index](./cases/README.en.md) | Detailed index of scenario-based cases |

## Sample Code

| Document | Description |
|---|---|
| [flutter_samples](https://gitcode.com/CPF-Flutter/flutter_samples) | Flutter sample code repository |

## API Reference

| Document | Description |
|---|---|
| [Flutter OHOS Adaptation Layer API Reference](./api-reference/flutter-ohos-api-guide.en.md) | API usage for core classes such as FlutterAbility, FlutterEntry, FlutterEngine, and FlutterView |
| [Flutter Adaptation Layer APIs](./api-reference/README.en.md) | API overview (per-class reference index generated from source paths) |

## Version Notes

| Document | Description |
|---|---|
| [Flutter OH Version Notes](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md) | Version evolution plan and branching strategy |
| [Flutter OH Version Upgrade Guide](./version/flutter-oh-upgrade-guide.en.md) | Flutter OH version upgrade guide |
| [Flutter 3.35 OpenHarmony Upgrade Guide](./version/flutter-3.35-openharmony-upgrade-guide.en.md) | Flutter 3.35 OpenHarmony upgrade guide |

## AI Skills

| Document | Description |
|---|---|
| [AI Skills](./skills/README.en.md) | Index of AI skills accompanying the Flutter OHOS docs (crash analysis, performance diagnosis, etc.) |
