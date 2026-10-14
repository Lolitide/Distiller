[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: PasteboardUtils

Utility class for pasteboard operations.
Provides methods for copying and pasting data to/from the system pasteboard.

## Constructors

### Constructor

> **new PasteboardUtils**(): `PasteboardUtils`

#### Returns

`PasteboardUtils`

## Methods

### getPasteDataAsync()

> `static` **getPasteDataAsync**(): `Promise`\<`string`\>

Gets paste data from the OpenHarmony pasteboard asynchronously.
Requests READ_PASTEBOARD permission if needed.

#### Returns

`Promise`\<`string`\>

A Promise that resolves to the pasted text, or empty string if no text is available.

***

### getTargetTypesData()

> `static` **getTargetTypesData**(`record`): `Promise`\<`string`\>

#### Parameters

##### record

`PasteDataRecord`

#### Returns

`Promise`\<`string`\>

***

### setCopyData()

> `static` **setCopyData**(`text`): `void`

Copies text data to the OpenHarmony pasteboard.

#### Parameters

##### text

`string`

The text to copy

#### Returns

`void`
