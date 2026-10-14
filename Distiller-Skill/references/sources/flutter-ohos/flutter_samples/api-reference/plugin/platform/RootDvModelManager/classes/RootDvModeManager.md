[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: RootDvModeManager

Manager for the root DynamicView model container.
This class provides a singleton root container for all platform views.

## Constructors

### Constructor

> **new RootDvModeManager**(): `RootDvModeManager`

#### Returns

`RootDvModeManager`

## Methods

### addDvModel()

> `static` **addDvModel**(`model`): `void`

Adds a DynamicView model to the root container.

#### Parameters

##### model

[`DVModel`](../../../../view/DynamicView/dynamicView/classes/DVModel.md)

The DVModel to add

#### Returns

`void`

***

### getRootDvMode()

> `static` **getRootDvMode**(): [`DVModelContainer`](../../../../view/DynamicView/dynamicView/classes/DVModelContainer.md)

Gets the root DynamicView model container.

#### Returns

[`DVModelContainer`](../../../../view/DynamicView/dynamicView/classes/DVModelContainer.md)

The root DVModelContainer instance
