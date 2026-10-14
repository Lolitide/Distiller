[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PlatformViewsController

Controller for managing platform views in Flutter applications.
This class handles the creation, lifecycle, and interaction of native views embedded in Flutter.

## Implements

- `unknown`

## Constructors

### Constructor

> **new PlatformViewsController**(): `PlatformViewsController`

Constructs a new PlatformViewsController instance.

#### Returns

`PlatformViewsController`

## Properties

### getParams()

> **getParams**: (`params`, `key`) => `number`

Gets a parameter value from the DVModelParameters.

#### Parameters

##### params

[`DVModelParameters`](../../../../view/DynamicView/dynamicView/classes/DVModelParameters.md)

The parameters object to read from

##### key

`string`

The parameter key

#### Returns

`number`

The parameter value as a number

***

### setParams()

> **setParams**: (`params`, `key`, `element`) => `void`

Sets a parameter value in the DVModelParameters.

#### Parameters

##### params

[`DVModelParameters`](../../../../view/DynamicView/dynamicView/classes/DVModelParameters.md)

The parameters object to modify

##### key

`string`

The parameter key

##### element

`Any`

The value to set

#### Returns

`void`

## Methods

### attach()

> **attach**(`context`, `textureRegistry`, `dartExecutor`): `void`

Attaches the controller to a context, texture registry, and Dart executor.

#### Parameters

##### context

`Context`

The application context

##### textureRegistry

[`TextureRegistry`](../../../../view/TextureRegistry/interfaces/TextureRegistry.md)

The texture registry for managing textures

##### dartExecutor

`DartExecutor`

The Dart executor for communication

#### Returns

`void`

***

### attachTextInputPlugin()

> **attachTextInputPlugin**(`textInputPlugin`): `void`

Attaches a text input plugin to this controller.

#### Parameters

##### textInputPlugin

`TextInputPlugin`

The TextInputPlugin instance

#### Returns

`void`

***

### attachToView()

> **attachToView**(`newFlutterView`): `void`

Attaches the controller to a FlutterView.

#### Parameters

##### newFlutterView

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

The FlutterView to attach to

#### Returns

`void`

***

### clearFocus()

> **clearFocus**(`viewId`): `void`

Clears focus from a platform view.

#### Parameters

##### viewId

`number`

The ID of the platform view

#### Returns

`void`

***

### createForPlatformViewLayer()

> **createForPlatformViewLayer**(`request`): `void`

Creates a platform view for hybrid composition mode.

#### Parameters

##### request

`PlatformViewCreationRequest`

The platform view creation request

#### Returns

`void`

***

### createForTextureLayer()

> **createForTextureLayer**(`request`): `number`

Creates a platform view for texture layer composition mode.

#### Parameters

##### request

`PlatformViewCreationRequest`

The platform view creation request

#### Returns

`number`

The texture ID for the created view

***

### createOverlaySurface()

> **createOverlaySurface**(): [`FlutterOverlaySurface`](../../../../embedding/engine/FlutterOverlaySurface/classes/FlutterOverlaySurface.md)

Creates a new overlay surface.

#### Returns

[`FlutterOverlaySurface`](../../../../embedding/engine/FlutterOverlaySurface/classes/FlutterOverlaySurface.md)

A new FlutterOverlaySurface instance

***

### detach()

> **detach**(): `void`

Detaches the controller and cleans up resources.

#### Returns

`void`

***

### detachFromView()

> **detachFromView**(`detachingFlutterView?`): `void`

Detaches the controller from the FlutterView.

#### Parameters

##### detachingFlutterView?

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

#### Returns

`void`

***

### detachTextInputPlugin()

> **detachTextInputPlugin**(): `void`

Detaches the text input plugin from this controller.

#### Returns

`void`

***

### dispose()

> **dispose**(`viewId`): `void`

Disposes a platform view and releases all associated resources.

#### Parameters

##### viewId

`number`

The ID of the platform view to dispose

#### Returns

`void`

***

### getFlutterView()

> **getFlutterView**(): [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

Gets the current FlutterView.

#### Returns

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

The FlutterView instance, or null if not attached

***

### getRegistry()

> **getRegistry**(): [`PlatformViewRegistry`](../../PlatformViewRegistry/interfaces/PlatformViewRegistry.md)

Gets the platform view registry.

#### Returns

[`PlatformViewRegistry`](../../PlatformViewRegistry/interfaces/PlatformViewRegistry.md)

The PlatformViewRegistry instance

***

### hover()

> **hover**(`viewId`): `void`

Sets the hover state for platform views.

#### Parameters

##### viewId

`number`

The ID of the platform view to set hover state for

#### Returns

`void`

***

### offset()

> **offset**(`viewId`, `top`, `left`): `void`

Updates the offset position of a platform view.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### top

`number`

The top offset

##### left

`number`

The left offset

#### Returns

`void`

***

### onBeginFrame()

> **onBeginFrame**(): `void`

Called at the beginning of each frame.
Clears the sets of used overlay layers and platform views.

#### Returns

`void`

***

### onDetachedFromNapi()

> **onDetachedFromNapi**(): `void`

Called when the controller is detached from NAPI.
Disposes all platform views.

#### Returns

`void`

***

### onDisplayOverlaySurface()

> **onDisplayOverlaySurface**(`id`, `x`, `y`, `width`, `height`): `void`

Called when an overlay surface should be displayed.

#### Parameters

##### id

`number`

The overlay surface ID

##### x

`number`

The X position

##### y

`number`

The Y position

##### width

`number`

The width

##### height

`number`

The height

#### Returns

`void`

***

### onEndFrame()

> **onEndFrame**(): `void`

Called at the end of each frame.

#### Returns

`void`

***

### onPreEngineRestart()

> **onPreEngineRestart**(): `void`

Called before the Flutter engine restarts.
Disposes all platform views.

#### Returns

`void`

***

### onTouch()

> **onTouch**(`touch`): `void`

Handles touch events for platform views.

#### Parameters

##### touch

`PlatformViewTouch`

The touch event information

#### Returns

`void`

***

### render()

> **render**(`surfaceId`, `platformView`, `width`, `height`, `left`, `top`): `void`

Renders a platform view with the specified dimensions and position.

#### Parameters

##### surfaceId

`number`

The surface ID

##### platformView

`PlatformView`

The platform view to render

##### width

`number`

The width in pixels

##### height

`number`

The height in pixels

##### left

`number`

The left position in pixels

##### top

`number`

The top position in pixels

#### Returns

`void`

***

### resize()

> **resize**(`request`, `onComplete`): `void`

Resizes a platform view.

#### Parameters

##### request

`PlatformViewResizeRequest`

The resize request containing new dimensions

##### onComplete

`PlatformViewBufferResized`

Callback to invoke when resize is complete

#### Returns

`void`

***

### setDirection()

> **setDirection**(`viewId`, `direction`): `void`

Sets the text direction for a platform view.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### direction

`Direction`

The text direction to set

#### Returns

`void`

***

### synchronizeToNativeViewHierarchy()

> **synchronizeToNativeViewHierarchy**(`yes`): `void`

Synchronizes the native view hierarchy.

#### Parameters

##### yes

`boolean`

Whether to synchronize

#### Returns

`void`

#### Throws

Error as this method is not implemented

***

### validateDirection()

> **validateDirection**(`direction`): `boolean`

Validates if a direction value is valid.

#### Parameters

##### direction

`number`

The direction value to validate

#### Returns

`boolean`

True if the direction is valid, false otherwise
