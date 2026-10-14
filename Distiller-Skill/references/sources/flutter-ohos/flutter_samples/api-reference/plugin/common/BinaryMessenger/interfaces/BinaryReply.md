[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: BinaryReply

Binary message reply callback. Used to submit a reply to an incoming message from Flutter. Also
used in the dual capacity to handle a reply received from Flutter after sending a message.

## Properties

### reply()

> **reply**: (`reply`) => `void`

Handles the specified reply.

#### Parameters

##### reply

`ArrayBuffer`

The reply payload, an ArrayBuffer or null. Senders of
    outgoing replies must place the reply bytes in the buffer.
    Reply receivers can read from the buffer directly.

#### Returns

`void`
