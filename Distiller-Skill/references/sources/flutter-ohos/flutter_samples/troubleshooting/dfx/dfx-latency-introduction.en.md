# Introduction to Flutter Tap Response and Completion Latency Analysis

## 1. Overview

When users report that a "page feels laggy", there are two common types of **latency** issues: excessive response latency and excessive completion latency.

Response latency generally refers to the time from when a finger touch event is generated to when the **first visible feedback frame** appears on screen. In Flutter this usually corresponds to: the touch event is dispatched by the system to the Flutter main thread → the main thread processes it and triggers a rebuild → a Layer tree is produced → the raster thread rasterizes it → the frame is presented to screen.

Completion latency generally refers to the time from the start of a user operation to the point where the entire operation is **thoroughly complete** (page rendering stable, all data displayed). It includes the response latency and also covers subsequent work such as data loading, image decoding, and complex layout.

## 2. Flutter Rendering Pipeline Overview

Rendering a frame in Flutter roughly goes through four stages:

| Stage | What it does | Thread where the time is mostly spent |
| --- | --- | --- |
| **Build** | Builds/updates the Widget tree and Element tree according to state changes | UI thread (main thread) |
| **Layout** | The RenderObject tree computes the size and position of each node | UI thread |
| **Paint** | Generates drawing commands and builds the Layer tree | UI thread |
| **Composite** | Rasterizes the Layer tree into pixels and outputs them to the screen | Raster thread (render thread / GPU thread) |

The **UI thread** runs the Dart VM, executes your Dart code and the Flutter framework code, and produces the Layer tree; the **Raster thread** receives the Layer tree, calls Skia or Impeller for rasterization and composition, and finally presents the frame to screen.

When analyzing performance, look at the durations of both threads: an overly long UI thread duration indicates a performance problem in the Dart layer; an overly long Raster thread duration means the drawing is too heavy (shadows, blur, large images, saveLayer, etc.).

The subsequent analysis mainly revolves around the UI thread and the Raster thread, so you first need to learn how to confirm their tids from a trace. Look through the thread list in the trace and focus on the following role categories:

| Role | Typical thread names | Description |
|---|---|---|
| `flutter_ui` | `1.ui`, `root.1.ui`, `root.N.ui` | Flutter UI thread, runs Dart code |
| `platform_main` | Application bundle name (e.g., `.my_app`) | Application main thread |
| `flutter_raster` | `1.raster`, `root.1.raster` | Flutter Raster thread, performs rasterization |

> **Flutter 3.35+ thread merging**: Starting from Flutter 3.35, on the OHOS platform the UI thread and the application main thread may be merged into a single thread named after the application bundle name (e.g., `.complex_layout`), classified as `platform_main` rather than `flutter_ui`. In this case, do not identify the UI thread by thread name alone; instead locate it by searching the trace for `flutter::Animator::BeginFrame` — the tid that slice lives on is the UI thread.

## 3. Locating Tap Response/Completion Latency Based on OHOS Platform Traces

### 3.1 Response latency: first frame presented to screen
| trace name | Field | Description |
|---|---|---|
| `DispatchTouchEvent` | type field: 0=press, 1=release, 2=move | Touch event dispatch. <br> In a tap scenario there is usually just one down/up pair, possibly with a few moves in between. If the trace contains multiple taps, each down/up pair corresponds to one tap. |


![Trace example of the tap window in DevEco Profiler](../media/latency/latency-3-1-click_window.png)



Starting from the **touch start point** (`type=1` release in tap scenarios, `type=0` press in touch/sliding scenarios), search forward for the first complete rendering frame chain: `Animator::BeginFrame` → `GPURasterizer::Draw` → `RSMainThread::DoComposition` → `RSHardwareThread::CommitAndReleaseLayers`. The moment the first frame reaches `CommitAndReleaseLayers` is the **response latency endpoint**.

### 3.2 Completion latency: first screen stabilization


Continue checking forward from the first frame presented to screen until frame rendering activity stabilizes — that is, `Animator::BeginFrame` and `GPURasterizer::Draw` no longer appear consecutively, or the frame interval returns to the normal refresh period. The moment the last frame is presented to screen is the **completion latency endpoint**.

![](../media/latency/latency-3-2-first_frame.png)

Response latency is a chain of multiple stages; you need to measure each segment's duration and find the longest bottleneck segment:

| Stage | Start/end traces | What a long duration means | Where to dig next |
|---|---|---|---|
| **Multimodal input** | No corresponding trace_name, but there is a corresponding thread `mmi_service` | System-side touch events | Not applicable |
| **Touch event dispatch** | `mmi_service` → `DispatchTouchEvent type=1/0` | The system dispatches touch events to the application for reception | Not applicable |
| **Event dispatch** | `DispatchTouchEvent type=1` → `Engine::DispatchPointerDataPacket` | Event dispatch delay in the system layer | Check `touchEventDispatch`, system-side event backlog |
| **Vsync wait** | `Engine::DispatchPointerDataPacket` → `VsyncFireCallback` | The touch occurred between two Vsync signals and must wait for the next one | Normal behavior; abnormal if > 1 frame budget |
| **UI thread processing** | `VsyncFireCallback` → `Animator::BeginFrame` → build/layout/paint complete | Heavy Dart-side build, or blocked by synchronous heavy work | Check `begin_frame_` / `draw_frame_` to determine which of BUILD/LAYOUT/PAINT is heaviest |
| **Raster rasterization** | `GPURasterizer::Draw` | Drawing too heavy, or cold shader/glyph compilation | Check `CreateGlyphAtlas`, `Load/Compile Shaders`, `SurfaceFrame::Submit` |
| **Application → render service** | `SurfaceFrame::Submit` → `RSMainThread::ProcessCommandUni[pid,seq]` | Submission and scheduling delay from the engine to the render service | Align with transactionFlag↔pid,seq, check buffer availability |
| **Composition and presentation** | `RSMainThread::DoComposition` → `CommitAndReleaseLayers` | Heavy composition load in the system layer | Check compositor layers, fence waits |

> In most cases the bottleneck is in the **UI thread processing** segment (heavy build or blocking by synchronous heavy work) or the **Raster rasterization** segment (cold shader/glyph compilation). Event dispatch and vsync waiting are usually short; if these two segments are long, it is a system-layer problem.


### 3.3 UI Thread Bottlenecks

Within the narrowed window, filter slices by the UI thread tid and focus on the following slices to determine which stage is heaviest:

| slice name | Description | Root cause it points to |
|---|---|---|
| `BUILD` | Widget tree build stage | Too much one-shot building on the first screen, setState triggering large-scale rebuilds, itemBuilder creating heavyweight Widgets |
| `LAYOUT` | RenderObject tree layout stage | Complex first-screen layout, use of `IntrinsicHeight` / `IntrinsicWidth`, heavy Flex/Stack nesting |
| `PAINT` | Generates drawing commands | Complex drawing commands, heavy clipping / complex `CustomPaint` |
| `Animate` | Animation callback execution | Heavy computation inside animation callbacks |
| `PlatformConfiguration` | Platform configuration/message handling | Blocking synchronous Platform Channel calls |
| `BeginFrame` long overall but no obvious child slices | Start of a frame; schedules the BUILD/LAYOUT/PAINT stages | Main thread blocked by synchronous heavy work (e.g., JSON parsing, file IO, complex computation) |

If `BUILD`/`LAYOUT`/`PAINT` are missing from the above slices, the trace was captured without `--trace-systrace`, and UI thread attribution is limited. Add the `--trace-systrace` engine parameter in `FlutterLoader.ets` and capture again.

#### Root Cause 1: Synchronous Heavy Work on the Main Thread

##### Symptom

After tapping the page, a white screen/freeze for a while, then the content appears all at once. Completion latency is very long.

##### Trace Signals

After the tap, if the UI thread becomes the bottleneck and the following characteristics appear, there is a high suspicion that the main thread is doing synchronous heavy work:

| trace characteristic | Description |
|---|---|
| `BeginFrame` long overall, but `BUILD`/`LAYOUT`/`PAINT` child slices not obvious | The UI thread is occupied by other synchronous tasks and is not visibly building, laying out, or painting |
| Slices such as `PlatformConfiguration` / `DartIsolate::HandleMessage` abnormally long | The main thread is processing a large number of platform messages or Dart messages |
| `Animator::BeginFrame` does not appear for a long time after the tap, or the first frame far exceeds the frame budget | The first frame is blocked by synchronous heavy work and cannot start rendering in time |
| Almost no `GPURasterizer::Draw` activity during the period | The Raster thread is waiting for the UI thread to produce the Layer tree |

> **Note**: A trace can only tell that "the main thread is blocked"; it cannot directly show whether the blocking source is JSON parsing, file IO, or complex computation — confirm against the code.

##### Code Verification

Open the handler for the button tap or page entry and check for the following synchronous heavy work:

- Parsing large payloads with `jsonDecode` / `xmlDecode`
- Synchronous file reads such as `rootBundle.loadString` / `File.readAsStringSync`
- CPU-intensive operations such as complex math, heavy string processing, image encoding
- Executing any of the above synchronously before `setState`

If present, this root cause is confirmed.

##### Fix

Move the heavy work into an Isolate:

```dart
import 'package:flutter/foundation.dart';

Future<List<Item>> loadItems() async {
  final raw = await rootBundle.loadString('assets/items.json');
  return compute(_parseItems, raw); // compute moves parsing to a background Isolate
}

List<Item> _parseItems(String raw) {
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Item.fromJson).toList();
}
```

##### Case Study

Two case studies use a 100-million-iteration integer loop to simulate "synchronous heavy work on the main thread" (about 0.5~2s). A button tap triggers the computation, comparing the tap response difference between synchronous blocking and background Isolate computation.

**Problem case: synchronously blocking the UI thread**

![](../media/latency/latency-3-3-1-problem_example.png)

After the button is tapped, the 100-million-iteration loop runs synchronously on the main thread; the loading indicator never gets a chance to render, and the button stays stuck in the pressed state until the computation finishes:

```dart
const _heavyIterations = 100000000; // 100 million iterations, about 0.5~2s

// Top-level function, called by compute() in a background Isolate
int _heavyWork(int iterations) {
  var result = 0;
  for (var i = 0; i < iterations; i++) {
    result = (result + i * 31) & 0x7FFFFFFF;
  }
  return result;
}

class _SyncBadTabState extends State<_SyncBadTab> {
  int? _result;

  void _run() {
    // Synchronous blocking: the loading indicator never appears and the button stays stuck in the pressed state
    final result = _heavyWork(_heavyIterations);
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _result == null ? 'Tap the button to start the calculation' : 'Result: $_result',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _run, child: const Text('Synchronous calculation (blocks the UI)')),
            const SizedBox(height: 8),
            const Text('After the tap, the UI freezes until the calculation completes', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
```


**Fix case: moving the work to a background Isolate with compute**

![](../media/latency/latency-3-3-1-fix_example.png)

Use `compute()` to offload the computation to a background Isolate. The main thread returns immediately, the loading indicator renders normally, and the UI stays responsive:

```dart
class _SyncGoodTabState extends State<_SyncGoodTab> {
  int? _result;
  bool _loading = false;

  Future<void> _run() async {
    setState(() => _loading = true);
    final result = await compute(_heavyWork, _heavyIterations);
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _result == null ? 'Tap the button to start the calculation' : 'Result: $_result',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _run,
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Isolate calculation (non-blocking)'),
            ),
            const SizedBox(height: 8),
            const Text('After the tap, loading appears immediately and the UI stays responsive', style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
```

**Result comparison**

| | Problem case | Fix case |
|---|---|---|
| Where the computation runs | Synchronously on the main thread | Background Isolate (`compute`) |
| First frame after the tap | Stuck in the pressed state; the loading indicator never appears | The loading indicator appears immediately |
| UI responsiveness | Completely frozen until the computation finishes | Always interactive |
| Completion latency | Long (computation + rendering serialized) | Short (computation and rendering in parallel) |
| hitrace screenshot | ![](../media/latency/latency-3-3-1-problem_example_hitrace.png) | ![](../media/latency/latency-3-3-1-fix_example_hitrace.png) |

#### Root Cause 2: Too Much One-Shot Building/Loading on the First Screen

##### Symptom

After the page opens, a white screen/spinner shows first, then all the content appears at once; completion latency is high.

##### Trace Signals

After the tap navigation, if the UI thread's `BUILD` stage is extremely long and the following characteristics appear, there is a high suspicion of too much one-shot building/loading on the first screen:

| trace characteristic | Description |
|---|---|
| The first frame's `BUILD` slice accounts for an extremely high proportion, and `LAYOUT`/`PAINT` are dragged longer as well | A large number of Widgets must be built for the first frame |
| The `BUILD` call stack contains heavy child construction (e.g., `ListView` children, `Wrap` children) | Non-lazy loading causes too many Elements to be built at once |
| After the first frame, `Animator::BeginFrame` + `GPURasterizer::Draw` continue for several consecutive frames | Content is built in batches or images are decoded frame by frame, dragging out completion latency |
| `DecodeImage` / `ImageDecoder` related slices cluster on the first screen | The first frame loads and decodes too many images |

> **Note**: A trace can show a "large build volume" but cannot directly distinguish whether there are many Widgets or heavy data loading — confirm against the code.

##### Code Verification

Check the target page's build logic and confirm whether any of the following exist:

- Using `ListView(children: ...)` / `Column` / `Wrap` to build a large number of children at once
- Generating or loading a large amount of data synchronously in `initState` / `build`
- Requesting and decoding all images on the first screen at once
- No skeleton screen or placeholder, waiting for all content to be ready before presenting to screen

If any of the above exist, this root cause is confirmed.

##### Fix

- Prefer showing a skeleton screen or placeholder to give the user early feedback;
- Paginate data and lazy-load images;
- Delay building of non-first-screen content.

##### Case Study

Both case studies have a button on their tab page that navigates to a list page. Completion latency is measured from the button tap until the list content is fully rendered and stable. It compares the completion latency of non-lazy full building versus skeleton screen + batched lazy loading.

**Problem case: non-lazy ListView, 500 Widgets fully built at once**

![](../media/latency/latency-3-3-2-problem_example.png)

The tab page shows a navigation button; after the tap, `Navigator.push` enters `_OverBuildBadListPage`. That page generates 500 items in `initState`, and `build` returns a non-lazy `ListView` in which all 500 Widgets are fully built — the first frame must wait for the entire build to finish:

```dart
class _OverBuildBadTab extends StatelessWidget {
  const _OverBuildBadTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _OverBuildBadListPage()),
            ),
            child: const Text('Open the list page (non-lazy, 500 items)'),
          ),
          const SizedBox(height: 8),
          const Text('After the tap, a white screen appears while 500 items are built at once', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class _OverBuildBadListPageState extends State<_OverBuildBadListPage> {
  late final List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.generate(500, (i) => 'Item $i');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Problem case')),
      body: ListView(children: _items.map(_buildListItem).toList()),
    );
  }
}
```


**Fix case: skeleton screen + batched lazy loading**

![](../media/latency/latency-3-3-2-fix_example.png)

The tab page likewise shows a navigation button; after the tap it enters `_OverBuildGoodListPage`. That page first renders a skeleton-screen placeholder so the first frame is presented quickly, then loads 10 batches of 50 items each incrementally, using `ListView.builder` lazy loading:

```dart
class _OverBuildGoodTab extends StatelessWidget {
  const _OverBuildGoodTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _OverBuildGoodListPage()),
            ),
            child: const Text('Open the list page (skeleton + batched loading)'),
          ),
          const SizedBox(height: 8),
          const Text('After the tap, the skeleton shows first and content fills in gradually', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

class _OverBuildGoodListPageState extends State<_OverBuildGoodListPage> {
  final List<String> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIncrementally();
  }

  Future<void> _loadIncrementally() async {
    await Future.delayed(const Duration(milliseconds: 16)); // let the skeleton frame render first
    for (int batch = 0; batch < 10; batch++) {
      if (!mounted) return;
      setState(() {
        _items.addAll(List.generate(50, (i) => 'Item ${batch * 50 + i}'));
        _loading = false;
      });
      await Future.delayed(Duration.zero); // yield the event loop without adding extra delay
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? ListView.builder(itemCount: 10, itemBuilder: (_, __) => _buildSkeletonItem())
        : ListView.builder(itemCount: _items.length, itemBuilder: (_, i) => _buildListItem(_items[i]));
    return Scaffold(
      appBar: AppBar(title: const Text('Fix case')),
      body: body,
    );
  }
}
```

> Supplementary note: each `_buildListItem` contains an avatar, a title, a subtitle, and 2~5 tags, so its construction cost is far greater than that of a plain text item; `_buildSkeletonItem` returns a gray rounded-corner placeholder `Container`. The two cases share these two helper functions and differ only in loading strategy. In the fix case, batches are separated by `Future.delayed(Duration.zero)`, which yields the event loop without adding extra delay, so completion latency is determined mainly by the actual build time.


**Result comparison**

| | Problem case | Fix case |
|---|---|---|
| Navigation method | Button tap → `Navigator.push` | Button tap → `Navigator.push` |
| Per-item complexity | Avatar + title + subtitle + tags | Avatar + title + subtitle + tags |
| First-frame build | 500 complex items fully built | 10 skeleton items |
| ListView type | `ListView(children:)` non-lazy | `ListView.builder` lazy |
| First-screen feedback | White screen waiting for the entire build to finish | Skeleton screen presented immediately |
| Data loading | 500 items at once | 10 batches × 50 items incrementally, no extra delay between batches |
| Completion latency | Long (500-item first frame blocked) | Short (fast first frame, content fills in gradually) |
| hitrace screenshot | ![](../media/latency/latency-3-3-2-problem_example_hitrace.png) | ![](../media/latency/latency-3-3-2-fix_example_hitrace.png) |

####  Root Cause 3: setState Granularity Too Large, Whole-Page Rebuild

##### Symptom

After a tap, the page gives no feedback for a long time, or a refresh takes a long time before the content stabilizes.

##### Trace Signals

After the tap, if the UI thread's `BUILD` stage becomes longer and the following characteristics appear, there is a high suspicion that the `setState` granularity is too large:

| trace characteristic | Description |
|---|---|
| After the tap, `BUILD` slices become noticeably longer, but each individual `build` function is not itself complex | The rebuild scope is too large, not a single overly heavy Widget |
| `BUILD` child calls include many static subtrees that should not have changed | `setState` is placed too high up, so static content is rebuilt as well |
| Every tap triggers a `BUILD` of nearly the same scope | The scope affected by the state change has not been narrowed |
| With `--trace-systrace` enabled, `LAYOUT`/`PAINT` are also dragged longer | The rebuild causes the whole page to go through Layout/Paint again |

> **Note**: A trace can show a "large rebuild scope" but cannot directly point out which `setState` triggered it — confirm against the code.

##### Code Verification

Check the state management of the corresponding page and confirm whether any of the following exist:

- `setState` is called at the page root or in a high-level ancestor Widget
- Static subtrees are not marked `const`, forcing a rebuild on every `setState`
- State has not been pushed down to the minimal changing scope (e.g., counter state at page level instead of component level)
- A `StatefulWidget` wraps a large amount of static content just for partial refresh

If any of the above exist, this root cause is confirmed.

##### Fix

Push state down to the minimal scope, and mark static subtrees `const` to avoid repeated building.

```dart
// ❌ Bad: when the counter changes, HeavyHeader and HeavyList are forced to repaint
class BadPage extends StatefulWidget {
  const BadPage({super.key});
  @override
  State<BadPage> createState() => _BadPageState();
}

class _BadPageState extends State<BadPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeavyHeader(),                 // unchanged, yet forced to rebuild
        Expanded(child: HeavyList()),  // unchanged, yet forced to rebuild
        Text('$_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

```dart
// ✅ Good: only Counter itself rebuilds; the static parts are all const
class GoodPage extends StatelessWidget {
  const GoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HeavyHeader(),               // const: Flutter reuses it directly, no more rebuild
        Expanded(child: HeavyList()),
        Counter(),                   // the change scope is confined to this subtree
      ],
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key});
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

##### Case Study

Four tabs compare the rebuild cost of two kinds of heavyweight content: **non-lazy** (`Wrap` + 300 items, all children have Elements) and **lazy** (`GridView.builder` + 500 items, only visible items have Elements). Each tab has a counter button underneath; tapping +1 triggers `setState`.

| Tab | Heavyweight content | setState location | Rebuild scope after +1 |
|---|---|---|---|
| Problem · non-lazy | `Wrap(300)` | Page root | All 300 items rebuilt |
| Fix · non-lazy | `const Wrap(300)` | Inside `_ScopedCounter` | Counter only |
| Problem · lazy | `GridView.builder(500)` | Page root | Only visible items rebuilt |
| Fix · lazy | `const GridView.builder(500)` | Inside `_ScopedCounter` | Counter only |

**Problem case: setState at the page root, heavyweight static subtrees forced to rebuild**

![](../media/latency/latency-3-3-3-problem_example.png)

`_SetStateBadTab` is a StatefulWidget with `setState` at the page root. On +1, not only the counter but also the heavyweight subtree above is forced to rebuild. The `useLazy` parameter switches between non-lazy and lazy:

```dart
class _SetStateBadTab extends StatefulWidget {
  final bool useLazy;
  const _SetStateBadTab({this.useLazy = false});
  @override
  State<_SetStateBadTab> createState() => _SetStateBadTabState();
}

class _SetStateBadTabState extends State<_SetStateBadTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.useLazy
              ? const _HeavyStaticContentLazy()
              : const _HeavyStaticContentNonLazy(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('$_count', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('+1')),
            ],
          ),
        ),
      ],
    );
  }
}
```


**Fix case: static subtrees as const, state pushed down to the minimal scope**

![](../media/latency/latency-3-3-3-fix_example.png)

The page becomes a `StatelessWidget`; static subtrees are all `const`. Counter state is pushed down into a standalone `_ScopedCounter`, so on +1 only it rebuilds:

```dart
class _SetStateGoodTab extends StatelessWidget {
  final bool useLazy;
  const _SetStateGoodTab({this.useLazy = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.useLazy
              ? const _HeavyStaticContentLazy()
              : const _HeavyStaticContentNonLazy(),
        ),
        const Padding(padding: EdgeInsets.all(16), child: _ScopedCounter()),
      ],
    );
  }
}

class _ScopedCounterState extends State<_ScopedCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$_count', style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 16),
        ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('+1')),
      ],
    );
  }
}
```

> Supplementary note: the two versions of the heavyweight subtree share `_buildHeavyCell` (icon + text). The **non-lazy** `_HeavyStaticContentNonLazy` uses `SingleChildScrollView` + `Wrap(300 items)`; all children have Elements, and on +1 all of them are rebuilt (about 1800 Widget instances, taking ~15-20ms). The **lazy** `_HeavyStaticContentLazy` uses `GridView.builder(500 items)`; only visible items have Elements, and on +1 only about 20 visible items are rebuilt (<1ms). In the fix case both are marked `const`, so Flutter directly reuses the existing instances and no rebuild happens on +1.


**Result comparison**

| | Problem · non-lazy | Fix · non-lazy |
|---|---|---|
| Heavyweight content | `Wrap(300 items)` | `const Wrap(300 items)` |
| Rebuild after +1 | All 300 items rebuilt | Counter only |
| +1 rebuild cost | ~15-20ms | <1ms |
| Response latency | Long (visible jank) | Short |
| hitrace screenshot | ![](../media/latency/latency-3-3-3-problem_example_hitrace.png) | ![](../media/latency/latency-3-3-3-fix_example_hitrace.png) |

### 3.4 Raster Thread Bottlenecks

Within the narrowed window, filter Flutter/Impeller-related slices by the Raster thread tid and focus on whether the following slices appear and how long they take:

| slice name | Description | Root cause it points to |
|---|---|---|
| `impeller::CreateGlyphAtlas` / `UpdateAtlasBitmap` | Glyph atlas creation and update | Cold glyph atlas startup (first rendering of new glyphs) |
| `Load/Compile Shaders` / `bisheng_graphic_pipeline_compilation` | Shader loading and compilation | Cold shader compilation (first use of a new shader) |
| `SurfaceFrame::Submit` / `Encode` | Frame submission and encoding | Complex scene, too many drawing commands |
| `AcquireNextImageKHR` / `vkQueueSubmit` | GPU image acquisition and command queue submission | GPU resource contention or driver bottleneck |
| `DecodeImage` / `ImageDecoder` related slices | Image decoding | Images decoded at original size, without `cacheWidth`/`cacheHeight` |

> Other common Raster bottlenecks (large image decoding, saveLayer overdraw, shadow blur, etc.).

#### Root Cause 1: Large Images Decoded at Original Size

##### Symptom

After entering the page, images take a long time to show, or after a pull-to-refresh the content takes a long time to stabilize.

##### Trace Signals

After the tap, if the Raster thread becomes the bottleneck and the following characteristics appear, there is a high suspicion of large images being decoded at original size:

| trace characteristic | Description |
|---|---|
| `GPURasterizer::Draw` or image-decoding-related slices become noticeably longer | Image decoding takes up a large amount of Raster thread time |
| Related slices such as `DecodeImage` / `ImageDecoder` / `UploadTexture` appear | The engine is decoding or uploading large-size images |
| The UI thread is normal, but the first-screen image area stays blank or stutters for a long time | The bottleneck is image decoding, not Dart-layer building |
| Frames drop the first time an image is displayed; subsequent sliding is normal | The first decode is expensive and does not recur after caching |

> **Note**: A trace can tell that "image decoding takes a long time" but cannot directly show the difference between the image's original resolution and its display size — confirm against the code.

##### Code Verification

Check the image-loading code on the page and confirm whether any of the following exist:

- `Image.network` / `Image.memory` / `Image.asset` etc. without `cacheWidth` / `cacheHeight` specified
- The original resolution of network/local images is far larger than the actual display size
- Many images in a list decoded simultaneously, without lazy loading or preload control
- `ImageCache` used without limiting image size

If any of the above exist, this root cause is confirmed.

##### Fix

Decode at the target display size:

```dart
Image.network(
  imageUrl,
  cacheWidth: 200,  // decode only to 200×200
  cacheHeight: 200,
);
```

##### Case Study

Both case studies have a button on their tab page that navigates to an image list page. Completion latency is measured from the button tap until all images are decoded and displayed. The image data is generated at runtime by `dart:ui` when entering the page (4000×3000 PNG), with **no network dependency**, ensuring that only decoding time is compared.

**Problem case: no cacheWidth/cacheHeight, decoded at the original 4000×3000 size**

![](../media/latency/latency-3-4-1-problem_example.png)

The tab page shows a navigation button; after the tap, `Navigator.push` enters `_ImageBadListPage`. `Image.memory` does not specify `cacheWidth`/`cacheHeight`, so images are decoded at the original 4000×3000 resolution but finally displayed only 200 high — the decoding and GPU memory cost is entirely wasted:

```dart
class _ImageBadTab extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageBadTab({required this.imageBytes});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ImageBadListPage(imageBytes: imageBytes)),
            ),
            child: const Text('Load images (decoded at original size)'),
          ),
          const SizedBox(height: 8),
          const Text('4000×3000 decoded at original size; long raster thread time', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class _ImageBadListPage extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageBadListPage({required this.imageBytes, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Problem case')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8),
          child: Image.memory(imageBytes, height: 200, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
```


**Fix case: specify cacheWidth/cacheHeight, decoding only to the size needed for display**

The tab page likewise shows a navigation button; after the tap it enters `_ImageGoodListPage`, which specifies `cacheWidth: 800` and `cacheHeight: 600` (physical pixels) — decoding to 800×600 is enough, greatly reducing decoding time and GPU memory:

```dart
class _ImageGoodTab extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageGoodTab({required this.imageBytes});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ImageGoodListPage(imageBytes: imageBytes)),
            ),
            child: const Text('Load images (downscaled decoding)'),
          ),
          const SizedBox(height: 8),
          const Text('800×600 downscaled decoding; short raster thread time', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

class _ImageGoodListPage extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageGoodListPage({required this.imageBytes, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fix case')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8),
          child: Image.memory(
            imageBytes,
            height: 200,
            fit: BoxFit.cover,
            cacheWidth: 800, // decode only to 800×600 (physical pixels)
            cacheHeight: 600,
          ),
        ),
      ),
    );
  }
}
```

> Supplementary note: the image data is generated at runtime by `dart:ui` when entering the page (`PictureRecorder` + `Canvas` draws a gradient + 500 circles → `toImage` → `toByteData(png)`), generated once and cached as a `Uint8List`; the two cases share the same bytes. The unit of `cacheWidth`/`cacheHeight` is physical pixels: with a device DPR=3, a logical height of 200 corresponds to 600 physical pixels; 800 is chosen here with a slight margin to ensure sharpness.

**Result comparison**

| | Problem case | Fix case |
|---|---|---|
| Navigation method | Button tap → `Navigator.push` | Button tap → `Navigator.push` |
| Image source | Runtime-generated 4000×3000 PNG | Same bytes |
| Decoding API | `Image.memory` | `Image.memory` + `cacheWidth`/`cacheHeight` |
| Decode resolution | 4000×3000 (original size) | 800×600 |
| Display size | 200 high | 200 high |
| Decoded pixels | 12 million | 480 thousand (about 1/25) |
| GPU memory usage | High | Low |
| Completion latency | Long (slow large-image decoding) | Short (fast decoding, content stabilizes sooner) |
| hitrace screenshot | ![](../media/latency/latency-3-4-1-problem_example_hitrace.png) | ![](../media/latency/latency-3-4-1-fix_example_hitrace.png) |

##### hitrace Details

The following analyzes the details one by one from the hitrace. First, favorite and sort the UI thread and the Raster thread, because this case involves image decoding, which entails file reads, and the IO thread or IO worker threads also take part.
The thread overview after favoriting is shown below; the problem case clearly takes longer than the fix case.

| | Problem case | Fix case |
|---|---|---|
| Thread overview | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_1.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_1.png) |


Information about the original image can be found in the UI thread. Comparing the screenshots of the problem case and the fix case shows they are identical.
`Image MakeFromDataOHOS` shows the original image's memory size, and `Image GetInfo:ImageGenerate-0xxxxxxxxx:(size-4000*3000,frame_count-1-duration-0,isHdr-0)` shows the memory size requested for decoding.

| | Problem case | Fix case |
|---|---|---|
| Original image memory size | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_2.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_2.png) |
| Original image size | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_3.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_3.png) |


Next, look at the time and memory size requested for image decoding. Comparing the screenshots below, the problem case's image decoding clearly takes longer than the fix case's, and the memory size requested for decoding is also clearly larger.
`Image CreateExternalTextureSourceOHOS:ImageGenerate-0xxxxxxxx:(size-4000*3000,frame_count-1-duration-0,isHdr-0)` shows the time requested for decoding and the original image size. Comparing the screenshots of the problem case and the fix case, the problem case's duration and memory size are clearly larger than the fix case's. 
`vkAllocateMemory: xxxxx` shows, on the system side, the memory size requested for the decoded image.

| | Problem case | Fix case |
|---|---|---|
| Image decoding duration | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_4.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_4.png) |
| Memory size requested for decoding | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_5.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_5.png) |


## 4. References and Further Reading

- Flutter official performance documentation (https://docs.flutter.dev/perf)
- DevTools Performance guide (https://docs.flutter.dev/tools/devtools/performance)
- HarmonyOS performance tuning tools overview (https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-insight-description)
- HarmonyOS trace-level deep dives (three companion articles):
  - [Performance Analysis: Sorting the Thread Sequence](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-analysis-threads-sequence.md)
  - [Performance Analysis: Frame Rendering Tracing](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-frame-rendering-tracking.md)
  - [Performance Analysis: Swipe Response Latency](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-sliding-response-time.md)
