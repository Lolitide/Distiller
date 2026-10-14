# 渲染引擎与 UI 问题

[渲染引擎切换指导](../rendering-engine/rendering-engine-switching.md)

[PlatformView 同层渲染方案适配切换指导](../hybrid-development/platform-view-same-layer-rendering.md)

<a id="section653333"></a>

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

<a id="section731902"></a>

## Tab 组件（TabBar/TabBarView）使用注意事项（手势冲突）

**现象：**

`TabBar` + `TabBarView` 是 Flutter 中常用的选项卡切换组件。`TabBarView` 内部使用 `PageView` 实现页面切换，当它与其它水平滚动手势或系统返回手势处于同一手势竞技场（GestureArena）时，由于手势方向相同，竞技场难以区分胜出者，容易产生手势冲突。以下列举几个常见场景及规避方案。

**原因：**

横向手势方向相同导致手势竞技场无法稳定区分胜出者，外层 `TabBarView` 与内层或系统手势相互争抢。

**解决方案：**

按场景选择规避方案，详见下方三个子场景。

### 1. TabBarView 内嵌横向滚动组件（WebView/PageView/ListView/CarouselView）

**现象：**

将 `WebView`、`PageView`、横向 `ListView` 或 `CarouselView` 等横向滚动组件直接放在 `TabBarView` 的子页面中时，内层组件无法正常横向滑动，手势被外层 `TabBarView` 抢占，或两者滑动相互干扰。

**原因：**

`TabBarView` 与内层横向滚动组件都会向手势竞技场（GestureArena）注册 `HorizontalDragGestureRecognizer`，由于两者手势方向相同，竞技场无法仅凭方向区分胜出者，导致外层 `TabBarView` 总是赢得手势，内层组件收不到拖拽事件。这是 Flutter 框架本身的已知问题，参见 [flutter/flutter#84238](https://github.com/flutter/flutter/issues/84238)。

**解决方案：**

- 当内层组件自身不需要横向切换 Tab 时，给 `TabBarView` 设置 `NeverScrollableScrollPhysics()`，让手势交由内层组件处理，仅通过点击 `TabBar` 切换：

```dart
TabBarView(
  physics: const NeverScrollableScrollPhysics(),
  controller: _tabController,
  children: [
    // WebView / PageView / 横向 ListView 等
  ],
)
```

- 若希望外层与内层都能滑动，可使用 `PageView` 的 `PageScrollPhysics` 配合内层 `ScrollController` 判断是否到达边界，再决定将手势让给外层；也可借助 `Listener`/`RawGestureDetector` 自定义手势识别器按边界条件分发手势。

### 2. TabBarView 滑动切换与系统侧滑返回手势冲突

**现象：**

在 `TabBarView` 中左右滑动切换页面时，从屏幕边缘起滑会触发系统的侧滑返回手势，导致页面被意外返回；或在 `TabBarView` 区域内滑动时角度稍有倾斜就被系统判定为返回手势。

**原因：**

`TabBarView` 的横向拖拽手势与系统侧滑返回手势方向一致（均为横向），当手指起滑点靠近屏幕边缘时，系统返回手势优先级较高，会与 `TabBarView` 的滑动切换产生竞争。例如在 Flutter Web 端表现为水平滑动角度不"完美水平"即触发浏览器返回，参见 [flutter/flutter#152588](https://github.com/flutter/flutter/issues/152588)。

**解决方案：**

- 优先使用点击 `TabBar` 切换页面，避免依赖 `TabBarView` 的边缘横向滑动；如确需滑动切换，可给 `TabBarView` 设置 `NeverScrollableScrollPhysics()` 关闭横向滑动，仅保留点击切换。
- 若需同时保留滑动切换，可在页面非边缘区域引导用户操作；或在 `TabBarView` 外层通过 `Listener` 监听起滑点 `position.dx`，对靠近边缘的横向手势做拦截处理。

### 3. TabBarView 与 PageView 嵌套

**现象：**

`TabBarView` 嵌套在 `PageView` 中（或 `PageView` 嵌套在 `TabBarView` 中）时，两层横向翻页手势相互争抢，难以流畅地分别翻动外层和内层。

**原因：**

`TabBarView` 本质是受限的 `PageView`，两层 `PageView` 同为横向手势，竞技场无法稳定区分，导致手势在两层之间抖动或只响应其中一层。

**解决方案：**

- 通常只保留一层横向翻页：外层用 `TabBarView` 时，内层 `PageView` 设置 `NeverScrollableScrollPhysics()`，反之亦然。
- 若必须双层都滑动，可使用自定义 `ScrollPhysics` 或监听内层 `ScrollController` 的边界，在内层到达边界时将手势让给外层，类似实现可参考社区中 `nested_page_view` 等方案。

> **小结：** 上述手势冲突多源于横向手势方向相同导致竞技场无法区分。建议优先采用点击 `TabBar` 切换 + 内层组件单独处理横向滚动的组合，必要时通过 `physics` 或自定义手势识别器明确手势归属，以获得稳定的手势体验。

---

<a id="section571264"></a>

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

<a id="section597629"></a>

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

<a id="section204618"></a>

## 鸿蒙端使用 flutter_svg 渲染 SVG 时出现锯齿

**现象：**

鸿蒙端使用 Impeller 渲染 SVG 时，图形的圆弧或斜线边缘可能出现锯齿；使用 `flutter_svg` 的 `colorFilter` 属性修改 SVG 颜色时，该现象可能更加明显。

**原因：**

鸿蒙端当前全局开启 2x MSAA（多重采样抗锯齿），所有使用 MSAA 的渲染内容都会采用 2 倍采样。相较于 4x MSAA，2x MSAA 的采样数更少，因此部分 SVG 的圆弧或斜线边缘可能不够平滑。若全局开启 4x MSAA，会增加 GPU 的采样和渲染负载，在部分机型上可能导致性能下降、画面卡顿、功耗升高或设备发热，因此鸿蒙端采用 2x MSAA，以平衡显示效果、性能和功耗。

**解决方案：**

推荐使用 `RenderingStrategy.raster`，以目标显示尺寸的 2 倍宽高栅格化 SVG，再通过外层组件将图片缩放到目标尺寸。例如：

```dart
Widget buildSvg(String assetName, double size) {
  return SizedBox(
    width: size,
    height: size,
    child: FittedBox(
      fit: BoxFit.contain,
      child: SvgPicture.asset(
        assetName,
        width: size * 2,
        height: size * 2,
        renderingStrategy: RenderingStrategy.raster,
      ),
    ),
  );
}
```

该方案可以增加边缘像素的取色层级，减小平均取色偏差，从而减弱锯齿。由于会生成分辨率更高的栅格图，可能增加内存占用和栅格化开销，建议仅对存在明显锯齿的 SVG 使用，并结合实际机型验证性能。

也可以根据业务场景采用以下方案：

- [切换使用 Skia](../rendering-engine/rendering-engine-switching.md)。
- 在 SVG 文件中预先设置颜色，避免通过 `flutter_svg` 的 `colorFilter` 属性修改颜色。SVG 描边说明可参考 [SVG Stroke 属性](https://www.w3schools.com/graphics/svg_stroking.asp)。

---

<a id="section480764"></a>

## 物理键盘 Numlock、Capslock、ScrollLock 暂不支持

**现象：**

物理键盘的 Numlock、Capslock、ScrollLock 按键在当前版本暂不支持。

**原因：**

当前版本未适配上述物理键盘状态键。

**解决方案：**

等待后续版本支持，或避免依赖上述按键状态进行业务判断。
