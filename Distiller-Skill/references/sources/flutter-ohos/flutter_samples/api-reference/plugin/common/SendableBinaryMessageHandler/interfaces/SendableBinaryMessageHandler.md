[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: SendableBinaryMessageHandler

Interface for sendable binary message handlers that can be used in background threads.
This interface extends ISendable to allow handlers to be passed across thread boundaries.

## Extends

- `ISendable`

## Methods

### onMessage()

> **onMessage**(`message`, `reply`, ...`args`): `void`

Handles a binary message received from Flutter.

#### Parameters

##### message

`ArrayBuffer`

The binary message received

##### reply

[`BinaryReply`](../../BinaryMessenger/interfaces/BinaryReply.md)

The reply callback to send a response

##### args

...`Object`[]

Additional arguments passed to the handler

#### Returns

`void`
