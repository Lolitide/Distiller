[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: MessageHandler\<T\>

Interface for handling incoming messages in BasicMessageChannel.

## Type Parameters

### T

`T`

The type of message being handled

## Methods

### onMessage()

> **onMessage**(`message`, `reply`): `void`

Handles the specified message received from Flutter.

Handler implementations must reply to all incoming messages, by submitting a single reply
message to the given [Reply](Reply.md). Failure to do so will result in lingering Flutter reply
handlers. The reply may be submitted asynchronously and invoked on any thread.

Any uncaught exception thrown by this method, or the preceding message decoding, will be
caught by the channel implementation and logged, and a null reply message will be sent back
to Flutter.

Any uncaught exception thrown during encoding a reply message submitted to the [Reply](Reply.md)
is treated similarly: the exception is logged, and a null reply is sent to Flutter.

#### Parameters

##### message

`T`

The message, possibly null

##### reply

[`Reply`](Reply.md)\<`T`\>

A [Reply](Reply.md) for sending a single message reply back to Flutter

#### Returns

`void`
