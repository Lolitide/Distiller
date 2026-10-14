# Flutter-OH核心对象简介

本文介绍 `@ohos/flutter_ohos` Embedding 核心对象在 Flutter-OH 中的作用及彼此协作关系。集成方式、生命周期回调与示例代码见 [Flutter-OH应用生命周期](./flutter-oh-app-lifecycle.md)。

`FlutterAbility` 与 `FlutterEntry` 是 Embedding 的两类 Host 入口：前者用于独立 Flutter 应用，对接 `UIAbility` 生命周期；后者用于 Add-to-App，在 ArkUI 页面中以页面级 Host 承载 Flutter 模块。

`FlutterAbilityAndEntryDelegate` 是二者共享的内部协调者，负责 Engine 创建、View 绑定与生命周期下发。

`FlutterManager` 是进程内单例，维护 Ability、`WindowStage` 与 `FlutterView` 的注册索引。

`FlutterEngine` 是 Flutter 的运行时，负责执行 Dart 代码、管理插件，并与原生层通过 Channel 通信。要把 Flutter 画面显示在页面上，需要 `FlutterView` 与 `FlutterPage` 配合：`FlutterView` 由框架创建，负责与 Engine 对接、处理视口指标与键盘/返回键等非触摸输入；`FlutterPage` 是开发者在 ArkUI `build()` 中使用的组件，通过 `viewId` 与 `FlutterView` 关联。`PlatformPlugin` 则把剪贴板、震动等鸿蒙系统能力暴露给 Dart 侧。

Embedding 设计与 Android Embedding V2 一致：

| Android | OHOS | 角色 |
|---------|------|------|
| `FlutterActivity` | `FlutterAbility` | 全屏 Flutter 宿主 |
| `FlutterFragment` | `FlutterEntry` | 页面级 Host |
| `FlutterActivityAndFragmentDelegate` | `FlutterAbilityAndEntryDelegate` | 共享内部协调者 |
| `FlutterView` | `FlutterView` + `FlutterPage` | 渲染视图（逻辑对象 + ArkUI 组件） |
| `FlutterEngine` | `FlutterEngine` | 引擎容器 |

下文分节展开各核心对象职责与协作关系。

---

## 核心对象协作关系总览

### Flutter-OH核心对象垂直分层

![Vertical layering class diagram](../media/app-development/vertical-layering-class-diagram.PNG)

<p align="center"><strong>图1</strong> Flutter-OH 核心对象垂直分层</p>

垂直分层图按职责将 Embedding 划分为三层：上层承接业务与插件扩展，中层衔接鸿蒙系统与 Flutter 运行时，底层提供 Dart 执行与渲染能力。各层要点如下：

**业务 / 插件层**：插件注册与 Platform View 等应用侧扩展。

**框架 / 适配层**：`FlutterAbility`、`FlutterEntry` 作为应用入口，由 `Delegate` 统一创建并管理 `FlutterEngine`、`PlatformPlugin` 与 UI 视图；其中 `FlutterManager` 维护 `FlutterView` 注册表，`FlutterPage` 在 ArkUI 页面中承载画面。

**Native Engine**：`libflutter.so` 是 Flutter C++ 引擎，提供 Dart VM 执行、UI 布局与绘制、帧合成渲染，并通过 NAPI 与上层 ArkTS Embedding 交换平台消息与渲染表面。

### Flutter-OH核心对象水平协作

![Horizontal collaboration class diagram](../media/app-development/horizontal-collaboration-class-diagram.PNG)

<p align="center"><strong>图2</strong> Flutter-OH 核心对象水平协作</p>

水平协作图从运行时视角说明核心对象如何衔接：Embedding 依赖三条数据通路完成跨层工作——将 Flutter 画面渲染到屏幕、在 ArkTS 与 Dart 之间传递平台消息、将鸿蒙前后台状态同步给 Dart 侧。通路如下：

```text
通路 A · 渲染
  ArkUI XComponent Surface
    → FlutterNapi.xComponentAttach / setViewportMetrics   ← 经 NAPI 下沉
      → libflutter.so (通过 viewId 定位 Shell)
        → Dart Framework (LayerTree → SceneBuilder)
  纹理注册：FlutterRenderer.registerTexture → FlutterNapi → libflutter.so

通路 B · Platform Message（双向）
  PlatformPlugin / FlutterPlugin
    ↔ System Channel / MethodChannel / EventChannel   ← ArkTS Embedding
      ↔ DartExecutor / DartMessenger
        ↔ FlutterNapi.dispatchPlatformMessage / handlePlatformMessage  ← 桥梁
          ↔ libflutter.so ↔ Dart (BinaryMessenger)

通路 C · 应用生命周期
  UIAbility.onForeground/onBackground
    或 Page.onPageShow/onPageHide
      → Delegate.onShow/onHide
        → LifecycleChannel ("flutter/lifecycle")
          → Dart WidgetsBindingObserver
```

通路 C 在鸿蒙侧对应的完整回调时序见 [Flutter-OH应用生命周期](./flutter-oh-app-lifecycle.md)。

---

## FlutterAbilityAndEntryDelegate

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

**作用**：抽取 `FlutterAbility` 与 `FlutterEntry` 的公共逻辑，统一处理 Engine 创建、Dart 启动、插件绑定与生命周期同步，避免两套宿主重复实现。

**用法**：应用开发者**不直接实例化** Delegate，而是继承 `FlutterAbility` 或 `FlutterEntry`，在子类中重写 Host 策略方法（如 `configureFlutterEngine`、`pagePath`）间接配置。

> [!WARNING]
> - Delegate 由框架在 Host 创建时自动管理，勿绕过 Host 自行 `new FlutterEngine` 或 `new FlutterView`。
> - 需要自定义 Engine 获取、缓存或销毁策略时，重写 Host 方法（如 `provideFlutterEngine`、`shouldDestroyEngineWithHost`），而非修改 Delegate 源码。

---

## FlutterManager

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

**作用**：进程内单例，作为 Embedding 注册中心，供各组件通过 `context` 或 `viewId` 查找 Ability、`WindowStage` 与 `FlutterView`。

**用法**：

- **独立 Flutter 应用**：由 `FlutterAbility` 在 `onCreate` / `onWindowStageCreate` / `onDestroy` 中自动 `push` / `pop`，一般无需手动调用。
- **Add-to-App**：宿主 `EntryAbility`（原生 `UIAbility`）须在 `onCreate`、`onWindowStageCreate`、`onWindowStageDestroy`、`onDestroy` 中调用 `FlutterManager.getInstance().pushUIAbility()` / `pushWindowStage()` 及对应的 `pop` 方法。完整示例见 [Flutter-OH应用生命周期](./flutter-oh-app-lifecycle.md)。
- **创建 FlutterView**：`FlutterManager.createFlutterView(context)` 创建 `FlutterView` 实例、分配 `viewId` 并注册到管理器。单引擎场景下由 `FlutterAbility` / `FlutterEntry` 内部的 `Delegate` 在 `onWindowStageCreate` 或 `aboutToAppear` 时自动调用，开发者通过 `getFlutterView()` 获取即可，**一般无需手动调用**。多引擎或自定义 Engine 绑定时须自行调用，参见 [如何使用多引擎 FlutterEngineGroup](../hybrid-development/using-flutter-engine-group.md)。

```ts
// EntryAbility.ets（Add-to-App 宿主 UIAbility，节选）
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ExclusiveAppComponent, FlutterManager } from '@ohos/flutter_ohos';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {
  getAppComponent(): UIAbility { return this; }
  detachFromFlutterEngine(): void {}

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    windowStage.loadContent('pages/MainPage'); // 加载原生主导航，非 Flutter 首页
  }

  onWindowStageDestroy(): void {
    FlutterManager.getInstance().popWindowStage(this);
  }

  onDestroy(): void {
    FlutterManager.getInstance().popUIAbility(this);
  }
}
```

> [!WARNING]
> - Ability 或 `WindowStage` 销毁时**必须** `pop`，否则后续页面 `viewId` 绑定、插件上下文解析会异常。
> - `createFlutterView()` 自动生成的 `viewId` 带 `oh_flutter_` 前缀，与 C++ 层 XComponent 查找逻辑一致，**请勿修改此前缀**。`FlutterAbility` / `FlutterEntry` 未提供重写 `viewId` 的 Host 钩子；若高级场景须自定义 `viewId`，可使用 `new FlutterView(viewId, context)` 构造并自行注册，但自定义值仍须保留 `oh_flutter_` 前缀。

---

## FlutterAbility

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

**作用**：独立 Flutter 应用的 Ability 级入口，继承 `UIAbility`，在 Ability 生命周期回调中驱动 Delegate，完成 Engine 创建、首页 `loadContent` 及 `viewId` 注入。

**用法**：

```ts
// EntryAbility.ets
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
```

首页 `Index.ets` 通过 `@LocalStorageLink('viewId')` 接收框架注入的 `viewId`，并渲染 `FlutterPage({ viewId })`。可选重写 `pagePath()` 更换首页路径。生命周期扩展见 [Flutter-OH应用生命周期](./flutter-oh-app-lifecycle.md)。

> [!WARNING]
> - 重写 `onForeground`、`onBackground` 等生命周期方法时**必须调用 `super`**，否则 Dart `AppLifecycleState` 与渲染可能异常。
> - `pagePath()` 返回值须与 `main_pages.json` 中注册的页面路径一致。
> - 插件注册统一在 `configureFlutterEngine` 中完成，且须调用 `super.configureFlutterEngine()`。

---

## FlutterEntry

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

**作用**：Add-to-App 的页面级入口，以普通 ArkTS 类嵌入 ArkUI `@Component`；复用所在 Ability 的 `WindowStage`，由页面生命周期驱动 Delegate。

**用法**：

```ts
// FlutterRoutePage.ets
aboutToAppear() {
  this.flutterEntry = new MyFlutterEntry(getContext(this))
  this.flutterEntry.aboutToAppear()
  this.flutterView = this.flutterEntry.getFlutterView()
}
onPageShow()  { this.flutterEntry?.onPageShow() }
onPageHide()  { this.flutterEntry?.onPageHide() }
aboutToDisappear() { this.flutterEntry?.aboutToDisappear() }

// build() 中
FlutterPage({ viewId: this.flutterView?.getId() })
```

插件注册通过继承 `FlutterEntry` 并重写 `configureFlutterEngine()`。完整示例见 [Flutter-OH应用生命周期](./flutter-oh-app-lifecycle.md)。

> [!WARNING]
> - 须在 ArkUI 的 `aboutToAppear`、`onPageShow`、`onPageHide`、`aboutToDisappear` 中**成对、主动调用** Entry 同名方法，遗漏 `onPageShow` / `onPageHide` 会导致 Dart 生命周期卡在错误状态。
> - 使用 `Navigation` 时，在 `onShown` / `onHidden` / `onDisAppear` 等路由回调中同步调用对应 Entry 方法。
> - 宿主 `UIAbility` 的 `loadContent` 应加载**原生主导航**，而非 Flutter 首页。

---

## FlutterEngine

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

`FlutterEngine` 是 **Flutter 运行在鸿蒙进程内的容器**：

- ✅ 持有并驱动一个 Dart Isolate（通过 `DartExecutor`）
- ✅ 持有与 C++ Shell 的绑定（通过 `FlutterNapi`）
- ✅ 统一管理所有内建 Channel 和插件注册表
- ❌ 不负责窗口管理（由 `FlutterView` 与 `PlatformPlugin` 承担）
- ❌ 不直接处理触摸事件（事件经 `FlutterPage` / `XComponent` 进入 Native 层）

可将 Engine 理解为已启动的服务器：`FlutterNapi` 是主板总线，`DartExecutor`、Channel、`Renderer`、Plugin 是板卡，`FlutterView` 是显示器。

**用法**：

- 由 `FlutterAbility` / `FlutterEntry` 内部创建，开发者通过 `configureFlutterEngine()` 注册插件。
- 需从原生侧切换 Dart 路由时，使用 `flutterEngine.getNavigationChannel()?.pushRoute('/path')`，勿重复调用 `executeDartEntrypoint()`。

> [!WARNING]
> - 每个 Engine 的 Dart Isolate **只能启动一次**；切页应使用 `Navigator` 或 `pushRoute`，而非再次执行 entrypoint。
> - 在 `configureFlutterEngine` 回调之前访问 Channel 可能为 null，须等引擎 `init()` 完成。
> - **同一 Engine 活跃态下只 attach 一个 `FlutterView`；切换页面前必须先 detach 再 attach**，否则可能导致渲染异常或 Engine 状态错误。

---

## FlutterView & FlutterPage

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

为适配 ArkUI 声明式模型，鸿蒙将 Android 单一的 `FlutterView` 拆为逻辑视图与 UI 组件两部分。`FlutterView` 管理视口指标、Engine 的 attach/detach，以及键盘、返回键、窗口 inset 等，对应 XComponent 的逻辑侧。`FlutterPage` 是 ArkUI `@Component`，在 `build()` 中通过 `XComponent({ id: viewId })` 承载 Flutter 画面；它经 `viewId` 关联 `FlutterView`，自身不持有 View 实例。

**用法**：

- `FlutterView` 由 `FlutterManager.createFlutterView(context)` 创建（单引擎场景下经 `Delegate` 自动调用，见 [FlutterManager](#fluttermanager)），在 `onWindowStageCreate`（独立应用）或 `aboutToAppear`（Add-to-App）时完成；开发者通过 `getFlutterView()` 或 `LocalStorage` 取得 `viewId`。
- 在 ArkUI `build()` 中声明 `FlutterPage({ viewId: this.viewId })` 即可嵌入 Flutter 画面。

> [!WARNING]
> - `viewId` 为空或未传入 `FlutterPage` 时表现为**黑屏**；须确认 Entry 已 `aboutToAppear` 且已取得 `FlutterView`。
> - `FlutterPage` 不宜在 `viewId` 未就绪时嵌套复杂原生布局，避免 XComponent 尺寸为 0。
> - 键盘避让、安全区等可在 `FlutterPage.aboutToAppear` 中通过 `FlutterView.setCheckKeyboard()`、`setCheckFullScreen()` 等配置。
> - **返回键**：在嵌入 `FlutterPage` 的 ArkUI `@Component` 中处理——普通页面重写 `onBackPress()`，`Navigation` 场景在 `NavDestination.onBackPressed()` 中转发。常见写法为 `flutterEntry.onBackPress()`，或通过 `getContext(this).eventHub.emit('EVENT_BACK_PRESS')` 通知 Flutter 处理返回（须 `return true` 消费事件）。原生导航栈与 Flutter 路由协同时，可在 `FlutterEntry` 子类重写 `popSystemNavigator()`。示例见 [如何使用混合开发添加跳转 FlutterEntry](../hybrid-development/using-flutter-entry.md)、[OpenHarmony应用集成Flutter指导](./ohos-integrate-flutter.md)。

---

## PlatformPlugin

> 源码目录：`engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/`（ArkTS Embedding）

**作用**：Embedding 内置的平台适配层，通过 `PlatformChannel`（Dart 侧 `SystemChannels.platform`，通道名 `flutter/platform`）将鸿蒙系统能力桥接到 Flutter Framework，处理剪贴板、震动反馈、系统音效、状态栏/导航栏样式、屏幕方向、系统返回（`popSystemNavigator`）等。路由（`NavigationChannel` / `flutter/navigation`）、应用生命周期（`LifecycleChannel` / `flutter/lifecycle`）等由 `FlutterEngine` 内其他 System Channel 承担，**不由 `PlatformPlugin` 管理**。

**用法**：

- `FlutterEngine` 初始化时会创建 `PlatformChannel`；`FlutterAbilityAndEntryDelegate.onAttach()` 中调用 `providePlatformPlugin()` 创建 `PlatformPlugin` 并绑定消息 Handler，**一般无需手动实例化**。
- 独立应用中，`onCreate` 内先执行 `onAttach()`（创建引擎与 `PlatformPlugin`），再调用 `setUIAbilityContext()` 注入 Ability 上下文；Dart 入口在 `onWindowStageCreate` 中执行。**`PlatformChannel` 完整消息处理以引擎初始化完成、`onWindowStageCreate` 执行 Dart 入口后为准**；此前到达的消息由 `processPendingMessages()` 尝试处理，上下文或 Handler 未就绪时可能无法响应。
- 需自定义系统返回等行为时，在 `FlutterAbility` / `FlutterEntry` 子类中重写 `popSystemNavigator()`（Host 实现 `PlatformPluginDelegate`）；高级场景可重写 `providePlatformPlugin()` 返回自定义实例。混合导航示例见 [如何使用混合开发添加跳转 FlutterEntry](../hybrid-development/using-flutter-entry.md)。

> [!WARNING]
> - 剪贴板、震动、`SystemChrome` 等常见平台能力已由框架实现，**勿重复注册同名 MethodChannel**。
> - `PlatformPlugin` 随 Delegate `onAttach` 创建、`onDetach` 时 `destroy()`，生命周期与 Host 绑定。
> - 注册时序与 `PlatformChannel` 消息处理细节见 [核心对象架构原理说明](./core-object-architecture.md) §7.4；System Channel 全貌见 [架构说明](../getting-started/architecture.md#72-系统通道与宿主通道)；API 详见 [PlatformPlugin](../api-reference/plugin/PlatformPlugin/README.md)。
