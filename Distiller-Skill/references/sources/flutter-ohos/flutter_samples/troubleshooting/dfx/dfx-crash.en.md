# Crash Troubleshooting Guide

> Back to [README.en.md](README.en.md)

---

## 1. Three Types of Crashes

A sudden exit in a Flutter OHOS app can originate from three different "layers" — like a three-story building where each floor catches fire for different reasons and needs different ways to put the fire out:

| Crash type | Which layer it occurs in | Log keyword | Common causes |
|---------|------------|-----------|---------|
| **Native crash** | Engine's underlying layer (C++ code) | `Caught signal SIG*` | Null pointers, GPU driver crashes, corrupted memory |
| **Dart exception** | Your Dart code | `Unhandled exception` | Type errors, array out-of-bounds, null pointers |
| **ETS exception** | ArkTS plugin code | `Failed to handle` | Error inside a MethodChannel callback |

> **Beginner tips**:
> - **Dart exceptions** are the most common; they are usually bugs in your code, such as calling a method on a null variable
> - **Native crashes** are more serious — possibly an engine bug or a GPU driver problem
> - **ETS exceptions** are usually not fatal (no sudden exit), but they make a feature unusable

### Quick Decision Flow

```
The app exits suddenly
│
├─ Search the logs for "Caught signal"
│  ├─ Found → crash in the engine's underlying layer → see §2 of this document
│  └─ Not found ↓
│
├─ Search the logs for "Unhandled exception"
│  ├─ Found → bug in your Dart code → see §3 of this document
│  └─ Not found ↓
│
├─ Search the logs for "FLUTTER_ETS_EXCEPTION"
│  ├─ Found → bug in an ArkTS plugin → see §4 of this document
│  └─ Not found → go back, capture full logs, and start over
```

> **How do I search the logs?** If you don't yet know how to capture logs, first read [dfx-logging.en.md](dfx-logging.en.md) or [README.en.md](README.en.md) §2.

---

## 2. Native Crash (Crash in the Engine's Underlying Layer)

### 2.1 What Is a Native Crash?

A Native crash is a severe error in the Flutter engine's C++ code. You can think of it as "the engine itself crashed". It is usually more serious than a Dart exception, because once the engine crashes, the whole app exits immediately, with no chance to do any cleanup.

At startup the engine registers signal handlers (like installing smoke detectors). When a crash happens, the detector records the crash information and writes it to the logs.

### 2.2 Crash Signal Types (The Alarm Went Off — What Kind of Fire Is It?)

| Signal | Name | Plain-language explanation | Common causes |
|------|------|---------|---------|
| SIGSEGV | Segmentation fault | The engine accessed memory it shouldn't have | Null pointers, using an object after it was freed |
| SIGABRT | Abnormal termination | The engine called `abort()` on itself | A failed assertion (assert) in the code, corrupted memory |
| SIGFPE | Floating-point exception | A math operation went wrong | Division by zero |
| SIGBUS | Bus error | Memory alignment problem | A DMA buffer was freed too early |
| SIGTERM | Software termination | The system asked the process to exit | System resource limits |
| SIGPIPE | Broken pipe | Writing to an already-closed pipe | The IPC channel broke |

> **Beginners only need to remember**: **SIGSEGV (the most common)** = null pointer or access to freed memory; **SIGABRT** = an internal engine check found a problem and exited deliberately.

### 2.3 Typical Symptoms (How Do I Know It's a Native Crash?)

| What you observe | Possible signal | Severity | Notes |
|-------------|----------|---------|------|
| The app exits suddenly without warning, with no Dart error | SIGSEGV | Fatal | Most common; the engine accessed illegal memory |
| The log contains `CHECK failed` or `assert` before the sudden exit | SIGABRT | Fatal | An internal engine assertion failed |
| Screen corruption/green screen followed by a sudden exit | SIGSEGV | Fatal | GPU memory corrupted |
| Sudden exit after going to the background and returning | SIGSEGV | Fatal | Rendering continued after GPU context loss |
| Stack contains `GPU` / `Rasterizer` at crash time | SIGSEGV/SIGABRT | Fatal | GPU driver crash |
| Stack contains `Texture` / `external_texture` at crash time | SIGSEGV | Fatal | Accessing a texture after it was freed |

### 2.4 What Does the Log Look Like?

Search the logs for `Caught signal` and you'll see something like this:

```
E Flutter: Caught signal SIGSEGV during program execution.
E Flutter: Frame 0: 0x7f8b2c3d4e50 FlutterRenderer::DrawFrame
E Flutter: Frame 1: 0x7f8b2c3d4f60 Shell::OnDrawFrame
E Flutter: Frame 2: 0x7f8b2c3d5070 fml::MessageLoopImpl::Run
```

**How do I read these logs?**
- **The first line** `Caught signal SIGSEGV` → tells you it's a segmentation fault (a null-pointer type of problem)
- **The Frame lines that follow** → this is the call stack at crash time, like a detective following clues
  - `Frame 0` is the most direct location of the crash
  - `Frame 1` and `Frame 2` are the upper levels of the call chain
  - The function names correspond to the engine source code and help you figure out which feature failed

### 2.5 How Do I Troubleshoot? (4 Steps)

**Step 1**: Search the logs and get the complete stack

```bash
hdc shell hilog | grep -A 30 "Caught signal"
```

> `-A 30` means showing 30 more lines after the matched keyword, so you can see the complete call stack.

**Step 2**: Determine the direction of investigation from the signal type

| Signal | Direction | What specifically to look for |
|------|---------|------------|
| SIGSEGV | Null pointer / dangling pointer | Search for `GpuReclaim` (GPU reclaim), `UnRegisterExternalTexture` (texture unregistration) |
| SIGABRT | Assertion failure / heap corruption | Search for `CHECK failed`, `DCheck failed` |
| SIGFPE | Division by zero | Check whether size or frame-rate calculations involve a 0 value |
| SIGBUS | Memory mapping invalidated | Check whether a DMA buffer was freed too early |

**Step 3**: Determine which part failed from the function names in the stack

- Function names in the stack map directly to file names in the engine source
- If a function name shows `Unknown`, use the `addr2line` tool to translate the address into a source line number:
  ```bash
  addr2line -e libflutter.so -f -C 0x7f8b2c3d4e50
  ```
- **Focus on Frame 0** (the topmost) — that is where the crash happened

**Step 4**: Search the logs from **before** the crash (find the "fuse")

```bash
# Logs from the 5-10 seconds before the crash usually contain the trigger
hdc shell hilog | grep -B 50 "Caught signal"
```

> `-B 50` means showing 50 lines before the matched keyword — like reviewing surveillance footage from before the crime.

### 2.6 Common Crash Scenarios and Fixes

#### Scenario 1: GPU Driver Crash

**How to recognize it?** The stack contains terms like `GPUSurface`, `Rasterizer`, and `SkSurface`.

**Possible causes and fixes**:

| Cause | How to investigate | How to fix |
|------|---------|--------|
| Rendering before recovery from a GPU reclaim | Search `GpuReclaim` and check for `Surface REBUILT` | Make sure rendering starts only after `OnGrContextCreated` completes (see [dfx-memory.en.md](dfx-memory.en.md) §3) |
| Surface rebuild failure | Search `SetDisplayWindow failed` | Check whether the native_window is still valid |
| Vulkan driver bug | Check whether the Vulkan backend is in use | Try switching to the OpenGL ES backend |
| Overly complex shaders | Check for complex custom shaders | Simplify the fragment shader |

#### Scenario 2: Accessing a Texture After It Was Freed

**How to recognize it?** The stack contains `Texture`, `external_texture`, or `OHOSExternalTexture`.

**In plain language**: it's like throwing away a delivery box while someone is still taking things out of it — of course that causes problems.

| Cause | How to investigate | How to fix |
|------|---------|--------|
| The native side keeps writing after the texture is unregistered | Search `UnRegisterExternalTexture` | **Stop the producer first, then unregister the texture** (order matters) |
| An external NativeImage is freed too early | Search `SetExternalNativeImage` | Make sure the external resource outlives the texture |
| GPU resources are still referenced after the GPU context is destroyed | Search `OnGrContextDestroyed` | Confirm that `OnTextureUnregistered` releases the resources |

**The correct unregistration order** (see [dfx-texture.en.md](dfx-texture.en.md) §3):
```typescript
// Step 1: stop production on the native side first (for example, pause video playback)
stopProducer();
// Step 2: then unregister the texture
textureRegistry.unregisterTexture(textureId);
```

#### Scenario 3: Double Engine Destruction

**How to recognize it?** The stack contains `~Shell` and `Destroy`, and the signal is SIGABRT.

**In plain language**: it's like returning your room key at checkout and then returning it again — the front desk gets confused.

| Cause | How to investigate | How to fix |
|------|---------|--------|
| `engine.destroy()` called multiple times | Count `FLUTTER_ENGINE_DESTROY` occurrences | Add a null check and make sure it is destroyed only once |
| Split view mode triggers `onDestroy` by mistake | Check when `FlutterPage.onDestroy` is called | In split view mode, check whether it was invoked by mistake |

```typescript
// Correct approach: add a null check
onAbilityDestroy() {
  this.flutterEngine?.destroy();
  this.flutterEngine = null;  // Prevent double destruction
}
```

#### Scenario 4: Skia Rendering Exception

**How to recognize it?** The stack contains `SkCanvas`, `SkSurface`, or `GrDirectContext`.

| Cause | How to investigate | How to fix |
|------|---------|--------|
| A CustomPainter accesses freed resources | Check whether the CustomPainter holds external references | Make sure it holds no external resources that could be freed |
| Rendering continues after GPU context loss | Search `GpuReclaim` | Pause rendering after `OnGrContextDestroyed` |
| A Picture is passed across isolates | Check whether Pictures are passed between isolates | Convert with `toImage` before passing |

---

## 3. Dart Exceptions (Your Code Has a Bug)

### 3.1 What Is a Dart Exception?

This is the most common cause of crashes — your Dart code threw an exception that wasn't caught by `try-catch`. For example, you called `null.toString()`, or accessed `list[100]` in a list with only 10 elements.

An uncaught Dart exception causes the isolate to exit and the app to exit suddenly. The engine catches it automatically and records it in the logs.

> **Beginner tip**: Dart exceptions are the easiest crashes to fix, because the log tells you the exact line of code that failed.

### 3.2 Typical Symptoms

| What you observe | Severity | Notes |
|-------------|---------|------|
| The app exits suddenly and the log contains `Unhandled exception` | High | Most common; your Dart code has an uncaught exception |
| Incomplete exception information (truncated) | Medium | The error message was too long (>4096 characters) and got truncated |
| HiLog only, no HiAppEvent | Medium | The system API version is too low (< 18) |
| Exceptions in async code | High | A `Future` without `await` or `.catchError` |

### 3.3 What Does the Log Look Like?

**HiLog output**:
```
E Flutter: Unhandled exception:
E Flutter: type 'Null' is not a subtype of type 'String'
E Flutter: #0      main (package:myapp/main.dart:12:5)
E Flutter: #1      _runMain (package:myapp/main.dart:8:3)
```

**How do I read these logs?**
- The first line `Unhandled exception:` → tells you this is an uncaught Dart exception
- The second line `type 'Null' is not a subtype of type 'String'` → this is the error: you tried to use null as a String
- `#0 main (package:myapp/main.dart:12:5)` → this is the location of the failing code!
  - `#0` is frame 0 (the most direct location of the error)
  - `package:myapp/main.dart` → your `main.dart` file
  - `12:5` → line 12, column 5

> **Beginner tip**: just open the file and line number called out in the log — the problem is usually obvious at a glance.

### 3.4 How Do I Troubleshoot? (4 Steps)

**Step 1**: Search the logs and get the complete stack

```bash
hdc shell hilog | grep -A 30 "Unhandled exception"
```

**Step 2**: Open the code file named in the log and go to the failing line

- Format: `#frame number function name (file path:line:column)`
- Start from `#0` and find the line beginning with `package:your_app_name/` — that's your code
- Lines beginning with `dart:` or `package:flutter/` are framework code and usually not your problem

**Step 3**: Determine the cause from the exception type

| Exception type | Plain-language explanation | Common scenario | How to fix |
|---------|---------|---------|--------|
| `NoSuchMethodError` | A method was called on null | `null.toString()` | Add a null check: `obj?.toString()` |
| `TypeError` | Type mismatch | `value as String` but value is null | Use a safe conversion: `value?.toString() ?? ''` |
| `RangeError` | Index out of bounds | `list[100]` in a list of 10 elements | Add a bounds check |
| `StateError` | Object in a bad state | Reading from a closed StreamController | Check the object state |
| `FormatException` | Bad format | `json.decode('invalid')` | Check the input format |
| `Stack Overflow` | Stack overflow | Recursion with no termination condition | Add a recursion termination condition |
| `LateInitializationError` | A `late` variable was used before initialization | `late String s;` then using `s` directly | Make sure it is assigned before use |

**Step 4**: Debug with DevTools (more intuitive)

```bash
flutter run --ohos
# Open DevTools in the browser
# Enable "Stop on uncaught exceptions" (pause on uncaught exceptions)
# Reproduce the problem; the debugger pauses where the error occurs so you can inspect all variable values
```

### 3.5 Common Dart Exceptions and Fixes

#### Problem 1: Null Pointer (the Most Common!)

**Failing code**:
```dart
// Suppose user may be null
String name = user.name.toUpperCase();  // Crashes here if user is null
```

**Fix**:
```dart
// Option 1: safe call with ?. (recommended)
String name = user?.name?.toUpperCase() ?? 'unknown';

// Option 2: check before use
if (user != null) {
  String name = user.name.toUpperCase();
}
```

#### Problem 2: Uncaught Async Exceptions

**Failing code**:
```dart
// This exception is not caught by try-catch because there is no await!
Future.delayed(Duration(seconds: 1), () {
  throw Exception('async error');
});  // Without await, the exception is lost or causes a sudden exit
```

**Fix**:
```dart
// Option 1: add await + try-catch
try {
  await Future.delayed(Duration(seconds: 1), () {
    throw Exception('async error');
  });
} catch (e, s) {
  print('Caught exception: $e\n$s');
}

// Option 2: use catchError
Future.delayed(Duration(seconds: 1), () {
  throw Exception('async error');
}).catchError((e, s) {
  print('Caught exception: $e\n$s');
});

// Option 3 (recommended): global fallback with runZonedGuarded in main
runZonedGuarded(() {
  runApp(MyApp());
}, (error, stackTrace) {
  // All uncaught exceptions end up here
  print('Globally caught: $error\n$stackTrace');
});
```

#### Problem 3: Type Conversion Error

**Failing code**:
```dart
// Crashes here if name in the JSON is null
String name = json['name'] as String;

// Also crashes if price in the JSON is 100 (int)
double price = json['price'] as double;
```

**Fix**:
```dart
// Safe string conversion
String name = json['name']?.toString() ?? '';

// Safe number conversion (handles both int and double)
double price = (json['price'] as num)?.toDouble() ?? 0.0;
```

#### Problem 4: Array Out-of-Bounds

**Failing code**:
```dart
var item = items[index];  // Crashes if index is out of range
```

**Fix**:
```dart
// Option 1: add a bounds check
if (index >= 0 && index < items.length) {
  var item = items[index];
}

// Option 2: use elementAtOrNull (Dart 3.0+)
var item = items.elementAtOrNull(index);  // Returns null instead of crashing when out of bounds
```

#### Problem 5: Error Inside a MethodChannel Callback

**Failing code**:
```dart
// The app exits suddenly if _loadData() throws
_methodChannel.setMethodCallHandler((call) async {
  if (call.method == 'getData') {
    return _loadData();  // An exception thrown here causes a sudden exit
  }
});
```

**Fix**:
```dart
_methodChannel.setMethodCallHandler((call) async {
  try {
    if (call.method == 'getData') {
      return await _loadData();
    }
  } catch (e, s) {
    print('MethodChannel error: $e\n$s');
    return null;  // Return a default value; don't let the exception escape
  }
});
```

### 3.6 Notes

- Error messages are at most 4096 characters; anything longer is truncated (if the message is incomplete, search HiLog for the full one)
- Stacks are at most 8192 characters; anything longer is truncated
- When the system API is below 18, no HiAppEvent events are generated (HiLog is still available)

---

## 4. ETS Exceptions (ArkTS Plugin Layer Exceptions)

### 4.1 What Is an ETS Exception?

ETS is short for ArkTS (OHOS's programming language). An ETS exception occurs when your ArkTS plugin code fails while handling a MethodChannel message.

> **Beginner tips**:
> - ETS exceptions usually **do not cause a sudden exit** (they are caught by try-catch)
> - But they make **a feature unusable** (for example, a MethodChannel call gets no response)
> - If you are using a third-party plugin, the problem may be a bug in the plugin's code

### 4.2 Typical Symptoms

| What you observe | Severity | Notes |
|-------------|---------|------|
| MethodChannel calls get no response | Medium | The plugin handler failed and returned no result |
| A feature suddenly stops working | Medium | The ETS exception was caught, but the feature failed |
| The app doesn't exit suddenly but a feature misbehaves | Low | ETS exceptions don't cause sudden exits |
| MethodChannel returns an error | Low | The plugin caught the exception and returned an error |

### 4.3 What Does the Log Look Like?

**HiLog output** (search for `Failed to handle` or `FLUTTER_ETS_EXCEPTION`):
```
E Flutter: MethodChannel# Failed to handle method call
E Flutter: TypeError: Cannot read property 'length' of undefined
E Flutter:     at MethodChannel.onMessage (MethodChannel.ets:227:15)
```

**How do I read these logs?**
- `Failed to handle method call` → MethodChannel message handling failed
- `TypeError: Cannot read property 'length' of undefined` → you tried to read the `length` property of undefined
- `at MethodChannel.onMessage (MethodChannel.ets:227:15)` → the failure is at line 227 of the MethodChannel.ets file

### 4.4 How Do I Troubleshoot?

**Step 1**: Search for ETS exception logs

```bash
hdc shell hilog | grep -E "FLUTTER_ETS_EXCEPTION|Failed to handle|Uncaught exception in"
```

**Step 2**: Use CONTEXT to determine which stage the exception occurred in

| CONTEXT value | Plain-language explanation | Where to investigate |
|-----------|---------|---------|
| `MethodChannel.onMessage` | Error while the plugin receives a message | Check the plugin's `onMethodCall` method |
| `MethodChannel.reply` | Error while processing the reply | Check the callback code on the Dart side |
| `DartMessenger.invokeHandler` | Error while handling a binary message | Check the BinaryMessageHandler |
| `DartMessenger.handlePlatformMessageResponse` | Error while handling a message reply | Check the BinaryReply callback |

**Step 3**: Open the failing ETS file and go to the line number

- STACK_TRACE format: `at function name (file:line:column)`
- Focus on `undefined` / `null` accesses

### 4.5 Common Causes and Fixes

#### Problem 1: MethodChannel Argument Is undefined

**Failing code** (ArkTS plugin):
```typescript
// If call.argument("name") returns undefined, the code below crashes
onMethodCall(call: MethodCall, result: MethodResult): void {
  const name: string = call.argument("name");
  const length = name.length;  // undefined.length → crash
}
```

**Fix**:
```typescript
onMethodCall(call: MethodCall, result: MethodResult): void {
  const name = call.argument("name");
  // Null check first!
  if (name === undefined || name === null) {
    result.error("INVALID_ARGS", "name must not be empty", null);
    return;
  }
  const length = (name as string).length;
}
```

#### Problem 2: Message Codec Mismatch

**Symptom**: the Dart side and the ETS side use different codecs, so argument parsing fails.

**Fix**:
```dart
// Make sure both sides use the same codec
// The Dart side uses StandardMethodCodec by default
// The ETS side also uses StandardMethodCodec (the default)

// If you use a custom codec, make sure both sides match
// Check that argument types line up:
// Dart int    ↔ ETS number
// Dart String ↔ ETS string
// Dart bool   ↔ ETS boolean
// Dart List   ↔ ETS Array
// Dart Map    ↔ ETS object
```

### 4.6 Characteristics

- ETS exceptions **do not cause sudden exits** (they are caught by try-catch)
- After `MethodChannel.onMessage` catches one, it automatically returns an error to the Dart side
- After `DartMessenger.invokeHandler` catches one, it sends an empty reply
- But the feature is affected (message handling failed)

---

## 5. Crash Troubleshooting Checklist

When you hit a crash, follow this checklist step by step:

### Step 1: Confirm the Crash Type

- [ ] Capture full logs: `hdc shell hilog > flutter_log.txt`
- [ ] Search for `Caught signal` → if present, it's a Native crash (§2)
- [ ] Search for `Unhandled exception` → if present, it's a Dart exception (§3)
- [ ] Search for `FLUTTER_ETS_EXCEPTION` / `Failed to handle` → if present, it's an ETS exception (§4)

### Step 2: If It Is a Native Crash

- [ ] Record the signal type (SIGSEGV? SIGABRT?)
- [ ] Record the function names and addresses in the stack
- [ ] Resolve `Unknown` function names with `addr2line`
- [ ] Search the 50 lines before the crash for the "fuse": `grep -B 50 "Caught signal"`
- [ ] Search for `GpuReclaim` to confirm whether the GPU is involved
- [ ] Search for `UnRegisterExternalTexture` to confirm whether textures are involved

### Step 3: If It Is a Dart Exception

- [ ] Read the complete stack and find the `package:your_app_name/` line
- [ ] Open the corresponding code file and line number
- [ ] Identify the exception type (null pointer? type error? out-of-bounds?)
- [ ] Check whether it's an async exception (Future without await / without catchError)
- [ ] Debug with DevTools' "Stop on uncaught exceptions"

### Step 4: If It Is an ETS Exception

- [ ] Use CONTEXT to determine the stage where the exception occurred
- [ ] Open the corresponding ETS file and line number
- [ ] Check whether any argument is undefined / null
- [ ] Check whether MethodChannel argument types match

### General

- [ ] Record what was done before the crash (which button was tapped, which page was opened)
- [ ] Check whether it reproduces reliably (bugs that reproduce are the easiest to fix)

---

## 6. HiAppEvent Event Parameters

### 6.1 FLUTTER_DART_EXCEPTION

| Parameter | Type | Limit | Description |
|------|------|------|------|
| `frameworkName` | String | — | Fixed as `"FLUTTER"` |
| `errorMsg` | String | ≤4096 characters | Exception error message |
| `stackTrace` | String | ≤8192 characters | Exception stack |
| `pid` | Int64 | — | Process ID |
| `timeStamp` | Int64 | — | Event time (UTC ms) |

### 6.2 FLUTTER_ETS_EXCEPTION

| Parameter | Type | Description |
|------|------|------|
| `EVENT_NAME` | String | Fixed as `"FLUTTER_ETS_EXCEPTION"` |
| `CONTEXT` | String | Stage where the exception occurred (see §4.4) |
| `ERROR_MSG` | String | Exception error message |
| `STACK_TRACE` | String | Exception stack |
