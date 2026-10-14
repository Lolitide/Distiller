[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: TextEditState

State of an on-going text editing session..

## Constructors

### Constructor

> **new TextEditState**(`text`, `selectionStart`, `selectionEnd`, `composingStart`, `composingEnd`): `TextEditState`

Constructs a new TextEditState instance.

#### Parameters

##### text

`string`

The text content

##### selectionStart

`number`

The start of the selection

##### selectionEnd

`number`

The end of the selection

##### composingStart

`number`

The start of the composing region

##### composingEnd

`number`

The end of the composing region

#### Returns

`TextEditState`

## Properties

### composingEnd

> **composingEnd**: `number`

The end position of the composing region.

***

### composingStart

> **composingStart**: `number`

The start position of the composing region.

***

### selectionEnd

> **selectionEnd**: `number`

The end position of the text selection.

***

### selectionStart

> **selectionStart**: `number`

The start position of the text selection.

***

### text

> **text**: `string`

The text content.

## Methods

### hasComposing()

> **hasComposing**(): `boolean`

Checks if there is an active composing region.

#### Returns

`boolean`

True if there is an active composing region, false otherwise

***

### hasSelection()

> **hasSelection**(): `boolean`

#### Returns

`boolean`

***

### fromJson()

> `static` **fromJson**(`textEditState`): `TextEditState`

Creates a TextEditState instance from JSON.

#### Parameters

##### textEditState

`Any`

The JSON object or map

#### Returns

`TextEditState`

A new TextEditState instance
