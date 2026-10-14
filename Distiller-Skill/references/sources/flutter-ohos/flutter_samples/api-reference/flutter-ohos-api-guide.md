# API接口说明

> **目录**
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

### 基本介绍

`FlutterAbility` 继承 ArkUI 的 [UIAbility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-app-ability-uiability-V5)，封装了启动 **Flutter** 的必要操作，如 FlutterEngine 的创建与管理、生命周期事件转发、窗口与 FlutterView 的创建、系统配置变化同步等。应用程序开发人员应扩展此类，使用方法可参考如下代码：

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

`FlutterAbility` 大部分代码由 **Flutter OHOS 适配层** 实现，以提高稳定性。本节主要介绍 `FlutterAbility` 中供应用开发者重写或调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `configureFlutterEngine(flutterEngine)` | 引擎创建并附加到 Ability 后调用，用于注册插件等初始化操作。 |
| `cleanUpFlutterEngine(flutterEngine)` | Ability 与引擎分离时调用，用于清理自定义资源。 |
| `provideFlutterEngine(context)` | 向框架提供自定义 `FlutterEngine`，返回 `null` 时由框架自动创建。 |
| `getCachedEngineId()` | 获取缓存引擎 ID，用于从 `FlutterEngineCache` 复用引擎。 |
| `getCachedEngineGroupId()` | 获取缓存引擎组 ID，用于从 `FlutterEngineGroupCache` 创建引擎。 |
| `shouldDestroyEngineWithHost()` | 决定 Ability 销毁时是否同时销毁关联的 `FlutterEngine`。 |
| `getDartEntrypointFunctionName()` | 获取 Dart 入口函数名称。 |
| `getInitialRoute()` | 获取 Flutter 应用的初始路由。 |
| `getDartEntrypointArgs()` | 获取传递给 Dart 入口函数的命令行参数。 |
| `popSystemNavigator()` | Flutter 侧调用 `SystemNavigator.pop()` 时触发，用于自定义返回行为。 |

### FlutterEngine 创建流程

框架在 `onCreate` 阶段通过 `FlutterAbilityAndEntryDelegate` 初始化 `FlutterEngine`，按以下优先级选择引擎来源：

1. **缓存引擎**：若 `getCachedEngineId()` 返回非空 ID，则从 `FlutterEngineCache` 中获取对应引擎。
2. **自定义引擎**：若 `provideFlutterEngine(context)` 返回非空实例，则使用该引擎。
3. **引擎组**：若 `getCachedEngineGroupId()` 返回非空 ID，则从 `FlutterEngineGroupCache` 获取引擎组，并通过 `createAndRunEngineByOptions` 创建新引擎。
4. **默认创建**：以上均未命中时，框架自动创建新的 `FlutterEngineGroup` 并运行引擎。

引擎创建完成后，框架会调用 `configureFlutterEngine` 进行配置；Ability 销毁时，框架会调用 `cleanUpFlutterEngine`，并根据 `shouldDestroyEngineWithHost()` 的返回值决定是否销毁引擎。

### 方法

#### configureFlutterEngine

```typescript
configureFlutterEngine(flutterEngine: FlutterEngine): void
```

在 `FlutterEngine` 创建并附加到 Ability 之后调用。应用开发者应重写此方法，用于注册插件、配置 Platform Channel 等引擎初始化操作。框架在 `onAttach` 阶段、引擎就绪后触发此回调。

典型用途包括调用 `GeneratedPluginRegistrant.registerWith(flutterEngine)` 注册自动生成的插件。

##### 参数

| 参数名         | 类型           | 说明                    |
| -------------- | -------------- | ----------------------- |
| flutterEngine  | FlutterEngine  | 已创建好的 Flutter 引擎实例。 |

#### cleanUpFlutterEngine

```typescript
cleanUpFlutterEngine(flutterEngine: FlutterEngine): void
```

在 Ability 与 `FlutterEngine` 分离时调用，用于执行引擎清理操作，例如注销插件、释放自定义资源等。框架在 `onDetach` 阶段触发此回调，调用时机早于引擎销毁判断。

##### 参数

| 参数名         | 类型           | 说明                    |
| -------------- | -------------- | ----------------------- |
| flutterEngine  | FlutterEngine  | 即将分离的 Flutter 引擎实例。 |

#### provideFlutterEngine

```typescript
provideFlutterEngine(context: common.Context): FlutterEngine | null
```

向框架提供自定义的 `FlutterEngine` 实例。若返回非 `null`，框架将直接使用该引擎，跳过默认创建流程。默认实现返回 `null`，表示由框架自动管理引擎创建。

适用于应用需要在多个 Ability 或页面间共享同一引擎、或对引擎创建时机有特殊控制的场景。返回的引擎应由调用方负责预先创建和配置。

##### 参数

| 参数名  | 类型                                                         | 说明           |
| ------- | ------------------------------------------------------------ | -------------- |
| context | [common.Context](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-inner-application-context-V5) | 应用上下文。   |

##### 返回值

| 类型                    | 说明                                                         |
| ----------------------- | ------------------------------------------------------------ |
| FlutterEngine \| null   | 自定义引擎实例；返回 `null` 时由框架按默认策略创建引擎。     |

#### getCachedEngineId

```typescript
getCachedEngineId(): string
```

获取启动参数中指定的缓存引擎 ID。框架优先根据此 ID 从 `FlutterEngineCache` 中查找并复用已有引擎，适用于多 Ability 共享同一 Flutter 引擎的场景。

对应 Want 参数键为 `cached_engine_id`（`FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_ID`）。

##### 返回值

| 类型   | 说明                                                         |
| ------ | ------------------------------------------------------------ |
| string | 缓存引擎 ID；未设置时返回空字符串。                          |

#### getCachedEngineGroupId

```typescript
getCachedEngineGroupId(): string | null
```

获取启动参数中指定的缓存引擎组 ID。框架根据此 ID 从 `FlutterEngineGroupCache` 获取 `FlutterEngineGroup`，并通过 `createAndRunEngineByOptions` 创建新引擎。适用于需要在同一引擎组内快速启动多个 Flutter 实例的场景。

对应 Want 参数键为 `cached_engine_group_id`（`FlutterAbilityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID`）。

##### 返回值

| 类型           | 说明                                                         |
| -------------- | ------------------------------------------------------------ |
| string \| null | 缓存引擎组 ID；未设置时返回 `null`。                         |

#### shouldDestroyEngineWithHost

```typescript
shouldDestroyEngineWithHost(): boolean
```

决定 Ability 销毁时是否同时销毁关联的 `FlutterEngine`。

默认逻辑如下：

- 若引擎来自 `FlutterEngineCache`（`getCachedEngineId()` 非空，优先匹配）或由宿主通过 `provideFlutterEngine` 提供，则返回 `false`，不自动销毁，由应用自行管理引擎生命周期。
- 其他情况下返回 `true`，框架在 `onDetach` 时销毁引擎。

应用可重写此方法以自定义引擎销毁策略。

##### 返回值

| 类型    | 说明                                                         |
| ------- | ------------------------------------------------------------ |
| boolean | `true` 表示随 Ability 销毁引擎；`false` 表示保留引擎。      |

#### getDartEntrypointFunctionName

```typescript
getDartEntrypointFunctionName(): string
```

获取 Dart 入口函数名称，即 Flutter 应用启动时执行的 `main` 函数或自定义入口函数名。

默认从启动 Want 参数 `dart_entrypoint` 中读取；未设置时返回 `"main"`（`FlutterAbilityLaunchConfigs.DEFAULT_DART_ENTRYPOINT`）。

##### 返回值

| 类型   | 说明                 |
| ------ | -------------------- |
| string | Dart 入口函数名称。  |

#### getInitialRoute

```typescript
getInitialRoute(): string
```

获取 Flutter 应用的初始路由。框架在 Dart 代码执行前通过 NavigationChannel 将初始路由发送给 Flutter 层，确保首屏路由及时生效。

默认从启动 Want 参数 `route` 中读取；未设置时返回空字符串，框架内部将使用默认路由 `"/"`。

##### 返回值

| 类型   | 说明                     |
| ------ | ------------------------ |
| string | Flutter 初始路由字符串。 |

#### getDartEntrypointArgs

```typescript
getDartEntrypointArgs(): Array<string>
```

获取传递给 Dart 入口函数的命令行参数列表。

默认从启动 Want 参数 `dart_entrypoint_args` 中读取；未设置时返回空数组。

##### 返回值

| 类型           | 说明                           |
| -------------- | ------------------------------ |
| Array\<string> | 传递给 Dart 入口函数的参数列表。 |

#### popSystemNavigator

```typescript
popSystemNavigator(): boolean
```

当 Flutter 侧调用 `SystemNavigator.pop()` 请求退出应用时，由 `PlatformPlugin` 回调此方法。应用可重写此方法以自定义返回行为，例如拦截退出、执行二次确认或切换原生页面。

- 若返回 `true`，表示应用已自行处理返回逻辑，框架不再执行默认的 `router.back()`。
- 若返回 `false`（默认），框架将调用 `router.back()` 执行系统返回。

##### 返回值

| 类型    | 说明                                                         |
| ------- | ------------------------------------------------------------ |
| boolean | `true` 表示已处理返回事件；`false` 表示使用框架默认返回行为。 |

### 启动参数说明

通过 Want 参数可配置 Flutter 启动行为，常用参数如下：

| 参数键                    | 类型           | 说明                                                         |
| ------------------------- | -------------- | ------------------------------------------------------------ |
| dart_entrypoint           | string         | Dart 入口函数名，默认 `"main"`。                             |
| route                     | string         | Flutter 初始路由。                                           |
| dart_entrypoint_args      | Array\<string> | 传递给 Dart 入口函数的参数。                                 |
| cached_engine_id          | string         | 缓存引擎 ID，用于复用 `FlutterEngineCache` 中的引擎。        |
| cached_engine_group_id    | string         | 缓存引擎组 ID，用于从 `FlutterEngineGroupCache` 创建引擎。   |
| destroy_engine_with_activity | boolean     | 是否在 Activity/Ability 销毁时销毁引擎。                     |
| enable_state_restoration  | boolean        | 是否启用状态恢复。                                           |

### 具体使用说明

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import common from '@ohos.app.ability.common';

export default class EntryAbility extends FlutterAbility {
  // 注册插件
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  // 自定义返回行为：拦截退出
  popSystemNavigator(): boolean {
    // 返回 true 表示自行处理，不执行默认 router.back()
    return true;
  }

  // 提供自定义引擎（可选）
  provideFlutterEngine(context: common.Context): FlutterEngine | null {
    return null; // 返回 null 使用框架默认创建
  }
}
```

## FlutterEntry

### 基本介绍

`FlutterEntry` 是在 ArkUI 页面中嵌入 **Flutter** 内容的入口类，用于在自定义页面（而非 `FlutterAbility` 独占 Ability）场景下管理 `FlutterView` 与 `FlutterEngine` 的生命周期。与 `FlutterAbility` 类似，`FlutterEntry` 同样实现 `Host` 接口，内部通过 `FlutterAbilityAndEntryDelegate` 完成引擎创建、视图挂载与生命周期转发。

适用于 **Add-to-App** 混合开发场景：在原生 ArkUI 页面中嵌入 Flutter 模块，或与 `FlutterAbility` 共享缓存引擎。

```typescript
import { FlutterEntry, FlutterEngine, FlutterEngineConfigurator } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

const engineConfigurator: FlutterEngineConfigurator = {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  },
  cleanUpFlutterEngine(flutterEngine: FlutterEngine): void {
    // 清理自定义资源
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

`FlutterEntry` 大部分代码由 **Flutter OHOS 适配层** 实现。本节主要介绍 `FlutterEntry` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `aboutToAppear()` | 页面即将显示时调用，初始化 Delegate、创建 FlutterView 并附加引擎。 |
| `aboutToDisappear()` | 页面即将销毁时调用，清理资源并从引擎分离。 |
| `onPageShow()` | 通知 Flutter 应用进入前台（`appIsResumed`）。 |
| `onPageHide()` | 通知 Flutter 应用进入后台（`appIsPaused`）。 |
| `onBackPress()` | 触发 Flutter 导航栈 `popRoute`。 |
| `configureFlutterEngine(flutterEngine)` | 引擎就绪后调用，委托给 `FlutterEngineConfigurator` 执行配置。 |
| `setFlutterEngineConfigurator(configurator)` | 设置引擎配置器，用于注册插件等初始化操作。 |
| `getFlutterView()` | 获取当前 `FlutterEntry` 关联的 `FlutterView` 实例。 |

### 方法

#### getFlutterView

```typescript
getFlutterView(): FlutterView | null
```

获取与当前 `FlutterEntry` 关联的 `FlutterView` 实例。用于在页面中通过 `FlutterPage({ viewId: flutterEntry.getFlutterView()?.getId() ?? '' })` 渲染 Flutter 内容。

`FlutterView` 在 `aboutToAppear` 中创建，在 `aboutToDisappear` 中销毁。在此生命周期之外的调用将返回 `null`。

##### 返回值

| 类型                  | 说明                                               |
| --------------------- | -------------------------------------------------- |
| FlutterView \| null   | 当前关联的 FlutterView 实例；未初始化时返回 `null`。 |

#### aboutToAppear

```typescript
aboutToAppear(): void
```

在 ArkUI 页面的 `aboutToAppear` 生命周期中调用。框架将依次完成以下操作：

1. 创建 `FlutterAbilityAndEntryDelegate` 实例；
2. 创建 `FlutterView` 并触发 `onWindowCreated`；
3. 调用 `onAttach` 初始化 `FlutterEngine`；
4. 设置 `PlatformPlugin` 的 UIAbility 上下文；
5. 调用 `onWindowStageCreate` 执行 Dart 入口并设置初始路由；
6. 注册 `windowStageEvent` 监听及环境变化回调。

若 `aboutToAppear` 晚于 `onPageShow` 执行，框架会在初始化完成后补发一次 `onShow`，避免生命周期事件丢失。

#### aboutToDisappear

```typescript
aboutToDisappear(): void
```

在 ArkUI 页面的 `aboutToDisappear` 生命周期中调用。框架将依次完成以下操作：

1. 注销环境变化回调；
2. 移除 `windowStageEvent` 监听；
3. 销毁 `FlutterView`；
4. 调用 `onDetach` 分离引擎，并根据 `shouldDestroyEngineWithHost()` 决定是否销毁引擎；
5. 释放 Delegate 持有的资源。

#### configureFlutterEngine

```typescript
configureFlutterEngine(flutterEngine: FlutterEngine): void
```

在 `FlutterEngine` 创建并附加后由框架调用。若已通过 `setFlutterEngineConfigurator` 设置了配置器，则委托给配置器的 `configureFlutterEngine` 方法执行。应用开发者通常通过实现 `FlutterEngineConfigurator` 接口来完成插件注册，而非直接重写此方法。

##### 参数

| 参数名        | 类型          | 说明                    |
| ------------- | ------------- | ----------------------- |
| flutterEngine | FlutterEngine | 已创建好的 Flutter 引擎实例。 |

#### setFlutterEngineConfigurator

```typescript
setFlutterEngineConfigurator(configurator: FlutterEngineConfigurator): void
```

设置 `FlutterEngine` 配置器。应在调用 `aboutToAppear()` **之前**调用，以便引擎初始化完成后立即执行配置逻辑。

`FlutterEngineConfigurator` 接口定义如下：

```typescript
interface FlutterEngineConfigurator {
  configureFlutterEngine: (flutterEngine: FlutterEngine) => void;
  cleanUpFlutterEngine: (flutterEngine: FlutterEngine) => void;
}
```

##### 参数

| 参数名       | 类型                      | 说明                                       |
| ------------ | ------------------------- | ------------------------------------------ |
| configurator | FlutterEngineConfigurator | 引擎配置器，负责引擎初始化与清理回调。     |

#### onPageShow

```typescript
onPageShow(): void
```

在 ArkUI 页面的 `onPageShow` 生命周期中调用。向 Flutter 侧发送 `appIsResumed` 生命周期事件，通知应用进入前台活跃状态。

#### onPageHide

```typescript
onPageHide(): void
```

在 ArkUI 页面的 `onPageHide` 生命周期中调用。向 Flutter 侧发送 `appIsPaused` 生命周期事件，通知应用进入后台暂停状态。

#### onBackPress

```typescript
onBackPress(): void
```

在 ArkUI 页面的 `onBackPress` 生命周期中调用。触发 Flutter 导航栈的 `popRoute`，用于处理系统返回键事件。

### 构造参数说明

`FlutterEntry` 构造函数接收 `context` 与可选的 `params` 参数，常用配置键与 `FlutterAbility` 启动参数一致：

| 参数键                 | 类型           | 说明                                                         |
| ---------------------- | -------------- | ------------------------------------------------------------ |
| dart_entrypoint        | string         | Dart 入口函数名，默认 `"main"`。                             |
| route                  | string         | Flutter 初始路由。                                           |
| dart_entrypoint_args   | Array\<string> | 传递给 Dart 入口函数的参数。                                 |
| cached_engine_id       | string         | 缓存引擎 ID，用于复用 `FlutterEngineCache` 中的引擎。        |
| cached_engine_group_id | string         | 缓存引擎组 ID，用于从 `FlutterEngineGroupCache` 创建引擎。   |
| should_attach_engine_to_ability | boolean | 是否将引擎附加到 UIAbility，默认 `true`。              |

### 页面生命周期配合

除 `aboutToAppear` / `aboutToDisappear` 外，建议在页面中同步转发以下生命周期方法：

| 页面生命周期 | FlutterEntry 方法 | 说明 |
| --- | --- | --- |
| `onPageShow` | `onPageShow()` | 通知 Flutter 应用进入前台（`appIsResumed`）。 |
| `onPageHide` | `onPageHide()` | 通知 Flutter 应用进入后台（`appIsPaused`）。 |
| `onBackPress` | `onBackPress()` | 触发 Flutter 导航栈 `popRoute`。 |

## FlutterEngine

### 基本介绍

`FlutterEngine` 是单个 **Flutter** 执行环境的容器，负责运行 Dart 代码、管理 Platform Channel 通信、维护插件注册表以及驱动渲染。在 OpenHarmony 应用中，可通过 `FlutterAbility` 或 `FlutterEntry` 自动创建引擎，也可通过 `FlutterEngineGroup` 手动创建以在多个页面间共享 VM 资源。

一个应用可存在多个 `FlutterEngine` 实例，各自拥有独立的 Dart Isolate。为获得更好的内存性能，建议通过 `FlutterEngineGroup` 而非直接构造多个 `FlutterEngine`。

```typescript
import { FlutterEngine } from '@ohos/flutter_ohos';

// 通过 FlutterAbility 或 FlutterEntry 获取引擎
// const flutterEngine: FlutterEngine | null = entryAbility.getFlutterEngine();

let flutterEngine: FlutterEngine | null = null; // 实际使用时由 FlutterAbility/FlutterEntry 提供

// 注册插件
flutterEngine?.getPlugins()?.add(new MyPlugin());

// 获取 Dart 执行器
const dartExecutor = flutterEngine?.getDartExecutor();

// 销毁引擎（通常由框架自动管理）
flutterEngine?.destroy();
```

本节主要介绍 `FlutterEngine` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `getDartExecutor()` | 获取 Dart 代码执行器，用于执行 Dart 入口或注册 MethodChannel。 |
| `getFlutterRenderer()` | 获取渲染器，用于将 Flutter 内容渲染到 `FlutterView`。 |
| `getPlugins()` | 获取插件注册表，用于添加、移除和查询 Flutter 插件。 |
| `getLifecycleChannel()` | 获取生命周期 Channel，用于向 Flutter 侧发送应用生命周期事件。 |
| `getNavigationChannel()` | 获取导航 Channel，用于管理 Flutter 路由（初始路由、pop 等）。 |
| `getPlatformChannel()` | 获取平台 Channel，用于系统 UI、剪贴板等平台级交互。 |
| `getTextInputChannel()` | 获取文本输入 Channel，用于软键盘与文本输入管理。 |
| `destroy()` | 销毁引擎并释放所有关联资源。 |

### 方法

#### getDartExecutor

```typescript
getDartExecutor(): DartExecutor
```

获取 `DartExecutor` 实例，用于配置、启动和执行 Dart 代码。`DartExecutor` 同时实现了 `BinaryMessenger` 接口，可用于注册 MethodChannel 和 EventChannel。

典型用途：

- 通过 `executeDartEntrypoint(DartEntrypoint)` 启动 Dart 入口（框架内部自动调用，应用一般无需手动执行）；
- 注册自定义 Platform Channel 的消息处理器。

##### 返回值

| 类型         | 说明                              |
| ------------ | --------------------------------- |
| DartExecutor | Dart 代码执行器，不会为 `null`。  |

#### getFlutterRenderer

```typescript
getFlutterRenderer(): FlutterRenderer
```

获取 `FlutterRenderer` 实例，负责将 Flutter 渲染管线输出到 `RenderSurface`（通常为 `FlutterView` 中的 XComponent）。`FlutterView.attachToFlutterEngine` 内部即通过此渲染器完成绑定。

##### 返回值

| 类型            | 说明                         |
| --------------- | ---------------------------- |
| FlutterRenderer | Flutter 渲染器，不会为 `null`。 |

#### getPlugins

```typescript
getPlugins(): PluginRegistry | null
```

获取插件注册表 `PluginRegistry`，用于管理附加到当前引擎的 `FlutterPlugin` 实例。

##### 返回值

| 类型           | 说明                                                         |
| -------------- | ------------------------------------------------------------ |
| PluginRegistry \| null | 插件注册表；引擎未完全初始化时可能为 `null`。          |

##### PluginRegistry 常用方法

| 方法 | 说明 |
| --- | --- |
| `add(plugin)` | 向引擎附加插件。 |
| `addList(plugins)` | 批量附加插件。 |
| `has(pluginClassName)` | 检查指定插件是否已附加。 |
| `get(pluginClassName)` | 获取指定类型的插件实例。 |
| `remove(pluginClassName)` | 从引擎分离并移除插件。 |

#### getLifecycleChannel

```typescript
getLifecycleChannel(): LifecycleChannel | null
```

获取生命周期 Channel，用于向 Flutter 侧发送应用生命周期状态变化，例如：

- `appIsResumed()` — 应用进入前台；
- `appIsPaused()` — 应用进入后台；
- `appIsInactive()` — 应用处于非活跃状态；
- `appIsDetached()` — 应用与引擎分离。

框架在 `FlutterAbility` / `FlutterEntry` 的生命周期回调中自动调用上述方法，应用开发者一般无需手动发送。

##### 返回值

| 类型              | 说明                                       |
| ----------------- | ------------------------------------------ |
| LifecycleChannel \| null | 生命周期 Channel；引擎未初始化时为 `null`。 |

#### getNavigationChannel

```typescript
getNavigationChannel(): NavigationChannel | null
```

获取导航 Channel，用于管理 Flutter 侧的路由行为。框架在引擎启动时通过 `setInitialRoute` 设置初始路由；页面返回时通过 `popRoute` 弹出当前路由。

##### 返回值

| 类型               | 说明                                     |
| ------------------ | ---------------------------------------- |
| NavigationChannel \| null | 导航 Channel；引擎未初始化时为 `null`。 |

#### getPlatformChannel

```typescript
getPlatformChannel(): PlatformChannel | null
```

获取平台 Channel，承载 Flutter 与 OpenHarmony 平台之间的系统级交互，包括：

- 系统导航栏样式（`SystemChrome`）；
- 剪贴板读写；
- 触觉反馈；
- 屏幕方向设置；
- `SystemNavigator.pop()` 退出应用等。

`PlatformPlugin` 作为此 Channel 的 ArkTS 侧处理器，在引擎初始化时自动创建。

##### 返回值

| 类型              | 说明                                     |
| ----------------- | ---------------------------------------- |
| PlatformChannel \| null | 平台 Channel；引擎未初始化时为 `null`。 |

#### getTextInputChannel

```typescript
getTextInputChannel(): TextInputChannel | null
```

获取文本输入 Channel，用于管理软键盘显示/隐藏、文本编辑状态同步等输入相关行为。`TextInputPlugin` 作为此 Channel 的 ArkTS 侧处理器，在引擎初始化时自动创建。

##### 返回值

| 类型               | 说明                                       |
| ------------------ | ------------------------------------------ |
| TextInputChannel \| null | 文本输入 Channel；引擎未初始化时为 `null`。 |

#### destroy

```typescript
destroy(): void
```

销毁 `FlutterEngine` 并释放所有关联资源，包括：

1. 通知所有 `EngineLifecycleListener` 引擎即将销毁；
2. 从 UIAbility 分离插件；
3. 销毁 `PlatformViewsController` 与插件注册表；
4. 分离 `DartExecutor` 与 NAPI 原生引用。

**注意**：若引擎来自 `FlutterEngineCache` 或由应用通过 `provideFlutterEngine` 提供，`shouldDestroyEngineWithHost()` 返回 `false` 时框架不会自动调用 `destroy()`，需由应用自行管理引擎生命周期。

##### 使用建议

- 通过 `FlutterAbility` / `FlutterEntry` 创建的引擎，通常无需手动调用 `destroy()`，框架会在 `onDetach` 阶段根据策略自动处理；
- 手动创建并缓存的引擎，应在确认不再使用时主动调用 `destroy()`，并从 `FlutterEngineCache` 中移除。

### 引擎获取方式

| 方式 | 说明 |
| --- | --- |
| `FlutterAbility.getFlutterEngine()` | 从 Ability 获取当前关联的引擎实例。 |
| `FlutterEntry.getFlutterEngine()` | 从页面 Entry 获取当前关联的引擎实例。 |
| `FlutterEngineCache.getInstance().get(id)` | 从全局缓存中获取指定 ID 的引擎。 |
| `FlutterEngineGroup.createAndRunEngineByOptions(options)` | 通过引擎组创建并运行新引擎。 |

## FlutterEngineGroup

### 基本介绍

`FlutterEngineGroup` 表示一组共享底层资源的 `FlutterEngine` 集合。在同一组内创建或重建引擎时，后续引擎会复用已有存活引擎的 Dart VM 与 NAPI 资源，从而以更低的内存开销和更快的启动速度创建多个 Flutter 实例。

共享资源会保留至组内最后一个存活的 `FlutterEngine` 被销毁。删除 `FlutterEngineGroup` 不会使组内已有引擎失效，但无法再在该组中创建新引擎。

`FlutterAbility` 和 `FlutterEntry` 可通过 `getCachedEngineGroupId()` 从 `FlutterEngineGroupCache` 获取预热的引擎组，并由 `FlutterAbilityAndEntryDelegate` 调用 `createAndRunEngineByOptions` 创建新引擎。

```typescript
import {
  FlutterEngineGroup,
  FlutterEngineGroupCache,
  Options,
} from '@ohos/flutter_ohos';
import { DartEntrypoint } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/dart/DartExecutor';
import common from '@ohos.app.ability.common';

// context 需从页面或 Ability 中获取
// const context: common.Context = ...

// 创建引擎组并预热第一个引擎
const engineGroup = new FlutterEngineGroup();
const engine = engineGroup.createAndRunEngineByOptions(
  new Options(context)
    .setDartEntrypoint(DartEntrypoint.createDefault())
    .setInitialRoute('/')
);

// 缓存引擎组，供 FlutterAbility / FlutterEntry 复用
FlutterEngineGroupCache.instance.put('my_engine_group', engineGroup);

// 在同一组内快速创建第二个引擎（spawn 复用资源）
const secondEngine = engineGroup.createAndRunEngineByOptions(
  new Options(context)
    .setInitialRoute('/second')
);
```

本节主要介绍 `FlutterEngineGroup` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `createAndRunEngineByOptions(options)` | 根据配置选项创建并运行 `FlutterEngine`；组内首个引擎新建，后续引擎从首个引擎 spawn。 |
| `getDefaultEngine()` | 获取组内默认（第一个）引擎实例。 |

### 引擎创建流程

`createAndRunEngineByOptions` 内部按以下逻辑创建引擎：

1. **组内无引擎**：调用 `createEngine` 创建全新 `FlutterEngine`，执行 `init`、设置初始路由、运行 Dart 入口，并调用 `prefetchFramesCfg` 预取帧配置。
2. **组内已有引擎**：从 `activeEngines[0]` 调用 `spawn` 复用资源创建新引擎。
3. 将新引擎加入 `activeEngines` 列表，并注册 `EngineLifecycleListener`，在引擎销毁时自动从列表中移除。

### 方法

#### createAndRunEngineByOptions

```typescript
createAndRunEngineByOptions(options: Options): FlutterEngine
```

根据 `Options` 配置创建并运行 `FlutterEngine`。若 `dartEntrypoint` 未设置，默认使用 `DartEntrypoint.createDefault()`；若 `platformViewsController` 未设置，自动创建新实例。

##### 参数

| 参数名  | 类型    | 说明                                       |
| ------- | ------- | ------------------------------------------ |
| options | Options | 引擎创建配置，包含上下文、入口点、路由等。 |

##### 返回值

| 类型          | 说明                         |
| ------------- | ---------------------------- |
| FlutterEngine | 创建或 spawn 的引擎实例。    |

#### getDefaultEngine

```typescript
getDefaultEngine(): FlutterEngine | null
```

获取组内第一个（默认）`FlutterEngine` 实例。`FlutterEnginePreload.preLoadFlutterNapi` 在通过 `cached_engine_group_id` 预加载时，会调用此方法获取默认引擎的 NAPI 引用以执行 `preSpawn`。

##### 返回值

| 类型                  | 说明                                     |
| --------------------- | ---------------------------------------- |
| FlutterEngine \| null | 组内首个引擎；组内无引擎时返回 `null`。  |

### Options 配置参数

`Options` 类用于配置 `createAndRunEngineByOptions` 的行为，支持链式调用：

| 方法 | 类型 | 说明 |
| --- | --- | --- |
| `setDartEntrypoint(dartEntrypoint)` | DartEntrypoint | Dart 入口点配置（bundle 路径、库 URI、函数名）。 |
| `setInitialRoute(initialRoute)` | string | Flutter 初始路由，默认空字符串。 |
| `setDartEntrypointArgs(args)` | Array\<string> | 传递给 Dart 入口函数的参数。 |
| `setWaitForRestorationData(wait)` | boolean | 是否等待状态恢复数据，默认 `false`。 |
| `setPlatformViewsController(controller)` | PlatformViewsController | 平台视图控制器，未设置时自动创建。 |

### 具体使用说明

```typescript
import {
  FlutterEngineGroup,
  FlutterEngineGroupCache,
  FlutterEnginePreload,
  FlutterInjector,
  Options,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从 AbilityStage 或页面中获取
// const context: common.Context = ...

// 1. 应用启动时预热引擎组
const engineGroup = new FlutterEngineGroup();
engineGroup.checkLoader(context, []); // 确保 FlutterLoader 已初始化

const warmupEngine = engineGroup.createAndRunEngineByOptions(
  new Options(context).setInitialRoute('/')
);

// 2. 缓存引擎组 ID
FlutterEngineGroupCache.instance.put('main_group', engineGroup);

// 3. FlutterAbility 中通过 getCachedEngineGroupId() 返回 'main_group' 即可复用
```

## FlutterEngineCache

### 基本介绍

`FlutterEngineCache` 是 **Flutter 引擎实例的全局缓存**，以键值对形式持有已创建的 `FlutterEngine`，供多个 `FlutterAbility` / `FlutterEntry` 在不同入口复用同一引擎，避免重复创建 Dart VM 与渲染资源带来的内存与启动开销。

缓存为进程内单例，通过 `FlutterEngineCache.getInstance()` 获取。`FlutterAbility` / `FlutterEntry` 在引擎创建阶段会优先根据 `getCachedEngineId()` 返回的 ID 从本缓存查找引擎；命中则直接复用，未命中时按默认流程创建。

```typescript
import { FlutterEngineCache, FlutterEngine } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从页面或 Ability 中获取
// const context: common.Context = ...

// 1. 预创建并缓存引擎
const engine: FlutterEngine = ...; // 实际多通过 FlutterEngineGroup 创建
FlutterEngineCache.getInstance().put('main_engine', engine);

// 2. 在 FlutterAbility 中重写 getCachedEngineId() 返回 'main_engine' 即可复用
```

本节主要介绍 `FlutterEngineCache` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `getInstance()` | 获取 `FlutterEngineCache` 全局单例。 |
| `put(id, engine)` | 将 `FlutterEngine` 以指定 ID 存入缓存。 |
| `get(id)` | 根据 ID 获取已缓存的引擎。 |
| `contains(id)` | 判断指定 ID 的引擎是否已存在于缓存中。 |
| `remove(id)` | 从缓存中移除指定 ID 的引擎（不销毁引擎本身）。 |
| `clear()` | 清空缓存中所有引擎引用（不销毁引擎）。 |

### 方法

#### getInstance

```typescript
static getInstance(): FlutterEngineCache
```

获取 `FlutterEngineCache` 全局单例实例，整个应用共享同一缓存。

##### 返回值

| 类型 | 说明 |
| --- | --- |
| FlutterEngineCache | 全局单例缓存实例。 |

#### put

```typescript
put(id: string, engine: FlutterEngine): void
```

将 `FlutterEngine` 以指定 `id` 存入缓存。若该 ID 已存在，将覆盖旧引用。存入缓存的引擎不会随某个 Ability 销毁而自动销毁，需由应用自行管理其生命周期。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| id | string | 缓存引擎的唯一标识，需与 `getCachedEngineId()` 返回值一致。 |
| engine | FlutterEngine | 待缓存的引擎实例。 |

#### get

```typescript
get(id: string): FlutterEngine | null
```

根据 `id` 获取已缓存的 `FlutterEngine` 实例。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| id | string | 缓存引擎的唯一标识。 |

##### 返回值

| 类型 | 说明 |
| --- | --- |
| FlutterEngine \| null | 命中的引擎实例；未命中时返回 `null`。 |

#### contains

```typescript
contains(id: string): boolean
```

判断指定 `id` 的引擎是否已存在于缓存中。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| id | string | 缓存引擎的唯一标识。 |

##### 返回值

| 类型 | 说明 |
| --- | --- |
| boolean | `true` 表示已缓存；`false` 表示未缓存。 |

#### remove

```typescript
remove(id: string): void
```

从缓存中移除指定 `id` 的引擎引用。此方法仅解除缓存关联，**不会调用 `engine.destroy()`**；引擎的实际销毁应由调用方在确认不再使用后执行。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| id | string | 要移除的缓存引擎 ID。 |

#### clear

```typescript
clear(): void
```

清空缓存中所有引擎引用。与 `remove` 一致，本方法不销毁引擎实例，仅解除关联。

### 与缓存引擎销毁策略的关系

通过 `getCachedEngineId()` 命中的引擎，`FlutterAbility` / `FlutterEntry` 的 `shouldDestroyEngineWithHost()` 默认返回 `false`，即宿主销毁时**不会自动销毁**该引擎。应用需在确认引擎不再被任何宿主使用时，显式调用 `engine.destroy()` 并通过 `remove(id)` 清理缓存引用，避免内存泄漏。

### 具体使用说明

```typescript
import {
  FlutterEngineCache,
  FlutterEngineGroup,
  Options,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从 AbilityStage 或页面中获取
// const context: common.Context = ...

// 1. 应用启动时预热引擎并缓存
const group = new FlutterEngineGroup();
const engine = group.createAndRunEngineByOptions(new Options(context).setInitialRoute('/'));
FlutterEngineCache.getInstance().put('main_engine', engine);

// 2. FlutterAbility 中复用：
//    override getCachedEngineId(): string { return 'main_engine'; }

// 3. 确认不再使用时销毁并清理
// FlutterEngineCache.getInstance().remove('main_engine');
// engine.destroy();
```

## FlutterEnginePreload

### 基本介绍

`FlutterEnginePreload` 是用于 **预加载 Flutter 引擎** 的工具类，提供静态方法在页面实际展示之前完成 Dart VM 初始化、Bundle 加载和首帧预绘制，从而缩短用户感知的启动时间。

典型使用场景：

- 在 `AbilityStage.onCreate` 或应用启动阶段提前加载 Flutter 资源；
- 在跳转 Flutter 页面前执行预绘制，减少白屏时间；
- 配合 `FlutterEngineCache` / `FlutterEngineGroupCache` 实现引擎预热。

```typescript
import { FlutterEnginePreload } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从页面或 Ability 中获取
// const context: common.Context = ...

// 应用启动时预加载
await FlutterEnginePreload.preloadEngine(context, {
  dart_entrypoint: 'main',
  route: '/',
});

// 对已创建的引擎执行预绘制（engine 由 FlutterAbility/FlutterEntry 提供）
// FlutterEnginePreload.predrawEngine(flutterEngine);
```

本节主要介绍 `FlutterEnginePreload` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `preloadEngine(context, params?)` | 完整预加载流程：初始化 Loader、加载 NAPI/Bundle、设置视口并执行预绘制。 |
| `predrawEngine(engine, params?)` | 对已存在的 `FlutterEngine` 设置视口指标并执行 XComponent 预绘制。 |
| `preLoadFlutterNapi(context, bundlePath)` | 底层 NAPI 预加载：加载 Bundle、设置初始路由，支持缓存引擎/引擎组复用。 |

### 方法

#### preloadEngine

```typescript
static async preloadEngine(
  context: common.Context,
  params: Record<string, Object> = {},
  nextViewId: string | null = null
): Promise<void>
```

执行完整的引擎预加载流程：

1. 初始化 `FlutterLoader`（若尚未初始化）；
2. 调用 `preLoadFlutterNapi` 加载 NAPI 并执行 Dart Bundle；
3. 获取或构造 `ViewportMetrics`（默认使用当前屏幕尺寸）；
4. 设置预加载标志，执行 `xComponentPreDraw` 和 `setViewportMetrics`。

##### 参数

| 参数名     | 类型                      | 必填 | 说明                                                         |
| ---------- | ------------------------- | ---- | ------------------------------------------------------------ |
| context    | common.Context            | 是   | 应用上下文。                                                 |
| params     | Record\<string, Object>   | 否   | 预加载配置参数，键名与 `FlutterAbilityLaunchConfigs` 常量一致。 |
| nextViewId | string \| null            | 否   | 预绘制使用的 XComponent ID；未设置时自动生成。                 |

#### predrawEngine

```typescript
static predrawEngine(
  engine: FlutterEngine,
  params: Record<string, Object> = {},
  nextViewId: string | null = null
): void
```

对已创建的 `FlutterEngine` 执行预绘制准备。适用于引擎已通过 `FlutterEngineGroup` 或 `FlutterEngineCache` 创建、仅需提前渲染首帧的场景。

执行流程：

1. 确保引擎的 `FlutterNapi` 已附加到原生层；
2. 获取或构造 `ViewportMetrics`；
3. 设置预加载标志，执行 `xComponentPreDraw` 和 `setViewportMetrics`。

##### 参数

| 参数名     | 类型                    | 必填 | 说明                                                         |
| ---------- | ----------------------- | ---- | ------------------------------------------------------------ |
| engine     | FlutterEngine           | 是   | 已创建的 Flutter 引擎实例。                                  |
| params     | Record\<string, Object> | 否   | 预绘制配置参数。                                             |
| nextViewId | string \| null          | 否   | 预绘制使用的 XComponent ID；未设置时自动生成。               |

#### preLoadFlutterNapi

```typescript
static preLoadFlutterNapi(
  context: common.Context,
  bundlePath: string,
  params: Record<string, Object> = {}
): FlutterNapi | null
```

底层 NAPI 预加载方法，负责在原生层加载 Flutter Bundle 并运行 Dart 代码。`preloadEngine` 内部调用此方法完成核心加载逻辑。

引擎来源按以下优先级选择：

1. **缓存引擎**：若 `params` 中指定 `cached_engine_id`，从 `FlutterEngineCache` 获取已有引擎的 NAPI。
2. **缓存引擎组**：若指定 `cached_engine_group_id`，从 `FlutterEngineGroupCache` 获取引擎组，通过默认引擎的 `preSpawn` 创建新 NAPI。
3. **默认预加载**：以上均未命中时，使用 `FlutterInjector.getPreloadFlutterNapi()` 获取专用预加载 NAPI 实例，执行 `runBundleAndSnapshotFromLibrary`。

##### 参数

| 参数名     | 类型                    | 必填 | 说明                                   |
| ---------- | ----------------------- | ---- | -------------------------------------- |
| context    | common.Context          | 是   | 应用上下文。                           |
| bundlePath | string                  | 是   | Flutter Bundle 路径。                  |
| params     | Record\<string, Object> | 否   | 预加载配置参数。                       |

##### 返回值

| 类型              | 说明                                       |
| ----------------- | ------------------------------------------ |
| FlutterNapi \| null | 预加载完成的 NAPI 实例；失败时返回 `null`。 |

### 预加载参数说明

`params` 参数支持以下配置键：

| 参数键                      | 类型           | 说明                                                         |
| --------------------------- | -------------- | ------------------------------------------------------------ |
| dart_entrypoint             | string         | Dart 入口函数名，默认 `"main"`。                             |
| dart_entrypoint_library_uri | string         | Dart 入口库 URI。                                            |
| route                       | string         | Flutter 初始路由。                                           |
| dart_entrypoint_args        | Array\<string> | 传递给 Dart 入口函数的参数。                                 |
| cached_engine_id            | string         | 缓存引擎 ID，复用 `FlutterEngineCache` 中的引擎 NAPI。       |
| cached_engine_group_id      | string         | 缓存引擎组 ID，通过 `FlutterEngineGroup.getDefaultEngine()` 执行 `preSpawn`。 |
| viewport_metrics            | ViewportMetrics | 自定义视口指标；未设置时使用当前屏幕默认尺寸。              |

### 具体使用说明

```typescript
import {
  FlutterEnginePreload,
  FlutterEngineGroup,
  FlutterEngineGroupCache,
  FlutterInjector,
  Options,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从 AbilityStage 或页面中获取
// const context: common.Context = ...

// 场景一：应用冷启动时完整预加载
async function onAppLaunch(context: common.Context) {
  await FlutterEnginePreload.preloadEngine(context, {
    dart_entrypoint: 'main',
    route: '/home',
  });
}

// 场景二：预热引擎组后预加载
function warmupEngineGroup(context: common.Context) {
  const group = new FlutterEngineGroup();
  group.createAndRunEngineByOptions(new Options(context).setInitialRoute('/'));
  FlutterEngineGroupCache.instance.put('warm_group', group);

  // 基于引擎组预加载（spawn 新 NAPI）
  FlutterEnginePreload.preLoadFlutterNapi(
    context,
    FlutterInjector.getInstance().getFlutterLoader().findAppBundlePath(),
    { cached_engine_group_id: 'warm_group', route: '/detail' }
  );
}

// 场景三：对已创建引擎执行预绘制
function predrawExistingEngine(engine: FlutterEngine) {
  FlutterEnginePreload.predrawEngine(engine);
}
```

## FlutterView

### 基本介绍

`FlutterView` 是 **Flutter** 在 OpenHarmony 上的渲染视图容器，负责管理 XComponent 渲染表面与 `FlutterEngine` 的绑定关系，处理视口尺寸、安全区域、键盘区域、首帧回调等。`FlutterAbility` 和 `FlutterEntry` 在内部创建 `FlutterView`，页面侧通过 `FlutterPage` 组件配合 `viewId` 完成渲染展示。

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import { FlutterView } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从页面或 Ability 中获取，engine 由框架或缓存提供
// const context: common.Context = ...
// const flutterEngine: FlutterEngine = ...

// 通常由 FlutterManager 创建
const flutterView: FlutterView = FlutterManager.getInstance().createFlutterView(context);

// 附加到引擎
flutterView.attachToFlutterEngine(flutterEngine);

// 在 FlutterPage 中使用
FlutterPage({ viewId: flutterView.getId() })
```

本节主要介绍 `FlutterView` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `new FlutterView(viewId, context)` | 构造 Flutter 渲染视图，指定唯一 viewId 与上下文。 |
| `attachToFlutterEngine(flutterEngine)` | 将视图附加到指定 `FlutterEngine`，建立渲染与输入通道。 |
| `detachFromFlutterEngine()` | 从当前引擎分离，清理相关插件与事件监听。 |
| `onSurfaceCreated()` | XComponent 表面创建时调用，返回 surface 生命周期 token。 |
| `onSurfaceDestroyed(token?)` | XComponent 表面销毁时调用，可选 token 防止乱序回调。 |
| `onAreaChange(newArea, setFullScreen?)` | 视图区域变化时更新视口指标与安全区域。 |
| `hasRenderedFirstFrame()` | 判断首帧是否已渲染完成。 |
| `addFirstFrameListener(listener)` | 注册首帧渲染完成监听器。 |
| `getId()` | 获取 FlutterView 的唯一标识符。 |

### 方法

#### getId

```typescript
getId(): string
```

获取 FlutterView 的唯一标识符（viewId）。此 ID 由 `FlutterManager.createFlutterView` 自动生成（格式 `oh_flutter_${index}`），或由构造函数直接传入。在 `FlutterPage({ viewId })` 中需使用此 ID 关联渲染表面。

##### 返回值

| 类型   | 说明                               |
| ------ | ---------------------------------- |
| string | FlutterView 的唯一标识符。         |

#### 构造函数

```typescript
constructor(viewId: string, context: Context)
```

创建 `FlutterView` 实例。构造时会初始化视口指标、注册窗口尺寸/避让区/键盘高度等系统事件监听。

应用侧通常通过 `FlutterManager.createFlutterView(context)` 创建，该方法会自动生成 `oh_flutter_${index}` 格式的 viewId 并注册到管理器。

##### 参数

| 参数名  | 类型    | 说明                                                         |
| ------- | ------- | ------------------------------------------------------------ |
| viewId  | string  | 视图唯一标识，需与 `FlutterPage` 中 XComponent 的 id 一致。建议保持 `oh_flutter_` 前缀。 |
| context | Context | 应用上下文，用于获取 UIAbility 与窗口信息。                  |

#### attachToFlutterEngine

```typescript
attachToFlutterEngine(flutterEngine: FlutterEngine): void
```

将 `FlutterView` 附加到指定 `FlutterEngine`。若已附加到其他引擎，会先调用 `detachFromFlutterEngine` 再附加新引擎。

附加后框架会：

- 将 XComponent 绑定到引擎 NAPI；
- 更新屏幕刷新率、尺寸与密度；
- 初始化 `MouseCursorPlugin`、`TextInputPlugin`、`KeyboardManager` 等；
- 注册返回键事件处理；
- 根据当前区域更新视口指标。

##### 参数

| 参数名        | 类型          | 说明                    |
| ------------- | ------------- | ----------------------- |
| flutterEngine | FlutterEngine | 要附加的 Flutter 引擎。 |

#### detachFromFlutterEngine

```typescript
detachFromFlutterEngine(): void
```

从当前 `FlutterEngine` 分离视图，清理文本输入、鼠标光标、键盘管理等插件资源，并解除 XComponent 与引擎的 NAPI 绑定。若视图未附加到引擎，调用无效果。

#### onSurfaceCreated

```typescript
onSurfaceCreated(): number
```

在 XComponent `onLoad` 回调中调用，标记渲染表面可用并返回 **surface 生命周期 token**。`FlutterPage` 内部在 XComponent 的 `onLoad` 回调中调用此方法，并将 token 保存供 `onSurfaceDestroyed` 使用。

返回的 token 用于防止快速路由切换时，旧的 `onDestroy` 回调错误地销毁新创建的表面（乱序销毁保护）。

##### 返回值

| 类型   | 说明                                   |
| ------ | -------------------------------------- |
| number | 当前 surface 的生命周期 token。        |

#### onSurfaceDestroyed

```typescript
onSurfaceDestroyed(surfaceLifecycleToken?: number): void
```

在 XComponent `onDestroy` 回调中调用，标记渲染表面不可用并解除引擎绑定。

若传入 `surfaceLifecycleToken` 且与当前活跃 token 不匹配，则忽略此次调用（防止过期的销毁回调影响新表面）。建议始终传入 `onSurfaceCreated` 返回的 token。

##### 参数

| 参数名                | 类型   | 必填 | 说明                                                         |
| --------------------- | ------ | ---- | ------------------------------------------------------------ |
| surfaceLifecycleToken | number | 否   | `onSurfaceCreated` 返回的 token；传入可启用乱序回调保护。    |

#### onAreaChange

```typescript
onAreaChange(newArea: Area | null, setFullScreen: boolean = false): void
```

视图区域变化时更新视口指标（`ViewportMetrics`），包括物理宽高、安全区域内边距、键盘区域、手势避让区等。`FlutterPage` 在窗口装饰变化时通过 `FlutterManager.handleWindowDecorSafeArea` 间接触发相关更新。

##### 参数

| 参数名        | 类型        | 必填 | 说明                                                         |
| ------------- | ----------- | ---- | ------------------------------------------------------------ |
| newArea       | Area \| null | 否   | 新的视图区域；为 `null` 时使用当前屏幕尺寸。                 |
| setFullScreen | boolean     | 否   | 是否按全屏模式计算避让区，默认 `false`。                     |

#### hasRenderedFirstFrame

```typescript
hasRenderedFirstFrame(): boolean
```

判断 Flutter 首帧是否已渲染完成。可用于控制启动页（Splash Screen）的隐藏时机，`FlutterPage` 通过 `FirstFrameListener` 在首帧完成后隐藏启动页。

##### 返回值

| 类型    | 说明                               |
| ------- | ---------------------------------- |
| boolean | `true` 表示首帧已渲染；否则为 `false`。 |

#### addFirstFrameListener

```typescript
addFirstFrameListener(listener: FirstFrameListener): void
```

注册首帧渲染完成监听器。首帧渲染后框架调用 `listener.onFirstFrame()`。配对使用 `removeFirstFrameListener` 在页面销毁时移除监听，避免资源泄漏。

##### 参数

| 参数名   | 类型               | 说明                 |
| -------- | ------------------ | -------------------- |
| listener | FirstFrameListener | 首帧渲染完成回调对象。 |

##### FirstFrameListener

```typescript
interface FirstFrameListener {
  onFirstFrame(): void;
}
```

### 具体使用说明

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

### 基本介绍

`FlutterPage` 是 ArkUI 声明式组件，用于在页面 `build()` 中承载 **Flutter** 渲染画面。它与逻辑侧的 `FlutterView` 配对使用：`FlutterView` 负责视口指标、引擎 attach/detach 与系统事件处理，`FlutterPage` 则通过内部 `XComponent({ id: viewId })` 将 Flutter 引擎渲染的 Surface 呈现到 ArkUI 组件树。`FlutterPage` 自身不持有 `FlutterView` 实例，仅通过 `viewId` 与之关联。

开发者无需继承或实例化 `FlutterPage`，直接在 `@Component` 的 `build()` 中声明即可。`viewId` 来源于 `FlutterView.getId()`：独立应用场景下由 `FlutterAbility` 自动注入 `LocalStorage`，Add-to-App 场景下由 `FlutterEntry.getFlutterView()` 取得。

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

本节主要介绍 `FlutterPage` 中供应用开发者使用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `FlutterPage({ viewId })` | 在 `build()` 中声明 Flutter 渲染组件，通过 `viewId` 关联 `FlutterView`。 |
| `viewId` | 必填构造参数，对应 `FlutterView.getId()` 返回的视图唯一标识。 |

### 参数说明

`FlutterPage` 构造参数：

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| viewId | string | 是 | `FlutterView.getId()` 返回的视图 ID；与 `FlutterManager.createFlutterView` 自动生成的 `oh_flutter_${index}` 一致。 |

### 渲染流程

`FlutterPage` 内部基于 `XComponent` 完成渲染表面管理：

1. `XComponent` 的 `onLoad` 回调触发 `FlutterView.onSurfaceCreated()`，返回 surface 生命周期 token；
2. 框架将 XComponent 绑定到引擎 NAPI，建立渲染通道；
3. 首帧渲染完成后触发 `FirstFrameListener`，`FlutterPage` 据此隐藏启动页（Splash）；
4. `XComponent` 的 `onDestroy` 回调触发 `FlutterView.onSurfaceDestroyed(token)`，token 不匹配时忽略以防止乱序销毁。

### 使用注意事项

- `viewId` 为空或未就绪时 `FlutterPage` 区域表现为**黑屏**，须确认 `FlutterAbility` / `FlutterEntry` 已完成初始化并取得 `FlutterView`。
- 独立 Flutter 应用通过 `FlutterAbility` 自动将 `viewId` 注入 `LocalStorage`，首页用 `@LocalStorageLink('viewId')` 接收；Add-to-App 场景须自行通过 `flutterEntry.getFlutterView()?.getId() ?? ''` 取值传入。
- `FlutterPage` 不宜在 `viewId` 未就绪时嵌套复杂原生布局，避免 XComponent 尺寸为 0 导致首帧无法渲染。
- 键盘避让、安全区等配置在配套的 `FlutterView` 上通过 `setCheckKeyboard()`、`setCheckFullScreen()` 等方法完成。

### 具体使用说明

独立 Flutter 应用：

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

Add-to-App 嵌入：

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

### 基本介绍

`FlutterManager` 是 **Flutter** 视图与 UIAbility 的全局单例管理器，负责 `FlutterView` 的创建与销毁、`UIAbility` / `WindowStage` 的注册追踪、全屏模式控制、系统栏可见性管理等。`FlutterAbility` 在 `onCreate` / `onDestroy` 中通过 `pushUIAbility` / `popUIAbility` 与 `FlutterManager` 交互。

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从页面或 Ability 中获取
// const context: common.Context = ...

const manager = FlutterManager.getInstance();

// 创建 FlutterView
const flutterView = manager.createFlutterView(context);

// 设置全屏
manager.setUseFullScreen(true, context);

// 控制系统栏
manager.setSpecificSystemBarEnabled(flutterView.getId(), 'status', true);
```

本节主要介绍 `FlutterManager` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `getInstance()` | 获取 `FlutterManager` 单例实例。 |
| `createFlutterView(context)` | 创建并注册新的 `FlutterView`，自动生成 viewId。 |
| `deleteFlutterView(viewId)` | 从管理器中移除指定 `FlutterView`。 |
| `setUseFullScreen(use, context?)` | 设置是否启用窗口全屏布局。 |
| `setSpecificSystemBarEnabled(viewId, bar, visible)` | 控制指定视图对应窗口的系统栏可见性。 |

### 方法

#### getInstance

```typescript
static getInstance(): FlutterManager
```

获取 `FlutterManager` 单例实例。整个应用共享同一管理器，用于统一管理所有 `FlutterView` 与 `UIAbility` 的关联关系。

##### 返回值

| 类型           | 说明                    |
| -------------- | ----------------------- |
| FlutterManager | 全局单例管理器实例。    |

#### createFlutterView

```typescript
createFlutterView(context: Context): FlutterView
```

创建新的 `FlutterView` 实例并注册到管理器。viewId 自动生成为 `oh_flutter_${index}` 格式（index 自增）。

**建议**保持 `oh_flutter_` 前缀，否则可能影响渲染性能。

##### 参数

| 参数名  | 类型    | 说明           |
| ------- | ------- | -------------- |
| context | Context | 应用上下文。   |

##### 返回值

| 类型        | 说明                |
| ----------- | ------------------- |
| FlutterView | 新创建的视图实例。  |

#### deleteFlutterView

```typescript
deleteFlutterView(viewId: string, flutterView?: FlutterView): void
```

从管理器的视图列表中移除指定 `FlutterView`。`FlutterView.onSurfaceDestroyed` 内部会调用此方法完成清理。

##### 参数

| 参数名      | 类型        | 必填 | 说明                                     |
| ----------- | ----------- | ---- | ---------------------------------------- |
| viewId      | string      | 是   | 要移除的视图 ID。                        |
| flutterView | FlutterView | 否   | 传入视图实例时执行删除；未传入时不操作。 |

#### setUseFullScreen

```typescript
setUseFullScreen(use: boolean, context?: Context | null | undefined): void
```

设置当前窗口是否使用全屏布局。内部委托给 `FullScreenListener` 实现，默认通过 `mainWindow.setWindowLayoutFullScreen` 控制。在 2in1 设备 API 14+ 上启用全屏时，还会调用 `maximize(ENTER_IMMERSIVE)`。

`FlutterAbility` 在 `onWindowStageCreate` 中若 `isDefaultFullScreen()` 返回 `true`，会自动调用此方法。

##### 参数

| 参数名  | 类型    | 必填 | 说明                                                         |
| ------- | ------- | ---- | ------------------------------------------------------------ |
| use     | boolean | 是   | `true` 启用全屏布局；`false` 关闭全屏。                      |
| context | Context | 否   | 应用上下文；未设置时使用第一个已注册的 UIAbility 上下文。      |

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

控制指定 `FlutterView` 对应窗口的系统栏可见性，并在隐藏系统栏时自动为视图设置避让区内边距，防止 Flutter 内容被遮挡。

##### 参数

| 参数名            | 类型                                                         | 必填 | 说明                                                         |
| ----------------- | ------------------------------------------------------------ | ---- | ------------------------------------------------------------ |
| flutterViewId     | string                                                       | 是   | 目标 `FlutterView` 的 ID。                                   |
| specificSystemBar | `'status'` \| `'navigation'` \| `'navigationIndicator'`      | 是   | 系统栏类型：状态栏、三键导航栏或手势导航条。                 |
| isVisible         | boolean                                                      | 是   | `true` 显示；`false` 隐藏。                                  |
| enableAnimation   | boolean                                                      | 否   | 是否启用动画效果。                                           |
| context           | Context                                                      | 否   | 应用上下文；未设置时使用第一个已注册的 UIAbility。           |

##### specificSystemBar 枚举说明

| 值                    | 说明           |
| --------------------- | -------------- |
| status                | 状态栏。       |
| navigation            | 三键导航栏。   |
| navigationIndicator   | 手势导航条。   |

### 具体使用说明

```typescript
import { FlutterManager } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// context 需从页面或 Ability 中获取
// const context: common.Context = ...

const manager = FlutterManager.getInstance();

// 创建 FlutterView 并获取 viewId
const flutterView = manager.createFlutterView(context);
const viewId = flutterView.getId();

// 全屏显示（非 2in1 设备默认行为）
manager.setUseFullScreen(true, context);

// 隐藏状态栏，自动设置顶部避让
manager.setSpecificSystemBarEnabled(viewId, 'status', false);

// 在页面中使用
FlutterPage({ viewId: viewId })
```

## LifecycleChannel

### 基本介绍

`LifecycleChannel` 是应用生命周期通信通道，负责将 OpenHarmony 侧的应用生命周期状态同步到 Flutter 框架。通过 `BasicMessageChannel`（通道名 `flutter/lifecycle`）向 Dart 侧发送 `AppLifecycleState` 状态字符串。

`FlutterAbility` 和 `FlutterEntry` 在生命周期回调中通过 `FlutterAbilityAndEntryDelegate` 自动调用本通道的方法，应用开发者一般无需手动发送。可通过 `FlutterEngine.getLifecycleChannel()` 获取实例。

```typescript
import { FlutterEngine } from '@ohos/flutter_ohos';

// flutterEngine 由 FlutterAbility 或 FlutterEntry 提供
// const flutterEngine: FlutterEngine = ...

const lifecycleChannel = flutterEngine.getLifecycleChannel();

// 通常由框架自动调用，以下为手动通知示例
lifecycleChannel?.appIsResumed();
lifecycleChannel?.appIsPaused();
```

本节主要介绍 `LifecycleChannel` 的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `appIsResumed()` | 通知 Flutter 应用进入 resumed（前台活跃）状态。 |
| `appIsInactive()` | 通知 Flutter 应用进入 inactive（非活跃）状态。 |
| `appIsPaused()` | 通知 Flutter 应用进入 paused（后台）状态。 |
| `appIsDetached()` | 通知 Flutter 应用进入 detached（与引擎分离）状态。 |

### 生命周期状态映射

`LifecycleChannel` 根据 UIAbility 状态与窗口焦点综合计算最终发送给 Flutter 的状态：

| UIAbility 状态 | 窗口有焦点 | Flutter 状态 |
| --- | --- | --- |
| FOREGROUND | true | resumed |
| FOREGROUND | false | inactive |
| BACKGROUND | true / false | paused |
| DESTROY | true / false | detached |

当 UIAbility 处于 FOREGROUND 但窗口失去焦点时，实际发送给 Flutter 的状态为 `inactive` 而非 `resumed`。

### 方法

#### appIsResumed

```typescript
appIsResumed(): void
```

通知 Flutter 应用已恢复至前台活跃状态。框架在以下时机自动调用：

- `FlutterAbilityAndEntryDelegate.onShow()`（Ability 切换至前台）；
- `WindowStageEventType.RESUMED` 窗口事件；
- 窗口重新获得焦点且 Ability 处于前台时。

对应发送状态：`AppLifecycleState.resumed`（有焦点）或 `AppLifecycleState.inactive`（无焦点）。

#### appIsInactive

```typescript
appIsInactive(): void
```

通知 Flutter 应用进入非活跃状态，例如窗口失焦但仍可见。框架在 `WindowStageEventType.PAUSED` 事件时自动调用。

对应发送状态：`AppLifecycleState.inactive`。

#### appIsPaused

```typescript
appIsPaused(): void
```

通知 Flutter 应用已进入后台暂停状态。框架在 `FlutterAbilityAndEntryDelegate.onHide()`（Ability 切换至后台）时自动调用。

对应发送状态：`AppLifecycleState.paused`。

#### appIsDetached

```typescript
appIsDetached(): void
```

通知 Flutter 应用已与引擎分离，通常发生在 Ability 销毁、引擎 detach 阶段。框架在 `FlutterAbilityAndEntryDelegate.onDetach()` 中，当 `shouldDispatchAppLifecycleState()` 返回 `true` 时自动调用。

对应发送状态：`AppLifecycleState.detached`。

### 获取方式

```typescript
const lifecycleChannel = flutterEngine.getLifecycleChannel();
```

| 类型 | 说明 |
| --- | --- |
| LifecycleChannel \| null | 引擎未初始化时为 `null`。 |

## NavigationChannel

### 基本介绍

`NavigationChannel` 是 Flutter 路由导航通信通道，通过 `BasicMessageChannel`（通道名 `flutter/navigation`）在 ArkTS 侧与 Dart 侧之间同步路由状态。框架在引擎启动时通过本通道设置初始路由，原生侧切页时通过 `pushRoute` / `popRoute` 驱动 Flutter 导航栈。

`FlutterAbility` / `FlutterEntry` 在引擎初始化阶段自动调用 `setInitialRoute` 设置初始路由。应用开发者一般通过 `FlutterEngine.getNavigationChannel()` 获取实例后，在原生交互中主动调用 `pushRoute` / `popRoute`。

```typescript
import { FlutterEngine } from '@ohos/flutter_ohos';

// flutterEngine 由 FlutterAbility 或 FlutterEntry 提供
// const flutterEngine: FlutterEngine = ...

const navigationChannel = flutterEngine?.getNavigationChannel();

// 原生侧主动切换 Flutter 路由
navigationChannel?.pushRoute('/detail');
```

本节主要介绍 `NavigationChannel` 的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `setInitialRoute(route)` | 设置 Flutter 初始路由，引擎启动时由框架自动调用。 |
| `pushRoute(route)` | 原生侧向 Flutter 推送新路由。 |
| `popRoute()` | 通知 Flutter 弹出当前路由。 |
| `setRoutePoppingListener(listener)` | 注册路由弹出监听器。 |

### 方法

#### setInitialRoute

```typescript
setInitialRoute(route: string): void
```

设置 Flutter 应用的初始路由。框架在执行 Dart 入口前调用此方法，确保 Flutter 首屏渲染时即生效目标路由。对应 `FlutterAbility` / `FlutterEntry` 的 `getInitialRoute()` 返回值。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| route | string | 初始路由字符串，如 `"/"` 或 `"/home"`。 |

#### pushRoute

```typescript
pushRoute(route: string): void
```

从原生侧向 Flutter 导航栈推送新路由。适用于原生按钮、跳板等交互触发 Flutter 内部页面切换的场景。

> 注意：切换页面应使用 `pushRoute`，**勿重复调用 `executeDartEntrypoint()`**，因为每个引擎的 Dart Isolate 只能启动一次。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| route | string | 要推送的路由字符串。 |

#### popRoute

```typescript
popRoute(): void
```

通知 Flutter 弹出当前路由。通常在 ArkUI 页面的 `onBackPress()` 中调用：

```typescript
onBackPress(): boolean {
  this.flutterEntry?.onBackPress(); // 内部触发 popRoute
  return true;
}
```

#### setRoutePoppingListener

```typescript
setRoutePoppingListener(listener: RoutePoppingListener): void
```

注册路由弹出监听器，用于在 Flutter 侧请求 `SystemNavigator.pop()` 时接收回调。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| listener | RoutePoppingListener | 路由弹出事件监听器。 |

### 获取方式

```typescript
const navigationChannel = flutterEngine.getNavigationChannel();
```

| 类型 | 说明 |
| --- | --- |
| NavigationChannel \| null | 引擎未初始化时为 `null`。 |

### 具体使用说明

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';

export default class EntryAbility extends FlutterAbility {
  private flutterEngine: FlutterEngine | null = null;

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    this.flutterEngine = flutterEngine;
  }

  // 原生按钮触发：跳转到 Flutter 的 /detail 路由
  jumpToFlutterDetail(): void {
    this.flutterEngine?.getNavigationChannel()?.pushRoute('/detail');
  }
}
```

## MethodChannel

### 基本介绍

`MethodChannel` 是 Flutter 平台通道（Platform Channel）的一种，用于在 ArkTS 侧与 Dart 侧之间进行**方法调用与结果回传**的双向通信。插件通过 `MethodChannel` 接收 Dart 侧发起的方法调用并返回结果，也可主动向 Dart 侧调用方法。

通道通过唯一 `name` 标识，Dart 侧与 ArkTS 侧需使用相同的 `name` 建立通道。默认编解码器为 `StandardMethodCodec`，也支持通过构造参数指定 `JSONMethodCodec`。

```typescript
import { MethodChannel, MethodCall, MethodResult } from '@ohos/flutter_ohos';

const channel = new MethodChannel('com.example.app/my_channel');

// 接收 Dart 侧方法调用
channel.setMethodCallHandler((call: MethodCall, result: MethodResult) => {
  switch (call.method) {
    case 'getBatteryLevel':
      result.success(85);
      break;
    default:
      result.notImplemented();
  }
});

// 主动调用 Dart 侧方法
const value = await channel.invokeMethod('dartMethod', { arg: 1 });
```

本节主要介绍 `MethodChannel` 中供应用开发者调用的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `new MethodChannel(name, codec?)` | 创建指定名称的方法通道，可选编解码器。 |
| `setMethodCallHandler(handler)` | 设置方法调用处理器，接收 Dart 侧调用。 |
| `invokeMethod(method, args?)` | 主动调用 Dart 侧方法，返回 `Promise`。 |
| `setMethodCallHandler(null)` | 传入 `null` 取消方法调用处理器。 |

### 方法

#### 构造函数

```typescript
constructor(name: string, codec: MethodCodec = StandardMethodCodec.INSTANCE)
```

创建 `MethodChannel` 实例。Dart 侧与 ArkTS 侧的 `name` 与 `codec` 必须一致。

##### 参数

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| name | string | 是 | 通道唯一标识。 |
| codec | MethodCodec | 否 | 方法编解码器，默认 `StandardMethodCodec.INSTANCE`。 |

#### setMethodCallHandler

```typescript
setMethodCallHandler(handler: ((call: MethodCall, result: MethodResult) => void) | null): void
```

设置方法调用处理器。Dart 侧通过 `MethodChannel.invokeMethod` 调用时，框架将方法名与参数解码后回调 `handler`。传入 `null` 可取消已有处理器。

`handler` 中**必须**调用 `result` 的 `success` / `error` / `notImplemented` 之一，否则 Dart 侧 `await` 将永不返回。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| handler | (call: MethodCall, result: MethodResult) => void \| null | 方法调用回调；传 `null` 取消。 |

##### MethodCall

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| method | string | 方法名。 |
| args | Any | Dart 侧传入的参数，经 codec 解码；无参数时为 `null`。 |

##### MethodResult

| 方法 | 说明 |
| --- | --- |
| `success(result)` | 回传成功结果。 |
| `error(code, message, details)` | 回传错误，含错误码、消息与详情。 |
| `notImplemented()` | 表示该方法未实现。 |

#### invokeMethod

```typescript
invokeMethod(method: string, args?: Any): Promise<Any>
```

主动调用 Dart 侧已注册的方法。返回的 `Promise` 在 Dart 侧回传结果后 resolve；Dart 侧抛出 `MissingPluginException` 或 `PlatformException` 时 reject。

##### 参数

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| method | string | 是 | 要调用的 Dart 方法名。 |
| args | Any | 否 | 传递给 Dart 侧的参数。 |

##### 返回值

| 类型 | 说明 |
| --- | --- |
| Promise\<Any> | Dart 侧回传的结果。 |

### 与 MissingPluginException 的关系

当 Dart 侧调用 `MethodChannel.invokeMethod` 而 ArkTS 侧**未注册对应 `setMethodCallHandler`** 时，Dart 侧会抛出 `MissingPluginException`。常见原因：

1. 插件未在 `configureFlutterEngine` 中通过 `GeneratedPluginRegistrant.registerWith(flutterEngine)` 注册；
2. 手动注册的插件未在 `onAttachedToEngine` 中为对应通道 `setMethodCallHandler`；
3. 通道 `name` 在 Dart 侧与 ArkTS 侧不一致。

排查时可先确认 `GeneratedPluginRegistrant` 是否包含目标插件，再核对通道名与 handler 注册时序。

### 具体使用说明

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

> 相关通道类型：`EventChannel` 用于事件流（Dart 监听 ArkTS 主动推送的事件）；`BasicMessageChannel` 用于双向消息传递（`LifecycleChannel` / `NavigationChannel` 均基于它实现）。用法与 `MethodChannel` 类似，分别使用 `setStreamHandler` 与 `setMessageHandler`。

## FlutterPlugin

### 基本介绍

`FlutterPlugin` 是 **Flutter 插件的根接口**，定义插件附加到 `FlutterEngine` 与从中分离时的生命周期回调。所有平台原生插件（MethodChannel、PlatformView、EventChannel 等）均需实现此接口，通过 `FlutterPluginBinding` 获取通信所需的 `BinaryMessenger`、`FlutterEngine`、上下文与注册表。

插件通过两种方式注册到引擎：

1. **自动注册**：在 `FlutterAbility` / `FlutterEntry` 的 `configureFlutterEngine` 中调用 `GeneratedPluginRegistrant.registerWith(flutterEngine)`，由自动生成的注册类批量附加 `pubspec.yaml` 声明的插件。
2. **手动注册**：通过 `flutterEngine.getPlugins()?.add(new MyPlugin())` 单个附加。

无论哪种方式，框架在附加时回调 `onAttachedToEngine`，在分离时回调 `onDetachedFromEngine`。

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
      // 处理 Dart 侧方法调用
    });
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }
}
```

本节主要介绍 `FlutterPlugin` 的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `onAttachedToEngine(binding)` | 插件附加到引擎时回调，用于初始化通道、注册 handler 等。 |
| `onDetachedFromEngine(binding)` | 插件从引擎分离时回调，用于释放资源、注销 handler。 |

### 方法

#### onAttachedToEngine

```typescript
onAttachedToEngine(binding: FlutterPluginBinding): void
```

插件被附加到 `FlutterEngine` 时由框架回调。在此方法中通常完成：

- 通过 `binding.getBinaryMessenger()` 创建 `MethodChannel` / `EventChannel`；
- 通过 `binding.getPlatformViewRegistry()` 注册平台视图工厂；
- 通过 `binding.getContext()` 获取上下文，初始化平台资源；
- 为各通道 `setMethodCallHandler` / `setMessageHandler`。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| binding | FlutterPluginBinding | 引擎绑定对象，提供通信与上下文能力。 |

#### onDetachedFromEngine

```typescript
onDetachedFromEngine(binding: FlutterPluginBinding): void
```

插件从 `FlutterEngine` 分离时由框架回调。在此方法中应：

- 调用各通道的 `setMethodCallHandler(null)` / `setMessageHandler(null)` 注销 handler；
- 释放平台资源、解除监听；
- 置空引用，避免内存泄漏。

##### 参数

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| binding | FlutterPluginBinding | 引擎绑定对象。 |

## FlutterPluginBinding

### 基本介绍

`FlutterPluginBinding` 在插件附加 / 分离时由框架传入，封装插件与 `FlutterEngine` 交互所需的全部能力：消息通道、引擎实例、上下文、平台视图注册表、生命周期通道等。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `getFlutterEngine()` | 获取关联的 `FlutterEngine` 实例。 |
| `getBinaryMessenger()` | 获取 `BinaryMessenger`，用于创建 MethodChannel / EventChannel。 |
| `getContext()` | 获取应用上下文。 |
| `getPlatformViewRegistry()` | 获取平台视图注册表，用于注册 `PlatformViewFactory`。 |
| `getLifecycleChannel()` | 获取生命周期 Channel（插件如需感知生命周期可使用）。 |

### 方法

#### getFlutterEngine

```typescript
getFlutterEngine(): FlutterEngine
```

获取当前插件所附加的 `FlutterEngine` 实例，可用于进一步访问 `getPlugins()`、其他 Channel 或渲染器。

##### 返回值

| 类型 | 说明 |
| --- | --- |
| FlutterEngine | 关联的引擎实例。 |

#### getBinaryMessenger

```typescript
getBinaryMessenger(): BinaryMessenger
```

获取 `BinaryMessenger`，是创建 `MethodChannel` / `EventChannel` / `BasicMessageChannel` 的底层消息总线。`DartExecutor` 同时实现此接口，框架内部即通过引擎的 `DartExecutor` 提供。

##### 返回值

| 类型 | 说明 |
| --- | --- |
| BinaryMessenger | 消息总线实例。 |

#### getContext

```typescript
getContext(): common.Context
```

获取应用上下文，用于访问资源、能力等。

##### 返回值

| 类型 | 说明 |
| --- | --- |
| common.Context | 应用上下文。 |

#### getPlatformViewRegistry

```typescript
getPlatformViewRegistry(): PlatformViewRegistry
```

获取平台视图注册表，用于注册 `PlatformViewFactory`。详见 [PlatformViewRegistry](#platformviewregistry)。

##### 返回值

| 类型 | 说明 |
| --- | --- |
| PlatformViewRegistry | 平台视图注册表实例。 |

#### getLifecycleChannel

```typescript
getLifecycleChannel(): LifecycleChannel
```

获取生命周期 Channel，供插件感知应用前后台状态。详见 [LifecycleChannel](#lifecyclechannel)。

##### 返回值

| 类型 | 说明 |
| --- | --- |
| LifecycleChannel | 生命周期 Channel 实例。 |

### 具体使用说明

完整插件示例（MethodChannel + 资源访问）：

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
      // 通过 context 调用系统能力获取电量
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

手动注册到引擎：

```typescript
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { BatteryPlugin } from './BatteryPlugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    // 手动附加未在 pubspec 声明的插件
    flutterEngine.getPlugins()?.add(new BatteryPlugin());
  }
}
```

> 当 Dart 侧调用某通道方法抛出 `MissingPluginException` 时，请优先确认：
> 1. 插件是否在 `configureFlutterEngine` 中注册（自动或手动）；
> 2. `onAttachedToEngine` 中是否为对应通道 `setMethodCallHandler`；
> 3. Dart 与 ArkTS 侧通道 `name` 是否一致。

## PlatformViewRegistry

### 基本介绍

`PlatformViewRegistry` 是平台视图（Platform View）工厂的注册表接口，允许插件为特定 `viewTypeId` 注册原生视图工厂，从而在 Flutter Widget 树中嵌入 OpenHarmony 原生组件（ArkUI 组件）。

实现类为 `PlatformViewRegistryImpl`，由 `PlatformViewsController` 内部持有。插件在注册时通过 `FlutterPlugin.FlutterPluginBinding.getPlatformViewRegistry()` 获取注册表实例。

```typescript
import { FlutterPlugin, PlatformViewFactory, PlatformView } from '@ohos/flutter_ohos';
import { StandardMessageCodec } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// MyPlatformView 需为 PlatformView 的子类实现
// class MyPlatformView extends PlatformView { ... }

class MyPlatformViewFactory extends PlatformViewFactory {
  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    // 创建并返回原生 PlatformView 实例
    return new MyPlatformView(context);
  }
}

// 在插件 onAttachedToEngine 中注册
// binding.getPlatformViewRegistry().registerViewFactory('my-view-type', new MyPlatformViewFactory());
```

本节主要介绍 `PlatformViewRegistry` 的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `registerViewFactory(viewTypeId, factory)` | 为指定 viewTypeId 注册平台视图工厂。 |
| `getFactory(viewTypeId)` | 获取已注册的工厂（`PlatformViewRegistryImpl` 提供）。 |

### 方法

#### registerViewFactory

```typescript
registerViewFactory(viewTypeId: string, factory: PlatformViewFactory): boolean
```

为指定的 `viewTypeId` 注册 `PlatformViewFactory`。Dart 侧通过 `PlatformView` Widget 的 `viewType` 参数引用此 ID，框架在创建平台视图时调用对应工厂的 `create` 方法。

同一 `viewTypeId` 只能注册一次；若已存在则返回 `false` 且不覆盖。

##### 参数

| 参数名     | 类型                 | 说明                                                         |
| ---------- | -------------------- | ------------------------------------------------------------ |
| viewTypeId | string               | 平台视图类型唯一标识，需与 Dart 侧 OhosView / UiKitView / AndroidView 等的 viewType 一致。 |
| factory    | PlatformViewFactory  | 用于创建平台视图实例的工厂类。                               |

##### 返回值

| 类型    | 说明                                                         |
| ------- | ------------------------------------------------------------ |
| boolean | `true` 表示注册成功；`false` 表示该 viewTypeId 已被注册。    |

#### getFactory

```typescript
getFactory(viewTypeId: string): PlatformViewFactory
```

获取指定 `viewTypeId` 对应的 `PlatformViewFactory`。此方法由 `PlatformViewRegistryImpl` 实现，`PlatformViewsController` 在创建平台视图时内部调用。

应用开发者通常通过注册工厂即可，无需直接调用此方法。

##### 参数

| 参数名     | 类型   | 说明               |
| ---------- | ------ | ------------------ |
| viewTypeId | string | 平台视图类型 ID。  |

##### 返回值

| 类型                | 说明                                     |
| ------------------- | ---------------------------------------- |
| PlatformViewFactory | 对应的工厂实例；未注册时返回 `undefined`。 |

### PlatformViewFactory

详见 [PlatformViewFactory](#platformviewfactory) 章节的完整文档。

## PlatformViewFactory

### 基本介绍

`PlatformViewFactory` 是平台视图工厂的抽象基类，用于根据 Dart 侧 `PlatformView` Widget 的请求创建对应的 OpenHarmony 原生视图实例。插件通过 `PlatformViewRegistry.registerViewFactory` 注册工厂后，框架在 Flutter 渲染树需要嵌入原生组件时调用工厂的 `create` 方法。

```typescript
import { PlatformViewFactory, PlatformView } from '@ohos/flutter_ohos';
import { StandardMessageCodec } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// MyNativeView 需为 PlatformView 的子类实现
class MyViewFactory extends PlatformViewFactory {
  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new MyNativeView(context, viewId, args);
  }
}
```

本节主要介绍 `PlatformViewFactory` 中供插件开发者实现的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `new PlatformViewFactory(createArgsCodec)` | 构造工厂，指定 Dart 创建参数的编解码器。 |
| `create(context, viewId, args)` | 创建平台视图实例（抽象方法，子类必须实现）。 |
| `getCreateArgsCodec()` | 获取用于解码 `args` 的编解码器。 |

### 方法

#### 构造函数

```typescript
constructor(createArgsCodec: MessageCodec<Any>)
```

创建 `PlatformViewFactory` 实例，并保存用于解码 Dart 侧传入创建参数的编解码器。

常用编解码器：

| 编解码器 | 说明 |
| --- | --- |
| `StandardMessageCodec.INSTANCE` | 标准消息编解码，支持常见基础类型。 |
| `JSONMethodCodec` / `JSONMessageCodec` | JSON 格式编解码。 |

##### 参数

| 参数名          | 类型              | 说明                                       |
| --------------- | ----------------- | ------------------------------------------ |
| createArgsCodec | MessageCodec\<Any> | 解码 `create` 方法 `args` 参数的编解码器。 |

#### create

```typescript
abstract create(context: common.Context, viewId: number, args: Any): PlatformView
```

创建并返回一个新的 `PlatformView` 实例，供 Flutter 渲染树嵌入。子类必须实现此方法。

##### 参数

| 参数名  | 类型            | 说明                                                         |
| ------- | --------------- | ------------------------------------------------------------ |
| context | common.Context  | 创建视图使用的上下文，与 `FlutterView` 的 context 可能不同。   |
| viewId  | number          | Dart 侧分配的唯一实例 ID，用于标识该次创建的平台视图。       |
| args    | Any             | Dart 侧传入的创建参数，经 `createArgsCodec` 解码；无参数时为 `null`。 |

##### 返回值

| 类型         | 说明                         |
| ------------ | ---------------------------- |
| PlatformView | 新创建的平台视图实例。       |

#### getCreateArgsCodec

```typescript
getCreateArgsCodec(): MessageCodec<Any>
```

返回构造时传入的编解码器，框架在解码 Dart 侧 `creationParams` 时使用。

##### 返回值

| 类型              | 说明           |
| ----------------- | -------------- |
| MessageCodec\<Any> | 创建参数编解码器。 |

## PlatformView

### 基本介绍

`PlatformView` 是嵌入 Flutter 渲染层次中的原生视图句柄抽象类。插件实现此类，通过 `getView()` 返回 ArkUI `WrappedBuilder`，由 `EmbeddingNodeController` 构建为 `FrameNode` 并挂载到 Flutter 组件树中。

```typescript
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';

class MyNativeView extends PlatformView {
  getView(): WrappedBuilder<[Params]> {
    return wrapBuilder(buildNativeComponent);
  }

  dispose(): void {
    // 释放资源
  }
}

@Builder
function buildNativeComponent(params: Params) {
  // 构建 ArkUI 原生组件
}
```

本节主要介绍 `PlatformView` 中供插件开发者实现的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `getView()` | 返回用于嵌入 Flutter 层次的 ArkUI `WrappedBuilder`。 |
| `dispose()` | 销毁平台视图，释放所有引用（抽象方法，必须实现）。 |
| `onFlutterViewAttached(dvModel)` | Flutter 渲染视图关联时回调。 |
| `onFlutterViewDetached()` | Flutter 渲染视图分离时回调。 |
| `getType()` | 获取平台视图类型标识。 |
| `onActive()` | 视图可见区域达到阈值时恢复纹理连续产出（动画/视频等）。 |
| `onInactive()` | 视图不可见时暂停纹理连续产出。 |
| `getPlatformViewVisibleAreaEventOptions()` | 配置可见区域监控阈值，控制 `onActive` / `onInactive` 的触发。 |

### 方法

#### getView

```typescript
abstract getView(): WrappedBuilder<[Params]>
```

返回嵌入 Flutter 组件树的 ArkUI 构建器。`EmbeddingNodeController` 在 `setRenderOption` 时调用此方法，并通过 `BuilderNode.build` 将原生组件渲染到 Flutter 表面。

`Params` 包含以下字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| direction | Direction | 布局方向。 |
| platformView | PlatformView | 当前平台视图实例引用。 |

##### 返回值

| 类型 | 说明 |
| --- | --- |
| WrappedBuilder\<[Params]> | ArkUI 组件构建器。 |

#### dispose

```typescript
abstract dispose(): void
```

销毁平台视图。调用后该 `PlatformView` 实例不可再使用。插件必须在此方法中清除对 `DynamicView` 及所有原生资源的引用，否则会导致内存泄漏。

框架在 `PlatformViewsController.dispose(viewId)` 时调用此方法。

#### onFlutterViewAttached

```typescript
onFlutterViewAttached(dvModel: DVModel): void
```

当拥有此 `PlatformView` 的 `FlutterEngine` 关联了负责渲染 Flutter UI 的 `DynamicView` 时调用。表示 Flutter 引擎已具备渲染能力和用户交互表面。

`PlatformViewsController` 在平台视图附加到 `FlutterView` 时触发此回调。子类可重写以获取 `DVModel` 引用，但应尽量避免强依赖，以降低对未来架构变更的脆弱性。

##### 参数

| 参数名  | 类型    | 说明                              |
| ------- | ------- | --------------------------------- |
| dvModel | DVModel | 与 FlutterView 关联的动态视图模型。 |

#### onFlutterViewDetached

```typescript
onFlutterViewDetached(): void
```

当 Flutter 渲染视图与 `FlutterEngine` 分离时调用。表示引擎不再拥有渲染表面和用户交互表面。子类应释放 `onFlutterViewAttached` 中获取的所有 `DynamicView` 相关引用。

#### getType

```typescript
getType(): string
```

获取平台视图类型标识，默认返回 `'default'`。子类可重写以返回自定义类型字符串，用于区分不同渲染策略。

##### 返回值

| 类型   | 说明                 |
| ------ | -------------------- |
| string | 平台视图类型标识。   |

#### onActive

```typescript
onActive(): void
```

恢复外部纹理的连续产出操作，包括动画和视频播放。当平台视图可见区域比例达到 `onActiveThreshold` 阈值时，由 `EmbeddingNodeController` 通过可见区域监听自动调用。

子类可重写以恢复视频播放、动画等消耗 GPU 纹理资源的操作。

#### onInactive

```typescript
onInactive(): void
```

暂停外部纹理的连续产出操作。当平台视图可见区域比例降至 `onInactiveThreshold` 以下，或视图进入不可见状态时，由 `EmbeddingNodeController` 自动调用。

子类可重写以暂停视频播放、动画等，节省系统资源。

### 可见区域监控

平台视图可通过重写 `getPlatformViewVisibleAreaEventOptions()` 配置可见区域监控，控制 `onActive` / `onInactive` 的触发阈值：

```typescript
getPlatformViewVisibleAreaEventOptions(): PlatformViewVisibleAreaEventOptions
```

返回值 `PlatformViewVisibleAreaEventOptions` 包含以下字段：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| enable | boolean | 是否启用可见区域监控，默认 `false`。 |
| ratios | Array\<number> | 可见比例阈值数组，如 `[0.0, 1.0]`。 |
| expectedUpdateInterval | number | 更新间隔（毫秒），默认 `1000`。 |
| onInactiveThreshold | number | 触发 `onInactive` 的可见比例阈值，默认 `0.0`。 |
| onActiveThreshold | number | 触发 `onActive` 的可见比例阈值，默认 `1.0`。 |

### 具体使用说明

```typescript
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { PlatformViewFactory } from '@ohos/flutter_ohos';
import { StandardMessageCodec } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

// @Builder 函数必须在全局作用域中声明
@Builder
function buildMap(params: Params) {
  // 嵌入原生地图组件
  Column() {
    Text('Native Map View')
  }
}

// 1. 实现 PlatformView
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
    // 恢复地图动画
  }

  onInactive(): void {
    // 暂停地图动画
  }

  dispose(): void {
    // 释放地图资源
  }
}

// 2. 实现 PlatformViewFactory 并注册
class NativeMapFactory extends PlatformViewFactory {
  constructor() {
    super(StandardMessageCodec.INSTANCE);
  }

  create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new NativeMapView(context);
  }
}

// 在插件 onAttachedToEngine 中注册：
// binding.getPlatformViewRegistry().registerViewFactory('my_map_view', new NativeMapFactory());
```

## PlatformViewWrapper

### 基本介绍

`PlatformViewWrapper` 用于包装平台视图（Platform View），拦截手势并将其投影到渲染目标上。OpenHarmony 平台视图通过引擎的 `TextureLayer` 组合：视图嵌入 ArkUI 的 `DynamicView` 层次结构，同时投影到纹理渲染目标，由 Flutter 引擎高效合成。

由于视图位于 ArkUI 视图层次中，键盘和无障碍交互可正常工作。`PlatformViewsController` 在创建平台视图时内部实例化 `PlatformViewWrapper`，将 `DVModel` 挂载到 `FlutterView` 的组件树中。

```typescript
import { PlatformViewWrapper } from '@ohos/flutter_ohos';
import { createDVModelFromJson, DVModelJson } from '@ohos/flutter_ohos';

// 通常由 PlatformViewsController 内部创建，以下为结构示意
// dvModel 由 createDVModelFromJson 创建，flutterView 由 FlutterManager 提供
const viewWrapper = new PlatformViewWrapper();
viewWrapper.addDvModel(dvModel);
flutterView.getDVModel().children.push(viewWrapper.getDvModel());
```

本节主要介绍 `PlatformViewWrapper` 的关键接口。

### 关键接口

| 接口 | 说明 |
| --- | --- |
| `new PlatformViewWrapper()` | 构造平台视图包装器实例。 |
| `setTouchProcessor(newTouchProcessor)` | 设置触摸事件处理器。 |
| `addDvModel(model)` | 添加 `DynamicView` 模型到包装器。 |
| `setLayoutParams(parameters)` | 设置平台视图的布局参数（位置与尺寸）。 |

### 方法

#### 构造函数

```typescript
constructor()
```

创建空的 `PlatformViewWrapper` 实例。创建后需通过 `addDvModel` 关联 `DVModel`，再由 `PlatformViewsController` 将其挂载到 `FlutterView` 的 `DVModel.children` 列表中。

#### setTouchProcessor

```typescript
setTouchProcessor(newTouchProcessor: OhosTouchProcessor): void
```

设置用于处理平台视图触摸事件的 `OhosTouchProcessor`。触摸处理器负责将 ArkUI 侧的触摸事件转换为 Flutter 引擎可识别的格式并分发。

##### 参数

| 参数名           | 类型                | 说明                     |
| ---------------- | ------------------- | ------------------------ |
| newTouchProcessor | OhosTouchProcessor | 触摸事件处理器实例。     |

#### addDvModel

```typescript
addDvModel(model: DVModel): void
```

将 `DynamicView` 模型添加到包装器。`PlatformViewsController` 在创建平台视图时，先通过 `createDVModelFromJson` 构建包含 `NodeContainer` 和 `EmbeddingNodeController` 的 `DVModel`，再调用此方法关联。

关联后通过 `getDvModel()` 获取模型并推入 `FlutterView.getDVModel().children`，完成平台视图在 Flutter 组件树中的挂载。

##### 参数

| 参数名 | 类型    | 说明                              |
| ------ | ------- | --------------------------------- |
| model  | DVModel | 要添加的 DynamicView 模型实例。   |

#### setLayoutParams

```typescript
setLayoutParams(parameters: DVModelParameters): void
```

设置平台视图的布局参数，更新 `DVModel` 的 `params` 中的位置与尺寸信息。

从 `parameters` 中读取并应用以下字段：

| 参数字段   | 说明                       |
| ---------- | -------------------------- |
| marginLeft | 左边距，同步更新内部 `left`。 |
| marginTop  | 上边距，同步更新内部 `top`。  |
| width      | 视图宽度。                 |
| height     | 视图高度。                 |

若 `DVModel` 尚未关联（`model` 为 `undefined`），调用将被忽略。

##### 参数

| 参数名     | 类型              | 说明           |
| ---------- | ----------------- | -------------- |
| parameters | DVModelParameters | 布局参数对象。 |

### 内部使用流程

`PlatformViewsController` 创建平台视图时的典型流程：

1. 通过 `PlatformViewFactory.create` 创建 `PlatformView` 实例；
2. 创建 `EmbeddingNodeController` 并设置渲染选项；
3. 通过 `createDVModelFromJson` 构建 `NodeContainer` 类型的 `DVModel`；
4. `new PlatformViewWrapper()` → `addDvModel(dvModel)` → 存入 `viewWrappers` 映射表；
5. 将 `viewWrapper.getDvModel()` 推入 `FlutterView.getDVModel().children`；
6. 调用 `platformView.onFlutterViewAttached`。

### 具体使用说明

```typescript
import { PlatformViewWrapper } from '@ohos/flutter_ohos';
import { createDVModelFromJson, DVModelJson } from '@ohos/flutter_ohos';
import { EmbeddingNodeController } from '@ohos/flutter_ohos';
import { PlatformView } from '@ohos/flutter_ohos';

// 以下为 PlatformViewsController 内部逻辑的简化示意
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

