# Log Capture and Filtering Guide

> Back to [README.en.md](README.en.md)

---

## 1. The Three Log Systems (Where Do Logs Come From?)

Logs from the Flutter OHOS platform come from three different "sources" — like a building with three floors, where the people on each floor need to be listened to in a different way:

| Log Source | Tag | Who Produces It | Typical Content | When to Look |
|---------|------------|---------|---------|-----------|
| **Engine internals** | Mapped to HiLog | C++ code of the Flutter engine | Crash stacks, freeze detection, GPU reclaim | Troubleshooting crashes, freezes, black screens |
| **Platform C++ layer** | `XComFlutterOHOS_Native` | C++ code of the OHOS platform | Engine initialization, NAPI calls | Troubleshooting engine initialization issues |
| **ETS embedding layer** | `Flutter` | ArkTS code | MethodChannel, plugin exceptions, lifecycle | Troubleshooting plugin/channel issues |

> **Beginner tip**: Not sure which one to look at? Use this command to see all Flutter logs:
> ```bash
> hdc shell hilog | grep -E "Flutter|XComFlutter|flutter"
> ```

---

## 2. Log Capture Methods

### 2.1 Basic Workflow (Just Follow These 4 Steps)

```bash
# 1. Clear historical logs (discard old ones, keep only new logs produced after reproducing the issue)
hdc shell hilog -r

# 2. Reproduce the problem (operate your app to trigger the bug)

# 3. Capture logs (press Ctrl+C to stop capturing)
hdc shell hilog > flutter_log.txt

# 4. Filter Flutter-related content from the logs
hdc shell hilog | grep -E "Flutter|XComFlutter|flutter" > flutter_filtered.txt
```

> **Beginner tip**:
> - `hilog` is the OHOS logging system, similar to Android's `logcat`
> - `grep` is a text search tool; `-E` means matching with regular expressions
> - `>` means saving the output to a file

### 2.2 Monitor Logs in Real Time (Watch Logs While Operating the App)

```bash
# Watch all Flutter logs in real time
hdc shell hilog | grep -E "Flutter|XComFlutter|flutter"

# Watch crash logs in real time
hdc shell hilog | grep -E "Caught signal|Unhandled exception|FLUTTER_"

# Watch freeze logs in real time
hdc shell hilog | grep -E "FlutterWatchdog|not alive|HiCollie"

# Watch GPU reclaim logs in real time
hdc shell hilog | grep -E "GpuReclaim|Surface"

# Watch external texture logs in real time
hdc shell hilog | grep -E "external_texture|NativeImage|texture_id"
```

### 2.3 Capture to a Device File, Then Pull It to the Computer

```bash
# Save logs to a device file
hdc shell "hilog > /data/local/tmp/flutter_log.txt"

# Pull it to the computer
hdc file recv /data/local/tmp/flutter_log.txt ./flutter_log.txt
```

### 2.4 Capture Crash Logs (tombstone)

On a native crash, the system generates a tombstone file (more detailed than hilog):

```bash
# List crash log files
hdc shell ls /data/log/faultlog/

# Pull it to the computer
hdc file recv /data/log/faultlog/faultlog-xxx ./faultlog.txt
```

### 2.5 Capture Freeze Logs (APP_FREEZE)

When the UI thread is stuck for 6 seconds, the system generates an APP_FREEZE event:

```bash
hdc shell ls /data/log/faultlog/
hdc file recv /data/log/faultlog/appfreeze-xxx ./appfreeze.txt
```

---

## 3. Log Filtering Methods

### 3.1 Filter by Problem Type (Most Common)

Not sure which one to use? Match it against your symptom:

| Problem Type | Filter Command |
|---------|---------|
| Crash (app exits abruptly) | `hdc shell hilog \| grep -E "Caught signal\|Unhandled exception\|FLUTTER_DART_EXCEPTION\|FLUTTER_ETS_EXCEPTION"` |
| Freeze (unresponsive) | `hdc shell hilog \| grep -E "FlutterWatchdog\|not alive\|HiCollie\|THREAD_STUCK\|APP_FREEZE"` |
| Jank/frame dropping | `hdc shell hilog \| grep -E "JANK\|jank\|missed\|frame"` |
| Memory (OOM) | `hdc shell hilog \| grep -E "heap memory\|memory\|OOM\|threshold"` |
| GPU (black screen) | `hdc shell hilog \| grep -E "GpuReclaim\|Surface"` |
| Vsync | `hdc shell hilog \| grep -E "vsync\|Vsync\|Poll error"` |
| External texture | `hdc shell hilog \| grep -E "external_texture\|NativeImage\|texture_id\|frame gate"` |
| Engine lifecycle | `hdc shell hilog \| grep -E "FLUTTER_ENGINE_CREATE\|FLUTTER_ENGINE_DESTROY"` |
| Platform channels | `hdc shell hilog \| grep -E "handlePlatformMessage\|MethodChannel\|Failed to handle"` |

### 3.2 Filter by Tag

```bash
# Show only engine C++ logs
hdc shell hilog -T XComFlutterOHOS_Native

# Show only ArkTS logs
hdc shell hilog -T Flutter
```

### 3.3 Filter by Level

```bash
hdc shell hilog -b D  # All logs (Debug and above)
hdc shell hilog -b I  # Info and above only
hdc shell hilog -b W  # Warn and above only
hdc shell hilog -b E  # Error and above only
```

### 3.4 Combined Filtering Tips

```bash
# Search multiple keywords (OR relation)
hdc shell hilog | grep -E "GpuReclaim|frame gate|Surface REBUILT"

# Exclude noise (NOT relation)
hdc shell hilog | grep -E "Flutter" | grep -v "flutter::"

# Look at a specific time window only
hdc shell hilog | grep "08-03 10:3[0-5]"  # logs from 10:30-10:35

# Count keyword occurrences
hdc shell hilog | grep -c "is not alive"  # how many times it froze
```

---

## 4. Log Level Reference

### 4.1 What Each Level Means

| Level | Value | Plain-Language Meaning | When to Look |
|------|------|---------|-----------|
| DEBUG | 3 | The most detailed debug information | During development and debugging |
| INFO | 4 | Key workflow milestones | To confirm a flow is working normally |
| WARN | 5 | Warning (recoverable issue) | To check for potential problems |
| ERROR | 6 | Error (a feature failed) | When troubleshooting a problem |
| FATAL | 7 | Fatal (unrecoverable) | Must be fixed |

> **Beginner tip**: When troubleshooting, it is recommended to enable DEBUG level: `hdc shell hilog -b D`

### 4.2 Can't See ETS Logs in Release Mode?

Release/Profile modes output only WARN and above by default. If you need more detailed logs:

```typescript
import Log from '@ohos.flutter.ohos/src/main/ets/util/Log';
Log.setLogLevel(HiLog.LogLevel.DEBUG);
```

---

## 5. HiTrace Capture (Dedicated to Jank Analysis)

### 5.1 What Is HiTrace?

HiTrace is a performance tracing tool that records the duration of every frame, similar to the Performance recording in Chrome DevTools.

### 5.2 How to Capture

```bash
# Capture a 10-second trace (reproduce the problem within those 10 seconds)
hdc shell hitrace --trace_clock boottime -t 10 flutter -o /data/local/tmp/trace.ftrace

# Pull it to the computer
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# Open in Chrome: visit chrome://tracing → click Load → select the file
```

### 5.3 Capture Multiple Categories at Once

```bash
# Flutter + scheduling info (for analyzing thread blocking)
hdc shell hitrace --trace_clock boottime -t 30 flutter sched -o /data/local/tmp/trace.ftrace
```

### 5.4 What to Search for in the Trace?

| Search Keyword | What to Look At | Normal Behavior |
|-----------|--------|---------|
| `flutter::Frame` | Duration of each frame | <16ms |
| `Flutter Lost Frames` | Frame drop count | Value is 0 |
| `Flutter Hitch Time` | Frame drop details | Does not appear |
| `feedFlutterWatchdog` | UI thread heartbeat | Once every 3 seconds |
| `feedFlutterRasterWatchdog` | Raster thread heartbeat | Once every 3 seconds |

> Keyboard shortcuts: `w` zoom in, `s` zoom out, `a` pan left, `d` pan right

---

## 6. DFX Key Logs at a Glance

### 6.1 Crash-Related

| Search This Keyword | Meaning | Severity |
|--------------|------|---------|
| `Caught signal SIGSEGV` | The engine accessed illegal memory | Fatal |
| `Caught signal SIGABRT` | Engine assertion failure/heap corruption | Fatal |
| `Unhandled exception` | Dart code has an uncaught exception | Fatal |
| `Failed to handle method call` | ETS plugin exception | Medium |

### 6.2 Freeze-Related

| Search This Keyword | Meaning | Severity |
|--------------|------|---------|
| `is not alive` | A thread is stuck | Fatal |
| `m_is_six_second_event = false` | Stuck for 3 seconds (first stage) | Severe |
| `m_is_six_second_event = true` | Stuck for 6 seconds (second stage, may show a dialog) | Fatal |
| `thread may be blocked, do not report` | Skipped to prevent false positives (normal) | — |

### 6.3 Memory/GPU-Related

| Search This Keyword | Meaning | Severity |
|--------------|------|---------|
| `Dart heap memory usage exceeds threshold` | Dart memory exceeds 1.5 GB | High |
| `GpuReclaim` + `kAggressive` | GPU resources reclaimed | Normal (when going to the background) |
| `GpuReclaim` + `kRestore` | GPU resources restored | Normal (when returning to the foreground) |
| `Surface REBUILT` | Surface rebuilt successfully | Normal |
| `SetDisplayWindow failed` | Surface rebuild failed | **Abnormal** |

### 6.4 External Texture-Related

| Search This Keyword | Meaning | Severity |
|--------------|------|---------|
| `No DlImage available` | No drawable image (black screen) | Medium |
| `frame gate enabled` | Background frame gate enabled | Normal |
| `skip one frame(slow consumer)` | Frame skipped due to slow consumption | Medium |
| `PlatformViewVisibleAreaEventCallback` | Visible area changed | — |

### 6.5 Vsync-Related

| Search This Keyword | Meaning | Severity |
|--------------|------|---------|
| `vsync_handle_ is nullptr` | Invalid Vsync handle | Fatal |
| `AwaitVSync...failed` | Vsync request failed | Fatal |
| `Failed to dlopen libnative_vsync.so` | Vsync library failed to load | Fatal |

---

## 7. FAQ

### Q1: Can't Capture Flutter Logs?

| Cause | Solution |
|------|---------|
| Log level not enabled | `hdc shell hilog -b D` |
| hilog service not running | `hdc shell hilog -v` to check status, `hdc shell hilog -r` to clear and retry |
| Device not connected | `hdc list targets` to confirm the device |

### Q2: Can't See Detailed Logs in Release Mode?

```typescript
// Set the log level at the app entry point
Log.setLogLevel(HiLog.LogLevel.DEBUG);
```

### Q3: Where Can I View HiAppEvent Events?

```bash
# Method 1: search the reporting logs
hdc shell hilog | grep "OH_HiAppEvent_Write"

# Method 2: search for a specific event
hdc shell hilog | grep -E "FLUTTER_DART_EXCEPTION|OTHER_JANK|FLUTTER_STABILITY_EVENT"

# Method 3: check the faultlog directory
hdc shell ls /data/log/faultlog/
```

### Q4: How Do I Analyze a Trace File?

1. Open `chrome://tracing` in the Chrome browser
2. Click `Load` to load the `.ftrace` file
3. Search `flutter::` to see frame durations
4. Search `Flutter Lost Frames` to see dropped frames
5. Keyboard shortcuts: `w` zoom in, `s` zoom out

### Q5: Too Many Logs to Get Through?

```bash
# Filter by problem type (see §3.1)
hdc shell hilog | grep -E "Caught signal|Unhandled exception"

# Exclude noise
hdc shell hilog | grep -E "Flutter" | grep -v "flutter::"

# Filter by time window
hdc shell hilog | grep "08-03 10:3[0-5]"

# Save to a file and analyze offline
hdc shell hilog > flutter_log.txt
```

### Q6: HiAppEvent Event Reporting Failed?

| Error Log | Meaning | Solution |
|---------|------|---------|
| `API version too low` | The system API is too low | Requires API 18+ |
| `reportFrameworkMemAnomaly_ is nullptr` | Memory reporting API is insufficient | Requires API 26+ |
| `flush isValid_ false` | HiAppEvent is not initialized | Check SO library loading |

### Q7: How Do I Tell Which Thread a Log Belongs To?

| Search Keyword | Corresponding Thread |
|-----------|---------|
| `FlutterUiThread` / `feedFlutterWatchdog` | UI thread |
| `FlutterRasterThread` / `feedFlutterRasterWatchdog` | Raster thread |
| `FlutterPlatformThread` / `feedFlutterPlatformWatchdog` | Platform thread |
