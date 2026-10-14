[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DartExecutor

Configures, bootstraps, and starts executing Dart code.

To specify a top-level Dart function to execute, use a [DartEntrypoint](DartEntrypoint.md) to tell
DartExecutor where to find the Dart code to execute, and which Dart function to use as the
entrypoint. To execute the entrypoint, pass the [DartEntrypoint](DartEntrypoint.md) to
[executeDartEntrypoint](#executedartentrypoint).

To specify a Dart callback to execute, use a [DartCallback](DartCallback.md). A given Dart callback must
be registered with the Dart VM to be invoked by a DartExecutor. To execute the callback,
pass the [DartCallback](DartCallback.md) to [executeDartCallback](#executedartcallback).

Once started, a DartExecutor cannot be stopped. The associated Dart code will execute
until it completes, or until the FlutterEngine that owns this
DartExecutor is destroyed.

## Implements

- [`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

## Constructors

### Constructor

> **new DartExecutor**(`flutterNapi`, `assetManager`): `DartExecutor`

Constructs a new DartExecutor instance.

#### Parameters

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

##### assetManager

`ResourceManager`

The resource manager for accessing assets

#### Returns

`DartExecutor`

## Properties

### assetManager

> **assetManager**: `ResourceManager`

The resource manager for accessing application assets.

***

### flutterNapi

> **flutterNapi**: `FlutterNapi`

The FlutterNapi instance for native communication.

## Methods

### executeDartCallback()

> **executeDartCallback**(`dartCallback`): `void`

Starts executing Dart code based on the given dartCallback.

See DartCallback for configuration options.

#### Parameters

##### dartCallback

[`DartCallback`](DartCallback.md)

Specifies which Dart callback to run, and where to find it

#### Returns

`void`

***

### executeDartEntrypoint()

> **executeDartEntrypoint**(`dartEntrypoint`, `dartEntrypointArgs?`): `void`

Starts executing Dart code based on the given dartEntrypoint and the dartEntrypointArgs.

See DartEntrypoint for configuration options.

#### Parameters

##### dartEntrypoint

[`DartEntrypoint`](DartEntrypoint.md)

Specifies which Dart function to run, and where to find it

##### dartEntrypointArgs?

`string`[]

Arguments passed as a list of strings to Dart's entrypoint function

#### Returns

`void`

***

### getBinaryMessenger()

> **getBinaryMessenger**(): [`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

Gets a BinaryMessenger that can be used to send messages to, and receive messages
from, Dart code that this DartExecutor is executing.

#### Returns

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger instance

***

### getIsolateServiceId()

> **getIsolateServiceId**(): `String`

Gets an identifier for this executor's primary isolate. This identifier can be used in
queries to the Dart service protocol.

#### Returns

`String`

The isolate service ID

***

### getPendingChannelResponseCount()

> **getPendingChannelResponseCount**(): `number`

Gets the number of pending channel callback replies.
When sending messages with reply callbacks, this tracks how many are still waiting for responses.
Must be called from the main thread.
Mainly useful for testing frameworks to determine if the app is idle.

#### Returns

`number`

The number of pending channel callback replies

***

### isExecutingDart()

> **isExecutingDart**(): `boolean`

Checks if this DartExecutor is currently executing Dart code.

#### Returns

`boolean`

True if Dart code is being executed, false otherwise

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

### notifyLowMemoryWarning()

> **notifyLowMemoryWarning**(): `void`

Notifies the Dart VM of a low memory event.
This allows the Dart VM to free resources, but does not notify the Flutter application.
To notify the Flutter application, use SystemChannel.sendMemoryPressureWarning().

Note: Calling this method may cause performance issues. Avoid calling during startup or animations.

#### Returns

`void`

***

### onAttachedToNAPI()

> **onAttachedToNAPI**(): `void`

Invoked when the FlutterEngine that owns this DartExecutor attaches to NAPI.

When attached to NAPI, this DartExecutor begins handling 2-way communication to/from
the Dart execution context. This communication is facilitated via 2 APIs:
BinaryMessenger, which sends messages to Dart
PlatformMessageHandler, which receives messages from Dart

#### Returns

`void`

***

### onDetachedFromNAPI()

> **onDetachedFromNAPI**(): `void`

Invoked when the FlutterEngine that owns this DartExecutor detaches from NAPI.

When detached from NAPI, this DartExecutor stops handling 2-way communication to/from
the Dart execution context.

#### Returns

`void`

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

The message data as an ArrayBuffer

##### callback?

[`BinaryReply`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryReply.md)

Optional callback to receive the reply from Dart

#### Returns

`void`

#### Implementation of

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md).[`send`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md#send)

***

### setIsolateServiceIdListener()

> **setIsolateServiceIdListener**(`listener`): `void`

Sets a listener that will be notified when an isolate identifier is available for this
executor's primary isolate.

#### Parameters

##### listener

`IsolateServiceIdListener`

The listener to be notified when the isolate service ID is available

#### Returns

`void`

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
