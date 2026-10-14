[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: JSONMessageCodec

A [MessageCodec](../../MessageCodec/interfaces/MessageCodec.md) using UTF-8 encoded JSON messages.

This codec is guaranteed to be compatible with the corresponding `JSONMessageCodec` on the Dart side.
These parts of the Flutter SDK are evolved synchronously.

On the Dart side, JSON messages are handled by the JSON facilities of the `dart:convert` package.

## Implements

- [`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md)\<`Object`\>

## Constructors

### Constructor

> **new JSONMessageCodec**(): `JSONMessageCodec`

#### Returns

`JSONMessageCodec`

## Properties

### INSTANCE

> `static` **INSTANCE**: `JSONMessageCodec`

Singleton instance of JSONMessageCodec.

## Methods

### decodeMessage()

> **decodeMessage**(`message`): `Any`

Decodes a binary message from JSON format.

#### Parameters

##### message

`ArrayBuffer`

The binary message to decode, possibly null

#### Returns

`Any`

The decoded message object

#### Throws

Error if the JSON is invalid

#### Implementation of

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md).[`decodeMessage`](../../MessageCodec/interfaces/MessageCodec.md#decodemessage)

***

### encodeMessage()

> **encodeMessage**(`message`): `ArrayBuffer`

Encodes a message into JSON binary format.

#### Parameters

##### message

`Any`

The message to encode, possibly null

#### Returns

`ArrayBuffer`

The encoded message as an ArrayBuffer

#### Implementation of

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md).[`encodeMessage`](../../MessageCodec/interfaces/MessageCodec.md#encodemessage)

***

### toBaseData()

> **toBaseData**(`message`): `Any`

Converts a message to base data types suitable for JSON serialization.

#### Parameters

##### message

`Any`

The message to convert

#### Returns

`Any`

The converted message with base data types
