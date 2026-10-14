[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: JSONMethodCodec

A [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) using UTF-8 encoded JSON method calls and result envelopes.

This codec is guaranteed to be compatible with the corresponding `JSONMethodCodec` on
the Dart side. These parts of the Flutter SDK are evolved synchronously.

Values supported as methods arguments and result payloads are those supported by JSONMessageCodec.

## Implements

- [`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md)

## Constructors

### Constructor

> **new JSONMethodCodec**(): `JSONMethodCodec`

#### Returns

`JSONMethodCodec`

## Properties

### INSTANCE

> `static` **INSTANCE**: `JSONMethodCodec`

Singleton instance of JSONMethodCodec.

## Methods

### decodeEnvelope()

> **decodeEnvelope**(`envelope`): `Any`

Decodes a result envelope from JSON binary format.

#### Parameters

##### envelope

`ArrayBuffer`

The binary envelope to decode

#### Returns

`Any`

The decoded result value

#### Throws

FlutterException if the envelope contains an error

#### Throws

Error if the envelope is invalid

#### Implementation of

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`decodeEnvelope`](../../MethodCodec/interfaces/MethodCodec.md#decodeenvelope)

***

### decodeMethodCall()

> **decodeMethodCall**(`message`): `MethodCall`

Decodes a method call from JSON binary format.

#### Parameters

##### message

`ArrayBuffer`

The binary message to decode

#### Returns

`MethodCall`

The decoded MethodCall

#### Throws

Error if decoding fails or the message is invalid

#### Implementation of

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`decodeMethodCall`](../../MethodCodec/interfaces/MethodCodec.md#decodemethodcall)

***

### encodeErrorEnvelope()

> **encodeErrorEnvelope**(`errorCode`, `errorMessage`, `errorDetails`): `ArrayBuffer`

Encodes an error result into a JSON envelope.

#### Parameters

##### errorCode

`Any`

The error code

##### errorMessage

`string`

The error message, possibly null

##### errorDetails

`Any`

Error details, possibly null

#### Returns

`ArrayBuffer`

The encoded envelope as an ArrayBuffer

#### Implementation of

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeErrorEnvelope`](../../MethodCodec/interfaces/MethodCodec.md#encodeerrorenvelope)

***

### encodeErrorEnvelopeWithStacktrace()

> **encodeErrorEnvelopeWithStacktrace**(`errorCode`, `errorMessage`, `errorDetails`, `errorStacktrace`): `ArrayBuffer`

Encodes an error result into a JSON envelope with stacktrace.

#### Parameters

##### errorCode

`string`

The error code

##### errorMessage

`string`

The error message, possibly null

##### errorDetails

`Any`

Error details, possibly null

##### errorStacktrace

`string`

The platform stacktrace, possibly null

#### Returns

`ArrayBuffer`

The encoded envelope as an ArrayBuffer

#### Implementation of

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeErrorEnvelopeWithStacktrace`](../../MethodCodec/interfaces/MethodCodec.md#encodeerrorenvelopewithstacktrace)

***

### encodeMethodCall()

> **encodeMethodCall**(`methodCall`): `ArrayBuffer`

Encodes a method call into JSON binary format.

#### Parameters

##### methodCall

`MethodCall`

The MethodCall to encode

#### Returns

`ArrayBuffer`

The encoded method call as an ArrayBuffer

#### Throws

Error if encoding fails

#### Implementation of

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeMethodCall`](../../MethodCodec/interfaces/MethodCodec.md#encodemethodcall)

***

### encodeSuccessEnvelope()

> **encodeSuccessEnvelope**(`result`): `ArrayBuffer`

Encodes a successful result into a JSON envelope.

#### Parameters

##### result

`Any`

The result value, possibly null

#### Returns

`ArrayBuffer`

The encoded envelope as an ArrayBuffer

#### Implementation of

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeSuccessEnvelope`](../../MethodCodec/interfaces/MethodCodec.md#encodesuccessenvelope)
