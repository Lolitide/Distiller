[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DartCallback

Configuration options that specify which Dart callback function is executed and where to find
that callback and other assets required for Dart execution.

## Constructors

### Constructor

> **new DartCallback**(`resourceManager`, `pathToBundle`, `callbackHandle`): `DartCallback`

Constructs a new DartCallback instance.

#### Parameters

##### resourceManager

`ResourceManager`

Standard OpenHarmony ResourceManager

##### pathToBundle

`string`

The path within the ResourceManager where the app will look for assets

##### callbackHandle

[`FlutterCallbackInformation`](../../../../../view/FlutterCallbackInformation/classes/FlutterCallbackInformation.md)

A Dart callback that was previously registered with the Dart VM

#### Returns

`DartCallback`

## Properties

### callbackHandle

> **callbackHandle**: [`FlutterCallbackInformation`](../../../../../view/FlutterCallbackInformation/classes/FlutterCallbackInformation.md)

A Dart callback that was previously registered with the Dart VM.

***

### pathToBundle

> **pathToBundle**: `string`

The path within the ResourceManager where the app will look for assets.

***

### resourceManager

> **resourceManager**: `ResourceManager`

Standard OpenHarmony ResourceManager for accessing assets.

## Methods

### toString()

> **toString**(): `String`

Returns a string representation of this DartCallback.

#### Returns

`String`

A string describing the callback's bundle path, library path, and function name
