# Rendering Engine and UI Issues

[Rendering Engine Switching Guide](../rendering-engine/rendering-engine-switching.en.md)

[Platform View Same-Layer Rendering Adaptation and Switching](../hybrid-development/platform-view-same-layer-rendering.en.md)

<a id="section653333"></a>

## Flutter inappwebview: After Setting the Height, the Web Page Content Is Stretched

**Symptom:**

After a height is set using `flutter inappwebview`, the web page content is stretched.

**Cause:**

Currently, the canvas limit of the OS native web is below 2400; native web cannot load a height above 2400.

**Solution:**

Convert parameters of the px type to the dp type:

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

## Notes on Using the Tab Component (TabBar/TabBarView) (Gesture Conflicts)

**Symptom:**

`TabBar` + `TabBarView` are commonly used tab-switching components in Flutter. `TabBarView` internally uses `PageView` to implement page switching. When it is in the same gesture arena (GestureArena) as other horizontal scroll gestures or the system back gesture, the arena can hardly determine the winner because the gestures are in the same direction, which easily leads to gesture conflicts. Several common scenarios and workarounds are listed below.

**Cause:**

The horizontal gestures are in the same direction, so the gesture arena cannot stably determine the winner; the outer `TabBarView` competes with the inner gestures or the system gesture.

**Solution:**

Choose a workaround based on the scenario. See the following three sub-scenarios for details.

### 1. Horizontally Scrollable Components Nested in TabBarView (WebView/PageView/ListView/CarouselView)

**Symptom:**

When horizontally scrollable components such as `WebView`, `PageView`, a horizontal `ListView`, or `CarouselView` are placed directly in a child page of `TabBarView`, the inner component cannot scroll horizontally properly — the gesture is seized by the outer `TabBarView`, or the two scrolls interfere with each other.

**Cause:**

Both `TabBarView` and the inner horizontally scrollable component register a `HorizontalDragGestureRecognizer` with the gesture arena (GestureArena). Because the two gestures are in the same direction, the arena cannot determine the winner by direction alone, so the outer `TabBarView` always wins the gesture and the inner component receives no drag events. This is a known issue of the Flutter framework itself; see [flutter/flutter#84238](https://github.com/flutter/flutter/issues/84238).

**Solution:**

- When the inner component itself does not need to switch tabs horizontally, set `NeverScrollableScrollPhysics()` for `TabBarView` so that the gesture is handled by the inner component, and switch tabs only by tapping `TabBar`:

```dart
TabBarView(
  physics: const NeverScrollableScrollPhysics(),
  controller: _tabController,
  children: [
    // WebView / PageView / horizontal ListView, etc.
  ],
)
```

- If you want both the outer and inner layers to scroll, you can use the `PageScrollPhysics` of `PageView` together with the inner `ScrollController` to determine whether the boundary has been reached, and then decide whether to yield the gesture to the outer layer. You can also use `Listener`/`RawGestureDetector` to build a custom gesture recognizer that dispatches gestures based on boundary conditions.

### 2. Conflict Between TabBarView Swipe Switching and the System Side-Swipe Back Gesture

**Symptom:**

When swiping left or right in `TabBarView` to switch pages, starting the swipe from the screen edge triggers the system side-swipe back gesture, causing the page to be unexpectedly returned; or when swiping within the `TabBarView` area, a slightly tilted swipe angle is judged by the system as a back gesture.

**Cause:**

The horizontal drag gesture of `TabBarView` and the system side-swipe back gesture are in the same direction (both horizontal). When the touch-down point of the finger is near the screen edge, the system back gesture has a higher priority and competes with the swipe switching of `TabBarView`. For example, on the Flutter Web, a horizontal swipe whose angle is not "perfectly horizontal" triggers the browser back; see [flutter/flutter#152588](https://github.com/flutter/flutter/issues/152588).

**Solution:**

- Prefer switching pages by tapping `TabBar` instead of relying on the edge horizontal swipe of `TabBarView`. If swipe switching is really required, you can set `NeverScrollableScrollPhysics()` for `TabBarView` to disable horizontal swiping and keep only tap switching.
- If swipe switching must be retained, guide users to operate in non-edge areas of the page; or wrap the `TabBarView` with a `Listener` to monitor the touch-down point `position.dx` and intercept horizontal gestures near the edge.

### 3. TabBarView Nested in PageView

**Symptom:**

When a `TabBarView` is nested in a `PageView` (or a `PageView` is nested in a `TabBarView`), the two layers of horizontal paging gestures compete with each other, making it difficult to page the outer and inner layers smoothly and separately.

**Cause:**

A `TabBarView` is essentially a constrained `PageView`. Both `PageView` layers use horizontal gestures, and the arena cannot stably distinguish them, causing the gesture to jitter between the two layers or respond to only one of them.

**Solution:**

- Usually only one layer of horizontal paging is retained: when the outer layer is a `TabBarView`, set `NeverScrollableScrollPhysics()` for the inner `PageView`, and vice versa.
- If both layers must scroll, you can use a custom `ScrollPhysics` or listen to the boundary of the inner `ScrollController`, and yield the gesture to the outer layer when the inner layer reaches its boundary. For a similar implementation, refer to community solutions such as `nested_page_view`.

> **Summary:** The preceding gesture conflicts mostly stem from the arena being unable to distinguish gestures in the same horizontal direction. It is recommended to prioritize the combination of switching by tapping `TabBar` plus letting the inner component handle horizontal scrolling on its own; when necessary, clarify gesture ownership through `physics` or a custom gesture recognizer to achieve a stable gesture experience.

---

<a id="section571264"></a>

## How to Adapt a Flutter Project to Foldable Screens

**Symptom:**

A Flutter project needs to adapt to foldable devices.

**Cause:**

Foldable devices change noticeably in size and aspect ratio across the folded, unfolded, and hover states, so responsive layout adaptation is required.

**Solution:**

- For phones and foldables in the folded state, the app needs to adapt to the portrait layout. Only a few special scenarios, such as landscape games and long videos, need to adapt to the landscape layout. When the device aspect ratio is close to 1:1, it is recommended that portrait and landscape use the same or similar layouts; when the device aspect ratio differs greatly, portrait and landscape can use different layouts, providing a better user experience.
- For adaptation to the punch-hole area, make sure that core content or important interactions are not occluded by the punch hole. If occlusion occurs, keep the local content clear of it as appropriate; scrollable content does not need to specifically avoid the punch-hole area. Avoid inconsistent margins on the left and right sides caused by dodging the punch hole.
- On multiple device types, support picture-in-picture in scenarios such as long videos, live streaming, meetings, and calls. For card ads on wide screens, extended layouts and deformation are recommended for responsive adaptation.
- For the foldable hover state (where the user can half-fold the product and stand it on a desk), the middle bend area is difficult to operate and the displayed content is deformed. Therefore, it is recommended that the page content keep clear of the crease area. It is recommended that the content in the upper half of the screen keep 16 vp (3 mm) upward away from the center line, and the content in the lower half keep 40 vp (7 mm) downward from the center line. These are the main guidelines for foldable screen design.

For more information, see:

- [Multi-Device Responsive Design](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-responsive-layout#section1914110349546)
- [Foldable Screen UX](https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-foldable-screen-0000001807866557)
- [Determining the Fold Status](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-display-V5#foldstatus10)
- [One-Develop-Multi-Deploy Development](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/foreword-V5)
- [Listening for Height Changes via windowSizeChange](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-window-V5#onwindowsizechange7)
- [Foldable Hover State](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-folded-hover)
- [FolderStack](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-folderstack-V5)

---

<a id="section597629"></a>

## Splash Screen Flicker When Loading a Flutter Page After the Launch Screen Is Set

**Symptom:**

After setting the launch screen, a developer sees a flicker when loading the Flutter page and wants to avoid it.

**Cause:**

The background image of the splash screen is loaded asynchronously. When the app starts, the image is not ready yet, causing a flicker during the switchover from the launch screen to the Flutter page.

**Solution:**

In the `componentBuilder` of the `ohos/entry/src/main/ets/pages/Index.ets` file, add `.syncLoad(true)` to each `Image` component so that the image is loaded synchronously, avoiding the flicker.

```ts
@Entry
@Component
struct Index {
  // ...

  @Builder
  componentBuilder() {
    // Add syncLoad(true) to every Image in the launch screen
    Image($r('app.media.start_icon'))
      .syncLoad(true)
      .width('100%')
      .height('100%')
  }

  // ...
}
```

> **Note:** `.syncLoad(true)` synchronously decodes the image on the UI main thread, blocking rendering until the decoding is complete. It is suitable for launch screens and other scenarios with a few small images. If the launch image is large or there are many images, the startup may become noticeably janky or even trigger an ANR. In this case, it is recommended to compress the image resources first, or place the images in the `rawfile` directory and preload them in advance; you can also consider pre-decoding them with `PixelMap` before displaying them. Ensure that the referenced image resources actually exist and the paths are correct: when `syncLoad(true)` loads synchronously, a missing resource directly crashes the app; unlike asynchronous loading, it does not merely show a blank area.

For more information, see [Description of the syncLoad Attribute of the Image Component](https://developer.huawei.com/consumer/cn/doc/architecture-guides/tools-v1_2-ts_c13-0000002390874093)

---

<a id="section204618"></a>

## Jagged Edges When Rendering SVG with flutter_svg on HarmonyOS

**Symptom:**

When Impeller renders SVGs on HarmonyOS, jagged edges may appear on arcs or diagonal lines of the graphics; the effect may become more visible when the `colorFilter` property of `flutter_svg` is used to change the SVG color.

**Cause:**

HarmonyOS currently enables 2x MSAA (multi-sample anti-aliasing) globally, and all rendering content that uses MSAA is sampled at 2x. Compared with 4x MSAA, 2x MSAA takes fewer samples, so the arcs or diagonal-line edges of some SVGs may not be smooth enough. Enabling 4x MSAA globally would increase the GPU sampling and rendering load, and on some device models it may degrade performance, cause screen jank, raise power consumption, or heat the device. Therefore, 2x MSAA is adopted on HarmonyOS to balance visual quality, performance, and power consumption.

**Solution:**

It is recommended to use `RenderingStrategy.raster` to rasterize the SVG at twice the width and height of the target display size, and then have the outer widget scale the image to the target size. For example:

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

This approach adds more color-sampling levels for edge pixels and reduces the average color deviation, thereby weakening the jagged edges. Because a higher-resolution raster image is generated, it may increase memory usage and rasterization overhead. It is recommended to apply it only to SVGs with visible jagged edges and verify the performance on actual device models.

You can also adopt the following solutions based on your service scenario:

- [Switch to Skia](../rendering-engine/rendering-engine-switching.en.md).
- Set the colors in the SVG file in advance instead of changing colors through the `colorFilter` property of `flutter_svg`. For a description of SVG strokes, see [SVG Stroke Attribute](https://www.w3schools.com/graphics/svg_stroking.asp).

---

<a id="section480764"></a>

## Physical Keyboard Numlock, Capslock, and ScrollLock Not Supported Yet

**Symptom:**

The Numlock, Capslock, and ScrollLock keys on a physical keyboard are not supported in the current version.

**Cause:**

The current version has not been adapted to the preceding physical keyboard state keys.

**Solution:**

Wait for support in a later version, or avoid relying on the states of these keys in business logic.
