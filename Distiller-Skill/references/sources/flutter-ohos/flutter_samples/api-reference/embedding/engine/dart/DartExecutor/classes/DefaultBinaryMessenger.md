[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DefaultBinaryMessenger

Default implementation of BinaryMessenger that delegates to DartMessenger.

## Implements

- [`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

## Constructors

### Constructor

> **new DefaultBinaryMessenger**(`messenger`): `DefaultBinaryMessenger`

Constructs a new DefaultBinaryMessenger instance.

#### Parameters

##### messenger

[`DartMessenger`](../../DartMessenger/classes/DartMessenger.md)

The DartMessenger instance to delegate to

#### Returns

`DefaultBinaryMessenger`

## Methods

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

Sends a message from OpenHarmony to Dart over the given channel and then
has the provided callback invoked when the Dart side responds.

#### Parameters

##### channel

`String`

The name of the logical channel used for the message

##### message

`ArrayBuffer`

The message payload as an ArrayBuffer, or null for an empty message

##### callback?

[`BinaryReply`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryReply.md)

A callback invoked when the Dart application responds to the message

#### Returns

`void`

#### Implementation of

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md).[`send`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md#send)

***

### setMessageHandler()

> **setMessageHandler**(`channel`, `handler`, `taskQueue?`, ...`args?`): `void`

Sets the given BinaryMessageHandler as the singular handler for all incoming messages
received from the Dart side of this Dart execution context.

#### Parameters

##### channel

`String`

The name of the channel

##### handler

A BinaryMessageHandler to be invoked on incoming messages, or null

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
