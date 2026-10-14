# Guide to Analyzing Sliding Jank, Frame Dropping, and Latency Issues

> Back to [README.en.md](README.en.md)

> When a user says "why is this list janky again", chances are it is not the network slacking off — frames are being dropped behind the scenes.
> This document teaches you the complete method for going from "feels janky" to "hard evidence": rendering model → jank locating → tool usage → latency measurement.

---

## 1. Rendering Model: Where Does a Frame's Time Go?

### 1.1 Rendering Pipeline: Build → Layout → Paint → Composite

Every frame must pass through four stages before it can be displayed on screen, like an assembly line in a factory:

```
Build → Layout → Paint → Composite (rasterization)
 │       │        │         │
 │       │        │         └─ Raster thread: turns the scene into pixels and hands them to the GPU to present to screen
 │       │        └─ UI thread: generates drawing commands (Layer tree)
 │       └─ UI thread: determines each component's size and position
 └─ UI thread: runs your Dart code, updates the Widget tree
```

| Stage | Which thread | What it does | What being slow means |
|------|-----------|--------|-----------|
| **Build** | UI thread | Runs Dart code, updates the Widget tree | Dart code too complex |
| **Layout** | UI thread | Determines each component's size and position | Layout hierarchy too deep |
| **Paint** | UI thread | Generates drawing commands (Layer tree) | Too many drawing commands |
| **Composite** | Raster thread | Turns the Layer tree into pixels, composited and presented to screen via HarmonyOS RenderService | Scene too complex (large images/blur/many layers) |

> **Beginner tip**: The first step in troubleshooting jank is figuring out **which thread exceeded its budget** — the UI thread (slow Dart code) or the Raster thread (drawing too heavy).

### 1.2 Frame Budget

The screen refreshes 60 times per second (or 90/120 times), and every frame must be drawn within the allotted time:

| Screen refresh rate | Frame budget | Plain explanation |
|-----------|--------|---------|
| 60Hz | **16.6ms** | Each frame must be drawn within 16.6 milliseconds |
| 90Hz | **11.1ms** | Each frame must be drawn within 11.1 milliseconds |
| 120Hz | **8.3ms** | Each frame must be drawn within 8.3 milliseconds |

If a frame is not drawn within its budget, that frame is "dropped" (frame drop/jank), and what the user sees is a brief "hiccup".

> **An analogy**: Think of a flipbook — you need to flip 60 pages per second for the animation to look smooth. If one page takes you 50 milliseconds to flip, the animation "hitches".

### 1.3 Four Metrics You Must Distinguish

| Metric | Plain explanation | How to check | Notes |
|------|---------|--------|---------|
| **FPS / frame drop rate** | Overall smoothness | Overlay or SmartPerf | **Averages hide occasional big janks**; check P90/P99 frame durations |
| **Frame duration** | How long each frame took to draw | DevTools Frames chart | UI and Raster must be checked separately |
| **Response latency** | Time from touch to first-frame feedback | trace chain / instrumentation | >100ms feels "sluggish" to users |
| **Completion latency** | Time from operation to thorough completion | Instrumentation (t2-t0) | A passing response latency does not mean a passing completion latency |

> **Beginner pitfall**: Do not be fooled by average FPS! An average of 55fps looks decent, but if a few frames took 200ms, users will definitely feel the jank. Check P90/P99 frame durations and the over-budget frame count.

### 1.4 Response Latency vs. Completion Latency

These are two important metrics in the Huawei application experience quality standards; when users say "laggy", it is often one of these two latencies at fault:

| Metric | Plain explanation | User perception threshold | Example |
|------|---------|------------|------|
| **Response latency** | Time from user touch to the **first visual feedback** | >100ms feels "sluggish" | A button is tapped, and only after 100ms does the UI react |
| **Completion latency** | Time from a user operation to **thorough completion of the entire operation** | Depends on the scenario | Opening a detail page shows a white screen for 2 seconds before the content appears |

> **How to tell them apart**:
> - Response latency is "did it react immediately after the tap" — a blocked main thread makes the response slow
> - Completion latency is "has the operation thoroughly completed" — slow data loading or an oversized first-screen build makes completion slow
> - Response latency may pass (an animation starts right after the tap) while completion latency fails (the animation ends but the content still has not appeared)

---

## 2. The Full Chain from Touch Event to Screen

### 2.1 The Touch Event Delivery Chain

When your finger slides across the screen, the event travels a long "delivery chain" before becoming a frame on screen:

```
Finger presses down
│
├─ mmi_service (multimodal interaction service)
│  └─ Forwards immediately to the application main thread (DispatchTouchEvent, type=0)
│
├─ Finger slides (move events, type=2)
│  └─ Not forwarded immediately! Gated by the vsync signal, dispatched in frame rhythm:
│     mmi_service → VSyncGennerator → DVSync-app → application main thread
│
├─ TouchSlop sliding threshold
│  └─ The minimum displacement for the system to decide "sliding has started"; default 18vp
│     If the displacement does not exceed the threshold, no sliding is triggered
│
├─ First-frame one-frame delay
│  └─ Crossing the threshold triggers an update, but drawing must wait for the next frame
│     So the first frame at the start of a slide naturally waits one extra frame
│
└─ Rendering and presentation
   └─ 1.ui → 1.raster → render_service → RSUniRenderThread → RSHardwareThread → screen display
```

### 2.2 The Standard Definition of Sliding Response Latency

**Sliding response latency = from the finger-press trace in mmi_service → to the end of the first sliding frame's rendering in RSHardwareThread**

This is the definition used for externally reported figures under the Huawei application experience quality standards. Flutter-side instrumentation can only measure part of it; the data counts only after the two sides are aligned.

### 2.3 DevEco Profiler Trace Chain Analysis

After capturing a trace with DevEco Profiler, favorite the following 11 threads in order, and you can follow any frame's full chain from touch to presentation:

```
VSyncGennerator → DVSync-app → mmi_service → application main thread
→ 1.ui → 1.raster → DVSync-rs → render_service
→ RSUniRenderThread → RSHardwareThread → dpu_gfx_primary
```

Two identifiers for tracing frames across processes:
- `frame_number`: links 1.ui ↔ 1.raster
- `ReuseBuffer / acquire buffer`: links 1.raster ↔ render_service

> **Beginner tip**: Why must "sliding response latency" be based on the trace chain? Because from finger press to pixels on screen, the event passes through system services and multiple threads — only the trace chain covers it end to end.

---

## 3. Three Core Techniques for Locating Jank

> Overall approach: **Overlay for trends (which thread turns red) → DevTools for demarcation (which stage exceeds its budget) → frame-by-frame hard evidence (exactly who)**

### 3.1 Technique A: Watch Trends with Performance Overlay (Cheapest)

One line of code turns it on, and two bar charts appear at the top of the screen:

```dart
MaterialApp(
  showPerformanceOverlay: true,  // enable the performance overlay
  home: MyApp(),
);
```

| Bar chart position | What it represents | What red means |
|-----------|---------|---------|
| **Upper** | Raster thread (GPU drawing) | Drawing too heavy (large images, blur, saveLayer) |
| **Lower** | UI thread (Dart code) | Dart code slow (build/layout/paint) |
| **Both red** | Both threads over budget | Usually a chain reaction caused by oversized rebuilds |

> **Beginner tip**: With the Overlay on, operate your app — whichever bar turns red tells you which thread has the problem.

### 3.2 Technique B: Demarcation with DevTools Performance

```bash
flutter run --profile  # You must use profile mode! Debug data is inaccurate
```

Open DevTools in a browser → the **Performance** page:

- In the **Flutter Frames** chart, frames over budget are marked red (frame drops caused by shader compilation have a dedicated marker)
- Select a frame, and the **UI** and **Raster** timelines are shown separately below
- **Whichever is longer is the one slacking off**

### 3.3 Technique C: Frame-by-Frame Evidence to Nail the Culprit

On the DevTools Performance page, enable the three **Enhance Tracing** options:

| What to enable | What you see | What to look for |
|---------|--------|--------|
| **Track Widget Builds** | Each Widget's build time | "Rebuild hogs" — Widgets that should not rebuild but do |
| **Track Layouts** | Layout time | The worst offenders in the layout stage |
| **Track Paints** | Paint time | The worst offenders in the paint stage |

> Once you have "over-budget frame + specific Widget / specific stage", the Flutter-side evidence chain is closed. If you suspect the problem lies in platform scheduling rather than Dart code, move on to the DevEco Profiler trace chain analysis in §5.

### 3.4 Other DevTools Tools

| Tool | Purpose | Best suited for |
|------|------|---------|
| **CPU Profiler** | Sampling for Dart function-level time costs | Finding the "rogue function" inside the build stage |
| **Widget Inspector → Repaint Rainbow** | Repainted areas flicker in changing colors | Whoever flickers across the whole screen is the repaint hog |

---

## 4. Common "Jank Culprits" and Fixes

### 4.1 High-Frequency Pitfalls in the Build Stage (UI Thread)

#### 🕳️ Oversized setState granularity: one change rebuilds the whole page

**Symptom**: In Track Widget Builds, the entire page's Widgets are rebuilding.

**Fix**: Push state down to the minimal scope + mark static parts `const` (see the complete demo in §7).

#### 🕳️ Missing const: the same subtree rebuilt every frame

```dart
// ❌ Every time the parent rebuilds, this static header is rebuilt along with it
Widget build(_) => Column(children: [Header(), ...]);

// ✅ const constructor: Flutter reuses the instance directly, slimming the build stage instantly
Widget build(_) => Column(children: [const Header(), ...]);
```

#### 🕳️ Doing heavy work inside build

Reading files synchronously, parsing JSON, or running complex computations inside build — build should behave like a pure function; for heavy work, go straight to `compute` (see §7 Demo 2).

### 4.2 High-Frequency Pitfalls in the Raster Stage (GPU Thread)

#### 🕳️ Clip.antiAliasWithSaveLayer

The name says it all: every clip opens a saveLayer, and the Raster thread load skyrockets. Unless absolutely necessary, use the default `Clip.antiAlias`.

#### 🕳️ Opacity in animations

```dart
// ❌ Using Opacity directly in an animation easily triggers saveLayer
Opacity(opacity: anim.value, child: heavyChild);

// ✅ Official recommendation: use FadeTransition / AnimatedOpacity
FadeTransition(opacity: anim, child: heavyChild);
```

Static translucency is even simpler: add alpha directly to the color (`const Color(0x80FFFFFF)`) — no Opacity layer needed at all.

#### 🕳️ Large-area blur and big shadows

The cost of `BackdropFilter` / `ImageFiltered` scales with the blurred area — use them only on small card-sized regions, not the whole screen.

#### 🕳️ RepaintBoundary used the wrong way

Use it to isolate locally high-frequency repaint areas (progress bars, animations) so they do not drag the whole page into repainting; but it costs memory itself — **do not wrap everything in it**.

### 4.3 High-Frequency List Pitfalls

#### 🕳️ Variable heights + no prototype

Every scroll has to measure each item's height on the spot.

```dart
// ✅ For fixed-height lists, provide itemExtent directly; for variable heights, provide a prototypeItem as a template
ListView.builder(
  itemExtent: 56,
  itemCount: data.length,
  itemBuilder: (context, i) => ItemCell(data[i]),
);
```

#### 🕳️ Building hundreds of items at once

```dart
// ❌ Everything is built
ListView(children: items.map((e) => ItemWidget(e)).toList());

// ✅ Switch to builder for lazy loading
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);
```

#### 🕳️ Synchronous IO / data reshaping inside itemBuilder

itemBuilder is called at high frequency during scrolling; only lightweight assembly is allowed inside.

### 4.4 High-Frequency Image Pitfalls

#### 🕳️ Stuffing a 4K original into a 200px card

Decoding and GPU memory both blow up — frame drops in no time.

```dart
// ✅ Decode at the display size
Image.network(url, cacheWidth: 200, cacheHeight: 200);
```

### 4.5 High-Frequency Latency Pitfalls (the Main Battlefield of Response/Completion Latency)

#### 🕳️ Synchronous heavy work on the main thread

Big JSON parsing, bulk reads/writes, and encryption/decryption all on the UI thread → the first frame after a tap arrives late outright.

**Fix**: offload with `compute` / an Isolate (see §7 Demo 2).

#### 🕳️ One-shot full build of the first screen

A new page builds hundreds of Widgets in one go — completion latency will inevitably blow up.

**Fix**: pagination / lazy loading / a skeleton screen to give a response first, with data filled in progressively.

### 4.6 Shader Compilation Jank (the Kind That Always Hitches the First Time)

**Symptom**: Every new animation / new page always drops frames the first time, and DevTools flags "Shader Compilation Jank".

**In plain terms**: In the Skia rendering pipeline, the first occurrence of certain kinds of drawing compiles a shader on the spot — like looking up a recipe the first time you cook a dish.

| Backend | How to fix it |
|------|--------|
| **Impeller** (recommended) | Precompiles shaders at engine startup — essentially a complete cure |
| **Skia** | Capture with `--cache-sksl` and bundle it for warm-up (the Flutter official documentation has the full process) |

---

## 5. How Do You Measure Latency? (Turning "Feels Janky" into Data)

### 5.1 Method 1: FrameTiming API (Self-Check During Development)

```dart
import 'package:flutter/scheduler.dart';

void startFrameWatch() {
  SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
    const budget = Duration(milliseconds: 16); // 60Hz frame budget
    for (final t in timings) {
      if (t.buildDuration > budget || t.rasterDuration > budget) {
        // Over-budget frame: you can read t.buildDuration / t.rasterDuration / t.totalSpan
        // Log or report it; accumulated, this becomes the frame drop rate
      }
    }
  });
}
```

Combine it with instrumentation to quantify latency:
- Record **t0** in the gesture callback
- Record **t1** in the first frame's `addPostFrameCallback`
- Record **t2** when the data is ready and rendering is stable

| Latency | Calculation | Plain explanation |
|------|------|---------|
| Response latency | t1 - t0 | How long from tap to reaction |
| Completion latency | t2 - t0 | How long from tap to thorough completion |

### 5.2 Method 2: System Trace Chain (the Standard for Reported Figures)

Capture a trace with **DevEco Profiler** and follow frames with the 11-thread chain in §2.3.

| Tool | Purpose | Best suited for |
|------|------|---------|
| **DevEco Profiler** | Trace analysis, hard latency evidence | In-depth analysis during development |
| **SmartPerf** (Host side / on-device SP_daemon) | Collects FPS, frame drops, CPU, etc. by bundle name | Scenario-based inspection outside the IDE; good for walkthroughs and regression archiving |

> **Latency measurement basis**: For externally reported figures, the trace chain is authoritative (`mmi_service` press → the first frame finishes rendering in `RSHardwareThread`); FrameTiming instrumentation is a development-time self-check; a high-speed camera can serve as the final arbiter.

### 5.3 Method 3: Automated Regression (Against Degradation)

```dart
testWidgets('list scroll perf', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  await tester.binding.traceAction(() async {
    await tester.fling(find.byType(Scrollable), const Offset(0, -600), 8000);
    await tester.pumpAndSettle();
  }, reportKey: 'scrolling_timeline');
});
```

After the run you get frame duration statistics (build/raster averages, P90). Feed them into CI as baseline inspection, and regressions trigger alarms directly.

---

## 6. The Prerequisite for Performance Analysis

> **All performance conclusions must be based on profile mode + a real HarmonyOS device!**

| Mode | Usable for performance analysis? | Reason |
|------|-----------------|------|
| **Debug** | ❌ No | Assertions, JIT, and extra checks make the data inaccurate |
| **Profile** | ✅ Yes | Release-level optimization + observability |
| **Release** | ⚠️ Lacks debug information | Good for production, not for analysis |

```bash
flutter run --profile  # Always use this for performance analysis
```

> Keep a **mid-to-low-end HarmonyOS real device** as your baseline — jank imperceptible on a high-end device will surface on a mid-to-low-end one.

---

## 7. Reusable Demo Snippets

### Demo 1: Whole-Page setState → Partial Refresh (Fixing Frame Drops)

```dart
// ❌ Problem: one counter change and the Header and the long list all rebuild with it
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
        HeavyHeader(),                    // Innocent bystander, rebuilt every time
        Expanded(child: HeavyList()),     // Innocent bystander ×2
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
// ✅ Fix: mutable state pushed down to the minimal subtree; static parts all made const
class GoodPage extends StatelessWidget {
  const GoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HeavyHeader(),               // const constructor, never rebuilt again
        Expanded(child: HeavyList()),
        Counter(),                   // Only this rebuilds
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
      mainAxisAlignment: MainAxisAlignment.center,
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

Retest comparison: In Track Widget Builds, the number of rebuilds per tap drops from "the whole page" to "1 subtree".

### Demo 2: First-Screen Completion Latency Explosion → compute Offload (Fixing Latency)

```dart
// ❌ Problem: big JSON parsed + mapped on the main thread; the first frame after a tap arrives noticeably late
Future<List<Item>> loadItems() async {
  final raw = await rootBundle.loadString('assets/items.json'); // big file
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Item.fromJson).toList(); // All on the UI thread
}
```

```dart
// ✅ Fix: parsing pushed down to a background Isolate; the main thread only renders
import 'package:flutter/foundation.dart'; // compute

Future<List<Item>> loadItems() async {
  final raw = await rootBundle.loadString('assets/items.json');
  return compute(_parseItems, raw); // compute requires a top-level or static function
}

List<Item> _parseItems(String raw) {
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Item.fromJson).toList();
}
```

After the fix, instrument the same scenario: **completion latency t2 - t0 falls back significantly**, and response latency is no longer dragged down by parsing.

---

## 8. A 30-Minute Hands-On Script

**Scenario**: A user reports "the list stutters when sliding"; you suspect oversized rebuilds or oversized images.

| Step | Time | What to do | What to look for |
|------|------|--------|--------|
| 1. Reproduce + watch trends | 5 min | Run the profile build on a real device, enable the Overlay, scroll endlessly | Lower UI bar red, upper one occasionally red → mainly the Dart side |
| 2. DevTools demarcation | 10 min | Record Performance with Track Widget Builds enabled | `ItemCell`'s parent rebuilds the entire tree + `Image.network` all at original size |
| 3. Fix | 10 min | Split data into standalone Widgets + `const` + `itemExtent` + image `cacheWidth/cacheHeight` | — |
| 4. Verify + report figures | 5 min | Retest the same scenario | Overlay all green, P90 back within budget, over-budget frames zeroed; capture a trace to measure response latency, archive with SmartPerf |

---

## 9. Performance Self-Check Checklist

**Dart / Flutter side**

- [ ] Is state pushed down to the minimal scope? Are static subtrees `const`?
- [ ] Any synchronous IO / parsing / complex computation inside build? Is heavy work offloaded with `compute`?
- [ ] Does the list use `builder` for lazy loading? Fixed heights given `itemExtent`, variable heights given `prototypeItem`?
- [ ] Are images decoded at display size (`cacheWidth/cacheHeight`)?
- [ ] Any `Clip.antiAliasWithSaveLayer`, animated `Opacity`, or large-area blur?
- [ ] Are locally high-frequency repaint areas isolated with `RepaintBoundary` (and not overused)?
- [ ] Is the first screen built in full? Is there a skeleton screen / pagination to give a response first?

**Engineering & environment**

- [ ] All performance conclusions are based on **profile + a real HarmonyOS device**; debug data never goes into reports
- [ ] Do core sliding / transition scenarios have dual baselines with `traceAction` + SmartPerf?
- [ ] Are there trend charts for frame drop rate, P90 frame duration, and response / completion latency?
- [ ] Is instrumentation code permanent (toggleable)? Can latency data be retrieved from production gray releases?

---

## 10. FAQ

**Q1: Debug mode is unbearably janky — is that a problem?**
Not necessarily. Debug has assertion and JIT overhead; all conclusions must be based on the profile build.

**Q2: How do the two Overlay bars divide the work?**
The upper one is the Raster (GPU) thread, the lower one is the UI thread; the chart has text labels. A red bar = over frame budget.

**Q3: DevTools flagged "Shader Compilation Jank" — how do I fix it?**
It is caused by Skia compiling shaders on first use. If your OHOS engine version supports Impeller, enable it first; on the Skia backend, warm up with `--cache-sksl`.

**Q4: How should response / completion latency be measured to count as the "standard definition"?**
Sliding response latency is based on the trace chain: mmi_service press → the first sliding frame finishes rendering in RSHardwareThread (automated tests look at `dpu_gfx_primary`); Flutter-side instrumentation (t0 touch → t1 first frame → t2 stable) is a development-time self-check. Once both sides are aligned, report using the terminology of the Huawei application experience quality standards.

**Q5: Average FPS looks quite high, but users still report jank?**
Averages hide occasional big janks. Check P90/P99 frame durations and the over-budget frame count — do not be fooled by the mean.

---

## 11. Related Documents

| Document | Related content |
|------|---------|
| [dfx-performance.en.md](dfx-performance.en.md) | Frame drop detection mechanism and HiAppEvent event parameters |
| [dfx-appfreeze.en.md](dfx-appfreeze.en.md) | Freeze issues (severe jank can escalate into a freeze) |
| [dfx-memory.en.md](dfx-memory.en.md) | Jank caused by GPU context loss |
| [dfx-texture.en.md](dfx-texture.en.md) | Jank caused by slow external texture consumption |
| [dfx-logging.en.md](dfx-logging.en.md) | HiTrace capture methods |

---

## 12. References and Further Reading

- Flutter official performance overview and best practices (docs.flutter.dev/perf, docs.flutter.dev/perf/best-practices)
- DevTools Performance view usage guide (docs.flutter.dev/tools/devtools/performance)
- Impeller rendering engine (docs.flutter.dev/perf/impeller)
- FrameTiming API (api.flutter.dev, scheduler library)
- HarmonyOS trace-level deep dives (three companion articles, flutter_samples/docs/ohos/performance):
  - [Performance Analysis: Sorting the Thread Sequence](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-analysis-threads-sequence.md)
  - [Performance Analysis: Frame Rendering Tracing](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-frame-rendering-tracking.md)
  - [Performance Analysis: Swipe Response Latency](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-sliding-response-time.md)
- SmartPerf performance testing tool usage guide (Huawei Developer website / OpenHarmony official documentation)
- DevEco Profiler performance analysis guide (developer.huawei.com)
- Huawei application experience quality standards: response latency / completion latency terminology definitions (developer.huawei.com)
