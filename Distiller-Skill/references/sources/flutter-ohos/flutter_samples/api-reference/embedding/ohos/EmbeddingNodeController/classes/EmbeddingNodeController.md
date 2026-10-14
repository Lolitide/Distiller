[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: EmbeddingNodeController

Node controller for embedding platform views in Flutter.
This class manages the lifecycle and rendering of platform views using BuilderNode.

## Extends

- `NodeController`

## Constructors

### Constructor

> **new EmbeddingNodeController**(): `EmbeddingNodeController`

#### Returns

`EmbeddingNodeController`

#### Inherited from

`NodeController.constructor`

## Methods

### disposeFrameNode()

> **disposeFrameNode**(): `void`

Disposes the frame node and cleans up resources.

#### Returns

`void`

***

### getBuilderNode()

> **getBuilderNode**(): `BuilderNode`\<\[[`Params`](../../../../plugin/platform/PlatformView/classes/Params.md)\]\>

Gets the builder node.

#### Returns

`BuilderNode`\<\[[`Params`](../../../../plugin/platform/PlatformView/classes/Params.md)\]\>

The BuilderNode instance, or null if not set

***

### getEmbedId()

> **getEmbedId**(): `string`

Gets the embed ID.

#### Returns

`string`

The embed ID string

***

### makeNode()

> **makeNode**(`uiContext`): `FrameNode`

Creates a FrameNode for the platform view.

#### Parameters

##### uiContext

`UIContext`

The UI context

#### Returns

`FrameNode`

The created FrameNode, or null if creation fails

***

### notifyPlatformViewInvisible()

> **notifyPlatformViewInvisible**(): `void`

Notify the PlatformView that it has entered an invisible state, and animations on it need to be inactive.

#### Returns

`void`

***

### postAxisEvent()

> **postAxisEvent**(`event`): `void`

Posts an axis event to the builder node.
Note: postInputEvent is an API20 interface, so we check for its existence to avoid compilation errors.

#### Parameters

##### event

`AxisEvent`

The axis event to post

#### Returns

`void`

***

### postEvent()

> **postEvent**(`event`, `isPx`): `boolean`

Posts a touch event to the builder node.

#### Parameters

##### event

`TouchEvent`

The touch event to post, or undefined

##### isPx

`boolean` = `false`

Whether the coordinates are already in pixels (default: false, will convert from vp to px)

#### Returns

`boolean`

Whether the event was successfully posted

***

### postMouseEvent()

> **postMouseEvent**(`event`): `void`

Posts a mouse event to the builder node.
Note: postInputEvent is an API20 interface, so we check for its existence to avoid compilation errors.

#### Parameters

##### event

`MouseEvent`

The mouse event to post

#### Returns

`void`

***

### setBuilderNode()

> **setBuilderNode**(`builderNode`): `void`

Sets the builder node.

#### Parameters

##### builderNode

`BuilderNode`\<[`Params`](../../../../plugin/platform/PlatformView/classes/Params.md)[]\>

The BuilderNode instance, or null

#### Returns

`void`

***

### setDestroy()

> **setDestroy**(`isDestroy`): `void`

Sets the destroy state and disposes the builder node if needed.

#### Parameters

##### isDestroy

`boolean`

Whether the controller is being destroyed

#### Returns

`void`

***

### setPlatformViewVisibleAreaEventCallback()

> **setPlatformViewVisibleAreaEventCallback**(): `void`

Set up the callback for monitoring changes in the visible area of the external texture.

#### Returns

`void`

***

### setRenderOption()

> **setRenderOption**(`platformView`, `surfaceId`, `renderType`, `direction`): `void`

Sets the render options for the platform view.

#### Parameters

##### platformView

`PlatformView`

The platform view instance

##### surfaceId

`string`

The surface ID

##### renderType

`NodeRenderType`

The render type

##### direction

`Direction`

The layout direction

#### Returns

`void`

***

### updateNode()

> **updateNode**(`arg`): `void`

Updates the node with new arguments.

#### Parameters

##### arg

`Object`

The update arguments

#### Returns

`void`
