# How to Import Self-Rendered Content into Flutter

## Background

External self-rendered content (whether drawn via OHOS CAPI such as `NativeDrawing`, or drawn via OpenGL interfaces) can be imported into Flutter's `Texture` widget for display by way of external textures.

## Prerequisites

- [Flutter OH Development Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md) has been completed.
- Flutter OH version 3.22 or later is required.

---

## Implementation Steps

### Step 1: Dart-Side Operations

#### Create the Texture Widget

- Create a Texture widget and bind the textureId.

#### Register the Texture

- Create a `MethodChannel`:

  ```dart
  final MethodChannel _channel = const MethodChannel('PictureChannel1');
  ```

- Register the texture in the `initState` function:

  ```dart
  _textureId = await _channel.invokeMethod("registerStarTexture");
  ```

#### Unregister the Texture

- Unregister the texture in the `dispose` function:

  ```dart
  _channel.invokeMethod('unregisterTexture', {'textureId': _textureId});
  ```

---

### Step 2: OHOS-Side Operations

#### Import the Utility Classes

The following utility classes need to be imported:

```ts
import { TextureRegistry, SurfaceTextureEntry } from '@ohos/flutter_ohos/src/main/ets/view/TextureRegistry';
```

#### Provided Implementation Methods

This document provides two implementation methods for importing self-rendered content into Flutter textures.

---

## Implementation Method 1: Draw to a Buffer via `getNativeWindowId`

Use `getNativeWindowId` to obtain the `OHNativeWindow` pointer corresponding to the engine-level `Texture`, and then draw the self-rendered content onto the buffer associated with that `window`.

### ArkTS-Side Implementation Steps

1. Obtain the relevant information when registering the texture:

```ts
    this.textureId = this.textureRegistry!.getTextureId();
    this.surfaceTextureEntry = this.textureRegistry!.registerTexture(this.textureId);
    this.windowId = this.surfaceTextureEntry.getNativeWindowId();
    drawNapi.drawPatternWindow(this.windowId, 300, 300);// The draw function needs to be implemented in the cpp layer; it receives the window pointer
```

2. The `drawPatternWindow` in the above `drawNapi.drawPatternWindow(this.windowId, 300, 300)` must be implemented in the cpp layer; it receives the `window` pointer and draws the self-rendered content onto the buffer associated with that `window`.

### CPP-Side Implementation Steps

1. Use `OH_NativeWindow_NativeWindowHandleOpt` to set the `window`'s `USAGE`, width, height, and other information.
2. Call `OH_NativeWindow_NativeWindowRequestBuffer` to obtain the `window`'s buffer.
3. Use `OH_NativeWindow_GetBufferHandleFromNative` to obtain the `bufferHandle`.
4. Use `OH_NativeWindow_NativeWindowFlushBuffer` to put the produced buffer into the buffer queue for consumption.

---

## Implementation Method 2: Via `setExternalNativeImage`

Directly pass the `NativeImage` pointer used for content production to the Flutter engine layer. The engine layer then uses that `NativeImage` to register a frame-available callback via `OH_NativeImage_SetOnFrameAvailableListener` and consume the content.

### ArkTS-Side Implementation Steps

1. Obtain the relevant information when registering the texture:

```ts
    this.textureId = this.textureRegistry!.getTextureId();
    this.surfaceTextureEntry = this.textureRegistry!.registerTexture(this.textureId);
    drawNapi.drawPatternWindow(1000, 1000);
    this.nativeImageId = drawNapi.getNativeImage();// Obtain the NativeImage used for content production
    this.textureRegistry!.setExternalNativeImage(this.textureId, this.nativeImageId);// Pass the NativeImage to the engine layer
```

### CPP-Side Implementation Steps

The following are the steps for a simple drawing implementation based on OpenGL:

1. Use `OH_NativeImage_Create` to create a `NativeImage`.
2. Use `OH_NativeImage_AcquireNativeWindow` to obtain the `window` associated with the `NativeImage`.
3. Use `OH_NativeWindow_NativeWindowHandleOpt` to set the `USAGE`, width, and height.
4. Convert the `NativeWindow` to the `EGLNativeWindowType` type.
5. Call the following OpenGL commands to complete the drawing:
   - `eglCreateWindowSurface`
   - `eglCreateContext`
   - `eglMakeCurrent`
   - `gl` drawing commands
   - `eglSwapBuffers`

---

## Texture Unregistration

Whichever of the above methods is used, the following function must be called to unregister the texture:

```ts
this.textureRegistry!.unregisterTexture(textureId);
```

---

## Reference Implementation

[flutter_it_image](../../../ohos/flutter_it_image)

## Code Location Description

1. **Dart-side code**  
    Method 1: The code is located in `lib/PicturePage1.dart`; the texture widget added at the bottom is used to import self-rendered content.  
    Method 2: The code is located in `lib/PicturePage2.dart`.

2. **ArkTS-side code**  
    Method 1: The code is located in `ohos/entry/src/main/ets/entryability/PicturePlugin1.ets`, which contains the texture registration and unregistration functions.  
    Method 2: The code is located in `ohos/entry/src/main/ets/entryability/PicturePlugin2.ets`.

3. **Native drawing code**  
    The code is located in `ohos/entry/src/main/cpp`.

---

## Notes

1. When using Method 2, developers need to manage the lifecycle of the `NativeImage` on their own and make sure the object is not destroyed before `unregister`.
