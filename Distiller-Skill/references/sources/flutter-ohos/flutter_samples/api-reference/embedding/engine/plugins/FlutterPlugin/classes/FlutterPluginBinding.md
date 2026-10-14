[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterPluginBinding

Binding that provides Flutter plugins with access to Flutter engine resources.
This class holds references to the engine, messenger, assets, and registries that plugins may need.

## Constructors

### Constructor

> **new FlutterPluginBinding**(`applicationContext`, `flutterEngine`, `binaryMessenger`, `flutterAssets`, `textureRegistry`, `platformViewRegistry?`): `FlutterPluginBinding`

Constructs a new FlutterPluginBinding instance.

#### Parameters

##### applicationContext

`Context`

The application context

##### flutterEngine

`FlutterEngine`

The FlutterEngine instance

##### binaryMessenger

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger for platform communication

##### flutterAssets

[`FlutterAssets`](../interfaces/FlutterAssets.md)

The FlutterAssets for accessing Flutter assets

##### textureRegistry

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md)

The TextureRegistry for managing textures

##### platformViewRegistry?

[`PlatformViewRegistry`](../../../../../plugin/platform/PlatformViewRegistry/interfaces/PlatformViewRegistry.md)

Optional PlatformViewRegistry, will be created if not provided

#### Returns

`FlutterPluginBinding`

## Methods

### getApplicationContext()

> **getApplicationContext**(): `Context`

Gets the application context.

#### Returns

`Context`

The application context

***

### getBinaryMessenger()

> **getBinaryMessenger**(): [`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

Gets the BinaryMessenger for platform communication.

#### Returns

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

The BinaryMessenger instance

***

### getFlutterAssets()

> **getFlutterAssets**(): [`FlutterAssets`](../interfaces/FlutterAssets.md)

Gets the FlutterAssets for accessing Flutter assets.

#### Returns

[`FlutterAssets`](../interfaces/FlutterAssets.md)

The FlutterAssets instance

***

### getFlutterEngine()

> **getFlutterEngine**(): `FlutterEngine`

Gets the FlutterEngine instance.

#### Returns

`FlutterEngine`

The FlutterEngine instance

***

### getPlatformViewRegistry()

> **getPlatformViewRegistry**(): [`PlatformViewRegistry`](../../../../../plugin/platform/PlatformViewRegistry/interfaces/PlatformViewRegistry.md)

Gets the PlatformViewRegistry for managing platform views.

#### Returns

[`PlatformViewRegistry`](../../../../../plugin/platform/PlatformViewRegistry/interfaces/PlatformViewRegistry.md)

The PlatformViewRegistry instance

***

### getTextureRegistry()

> **getTextureRegistry**(): [`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md)

Gets the TextureRegistry for managing textures.

#### Returns

[`TextureRegistry`](../../../../../view/TextureRegistry/interfaces/TextureRegistry.md)

The TextureRegistry instance
