# Flutter-OH App Lifecycle

## Overview

This document introduces the two integration modes of Flutter-OH (`@ohos/flutter_ohos`) on OpenHarmony: [**Standalone Flutter app**](https://docs.flutter.dev/get-started/install) and [**Add-to-App**](https://docs.flutter.dev/add-to-app). Both are mainstream embedding paths officially defined by Flutter. Flutter-OH carries them via `FlutterAbility` and `FlutterEntry` respectively; see [Flutter-OH Core Objects Overview](./flutter-oh-core-objects.en.md) for details.

---

## 1. Integration Modes

| Integration Mode | Typical Use Case | Host | Flutter Entry |
| -------- | -------- | ---- | ------------ |
| **Standalone Flutter app** | `flutter create` project | `EntryAbility extends FlutterAbility` | Engine created inside `FlutterAbility` |
| **Add-to-App** | Embedding Flutter pages in an existing HarmonyOS app | `EntryAbility extends UIAbility` | `new FlutterEntry(context)` within the page |

### Standalone Flutter App

`FlutterAbility` extends `UIAbility` and overrides key lifecycle callbacks to integrate Flutter.

### Add-to-App

The host remains a native `UIAbility`. Flutter modules are embedded in ArkUI pages via `FlutterEntry`.

---

## 2. Lifecycle Sequence Overview

This section presents the lifecycle chains for both integration modes. Standalone Flutter app's `FlutterAbility` and its subclasses follow the [UIAbility component lifecycle](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-lifecycle); Add-to-App's Flutter pages are driven by the **ArkUI component lifecycle**, while the host `UIAbility` still follows the UIAbility lifecycle.

> [!NOTE]
>
> "Lifecycle" in this document refers to the native callback chain from Flutter app launch to first frame, page visibility changes, foreground/background transitions, and finally destruction.

### Standalone Flutter App

![](../media/app-development/Flutter-OH-Lifecycle.PNG)

<p align="center"><strong>Figure 1</strong> Standalone Flutter app lifecycle</p>

- **Launch**: `onCreate` registers `FlutterManager`; `onWindowStageCreate` loads the home page and creates the `FlutterEngine`; after engine creation, `configureFlutterEngine` is triggered, then Dart `main` is entered.
- **Foreground/Background transition**: `onForeground` / `onBackground`.
- **Exit**: `onWindowStageDestroy` / `onDestroy` releases the window and engine, and unregisters from `FlutterManager`.

### Add-to-App

![](../media/app-development/Flutter-OH-Lifecycle-Module.PNG)

<p align="center"><strong>Figure 2</strong> Embedded Flutter page lifecycle</p>

After the system triggers ArkUI component lifecycle, developers must **proactively call** the corresponding `FlutterEntry` methods in the respective callbacks (see [Add-to-App](#add-to-app)):

**Loading the Flutter page**

- **aboutToAppear**: Creates `FlutterEngine` and `FlutterView` (triggering [`configureFlutterEngine`](#4-engine-configuration-configureflutterengine) during the process), and provides `viewId` via `getFlutterView()`.
- **onPageShow**: Resumes rendering (persists until `onPageHide` is called).

**Leaving the Flutter page**

- **onPageHide**: Pauses rendering.
- **aboutToDisappear**: Destroys `FlutterEngine` and `FlutterView`, releasing engine and view resources.

---

## 3. Lifecycle Callbacks

This section introduces each lifecycle callback's trigger timing and extension points from the **app developer's** perspective. Embedding APIs such as `FlutterAbility` and `FlutterEntry` are implemented by the `@ohos/flutter_ohos` framework. Engine creation, view binding, and lifecycle synchronization are handled automatically by the framework; app-side developers typically do not need to concern themselves with the internal implementation. For core object collaboration, see [Flutter-OH Core Objects Overview](./flutter-oh-core-objects.en.md). For engine configuration such as plugin registration, see [Section 4](#4-engine-configuration-configureflutterengine).

> **Note**
>
> - Lifecycle callbacks execute on the main thread; perform only lightweight operations. Time-consuming tasks should be handled asynchronously or delegated to worker threads.
> - When overriding `FlutterAbility` / `FlutterEntry` lifecycle methods, you **must call `super`**, otherwise framework default handling and rendering may be abnormal. The call order of `super` differs between callbacks: `onForeground` / `onBackground` should call `super` **first**, then execute developer logic; `onDestroy` should call `super.onDestroy()` **after** developer logic, because `super` destroys the engine — data saving and resource release must be completed before the engine is destroyed.

### Standalone Flutter App

The app entry is `EntryAbility extends FlutterAbility`. Except for the extension points noted in the table below, other UIAbility callbacks are handled by the framework and generally do not need to be overridden.

| Callback | Trigger Timing | Framework Default Behavior | Developer Extension |
| ---- | -------- | ------------ | ------------ |
| `onCreate()` | First creation of the UIAbility instance | Registers `FlutterManager` | Perform one-time startup logic |
| `onWindowStageCreate()` | After `WindowStage` is created, before entering foreground | Creates `FlutterView`, loads home page via `loadContent` | Override `pagePath()` to change home page path (extension method, not a lifecycle callback) |
| `onForeground()` | Switching to foreground, before UI becomes visible | Resumes rendering | Acquire/restore native resources/services (e.g., location services) |
| `onBackground()` | After UI becomes fully invisible | Pauses rendering | Release unused native resources/services |
| `onWindowStageDestroy()` | Before instance destruction, after `WindowStage` is destroyed | Unregisters `WindowStage`, releases window resources | Release resources/services obtained via `WindowStage` |
| `onDestroy()` | Before UIAbility instance is destroyed (last callback) | Destroys engine and view | Save data, release system resources/services |

#### onCreate()

When the UIAbility instance is first created, the system triggers the `onCreate()` callback. Developers can perform one-time startup logic in this callback. The framework has already registered `FlutterManager` (the engine is created in `onWindowStageCreate`), so overriding is typically unnecessary. If you need to extend it, call `super.onCreate()`.

#### onWindowStageCreate()

After the UIAbility instance is created and before entering the foreground, the system creates the WindowStage. The framework completes `FlutterView` creation and home page loading here. To change the home page path, override the `pagePath()` extension method (not a lifecycle callback).

#### onForeground()

Before the UIAbility switches to the foreground and the UI becomes visible, the system triggers the `onForeground()` callback. The framework resumes rendering. Developers can acquire system resources or re-acquire resources released in `onBackground` (e.g., restore location). **Must call `super.onForeground()`**.

#### onBackground()

After the UIAbility's UI becomes fully invisible, the system triggers the `onBackground` callback. The framework pauses rendering. Developers can release unused resources when the UI is invisible (e.g., stop location). `onBackground()` has a short execution time; do not perform time-consuming operations such as saving user data or database transactions. **Must call `super.onBackground()`**.

#### onWindowStageDestroy()

Before the UIAbility instance is destroyed, the system triggers the `onWindowStageDestroy` callback. The framework releases window-related resources. Developers can release custom resources obtained via `WindowStage` in this callback. This callback executes after `WindowStage` is destroyed; `WindowStage` is no longer usable at this point.

#### onDestroy()

Before the UIAbility instance is destroyed, the system triggers the `onDestroy` callback. This is the last lifecycle callback the UIAbility receives. The framework destroys the engine and view. Developers can perform system resource release and data saving in this callback; **complete custom logic first, then call `super.onDestroy()`**, to avoid data not being saved before the engine is destroyed.

Below is an `EntryAbility` extension example covering the above callbacks and `pagePath()`:

```typescript
// EntryAbility.ets
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { FlutterAbility } from '@ohos/flutter_ohos';

export default class EntryAbility extends FlutterAbility {
  pagePath(): string {
    return 'pages/CustomIndex'  // Default is 'pages/Index'; not a lifecycle callback
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam)
    // Perform one-time startup logic, e.g., parse Want launch parameters
  }

  onForeground(): void {
    super.onForeground()
    // Acquire resources needed by the system, or re-acquire resources released in onBackground()
    // e.g.: restore location, re-subscribe to sensors
  }

  onBackground(): void {
    super.onBackground()
    // Release resources unused when UI is invisible
    // e.g.: stop location, cancel sensor subscriptions
  }

  onWindowStageDestroy(): void {
    super.onWindowStageDestroy()
    // Release custom resources obtained via WindowStage
    // e.g.: unregister windowStageEvent subscriptions made in onWindowStageCreate
  }

  onDestroy(): void {
    // Save user data, release custom native resources
    // Note: super.onDestroy() destroys the engine; call it after the above logic is complete.
    // Unlike onForeground/onBackground where super is called first
    super.onDestroy()
  }
}
```

### Add-to-App

The host `UIAbility` remains a native implementation. It must call `FlutterManager`'s `push` / `pop` methods in `onCreate` / `onWindowStageCreate` / `onWindowStageDestroy` / `onDestroy` for registration and unregistration, and `loadContent` must load **native main navigation** rather than the Flutter home page.

Below is an Add-to-App host `EntryAbility` example showing `FlutterManager` registration and unregistration:

```typescript
// EntryAbility.ets (Add-to-App host UIAbility)
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ExclusiveAppComponent, FlutterManager } from '@ohos/flutter_ohos';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {
  detachFromFlutterEngine(): void {
  }

  getAppComponent(): UIAbility {
    return this;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 1. Register UIAbility so Embedding can find the Ability via context
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 2. Register WindowStage and load native main navigation page (not Flutter home page)
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    windowStage.loadContent('pages/MainPage');
  }

  onWindowStageDestroy(): void {
    // 3. Unregister when WindowStage is destroyed
    FlutterManager.getInstance().popWindowStage(this);
  }

  onDestroy(): void {
    // 4. Unregister when UIAbility is destroyed
    FlutterManager.getInstance().popUIAbility(this);
  }
}
```

> **Note**: `pushUIAbility` / `popUIAbility` and `pushWindowStage` / `popWindowStage` **must be called in pairs**; missing `pop` will cause subsequent page `viewId` binding anomalies and plugin context resolution errors. Implementing the `ExclusiveAppComponent` interface allows plugins to obtain the host `UIAbility` context via `getAppComponent()`.

#### Host Foreground/Background and FlutterEntry

Add-to-App has **two sets of lifecycles**: the host `UIAbility`'s `onForeground` / `onBackground` handles Ability-level native resources; the Flutter engine's rendering start/stop is driven by the ArkUI page's `onPageShow` / `onPageHide` — **the two are not automatically bridged**.

Flutter pages are embedded as ArkUI components. After the system triggers ArkUI component lifecycle, developers must **proactively call** the corresponding `FlutterEntry` methods in the respective callbacks. The framework uses these to manage engine and view lifecycles:

| ArkUI Component Callback | Trigger Timing | Developer Must Call | Effect |
| -------------- | -------- | ------------ | ---- |
| `aboutToAppear()` | Component is about to mount | `flutterEntry.aboutToAppear()` | Creates engine and view (triggers `configureFlutterEngine` during the process; see Section 4) |
| `onPageShow()` | Page becomes visible (including Navigation `onShown`) | `flutterEntry.onPageShow()` | Resumes rendering |
| `onPageHide()` | Page is obscured or left (including `onHidden`) | `flutterEntry.onPageHide()` | Pauses rendering |
| `aboutToDisappear()` | Component is about to unmount (Navigation: `onDisAppear`) | `flutterEntry.aboutToDisappear()` | Destroys engine and view |

When using `Navigation`, you must call the corresponding `FlutterEntry` methods in route callbacks such as `onShown` / `onHidden` / `onDisAppear` to keep the engine lifecycle consistent with page visibility.

Below is a complete ArkUI page example that calls `FlutterEntry` methods in component lifecycle and binds `viewId` via `FlutterPage`:

```typescript
// FlutterRoutePage.ets
import { FlutterPage, FlutterView } from '@ohos/flutter_ohos';
import MyFlutterEntry from '../entry/MyFlutterEntry';

@Component
export struct FlutterRoutePage {
  private flutterEntry?: MyFlutterEntry;
  private flutterView?: FlutterView;

  aboutToAppear(): void {
    this.flutterEntry = new MyFlutterEntry(getContext(this));
    this.flutterEntry.aboutToAppear();
    this.flutterView = this.flutterEntry.getFlutterView();
  }

  onPageShow(): void {
    this.flutterEntry?.onPageShow();
  }

  onPageHide(): void {
    this.flutterEntry?.onPageHide();
  }

  aboutToDisappear(): void {
    this.flutterEntry?.aboutToDisappear();
    this.flutterEntry = undefined;
    this.flutterView = undefined;
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
    .width('100%')
    .height('100%')
  }
}
```

> **Note (Engine and FlutterView binding)**: **A `FlutterEngine` can only have one `FlutterView` attached at a time in its active state**. In Add-to-App multi-page navigation, if multiple ArkUI pages **share the same Engine** (e.g., cached Engine, `FlutterEngineGroup` scenarios), you must detach the current `FlutterView` when leaving a page (e.g., call `flutterView.detachFromFlutterEngine()` in `aboutToDisappear` / `onPageHide`), and attach a new `FlutterView` when entering the new page (e.g., call `flutterView.attachToFlutterEngine(engine)` in `aboutToAppear` / `onPageShow`); **detach before attach when switching pages**, otherwise black screens, overlapping content, or Engine state errors may occur. When each page creates its own `FlutterEntry` (as in the example above), the framework automatically manages attach/detach within the Entry lifecycle; **when sharing an Engine, you must ensure the above constraints yourself and refer to the code examples in the following documents**:
>
> - [Using FlutterEngineGroup for Multiple Engine Instances](../hybrid-development/using-flutter-engine-group.en.md): `EngineBindings` wraps `attach()` / `detach()`, called in `aboutToAppear` / `aboutToDisappear`
> - [Flutter-OH Multi-Engine Development Guide](../hybrid-development/flutter-oh-multi-engine-dev-guide.en.md): Multi-engine Add-to-App end-to-end example

---

## 4. Engine Configuration (configureFlutterEngine)

`configureFlutterEngine()` is an **engine initialization hook** provided by the Flutter Embedding — it is not a UIAbility or ArkUI lifecycle callback. The framework calls it after `FlutterEngine` is created and before Dart `main` is executed (once per engine), for the app to register plugins or perform engine-level configuration.

Both integration modes extend it by overriding the method in a subclass — **must call `super.configureFlutterEngine()`**.

### Standalone Flutter App

Override in `EntryAbility.ets`:

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
```

### Add-to-App

Override in `MyFlutterEntry.ets`:

```typescript
import { FlutterEngine, FlutterEntry } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class MyFlutterEntry extends FlutterEntry {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
```
