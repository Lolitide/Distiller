# Flutter OHOS External Texture First Frame (Background) Customization

## Overview

In Flutter plugins, the `flutterRenderer.setTextureBackGroundColor` and `flutterRenderer.setTextureBackGroundPixelMap` methods are used to set the background color and texture content of the video player texture. The background color and texture image can be set before the video is loaded or played, ensuring that users see an appropriate background while waiting for the video to render.

> Prerequisite reading: For how the `textureId` is obtained and where `flutterRenderer` (a `TextureRegistry` instance) comes from, see [Introduction to Flutter OHOS External Texture Adaptation](./flutter-external-texture.en.md).

---

## Background and Expectations

### Background and Challenges of the Functional Requirement

Currently, Flutter external textures use a fixed white background for the first frame by default. For video and similar content, however, the default white background does not meet requirements. Specifically, some business scenarios require a white background, while others may require a black background or a background of another color. Therefore, the fixed white background implementation cannot satisfy all business scenarios, especially video-related scenarios.

### Expectations

To support more scenarios, control through the background color of the Texture container should be allowed, or an interface for setting the background color should be provided. This way, developers can dynamically set the texture's background color as needed.

### iOS and Android Benchmark Approach

Currently, iOS and Android default to a black background for the first frame. Considering that a previous change switched the first frame background color from black to white, providing the ability for users to customize the background color is more reasonable. This not only preserves compatibility with older versions but also offers more flexibility for business requirements.

---

## `flutterRenderer` Type

`flutterRenderer` is an instance of the `TextureRegistry` type, obtained through the `FlutterState` class. The `FlutterState` class contains two important members:

- **`binaryMessenger`** (`BinaryMessenger`): Used for message passing with the Flutter engine.
- **`textureRegistry`** (`TextureRegistry`): Used to manage textures and register new textures.

### `FlutterState` Class

```ts
export class FlutterState {
  private binaryMessenger: BinaryMessenger;
  private textureRegistry: TextureRegistry;

  constructor(binaryMessenger: BinaryMessenger, textureRegistry: TextureRegistry) {
    this.binaryMessenger = binaryMessenger;
    this.textureRegistry = textureRegistry;
  }

  getBinaryMessenger(): BinaryMessenger {
    return this.binaryMessenger;
  }

  getTextureRegistry(): TextureRegistry {
    return this.textureRegistry;
  }
}
```

Access `flutterRenderer` through the `FlutterState.getTextureRegistry()` method; it is an instance of `TextureRegistry` and can be used to manage and register video player textures.

---

## Method Signatures

### `flutterRenderer.setTextureBackGroundColor`

```ts
flutterRenderer.setTextureBackGroundColor(textureId: number, color: number)
```

- **`textureId`** (`number`): The ID of the texture, used to identify the texture whose background color is to be set.
- **`color`** (`number`): The background color value, in the 32-bit hexadecimal format `0xAABBGGRR`.

### `flutterRenderer.setTextureBackGroundPixelMap`

```ts
flutterRenderer.setTextureBackGroundPixelMap(textureId: number, pixelMap: image.PixelMap)
```

- **`textureId`** (`number`): The ID of the texture, used to identify the texture whose background image is to be set.
- **`pixelMap`** (`image.PixelMap`): A `PixelMap` object containing image data, used as the background image of the texture.

---

## Main Features

1. **Set Background Color**
   The `setTextureBackGroundColor` method is used to set the background color of the texture. Before the video is loaded, it provides a preset color for the texture, typically used to display a solid color background.

2. **Set Background Image**
   The `setTextureBackGroundPixelMap` method allows setting a frame of video or any image as the background of the texture; typically the first frame image is used to fill the texture when the video file is loaded.

---

## Example Code

### Set the Background Color to Red

```ts
flutterRenderer.setTextureBackGroundColor(textureId, 0xFF0000FF);
```

In this example, the background color is set to red (`0xFF0000FF`), where each byte means:

- `FF` is the Alpha value, indicating fully opaque.
- `00` is the blue component, indicating no blue.
- `00` is the green component, indicating no green.
- `FF` is the red component, indicating maximum red.

### Set the Background Image to the First Frame of the Video

```ts
let avImageGenerator = await media.createAVImageGenerator();
let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
  width: -1,
  height: -1
});
flutterRenderer.setTextureBackGroundPixelMap(textureId, pixelMap);
```

In this code:

1. `AVImageGenerator` is used to obtain the first frame image of the video.
2. The `flutterRenderer.setTextureBackGroundPixelMap` method is used to set this frame image as the background image of the texture.

### Set Both Background Color and Background Image for the Texture

When creating the video player, you can set both the texture's background color and background image at the same time, ensuring an appropriate display effect before the video is loaded.

```ts
flutterRenderer.setTextureBackGroundColor(textureId, 0xFF0000FF);  // Red background
flutterRenderer.setTextureBackGroundPixelMap(textureId, pixelMap);  // First frame image
```

## Common Use Cases

1. **Placeholder Background Before Video Loading**
   When the video player is initialized, fill the texture with a background color or background image so that users do not see a blank interface during video loading.

2. **Display the Loading State**
   While waiting for the video to load and render, a preset background color or image can indicate the loading state, improving the user experience.

3. **Custom Video Background**
   You can customize the player's appearance with a background image or color to enhance the visual effect.

---

## Practical Example

In the third-party library [video_player_ohos](https://gitcode.com/CPF-Flutter/flutter_packages/tree/master/packages/video_player/video_player_ohos), in [`VideoPlayerApiImpl.ets`](https://gitcode.com/CPF-Flutter/flutter_packages/blob/master/packages/video_player/video_player_ohos/ohos/src/main/ets/components/videoplayer/VideoPlayerApiImpl.ets), the `create` method creates an `AVImageGenerator` and an `AVMetadataExtractor` to obtain the video's metadata and image data. If the video resource comes from an asset or a local file, the first frame is set as the background.

```ts
if (asset != null) {
  Log.i(TAG, "asset create called, asset is" + asset);
  let avMetaExtractor = await media.createAVMetadataExtractor();
  avMetaExtractor.fdSrc = await this.getContext().resourceManager.getRawFd("flutter_assets/" + asset);
  let mateData = await avMetaExtractor.fetchMetadata();
  if (mateData.hasVideo == CommonConstants.YES) {
    let avImageGenerator = await media.createAVImageGenerator();
    Log.i(TAG, "asset video create");
    avImageGenerator.fdSrc = await this.getContext().resourceManager.getRawFd("flutter_assets/" + asset);
    let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
      width: -1,
      height: -1
    });
    this.pixelMaps.set(JSON.stringify(arg), pixelMap);
    avImageGenerator.release();
    flutterRenderer.setTextureBackGroundPixelMap(textureId, this.pixelMaps.get(JSON.stringify(arg)));
  }
  avMetaExtractor.release();
} else if (uri != null && uri.startsWith("fd://")) {
  Log.i(TAG, "local create called, file is" + uri);
  let avMetaExtractor = await media.createAVMetadataExtractor();
  avMetaExtractor.fdSrc = {
    fd: Number.parseInt(uri.replace("fd://", ""))
  };
  let mateData = await avMetaExtractor.fetchMetadata();
  if (mateData.hasVideo == CommonConstants.YES) {
    let avImageGenerator = await media.createAVImageGenerator();
    Log.i(TAG, "local video create");
    avImageGenerator.fdSrc = {
      fd: Number.parseInt(uri.replace("fd://", ""))
    };
    let pixelMap = await avImageGenerator.fetchFrameByTime(0, media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC, {
      width: -1,
      height: -1
    });
    this.pixelMaps.set(JSON.stringify(arg), pixelMap);
    avImageGenerator.release();
    flutterRenderer.setTextureBackGroundPixelMap(textureId, this.pixelMaps.get(JSON.stringify(arg)));
  }
  avMetaExtractor.release();
}
flutterRenderer.setTextureBackGroundColor(textureId, 0xFF0000FF); // Set a red background, demonstrating the usage of setTextureBackGroundColor
```

Here, `flutterRenderer.setTextureBackGroundPixelMap(textureId, pixelMap)` sets the first frame image extracted from the video resource as the background of the texture, and `flutterRenderer.setTextureBackGroundColor(textureId, 0xFF0000FF)` sets red as the background color of the texture.

---

## Notes

> **Note**:
>
> - **Texture ID**: Ensure that a valid `textureId` has been assigned to the texture before calling these methods.
> - **Memory management**: After setting an image with `setTextureBackGroundPixelMap`, manage memory properly to avoid memory leaks.
> - **Video resources**: Ensure that the resource paths (e.g., asset paths or local paths) are correct, so that the video file can be loaded and images extracted successfully.

---

## Summary

The `flutterRenderer.setTextureBackGroundColor` and `flutterRenderer.setTextureBackGroundPixelMap` methods are very practical features in Flutter video player plugins. They allow developers to customize the texture's display effect during video loading. By setting a background color or image, developers can improve the user experience and ensure that an appropriate interface is displayed before the video content is rendered.
