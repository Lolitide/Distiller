[**Flutter ETS API Documentation v1.0.0**](../../../../../../README.md)

***

# Interface: OnSaveStateListener

Delegate interface for handling save state events.

## Methods

### onSaveState()

> **onSaveState**(`reason`, `wantParam`): `OnSaveResult`

Invoked when the associated UIAbility saves and restores instance state.

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
