# FlutterEnginePreload User Guide

`FlutterEnginePreload` aims to accelerate page navigation rendering in hybrid applications combining native and Flutter, optimizing user experience. The core idea is to move part of the execution logic to the moment of user interaction (e.g., button press) instead of executing it after the event is triggered (e.g., button release).

## Prerequisites

+ The application needs a mechanism to navigate from a native page to a Flutter page. For instance, when a user clicks a button to navigate, preloading can be used to speed up Flutter page rendering.
+ Flutter version 3.22 or above is required.

---

## Steps to Use

In the native `arkts` page, first import the following utility class:

    import { FlutterEnginePreload } from '@ohos/flutter_ohos';

### External Interfaces Provided

`FlutterEnginePreload` provides two core interfaces:

1. **`preloadEngine`**
2. **`predrawEngine`**

---

## Interface Description

### 1. `preloadEngine`

The parameters of `preloadEngine` are as follows:

- **`Context`**: Pass the current page's `context`.
- **`Params`**: Pass the corresponding NAPI parameters, which are mostly consistent with `FlutterEntry` and `FlutterAbility`. For detailed settings, refer to `FlutterAbilityLaunchConfigs`, including but not limited to the following parameters:
    - **`dart_entrypoint`**: Sets the entry point function name (default is `main`).
    - **`route`**: Sets the default initial route (default is `/`).
    - **`cached_engine_id`**: Sets the unique ID of the cached `FlutterEngine` you want to reuse. If this parameter is passed, the pre-created engine can be reused (the engine must have been previously added to the `FlutterEngineCache` for management).
    - **`viewport_metrics`**: Developers can set `viewport_metrics` during preloading, especially when the Flutter page to be rendered is not fullscreen. You need to set `viewportMetrics.physicalWidth` and `viewportMetrics.physicalHeight` as the width and height for pre-rendering; otherwise, it defaults to fullscreen pre-rendering.
- **`nextViewId`**: Identifies the `FlutterView` ID to be pre-rendered. You can pass `null`, which will automatically retrieve the next ID by calling `FlutterManager.getInstance().getNextFlutterViewId()`.
    - **Note**: When pre-rendering multiple pages simultaneously, different `nextViewId` values must be passed. You can use `getNextFlutterViewId(offset)` to pass an offset and get the `(offset+1)`th `viewId`.

---

### 2. `predrawEngine`

The `predrawEngine` interface is similar to `preloadEngine`, except that its first parameter directly passes a `FlutterEngine` instance. Therefore, the pre-created engine does not need to be maintained by `FlutterEngineCache`.

The usage and configuration of the other parameters are the same as `preloadEngine`.

---

## Implementation Examples

### Example 1: Simple Case

Below is the typical implementation logic for preloading a Flutter page through a button:

```arkts
build() {
  Button(this.title)
    .onClick(() => {
      try {
        router.pushUrl({ url: 'pages/Flutter', params: { route: this.route } });
      } catch (err) {
        Log.d(TAG, `Page navigation ${this.route} error === ${JSON.stringify(err)}`);
      }
    })
    .onTouch((touch: TouchEvent) => {
      if (touch.type == TouchType.Down) {
        let params: Record<string, Object> = {};
        params['route'] = this.route;
        FlutterEnginePreload.preloadEngine(getContext(this), params);
      }
    });
}
```

For a complete demo, refer to: [Flutter_it_preload](../../../ohos/flutter_it_preload/)

**Preloading Logic Location**: `pages/index.ets`

---

### Example 2: Complex Case

Below is a more complex scenario where a cached `FlutterEngine` is used, the target page contains multiple Flutter pages, and dimensions and `FlutterViewId` offsets need to be set.

This scenario involves two steps: **Step 1 creates the engine and registers plugins during page initialization**, and **Step 2 pre-renders the engine on the touch event**.

#### Step 1: Create the Engine, Register Plugins, and Add to Cache

In the `MainPage` lifecycle function (e.g., `aboutToAppear`), manually create a `FlutterEngine` and add it to the `FlutterEngineCache` for management.

> **Important**: After manually creating the engine, you must call `GeneratedPluginRegistrant.registerWith(engine)` to register plugins. Otherwise, the native implementations of Flutter plugins (such as path_provider, shared_preferences, etc.) will not be bound to the engine, and calling plugins from Dart code will result in errors. In the standard `FlutterAbility` flow, plugin registration is performed automatically; however, when creating an engine manually, the developer must register plugins themselves.

```arkts
import { FlutterEngineCache, engines, GeneratedPluginRegistrant } from '@ohos/flutter_ohos';

aboutToAppear() {
  // Create engine options
  let options: FlutterAbilityLaunchConfigs = new FlutterAbilityLaunchConfigs();
  options.dart_entrypoint = 'main';
  options.route = '/';

  // Create and run the engine
  let engine = await engines.createAndRunEngineByOptions(options) ?? undefined;

  // Plugins must be registered, otherwise Flutter plugin calls will fail
  GeneratedPluginRegistrant.registerWith(engine);

  // Add the engine to the cache so that predrawEngine can reuse it
  FlutterEngineCache.getInstance().put('DoubleFlutterTop', engine);

  // Repeat the above steps to create and cache additional engines if needed
  let options2: FlutterAbilityLaunchConfigs = new FlutterAbilityLaunchConfigs();
  options2.dart_entrypoint = 'main';
  options2.route = '/second';
  let engine2 = await engines.createAndRunEngineByOptions(options2) ?? undefined;
  GeneratedPluginRegistrant.registerWith(engine2);
  FlutterEngineCache.getInstance().put('DoubleFlutterBottom', engine2);
}
```

#### Step 2: Pre-render the Engine on the Touch Event

In the button's `onTouch` event, call `predrawEngine` to retrieve the engine from the cache for pre-rendering:

```arkts
.onTouch((touch: TouchEvent) => {
  if (touch.type == TouchType.Down) {
    let params: Record<string, Object> = {};
    let viewports: ViewportMetrics = new ViewportMetrics();
    // For multi-engine scenarios, manually add an offset to the incoming view ID
    let nextViewId = FlutterManager.getInstance().getNextFlutterViewId();
    let nextViewId2 = FlutterManager.getInstance().getNextFlutterViewId(1);
    viewports.physicalWidth = display.getDefaultDisplaySync().width;
    viewports.physicalHeight = display.getDefaultDisplaySync().height / 2;
    params[FlutterAbilityLaunchConfigs.PRELOAD_VIEWPORT_METRICS_KEY] = viewports;

    FlutterEnginePreload.predrawEngine(
      FlutterEngineCache.getInstance().get('DoubleFlutterTop'),
      params,
      nextViewId
    );

    FlutterEnginePreload.predrawEngine(
      FlutterEngineCache.getInstance().get('DoubleFlutterBottom'),
      params,
      nextViewId2
    );
  }
});
```

For a complete demo, refer to: [Multiple_flutters_predraw](../../../ohos/multiple_flutters_predraw/)

**Engine Creation and Registration Location**: `aboutToAppear` and other lifecycle functions in `pages/MainPage.ets`
**Pre-rendering Logic Location**: `onTouch` event in `pages/MainPage.ets`

---

## Verification of Results

After correctly adding `preload` in the project, the rendering speed of page navigation can be significantly optimized. To verify the effect before and after optimization, you can:

1. **Slow-motion recording**: Observe the speed of Flutter page loading during navigation.
2. **Capture application traces**: Analyze the changes in page loading time.
3. **DevTools**: During hybrid application development and debugging, the native application is opened by default, and DevTools will not establish a connection. When preload is triggered (e.g., touch event), even if no actual navigation occurs, the connection will be automatically established.

---

## Notes

1. When setting `viewport_metrics`, ensure that the passed width and height match the actual rendering area.
2. If multiple pages are to be pre-rendered simultaneously, ensure that `nextViewId` values are not repeated.
3. **After manually creating an engine, you must call `GeneratedPluginRegistrant.registerWith(engine)` to register plugins.** In the standard `FlutterAbility` flow, plugin registration is performed automatically; however, when creating an engine manually via `engines.createAndRunEngineByOptions` or similar methods, plugins are not registered automatically and must be registered manually by the developer. Failing to register plugins will cause `MissingPluginException` when calling plugins from the Dart side. Additionally, if a plugin implements `AbilityAware`, you must also call `engine.getAbilityControlSurface()?.attachToAbility(host)` to attach it to the Ability; otherwise, the plugin will not be able to obtain the context and channel binding will fail. For the complete 3-category root cause troubleshooting (lifecycle / registration call / plugin ohos layer), see [Flutter Plugin MissingPluginException](../faq/plugin-adaptation-faq.en.md#section592016).
4. Engine creation and caching should be completed during the page initialization phase (e.g., `aboutToAppear`) to ensure that the engine already exists in the cache when `predrawEngine` is called.