[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: FlutterPlugin

Interface to be implemented by all Flutter plugins.

A Flutter plugin allows Flutter developers to interact with a host platform, e.g., OpenHarmony,
via Dart code. It includes platform code, as well as Dart code. A plugin author is responsible
for setting up an appropriate MethodChannel to communicate between platform code and Dart code.

A Flutter plugin has a lifecycle. First, a developer must add a FlutterPlugin to an instance
of FlutterEngine. To do this, obtain a PluginRegistry with FlutterEngine.getPlugins(), then call
PluginRegistry.add(FlutterPlugin), passing the instance of the Flutter plugin. During the call
to PluginRegistry.add(FlutterPlugin), the FlutterEngine will invoke onAttachedToEngine(FlutterPluginBinding)
on the given FlutterPlugin. If the FlutterPlugin is removed from the FlutterEngine via
PluginRegistry.remove(pluginClassName), or if the FlutterEngine is destroyed, the FlutterEngine will invoke
onDetachedFromEngine(FlutterPluginBinding) on the given FlutterPlugin.

Once a FlutterPlugin is attached to a FlutterEngine, the plugin's code is permitted to access
and invoke methods on resources within the FlutterPlugin.FlutterPluginBinding that the FlutterEngine
gave to the FlutterPlugin in onAttachedToEngine(FlutterPluginBinding). This includes, for example,
the application Context for the running app.

The FlutterPlugin.FlutterPluginBinding provided in onAttachedToEngine(FlutterPluginBinding) is
no longer valid after the execution of onDetachedFromEngine(FlutterPluginBinding). Do not access
any properties of the FlutterPlugin.FlutterPluginBinding after the completion of
onDetachedFromEngine(FlutterPluginBinding).

To register a MethodChannel, obtain a BinaryMessenger via the FlutterPlugin.FlutterPluginBinding.

An OpenHarmony Flutter plugin may require access to app resources or other artifacts that can only
be retrieved through a Context. Developers can access the application context via
FlutterPlugin.FlutterPluginBinding.getApplicationContext().

Some plugins may require access to the UIAbility that is displaying a Flutter experience, or
may need to react to UIAbility lifecycle events, e.g., onCreate(), onWindowStageCreate(), onForeground(),
onBackground(), onWindowStageDestroy(), onDestroy(). Any such plugin should implement AbilityAware
in addition to implementing FlutterPlugin. AbilityAware provides callback hooks that expose access
to an associated UIAbility and its Lifecycle. All plugins must respect the possibility that a Flutter
experience may never be associated with a UIAbility, e.g., when Flutter is used for background
behavior. Additionally, all plugins must respect that UIAbilities may come and go over time, thus
requiring plugins to cleanup resources and recreate those resources as the UIAbility comes and goes.

## Methods

### getUniqueClassName()

> **getUniqueClassName**(): `string`

Gets the unique class name of this plugin.
Similar to Android's Class<? extends FlutterPlugin>, but in TypeScript this must be user-defined.

#### Returns

`string`

The unique class name of this plugin

***

### onAttachedToEngine()

> **onAttachedToEngine**(`binding`): `void`

This FlutterPlugin has been associated with a FlutterEngine instance.

Relevant resources that this FlutterPlugin may need are provided via the binding.
The binding may be cached and referenced until onDetachedFromEngine is invoked and returns.

#### Parameters

##### binding

[`FlutterPluginBinding`](../classes/FlutterPluginBinding.md)

The FlutterPluginBinding providing access to engine resources

#### Returns

`void`

***

### onDetachedFromEngine()

> **onDetachedFromEngine**(`binding`): `void`

This FlutterPlugin has been removed from a FlutterEngine instance.

The binding passed to this method is the same instance that was passed in
onAttachedToEngine. It is provided again in this method as a convenience.
The binding may be referenced during the execution of this method, but it
must not be cached or referenced after this method returns.

FlutterPlugins should release all resources in this method.

#### Parameters

##### binding

[`FlutterPluginBinding`](../classes/FlutterPluginBinding.md)

The FlutterPluginBinding that was provided in onAttachedToEngine

#### Returns

`void`
