[**Flutter ETS API Documentation v1.0.0**](../../../../../../README.md)

***

# Interface: AbilityControlSurface

Interface for controlling ability-related operations in Flutter engines.
This interface provides methods to attach/detach from abilities and handle ability lifecycle events.

## Methods

### attachToAbility()

> **attachToAbility**(`exclusiveActivity`): `void`

Attaches this surface to an exclusive app component (UIAbility).

#### Parameters

##### exclusiveActivity

[`ExclusiveAppComponent`](../../../../../ohos/ExclusiveAppComponent/interfaces/ExclusiveAppComponent.md)\<`UIAbility`\>

The exclusive app component to attach to

#### Returns

`void`

***

### detachFromAbility()

> **detachFromAbility**(): `void`

Detaches this surface from the current ability.

#### Returns

`void`

***

### onNewWant()

> **onNewWant**(`want`, `launchParams`): `void`

Handles a new Want event from the ability.

#### Parameters

##### want

`Want`

The Want object representing the request

##### launchParams

`LaunchParam`

The launch parameters

#### Returns

`void`

***

### onSaveState()

> **onSaveState**(`reason`, `wantParam`): `OnSaveResult`

Handles save state requests from the ability.

#### Parameters

##### reason

`StateType`

The reason for saving state

##### wantParam

`Record`\<`string`, `Object`\>

Parameters to save

#### Returns

`OnSaveResult`

The result of the save state operation

***

### onWindowFocusChanged()

> **onWindowFocusChanged**(`hasFocus`): `void`

Handles window focus change events from the ability.

#### Parameters

##### hasFocus

`boolean`

Whether the window has focus

#### Returns

`void`
