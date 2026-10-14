[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: PlatformViewsChannel

System channel that sends 2-way communication between Flutter and OpenHarmony to facilitate
embedding of OpenHarmony Views within a Flutter application.

Implement PlatformViewsHandler and register it via setPlatformViewsHandler() to implement
the OpenHarmony side of this channel.

## Constructors

### Constructor

> **new PlatformViewsChannel**(`dartExecutor`): `PlatformViewsChannel`

Constructs a PlatformViewsChannel that connects OpenHarmony to the Dart
code running in dartExecutor.

The given dartExecutor is permitted to be idle or executing code.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`PlatformViewsChannel`

## Methods

### clearFocus()

> **clearFocus**(`call`, `result`): `void`

Handles platform view focus clearing requests.

#### Parameters

##### call

`MethodCall`

The method call containing the view ID

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### create()

> **create**(`call`, `result`): `void`

Handles platform view creation requests.

#### Parameters

##### call

`MethodCall`

The method call containing creation parameters

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### dispose()

> **dispose**(`call`, `result`): `void`

Handles platform view disposal requests.

#### Parameters

##### call

`MethodCall`

The method call containing the view ID to dispose

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### hover()

> **hover**(`call`, `result`): `void`

Handles hover events on platform views.

#### Parameters

##### call

`MethodCall`

The method call containing the view ID

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### invokeViewFocused()

> **invokeViewFocused**(`viewId`): `void`

Notifies Flutter that a platform view has gained focus.

#### Parameters

##### viewId

`number`

The ID of the platform view that gained focus

#### Returns

`void`

***

### offset()

> **offset**(`call`, `result`): `void`

Handles platform view offset change requests.

#### Parameters

##### call

`MethodCall`

The method call containing offset parameters

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### resize()

> **resize**(`call`, `result`): `void`

Handles platform view resize requests.

#### Parameters

##### call

`MethodCall`

The method call containing resize parameters

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### setDirection()

> **setDirection**(`call`, `result`): `void`

Handles platform view direction change requests.

#### Parameters

##### call

`MethodCall`

The method call containing direction parameters

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### setPlatformViewsHandler()

> **setPlatformViewsHandler**(`handler`): `void`

Sets the PlatformViewsHandler which receives all events and requests that are parsed
from the underlying platform views channel.

#### Parameters

##### handler

[`PlatformViewsHandler`](../interfaces/PlatformViewsHandler.md)

The PlatformViewsHandler instance, or null to remove

#### Returns

`void`

***

### synchronizeToNativeViewHierarchy()

> **synchronizeToNativeViewHierarchy**(`call`, `result`): `void`

Handles requests to synchronize to native view hierarchy.

#### Parameters

##### call

`MethodCall`

The method call containing synchronization parameters

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

***

### touch()

> **touch**(`call`, `result`): `void`

Handles touch events on platform views.

#### Parameters

##### call

`MethodCall`

The method call containing touch event data

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`
