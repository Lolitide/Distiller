[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: FlutterPluginRegistry

Registry for managing Flutter plugins and platform views.
This class handles the lifecycle of FlutterView, Context, and PlatformViewController,
providing methods to attach, detach, and manage resources during engine restarts.

## Constructors

### Constructor

> **new FlutterPluginRegistry**(): `FlutterPluginRegistry`

Constructs a new FlutterPluginRegistry instance.
Initializes the platform views controller and sets FlutterView and Context to null.

#### Returns

`FlutterPluginRegistry`

## Methods

### attach()

> **attach**(`flutterView`, `context`): `void`

Attaches a FlutterView and Context to this registry.

#### Parameters

##### flutterView

[`FlutterView`](../../../view/FlutterView/classes/FlutterView.md)

The FlutterView instance to attach

##### context

`Context`

The application context to attach

#### Returns

`void`

***

### destroy()

> **destroy**(): `void`

Destroys this registry instance.
Notifies the platform views controller that it has been detached from NAPI.

#### Returns

`void`

***

### detach()

> **detach**(): `void`

Detaches the FlutterView and Context from this registry.
Cleans up the platform views controller and resets all references.

#### Returns

`void`

***

### onPreEngineRestart()

> **onPreEngineRestart**(): `void`

Called before the Flutter engine restarts.
Notifies the platform views controller to prepare for engine restart.

#### Returns

`void`
