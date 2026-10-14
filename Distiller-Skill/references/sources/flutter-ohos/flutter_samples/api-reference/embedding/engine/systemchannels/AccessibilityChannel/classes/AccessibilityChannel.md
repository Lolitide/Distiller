[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: AccessibilityChannel

Channel for handling accessibility-related communication between Flutter and OpenHarmony.
This channel manages accessibility features, semantics, and accessibility events.

## Implements

- [`MessageHandler`](../../../../../plugin/common/BasicMessageChannel/interfaces/MessageHandler.md)\<`object`\>

## Constructors

### Constructor

> **new AccessibilityChannel**(`dartExecutor`, `flutterNapi`): `AccessibilityChannel`

Constructs a new AccessibilityChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

#### Returns

`AccessibilityChannel`

## Methods

### dispatchSemanticsAction()

> **dispatchSemanticsAction**(`virtualViewId`, `action`): `void`

Dispatches a semantics action to Flutter.

#### Parameters

##### virtualViewId

`number`

The virtual view ID

##### action

[`Action`](../enumerations/Action.md)

The accessibility action to dispatch

#### Returns

`void`

***

### onMessage()

> **onMessage**(`message`, `reply`): `void`

Handles messages from Dart.

#### Parameters

##### message

`object`

The message object from Dart

##### reply

[`Reply`](../../../../../plugin/common/BasicMessageChannel/interfaces/Reply.md)\<`object`\>

The reply callback to send a response

#### Returns

`void`

#### Implementation of

[`MessageHandler`](../../../../../plugin/common/BasicMessageChannel/interfaces/MessageHandler.md).[`onMessage`](../../../../../plugin/common/BasicMessageChannel/interfaces/MessageHandler.md#onmessage)

***

### onOhosAccessibilityEnabled()

> **onOhosAccessibilityEnabled**(): `void`

Called when OpenHarmony accessibility is enabled.

#### Returns

`void`

***

### onOhosAccessibilityFeatures()

> **onOhosAccessibilityFeatures**(`accessibilityFeatureFlags`): `void`

Called when OpenHarmony accessibility features change.

#### Parameters

##### accessibilityFeatureFlags

`number`

The accessibility feature flags

#### Returns

`void`

***

### setAccessibilityMessageHandler()

> **setAccessibilityMessageHandler**(`handler`): `void`

Sets the accessibility message handler.

#### Parameters

##### handler

[`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md)

The AccessibilityMessageHandler instance

#### Returns

`void`
