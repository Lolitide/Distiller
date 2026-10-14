# Introduction to Page Sliding Jank and Frame Dropping in Flutter

## 1. Overview

When users report a "laggy page", the most common type is **sliding or animation jank**: the motion is not smooth and stutters. In Flutter this usually corresponds to **frame dropping (jank)** — generating a frame takes longer than the frame budget, so the screen can only keep displaying the previous frame.

**60Hz** means the screen refreshes 60 times per second, with an interval of about **16.6ms** between adjacent refreshes; **90Hz** is about **11.1ms**; **120Hz** about **8.3ms**.

## 2. Flutter Rendering Pipeline Overview

Rendering a frame in Flutter roughly goes through four stages:

| Stage | What it does | Thread where the time is mostly spent |
| --- | --- | --- |
| **Build** | Builds/updates the Widget tree and Element tree according to state changes | UI thread (main thread) |
| **Layout** | The RenderObject tree computes the size and position of each node | UI thread |
| **Paint** | Generates drawing commands and builds the Layer tree | UI thread |
| **Composite** | Rasterizes the Layer tree into pixels and outputs them to the screen | Raster thread (render thread / GPU thread) |


The **UI thread** runs the Dart VM, executes your Dart code and the Flutter framework code, and produces the Layer tree; the **Raster thread** receives the Layer tree, calls Skia or Impeller for rasterization and composition, and finally presents the frame to screen.

When analyzing performance, look at the durations of both threads:
- An overly long UI thread duration indicates a performance problem in the Dart layer
- An overly long Raster thread duration means the drawing is too heavy (shadows, blur, large images, saveLayer, etc.).

The subsequent analysis mainly revolves around the UI thread and the Raster thread, so you first need to learn how to confirm their tids from a trace. Look through the thread list in the trace and focus on the following role categories:

| Role | Typical thread names | Description |
|---|---|---|
| `flutter_ui` | `1.ui`, `root.1.ui`, `root.N.ui` | Flutter UI thread, runs Dart code |
| `platform_main` | Application bundle name (e.g., `.my_app`) | Application main thread |
| `flutter_raster` | `1.raster`, `root.1.raster` | Flutter Raster thread, performs rasterization |

> **Flutter 3.35+ thread merging**: Starting from Flutter 3.35, on the OHOS platform the UI thread and the application main thread may be merged into a single thread named after the application bundle name (e.g., `.complex_layout`), classified as `platform_main` rather than `flutter_ui`. In this case, do not identify the UI thread by thread name alone; instead locate it by searching the trace for `flutter::Animator::BeginFrame` — the tid that slice lives on is the UI thread.



## 3. Locating Sliding Frame Drops Based on OHOS Platform Traces

**Rendering chain overview**: The chain below shows the complete process of "finger touches screen → Flutter processing → system composition → presented to screen". Each trace corresponds to one key node in it, making the overall picture quick to grasp.

> **Controllability note**: Most events in the chain are generated automatically by the system or the Flutter framework and cannot be directly changed by application code; only the durations of `Animator::BeginFrame` (the Dart-side BUILD/LAYOUT/PAINT) and `GPURasterizer::Draw` (the Raster thread's drawing load) are indirectly affected by the complexity of application code — these are the main levers for performance optimization.

| trace name | Role | Thread/module | Controllability / notes |
|---|---|---|---|
| `originEventHandle` or absent | Raw input when the system receives a finger touch/sliding event | System multimodal input subsystem `mmi_service` | System event, unchangeable; used only to locate the input start point |
| `DispatchTouchEvent` <br> id:N, pointX=XXX pointY=XXX type=x | The system dispatches the touch event to the application main thread <br> type 0-press, 1-release, 2-move | Application main thread / application bundle name | System event, unchangeable |
| `Shell::OnPlatformViewDispatchPointerDataPacket` | The Flutter Shell layer receives the touch data packet from the platform view | Application main thread / application bundle name | Flutter framework event, unchangeable |
| `Engine::DispatchPointerDataPacket` | The Flutter engine dispatches the touch data packet to the Dart layer for handling | UI thread | Flutter framework event, unchangeable |
| `flutter::VsyncFireCallback` | Receives the vertical sync signal notifying Flutter that it can start rendering the next frame | OS_VSyncThread | System VSync signal, unchangeable |
| `Animator::BeginFrame` | The Flutter animator starts a frame's build, layout, and paint | UI thread | **Optimizable by application code**: reduce rebuild, layout, and paint costs |
| `GPURasterizer::Draw` | Rasterizes the Layer tree produced by the UI thread into pixels | Raster thread | **Optimizable drawing load**: avoid saveLayer, heavy shadows, large images, excessive blur |
| `oh_flutter_1Surface` | Flutter submits the current frame's graphics buffer to the system | Flutter → RenderService | Framework event, unchangeable; used to observe whether buffer production/consumption match |
| `RSMainThread::DoComposition` | RenderService composes multiple windows/layers | render_service | System composition event, unchangeable |
| `RenderFrame` | The GPU performs the actual pixel drawing | GPU | GPU execution, unchangeable |
| `RSHardwareThread::CommitAndReleaseLayers` | Commits the composed layers to the display hardware and releases expired buffers | render_service / display hardware | System/hardware event, unchangeable |

### 3.1 Identifying the Sliding Segment

The premise of analyzing sliding frame drops is first determining "which segment of the trace is the sliding". Traces captured by DevEco Profiler usually span several to tens of seconds and include multiple phases such as app startup, idle, sliding, and stopped. Only after circling the sliding interval does subsequent frame-drop locating become meaningful.

`flutter::APP_LIST_FLING` is a sliding lifecycle marker instrumented proactively by application code. If this slice exists in the trace, it covers the complete process of finger dragging and inertial sliding. Search for `APP_LIST_FLING` in the trace, take its start and end timestamps, and use them directly as the time window for subsequent frame-drop analysis.

![Sliding window](../media/sliding/sliding-3-1-sliding_window.png)

> **Note**: `APP_LIST_FLING` covers the whole process of finger dragging and inertial sliding. In special cases, however, the marker may not fully cover the actual sliding process (e.g., the instrumentation was not triggered before sliding started, or inertia continues after sliding ended); in that case, extend the window using the touch event chain.

### 3.2 Identifying Frame Drop Positions

#### 3.2.1 Locating Frame Drops

Locate frame drops within the sliding window. There are two methods; prefer the first:

**Method 1: Quick locating via `flutter::SceneDisplayLag`**

Flutter provides the `flutter::SceneDisplayLag` trace to mark frame drops in the rendering pipeline. Searching for this trace within the sliding window directly locates the moments where frame drops occur, without comparing frame durations one by one.

![Frame drop marker](../media/sliding/sliding-3-2-1-scene_display_lag.png)


**Method 2: Quick checking via render_service**

render_service provides two trace swimlanes that describe buffer consumption. Favorite the two swimlanes and quickly check the moments where the two swimlanes do not overlap or have gaps.

| Swimlane | Description |
|---|---|
| `oh_flutter_1Surface` | The production buffers Flutter submits and their count. The name usually starts with `oh_flutter_` + a number and ends with `Surface` |
| `render_service` | Consumes the buffers submitted by Flutter |

![Determining frame drops from surfaces](../media/sliding/sliding-3-2-1-surface_render_service.png)

#### 3.2.2 Determining the Bottleneck

There is no baseline for comparing the durations of the UI thread and the Raster thread; judge which thread is the bottleneck from the slow-frame metric distribution:

| Metric pattern | Bottleneck thread | Where to dig next |
|---|---|---|
| `ui` far greater than `raster` | **UI thread** | Check `Animator::BeginFrame` → `begin_frame_` / `draw_frame_` to determine which of BUILD/LAYOUT/PAINT is heaviest |
| `raster` far greater than `ui` | **Raster thread** | Check the `GPURasterizer::Draw` child call stack to determine whether it is shader compilation, image decoding, saveLayer, or fence waiting |
| Both `ui` and `raster` high | **Chain reaction** | Usually an oversized UI-layer rebuild drags down the Raster thread; fix the UI thread first |
| Both `ui`/`raster` low, yet frame drops exist | **UI thread or main thread** | Check `DartIsolate::HandleMessage`, `Animator::AwaitVSync`, fence waits, binder blocking |


After locking onto the slowest frame, confirm whether the two threads' frame numbers `frame_number:` are identical. Narrow the window around its timestamp and examine the slices of the UI thread and the Raster thread within that window separately to find the most time-consuming slice. Based on the durations and call stack information, determine whether the bottleneck is in the UI thread or the Raster thread.

| Marker | trace name | Description |
|---|---|---|
| Start | `flutter::Animator::BeginFrame` | UI thread drawing |
| End | `flutter::GPURasterizer::Draw` | Raster thread rasterization |


![Single-frame drawing](../media/sliding/sliding-3-2-2-flutter_frame.png)


**Main branch 1: UI thread bottleneck**

Within the narrowed window, filter slices by the UI thread tid and focus on slices named `BUILD`, `LAYOUT`, `PAINT`, `Animate`, `BeginFrame`, `PlatformConfiguration`, etc., to determine which stage is heaviest.

| slice name | Description | Root cause it points to |
|---|---|---|
| `BUILD` | Widget tree build stage | Complex list item construction, heavyweight Widgets created in `itemBuilder`, `setState` triggering large-scale rebuilds, animations causing rebuilds every frame |
| `LAYOUT` | RenderObject tree layout stage | Variable-height list items (see [4.1 Root Cause: ListView with Variable Item Heights](#41-root-cause-listview-with-variable-item-heights)), complexly nested Flex/Stack, use of `IntrinsicHeight` / `IntrinsicWidth` and other forced intrinsic size measurement |
| `PAINT` | Generates drawing commands | Complex drawing commands, heavy clipping / complex `CustomPaint`, subtrees not isolated with `RepaintBoundary` causing repaints to spread |
| `Animate` | Animation callback execution | Heavy computation inside animation callbacks, `AnimatedBuilder` not reusing its `child`, `setState` every frame rebuilding large numbers of Widgets |
| `PlatformConfiguration` | Platform configuration/message handling | Blocking synchronous Platform Channel calls, large bursts of platform messages processed together |
| `BeginFrame` | Start of a frame; schedules the BUILD/LAYOUT/PAINT stages | Dart main thread blocked by other messages (e.g., `DartIsolate::HandleMessage`), synchronous time-consuming operations, sync waiting between the main thread and the Raster thread |

![UI bottleneck](../media/sliding/sliding-3-2-2-ui_bottleneck.png)


> **Note on the image**: The screenshot should show the UI thread's call stack expanded within the slow-frame window, with the durations of the BUILD/LAYOUT/PAINT stages annotated. If `--trace-systrace` was not enabled, note that these stages are missing. App developers can use Flutter's built-in DevTools to examine the time costs in detail.


**Main branch 2: Raster thread bottleneck**

Within the narrowed window, filter Flutter/Impeller-related slices by the Raster thread tid and focus on whether the following slices appear and how long they take:

| slice name | Description | Root cause it points to |
|---|---|---|
| `impeller::CreateGlyphAtlas` / `UpdateAtlasBitmap` | Glyph atlas creation and update | Cold glyph atlas startup (first rendering of new glyphs) |
| `Load/Compile Shaders` / `bisheng_graphic_pipeline_compilation` | Shader loading and compilation | Cold shader compilation (first use of a new shader) |
| `SurfaceFrame::Submit` / `Encode` | Frame submission and encoding | Complex scene, too many drawing commands |
| `AcquireNextImageKHR` / `vkQueueSubmit` | GPU image acquisition and command queue submission | GPU resource contention or driver bottleneck |

![Raster bottleneck](../media/sliding/sliding-3-2-2-raster_bottleneck.png)

## 4 Common Root Causes and Fixes

### 4.1 Root Cause: ListView with Variable Item Heights

#### Symptom

Frame drops when fast-sliding a long list, especially obvious on low-end devices. Flutter does not know each item's height; during scrolling, every item that appears must be measured again, `itemBuilder` is called at high frequency, and the measurement cost is amplified.

#### Trace Signals

Within the sliding window, if the UI thread becomes the bottleneck and the following characteristics appear, there is a high suspicion of a variable-height ListView:

| trace characteristic | Description |
|---|---|
| The UI thread's `LAYOUT` stage proportion is clearly higher than `BUILD` / `PAINT` | Every item entering the viewport must be measured; layout time is amplified |
| `RenderSliverList.performLayout` / `childLayout` appears in the call stack | A variable-height list implementation is in use, measuring child nodes one by one |
| `RenderSliverFixedExtentList` does not appear | Height is not fixed via `itemExtent` / `prototypeItem` |
| During fast sliding, `BUILD` + `LAYOUT` alternate densely | New items keep entering the viewport, each needing build + layout to measure its height |

> **Note**: A trace can only give a strong-suspicion signal and cannot directly show "`itemExtent` is not set". The final root cause must be confirmed against the code.

#### Code Verification

Open the source of the corresponding page and check whether `ListView.builder` / `ListView.separated` etc. are missing either of the following properties:

- `itemExtent`: fixed height
- `prototypeItem`: provides a height template item

If neither is set and the list item heights genuinely vary with content, this root cause is confirmed.

#### Fix

For fixed heights, provide `itemExtent` directly:

```dart
ListView.builder(
  itemCount: data.length,
  itemExtent: 56, // Each item is 56 high; measurement is skipped
  itemBuilder: (context, i) => ItemCell(data[i]),
);
```

When heights are not fixed, you can also use `prototypeItem` to provide a template.

#### Case Study


**Problem case: variable heights, measured item by item**

| | Problem case | Fix case |
|---|---|---|
| Description | Variable heights, measured item by item | Fixed height, measurement skipped |
| Screenshot | ![](../media/sliding/sliding-4-1-problem_example.png) | ![](../media/sliding/sliding-4-1-fix_example.png) |

```dart
Widget _buildBadListView() {
  return ListView.builder(
    itemCount: itemCount,
    // itemExtent not set; each item's height must be measured on the fly
    itemBuilder: (context, index) =>
        _buildItem(index, fixedHeight: false),
  );
}
```

Without `itemExtent` set, the ListView uses `RenderSliverList` (variable-height list); the scroll offset cannot be computed directly, so every appearing item needs a build + layout to measure its height. With 2~7 tags and varying line wraps, each item's height varies between roughly 99~130px; during fast sliding the measurement cost is amplified and frame drops occur.

![](../media/sliding/sliding-4-1-problem_hitrace_jank.png)

**Fix case: fixed height, measurement skipped**

```dart
Widget _buildGoodListView() {
  return ListView.builder(
    itemCount: itemCount,
    itemExtent: 136, // Fixed height (enough to hold two rows of tags); per-item measurement is skipped
    itemBuilder: (context, index) =>
        _buildItem(index, fixedHeight: true),
  );
}
```

With `itemExtent` set, the ListView switches to `RenderSliverFixedExtentList`; scroll offset = `index * 136`, locating the visible area without per-item measurement. The content is identical to the problem case, except that shorter items leave whitespace at the bottom — the expected trade-off of fixed height for smoothness.

The two cases share the same `_buildItem`, differing only in `mainAxisSize` — the variable-height case uses `.min` (shrink to content → uneven heights), the fixed-height case uses `.max` (fill the `itemExtent`):

```dart
Widget _buildItem(int index, {required bool fixedHeight}) {
  final tagCount = (index % 6) + 2; // 2~7 tags
  return Container(
    margin: _itemMargin,
    padding: _itemPadding,
    decoration: _itemDecorations[index % _itemDecorations.length],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text('Item $index', style: _titleStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(tagCount, _buildTag),
        ),
      ],
    ),
  );
}
```

> Supplementary note: `itemExtent` removes only the "measure height to locate" cost; build + layout still run when each item enters the viewport. To control the per-item construction cost, both cases also share the following treatment:
>
> - Tags use lightweight `Container` + `Text` instead of `Chip`, avoiding the internal `Material`/`InkWell`/shape clipping cost of `Chip`;
> - Background decoration `BoxDecoration` + color shades are precomputed into a `static final` list, not recreated on every `itemBuilder` call;
> - Styles and margins are hoisted to `static const`, shared globally and never rebuilt.

**Result comparison**

| | Problem case | Fix case |
|---|---|---|
| `itemExtent` | Not set | 136 |
| Per-item height | Varies with tag count/line wraps (roughly 99~130px) | Fixed at 136px |
| Scroll positioning | Per-item build+layout to measure height | `index * 136` direct positioning |
| Fast sliding | Frame drops present | Smooth |
| hitrace screenshot | ![](../media/sliding/sliding-4-1-problem_hitrace.png) | ![](../media/sliding/sliding-4-1-fix_example_hitrace.png) |

### 4.2 Root Cause: Overdraw / Offscreen Buffers

#### Symptom

Looks normal when static, but frame drops during sliding or animation, with only the Raster thread duration long.

#### Trace Signals

During sliding, if the UI thread is normal but the Raster thread becomes the bottleneck and the following characteristics appear, there is a high suspicion of overdraw / offscreen buffers:

| trace characteristic | Description |
|---|---|
| `GPURasterizer::Draw` proportion clearly higher than `Animator::BeginFrame` | Heavy drawing load; the problem is on the Raster thread |
| `saveLayer` appears in the `GPURasterizer::Draw` child calls | An offscreen buffer exists, usually triggered by clipping, Opacity, shadows, etc. |
| `BackdropFilter` / `ImageFilter` related slices appear | Full-screen or large-area blur causes per-pixel convolution |
| In animation scenarios, every frame's `GPURasterizer::Draw` is long | The animation repaints every frame, amplifying the saveLayer / blur cost |
| Shader compilation excluded (no `Load/Compile Shaders`) | Shows it is not cold shader compilation but the drawing itself being too heavy |

> **Note**: A trace can tell you "saveLayer / blur / heavy drawing exists" but cannot directly point out which Widget triggers it. To locate the specific Widget, combine the code with tools such as DevTools' Repaint Rainbow.

#### Code Verification

Return to the corresponding page code and focus on whether the visible items and their animation subtrees contain the following expensive operations:

- `Clip.antiAliasWithSaveLayer` (including `ClipRRect` etc. using `antiAliasWithSaveLayer`)
- Direct use of the `Opacity` Widget inside animations
- Large-area `BackdropFilter` / `ImageFiltered` blur
- Complex `BoxShadow` (large `blurRadius` / `spreadRadius`)
- Missing `RepaintBoundary`, letting animation repaints spread to parents

#### Fix

- Use the default clipping for rounded corners; avoid `antiAliasWithSaveLayer`;
- When opacity changes are needed in animations, replace directly animating `Opacity` with `FadeTransition` / `AnimatedOpacity`;
- For static translucency, change the color's alpha directly and use the Opacity Widget sparingly;
- Apply blur only to small areas;
- Isolate locally high-frequency repaint areas with `RepaintBoundary`, but do not overuse it.

#### Case Study

50 items each looping an opacity animation (0.3↔1.0, 2s); the two cases have identical animation parameters and differ only in Widget selection and clipping/blur/shadow configuration.
![](../media/sliding/sliding-4-2-occlusion_case.png)

**Problem case: four saveLayers stacked**

The animation driver uses `AnimatedBuilder` + a bare `Opacity`; the per-frame opacity change triggers a paint-stage `saveLayer`:

```dart
@override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Opacity(
        opacity: _animation.value,  // changes every frame → saveLayer
        child: child,
      );
    },
    child: _buildBadContent(widget.index),
  );
}
```

The content layer stacks three more saveLayers / expensive operations:

```dart
Widget _buildBadContent(int index) {
  return ClipRRect(
    clipBehavior: Clip.antiAliasWithSaveLayer,    // ① offscreen clipping
    borderRadius: _overdrawClipRadius,
    child: Container(
      // ...
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: ...),
        boxShadow: const [
          BoxShadow(blurRadius: 12, spreadRadius: 2, ...),  // ③ large-area shadow
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(               // ② full-area Gaussian blur
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Center(child: Text('Item $index', style: _overdrawTextStyle)),
        ],
      ),
    ),
  );
}
```

Every visible item, every frame = `Opacity` saveLayer + `antiAliasWithSaveLayer` saveLayer + full-area `BackdropFilter` blur + large-area shadow repaint — the Raster thread overloads quickly.

**Fix case: eliminating saveLayers one by one**

```dart
@override
Widget build(BuildContext context) {
  return RepaintBoundary(              // ④ isolate the repaint scope
    child: FadeTransition(            // ①→ compositor-layer opacity, no saveLayer
      opacity: _animation,
      child: _buildGoodContent(widget.index),
    ),
  );
}
```

```dart
Widget _buildGoodContent(int index) {
  return ClipRRect(
    clipBehavior: Clip.hardEdge,     // ②→ hard-edge clipping, no saveLayer
    borderRadius: _overdrawClipRadius,
    child: Container(
      // ...
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: ...),
        boxShadow: const [
          BoxShadow(blurRadius: 6, spreadRadius: 0, ...),  // ③→ smaller shadow
        ],
      ),
      child: Center(
        child: Text('Item $index', style: _overdrawTextStyle),
      ),
    ),
  );
}
```

Key changes:

- `Opacity` → `FadeTransition`: opacity is pushed down to the composition layer (`OpacityLayer`); the subtree is painted only once, and afterwards only the compositor adjusts the layer opacity each frame — no more `saveLayer` in the paint stage;
- `antiAliasWithSaveLayer` → `hardEdge`: pixels outside the clip region are skipped directly at paint time, with no offscreen buffer opened;
- `BackdropFilter` removed outright: the background is just a gradient, the blur adds no real visual value, and removing it saves the per-pixel convolution;
- `BoxShadow` shrunk (blur 12→6, spread 2→0): reduces the shadow repaint area;
- Outer `RepaintBoundary`: the animation only dirties its own layer and does not propagate to the parent ListView.

> Supplementary note: the `child` parameter of `AnimatedBuilder` should receive unchanging content (like `_buildBadContent` above) instead of being built inside the builder on every call — that way the Widget tree is built only once. The problem case still triggers saveLayer because of `Opacity`, but at least it avoids the cost of rebuilding the subtree every frame.

**Result comparison**

| Cost source | Problem case | Fix case |
|---|---|---|
| Opacity animation | `Opacity` → paint-stage saveLayer | `FadeTransition` → compositor-layer opacity |
| Rounded-corner clipping | `antiAliasWithSaveLayer` → offscreen buffer | `hardEdge` → direct clipping |
| Background blur | Full-area `BackdropFilter` sigma=8 | Removed |
| Shadow | blur 12 / spread 2 | blur 6 / spread 0 |
| Repaint isolation | No explicit `RepaintBoundary` | Has `RepaintBoundary` |
| Fast sliding | Raster thread red, obvious frame drops | Smooth |
| hitrace screenshot | ![](../media/sliding/sliding-4-2-problem_example_hitrace.png) | ![](../media/sliding/sliding-4-2-fix_example_hitrace.png) |

## 5. References and Further Reading

- Flutter official performance documentation (https://docs.flutter.dev/perf)
- DevTools Performance guide (https://docs.flutter.dev/tools/devtools/performance)
- HarmonyOS performance tuning tools overview (https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-insight-description)
- HarmonyOS trace-level deep dives (three companion articles):
  - [Performance Analysis: Sorting the Thread Sequence](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-analysis-threads-sequence.md)
  - [Performance Analysis: Frame Rendering Tracing](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-frame-rendering-tracking.md)
  - [Performance Analysis: Swipe Response Latency](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-sliding-response-time.md)
