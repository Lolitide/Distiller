[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: BasicMessageChannel\<T\>

A named channel for communicating with the Flutter application using basic, asynchronous message
passing.

Messages are encoded into binary before being sent, and binary messages received are decoded
into objects. The [MessageCodec](../../MessageCodec/interfaces/MessageCodec.md) used must be compatible with the one used by the
Flutter application. This can be achieved by creating a `BasicMessageChannel`
counterpart of this channel on the Dart side. The static type of messages sent and received
is `Object`, but only values supported by the specified [MessageCodec](../../MessageCodec/interfaces/MessageCodec.md) can be used.

The logical identity of the channel is given by its name. Identically named channels will
interfere with each other's communication.

## Type Parameters

### T

`T`

## Constructors

### Constructor

> **new BasicMessageChannel**\<`T`\>(`messenger`, `name`, `codec`): `BasicMessageChannel`\<`T`\>

Constructs a new BasicMessageChannel instance.

#### Parameters

##### messenger

[`BinaryMessenger`](../../BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger to use for communication

##### name

`string`

The channel name

##### codec

[`MessageCodec`](../../MessageCodec/interfaces/MessageCodec.md)\<`T`\>

The MessageCodec to use for encoding/decoding messages

#### Returns

`BasicMessageChannel`\<`T`\>

## Properties

### CHANNEL\_BUFFERS\_CHANNEL

> `static` **CHANNEL\_BUFFERS\_CHANNEL**: `string` = `"dev.flutter/channel-buffers"`

Channel name for buffer management.

***

### TAG

> `static` **TAG**: `string` = `"BasicMessageChannel#"`

Tag for logging.

## Methods

### resizeChannelBuffer()

> **resizeChannelBuffer**(`newSize`): `void`

Adjusts the number of messages that will get buffered when sending messages to channels that
aren't fully set up yet. For example, the engine isn't running yet or the channel's message
handler isn't set up on the Dart side yet.

#### Parameters

##### newSize

`number`

The new buffer size

#### Returns

`void`

***

### send()

> **send**(`message`, `callback?`): `void`

Sends the specified message to the Flutter application, optionally expecting a reply.

Any uncaught exception thrown by the reply callback will be caught and logged.

#### Parameters

##### message

`T`

The message, possibly null

##### callback?

(`reply`) => `void`

A [Reply](../interfaces/Reply.md) callback, possibly null

#### Returns

`void`

***

### setMessageHandler()

> **setMessageHandler**(`handler`): `void`

Registers a message handler on this channel for receiving messages sent from the Flutter
application.

Overrides any existing handler registration for (the name of) this channel.

If no handler has been registered, any incoming message on this channel will be handled
silently by sending a null reply.

#### Parameters

##### handler

[`MessageHandler`](../interfaces/MessageHandler.md)\<`T`\>

A [MessageHandler](../interfaces/MessageHandler.md), or null to deregister

#### Returns

`void`
