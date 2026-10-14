[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEngineGroupCache

Static singleton cache that holds FlutterEngineGroup instances identified by Strings.

The ID of a given FlutterEngineGroup can be whatever String is desired.

FlutterEngineGroupCache is useful for storing pre-warmed FlutterEngineGroup instances. FlutterAbility
and FlutterEntry can use cached FlutterEngineGroup instances by implementing getCachedEngineGroupId()
to return a cached engine group ID. The FlutterAbilityAndEntryDelegate will then retrieve the
engine group from this cache and create new engines within that group. See FlutterAbility.getCachedEngineGroupId()
and FlutterEntry.getCachedEngineGroupId() for related APIs.

## Constructors

### Constructor

> **new FlutterEngineGroupCache**(): `FlutterEngineGroupCache`

#### Returns

`FlutterEngineGroupCache`

## Properties

### instance

> `readonly` `static` **instance**: `FlutterEngineGroupCache`

## Methods

### clear()

> **clear**(): `void`

Clears all engine groups from the cache.

#### Returns

`void`

***

### contains()

> **contains**(`engineGroupId`): `boolean`

Checks if an engine group with the given ID exists in the cache.

#### Parameters

##### engineGroupId

`string`

The ID of the engine group to check

#### Returns

`boolean`

true if the engine group exists, false otherwise

***

### get()

> **get**(`engineGroupId`): `any`

Gets an engine group from the cache by ID.

#### Parameters

##### engineGroupId

`string`

The ID of the engine group to retrieve

#### Returns

`any`

The FlutterEngineGroup instance, or null if not found

***

### put()

> **put**(`engineGroupId`, `engineGroup?`): `void`

Puts an engine group into the cache or removes it if null is provided.

#### Parameters

##### engineGroupId

`string`

The ID of the engine group

##### engineGroup?

`FlutterEngineGroup`

The FlutterEngineGroup instance to cache, or undefined to remove

#### Returns

`void`
