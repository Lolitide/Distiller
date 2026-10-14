[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: NativeVsyncChannel

Channel for handling native VSync functionality.
This channel manages VSync switching, animation velocity voting, and LTPO switch state checking.

## Implements

- [`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

## Constructors

### Constructor

> **new NativeVsyncChannel**(`dartExecutor`, `flutterNapi`): `NativeVsyncChannel`

Constructs a new NativeVsyncChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

#### Returns

`NativeVsyncChannel`

## Properties

### channel

> **channel**: `MethodChannel`

The MethodChannel for native VSync communication with Flutter.

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
