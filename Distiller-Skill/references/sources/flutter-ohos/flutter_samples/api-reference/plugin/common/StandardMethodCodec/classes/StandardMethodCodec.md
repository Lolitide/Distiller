[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: StandardMethodCodec

A [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) using the Flutter standard binary encoding.

This codec is guaranteed to be compatible with the corresponding StandardMethodCodec
on the Dart side. These parts of the Flutter SDK are evolved synchronously.

Values supported as method arguments and result payloads are those supported by StandardMessageCodec.

## Implements

- [`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md)

## Constructors

### Constructor

> **new StandardMethodCodec**(`messageCodec`): `StandardMethodCodec`

Creates a new method codec based on the specified message codec.

#### Parameters

##### messageCodec

`StandardMessageCodec`

The StandardMessageCodec to use for encoding/decoding

#### Returns

`StandardMethodCodec`

## Properties

### INSTANCE

> `static` **INSTANCE**: `StandardMethodCodec`

Singleton instance of StandardMethodCodec.

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

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`decodeEnvelope`](../../MethodCodec/interfaces/MethodCodec.md#decodeenvelope)

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

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`decodeMethodCall`](../../MethodCodec/interfaces/MethodCodec.md#decodemethodcall)

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

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeErrorEnvelope`](../../MethodCodec/interfaces/MethodCodec.md#encodeerrorenvelope)

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

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeErrorEnvelopeWithStacktrace`](../../MethodCodec/interfaces/MethodCodec.md#encodeerrorenvelopewithstacktrace)

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

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeMethodCall`](../../MethodCodec/interfaces/MethodCodec.md#encodemethodcall)

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

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md).[`encodeSuccessEnvelope`](../../MethodCodec/interfaces/MethodCodec.md#encodesuccessenvelope)
