# DFX Event Catalog Reference

> Back to [README.en.md](README.en.md)

This document lists all DFX events reported by the Flutter OHOS platform via HiAppEvent, along with their parameters, for developer reference.

> **Beginner tip**: HiAppEvent events are like "structured crash reports" — better organized than plain logs, containing information such as problem type, timestamp, and parameters. You can think of them as "bug report forms" that the system fills in for you automatically.

---

## 1. Event Overview

| Event Name | Problem Type | Plain-Language Description | Minimum API | Detailed Documentation |
|--------|---------|---------|---------|---------|
| `FLUTTER_DART_EXCEPTION` | Dart exception | Your Dart code has a bug | API 18 | [dfx-crash.en.md](dfx-crash.en.md) §3 |
| `FLUTTER_STABILITY_EVENT` | Stability event | The engine detected instability (freeze/GPU loss, etc.) | API 18 | See §3 |
| `FLUTTER_ETS_EXCEPTION` | ETS exception | ArkTS plugin code has a bug | API 18 | [dfx-crash.en.md](dfx-crash.en.md) §4 |
| `OTHER_JANK` | Frame dropping | One frame took too long to render | API 18 | [dfx-performance.en.md](dfx-performance.en.md) |
| `OTHER_JANK_STAT` | Frame drop statistics | Summary of dropped frames over a period | API 18 | [dfx-performance.en.md](dfx-performance.en.md) |
| `OTHER_JANK_SCROLL` | Scrolling frame drops | A frame exceeded 50 ms during scrolling | API 18 | [dfx-performance.en.md](dfx-performance.en.md) |
| FrameworkMemAnomaly | Memory limit exceeded | Dart memory exceeds 1.5 GB | API 26 | [dfx-memory.en.md](dfx-memory.en.md) §2 |

> **Beginner tip**: If you cannot find certain events, the system API version may be too low. HiLog logs are not restricted by API version and are always available.

---

## 2. FLUTTER_DART_EXCEPTION (Dart Code Exception)

**When it is triggered**: Your Dart code has an exception that is not caught by try-catch.

| Parameter | Type | Limit | Description | How to Use It |
|------|------|------|------|--------|
| `frameworkName` | String | — | Fixed `"FLUTTER"` | Identification |
| `errorMsg` | String | ≤4096 characters | Error message | Determine what the exception is |
| `stackTrace` | String | ≤8192 characters | Stack trace | Locate the code line |
| `pid` | Int64 | — | Process ID | Correlate with the process |
| `timeStamp` | Int64 | — | Event time | When it occurred |

### How to Read errorMsg?

| errorMsg Example | Exception Type | Plain-Language Description | How to Fix It |
|--------------|---------|---------|--------|
| `type 'Null' is not a subtype of type 'String'` | TypeError | Trying to use null as a String | Add a null check |
| `NoSuchMethodError: ... was called on null` | NoSuchMethodError | Calling a method on null | Use `?.` for safe calls |
| `RangeError: Index value 'N' is out of range` | RangeError | Array index out of range | Add bounds checking |
| `Bad state: Stream has already been listened to` | StateError | The Stream is in a bad state | Check the Stream state |

**Detailed troubleshooting**: See [dfx-crash.en.md](dfx-crash.en.md) §3

---

## 3. FLUTTER_STABILITY_EVENT (Stability Event)

**When it is triggered**: The engine detected an instability (thread stuck, GPU loss, engine creation/destruction).

This is a "catch-all" event category; the `eventName` field tells you what the specific problem is:

| eventName | Plain-Language Description | Severity | Detailed Documentation |
|-----------|---------|---------|---------|
| `FLUTTER_THREAD_STUCK` | A thread is stuck | Fatal | [dfx-appfreeze.en.md](dfx-appfreeze.en.md) |
| `FLUTTER_GPU_CONTEXT_LOSS` | GPU resources reclaimed by the system | High | [dfx-memory.en.md](dfx-memory.en.md) §3 |
| `FLUTTER_ENGINE_CREATE` | A Flutter engine was created | — | [dfx-memory.en.md](dfx-memory.en.md) §4 |
| `FLUTTER_ENGINE_DESTROY` | A Flutter engine was destroyed | — | [dfx-memory.en.md](dfx-memory.en.md) §4 |

### How to Read description?

#### FLUTTER_THREAD_STUCK

| description Content | Plain-Language Description | What Happens Next |
|-----------------|---------|--------------|
| `Flutter UI thread stuck. isSixSecondEvent=false` | The UI thread was stuck for 3 seconds | Logged only, no dialog |
| `Flutter UI thread stuck. isSixSecondEvent=true` | The UI thread was stuck for 6 seconds | May show an "app not responding" dialog |
| `Flutter Raster thread stuck. isSixSecondEvent=false` | The Raster thread is stuck | Logged only |
| `Flutter Platform thread stuck. isSixSecondEvent=false` | The Platform thread is stuck | Logged only |

#### FLUTTER_GPU_CONTEXT_LOSS

**How to troubleshoot**: Search for `GpuReclaim` to see the full reclaim/restore flow, and check whether `Surface REBUILT` succeeded. See [dfx-memory.en.md](dfx-memory.en.md) §3 for details.

#### FLUTTER_ENGINE_CREATE / FLUTTER_ENGINE_DESTROY

**How to troubleshoot**: Check whether CREATE and DESTROY are paired 1:1. See [dfx-memory.en.md](dfx-memory.en.md) §4 for details.

---

## 4. FLUTTER_ETS_EXCEPTION (ArkTS Plugin Exception)

**When it is triggered**: ArkTS plugin code fails while handling a MethodChannel message.

| Parameter | Description | How to Use It |
|------|------|--------|
| `CONTEXT` | Where the exception occurred | Determine where the error happened |
| `ERROR_MSG` | Error message | Determine the exception type |
| `STACK_TRACE` | Stack trace | Locate the code line |

### CONTEXT Value Meanings

| CONTEXT | Plain-Language Description | Where to Look |
|---------|---------|---------|
| `MethodChannel.onMessage` | Error while the plugin was receiving a message | Check the plugin's `onMethodCall` |
| `MethodChannel.reply` | Error while processing the reply result | Check the Dart-side callback |
| `DartMessenger.invokeHandler` | Error while handling a binary message | Check the message handler |
| `DartMessenger.handlePlatformMessageResponse` | Error while replying to a message | Check the reply callback |

> **Characteristic**: ETS exceptions usually do not cause crashes (they are caught by try-catch), but they leave the affected feature unusable.

**Detailed troubleshooting**: See [dfx-crash.en.md](dfx-crash.en.md) §4

---

## 5. OTHER_JANK (Single Frame Drop)

**When it is triggered**: A frame takes too long to render in a non-scrolling scenario.

| Parameter | Description | How to Interpret It |
|------|------|---------|
| `missedFrames` | How many frames were dropped | 1-3 is minor, >3 is severe |
| `startTime` / `endTime` | Time range of the frame drop | Pinpoint when it occurred |

**Detailed troubleshooting**: See [dfx-performance.en.md](dfx-performance.en.md)

---

## 6. OTHER_JANK_STAT (Frame Drop Statistics)

**When it is triggered**: Dropped frames are reported in a batch after a cumulative count of up to 10 dropped frames is reached in non-scrolling scenarios.

| Parameter | Description | How to Interpret It |
|------|------|---------|
| `totalMissedFrames` | Total number of dropped frames | Overall amount of frame dropping |
| `maxFrameTime` | How long the worst frame took to render (ms) | <16ms is normal, >50ms is severe |
| `maxMissedFrameRate` | The corresponding frame rate | 60/120 is normal; lower values mean the frame rate falls short |

### How to Judge Severity?

| maxFrameTime | Severity | User Perception |
|-------------|---------|---------|
| <16ms | Normal | Imperceptible |
| 16-50ms | Minor | Occasional stutter |
| 50-100ms | Noticeable | Perceptible jank |
| >100ms | Severe | Severe jank |

---

## 7. OTHER_JANK_SCROLL (Scrolling Frame Drops)

**When it is triggered**: A frame exceeds 50 ms during scrolling.

| Parameter | Description | How to Use It |
|------|------|--------|
| `maxFrameTime` | How long the worst frame took to render | >50ms is perceptible to users |
| `totalMissedFrames` | Frames dropped during the scroll | Use with totalFrames to compute the frame drop rate |
| `totalFrames` | Total frames during the scroll | Used to compute the frame drop rate |
| `recentScrollCount` | Number of scrolls since the last report | 1 = every scroll drops frames |
| `frameId` | Frame number of the worst drop | Locate it in the Trace |

### How to Calculate the Frame Drop Rate?

```
frame drop rate = totalMissedFrames / totalFrames
```

| Frame Drop Rate | Severity | User Perception |
|--------|---------|---------|
| <5% | Normal | Imperceptible |
| 5-10% | Minor | Occasional stutter |
| 10-30% | Noticeable | Obvious jank |
| >30% | Severe | Seriously degrades the experience |

**Detailed troubleshooting**: See [dfx-performance.en.md](dfx-performance.en.md) §4.3

---

## 8. FrameworkMemAnomaly (Memory Limit Exceeded)

**When it is triggered**: Dart memory exceeds 1.5 GB (API 26+ only).

| Parameter | Description |
|------|------|
| `description` | Format: `Dart heap memory usage exceeds threshold: total = X MB (old = Y MB, new = Z MB)` |

### How to Read description?

| Field | Meaning | Analysis Direction |
|------|------|---------|
| `total` | Total memory | Overall usage |
| `old` | Old Space (long-lived objects) | **Continued growth = memory leak!** |
| `new` | New Space (short-lived objects) | High but drops after GC = normal |

> **Note**: Reported on API 26+ only; lower versions have HiLog only. Once triggered, monitoring stops, and the engine must be restarted to resume it.

**Detailed troubleshooting**: See [dfx-memory.en.md](dfx-memory.en.md) §2

---

## 9. How to View These Events?

### Method 1: Search via hilog

```bash
# Search all HiAppEvent reports
hdc shell hilog | grep "OH_HiAppEvent_Write"

# Search for a specific event
hdc shell hilog | grep "FLUTTER_DART_EXCEPTION"
hdc shell hilog | grep "FLUTTER_STABILITY_EVENT"
hdc shell hilog | grep "OTHER_JANK"
hdc shell hilog | grep "FrameworkMemAnomaly"
```

### Method 2: Check the faultlog directory

```bash
# Crash logs
hdc shell ls /data/log/faultlog/
hdc file recv /data/log/faultlog/faultlog-xxx ./faultlog.txt

# Freeze logs
hdc file recv /data/log/faultlog/appfreeze-xxx ./appfreeze.txt
```

### What if Event Reporting Fails?

| Error Log | Plain-Language Description | Solution |
|---------|---------|---------|
| `API version too low` | The system API is too low | Requires API 18+ |
| `reportFrameworkMemAnomaly_ is nullptr` | Memory reporting API is insufficient | Requires API 26+ |
| `flush isValid_ false` | HiAppEvent is not initialized | Check SO library loading |

---

## 10. API Version Requirements

| Feature | Minimum API | Below This Version | Alternative |
|------|---------|-----------|---------|
| HiAppEvent event reporting | API 18 | No events are generated | Use HiLog |
| HiTrace extension APIs | API 19 | No frame-drop details in Trace | Frame drop counts only |
| Memory anomaly reporting | API 26 | FrameworkMemAnomaly is not reported | Search HiLog for `heap memory` |

> HiLog logs are not restricted by API version and are always available.

---

## 11. Event Correlation Quick Reference (Saw This Event — Where to Look?)

| Event Seen | What the Problem Is | Troubleshooting Step | Which Document to Check |
|-----------|-----------|---------|-----------|
| `FLUTTER_DART_EXCEPTION` | Dart code exception | Search `Unhandled exception` to see the stack | [dfx-crash.en.md](dfx-crash.en.md) §3 |
| `FLUTTER_ETS_EXCEPTION` | ETS plugin exception | Use CONTEXT to determine the location | [dfx-crash.en.md](dfx-crash.en.md) §4 |
| `FLUTTER_THREAD_STUCK` (UI) | UI thread stuck | Check logs from the 5-10 seconds before the freeze | [dfx-appfreeze.en.md](dfx-appfreeze.en.md) §3 |
| `FLUTTER_GPU_CONTEXT_LOSS` | GPU loss | Search `GpuReclaim` to see the flow | [dfx-memory.en.md](dfx-memory.en.md) §3 |
| `OTHER_JANK` | Frame dropping | Capture a HiTrace and analyze frame durations | [dfx-performance.en.md](dfx-performance.en.md) |
| `OTHER_JANK_SCROLL` | Scrolling frame drops | Compute the frame drop rate, capture a Trace | [dfx-performance.en.md](dfx-performance.en.md) §4.3 |
| `FrameworkMemAnomaly` | Memory limit exceeded | Examine the old/new distribution, use DevTools | [dfx-memory.en.md](dfx-memory.en.md) §2 |
