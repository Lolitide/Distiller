[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: TextInputChannel

TextInputChannel is a platform channel between OpenHarmony and Flutter that is used to
communicate information about the user's text input.

When the user presses an action button like "done" or "next", that action is sent from
OpenHarmony to Flutter through this TextInputChannel.

When an input system in the Flutter app wants to show the keyboard, or hide it, or configure
editing state, etc. a message is sent from Flutter to OpenHarmony through this TextInputChannel.

TextInputChannel comes with a default MethodChannel.MethodCallHandler that parses incoming
messages from Flutter. Implement TextInputMethodHandler and register it via
setTextInputMethodHandler() to respond to standard Flutter text input messages.

## Constructors

### Constructor

> **new TextInputChannel**(`dartExecutor`): `TextInputChannel`

Constructs a new TextInputChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`TextInputChannel`

## Properties

### channel

> **channel**: `MethodChannel`

The MethodChannel for text input communication with Flutter.

***

### textInputMethodHandler

> **textInputMethodHandler**: [`TextInputMethodHandler`](../interfaces/TextInputMethodHandler.md) = `null`

The text input method handler for processing text input requests, or null if not set.

## Methods

### commitContent()

> **commitContent**(`inputClientId`): `void`

Sends a commit content action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### createEditingDeltaJSON()

> **createEditingDeltaJSON**(`batchDeltas`): `EditingDelta`

Creates an editing delta JSON object from a batch of deltas.

#### Parameters

##### batchDeltas

`ArrayList`\<[`TextEditingDelta`](../../../../../plugin/editing/TextEditingDelta/classes/TextEditingDelta.md)\>

Array list of text editing deltas

#### Returns

`EditingDelta`

The editing delta object

***

### createEditingStateJSON()

> **createEditingStateJSON**(`text`, `selectionStart`, `selectionEnd`, `composingStart`, `composingEnd`): `EditingState`

Creates an editing state JSON object.

#### Parameters

##### text

`string`

The text content

##### selectionStart

`number`

The start of the selection

##### selectionEnd

`number`

The end of the selection

##### composingStart

`number`

The start of the composing region

##### composingEnd

`number`

The end of the composing region

#### Returns

`EditingState`

The editing state object

***

### done()

> **done**(`inputClientId`): `void`

Sends a done action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### getKeyboardFocusState()

> **getKeyboardFocusState**(): `boolean`

Gets the keyboard focus state.

#### Returns

`boolean`

Whether the keyboard has focus

***

### go()

> **go**(`inputClientId`): `void`

Sends a go action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### newline()

> **newline**(`inputClientId`): `void`

Sends a newline action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### next()

> **next**(`inputClientId`): `void`

Sends a next action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### onConnectionClosed()

> **onConnectionClosed**(`inputClientId`): `void`

Notifies Flutter that the input connection has been closed.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### performPrivateCommand()

> **performPrivateCommand**(`inputClientId`, `action`, `data`): `void`

Performs a private command.

#### Parameters

##### inputClientId

`number`

The input client ID

##### action

`string`

The action string

##### data

`Any`

The command data

#### Returns

`void`

***

### previous()

> **previous**(`inputClientId`): `void`

Sends a previous action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### requestExistingInputState()

> **requestExistingInputState**(): `void`

Requests the existing input state from Flutter.

#### Returns

`void`

***

### search()

> **search**(`inputClientId`): `void`

Sends a search action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### send()

> **send**(`inputClientId`): `void`

Sends a send action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### setDevicePixelRatio()

> **setDevicePixelRatio**(`devicePixelRatio`): `void`

Sets the device pixel ratio.

#### Parameters

##### devicePixelRatio

`number`

The device pixel ratio value

#### Returns

`void`

***

### setTextInputMethodHandler()

> **setTextInputMethodHandler**(`textInputMethodHandler`): `void`

Sets the text input method handler.

#### Parameters

##### textInputMethodHandler

[`TextInputMethodHandler`](../interfaces/TextInputMethodHandler.md)

The TextInputMethodHandler instance, or null to remove

#### Returns

`void`

***

### setWindowPosition()

> **setWindowPosition**(`windowPosition`): `void`

Sets the window position for text input.

#### Parameters

##### windowPosition

`Rect`

The window position rectangle

#### Returns

`void`

***

### unspecifiedAction()

> **unspecifiedAction**(`inputClientId`): `void`

Sends an unspecified action to Flutter.

#### Parameters

##### inputClientId

`number`

The input client ID

#### Returns

`void`

***

### updateEditingState()

> **updateEditingState**(`inputClientId`, `text`, `selectionStart`, `selectionEnd`, `composingStart`, `composingEnd`): `void`

Instructs Flutter to update its text input editing state to reflect the given configuration.

#### Parameters

##### inputClientId

`number`

##### text

`string`

##### selectionStart

`number`

##### selectionEnd

`number`

##### composingStart

`number`

##### composingEnd

`number`

#### Returns

`void`

***

### updateEditingStateWithDeltas()

> **updateEditingStateWithDeltas**(`inputClientId`, `batchDeltas`): `void`

Updates the editing state with deltas.

#### Parameters

##### inputClientId

`number`

The input client ID

##### batchDeltas

`ArrayList`\<[`TextEditingDelta`](../../../../../plugin/editing/TextEditingDelta/classes/TextEditingDelta.md)\>

Array list of text editing deltas

#### Returns

`void`
