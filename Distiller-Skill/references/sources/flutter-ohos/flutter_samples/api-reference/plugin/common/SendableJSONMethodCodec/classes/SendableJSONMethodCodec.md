[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: SendableJSONMethodCodec

A sendable MethodCodec using UTF-8 encoded JSON method calls and result envelopes.
This codec can be used in background threads and worker contexts.

## Implements

- [`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md)

## Constructors

### Constructor

> **new SendableJSONMethodCodec**(): `SendableJSONMethodCodec`

#### Returns

`SendableJSONMethodCodec`

## Properties

### INSTANCE

> `static` **INSTANCE**: `SendableJSONMethodCodec`

Singleton instance of SendableJSONMethodCodec.

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

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`decodeEnvelope`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#decodeenvelope)

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

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`decodeMethodCall`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#decodemethodcall)

***

### encodeErrorEnvelope()

> **encodeErrorEnvelope**(`errorCode`, `errorMessage`, `errorDetails`): `any`

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

`any`

The encoded envelope as an ArrayBuffer

#### Implementation of

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeErrorEnvelope`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodeerrorenvelope)

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

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeErrorEnvelopeWithStacktrace`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodeerrorenvelopewithstacktrace)

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

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeMethodCall`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodemethodcall)

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

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeSuccessEnvelope`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodesuccessenvelope)
