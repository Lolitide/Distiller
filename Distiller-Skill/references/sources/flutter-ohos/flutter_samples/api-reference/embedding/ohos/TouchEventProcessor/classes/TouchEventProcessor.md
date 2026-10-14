[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: TouchEventProcessor

Processor for handling touch events received by FlutterNapi.
This class processes and converts touch events from native format to Flutter format.

## Constructors

### Constructor

> **new TouchEventProcessor**(): `TouchEventProcessor`

#### Returns

`TouchEventProcessor`

## Methods

### checkHitPlatformView()

> **checkHitPlatformView**(`left`, `top`, `width`, `height`, `x`, `y`): `boolean`

#### Parameters

##### left

`number`

##### top

`number`

##### width

`number`

##### height

`number`

##### x

`number`

##### y

`number`

#### Returns

`boolean`

***

### constructCustomTouchEvent()

> **constructCustomTouchEvent**(`strings`, `top`, `left`): [`CustomTouchEvent`](../../../../plugin/platform/CustomTouchEvent/classes/CustomTouchEvent.md)

Constructs a CustomTouchEvent from string array data.

#### Parameters

##### strings

`string`[]

Array of string values representing touch data

##### top

`number`

The top offset

##### left

`number`

The left offset

#### Returns

[`CustomTouchEvent`](../../../../plugin/platform/CustomTouchEvent/classes/CustomTouchEvent.md)

A CustomTouchEvent instance

***

### constructMouseEvent()

> **constructMouseEvent**(`strings`, `top`, `left`): `MouseEvent`

Construct the MouseEvent and return.

#### Parameters

##### strings

`string`[]

##### top

`number`

##### left

`number`

#### Returns

`MouseEvent`

***

### postAxisEvent()

> **postAxisEvent**(`strings`): `void`

Posts an axis/scroll event to platform views.
Axis/wheel coordinates are passed to nodes through this method.

#### Parameters

##### strings

`string`[]

Array of string values representing axis event data

#### Returns

`void`

***

### postMouseEvent()

> **postMouseEvent**(`strings`): `void`

Posts a mouse event to platform views.

#### Parameters

##### strings

`string`[]

Array of string values representing mouse event data

#### Returns

`void`

***

### postTouchEvent()

> **postTouchEvent**(`strings`): `void`

Posts a touch event to platform views.

#### Parameters

##### strings

`string`[]

Array of string values representing touch event data

#### Returns

`void`

***

### getInstance()

> `static` **getInstance**(): `TouchEventProcessor`

Gets the singleton instance of TouchEventProcessor.

#### Returns

`TouchEventProcessor`

The singleton TouchEventProcessor instance
