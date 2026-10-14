[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: MethodChannel

A named channel for communicating with the Flutter application using asynchronous method calls.

Incoming method calls are decoded from binary on receipt, and results are encoded into
binary before being transmitted back to Flutter. The [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) used must be compatible
with the one used by the Flutter application. This can be achieved by creating a `MethodChannel` counterpart of this
channel on the Dart side. The type of method call arguments and results is Any,
but only values supported by the specified [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) can be used.

The logical identity of the channel is given by its name. Identically named channels will
interfere with each other's communication.

## Constructors

### Constructor

> **new MethodChannel**(`messenger`, `name`, `codec`): `MethodChannel`

Constructs a new MethodChannel instance.

#### Parameters

##### messenger

[`BinaryMessenger`](../../BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger to use for communication

##### name

`string`

The channel name

##### codec

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md) = `StandardMethodCodec.INSTANCE`

The MethodCodec to use for encoding/decoding, defaults to StandardMethodCodec.INSTANCE

#### Returns

`MethodChannel`

## Properties

### TAG

> `static` **TAG**: `string` = `"MethodChannel#"`

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

[`MethodResult`](../interfaces/MethodResult.md)

A [MethodResult](../interfaces/MethodResult.md) callback for the invocation result, or null

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
silently by sending a null reply. This results in a `MissingPluginException` on the Dart side, unless an
`OptionalMethodChannel` is used.

#### Parameters

##### handler

[`MethodCallHandler`](../interfaces/MethodCallHandler.md)

A [MethodCallHandler](../interfaces/MethodCallHandler.md), or null to deregister

#### Returns

`void`
