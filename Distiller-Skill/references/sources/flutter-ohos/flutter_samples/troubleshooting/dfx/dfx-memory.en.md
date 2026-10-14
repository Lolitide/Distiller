# Memory and GPU Issue Locating Guide

> Back to [README.en.md](README.en.md)

---

## 1. Issue Types

This document covers the following issues:

| Issue | What you see | Log keyword | Plain-language explanation |
|------|------------|-----------|---------|
| **Dart memory limit exceeded** | App jank, OOM crash | `Dart heap memory usage exceeds threshold` | Your Dart code used too much memory (>1.5GB) |
| **GPU context loss** | Black screen, white screen, rendering anomalies | `GpuReclaim` | The system reclaimed GPU resources when the app went to the background |
| **Engine lifecycle anomaly** | Engine create/destroy anomalies | `FLUTTER_ENGINE_CREATE/DESTROY` | The engine was not created properly or was destroyed unexpectedly |
| **Vsync pipeline failure** | No rendering, janky rendering | `vsync` / `Poll error` | Something went wrong with the vertical sync signal |

---

## 2. Dart Memory Limit Exceeded

### 2.1 Plain-Language Explanation

The Flutter engine checks every 10 seconds how much memory the Dart code is using. If it exceeds **1.5GB**, it raises an alarm and writes it to the log.

> **An analogy**: It is like your home water meter — it reads consumption every 10 seconds and alarms if usage exceeds 1.5 tons.

| Parameter | Value | Description |
|------|-----|------|
| Threshold | 1.5 GB (1536 MB) | An alarm is raised above this value |
| Check interval | 10 seconds | Checked every 10 seconds |
| Trigger count | Single-shot | Monitoring stops after one alarm |

> **Note**: 1.5GB is the engine's detection threshold, but system-level OOM (killing the process due to insufficient memory) can occur at lower memory usage — the system looks at overall memory pressure, not just Dart's.

### 2.2 Typical Symptoms

| What you see | Severity | Description |
|-------------|---------|------|
| The app gets increasingly janky | Medium | GC (garbage collection) starts frequently; each GC pauses the UI thread |
| The app crashes with OOM (killed by the system) | High | The system is out of memory and kills the process outright |
| Old Space keeps growing and never falls back | High | Memory leak! Objects are never released |
| No further monitoring after the alarm | — | Single-shot mechanism; restart the engine to restore it |
| HiLog only, no HiAppEvent | Medium | System API < 26 |

### 2.3 How to Troubleshoot?

**Step 1**: Search the logs to confirm whether it was triggered

```bash
hdc shell hilog | grep -E "heap memory|threshold|FrameworkMemAnomaly"
```

**Typical log**:
```
W Flutter: Dart heap memory usage exceeds threshold: total = 1600 MB (old = 1200 MB, new = 400 MB)
```

**How to read this log line?**
- `total = 1600 MB` → 1600MB used in total (above the 1.5GB threshold)
- `old = 1200 MB` → Old Space (long-lived objects) used 1200MB
  - **If old keeps growing and never falls back = memory leak!**
- `new = 400 MB` → New Space (newly created temporary objects) used 400MB
  - **new is high but falls back after GC = normal, just a burst of allocations in a short time**

**Step 2**: Determine which kind of memory problem it is

| Memory distribution | Diagnosis | What to do |
|---------|------|--------|
| old is high and keeps growing | Memory leak | Check whether `dispose()` releases resources correctly |
| new is high but drops after GC | Burst of allocations | Optimize batch operations, reduce temporary objects |
| Both old and new are high | Combined problem | Fix the leak first, then optimize allocations |

**Step 3**: Pinpoint the problem with DevTools Memory

```bash
flutter run --ohos
# Open DevTools in a browser → Memory tab
# Take a Heap Snapshot before and after reproducing the problem
# Compare the two snapshots; whichever objects grew are the leaked ones
```

### 2.4 Common Causes and Fixes

#### Cause 1: Too Many Cached Images

**Symptom**: Memory rises after loading many images and does not fall back after leaving the page.

**Troubleshooting**:
```dart
// Check image cache usage
print(PaintingBinding.instance.imageCache.currentSize);       // How many images are cached
print(PaintingBinding.instance.imageCache.currentSizeBytes);  // How many bytes the cache occupies
```

**Fix**:
```dart
// Method 1: limit the image cache size
PaintingBinding.instance.imageCache.maximumSize = 100;           // Default is 1000 images
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;  // 50MB, default is 100MB

// Method 2: limit the decode size of large images with cacheWidth/cacheHeight
Image.network(
  url,
  cacheWidth: (screenWidth * devicePixelRatio).toInt(),  // Do not decode at full size
  cacheHeight: (screenHeight * devicePixelRatio).toInt(),
);
```

#### Cause 2: Large List Without Lazy Loading

**Symptom**: Memory skyrockets on long-list pages.

**Fix**:
```dart
// ❌ Wrong: builds all children at once (all 1000 are built)
ListView(children: items.map((e) => ItemWidget(e)).toList());

// ✅ Correct: lazy loading, only visible items are built
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// ✅ Better: add itemExtent for further optimization
ListView.builder(
  itemExtent: 80.0,  // Fixed height; the engine does not need to measure each item
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);
```

#### Cause 3: Resources Not Released (Memory Leak)

**Symptom**: Memory does not fall back after leaving a page; it keeps growing as you repeatedly enter and exit the page.

**Fix**: Make sure all resources are released in `dispose()`:
```dart
class _MyPageState extends State<MyPage> {
  late StreamSubscription _sub;
  late AnimationController _controller;
  late TextEditingController _textController;

  @override
  void dispose() {
    // Must be released! Otherwise this is a memory leak
    _sub.cancel();             // Cancel the Stream subscription
    _controller.dispose();     // Release the animation controller
    _textController.dispose(); // Release the text controller
    super.dispose();
  }
}
```

#### Cause 4: Isolate Not Closed

**Symptom**: Memory is not released after using `Isolate.spawn`.

**Fix**:
```dart
Isolate? isolate;

Future<void> startWork() async {
  final receivePort = ReceivePort();
  isolate = await Isolate.spawn(_entryPoint, receivePort.sendPort);
}

void stopWork() {
  isolate?.kill(priority: Isolate.immediate);  // Close it after use
  isolate = null;
}

// Tip: compute() manages the Isolate lifecycle automatically; prefer it
final result = await compute(_heavyTask, data);
```

### 2.5 Notes

- Memory monitoring is **single-shot**: it stops after one alarm; the engine must be restarted to resume monitoring
- 1.5GB is the engine's detection threshold; system-level OOM can occur at lower memory usage
- **Old Space growing continuously = memory leak** (the most important criterion)

---

## 3. GPU Context Loss

### 3.1 Plain-Language Explanation

When the app goes to the background or the system is low on memory, the OHOS system reclaims GPU resources (to save power/memory). It is like your computer suddenly shutting down while you are working — your "working environment" (the GPU context) is lost.

The Flutter engine handles this process automatically:
- **Going to the background**: GPU resources are cleaned up (`kAggressive`, aggressive reclaim)
- **Returning to the foreground**: the GPU context is rebuilt (`kRestore`, restore)

The screen briefly goes black during the rebuild; this is **normal behavior**. But if the rebuild fails, the black screen persists.

### 3.2 Typical Symptoms

| What you see | Severity | Description |
|-------------|---------|------|
| Brief black screen after returning from background, then recovery | Normal | GPU reclaim followed by successful restore |
| Persistent black/white screen after returning to foreground | High | Surface rebuild failed |
| Janky for a few seconds after returning to foreground | Medium | Rebuild took a long time |
| Images display incorrectly | Low | The image cache was cleared (normal) and needs reloading |
| Video/textures stop updating in the background | Normal | Frame gate enabled (normal behavior) |
| Repeated black screen flickering | Medium | Lifecycle state flapping (frequent foreground/background switching) |

### 3.3 How to Troubleshoot?

**Step 1**: Search for the GPU reclaim log

```bash
hdc shell hilog | grep "GpuReclaim"
```

**Step 2**: Analyze the timeline (a normal "background → foreground" cycle)

```
[T+0]   GpuReclaim: Lifecycle Resumed -> Paused        ← went to the background
[T+0]   GpuReclaim: Restore -> Aggressive              ← decision: reclaim the GPU
[T+0]   GpuReclaim: ExecuteAggressive - deferring 1000ms  ← deferred by 1 second (waiting for PiP detection)
[T+0]   GpuReclaim: Sending memoryPressure            ← tells Dart to clear the image cache
[T+0]   GpuReclaim: [Raster] Surface torn down        ← GPU resources released

[T+N]   GpuReclaim: Lifecycle Paused -> Resumed       ← returned to the foreground
[T+N]   GpuReclaim: Aggressive -> Restore             ← decision: restore
[T+N]   GpuReclaim: Rebuilding onscreen context       ← rebuilding
[T+N]   GpuReclaim: [Raster] Surface REBUILT          ← rebuild succeeded! display restored
```

> **Seeing `Surface REBUILT` means success**. Seeing `SetDisplayWindow failed` means failure.

### 3.4 Common Problems and Fixes

#### Problem 1: Persistent Black Screen After Returning to the Foreground

**Troubleshooting**: Search for `SetDisplayWindow failed during rebuild`

| Cause | How to fix |
|------|--------|
| Surface rebuild failed | Check whether native_window is still valid |
| Rebuild never executed | Check whether the `ExecuteRestore` log exists |
| App-layer `onDestroy` called too early | Ensure `FlutterPage.onDestroy` is called only when actually destroying |

**App-layer check** (FlutterPage.ets):
```typescript
// Ensure onLoad/onDestroy are correctly paired
.onLoad((context) => {
  this.flutterView = FlutterManager.getInstance().getFlutterView(this.viewId);
  this.surfaceLifecycleToken = this.flutterView?.onSurfaceCreated() ?? 0;
})
.onDestroy(() => {
  // Must be called only when actually destroying, not earlier
  this.flutterView?.onSurfaceDestroyed(this.surfaceLifecycleToken);
  this.flutterView = null;
})
```

#### Problem 2: Textures/Video Still Consuming Power in the Background

**Troubleshooting**: Search for `frame gate enabled`

| Cause | How to fix |
|------|--------|
| Lifecycle not correctly passed to the engine | Ensure `onPageShow`/`onPageHide` are called correctly |
| Plugin does not implement pause logic | Implement `onInactive()`/`onActive()` in the plugin (see [dfx-texture.en.md](dfx-texture.en.md) §7) |

**App-layer check**:
```typescript
// FlutterAbilityAndEntryDelegate.ets must forward page visibility
onPageShow() {
  this.flutterView?.onPageVisibilityChanged(true);
}
onPageHide() {
  this.flutterView?.onPageVisibilityChanged(false);
}
```

#### Problem 3: Images Display Incorrectly

**Cause**: The image cache was cleared during GPU reclaim (`Sending memoryPressure`); images must be re-decoded when shown again.

**Fix**:
```dart
// Preload key images after returning to the foreground
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    precacheImage(AssetImage('assets/key_image.png'), context);
  }
}
```

### 3.5 Key Log Quick Reference

| Log | Plain-language explanation | Normal? |
|------|---------|--------|
| `GpuReclaim: Restore -> Aggressive` | The system starts reclaiming the GPU | Normal (when going to the background) |
| `GpuReclaim: Aggressive -> Restore` | The system starts restoring the GPU | Normal (when returning to the foreground) |
| `Surface torn down` | GPU resources released | Normal |
| `Surface REBUILT` | Rebuild succeeded | Normal |
| `SetDisplayWindow failed` | Rebuild failed | **Abnormal!** |
| `frame gate enabled` | Frame gate enabled | Normal (when going to the background) |
| `Sending memoryPressure` | Tells Dart to clear the image cache | Normal |
| `Deferred aggressive cancelled - PiP visible` | PiP visible, reclaim cancelled | Normal (PiP scenario) |

---

## 4. Engine Lifecycle

### 4.1 Plain-Language Explanation

The Flutter engine is the heart of the app. Like a car engine — if the engine does not start, the car cannot move; if the engine stalls unexpectedly, the car breaks down.

| Event | Plain-language explanation | When it triggers |
|------|---------|---------|
| `FLUTTER_ENGINE_CREATE` | The engine started | App startup / engine initialization |
| `FLUTTER_ENGINE_DESTROY` | The engine shut down | App exit / engine destruction |

### 4.2 Typical Symptoms

| What you see | Severity | Description |
|-------------|---------|------|
| White screen after app startup | High | The engine was not created successfully |
| App crash (no Dart exception) | High | The engine was destroyed unexpectedly |
| Memory keeps growing | High | Engines created repeatedly but never destroyed |
| Memory monitoring not working | Medium | Monitoring was not started at engine creation |

### 4.3 How to Troubleshoot?

```bash
hdc shell hilog | grep -E "FLUTTER_ENGINE_CREATE|FLUTTER_ENGINE_DESTROY"
```

**Check that CREATE and DESTROY are paired**: Normally they should pair 1:1. If there are more CREATEs than DESTROYs, some engine was not destroyed (memory leak).

### 4.4 Common Problems and Fixes

#### Problem 1: Engine Creation Failed (White Screen)

| Cause | How to fix |
|------|--------|
| Wrong Flutter configuration | Check the `flutter_ohos.json5` configuration |
| Dart bundle failed to load | Check that `flutter_assets` is fully packaged |
| SO library failed to load | Check that `libflutter.so` is packaged correctly |

#### Problem 2: Engine Created Repeatedly (Memory Leak)

```typescript
// ❌ Wrong: creates a new engine every time
getEngine(): FlutterEngine {
  return new FlutterEngine(context);  // a new one every time!
}

// ✅ Correct: reuse the engine
private flutterEngine: FlutterEngine | null = null;

getEngine(): FlutterEngine {
  if (this.flutterEngine === null) {
    this.flutterEngine = new FlutterEngine(context);
  }
  return this.flutterEngine;
}
```

---

## 5. Vsync Pipeline Failure

### 5.1 Plain-Language Explanation

Vsync (vertical synchronization) is the core signal that drives screen refresh. Think of it as a "metronome" — it beats 60 times per second, and Flutter draws frames to the beat. If the metronome breaks, Flutter no longer knows when to draw a frame.

### 5.2 Typical Symptoms

| What you see | Severity | Corresponding log |
|-------------|---------|---------|
| No rendering at all (frozen screen) | Fatal | `vsync_handle_ is nullptr` |
| Intermittent jank | Medium | `AwaitVSync...failed` |
| Frame rate cannot be set (120fps has no effect) | Medium | `SetExpectedFrameRateRange failed` |
| No rendering + frozen | Fatal | `Failed to dlopen libnative_vsync.so` |

### 5.3 How to Troubleshoot?

```bash
hdc shell hilog | grep -E "vsync|Vsync|VSync|Poll error"
```

| Log | Plain-language explanation | Severity |
|------|---------|---------|
| `vsync_handle_ is nullptr` | Vsync handle is invalid (the metronome was never installed) | Fatal |
| `AwaitVSync...failed:` | Vsync request failed (the metronome stopped beating) | Fatal |
| `Failed to dlopen libnative_vsync.so` | Vsync library failed to load | Fatal |
| `SetExpectedFrameRateRange failed` | Frame rate setting failed | Medium |
| `Poll error:` | Message loop error | Medium |

### 5.4 Common Problems and Fixes

| Problem | Cause | How to fix |
|------|------|--------|
| No rendering at all | Vsync library not loaded | Confirm the device system version supports the NativeVSync API |
| Intermittent jank | System load occasionally causes Vsync request failures | The engine has a retry mechanism; if failures are frequent, check the system state |
| 120fps has no effect | Device or system does not support it | Confirm the device supports 120fps and the system API supports frame rate configuration |

---

## 6. Troubleshooting Checklist

### Memory issues

- [ ] Search for `Dart heap memory` to confirm whether it was triggered
- [ ] Check the `old` and `new` values to determine whether it is a leak or heavy allocation
- [ ] old keeps growing → take snapshots with DevTools Memory to find the leak
- [ ] Check image caching, lazy list loading, and dispose cleanup

### GPU issues

- [ ] Search for `GpuReclaim` to see the full reclaim/restore flow
- [ ] Check for `Surface REBUILT` (success) or `SetDisplayWindow failed` (failure)
- [ ] Check for `frame gate enabled` when going to the background (normal)
- [ ] Check for `ExecuteReclaimRestore` when returning to the foreground (normal)
- [ ] Check that the app layer forwards `onPageShow`/`onPageHide` correctly

### Engine lifecycle

- [ ] Search for `FLUTTER_ENGINE_CREATE` / `FLUTTER_ENGINE_DESTROY`
- [ ] Check that they pair 1:1
- [ ] In multi-engine scenarios, check whether engines are reused

### Vsync issues

- [ ] Search for `vsync` / `Poll error`
- [ ] Check whether `vsync_handle_ is nullptr` appears
- [ ] Check that `libnative_vsync.so` loads successfully
