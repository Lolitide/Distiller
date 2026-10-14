[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: StreamHandler

Handler of stream setup and teardown requests.

Implementations must be prepared to accept sequences of alternating calls to onListen and onCancel.
Implementations should ideally consume no resources when the last such call is not onListen.
In typical situations, this means that the implementation should register itself with 
platform-specific event sources onListen and deregister again onCancel.

## Methods

### onCancel()

> **onCancel**(`args`): `void`

Handles a request to tear down the most recently created event stream.

Any uncaught exception thrown by this method will be caught by the channel implementation
and logged. An error result message will be sent back to Flutter.

The channel implementation may call this method with null arguments to separate a pair of
two consecutive set up requests. Such request pairs may occur during Flutter hot restart. Any
uncaught exception thrown in this situation will be logged without notifying Flutter.

#### Parameters

##### args

`Any`

Stream configuration arguments, possibly null

#### Returns

`void`

***

### onListen()

> **onListen**(`args`, `events`): `void`

Handles a request to set up an event stream.

Any uncaught exception thrown by this method will be caught by the channel implementation
and logged. An error result message will be sent back to Flutter.

#### Parameters

##### args

`Any`

Stream configuration arguments, possibly null

##### events

[`EventSink`](EventSink.md)

An [EventSink](EventSink.md) for emitting events to the Flutter receiver

#### Returns

`void`
