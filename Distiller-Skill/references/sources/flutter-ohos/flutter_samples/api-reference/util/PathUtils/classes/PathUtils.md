[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: PathUtils

Utility class for path operations in OpenHarmony.
Provides methods for getting application directories.

## Constructors

### Constructor

> **new PathUtils**(): `PathUtils`

#### Returns

`PathUtils`

## Methods

### getCacheDirectory()

> `static` **getCacheDirectory**(`context`): `string`

Gets the cache directory for the application.

#### Parameters

##### context

`Context`

The application context

#### Returns

`string`

The cache directory path.

***

### getDataDirectory()

> `static` **getDataDirectory**(`context`): `string`

Gets or creates the Flutter data directory.

#### Parameters

##### context

`Context`

The application context

#### Returns

`string`

The Flutter data directory path, or null if creation fails.

***

### getFilesDir()

> `static` **getFilesDir**(`context`): `string`

Gets the files directory for the application.

#### Parameters

##### context

`Context`

The application context

#### Returns

`string`

The files directory path.
