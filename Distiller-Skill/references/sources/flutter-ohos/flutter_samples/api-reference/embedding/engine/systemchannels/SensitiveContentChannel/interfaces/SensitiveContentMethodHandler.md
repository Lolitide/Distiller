[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: SensitiveContentMethodHandler

## Methods

### getContentSensitivity()

> **getContentSensitivity**(): `number`

Returns the current content sensitivity level of a Flutter OpenHarmony View.

#### Returns

`number`

***

### isSupported()

> **isSupported**(): `boolean`

Returns whether or not setting/getting content sensitivity via OpenHarmony APIs is supported on
the device.

#### Returns

`boolean`

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
