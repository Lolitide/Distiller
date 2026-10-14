[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: TextInputPlugin

Plugin for handling text input in Flutter applications.
This class manages the interaction between Flutter's text input system
and the OpenHarmony input method framework.

## Implements

- [`EditingStateWatcher`](../../ListenableEditingState/interfaces/EditingStateWatcher.md)

## Constructors

### Constructor

> **new TextInputPlugin**(`textInputChannel`, `viewId`, `keyEventChannel?`): `TextInputPlugin`

Constructs a new TextInputPlugin instance.

#### Parameters

##### textInputChannel

`TextInputChannel`

The TextInputChannel for communication with Flutter

##### viewId

`string`

The view ID for focus management

##### keyEventChannel?

`KeyEventChannel`

Optional KeyEventChannel for key event handling

#### Returns

`TextInputPlugin`

## Methods

### clearTextInputClient()

> **clearTextInputClient**(): `void`

Clears the current text input client.

#### Returns

`void`

***

### destroy()

> **destroy**(): `void`

Destroys the text input plugin, hiding the keyboard and cleaning up resources.

#### Returns

`void`

***

### detach()

> **detach**(): `void`

Detaches the text input plugin from the input method framework.

#### Returns

`void`

***

### didChangeEditingState()

> **didChangeEditingState**(`textChanged`, `selectionChanged`, `composingRegionChanged`): `void`

Called when the editing state changes. Delegates sync strategy to PreviewTextCoordinator.

#### Parameters

##### textChanged

`boolean`

Whether the text has changed

##### selectionChanged

`boolean`

Whether the selection has changed

##### composingRegionChanged

`boolean`

Whether the composing region has changed

#### Returns

`void`

#### Implementation of

[`EditingStateWatcher`](../../ListenableEditingState/interfaces/EditingStateWatcher.md).[`didChangeEditingState`](../../ListenableEditingState/interfaces/EditingStateWatcher.md#didchangeeditingstate)

***

### getEditingState()

> **getEditingState**(): [`ListenableEditingState`](../../ListenableEditingState/classes/ListenableEditingState.md)

Gets the current editing state.

#### Returns

[`ListenableEditingState`](../../ListenableEditingState/classes/ListenableEditingState.md)

The current ListenableEditingState instance
