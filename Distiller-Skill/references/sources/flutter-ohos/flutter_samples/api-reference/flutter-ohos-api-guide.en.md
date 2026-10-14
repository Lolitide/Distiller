# API Reference

> **Contents**
>
> - [FlutterAbility](#flutterability)
> - [FlutterEntry](#flutterentry)
> - [FlutterEngine](#flutterengine)
> - [FlutterEngineGroup](#flutterenginegroup)
> - [FlutterEngineCache](#flutterenginecache)
> - [FlutterEnginePreload](#flutterenginepreload)
> - [FlutterView](#flutterview)
> - [FlutterPage](#flutterpage)
> - [FlutterManager](#fluttermanager)
> - [LifecycleChannel](#lifecyclechannel)
> - [NavigationChannel](#navigationchannel)
> - [MethodChannel](#methodchannel)
> - [FlutterPlugin](#flutterplugin)
> - [FlutterPluginBinding](#flutterpluginbinding)
> - [PlatformViewRegistry](#platformviewregistry)
> - [PlatformViewFactory](#platformviewfactory)
> - [PlatformView](#platformview)
> - [PlatformViewWrapper](#platformviewwrapper)

## FlutterAbility

### Overview

`FlutterAbility` extends ArkUI's [UIAbility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-app-ability-uiability-V5) and encapsulates the operations required to launch **Flutter**, such as creating and managing the FlutterEngine, forwarding lifecycle events, creating the window and FlutterView, and synchronizing system configuration changes. App developers should extend this class. See the following code for usage:

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
```

Most of the code in `FlutterAbility` is implemented by the **Flutter OHOS adaptation layer** to improve stability. This section focuses on the key APIs in `FlutterAbility` that app developers can override or call.

### Key APIs

| API | Description |
| --- | --- |
| `configureFlutterEngine(flutterEngine)` | Called after the engine is created and attached to the Ability, for initialization operations such as plugin registration. |
| `cleanUpFlutterEngine(flutterEngine)` | Called when the Ability is detached from the engine, for cleaning up custom resources. |
| `provideFlutterEngine(context)` | Provides a custom `FlutterEngine` to the framework; when `null` is returned, the framework creates one automatically. |
| `getCachedEngineId()` | Returns the cached engine ID, used to reuse an engine from `FlutterEngineCache`. |
| `getCachedEngineGroupId()` | Returns the cached engine group ID, used to create an engine from `FlutterEngineGroupCache`. |
| `shouldDestroyEngineWithHost()` | Determines whether the associated `FlutterEngine` is destroyed along with the Ability. |
| `getDartEntrypointFunctionName()` | Returns the name of the Dart entrypoint function. |
| `getInitialRoute()` | Returns the initial route of the Flutter app. |
| `getDartEntrypointArgs()` | Returns the command-line arguments passed to the Dart entrypoint function. |
| `popSystemNavigator()` | Triggered when the Flutter side calls `SystemNavigator.pop()`, for customizing back behavior. |

### FlutterEngine Creation Flow

During `onCreate`, the framework initializes the `FlutterEngine` through `FlutterAbilityAndEntryDelegate` and selects the engine source by the following priority:

1. **Cached engine**: If `getCachedEngineId()` returns a non-empty ID, the corresponding engine is retrieved from `FlutterEngineCache`.
2. **Custom engine**: If `provideFlutterEngine(context)` returns a non-null instance, that engine is used.
3. **Engine group**: If `getCachedEngineGroupId()` returns a non-null ID, the engine group is retrieved from `FlutterEngineGroupCache` and a new engine is created via `createAndRunEngineByOptions`.
4. **Default creation**: If none of the above matches, the framework automatically creates a new `FlutterEngineGroup` and runs the engine.

After the engine is created, the framework calls `configureFlutterEngine` to configure it. When the Ability is destroyed, the framework calls `cleanUpFlutterEngine` and decides whether to destroy the engine based on the return value of `shouldDestroyEngineWithHost()`.

### Methods

#### configureFlutterEngine

```typescript
configureFlutterEngine(flutterEngine: FlutterEngine): void
```

Called after the `FlutterEngine` is created and attached to the Ability. App developers should override this method for engine initialization operations such as registering plugins and configuring platform channels. The framework triggers this callback during `onAttach`, once the engine is ready.

A typical use is calling `GeneratedPluginRegistrant.registerWith(flutterEngine)` to register auto-generated plugins.

##### Parameters

| Parameter     | Type          | Description                       |
| ------------- | ------------- | --------------------------------- |
| flutterEngine | FlutterEngine | The Flutter engine instance that has been created. |

#### cleanUpFlutterEngine

```typescript
cleanUpFlutterEngine(flutterEngine: FlutterEngine): void
```

Called when the Ability is detached from the `FlutterEngine`, for engine cleanup operations such as unregistering plugins and releasing custom resources. The framework triggers this callback during `onDetach`, before the engine destruction decision is made.

##### Parameters

| Parameter     | Type          | Description                       |
| ------------- | ------------- | --------------------------------- |
| flutterEngine | FlutterEngine | The Flutter engine instance about to be detached. |

#### provideFlutterEngine

```typescript
provideFlutterEngine(context: common.Context): FlutterEngine | null
```

Provides a custom `FlutterEngine` instance to the framework. If a non-`null` value is returned, the framework uses that engine directly and skips the default creation process. The default implementation returns `null`, indicating that the framework manages engine creation automatically.

This applies to scenarios where the app needs to share the same engine across multiple Abilities or pages, or requires special control over when the engine is created. The returned engine should be created and configured in advance by the caller.

##### Parameters

| Parameter | Type                                                         | Description           |
| --------- | ------------------------------------------------------------ | --------------------- |
| context   | [common.Context](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-inner-application-context-V5) | Application context. |

##### Return Value

| Type                   | Description                                                          |
| ---------------------- | -------------------------------------------------------------------- |
| FlutterEngine \| null  | Custom engine instance; when `null` is returned, the framework creates the engine according to the default policy. |

#### getCachedEngineId

```typescript
getCachedEngineId(): string
```

Returns the cached engine ID specified in the launch parameters. The framework first looks up and reuses an existing engine in `FlutterEngineCache` based on this ID, which is suitable for scenarios where multiple Abilities share the same Flutter engine.

The corresponding Want parameter key is `cached_engine_id` (`FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID`).

##### Return Value

| Type   | Description                                              |
| ------ | -------------------------------------------------------- |
| string | The cached engine ID; returns an empty string if not set. |

#### getCachedEngineGroupId

```typescript
getCachedEngineGroupId(): string | null
```

Returns the cached engine group ID specified in the launch parameters. Based on this ID, the framework retrieves a `FlutterEngineGroup` from `FlutterEngineGroupCache` and creates a new engine via `createAndRunEngineByOptions`. This is suitable for scenarios that require launching multiple Flutter instances quickly within the same engine group.

The corresponding Want parameter key is `cached_engine_group_id` (`FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID`).

##### Return Value

| Type           | Description                                      |
| -------------- | ------------------------------------------------ |
| string \| null | The cached engine group ID; returns `null` if not set. |

#### shouldDestroyEngineWithHost

```typescript
shouldDestroyEngineWithHost(): boolean
```

Determines whether the associated `FlutterEngine` is destroyed when the Ability is destroyed.

The default logic is as follows:

- If the engine comes from `FlutterEngineCache` (`getCachedEngineId()` is non-empty, matched first) or is provided by the host via `provideFlutterEngine`, returns `false`: the engine is not destroyed automatically, and the app manages the engine lifecycle itself.
- In other cases, returns `true`: the framework destroys the engine during `onDetach`.

Apps can override this method to customize the engine destruction policy.

##### Return Value

| Type    | Description                                                              |
| ------- | ------------------------------------------------------------------------ |
| boolean | `true` means the engine is destroyed with the Ability; `false` means the engine is retained. |

#### getDartEntrypointFunctionName

```typescript
getDartEntrypointFunctionName(): string
```

Returns the name of the Dart entrypoint function, that is, the `main` function executed when the Flutter app starts, or a custom entrypoint function name.

By default, this is read from the launch Want parameter `dart_entrypoint`; if not set, `"main"` is returned (`FlutterAbilityLaunchConfigs.DEFAULT_DART_ENTRYPOINT`).

##### Return Value

| Type   | Description                    |
| ------ | ------------------------------ |
| string | The Dart entrypoint function name. |

#### getInitialRoute

```typescript
getInitialRoute(): string
```

Returns the initial route of the Flutter app. Before the Dart code executes, the framework sends the initial route to the Flutter side through the NavigationChannel to ensure the first-screen route takes effect in time.

By default, this is read from the launch Want parameter `route`; if not set, an empty string is returned and the framework internally uses the default route `"/"`.

##### Return Value

| Type   | Description                      |
| ------ | -------------------------------- |
| string | The Flutter initial route string. |

#### getDartEntrypointArgs

```typescript
getDartEntrypointArgs(): Array<string>
```

Returns the list of command-line arguments passed to the Dart entrypoint function.

By default, these are read from the launch Want parameter `dart_entrypoint_args`; an empty array is returned if not set.

##### Return Value

| Type           | Description                                 |
| -------------- | ------------------------------------------- |
| Array\<string> | The list of arguments passed to the Dart entrypoint function. |

#### popSystemNavigator

```typescript
popSystemNavigator(): boolean
```

This method is called back by `PlatformPlugin` when the Flutter side calls `SystemNavigator.pop()` to request exiting the app. Apps can override it to customize back behavior, such as intercepting the exit, asking for confirmation, or switching to a native page.

- Returning `true` indicates that the app has handled the back logic itself, and the framework will not execute the default `router.back()`.
- If `false` is returned (the default), the framework calls `router.back()` to perform the system back navigation.

##### Return Value

| Type    | Description                                                              |
| ------- | ------------------------------------------------------------------------ |
| boolean | `true` means the back event has been handled; `false` means the framework's default back behavior is used. |

### Launch Parameters

Flutter launch behavior can be configured through Want parameters. Common parameters are as follows:

| Parameter Key             | Type           | Description                                                          |
| ------------------------- | -------------- | -------------------------------------------------------------------- |
| dart_entrypoint           | string         | Dart entrypoint function name; defaults to `"main"`.                 |
| route                     | string         | Flutter initial route.                                               |
| dart_entrypoint_args      | Array\<string> | Arguments passed to the Dart entrypoint function.                    |
| cached_engine_id          | string         | Cached engine ID, used to reuse an engine from `FlutterEngineCache`. |
| cached_engine_group_id    | string         | Cached engine group ID, used to create an engine from `FlutterEngineGroupCache`. |
| destroy_engine_with_activity | boolean     | Whether to destroy the engine when the Activity/Ability is destroyed. |
| enable_state_restoration  | boolean        | Whether to enable state restoration.                                 |

### Usage Example

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import common from '@ohos.app.ability.common';

export default class EntryAbility extends FlutterAbility {
  // Register plugins
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  // Customize back behavior: intercept the exit
  popSystemNavigator(): boolean {
    // Returning true means the app handles it itself; the default router.back() is not executed
    return true;
  }

  // Provide a custom engine (optional)
  provideFlutterEngine(context: common.Context): FlutterEngine | null {
    return null; // Return null to use the framework's default creation
  }
}
```

## FlutterEntry

### Overview

`FlutterEntry` is the entry class for embedding **Flutter** content in an ArkUI page. It manages the lifecycles of `FlutterView` and `FlutterEngine` in scenarios that use custom pages (rather than a `FlutterAbility`-owned Ability). Like `FlutterAbility`, `FlutterEntry` implements the `Host` interface and uses `FlutterAbilityAndEntryDelegate` internally for engine creation, view mounting, and lifecycle forwarding.

It is intended for **Add-to-App** hybrid development scenarios: embedding a Flutter module in a native ArkUI page, or sharing a cached engine with `FlutterAbility`.

```typescript
import { FlutterEntry, FlutterEngine, FlutterEngineConfigurator } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

const engineConfigurator: FlutterEngineConfigurator = {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  },
  cleanUpFlutterEngine(flutterEngine: FlutterEngine): void {
    // Clean up custom resources
  },
};

let flutterEntry: FlutterEntry | null = null;

@Entry
@Component
struct MyFlutterPage {
  private context = getContext(this);

  aboutToAppear(): void {
    flutterEntry = new FlutterEntry(this.context, {
      dart_entrypoint: 'main',
      route: '/',
    });
    flutterEntry.setFlutterEngineConfigurator(engineConfigurator);
    flutterEntry.aboutToAppear();
  }

  aboutToDisappear(): void {
    flutterEntry?.aboutToDisappear();
    flutterEntry = null;
  }

  onPageShow(): void {
    flutterEntry?.onPageShow();
  }

  onPageHide(): void {
    flutterEntry?.onPageHide();
  }

  build() {
    Column() {
      FlutterPage({ viewId: flutterEntry?.getFlutterView().getId() ?? '' })
    }
  }
}
```

Most of the code in `FlutterEntry` is implemented by the **Flutter OHOS adaptation layer**. This section focuses on the key APIs in `FlutterEntry` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `aboutToAppear()` | Called when the page is about to be shown; initializes the delegate, creates the FlutterView, and attaches the engine. |
| `aboutToDisappear()` | Called when the page is about to be destroyed; cleans up resources and detaches from the engine. |
| `onPageShow()` | Notifies the Flutter app that it has entered the foreground (`appIsResumed`). |
| `onPageHide()` | Notifies the Flutter app that it has entered the background (`appIsPaused`). |
| `onBackPress()` | Triggers `popRoute` on the Flutter navigation stack. |
| `configureFlutterEngine(flutterEngine)` | Called when the engine is ready; delegates configuration to `FlutterEngineConfigurator`. |
| `setFlutterEngineConfigurator(configurator)` | Sets the engine configurator, for initialization operations such as plugin registration. |
| `getFlutterView()` | Returns the `FlutterView` instance associated with the current `FlutterEntry`. |

### Methods

#### getFlutterView

```typescript
getFlutterView(): FlutterView | null
```

Returns the `FlutterView` instance associated with the current `FlutterEntry`. It is used to render Flutter content in a page via `FlutterPage({ viewId: flutterEntry.getFlutterView()?.getId() ?? '' })`.

The `FlutterView` is created in `aboutToAppear` and destroyed in `aboutToDisappear`. Calls outside this lifecycle return `null`.

##### Return Value

| Type                 | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| FlutterView \| null  | The currently associated FlutterView instance; returns `null` if not initialized. |

#### aboutToAppear

```typescript
aboutToAppear(): void
```

Called in the `aboutToAppear` lifecycle of an ArkUI page. The framework performs the following operations in order:

1. Creates the `FlutterAbilityAndEntryDelegate` instance;
2. Creates the `FlutterView` and triggers `onWindowCreated`;
3. Calls `onAttach` to initialize the `FlutterEngine`;
4. Sets the UIAbility context for `PlatformPlugin`;
5. Calls `onWindowStageCreate` to execute the Dart entrypoint and set the initial route;
6. Registers the `windowStageEvent` listener and environment change callbacks.

If `aboutToAppear` runs after `onPageShow`, the framework dispatches a supplementary `onShow` after initialization completes, preventing lifecycle events from being lost.

#### aboutToDisappear

```typescript
aboutToDisappear(): void
```

Called in the `aboutToDisappear` lifecycle of an ArkUI page. The framework performs the following operations in order:

1. Unregisters the environment change callbacks;
2. Removes the `windowStageEvent` listener;
3. Destroys the `FlutterView`;
4. Calls `onDetach` to detach the engine and decides whether to destroy the engine based on `shouldDestroyEngineWithHost()`;
5. Releases the resources held by the delegate.

#### configureFlutterEngine

```typescript
configureFlutterEngine(flutterEngine: FlutterEngine): void
```

Called by the framework after the `FlutterEngine` is created and attached. If a configurator has been set via `setFlutterEngineConfigurator`, this method delegates to the configurator's `configureFlutterEngine` method. App developers typically implement the `FlutterEngineConfigurator` interface for plugin registration instead of overriding this method directly.

##### Parameters

| Parameter     | Type          | Description                       |
| ------------- | ------------- | --------------------------------- |
| flutterEngine | FlutterEngine | The Flutter engine instance that has been created. |

#### setFlutterEngineConfigurator

```typescript
setFlutterEngineConfigurator(configurator: FlutterEngineConfigurator): void
```

Sets the `FlutterEngine` configurator. It should be called **before** `aboutToAppear()` so that the configuration logic runs immediately after the engine is initialized.

The `FlutterEngineConfigurator` interface is defined as follows:

```typescript
interface FlutterEngineConfigurator {
  configureFlutterEngine: (flutterEngine: FlutterEngine) => void;
  cleanUpFlutterEngine: (flutterEngine: FlutterEngine) => void;
}
```

##### Parameters

| Parameter     | Type                      | Description                                                    |
| ------------- | ------------------------- | -------------------------------------------------------------- |
| configurator  | FlutterEngineConfigurator | The engine configurator, responsible for engine initialization and cleanup callbacks. |

#### onPageShow

```typescript
onPageShow(): void
```

Called in the `onPageShow` lifecycle of an ArkUI page. Sends the `appIsResumed` lifecycle event to the Flutter side, notifying the app that it has entered the active foreground state.

#### onPageHide

```typescript
onPageHide(): void
```

Called in the `onPageHide` lifecycle of an ArkUI page. Sends the `appIsPaused` lifecycle event to the Flutter side, notifying the app that it has entered the paused background state.

#### onBackPress

```typescript
onBackPress(): void
```

Called in the `onBackPress` lifecycle of an ArkUI page. Triggers `popRoute` on the Flutter navigation stack to handle system back key events.

### Constructor Parameters

The `FlutterEntry` constructor takes a `context` and an optional `params` parameter. The common configuration keys are the same as the `FlutterAbility` launch parameters:

| Parameter Key           | Type           | Description                                                           |
| ---------------------- | -------------- | --------------------------------------------------------------------- |
| dart_entrypoint        | string         | Dart entrypoint function name; defaults to `"main"`.                  |
| route                  | string         | Flutter initial route.                                                |
| dart_entrypoint_args   | Array\<string> | Arguments passed to the Dart entrypoint function.                     |
| cached_engine_id       | string         | Cached engine ID, used to reuse an engine from `FlutterEngineCache`.  |
| cached_engine_group_id | string         | Cached engine group ID, used to create an engine from `FlutterEngineGroupCache`. |
| should_attach_engine_to_ability | boolean | Whether to attach the engine to the UIAbility; defaults to `true`. |

### Page Lifecycle Coordination

In addition to `aboutToAppear` / `aboutToDisappear`, it is recommended that the page also forward the following lifecycle methods:

| Page Lifecycle | FlutterEntry Method | Description |
| --- | --- | --- |
| `onPageShow` | `onPageShow()` | Notifies the Flutter app that it has entered the foreground (`appIsResumed`). |
| `onPageHide` | `onPageHide()` | Notifies the Flutter app that it has entered the background (`appIsPaused`). |
| `onBackPress` | `onBackPress()` | Triggers `popRoute` on the Flutter navigation stack. |

## FlutterEngine

### Overview

`FlutterEngine` is the container for a single **Flutter** execution environment. It runs Dart code, manages platform channel communication, maintains the plugin registry, and drives rendering. In an OpenHarmony app, the engine can be created automatically by `FlutterAbility` or `FlutterEntry`, or manually through a `FlutterEngineGroup` to share VM resources across multiple pages.

An app can have multiple `FlutterEngine` instances, each with its own Dart Isolate. For better memory performance, it is recommended to use `FlutterEngineGroup` instead of directly constructing multiple `FlutterEngine` instances.

```typescript
import { FlutterEngine } from '@ohos/flutter_ohos';

// Obtain the engine via FlutterAbility or FlutterEntry
// const flutterEngine: FlutterEngine | null = entryAbility.getFlutterEngine();

let flutterEngine: FlutterEngine | null = null; // In practice, provided by FlutterAbility/FlutterEntry

// Register a plugin
flutterEngine?.getPlugins()?.add(new MyPlugin());

// Obtain the Dart executor
const dartExecutor = flutterEngine?.getDartExecutor();

// Destroy the engine (usually managed automatically by the framework)
flutterEngine?.destroy();
```

This section focuses on the key APIs in `FlutterEngine` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `getDartExecutor()` | Returns the Dart code executor, used to execute the Dart entrypoint or register a MethodChannel. |
| `getFlutterRenderer()` | Returns the renderer, which renders Flutter content to the `FlutterView`. |
| `getPlugins()` | Returns the plugin registry, used to add, remove, and query Flutter plugins. |
| `getLifecycleChannel()` | Returns the lifecycle channel, used to send app lifecycle events to the Flutter side. |
| `getNavigationChannel()` | Returns the navigation channel, used to manage Flutter routes (initial route, pop, and so on). |
| `getPlatformChannel()` | Returns the platform channel, used for platform-level interactions such as system UI and the clipboard. |
| `getTextInputChannel()` | Returns the text input channel, used for soft keyboard and text input management. |
| `destroy()` | Destroys the engine and releases all associated resources. |

### Methods

#### getDartExecutor

```typescript
getDartExecutor(): DartExecutor
```

Returns the `DartExecutor` instance, used to configure, start, and execute Dart code. `DartExecutor` also implements the `BinaryMessenger` interface and can be used to register MethodChannels and EventChannels.

Typical uses:

- Launching the Dart entrypoint via `executeDartEntrypoint(DartEntrypoint)` (called automatically inside the framework; apps generally do not need to call it manually);
- Registering message handlers for custom platform channels.

##### Return Value

| Type         | Description                               |
| ------------ | ----------------------------------------- |
| DartExecutor | The Dart code executor; never `null`.    |

#### getFlutterRenderer

```typescript
getFlutterRenderer(): FlutterRenderer
```

Returns the `FlutterRenderer` instance, which outputs the Flutter rendering pipeline to a `RenderSurface` (usually the XComponent inside a `FlutterView`). `FlutterView.attachToFlutterEngine` performs the binding through this renderer internally.

##### Return Value

| Type            | Description                            |
| --------------- | -------------------------------------- |
| FlutterRenderer | The Flutter renderer; never `null`.    |

#### getPlugins

```typescript
getPlugins(): PluginRegistry | null
```

Returns the plugin registry `PluginRegistry`, which manages the `FlutterPlugin` instances attached to the current engine.

##### Return Value

| Type                    | Description                                                          |
| ----------------------- | -------------------------------------------------------------------- |
| PluginRegistry \| null  | The plugin registry; may be `null` if the engine is not fully initialized. |

##### Common PluginRegistry Methods

| Method | Description |
| --- | --- |
| `add(plugin)` | Attaches a plugin to the engine. |
| `addList(plugins)` | Attaches plugins in batch. |
| `has(pluginClassName)` | Checks whether the specified plugin is attached. |
| `get(pluginClassName)` | Returns the plugin instance of the specified class. |
| `remove(pluginClassName)` | Detaches and removes the plugin from the engine. |

#### getLifecycleChannel

```typescript
getLifecycleChannel(): LifecycleChannel | null
```

Returns the lifecycle channel, used to send app lifecycle state changes to the Flutter side, for example:

- `appIsResumed()` — the app enters the foreground;
- `appIsPaused()` — the app enters the background;
- `appIsInactive()` — the app is inactive;
- `appIsDetached()` — the app is detached from the engine.

The framework calls these methods automatically in the lifecycle callbacks of `FlutterAbility` / `FlutterEntry`; app developers generally do not need to send them manually.

##### Return Value

| Type                     | Description                                                  |
| ------------------------ | ------------------------------------------------------------ |
| LifecycleChannel \| null | The lifecycle channel; `null` if the engine is not initialized. |

#### getNavigationChannel

```typescript
getNavigationChannel(): NavigationChannel | null
```

Returns the navigation channel, used to manage routing behavior on the Flutter side. The framework sets the initial route via `setInitialRoute` when the engine starts, and pops the current route via `popRoute` when the page goes back.

##### Return Value

| Type                      | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| NavigationChannel \| null | The navigation channel; `null` if the engine is not initialized. |

#### getPlatformChannel

```typescript
getPlatformChannel(): PlatformChannel | null
```

Returns the platform channel, which carries system-level interactions between Flutter and the OpenHarmony platform, including:

- System navigation bar styles (`SystemChrome`);
- Clipboard read and write;
- Haptic feedback;
- Screen orientation settings;
- Exiting the app via `SystemNavigator.pop()`, and so on.

`PlatformPlugin`, the ArkTS-side handler of this channel, is created automatically when the engine is initialized.

##### Return Value

| Type                    | Description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| PlatformChannel \| null | The platform channel; `null` if the engine is not initialized. |

#### getTextInputChannel

```typescript
getTextInputChannel(): TextInputChannel | null
```

Returns the text input channel, used to manage input-related behavior such as showing/hiding the soft keyboard and synchronizing text editing state. `TextInputPlugin`, the ArkTS-side handler of this channel, is created automatically when the engine is initialized.

##### Return Value

| Type                     | Description                                                    |
| ------------------------ | -------------------------------------------------------------- |
| TextInputChannel \| null | The text input channel; `null` if the engine is not initialized. |

#### destroy

```typescript
destroy(): void
```

Destroys the `FlutterEngine` and releases all associated resources, including:

1. Notifying all `EngineLifecycleListener`s that the engine is about to be destroyed;
2. Detaching plugins from the UIAbility;
3. Destroying the `PlatformViewsController` and the plugin registry;
4. Detaching the `DartExecutor` and native NAPI references.

**Note**: If the engine comes from `FlutterEngineCache` or is provided by the app via `provideFlutterEngine`, the framework does not call `destroy()` automatically when `shouldDestroyEngineWithHost()` returns `false`; the app must manage the engine lifecycle itself.

##### Usage Recommendations

- For engines created via `FlutterAbility` / `FlutterEntry`, calling `destroy()` manually is usually unnecessary; the framework handles it automatically during `onDetach` according to its policy;
- For manually created and cached engines, call `destroy()` proactively once the engine is no longer used, and remove it from `FlutterEngineCache`.

### Obtaining an Engine

| Approach | Description |
| --- | --- |
| `FlutterAbility.getFlutterEngine()` | Obtains the currently associated engine instance from the Ability. |
| `FlutterEntry.getFlutterEngine()` | Obtains the currently associated engine instance from the page entry. |
| `FlutterEngineCache.getInstance().get(id)` | Obtains the engine with the specified ID from the global cache. |
| `FlutterEngineGroup.createAndRunEngineByOptions(options)` | Creates and runs a new engine through the engine group. |

## FlutterEngineGroup

### Overview

`FlutterEngineGroup` represents a collection of `FlutterEngine`s that share underlying resources. When engines are created or re-created within the same group, subsequent engines reuse the Dart VM and NAPI resources of an existing live engine, allowing multiple Flutter instances to be created with lower memory overhead and faster startup.

The shared resources are retained until the last live `FlutterEngine` in the group is destroyed. Deleting a `FlutterEngineGroup` does not invalidate existing engines in the group, but no new engines can be created in it.

`FlutterAbility` and `FlutterEntry` can obtain a warmed-up engine group from `FlutterEngineGroupCache` via `getCachedEngineGroupId()`, and `FlutterAbilityAndEntryDelegate` then creates a new engine by calling `createAndRunEngineByOptions`.

```typescript
import {
  FlutterEngineGroup,
  FlutterEngineGroupCache,
  Options,
} from '@ohos/flutter_ohos';
import { DartEntrypoint } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/dart/DartExecutor';
import common from '@ohos.app.ability.common';

// context must be obtained from a page or Ability
// const context: common.Context = ...

// Create the engine group and warm up the first engine
const engineGroup = new FlutterEngineGroup();
const engine = engineGroup.createAndRunEngineByOptions(
  new Options(context)
    .setDartEntrypoint(DartEntrypoint.createDefault())
    .setInitialRoute('/')
);

// Cache the engine group for reuse by FlutterAbility / FlutterEntry
FlutterEngineGroupCache.instance.put('my_engine_group', engineGroup);

// Quickly create a second engine in the same group (spawn reuses resources)
const secondEngine = engineGroup.createAndRunEngineByOptions(
  new Options(context)
    .setInitialRoute('/second')
);
```

This section focuses on the key APIs in `FlutterEngineGroup` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `createAndRunEngineByOptions(options)` | Creates and runs a `FlutterEngine` based on the configuration options; the first engine in the group is newly created, and subsequent engines are spawned from the first engine. |
| `getDefaultEngine()` | Returns the default (first) engine instance in the group. |

### Engine Creation Flow

`createAndRunEngineByOptions` creates engines with the following internal logic:

1. **No engines in the group**: Calls `createEngine` to create a brand-new `FlutterEngine`, runs `init`, sets the initial route, executes the Dart entrypoint, and calls `prefetchFramesCfg` to prefetch frame configuration.
2. **Engines already in the group**: Calls `spawn` on `activeEngines[0]` to create a new engine with reused resources.
3. Adds the new engine to the `activeEngines` list and registers an `EngineLifecycleListener` so the engine is removed from the list automatically when destroyed.

### Methods

#### createAndRunEngineByOptions

```typescript
createAndRunEngineByOptions(options: Options): FlutterEngine
```

Creates and runs a `FlutterEngine` based on the `Options` configuration. If `dartEntrypoint` is not set, `DartEntrypoint.createDefault()` is used by default; if `platformViewsController` is not set, a new instance is created automatically.

##### Parameters

| Parameter | Type    | Description                                                        |
| --------- | ------- | ------------------------------------------------------------------ |
| options   | Options | Engine creation configuration, including the context, entrypoint, route, and so on. |

##### Return Value

| Type          | Description                            |
| ------------- | -------------------------------------- |
| FlutterEngine | The created or spawned engine instance. |

#### getDefaultEngine

```typescript
getDefaultEngine(): FlutterEngine | null
```

Returns the first (default) `FlutterEngine` instance in the group. When preloading via `cached_engine_group_id`, `FlutterEnginePreload.preLoadFlutterNapi` calls this method to obtain the default engine's NAPI reference to execute `preSpawn`.

##### Return Value

| Type                   | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| FlutterEngine \| null  | The first engine in the group; returns `null` if the group has no engines. |

### Options Configuration Parameters

The `Options` class configures the behavior of `createAndRunEngineByOptions` and supports chained calls:

| Method | Type | Description |
| --- | --- | --- |
| `setDartEntrypoint(dartEntrypoint)` | DartEntrypoint | Dart entrypoint configuration (bundle path, library URI, function name). |
| `setInitialRoute(initialRoute)` | string | Flutter initial route; defaults to an empty string. |
| `setDartEntrypointArgs(args)` | Array\<string> | Arguments passed to the Dart entrypoint function. |
| `setWaitForRestorationData(wait)` | boolean | Whether to wait for state restoration data; defaults to `false`. |
| `setPlatformViewsController(controller)` | PlatformViewsController | Platform views controller; created automatically if not set. |

### Usage Example

```typescript
import {
  FlutterEngineGroup,
  FlutterEngineGroupCache,
  FlutterEnginePreload,
  FlutterInjector,
  Options,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from an AbilityStage or a page
// const context: common.Context = ...

// 1. Warm up the engine group at app startup
const engineGroup = new FlutterEngineGroup();
engineGroup.checkLoader(context, []); // Ensure that FlutterLoader is initialized

const warmupEngine = engineGroup.createAndRunEngineByOptions(
  new Options(context).setInitialRoute('/')
);

// 2. Cache the engine group ID
FlutterEngineGroupCache.instance.put('main_group', engineGroup);

// 3. In FlutterAbility, simply return 'main_group' from getCachedEngineGroupId() for reuse
```

## FlutterEngineCache

### Overview

`FlutterEngineCache` is a **global cache of Flutter engine instances**. It holds created `FlutterEngine`s as key-value pairs so that multiple `FlutterAbility`s / `FlutterEntry`s can reuse the same engine at different entry points, avoiding the memory and startup overhead of repeatedly creating Dart VMs and rendering resources.

The cache is a process-wide singleton, obtained through `FlutterEngineCache.getInstance()`. During engine creation, `FlutterAbility` / `FlutterEntry` first looks up an engine in this cache using the ID returned by `getCachedEngineId()`; on a hit the engine is reused directly, and on a miss it is created through the default process.

```typescript
import { FlutterEngineCache, FlutterEngine } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from a page or Ability
// const context: common.Context = ...

// 1. Pre-create and cache an engine
const engine: FlutterEngine = ...; // In practice, usually created via FlutterEngineGroup
FlutterEngineCache.getInstance().put('main_engine', engine);

// 2. In FlutterAbility, override getCachedEngineId() to return 'main_engine' for reuse
```

This section focuses on the key APIs in `FlutterEngineCache` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `getInstance()` | Returns the `FlutterEngineCache` global singleton. |
| `put(id, engine)` | Stores a `FlutterEngine` in the cache under the specified ID. |
| `get(id)` | Returns the cached engine with the specified ID. |
| `contains(id)` | Checks whether an engine with the specified ID exists in the cache. |
| `remove(id)` | Removes the engine with the specified ID from the cache (does not destroy the engine itself). |
| `clear()` | Clears all engine references from the cache (does not destroy the engines). |

### Methods

#### getInstance

```typescript
static getInstance(): FlutterEngineCache
```

Returns the global singleton `FlutterEngineCache` instance; the entire app shares the same cache.

##### Return Value

| Type | Description |
| --- | --- |
| FlutterEngineCache | The global singleton cache instance. |

#### put

```typescript
put(id: string, engine: FlutterEngine): void
```

Stores a `FlutterEngine` in the cache under the specified `id`. If the ID already exists, the old reference is overwritten. An engine stored in the cache is not destroyed automatically when a particular Ability is destroyed; the app must manage its lifecycle.

##### Parameters

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| id | string | Unique identifier of the cached engine; must match the value returned by `getCachedEngineId()`. |
| engine | FlutterEngine | The engine instance to cache. |

#### get

```typescript
get(id: string): FlutterEngine | null
```

Returns the cached `FlutterEngine` instance for the specified `id`.

##### Parameters

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| id | string | Unique identifier of the cached engine. |

##### Return Value

| Type | Description |
| ---- | ----------- |
| FlutterEngine \| null | The matched engine instance; returns `null` on a miss. |

#### contains

```typescript
contains(id: string): boolean
```

Checks whether an engine with the specified `id` already exists in the cache.

##### Parameters

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| id | string | Unique identifier of the cached engine. |

##### Return Value

| Type | Description |
| ---- | ----------- |
| boolean | `true` means cached; `false` means not cached. |

#### remove

```typescript
remove(id: string): void
```

Removes the engine reference for the specified `id` from the cache. This method only breaks the cache association and **does not call `engine.destroy()`**; the caller should destroy the engine after confirming it is no longer in use.

##### Parameters

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| id | string | The ID of the cached engine to remove. |

#### clear

```typescript
clear(): void
```

Clears all engine references from the cache. Like `remove`, this method does not destroy engine instances; it only breaks the associations.

### Relationship to the Cached Engine Destruction Policy

For an engine matched via `getCachedEngineId()`, the default `shouldDestroyEngineWithHost()` of `FlutterAbility` / `FlutterEntry` returns `false`; that is, the engine is **not destroyed automatically** when the host is destroyed. Once the app confirms that no host is using the engine anymore, it should explicitly call `engine.destroy()` and clean up the cache reference with `remove(id)` to avoid memory leaks.

### Usage Example

```typescript
import {
  FlutterEngineCache,
  FlutterEngineGroup,
  Options,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from an AbilityStage or a page
// const context: common.Context = ...

// 1. Warm up and cache the engine at app startup
const group = new FlutterEngineGroup();
const engine = group.createAndRunEngineByOptions(new Options(context).setInitialRoute('/'));
FlutterEngineCache.getInstance().put('main_engine', engine);

// 2. Reuse in FlutterAbility:
//    override getCachedEngineId(): string { return 'main_engine'; }

// 3. Destroy and clean up once it is no longer used
// FlutterEngineCache.getInstance().remove('main_engine');
// engine.destroy();
```

## FlutterEnginePreload

### Overview

`FlutterEnginePreload` is a utility class for **preloading the Flutter engine**. It provides static methods that complete Dart VM initialization, bundle loading, and first-frame pre-drawing before the page is actually shown, shortening the perceived startup time.

Typical scenarios:

- Loading Flutter resources ahead of time in `AbilityStage.onCreate` or during app startup;
- Pre-drawing before navigating to a Flutter page to reduce white screen time;
- Working with `FlutterEngineCache` / `FlutterEngineGroupCache` to warm up engines.

```typescript
import { FlutterEnginePreload } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from a page or Ability
// const context: common.Context = ...

// Preload at app startup
await FlutterEnginePreload.preloadEngine(context, {
  dart_entrypoint: 'main',
  route: '/',
});

// Pre-draw an already created engine (engine provided by FlutterAbility/FlutterEntry)
// FlutterEnginePreload.predrawEngine(flutterEngine);
```

This section focuses on the key APIs in `FlutterEnginePreload` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `preloadEngine(context, params?)` | Full preloading process: initializes the loader, loads NAPI/bundle, sets the viewport, and performs pre-drawing. |
| `predrawEngine(engine, params?)` | Sets viewport metrics for an existing `FlutterEngine` and performs XComponent pre-drawing. |
| `preLoadFlutterNapi(context, bundlePath)` | Low-level NAPI preloading: loads the bundle, sets the initial route, and supports cached engine/engine group reuse. |

### Methods

#### preloadEngine

```typescript
static async preloadEngine(
  context: common.Context,
  params: Record<string, Object> = {},
  nextViewId: string | null = null
): Promise<void>
```

Performs the full engine preloading process:

1. Initializes `FlutterLoader` (if not already initialized);
2. Calls `preLoadFlutterNapi` to load NAPI and execute the Dart bundle;
3. Obtains or constructs `ViewportMetrics` (defaults to the current screen size);
4. Sets the preload flag, then executes `xComponentPreDraw` and `setViewportMetrics`.

##### Parameters

| Parameter | Type                    | Required | Description                                                          |
| --------- | ----------------------- | -------- | -------------------------------------------------------------------- |
| context   | common.Context          | Yes      | Application context.                                                 |
| params    | Record\<string, Object> | No       | Preloading configuration parameters; key names match the `FlutterAbilityLaunchConfigs` constants. |
| nextViewId | string \| null         | No       | XComponent ID used for pre-drawing; generated automatically if not set. |

#### predrawEngine

```typescript
static predrawEngine(
  engine: FlutterEngine,
  params: Record<string, Object> = {},
  nextViewId: string | null = null
): void
```

Performs pre-drawing preparation for an already created `FlutterEngine`. This applies when the engine has been created through `FlutterEngineGroup` or `FlutterEngineCache` and only the first frame needs to be rendered in advance.

Execution flow:

1. Ensures the engine's `FlutterNapi` is attached to the native layer;
2. Obtains or constructs `ViewportMetrics`;
3. Sets the preload flag, then executes `xComponentPreDraw` and `setViewportMetrics`.

##### Parameters

| Parameter | Type                    | Required | Description                            |
| --------- | ----------------------- | -------- | -------------------------------------- |
| engine    | FlutterEngine           | Yes      | The created Flutter engine instance.   |
| params    | Record\<string, Object> | No       | Pre-drawing configuration parameters.  |
| nextViewId | string \| null         | No       | XComponent ID used for pre-drawing; generated automatically if not set. |

#### preLoadFlutterNapi

```typescript
static preLoadFlutterNapi(
  context: common.Context,
  bundlePath: string,
  params: Record<string, Object> = {}
): FlutterNapi | null
```

The low-level NAPI preloading method, responsible for loading the Flutter bundle on the native layer and running the Dart code. `preloadEngine` calls this method internally to complete the core loading logic.

The engine source is selected by the following priority:

1. **Cached engine**: If `cached_engine_id` is specified in `params`, the NAPI of the existing engine is retrieved from `FlutterEngineCache`.
2. **Cached engine group**: If `cached_engine_group_id` is specified, the engine group is retrieved from `FlutterEngineGroupCache` and a new NAPI is created through the default engine's `preSpawn`.
3. **Default preloading**: If neither matches, `FlutterInjector.getPreloadFlutterNapi()` is used to obtain a dedicated preloading NAPI instance and `runBundleAndSnapshotFromLibrary` is executed.

##### Parameters

| Parameter  | Type                    | Required | Description                            |
| ---------- | ----------------------- | -------- | -------------------------------------- |
| context    | common.Context          | Yes      | Application context.                   |
| bundlePath | string                  | Yes      | The Flutter bundle path.               |
| params     | Record\<string, Object> | No       | Preloading configuration parameters.   |

##### Return Value

| Type                | Description                                                |
| ------------------- | ---------------------------------------------------------- |
| FlutterNapi \| null | The preloaded NAPI instance; returns `null` on failure.     |

### Preloading Parameters

The `params` parameter supports the following configuration keys:

| Parameter Key               | Type           | Description                                                          |
| --------------------------- | -------------- | -------------------------------------------------------------------- |
| dart_entrypoint             | string         | Dart entrypoint function name; defaults to `"main"`.                 |
| dart_entrypoint_library_uri | string         | Dart entrypoint library URI.                                         |
| route                       | string         | Flutter initial route.                                               |
| dart_entrypoint_args        | Array\<string> | Arguments passed to the Dart entrypoint function.                    |
| cached_engine_id            | string         | Cached engine ID, reusing the engine NAPI from `FlutterEngineCache`. |
| cached_engine_group_id      | string         | Cached engine group ID; `preSpawn` is executed via `FlutterEngineGroup.getDefaultEngine()`. |
| viewport_metrics            | ViewportMetrics | Custom viewport metrics; the current default screen size is used if not set. |

### Usage Example

```typescript
import {
  FlutterEnginePreload,
  FlutterEngineGroup,
  FlutterEngineGroupCache,
  FlutterInjector,
  Options,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from an AbilityStage or a page
// const context: common.Context = ...

// Scenario 1: Full preloading on a cold app start
async function onAppLaunch(context: common.Context) {
  await FlutterEnginePreload.preloadEngine(context, {
    dart_entrypoint: 'main',
    route: '/home',
  });
}

// Scenario 2: Preloading after warming up an engine group
function warmupEngineGroup(context: common.Context) {
  const group = new FlutterEngineGroup();
  group.createAndRunEngineByOptions(new Options(context).setInitialRoute('/'));
  FlutterEngineGroupCache.instance.put('warm_group', group);

  // Preload based on the engine group (spawns a new NAPI)
  FlutterEnginePreload.preLoadFlutterNapi(
    context,
    FlutterInjector.getInstance().getFlutterLoader().findAppBundlePath(),
    { cached_engine_group_id: 'warm_group', route: '/detail' }
  );
}

// Scenario 3: Pre-draw an already created engine
function predrawExistingEngine(engine: FlutterEngine) {
  FlutterEnginePreload.predrawEngine(engine);
}
```

## FlutterView

### Overview

`FlutterView` is the rendering view container for **Flutter** on OpenHarmony. It manages the binding between the XComponent rendering surface and the `FlutterEngine`, and handles viewport size, safe areas, keyboard areas, first-frame callbacks, and more. `FlutterAbility` and `FlutterEntry` create the `FlutterView` internally, and the page side presents the rendering through the `FlutterPage` component together with a `viewId`.

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import { FlutterView } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from a page or Ability; the engine is provided by the framework or a cache
// const context: common.Context = ...
// const flutterEngine: FlutterEngine = ...

// Usually created by FlutterManager
const flutterView: FlutterView = FlutterManager.getInstance().createFlutterView(context);

// Attach to the engine
flutterView.attachToFlutterEngine(flutterEngine);

// Use in FlutterPage
FlutterPage({ viewId: flutterView.getId() })
```

This section focuses on the key APIs in `FlutterView` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `new FlutterView(viewId, context)` | Constructs a Flutter rendering view with a unique viewId and context. |
| `attachToFlutterEngine(flutterEngine)` | Attaches the view to the specified `FlutterEngine`, establishing the rendering and input channels. |
| `detachFromFlutterEngine()` | Detaches from the current engine, cleaning up related plugins and event listeners. |
| `onSurfaceCreated()` | Called when the XComponent surface is created; returns a surface lifecycle token. |
| `onSurfaceDestroyed(token?)` | Called when the XComponent surface is destroyed; the optional token guards against out-of-order callbacks. |
| `onAreaChange(newArea, setFullScreen?)` | Updates viewport metrics and safe areas when the view area changes. |
| `hasRenderedFirstFrame()` | Checks whether the first frame has finished rendering. |
| `addFirstFrameListener(listener)` | Registers a first-frame rendered listener. |
| `getId()` | Returns the unique identifier of the FlutterView. |

### Methods

#### getId

```typescript
getId(): string
```

Returns the unique identifier (viewId) of the FlutterView. This ID is generated automatically by `FlutterManager.createFlutterView` (in the format `oh_flutter_${index}`) or passed in directly through the constructor. `FlutterPage({ viewId })` uses this ID to associate the rendering surface.

##### Return Value

| Type   | Description                               |
| ------ | ----------------------------------------- |
| string | The unique identifier of the FlutterView. |

#### Constructor

```typescript
constructor(viewId: string, context: Context)
```

Creates a `FlutterView` instance. The constructor initializes the viewport metrics and registers system event listeners such as window size, avoidance areas, and keyboard height.

On the app side, a FlutterView is usually created through `FlutterManager.createFlutterView(context)`, which automatically generates a viewId in the `oh_flutter_${index}` format and registers it with the manager.

##### Parameters

| Parameter | Type    | Description                                                          |
| --------- | ------- | -------------------------------------------------------------------- |
| viewId    | string  | Unique view identifier; must match the id of the XComponent in `FlutterPage`. Keeping the `oh_flutter_` prefix is recommended. |
| context   | Context | Application context, used to obtain UIAbility and window information. |

#### attachToFlutterEngine

```typescript
attachToFlutterEngine(flutterEngine: FlutterEngine): void
```

Attaches the `FlutterView` to the specified `FlutterEngine`. If it is already attached to another engine, `detachFromFlutterEngine` is called first before attaching the new engine.

After the attachment, the framework:

- Binds the XComponent to the engine NAPI;
- Updates the screen refresh rate, size, and density;
- Initializes `MouseCursorPlugin`, `TextInputPlugin`, `KeyboardManager`, and so on;
- Registers back key event handling;
- Updates the viewport metrics based on the current area.

##### Parameters

| Parameter     | Type          | Description                     |
| ------------- | ------------- | ------------------------------- |
| flutterEngine | FlutterEngine | The Flutter engine to attach to. |

#### detachFromFlutterEngine

```typescript
detachFromFlutterEngine(): void
```

Detaches the view from the current `FlutterEngine`, cleaning up plugin resources such as text input, mouse cursor, and keyboard management, and unbinding the NAPI binding between the XComponent and the engine. If the view is not attached to an engine, the call has no effect.

#### onSurfaceCreated

```typescript
onSurfaceCreated(): number
```

Called in the XComponent `onLoad` callback to mark the rendering surface as available and return a **surface lifecycle token**. `FlutterPage` calls this method internally in the XComponent's `onLoad` callback and saves the token for use by `onSurfaceDestroyed`.

The returned token prevents a stale `onDestroy` callback from incorrectly destroying a newly created surface during rapid route switches (out-of-order destruction protection).

##### Return Value

| Type   | Description                                    |
| ------ | ---------------------------------------------- |
| number | The lifecycle token of the current surface.    |

#### onSurfaceDestroyed

```typescript
onSurfaceDestroyed(surfaceLifecycleToken?: number): void
```

Called in the XComponent `onDestroy` callback to mark the rendering surface as unavailable and unbind the engine.

If `surfaceLifecycleToken` is passed and does not match the current active token, the call is ignored (preventing stale destroy callbacks from affecting the new surface). Always pass the token returned by `onSurfaceCreated`.

##### Parameters

| Parameter             | Type   | Required | Description                                                        |
| --------------------- | ------ | -------- | ------------------------------------------------------------------ |
| surfaceLifecycleToken | number | No       | The token returned by `onSurfaceCreated`; passing it enables out-of-order callback protection. |

#### onAreaChange

```typescript
onAreaChange(newArea: Area | null, setFullScreen: boolean = false): void
```

Updates the viewport metrics (`ViewportMetrics`) when the view area changes, including physical width and height, safe area insets, keyboard area, gesture avoidance area, and so on. When the window decoration changes, `FlutterPage` indirectly triggers these updates through `FlutterManager.handleWindowDecorSafeArea`.

##### Parameters

| Parameter    | Type        | Required | Description                                                        |
| ------------ | ----------- | -------- | ------------------------------------------------------------------ |
| newArea      | Area \| null | No       | The new view area; the current screen size is used when `null`.    |
| setFullScreen | boolean    | No       | Whether to calculate avoidance areas in full-screen mode; defaults to `false`. |

#### hasRenderedFirstFrame

```typescript
hasRenderedFirstFrame(): boolean
```

Checks whether the Flutter first frame has finished rendering. It can be used to control when the splash screen is hidden; `FlutterPage` hides the splash screen through a `FirstFrameListener` once the first frame completes.

##### Return Value

| Type    | Description                                    |
| ------- | ---------------------------------------------- |
| boolean | `true` if the first frame has been rendered; `false` otherwise. |

#### addFirstFrameListener

```typescript
addFirstFrameListener(listener: FirstFrameListener): void
```

Registers a first-frame rendered listener. After the first frame is rendered, the framework calls `listener.onFirstFrame()`. Use `removeFirstFrameListener` together with this method to remove the listener when the page is destroyed, avoiding resource leaks.

##### Parameters

| Parameter | Type               | Description                          |
| --------- | ------------------ | ------------------------------------ |
| listener  | FirstFrameListener | The first-frame rendered callback object. |

##### FirstFrameListener

```typescript
interface FirstFrameListener {
  onFirstFrame(): void;
}
```

### Usage Example

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct Index {
  private flutterView = FlutterManager.getInstance().createFlutterView(getContext(this));
  @LocalStorageLink('viewId') viewId: string = this.flutterView.getId();

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }
}
```

## FlutterPage

### Overview

`FlutterPage` is an ArkUI declarative component used in a page's `build()` to host the **Flutter** rendering output. It works in tandem with the logic-side `FlutterView`: `FlutterView` handles viewport metrics, engine attach/detach, and system event processing, while `FlutterPage` presents the surface rendered by the Flutter engine to the ArkUI component tree through its internal `XComponent({ id: viewId })`. `FlutterPage` does not hold a `FlutterView` instance itself; it is associated with one only through the `viewId`.

Developers do not need to subclass or instantiate `FlutterPage`; simply declare it in a `@Component`'s `build()`. The `viewId` comes from `FlutterView.getId()`: in a standalone app scenario, `FlutterAbility` injects it into `LocalStorage` automatically; in the Add-to-App scenario, it is obtained from `FlutterEntry.getFlutterView()`.

```typescript
import { FlutterPage } from '@ohos/flutter_ohos';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct Index {
  @LocalStorageLink('viewId') viewId: string = '';

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }
}
```

This section focuses on the key APIs in `FlutterPage` for app developers.

### Key APIs

| API | Description |
| --- | --- |
| `FlutterPage({ viewId })` | Declares the Flutter rendering component in `build()`; associates with a `FlutterView` through `viewId`. |
| `viewId` | Required constructor parameter; the unique view identifier returned by `FlutterView.getId()`. |

### Parameters

`FlutterPage` constructor parameters:

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| viewId | string | Yes | The view ID returned by `FlutterView.getId()`; matches the `oh_flutter_${index}` generated automatically by `FlutterManager.createFlutterView`. |

### Rendering Flow

`FlutterPage` manages the rendering surface internally based on `XComponent`:

1. The `XComponent`'s `onLoad` callback triggers `FlutterView.onSurfaceCreated()`, which returns a surface lifecycle token;
2. The framework binds the XComponent to the engine NAPI to establish the rendering channel;
3. After the first frame is rendered, `FirstFrameListener` is triggered, and `FlutterPage` hides the splash screen accordingly;
4. The `XComponent`'s `onDestroy` callback triggers `FlutterView.onSurfaceDestroyed(token)`; a token mismatch is ignored to prevent out-of-order destruction.

### Usage Notes

- When `viewId` is empty or not ready, the `FlutterPage` area shows a **black screen**. Make sure `FlutterAbility` / `FlutterEntry` has finished initializing and the `FlutterView` has been obtained.
- In a standalone Flutter app, `FlutterAbility` injects the `viewId` into `LocalStorage` automatically, and the home page receives it with `@LocalStorageLink('viewId')`; in the Add-to-App scenario, you must pass it in yourself via `flutterEntry.getFlutterView()?.getId() ?? ''`.
- Avoid nesting complex native layouts inside `FlutterPage` while `viewId` is not ready, otherwise a zero-sized XComponent may prevent the first frame from rendering.
- Keyboard avoidance, safe area, and similar configuration is done on the associated `FlutterView` via methods such as `setCheckKeyboard()` and `setCheckFullScreen()`.

### Usage Example

Standalone Flutter app:

```typescript
import { FlutterPage } from '@ohos/flutter_ohos';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct Index {
  @LocalStorageLink('viewId') viewId: string = '';

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }
}
```

Add-to-App embedding:

```typescript
import { FlutterPage, FlutterEntry } from '@ohos/flutter_ohos';

@Entry
@Component
struct MyFlutterPage {
  private flutterEntry: FlutterEntry = new FlutterEntry(getContext(this));

  aboutToAppear(): void {
    this.flutterEntry.aboutToAppear();
  }

  aboutToDisappear(): void {
    this.flutterEntry.aboutToDisappear();
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.flutterEntry.getFlutterView()?.getId() ?? '' })
    }
  }
}
```

## FlutterManager

### Overview

`FlutterManager` is the global singleton manager for **Flutter** views and UIAbilities. It handles creating and destroying `FlutterView`s, tracking registered `UIAbility`s / `WindowStage`s, full-screen mode control, system bar visibility management, and more. `FlutterAbility` interacts with `FlutterManager` through `pushUIAbility` / `popUIAbility` in `onCreate` / `onDestroy`.

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from a page or Ability
// const context: common.Context = ...

const manager = FlutterManager.getInstance();

// Create a FlutterView
const flutterView = manager.createFlutterView(context);

// Set full-screen mode
manager.setUseFullScreen(true, context);

// Control system bars
manager.setSpecificSystemBarEnabled(flutterView.getId(), 'status', true);
```

This section focuses on the key APIs in `FlutterManager` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `getInstance()` | Returns the `FlutterManager` singleton instance. |
| `createFlutterView(context)` | Creates and registers a new `FlutterView`, with a viewId generated automatically. |
| `deleteFlutterView(viewId)` | Removes the specified `FlutterView` from the manager. |
| `setUseFullScreen(use, context?)` | Sets whether to enable full-screen window layout. |
| `setSpecificSystemBarEnabled(viewId, bar, visible)` | Controls the system bar visibility of the window associated with the specified view. |

### Methods

#### getInstance

```typescript
static getInstance(): FlutterManager
```

Returns the `FlutterManager` singleton instance. The entire app shares the same manager, which uniformly manages the associations between all `FlutterView`s and `UIAbility`s.

##### Return Value

| Type           | Description                           |
| -------------- | ------------------------------------- |
| FlutterManager | The global singleton manager instance. |

#### createFlutterView

```typescript
createFlutterView(context: Context): FlutterView
```

Creates a new `FlutterView` instance and registers it with the manager. The viewId is generated automatically in the `oh_flutter_${index}` format (with an incrementing index).

It is **recommended** to keep the `oh_flutter_` prefix; otherwise, rendering performance may be affected.

##### Parameters

| Parameter | Type    | Description          |
| --------- | ------- | -------------------- |
| context   | Context | Application context. |

##### Return Value

| Type        | Description                        |
| ----------- | ---------------------------------- |
| FlutterView | The newly created view instance.   |

#### deleteFlutterView

```typescript
deleteFlutterView(viewId: string, flutterView?: FlutterView): void
```

Removes the specified `FlutterView` from the manager's view list. `FlutterView.onSurfaceDestroyed` calls this method internally to complete the cleanup.

##### Parameters

| Parameter   | Type        | Required | Description                                                        |
| ----------- | ----------- | -------- | ------------------------------------------------------------------ |
| viewId      | string      | Yes      | The ID of the view to remove.                                      |
| flutterView | FlutterView | No       | If the view instance is passed in, the deletion is performed; otherwise, nothing happens. |

#### setUseFullScreen

```typescript
setUseFullScreen(use: boolean, context?: Context | null | undefined): void
```

Sets whether the current window uses full-screen layout. This is delegated internally to a `FullScreenListener` implementation, controlled by `mainWindow.setWindowLayoutFullScreen` by default. On 2-in-1 devices with API 14+, enabling full screen also calls `maximize(ENTER_IMMERSIVE)`.

In `onWindowStageCreate`, `FlutterAbility` calls this method automatically if `isDefaultFullScreen()` returns `true`.

##### Parameters

| Parameter | Type    | Required | Description                                                        |
| --------- | ------- | -------- | ------------------------------------------------------------------ |
| use       | boolean | Yes      | `true` enables full-screen layout; `false` disables it.            |
| context   | Context | No       | Application context; if not set, the context of the first registered UIAbility is used. |

#### setSpecificSystemBarEnabled

```typescript
setSpecificSystemBarEnabled(
  flutterViewId: string,
  specificSystemBar: 'status' | 'navigation' | 'navigationIndicator',
  isVisible: boolean,
  enableAnimation?: boolean,
  context?: Context
): void
```

Controls the system bar visibility of the window associated with the specified `FlutterView`, and automatically sets avoidance area insets for the view when system bars are hidden, preventing Flutter content from being obscured.

##### Parameters

| Parameter         | Type                                                    | Required | Description                                                        |
| ----------------- | ------------------------------------------------------- | -------- | ------------------------------------------------------------------ |
| flutterViewId     | string                                                  | Yes      | The ID of the target `FlutterView`.                                |
| specificSystemBar | `'status'` \| `'navigation'` \| `'navigationIndicator'` | Yes      | The system bar type: status bar, three-button navigation bar, or gesture navigation indicator. |
| isVisible         | boolean                                                 | Yes      | `true` to show; `false` to hide.                                   |
| enableAnimation   | boolean                                                 | No       | Whether to enable animation effects.                               |
| context           | Context                                                 | No       | Application context; if not set, the first registered UIAbility is used. |

##### specificSystemBar Enum Values

| Value                  | Description                     |
| ---------------------- | ------------------------------- |
| status                 | Status bar.                     |
| navigation             | Three-button navigation bar.    |
| navigationIndicator    | Gesture navigation indicator.   |

### Usage Example

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context must be obtained from a page or Ability
// const context: common.Context = ...

const manager = FlutterManager.getInstance();

// Create a FlutterView and obtain the viewId
const flutterView = manager.createFlutterView(context);
const viewId = flutterView.getId();

// Full-screen display (default behavior on non-2-in-1 devices)
manager.setUseFullScreen(true, context);

// Hide the status bar; the top avoidance area is set automatically
manager.setSpecificSystemBarEnabled(viewId, 'status', false);

// Use in a page
FlutterPage({ viewId: viewId })
```

## LifecycleChannel

### Overview

`LifecycleChannel` is the app lifecycle communication channel. It synchronizes app lifecycle states from the OpenHarmony side to the Flutter framework, sending `AppLifecycleState` state strings to the Dart side over a `BasicMessageChannel` (channel name `flutter/lifecycle`).

`FlutterAbility` and `FlutterEntry` call this channel's methods automatically in their lifecycle callbacks through `FlutterAbilityAndEntryDelegate`; app developers generally do not need to send them manually. The instance can be obtained via `FlutterEngine.getLifecycleChannel()`.

```typescript
import { FlutterEngine } from '@ohos/flutter_ohos';

// flutterEngine is provided by FlutterAbility or FlutterEntry
// const flutterEngine: FlutterEngine = ...

const lifecycleChannel = flutterEngine.getLifecycleChannel();

// Usually called automatically by the framework; the following is a manual notification example
lifecycleChannel?.appIsResumed();
lifecycleChannel?.appIsPaused();
```

This section focuses on the key APIs of `LifecycleChannel`.

### Key APIs

| API | Description |
| --- | --- |
| `appIsResumed()` | Notifies the Flutter app that it has entered the resumed (active foreground) state. |
| `appIsInactive()` | Notifies the Flutter app that it has entered the inactive state. |
| `appIsPaused()` | Notifies the Flutter app that it has entered the paused (background) state. |
| `appIsDetached()` | Notifies the Flutter app that it has entered the detached (separated from the engine) state. |

### Lifecycle State Mapping

`LifecycleChannel` computes the final state sent to Flutter based on both the UIAbility state and window focus:

| UIAbility State | Window Focused | Flutter State |
| --- | --- | --- |
| FOREGROUND | true | resumed |
| FOREGROUND | false | inactive |
| BACKGROUND | true / false | paused |
| DESTROY | true / false | detached |

When the UIAbility is in the FOREGROUND state but the window loses focus, the state actually sent to Flutter is `inactive` rather than `resumed`.

### Methods

#### appIsResumed

```typescript
appIsResumed(): void
```

Notifies the Flutter app that it has resumed to the active foreground state. The framework calls this automatically on the following occasions:

- `FlutterAbilityAndEntryDelegate.onShow()` (the Ability switches to the foreground);
- The `WindowStageEventType.RESUMED` window event;
- When the window regains focus while the Ability is in the foreground.

State sent: `AppLifecycleState.resumed` (focused) or `AppLifecycleState.inactive` (not focused).

#### appIsInactive

```typescript
appIsInactive(): void
```

Notifies the Flutter app that it has entered the inactive state, for example when the window loses focus but is still visible. The framework calls this automatically on the `WindowStageEventType.PAUSED` event.

State sent: `AppLifecycleState.inactive`.

#### appIsPaused

```typescript
appIsPaused(): void
```

Notifies the Flutter app that it has entered the paused background state. The framework calls this automatically in `FlutterAbilityAndEntryDelegate.onHide()` (the Ability switches to the background).

State sent: `AppLifecycleState.paused`.

#### appIsDetached

```typescript
appIsDetached(): void
```

Notifies the Flutter app that it has been detached from the engine, which usually happens when the Ability is destroyed, during the engine detach phase. The framework calls this automatically in `FlutterAbilityAndEntryDelegate.onDetach()` when `shouldDispatchAppLifecycleState()` returns `true`.

State sent: `AppLifecycleState.detached`.

### How to Obtain

```typescript
const lifecycleChannel = flutterEngine.getLifecycleChannel();
```

| Type | Description |
| --- | --- |
| LifecycleChannel \| null | `null` if the engine is not initialized. |

## NavigationChannel

### Overview

`NavigationChannel` is the Flutter route navigation communication channel. It synchronizes routing state between the ArkTS side and the Dart side over a `BasicMessageChannel` (channel name `flutter/navigation`). The framework sets the initial route through this channel when the engine starts, and drives the Flutter navigation stack with `pushRoute` / `popRoute` when the native side switches pages.

`FlutterAbility` / `FlutterEntry` call `setInitialRoute` automatically during engine initialization to set the initial route. App developers typically obtain the instance via `FlutterEngine.getNavigationChannel()` and then call `pushRoute` / `popRoute` proactively in native interactions.

```typescript
import { FlutterEngine } from '@ohos/flutter_ohos';

// flutterEngine is provided by FlutterAbility or FlutterEntry
// const flutterEngine: FlutterEngine = ...

const navigationChannel = flutterEngine?.getNavigationChannel();

// The native side actively switches the Flutter route
navigationChannel?.pushRoute('/detail');
```

This section focuses on the key APIs of `NavigationChannel`.

### Key APIs

| API | Description |
| --- | --- |
| `setInitialRoute(route)` | Sets the Flutter initial route; called automatically by the framework at engine startup. |
| `pushRoute(route)` | Pushes a new route to Flutter from the native side. |
| `popRoute()` | Notifies Flutter to pop the current route. |
| `setRoutePoppingListener(listener)` | Registers a route popping listener. |

### Methods

#### setInitialRoute

```typescript
setInitialRoute(route: string): void
```

Sets the initial route of the Flutter app. The framework calls this before executing the Dart entrypoint to ensure the target route takes effect when the Flutter first screen renders. It corresponds to the return value of `getInitialRoute()` in `FlutterAbility` / `FlutterEntry`.

##### Parameters

| Parameter | Type | Description                                            |
| --------- | ---- | ------------------------------------------------------ |
| route     | string | The initial route string, such as `"/"` or `"/home"`. |

#### pushRoute

```typescript
pushRoute(route: string): void
```

Pushes a new route onto the Flutter navigation stack from the native side. This applies to scenarios where native buttons, springboards, or other interactions trigger page navigation inside Flutter.

> Note: Use `pushRoute` to switch pages and **do not call `executeDartEntrypoint()` again**, because each engine's Dart Isolate can only be started once.

##### Parameters

| Parameter | Type | Description                    |
| --------- | ---- | ------------------------------ |
| route     | string | The route string to push.    |

#### popRoute

```typescript
popRoute(): void
```

Notifies Flutter to pop the current route. It is usually called in the ArkUI page's `onBackPress()`:

```typescript
onBackPress(): boolean {
  this.flutterEntry?.onBackPress(); // Triggers popRoute internally
  return true;
}
```

#### setRoutePoppingListener

```typescript
setRoutePoppingListener(listener: RoutePoppingListener): void
```

Registers a route popping listener, used to receive a callback when the Flutter side requests `SystemNavigator.pop()`.

##### Parameters

| Parameter | Type                | Description                        |
| --------- | ------------------- | ---------------------------------- |
| listener  | RoutePoppingListener | The route popping event listener. |

### How to Obtain

```typescript
const navigationChannel = flutterEngine.getNavigationChannel();
```

| Type | Description |
| --- | --- |
| NavigationChannel \| null | `null` if the engine is not initialized. |

### Usage Example

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';

export default class EntryAbility extends FlutterAbility {
  private flutterEngine: FlutterEngine | null = null;

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    this.flutterEngine = flutterEngine;
  }

  // Triggered by a native button: navigate to Flutter's /detail route
  jumpToFlutterDetail(): void {
    this.flutterEngine?.getNavigationChannel()?.pushRoute('/detail');
  }
}
```

## MethodChannel

### Overview

`MethodChannel` is a type of Flutter platform channel used for bidirectional communication of **method invocation and result return** between the ArkTS side and the Dart side. Plugins use a `MethodChannel` to receive method calls initiated on the Dart side and return results, and they can also invoke methods on the Dart side proactively.

A channel is identified by a unique `name`; the Dart side and the ArkTS side must use the same `name` to establish the channel. The default codec is `StandardMethodCodec`, and `JSONMethodCodec` can also be specified through a constructor parameter.

```typescript
import { MethodChannel, MethodCall, MethodResult } from '@ohos/flutter_ohos';

const channel = new MethodChannel('com.example.app/my_channel');

// Receive method calls from the Dart side
channel.setMethodCallHandler((call: MethodCall, result: MethodResult) => {
  switch (call.method) {
    case 'getBatteryLevel':
      result.success(85);
      break;
    default:
      result.notImplemented();
  }
});

// Proactively invoke a method on the Dart side
const value = await channel.invokeMethod('dartMethod', { arg: 1 });
```

This section focuses on the key APIs in `MethodChannel` that app developers can call.

### Key APIs

| API | Description |
| --- | --- |
| `new MethodChannel(name, codec?)` | Creates a method channel with the specified name and optional codec. |
| `setMethodCallHandler(handler)` | Sets the method call handler to receive calls from the Dart side. |
| `invokeMethod(method, args?)` | Invokes a method on the Dart side proactively; returns a `Promise`. |
| `setMethodCallHandler(null)` | Passes `null` to cancel the method call handler. |

### Methods

#### Constructor

```typescript
constructor(name: string, codec: MethodCodec = StandardMethodCodec.INSTANCE)
```

Creates a `MethodChannel` instance. The `name` and `codec` on the Dart side and the ArkTS side must be identical.

##### Parameters

| Parameter | Type        | Required | Description                                                    |
| --------- | ----------- | -------- | -------------------------------------------------------------- |
| name      | string      | Yes      | The unique channel identifier.                                 |
| codec     | MethodCodec | No       | The method codec; defaults to `StandardMethodCodec.INSTANCE`.  |

#### setMethodCallHandler

```typescript
setMethodCallHandler(handler: ((call: MethodCall, result: MethodResult) => void) | null): void
```

Sets the method call handler. When the Dart side calls via `MethodChannel.invokeMethod`, the framework decodes the method name and arguments and then calls back the `handler`. Passing `null` cancels the existing handler.

Inside the `handler`, you **must** call one of `result`'s `success` / `error` / `notImplemented`; otherwise, the Dart side's `await` will never return.

##### Parameters

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| handler | (call: MethodCall, result: MethodResult) => void \| null | The method call callback; pass `null` to cancel. |

##### MethodCall

| Field  | Type   | Description                                                                  |
| ------ | ------ | ---------------------------------------------------------------------------- |
| method | string | The method name.                                                             |
| args   | Any    | The arguments passed in from the Dart side, decoded by the codec; `null` when there are no arguments. |

##### MethodResult

| Method | Description |
| ------ | ----------- |
| `success(result)` | Returns a success result. |
| `error(code, message, details)` | Returns an error, with the error code, message, and details. |
| `notImplemented()` | Indicates that the method is not implemented. |

#### invokeMethod

```typescript
invokeMethod(method: string, args?: Any): Promise<Any>
```

Proactively invokes a method registered on the Dart side. The returned `Promise` resolves after the Dart side returns a result, and rejects when the Dart side throws a `MissingPluginException` or `PlatformException`.

##### Parameters

| Parameter | Type   | Required | Description                           |
| --------- | ------ | -------- | ------------------------------------- |
| method    | string | Yes      | The name of the Dart method to call.  |
| args      | Any    | No       | The arguments passed to the Dart side. |

##### Return Value

| Type | Description |
| ---- | ----------- |
| Promise\<Any> | The result returned from the Dart side. |

### Relationship to MissingPluginException

When the Dart side calls `MethodChannel.invokeMethod` but the ArkTS side **has not registered a corresponding `setMethodCallHandler`**, the Dart side throws a `MissingPluginException`. Common causes:

1. The plugin is not registered in `configureFlutterEngine` via `GeneratedPluginRegistrant.registerWith(flutterEngine)`;
2. A manually registered plugin does not call `setMethodCallHandler` for the corresponding channel in `onAttachedToEngine`;
3. The channel `name` differs between the Dart side and the ArkTS side.

When troubleshooting, first confirm that `GeneratedPluginRegistrant` contains the target plugin, then verify the channel name and the handler registration timing.

### Usage Example

```typescript
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
  MethodCall,
  MethodResult,
} from '@ohos/flutter_ohos';

class BatteryPlugin implements FlutterPlugin {
  private methodChannel: MethodChannel | null = null;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel('com.example.app/battery');
    this.methodChannel.setMethodCallHandler(this.onMethodCall.bind(this));
  }

  private onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'getLevel') {
      result.success(85);
    } else {
      result.notImplemented();
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
  }
}
```

> Related channel types: `EventChannel` is for event streams (Dart listens to events pushed proactively by ArkTS); `BasicMessageChannel` is for bidirectional message passing (`LifecycleChannel` / `NavigationChannel` are both built on it). Their usage is similar to `MethodChannel`, using `setStreamHandler` and `setMessageHandler` respectively.

## FlutterPlugin

### Overview

`FlutterPlugin` is the **root interface of Flutter plugins**. It defines the lifecycle callbacks for when a plugin is attached to and detached from a `FlutterEngine`. All platform native plugins (MethodChannel, PlatformView, EventChannel, and so on) must implement this interface and obtain the `BinaryMessenger`, `FlutterEngine`, context, and registries needed for communication through `FlutterPluginBinding`.

Plugins are registered with the engine in two ways:

1. **Automatic registration**: `GeneratedPluginRegistrant.registerWith(flutterEngine)` is called in `configureFlutterEngine` of `FlutterAbility` / `FlutterEntry`, and the auto-generated registrant class attaches the plugins declared in `pubspec.yaml` in batch.
2. **Manual registration**: plugins are attached individually via `flutterEngine.getPlugins()?.add(new MyPlugin())`.

In either case, the framework calls back `onAttachedToEngine` when attaching and `onDetachedFromEngine` when detaching.

```typescript
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
} from '@ohos/flutter_ohos';

class MyPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel('com.example.app/my');
    this.channel.setMethodCallHandler((call, result) => {
      // Handle the Dart-side method call
    });
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }
}
```

This section focuses on the key APIs of `FlutterPlugin`.

### Key APIs

| API | Description |
| --- | --- |
| `onAttachedToEngine(binding)` | Called back when the plugin is attached to the engine; used to initialize channels, register handlers, and so on. |
| `onDetachedFromEngine(binding)` | Called back when the plugin is detached from the engine; used to release resources and unregister handlers. |

### Methods

#### onAttachedToEngine

```typescript
onAttachedToEngine(binding: FlutterPluginBinding): void
```

Called back by the framework when the plugin is attached to a `FlutterEngine`. This method typically:

- Creates `MethodChannel`s / `EventChannel`s via `binding.getBinaryMessenger()`;
- Registers platform view factories via `binding.getPlatformViewRegistry()`;
- Obtains the context via `binding.getContext()` and initializes platform resources;
- Calls `setMethodCallHandler` / `setMessageHandler` on each channel.

##### Parameters

| Parameter | Type                | Description                                                        |
| --------- | ------------------- | ------------------------------------------------------------------ |
| binding   | FlutterPluginBinding | The engine binding object, providing communication and context capabilities. |

#### onDetachedFromEngine

```typescript
onDetachedFromEngine(binding: FlutterPluginBinding): void
```

Called back by the framework when the plugin is detached from a `FlutterEngine`. In this method you should:

- Call `setMethodCallHandler(null)` / `setMessageHandler(null)` on each channel to unregister handlers;
- Release platform resources and remove listeners;
- Null out references to avoid memory leaks.

##### Parameters

| Parameter | Type                | Description                 |
| --------- | ------------------- | --------------------------- |
| binding   | FlutterPluginBinding | The engine binding object.  |

## FlutterPluginBinding

### Overview

`FlutterPluginBinding` is passed in by the framework when a plugin is attached / detached. It encapsulates all the capabilities a plugin needs to interact with a `FlutterEngine`: message channels, the engine instance, the context, the platform view registry, the lifecycle channel, and more.

### Key APIs

| API | Description |
| --- | --- |
| `getFlutterEngine()` | Returns the associated `FlutterEngine` instance. |
| `getBinaryMessenger()` | Returns the `BinaryMessenger`, used to create MethodChannels / EventChannels. |
| `getContext()` | Returns the application context. |
| `getPlatformViewRegistry()` | Returns the platform view registry, used to register a `PlatformViewFactory`. |
| `getLifecycleChannel()` | Returns the lifecycle channel (for plugins that need lifecycle awareness). |

### Methods

#### getFlutterEngine

```typescript
getFlutterEngine(): FlutterEngine
```

Returns the `FlutterEngine` instance the plugin is currently attached to, which can be used to further access `getPlugins()`, other channels, or the renderer.

##### Return Value

| Type | Description |
| ---- | ----------- |
| FlutterEngine | The associated engine instance. |

#### getBinaryMessenger

```typescript
getBinaryMessenger(): BinaryMessenger
```

Returns the `BinaryMessenger`, the underlying message bus for creating `MethodChannel`s / `EventChannel`s / `BasicMessageChannel`s. `DartExecutor` also implements this interface; internally, the framework provides it through the engine's `DartExecutor`.

##### Return Value

| Type | Description |
| ---- | ----------- |
| BinaryMessenger | The message bus instance. |

#### getContext

```typescript
getContext(): common.Context
```

Returns the application context, used to access resources, capabilities, and so on.

##### Return Value

| Type | Description |
| ---- | ----------- |
| common.Context | The application context. |

#### getPlatformViewRegistry

```typescript
getPlatformViewRegistry(): PlatformViewRegistry
```

Returns the platform view registry, used to register a `PlatformViewFactory`. See [PlatformViewRegistry](#platformviewregistry) for details.

##### Return Value

| Type | Description |
| ---- | ----------- |
| PlatformViewRegistry | The platform view registry instance. |

#### getLifecycleChannel

```typescript
getLifecycleChannel(): LifecycleChannel
```

Returns the lifecycle channel, for plugins to sense the app's foreground/background state. See [LifecycleChannel](#lifecyclechannel) for details.

##### Return Value

| Type | Description |
| ---- | ----------- |
| LifecycleChannel | The lifecycle channel instance. |

### Usage Example

A complete plugin example (MethodChannel + resource access):

```typescript
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
  MethodCall,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

export class BatteryPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getContext();
    this.channel = new MethodChannel('com.example.app/battery');
    this.channel.setMethodCallHandler(this.onMethodCall.bind(this));
  }

  private onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'getLevel') {
      // Call system capabilities via context to obtain the battery level
      result.success(85);
    } else {
      result.notImplemented();
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.context = null;
  }
}
```

Manually registering with the engine:

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { BatteryPlugin } from './BatteryPlugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    // Manually attach a plugin that is not declared in pubspec
    flutterEngine.getPlugins()?.add(new BatteryPlugin());
  }
}
```

> When a `MissingPluginException` is thrown for a channel method call on the Dart side, check the following first:
> 1. Whether the plugin is registered in `configureFlutterEngine` (automatically or manually);
> 2. Whether `setMethodCallHandler` is called for the corresponding channel in `onAttachedToEngine`;
> 3. Whether the channel `name` is identical on the Dart and ArkTS sides.

## PlatformViewRegistry

### Overview

`PlatformViewRegistry` is the registry interface for platform view factories. It allows plugins to register native view factories for specific `viewTypeId`s, thereby embedding OpenHarmony native components (ArkUI components) in the Flutter widget tree.

The implementing class is `PlatformViewRegistryImpl`, held internally by `PlatformViewsController`. When registering, plugins obtain the registry instance via `FlutterPlugin.FlutterPluginBinding.getPlatformViewRegistry()`.

```typescript
import { FlutterPlugin, PlatformViewFactory, PlatformView } from '@ohos/flutter_ohos';
import { StandardMessageCodec } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// MyPlatformView must be a subclass implementation of PlatformView
// class MyPlatformView extends PlatformView { ... }

class MyPlatformViewFactory extends PlatformViewFactory {
  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    // Create and return the native PlatformView instance
    return new MyPlatformView(context);
  }
}

// Register in the plugin's onAttachedToEngine
// binding.getPlatformViewRegistry().registerViewFactory('my-view-type', new MyPlatformViewFactory());
```

This section focuses on the key APIs of `PlatformViewRegistry`.

### Key APIs

| API | Description |
| --- | --- |
| `registerViewFactory(viewTypeId, factory)` | Registers a platform view factory for the specified viewTypeId. |
| `getFactory(viewTypeId)` | Returns the registered factory (provided by `PlatformViewRegistryImpl`). |

### Methods

#### registerViewFactory

```typescript
registerViewFactory(viewTypeId: string, factory: PlatformViewFactory): boolean
```

Registers a `PlatformViewFactory` for the specified `viewTypeId`. The Dart side references this ID through the `viewType` parameter of the `PlatformView` widget, and the framework calls the corresponding factory's `create` method when creating the platform view.

A `viewTypeId` can only be registered once; if it already exists, `false` is returned and the existing entry is not overwritten.

##### Parameters

| Parameter | Type                | Description                                                                                                       |
| --------- | ------------------- | ----------------------------------------------------------------------------------------------------------------- |
| viewTypeId | string             | The unique platform view type identifier; must match the viewType used by the Dart-side OhosView / UiKitView / AndroidView and the like. |
| factory   | PlatformViewFactory | The factory class used to create platform view instances.                                                          |

##### Return Value

| Type    | Description                                                              |
| ------- | ------------------------------------------------------------------------ |
| boolean | `true` if the registration succeeds; `false` if the viewTypeId is already registered. |

#### getFactory

```typescript
getFactory(viewTypeId: string): PlatformViewFactory
```

Returns the `PlatformViewFactory` for the specified `viewTypeId`. This method is implemented by `PlatformViewRegistryImpl` and called internally by `PlatformViewsController` when creating a platform view.

App developers usually only need to register a factory; there is no need to call this method directly.

##### Parameters

| Parameter | Type   | Description                     |
| --------- | ------ | ------------------------------- |
| viewTypeId | string | The platform view type ID.     |

##### Return Value

| Type                | Description                                                |
| ------------------- | ---------------------------------------------------------- |
| PlatformViewFactory | The corresponding factory instance; returns `undefined` if not registered. |

### PlatformViewFactory

See the [PlatformViewFactory](#platformviewfactory) section for the full documentation.

## PlatformViewFactory

### Overview

`PlatformViewFactory` is the abstract base class for platform view factories. It creates the corresponding OpenHarmony native view instance based on requests from the Dart-side `PlatformView` widget. After a plugin registers a factory via `PlatformViewRegistry.registerViewFactory`, the framework calls the factory's `create` method when the Flutter rendering tree needs to embed a native component.

```typescript
import { PlatformViewFactory, PlatformView } from '@ohos/flutter_ohos';
import { StandardMessageCodec } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// MyNativeView must be a subclass implementation of PlatformView
class MyViewFactory extends PlatformViewFactory {
  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new MyNativeView(context, viewId, args);
  }
}
```

This section focuses on the key APIs in `PlatformViewFactory` that plugin developers implement.

### Key APIs

| API | Description |
| --- | --- |
| `new PlatformViewFactory(createArgsCodec)` | Constructs the factory, specifying the codec for the Dart creation parameters. |
| `create(context, viewId, args)` | Creates a platform view instance (abstract method that subclasses must implement). |
| `getCreateArgsCodec()` | Returns the codec used to decode `args`. |

### Methods

#### Constructor

```typescript
constructor(createArgsCodec: MessageCodec<Any>)
```

Creates a `PlatformViewFactory` instance and saves the codec used to decode the creation parameters passed in from the Dart side.

Common codecs:

| Codec | Description |
| --- | --- |
| `StandardMessageCodec.INSTANCE` | Standard message codec that supports common basic types. |
| `JSONMethodCodec` / `JSONMessageCodec` | JSON-format encoding and decoding. |

##### Parameters

| Parameter      | Type               | Description                                                    |
| -------------- | ------------------ | -------------------------------------------------------------- |
| createArgsCodec | MessageCodec\<Any> | The codec used to decode the `args` parameter of the `create` method. |

#### create

```typescript
abstract create(context: common.Context, viewId: number, args: Any): PlatformView
```

Creates and returns a new `PlatformView` instance for the Flutter rendering tree to embed. Subclasses must implement this method.

##### Parameters

| Parameter | Type           | Description                                                                                       |
| --------- | -------------- | ------------------------------------------------------------------------------------------------- |
| context   | common.Context | The context used to create the view; it may differ from the `FlutterView`'s context.              |
| viewId    | number         | The unique instance ID assigned by the Dart side, identifying the platform view created this time. |
| args      | Any            | The creation parameters passed in from the Dart side, decoded by `createArgsCodec`; `null` when there are no parameters. |

##### Return Value

| Type         | Description                            |
| ------------ | -------------------------------------- |
| PlatformView | The newly created platform view instance. |

#### getCreateArgsCodec

```typescript
getCreateArgsCodec(): MessageCodec<Any>
```

Returns the codec passed in at construction; the framework uses it when decoding the Dart side's `creationParams`.

##### Return Value

| Type               | Description                    |
| ------------------ | ------------------------------ |
| MessageCodec\<Any> | The creation parameter codec.  |

## PlatformView

### Overview

`PlatformView` is the abstract class for native view handles embedded in the Flutter rendering hierarchy. Plugins implement it and return an ArkUI `WrappedBuilder` from `getView()`; the `EmbeddingNodeController` builds it into a `FrameNode` and mounts it in the Flutter component tree.

```typescript
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';

class MyNativeView extends PlatformView {
  getView(): WrappedBuilder<[Params]> {
    return wrapBuilder(buildNativeComponent);
  }

  dispose(): void {
    // Release resources
  }
}

@Builder
function buildNativeComponent(params: Params) {
  // Build the ArkUI native component
}
```

This section focuses on the key APIs in `PlatformView` that plugin developers implement.

### Key APIs

| API | Description |
| --- | --- |
| `getView()` | Returns the ArkUI `WrappedBuilder` to embed in the Flutter hierarchy. |
| `dispose()` | Destroys the platform view and releases all references (abstract method that must be implemented). |
| `onFlutterViewAttached(dvModel)` | Called back when a Flutter rendering view is attached. |
| `onFlutterViewDetached()` | Called back when a Flutter rendering view is detached. |
| `getType()` | Returns the platform view type identifier. |
| `onActive()` | Resumes continuous texture production (animations, videos, and so on) when the view's visible area reaches the threshold. |
| `onInactive()` | Pauses continuous texture production when the view is not visible. |
| `getPlatformViewVisibleAreaEventOptions()` | Configures visible area monitoring thresholds to control when `onActive` / `onInactive` are triggered. |

### Methods

#### getView

```typescript
abstract getView(): WrappedBuilder<[Params]>
```

Returns the ArkUI builder embedded in the Flutter component tree. `EmbeddingNodeController` calls this method during `setRenderOption` and renders the native component onto the Flutter surface via `BuilderNode.build`.

`Params` contains the following fields:

| Field | Type | Description |
| --- | --- | --- |
| direction | Direction | The layout direction. |
| platformView | PlatformView | A reference to the current platform view instance. |

##### Return Value

| Type | Description |
| ---- | ----------- |
| WrappedBuilder\<[Params]> | The ArkUI component builder. |

#### dispose

```typescript
abstract dispose(): void
```

Destroys the platform view. After the call, the `PlatformView` instance can no longer be used. Plugins must clear references to the `DynamicView` and all native resources in this method; otherwise, memory leaks will occur.

The framework calls this method in `PlatformViewsController.dispose(viewId)`.

#### onFlutterViewAttached

```typescript
onFlutterViewAttached(dvModel: DVModel): void
```

Called when the `FlutterEngine` that owns this `PlatformView` is associated with the `DynamicView` responsible for rendering the Flutter UI. It indicates that the Flutter engine now has rendering capability and a user interaction surface.

`PlatformViewsController` triggers this callback when the platform view is attached to a `FlutterView`. Subclasses may override it to obtain the `DVModel` reference, but should avoid strong dependencies where possible to reduce fragility against future architecture changes.

##### Parameters

| Parameter | Type    | Description                                          |
| --------- | ------- | ---------------------------------------------------- |
| dvModel   | DVModel | The dynamic view model associated with the FlutterView. |

#### onFlutterViewDetached

```typescript
onFlutterViewDetached(): void
```

Called when the Flutter rendering view is detached from the `FlutterEngine`. It indicates that the engine no longer has a rendering surface or a user interaction surface. Subclasses should release all `DynamicView`-related references obtained in `onFlutterViewAttached`.

#### getType

```typescript
getType(): string
```

Returns the platform view type identifier, which defaults to `'default'`. Subclasses may override it to return a custom type string to distinguish different rendering strategies.

##### Return Value

| Type   | Description                        |
| ------ | ---------------------------------- |
| string | The platform view type identifier. |

#### onActive

```typescript
onActive(): void
```

Resumes continuous production of external textures, including animations and video playback. It is called automatically by `EmbeddingNodeController` through visible area monitoring when the platform view's visible area ratio reaches the `onActiveThreshold`.

Subclasses may override it to resume video playback, animations, and other operations that consume GPU texture resources.

#### onInactive

```typescript
onInactive(): void
```

Pauses continuous production of external textures. It is called automatically by `EmbeddingNodeController` when the platform view's visible area ratio falls below `onInactiveThreshold` or the view becomes invisible.

Subclasses may override it to pause video playback, animations, and so on, saving system resources.

### Visible Area Monitoring

A platform view can override `getPlatformViewVisibleAreaEventOptions()` to configure visible area monitoring and control the thresholds that trigger `onActive` / `onInactive`:

```typescript
getPlatformViewVisibleAreaEventOptions(): PlatformViewVisibleAreaEventOptions
```

The return value `PlatformViewVisibleAreaEventOptions` contains the following fields:

| Parameter | Type | Description |
| --- | --- | --- |
| enable | boolean | Whether to enable visible area monitoring; defaults to `false`. |
| ratios | Array\<number> | An array of visible ratio thresholds, such as `[0.0, 1.0]`. |
| expectedUpdateInterval | number | The update interval in milliseconds; defaults to `1000`. |
| onInactiveThreshold | number | The visible ratio threshold that triggers `onInactive`; defaults to `0.0`. |
| onActiveThreshold | number | The visible ratio threshold that triggers `onActive`; defaults to `1.0`. |

### Usage Example

```typescript
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { PlatformViewFactory } from '@ohos/flutter_ohos';
import { StandardMessageCodec } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// The @Builder function must be declared in the global scope
@Builder
function buildMap(params: Params) {
  // Embed a native map component
  Column() {
    Text('Native Map View')
  }
}

// 1. Implement PlatformView
class NativeMapView extends PlatformView {
  private context: common.Context;

  constructor(context: common.Context) {
    super();
    this.context = context;
  }

  getView(): WrappedBuilder<[Params]> {
    return wrapBuilder(buildMap);
  }

  getType(): string {
    return 'map';
  }

  onActive(): void {
    // Resume map animations
  }

  onInactive(): void {
    // Pause map animations
  }

  dispose(): void {
    // Release map resources
  }
}

// 2. Implement PlatformViewFactory and register it
class NativeMapFactory extends PlatformViewFactory {
  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new NativeMapView(context);
  }
}

// Register in the plugin's onAttachedToEngine:
// binding.getPlatformViewRegistry().registerViewFactory('my_map_view', new NativeMapFactory());
```

## PlatformViewWrapper

### Overview

`PlatformViewWrapper` wraps a platform view, intercepting gestures and projecting them onto the rendering target. OpenHarmony platform views are composited through the engine's `TextureLayer`: the view is embedded in the ArkUI `DynamicView` hierarchy and, at the same time, projected onto a texture rendering target, which the Flutter engine composites efficiently.

Because the view lives in the ArkUI view hierarchy, keyboard and accessibility interactions work normally. When creating a platform view, `PlatformViewsController` instantiates a `PlatformViewWrapper` internally and mounts the `DVModel` into the `FlutterView`'s component tree.

```typescript
import { PlatformViewWrapper } from '@ohos/flutter_ohos';
import { createDVModelFromJson, DVModelJson } from '@ohos/flutter_ohos';

// Usually created internally by PlatformViewsController; the following is a structural illustration
// dvModel is created by createDVModelFromJson; flutterView is provided by FlutterManager
const viewWrapper = new PlatformViewWrapper();
viewWrapper.addDvModel(dvModel);
flutterView.getDVModel().children.push(viewWrapper.getDvModel());
```

This section focuses on the key APIs of `PlatformViewWrapper`.

### Key APIs

| API | Description |
| --- | --- |
| `new PlatformViewWrapper()` | Constructs a platform view wrapper instance. |
| `setTouchProcessor(newTouchProcessor)` | Sets the touch event processor. |
| `addDvModel(model)` | Adds a `DynamicView` model to the wrapper. |
| `setLayoutParams(parameters)` | Sets the platform view's layout parameters (position and size). |

### Methods

#### Constructor

```typescript
constructor()
```

Creates an empty `PlatformViewWrapper` instance. After creation, use `addDvModel` to associate a `DVModel`; `PlatformViewsController` then mounts it into the `FlutterView`'s `DVModel.children` list.

#### setTouchProcessor

```typescript
setTouchProcessor(newTouchProcessor: OhosTouchProcessor): void
```

Sets the `OhosTouchProcessor` that handles touch events for the platform view. The touch processor converts touch events on the ArkUI side into a format the Flutter engine recognizes and dispatches them.

##### Parameters

| Parameter        | Type              | Description                       |
| ---------------- | ----------------- | --------------------------------- |
| newTouchProcessor | OhosTouchProcessor | The touch event processor instance. |

#### addDvModel

```typescript
addDvModel(model: DVModel): void
```

Adds a `DynamicView` model to the wrapper. When creating a platform view, `PlatformViewsController` first builds a `DVModel` containing a `NodeContainer` and an `EmbeddingNodeController` via `createDVModelFromJson`, then calls this method to associate it.

After the association, the model is obtained via `getDvModel()` and pushed into `FlutterView.getDVModel().children`, completing the mounting of the platform view in the Flutter component tree.

##### Parameters

| Parameter | Type    | Description                                 |
| --------- | ------- | ------------------------------------------- |
| model     | DVModel | The DynamicView model instance to add.      |

#### setLayoutParams

```typescript
setLayoutParams(parameters: DVModelParameters): void
```

Sets the platform view's layout parameters, updating the position and size information in the `DVModel`'s `params`.

The following fields are read from `parameters` and applied:

| Parameter Field | Description                              |
| --------------- | ---------------------------------------- |
| marginLeft      | Left margin; also updates the internal `left`. |
| marginTop       | Top margin; also updates the internal `top`.   |
| width           | The view width.                          |
| height          | The view height.                         |

If no `DVModel` is associated yet (`model` is `undefined`), the call is ignored.

##### Parameters

| Parameter  | Type              | Description                    |
| ---------- | ----------------- | ------------------------------ |
| parameters | DVModelParameters | The layout parameter object.  |

### Internal Usage Flow

The typical flow when `PlatformViewsController` creates a platform view:

1. Creates the `PlatformView` instance via `PlatformViewFactory.create`;
2. Creates the `EmbeddingNodeController` and sets the rendering options;
3. Builds a `NodeContainer`-type `DVModel` via `createDVModelFromJson`;
4. `new PlatformViewWrapper()` → `addDvModel(dvModel)` → stores it in the `viewWrappers` map;
5. Pushes `viewWrapper.getDvModel()` into `FlutterView.getDVModel().children`;
6. Calls `platformView.onFlutterViewAttached`.

### Usage Example

```typescript
import { PlatformViewWrapper } from '@ohos/flutter_ohos';
import { createDVModelFromJson, DVModelJson } from '@ohos/flutter_ohos';
import { EmbeddingNodeController } from '@ohos/flutter_ohos';
import { PlatformView } from '@ohos/flutter_ohos';

// The following is a simplified illustration of PlatformViewsController's internal logic
function createPlatformViewWrapper(
  viewId: number,
  platformView: PlatformView,
  nodeController: EmbeddingNodeController,
  width: number,
  height: number,
  left: number,
  top: number
): PlatformViewWrapper {
  const dvModel = createDVModelFromJson(new DVModelJson(
    'NodeContainer',
    [],
    {
      width: width,
      height: height,
      nodeController: nodeController,
      left: left,
      top: top,
    },
    {},
    undefined
  ));

  const viewWrapper = new PlatformViewWrapper();
  viewWrapper.addDvModel(dvModel);

  return viewWrapper;
}
```
