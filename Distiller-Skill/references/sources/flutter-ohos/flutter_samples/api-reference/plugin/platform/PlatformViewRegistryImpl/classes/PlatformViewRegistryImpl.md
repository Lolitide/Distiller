[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PlatformViewRegistryImpl

Implementation of PlatformViewRegistry for managing platform view factories.

## Implements

- [`PlatformViewRegistry`](../../PlatformViewRegistry/interfaces/PlatformViewRegistry.md)

## Constructors

### Constructor

> **new PlatformViewRegistryImpl**(): `PlatformViewRegistryImpl`

Constructs a new PlatformViewRegistryImpl instance.

#### Returns

`PlatformViewRegistryImpl`

## Methods

### getFactory()

> **getFactory**(`viewTypeId`): `PlatformViewFactory`

Gets the factory for a specific view type.

#### Parameters

##### viewTypeId

`string`

The view type ID

#### Returns

`PlatformViewFactory`

The PlatformViewFactory for the view type, or undefined if not found

***

### registerViewFactory()

> **registerViewFactory**(`viewTypeId`, `factory`): `boolean`

Registers a factory for a platform view.

#### Parameters

##### viewTypeId

`string`

Unique identifier for the platform view's type

##### factory

`PlatformViewFactory`

Factory for creating platform views of the specified type

#### Returns

`boolean`

True if succeeded, false if a factory is already registered for viewTypeId

#### Implementation of

[`PlatformViewRegistry`](../../PlatformViewRegistry/interfaces/PlatformViewRegistry.md).[`registerViewFactory`](../../PlatformViewRegistry/interfaces/PlatformViewRegistry.md#registerviewfactory)
