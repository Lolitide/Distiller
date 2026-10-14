[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: ByteBuffer

A byte buffer.

Supports the following data types:
- Bool
- Int (8, 16, 32, 64)
- Uint (8, 16, 32, 64)
- BigInt (64)
- String (utf8, utf16, and delimited)
- TypedArray

## Constructors

### Constructor

> **new ByteBuffer**(): `ByteBuffer`

#### Returns

`ByteBuffer`

## Properties

### mByteOffset

> **mByteOffset**: `number` = `0`

The byte offset.

## Accessors

### buffer

#### Get Signature

> **get** **buffer**(): `ArrayBuffer`

Gets the underlying ArrayBuffer up to the current offset.

##### Returns

`ArrayBuffer`

The ArrayBuffer slice

***

### byteLength

#### Get Signature

> **get** **byteLength**(): `number`

Gets the byte length of the buffer.

##### Returns

`number`

The byte length

***

### byteOffset

#### Get Signature

> **get** **byteOffset**(): `number`

The byte offset.

##### Returns

`number`

The byte offset.

***

### bytesRemaining

#### Get Signature

> **get** **bytesRemaining**(): `number`

The number of remaining bytes.

##### Returns

`number`

The number of bytes remaining.

## Methods

### checkWriteCapacity()

> **checkWriteCapacity**(`slen`): `void`

check buffer capacity.

#### Parameters

##### slen

`number`

#### Returns

`void`

***

### clear()

> **clear**(): `void`

Clears the byte buffer.

#### Returns

`void`

***

### getBigInt64()

> **getBigInt64**(`byteOffset`, `littleEndian?`): `bigint`

Gets an signed long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`bigint`

The value.

***

### getBigUint64()

> **getBigUint64**(`byteOffset`, `littleEndian?`): `bigint`

Gets an unsigned long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`bigint`

The value.

***

### getBool()

> **getBool**(`byteOffset`): `boolean`

Gets a boolean.

#### Parameters

##### byteOffset

`number`

The byte offset

#### Returns

`boolean`

***

### getFloat32()

> **getFloat32**(`byteOffset`, `littleEndian?`): `number`

Gets a float.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getFloat64()

> **getFloat64**(`byteOffset`, `littleEndian?`): `number`

Gets a double.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getInt16()

> **getInt16**(`byteOffset`, `littleEndian?`): `number`

Gets an signed short.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getInt32()

> **getInt32**(`byteOffset`, `littleEndian?`): `number`

Gets an signed integer.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getInt64()

> **getInt64**(`byteOffset`, `littleEndian?`): `bigint`

Gets an signed long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`bigint`

The value.

***

### getInt8()

> **getInt8**(`byteOffset`): `number`

Gets an signed byte.

#### Parameters

##### byteOffset

`number`

The byte offset

#### Returns

`number`

The value.

***

### getString()

> **getString**(`byteOffset`, `byteLength?`, `byteEncoding?`): `string`

Gets a string.

#### Parameters

##### byteOffset

`number`

The byte offset

##### byteLength?

`number`

The byte length

##### byteEncoding?

`string`

The byte encoding

#### Returns

`string`

The value.

***

### getUint16()

> **getUint16**(`byteOffset`, `littleEndian?`): `number`

Gets an unsigned short.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getUint16Array()

> **getUint16Array**(`byteOffset`, `byteLength?`): `Uint16Array`

Gets an array of unsigned shorts.

#### Parameters

##### byteOffset

`number`

The byte offset

##### byteLength?

`number`

The byte length

#### Returns

`Uint16Array`

The value.

***

### getUint32()

> **getUint32**(`byteOffset`, `littleEndian?`): `number`

Gets an unsigned integer.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getUint64()

> **getUint64**(`byteOffset`, `littleEndian?`): `number`

Gets an unsigned long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### getUint8()

> **getUint8**(`byteOffset`): `number`

Gets an unsigned byte.

#### Parameters

##### byteOffset

`number`

The byte offset

#### Returns

`number`

The value.

***

### getUint8Array()

> **getUint8Array**(`byteOffset`, `byteLength?`): `Uint8Array`

Gets an array of unsigned bytes.

#### Parameters

##### byteOffset

`number`

The byte offset

##### byteLength?

`number`

The byte length

#### Returns

`Uint8Array`

The value.

***

### hasRemaining()

> **hasRemaining**(): `boolean`

Checks if there are remaining bytes to read.

#### Returns

`boolean`

True if there are remaining bytes, false otherwise

***

### readBigInt64()

> **readBigInt64**(`littleEndian?`): `bigint`

Reads the next signed long.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`bigint`

The value.

***

### readBigUint64()

> **readBigUint64**(`littleEndian?`): `bigint`

Reads the next unsigned long.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`bigint`

The value.

***

### readBool()

> **readBool**(): `boolean`

Reads the next boolean.

#### Returns

`boolean`

***

### readFloat32()

> **readFloat32**(`littleEndian?`): `number`

Reads the next float.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readFloat64()

> **readFloat64**(`littleEndian?`): `number`

Reads the next double.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readInt16()

> **readInt16**(`littleEndian?`): `number`

Reads the next signed short.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readInt32()

> **readInt32**(`littleEndian?`): `number`

Reads the next signed integer.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readInt64()

> **readInt64**(`littleEndian?`): `bigint`

Reads the next signed long.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`bigint`

The value.

***

### readInt8()

> **readInt8**(): `number`

Reads the next signed byte.

#### Returns

`number`

The value.

***

### readString()

> **readString**(`byteLength?`, `byteEncoding?`): `string`

Reads the next string.

#### Parameters

##### byteLength?

`number`

The byte length

##### byteEncoding?

`string`

The byte encoding

#### Returns

`string`

The value.

***

### readUint16()

> **readUint16**(`littleEndian?`): `number`

Reads the next unsigned short.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readUint16Array()

> **readUint16Array**(`byteLength?`): `Uint16Array`

Reads the next array of unsigned shorts.

#### Parameters

##### byteLength?

`number`

The byte length

#### Returns

`Uint16Array`

The value.

***

### readUint32()

> **readUint32**(`littleEndian?`): `number`

Reads the next unsigned integer.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readUint64()

> **readUint64**(`littleEndian?`): `number`

Reads the next unsigned long.

#### Parameters

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`number`

The value.

***

### readUint8()

> **readUint8**(): `number`

Reads the next unsigned byte.

#### Returns

`number`

The value.

***

### readUint8Array()

> **readUint8Array**(`byteLength?`): `Uint8Array`

Reads the next array of unsigned bytes.

#### Parameters

##### byteLength?

`number`

The byte length

#### Returns

`Uint8Array`

The value.

***

### reset()

> **reset**(): `void`

Resets the byte offset.

#### Returns

`void`

***

### setBigInt64()

> **setBigInt64**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets a signed long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`bigint`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setBigUint64()

> **setBigUint64**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets an unsigned long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`bigint`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setBool()

> **setBool**(`byteOffset`, `value`): `void`

Sets a boolean.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`boolean`

The value

#### Returns

`void`

***

### setFloat32()

> **setFloat32**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets a float.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setFloat64()

> **setFloat64**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets a double.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setInt16()

> **setInt16**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets a signed short.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setInt32()

> **setInt32**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets a signed integer.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setInt64()

> **setInt64**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets a signed long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setInt8()

> **setInt8**(`byteOffset`, `value`): `void`

Sets a signed byte.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

#### Returns

`void`

***

### setString()

> **setString**(`byteOffset`, `value`, `byteEncoding?`, `write?`): `number`

Sets a string.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`string`

The string value

##### byteEncoding?

`string`

The byte encoding

##### write?

`boolean`

#### Returns

`number`

The byte length.

***

### setUint16()

> **setUint16**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets an unsigned short.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setUint16Array()

> **setUint16Array**(`byteOffset`, `value`): `void`

Sets an array of unsigned bytes.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`Uint16Array`

The value

#### Returns

`void`

***

### setUint32()

> **setUint32**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets an unsigned integer.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setUint64()

> **setUint64**(`byteOffset`, `value`, `littleEndian?`): `void`

Sets an unsigned long.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### setUint8()

> **setUint8**(`byteOffset`, `value`): `void`

Sets an unsigned byte.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`number`

The value

#### Returns

`void`

***

### setUint8Array()

> **setUint8Array**(`byteOffset`, `value`): `void`

Sets an array of unsigned bytes.

#### Parameters

##### byteOffset

`number`

The byte offset

##### value

`Uint8Array`

The value

#### Returns

`void`

***

### skip()

> **skip**(`byteLength`): `void`

Skips the specified number of bytes.

#### Parameters

##### byteLength

`number`

The number of bytes to skip

#### Returns

`void`

***

### toString()

> **toString**(`format?`): `string`

Formats to a string.

#### Parameters

##### format?

`string`

The string format

#### Returns

`string`

The string.

***

### writeBigInt64()

> **writeBigInt64**(`value`, `littleEndian?`): `void`

Writes the next signed long.

#### Parameters

##### value

`bigint`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeBigUint64()

> **writeBigUint64**(`value`, `littleEndian?`): `void`

Writes the next unsigned long.

#### Parameters

##### value

`bigint`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeBool()

> **writeBool**(`value`): `void`

Writes the next boolean.

#### Parameters

##### value

`boolean`

The value

#### Returns

`void`

***

### writeFloat32()

> **writeFloat32**(`value`, `littleEndian?`): `void`

Writes the next float.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeFloat64()

> **writeFloat64**(`value`, `littleEndian?`): `void`

Writes the next double.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeInt16()

> **writeInt16**(`value`, `littleEndian?`): `void`

Writes the next signed short.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeInt32()

> **writeInt32**(`value`, `littleEndian?`): `void`

Writes the next signed integer.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeInt64()

> **writeInt64**(`value`, `littleEndian?`): `void`

Writes the next signed long.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeInt8()

> **writeInt8**(`value`): `void`

Writes the next signed byte.

#### Parameters

##### value

`number`

The value

#### Returns

`void`

***

### writeString()

> **writeString**(`value`, `byteEncoding?`): `void`

Writes the next a string.

#### Parameters

##### value

`string`

The string value

##### byteEncoding?

`string`

The byte encoding

#### Returns

`void`

***

### writeUint16()

> **writeUint16**(`value`, `littleEndian?`): `void`

Writes the next signed short.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeUint16Array()

> **writeUint16Array**(`value`): `void`

Writes the next array of unsigned bytes.

#### Parameters

##### value

`Uint16Array`

The value

#### Returns

`void`

***

### writeUint32()

> **writeUint32**(`value`, `littleEndian?`): `void`

Writes the next signed integer.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeUint64()

> **writeUint64**(`value`, `littleEndian?`): `void`

Writes the next signed long.

#### Parameters

##### value

`number`

The value

##### littleEndian?

`boolean`

Whether the value is little endian

#### Returns

`void`

***

### writeUint8()

> **writeUint8**(`value`): `void`

Writes the next signed byte.

#### Parameters

##### value

`number`

The value

#### Returns

`void`

***

### writeUint8Array()

> **writeUint8Array**(`value`): `void`

Writes the next array of unsigned bytes.

#### Parameters

##### value

`Uint8Array`

The value

#### Returns

`void`

***

### from()

> `static` **from**(`source`, `byteOffset?`, `byteLength?`): `ByteBuffer`

Creates a byte buffer.

#### Parameters

##### source

`ArrayBuffer`

The data source

##### byteOffset?

`number`

The byte offset

##### byteLength?

`number`

The byte length

#### Returns

`ByteBuffer`

A byte buffer
