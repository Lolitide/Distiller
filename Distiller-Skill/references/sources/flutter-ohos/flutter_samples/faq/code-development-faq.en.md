# ohos Code Development Issues

<a id="section129795"></a>

## Determining Whether the Current Platform is ohos in Dart Code

**Symptom:**

You need to determine in Dart code whether the current platform is ohos.

**Cause:**

Cross-platform code often needs to branch by platform, and the ohos platform needs separate detection.

**Solution:**

```dart
import 'package:flutter/foundation.dart';

bool isOhos() {
  return defaultTargetPlatform == TargetPlatform.ohos;
}
```

---

<a id="section231343"></a>

## Platform.isOhos in the Code Causes flutter run, flutter build har, and flutter attach to Fail

**Symptom:**

If `Platform.isOhos` exists in the Flutter code, for example:

```dart
if (Platform.isAndroid || Platform.isOhos) {
  print("test");
}
```

it causes `flutter run`, `flutter build har`, and `flutter attach` to fail (when no local engine artifacts are specified and the engine artifacts on the server are used).

Error message:

![](../media/faq/code1.png)

<p align="center"><strong>Figure 1</strong> Platform.isOhos build error message</p>

**Cause:**

`Platform.isOhos` of `dart:io` triggers the platform detection logic at compile time, causing the build to fail when it relies on the engine artifacts on the server.

**Solution:**

Change `Platform.isOhos` to `defaultTargetPlatform == TargetPlatform.ohos`.

---

<a id="section556814"></a>

## Obtaining Image Resources on the OpenHarmony Native Side of Flutter OpenHarmony

**Symptom:**

When using a plugin, OpenHarmony returns an object of the `binding: FlutterPluginBinding` type. When `binding.getFlutterAssets().getAssetFilePathByName('xxxx')` is used to obtain the image resources in the Flutter codebase, the OpenHarmony native side cannot obtain the image resources (the OpenHarmony side loads them directly with the `Image(this.img)` method).

**Cause:**

`binding.getFlutterAssets().getAssetFilePathByName('xxxx')` returns a resource path, which cannot be used directly for loading by the native `Image` component. The raw resource data must be read through `resourceManager` to create an image source.

**Solution:**

To load native image resources, refer to the following implementation:

![](../media/faq/code2_en.png)

<p align="center"><strong>Figure 2</strong> Implementation of obtaining Flutter image resources on the native side</p>

```ts
import { image } from '@kit.ImageKit';
@Component
export struct DemoComponent {
  @ObjectLink params: Params
  viewManager: DemoView = this.params.platformView as DemoView
  image?: string
  @State imageSource:image.ImageSource|null=null

  async aboutToAppear() {
    let args: HashMap<string, object | string> = this.viewManager.args as HashMap<string, object>
    this.image = args.get('src') as string
    let rmg = DemoPluginAssetPlugin.binding.getApplicationContext().resourceManager;
    let rawfile = await rmg.getRawFileContent("flutter_assets/${this.image}");
    let buffer = rawfile.buffer.slice(0);
    this.imageSource = image.createImageSource(buffer);
  }

  build() {
    Column(){
      if(this.imageSource){
        Image(this.imageSource.createPixelMapSync())
      }
    }
  }
}
```

> **Note:** The line `let rawfile = await rmg.getRawFileContent("flutter_assets/" + this.image)` is a time-consuming operation. During debugging, the remaining code of the current method is not executed until the time-consuming operation returns a result, while entering `build` is just the normal rendering process.

---

<a id="section665522"></a>

## Web Content Stretched After Setting the Height in flutter inappwebview

**Symptom:**

After the height is set with `flutter inappwebview`, the web content is stretched.

**Cause:**

Currently, the OS native web canvas limit is below 2400, and native web cannot load at heights above 2400.

**Solution:**

Convert px-type parameters to the dp type:

```dart
class _MyHomePageState extends State<MyHomePage> {
  double _height = 10.0;

  void _changeHeight(double newHeight) {
    setState(() {
      double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      _height = newHeight / devicePixelRatio;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

---

<a id="section472901"></a>

## How to Adapt a Flutter Project to Foldable Screens

**Symptom:**

The Flutter project needs to adapt to foldable devices.

**Cause:**

Foldable devices change size and aspect ratio significantly across the folded, unfolded, and hovering states, so responsive layout adaptation is required.

**Solution:**

- For phones and foldables in the folded state, apps need to adapt to the portrait layout. Only some special scenarios, such as landscape games and long videos, require adaptation to the landscape layout. When the device aspect ratio is close to 1:1, it is recommended to use the same or a similar layout for both orientations; when the device aspect ratio differs greatly, different layouts can be used for landscape and portrait to provide a better experience.
- For adaptation to the punch-hole area, make sure that core content or important interactions are not obscured by the punch-hole area. If they are obscured, apply avoidance such as adjusting the local content; scrollable content does not need dedicated avoidance of the punch-hole area. Avoid inconsistent left and right margins caused by avoiding the punch hole.
- On multiple devices, support picture-in-picture in scenarios such as long videos, live streaming, meetings, and calls. For card ads on wide-screen devices, extended layouts and deformation are recommended for responsive adaptation.
- For the foldable hovering state (where the user can half-fold the device and stand it on the desk), the middle bending area is difficult to operate and its displayed content is deformed, so it is recommended that the page content apply avoidance adaptation for the crease area. It is recommended that the upper-half screen content avoid 16 vp (3 mm) upward from the center line and the lower-half screen content avoid 40 vp (7 mm) downward from the center line. These are the main approaches in foldable screen design.

References:

- [Multi-Device Responsive Design](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-responsive-layout#section1914110349546)
- [Foldable Screen UX Experience](https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-foldable-screen-0000001807866557)
- [Determining the Fold State](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-display-V5#foldstatus10)
- [One-Time Development for Multiple Devices](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/foreword-V5)
- [Listening for Height Changes Through windowSizeChange](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-window-V5#onwindowsizechange7)
- [Foldable Hovering State](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-folded-hover)
- [FolderStack](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-folderstack-V5)

---

<a id="section683154"></a>

## Sudden Exit on Flutter Project Startup

**Symptom:**

The Flutter project suddenly exits after startup.

**Cause:**

Check the top frames of the crash log for the following information. If it is present, the cause may be a mismatch between the mode used to build the hap file and the mode of the built engine — for example, building a release hap package while using the debug engine.

Crash information:

```log
Reason:Signal:SIGABRT(SI_TKILL).............................
........................................................
#01 pc 000000000014710c /system/lib/ld-musl-aarch64.so.1(abort+20).............
........................................................
........................................................
........................................................
```

**Solution:**

Ensure that the mode used to build the hap file matches the engine mode in use (a release package uses the release engine, and a debug package uses the debug engine).

---

<a id="section945038"></a>

## Flicker When Loading the Flutter Page After the Splash Screen Is Set

**Symptom:**

After setting the splash screen, developers see a flicker when the Flutter page loads and want to avoid it.

**Cause:**

The splash screen background image is loaded asynchronously. When the app starts, the image is not ready yet, causing a flicker during the switch from the splash screen to the Flutter page.

**Solution:**

In the `componentBuilder` of the `ohos/entry/src/main/ets/pages/Index.ets` file, add `.syncLoad(true)` to each `Image` component so that images are loaded synchronously to avoid the flicker.

```ts
@Entry
@Component
struct Index {
  // ...

  @Builder
  componentBuilder() {
    // Add syncLoad(true) to each Image in the splash screen
    Image($r('app.media.start_icon'))
      .syncLoad(true)
      .width('100%')
      .height('100%')
  }

  // ...
}
```

> **Caution:** `.syncLoad(true)` decodes images synchronously on the UI main thread and blocks rendering until decoding is complete. It is suitable for scenarios with a few small images, such as the splash screen. If the splash image is large or there are many images, noticeable startup jank or even ANR may occur. In that case, prefer compressing the image resources first, placing the images in the `rawfile` directory and preloading them in advance, or pre-decoding with `PixelMap` before displaying. Make sure the referenced image resources actually exist and the paths are correct: with `syncLoad(true)`, a missing resource causes the app to crash directly instead of only showing a blank as with asynchronous loading.

Reference: [Image Component syncLoad Property](https://developer.huawei.com/consumer/cn/doc/architecture-guides/tools-v1_2-ts_c13-0000002390874093)

---

<a id="section271564"></a>

## The ohos Directory of a Plugin Project Cannot Sync in DevEco

**Symptom:**

Opening the `ohos` directory of a Flutter plugin project directly in DevEco Studio fails to sync the project.

**Cause:**

This is by design in DevEco Studio. The `ohos` directory of a Flutter plugin is an OpenHarmony **module** structure rather than a standalone OpenHarmony **project**, so it cannot be opened and synced in DevEco as an independent project.

**Solution:**

1. **Develop and debug in the example project**: Use DevEco Studio to open the plugin's `example/ohos` directory, and develop and debug the ohos platform code in that project. For details, see [Developing a Flutter Plugin](../plugin-and-package/developing-plugin.en.md).

2. **Reference the plugin as source code**: In the host Flutter project, depend directly on the plugin source code for building via the hvigor plugin approach. This way, you can modify the source code directly while writing the plugin and get code hints, an experience consistent with Android and iOS. For details, see [Building a Flutter Project with the hvigor Plugin](../app-development/hvigor-plugin-build.en.md).

> Note: For an existing flutter plugin project, leaving it unchanged only prevents the example from compiling normally; it does not affect the normal use and compilation of the plugin in flutter projects.

---

<a id="section836729"></a>

## Video Thumbnails Cannot Be Displayed on the 5.0 System

**Symptom:**

In Flutter code scenarios involving video thumbnails, for example, implementing the video thumbnail feature with the `video_thumbnail` plugin, the thumbnails cannot be displayed.

**Cause:**

Network videos require `api >= 20` to display thumbnails, and the 5.0 system does not meet this specification.

**Solution:**

This is a system specification: upgrade the 5.0 system to 6.0 or later.
