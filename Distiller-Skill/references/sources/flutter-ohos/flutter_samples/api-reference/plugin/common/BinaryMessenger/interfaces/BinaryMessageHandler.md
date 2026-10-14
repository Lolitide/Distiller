[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: BinaryMessageHandler

Handler for incoming binary messages from Flutter.

## Methods

### onMessage()

> **onMessage**(`message`, `reply`): `void`

Handles the specified message.

Handler implementations must reply to all incoming messages, by submitting a single reply
message to the given [BinaryReply](BinaryReply.md). Failure to do so will result in lingering Flutter
reply handlers. The reply may be submitted asynchronously.

Any uncaught exception thrown by this method will be caught by the messenger
implementation and logged, and a null reply message will be sent back to Flutter.

#### Parameters

##### message

`ArrayBuffer`

The message ArrayBuffer payload, possibly null

##### reply

[`BinaryReply`](BinaryReply.md)

A [BinaryReply](BinaryReply.md) used for submitting a reply back to Flutter

#### Returns

`void`
