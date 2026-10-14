[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: SensitiveContentPlugin

## Implements

- [`SensitiveContentMethodHandler`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md)

## Constructors

### Constructor

> **new SensitiveContentPlugin**(`sensitiveContentChannel`): `SensitiveContentPlugin`

#### Parameters

##### sensitiveContentChannel

`SensitiveContentChannel`

#### Returns

`SensitiveContentPlugin`

## Methods

### destroy()

> **destroy**(): `void`

#### Returns

`void`

***

### getContentSensitivity()

> **getContentSensitivity**(): `number`

Returns the current content sensitivity level of a Flutter OpenHarmony View.

#### Returns

`number`

#### Implementation of

[`SensitiveContentMethodHandler`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md).[`getContentSensitivity`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md#getcontentsensitivity)

***

### isSupported()

> **isSupported**(): `boolean`

Returns whether or not setting/getting content sensitivity via OpenHarmony APIs is supported on
the device.

#### Returns

`boolean`

#### Implementation of

[`SensitiveContentMethodHandler`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md).[`isSupported`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md#issupported)

***

### setContentSensitivity()

> **setContentSensitivity**(`requestedContentSensitivity`): `void`

Requests that a native Flutter OpenHarmony View sets its content sensitivity level to
requestedContentSensitivity.

#### Parameters

##### requestedContentSensitivity

`number`

#### Returns

`void`

#### Implementation of

[`SensitiveContentMethodHandler`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md).[`setContentSensitivity`](../../../../embedding/engine/systemchannels/SensitiveContentChannel/interfaces/SensitiveContentMethodHandler.md#setcontentsensitivity)
