[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEnginePreload

Utility class for preloading Flutter engines.
This class provides static methods to preload and prepare Flutter engines
before they are actually displayed, improving startup performance.

## Constructors

### Constructor

> **new FlutterEnginePreload**(): `FlutterEnginePreload`

#### Returns

`FlutterEnginePreload`

## Methods

### predrawEngine()

> `static` **predrawEngine**(`engine`, `params`, `nextViewId`): `void`

Prepares an existing engine for drawing by setting up viewport metrics and pre-drawing.

#### Parameters

##### engine

`FlutterEngine`

The FlutterEngine instance to prepare

##### params

`Record`\<`string`, `Object`\> = `{}`

Parameters for engine preparation, including viewport metrics

##### nextViewId

`string` = `null`

Optional view ID for the next Flutter view

#### Returns

`void`

***

### preloadEngine()

> `static` **preloadEngine**(`context`, `params`, `nextViewId`): `Promise`\<`void`\>

Preloads a Flutter engine with the specified parameters.

#### Parameters

##### context

`Context`

The application context

##### params

`Record`\<`string`, `Object`\> = `{}`

Parameters for engine preloading, including entrypoint, route, etc.

##### nextViewId

`string` = `null`

Optional view ID for the next Flutter view

#### Returns

`Promise`\<`void`\>

***

### preLoadFlutterNapi()

> `static` **preLoadFlutterNapi**(`context`, `bundlePath`, `params`): `any`

Preloads a FlutterNapi instance with the specified configuration.

#### Parameters

##### context

`Context`

The application context

##### bundlePath

`string`

Path to the Flutter bundle

##### params

`Record`\<`string`, `Object`\> = `{}`

Parameters for NAPI preloading, including cached engine ID, entrypoint, etc.

#### Returns

`any`

The preloaded FlutterNapi instance, or null if preloading fails
