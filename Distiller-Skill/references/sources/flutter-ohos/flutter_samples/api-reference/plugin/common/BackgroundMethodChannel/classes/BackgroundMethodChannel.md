[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: BackgroundMethodChannel

A named channel for communicating with Flutter using asynchronous method calls on background threads.
This channel uses sendable codecs that can be passed across thread boundaries.

Incoming method calls are decoded from binary on receipt, and results are encoded into
binary before being transmitted back to Flutter. The [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) used must be compatible
with the one used by the Flutter application. This can be achieved by creating a `MethodChannel`
counterpart of this channel on the Dart side. The type of method call arguments and results
is Any, but only values supported by the specified [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) can be used.

The logical identity of the channel is given by its name. Identically named channels will
interfere with each other's communication.

## Constructors

### Constructor

> **new BackgroundMethodChannel**(`messenger`, `name`, `codec`, `taskQueue?`, ...`args?`): `BackgroundMethodChannel`

Constructs a new BackgroundMethodChannel instance.

#### Parameters

##### messenger

[`BinaryMessenger`](../../BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger to use for communication

##### name

`string`

The channel name

##### codec

[`SendableMethodCodec`](../../SendableMethodCodec/interfaces/SendableMethodCodec.md) = `SendableStandardMethodCodec.INSTANCE`

The SendableMethodCodec to use for encoding/decoding, defaults to SendableStandardMethodCodec.INSTANCE

##### taskQueue?

[`TaskQueue`](../../BinaryMessenger/interfaces/TaskQueue.md)

Optional TaskQueue for background processing, defaults to a new background task queue

##### args?

...`Object`[]

Additional arguments to pass to message handlers

#### Returns

`BackgroundMethodChannel`

## Properties

### TAG

> `static` **TAG**: `string` = `"BackgroundMethodChannel#"`

Tag for logging.

## Methods

### invokeMethod()

> **invokeMethod**(`method`, `args`, `callback?`): `void`

Invokes a method on this channel, optionally expecting a result.

Any uncaught exception thrown by the result callback will be caught and logged.

#### Parameters

##### method

`string`

The name of the method

##### args

`Any`

The arguments for the invocation, possibly null

##### callback?

[`MethodResult`](../../MethodChannel/interfaces/MethodResult.md)

A [MethodResult](../../MethodChannel/interfaces/MethodResult.md) callback for the invocation result, or null

#### Returns

`void`

***

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

### setMethodCallHandler()

> **setMethodCallHandler**(`handler`): `void`

Registers a method call handler on this channel.

Overrides any existing handler registration for (the name of) this channel.

If no handler has been registered, any incoming method call on this channel will be handled
silently by sending a null reply. This results in a `MissingPluginException` 
on the Dart side, unless an `OptionalMethodChannel` is used.

#### Parameters

##### handler

[`SendableMethodCallHandler`](../../SendableMethodCallHandler/interfaces/SendableMethodCallHandler.md)

A [SendableMethodCallHandler](../../SendableMethodCallHandler/interfaces/SendableMethodCallHandler.md), or null to deregister

#### Returns

`void`
