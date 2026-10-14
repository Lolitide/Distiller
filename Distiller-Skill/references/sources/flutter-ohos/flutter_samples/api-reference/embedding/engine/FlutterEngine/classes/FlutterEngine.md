[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEngine

A single Flutter execution environment.

The FlutterEngine is the container through which Dart code can be run in an OpenHarmony application.

Dart code in a FlutterEngine can execute in the background, or it can be rendered to the screen by
using the accompanying FlutterRenderer and Dart code using the Flutter framework on the Dart side.
Rendering can be started and stopped, thus allowing a FlutterEngine to move from UI interaction
to data-only processing and then back to UI interaction.

Multiple FlutterEngines may exist, execute Dart code, and render UIs within a single OpenHarmony app.
For better memory performance characteristics, construct multiple FlutterEngines via FlutterEngineGroup
rather than via FlutterEngine's constructor directly.

To start running Dart and/or Flutter within this FlutterEngine, get a reference to this engine's
DartExecutor and then use DartExecutor.executeDartEntrypoint(DartEntrypoint). The
DartExecutor.executeDartEntrypoint(DartEntrypoint) method must not be invoked twice on the same FlutterEngine.

To start rendering Flutter content to the screen, use getFlutterRenderer() to obtain a FlutterRenderer
and then attach a RenderSurface. Consider using a FlutterView as a RenderSurface.

Instantiating the first FlutterEngine per process will also load the Flutter engine's native library
and start the Dart VM. Subsequent FlutterEngines will run on the same VM instance but will have
their own Dart Isolate when the DartExecutor is run. Each Isolate is a self-contained Dart environment
and cannot communicate with each other except via Isolate ports.

## Implements

- [`EngineLifecycleListener`](../interfaces/EngineLifecycleListener.md)

## Constructors

### Constructor

> **new FlutterEngine**(`context`, `flutterLoader`, `flutterNapi`, `platformViewsController`): `FlutterEngine`

Constructs a new FlutterEngine instance.
Initializes DartExecutor, channels, plugins, FlutterLoader, FlutterNapi, and lifecycle listeners.

#### Parameters

##### context

`Context`

The application context

##### flutterLoader

`any`

Optional FlutterLoader instance, will be created if null

##### flutterNapi

`any`

Optional FlutterNapi instance, will be created if null

##### platformViewsController

`any`

Optional PlatformViewsController, will be created if null

#### Returns

`FlutterEngine`

## Properties

### dartExecutor

> **dartExecutor**: `DartExecutor`

## Methods

### addEngineLifecycleListener()

> **addEngineLifecycleListener**(`listener`): `void`

Adds a lifecycle listener to be notified of engine lifecycle events.

#### Parameters

##### listener

[`EngineLifecycleListener`](../interfaces/EngineLifecycleListener.md)

The EngineLifecycleListener to add

#### Returns

`void`

***

### destroy()

> **destroy**(): `void`

Destroys the Flutter engine and releases all resources.
Notifies listeners, detaches from ability, and cleans up all components.

#### Returns

`void`

***

### getAbilityControlSurface()

> **getAbilityControlSurface**(): [`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md)

Gets the ability control surface for managing ability-related operations.

#### Returns

[`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md)

The AbilityControlSurface instance, or null if not initialized

***

### getAccessibilityChannel()

> **getAccessibilityChannel**(): `any`

Gets the accessibility channel for managing accessibility features.

#### Returns

`any`

The AccessibilityChannel instance, or null if not initialized

***

### getDartExecutor()

> **getDartExecutor**(): `DartExecutor`

Gets the DartExecutor instance for executing Dart code.

#### Returns

`DartExecutor`

The DartExecutor instance

***

### getDisplayMetricsChannel()

> **getDisplayMetricsChannel**(): `any`

#### Returns

`any`

***

### getFlutterLoader()

> **getFlutterLoader**(): `FlutterLoader`

Gets the FlutterLoader instance for loading Flutter assets.

#### Returns

`FlutterLoader`

The FlutterLoader instance

***

### getFlutterNapi()

> **getFlutterNapi**(): `FlutterNapi`

Gets the FlutterNapi instance for native communication.

#### Returns

`FlutterNapi`

The FlutterNapi instance

***

### getFlutterRenderer()

> **getFlutterRenderer**(): [`FlutterRenderer`](../../renderer/FlutterRenderer/classes/FlutterRenderer.md)

Gets the FlutterRenderer instance for rendering operations.

#### Returns

[`FlutterRenderer`](../../renderer/FlutterRenderer/classes/FlutterRenderer.md)

The FlutterRenderer instance

***

### getLifecycleChannel()

> **getLifecycleChannel**(): `any`

Gets the lifecycle channel for managing application lifecycle events.

#### Returns

`any`

The LifecycleChannel instance, or null if not initialized

***

### getLocaleChannel()

> **getLocaleChannel**(): `any`

Gets the localization channel for managing locale information.

#### Returns

`any`

The LocalizationChannel instance, or null if not initialized

***

### getLocalizationPlugin()

> **getLocalizationPlugin**(): `any`

Gets the localization plugin for managing locale information.

#### Returns

`any`

The LocalizationPlugin instance, or null if not initialized

***

### getMouseCursorChannel()

> **getMouseCursorChannel**(): `any`

Gets the mouse cursor channel for managing cursor changes.

#### Returns

`any`

The MouseCursorChannel instance, or null if not initialized

***

### getNativeVsyncChannel()

> **getNativeVsyncChannel**(): `any`

Gets the native VSync channel for managing vertical synchronization.

#### Returns

`any`

The NativeVsyncChannel instance, or null if not initialized

***

### getNavigationChannel()

> **getNavigationChannel**(): `any`

Gets the navigation channel for managing navigation events.

#### Returns

`any`

The NavigationChannel instance, or null if not initialized

***

### getPlatformChannel()

> **getPlatformChannel**(): `any`

Gets the platform channel for platform-specific communication.

#### Returns

`any`

The PlatformChannel instance, or null if not initialized

***

### getPlatformViewsController()

> **getPlatformViewsController**(): `any`

Gets the platform views controller for managing platform views.

#### Returns

`any`

The PlatformViewsController instance, or null if not initialized

***

### getPlugins()

> **getPlugins**(): [`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md)

Gets the plugin registry for managing Flutter plugins.

#### Returns

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md)

The PluginRegistry instance, or null if not initialized

***

### getRestorationChannel()

> **getRestorationChannel**(): `any`

Gets the restoration channel for managing state restoration.

#### Returns

`any`

The RestorationChannel instance, or null if not initialized

***

### getSensitiveContentChannel()

> **getSensitiveContentChannel**(): `any`

#### Returns

`any`

***

### getSettingsChannel()

> **getSettingsChannel**(): `any`

Gets the settings channel for managing application settings.

#### Returns

`any`

The SettingsChannel instance, or null if not initialized

***

### getSystemChannel()

> **getSystemChannel**(): `any`

Gets the system channel for system-level communication.

#### Returns

`any`

The SystemChannel instance, or null if not initialized

***

### getSystemLanguages()

> **getSystemLanguages**(): `void`

Gets the system languages from the native side.

#### Returns

`void`

***

### getTextInputChannel()

> **getTextInputChannel**(): `any`

Gets the text input channel for managing text input events.

#### Returns

`any`

The TextInputChannel instance, or null if not initialized

***

### init()

> **init**(`context`, `dartVmArgs`, `waitForRestorationData`): `void`

Initializes the Flutter engine.
Sets up all channels, plugins, and attaches to the native engine.

#### Parameters

##### context

`Context`

The application context

##### dartVmArgs

`string`[]

Optional Dart VM arguments

##### waitForRestorationData

`boolean`

Whether to wait for restoration data

#### Returns

`void`

***

### onEngineWillDestroy()

> **onEngineWillDestroy**(): `void`

Called when the engine is about to be destroyed.

#### Returns

`void`

#### Implementation of

[`EngineLifecycleListener`](../interfaces/EngineLifecycleListener.md).[`onEngineWillDestroy`](../interfaces/EngineLifecycleListener.md#onenginewilldestroy)

***

### onPreEngineRestart()

> **onPreEngineRestart**(): `void`

Called before the engine restarts.
Notifies all registered lifecycle listeners.

#### Returns

`void`

#### Implementation of

[`EngineLifecycleListener`](../interfaces/EngineLifecycleListener.md).[`onPreEngineRestart`](../interfaces/EngineLifecycleListener.md#onpreenginerestart)

***

### prefetchFramesCfg()

> **prefetchFramesCfg**(): `Promise`\<`void`\>

Prefetches frame configuration for improved performance.

#### Returns

`Promise`\<`void`\>

***

### processPendingMessages()

> **processPendingMessages**(): `void`

Processes any pending messages from the native side.

#### Returns

`void`

***

### removeEngineLifecycleListener()

> **removeEngineLifecycleListener**(`listener`): `void`

Removes a lifecycle listener from the list of registered listeners.

#### Parameters

##### listener

[`EngineLifecycleListener`](../interfaces/EngineLifecycleListener.md)

The EngineLifecycleListener to remove

#### Returns

`void`

***

### spawn()

> **spawn**(`context`, `dartEntrypoint`, `initialRoute`, `dartEntrypointArgs`, `platformViewsController`, `waitForRestorationData`): `FlutterEngine`

Spawns a new Flutter engine from this engine.
The spawned engine shares resources with the parent engine.

#### Parameters

##### context

`Context`

The application context

##### dartEntrypoint

[`DartEntrypoint`](../../dart/DartExecutor/classes/DartEntrypoint.md)

The Dart entrypoint configuration

##### initialRoute

`string`

The initial route for navigation

##### dartEntrypointArgs

`string`[]

Arguments for the Dart entrypoint

##### platformViewsController

`PlatformViewsController`

The platform views controller

##### waitForRestorationData

`boolean`

Whether to wait for restoration data

#### Returns

`FlutterEngine`

The spawned FlutterEngine instance

#### Throws

Error if this engine is not fully constructed
