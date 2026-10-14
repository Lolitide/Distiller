[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: MouseCursorPlugin

Plugin for handling mouse cursor changes in Flutter applications.
This class manages the interaction between Flutter's cursor system
and the OpenHarmony pointer style system.

## Implements

- [`MouseCursorMethodHandler`](../../../../embedding/engine/systemchannels/MouseCursorChannel/interfaces/MouseCursorMethodHandler.md)

## Constructors

### Constructor

> **new MouseCursorPlugin**(`windowId`, `mouseCursorChannel`): `MouseCursorPlugin`

Constructs a new MouseCursorPlugin instance.

#### Parameters

##### windowId

`number`

The window ID for setting pointer styles

##### mouseCursorChannel

`MouseCursorChannel`

The MouseCursorChannel for communication with Flutter

#### Returns

`MouseCursorPlugin`

## Methods

### activateSystemCursor()

> **activateSystemCursor**(`kind`): `void`

Activates a system cursor for the specified kind.

#### Parameters

##### kind

`string`

The cursor kind (e.g., "click", "text", "move")

#### Returns

`void`

#### Implementation of

[`MouseCursorMethodHandler`](../../../../embedding/engine/systemchannels/MouseCursorChannel/interfaces/MouseCursorMethodHandler.md).[`activateSystemCursor`](../../../../embedding/engine/systemchannels/MouseCursorChannel/interfaces/MouseCursorMethodHandler.md#activatesystemcursor)

***

### destroy()

> **destroy**(): `void`

Destroys the mouse cursor plugin and cleans up resources.
The MouseCursorPlugin instance should not be used after calling this.

#### Returns

`void`
