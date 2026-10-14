[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: RawPointerCoords

Represents raw pointer coordinates with additional touch information.
This class holds detailed information about a pointer event.

## Constructors

### Constructor

> **new RawPointerCoords**(`orientation`, `pressure`, `size`, `toolMajor`, `toolMinor`, `touchMajor`, `touchMinor`, `x`, `y`): `RawPointerCoords`

Constructs a new RawPointerCoords instance.

#### Parameters

##### orientation

`number`

The orientation angle in radians

##### pressure

`number`

The pressure value (0.0 to 1.0)

##### size

`number`

The size value

##### toolMajor

`number`

The major axis of the tool ellipse

##### toolMinor

`number`

The minor axis of the tool ellipse

##### touchMajor

`number`

The major axis of the touch ellipse

##### touchMinor

`number`

The minor axis of the touch ellipse

##### x

`number`

The X coordinate

##### y

`number`

The Y coordinate

#### Returns

`RawPointerCoords`

## Methods

### getX()

> **getX**(): `number`

Gets the X coordinate.

#### Returns

`number`

The X coordinate value

***

### getY()

> **getY**(): `number`

Gets the Y coordinate.

#### Returns

`number`

The Y coordinate value
