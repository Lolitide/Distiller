[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: SendableMethodCodec

## Extends

- `ISendable`

## Methods

### decodeEnvelope()

> **decodeEnvelope**(`envelope`): `Any`

Decodes a result envelope from binary.

#### Parameters

##### envelope

`ArrayBuffer`

The binary encoding of a result envelope as an ArrayBuffer

#### Returns

`Any`

The enveloped result value

#### Throws

FlutterException if the envelope was an error envelope

***

### decodeMethodCall()

> **decodeMethodCall**(`methodCall`): `MethodCall`

Decodes a message call from binary.

#### Parameters

##### methodCall

`ArrayBuffer`

The binary encoding of the method call as an ArrayBuffer

#### Returns

`MethodCall`

A MethodCall representation of the binary data

***

### encodeErrorEnvelope()

> **encodeErrorEnvelope**(`errorCode`, `errorMessage`, `errorDetails`): `ArrayBuffer`

Encodes an error result into a binary envelope message.

#### Parameters

##### errorCode

`string`

An error code string

##### errorMessage

`string`

An error message string, possibly null

##### errorDetails

`Any`

Error details, possibly null. Consider supporting Error in your
    codec. This is the most common value passed to this field.

#### Returns

`ArrayBuffer`

An ArrayBuffer containing the encoded envelope

***

### encodeErrorEnvelopeWithStacktrace()

> **encodeErrorEnvelopeWithStacktrace**(`errorCode`, `errorMessage`, `errorDetails`, `errorStacktrace`): `ArrayBuffer`

Encodes an error result into a binary envelope message with the native stacktrace.

#### Parameters

##### errorCode

`string`

An error code string

##### errorMessage

`string`

An error message string, possibly null

##### errorDetails

`Any`

Error details, possibly null. Consider supporting Error in your
    codec. This is the most common value passed to this field.

##### errorStacktrace

`string`

Platform stacktrace for the error, possibly null

#### Returns

`ArrayBuffer`

An ArrayBuffer containing the encoded envelope

***

### encodeMethodCall()

> **encodeMethodCall**(`methodCall`): `ArrayBuffer`

Encodes a message call into binary.

#### Parameters

##### methodCall

`MethodCall`

A MethodCall

#### Returns

`ArrayBuffer`

An ArrayBuffer containing the encoded method call

***

### encodeSuccessEnvelope()

> **encodeSuccessEnvelope**(`result`): `ArrayBuffer`

Encodes a successful result into a binary envelope message.

#### Parameters

##### result

`Any`

The result value, possibly null

#### Returns

`ArrayBuffer`

An ArrayBuffer containing the encoded envelope
