[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: KeyboardManager

Manages keyboard events and state for Flutter.
This class coordinates between key event channels, keyboard channels, and text input handling.

## Constructors

### Constructor

> **new KeyboardManager**(`engine`, `textInputPlugin`): `KeyboardManager`

Constructs a new KeyboardManager instance.

#### Parameters

##### engine

`FlutterEngine`

The FlutterEngine instance

##### textInputPlugin

`TextInputPlugin`

The TextInputPlugin instance

#### Returns

`KeyboardManager`

## Properties

### keyEmbedderResponder

> `protected` **keyEmbedderResponder**: `KeyEmbedderResponder`

The key embedder responder for handling key events.

## Methods

### getKeyboardState()

> **getKeyboardState**(): `Map`\<`number`, `number`\>

Gets the current keyboard state (pressed keys).

#### Returns

`Map`\<`number`, `number`\>

A map of pressed key codes

***

### onKeyEvent()

> **onKeyEvent**(`event`): `boolean`

Handles key events.

#### Parameters

##### event

`KeyEvent`

The key event

#### Returns

`boolean`

Whether the event was handled

***

### onKeyPreIme()

> **onKeyPreIme**(`event`): `boolean`

Handles key events before they are processed by the input method editor.

#### Parameters

##### event

`KeyEvent`

The key event

#### Returns

`boolean`

Whether the event was handled
