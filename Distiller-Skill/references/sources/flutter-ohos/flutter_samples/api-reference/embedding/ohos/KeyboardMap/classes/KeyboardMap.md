[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: KeyboardMap

Maps OpenHarmony KeyCodes to Flutter LogicalKeys and PhysicalKeys.
This class provides static mappings for keyboard key translation between OpenHarmony and Flutter.

## Constructors

### Constructor

> **new KeyboardMap**(): `KeyboardMap`

#### Returns

`KeyboardMap`

## Properties

### kOhosPlane

> `static` **kOhosPlane**: `number` = `0x01900000000`

OpenHarmony plane identifier.

***

### kUnicodePlane

> `static` **kUnicodePlane**: `number` = `0x00000000000`

Unicode plane identifier.

***

### kValueMask

> `static` **kValueMask**: `number` = `0x000FFFFFFFF`

Bitmask for extracting key values.

***

### modifierGoals

> `static` **modifierGoals**: [`ModifierGoal`](ModifierGoal.md)[]

Array of modifier key goals for synchronization.

***

### ohKeyToScanCode

> `static` **ohKeyToScanCode**: `Map`\<`number`, `number`\>

Map OpenHarmony KeyCode to ScanCode since cannot access ScanCode directly from KeyEvent.

***

### toLogicalKey

> `static` **toLogicalKey**: `Map`\<`number`, `number`\>

Map from OpenHarmony KeyCode to Flutter LogicalKey.

***

### toPhysicalKey

> `static` **toPhysicalKey**: `Map`\<`number`, `number`\>

Map OH KeyCode to Flutter PhysicalKey.
Should map OH ScanCode to Flutter PhysicalKey, but we use KeyCode here
instead since there is no ScanCode in OH KeyEvent yet. There may be some
mistakes and should correct the map as soon as we can access ScanCode.
