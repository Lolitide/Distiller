[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEntry

Entry point for Flutter content in a page component.
This class manages the lifecycle of FlutterView and FlutterEngine within a page context.

## Implements

- [`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md)

## Constructors

### Constructor

> **new FlutterEntry**(`context`, `params`): `FlutterEntry`

Constructs a new FlutterEntry instance.

#### Parameters

##### context

`Context`

The page context

##### params

`Record`\<`string`, `Object`\> = `{}`

Optional parameters for configuration

#### Returns

`FlutterEntry`

## Properties

### callbackId

> `protected` **callbackId**: `number` = `undefined`

***

### context

> `protected` **context**: `Context`

***

### delegate

> `protected` **delegate**: [`FlutterAbilityAndEntryDelegate`](../../FlutterAbilityAndEntryDelegate/classes/FlutterAbilityAndEntryDelegate.md) = `null`

***

### engineConfigurator

> `protected` **engineConfigurator**: [`FlutterEngineConfigurator`](../../FlutterEngineConfigurator/interfaces/FlutterEngineConfigurator.md) = `null`

***

### flutterView

> `protected` **flutterView**: [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md) = `null`

***

### hasInit

> `protected` **hasInit**: `boolean` = `false`

***

### uiAbility

> `protected` **uiAbility**: `UIAbility` = `null`

***

### windowStage

> `protected` **windowStage**: `any` = `null`

## Methods

### aboutToAppear()

> **aboutToAppear**(): `void`

Called when the page is about to appear.
Initializes the Flutter delegate and view.

#### Returns

`void`

***

### aboutToDisappear()

> **aboutToDisappear**(): `void`

Called when the page is about to disappear.
Cleans up resources and detaches from the Flutter engine.

#### Returns

`void`

***

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

Gets the associated UIAbility.

#### Returns

`UIAbility`

The UIAbility instance

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

Gets the cached engine group ID from parameters.

#### Returns

`string`

The cached engine group ID, or null if not set

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getCachedEngineGroupId`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getcachedenginegroupid)

***

### getCachedEngineId()

> **getCachedEngineId**(): `string`

Gets the cached engine ID from parameters.

#### Returns

`string`

The cached engine ID, or empty string if not set

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getCachedEngineId`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getcachedengineid)

***

### getDartEntrypointArgs()

> **getDartEntrypointArgs**(): `string`[]

Gets Dart entrypoint arguments from parameters.

#### Returns

`string`[]

Array of entrypoint arguments

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getDartEntrypointArgs`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getdartentrypointargs)

***

### getDartEntrypointFunctionName()

> **getDartEntrypointFunctionName**(): `string`

Gets the Dart entrypoint function name from parameters.

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

### getFlutterEngine()

> **getFlutterEngine**(): `any`

Gets the FlutterEngine instance.

#### Returns

`any`

The FlutterEngine instance, or null if not available

***

### getFlutterShellArgs()

> **getFlutterShellArgs**(): `FlutterShellArgs`

Gets Flutter shell arguments.

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

The FlutterView instance

***

### getInitialRoute()

> **getInitialRoute**(): `string`

Gets the initial route from parameters.

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

A new Want instance

#### Implementation of

[`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md).[`getWant`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md#getwant)

***

### loadContent()

> **loadContent**(): `void`

Loads the page content.
This method is called by the framework.

#### Returns

`void`

***

### onBackPress()

> **onBackPress**(): `void`

Called when the back button is pressed.
Pops the current route in Flutter navigation.

#### Returns

`void`

***

### onPageHide()

> **onPageHide**(): `void`

Called when the page is hidden.
Notifies the delegate that the page is hidden.

#### Returns

`void`

***

### onPageShow()

> **onPageShow**(): `void`

Called when the page is shown.
Notifies the delegate that the page is visible.

#### Returns

`void`

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

### registerEnvironmentCallback()

> **registerEnvironmentCallback**(): `void`

Registers an environment callback to listen for configuration changes.

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

### setFlutterEngineConfigurator()

> **setFlutterEngineConfigurator**(`configurator`): `void`

Sets the Flutter engine configurator.

#### Parameters

##### configurator

[`FlutterEngineConfigurator`](../../FlutterEngineConfigurator/interfaces/FlutterEngineConfigurator.md)

The FlutterEngineConfigurator instance

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

### unregisterEnvironmentCallback()

> **unregisterEnvironmentCallback**(): `void`

Unregisters the environment callback.

#### Returns

`void`

***

### windowStageEventCallback()

> `protected` **windowStageEventCallback**(`data`): `void`

Callback for window stage events.

#### Parameters

##### data

`WindowStageEventType`

The window stage event type

#### Returns

`void`
