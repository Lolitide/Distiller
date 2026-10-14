[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: EventResponseHandler

Interface for handling event responses from the Flutter framework.
Implementations of this interface receive callbacks when Flutter processes
key events and indicates whether the event was handled.

## Properties

### onFrameworkResponse()

> **onFrameworkResponse**: (`isEventHandled`) => `void`

Called when Flutter responds to a key event.
This callback is invoked asynchronously after Flutter processes the key event.

#### Parameters

##### isEventHandled

`boolean`

Whether Flutter handled the event (true) or not (false)

#### Returns

`void`
