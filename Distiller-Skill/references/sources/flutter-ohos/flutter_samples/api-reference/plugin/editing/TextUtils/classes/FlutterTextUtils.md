[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterTextUtils

Utility class for text processing operations, including Unicode code point handling,
emoji detection, and text offset calculations.

## Constructors

### Constructor

> **new FlutterTextUtils**(): `FlutterTextUtils`

#### Returns

`FlutterTextUtils`

## Methods

### charCount()

> `static` **charCount**(`codePoint`): `number`

Gets the number of UTF-16 code units required to represent a Unicode code point.

#### Parameters

##### codePoint

`number`

The Unicode code point

#### Returns

`number`

1 for BMP characters (0x0000-0xFFFF), 2 for supplementary characters (0x10000-0x10FFFF)

***

### codePointAt()

> `static` **codePointAt**(`text`, `offset`): `number`

Gets the Unicode code point at the specified offset in the text.
Handles surrogate pairs correctly.

#### Parameters

##### text

`string`

The text to examine

##### offset

`number`

The offset position

#### Returns

`number`

The Unicode code point at the offset

#### Throws

RangeError if the offset is out of range

***

### codePointBefore()

> `static` **codePointBefore**(`text`, `offset`): `number`

Gets the Unicode code point before the specified offset in the text.
Handles surrogate pairs correctly.

#### Parameters

##### text

`string`

The text to examine

##### offset

`number`

The offset position

#### Returns

`number`

The Unicode code point before the offset

#### Throws

RangeError if the offset is out of range

***

### getImePreviewBackspaceDeleteRange()

> `static` **getImePreviewBackspaceDeleteRange**(`text`, `offset`): [`ImePreviewBackspaceRange`](ImePreviewBackspaceRange.md)

One preview Backspace step: delete `[delStart, delEnd)` so a lone IME `'` left of the caret
does not expand the removal to `[delStart, caret)` (which would swallow the previous letter too).
When `[plain, offset)` is apostrophe-only, deletes one grapheme cluster immediately before that run:
`[getOffsetBefore(text, plain), plain)` instead of `[…, offset)`.

#### Parameters

##### text

`string`

##### offset

`number`

#### Returns

[`ImePreviewBackspaceRange`](ImePreviewBackspaceRange.md)

***

### getOffsetAfter()

> `static` **getOffsetAfter**(`text`, `offset`): `number`

Gets the offset after the current position, handling complex Unicode sequences
such as emojis, regional indicators, keycaps, and variation selectors.

#### Parameters

##### text

`string`

The text to examine

##### offset

`number`

The current offset position

#### Returns

`number`

The offset after the current position, accounting for Unicode sequences

***

### getOffsetAfterForImePreview()

> `static` **getOffsetAfterForImePreview**(`text`, `offset`): `number`

Same as getOffsetAfter, but if `[offset, end)` is only consecutive `'` (IME separators),
extend once more so `'` is not counted alone as one forward-delete step.

#### Parameters

##### text

`string`

##### offset

`number`

#### Returns

`number`

***

### getOffsetBefore()

> `static` **getOffsetBefore**(`text`, `offset`): `number`

Gets the offset before the current position, handling complex Unicode sequences
such as emojis, regional indicators, keycaps, and variation selectors.

#### Parameters

##### text

`string`

The text to examine

##### offset

`number`

The current offset position

#### Returns

`number`

The offset before the current position, accounting for Unicode sequences

***

### isEmoji()

> `static` **isEmoji**(`code`): `boolean`

Checks if a Unicode code point represents an emoji.

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is an emoji, false otherwise

***

### isEmojiModifier()

> `static` **isEmojiModifier**(`code`): `boolean`

Checks if a Unicode code point represents an emoji modifier.

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is an emoji modifier, false otherwise

***

### isEmojiModifierBase()

> `static` **isEmojiModifierBase**(`code`): `boolean`

Checks if a Unicode code point represents an emoji modifier base.

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is an emoji modifier base, false otherwise

***

### isKeycapBase()

> `static` **isKeycapBase**(`code`): `boolean`

Checks if a Unicode code point is a keycap base character (0-9, #, *).

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is a keycap base, false otherwise

***

### isRegionalIndicatorSymbol()

> `static` **isRegionalIndicatorSymbol**(`code`): `boolean`

Checks if a Unicode code point represents a regional indicator symbol.

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is a regional indicator symbol, false otherwise

***

### isTagSpecChar()

> `static` **isTagSpecChar**(`code`): `boolean`

Checks if a Unicode code point is a tag specification character.

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is a tag specification character, false otherwise

***

### isVariationSelector()

> `static` **isVariationSelector**(`code`): `boolean`

Checks if a Unicode code point represents a variation selector.

#### Parameters

##### code

`number`

The Unicode code point to check

#### Returns

`boolean`

True if the code point is a variation selector, false otherwise
