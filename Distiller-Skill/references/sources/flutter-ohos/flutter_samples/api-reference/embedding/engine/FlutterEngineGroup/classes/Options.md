[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: Options

Options that control how a FlutterEngine should be created..

## Constructors

### Constructor

> **new Options**(`context`): `Options`

Constructs a new Options instance.

#### Parameters

##### context

`Context`

The application context

#### Returns

`Options`

## Methods

### getContext()

> **getContext**(): `Context`

Gets the application context.

#### Returns

`Context`

The context

***

### getDartEntrypoint()

> **getDartEntrypoint**(): [`DartEntrypoint`](../../dart/DartExecutor/classes/DartEntrypoint.md)

Gets the Dart entrypoint configuration.

#### Returns

[`DartEntrypoint`](../../dart/DartExecutor/classes/DartEntrypoint.md)

The DartEntrypoint, or null if not set

***

### getDartEntrypointArgs()

> **getDartEntrypointArgs**(): `string`[]

Gets the Dart entrypoint arguments.

#### Returns

`string`[]

Array of entrypoint arguments

***

### getInitialRoute()

> **getInitialRoute**(): `string`

Gets the initial route for navigation.

#### Returns

`string`

The initial route string

***

### getPlatformViewsController()

> **getPlatformViewsController**(): `any`

Gets the platform views controller.

#### Returns

`any`

The PlatformViewsController, or null if not set

***

### getWaitForRestorationData()

> **getWaitForRestorationData**(): `boolean`

Gets whether to wait for restoration data.

#### Returns

`boolean`

true if waiting for restoration data, false otherwise

***

### setDartEntrypoint()

> **setDartEntrypoint**(`dartEntrypoint`): `Options`

Sets the Dart entrypoint configuration.

#### Parameters

##### dartEntrypoint

[`DartEntrypoint`](../../dart/DartExecutor/classes/DartEntrypoint.md)

The DartEntrypoint to set

#### Returns

`Options`

This Options instance for method chaining

***

### setDartEntrypointArgs()

> **setDartEntrypointArgs**(`dartEntrypointArgs`): `Options`

Sets the Dart entrypoint arguments.

#### Parameters

##### dartEntrypointArgs

`string`[]

Array of entrypoint arguments

#### Returns

`Options`

This Options instance for method chaining

***

### setInitialRoute()

> **setInitialRoute**(`initialRoute`): `Options`

Sets the initial route for navigation.

#### Parameters

##### initialRoute

`string`

The initial route string

#### Returns

`Options`

This Options instance for method chaining

***

### setPlatformViewsController()

> **setPlatformViewsController**(`platformViewsController`): `Options`

Sets the platform views controller.

#### Parameters

##### platformViewsController

`PlatformViewsController`

The PlatformViewsController to set

#### Returns

`Options`

This Options instance for method chaining

***

### setWaitForRestorationData()

> **setWaitForRestorationData**(`waitForRestorationData`): `Options`

Sets whether to wait for restoration data.

#### Parameters

##### waitForRestorationData

`boolean`

Whether to wait for restoration data

#### Returns

`Options`

This Options instance for method chaining
