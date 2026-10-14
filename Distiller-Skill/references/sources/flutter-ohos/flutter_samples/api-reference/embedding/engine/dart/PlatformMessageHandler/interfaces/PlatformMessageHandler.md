[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: PlatformMessageHandler

Interface for handling platform messages from Dart.
This interface provides methods to receive messages from the Dart side of the Flutter application.

## Methods

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
