[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterRenderer

Renderer for Flutter content that manages textures and rendering operations.
This class implements TextureRegistry and provides methods to register and manage textures
for use in Flutter applications.

## Implements

- [`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md)

## Constructors

### Constructor

> **new FlutterRenderer**(`flutterNapi`): `FlutterRenderer`

Constructs a new FlutterRenderer instance.

#### Parameters

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

#### Returns

`FlutterRenderer`

## Methods

### ~~createSurfaceTexture()~~

> **createSurfaceTexture**(): [`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

#### Returns

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

#### Deprecated

since 3.7

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`createSurfaceTexture`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#createsurfacetexture)

***

### getTextureId()

> **getTextureId**(): `number`

Gets the next available texture ID.

#### Returns

`number`

A unique texture ID

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`getTextureId`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#gettextureid)

***

### notifyTextureResizing()

> **notifyTextureResizing**(`textureId`, `width`, `height`): `void`

Notifies the Flutter engine that a texture is being resized.

#### Parameters

##### textureId

`number`

The texture ID

##### width

`number`

The new width

##### height

`number`

The new height

#### Returns

`void`

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`notifyTextureResizing`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#notifytextureresizing)

***

### onTrimMemory()

> **onTrimMemory**(`level`): `void`

Called when the system needs to trim memory.

#### Parameters

##### level

`number`

The memory trim level

#### Returns

`void`

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`onTrimMemory`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#ontrimmemory)

***

### registerPixelMap()

> **registerPixelMap**(`pixelMap`): `number`

Registers a PixelMap as a texture.

#### Parameters

##### pixelMap

`PixelMap`

The PixelMap to register

#### Returns

`number`

The texture ID assigned to the PixelMap

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`registerPixelMap`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#registerpixelmap)

***

### ~~registerSurfaceTexture()~~

> **registerSurfaceTexture**(`receiver`): [`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

#### Parameters

##### receiver

`ImageReceiver`

#### Returns

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

#### Deprecated

since 3.7

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`registerSurfaceTexture`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#registersurfacetexture)

***

### registerTexture()

> **registerTexture**(`textureId`): [`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

Registers a texture with the Flutter engine.

#### Parameters

##### textureId

`number`

The texture ID to register

#### Returns

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

A SurfaceTextureEntry containing the registered texture information

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`registerTexture`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#registertexture)

***

### resetExternalTexture()

> **resetExternalTexture**(`textureId`, `need_surfaceId`): `number`

Resets an external texture.

#### Parameters

##### textureId

`number`

The texture ID

##### need\_surfaceId

`boolean`

Whether a surface ID is needed

#### Returns

`number`

The result code

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`resetExternalTexture`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#resetexternaltexture)

***

### ~~setExternalNativeImage()~~

> **setExternalNativeImage**(`textureId`, `native_image`): `boolean`

#### Parameters

##### textureId

`number`

##### native\_image

`number`

#### Returns

`boolean`

#### Deprecated

since 3.22

#### Useinstead

FlutterRenderer#setExternalNativeImagePtr

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`setExternalNativeImage`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#setexternalnativeimage)

***

### setExternalNativeImagePtr()

> **setExternalNativeImagePtr**(`textureId`, `native_image_ptr`): `boolean`

Sets an external native image pointer for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### native\_image\_ptr

`bigint`

The native image pointer as a bigint

#### Returns

`boolean`

true if successful, false otherwise

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`setExternalNativeImagePtr`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#setexternalnativeimageptr)

***

### ~~setTextureBackGroundColor()~~

> **setTextureBackGroundColor**(`textureId`, `color`): `void`

#### Parameters

##### textureId

`number`

##### color

`number`

#### Returns

`void`

#### Deprecated

since 3.7

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`setTextureBackGroundColor`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#settexturebackgroundcolor)

***

### setTextureBackGroundPixelMap()

> **setTextureBackGroundPixelMap**(`textureId`, `pixelMap`): `void`

Sets the background PixelMap for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### pixelMap

`PixelMap`

The PixelMap to use as background

#### Returns

`void`

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`setTextureBackGroundPixelMap`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#settexturebackgroundpixelmap)

***

### setTextureBufferSize()

> **setTextureBufferSize**(`textureId`, `width`, `height`): `void`

Sets the buffer size for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### width

`number`

The buffer width

##### height

`number`

The buffer height

#### Returns

`void`

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`setTextureBufferSize`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#settexturebuffersize)

***

### unregisterTexture()

> **unregisterTexture**(`textureId`): `void`

Unregisters a texture from the Flutter engine.

#### Parameters

##### textureId

`number`

The texture ID to unregister

#### Returns

`void`

#### Implementation of

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md).[`unregisterTexture`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md#unregistertexture)
