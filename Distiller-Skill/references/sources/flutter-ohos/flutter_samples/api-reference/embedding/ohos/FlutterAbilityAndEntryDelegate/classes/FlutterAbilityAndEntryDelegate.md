[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterAbilityAndEntryDelegate

Delegate for managing FlutterAbility and FlutterEntry lifecycle.
Main responsibilities:
1. Initializes the Flutter engine
2. Handles ability lifecycle callbacks

## Implements

- [`ExclusiveAppComponent`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md)\<`UIAbility`\>

## Constructors

### Constructor

> **new FlutterAbilityAndEntryDelegate**(`host?`): `FlutterAbilityAndEntryDelegate`

Constructs a new FlutterAbilityAndEntryDelegate instance.

#### Parameters

##### host?

[`Host`](../interfaces/Host.md)

The Host instance, optional

#### Returns

`FlutterAbilityAndEntryDelegate`

## Properties

### context?

> `protected` `optional` **context**: `Context`

***

### flutterEngine?

> `optional` **flutterEngine**: `any`

The FlutterEngine instance, or null if not created.

***

### host?

> `protected` `optional` **host**: [`Host`](../interfaces/Host.md)

***

### isAttached

> **isAttached**: `boolean` = `false`

Whether the delegate is still attached to the ability.

***

### isFlutterEngineFromHostOrCache

> `protected` **isFlutterEngineFromHostOrCache**: `boolean` = `false`

***

### platformPlugin?

> `optional` **platformPlugin**: `PlatformPlugin`

The PlatformPlugin instance, or undefined if not set.

***

### sensitiveContentPlugin?

> `optional` **sensitiveContentPlugin**: `SensitiveContentPlugin`

## Methods

### addEntrypointOptions()

> **addEntrypointOptions**(`options`): [`Options`](../../../engine/FlutterEngineGroup/classes/Options.md)

Adds entrypoint options to the engine options.

#### Parameters

##### options

[`Options`](../../../engine/FlutterEngineGroup/classes/Options.md)

The Options instance to configure

#### Returns

[`Options`](../../../engine/FlutterEngineGroup/classes/Options.md)

The configured Options instance

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

### changeColorMode()

> **changeColorMode**(`colorMode?`): `void`

#### Parameters

##### colorMode?

`ColorMode`

#### Returns

`void`

***

### createView()

> **createView**(`context`): [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

Creates a FlutterView instance.

#### Parameters

##### context

`Context`

The context for creating the view

#### Returns

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

A new FlutterView instance

***

### detachFromFlutterEngine()

> **detachFromFlutterEngine**(): `void`

Detaches from the Flutter engine.

#### Returns

`void`

#### Throws

Error if the engine should not be detached

#### Implementation of

[`ExclusiveAppComponent`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md).[`detachFromFlutterEngine`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md#detachfromflutterengine)

***

### ensureAlive()

> **ensureAlive**(): `void`

Ensures the delegate is still alive.

#### Returns

`void`

#### Throws

Error if the delegate has been destroyed

***

### getAppComponent()

> **getAppComponent**(): `UIAbility`

Gets the app component (UIAbility).

#### Returns

`UIAbility`

The UIAbility instance

#### Throws

Error if the ability is null

#### Implementation of

[`ExclusiveAppComponent`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md).[`getAppComponent`](../../ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md#getappcomponent)

***

### getFlutterEngine()

> **getFlutterEngine**(): `any`

Gets the FlutterEngine instance.

#### Returns

`any`

The FlutterEngine instance, or null if not available

***

### getFlutterNapi()

> **getFlutterNapi**(): `any`

Gets the FlutterNapi instance.

#### Returns

`any`

The FlutterNapi instance, or null if not available

***

### initWindow()

> **initWindow**(): `void`

Initializes the window.

#### Returns

`void`

***

### isFlutterEngineFromHost()

> **isFlutterEngineFromHost**(): `boolean`

Checks if the FlutterEngine was provided by the host or cache.

#### Returns

`boolean`

True if from host or cache, false if created by delegate

***

### onAttach()

> **onAttach**(`context`): `void`

Called when the delegate is attached to a context.

#### Parameters

##### context

`Context`

The application context

#### Returns

`void`

***

### onCheckAndReloadFont()

> **onCheckAndReloadFont**(): `void`

Checks and reloads fonts if needed.

#### Returns

`void`

***

### onDetach()

> **onDetach**(): `void`

Called when the delegate is detached from the ability.
Cleans up resources and optionally destroys the engine.

#### Returns

`void`

***

### onHide()

> **onHide**(): `void`

Called when the ability is hidden.
Notifies Flutter that the app is paused.

#### Returns

`void`

***

### onLowMemory()

> **onLowMemory**(): `void`

Called when the system is running low on memory.
Notifies Flutter about the memory pressure.

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

### onPaused()

> **onPaused**(): `void`

Called when the ability is paused.
Notifies Flutter that the app is inactive.

#### Returns

`void`

***

### onRestoreInstanceState()

> **onRestoreInstanceState**(`want`): `void`

Configures the FlutterEngine through parameters.

#### Parameters

##### want

`Want`

The Want object containing restoration data

#### Returns

`void`

***

### onResumed()

> **onResumed**(): `void`

Called when the ability is resumed.
Notifies Flutter that the app is resumed.

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

### onShow()

> **onShow**(): `void`

Called when the ability is shown.
Notifies Flutter that the app is resumed.

#### Returns

`void`

***

### onWindowFocusChanged()

> **onWindowFocusChanged**(`hasFocus`): `void`

Called when window focus changes.

#### Parameters

##### hasFocus

`boolean`

Whether the window has focus

#### Returns

`void`

***

### onWindowStageChanged()

> **onWindowStageChanged**(`stageEventType`): `void`

Called when the window stage state changes.

#### Parameters

##### stageEventType

`WindowStageEventType`

The window stage event type

#### Returns

`void`

***

### onWindowStageCreate()

> **onWindowStageCreate**(): `void`

Called when the window stage is created.
Runs the initial Flutter view.

#### Returns

`void`

***

### onWindowStageDestroy()

> **onWindowStageDestroy**(): `void`

Called when the window stage is destroyed.

#### Returns

`void`

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

### setupFlutterEngine()

> **setupFlutterEngine**(): `void`

Initializes the FlutterEngine.
Checks for cached engines, engine groups, or creates a new engine.

#### Returns

`void`

***

### shouldDispatchAppLifecycleState()

> **shouldDispatchAppLifecycleState**(): `boolean`

Determines whether to dispatch app lifecycle state changes.

#### Returns

`boolean`

True to dispatch lifecycle state, false otherwise
