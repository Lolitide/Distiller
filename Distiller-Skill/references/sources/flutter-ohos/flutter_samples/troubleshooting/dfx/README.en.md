# Flutter OHOS Platform DFX Troubleshooting Navigation

> Intended for app developers using the Flutter OHOS SDK (including Flutter beginners)
> When you run into a problem, start from the "Fault Quick Reference" entry below

---

## 0. Must-Read for Beginners: Basic Concepts

Before you start troubleshooting, get familiar with a few basic concepts. They come up again and again in the documents that follow.

### 0.1 What Is DFX?

DFX is short for "Design for X"; here it specifically refers to **testability/diagnosability design**. Simply put, the Flutter engine has a built-in "self-monitoring" mechanism: when the app hits a crash, app freeze, jank, memory leak, or similar problem, the engine automatically records logs and events to help you find the cause.

### 0.2 What Are HiLog / HiAppEvent / HiTrace?

These are three diagnostic toolsets provided by the OHOS system. You can think of them as:

| Tool | Plain-language description | Analogy |
|------|---------|------|
| **HiLog** | System log output, similar to `print()` | Like the browser Console |
| **HiAppEvent** | Structured event reporting, more organized than logs | Like Crashlytics crash reports |
| **HiTrace** | Performance tracing that records the duration of every frame | Like Chrome DevTools Performance |

> **Beginner tip**: When troubleshooting, the first step is always to **capture HiLog logs** (see §2). The logs contain clues for most problems.

### 0.3 What Is hdc?

`hdc` stands for OHOS Device Connector, similar to Android's `adb`. It transfers files and runs commands between your computer and an OHOS device.

```bash
# List connected devices
hdc list targets

# Run a command on the device
hdc shell <command>

# Pull a file from the device to your computer
hdc file recv <device path> <computer path>
```

### 0.4 What Are Flutter's Three Threads?

A Flutter app has three key threads at runtime. Understanding them helps with freeze and jank problems:

| Thread | Plain-language description | Symptoms when it fails |
|------|---------|--------------|
| **UI thread** | Runs your Dart code and builds the widget tree | The screen freezes completely and touch gets no response |
| **Raster thread** (rasterization thread) | Turns the widget tree into pixels and hands them to the GPU | The screen stops updating, but touch may still respond |
| **Platform thread** | Interacts with the OHOS system (e.g., handles touch events and system messages) | Platform channel communication blocks, which can indirectly freeze the UI |

### 0.5 How Is a Frame Drawn? (The Rendering Pipeline)

Every frame goes through four stages before it appears on screen, like a factory assembly line:

```
Build → Layout → Paint → Composite (rasterization)
 │       │        │         │
 │       │        │         └─ Raster thread: turns the frame into pixels and hands it to the GPU for display
 │       │        └─ UI thread: generates drawing commands (the Layer tree)
 │       └─ UI thread: determines each widget's size and position
 └─ UI thread: runs your Dart code and updates the widget tree
```

> **Beginner tips**:
> - **Build/Layout/Paint run on the UI thread** — if your Dart code is slow, this is where the timeout occurs
> - **Composite runs on the Raster thread** — if the frame is too complex (large images, blur, many layers), this is where the timeout occurs
> - When troubleshooting jank, the first step is figuring out **which thread timed out**
> - For detailed analysis methods, see [dfx-jank-latency.en.md](dfx-jank-latency.en.md)

### 0.6 What Is a "Frame Budget"?

The screen refreshes 60 times per second (or 90/120 times), and each refresh is called a frame. Every frame must be drawn within a fixed amount of time — that time is the "frame budget":

| Screen refresh rate | Frame budget | Plain-language explanation |
|-----------|--------|---------|
| 60Hz | **16.6ms** | Each frame must be drawn within 16.6 milliseconds |
| 90Hz | **11.1ms** | Each frame must be drawn within 11.1 milliseconds |
| 120Hz | **8.3ms** | Each frame must be drawn within 8.3 milliseconds |

If a frame isn't finished within its budget, that frame is "dropped" (frame dropping/jank), and what the user sees is a brief stutter.

> **An analogy**: it's like a flip-book animation — you need to flip 60 pages per second for it to look smooth. If one page takes you 50 milliseconds to flip, the animation "stutters".

### 0.7 What Are "Response Latency" and "Completion Latency"?

These are two important metrics in Huawei's app experience quality standards. When a user says the app "feels laggy", it is often one of these two latencies at fault:

| Metric | Plain-language explanation | User perception threshold | Example |
|------|---------|------------|------|
| **Response latency** | Time from the user's touch to the **first visual feedback** | >100ms feels "sluggish" | You tap a button and the UI reacts only after 100ms |
| **Completion latency** | Time from the user's action to the **operation fully completing** | Depends on the scenario | You open a detail page and content appears only after a 2-second white screen |

> **How beginners tell them apart**:
> - Response latency is "does it react immediately when I tap" — a blocked main thread makes responses slow
> - Completion latency is "has the operation fully completed" — slow data loading or an oversized first screen makes completion slow
> - Response latency can pass (an animation starts right after the tap) while completion latency fails (the animation ends but the content still hasn't appeared)
> - For detailed measurement methods, see [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §5

### 0.8 How Does a Touch Event Become a Frame? (The Full Path from Touch to Screen)

When your finger slides across the screen, the event travels a long "conveyor chain" before becoming a frame:

```
Finger down
│
├─ mmi_service (multimodal input service)
│  └─ Forwards to the app main thread immediately (DispatchTouchEvent)
│
├─ Finger slides (move events)
│  └─ Not forwarded immediately! Gated by the vsync signal and dispatched
│     in step with the frame cadence:
│     mmi_service → VSyncGennerator → DVSync-app → app main thread
│
├─ TouchSlop slide threshold
│  └─ The minimum displacement for the system to decide "sliding has
│     started"; 18vp by default
│
└─ Render and present to screen
   └─ 1.ui → 1.raster → render_service → RSUniRenderThread → RSHardwareThread → screen display
```

> **Beginner tip**: For detailed trace-chain analysis methods, see [dfx-jank-latency.en.md](dfx-jank-latency.en.md) §2.

### 0.9 What Is an "External Texture"?

An external texture is a mechanism that lets the native side (video players, cameras, animations, and so on) "feed" frames to Flutter for display. You can think of it as a "frame conveyor belt":

- **Producer**: native components such as video players and cameras, which continuously produce frames
- **Consumer**: the Flutter engine, which draws the frames onto the screen

If something goes wrong on the conveyor belt (production outpaces consumption, the producer stops, or the consumer gets stuck), the result is a black screen, jank, or a frozen screen.

### 0.10 What Is "GPU Context Loss"?

When the app goes to the background or system memory runs low, the OHOS system reclaims GPU resources (to save power/memory). It's like your computer suddenly shutting down while you work — your "working environment" (the GPU context) is gone, and you have to restart to continue working. The Flutter engine rebuilds the GPU context automatically, but the screen briefly goes black during the rebuild.

---

## 1. Fault Quick Reference

### 1.1 What Problem Am I Hitting?

Based on what you observe, find the matching document:

| What you observe | What the problem might be | Which document to read |
|-------------|--------------|-----------|
| App exits suddenly or crashes | Native crash / Dart exception / ETS exception | [dfx-crash.en.md](dfx-crash.en.md) |
| App freezes, stops responding, won't react to taps | A frozen thread (UI/Raster/Platform) | [dfx-appfreeze.en.md](dfx-appfreeze.en.md) |
| Janky UI, scrolling isn't smooth | Frame dropping/JANK (frame rate too low) | [dfx-performance.en.md](dfx-performance.en.md) |
| Slow response to taps, scrolling doesn't track the finger | Excessive response latency (main thread blocked) | [dfx-jank-latency.en.md](dfx-jank-latency.en.md) |
| Page opens with a long white screen before content appears | Excessive completion latency (slow first-screen build/data loading) | [dfx-jank-latency.en.md](dfx-jank-latency.en.md) |
| Phone runs hot, battery drains fast, CPU stays at high usage | Abnormal load / background power consumption (continuous repaints, polling never stops) | [dfx-power-load.en.md](dfx-power-load.en.md) |
| Memory usage too high, OOM sudden exit | Dart heap memory over the limit | [dfx-memory.en.md](dfx-memory.en.md) |
| Black screen, white screen, rendering exceptions | GPU context loss (recovery after returning from the background failed) | [dfx-memory.en.md](dfx-memory.en.md) |
| Video/camera frames are black, don't update, or jank | External texture problem | [dfx-texture.en.md](dfx-texture.en.md) |
| Split view not working / avoid area not applied / foldable anomalies | Multi-device adaptation problem | [dfx-multi-device.en.md](dfx-multi-device.en.md) |
| Not sure what the problem is | Capture full logs first and go from there | [dfx-logging.en.md](dfx-logging.en.md) |

### 1.2 Fault Locating Decision Tree

If you're not sure what type of problem it is, follow these steps to search the logs for keywords and find out:

```
An app exception occurs
│
├─ App sudden exit/crash
│  ├─ The log contains "Caught signal SIG*"
│  │  → Crash in the engine's underlying C++ layer (Native crash); see dfx-crash.en.md §2
│  ├─ The log contains "Unhandled Exception:"
│  │  → Your Dart code threw an uncaught exception; see dfx-crash.en.md §3
│  ├─ The log contains "FLUTTER_ETS_EXCEPTION"
│  │  → Exception in the ETS (ArkTS) plugin layer; see dfx-crash.en.md §4
│  └─ None of the above found
│     → Capture full logs first; see dfx-logging.en.md
│
├─ App freeze/no response
│  ├─ The log contains "is not alive"
│  │  → A thread is stuck; see dfx-appfreeze.en.md
│  ├─ The log contains "FLUTTER_THREAD_STUCK"
│  │  → The watchdog detected a stuck thread; see dfx-appfreeze.en.md
│  └─ The log contains "APP_FREEZE"
│     → The UI thread has been stuck for over 6 seconds and the system is about to kill the process; see dfx-appfreeze.en.md
│
├─ Janky UI/frame dropping
│  ├─ The log contains "OTHER_JANK" or "OTHER_JANK_STAT"
│  │  → Frame dropping in non-scrolling scenarios; see dfx-performance.en.md
│  ├─ The log contains "OTHER_JANK_SCROLL"
│  │  → Frame dropping while scrolling; see dfx-performance.en.md
│  ├─ DevTools marks the frame red and only the UI thread timed out
│  │  → Slow Dart code (build/layout/paint); see dfx-jank-latency.en.md §4.1
│  ├─ DevTools marks the frame red and only the Raster thread timed out
│  │  → Drawing too heavy (large images/blur/saveLayer); see dfx-jank-latency.en.md §4.2
│  ├─ DevTools labels "Shader Compilation Jank"
│  │  → Caused by first-time shader compilation; see dfx-jank-latency.en.md §4.6
│  └─ More detailed analysis needed
│     → Capture a HiTrace; see dfx-performance.en.md
│
├─ Response latency / completion latency problems
│  ├─ Slow reaction after a tap (long response latency)
│  │  → The main thread is blocked by heavy work; see dfx-jank-latency.en.md §4.5
│  ├─ Page opens with a long white screen (long completion latency)
│  │  → Full first-screen build / slow data loading; see dfx-jank-latency.en.md §4.5
│  └─ Measured latency numbers needed
│     → Use FrameTiming instrumentation + the system trace chain; see dfx-jank-latency.en.md §5
│
├─ Load / power problems (phone runs hot, battery drains fast, CPU stays at high usage)
│  ├─ top -H shows a thread with persistently high CPU usage
│  │  → Use hiperf to capture instruction-count sampling + a flame graph to locate hotspots; see dfx-power-load.en.md §2
│  ├─ CPU stays high even on a static page
│  │  → Useless repaints (missing const/RepaintBoundary); see dfx-power-load.en.md §5.1
│  ├─ Tasks still running after going to the background / timers not stopped
│  │  → Background power consumption (pause animations/polling/textures); see dfx-power-load.en.md §5.2
│  └─ Accompanied by OTHER_JANK events
│     → Smoothness already affected; cross-check HiTrace/HiLog; see dfx-power-load.en.md §2.4
│
├─ Memory problems
│  ├─ The log contains "Dart heap memory usage exceeds threshold"
│  │  → Dart memory exceeded 1.5GB; see dfx-memory.en.md
│  └─ The log contains "FrameworkMemAnomaly"
│     → The system recorded a memory anomaly event; see dfx-memory.en.md
│
├─ GPU/rendering problems
│  ├─ The log contains "GpuReclaim" together with "kAggressive"
│  │  → GPU resources were reclaimed by the system; see dfx-memory.en.md
│  └─ The log contains "FLUTTER_GPU_CONTEXT_LOSS"
│     → GPU context loss event; see dfx-memory.en.md
│
├─ External texture problems (abnormal video/camera frames)
│  ├─ The log contains "No DlImage available" or "OH_NativeImage_Create() failed"
│  │  → Texture creation failed or no frames available; see dfx-texture.en.md §5
│  ├─ The log contains "frame gate enabled, drain-only"
│  │  → The app is in the background and texture frames are paused (normal behavior); see dfx-texture.en.md §6
│  ├─ The log contains "skip one frame"
│  │  → Frames produced faster than consumed; see dfx-texture.en.md §8
│  └─ The log contains "PlatformViewVisibleAreaEventCallback"
│     → A visible-area change triggered pause/resume; see dfx-texture.en.md §7
│
├─ Multi-device adaptation anomalies
│  ├─ The log contains "SplitView" or "SystemChannel config parse failed"
│  │  → Split view configuration problem; see dfx-multi-device.en.md §2
│  ├─ The log contains "avoidAreaChangeCallback"
│  │  → Safe area avoidance problem; see dfx-multi-device.en.md §3
│  ├─ The log contains "Fold status change"
│  │  → Foldable status change; see dfx-multi-device.en.md §4
│  ├─ The log contains "Device pixel ratio"
│  │  → DPI scaling problem; see dfx-multi-device.en.md §5
│  ├─ The log contains "LTPO"
│  │  → Adaptive refresh rate problem; see dfx-multi-device.en.md §6
│  └─ The log contains "windowSizeChangeCallback"
│     → Multi-window size change; see dfx-multi-device.en.md §7
│
└─ Engine lifecycle anomalies
   └─ The log contains "FLUTTER_ENGINE_CREATE" or "FLUTTER_ENGINE_DESTROY"
      → The engine was created or destroyed; see dfx-memory.en.md §4
```

> **Beginner tip**: If you don't know how to search for the keywords above, don't worry — read §2 first to learn how to capture logs.

---

## 2. First Step: Capture Logs

Whatever problem you run into, **capturing logs right away** is the most critical step. Just as investigators must secure the crime scene, the logs are the "scene".

### 2.1 Quickly Capture Full Logs (Just Follow These 4 Steps)

```bash
# 1. Clear historical logs (remove the old ones and keep only the new logs captured after reproduction)
hdc shell hilog -r

# 2. Reproduce the problem (operate your app to trigger the bug)

# 3. Capture logs (press Ctrl+C to stop capturing)
hdc shell hilog > flutter_log.txt

# 4. Filter Flutter-related content from the logs
hdc shell hilog | grep -E "Flutter|XComFlutter|flutter" > flutter_filtered.txt
```

> **Beginner tips**:
> - `hilog` is the OHOS logging system, similar to Android's `logcat`
> - `grep` is a text search tool; `-E` means matching with regular expressions
> - `>` means saving the output to a file

### 2.2 Filter Logs by Problem Type (View Only Relevant Content, Filter Out Noise)

Not sure which one to use? Go back to §1.1 and pick based on your symptom:

```bash
# Crash related (app sudden exit)
hdc shell hilog | grep -E "Caught signal|Unhandled Exception|FLUTTER_DART_EXCEPTION|FLUTTER_ETS_EXCEPTION"

# Freeze related (app not responding)
hdc shell hilog | grep -E "FlutterWatchdog|not alive|HiCollie|THREAD_STUCK"

# Jank/frame dropping related (UI not smooth)
hdc shell hilog | grep -E "JANK|jank|missed|frame"

# Memory related (OOM, high memory usage)
hdc shell hilog | grep -E "heap memory|memory|OOM|threshold"

# GPU related (black screen, white screen)
hdc shell hilog | grep -E "GpuReclaim|GPU|gpu"

# External texture related (abnormal video/camera frames)
hdc shell hilog | grep -E "external_texture|ExternalTexture|NativeImage|DlImage|frame gate|VisibleArea|texture_id"

# Multi-device adaptation related (split view, foldables, etc.)
hdc shell hilog | grep -E "SplitView|split_view|avoidArea|displayFeature|foldStatus|device pixel ratio|windowSizeChange|LTPO"
```

### 2.3 Capture a Performance Trace (for Jank Analysis)

If the UI is janky but the logs reveal nothing, capture a performance trace (similar to a Chrome DevTools Performance recording):

```bash
# Capture a 10-second performance trace (reproduce the jank within those 10 seconds)
hdc shell hitrace --trace_clock boottime -t 10 flutter -o /data/local/tmp/trace.ftrace

# Pull the trace file to your computer
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# Open it in Chrome: visit chrome://tracing → click Load → select trace.ftrace
```

For detailed log capture and filtering methods, see [dfx-logging.en.md](dfx-logging.en.md).

---

## 3. DFX Event Quick Reference

While running, the Flutter engine automatically reports "events" (think of them as structured crash reports). Each event carries information such as the problem type, timestamp, and process ID.

| Event name | Problem type | Plain-language explanation | Which document to read |
|--------|---------|---------|-----------|
| `FLUTTER_DART_EXCEPTION` | Dart exception | A bug in your Dart code caused a crash | [dfx-crash.en.md](dfx-crash.en.md) |
| `FLUTTER_ETS_EXCEPTION` | ETS exception | A bug in ArkTS plugin code | [dfx-crash.en.md](dfx-crash.en.md) |
| `FLUTTER_STABILITY_EVENT` | Stability event | The engine detected instability (freeze, GPU loss, etc.) | See the sub-table below |
| `OTHER_JANK` | Frame dropping | One frame rendered too slowly, causing jank | [dfx-performance.en.md](dfx-performance.en.md) |
| `OTHER_JANK_STAT` | Frame dropping statistics | A summary of dropped frames over a period | [dfx-performance.en.md](dfx-performance.en.md) |
| `OTHER_JANK_SCROLL` | Scrolling frame dropping | A frame exceeded 50ms while scrolling | [dfx-performance.en.md](dfx-performance.en.md) |
| FrameworkMemAnomaly | Memory over limit | Dart memory exceeded 1.5GB | [dfx-memory.en.md](dfx-memory.en.md) |

### Sub-types of FLUTTER_STABILITY_EVENT

`FLUTTER_STABILITY_EVENT` is a "parent category"; its `eventName` field distinguishes the specific stability problem:

| eventName | Plain-language explanation | Which document to read |
|-----------|---------|-----------|
| `FLUTTER_THREAD_STUCK` | A thread is stuck | [dfx-appfreeze.en.md](dfx-appfreeze.en.md) |
| `FLUTTER_GPU_CONTEXT_LOSS` | GPU resources reclaimed by the system | [dfx-memory.en.md](dfx-memory.en.md) |
| `FLUTTER_ENGINE_CREATE` | The Flutter engine was created | [dfx-memory.en.md](dfx-memory.en.md) |
| `FLUTTER_ENGINE_DESTROY` | The Flutter engine was destroyed | [dfx-memory.en.md](dfx-memory.en.md) |

For complete event parameter descriptions, see [dfx-hiappevent.en.md](dfx-hiappevent.en.md).

---

## 4. HiLog Keyword Quick Reference

Search the logs for these keywords to quickly determine the problem type:

| Search this keyword | Problem type | Meaning (plain-language explanation) |
|--------------|---------|----------------|
| `Caught signal SIGSEGV` | Engine crash | The engine accessed illegal memory (e.g., a null pointer) |
| `Caught signal SIGABRT` | Engine crash | An internal engine assertion failed or memory was corrupted |
| `Unhandled Exception:` | Dart exception | Your Dart code threw an exception not caught by try-catch |
| `is not alive` | App freeze | A thread hasn't responded for 3 seconds |
| `OH_HiCollie_Report() success` | App freeze | The freeze event has been reported to the system |
| `Dart heap memory usage exceeds threshold` | Memory over limit | Dart memory exceeded 1.5GB |
| `GpuReclaim` + `kAggressive` | GPU reclaim | The system is reclaiming GPU resources (normal when going to the background) |
| `GpuReclaim` + `kRestore` | GPU restore | GPU resources are being restored (normal when returning to the foreground) |
| `Poll error:` | Message loop anomaly | The system message loop failed; may cause an app freeze |
| `AwaitVSync...failed` | Vsync failure | The vertical sync signal request failed; may stop rendering |
| `No DlImage available` | External texture | The texture has no frame to draw (black screen) |
| `frame gate enabled` | External texture | The app is in the background and texture frames are paused (normal) |
| `skip one frame` | External texture | Frames are produced faster than consumed; some frames were skipped |

---

## 5. DFX Capability Overview

### 5.1 The Three Logging Systems (Where Do Logs Come From?)

Logs on the Flutter OHOS platform come from three different "sources". Knowing them helps you filter precisely:

| Log source | Tag | Who produces it | Typical content | When to look |
|---------|-----|---------|---------|-----------|
| **Engine internals** (FML_LOG) | Mapped to HiLog | The Flutter engine's C++ code | Crash stacks, freeze detection, GPU reclaim | Troubleshooting crashes, freezes, black screens |
| **Platform C++ layer** | `XComFlutterOHOS_Native` | C++ code on the OHOS platform | Engine initialization, NAPI calls | Troubleshooting engine initialization problems |
| **ETS embedding layer** | `Flutter` | ArkTS code | MethodChannel, plugin exceptions, lifecycle | Troubleshooting plugin/channel problems |

> **One command to see all Flutter logs**:
> ```bash
> hdc shell hilog | grep -E "Flutter|XComFlutter|flutter"
> ```

### 5.2 DFX Reporting Channels (Where Is Problem Information Recorded?)

| Channel | Plain-language description | How to view |
|------|---------|---------|
| **HiLog** | Real-time text logs | `hdc shell hilog` |
| **HiAppEvent** | Structured events (with parameters) | `hdc shell hilog \| grep "OH_HiAppEvent_Write"` |
| **HiCollie** | System-level freeze detection | Triggers the system APP_FREEZE event |
| **HiTrace** | Performance tracing (per-frame duration) | `hdc shell hitrace ...` |

### 5.3 API Version Requirements (Some Features Require a Newer System)

| Feature | Minimum system API version | What happens below this version |
|------|-----------------|----------------|
| HiAppEvent event reporting | API 18 | No HiAppEvent events are generated (but HiLog still works) |
| HiTrace extension interfaces | API 19 | The frame-drop detail trace is unavailable |
| Memory anomaly reporting (FrameworkMemAnomaly) | API 26 | Memory anomaly events are not reported (but HiLog still works) |

> **Beginner tip**: HiLog logs are not restricted by API version and are always available. If certain events can't be found, check the system API version first.

---

## 6. Document Index

| Document | What it covers | When to read it |
|------|--------|----------|
| [dfx-logging.en.md](dfx-logging.en.md) | How to capture and filter logs | **The first step for troubleshooting every problem** |
| [dfx-crash.en.md](dfx-crash.en.md) | How to investigate app sudden exit/crash | App sudden exit, crash |
| [dfx-appfreeze.en.md](dfx-appfreeze.en.md) | How to investigate app freeze/no response | App won't react to taps, frozen |
| [dfx-performance.en.md](dfx-performance.en.md) | How to investigate UI jank/frame dropping (at the DFX event level) | UI not smooth, scrolling stutters, investigating frame-drop events |
| [dfx-jank-latency.en.md](dfx-jank-latency.en.md) | In-depth analysis of scrolling jank, frame dropping, and latency problems | Jank optimization, response/completion latency measurement, using DevTools/SmartPerf |
| [dfx-power-load.en.md](dfx-power-load.en.md) | How to investigate load anomalies and power problems | Phone runs hot, battery drains fast, CPU stays at high usage, unwanted background activity |
| [dfx-hiappevent.en.md](dfx-hiappevent.en.md) | Complete reference for all DFX events | Looking up event parameter meanings |
| [dfx-memory.en.md](dfx-memory.en.md) | How to investigate memory/OOM/GPU problems | High memory usage, OOM, black screen |
| [dfx-texture.en.md](dfx-texture.en.md) | How to investigate external texture problems | Abnormal video/camera frames |
| [dfx-multi-device.en.md](dfx-multi-device.en.md) | How to investigate multi-device adaptation problems | Split view, foldables, DPI, etc. |
