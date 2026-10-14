# FlutterEnginePreload 使用指南

`FlutterEnginePreload` 旨在加速原生与 Flutter 混编应用的跳转渲染，优化用户体验。其基本思路是将部分执行逻辑提前到用户交互事件（如按钮按下）发生时，而不是在触发事件（如按钮抬起）后执行。

## 使用前提

+ 应用需要通过某种方式从原生页面跳转到 Flutter 页面。例如，当用户点击一个按钮跳转页面时，可以通过预加载的方式加速 Flutter 页面渲染。
+ Flutter版本需要3.22及以上。

---

## 使用步骤

在原生 `arkts` 页面中，需要先引用以下工具类：

`import { FlutterEnginePreload } from '@ohos/flutter_ohos';`

### 提供的外部接口

`FlutterEnginePreload` 提供两个核心接口：

1. **`preloadEngine`**
2. **`predrawEngine`**

---

## 接口说明

### 1. `preloadEngine`

`preloadEngine` 的参数说明如下：

- **`Context`**：传入当前页面的 `context` 即可。
- **`Params`**：传递对应的 NAPI 参数，基本与 `FlutterEntry` 和 `FlutterAbility` 一致。详细设置可参考 `FlutterAbilityLaunchConfigs`，包括但不限于以下参数：
  - **`dart_entrypoint`**：设置入口点函数名称（默认为 `main`）。
  - **`route`**：设置默认初始路由（默认为 `/`）。
  - **`cached_engine_id`**：设置想要复用的缓存 `FlutterEngine` 的唯一标识 ID。传入此参数后，可复用预创建的引擎（需之前已将该引擎放入 `FlutterEngineCache` 缓存管理中）。
  - **`viewport_metrics`**：开发者在预加载时，可提前设置 `viewport_metrics`，特别是当待渲染的 Flutter 页面并非全屏时。需要提前设置 `viewportMetrics.physicalWidth` 和 `viewportMetrics.physicalHeight` 作为预渲染的宽高，否则默认按全屏预渲染。
- **`nextViewId`**：标识想要预渲染的 FlutterView 的 ID。可以传 `null`，此时会通过调用 `FlutterManager.getInstance().getNextFlutterViewId()` 自动获取下一个 ID。
  - **注意**：当希望同时预渲染多个页面时，需要传入不同的 `nextViewId`。可通过 `getNextFlutterViewId(offset)` 传入偏移量获取接下来的第 `offset+1` 个 `viewId`。

---

### 2. `predrawEngine`

`predrawEngine` 的接口与 `preloadEngine` 类似，不同之处是其第一个参数直接传递一个 `FlutterEngine` 实例。因此，预创建的引擎可以不用 `FlutterEngineCache` 维护。

其余参数的使用和配置与 `preloadEngine` 一致。

---

## 实现示例

### 示例 1：简单情况

以下为典型实现逻辑，通过按钮预加载 Flutter 页面：

```arkts
build() {
  Button(this.title)
    .onClick(() => {
      try {
        router.pushUrl({ url: 'pages/Flutter', params: { route: this.route } });
      } catch (err) {
        Log.d(TAG, `跳转页面${this.route} error === ${JSON.stringify(err)}`);
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

完整 Demo 可参考：[Flutter_it_preload](../../../ohos/flutter_it_preload/)

**预加载逻辑位置**：`pages/index.ets`

---

### 示例 2：复杂情况

以下为更复杂的场景，使用缓存的 `FlutterEngine`，且目标页面包含多个 Flutter 页面，并需要设置尺寸以及 `FlutterViewId` 偏移量。

此场景分为两步：**第一步在页面初始化时创建引擎并注册插件**，**第二步在触摸事件时预渲染引擎**。

#### 步骤一：创建引擎、注册插件并放入缓存

在 `MainPage` 的页面生命周期函数（如 `aboutToAppear`）中，手动创建 `FlutterEngine` 并将其放入 `FlutterEngineCache` 缓存管理。

> **重要**：手动创建引擎后，必须调用 `GeneratedPluginRegistrant.registerWith(engine)` 注册插件。否则 Flutter 插件（如 path_provider、shared_preferences 等）的原生端实现不会绑定到引擎，Dart 代码中调用插件时会报错。在标准的 `FlutterAbility` 流程中，插件注册会自动完成；但手动创建引擎时需要开发者自行注册。

```arkts
import { FlutterEngineCache, engines, GeneratedPluginRegistrant } from '@ohos/flutter_ohos';

aboutToAppear() {
  // 创建引擎选项
  let options: FlutterAbilityLaunchConfigs = new FlutterAbilityLaunchConfigs();
  options.dart_entrypoint = 'main';
  options.route = '/';

  // 创建并运行引擎
  let engine = await engines.createAndRunEngineByOptions(options) ?? undefined;

  // 必须注册插件，否则 Flutter 插件调用会报错
  GeneratedPluginRegistrant.registerWith(engine);

  // 将引擎放入缓存，以便 predrawEngine 复用
  FlutterEngineCache.getInstance().put('DoubleFlutterTop', engine);

  // 如需多个引擎，重复上述步骤创建并缓存
  let options2: FlutterAbilityLaunchConfigs = new FlutterAbilityLaunchConfigs();
  options2.dart_entrypoint = 'main';
  options2.route = '/second';
  let engine2 = await engines.createAndRunEngineByOptions(options2) ?? undefined;
  GeneratedPluginRegistrant.registerWith(engine2);
  FlutterEngineCache.getInstance().put('DoubleFlutterBottom', engine2);
}
```

#### 步骤二：在触摸事件中预渲染引擎

在按钮的 `onTouch` 事件中调用 `predrawEngine`，从缓存中取出引擎进行预渲染：

```arkts
.onTouch((touch: TouchEvent) => {
  if (touch.type == TouchType.Down) {
    let params: Record<string, Object> = {};
    let viewports: ViewportMetrics = new ViewportMetrics();
    // 多引擎时，对传入的 view ID 手动添加偏移
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

完整 Demo 可参考：[Multiple_flutters_predraw](../../../ohos/multiple_flutters_predraw/)

**引擎创建与注册位置**：`pages/MainPage.ets` 的 `aboutToAppear` 等生命周期函数
**预渲染逻辑位置**：`pages/MainPage.ets` 的 `onTouch` 事件

---

## 效果验证

在项目中正确加入 `preload` 后，可显著优化页面跳转的渲染速度。优化前后对比，可通过以下方式验证效果：

1. **慢镜头拍摄**：观察跳转过程中 Flutter 页面加载的速度。
2. **抓取应用 Trace**：分析页面加载时间的变化。
3. **devtools**: 混编应用开发调测时，默认打开原生应用，devtools并不会建立连接，当触发preload时(例如touch事件)，即使并未发生真实跳转也会自动建立连接。

---

## 注意事项

1. 当设置 `viewport_metrics` 时，确保传入的宽高与实际渲染区域一致。
2. 如果需要同时预渲染多个页面，请确保 `nextViewId` 不重复。
3. **手动创建引擎后，务必调用 `GeneratedPluginRegistrant.registerWith(engine)` 注册插件**。在标准的 `FlutterAbility` 流程中，插件注册会自动完成；但通过 `engines.createAndRunEngineByOptions` 等方式手动创建引擎时，插件不会自动注册，必须由开发者手动调用。未注册插件将导致 Dart 侧调用插件时报 `MissingPluginException`。此外，若插件实现了 `AbilityAware`，还需调用 `engine.getAbilityControlSurface()?.attachToAbility(host)` 附着到 Ability，否则插件拿不到上下文、channel 绑定异常。完整的 3 类根因排查（生命周期 / 注册调用 / 插件 ohos 层）见 [Flutter 插件调用报 MissingPluginException](../faq/plugin-adaptation-faq.md#section-missing-plugin-exception)。
4. 引擎创建和缓存应在页面初始化阶段（如 `aboutToAppear`）完成，以确保在 `predrawEngine` 调用时引擎已存在于缓存中。
