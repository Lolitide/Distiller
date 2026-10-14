[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: PluginRegistry

Registry for managing Flutter plugins.
This interface provides methods to add, remove, and query plugins attached to a FlutterEngine.

## Methods

### add()

> **add**(`plugin`): `void`

Attaches the given plugin to the FlutterEngine associated with this PluginRegistry.

#### Parameters

##### plugin

[`FlutterPlugin`](../../FlutterPlugin/interfaces/FlutterPlugin.md)

The FlutterPlugin to attach

#### Returns

`void`

***

### addList()

> **addList**(`plugins`): `void`

Attaches the given plugins to the FlutterEngine associated with this PluginRegistry.

#### Parameters

##### plugins

`Set`\<[`FlutterPlugin`](../../FlutterPlugin/interfaces/FlutterPlugin.md)\>

The set of FlutterPlugins to attach

#### Returns

`void`

***

### get()

> **get**(`pluginClassName`): [`FlutterPlugin`](../../FlutterPlugin/interfaces/FlutterPlugin.md)

Gets the instance of a plugin that is currently attached to the FlutterEngine
associated with this PluginRegistry, which matches the given pluginClassName.

If no matching plugin is found, null is returned.

#### Parameters

##### pluginClassName

`string`

The class name of the plugin to get

#### Returns

[`FlutterPlugin`](../../FlutterPlugin/interfaces/FlutterPlugin.md)

The FlutterPlugin instance, or null if not found

***

### has()

> **has**(`pluginClassName`): `boolean`

Checks if a plugin of the given type is currently attached to the FlutterEngine
associated with this PluginRegistry.

#### Parameters

##### pluginClassName

`string`

The class name of the plugin to check

#### Returns

`boolean`

True if the plugin is attached, false otherwise

***

### remove()

> **remove**(`pluginClassName`): `void`

Detaches the plugin of the given type from the FlutterEngine
associated with this PluginRegistry.

If no such plugin exists, this method does nothing.

#### Parameters

##### pluginClassName

`string`

The class name of the plugin to remove

#### Returns

`void`

***

### removeAll()

> **removeAll**(): `void`

Detaches all plugins that are currently attached to the FlutterEngine
associated with this PluginRegistry.

If no plugins are currently attached, this method does nothing.

#### Returns

`void`

***

### removeList()

> **removeList**(`pluginClassNames`): `void`

Detaches the plugins of the given types from the FlutterEngine
associated with this PluginRegistry.

If no such plugins exist, this method does nothing.

#### Parameters

##### pluginClassNames

`Set`\<`string`\>

The set of plugin class names to remove

#### Returns

`void`
