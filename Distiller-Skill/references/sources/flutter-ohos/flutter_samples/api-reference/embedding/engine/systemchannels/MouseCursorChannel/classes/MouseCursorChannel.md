[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: MouseCursorChannel

Channel for handling mouse cursor changes.
This channel manages communication between Flutter and OpenHarmony for cursor appearance changes.

## Implements

- [`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

## Constructors

### Constructor

> **new MouseCursorChannel**(`dartExecutor`): `MouseCursorChannel`

Constructs a new MouseCursorChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`MouseCursorChannel`

## Properties

### channel

> **channel**: `MethodChannel`

The MethodChannel for mouse cursor communication with Flutter.

## Methods

### onMethodCall()

> **onMethodCall**(`call`, `result`): `void`

Handles method calls from Dart.

#### Parameters

##### call

`MethodCall`

The method call from Dart

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

#### Implementation of

[`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md).[`onMethodCall`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md#onmethodcall)

***

### setMethodHandler()

> **setMethodHandler**(`mouseCursorMethodHandler`): `void`

Sets the MouseCursorMethodHandler which receives all events and requests that are
parsed from the underlying platform channel.

#### Parameters

##### mouseCursorMethodHandler

[`MouseCursorMethodHandler`](../interfaces/MouseCursorMethodHandler.md)

The MouseCursorMethodHandler instance, or null to remove

#### Returns

`void`

***

### synthesizeMethodCall()

> **synthesizeMethodCall**(`call`, `result`): `void`

Synthesizes a method call for testing purposes.

#### Parameters

##### call

`MethodCall`

The method call to synthesize

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`
