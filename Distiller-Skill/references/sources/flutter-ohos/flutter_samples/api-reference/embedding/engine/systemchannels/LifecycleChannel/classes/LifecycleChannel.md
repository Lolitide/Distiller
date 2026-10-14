[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: LifecycleChannel

Channel for handling application lifecycle events.
This channel manages communication of lifecycle state changes between OpenHarmony and Flutter,
including resumed, inactive, paused, and detached states.

## Constructors

### Constructor

> **new LifecycleChannel**(`dartExecutor`): `LifecycleChannel`

Constructs a new LifecycleChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`LifecycleChannel`

## Methods

### appIsDetached()

> **appIsDetached**(): `void`

Called when the app is detached.

#### Returns

`void`

***

### appIsInactive()

> **appIsInactive**(): `void`

Called when the app is inactive.

#### Returns

`void`

***

### appIsPaused()

> **appIsPaused**(): `void`

Called when the app is paused.

#### Returns

`void`

***

### appIsResumed()

> **appIsResumed**(): `void`

Called when the app is resumed.

#### Returns

`void`

***

### aWindowIsFocused()

> **aWindowIsFocused**(): `void`

Called when at least one window in the app has focus.

#### Returns

`void`

***

### noWindowsAreFocused()

> **noWindowsAreFocused**(): `void`

Called when no windows in the app have focus.

#### Returns

`void`
