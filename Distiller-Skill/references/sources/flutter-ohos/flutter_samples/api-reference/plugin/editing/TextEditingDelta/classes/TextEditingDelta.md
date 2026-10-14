[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: TextEditingDelta

Represents a delta (change) in text editing state.
This class tracks changes to text, selection, and composing regions.

## Constructors

### Constructor

> **new TextEditingDelta**(`oldEditable`, `selectionStart`, `selectionEnd`, `composingStart`, `composingEnd`, `replacementDestinationStart?`, `replacementDestinationEnd?`, `replacementSource?`): `TextEditingDelta`

Constructs a new TextEditingDelta instance.

#### Parameters

##### oldEditable

`string`

The text before the change

##### selectionStart

`number`

The new selection start position

##### selectionEnd

`number`

The new selection end position

##### composingStart

`number`

The new composing region start position

##### composingEnd

`number`

The new composing region end position

##### replacementDestinationStart?

`number`

Optional start position of the replacement destination

##### replacementDestinationEnd?

`number`

Optional end position of the replacement destination

##### replacementSource?

`string`

Optional replacement text

#### Returns

`TextEditingDelta`

## Methods

### setDeltas()

> **setDeltas**(`oldText`, `newText`, `newStart`, `newExtent`): `void`

Sets the delta information for this change.

#### Parameters

##### oldText

`string`

The text before the change

##### newText

`string`

The replacement text

##### newStart

`number`

The start position of the replacement

##### newExtent

`number`

The end position of the replacement

#### Returns

`void`

***

### toJSON()

> **toJSON**(): [`TextEditingDeltaJson`](../interfaces/TextEditingDeltaJson.md)

Converts this delta to a JSON representation.

#### Returns

[`TextEditingDeltaJson`](../interfaces/TextEditingDeltaJson.md)

A JSON object containing all delta information
