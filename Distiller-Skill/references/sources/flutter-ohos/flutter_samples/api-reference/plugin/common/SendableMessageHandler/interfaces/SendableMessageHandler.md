[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: SendableMessageHandler\<T\>

Interface for sendable message handlers that can be used in background threads.
This interface extends ISendable to allow handlers to be passed across thread boundaries.

## Extends

- `ISendable`

## Type Parameters

### T

`T`

The type of message being handled

## Methods

### onMessage()

> **onMessage**(`message`, `reply`): `void`

Handles a message received from Flutter.

#### Parameters

##### message

`T`

The message received

##### reply

[`Reply`](../../BasicMessageChannel/interfaces/Reply.md)\<`T`\>

The reply callback to send a response

#### Returns

`void`
