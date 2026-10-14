[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: SendableStandardMethodCodec

A sendable MethodCodec using the Flutter standard binary encoding.
This codec can be used in background threads and worker contexts.

## Implements

- [`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md)

## Constructors

### Constructor

> **new SendableStandardMethodCodec**(`messageCodec`): `SendableStandardMethodCodec`

Creates a new method codec based on the specified message codec.

#### Parameters

##### messageCodec

`SendableStandardMessageCodec`

The SendableStandardMessageCodec to use for encoding/decoding

#### Returns

`SendableStandardMethodCodec`

## Properties

### INSTANCE

> `static` **INSTANCE**: `SendableStandardMethodCodec`

Singleton instance of SendableStandardMethodCodec.

## Methods

### decodeEnvelope()

> **decodeEnvelope**(`envelope`): `Any`

Decodes a result envelope from binary format.

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

Error if the envelope is corrupted

#### Implementation of

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`decodeEnvelope`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#decodeenvelope)

***

### decodeMethodCall()

> **decodeMethodCall**(`methodCall`): `MethodCall`

Decodes a method call from binary format.

#### Parameters

##### methodCall

`ArrayBuffer`

The binary message to decode

#### Returns

`MethodCall`

The decoded MethodCall

#### Throws

Error if the method call is corrupted

#### Implementation of

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`decodeMethodCall`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#decodemethodcall)

***

### encodeErrorEnvelope()

> **encodeErrorEnvelope**(`errorCode`, `errorMessage`, `errorDetails`): `ArrayBuffer`

Encodes an error result into a binary envelope.

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

#### Returns

`ArrayBuffer`

The encoded envelope as an ArrayBuffer

#### Implementation of

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeErrorEnvelope`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodeerrorenvelope)

***

### encodeErrorEnvelopeWithStacktrace()

> **encodeErrorEnvelopeWithStacktrace**(`errorCode`, `errorMessage`, `errorDetails`, `errorStacktrace`): `ArrayBuffer`

Encodes an error result into a binary envelope with stacktrace.

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

Encodes a method call into binary format.

#### Parameters

##### methodCall

`MethodCall`

The MethodCall to encode

#### Returns

`ArrayBuffer`

The encoded method call as an ArrayBuffer

#### Implementation of

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeMethodCall`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodemethodcall)

***

### encodeSuccessEnvelope()

> **encodeSuccessEnvelope**(`result`): `ArrayBuffer`

Encodes a successful result into a binary envelope.

#### Parameters

##### result

`Any`

The result value, possibly null

#### Returns

`ArrayBuffer`

The encoded envelope as an ArrayBuffer

#### Implementation of

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md).[`encodeSuccessEnvelope`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md#encodesuccessenvelope)
