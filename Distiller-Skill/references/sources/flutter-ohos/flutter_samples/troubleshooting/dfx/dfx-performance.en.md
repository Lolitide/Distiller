# Performance Jank and Frame Drop Locating Guide

> Back to [README.en.md](README.en.md)

> This document focuses on locating frame drops from the **DFX event level** (HiAppEvent / HiLog).
> For in-depth methods such as DevTools Performance analysis, FrameTiming instrumentation, and trace-chain latency measurement, see [dfx-jank-latency.en.md](dfx-jank-latency.en.md).

---

## 1. What Is a Frame Drop?

### 1.1 Plain-Language Explanation

Flutter aims to draw 60 pictures per second (60 frames), which means each picture must be finished within **16.6 milliseconds**. If one picture takes too long — over 16.6 milliseconds — the display "stutters". This is a "frame drop" (JANK).

> **An analogy**: It is like a flipbook — you need to flip 60 pages per second for the animation to look smooth. If one page takes you 50 milliseconds to flip, the animation "hitches".

If the device supports 120 frames (high refresh rate), each frame must be completed within **8.3 milliseconds** — an even tighter requirement.

### 1.2 Two Frame Drop Scenarios

| Scenario | Trigger condition | Corresponding event | Plain-language explanation |
|------|---------|---------|---------|
| **Scroll jank** | A frame takes ≥50ms during scrolling | `OTHER_JANK_SCROLL` | Stutter while a list is scrolling |
| **Non-scroll frame drop** | Frame rendering exceeds the target time | `OTHER_JANK` + `OTHER_JANK_STAT` | Jank in ordinary scenarios (animations, page transitions, etc.) |

> **Tip for beginners**: Scroll jank is reported only when a single frame reaches ≥50ms. If scrolling feels janky but no event is found, each frame may be <50ms yet consistently >16ms — capture a trace for analysis.

### 1.3 Typical Symptoms

| What you see | Severity | Possible cause |
|-------------|---------|-----------|
| Stutter while scrolling a list | Medium | Scroll jank |
| Choppy page transition animations | Medium | Non-scroll frame drop |
| Occasional hitch followed by recovery | Low | Sporadic frame drop |
| Persistent jank with no recovery | High | Continuous frame dropping |
| Animation plays in stutters | Medium | Slow frame rendering |
| Jank accompanied by black/white screen | High | GPU context loss |
| Janky video/camera picture | Medium | External texture consumed too slowly |

### 1.4 Quick Locating Flow

```
Janky / non-smooth UI
│
├─ Search the log for "OTHER_JANK_SCROLL"
│  → Scroll jank (a frame ≥50ms during scrolling)
│
├─ Search the log for "OTHER_JANK" or "OTHER_JANK_STAT"
│  → Non-scroll frame drop
│
├─ Search the log for "GpuReclaim"
│  → Check whether it is accompanied by GPU reclaim
│
├─ Search the log for "skip one frame"
│  → Check whether texture consumption is too slow
│
└─ Capture HiTrace for detailed analysis
   → Search for "Flutter Lost Frames" and "Flutter Hitch Time"
```

---

## 2. Frame Drop Detection Mechanism (How Does the Engine Know a Frame Was Dropped?)

### 2.1 Detection Flow

```
After each frame is drawn
│
├─ Calculate: how long did this frame take? (frame_duration = end time - start time)
│
├─ Did it exceed the target time? (>16.6ms or >8.3ms)
│  ├─ No → normal frame, ignore it
│  └─ Yes → frame dropped! Record it
│
├─ Is scrolling happening right now?
│  ├─ Yes → if this frame is ≥50ms, report OTHER_JANK_SCROLL
│  │           if it is <50ms, ignore it (output the "Ignore scroll jank" log)
│  └─ No → buffer it (at most 10 frames)
│     ├─ Buffer reaches 10 frames → report OTHER_JANK + OTHER_JANK_STAT in batch
│     └─ Not full → keep buffering
│
└─ Also output HiTrace (recording frame drop details)
```

### 2.2 Scroll Jank Threshold

In scrolling scenarios, a report is made only when a single frame takes **≥50ms**; frames under 50ms are ignored:

```bash
# Ignored frame drops appear in the log
I Flutter: Ignore scroll jank: frameCost=30000us (<50ms)
```

> 30,000 microseconds = 30 milliseconds, which is below 50ms, so it was ignored. But 30ms already exceeds the 16.6ms frame budget, so the user may still perceive jank.

---

## 3. How to Locate Frame Drop Issues?

### 3.1 Locate via Logs

**Search command**:
```bash
hdc shell hilog | grep -E "OTHER_JANK|JANK|jank|missed"
```

**Key logs**:

| Log keyword | Meaning | When it appears |
|-----------|------|------------|
| `ReportScrollJANKEvent` | Scroll jank report | A frame takes ≥50ms during scrolling |
| `ReportJANKEvent` | Non-scroll frame drop report | When a non-scroll frame drop occurs |
| `Ignore scroll jank: frameCost=Xus (<50ms)` | Scroll jank ignored | Scroll jank below 50ms |
| `Vector stops push_back` | Frame drop buffer full (10 frames) | More than 10 consecutive dropped frames |
| `skip one frame(slow consumer)` | Frame skipped due to slow consumption | External texture scenarios |

### 3.2 Locate via HiAppEvent

| Event | Meaning | Key parameter to check |
|------|------|-------------|
| `OTHER_JANK` | Single frame drop details | `missedFrames` (how many frames were dropped) |
| `OTHER_JANK_STAT` | Aggregated statistics | `maxFrameTime` (how long the worst frame took) |
| `OTHER_JANK_SCROLL` | Scroll jank | `totalMissedFrames` / `totalFrames` (frame drop rate) |

### 3.3 Locate via HiTrace (Most Detailed)

```bash
# Capture a 30-second trace (reproduce the jank within those 30 seconds)
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# Open chrome://tracing in Chrome → Load the file
```

**Search the trace for these keywords**:

| Search keyword | What to look at |
|-----------|--------|
| `flutter::Frame` | How long each frame took (anything over 16ms is a dropped frame) |
| `Flutter Lost Frames` | Frame drop count (value = number of dropped frames) |
| `Flutter Hitch Time` | Frame drop details (frame number, duration, cause) |
| `feedFlutterWatchdog` | UI thread heartbeat (check whether it is stuck) |

### 3.4 Analyze with DevTools Performance (Most Intuitive)

```bash
flutter run --ohos
# Open DevTools in a browser → Performance tab
# Click record → reproduce the jank → stop
# Red frames are dropped frames; click one to see exactly which step is slow
```

---

## 4. Frame Drop Analysis

> **In-depth analysis**: This section lists common causes and quick fixes. To pinpoint "which Widget and which stage is slow" frame by frame with tools such as DevTools Performance Overlay / Track Widget Builds / CPU Profiler, see [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §3 "Three Core Techniques for Locating Jank".

### 4.1 Assess Frame Drop Severity

| Metric | Normal | Slight jank | Severe jank | User-perceptible |
|------|------|---------|---------|------------|
| Single frame duration | <16ms | 16-50ms | >50ms | >50ms |
| Dropped frames | 0 | 1-3 frames | >3 frames | >5 frames |
| Frame drop rate | <5% | 5-10% | >10% | >15% |

### 4.2 Common Frame Drop Causes and Fixes

#### Cause 1: Dart Code Executes Too Slowly

**Plain-language explanation**: Your `build()` method does too much work, so a frame cannot be completed in time.

**How to confirm**: Search for `flutter::Frame` in HiTrace and check whether the UI thread portion of the frame takes long.

**Common cases and fixes**:

| Case | How to fix | Code example |
|------|--------|---------|
| Widget tree too complex | Split widgets, use more `const` | `const Text('hello')` instead of `Text('hello')` |
| Rebuild every frame | Limit the rebuild scope | Use `shouldRepaint` / `shouldRebuild` |
| Heavy computation on the main thread | Move it to an isolate with `compute()` | `final result = await compute(heavyTask, data);` |
| Layout hierarchy too deep | Simplify the layout and fix sizes with `SizedBox` | `SizedBox(height: 80, child: ...)` |

**Code example**:
```dart
// ❌ Wrong: creates new objects every frame, causing rebuilds
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return Container(
      color: Colors.blue,  // A new object is created on every build
      child: Text('Item $index'),
    );
  },
);

// ✅ Correct: optimized with const and itemExtent
ListView.builder(
  itemExtent: 80.0,  // Fixed height; the engine does not need to measure each item
  itemCount: 1000,
  itemBuilder: (context, index) => const _ItemTile(),  // const Widget
);
```

#### Cause 2: GPU Rendering Is Too Slow

**Plain-language explanation**: The Dart code runs fast (build completes), but the GPU draws too slowly.

**How to confirm**: In HiTrace, check whether the Raster portion of `flutter::Frame` takes long.

| Case | How to fix |
|------|--------|
| Images too large | Limit the decode size with `cacheWidth`/`cacheHeight` |
| Too many layers | Reduce the number of layers, isolate with `RepaintBoundary` |
| Slow shader compilation | Warm up shaders (SkSL warmup) |
| Heavy blur effects | Reduce the scope of `BackdropFilter` usage |
| Overdraw | Isolate complex areas with `RepaintBoundary` |

**Code example**:
```dart
// ❌ Wrong: loading a 4000x3000 image is slow to decode
Image.network(url)

// ✅ Correct: limit the decode size
Image.network(
  url,
  cacheWidth: (screenWidth * devicePixelRatio).toInt(),
  cacheHeight: (screenHeight * devicePixelRatio).toInt(),
)

// ✅ Isolate complex areas with RepaintBoundary (avoids repeated painting)
RepaintBoundary(
  child: ComplexWidget(),
)
```

#### Cause 3: Resource Loading Blocks build

**Plain-language explanation**: You load resources directly inside the `build()` method, blocking UI construction.

```dart
// ❌ Wrong: synchronous loading inside build
Widget build(BuildContext context) {
  final data = loadAssetSync();  // Blocks build!
  return Text(data);
}

// ✅ Correct: load asynchronously
@override
void initState() {
  super.initState();
  _loadData();  // Load asynchronously
}

Future<void> _loadData() async {
  final data = await rootBundle.loadString('assets/data.json');
  setState(() => _data = data);
}
```

#### Cause 4: Memory Pressure Causes Frequent GC (Garbage Collection)

**Plain-language explanation**: You create too many temporary objects, so Dart's garbage collector starts frequently, and every GC pauses the UI thread.

**How to confirm**: Search for `heap memory` to check memory usage (see [dfx-memory.en.md](dfx-memory.en.md) §2).

**How to fix**:
- Reduce temporary objects created in `build()`
- Use `const` constructors more
- Limit the `ImageCache` size
- Reuse objects instead of creating them repeatedly

#### Cause 5: GPU Context Loss

**Plain-language explanation**: When the app goes to the background, GPU resources are reclaimed; frame rendering is interrupted during the rebuild after returning to the foreground.

**How to confirm**: Search for the `GpuReclaim` log (see [dfx-memory.en.md](dfx-memory.en.md) §3).

#### Cause 6: External Texture Consumed Too Slowly

**Plain-language explanation**: Video/camera produce frames faster than Flutter can consume them, so frames are forcibly skipped.

**How to confirm**: Search for `skip one frame(slow consumer)` (see [dfx-texture.en.md](dfx-texture.en.md) §4).

### 4.3 Scroll Jank Deep Dive

#### Step 1: Calculate the frame drop rate

Take `totalMissedFrames` and `totalFrames` from the `OTHER_JANK_SCROLL` event:

```
Frame drop rate = totalMissedFrames / totalFrames
```

| Frame drop rate | Severity | User perception |
|--------|---------|---------|
| <5% | Normal | Imperceptible |
| 5-10% | Slight | Occasional stutter |
| 10-30% | Noticeable | Clear jank |
| >30% | Severe | Seriously hurts the experience |

#### Step 2: Look at the worst frame

`maxFrameTime` tells you how long the worst frame took:

| maxFrameTime | Severity |
|-------------|---------|
| <16ms | Normal |
| 16-50ms | Slight |
| 50-100ms | Noticeable jank |
| >100ms | Severe jank |

#### Step 3: Capture a trace for analysis

```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
```

After opening it in Chrome:
1. Search for `flutter::Frame` to find frames with long durations
2. Expand the frame event to see whether the UI thread or the Raster thread is slow
3. Search for `Flutter Hitch Time` to see frame drop details

---

## 5. HiAppEvent Event Parameters

### 5.1 OTHER_JANK (Single Frame Drop)

| Parameter | Description | How to use it |
|------|------|--------|
| `missedFrames` | How many frames were dropped | 1-3 slight, >3 severe |
| `startTime` / `endTime` | Time range of the frame drop | Pinpoint when it happened |

### 5.2 OTHER_JANK_STAT (Aggregated Statistics)

| Parameter | Description | How to use it |
|------|------|--------|
| `totalMissedFrames` | Total frames dropped | Total frame drop volume |
| `maxFrameTime` | How long the worst frame took (milliseconds) | >50ms means severe jank |
| `maxMissedFrameRate` | The corresponding frame rate | 60/120 is normal; lower values mean the frame rate target was not met |

### 5.3 OTHER_JANK_SCROLL (Scroll Jank)

| Parameter | Description | How to use it |
|------|------|--------|
| `maxFrameTime` | How long the worst frame took | >50ms is user-perceptible |
| `totalMissedFrames` | Frames dropped during scrolling | Combine with totalFrames to compute the frame drop rate |
| `totalFrames` | Total frames during scrolling | Compute the frame drop rate |
| `recentScrollCount` | Number of scrolls since the last report | 1 = every scroll drops frames |
| `frameId` | Frame number of the worst drop | Locate the specific frame in the trace |

---

## 6. Troubleshooting Checklist

### Step 1: Confirm the frame drop

- [ ] Capture full logs: `hdc shell hilog > flutter_log.txt`
- [ ] Search for `OTHER_JANK_SCROLL` → scroll jank
- [ ] Search for `OTHER_JANK` / `OTHER_JANK_STAT` → non-scroll frame drop
- [ ] Check `maxFrameTime` to determine severity
- [ ] Calculate the frame drop rate (`totalMissedFrames` / `totalFrames`)

### Step 2: Find the cause

- [ ] Search for `GpuReclaim` → caused by GPU reclaim?
- [ ] Search for `skip one frame` → texture consumed too slowly?
- [ ] Search for `heap memory` → GC caused by memory pressure?
- [ ] Check whether the Dart code runs heavy computation / synchronous IO on the main thread
- [ ] Check whether Widgets rebuild excessively

### Step 3: Trace analysis

- [ ] Capture a trace: `hdc shell hitrace --trace_clock boottime -t 30 flutter`
- [ ] Search for `flutter::Frame` to analyze per-frame durations
- [ ] Distinguish between a slow UI thread and a slow Raster thread
- [ ] Search for `Flutter Lost Frames` to see the frame drop distribution

### Step 4: DevTools analysis

- [ ] Record the janky scenario with DevTools Performance
- [ ] Inspect red frames (dropped frames)
- [ ] Analyze build/layout/paint durations in the Timeline

---

## 7. HiTrace Analysis Tips

### 7.1 Open the Trace File

1. Pull the `.ftrace` file to your computer
2. Open Chrome and visit `chrome://tracing`
3. Click `Load` to load the file
4. Shortcuts: `w` zoom in, `s` zoom out, `a` pan left, `d` pan right

### 7.2 Which Keywords to Search For?

| Search keyword | What to look at | Normal behavior |
|-----------|--------|---------|
| `flutter::Frame` | Duration of each frame | <16ms |
| `Flutter Lost Frames` | Frame drop count | Value is 0 |
| `Flutter Hitch Time` | Frame drop details | Does not appear |
| `feedFlutterWatchdog` | UI heartbeat | Once every 3 seconds |

### 7.3 Analyze Frame Durations

1. Search for `flutter::Frame`
2. Look at the duration of each Frame event
3. Anything over 16ms is a dropped frame
4. Expand the frame event to see which part is slow:

| Which part is slow | Diagnosis | How to optimize |
|---------|------|---------|
| UI thread (build/layout/paint) | Slow Dart code | Optimize Widget builds, reduce rebuilds |
| Raster thread | Slow GPU rendering | Optimize images, simplify layers |
| Both slow | Combined problem | Optimize the UI thread first, then the Raster thread |

### 7.4 API Version Impact

| API version | Trace capability |
|---------|-----------|
| < 19 | Drop count only, no details |
| ≥ 19 | Both count and details (recommended) |
