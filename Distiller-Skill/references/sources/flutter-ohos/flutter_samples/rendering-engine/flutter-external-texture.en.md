# Flutter OHOS External Texture Adaptation Overview

Flutter uses external textures on the OHOS platform. For video playback and camera preview, the registration method is the same — obtain `textureId` via `TextureRegistry` and register the texture, then Flutter Engine returns `surfaceId`. For image display, the texture is registered with the Flutter Engine in the form of a `PixelMap`.

> **Note**
>
> 1. To facilitate code reuse, the OHOS platform's Flutter external texture integration code is typically encapsulated as an independent module/HAR plugin and registered with the Flutter Engine. Refer to the video playback demo: [video_player_ohos](https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player_ohos/example).
>
> 2. **Background color setting**: `TextureRegistry` provides the `setTextureBackGroundPixelMap()` method, which can set the background frame (first frame) PixelMap after texture registration, avoiding blank display when the texture initially appears. The video playback plugin has already utilized this API to implement video first frame preview functionality.

---

## Core Concepts

| Term | Description |
|------|------|
| `TextureRegistry` | Texture registration manager provided by Flutter Engine, obtainable via `FlutterPluginBinding.getTextureRegistry()` |
| `textureId` | Texture identifier used by the Dart-side `Texture` Widget, allocated by `TextureRegistry.getTextureId()` |
| `surfaceId` | Surface identifier used on the OHOS native side, obtained from the `SurfaceTextureEntry` returned by `TextureRegistry.registerTexture()` |
| `SurfaceTextureEntry` | Entry object returned after registering a texture, containing `textureId` and `surfaceId` |
| `registerPixelMap()` | PixelMap registration interface provided by `TextureRegistry`, used for image external texture scenarios |

### Texture Registration Flow Comparison

| Scenario | Registration Method | Returned to Dart | Native Side Usage |
|----------|---------------------|-----------------|-------------------|
| Video Playback / Camera Preview | `getTextureId()` → `registerTexture()` → obtain `surfaceId` | `textureId` | Assign `surfaceId` to AVPlayer or Camera PreviewOutput |
| Image Display | Directly call `registerPixelMap(pixelMap)` | `textureId` | No `surfaceId` needed |

---

# Camera Preview

## Demo URL

[test_camera](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testcamera)

## Implementation Guide

### 1. Implement the plugin, obtain TextureRegistry

In `onAttachedToEngine`, obtain `TextureRegistry` from `FlutterPluginBinding`:

```typescript
// CameraPlugin.ets
import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { TextureRegistry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import MethodChannel, { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';

export class CameraPlugin implements FlutterPlugin, MethodCallHandler {
  private binding: FlutterPluginBinding | null = null;
  private mMethodChannel: MethodChannel | null = null;
  private textureRegistry: TextureRegistry | null = null;
  private textureId: number = -1;
  private surfaceId: number = -1;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.binding = binding;
    this.mMethodChannel = new MethodChannel(binding.getBinaryMessenger(), "CameraControlChannel");
    this.mMethodChannel.setMethodCallHandler(this);
    this.textureRegistry = binding.getTextureRegistry();
  }
}
```

### 2. Register texture, obtain surfaceId

Respond to the Dart-side `registerTexture` call in the MethodCallHandler:

```typescript
onMethodCall(call: MethodCall, result: MethodResult): void {
  switch (call.method) {
    case "registerTexture":
      this.registerCameraTexture();
      result.success(this.textureId);
      break;
    case "startCamera":
      this.startCamera();
      result.success(null);
      break;
    case "unregisterTexture":
      this.unregisterTexture(call.argument("textureId"));
      result.success(null);
      break;
  }
}

registerCameraTexture(): void {
  // First obtain textureId, then register the texture with Flutter Engine
  this.textureId = this.textureRegistry!.getTextureId();
  // registerTexture returns SurfaceTextureEntry, from which surfaceId is obtained
  let surfaceTextureEntry = this.textureRegistry!.registerTexture(this.textureId);
  this.surfaceId = surfaceTextureEntry!.getSurfaceId();
}

unregisterTexture(textureId: number): void {
  this.textureRegistry!.unregisterTexture(textureId);
}
```

### 3. Start camera preview, use surfaceId

Pass `surfaceId` to the OHOS camera's `PreviewOutput` so that the camera preview is rendered onto the Flutter texture:

```typescript
import { common } from '@kit.AbilityKit';

startSession() {
  let cameraManager = getCameraManager(getContext(this) as common.BaseContext);
  let cameraDevices = getCameraDevices(cameraManager);
  let cameraInput = getCameraInput(cameraDevices[0], cameraManager);
  if (cameraInput != null) {
    getSupportedOutputCapability(cameraDevices[0], cameraManager, cameraInput)
      .then((supportedOutputCapability) => {
        if (supportedOutputCapability != undefined) {
          // Pass surfaceId into PreviewOutput
          let previewOutput = getPreviewOutput(
            cameraManager,
            supportedOutputCapability,
            this.surfaceId.toString()
          );
          let captureSession = getCaptureSession(cameraManager);
          beginConfig(captureSession);
          setSessionCameraInput(captureSession, cameraInput);
          setSessionPreviewOutput(captureSession, previewOutput);
          startSession(captureSession);
        }
      });
  }
}
```

### 4. Dart-side implementation

Trigger texture registration and camera start via `MethodChannel`, and build the `Texture` Widget using `textureId`:

```dart
// CameraPage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const MethodChannel _channel = MethodChannel('CameraControlChannel');
  int textureId = -1;

  @override
  void initState() {
    super.initState();
    _registerTexture();
    _startCamera();
  }

  @override
  void dispose() {
    super.dispose();
    if (textureId >= 0) {
      _channel.invokeMethod('unregisterTexture', {'textureId': textureId});
    }
  }

  Future<void> _registerTexture() async {
    int id = await _channel.invokeMethod('registerTexture');
    setState(() { textureId = id; });
  }

  Future<void> _startCamera() async {
    await _channel.invokeMethod('startCamera');
  }

  @override
  Widget build(BuildContext context) {
    Widget body = textureId >= 0
        ? Container(
            width: 500,
            height: 500,
            child: Texture(textureId: textureId),
          )
        : const Text('loading...');
    return Scaffold(
      appBar: AppBar(title: const Text("camera_texture")),
      body: Center(child: body),
    );
  }
}
```

---

# Video Playback

## Demo URL

[video_player](https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player_ohos/example)

## Implementation Guide

Video playback uses the same texture registration method as camera preview. The difference is that `surfaceId` is assigned to `AVPlayer` instead of the camera PreviewOutput.

### 1. Implement FlutterPlugin + AbilityAware

`VideoPlayerPlugin` implements both `FlutterPlugin` and `AbilityAware`, encapsulating `TextureRegistry` into `FlutterState`:

```typescript
// VideoPlayerPlugin.ets
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import { TextureRegistry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import { VideoPlayerApiImpl } from './VideoPlayerApiImpl';

export class VideoPlayerPlugin implements FlutterPlugin, AbilityAware {
  private pluginBinding: FlutterPluginBinding | null = null;
  private videoPlayerApi: VideoPlayerApiImpl | null = null;
  private flutterState: FlutterState | null = null;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
    // Encapsulate BinaryMessenger and TextureRegistry into FlutterState
    this.flutterState = new FlutterState(
      binding.getBinaryMessenger(),
      binding.getTextureRegistry()
    );
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    if (this.flutterState != null && this.pluginBinding != null && this.videoPlayerApi == null) {
      this.videoPlayerApi = new VideoPlayerApiImpl(this.flutterState, binding);
      this.videoPlayerApi.setup(this.pluginBinding.getBinaryMessenger());
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = null;
    if (this.videoPlayerApi != null) {
      this.videoPlayerApi.detach();
      this.videoPlayerApi = null;
    }
  }
}

export class FlutterState {
  private binaryMessenger: BinaryMessenger;
  private textureRegistry: TextureRegistry;

  constructor(binaryMessenger: BinaryMessenger, textureRegistry: TextureRegistry) {
    this.binaryMessenger = binaryMessenger;
    this.textureRegistry = textureRegistry;
  }

  getBinaryMessenger(): BinaryMessenger { return this.binaryMessenger; }
  getTextureRegistry(): TextureRegistry { return this.textureRegistry; }
}
```

### 2. Create video player, register texture

In `VideoPlayerApiImpl.create()`, obtain `textureId` → register texture → obtain `surfaceId`, and return `textureId` to the Dart layer:

```typescript
// VideoPlayerApiImpl.ets (core snippet)
async create(arg: CreateMessage): Promise<TextureMessage> {
  let flutterRenderer = this.flutterState!.getTextureRegistry();
  let textureId: number = flutterRenderer.getTextureId();
  // Register the texture with Flutter Engine, returns SurfaceTextureEntry
  let surfaceTextureEntry: SurfaceTextureEntry = flutterRenderer.registerTexture(textureId);

  // Optional: Set video first frame background PixelMap
  // flutterRenderer.setTextureBackGroundPixelMap(textureId, pixelMap);

  let eventChannel = new EventChannel(
    this.flutterState!.getBinaryMessenger(),
    "flutter.io/videoPlayer/videoEvents" + textureId.toString()
  );

  let videoPlayer = new VideoPlayer(
    playerModel, surfaceTextureEntry, rawFile, url,
    eventChannel, this.AudioFocus, header
  );
  await videoPlayer.createAVPlayer();

  let textureMessage = new TextureMessage();
  textureMessage.setTextureId(textureId);
  return textureMessage;  // Return textureId to Dart layer
}
```

### 3. Obtain surfaceId from AVPlayer constructor

In the `VideoPlayer` constructor, obtain `surfaceId` from `SurfaceTextureEntry`:

```typescript
// VideoPlayer.ets
import media from '@ohos.multimedia.media';
import { SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';

export class VideoPlayer {
  private avPlayer: media.AVPlayer | null = null;
  private surfaceId: string = '';
  private textureEntry: SurfaceTextureEntry;

  constructor(playerModel, textureEntry, rawFile, url, eventChannel, AudioFocus, headers) {
    this.textureEntry = textureEntry;
    // Obtain surfaceId from SurfaceTextureEntry
    this.surfaceId = textureEntry.getSurfaceId().toString();
  }
}
```

### 4. Assign surfaceId after AVPlayer initialization

When `AVPlayer` enters the `INITIALIZED` state, assign `surfaceId` to the AVPlayer:

```typescript
// VideoPlayer.ets - bindState() method state listener
async bindState() {
  this.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
    switch (state) {
      case 'initialized':
        // Assign surfaceId to AVPlayer so that the video renders onto the Flutter texture
        this.avPlayer.surfaceId = this.surfaceId;
        this.avPlayer.prepare();
        break;
      case 'prepared':
        this.setVideoSize();
        this.sendInitialized();
        break;
      // ... other state handling
    }
  });
}
```

### 5. Dart layer uses textureId for rendering

After the Dart layer obtains `textureId`, rendering is completed via the `Texture` Widget:

```dart
// ohos_video_player.dart
@override
Widget buildView(int textureId) {
  return Texture(textureId: textureId);
}
```

---

# Image Display

## Demo URL

[test_picture](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testpicture)

## Implementation Guide

Image external texture does not require `surfaceId`. Instead, the texture is registered with the Flutter Engine in the form of a `PixelMap` using the `TextureRegistry.registerPixelMap()` interface.

### 1. Implement the plugin, obtain TextureRegistry

```typescript
// PicturePlugin.ets
import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import { TextureRegistry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
import image from '@ohos.multimedia.image';
import MethodChannel, { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { HashMap } from '@kit.ArkTS';

export class PicturePlugin implements FlutterPlugin, MethodCallHandler {
  private binding: FlutterPluginBinding | null = null;
  private mMethodChannel: MethodChannel | null = null;
  private textureRegistry: TextureRegistry | null = null;
  private pixelMapCache: HashMap<number, image.PixelMap> = new HashMap();

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.binding = binding;
    this.mMethodChannel = new MethodChannel(binding.getBinaryMessenger(), "PictureChannel");
    this.mMethodChannel.setMethodCallHandler(this);
    this.textureRegistry = binding.getTextureRegistry();
  }
}
```

### 2. Respond to register texture method call

```typescript
onMethodCall(call: MethodCall, result: MethodResult): void {
  switch (call.method) {
    case "registerTexture":
      this.registerPicturePixMap(call.argument("pic")).then((textureId: number) => {
        result.success(textureId);
      }).catch((err: Error) => {
        Log.e(TAG, "registerTexture error: " + JSON.stringify(err));
      });
      break;
    case "unregisterTexture":
      this.unregisterPicturePixelMap(call.argument("textureId"));
      result.success(null);
      break;
  }
}
```

### 3. Read image data, create PixelMap, register texture

```typescript
async registerPicturePixMap(pictureName: string): Promise<number> {
  // Read image data from rawfile
  let fileData = await this.binding!.getApplicationContext().resourceManager
      .getRawFileContent(`flutter_assets/${pictureName}`);
  let buffer: ArrayBuffer = fileData?.buffer as ArrayBuffer ?? new ArrayBuffer(0);

  // Create ImageSource → create PixelMap
  let imageSource: image.ImageSource = image.createImageSource(buffer);
  let pixelMap = await imageSource.createPixelMap();

  // Use registerPixelMap interface to register texture with Flutter Engine
  let textureId = this.textureRegistry!.registerPixelMap(pixelMap);
  this.pixelMapCache.set(textureId, pixelMap);
  return textureId;  // Return textureId to Dart layer
}

unregisterPicturePixelMap(textureId: number): void {
  let pixelMap = this.pixelMapCache.remove(textureId);
  pixelMap?.release();       // Release PixelMap resources
  this.textureRegistry!.unregisterTexture(textureId);  // Unregister texture
}
```

### 4. Dart layer uses textureId to render image

```dart
// PicturePage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('PictureChannel');

Future<int> registerTexture(String picName) async {
  return await _channel.invokeMethod("registerTexture", {'pic': picName});
}

Future<void> unregisterTexture(int textureId) async {
  await _channel.invokeMethod('unregisterTexture', {'textureId': textureId});
}

class PictureWidget extends StatefulWidget {
  const PictureWidget({super.key, required this.bean});
  final PicBean bean;
  @override
  State<PictureWidget> createState() => _PictureWidgetState();
}

class _PictureWidgetState extends State<PictureWidget> {
  int textureId = 0;

  @override
  void initState() {
    super.initState();
    registerTexture(widget.bean.name).then((id) {
      setState(() { textureId = id; });
    });
  }

  @override
  void dispose() {
    unregisterTexture(textureId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return textureId > 0
        ? SizedBox(
            width: 300,
            height: 300,
            child: Texture(textureId: textureId),
          )
        : const Text('loading...');
  }
}
```

---

# Texture Lifecycle Management

When using external textures, note the following lifecycle management points:

| Operation | Video Playback / Camera | Image |
|-----------|------------------------|-------|
| Register | `getTextureId()` → `registerTexture()` | `registerPixelMap()` |
| Unregister | `unregisterTexture(textureId)` | `unregisterTexture(textureId)` + `pixelMap.release()` |
| Set background | `setTextureBackGroundPixelMap(textureId, pixelMap)` | Not applicable |
| Dart-side unregister | Call `unregisterTexture` in `dispose()` | Call `unregisterTexture` in Widget `dispose()` |

> **Note**: `PixelMap` must be manually released by calling `release()` after unregistration to avoid memory leaks. The video player also needs to call `avPlayer.release()` in `dispose` to release player resources.