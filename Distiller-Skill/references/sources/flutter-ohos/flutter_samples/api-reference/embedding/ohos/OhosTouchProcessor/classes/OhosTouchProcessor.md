[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: OhosTouchProcessor

Processor for handling touch events from OpenHarmony.
This class processes touch events and converts them for Flutter.

## Constructors

### Constructor

> **new OhosTouchProcessor**(): `OhosTouchProcessor`

#### Returns

`OhosTouchProcessor`

## Properties

### BYTES\_PER\_FIELD

> `static` **BYTES\_PER\_FIELD**: `number` = `8`

Number of bytes per field in pointer data.

## Methods

### onTouchEvent()

> **onTouchEvent**(`event`, `transformMatrix`): `void`

Processes a touch event.

#### Parameters

##### event

`TouchEvent`

The touch event from OpenHarmony

##### transformMatrix

`Any`

The transformation matrix to apply

#### Returns

`void`
