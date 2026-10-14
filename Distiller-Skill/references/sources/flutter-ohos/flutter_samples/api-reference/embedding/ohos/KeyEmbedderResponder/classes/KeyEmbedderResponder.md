[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: KeyEmbedderResponder

Responder for handling key events using the embedder API.
This class converts OpenHarmony key events to Flutter key data format and sends them to Flutter.

## Implements

- [`Responder`](../../KeyboardManager/interfaces/Responder.md)

## Constructors

### Constructor

> **new KeyEmbedderResponder**(`binaryMessenger`): `KeyEmbedderResponder`

Constructs a new KeyEmbedderResponder instance.

#### Parameters

##### binaryMessenger

[`BinaryMessenger`](../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger for sending key events to Flutter

#### Returns

`KeyEmbedderResponder`

## Methods

### getPressedKeys()

> **getPressedKeys**(): `Map`\<`number`, `number`\>

Gets the currently pressed keys.

#### Returns

`Map`\<`number`, `number`\>

A map of physical key codes to logical key codes

***

### handleKeyEvent()

> **handleKeyEvent**(`event`): `boolean`

Handles a key event from OpenHarmony.

#### Parameters

##### event

`KeyEvent`

The key event to handle

#### Returns

`boolean`

Whether the event was handled

#### Implementation of

[`Responder`](../../KeyboardManager/interfaces/Responder.md).[`handleKeyEvent`](../../KeyboardManager/interfaces/Responder.md#handlekeyevent)

***

### sendKeyEvent()

> **sendKeyEvent**(`data`): `void`

Sends a key event to Flutter.

#### Parameters

##### data

`KeyData`

The KeyData to send

#### Returns

`void`

***

### synchronizeModifierKey()

> **synchronizeModifierKey**(`goal`, `truePressed`, `logicalKey`, `physicalKey`, `event`, `postSyncEvents`): `void`

Synchronizes modifier key states to match expected states.

#### Parameters

##### goal

[`ModifierGoal`](../../KeyboardMap/classes/ModifierGoal.md)

The modifier goal to synchronize

##### truePressed

`boolean`

Whether the modifier key is actually pressed

##### logicalKey

`number`

The logical key code

##### physicalKey

`number`

The physical key code

##### event

`KeyEvent`

The key event

##### postSyncEvents

`EventTaskRunner`

Task runner for post-synchronization events

#### Returns

`void`

***

### synthesizeEvent()

> **synthesizeEvent**(`isDown`, `timestamp`, `logicalKey`, `physicalKey`): `void`

Synthesizes a key event.

#### Parameters

##### isDown

`boolean`

Whether the key is down

##### timestamp

`number`

The event timestamp

##### logicalKey

`number`

The logical key code

##### physicalKey

`number`

The physical key code

#### Returns

`void`

***

### updatePressingKeys()

> **updatePressingKeys**(`physicalKey`, `logicalKey`): `void`

Updates the pressing keys record.

#### Parameters

##### physicalKey

`number`

The physical key code

##### logicalKey

`number`

The logical key code, or null if the key is released

#### Returns

`void`
