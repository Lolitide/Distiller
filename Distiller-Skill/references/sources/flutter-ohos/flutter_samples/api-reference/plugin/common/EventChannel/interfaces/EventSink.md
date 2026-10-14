[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: EventSink

Event callback. Supports dual use: Producers of events to be sent to Flutter act as clients of
this interface for sending events. Consumers of events sent from Flutter implement this
interface for handling received events (the latter facility has not been implemented yet).

## Methods

### endOfStream()

> **endOfStream**(): `void`

Consumes end of stream. Ensuing calls to success or error, if any, are ignored.

#### Returns

`void`

***

### error()

> **error**(`errorCode`, `errorMessage`, `errorDetails`): `void`

Consumes an error event.

#### Parameters

##### errorCode

`string`

An error code string

##### errorMessage

`string`

A human-readable error message, possibly null

##### errorDetails

`Any`

Error details, possibly null

#### Returns

`void`

***

### success()

> **success**(`event`): `void`

Consumes a successful event.

#### Parameters

##### event

`Any`

The event, possibly null

#### Returns

`void`
