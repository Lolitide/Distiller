[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: SendableStringCodec

A sendable MessageCodec using UTF-8 encoded String messages.
This codec can be used in background threads and worker contexts.

## Implements

- [`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md)\<`string`\>

## Constructors

### Constructor

> **new SendableStringCodec**(): `SendableStringCodec`

#### Returns

`SendableStringCodec`

## Properties

### INSTANCE

> `readonly` `static` **INSTANCE**: `SendableStringCodec`

Singleton instance of SendableStringCodec.

## Methods

### decodeMessage()

> **decodeMessage**(`message`): `string`

Decodes a binary message into a string.

#### Parameters

##### message

`ArrayBuffer`

The binary message to decode, possibly null

#### Returns

`string`

The decoded string

#### Implementation of

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md).[`decodeMessage`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md#decodemessage)

***

### encodeMessage()

> **encodeMessage**(`message`): `ArrayBuffer`

Encodes a string message into binary format.

#### Parameters

##### message

`string`

The string message to encode, possibly null

#### Returns

`ArrayBuffer`

The encoded message as an ArrayBuffer

#### Implementation of

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md).[`encodeMessage`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md#encodemessage)
