[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: SimulateKeyEvent

Simulated key event used in soft-keyboard text-editing.
This class represents a programmatically generated key event, typically used
for virtual keyboard interactions such as arrow keys, selection keys, or
other input method editor (IME) operations. Unlike FlutterKeyEvent, this
does not wrap a hardware KeyEvent and contains only the essential key information.

## Constructors

### Constructor

> **new SimulateKeyEvent**(`keyCode`, `keyText`): `SimulateKeyEvent`

Constructs a new SimulateKeyEvent instance.

#### Parameters

##### keyCode

`number`

The key code value (e.g., KeyCode.KEYCODE_DPAD_UP)

##### keyText

`string`

The text representation of the key (e.g., "Arrow Up")

#### Returns

`SimulateKeyEvent`

## Properties

### keyCode

> **keyCode**: `number`

The key code value identifying which key was pressed.

***

### keyText

> **keyText**: `string`

The text representation of the key (e.g., "Arrow Up", "Shift").
