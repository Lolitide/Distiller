[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: PlatformViewTouch

The state of a touch event in Flutter within a platform view.

## Constructors

### Constructor

> **new PlatformViewTouch**(`viewId`, `downTime`, `eventTime`, `action`, `pointerCount`, `rawPointerPropertiesList`, `rawPointerCoords`, `metaState`, `buttonState`, `xPrecision`, `yPrecision`, `deviceId`, `edgeFlags`, `source`, `flags`, `motionEventId`): `PlatformViewTouch`

Constructs a new PlatformViewTouch instance.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### downTime

`number`

The time when the touch was pressed

##### eventTime

`number`

The time of the event

##### action

`number`

The touch action

##### pointerCount

`number`

The number of pointers

##### rawPointerPropertiesList

`Any`

Raw pointer properties

##### rawPointerCoords

`Any`

Raw pointer coordinates

##### metaState

`number`

The meta state

##### buttonState

`number`

The button state

##### xPrecision

`number`

X-axis coordinate precision

##### yPrecision

`number`

Y-axis coordinate precision

##### deviceId

`number`

The device ID

##### edgeFlags

`number`

Edge flags

##### source

`number`

The event source

##### flags

`number`

Event flags

##### motionEventId

`number`

The motion event ID

#### Returns

`PlatformViewTouch`

## Properties

### action

> **action**: `number`

The touch action type.

***

### buttonState

> **buttonState**: `number`

The button state indicating which buttons are pressed.

***

### deviceId

> **deviceId**: `number`

The ID of the input device that generated the event.

***

### downTime

> **downTime**: `number`

The amount of time that the touch has been pressed.

***

### edgeFlags

> **edgeFlags**: `number`

Edge flags indicating which screen edges were touched.

***

### eventTime

> **eventTime**: `number`

The time when the event occurred.

***

### flags

> **flags**: `number`

Event flags providing additional information about the event.

***

### metaState

> **metaState**: `number`

The meta state indicating modifier keys pressed.

***

### motionEventId

> **motionEventId**: `number`

The motion event ID for tracking the event.

***

### pointerCount

> **pointerCount**: `number`

The number of pointers (e.g, fingers) involved in the touch event.

***

### rawPointerCoords

> **rawPointerCoords**: `Any`

Coordinates for each pointer, encoded in a raw format.

***

### rawPointerPropertiesList

> **rawPointerPropertiesList**: `Any`

Properties for each pointer, encoded in a raw format.

***

### source

> **source**: `number`

The event source indicating the type of input device.

***

### viewId

> **viewId**: `number`

The ID of the platform view as seen by the Flutter side.

***

### xPrecision

> **xPrecision**: `number`

Coordinate precision along the x-axis.

***

### yPrecision

> **yPrecision**: `number`

Coordinate precision along the y-axis.
