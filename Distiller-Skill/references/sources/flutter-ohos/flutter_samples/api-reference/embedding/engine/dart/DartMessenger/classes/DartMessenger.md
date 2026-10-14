[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DartMessenger

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

## Implements

- [`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)
- [`PlatformMessageHandler`](../../PlatformMessageHandler/interfaces/PlatformMessageHandler.md)

## Constructors

### Constructor

> **new DartMessenger**(`flutterNapi`): `DartMessenger`

Constructs a new DartMessenger instance.

#### Parameters

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

#### Returns

`DartMessenger`

## Properties

### createdTaskQueues

> **createdTaskQueues**: `Map`\<[`TaskQueue`](../../../../../plugin/common/BinaryMessenger/interfaces/TaskQueue.md), `DartMessengerTaskQueue`\>

Map of TaskQueue tokens to their actual task queue implementations.

***

### flutterNapi

> **flutterNapi**: `FlutterNapi`

The FlutterNapi instance for native communication.

***

### messageHandlers

> **messageHandlers**: `Map`\<`String`, `HandlerInfo`\>

Map of channel names to their message handlers.

***

### nextReplyId

> **nextReplyId**: `number` = `1`

The next reply ID to use for message callbacks.

***

### pendingReplies

> **pendingReplies**: `Map`\<`number`, [`BinaryReply`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryReply.md)\>

Map of reply IDs to their callback functions waiting for responses.

***

### taskQueueFactory

> **taskQueueFactory**: `TaskQueueFactory`

Factory for creating task queues for background message processing.

## Methods

### dispatchMessageToQueue()

> **dispatchMessageToQueue**(`handlerInfo`, `message`, `replyId`): `void`

Dispatches a message to a task queue for asynchronous processing.

#### Parameters

##### handlerInfo

`HandlerInfo`

The handler information containing the handler and task queue

##### message

`ArrayBuffer`

The message data as an ArrayBuffer

##### replyId

`number`

The reply ID for responding to the message

#### Returns

`void`

***

### getPendingChannelResponseCount()

> **getPendingChannelResponseCount**(): `number`

Returns the number of pending channel callback replies.

When sending messages to the Flutter application using BinaryMessenger.send,
developers can optionally specify a reply callback if they expect a reply from the Flutter application.

This method tracks all the pending callbacks that are waiting for response, and is supposed
to be called from the main thread (as other methods). Calling from a different thread could
possibly capture an indeterministic internal state, so don't do it.

#### Returns

`number`

The number of pending channel callback replies

***

### handleMessageFromDart()

> **handleMessageFromDart**(`channel`, `message`, `replyId`, `messageData`): `void`

Handles a message received from Dart over a specific channel.

#### Parameters

##### channel

`String`

The channel name for the message

##### message

`ArrayBuffer`

The message data as an ArrayBuffer

##### replyId

`number`

The reply ID for responding to the message

##### messageData

`number`

Additional message data

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../PlatformMessageHandler/interfaces/PlatformMessageHandler.md).[`handleMessageFromDart`](../../PlatformMessageHandler/interfaces/PlatformMessageHandler.md#handlemessagefromdart)

***

### handlePlatformMessageResponse()

> **handlePlatformMessageResponse**(`replyId`, `reply`): `void`

Handles a platform message response from Dart.

#### Parameters

##### replyId

`number`

The reply ID that was sent with the original message

##### reply

`ArrayBuffer`

The reply data as an ArrayBuffer

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../PlatformMessageHandler/interfaces/PlatformMessageHandler.md).[`handlePlatformMessageResponse`](../../PlatformMessageHandler/interfaces/PlatformMessageHandler.md#handleplatformmessageresponse)

***

### invokeHandler()

> **invokeHandler**(`handler`, `message`, `replyId`): `void`

Invokes a message handler synchronously.

#### Parameters

##### handler

[`BinaryMessageHandler`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessageHandler.md)

The message handler to invoke, or null if no handler is registered

##### message

`ArrayBuffer`

The message data as an ArrayBuffer

##### replyId

`number`

The reply ID for responding to the message

#### Returns

`void`

***

### IsFlutterNavigationExecuted()

> **IsFlutterNavigationExecuted**(`channel`): `void`

Checks if the current Flutter page is performing navigation and notifies the native side.

#### Parameters

##### channel

`String`

The channel name to check

#### Returns

`void`

***

### makeBackgroundTaskQueue()

> **makeBackgroundTaskQueue**(`options?`): [`TaskQueue`](../../../../../plugin/common/BinaryMessenger/interfaces/TaskQueue.md)

Creates a background task queue for handling messages asynchronously.

#### Parameters

##### options?

[`TaskQueueOptions`](../../../../../plugin/common/BinaryMessenger/classes/TaskQueueOptions.md)

Optional task queue configuration options

#### Returns

[`TaskQueue`](../../../../../plugin/common/BinaryMessenger/interfaces/TaskQueue.md)

A TaskQueue instance for background message processing

#### Implementation of

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md).[`makeBackgroundTaskQueue`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md#makebackgroundtaskqueue)

***

### send()

> **send**(`channel`, `message`, `callback?`): `void`

Sends a binary message to Dart over the specified channel.

#### Parameters

##### channel

`String`

The channel name for the message

##### message

`ArrayBuffer`

The message data as an ArrayBuffer, or null for an empty message

##### callback?

[`BinaryReply`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryReply.md)

Optional callback to receive the reply from Dart

#### Returns

`void`

#### Implementation of

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md).[`send`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md#send)

***

### setMessageHandler()

> **setMessageHandler**(`channel`, `handler`, `taskQueue?`, ...`args?`): `void`

Sets a message handler for incoming messages from Dart on the specified channel.

#### Parameters

##### channel

`String`

The channel name to listen on

##### handler

The message handler, or null to remove the handler

[`BinaryMessageHandler`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessageHandler.md) | [`SendableBinaryMessageHandler`](../../../../../plugin/common/SendableBinaryMessageHandler/interfaces/SendableBinaryMessageHandler.md)

##### taskQueue?

[`TaskQueue`](../../../../../plugin/common/BinaryMessenger/interfaces/TaskQueue.md)

Optional task queue for processing messages

##### args?

...`Object`[]

Additional arguments to pass to the handler

#### Returns

`void`

#### Implementation of

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md).[`setMessageHandler`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md#setmessagehandler)
