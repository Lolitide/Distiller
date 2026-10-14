[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterKeyEvent

Wrapper for OpenHarmony KeyEvent that provides Flutter-compatible meta state information.
OpenHarmony KeyEvent does not natively support meta state tracking for modifier keys
(Ctrl, Alt, Shift) in the same way Flutter expects. This class supplements the missing
functionality by tracking modifier key states and providing a getMetaState() method
that returns a bitmask compatible with Flutter's key event handling.

## Constructors

### Constructor

> **new FlutterKeyEvent**(`ohosKeyEvent`): `FlutterKeyEvent`

Constructs a new FlutterKeyEvent instance.

#### Parameters

##### ohosKeyEvent

`KeyEvent`

The OpenHarmony KeyEvent to wrap

#### Returns

`FlutterKeyEvent`

## Properties

### event

> **event**: `KeyEvent`

The underlying OpenHarmony KeyEvent instance.

## Methods

### getMetaState()

> **getMetaState**(): `number`

Gets the meta state value as a bitmask.
This supplements the missing metaState feature of OpenHarmony when pressing
modifier keys (Ctrl, Alt, Shift) to perform combination key operations.
The meta state is a bitmask that indicates which modifier keys are currently pressed.
Currently only supports metaState tracking for Ctrl, Alt, and Shift keys.

#### Returns

`number`

The meta state value as a bitmask indicating pressed modifier keys
