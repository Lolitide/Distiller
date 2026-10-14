# App Freeze Troubleshooting Guide

> Back to [README.en.md](README.en.md)

---

## 1. What Is an App Freeze?

An app freeze (AppFreeze) means the app is "frozen solid" — the screen stops updating, buttons don't respond to taps, and swiping has no effect. Like a hung computer.

A Flutter app has three key threads (think of them as three "workers"); if any of them "goes on strike", the app freezes:

| Thread (worker) | What it does | Symptoms when stuck | Severity |
|-------------|---------|------------|---------|
| **UI thread** | Runs your Dart code and builds the UI | The screen freezes completely and touch gets no response | Fatal |
| **Raster thread** (the painter) | Turns the UI into pixels for the GPU | The screen stops updating, but touch may still respond | Severe |
| **Platform thread** (the one that talks to the system) | Handles touch events and system messages | System messages block, which can indirectly freeze the UI | Severe |

> **Beginner tips**:
> - A **UI thread freeze** is the most serious: after 6 seconds the system may pop up an "app not responding" dialog or simply kill your app
> - **Raster thread** blockages are not detected directly, but they keep frames from being drawn and drag the UI thread down with them
> - **Platform thread** blockages keep system messages (touch, keyboard, etc.) from being handled

### 1.1 Freeze Detection Mechanism (How Does the Engine Know the App Froze?)

The Flutter engine has a built-in watchdog (Watchdog), like a patrolling security guard:

```
The guard patrols every 3 seconds
│
├─ Sends a "check-in" request to the UI thread
│
└─ Checks 3 seconds later:
   ├─ The UI thread checked in → normal, keep patrolling
   └─ The UI thread didn't check in → it's stuck! Raise the alarm
      ├─ Stuck for 3 seconds → record one event (no dialog)
      └─ Stuck for 6 seconds → report to the system; an "app not responding" dialog may pop up
```

> **Note**: the watchdog directly monitors the **UI thread**. Blockages on the Raster and Platform threads indirectly freeze the UI thread (for example, if Raster stops drawing frames, the UI thread blocks waiting to submit a frame) and are ultimately caught by the UI thread's watchdog.

### 1.2 Two-Phase Reporting (the Difference Between 3 and 6 Seconds)

| Phase | Freeze duration | What happens | Visible to the user? |
|------|---------|-----------|------------|
| Phase 1 | 3 seconds | Recorded to logs, **no dialog** | The user may feel the stutter, but no dialog appears |
| Phase 2 | 6 seconds | Reported to the system; **an "app not responding" dialog may pop up** | The user sees the dialog and can choose "Wait" or "Close" |

---

## 2. How Do I Locate an App Freeze?

### 2.1 Quick Locating Flow

```
The app is frozen
│
├─ Search the logs for "is not alive"
│  └─ Found "FlutterUiThread is not alive" → the UI thread is stuck → see §3
│
├─ Search the logs for "FLUTTER_THREAD_STUCK"
│  └─ Found → the watchdog detected the freeze; check description to identify the thread
│
├─ Search the logs for "APP_FREEZE"
│  └─ Found → the UI thread has been stuck for over 6 seconds; the system is about to kill the process
│
└─ Look for the indirect cause (why did it freeze?)
   ├─ Search for "GpuReclaim" → GPU reclaim blocked Raster → see §4
   ├─ Search for "handlePlatformMessage" → platform channel blocked → see §5
   └─ Search for "external_texture" → texture callback blocked → see §4
```

> **The most critical step**: always read the logs from the **5-10 seconds before the freeze**! The cause usually happened before the watchdog raised the alarm. Like investigating a car crash, you review the dashcam footage from before the collision.

---

## 3. UI Thread Freeze

### 3.1 How Do I Confirm the UI Thread Is Frozen?

**Search command**:
```bash
hdc shell hilog | grep -E "FlutterUiThread|FlutterWatchdog|HiCollie"
```

**Typical logs (what you'll see)**:
```
[T+3s] E Flutter: FlutterWatchdog: FlutterUiThread is not alive
[T+3s] W Flutter: FlutterWatchdog: calling OH_HiCollie_Report(), m_is_six_second_event = false
[T+3s] I Flutter: FlutterWatchdog: OH_HiCollie_Report() success
[T+3s] HiAppEvent: FLUTTER_STABILITY_EVENT, eventName=FLUTTER_THREAD_STUCK
                  description: "Flutter UI thread stuck. isSixSecondEvent=false"

[T+6s] E Flutter: FlutterWatchdog: FlutterUiThread is not alive
[T+6s] W Flutter: FlutterWatchdog: calling OH_HiCollie_Report(), m_is_six_second_event = true
[T+6s] HiAppEvent: FLUTTER_STABILITY_EVENT, eventName=FLUTTER_THREAD_STUCK
                  description: "Flutter UI thread stuck. isSixSecondEvent=true"
[T+6s] The system generates the APP_FREEZE event (an "app not responding" dialog may pop up)
```

**How do I read these logs?**
- `FlutterUiThread is not alive` → the UI thread hasn't responded for 3 seconds
- `m_is_six_second_event = false` → Phase 1 (stuck for 3 seconds): recorded only, no dialog
- `m_is_six_second_event = true` → Phase 2 (stuck for 6 seconds): a dialog may appear
- `APP_FREEZE` → system-level freeze event; the process may be killed

### 3.2 Typical Symptoms

| What you observe | Severity | Notes |
|-------------|---------|------|
| The screen freezes completely; nothing responds to taps | Fatal | The UI thread has been blocked for a long time |
| An "app not responding" dialog pops up after 6 seconds | Fatal | System-level APP_FREEZE triggered |
| It hangs for a while and then recovers on its own | Medium | Recorded at the 3-second stage but recovered before 6 seconds |

### 3.3 How Do I Troubleshoot?

**Step 1**: Search for freeze logs

```bash
hdc shell hilog | grep -E "FlutterUiThread|FlutterWatchdog|FLUTTER_THREAD_STUCK"
```

**Step 2**: **Read the logs from before the freeze** (the most important step!)

```bash
hdc shell hilog > flutter_log.txt
# Find the "is not alive" line in the log file, then scroll back through the previous 5-10 seconds of logs
# The "culprit" behind the freeze usually hides there
```

**Step 3**: Capture a HiTrace for analysis (if it reproduces)

```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace
# Open chrome://tracing in Chrome → Load the file
# Search for "feedFlutterWatchdog" to check whether the heartbeat stopped
```

### 3.4 Common Causes and Fixes

#### Cause 1: Infinite Loop or Deadlock in Dart Code

**In plain language**: your code fell into an infinite loop, or two locks are waiting on each other, so the UI thread never gets out.

**Fix**:
```dart
// ❌ Wrong: infinite loop (condition is never true)
while (true) {
  if (condition) break;
}

// ❌ Wrong: deadlock (two locks waiting on each other)
// Thread A holds lock 1 and waits for lock 2
// Thread B holds lock 2 and waits for lock 1
// → both threads wait forever

// ✅ Correct: avoid nested locks and add a timeout
await lock.synchronized(() async {
  await someWork();
}, timeout: Duration(seconds: 5));
```

#### Cause 2: Time-Consuming Work on the Main Thread (File I/O, Network Requests)

**In plain language**: the UI thread is like a checkout counter — if you count cash slowly at the register, everyone queued behind you gets stuck.

**Fix**:
```dart
// ❌ Wrong: reading a large file synchronously on the main thread
final data = File('large_file.json').readAsStringSync();  // Blocks the UI!

// ✅ Correct: use async I/O
final data = await File('large_file.json').readAsString();  // Non-blocking

// ✅ Correct: use compute() to move heavy work to a separate thread
final data = await compute(_readFile, 'large_file.json');

// ✅ Correct: process large data in batches
for (var i = 0; i < list.length; i += batchSize) {
  // Process one batch
  await Future.delayed(Duration.zero);  // Give the UI a chance to respond
}
```

#### Cause 3: Heavy Computation Blocking the UI Thread

**In plain language**: processing 100,000 records on the main thread — of course it stutters.

**Fix**:
```dart
// ❌ Wrong: processing 100,000 records on the UI thread
List<Data> parseData(String json) {
  final list = jsonDecode(json) as List;
  return list.map((e) => Data.fromJson(e)).toList();  // 100,000 records will freeze the app
}

// ✅ Correct: move it to a separate isolate with compute
final data = await compute(_parseData, json);
```

#### Cause 4: Waiting on a Lock/Semaphore Whose Holder Never Releases It

**In plain language**: you're waiting for the restroom, but the person inside never comes out (they may have collapsed) — you wait forever.

**Fix**:
```dart
// ❌ Wrong: waiting without a timeout
await lock.synchronized(() async {
  // If the holder crashes, the lock is never released
});

// ✅ Correct: add a timeout
await lock.synchronized(() async {
  // ...
}, timeout: Duration(seconds: 5)).catchError((e) {
  print('Lock timed out: $e');
  return null;
});
```

---

## 4. Raster Thread Blockage (the Painter Is Stuck)

The Raster thread "paints" the UI into pixels. A blockage here is not detected directly by the watchdog, but frames stop being drawn and the UI thread is eventually dragged down with it.

### 4.1 How Do I Troubleshoot?

**Search command**:
```bash
# Search GPU-related logs (GPU reclaims often block Raster)
hdc shell hilog | grep -E "GpuReclaim|Teardown|SetDisplayWindow|Surface"

# Search external-texture-related logs
hdc shell hilog | grep -E "external_texture|NativeImage|AcquireNativeWindowBuffer"
```

**Capture a HiTrace to check the Raster heartbeat**:
```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter sched -o /data/local/tmp/trace.ftrace
# In Chrome, search for "feedFlutterRasterWatchdog" to check the Raster heartbeat
# Search for "flutter::Frame" to check frame rendering durations
```

### 4.2 Common Causes and Fixes

| Cause | Plain-language explanation | How to fix |
|------|---------|--------|
| GPU pipeline blockage | The GPU can't keep up | See [dfx-memory.en.md](dfx-memory.en.md) §3 |
| Heavy Vulkan rendering overhead | The Vulkan backend renders too slowly | Simplify the scene, or switch to OpenGL ES |
| Blocked texture callbacks | The texture's "frame conveyor belt" is stuck | See [dfx-texture.en.md](dfx-texture.en.md) §4 |
| Too many layers | Too much to paint in one frame | Reduce the number of layers; use `RepaintBoundary` |
| Blocked during GPU reclaim | Raster gets stuck while the system reclaims GPU resources | Resume rendering only after `Surface REBUILT` |

---

## 5. Platform Thread Blockage (the System-Facing Worker Is Stuck)

The Platform thread interacts with the OHOS system (handling touch events, system messages, and so on). When it blocks, system messages go unhandled.

### 5.1 How Do I Troubleshoot?

**Search command**:
```bash
hdc shell hilog | grep -E "handlePlatformMessage|onTouchEvent|MethodChannel|DartMessenger"
```

### 5.2 Common Causes and Fixes

#### Cause 1: ArkTS Plugin Handling MethodChannel Messages Too Slowly

**In plain language**: when the Platform thread receives a message from Dart, it calls the ArkTS plugin synchronously. If the plugin is slow (for example, reading a file synchronously), the Platform thread gets stuck.

**Fix** (ArkTS plugin code):
```typescript
// ❌ Wrong: reading a file synchronously inside onMethodCall
onMethodCall(call: MethodCall, result: MethodResult): void {
  const data = fs.readFileSync(path);  // Blocks!
  result.success(data);
}

// ✅ Correct: use async I/O
async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
  try {
    const data = await fs.readFile(path);  // Non-blocking
    result.success(data);
  } catch (e) {
    result.error("IO_ERROR", e.message, null);
  }
}
```

#### Cause 2: Platform Thread Waiting on the Raster Thread (Synchronous Wait)

There are 6 places in the engine where the Platform thread "synchronously waits" for the Raster thread to finish. If the Raster thread is busy, the Platform thread gets stuck.

These waits occur in the following operations:
- Surface window changes (`NotifySurfaceWindowChanged`)
- Window size changes (`NotifyChanged`)
- Engine destruction (`NotifyDestroyed`)
- Texture unregistration (`UnRegisterExternalTexture`)
- Texture replacement (`SetExternalNativeImage`)
- Texture reset (`ResetExternalTexture`)

**Fix**: these are synchronous waits inside the engine; what developers can do is avoid triggering these operations while the Raster thread is busy.

#### Cause 3: Touch Event Handling Too Slow

The Platform thread also dispatches touch events. Slow touch handling blocks the Platform thread.

**Fix**: keep touch event handling on the ArkTS side lightweight; don't do time-consuming work in touch callbacks.

---

## 6. Log Keyword Quick Reference

| Search this keyword | Meaning | When it appears |
|--------------|------|------------|
| `FlutterUiThread is not alive` | The UI thread is stuck | Whenever the UI freezes (always present) |
| `calling OH_HiCollie_Report()` | Reporting the freeze in progress | When the UI freezes |
| `OH_HiCollie_Report() success` | Report succeeded | When the UI freezes |
| `m_is_six_second_event = false` | Phase 1 (stuck for 3 seconds) | At 3 seconds of freeze |
| `m_is_six_second_event = true` | Phase 2 (stuck for 6 seconds) | At 6 seconds of freeze |
| `thread may be blocked, do not report` | Skipped to prevent false positives | Occasionally under high load (normal) |
| `FLUTTER_THREAD_STUCK` | Freeze event | Reported on every freeze |
| `APP_FREEZE` | System-level freeze event | At 6 seconds of freeze |
| `GpuReclaim` | GPU reclaim (an indirect cause of freezes) | GPU-related freezes |
| `handlePlatformMessage` | Platform messages (an indirect cause of freezes) | Platform thread blockage |

---

## 7. HiAppEvent Events

### 7.1 FLUTTER_THREAD_STUCK

**Event name**: `FLUTTER_STABILITY_EVENT` (type: FAULT)
**eventName**: `FLUTTER_THREAD_STUCK`

| Parameter | Description |
|------|------|
| `frameworkName` | Fixed as `"FLUTTER"` |
| `eventName` | Fixed as `"FLUTTER_THREAD_STUCK"` |
| `description` | Tells you which thread is stuck and for how long |
| `pid` | Process ID |
| `timeStamp` | Event time |

**How do I read description?**

| description content | Plain-language explanation |
|-----------------|---------|
| `Flutter UI thread stuck. isSixSecondEvent=false` | The UI thread has been stuck for 3 seconds (no dialog yet) |
| `Flutter UI thread stuck. isSixSecondEvent=true` | The UI thread has been stuck for 6 seconds (a dialog may have appeared) |
| `Flutter Raster thread stuck. isSixSecondEvent=false` | The Raster thread is stuck |
| `Flutter Platform thread stuck. isSixSecondEvent=false` | The Platform thread is stuck |

### 7.2 System-Level APP_FREEZE

When the UI thread is stuck for 6 seconds, the system generates an `APP_FREEZE` event. This is system-level and produced directly by the HiCollie service. It may result in:
- An app not responding dialog (the user can choose "Wait" or "Close")
- The system killing the process automatically

---

## 8. Troubleshooting Checklist

### Step 1: Confirm the Freeze

- [ ] Capture full logs: `hdc shell hilog > flutter_log.txt`
- [ ] Search for `is not alive` to identify the stuck thread
- [ ] Search for `FLUTTER_THREAD_STUCK` to view event details
- [ ] Search for `APP_FREEZE` to confirm whether a system event was triggered
- [ ] **Read the logs from the 5-10 seconds before the freeze** (most important!)

### Step 2: Find the Cause

- [ ] Search for `GpuReclaim` → was it caused by a GPU reclaim
- [ ] Search for `external_texture` → is a texture callback blocked
- [ ] Search for `handlePlatformMessage` → is the platform channel blocked
- [ ] Check the Dart code for infinite loops/deadlocks
- [ ] Check for synchronous I/O or network requests on the main thread
- [ ] Check for heavy computation blocking the UI thread

### Step 3: HiTrace Analysis

- [ ] Capture a trace: `hdc shell hitrace --trace_clock boottime -t 30 flutter`
- [ ] Search for `feedFlutterWatchdog` to check the UI heartbeat
- [ ] Search for `feedFlutterRasterWatchdog` to check the Raster heartbeat
- [ ] Search for `flutter::Frame` to view frame rendering durations
- [ ] Record what was being done when the freeze happened

---

## 9. Trace Analysis Tips

### 9.1 Normal Heartbeat (Healthy)

Normally, `feedFlutterWatchdog` appears once every 3 seconds, as regular as an ECG:

```
[0.0s] feedFlutterWatchdog     ← UI heartbeat ✓
[0.0s] feedFlutterRasterWatchdog  ← Raster heartbeat ✓
[3.0s] feedFlutterWatchdog     ← UI heartbeat ✓
[3.0s] feedFlutterRasterWatchdog  ← Raster heartbeat ✓
```

### 9.2 Abnormal Heartbeat (Frozen)

If the UI thread freezes, the heartbeat "stops":

```
[0.0s] feedFlutterWatchdog     ← last normal heartbeat
[3.0s] runHiCollieStuckDetectionTask  ← the guard notices the UI missed its check-in
[6.0s] runHiCollieStuckDetectionTask  ← still no check-in; the 6-second alarm fires
(feedFlutterWatchdog no longer appears = the UI thread is frozen)
```

### 9.3 Capture and Analyze a Trace

```bash
# Capture a 30-second trace (reproduce the freeze within those 30 seconds)
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# Open it in Chrome
# Visit chrome://tracing → click Load → select trace.ftrace
# Shortcuts: w zoom in, s zoom out, a pan left, d pan right
```
