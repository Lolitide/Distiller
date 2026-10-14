[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: BackgroundBasicMessageChannel\<T\>

A named channel for communicating with Flutter using basic, asynchronous message passing
on background threads. This channel uses sendable codecs that can be passed across thread boundaries.

Messages are encoded into binary before being sent, and binary messages received are decoded
into objects. The [SendableMessageCodec](../../SendableMessageCodec/interfaces/SendableMessageCodec.md) used must be compatible with the one used by the
Flutter application. This can be achieved by creating a `BasicMessageChannel` counterpart of this channel
on the Dart side. The type of messages sent and received
is Any, but only values supported by the specified [SendableMessageCodec](../../SendableMessageCodec/interfaces/SendableMessageCodec.md) can be used.

The logical identity of the channel is given by its name. Identically named channels will
interfere with each other's communication.

## Type Parameters

### T

`T`

The type of message being sent/received

## Constructors

### Constructor

> **new BackgroundBasicMessageChannel**\<`T`\>(`messenger`, `name`, `codec`, `taskQueue?`): `BackgroundBasicMessageChannel`\<`T`\>

Constructs a new BackgroundBasicMessageChannel instance.

#### Parameters

##### messenger

[`BinaryMessenger`](../../BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger to use for communication

##### name

`string`

The channel name

##### codec

[`SendableMessageCodec`](../../SendableMessageCodec/interfaces/SendableMessageCodec.md)\<`T`\>

The SendableMessageCodec to use for encoding/decoding messages

##### taskQueue?

[`TaskQueue`](../../BinaryMessenger/interfaces/TaskQueue.md)

Optional TaskQueue for background processing, defaults to a new background task queue

#### Returns

`BackgroundBasicMessageChannel`\<`T`\>

## Properties

### CHANNEL\_BUFFERS\_CHANNEL

> `static` **CHANNEL\_BUFFERS\_CHANNEL**: `string` = `"dev.flutter/channel-buffers"`

Channel name for buffer management.

***

### TAG

> `static` **TAG**: `string` = `"BackgroundBasicMessageChannel#"`

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

A reply callback, possibly null

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

[`SendableMessageHandler`](../../SendableMessageHandler/interfaces/SendableMessageHandler.md)\<`T`\>

A [SendableMessageHandler](../../SendableMessageHandler/interfaces/SendableMessageHandler.md), or null to deregister

#### Returns

`void`
