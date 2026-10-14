[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: PlatformViewsHandler

Handler that receives platform view messages sent from Flutter to OpenHarmony through a given
PlatformViewsChannel.

To register a PlatformViewsHandler with a PlatformViewsChannel,
see PlatformViewsChannel.setPlatformViewsHandler.

## Methods

### clearFocus()

> **clearFocus**(`viewId`): `void`

Clears the focus from the platform view with a given id if it is currently focused.

#### Parameters

##### viewId

`number`

The ID of the platform view

#### Returns

`void`

***

### createForPlatformViewLayer()

> **createForPlatformViewLayer**(`request`): `void`

The Flutter application would like to display a new OpenHarmony View, i.e., platform view.

The OpenHarmony View is added to the view hierarchy. This view is rendered in the Flutter
framework by a PlatformViewLayer.

#### Parameters

##### request

[`PlatformViewCreationRequest`](../classes/PlatformViewCreationRequest.md)

The metadata sent from the framework

#### Returns

`void`

***

### createForTextureLayer()

> **createForTextureLayer**(`request`): `number`

The Flutter application would like to display a new OpenHarmony View, i.e., platform view.

The OpenHarmony View is added to the view hierarchy. This view is rendered in the Flutter
framework by a TextureLayer.

The ID returned by createForTextureLayer to indicate that the requested texture mode
was not available and the view creation fell back to PlatformViewLayer mode.
This can only be returned if the PlatformViewCreationRequest sets
TEXTURE_WITH_HYBRID_FALLBACK as the requested display mode.

#### Parameters

##### request

[`PlatformViewCreationRequest`](../classes/PlatformViewCreationRequest.md)

The metadata sent from the framework

#### Returns

`number`

The texture ID, or NON_TEXTURE_FALLBACK if falling back to hybrid mode

***

### dispose()

> **dispose**(`viewId`): `void`

The Flutter application would like to dispose of an existing OpenHarmony View.

#### Parameters

##### viewId

`number`

The ID of the platform view to dispose

#### Returns

`void`

***

### hover()

> **hover**(`viewId`): `void`

Handles hover events on a platform view.

#### Parameters

##### viewId

`number`

The ID of the platform view

#### Returns

`void`

***

### offset()

> **offset**(`viewId`, `top`, `left`): `void`

The Flutter application would like to change the offset of an existing OpenHarmony View.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### top

`number`

The new top offset

##### left

`number`

The new left offset

#### Returns

`void`

***

### onTouch()

> **onTouch**(`touch`): `void`

The user touched a platform view within Flutter.

Touch data is reported in the touch parameter.

#### Parameters

##### touch

[`PlatformViewTouch`](../classes/PlatformViewTouch.md)

The touch event data

#### Returns

`void`

***

### resize()

> **resize**(`request`, `onComplete`): `void`

The Flutter application would like to resize an existing OpenHarmony View.

#### Parameters

##### request

[`PlatformViewResizeRequest`](../classes/PlatformViewResizeRequest.md)

The request to resize the platform view

##### onComplete

[`PlatformViewBufferResized`](../classes/PlatformViewBufferResized.md)

Once the resize is completed, this is the handler to notify the size of the
    platform view buffer

#### Returns

`void`

***

### setDirection()

> **setDirection**(`viewId`, `direction`): `void`

The Flutter application would like to change the layout direction of an existing OpenHarmony
View, i.e., platform view.

#### Parameters

##### viewId

`number`

The ID of the platform view

##### direction

`Direction`

The new layout direction

#### Returns

`void`

***

### synchronizeToNativeViewHierarchy()

> **synchronizeToNativeViewHierarchy**(`yes`): `void`

Whether the render surface of FlutterView should be converted to a
FlutterImageView when a PlatformView is added.

This is done to synchronize the rendering of the PlatformView and the FlutterView. Defaults
to true.

#### Parameters

##### yes

`boolean`

Whether to synchronize to native view hierarchy

#### Returns

`void`
