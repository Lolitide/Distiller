# Flutter-OH Core Objects Overview

This document introduces the role and collaboration of the `@ohos/flutter_ohos` Embedding core objects in Flutter-OH. For integration modes, lifecycle callbacks, and sample code, see [Flutter-OH App Lifecycle](./flutter-oh-app-lifecycle.en.md).

`FlutterAbility` and `FlutterEntry` are the two types of Host entries in the Embedding: the former is used for standalone Flutter apps, interfacing with the `UIAbility` lifecycle; the latter is used for Add-to-App, serving as a page-level Host within ArkUI pages to carry Flutter modules.

`FlutterAbilityAndEntryDelegate` is the shared internal coordinator for both, responsible for Engine creation, View binding, and lifecycle dispatch.

`FlutterManager` is a process-level singleton that maintains the registration index for Ability, `WindowStage`, and `FlutterView`.

`FlutterEngine` is the Flutter runtime, responsible for executing Dart code, managing plugins, and communicating with the native layer via Channels. To display Flutter content on a page, `FlutterView` and `FlutterPage` work together: `FlutterView` is created by the framework and is responsible for interfacing with the Engine, handling viewport metrics, and non-touch input such as keyboard and back button; `FlutterPage` is the component developers use in ArkUI `build()`, associated with `FlutterView` via `viewId`. `PlatformPlugin` exposes HarmonyOS system capabilities such as clipboard and vibration to the Dart side.

The Embedding design is consistent with Android Embedding V2:

| Android | OHOS | Role |
|---------|------|------|
| `FlutterActivity` | `FlutterAbility` | Full-screen Flutter host |
| `FlutterFragment` | `FlutterEntry` | Page-level Host |
| `FlutterActivityAndFragmentDelegate` | `FlutterAbilityAndEntryDelegate` | Shared internal coordinator |
| `FlutterView` | `FlutterView` + `FlutterPage` | Render view (logical object + ArkUI component) |
| `FlutterEngine` | `FlutterEngine` | Engine container |

The following sections detail each core object's responsibilities and collaboration.

---

## Core Object Collaboration Overview

### Vertical Layering of Flutter-OH Core Objects

![Vertical layering class diagram](../media/app-development/vertical-layering-class-diagram.PNG)

<p align="center"><strong>Figure 1</strong> Vertical layering of Flutter-OH core objects</p>

The vertical layering diagram divides the Embedding into three layers by responsibility: the upper layer handles business logic and plugin extensions, the middle layer bridges the HarmonyOS system and Flutter runtime, and the lower layer provides Dart execution and rendering capabilities. Key points of each layer:

**Business / Plugin Layer**: Plugin registration, Platform View, and other application-side extensions.

**Framework / Adaptation Layer**: `FlutterAbility` and `FlutterEntry` serve as app entry points, with `Delegate` uniformly creating and managing `FlutterEngine`, `PlatformPlugin`, and UI views; `FlutterManager` maintains the `FlutterView` registry, and `FlutterPage` carries the rendering surface in ArkUI pages.

**Native Engine**: `libflutter.so` is the Flutter C++ engine, providing Dart VM execution, UI layout and drawing, frame composition and rendering, and exchanging platform messages and rendering surfaces with the upper ArkTS Embedding via NAPI.

### Horizontal Collaboration of Flutter-OH Core Objects

![Horizontal collaboration class diagram](../media/app-development/horizontal-collaboration-class-diagram.PNG)

<p align="center"><strong>Figure 2</strong> Horizontal collaboration of Flutter-OH core objects</p>

The horizontal collaboration diagram illustrates how core objects connect from a runtime perspective: the Embedding relies on three data pathways to accomplish cross-layer work — rendering Flutter content to the screen, passing platform messages between ArkTS and Dart, and syncing HarmonyOS foreground/background state to the Dart side. The pathways are:

```
Pathway A · Rendering
  ArkUI XComponent Surface
    → FlutterNapi.xComponentAttach / setViewportMetrics   ← via NAPI
      → libflutter.so (locates Shell by viewId)
        → Dart Framework (LayerTree → SceneBuilder)
  Texture registration: FlutterRenderer.registerTexture → FlutterNapi → libflutter.so

Pathway B · Platform Message (bidirectional)
  PlatformPlugin / FlutterPlugin
    ↔ System Channel / MethodChannel / EventChannel   ← ArkTS Embedding
      ↔ DartExecutor / DartMessenger
        ↔ FlutterNapi.dispatchPlatformMessage / handlePlatformMessage  ← bridge
          ↔ libflutter.so ↔ Dart (BinaryMessenger)

Pathway C · App Lifecycle
  UIAbility.onForeground/onBackground
    or Page.onPageShow/onPageHide
      → Delegate.onShow/onHide
        → LifecycleChannel ("flutter/lifecycle")
          → Dart WidgetsBindingObserver
```

For the complete callback sequence of Pathway C on the HarmonyOS side, see [Flutter-OH App Lifecycle](./flutter-oh-app-lifecycle.en.md).

---

## FlutterAbilityAndEntryDelegate

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

**Role**: Extracts common logic from `FlutterAbility` and `FlutterEntry`, uniformly handling Engine creation, Dart launch, plugin binding, and lifecycle synchronization, avoiding duplicate implementations in both hosts.

**Usage**: App developers do **not** directly instantiate the Delegate. Instead, they subclass `FlutterAbility` or `FlutterEntry` and override Host strategy methods (e.g., `configureFlutterEngine`, `pagePath`) to configure indirectly.

**Notes**:

- The Delegate is automatically managed by the framework when the Host is created. Do not bypass the Host to `new FlutterEngine` or `new FlutterView` directly.
- When you need custom Engine acquisition, caching, or destruction strategies, override Host methods (e.g., `provideFlutterEngine`, `shouldDestroyEngineWithHost`) rather than modifying Delegate source code.

---

## FlutterManager

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

**Role**: Process-level singleton, serving as the Embedding registry. Components can look up Ability, `WindowStage`, and `FlutterView` via `context` or `viewId`.

**Usage**:

- **Standalone Flutter app**: `FlutterAbility` automatically `push` / `pop` in `onCreate` / `onWindowStageCreate` / `onDestroy`. Manual calls are generally unnecessary.
- **Add-to-App**: The host `EntryAbility` (native `UIAbility`) must call `FlutterManager.getInstance().pushUIAbility()` / `pushWindowStage()` and corresponding `pop` methods in `onCreate`, `onWindowStageCreate`, `onWindowStageDestroy`, and `onDestroy`. See [Flutter-OH App Lifecycle](./flutter-oh-app-lifecycle.en.md) for a complete example.
- **Creating a FlutterView**: `FlutterManager.createFlutterView(context)` creates a `FlutterView` instance, allocates a `viewId`, and registers it with the manager. In single-engine scenarios, this is automatically called by the `Delegate` inside `FlutterAbility` / `FlutterEntry` during `onWindowStageCreate` or `aboutToAppear`. Developers obtain it via `getFlutterView()` — **manual invocation is generally unnecessary**. For multi-engine or custom Engine binding, you must call it yourself; see [Using FlutterEngineGroup for Multiple Engine Instances](../hybrid-development/using-flutter-engine-group.en.md).

```typescript
// EntryAbility.ets (Add-to-App host UIAbility, excerpt)
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
    windowStage.loadContent('pages/MainPage'); // Load native main navigation, not Flutter home page
  }

  onWindowStageDestroy(): void {
    FlutterManager.getInstance().popWindowStage(this);
  }

  onDestroy(): void {
    FlutterManager.getInstance().popUIAbility(this);
  }
}
```

**Notes**:

- When Ability or `WindowStage` is destroyed, you **must** `pop` it. Otherwise, subsequent page `viewId` binding and plugin context resolution will fail.
- The `viewId` auto-generated by `createFlutterView()` has the `oh_flutter_` prefix, consistent with the C++ layer's XComponent lookup logic. **Do not modify this prefix.** `FlutterAbility` / `FlutterEntry` do not provide a Host hook to override `viewId`; if advanced scenarios require a custom `viewId`, you can use `new FlutterView(viewId, context)` to construct and register it yourself, but the custom value must still retain the `oh_flutter_` prefix.

---

## FlutterAbility

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

**Role**: The Ability-level entry for standalone Flutter apps. It extends `UIAbility` and drives the Delegate in Ability lifecycle callbacks to complete Engine creation, home page `loadContent`, and `viewId` injection.

**Usage**:

```typescript
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

The home page `Index.ets` receives the `viewId` injected by the framework via `@LocalStorageLink('viewId')` and renders `FlutterPage({ viewId })`. You can optionally override `pagePath()` to change the home page path. For lifecycle extensions, see [Flutter-OH App Lifecycle](./flutter-oh-app-lifecycle.en.md).

**Notes**:

- When overriding lifecycle methods such as `onForeground` and `onBackground`, you **must call `super`**, otherwise Dart `AppLifecycleState` and rendering may be abnormal.
- The return value of `pagePath()` must match the page path registered in `main_pages.json`.
- Plugin registration should be done uniformly in `configureFlutterEngine`, and `super.configureFlutterEngine()` must be called.

---

## FlutterEntry

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

**Role**: The page-level entry for Add-to-App. It is a plain ArkTS class embedded in an ArkUI `@Component`; it reuses the `WindowStage` of the host Ability and is driven by page lifecycle to operate the Delegate.

**Usage**:

```typescript
// FlutterRoutePage.ets
aboutToAppear() {
  this.flutterEntry = new MyFlutterEntry(getContext(this))
  this.flutterEntry.aboutToAppear()
  this.flutterView = this.flutterEntry.getFlutterView()
}
onPageShow()  { this.flutterEntry?.onPageShow() }
onPageHide()  { this.flutterEntry?.onPageHide() }
aboutToDisappear() { this.flutterEntry?.aboutToDisappear() }

// In build()
FlutterPage({ viewId: this.flutterView?.getId() })
```

Plugin registration is done by subclassing `FlutterEntry` and overriding `configureFlutterEngine()`. For a complete example, see [Flutter-OH App Lifecycle](./flutter-oh-app-lifecycle.en.md).

**Notes**:

- You must **call the corresponding Entry methods proactively and in pairs** in ArkUI's `aboutToAppear`, `onPageShow`, `onPageHide`, and `aboutToDisappear`. Missing `onPageShow` / `onPageHide` will cause the Dart lifecycle to get stuck in an incorrect state.
- When using `Navigation`, call the corresponding Entry methods in route callbacks such as `onShown` / `onHidden` / `onDisAppear`.
- The host `UIAbility`'s `loadContent` should load **native main navigation**, not the Flutter home page.

---

## FlutterEngine

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

`FlutterEngine` is the **container in which Flutter runs within the HarmonyOS process**:

- ✅ Holds and drives a Dart Isolate (via `DartExecutor`)
- ✅ Holds the binding to the C++ Shell (via `FlutterNapi`)
- ✅ Uniformly manages all built-in Channels and the plugin registry
- ❌ Does not handle window management (handled by `FlutterView` and `PlatformPlugin`)
- ❌ Does not directly handle touch events (events enter the native layer via `FlutterPage` / `XComponent`)

You can think of the Engine as a started server: `FlutterNapi` is the motherboard bus, `DartExecutor`, Channels, `Renderer`, and Plugin are expansion cards, and `FlutterView` is the display.

**Usage**:

- Created internally by `FlutterAbility` / `FlutterEntry`. Developers register plugins via `configureFlutterEngine()`.
- To switch Dart routes from the native side, use `flutterEngine.getNavigationChannel()?.pushRoute('/path')`. Do not call `executeDartEntrypoint()` again.

**Notes**:

- Each Engine's Dart Isolate **can only be started once**; use `Navigator` or `pushRoute` for page navigation, not re-executing the entrypoint.
- Accessing Channels before the `configureFlutterEngine` callback may return null; wait for the Engine's `init()` to complete.
- **Only one `FlutterView` may be attached to a live Engine at a time; you must detach before attaching a new one when switching pages**, otherwise rendering anomalies or Engine state errors may occur.

---

## FlutterView & FlutterPage

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

To adapt to the ArkUI declarative model, HarmonyOS splits the Android single `FlutterView` into two parts: a logical view and a UI component. `FlutterView` manages viewport metrics, Engine attach/detach, keyboard, back button, and window insets, corresponding to the logical side of the XComponent. `FlutterPage` is an ArkUI `@Component` that carries the Flutter rendering surface in `build()` via `XComponent({ id: viewId })`; it is associated with `FlutterView` via `viewId` and does not hold a View instance itself.

**Usage**:

- `FlutterView` is created by `FlutterManager.createFlutterView(context)` (automatically called by `Delegate` in single-engine scenarios; see [FlutterManager](#fluttermanager)), completed during `onWindowStageCreate` (standalone app) or `aboutToAppear` (Add-to-App). Developers obtain the `viewId` via `getFlutterView()` or `LocalStorage`.
- In ArkUI `build()`, declare `FlutterPage({ viewId: this.viewId })` to embed the Flutter rendering surface.

**Notes**:

- A blank or missing `viewId` passed to `FlutterPage` results in a **black screen**; ensure the Entry has called `aboutToAppear` and obtained a `FlutterView`.
- `FlutterPage` should not be nested with complex native layouts when `viewId` is not ready, to avoid zero-size XComponent.
- Keyboard avoidance, safe area, etc., can be configured in `FlutterPage.aboutToAppear` via `FlutterView.setCheckKeyboard()`, `setCheckFullScreen()`, etc.
- **Back button**: Handle it in the ArkUI `@Component` that embeds `FlutterPage` — override `onBackPress()` for regular pages, or forward it in `NavDestination.onBackPressed()` for `Navigation` scenarios. A common pattern is `flutterEntry.onBackPress()`, or notify Flutter to handle the back via `getContext(this).eventHub.emit('EVENT_BACK_PRESS')` (must `return true` to consume the event). For coordinating native navigation stack with Flutter routing, override `popSystemNavigator()` in the `FlutterEntry` subclass. See [Using FlutterEntry in Hybrid Development](../hybrid-development/using-flutter-entry.en.md) and [Integrating Flutter into OpenHarmony Apps](./ohos-integrate-flutter.en.md) for examples.

---

## PlatformPlugin

> Source code directory: `engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/ets/` (ArkTS Embedding)

**Role**: The Embedding's built-in platform adaptation layer. It bridges HarmonyOS system capabilities to the Flutter Framework via `PlatformChannel` (Dart side `SystemChannels.platform`, channel name `flutter/platform`), handling clipboard, vibration feedback, system sound, status bar/navigation bar styles, screen orientation, system back (`popSystemNavigator`), etc. Routing (`NavigationChannel` / `flutter/navigation`), app lifecycle (`LifecycleChannel` / `flutter/lifecycle`), and other System Channels are handled by other parts of `FlutterEngine` — **not by `PlatformPlugin`**.

**Usage**:

- `FlutterEngine` creates `PlatformChannel` during initialization; `FlutterAbilityAndEntryDelegate.onAttach()` calls `providePlatformPlugin()` to create the `PlatformPlugin` and bind message handlers. **Manual instantiation is generally unnecessary.**
- In standalone apps, `onCreate` first executes `onAttach()` (creating the engine and `PlatformPlugin`), then calls `setUIAbilityContext()` to inject the Ability context; the Dart entry is executed in `onWindowStageCreate`. **Complete `PlatformChannel` message handling is subject to engine initialization completion and Dart entry execution in `onWindowStageCreate`**; messages arriving before that are processed on a best-effort basis by `processPendingMessages()`, but may not be responded to if the context or handlers are not ready.
- To customize system back behavior, override `popSystemNavigator()` in `FlutterAbility` / `FlutterEntry` subclasses (the Host implements `PlatformPluginDelegate`); for advanced scenarios, override `providePlatformPlugin()` to return a custom instance. See [Using FlutterEntry in Hybrid Development](../hybrid-development/using-flutter-entry.en.md) for mixed navigation examples.

**Notes**:

- Common platform capabilities such as clipboard, vibration, and `SystemChrome` are already implemented by the framework. **Do not register duplicate MethodChannels with the same name.**
- `PlatformPlugin` is created on Delegate `onAttach` and `destroy()`ed on `onDetach`; its lifecycle is bound to the Host.
- For registration timing and `PlatformChannel` message handling details, see [Core Objects Architecture](./core-object-architecture.en.md) §7.4; for the full System Channel overview, see [Architecture](../getting-started/architecture.en.md#72-system-channels-and-host-channels); for API details, see [PlatformPlugin](../api-reference/plugin/PlatformPlugin/README.md).
