[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: SensitiveContentChannel

A handler of incoming method calls.

## Implements

- [`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

## Constructors

### Constructor

> **new SensitiveContentChannel**(`dartExecutor`): `SensitiveContentChannel`

#### Parameters

##### dartExecutor

`DartExecutor`

#### Returns

`SensitiveContentChannel`

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

***

### setSensitiveContentMethodHandler()

> **setSensitiveContentMethodHandler**(`sensitiveContentMethodHandler`): `void`

Sets the [SensitiveContentMethodHandler](../interfaces/SensitiveContentMethodHandler.md) which receives all requests to get and set a
particular content sensitivity level sent through this channel.

#### Parameters

##### sensitiveContentMethodHandler

[`SensitiveContentMethodHandler`](../interfaces/SensitiveContentMethodHandler.md)

#### Returns

`void`
