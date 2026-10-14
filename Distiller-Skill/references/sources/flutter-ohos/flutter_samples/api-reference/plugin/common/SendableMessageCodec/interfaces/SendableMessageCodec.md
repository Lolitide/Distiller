[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: SendableMessageCodec\<T\>

Interface for sendable message codecs that can be used in background threads.
This interface extends ISendable to allow codecs to be passed across thread boundaries.

## Extends

- `ISendable`

## Type Parameters

### T

`T`

The type of message being encoded/decoded

## Methods

### decodeMessage()

> **decodeMessage**(`message`): `T`

Decodes the specified message from binary.

#### Parameters

##### message

`ArrayBuffer`

The binary message to decode, possibly null

#### Returns

`T`

The decoded message

***

### encodeMessage()

> **encodeMessage**(`message`): `ArrayBuffer`

Encodes the specified message into binary.

#### Parameters

##### message

`T`

The message to encode

#### Returns

`ArrayBuffer`

The encoded message as an ArrayBuffer
