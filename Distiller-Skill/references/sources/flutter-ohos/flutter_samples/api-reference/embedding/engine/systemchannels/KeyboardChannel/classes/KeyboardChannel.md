[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: KeyboardChannel

Channel for handling keyboard-related communication between Flutter and OpenHarmony.
This channel manages keyboard state queries and keyboard method calls.

## Implements

- [`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

## Constructors

### Constructor

> **new KeyboardChannel**(`dartExecutor`): `KeyboardChannel`

Constructs a new KeyboardChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`KeyboardChannel`

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

### setKeyboardMethodHandler()

> **setKeyboardMethodHandler**(`keyboardMessageHandler`): `void`

Sets the keyboard method handler for processing keyboard-related requests.

#### Parameters

##### keyboardMessageHandler

[`KeyboardMethodHandler`](../interfaces/KeyboardMethodHandler.md)

The KeyboardMethodHandler instance, or null to remove

#### Returns

`void`
