[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: DisplayFeature

Represents a display feature such as a fold, hinge, or cutout.

## Constructors

### Constructor

> **new DisplayFeature**(`bound`, `type`, `state`): `DisplayFeature`

Constructs a new DisplayFeature instance.

#### Parameters

##### bound

`Rect`

The bounding rectangle of the feature

##### type

[`DisplayFeatureType`](../enumerations/DisplayFeatureType.md)

The type of display feature

##### state

[`DisplayFeatureState`](../enumerations/DisplayFeatureState.md)

The state of the display feature

#### Returns

`DisplayFeature`

## Properties

### bound

> **bound**: `Rect`

Bounding rectangle of the display feature.

***

### state

> **state**: [`DisplayFeatureState`](../enumerations/DisplayFeatureState.md)

State of the display feature.

***

### type

> **type**: [`DisplayFeatureType`](../enumerations/DisplayFeatureType.md)

Type of the display feature (fold, hinge, cutout, etc.).

## Methods

### getBound()

> **getBound**(): `Rect`

Gets the bounding rectangle of the display feature.

#### Returns

`Rect`

The bounding rectangle

***

### getState()

> **getState**(): [`DisplayFeatureState`](../enumerations/DisplayFeatureState.md)

Gets the state of the display feature.

#### Returns

[`DisplayFeatureState`](../enumerations/DisplayFeatureState.md)

The display feature state

***

### getType()

> **getType**(): [`DisplayFeatureType`](../enumerations/DisplayFeatureType.md)

Gets the type of the display feature.

#### Returns

[`DisplayFeatureType`](../enumerations/DisplayFeatureType.md)

The display feature type

***

### setBound()

> **setBound**(`bound`): `void`

Sets the bounding rectangle of the display feature.

#### Parameters

##### bound

`Rect`

The bounding rectangle to set

#### Returns

`void`

***

### setState()

> **setState**(`state`): `void`

Sets the state of the display feature.

#### Parameters

##### state

[`DisplayFeatureState`](../enumerations/DisplayFeatureState.md)

The display feature state to set

#### Returns

`void`

***

### setType()

> **setType**(`type`): `void`

Sets the type of the display feature.

#### Parameters

##### type

[`DisplayFeatureType`](../enumerations/DisplayFeatureType.md)

The display feature type to set

#### Returns

`void`
