[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: TextInputMethodHandler

Interface for handling text input method operations.

## Methods

### clearClient()

> **clearClient**(): `void`

#### Returns

`void`

***

### finishAutofillContext()

> **finishAutofillContext**(`shouldSave`): `void`

#### Parameters

##### shouldSave

`boolean`

#### Returns

`void`

***

### getKeyboardFocusState()

> **getKeyboardFocusState**(): `boolean`

#### Returns

`boolean`

***

### handleChangeFocus()

> **handleChangeFocus**(`focusState`): `void`

#### Parameters

##### focusState

`boolean`

#### Returns

`void`

***

### hide()

> **hide**(): `void`

#### Returns

`void`

***

### requestAutofill()

> **requestAutofill**(): `void`

#### Returns

`void`

***

### setClient()

> **setClient**(`textInputClientId`, `configuration`): `void`

#### Parameters

##### textInputClientId

`number`

##### configuration

[`Configuration`](../classes/Configuration.md)

#### Returns

`void`

***

### setCursorSizeAndPosition()

> **setCursorSizeAndPosition**(`cursorInfo`): `void`

#### Parameters

##### cursorInfo

`CursorInfo`

#### Returns

`void`

***

### setEditableSizeAndTransform()

> **setEditableSizeAndTransform**(`width`, `height`, `transform`): `void`

#### Parameters

##### width

`number`

##### height

`number`

##### transform

`number`[]

#### Returns

`void`

***

### setEditingState()

> **setEditingState**(`editingState`): `void`

#### Parameters

##### editingState

[`TextEditState`](../classes/TextEditState.md)

#### Returns

`void`

***

### setPlatformViewClient()

> **setPlatformViewClient**(`id`, `usesVirtualDisplay`): `void`

#### Parameters

##### id

`number`

##### usesVirtualDisplay

`boolean`

#### Returns

`void`

***

### show()

> **show**(): `void`

#### Returns

`void`

***

### updateConfig()

> **updateConfig**(`configuration`): `void`

#### Parameters

##### configuration

[`Configuration`](../classes/Configuration.md)

#### Returns

`void`
