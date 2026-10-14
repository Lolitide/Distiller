[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: FullScreenListener

Interface for full screen state management.

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

***

### useFullScreen()

> **useFullScreen**(): `boolean`

Checks if full screen mode is enabled.

#### Returns

`boolean`

True if full screen is enabled, false otherwise
