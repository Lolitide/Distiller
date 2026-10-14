[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: IncomingMethodCallHandler

Internal handler for incoming method calls from Flutter.

## Implements

- [`BinaryMessageHandler`](../../BinaryMessenger/interfaces/BinaryMessageHandler.md)

## Constructors

### Constructor

> **new IncomingMethodCallHandler**(`handler`, `codec`): `IncomingMethodCallHandler`

Constructs a new IncomingMethodCallHandler instance.

#### Parameters

##### handler

[`MethodCallHandler`](../interfaces/MethodCallHandler.md)

The MethodCallHandler to delegate to

##### codec

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md)

The MethodCodec to use for encoding/decoding

#### Returns

`IncomingMethodCallHandler`

## Methods

### onMessage()

> **onMessage**(`message`, `reply`): `void`

Handles a binary method call from Flutter.

#### Parameters

##### message

`ArrayBuffer`

The binary message containing the method call

##### reply

[`BinaryReply`](../../BinaryMessenger/interfaces/BinaryReply.md)

The BinaryReply callback to send a response

#### Returns

`void`

#### Implementation of

[`BinaryMessageHandler`](../../BinaryMessenger/interfaces/BinaryMessageHandler.md).[`onMessage`](../../BinaryMessenger/interfaces/BinaryMessageHandler.md#onmessage)
