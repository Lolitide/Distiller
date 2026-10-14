# Flutter OHOS 外接纹理适配简介

Flutter 在 OHOS 平台使用外接纹理时，视频播放和相机预览的注册方式一致——通过 `TextureRegistry` 获取 `textureId` 并注册纹理，Flutter Engine 返回 `surfaceId`。而图片场景则以 `PixelMap` 的形式注册到 Flutter Engine。

> **说明**
>
> 1. 为了方便复用，通常会将 OHOS 对接 Flutter 外接纹理的功能代码封装为一个独立的 module/HAR 插件注册到 Flutter Engine。参考视频播放的 Demo：[video_player_ohos](https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player_ohos/example)。
>
> 2. **背景色设置**：`TextureRegistry` 提供了 `setTextureBackGroundPixelMap()` 方法，可在纹理注册后设置背景帧（首帧）的 PixelMap，避免纹理初始显示时出现空白。视频播放插件已利用此 API 实现了视频首帧预览功能。

---

## 核心概念

| 术语 | 说明 |
|------|------|
| `TextureRegistry` | Flutter Engine 提供的纹理注册管理器，可通过 `FlutterPluginBinding.getTextureRegistry()` 获取 |
| `textureId` | Dart 侧 `Texture` Widget 使用的纹理标识，由 `TextureRegistry.getTextureId()` 分配 |
| `surfaceId` | OHOS 原生侧使用的 Surface 标识，由 `TextureRegistry.registerTexture()` 返回的 `SurfaceTextureEntry` 中获取 |
| `SurfaceTextureEntry` | 注册纹理后返回的入口对象，包含 `textureId` 和 `surfaceId` |
| `registerPixelMap()` | `TextureRegistry` 提供的 PixelMap 注册接口，用于图片外接纹理场景 |

### 纹理注册流程对比

| 场景 | 注册方式 | 返回给 Dart | 原生侧使用 |
|------|----------|-------------|-----------|
| 视频播放 / 相机预览 | `getTextureId()` → `registerTexture()` → 获取 `surfaceId` | `textureId` | `surfaceId` 赋给 AVPlayer 或 Camera PreviewOutput |
| 图片显示 | 直接调用 `registerPixelMap(pixelMap)` | `textureId` | 无需 `surfaceId` |

---

# 相机预览

## Demo 地址

[test_camera](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testcamera)

## 实现说明

### 1. 实现插件，获取 TextureRegistry

在 `onAttachedToEngine` 中，从 `FlutterPluginBinding` 获取 `TextureRegistry`：

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

### 2. 注册纹理，获取 surfaceId

在 MethodCallHandler 中响应 Dart 侧的 `registerTexture` 调用：

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
  // 先获取 textureId，再注册纹理到 Flutter Engine
  this.textureId = this.textureRegistry!.getTextureId();
  // registerTexture 返回 SurfaceTextureEntry，从中获取 surfaceId
  let surfaceTextureEntry = this.textureRegistry!.registerTexture(this.textureId);
  this.surfaceId = surfaceTextureEntry!.getSurfaceId();
}

unregisterTexture(textureId: number): void {
  this.textureRegistry!.unregisterTexture(textureId);
}
```

### 3. 启动相机预览，使用 surfaceId

将 `surfaceId` 传递给 OHOS 相机的 `PreviewOutput`，使相机预览画面渲染到 Flutter 纹理上：

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
          // 将 surfaceId 传入 PreviewOutput
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

### 4. Dart 侧实现

通过 `MethodChannel` 触发纹理注册和启动相机，使用 `textureId` 构建 `Texture` Widget：

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

# 视频播放

## Demo 地址

[video_player](https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player_ohos/example)

## 实现说明

视频播放和相机预览的纹理注册方式一致，区别在于 `surfaceId` 赋给 `AVPlayer` 而非相机 PreviewOutput。

### 1. 实现 FlutterPlugin + AbilityAware

`VideoPlayerPlugin` 同时实现 `FlutterPlugin` 和 `AbilityAware`，将 `TextureRegistry` 封装到 `FlutterState` 中：

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
    // 将 BinaryMessenger 和 TextureRegistry 封装到 FlutterState
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

### 2. 创建视频播放器，注册纹理

在 `VideoPlayerApiImpl.create()` 中，获取 `textureId` → 注册纹理 → 获得 `surfaceId`，并返回 `textureId` 给 Dart 层：

```typescript
// VideoPlayerApiImpl.ets（核心片段）
async create(arg: CreateMessage): Promise<TextureMessage> {
  let flutterRenderer = this.flutterState!.getTextureRegistry();
  let textureId: number = flutterRenderer.getTextureId();
  // 注册纹理到 Flutter Engine，返回 SurfaceTextureEntry
  let surfaceTextureEntry: SurfaceTextureEntry = flutterRenderer.registerTexture(textureId);

  // 可选：设置视频首帧背景 PixelMap
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
  return textureMessage;  // 返回 textureId 给 Dart 层
}
```

### 3. AVPlayer 构造时取出 surfaceId

`VideoPlayer` 构造方法中从 `SurfaceTextureEntry` 获取 `surfaceId`：

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
    // 从 SurfaceTextureEntry 中获取 surfaceId
    this.surfaceId = textureEntry.getSurfaceId().toString();
  }
}
```

### 4. AVPlayer 初始化后赋值 surfaceId

在 `AVPlayer` 进入 `INITIALIZED` 状态时，将 `surfaceId` 赋给 AVPlayer：

```typescript
// VideoPlayer.ets - bindState() 方法中的状态监听
async bindState() {
  this.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
    switch (state) {
      case 'initialized':
        // 将 surfaceId 赋给 AVPlayer，使视频画面渲染到 Flutter 纹理
        this.avPlayer.surfaceId = this.surfaceId;
        this.avPlayer.prepare();
        break;
      case 'prepared':
        this.setVideoSize();
        this.sendInitialized();
        break;
      // ... 其他状态处理
    }
  });
}
```

### 5. Dart 层使用 textureId 渲染

Dart 层拿到 `textureId` 后，通过 `Texture` Widget 完成渲染：

```dart
// ohos_video_player.dart
@override
Widget buildView(int textureId) {
  return Texture(textureId: textureId);
}
```

---

# 图片显示

## Demo 地址

[test_picture](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/testpicture)

## 使用说明

图片外接纹理不需要 `surfaceId`，而是以 `PixelMap` 形式直接注册到 Flutter Engine，使用 `TextureRegistry.registerPixelMap()` 接口。

### 1. 实现插件，获取 TextureRegistry

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

### 2. 响应注册纹理方法调用

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

### 3. 读取图片数据，创建 PixelMap，注册纹理

```typescript
async registerPicturePixMap(pictureName: string): Promise<number> {
  // 从 rawfile 读取图片数据
  let fileData = await this.binding!.getApplicationContext().resourceManager
      .getRawFileContent(`flutter_assets/${pictureName}`);
  let buffer: ArrayBuffer = fileData?.buffer as ArrayBuffer ?? new ArrayBuffer(0);

  // 创建 ImageSource → 创建 PixelMap
  let imageSource: image.ImageSource = image.createImageSource(buffer);
  let pixelMap = await imageSource.createPixelMap();

  // 使用 registerPixelMap 接口注册纹理到 Flutter Engine
  let textureId = this.textureRegistry!.registerPixelMap(pixelMap);
  this.pixelMapCache.set(textureId, pixelMap);
  return textureId;  // 返回 textureId 给 Dart 层
}

unregisterPicturePixelMap(textureId: number): void {
  let pixelMap = this.pixelMapCache.remove(textureId);
  pixelMap?.release();       // 释放 PixelMap 资源
  this.textureRegistry!.unregisterTexture(textureId);  // 反注册纹理
}
```

### 4. Dart 层使用 textureId 渲染图片

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

# 纹理生命周期管理

在使用外接纹理时，需注意以下生命周期管理要点：

| 操作 | 视频播放 / 相机 | 图片 |
|------|-----------------|------|
| 注册 | `getTextureId()` → `registerTexture()` | `registerPixelMap()` |
| 反注册 | `unregisterTexture(textureId)` | `unregisterTexture(textureId)` + `pixelMap.release()` |
| 设置背景 | `setTextureBackGroundPixelMap(textureId, pixelMap)` | 不适用 |
| Dart 侧反注册 | `dispose()` 时调用 `unregisterTexture` | Widget `dispose()` 时调用 `unregisterTexture` |

> **注意**：`PixelMap` 需在反注册后手动调用 `release()` 释放资源，避免内存泄漏。视频播放器也需在 `dispose` 时调用 `avPlayer.release()` 释放播放器资源。
