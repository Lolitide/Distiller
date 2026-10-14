[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: PlatformMessageHandler

Interface for handling platform message requests from Flutter.

## Methods

### clipboardHasStrings()

> **clipboardHasStrings**(): `boolean`

#### Returns

`boolean`

***

### getClipboardData()

> **getClipboardData**(`result`): `void`

#### Parameters

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

#### Returns

`void`

***

### playSystemSound()

> **playSystemSound**(`soundType`): `void`

#### Parameters

##### soundType

[`SoundType`](../enumerations/SoundType.md)

#### Returns

`void`

***

### popSystemNavigator()

> **popSystemNavigator**(): `void`

#### Returns

`void`

***

### restoreSystemUiOverlays()

> **restoreSystemUiOverlays**(): `void`

#### Returns

`void`

***

### setApplicationSwitcherDescription()

> **setApplicationSwitcherDescription**(`description`): `void`

#### Parameters

##### description

[`AppSwitcherDescription`](../classes/AppSwitcherDescription.md)

#### Returns

`void`

***

### setClipboardData()

> **setClipboardData**(`text`, `result`): `void`

#### Parameters

##### text

`string`

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

#### Returns

`void`

***

### setPreferredOrientations()

> **setPreferredOrientations**(`ohosOrientation`, `result`): `void`

#### Parameters

##### ohosOrientation

`number`

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

#### Returns

`void`

***

### setSystemUiChangeListener()

> **setSystemUiChangeListener**(): `void`

#### Returns

`void`

***

### setSystemUiOverlayStyle()

> **setSystemUiOverlayStyle**(`systemUiOverlayStyle`): `void`

#### Parameters

##### systemUiOverlayStyle

[`SystemChromeStyle`](../classes/SystemChromeStyle.md)

#### Returns

`void`

***

### showSystemOverlays()

> **showSystemOverlays**(`overlays`): `void`

#### Parameters

##### overlays

[`SystemUiOverlay`](../enumerations/SystemUiOverlay.md)[]

#### Returns

`void`

***

### showSystemUiMode()

> **showSystemUiMode**(`mode`): `void`

#### Parameters

##### mode

[`SystemUiMode`](../enumerations/SystemUiMode.md)

#### Returns

`void`

***

### vibrateHapticFeedback()

> **vibrateHapticFeedback**(`feedbackType`): `Promise`\<`void`\>

#### Parameters

##### feedbackType

[`HapticFeedbackType`](../enumerations/HapticFeedbackType.md)

#### Returns

`Promise`\<`void`\>
