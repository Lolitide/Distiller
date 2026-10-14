[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: PlatformViewResizeRequest

Request sent from Flutter to resize a platform view.

## Constructors

### Constructor

> **new PlatformViewResizeRequest**(`viewId`, `newLogicalWidth`, `newLogicalHeight`): `PlatformViewResizeRequest`

Constructs a new PlatformViewResizeRequest instance.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### newLogicalWidth

`number`

The new density-independent width

##### newLogicalHeight

`number`

The new density-independent height

#### Returns

`PlatformViewResizeRequest`

## Properties

### newLogicalHeight

> **newLogicalHeight**: `number`

The new density independent height to display the platform view.

***

### newLogicalWidth

> **newLogicalWidth**: `number`

The new density independent width to display the platform view.

***

### viewId

> **viewId**: `number`

The ID of the platform view as seen by the Flutter side.
