[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: EventChannel

A named channel for communicating with the Flutter application using asynchronous event streams.

Incoming requests for event stream setup are decoded from binary on receipt, and
responses and events are encoded into binary before being transmitted back to Flutter. The [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md)
used must be compatible with the one used by the Flutter application. This can be achieved by creating an
`EventChannel` counterpart of this channel on the Dart side. The type of stream configuration arguments, events,
and error details is Any, but only values supported by the specified [MethodCodec](../../MethodCodec/interfaces/MethodCodec.md) can be used.

The logical identity of the channel is given by its name. Identically named channels will
interfere with each other's communication.

## Constructors

### Constructor

> **new EventChannel**(`messenger`, `name`, `codec?`, `taskQueue?`): `EventChannel`

Constructs a new EventChannel instance.

#### Parameters

##### messenger

[`BinaryMessenger`](../../BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger to use for communication

##### name

`string`

The channel name

##### codec?

[`MethodCodec`](../../MethodCodec/interfaces/MethodCodec.md)

The MethodCodec to use for encoding/decoding, defaults to StandardMethodCodec.INSTANCE

##### taskQueue?

[`TaskQueue`](../../BinaryMessenger/interfaces/TaskQueue.md)

Optional TaskQueue for background processing

#### Returns

`EventChannel`

## Methods

### setStreamHandler()

> **setStreamHandler**(`handler`): `void`

Registers a stream handler on this channel.

Overrides any existing handler registration for (the name of) this channel.

If no handler has been registered, any incoming stream setup requests will be handled
silently by providing an empty stream.

#### Parameters

##### handler

[`StreamHandler`](../interfaces/StreamHandler.md)

A [StreamHandler](../interfaces/StreamHandler.md), or null to deregister

#### Returns

`void`
