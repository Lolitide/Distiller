[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEngineConnectionRegistry

Registry for managing Flutter plugins and their connections to the engine and ability.
This class implements both PluginRegistry and AbilityControlSurface interfaces,
providing a unified way to manage plugin lifecycle and ability-related operations.

## Implements

- [`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md)
- [`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md)

## Constructors

### Constructor

> **new FlutterEngineConnectionRegistry**(`appContext`, `flutterEngine`, `flutterLoader`): `FlutterEngineConnectionRegistry`

Constructs a new FlutterEngineConnectionRegistry instance.

#### Parameters

##### appContext

`Context`

The application context

##### flutterEngine

`FlutterEngine`

The FlutterEngine instance this registry is associated with

##### flutterLoader

`FlutterLoader`

The FlutterLoader instance for asset management

#### Returns

`FlutterEngineConnectionRegistry`

## Methods

### add()

> **add**(`plugin`): `void`

Adds a plugin to this registry.

#### Parameters

##### plugin

[`FlutterPlugin`](../../plugins/FlutterPlugin/interfaces/FlutterPlugin.md)

The FlutterPlugin instance to add

#### Returns

`void`

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`add`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#add)

***

### addList()

> **addList**(`plugins`): `void`

Adds multiple plugins to this registry.

#### Parameters

##### plugins

`Set`\<[`FlutterPlugin`](../../plugins/FlutterPlugin/interfaces/FlutterPlugin.md)\>

Set of FlutterPlugin instances to add

#### Returns

`void`

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`addList`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#addlist)

***

### attachToAbility()

> **attachToAbility**(`exclusiveAbility`): `void`

Attaches this registry to an ability.

#### Parameters

##### exclusiveAbility

[`ExclusiveAppComponent`](../../../ohos/ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md)\<`UIAbility`\>

The exclusive app component (UIAbility) to attach to

#### Returns

`void`

#### Implementation of

[`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md).[`attachToAbility`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md#attachtoability)

***

### destroy()

> **destroy**(): `void`

Destroys this registry and removes all plugins.

#### Returns

`void`

***

### detachFromAbility()

> **detachFromAbility**(): `void`

Detaches this registry from the current ability.

#### Returns

`void`

#### Implementation of

[`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md).[`detachFromAbility`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md#detachfromability)

***

### get()

> **get**(`pluginClassName`): [`FlutterPlugin`](../../plugins/FlutterPlugin/interfaces/FlutterPlugin.md)

Gets a plugin by its class name.

#### Parameters

##### pluginClassName

`string`

The class name of the plugin to retrieve

#### Returns

[`FlutterPlugin`](../../plugins/FlutterPlugin/interfaces/FlutterPlugin.md)

The FlutterPlugin instance, or a default empty plugin if not found

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`get`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#get)

***

### has()

> **has**(`pluginClassName`): `boolean`

Checks if a plugin with the given class name is registered.

#### Parameters

##### pluginClassName

`string`

The class name of the plugin to check

#### Returns

`boolean`

true if the plugin is registered, false otherwise

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`has`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#has)

***

### onNewWant()

> **onNewWant**(`want`, `launchParams`): `void`

Handles a new Want event from the ability.

#### Parameters

##### want

`Want`

The Want object containing the intent

##### launchParams

`LaunchParam`

The launch parameters

#### Returns

`void`

#### Implementation of

[`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md).[`onNewWant`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md#onnewwant)

***

### onSaveState()

> **onSaveState**(`reason`, `wantParam`): `OnSaveResult`

Handles save state requests from the ability.

#### Parameters

##### reason

`StateType`

The reason for saving state

##### wantParam

`Record`\<`string`, `Object`\>

Parameters to save

#### Returns

`OnSaveResult`

The result of the save state operation

#### Implementation of

[`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md).[`onSaveState`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md#onsavestate)

***

### onWindowFocusChanged()

> **onWindowFocusChanged**(`hasFocus`): `void`

Handles window focus change events from the ability.

#### Parameters

##### hasFocus

`boolean`

Whether the window has focus

#### Returns

`void`

#### Implementation of

[`AbilityControlSurface`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md).[`onWindowFocusChanged`](../../plugins/ability/AbilityControlSurface/interfaces/AbilityControlSurface.md#onwindowfocuschanged)

***

### remove()

> **remove**(`pluginClassName`): `void`

Removes a plugin from this registry.

#### Parameters

##### pluginClassName

`string`

The class name of the plugin to remove

#### Returns

`void`

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`remove`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#remove)

***

### removeAll()

> **removeAll**(): `void`

Removes all plugins from this registry.

#### Returns

`void`

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`removeAll`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#removeall)

***

### removeList()

> **removeList**(`pluginClassNames`): `void`

Removes multiple plugins from this registry.

#### Parameters

##### pluginClassNames

`Set`\<`string`\>

Set of plugin class names to remove

#### Returns

`void`

#### Implementation of

[`PluginRegistry`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md).[`removeList`](../../plugins/PluginRegistry/interfaces/PluginRegistry.md#removelist)
