[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: StringUtils

Utility class for string operations.
Provides methods for converting between strings and ArrayBuffer/Uint8Array.

## Constructors

### Constructor

> **new StringUtils**(): `StringUtils`

#### Returns

`StringUtils`

## Methods

### arrayBufferToString()

> `static` **arrayBufferToString**(`buffer`): `string`

Converts an ArrayBuffer to a string using UTF-8 decoding.

#### Parameters

##### buffer

`ArrayBuffer`

The ArrayBuffer to convert.

#### Returns

`string`

The decoded string, or empty string if buffer is empty.

***

### isEmpty()

> `static` **isEmpty**(`str`): `boolean`

Checks if a string is empty.

#### Parameters

##### str

`string`

The string to check

#### Returns

`boolean`

True if the string is null, undefined, or has length 0, false otherwise.

***

### isNotEmpty()

> `static` **isNotEmpty**(`str`): `boolean`

Checks if a string is not empty.

#### Parameters

##### str

`string`

The string to check.

#### Returns

`boolean`

True if the string is not null and has length > 0, false otherwise.

***

### stringToArrayBuffer()

> `static` **stringToArrayBuffer**(`str`): `ArrayBuffer`

Converts a string to an ArrayBuffer using UTF-8 encoding.

#### Parameters

##### str

`string`

The string to convert.

#### Returns

`ArrayBuffer`

The ArrayBuffer containing the UTF-8 encoded string.

***

### uint8ArrayToString()

> `static` **uint8ArrayToString**(`buffer`): `string`

Converts a Uint8Array to a string using UTF-8 decoding.

#### Parameters

##### buffer

`Uint8Array`

The Uint8Array to convert.

#### Returns

`string`

The decoded string, or empty string if buffer is empty.
