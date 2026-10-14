[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PlatformViewWrapper

Wraps a platform view to intercept gestures and project this view onto a rendering target.

An OpenHarmony platform view is composed by the engine using a TextureLayer. The view is embedded
in the OpenHarmony view hierarchy like a normal DynamicView, but it's projected onto a rendering
target, so it can be efficiently composed by the engine.

Since the view is in the OpenHarmony view hierarchy, keyboard and accessibility interactions
behave normally.

## Constructors

### Constructor

> **new PlatformViewWrapper**(): `PlatformViewWrapper`

Constructs a new PlatformViewWrapper instance.

#### Returns

`PlatformViewWrapper`

## Properties

### getParams()

> **getParams**: (`params`, `element`) => `any`

Gets a parameter value from the DVModelParameters.

#### Parameters

##### params

[`DVModelParameters`](../../../../view/DynamicView/dynamicView/classes/DVModelParameters.md)

The parameters object to read from

##### element

`string`

The parameter key

#### Returns

`any`

The parameter value, or undefined if not found

***

### setParams()

> **setParams**: (`params`, `key`, `element`) => `void`

Sets a parameter value in the DVModelParameters.

#### Parameters

##### params

[`DVModelParameters`](../../../../view/DynamicView/dynamicView/classes/DVModelParameters.md)

The parameters object to modify

##### key

`string`

The parameter key

##### element

`Any`

The value to set

#### Returns

`void`

## Methods

### addDvModel()

> **addDvModel**(`model`): `void`

Adds a DynamicView model to this wrapper.

#### Parameters

##### model

[`DVModel`](../../../../view/DynamicView/dynamicView/classes/DVModel.md)

The DVModel to add

#### Returns

`void`

***

### getDvModel()

> **getDvModel**(): [`DVModel`](../../../../view/DynamicView/dynamicView/classes/DVModel.md)

Gets the DynamicView model associated with this wrapper.

#### Returns

[`DVModel`](../../../../view/DynamicView/dynamicView/classes/DVModel.md)

The DVModel instance

***

### setLayoutParams()

> **setLayoutParams**(`parameters`): `void`

Sets the layout parameters for the platform view.

#### Parameters

##### parameters

[`DVModelParameters`](../../../../view/DynamicView/dynamicView/classes/DVModelParameters.md)

The layout parameters to apply

#### Returns

`void`

***

### setTouchProcessor()

> **setTouchProcessor**(`newTouchProcessor`): `void`

Sets the touch processor for handling touch events.

#### Parameters

##### newTouchProcessor

`OhosTouchProcessor`

The OhosTouchProcessor instance

#### Returns

`void`
