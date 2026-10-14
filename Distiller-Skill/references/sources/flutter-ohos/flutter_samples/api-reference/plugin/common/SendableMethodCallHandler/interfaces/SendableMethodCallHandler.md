[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: SendableMethodCallHandler

Interface for sendable method call handlers that can be used in background threads.
This interface extends ISendable to allow handlers to be passed across thread boundaries.

## Extends

- `ISendable`

## Methods

### onMethodCall()

> **onMethodCall**(`call`, `result`, ...`args`): `void`

Handles the specified method call received from Flutter.

Handler implementations must submit a result for all incoming calls, by making a single
call on the given [MethodResult](../../MethodChannel/interfaces/MethodResult.md) callback. Failure to do so will result in lingering Flutter
result handlers. The result may be submitted asynchronously and on any thread. Calls to
unknown or unimplemented methods should be handled using [()](../../MethodChannel/interfaces/MethodResult.md#notimplemented).

Any uncaught exception thrown by this method will be caught by the channel implementation
and logged, and an error result will be sent back to Flutter.

The handler is called on the platform thread (OpenHarmony main thread) by default, or
otherwise on the thread specified by the BinaryMessenger.TaskQueue provided to the
associated MethodChannel when it was created.

#### Parameters

##### call

`MethodCall`

A MethodCall

##### result

[`MethodResult`](../../MethodChannel/interfaces/MethodResult.md)

A [MethodResult](../../MethodChannel/interfaces/MethodResult.md) used for submitting the result of the call

##### args

...`Object`[]

Additional arguments

#### Returns

`void`
