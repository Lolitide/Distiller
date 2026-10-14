[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: KeyEventHandler

Handler for key events in emulator/hdc tool input scenarios.

In the emulator/hdc tool input scenario, all keyevents will be passed to the onKeyEvent callback,
so we need to insert the text to textInputPlugin ourselves. In other scenarios like phone/pc/ets,
the input method will be responsible for inserting the text to textInputPlugin, consuming 'down' events
and letting 'up' events go which will be captured by onKeyEvent.

There is no need to process the status of the capslock button. Because in the scenario of the emulator/hdc tool,
if capslock is pressed, os will send a 'shift' keyevent before the keyevent of the input key and we will insert
uppercase characters correctly.

## Constructors

### Constructor

> **new KeyEventHandler**(`textInputPlugin?`): `KeyEventHandler`

Constructs a new KeyEventHandler instance.

#### Parameters

##### textInputPlugin?

`TextInputPlugin`

The TextInputPlugin instance, optional

#### Returns

`KeyEventHandler`

## Methods

### endDeletion()

> **endDeletion**(`code`): `void`

Ends a deletion operation.

#### Parameters

##### code

`number`

The key code for deletion

#### Returns

`void`

***

### getKeyText()

> **getKeyText**(`event`): `string`

Gets the text representation of a key event.

#### Parameters

##### event

`KeyEvent`

The key event

#### Returns

`string`

The text string for the key, considering shift state

***

### handleKeyEvent()

> **handleKeyEvent**(`event`): `void`

Handles a key event and inserts text if appropriate.

#### Parameters

##### event

`KeyEvent`

The key event to handle

#### Returns

`void`

***

### startDeleting()

> **startDeleting**(`code`): `void`

Starts a deletion operation.

#### Parameters

##### code

`number`

The key code for deletion

#### Returns

`void`
