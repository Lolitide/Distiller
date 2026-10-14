[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: ViewportMetrics

Metrics describing the viewport dimensions and insets.
This class holds information about the physical dimensions, padding, insets, and display features.

## Constructors

### Constructor

> **new ViewportMetrics**(): `ViewportMetrics`

#### Returns

`ViewportMetrics`

## Properties

### devicePixelRatio

> **devicePixelRatio**: `number` = `1.0`

Device pixel ratio for converting logical to physical pixels.

***

### displayFeatures

> **displayFeatures**: `ArrayList`\<[`DisplayFeature`](DisplayFeature.md)\>

List of display features such as folds, hinges, or cutouts.

***

### physicalHeight

> **physicalHeight**: `number` = `0`

Physical height of the viewport in pixels.

***

### physicalTouchSlop

> **physicalTouchSlop**: `number` = `-1`

Physical touch slop value, or -1 if not set.

***

### physicalViewInsetBottom

> **physicalViewInsetBottom**: `number` = `0`

Bottom inset of the viewport in physical pixels.

***

### physicalViewInsetLeft

> **physicalViewInsetLeft**: `number` = `0`

Left inset of the viewport in physical pixels.

***

### physicalViewInsetRight

> **physicalViewInsetRight**: `number` = `0`

Right inset of the viewport in physical pixels.

***

### physicalViewInsetTop

> **physicalViewInsetTop**: `number` = `0`

Top inset of the viewport in physical pixels.

***

### physicalViewPaddingBottom

> **physicalViewPaddingBottom**: `number` = `0`

Bottom padding of the viewport in physical pixels.

***

### physicalViewPaddingLeft

> **physicalViewPaddingLeft**: `number` = `0`

Left padding of the viewport in physical pixels.

***

### physicalViewPaddingRight

> **physicalViewPaddingRight**: `number` = `0`

Right padding of the viewport in physical pixels.

***

### physicalViewPaddingTop

> **physicalViewPaddingTop**: `number` = `0`

Top padding of the viewport in physical pixels.

***

### physicalWidth

> **physicalWidth**: `number` = `0`

Physical width of the viewport in pixels.

***

### systemGestureInsetBottom

> **systemGestureInsetBottom**: `number` = `0`

Bottom system gesture inset in physical pixels.

***

### systemGestureInsetLeft

> **systemGestureInsetLeft**: `number` = `0`

Left system gesture inset in physical pixels.

***

### systemGestureInsetRight

> **systemGestureInsetRight**: `number` = `0`

Right system gesture inset in physical pixels.

***

### systemGestureInsetTop

> **systemGestureInsetTop**: `number` = `0`

Top system gesture inset in physical pixels.

## Methods

### clone()

> **clone**(): `ViewportMetrics`

Creates a deep copy of this ViewportMetrics instance.

#### Returns

`ViewportMetrics`

A new ViewportMetrics instance with copied values

***

### isEqual()

> **isEqual**(`other`): `boolean`

Checks if this ViewportMetrics is equal to another.

#### Parameters

##### other

`ViewportMetrics`

The other ViewportMetrics to compare with

#### Returns

`boolean`

True if all metrics are equal, false otherwise
