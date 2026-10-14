[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: RestorationChannel

System channel to exchange restoration data between framework and engine.

The engine can obtain the current restoration data from the framework via this channel to
store it on disk and - when the app is relaunched - provide the stored data back to the framework
to recreate the original state of the app.

The channel can be configured to delay responding to the framework's request for restoration
data via waitForRestorationData until the engine-side has provided the data. This is
useful when the engine is pre-warmed at a point in the application's life cycle where the
restoration data is not available yet. For example, if the engine is pre-warmed as part of the
Application before an Ability is created, this flag should be set to true because OpenHarmony will
only provide the restoration data to the Ability during the onCreate callback.

The current restoration data provided by the framework can be read via getRestorationData.

## Constructors

### Constructor

> **new RestorationChannel**(`channelOrExecutor`, `waitForRestorationData`): `RestorationChannel`

Constructs a new RestorationChannel instance.

#### Parameters

##### channelOrExecutor

`any`

Either a MethodChannel or DartExecutor instance

##### waitForRestorationData

`boolean`

Whether to wait for restoration data before responding

#### Returns

`RestorationChannel`

## Properties

### engineHasProvidedData

> **engineHasProvidedData**: `boolean` = `false`

Whether the engine has provided restoration data.

***

### frameworkHasRequestedData

> **frameworkHasRequestedData**: `boolean` = `false`

Whether the framework has requested restoration data.

***

### pendingFrameworkRestorationChannelRequest

> **pendingFrameworkRestorationChannelRequest**: [`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md) = `null`

Pending framework restoration channel request waiting for restoration data.

***

### waitForRestorationData

> **waitForRestorationData**: `boolean` = `false`

Whether the channel delays responding to the framework's initial request for restoration data
until setRestorationData has been called.

If the engine never calls setRestorationData this flag must be set to false. If set
to true, the engine must call setRestorationData either with the actual restoration
data as argument or null if it turns out that there is no restoration data.

If the response to the framework's request for restoration data is not delayed until the
data has been set via setRestorationData, the framework may intermittently initialize
itself to default values until the restoration data has been made available. Setting this flag
to true avoids that extra work.

## Methods

### clearData()

> **clearData**(): `void`

Clears the current restoration data.

This should be called just prior to a hot restart. Otherwise, after the hot restart the
state prior to the hot restart will get restored.

#### Returns

`void`

***

### getRestorationData()

> **getRestorationData**(): `Uint8Array`

Gets the most current restoration data that the framework has provided.

#### Returns

`Uint8Array`

The restoration data as a Uint8Array

***

### setRestorationData()

> **setRestorationData**(`data`): `void`

Sets the restoration data from which the framework will restore its state.

#### Parameters

##### data

`Uint8Array`

The restoration data to set

#### Returns

`void`

***

### setRestorationDataOnly()

> **setRestorationDataOnly**(`data`): `void`

Sets the restoration data without sending it to the framework.

#### Parameters

##### data

`Uint8Array`

The restoration data to set

#### Returns

`void`
