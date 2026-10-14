[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: StringCodec

A [MessageCodec](../../MessageCodec/interfaces/MessageCodec.md) using UTF-8 encoded String messages.

This codec is guaranteed to be compatible with the corresponding `StringCodec` on the
Dart side. These parts of the Flutter SDK are evolved synchronously.

## Implements

- [`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md)\<`string`\>

## Constructors

### Constructor

> **new StringCodec**(): `StringCodec`

#### Returns

`StringCodec`

## Properties

### INSTANCE

> `readonly` `static` **INSTANCE**: `StringCodec`

Singleton instance of StringCodec.

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

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md).[`decodeMessage`](../../MessageCodec/interfaces/MessageCodec.md#decodemessage)

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

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md).[`encodeMessage`](../../MessageCodec/interfaces/MessageCodec.md#encodemessage)
