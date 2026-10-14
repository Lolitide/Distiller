[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: CustomTouchEvent

Custom implementation of TouchEvent for platform views.
This class wraps touch event data for communication between Flutter and native views.

## Implements

- `TouchEvent`

## Constructors

### Constructor

> **new CustomTouchEvent**(`type`, `touches`, `changedTouches`, `timestamp`, `source`, `pressure`, `tiltX`, `tiltY`, `sourceTool`): `CustomTouchEvent`

Constructs a new CustomTouchEvent instance.

#### Parameters

##### type

`TouchType`

The touch event type

##### touches

[`CustomTouchObject`](CustomTouchObject.md)[]

Array of all touch points

##### changedTouches

[`CustomTouchObject`](CustomTouchObject.md)[]

Array of touch points that changed

##### timestamp

`number`

The event timestamp

##### source

`SourceType`

The source type of the touch

##### pressure

`number`

The pressure value

##### tiltX

`number`

The X-axis tilt value

##### tiltY

`number`

The Y-axis tilt value

##### sourceTool

`SourceTool`

The source tool type

#### Returns

`CustomTouchEvent`

## Properties

### changedTouches

> **changedTouches**: [`CustomTouchObject`](CustomTouchObject.md)[]

Array of touch points that changed in this event.

#### Implementation of

`TouchEvent.changedTouches`

***

### pressure

> **pressure**: `number`

The pressure value of the touch.

***

### preventDefault()

> **preventDefault**: () => `void`

Function to prevent the default action.

#### Returns

`void`

#### Implementation of

`TouchEvent.preventDefault`

***

### source

> **source**: `SourceType`

The source type of the touch event.

***

### sourceTool

> **sourceTool**: `SourceTool`

The source tool type for the touch.

***

### stopPropagation()

> **stopPropagation**: () => `void`

Function to stop event propagation.

#### Returns

`void`

#### Implementation of

`TouchEvent.stopPropagation`

***

### target

> **target**: `EventTarget`

The event target for this touch event.

#### Implementation of

`TouchEvent.target`

***

### tiltX

> **tiltX**: `number`

The X-axis tilt value of the touch.

***

### tiltY

> **tiltY**: `number`

The Y-axis tilt value of the touch.

***

### timestamp

> **timestamp**: `number`

The timestamp when the event occurred.

***

### touches

> **touches**: [`CustomTouchObject`](CustomTouchObject.md)[]

Array of all touch points in this event.

#### Implementation of

`TouchEvent.touches`

***

### type

> **type**: `TouchType` = `0`

The type of touch event.

#### Implementation of

`TouchEvent.type`

## Methods

### getHistoricalPoints()

> **getHistoricalPoints**(): `HistoricalPoint`[]

Gets historical touch points.

#### Returns

`HistoricalPoint`[]

Array of historical points

#### Throws

Error as this method is not implemented

***

### getModifierKeyState()

> **getModifierKeyState**(`keys`): `boolean`

Gets the modifier key state.

#### Parameters

##### keys

`string`[]

Array of key names to check

#### Returns

`boolean`

True if any of the keys are pressed

#### Throws

Error as this method is not implemented
