[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterMutatorsStack

Stack of mutators that can be applied to Flutter views.
This class manages transformations, clipping rectangles, and clipping paths
that are applied in sequence to create the final view appearance.

## Constructors

### Constructor

> **new FlutterMutatorsStack**(): `FlutterMutatorsStack`

Constructs a new FlutterMutatorsStack instance.

#### Returns

`FlutterMutatorsStack`

## Methods

### getFinalClippingPaths()

> **getFinalClippingPaths**(): `List`\<`Path`\>

Gets all final clipping paths.

#### Returns

`List`\<`Path`\>

List of all clipping paths

***

### getFinalClippingRects()

> **getFinalClippingRects**(): `List`\<`Rect`\>

Gets all final clipping rectangles.

#### Returns

`List`\<`Rect`\>

List of all clipping rectangles

***

### getFinalMatrix()

> **getFinalMatrix**(): `Matrix4Transit`

Gets the final combined transformation matrix.

#### Returns

`Matrix4Transit`

The combined transformation matrix from all transforms

***

### getMutators()

> **getMutators**(): `List`\<[`FlutterMutator`](FlutterMutator.md)\>

Gets all mutators in the stack.

#### Returns

`List`\<[`FlutterMutator`](FlutterMutator.md)\>

List of all mutators

***

### pushClipPath()

> **pushClipPath**(`width`, `height`, `command?`): `void`

Pushes a path-based clipping region onto the mutators stack.

#### Parameters

##### width

`number`

The width of the clipping path

##### height

`number`

The height of the clipping path

##### command?

`string`

Optional SVG path commands

#### Returns

`void`

***

### pushClipRect()

> **pushClipRect**(`width`, `height`, `radius?`): `void`

Pushes a rectangular clipping region onto the mutators stack.

#### Parameters

##### width

`number`

The width of the clipping rectangle

##### height

`number`

The height of the clipping rectangle

##### radius?

`number`

Optional corner radius for rounded rectangles

#### Returns

`void`

***

### pushTransform()

> **pushTransform**(`values`): `void`

Pushes a transformation matrix onto the mutators stack.

#### Parameters

##### values

`number`[]

Array of 16 numbers representing a 4x4 transformation matrix

#### Returns

`void`
