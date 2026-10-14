[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: KeyEventChannel

Channel for handling keyboard key events between OpenHarmony and Flutter.
This channel manages communication of key events, including both hardware keyboard events
and simulated key events for soft-keyboard text-editing. It uses a BasicMessageChannel
with JSON encoding to send key event data to the Flutter framework.

## Constructors

### Constructor

> **new KeyEventChannel**(`binaryMessenger`): `KeyEventChannel`

Constructs a new KeyEventChannel instance.

#### Parameters

##### binaryMessenger

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger for sending messages to Dart

#### Returns

`KeyEventChannel`

## Methods

### sendFlutterKeyEvent()

> **sendFlutterKeyEvent**(`keyEvent`, `isKeyUp`, `responseHandler`): `void`

Sends a hardware key event to the Flutter framework.
The event is encoded and sent asynchronously. The response handler will be called
when Flutter responds, indicating whether the event was handled.

#### Parameters

##### keyEvent

[`FlutterKeyEvent`](FlutterKeyEvent.md)

The FlutterKeyEvent containing the OpenHarmony key event data

##### isKeyUp

`boolean`

Whether this is a key up event (true) or key down event (false)

##### responseHandler

[`EventResponseHandler`](../interfaces/EventResponseHandler.md)

Handler to receive the response from Flutter indicating if the event was handled

#### Returns

`void`

***

### simulateSendFlutterKeyEvent()

> **simulateSendFlutterKeyEvent**(`keyEvent`, `isKeyUp`, `responseHandler`): `void`

Sends a simulated key event for soft-keyboard text-editing in the input method.
This method is used for virtual keyboard events (e.g., arrow keys, selection keys)
that are generated programmatically rather than from hardware input.

#### Parameters

##### keyEvent

[`SimulateKeyEvent`](SimulateKeyEvent.md)

The SimulateKeyEvent containing the simulated key data

##### isKeyUp

`boolean`

Whether this is a key up event (true) or key down event (false)

##### responseHandler

[`EventResponseHandler`](../interfaces/EventResponseHandler.md)

Handler to receive the response from Flutter indicating if the event was handled

#### Returns

`void`
