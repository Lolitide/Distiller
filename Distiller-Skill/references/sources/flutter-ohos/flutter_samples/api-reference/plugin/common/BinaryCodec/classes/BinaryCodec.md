[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: BinaryCodec

A [MessageCodec](../../MessageCodec/interfaces/MessageCodec.md) using unencoded binary messages, represented as ArrayBuffers.

This codec is guaranteed to be compatible with the corresponding `BinaryCodec` on the Dart side.
These parts of the Flutter SDK are evolved synchronously.

On the Dart side, messages are represented using ByteData.

## Implements

- [`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md)\<`ArrayBuffer`\>

## Constructors

### Constructor

> **new BinaryCodec**(`returnsDirectByteBufferFromDecoding`): `BinaryCodec`

Constructs a new BinaryCodec instance.

#### Parameters

##### returnsDirectByteBufferFromDecoding

`boolean`

Whether to return the direct buffer from decoding

#### Returns

`BinaryCodec`

## Properties

### INSTANCE\_DIRECT

> `readonly` `static` **INSTANCE\_DIRECT**: `BinaryCodec`

Direct instance that returns the direct buffer from decoding.

## Methods

### decodeMessage()

> **decodeMessage**(`message`): `ArrayBuffer`

Decodes a binary message.

#### Parameters

##### message

`ArrayBuffer`

The ArrayBuffer message to decode, possibly null

#### Returns

`ArrayBuffer`

The decoded ArrayBuffer, or a copy depending on configuration

#### Implementation of

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md).[`decodeMessage`](../../MessageCodec/interfaces/MessageCodec.md#decodemessage)

***

### encodeMessage()

> **encodeMessage**(`message`): `ArrayBuffer`

Encodes a binary message (no-op for binary codec).

#### Parameters

##### message

`ArrayBuffer`

The ArrayBuffer message to encode

#### Returns

`ArrayBuffer`

The same ArrayBuffer

#### Implementation of

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md).[`encodeMessage`](../../MessageCodec/interfaces/MessageCodec.md#encodemessage)
