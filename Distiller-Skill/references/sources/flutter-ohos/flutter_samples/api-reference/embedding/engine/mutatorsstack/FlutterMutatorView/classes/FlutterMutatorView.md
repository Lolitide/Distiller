[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterMutatorView

View that applies Flutter mutators (transforms, clips) to a dynamic view model.
This class manages the layout and mutator application for platform views.

## Constructors

### Constructor

> **new FlutterMutatorView**(): `FlutterMutatorView`

#### Returns

`FlutterMutatorView`

## Methods

### addDvModel()

> **addDvModel**(`model`): `void`

Adds a child dynamic view model to this view.

#### Parameters

##### model

[`DVModel`](../../../../../view/DynamicView/dynamicView/classes/DVModel.md)

The DVModel to add as a child

#### Returns

`void`

***

### getDvModel()

> **getDvModel**(): [`DVModel`](../../../../../view/DynamicView/dynamicView/classes/DVModel.md)

Gets the dynamic view model for this view.

#### Returns

[`DVModel`](../../../../../view/DynamicView/dynamicView/classes/DVModel.md)

The DVModel instance, or undefined if not set

***

### readyToDisplay()

> **readyToDisplay**(`mutatorsStack`, `left`, `top`, `width`, `height`): `void`

Prepares this view for display by applying mutators and setting layout parameters.

#### Parameters

##### mutatorsStack

[`FlutterMutatorsStack`](../../FlutterMutatorsStack/classes/FlutterMutatorsStack.md)

The stack of mutators to apply

##### left

`number`

The left position of the view

##### top

`number`

The top position of the view

##### width

`number`

The width of the view

##### height

`number`

The height of the view

#### Returns

`void`

***

### setLayoutParams()

> **setLayoutParams**(`parameters`): `void`

Sets the layout parameters for this view.

#### Parameters

##### parameters

[`DVModelParameters`](../../../../../view/DynamicView/dynamicView/classes/DVModelParameters.md)

The layout parameters including margin, width, and height

#### Returns

`void`

***

### setOnDescendantFocusChangeListener()

> **setOnDescendantFocusChangeListener**(`onFocus`, `onBlur`): `void`

Sets listeners for descendant focus change events.

#### Parameters

##### onFocus

() => `void`

Callback invoked when a descendant gains focus

##### onBlur

() => `void`

Callback invoked when a descendant loses focus

#### Returns

`void`
