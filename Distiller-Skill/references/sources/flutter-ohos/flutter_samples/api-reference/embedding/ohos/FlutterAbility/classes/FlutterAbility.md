[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterAbility

Base Flutter Ability for OpenHarmony.
Main responsibilities:
1. Holds and initializes FlutterAbilityDelegate
2. Forwards lifecycle events

Main abilities should inherit from this class.

## Extends

- `UIAbility`

## Implements

- [`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md)

## Constructors

### Constructor

> **new FlutterAbility**(): `FlutterAbility`

#### Returns

`FlutterAbility`

#### Inherited from

`UIAbility.constructor`

## Methods

### addPlugin()

> **addPlugin**(`plugin`): `void`

Adds a Flutter plugin.

#### Parameters

##### plugin

[`FlutterPlugin`](../../../engine/plugins/FlutterPlugin/interfaces/FlutterPlugin.md)

The FlutterPlugin to add

#### Returns

`void`

***

### attachToEngineAutomatically()

> **attachToEngineAutomatically**(): `boolean`

Determines whether to automatically attach to the engine.

#### Returns

`boolean`

True to attach automatically, false otherwise

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`attachToEngineAutomatically`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#attachtoengineautomatically)

***

### cleanUpFlutterEngine()

> **cleanUpFlutterEngine**(`flutterEngine`): `void`

Cleans up a FlutterEngine instance.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine to clean up

#### Returns

`void`

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`cleanUpFlutterEngine`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#cleanupflutterengine)

***

### configureFlutterEngine()

> **configureFlutterEngine**(`flutterEngine`): `void`

Configures a FlutterEngine instance.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine to configure

#### Returns

`void`

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`configureFlutterEngine`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#configureflutterengine)

***

### detachFromFlutterEngine()

> **detachFromFlutterEngine**(): `void`

Detaches from the Flutter engine.

#### Returns

`void`

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`detachFromFlutterEngine`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#detachfromflutterengine)

***

### getAbility()

> **getAbility**(): `UIAbility`

Gets the UIAbility instance.

#### Returns

`UIAbility`

This UIAbility instance

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getAbility`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getability)

***

### getAppBundlePath()

> **getAppBundlePath**(): `string`

Gets the app bundle path.

#### Returns

`string`

The bundle path string

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getAppBundlePath`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getappbundlepath)

***

### getCachedEngineGroupId()

> **getCachedEngineGroupId**(): `string`

Gets the cached engine group ID from launch parameters.

#### Returns

`string`

The cached engine group ID string, or null if not set

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getCachedEngineGroupId`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getcachedenginegroupid)

***

### getCachedEngineId()

> **getCachedEngineId**(): `string`

Gets the cached engine ID from launch parameters.

#### Returns

`string`

The cached engine ID string

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getCachedEngineId`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getcachedengineid)

***

### getDartEntrypointArgs()

> **getDartEntrypointArgs**(): `string`[]

Gets Dart entrypoint arguments from launch parameters.

#### Returns

`string`[]

Array of entrypoint arguments

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getDartEntrypointArgs`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getdartentrypointargs)

***

### getDartEntrypointFunctionName()

> **getDartEntrypointFunctionName**(): `string`

Gets the Dart entrypoint function name from launch parameters.

#### Returns

`string`

The entrypoint function name, or default if not set

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getDartEntrypointFunctionName`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getdartentrypointfunctionname)

***

### getDartEntrypointLibraryUri()

> **getDartEntrypointLibraryUri**(): `string`

Gets the Dart entrypoint library URI.

#### Returns

`string`

The library URI string

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getDartEntrypointLibraryUri`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getdartentrypointlibraryuri)

***

### getExclusiveAppComponent()

> **getExclusiveAppComponent**(): [`ExclusiveAppComponent`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md)\<`UIAbility`\>

Gets the exclusive app component.

#### Returns

[`ExclusiveAppComponent`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md)\<`UIAbility`\>

The ExclusiveAppComponent instance, or null

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getExclusiveAppComponent`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getexclusiveappcomponent)

***

### getFlutterAbilityAndEntryDelegate()

> **getFlutterAbilityAndEntryDelegate**(): [`FlutterAbilityAndEntryDelegate`](../../FlutterAbilityAndEntryDelegate/classes/FlutterAbilityAndEntryDelegate.md)

Gets the FlutterAbilityAndEntryDelegate instance.

#### Returns

[`FlutterAbilityAndEntryDelegate`](../../FlutterAbilityAndEntryDelegate/classes/FlutterAbilityAndEntryDelegate.md)

The delegate instance, or null if not available

***

### getFlutterEngine()

> **getFlutterEngine**(): `any`

Gets the FlutterEngine instance.

#### Returns

`any`

The FlutterEngine instance, or null if not available

***

### getFlutterShellArgs()

> **getFlutterShellArgs**(): `FlutterShellArgs`

Gets Flutter shell arguments from the Want.

#### Returns

`FlutterShellArgs`

A FlutterShellArgs instance

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getFlutterShellArgs`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getfluttershellargs)

***

### getFlutterView()

> **getFlutterView**(): [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

Gets the FlutterView instance.

#### Returns

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

The FlutterView instance, or null if not available

***

### getInitialRoute()

> **getInitialRoute**(): `string`

Gets the initial route from launch parameters.

#### Returns

`string`

The initial route string, or empty string if not set

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getInitialRoute`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getinitialroute)

***

### getWant()

> **getWant**(): `Want`

Gets the Want object.

#### Returns

`Want`

The launch Want instance

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getWant`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getwant)

***

### isDefaultFullScreen()

> **isDefaultFullScreen**(): `boolean`

Determines whether FlutterAbility should be full screen by default.
Can be overridden to customize full screen behavior.
Default value: based on device type, determines if full screen is needed.

#### Returns

`boolean`

True if full screen by default, false otherwise

***

### onBackground()

> **onBackground**(): `void`

Called when the ability goes to background.

#### Returns

`void`

***

### onConfigurationUpdate()

> **onConfigurationUpdate**(`config`): `void`

Called when configuration is updated.

#### Parameters

##### config

`Configuration`

The new configuration

#### Returns

`void`

***

### onCreate()

> **onCreate**(`want`, `launchParam`): `void`

Called when the ability is created.
1. Creates and attaches delegate
2. Configures windows (transparency not needed)
3. Handles lifecycle.onCreate
4. setContentView() not needed

#### Parameters

##### want

`Want`

The Want object

##### launchParam

`LaunchParam`

The launch parameters

#### Returns

`void`

***

### onDestroy()

> **onDestroy**(): `void`

Called when the ability is destroyed.
Cleans up resources and removes the ability from FlutterManager.

#### Returns

`void`

***

### onForeground()

> **onForeground**(): `void`

Called when the ability comes to foreground.

#### Returns

`void`

***

### onMemoryLevel()

> **onMemoryLevel**(`level`): `void`

Called when memory level changes.

#### Parameters

##### level

`MemoryLevel`

The memory level

#### Returns

`void`

***

### onNewWant()

> **onNewWant**(`want`, `launchParams`): `void`

Called when a new Want is received.

#### Parameters

##### want

`Want`

The new Want object

##### launchParams

`LaunchParam`

The launch parameters

#### Returns

`void`

***

### onSaveState()

> **onSaveState**(`reason`, `wantParam`): `OnSaveResult`

Called to save the ability state.

#### Parameters

##### reason

`StateType`

The reason for saving state

##### wantParam

`Record`\<`string`, `Object`\>

The parameters to save state to

#### Returns

`OnSaveResult`

The save result

***

### onWindowStageCreate()

> **onWindowStageCreate**(`windowStage`): `void`

Called when the window stage is created.

#### Parameters

##### windowStage

`WindowStage`

The WindowStage instance

#### Returns

`void`

***

### onWindowStageDestroy()

> **onWindowStageDestroy**(): `void`

Called when the window stage is destroyed.

#### Returns

`void`

***

### onWindowStageWillDestroy()

> **onWindowStageWillDestroy**(`windowStage`): `void`

Called when the window stage is about to be destroyed.

#### Parameters

##### windowStage

`WindowStage`

The WindowStage instance

#### Returns

`void`

***

### pagePath()

> **pagePath**(): `string`

Gets the page path for loading content.

#### Returns

`string`

The page path string

***

### popSystemNavigator()

> **popSystemNavigator**(): `boolean`

Determines whether to pop the system navigator.

#### Returns

`boolean`

False by default

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`popSystemNavigator`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#popsystemnavigator)

***

### provideFlutterEngine()

> **provideFlutterEngine**(`context`): `any`

Provides a FlutterEngine instance.

#### Parameters

##### context

`Context`

The context

#### Returns

`any`

A FlutterEngine instance, or null if not provided

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`provideFlutterEngine`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#provideflutterengine)

***

### providePlatformPlugin()

> **providePlatformPlugin**(`flutterEngine`): `any`

Provides a PlatformPlugin instance.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine instance

#### Returns

`any`

A PlatformPlugin instance

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`providePlatformPlugin`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#provideplatformplugin)

***

### provideSensitiveContentPlugin()

> **provideSensitiveContentPlugin**(`flutterEngine`): `any`

Provides a SensitiveContentPlugin instance.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine instance

#### Returns

`any`

A SensitiveContentPlugin instance

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`provideSensitiveContentPlugin`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#providesensitivecontentplugin)

***

### release()

> **release**(): `void`

Releases all held objects.

#### Returns

`void`

***

### removePlugin()

> **removePlugin**(`plugin`): `void`

Removes a Flutter plugin.

#### Parameters

##### plugin

[`FlutterPlugin`](../../../engine/plugins/FlutterPlugin/interfaces/FlutterPlugin.md)

The FlutterPlugin to remove

#### Returns

`void`

***

### shouldAttachEngineToAbility()

> **shouldAttachEngineToAbility**(): `boolean`

Determines whether to attach the engine to the ability.

#### Returns

`boolean`

True to attach the engine, false otherwise

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`shouldAttachEngineToAbility`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#shouldattachenginetoability)

***

### shouldDestroyEngineWithHost()

> **shouldDestroyEngineWithHost**(): `boolean`

Determines whether to destroy the engine when the host is destroyed.

#### Returns

`boolean`

True to destroy the engine, false otherwise

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`shouldDestroyEngineWithHost`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#shoulddestroyenginewithhost)

***

### shouldDispatchAppLifecycleState()

> **shouldDispatchAppLifecycleState**(): `boolean`

Determines whether to dispatch app lifecycle state changes.

#### Returns

`boolean`

True to dispatch lifecycle state, false otherwise

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`shouldDispatchAppLifecycleState`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#shoulddispatchapplifecyclestate)

***

### shouldRestoreAndSaveState()

> **shouldRestoreAndSaveState**(): `boolean`

Determines whether to restore and save state.

#### Returns

`boolean`

True to restore and save state, false otherwise

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`shouldRestoreAndSaveState`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#shouldrestoreandsavestate)

***

### windowStageEventCallback()

> `protected` **windowStageEventCallback**(`data`): `void`

#### Parameters

##### data

`WindowStageEventType`

#### Returns

`void`
