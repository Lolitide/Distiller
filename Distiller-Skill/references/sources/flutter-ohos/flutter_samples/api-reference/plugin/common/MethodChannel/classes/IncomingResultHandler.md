[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: IncomingResultHandler

Internal handler for incoming method call results from Flutter.

## Implements

- [`BinaryReply`](../../BinaryMessenger/interfaces/BinaryReply.md)

## Constructors

### Constructor

> **new IncomingResultHandler**(`callback`, `codec`): `IncomingResultHandler`

Constructs a new IncomingResultHandler instance.

#### Parameters

##### callback

[`MethodResult`](../interfaces/MethodResult.md)

The MethodResult callback to invoke

##### codec

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md)

The MethodCodec to use for decoding

#### Returns

`IncomingResultHandler`

## Methods

### reply()

> **reply**(`reply`): `void`

Handles the specified reply.

#### Parameters

##### reply

`ArrayBuffer`

The binary reply, possibly null

#### Returns

`void`

#### Implementation of

[`BinaryReply`](../../BinaryMessenger/interfaces/BinaryReply.md).[`reply`](../../BinaryMessenger/interfaces/BinaryReply.md#reply)
