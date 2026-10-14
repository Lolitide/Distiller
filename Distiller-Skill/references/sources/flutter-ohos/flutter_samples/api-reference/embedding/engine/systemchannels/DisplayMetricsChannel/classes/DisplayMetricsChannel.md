[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DisplayMetricsChannel

System channel (`flutter/displaymetrics`) for display-metric requests from Flutter to the OpenHarmony embedding.
Construct it while wiring the engine so Dart can send DPI scale updates that the embedding applies through
`Context.eventHub` and [`FlutterView`](../../../../../view/FlutterView/classes/FlutterView.md).

## Supported methods (Dart → embedding)

| Method | Purpose |
| --- | --- |
| `updateDpiScale` | Argument `dpiScale` (number). Emits `changeDevicePixelRatio` on `context.eventHub`; [`FlutterView`](../../../../../view/FlutterView/classes/FlutterView.md) consumes this in `onDevicePixelRatioChange` to refresh viewport metrics. |
| *(any other name)* | `notImplemented` |

Additional methods may be added to the `onMethodCall` switch as the framework evolves.

## Example

```typescript
// Typical: construct when wiring the engine; context must be the ability/application Context with eventHub.
const displayMetricsChannel = new DisplayMetricsChannel(dartExecutor, context);
// Handler is registered in the constructor; Flutter then invokes methods such as updateDpiScale on
// flutter/displaymetrics automatically.
```

## Implements

- [`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

## Constructors

### Constructor

> **new DisplayMetricsChannel**(`dartExecutor`, `context`): `DisplayMetricsChannel`

#### Parameters

##### dartExecutor

`DartExecutor`

##### context

`Context`

#### Returns

`DisplayMetricsChannel`

## Properties

### channel

> **channel**: `MethodChannel`

***

### context

> **context**: `Context`

## Methods

### onMethodCall()

> **onMethodCall**(`call`, `result`): `void`

Handles the specified method call received from Flutter.

Handler implementations must submit a result for all incoming calls, by making a single
call on the given [MethodResult](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md) callback. Failure to do so will result in lingering Flutter
result handlers. The result may be submitted asynchronously and on any thread. Calls to
unknown or unimplemented methods should be handled using the notImplemented method of [MethodResult](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md).

Any uncaught exception thrown by this method will be caught by the channel implementation
and logged, and an error result will be sent back to Flutter.

The handler is called on the platform thread (OpenHarmony main thread) by default, or otherwise on the thread
specified by the TaskQueue provided to the associated [MethodChannel](../../../../../plugin/common/MethodChannel/classes/MethodChannel.md) when it was created.

#### Parameters

##### call

`MethodCall`

A MethodCall

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

A [MethodResult](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md) used for submitting the result of the call

#### Returns

`void`

#### Implementation of

[`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md).[`onMethodCall`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md#onmethodcall)
