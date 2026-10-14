[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: SendableStandardMessageCodec

A sendable MessageCodec using the Flutter standard binary encoding.
This codec can be used in background threads and worker contexts.

## Implements

- [`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md)\<`Any`\>

## Constructors

### Constructor

> **new SendableStandardMessageCodec**(): `SendableStandardMessageCodec`

#### Returns

`SendableStandardMessageCodec`

## Properties

### INSTANCE

> `static` **INSTANCE**: `SendableStandardMessageCodec`

Singleton instance of SendableStandardMessageCodec.

## Methods

### decodeMessage()

> **decodeMessage**(`message`): `Any`

Decodes a binary message from the standard encoding.

#### Parameters

##### message

`ArrayBuffer`

The binary message to decode, possibly null

#### Returns

`Any`

The decoded message

#### Implementation of

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md).[`decodeMessage`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md#decodemessage)

***

### encodeMessage()

> **encodeMessage**(`message`): `ArrayBuffer`

Encodes a message into binary format using the standard encoding.

#### Parameters

##### message

`Any`

The message to encode

#### Returns

`ArrayBuffer`

The encoded message as an ArrayBuffer

#### Implementation of

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md).[`encodeMessage`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md#encodemessage)

***

### readAlignment()

> **readAlignment**(`buffer`, `alignment`): `void`

Reads alignment padding from the buffer.

#### Parameters

##### buffer

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to read from

##### alignment

`number`

The alignment requirement (e.g., 4, 8)

#### Returns

`void`

***

### readBytes()

> **readBytes**(`buffer`): `Uint8Array`

Reads a byte array from the buffer.

#### Parameters

##### buffer

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to read from

#### Returns

`Uint8Array`

The byte array

***

### readSize()

> **readSize**(`buffer`): `number`

Reads a size value from the buffer using compact encoding.

#### Parameters

##### buffer

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to read from

#### Returns

`number`

The size value

***

### readValue()

> **readValue**(`buffer`): `Any`

Reads a value from the buffer using the standard encoding.

#### Parameters

##### buffer

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to read from

#### Returns

`Any`

The decoded value

***

### readValueOfType()

> **readValueOfType**(`type`, `buffer`): `Any`

Reads a value of a specific type from the buffer.

#### Parameters

##### type

`number`

The type code to read

##### buffer

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to read from

#### Returns

`Any`

The decoded value

#### Throws

Error if the type is unknown or the message is corrupted

***

### writeAlignment()

> **writeAlignment**(`stream`, `alignment`): `void`

Writes alignment padding to the stream.

#### Parameters

##### stream

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to write to

##### alignment

`number`

The alignment requirement (e.g., 4, 8)

#### Returns

`void`

***

### writeBytes()

> **writeBytes**(`stream`, `bytes`): `void`

Writes a byte array to the stream.

#### Parameters

##### stream

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to write to

##### bytes

`Uint8Array`

The byte array to write

#### Returns

`void`

***

### writeSize()

> **writeSize**(`stream`, `value`): `void`

Writes a size value to the stream using compact encoding.

#### Parameters

##### stream

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to write to

##### value

`number`

The size value to write

#### Returns

`void`

***

### writeValue()

> **writeValue**(`stream`, `value`): `Any`

Writes a value to the byte buffer using the standard encoding.

#### Parameters

##### stream

[`ByteBuffer`](../../../../util/ByteBuffer/classes/ByteBuffer.md)

The ByteBuffer to write to

##### value

`Any`

The value to write

#### Returns

`Any`

The ByteBuffer stream
