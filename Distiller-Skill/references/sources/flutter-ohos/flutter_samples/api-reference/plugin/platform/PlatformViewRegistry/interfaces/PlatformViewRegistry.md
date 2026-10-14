[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: PlatformViewRegistry

Registry for platform view factories.

Plugins can register factories for specific view types.

## Methods

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
