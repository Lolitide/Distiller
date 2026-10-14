[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: FlutterAssets

Provides Flutter plugins with access to Flutter asset information.

## Methods

### getAssetFilePathByName()

#### Call Signature

> **getAssetFilePathByName**(`assetFileName`): `string`

Returns the relative file path to the Flutter asset with the given name, including the file's
extension, e.g., "myImage.jpg".

The returned file path is relative to the OpenHarmony app's standard assets directory.
Therefore, the returned path is appropriate to pass to OpenHarmony's ResourceManager, but
the path is not appropriate to load as an absolute path.

##### Parameters

###### assetFileName

`string`

The name of the asset file

##### Returns

`string`

The relative file path to the asset

#### Call Signature

> **getAssetFilePathByName**(`assetFileName`, `bundleName`): `string`

Same as getAssetFilePathByName but with added support for an explicit bundleName.

##### Parameters

###### assetFileName

`string`

The name of the asset file

###### bundleName

`string`

The bundle name

##### Returns

`string`

The relative file path to the asset

***

### getAssetFilePathBySubpath()

#### Call Signature

> **getAssetFilePathBySubpath**(`assetSubpath`): `string`

Returns the relative file path to the Flutter asset with the given subpath, including the
file's extension, e.g., "/dir1/dir2/myImage.jpg".

The returned file path is relative to the OpenHarmony app's standard assets directory.
Therefore, the returned path is appropriate to pass to OpenHarmony's ResourceManager, but
the path is not appropriate to load as an absolute path.

##### Parameters

###### assetSubpath

`string`

The subpath of the asset

##### Returns

`string`

The relative file path to the asset

#### Call Signature

> **getAssetFilePathBySubpath**(`assetSubpath`, `bundleName`): `string`

Same as getAssetFilePathBySubpath but with added support for an explicit bundleName.

##### Parameters

###### assetSubpath

`string`

The subpath of the asset

###### bundleName

`string`

The bundle name

##### Returns

`string`

The relative file path to the asset
