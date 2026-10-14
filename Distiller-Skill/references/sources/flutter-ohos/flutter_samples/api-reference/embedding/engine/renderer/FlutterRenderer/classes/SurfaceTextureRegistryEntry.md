[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: SurfaceTextureRegistryEntry

Entry in the surface texture registry representing a registered texture.
This class holds information about a texture including its ID, surface ID, and native window information.

## Implements

- [`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md)

## Constructors

### Constructor

> **new SurfaceTextureRegistryEntry**(`id`): `SurfaceTextureRegistryEntry`

Constructs a new SurfaceTextureRegistryEntry instance.

#### Parameters

##### id

`number`

The texture ID

#### Returns

`SurfaceTextureRegistryEntry`

## Methods

### ~~getNativeWindowId()~~

> **getNativeWindowId**(): `number`

#### Returns

`number`

#### Deprecated

since 3.22

#### Useinstead

SurfaceTextureRegistryEntry#getNativeWindowPtr

#### Implementation of

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md).[`getNativeWindowId`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md#getnativewindowid)

***

### getNativeWindowPtr()

> **getNativeWindowPtr**(): `bigint`

Gets the native window pointer.

#### Returns

`bigint`

The native window pointer as a bigint

***

### getSurfaceId()

> **getSurfaceId**(): `number`

Gets the surface ID.

#### Returns

`number`

The surface ID

#### Implementation of

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md).[`getSurfaceId`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md#getsurfaceid)

***

### getTextureId()

> **getTextureId**(): `number`

Gets the texture ID.

#### Returns

`number`

The texture ID

#### Implementation of

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md).[`getTextureId`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md#gettextureid)

***

### release()

> **release**(): `void`

Releases this texture entry and frees associated resources.

#### Returns

`void`

#### Implementation of

[`SurfaceTextureEntry`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md).[`release`](../../../../../view/TextureRegistry/interfaces/SurfaceTextureEntry.md#release)

***

### ~~setNativeWindowId()~~

> **setNativeWindowId**(`nativeWindowId`): `void`

#### Parameters

##### nativeWindowId

`number`

#### Returns

`void`

#### Deprecated

since 3.22

#### Useinstead

SurfaceTextureRegistryEntry#setNativeWindowPtr

***

### setNativeWindowPtr()

> **setNativeWindowPtr**(`nativeWindowPtr`): `void`

Sets the native window pointer.

#### Parameters

##### nativeWindowPtr

`bigint`

The native window pointer as a bigint

#### Returns

`void`

***

### setSurfaceId()

> **setSurfaceId**(`surfaceId`): `void`

Sets the surface ID.

#### Parameters

##### surfaceId

`number`

The surface ID to set

#### Returns

`void`
