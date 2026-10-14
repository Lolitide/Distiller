[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: EditingStateWatcher

Interface for objects that watch for editing state changes.
Changing the editing state in a didChangeEditingState callback may cause unexpected behavior.

## Methods

### didChangeEditingState()

> **didChangeEditingState**(`textChanged`, `selectionChanged`, `composingRegionChanged`): `void`

Called when the editing state changes.

#### Parameters

##### textChanged

`boolean`

Whether the text has changed

##### selectionChanged

`boolean`

Whether the selection has changed

##### composingRegionChanged

`boolean`

Whether the composing region has changed

#### Returns

`void`
