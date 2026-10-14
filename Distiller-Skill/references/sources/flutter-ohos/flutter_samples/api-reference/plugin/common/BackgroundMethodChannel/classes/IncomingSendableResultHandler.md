[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: IncomingSendableResultHandler

Internal handler for incoming method call results from Flutter in background threads.

## Implements

- [`BinaryReply`](../../BinaryMessenger/interfaces/BinaryReply.md)

## Constructors

### Constructor

> **new IncomingSendableResultHandler**(`callback`, `codec`): `IncomingSendableResultHandler`

Constructs a new IncomingSendableResultHandler instance.

#### Parameters

##### callback

[`MethodResult`](../../MethodChannel/interfaces/MethodResult.md)

The MethodResult callback to invoke

##### codec

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md)

The SendableMethodCodec to use for decoding

#### Returns

`IncomingSendableResultHandler`

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
