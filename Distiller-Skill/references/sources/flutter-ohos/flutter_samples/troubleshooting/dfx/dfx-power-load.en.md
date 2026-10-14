# Load Anomaly and Power Consumption Issue Locating Guide

> Back to [README.en.md](README.en.md)

> When users say "my phone is burning hot", "the battery drains fast", or "it keeps consuming power in the background", the app is most likely consuming CPU continuously.
> This document walks you through the complete path from "it feels hot/janky" to "hard evidence of the hot spot": process and threads → hiperf sampling → flame graph → optimization.

---

## 1. What Are Load Anomalies and Power Consumption Issues?

### 1.1 Plain-Language Explanation

A running Flutter app consumes CPU, just as a car burns fuel. Normally, an app consumes CPU only when it needs to refresh the screen or handle interaction; when the screen is static, the CPU should idle. A **load anomaly** means the CPU stays highly occupied; a **power consumption issue** means this sustained high usage causes heat and battery drain.

> **An analogy**: A car waiting at a red light should idle (low CPU usage). If your car is flooring the gas at a red light (CPU usage stays high), it both wastes fuel (drains power) and overheats (gets hot).

### 1.2 Two Problem Scenarios

| Scenario | Trigger condition | Plain-language explanation | Troubleshooting difficulty |
|------|---------|---------|---------|
| **High foreground load** | A process keeps occupying CPU while the app is in the foreground | Gets hot while in use, possibly with jank | Finding "which thread is busy, and which code it is busy in" |
| **Abnormal background power consumption** | The app still wakes up frequently / runs tasks after going to the background | Battery drains fast even though the app is not open | Capturing "what is still running in the background and how often it wakes up" |

> **Tip for beginners**: High foreground load and jank often appear together (CPU saturated → frames cannot be drawn → frame drops). If you have already ruled out slow single Dart/GPU frames while troubleshooting frame drops (see [dfx-performance.en.md](dfx-performance.en.md)), suspect "sustained high load" dragging down the whole app.

### 1.3 Typical Symptoms

| What you see | Severity | Possible cause |
|-------------|---------|-----------|
| Phone gets hot (especially after the app runs for a while) | Medium | Sustained high-frequency repaints / background polling |
| Battery drains fast | Medium | Background tasks not paused / high-frequency timers |
| The app gets jankier with use | Medium | Frequent GC (excessive object creation) + CPU hot spots |
| Generally janky list scrolling (not occasional stutter) | Medium | Sustained hot CPU paths during scrolling |
| CPU usage does not fall back on a static page | High | Repaints continue while idle / background thread busy-polling |
| System kills the app in the background due to power consumption | High | App reclaimed by the system for exceeding background power limits |

### 1.4 Quick Locating Flow

```
App gets hot / drains power / sustained high CPU
│
├─ Confirm which process is consuming CPU
│  → hdc shell top -H -p {pid}, find the high-frequency thread
│
├─ Confirm whether it is triggered in the foreground or the background
│  → Foreground: check for continuous repaints / heavy computation
│  → Background: check for timers / polling / animations that never stopped
│
├─ Capture instruction-count samples with hiperf
│  → hdc shell hiperf record -e hw-instructions ...
│
├─ Generate a flame graph and find the function that keeps widening at the top
│  → Width = share of sampling time; the wider, the hotter
│
└─ Cross-reference HiTrace / HiLog / HiAppEvent
   → Check whether frame drop events accompany it, whether there is background trace
```

---

## 2. Common Data Capture Methods

### 2.1 Process and Thread Information

First confirm whether the target process continuously occupies CPU:

```bash
# Find the Flutter app process
hdc shell ps -A | grep flutter

# Per-thread CPU usage (replace {pid} with the PID obtained in the previous step)
hdc shell top -H -p {pid}
```

If there is a clearly high-frequency thread, focus on:

| What to check | Description |
|--------|------|
| Whether the UI thread is blocked | A blocked UI thread usually does not show high CPU, but heavy computation does |
| Whether Raster / GPU-related threads stay highly occupied | Sustained high usage usually means the screen keeps repainting |
| Whether a background thread is busy-polling | For example, repeatedly checking state inside while(true) |
| Whether a thread wakes up frequently with no real business benefit | Timer/polling intervals too short; the CPU is woken up frequently |

> **Tip for beginners**: In `top -H`, the `-H` flag expands by thread. If a thread's CPU usage stays above 30% (while the app is not refreshing the screen), you can basically pin it down.

### 2.2 CPU Instruction Count Capture (hiperf)

On the OHOS platform, `hiperf` can capture the CPU instruction count of a single process, which is well suited to locating "which paths keep consuming CPU".

```bash
# Capture a 30-second instruction-count sample (reproduce the problem within those 30 seconds)
hdc shell "hiperf record -e hw-instructions -p {pid} -f 1000 -d 30 -o /data/local/tmp/perf.data"

# Pull the sample data to your computer
hdc file recv /data/local/tmp/perf.data
```

| Parameter | Meaning |
|------|------|
| `-e hw-instructions` | Uses the hardware instruction count as the sampling event (whoever executes the most instructions is the hot spot) |
| `-p {pid}` | Samples only this process |
| `-f 1000` | Sampling frequency 1000Hz (1000 samples per second) |
| `-d 30` | Capture duration 30 seconds |
| `-o /data/local/tmp/perf.data` | Output path on the device |

Recommended capture scenarios:

- List sliding/scrolling (sustained interaction scenarios)
- Complex animations/page transitions (burst high-load scenarios)
- The idle state after staying on a page for a long time (verify whether idle is truly idle — the key scenario for catching power issues)

### 2.3 Sample Data Processing and FlameGraph Analysis

After capturing `perf.data`, convert the data into an analyzable stack format, then generate a flame graph:

```bash
# Using the perf/FlameGraph toolchain as an example
perf script -i perf.data > perf.stacks
stackcollapse-perf.pl perf.stacks > perf.folded
flamegraph.pl perf.folded > perf.svg
```

Open `perf.svg` in a browser to see the flame graph.

> **Tip for beginners**: What is a flame graph? It draws the time each function takes during the program's run as layers of "flames"; **horizontal width = the number of times the function was sampled (that is, its share of time)**. The wider the "block", the bigger the hot spot — find the widest one and you have basically locked onto the culprit.

### 2.4 HiTrace / HiLog / HiAppEvent Cross-Checking

CPU usage alone is not enough; combine trace and logs to determine "what the app was actually doing during this period":

```bash
# Capture a trace (30 seconds recommended while reproducing the problem scenario)
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace
```

Log capture:

```bash
hdc shell hilog | grep -Ei "jank|frame|flutter|cpu|power"
```

How to cross-reference:

| Data source | What to look at | Cross-reference conclusion |
|--------|--------|-------------|
| `top -H` | Which thread has high CPU | Locks onto the thread |
| `hiperf` flame graph | The thread's hot functions | Locks onto the code path |
| HiTrace | Whether frames were being drawn during this period | Frames present → foreground repaints; no frames → sneaky background work |
| HiLog | Whether frame drop/texture events occurred | Accompanied by `OTHER_JANK` → fluency already affected |

---

## 3. How to Interpret High CPU Load and Abnormal Power Consumption

### 3.1 What to Look for in the Flame Graph

The core of a flame graph is "**width = share of sampling time**". Focus on:

| What to look at | Description | How to read it |
|--------|------|--------|
| Which function keeps widening at the top of the flame graph | Top = the function actually executing | The widest block is the hot spot |
| Which stack paths recur | Recurring = the same kind of operation executed at high frequency | Look for repeated call stack patterns |
| Whether the same kind of operation is executed repeatedly | For example, build/layout triggered repeatedly | Follow the stack down to find the root cause |

> **Common pitfall**: Functions that widen at the top of the flame graph are often the "result" rather than the "cause". For example, if `decodeImage` is at the top, follow the stack down to find who calls it repeatedly — perhaps `build` re-decodes via `Image.network` every frame. **Fix the root cause, not the symptom.**

### 3.2 Typical Signals of Abnormal Power Consumption

Typical signals of abnormal power consumption in Flutter apps:

| Signal | How to spot it | Plain-language explanation |
|------|---------|---------|
| The page repaints frequently while idle | Continuous build/paint in the flame graph; frames never stop in the trace | The screen has not changed, yet the engine keeps drawing |
| Background tasks are not paused | `top -H` still shows a high-frequency thread after going to the background | The app is in the background, yet still working |
| Continuous polling or high-frequency timers exist | timer/poll stacks recur in the flame graph | Wakes up every few tens of milliseconds, preventing deep CPU sleep |

---

## 4. Common Hot Spots on the Flutter Side

### 4.1 High Load on the Dart Side (UI Thread)

| Hot spot | Plain-language explanation | How to spot it |
|------|---------|---------|
| Heavy computation / object creation inside `build` | Heavy work every frame | The flame graph top keeps widening toward build |
| Too many list items built, frequent rebuilds | Rebuilds hundreds of Widgets on every scroll | Track Widget Builds (see [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §3) |
| JSON parsing / image processing / complex layout measurement on the UI thread | Synchronous heavy work blocks the main thread | `jsonDecode` / `decodeImage` etc. appear in the flame graph |

```dart
// ❌ Wrong: heavy computation inside build, runs every frame
Widget build(BuildContext context) {
  final result = heavyCalc(data);   // Computed on every build
  return Text('$result');
}

// ✅ Right: move heavy work out of build and cache the result
class _MyState extends State<MyWidget> {
  late final int _result;

  @override
  void initState() {
    super.initState();
    _result = heavyCalc(data);      // Computed only once
  }

  @override
  Widget build(BuildContext context) => Text('$_result');
}
```

### 4.2 Rendering and Drawing Hot Spots (Raster Thread)

| Hot spot | Plain-language explanation | How to spot it |
|------|---------|---------|
| `CustomPainter` / `Canvas` too complex | Too much, too complex drawing per frame | Raster thread CPU stays high |
| Excessive repaints, over-occlusion, too many layers | The same pixel is drawn several times | Repaint Rainbow flickers across the screen (see [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §3.4) |
| Animations triggering repaints constantly | The animation keeps running and the screen keeps repainting | paint stacks appear continuously in the flame graph |

> **Tip for beginners**: If the app should have no animation at all (for example, a static page) yet the Raster thread stays highly occupied, it is almost certainly "ineffective repaints" — some Widget keeps rebuilding/repainting. See §5.1 for fixes.

### 4.3 Images, Textures, and Resource Management

| Hot spot | Plain-language explanation | Related document |
|------|---------|---------|
| Large images decoded without scaling/caching | A 4K image crammed into a 200px card — decoding explodes | [dfx-performance.en.md](dfx-performance.en.md) §4.2 |
| The same image decoded repeatedly or loaded frequently | Cache is bypassed; re-decoded every frame | [dfx-memory.en.md](dfx-memory.en.md) |
| Textures not released promptly on page switches | Video/camera textures keep producing frames after leaving the page | [dfx-texture.en.md](dfx-texture.en.md) |

---

## 5. Common Optimization Advice

### 5.1 Reduce Ineffective Rendering (Fixing High Foreground Load)

Ineffective rendering = the screen keeps repainting even though nothing changed; it is the most common cause of high foreground load.

```dart
// ❌ Wrong: the static subtree rebuilds with its parent every frame
Widget build(_) => Column(children: [Header(), ...]);

// ✅ Right: const constructor; Flutter reuses the instance directly
Widget build(_) => Column(children: [const Header(), ...]);
```

| Technique | Effect | Code example |
|------|------|---------|
| `const` constructors | Static subtrees do not rebuild | `const Header()` |
| `ValueKey` | Precisely control which Widgets need updating | `ItemCell(e, key: ValueKey(e.id))` |
| `RepaintBoundary` | Isolate high-frequency repaint areas from dragging the whole page | `RepaintBoundary(child: AnimatedThing())` |
| Reduce complex drawing/relayout during scrolling | Give lists `itemExtent` / `prototypeItem` | See [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §4.3 |
| Use lighter implementations for high-frequency animations | Do not animate `Opacity`; use `FadeTransition` | See [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §4.2 |

> **Common pitfall**: `RepaintBoundary` itself consumes memory — **do not wrap the screen with it everywhere**. Only wrap areas of "localized high-frequency repainting" (progress bars, animations, refresh indicators).

### 5.2 Reduce Background and Idle Power Consumption (Fixing Background Power Drain)

The core of background power consumption: **when the app is not visible, everything that should stop must stop**.

| Technique | Plain-language explanation | Code approach |
|------|---------|---------|
| Pause animations and resource refreshes when the page is not visible | If nobody is watching, do not draw | Listen to `WidgetsBindingObserver.didChangeAppLifecycleState`; stop animations when `paused` |
| Release unnecessary textures and graphics resources when going to the background | Stop video when it leaves the screen | See [dfx-texture.en.md](dfx-texture.en.md) §6 |
| Prevent timers/polling from running continuously in the background | Do not run `Timer.periodic` in the background | `timer.cancel()` when `paused`; recreate when `resumed` |
| Apply visibility control to WebView / PlatformView | Embedded web content should stop too | Listen for visibility-area callbacks |

```dart
// ✅ Listen for foreground/background switches and pause/resume promptly
class _MyPageState extends State<MyPage> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();   // Stop as soon as it goes to the background
    } else if (state == AppLifecycleState.resumed) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _poll() { /* ... */ }

  @override
  Widget build(BuildContext context) => /* ... */;
}
```

### 5.3 Optimize Image and Resource Loading

| Technique | Effect | Code example |
|------|------|---------|
| Use appropriately sized images | Do not make the engine decode oversized images | `Image.network(url, cacheWidth: 200, cacheHeight: 200)` |
| Cache and preload large images | Avoid repeated decoding | Use `precacheImage` |
| Avoid heavy decoding on the UI thread | Move decoding to an isolate | `compute(_decode, data)` |
| Release image objects and textures no longer in use | Prevent leaking both memory and CPU | `dispose` when leaving the page / clear the `ImageCache` |

See [dfx-performance.en.md](dfx-performance.en.md) §4.2 and [dfx-memory.en.md](dfx-memory.en.md) for details.

### 5.4 Reduce Cross-Language Call Overhead

| Technique | Effect |
|------|------|
| Merge frequent plugin calls | Combine 10 MethodChannel calls into 1 batched call |
| Move heavy computation or IO to a background thread/Isolate | The main thread only renders; offload heavy work with `compute` |

```dart
// ❌ Wrong: each item in the list makes its own native call
for (final e in items) {
  await platform.invokeMethod('fetch', e.id);
}

// ✅ Right: one batched request
final all = await platform.invokeMethod('fetchBatch', items.map((e) => e.id).toList());
```

---

## 6. Troubleshooting Checklist

### Step 1: Confirm the load anomaly

- [ ] `hdc shell ps -A | grep flutter` to find the target process
- [ ] `hdc shell top -H -p {pid}` to see which thread has high CPU
- [ ] Confirm whether it is triggered in the foreground, in the background, or by foreground/background switching
- [ ] Check whether the reproduction steps are stable

### Step 2: Sample and locate hot spots

- [ ] Capture an instruction-count sample with `hiperf record -e hw-instructions -p {pid} -d 30`
- [ ] Generate a flame graph (`perf script` → `stackcollapse-perf.pl` → `flamegraph.pl`)
- [ ] Check whether the top of the flame graph converges consistently on one function/stack path
- [ ] Check whether there is an obvious hot CPU path

### Step 3: Cross-reference

- [ ] Capture HiTrace to see whether frames were being drawn during this period (foreground repaints / sneaky background work)
- [ ] Capture HiLog to see whether `OTHER_JANK` / texture events accompany it
- [ ] Check whether CPU usage still does not fall on a static page (verifies whether there are ineffective repaints)

### Step 4: Targeted optimization

- [ ] High foreground load: `const` / `RepaintBoundary` / lazy list loading / decode images at the right size
- [ ] Background power: listen for foreground/background switches, pause animations/timers/polling, release textures
- [ ] Cross-language calls: merge plugin calls, offload heavy work with `compute`
- [ ] Re-test to verify: flame graph hot spots gone, `top -H` usage falls back, power metrics meet targets

---

## 7. Related Documents

| Document | Related content |
|------|---------|
| [dfx-performance.en.md](dfx-performance.en.md) | Frame drop detection mechanism — excessive load evolves into frame drops |
| [dfx-jank-latency.en.md](dfx-jank-latency.en.md) | DevTools / FrameTiming / trace-chain analysis methods (a powerful tool for locating hot functions) |
| [dfx-memory.en.md](dfx-memory.en.md) | Jank caused by frequent GC, GPU context loss |
| [dfx-texture.en.md](dfx-texture.en.md) | Background power consumption caused by unreleased video/camera textures |
| [dfx-logging.en.md](dfx-logging.en.md) | HiLog / HiTrace capture methods |
| [README.en.md](README.en.md) | Return to the navigation to choose another issue type |

---

## 8. References and Further Reading

- Flutter official performance overview and best practices (docs.flutter.dev/perf, docs.flutter.dev/perf/best-practices)
- DevTools Performance view user guide (docs.flutter.dev/tools/devtools/performance)
- hiperf / FlameGraph toolchain usage (OpenHarmony official documentation)
- SmartPerf performance testing tool user guide (Huawei developer website / OpenHarmony official documentation)
- DevEco Profiler performance analysis guide (developer.huawei.com)
- Huawei app experience quality standards: power-related terminology definitions (developer.huawei.com)
