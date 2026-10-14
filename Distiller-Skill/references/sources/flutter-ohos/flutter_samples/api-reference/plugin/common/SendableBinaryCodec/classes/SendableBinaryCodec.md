[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: SendableBinaryCodec

A sendable MessageCodec using unencoded binary messages.
This codec can be used in background threads and worker contexts.

## Implements

- [`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md)\<`ArrayBuffer`\>

## Constructors

### Constructor

> **new SendableBinaryCodec**(`returnsDirectByteBufferFromDecoding`): `SendableBinaryCodec`

Constructs a new SendableBinaryCodec instance.

#### Parameters

##### returnsDirectByteBufferFromDecoding

`boolean`

Whether to return the direct buffer from decoding

#### Returns

`SendableBinaryCodec`

## Properties

### INSTANCE\_DIRECT

> `readonly` `static` **INSTANCE\_DIRECT**: `SendableBinaryCodec`

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

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md).[`decodeMessage`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md#decodemessage)

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

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md).[`encodeMessage`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md#encodemessage)
