[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterMutator

Represents a single mutator operation (transform, clip rect, or clip path).

## Constructors

### Constructor

> **new FlutterMutator**(`args`): `FlutterMutator`

Constructs a new FlutterMutator instance.

#### Parameters

##### args

`any`

Either a transformation matrix, a clipping rectangle, or a clipping path

#### Returns

`FlutterMutator`

## Methods

### getMatrix()

> **getMatrix**(): `any`

Gets the transformation matrix, if this mutator is a transform.

#### Returns

`any`

The transformation matrix, or null if not a transform

***

### getPath()

> **getPath**(): `Path`

Gets the clipping path, if this mutator is a clip path.

#### Returns

`Path`

The clipping path

***

### getRect()

> **getRect**(): `Rect`

Gets the clipping rectangle, if this mutator is a clip rect.

#### Returns

`Rect`

The clipping rectangle
