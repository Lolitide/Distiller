[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterLoader

FlutterLoader is responsible for starting the Dart VM and loading Dart code.
This class locates Flutter resources in the HAP package and loads the Flutter native library.
It handles initialization, resource copying, and Dart VM configuration.

## Constructors

### Constructor

> **new FlutterLoader**(`flutterNapi`): `FlutterLoader`

Constructs a new FlutterLoader instance.

#### Parameters

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

#### Returns

`FlutterLoader`

## Properties

### context

> **context**: `any` = `null`

The application context for accessing resources.

***

### flutterApplicationInfo

> **flutterApplicationInfo**: `any` = `null`

Flutter application information including asset paths and build mode.

***

### flutterNapi

> **flutterNapi**: `FlutterNapi`

The FlutterNapi instance for native communication.

***

### initialized

> **initialized**: `boolean` = `false`

Whether the FlutterLoader has been initialized.

***

### initResult

> **initResult**: `InitResult` = `null`

Initialization result containing paths for app storage, engine caches, and data directory.

***

### initStartTimestampMillis

> **initStartTimestampMillis**: `number` = `0`

Timestamp when initialization started.

***

### isEnableImpeller

> **isEnableImpeller**: `boolean` = `false`

Whether Impeller rendering backend is enabled.

## Methods

### ensureInitializationComplete()

> **ensureInitializationComplete**(`shellArgs`): `void`

Ensures that Dart VM initialization is complete.
This method initializes the Dart VM with the appropriate shell arguments
based on the build mode (debug, profile, or release).

#### Parameters

##### shellArgs

`string`[]

Optional array of shell arguments, will be created if null

#### Returns

`void`

***

### findAppBundlePath()

> **findAppBundlePath**(): `string`

Finds the path to the Flutter app bundle.

#### Returns

`string`

The path to the Flutter assets directory, or empty string if not initialized

***

### fullAssetPathFrom()

> **fullAssetPathFrom**(`filePath`): `string`

Gets the full asset path from a relative file path.

#### Parameters

##### filePath

`string`

The relative file path

#### Returns

`string`

The full asset path, or empty string if not initialized

***

### getLookupKeyForAsset()

> **getLookupKeyForAsset**(`asset`, `packageName?`): `string`

Gets the lookup key for an asset file.

#### Parameters

##### asset

`string`

The asset file path

##### packageName?

`string`

Optional package name for package-specific assets

#### Returns

`string`

The full asset path lookup key

***

### isInitialized()

> **isInitialized**(): `boolean`

Checks if the FlutterLoader has been initialized.

#### Returns

`boolean`

true if initialized, false otherwise

***

### startInitialization()

> **startInitialization**(`context`): `void`

Starts initialization of the native system.

This loads the Flutter engine's native library to enable subsequent NAPI calls. This also
starts locating and unpacking Dart resources packaged in the app's HAP.

Calling this method multiple times has no effect.

#### Parameters

##### context

`Context`

The OpenHarmony application context

#### Returns

`void`
