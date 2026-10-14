[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Interface: TextureRegistry

Registry of backend textures used with a single FlutterView instance.
Entries may be embedded into the Flutter view using the Texture widget.
Textures can be created from surface textures, image receivers, or pixel maps.

## Methods

### createSurfaceTexture()

> **createSurfaceTexture**(): [`SurfaceTextureEntry`](SurfaceTextureEntry.md)

#### Returns

[`SurfaceTextureEntry`](SurfaceTextureEntry.md)

***

### getTextureId()

> **getTextureId**(): `number`

#### Returns

`number`

***

### notifyTextureResizing()

> **notifyTextureResizing**(`textureId`, `width`, `height`): `void`

#### Parameters

##### textureId

`number`

##### width

`number`

##### height

`number`

#### Returns

`void`

***

### onTrimMemory()

> **onTrimMemory**(`level`): `void`

#### Parameters

##### level

`number`

#### Returns

`void`

***

### registerPixelMap()

> **registerPixelMap**(`pixelMap`): `number`

#### Parameters

##### pixelMap

`PixelMap`

#### Returns

`number`

***

### registerSurfaceTexture()

> **registerSurfaceTexture**(`receiver`): [`SurfaceTextureEntry`](SurfaceTextureEntry.md)

#### Parameters

##### receiver

`ImageReceiver`

#### Returns

[`SurfaceTextureEntry`](SurfaceTextureEntry.md)

***

### registerTexture()

> **registerTexture**(`textureId`): [`SurfaceTextureEntry`](SurfaceTextureEntry.md)

#### Parameters

##### textureId

`number`

#### Returns

[`SurfaceTextureEntry`](SurfaceTextureEntry.md)

***

### resetExternalTexture()

> **resetExternalTexture**(`textureId`, `need_surfaceId`): `number`

#### Parameters

##### textureId

`number`

##### need\_surfaceId

`boolean`

#### Returns

`number`

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

TextureRegistry#setExternalNativeImagePtr

***

### setExternalNativeImagePtr()

> **setExternalNativeImagePtr**(`textureId`, `native_image`): `boolean`

#### Parameters

##### textureId

`number`

##### native\_image

`bigint`

#### Returns

`boolean`

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

***

### setTextureBackGroundPixelMap()

> **setTextureBackGroundPixelMap**(`textureId`, `pixelMap`): `void`

#### Parameters

##### textureId

`number`

##### pixelMap

`PixelMap`

#### Returns

`void`

***

### setTextureBufferSize()

> **setTextureBufferSize**(`textureId`, `width`, `height`): `void`

#### Parameters

##### textureId

`number`

##### width

`number`

##### height

`number`

#### Returns

`void`

***

### unregisterTexture()

> **unregisterTexture**(`textureId`): `void`

#### Parameters

##### textureId

`number`

#### Returns

`void`
