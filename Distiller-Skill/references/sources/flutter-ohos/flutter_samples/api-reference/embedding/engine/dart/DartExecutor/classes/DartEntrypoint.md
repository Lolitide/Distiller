[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DartEntrypoint

Configuration options that specify which Dart entrypoint function is executed and where to find
that entrypoint and other assets required for Dart execution.

## Constructors

### Constructor

> **new DartEntrypoint**(`pathToBundle`, `dartEntrypointLibrary`, `dartEntrypointFunctionName`): `DartEntrypoint`

Constructs a new DartEntrypoint instance.

#### Parameters

##### pathToBundle

`string`

The path within the AssetManager where the app will look for assets

##### dartEntrypointLibrary

`string`

The library or file location that contains the Dart entrypoint function

##### dartEntrypointFunctionName

`string`

The name of a Dart function to execute

#### Returns

`DartEntrypoint`

## Properties

### dartEntrypointFunctionName

> **dartEntrypointFunctionName**: `string`

The name of a Dart function to execute.

***

### dartEntrypointLibrary

> **dartEntrypointLibrary**: `string`

The library or file location that contains the Dart entrypoint function.

***

### pathToBundle

> **pathToBundle**: `string`

The path within the ResourceManager where the app will look for assets.

## Methods

### createDefault()

> `static` **createDefault**(): `DartEntrypoint`

Creates a default DartEntrypoint using the main function.

#### Returns

`DartEntrypoint`

A DartEntrypoint configured with the default main entrypoint

#### Throws

Error if FlutterLoader is not initialized
