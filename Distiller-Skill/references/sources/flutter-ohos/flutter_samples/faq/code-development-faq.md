# ohos 代码开发问题

<a id="section129795"></a>

## dart 代码中判断当前平台是否是 ohos

**现象：**

需要在 Dart 代码中判断当前运行平台是否为 ohos。

**原因：**

跨平台代码常需按平台分支处理，ohos 平台需独立判断。

**解决方案：**

```dart
import 'package:flutter/foundation.dart';

bool isOhos() {
  return defaultTargetPlatform == TargetPlatform.ohos;
}
```

---

<a id="section231343"></a>

## 代码中存在 Platform.isOhos 会导致 flutter run、flutter build har、flutter attach 失败

**现象：**

如果 flutter 代码中存在 `Platform.isOhos`，例如：

```dart
if (Platform.isAndroid || Platform.isOhos) {
  print("test");
}
```

会导致 `flutter run`、`flutter build har`、`flutter attach`（不指定本地引擎产物，依赖服务器的引擎产物）失败。

报错信息：

![](../media/faq/code1.png)

<p align="center"><strong>图1</strong> Platform.isOhos 构建报错信息</p>

**原因：**

`dart:io` 的 `Platform.isOhos` 在编译期会触发平台判断逻辑，导致依赖服务器引擎产物时构建失败。

**解决方案：**

请将 `Platform.isOhos` 修改成 `defaultTargetPlatform == TargetPlatform.ohos`。

---

<a id="section556814"></a>

## Flutter OpenHarmony 原生端获取到图片资源

**现象：**

在使用 plugin 时，OpenHarmony 会返回 `binding: FlutterPluginBinding` 类型的对象，使用 `binding.getFlutterAssets().getAssetFilePathByName('xxxx')` 获取 flutter 代码库中的图片资源时，OpenHarmony 原生端无法获取到图片资源（OpenHarmony 端直接用 `Image(this.img)` 方法加载）。

**原因：**

`binding.getFlutterAssets().getAssetFilePathByName('xxxx')` 得到的是资源路径，不能直接用于原生 `Image` 组件加载，需通过 `resourceManager` 读取原始资源数据后创建图片源。

**解决方案：**

加载原生图片资源可以参考以下实现：

![](../media/faq/code2.png)

<p align="center"><strong>图2</strong> 原生端获取 Flutter 图片资源实现</p>

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

> **说明：** `let rawfile = await rmg.getRawFileContent("flutter_assets/" + this.image)` 这行代码为耗时操作，debug 时会暂不执行当前方法的剩余代码直到耗时操作返回结果，而进入 `build` 只是正常渲染流程。

---

<a id="section665522"></a>

## flutter inappwebview 设置高度后网页内容被拉伸

**现象：**

使用 `flutter inappwebview` 设置高度后，网页内容被拉伸。

**原因：**

目前 OS 原生 web 画布限制范围是在 2400 以下，超过 2400 的高度原生 web 无法加载。

**解决方案：**

将 px 类型的参数转换为 dp 类型：

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

## Flutter 项目如何适配折叠屏

**现象：**

Flutter 项目需要适配折叠屏设备。

**原因：**

折叠屏设备在折叠态、展开态、悬停态下尺寸与比例变化明显，需进行响应式布局适配。

**解决方案：**

- 手机和折叠屏折叠态，应用需要适配竖屏布局。仅部分特殊场景例如横屏游戏、长视频需要适配横屏布局。当设备尺寸比例接近 1:1 时，建议横竖屏使用相同或相近的布局；当设备尺寸比例差异大时，横竖屏可以使用不同的布局，从而提供更好的使用体验。
- 对于挖孔区的适配，需要考虑核心内容或重要交互不要被挖孔区遮挡。如果被遮挡，则应进行局部内容等避让；可滚动内容无需专门避让挖孔区。要避免因为避让挖孔导致左右侧留白不一致。
- 在多端设备上，长视频、直播、会议、通话等场景下支持画中画功能。卡片广告在宽屏设备上建议使用延伸布局和形变进行响应式适配。
- 针对折叠屏悬停态（即用户可以将产品半折后立在桌面上），中间弯折区域难以操作且显示内容会变形，因此建议页面内容进行折痕区避让适配。建议上半屏内容由中线向上避让 16vp（3 毫米）、下半屏内容由中线向下避让 40vp（7 毫米）。这些是折叠屏设计的主要方案概述。

可参考：

- [多设备响应式设计](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-responsive-layout#section1914110349546)
- [折叠屏 UX 体验](https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-foldable-screen-0000001807866557)
- [判断折叠状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-display-V5#foldstatus10)
- [一多开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/foreword-V5)
- [通过 windowSizeChange 来监听高度](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-window-V5#onwindowsizechange7)
- [折叠屏悬停态](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-folded-hover)
- [FolderStack](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-folderstack-V5)

---

<a id="section683154"></a>

## Flutter 项目启动闪退

**现象：**

Flutter 项目启动后闪退。

**原因：**

请开发者在 crash 的栈顶日志中查看是否有以下信息，如有，可能是因为编译 hap 文件模式与编译出来的 engine 模式不匹配，如：编译 hap 文件 release 包，但用的是 debug 模式的 engine 引起。

crash 信息：

```log
Reason:Signal:SIGABRT(SI_TKILL).............................
........................................................
#01 pc 000000000014710c /system/lib/ld-musl-aarch64.so.1(abort+20).............
........................................................
........................................................
........................................................
```

**解决方案：**

确保编译 hap 文件的模式与使用的 engine 模式一致（release 包使用 release engine，debug 包使用 debug engine）。

---

<a id="section945038"></a>

## 设置启动页后加载 Flutter 页面出现闪动

**现象：**

开发者在设置启动页后，加载 Flutter 页面时出现闪动效果，希望避免这种情况。

**原因：**

闪屏页背景图片采用异步加载，应用启动时图片尚未就绪，导致启动页到 Flutter 页面切换时出现闪动。

**解决方案：**

在 `ohos/entry/src/main/ets/pages/Index.ets` 文件的 `componentBuilder` 中，为每个 `Image` 组件添加 `.syncLoad(true)`，使图片同步加载，避免闪动。

```ts
@Entry
@Component
struct Index {
  // ...

  @Builder
  componentBuilder() {
    // 启动页中的每个 Image 均添加 syncLoad(true)
    Image($r('app.media.start_icon'))
      .syncLoad(true)
      .width('100%')
      .height('100%')
  }

  // ...
}
```

> **注意：** `.syncLoad(true)` 会在 UI 主线程同步解码图片，阻塞渲染直至解码完成。适用于启动页等少量、小尺寸图片场景。若启动图较大或图片数量较多，可能导致启动明显卡顿甚至 ANR。此时建议优先压缩图片资源，或将图片放在 `rawfile` 目录并提前预加载，也可考虑使用 `PixelMap` 预解码后再展示。确保引用的图片资源确实存在且路径正确：`syncLoad(true)` 同步加载时，若资源不存在将直接导致应用崩溃，不会像异步加载那样仅显示空白。

可参考：[Image 组件 syncLoad 属性说明](https://developer.huawei.com/consumer/cn/doc/architecture-guides/tools-v1_2-ts_c13-0000002390874093)

---

<a id="section271564"></a>

## 插件工程的 ohos 目录无法在 DevEco 中同步

**现象：**

在 DevEco Studio 中直接打开 Flutter 插件工程的 `ohos` 目录，无法正常同步（Sync）项目。

**原因：**

这是 DevEco Studio 的设计行为。Flutter 插件的 `ohos` 目录是 OpenHarmony **module** 结构，而非独立的 OpenHarmony **project** 工程，因此无法作为独立工程在 DevEco 中打开和同步。

**解决方案：**

1. **在 example 工程中开发调试**：使用 DevEco Studio 打开插件的 `example/ohos` 目录，在该工程中开发和调试 ohos 平台代码。详见 [开发Flutter Plugin](../plugin-and-package/developing-plugin.md)。

2. **以源码方式引用插件**：在宿主 Flutter 工程中通过 hvigor 插件方式直接依赖插件源码构建，这样编写插件时可直接修改源码并获得代码提示，体验与 Android、iOS 一致。详见 [使用 hvigor 插件方式编译 flutter 项目](../app-development/hvigor-plugin-build.md)。

> 注意：对于既有的 flutter plugin 项目，如果不做任何修改仅会导致 example 无法正常编译，但不影响该 plugin 在 flutter 项目中的正常使用和编译。

---

<a id="section836729"></a>

## 5.0 系统无法显示视频缩略图

**现象：**

flutter 代码中涉及到视频缩略图的场景，例如使用 `video_thumbnail` 插件实现视频缩略图功能，会导致无法显示缩略图。

**原因：**

网络视频必须 `api >= 20` 才可以显示缩略图，5.0 系统不满足该规格。

**解决方案：**

系统规格，需要将 5.0 系统升级到 6.0 及以上系统即可。
