[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: MethodResult

Method call result callback. Supports dual use: Implementations of methods to be invoked by
Flutter act as clients of this interface for sending results back to Flutter. Invokers of
Flutter methods provide implementations of this interface for handling results received from
Flutter.

All methods of this class can be invoked on any thread.

## Properties

### error()

> **error**: (`errorCode`, `errorMessage`, `errorDetails`) => `void`

Handles an error result.

#### Parameters

##### errorCode

`string`

An error code string

##### errorMessage

`string`

A human-readable error message, possibly null

##### errorDetails

`Any`

Error details, possibly null. The details must be an Object type
    supported by the codec. For instance, if you are using StandardMessageCodec
    (default), please see its documentation on what types are supported.

#### Returns

`void`

***

### notImplemented()

> **notImplemented**: () => `void`

Handles a call to an unimplemented method.

#### Returns

`void`

***

### success()

> **success**: (`result`) => `void`

Handles a successful result.

#### Parameters

##### result

`Any`

The result, possibly null. The result must be an Object type supported by the
    codec. For instance, if you are using StandardMessageCodec (default), please see
    its documentation on what types are supported.

#### Returns

`void`
