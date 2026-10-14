# 如何导入自渲染内容到 Flutter

## 背景介绍

支持将外部自渲染内容（无论是通过 `NativeDrawing` 等 OHOS CAPI 绘制，还是通过 OpenGL 接口绘制）通过外接纹理的方式导入 Flutter 的 `Texture` 组件进行展示。

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)。
- Flutter OH 版本需要 3.22 及以上。

---

## 实现步骤

### 第一步：Dart 侧操作

#### 创建 Texture 组件

- 创建Texture组件，绑定textureId

#### 注册纹理

- 创建 `MethodChannel`：

  ```dart
  final MethodChannel _channel = const MethodChannel('PictureChannel1');
  ```

- 在 `initState` 函数中注册纹理：

  ```dart
  _textureId = await _channel.invokeMethod("registerStarTexture");
  ```

#### 注销纹理

- 在 `dispose` 函数中注销纹理：

  ```dart
  _channel.invokeMethod('unregisterTexture', {'textureId': _textureId});
  ```

---

### 第二步：OHOS 侧操作

#### 引入工具类

需要引入以下工具类：

```ts
import { TextureRegistry, SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
```

#### 提供的实现方式

本文提供两种将自渲染内容导入 Flutter 纹理的实现方式。

---

## 实现方式一：通过 `getNativeWindowId` 绘制到 Buffer

通过 `getNativeWindowId` 获取引擎层 `Texture` 对应的 `OHNativeWindow` 指针，然后将自渲染内容绘制到该 `window` 对应的 Buffer 上。

### ArkTS 侧实现步骤

1. 注册纹理时获取相关信息：

```ts
    this.textureId = this.textureRegistry!.getTextureId();
    this.surfaceTextureEntry = this.textureRegistry!.registerTexture(this.textureId);
    this.windowId = this.surfaceTextureEntry.getNativeWindowId();
    drawNapi.drawPatternWindow(this.windowId, 300, 300);// 需要在cpp层实现draw函数，接收window指针
```

2. 上述 `drawNapi.drawPatternWindow(this.windowId, 300, 300)` 中的 `drawPatternWindow` 需在 cpp 层实现，接收 `window` 指针并将自渲染内容绘制到该 `window` 对应的 Buffer 上。

### CPP 侧实现步骤

1. 使用 `OH_NativeWindow_NativeWindowHandleOpt` 设置 `window` 的 `USAGE`、宽高等信息。
2. 调用 `OH_NativeWindow_NativeWindowRequestBuffer` 获取 `window` 的 Buffer。
3. 使用 `OH_NativeWindow_GetBufferHandleFromNative` 获取 `bufferHandle`。
4. 使用 `OH_NativeWindow_NativeWindowFlushBuffer` 将生产好的 Buffer 放到 Buffer 队列中供消费。

---

## 实现方式二：通过 `setExternalNativeImage`

直接将用于内容生产的 `NativeImage` 指针传递给 Flutter 引擎层，由引擎层利用该 `NativeImage` 通过 `OH_NativeImage_SetOnFrameAvailableListener` 注册帧可用回调进行内容消费。

### ArkTS 侧实现步骤

1. 注册纹理时获取相关信息：

```ts
    this.textureId = this.textureRegistry!.getTextureId();
    this.surfaceTextureEntry = this.textureRegistry!.registerTexture(this.textureId);
    drawNapi.drawPatternWindow(1000, 1000);
    this.nativeImageId = drawNapi.getNativeImage();// 获取用于内容生产的NativeImage
    this.textureRegistry!.setExternalNativeImage(this.textureId, this.nativeImageId);// 将NativeImage传入引擎层
```

### CPP 侧实现步骤

以下为基于 OpenGL 的简单绘制实现步骤：

1. 使用 `OH_NativeImage_Create` 创建 `NativeImage`。
2. 使用 `OH_NativeImage_AcquireNativeWindow` 获取 `NativeImage` 关联的 `window`。
3. 使用 `OH_NativeWindow_NativeWindowHandleOpt` 设置 `USAGE` 和宽高。
4. 将 `NativeWindow` 转换为 `EGLNativeWindowType` 类型。
5. 调用以下 OpenGL 指令完成绘制：
   - `eglCreateWindowSurface`
   - `eglCreateContext`
   - `eglMakeCurrent`
   - `gl` 绘制指令
   - `eglSwapBuffers`

---

## 纹理注销

无论使用上述哪种方式，都需要调用以下函数进行纹理注销：

```ts
this.textureRegistry!.unregisterTexture(textureId);
```

---

## 参考实现

[flutter_it_image](../../../ohos/flutter_it_image)

## 代码位置说明

1. **Dart 侧代码**  
    方式一: 代码位于 `lib/PicturePage1.dart`，最下方添加的纹理组件用于自渲染内容导入。  
    方式二: 代码位于 `lib/PicturePage2.dart`。

2. **ArkTS 侧代码**  
    方式一: 代码位于 `ohos/entry/src/main/ets/entryability/PicturePlugin1.ets`，包含了纹理的注册和注销函数。  
    方式二: 代码位于 `ohos/entry/src/main/ets/entryability/PicturePlugin2.ets`。

3. **原生绘制代码**  
    代码位于 `ohos/entry/src/main/cpp`。

---

## 注意事项

1. 开发者在使用方式二时，需要自行管理 `NativeImage` 的生命周期，并确保在 `unregister` 前对象不会销毁。