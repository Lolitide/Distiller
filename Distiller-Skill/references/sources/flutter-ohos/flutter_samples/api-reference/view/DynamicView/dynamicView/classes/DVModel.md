[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: DVModel

Model class representing a dynamic view component.
This class holds all information needed to render a component dynamically,
including its type, parameters, events, children, and optional builder.

## Constructors

### Constructor

> **new DVModel**(`compType`, `params`, `events`, `children`, `builder?`): `DVModel`

Constructs a new DVModel instance.

#### Parameters

##### compType

`string`

The component type (e.g., "Column", "Row", "Text", "Image")

##### params

[`DVModelParameters`](DVModelParameters.md)

The component parameters

##### events

[`DVModelEvents`](DVModelEvents.md)

The component events

##### children

[`DVModelChildren`](DVModelChildren.md)

The child components

##### builder?

`Any`

Optional custom builder function

#### Returns

`DVModel`

## Properties

### builder

> **builder**: `Any`

Optional custom builder function.

***

### children

> **children**: [`DVModelChildren`](DVModelChildren.md)

The child components.

***

### compType

> **compType**: `string`

The component type (e.g., "Column", "Row", "Text", "Image").

***

### events

> **events**: [`DVModelEvents`](DVModelEvents.md)

The component events.

***

### id\_

> **id\_**: `number`

The unique identifier for this model.

***

### params

> **params**: [`DVModelParameters`](DVModelParameters.md)

The component parameters.

## Methods

### getLayoutParams()

> **getLayoutParams**(): [`DVModelParameters`](DVModelParameters.md)

Gets the layout parameters for this model.

#### Returns

[`DVModelParameters`](DVModelParameters.md)

The DVModelParameters instance
