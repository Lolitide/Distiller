[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEngineCache

Static singleton cache that holds FlutterEngine instances identified by Strings.

The ID of a given FlutterEngine can be whatever String is desired.

FlutterEngineCache is useful for storing pre-warmed FlutterEngine instances. FlutterAbility
and FlutterEntry can use cached FlutterEngine instances by implementing getCachedEngineId()
to return a cached engine ID. The FlutterAbilityAndEntryDelegate will then retrieve the
engine from this cache. See FlutterAbility.getCachedEngineId() and FlutterEntry.getCachedEngineId()
for related APIs.

## Constructors

### Constructor

> **new FlutterEngineCache**(): `FlutterEngineCache`

#### Returns

`FlutterEngineCache`

## Methods

### clear()

> **clear**(): `void`

Clears all engines from the cache.

#### Returns

`void`

***

### contains()

> **contains**(`engineId`): `boolean`

Checks if an engine with the given ID exists in the cache.

#### Parameters

##### engineId

`String`

The ID of the engine to check

#### Returns

`boolean`

true if the engine exists, false otherwise

***

### get()

> **get**(`engineId`): `any`

Gets an engine from the cache by ID.

#### Parameters

##### engineId

`String`

The ID of the engine to retrieve

#### Returns

`any`

The FlutterEngine instance, or null if not found

***

### put()

> **put**(`engineId`, `engine`): `void`

Puts an engine into the cache or removes it if null is provided.

#### Parameters

##### engineId

`String`

The ID of the engine

##### engine

`any`

The FlutterEngine instance to cache, or null to remove

#### Returns

`void`

***

### remove()

> **remove**(`engineId`): `void`

Removes an engine from the cache by ID.

#### Parameters

##### engineId

`String`

The ID of the engine to remove

#### Returns

`void`

***

### getInstance()

> `static` **getInstance**(): `FlutterEngineCache`

Gets the singleton instance of FlutterEngineCache.

#### Returns

`FlutterEngineCache`

The FlutterEngineCache instance
