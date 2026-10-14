[**Flutter ETS API Documentation v1.0.0**](../../../../../../README.md)

***

# Interface: AbilityPluginBinding

Binding that provides plugins with access to UIAbility-related resources.
This interface allows plugins to access the ability and register for ability lifecycle events.

## Methods

### addOnNewWantListener()

> **addOnNewWantListener**(`listener`): `void`

Adds a listener that is invoked whenever the associated UIAbility's onNewWant method is invoked.

#### Parameters

##### listener

[`NewWantListener`](NewWantListener.md)

The NewWantListener to add

#### Returns

`void`

***

### addOnSaveStateListener()

> **addOnSaveStateListener**(`listener`): `void`

Adds a listener that is invoked when the associated UIAbility saves and restores instance state.

#### Parameters

##### listener

[`OnSaveStateListener`](OnSaveStateListener.md)

The OnSaveStateListener to add

#### Returns

`void`

***

### addOnWindowFocusChangedListener()

> **addOnWindowFocusChangedListener**(`listener`): `void`

Adds a listener that is invoked whenever the associated UIAbility's windowStageEvent method is invoked.

#### Parameters

##### listener

[`WindowFocusChangedListener`](WindowFocusChangedListener.md)

The WindowFocusChangedListener to add

#### Returns

`void`

***

### getAbility()

> **getAbility**(): `UIAbility`

Gets the UIAbility instance.

#### Returns

`UIAbility`

The UIAbility instance

***

### removeOnNewWantListener()

> **removeOnNewWantListener**(`listener`): `void`

Removes a listener that was added in addOnNewWantListener.

#### Parameters

##### listener

[`NewWantListener`](NewWantListener.md)

The NewWantListener to remove

#### Returns

`void`

***

### removeOnSaveStateListener()

> **removeOnSaveStateListener**(`listener`): `void`

Removes a listener that was added in addOnSaveStateListener.

#### Parameters

##### listener

[`OnSaveStateListener`](OnSaveStateListener.md)

The OnSaveStateListener to remove

#### Returns

`void`

***

### removeOnWindowFocusChangedListener()

> **removeOnWindowFocusChangedListener**(`listener`): `void`

Removes a listener that was added in addOnWindowFocusChangedListener.

#### Parameters

##### listener

[`WindowFocusChangedListener`](WindowFocusChangedListener.md)

The WindowFocusChangedListener to remove

#### Returns

`void`
