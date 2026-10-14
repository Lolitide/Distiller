[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: PlatformViewCreationRequest

Request sent from Flutter to create a new platform view.

## Constructors

### Constructor

> **new PlatformViewCreationRequest**(`viewId`, `viewType`, `logicalTop`, `logicalLeft`, `logicalWidth`, `logicalHeight`, `direction`, `params`, `displayMode?`): `PlatformViewCreationRequest`

Constructs a new PlatformViewCreationRequest instance.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### viewType

`string`

The type of view to create

##### logicalTop

`number`

The density-independent top position

##### logicalLeft

`number`

The density-independent left position

##### logicalWidth

`number`

The density-independent width

##### logicalHeight

`number`

The density-independent height

##### direction

`Direction`

The layout direction

##### params

[`ByteBuffer`](../../../../../util/ByteBuffer/classes/ByteBuffer.md)

Custom parameters for the view

##### displayMode?

`RequestedDisplayMode`

The requested display mode (optional)

#### Returns

`PlatformViewCreationRequest`

## Properties

### direction

> **direction**: `Direction`

The layout direction of the new platform view.

***

### displayMode

> **displayMode**: `RequestedDisplayMode`

The requested display mode for the platform view.

***

### logicalHeight

> **logicalHeight**: `number`

The density independent height to display the platform view.

***

### logicalLeft

> **logicalLeft**: `number`

The density independent left position to display the platform view.

***

### logicalTop

> **logicalTop**: `number`

The density independent top position to display the platform view.

***

### logicalWidth

> **logicalWidth**: `number`

The density independent width to display the platform view.

***

### params

> **params**: [`ByteBuffer`](../../../../../util/ByteBuffer/classes/ByteBuffer.md)

Custom parameters that are unique to the desired platform view.

***

### viewId

> **viewId**: `number`

The ID of the platform view as seen by the Flutter side.

***

### viewType

> **viewType**: `string`

The type of view to create for this platform view.
