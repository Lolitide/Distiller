[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: BinaryMessenger

Facility for communicating with Flutter using asynchronous message passing with binary messages.
The Flutter Dart code should use `BinaryMessages` to participate.

BinaryMessenger is expected to be utilized from a single thread throughout the
duration of its existence. If created on the main thread, then all invocations should take place
on the main thread. If created on a background thread, then all invocations should take place on
that background thread.

## See

 - BasicMessageChannel , which supports message passing with Strings and semi-structured
    messages.
 - MethodChannel , which supports communication using asynchronous method invocation.
 - EventChannel , which supports communication using event streams.

## Methods

### makeBackgroundTaskQueue()

> **makeBackgroundTaskQueue**(`options?`): [`TaskQueue`](TaskQueue.md)

Creates a background task queue for handling messages on background threads.

#### Parameters

##### options?

[`TaskQueueOptions`](../classes/TaskQueueOptions.md)

Optional TaskQueueOptions to configure the task queue

#### Returns

[`TaskQueue`](TaskQueue.md)

A TaskQueue instance

***

### send()

#### Call Signature

> **send**(`channel`, `message`): `void`

Sends a binary message to the Flutter application.

##### Parameters

###### channel

`String`

The name of the logical channel used for the message

###### message

`ArrayBuffer`

The message payload, an ArrayBuffer or null

##### Returns

`void`

#### Call Signature

> **send**(`channel`, `message`, `callback?`): `void`

Sends a binary message to the Flutter application, optionally expecting a reply.

Any uncaught exception thrown by the reply callback will be caught and logged.

##### Parameters

###### channel

`String`

The name of the logical channel used for the message

###### message

`ArrayBuffer`

The message payload, an ArrayBuffer or null

###### callback?

[`BinaryReply`](BinaryReply.md)

A [BinaryReply](BinaryReply.md) callback invoked when the Flutter application responds to
    the message, possibly null

##### Returns

`void`

***

### setMessageHandler()

> **setMessageHandler**(`channel`, `handler`, `taskQueue?`, ...`args?`): `void`

Registers a handler to be invoked when the Flutter application sends a message to its host
platform.

Registration overwrites any previous registration for the same channel name. Use a null
handler to deregister.

If no handler has been registered for a particular channel, any incoming message on that
channel will be handled silently by sending a null reply.

#### Parameters

##### channel

`String`

The name of the channel

##### handler

A [BinaryMessageHandler](BinaryMessageHandler.md) to be invoked on incoming messages, or null

[`BinaryMessageHandler`](BinaryMessageHandler.md) | [`SendableBinaryMessageHandler`](../../SendableBinaryMessageHandler/interfaces/SendableBinaryMessageHandler.md)

##### taskQueue?

[`TaskQueue`](TaskQueue.md)

A BinaryMessenger.TaskQueue that specifies what thread will execute
    the handler. Specifying null means execute on the platform thread

##### args?

...`Object`[]

Additional arguments

#### Returns

`void`
