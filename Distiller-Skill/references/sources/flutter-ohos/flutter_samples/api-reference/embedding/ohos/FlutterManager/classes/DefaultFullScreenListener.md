[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: DefaultFullScreenListener

Default implementation of FullScreenListener.

## Implements

- [`FullScreenListener`](../interfaces/FullScreenListener.md)

## Constructors

### Constructor

> **new DefaultFullScreenListener**(): `DefaultFullScreenListener`

#### Returns

`DefaultFullScreenListener`

## Methods

### onScreenStateChanged()

> **onScreenStateChanged**(`data`): `void`

Called when the screen state changes.

#### Parameters

##### data

`WindowStatusType`

The window status type

#### Returns

`void`

#### Implementation of

[`FullScreenListener`](../interfaces/FullScreenListener.md).[`onScreenStateChanged`](../interfaces/FullScreenListener.md#onscreenstatechanged)

***

### setUseFullScreen()

> **setUseFullScreen**(`useFullScreen`, `context?`): `void`

Sets whether to use full screen mode.

#### Parameters

##### useFullScreen

`boolean`

Whether to use full screen

##### context?

`any`

Optional context

#### Returns

`void`

#### Implementation of

[`FullScreenListener`](../interfaces/FullScreenListener.md).[`setUseFullScreen`](../interfaces/FullScreenListener.md#setusefullscreen)

***

### useFullScreen()

> **useFullScreen**(): `boolean`

Checks if full screen mode is enabled.

#### Returns

`boolean`

True if full screen is enabled, false otherwise

#### Implementation of

[`FullScreenListener`](../interfaces/FullScreenListener.md).[`useFullScreen`](../interfaces/FullScreenListener.md#usefullscreen)
