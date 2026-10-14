# Flutter OHOS Rendering Flow and Exception Diagnosis Tutorial

> Scope: Rendering flow tracing and locating white screen and other rendering exceptions on the Flutter OHOS platform (`shell/platform/ohos`).
> Goal: Help developers and operations engineers understand the complete Flutter flow from startup to first frame rendering through logs, and quickly locate rendering exceptions.
> **Document Version**: v4 (based on oh-3.22.3-dev branch + logging system optimization, LOGI macro fixed for Release visibility, OHOS_LOGI added to shell/common)

---

## Rendering Flow Overview

The complete flow of a Flutter OHOS app from startup to the first frame presented to screen:

```text
[ArkTS] FlutterEntry / FlutterView
   │
   ├──> (1) OhosMain::Init ───────────────────────── ohos_main.cpp
   │        └─ Engine initialization, rendering API selection
   │
   ├──> (2) OHOSShellHolder Creation ─────────────── ohos_shell_holder.cpp
   │        ├─ Thread creation (raster/ui/io)
   │        ├─ Shell::Create
   │        └─ PlatformViewOHOS creation
   │
   ├──> (3) XComponent Surface Callback ──────────── ohos_xcomponent_adapter.cpp
   │        ├─ OnSurfaceCreated (OS triggered)
   │        └─ PlatformViewOHOS::NotifyCreate
   │            └─ SetDisplayWindow → Rasterizer::Setup
   │
   ├──> (4) OHOSShellHolder::Launch ──────────────── ohos_shell_holder.cpp
   │        └─ Start Dart Engine, run isolate
   │
   ├──> (5) VsyncWaiter Creation ─────────────────── vsync_waiter_ohos.cpp
   │        └─ Register vsync callback
   │
   ├──> (6) Dart scheduleFrame → First Frame Request ─ engine.cc
   │        └─ Animator::RequestFrame → AwaitVSync
   │
   ├──> (7) Vsync Callback → BeginFrame ──────────── animator.cc
   │        └─ Dart window.onBeginFrame → build → render
   │
   ├──> (8) Engine::Render ───────────────────────── engine.cc
   │        └─ Validate layer_tree → Animator::Render
   │
   └──> (9) Rasterizer::Draw ─────────────────────── rasterizer.cc
            ├─ DoDraw → DrawToSurfaces → DrawToSurfaceUnsafe
            ├─ AcquireFrame → Raster → Submit
            └─ First frame callback → FlutterView.onFirstFrame
```

---

## Key Log Nodes (Chronological)

The following logs fall into two categories:
- **`LOGI` / `OHOS_LOGI`**: Visible in Release builds, used for key flow nodes
- **`FML_LOG(INFO)`**: Visible in Debug builds, filtered out in Release builds (`min_log_level = kLogWarning`)

### Stage 1: Engine Initialization

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `OhosMain init done, rendering_api=<api>` | INFO | ohos_main.cpp | ✅ | Engine initialization complete; api=2 means Vulkan Impeller |
| `BuildRunConfiguration failed (kernel/snapshot unreadable)` | ERROR | ohos_shell_holder.cpp | ✅ | Run configuration build failed; kernel/snapshot files unreadable |
| `Unable to load the kernel blob asset.` | ERROR | ohos_shell_holder.cpp | ✅ | kernel blob asset loading failed |

**Diagnosis Points**:
- If `OhosMain init done` does not appear, check for engine initialization failure (e.g., `FML_CHECK` crash, resource loading failure)
- `rendering_api` values: 1=OpenGL, 2=Vulkan, 3=Software
- `BuildRunConfiguration failed` or `Unable to load the kernel blob asset` means the Dart kernel file is missing or corrupted; check the hap package integrity

### Stage 2: Surface Binding

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `Rasterizer::Setup done.` | INFO | rasterizer.cc | ✅ | Rasterizer has bound the surface |
| `SetDisplayWindow result=true/false window=<addr>` | INFO | platform_view_ohos.cpp | ✅ | Result of binding the surface to the XComponent |
| `NotifyCreated called, onscreen_valid=true/false` | INFO | platform_view_ohos.cpp | ✅ | PlatformView notified that creation is complete |

**Diagnosis Points**:
- `Rasterizer::Setup done` indicates the `PlatformViewOHOS::NotifyCreate` → `SetDisplayWindow` → `Rasterizer::Setup` chain succeeded
- `SetDisplayWindow result=false` means surface binding failed; check whether native_window is valid
- **Note**: In the Impeller Vulkan path, `Rasterizer::Setup done` may not appear (the surface is initialized through an independent path), but this does not indicate an exception

### Stage 3: Dart Render Request

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `Render layer_tree IS NULL` | WARNING | engine.cc | ✅ | The layer_tree passed from Dart is null (severe exception) |
| `engin Render frame_size is empty` | WARNING | engine.cc | ✅ | Viewport not ready at startup, frame skipped (**expected, not an exception**) |
| `engin Render device_pixel_ratio <= 0, dpr=<value>` | WARNING | engine.cc | ✅ | Viewport not ready at startup, frame skipped (**expected, not an exception**) |

**Diagnosis Points**:
- `layer_tree IS NULL`: severe error on the Dart side; check the Dart code
- `frame_size is empty` / `device_pixel_ratio <= 0`: **Release visible since v3**. Appearing early in startup (before the XComponent is ready) is **normal timing**; persistent occurrence is abnormal

### Stage 4: Rasterizer Rendering

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `rasterizer no surface, frame dropped (kNotSetUp)` | ERROR | rasterizer.cc | ✅ | Surface not ready, frame dropped (**expected at startup, printed only once**) |
| `GPU unavailable (sync switch), frame dropped` | ERROR | rasterizer.cc | ✅ | GPU disabled (e.g., background switch), frame dropped |
| `AcquireFrame returned null.` | ERROR | rasterizer.cc | ✅ | Surface valid but AcquireFrame failed (swapchain invalid) |
| `compositor AcquireFrame failed` | ERROR | rasterizer.cc | ✅ | Compositor could not acquire a draw frame |

**Diagnosis Points**:
- `kNotSetUp`: **appearing only once early in startup is normal** (guarded by `static bool logged`). If it appears persistently or during runtime, it means:
  - `Rasterizer::Setup` was not called (the ArkTS side did not call `notifyCreate`)
  - The surface was destroyed and not rebuilt (e.g., background/foreground switch exception)
- `GPU unavailable`: the app is in the background or the GPU was reclaimed by the system; it should recover automatically after returning to the foreground
- `AcquireFrame null`: surface lost or insufficient GPU resources; an app restart may be required

### Stage 5: Frame Submission (SurfaceFrame)

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `SurfaceFrame::Submit already submitted` | WARNING | surface_frame.cc | ✅ | Frame submitted twice (logic exception) |
| `SurfaceFrame::Submit failed` | ERROR | surface_frame.cc | ✅ | Frame submission failed |
| `SurfaceFrame::PerformSubmit submit_callback is null` | ERROR | surface_frame.cc | ✅ | Submit callback is null (severe exception) |
| `SurfaceFrame::PerformSubmit submit_callback failed` | ERROR | surface_frame.cc | ✅ | Submit callback execution failed |

**Diagnosis Points**:
- `already submitted`: the same frame was submitted twice; check the Rasterizer logic
- `submit_callback is null`: the Surface did not set the submit callback correctly; check the Surface implementation
- `submit_callback failed`: GPU submission failed; check the GL/Vulkan context state

### Log Capture and Filtering

When a rendering exception occurs, capture and filter logs as follows:

```bash
# 1) Clear historical logs
hdc shell hilog -r
# 2) Reproduce the issue, then capture full logs (Ctrl+C to stop)
hdc shell hilog > flutter_log.txt
# 3) Filter Flutter rendering logs
hdc shell hilog | grep -E "Flutter|XComponent|rasterizer|Rasterizer|Impeller|Vulkan|frame_gate|first-frame" > flutter_render.txt
```

Filter by issue type:

```bash
# Engine initialization / Surface binding
hdc shell hilog | grep -E "OhosMain|Rasterizer::Setup|SetDisplayWindow|NotifyCreated"
# Rendering pipeline / frame submission
hdc shell hilog | grep -E "engin Render|layer_tree|SurfaceFrame|kNotSetUp|AcquireFrame"
# GPU context (GL / Vulkan)
hdc shell hilog | grep -E "eglGetDisplay|eglCreate|ContextVK|GPUSurface|Could not create"
# Vsync / viewport
hdc shell hilog | grep -E "NativeVSync|viewport metrics|frame_gate"
# UI thread blocking / first frame
hdc shell hilog | grep -E "FlutterWatchdog|first-frame|onFirstFrame"
```

---

## GPU Context and Surface Creation Logs

The following logs are output during GPU context and EGL/Vulkan surface creation, and are used to diagnose GPU initialization issues.

### GL Skia Path

| Log Content | Level | Source | Meaning |
|---|---|---|---|
| `eglGetDisplay failed` | ERROR | ohos_environment_gl.cpp | Failed to obtain the EGL display |
| `eglInitialize failed` | ERROR | ohos_environment_gl.cpp | EGL initialization failed |
| `eglCreateWindowSurface returned EGL_NO_SURFACE err=<code>` | ERROR | ohos_context_gl_skia.cpp | Window surface creation failed |
| `eglCreatePbufferSurface returned EGL_NO_SURFACE err=<code>` | ERROR | ohos_context_gl_skia.cpp | Offscreen surface creation failed |
| `SetNativeWindow onscreen_surface invalid` | ERROR | ohos_surface_gl_skia.cpp | onscreen surface created but invalid |

### GL Impeller Path

| Log Content | Level | Source | Meaning |
|---|---|---|---|
| `Could not create EGL display.` | ERROR | ohos_surface_gl_impeller.cpp | EGL display creation failed |
| `Could not choose onscreen config.` | ERROR | ohos_surface_gl_impeller.cpp | Failed to choose the onscreen EGL config |
| `Could not choose offscreen config.` | ERROR | ohos_surface_gl_impeller.cpp | Failed to choose the offscreen EGL config |
| `Could not create onscreen context.` | ERROR | ohos_surface_gl_impeller.cpp | onscreen GL context creation failed |
| `Could not create offscreen context.` | ERROR | ohos_surface_gl_impeller.cpp | offscreen GL context creation failed |
| `Could not create offscreen surface.` | ERROR | ohos_surface_gl_impeller.cpp | offscreen surface creation failed |
| `Could not make offscreen context current.` | ERROR | ohos_surface_gl_impeller.cpp | Failed to make the offscreen context current |
| `Could not create Impeller context.` | ERROR | ohos_surface_gl_impeller.cpp | Impeller context creation failed |
| `Could not clear offscreen context.` | ERROR | ohos_surface_gl_impeller.cpp | Failed to clear the offscreen context |
| `Could not add lifecycle listeners` | ERROR | ohos_surface_gl_impeller.cpp | Failed to add lifecycle listeners |
| `Could not create onscreen surface.` | ERROR | ohos_surface_gl_impeller.cpp | onscreen surface creation failed |
| `GPUSurfaceGLImpeller delegate is null` | ERROR | gpu_surface_gl_impeller.cc | GPU surface delegate is null |
| `GPUSurfaceGLImpeller context invalid` | ERROR | gpu_surface_gl_impeller.cc | Impeller context invalid |
| `GPUSurfaceGLImpeller renderer invalid` | ERROR | gpu_surface_gl_impeller.cc | Impeller renderer invalid |
| `GPUSurfaceGLImpeller aiks_context invalid` | ERROR | gpu_surface_gl_impeller.cc | Aiks context invalid |

### Vulkan Impeller Path

| Log Content | Level | Source | Meaning |
|---|---|---|---|
| `ContextVK::Create returned null` | ERROR | ohos_context_vulkan_impeller.cpp | Vulkan Impeller context creation failed |
| `CreateSurfaceContext returned null` | ERROR | ohos_surface_vulkan_impeller.cpp | Vulkan surface context creation failed |
| `SetWindowSurface failed` | ERROR | ohos_surface_vulkan_impeller.cpp | Vulkan window surface setup failed |
| `GPUSurfaceVulkanImpeller context invalid` | ERROR | gpu_surface_vulkan_impeller.cc | Vulkan Impeller context invalid |
| `GPUSurfaceVulkanImpeller renderer invalid` | ERROR | gpu_surface_vulkan_impeller.cc | Vulkan renderer invalid |
| `GPUSurfaceVulkanImpeller aiks_context invalid` | ERROR | gpu_surface_vulkan_impeller.cc | Vulkan Aiks context invalid |

### Software Path

| Log Content | Level | Source | Meaning |
|---|---|---|---|
| `software surface unsupported format=<fmt>, frame content skipped` | WARNING | ohos_surface_software.cpp | Software rendering hit an unsupported pixel format; frame content skipped |

---

## XComponent and Lifecycle Logs

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `XComponent SurfaceCreated window=<addr> engine_attached=true/false` | INFO | ohos_xcomponent_adapter.cpp | ✅ | XComponent surface created |
| `XComponent destroyed, id=<id>` | INFO | ohos_xcomponent_adapter.cpp | ✅ | XComponent destroyed |
| `frame_gate enabled=false reason=SurfaceCreated` | INFO | platform_view_ohos.cpp | ✅ | Frame gate closed after surface creation |
| `frame_gate enabled=true reason=ExecuteAggressive` | INFO | platform_view_ohos.cpp | ✅ | Frame gate opened during aggressive reclaim |
| `frame_gate enabled=false reason=PiP_visible` | INFO | platform_view_ohos.cpp | ✅ | Frame gate closed when PiP is visible |
| `frame_gate enabled=false reason=ExecuteAggressiveCore` | INFO | platform_view_ohos.cpp | ✅ | Frame gate closed after aggressive reclaim core execution |
| `first-frame callback.` | INFO | platform_view_ohos.cpp | ✅ | First frame callback installed |
| `first-frame fired` | INFO | platform_view_ohos.cpp | ✅ | First frame callback fired |
| `first-frame wait cleared` | INFO | shell.cc | ✅ | First frame wait condition cleared |
| `rebuild skipped, surface=yes/no window=yes/no valid=true/false` | INFO | platform_view_ohos.cpp | ✅ | onscreen context rebuild skipped |
| `GpuReclaim: [Raster] rebuild SetDisplayWindow failed, no retry` | ERROR | platform_view_ohos.cpp | ✅ | SetDisplayWindow failed during rebuild |

---

## Vsync Logs

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `OH_NativeVSync_Create returned null` | ERROR | vsync_waiter_ohos.cpp | ✅ | Vsync handle creation failed |
| `OH_NativeVSync_RequestFrameWithMultiCallback failed: <code>` | ERROR | vsync_waiter_ohos.cpp | ✅ | vsync frame callback request failed |

---

## Viewport Metrics Logs

| Log Content | Level | Source | Release Visible | Meaning |
|---|---|---|---|---|
| `invalid viewport metrics dpr=<dpr> w=<w> h=<h>` | WARNING | shell.cc | ✅ | Viewport parameters invalid; frame ignored |

**Diagnosis Points**:
- Appearing early in startup is **normal timing** (XComponent not ready)
- If it appears persistently or `dpr <= 0`, check the viewport settings on the ArkTS side

---

## Normal Startup Log Example

```log
# Stage 1: Engine initialization
[INFO:ohos_main.cpp] OhosMain init done, rendering_api=2

# Stage 2: XComponent loading (ArkTS side logs)
[INFO:AceXcomponent] XComponent[oh_flutter_1] triggers onLoad and OnSurfaceCreated callback
[INFO:AceXcomponent] XComponent[oh_flutter_1] native OnSurfaceCreated

# Stage 3: Startup timing race (may appear, normal)
[ERROR:rasterizer.cc] rasterizer no surface, frame dropped (kNotSetUp)

# Stage 4: Surface binding successful
[INFO:rasterizer.cc] Rasterizer::Setup done.
[INFO:platform_view_ohos.cpp] SetDisplayWindow result=1 window=0x...
[INFO:platform_view_ohos.cpp] NotifyCreated called, onscreen_valid=1

# Stage 5: First frame callback
[INFO:platform_view_ohos.cpp] first-frame callback.
[INFO:platform_view_ohos.cpp] first-frame fired
[INFO:shell.cc] first-frame wait cleared

# (No new ERROR logs afterwards = rendering normal)
```

---

## Exception Scenario Diagnosis

### Scenario 1: White Screen (First Frame Not Presented to Screen for a Long Time)

**Diagnosis Flow**:

1. **Check whether the engine was initialized**
   - Search for `OhosMain init done`
   - Not found → engine initialization failed; check crash logs or `FML_CHECK`

2. **Check whether the XComponent was loaded**
   - Search `XComponent` logs (ArkTS side)
   - Not found → the ArkTS side did not trigger `onLoad`; check the FlutterView configuration

3. **Check whether the surface was bound**
   - Search for `Rasterizer::Setup done`
   - Not found → `NotifyCreate` was not called; check whether the ArkTS side called `flutterView?.notifyCreate(nativeWindow)`

4. **Check for persistent kNotSetUp**
   - If `kNotSetUp` logs appear persistently (not just once at startup)
   - → surface binding failed or the surface is continuously lost; check the `SetDisplayWindow` return value

5. **Check whether the GPU is available**
   - Search for `GPU unavailable` → the app is in the background or the GPU was reclaimed

6. **Check whether AcquireFrame failed**
   - Search for `AcquireFrame returned null` → swapchain invalid; check the surface lifecycle

### Scenario 2: Screen Flickering / Corruption After Startup

**Diagnosis Flow**:

1. Check `Rasterizer::Setup done, surface_valid=false`
   - Surface invalid but rendering still attempted → check the EGL/Vulkan context creation logs

2. Check ERROR logs from `ohos_surface_vulkan_impeller.cpp` or `ohos_surface_gl_*.cpp`

### Scenario 3: White Screen After Returning from Background

**Diagnosis Flow**:

1. Check for `GPU unavailable` logs
   - Should recover automatically after returning to the foreground; if persistent → Reclaim state machine exception

2. Check whether `Rasterizer::Setup done` appears again
   - Background/foreground switching should trigger a surface rebuild; if it does not appear → `ShouldRebuildOnscreenContext` returned false

3. Check `PlatformViewOHOS` reclaim logs

### Scenario 4: Dart Layer Initialization Exception (New)

**Diagnosis Flow**:

1. Check whether `OhosMain init done` appears
   - Appears → engine initialization succeeded

2. Check whether subsequent logs such as `Rasterizer::Setup done` and `engine Render` appear
   - **If there are no Flutter rendering logs for a long time after `OhosMain init done`**
   - → possibly a Dart layer `WidgetsBinding` initialization exception, `runApp()` not executed, or a blocked Platform Channel

3. Check for `FlutterWatchdog: FlutterUiThread is not alive`
   - Appears → the UI thread is blocked; check the Dart code for deadlocks or long synchronous operations

**Typical Cases**:
- A custom `WidgetsFlutterBinding` overriding `initInstances()` caused incomplete initialization
- A plugin initialized too early in `initInstances()`, before the Platform Channel was ready
- `runApp()` not called, or an exception occurring before the call

---

## Log Level Quick Reference

| Log Prefix | Level | Release Visible | Scenario |
|---|---|---|---|
| `OhosMain init done` | INFO | ✅ | Engine initialization complete |
| `BuildRunConfiguration failed` | ERROR | ✅ | kernel/snapshot files unreadable |
| `Unable to load the kernel blob asset` | ERROR | ✅ | kernel blob loading failed |
| `Rasterizer::Setup done` | INFO | ✅ | Surface binding successful |
| `SetDisplayWindow result=` | INFO | ✅ | Surface binding result |
| `rasterizer no surface` | ERROR | ✅ | Surface not ready (**once at startup is normal**) |
| `GPU unavailable` | ERROR | ✅ | GPU disabled |
| `AcquireFrame returned null` | ERROR | ✅ | Swapchain invalid |
| `compositor AcquireFrame failed` | ERROR | ✅ | Compositor failure |
| `SurfaceFrame::Submit already submitted` | WARNING | ✅ | Frame submitted twice |
| `SurfaceFrame::Submit failed` | ERROR | ✅ | Frame submission failed |
| `SurfaceFrame::PerformSubmit submit_callback is null` | ERROR | ✅ | Submit callback is null |
| `SurfaceFrame::PerformSubmit submit_callback failed` | ERROR | ✅ | Submit callback execution failed |
| `Render layer_tree IS NULL` | WARNING | ✅ | Dart passed null (exception) |
| `engin Render frame_size is empty` | WARNING | ✅ | Viewport not ready at startup (normal timing) |
| `engin Render device_pixel_ratio <= 0` | WARNING | ✅ | Viewport not ready at startup (normal timing) |
| `invalid viewport metrics` | WARNING | ✅ | Viewport parameters invalid |
| `eglGetDisplay failed` | ERROR | ✅ | EGL display acquisition failed |
| `eglInitialize failed` | ERROR | ✅ | EGL initialization failed |
| `eglCreateWindowSurface returned EGL_NO_SURFACE` | ERROR | ✅ | EGL window surface creation failed |
| `ContextVK::Create returned null` | ERROR | ✅ | Vulkan context creation failed |
| `CreateSurfaceContext returned null` | ERROR | ✅ | Vulkan surface context creation failed |
| `SetWindowSurface failed` | ERROR | ✅ | Vulkan window surface setup failed |
| `GPUSurfaceGLImpeller context invalid` | ERROR | ✅ | GL Impeller context invalid |
| `GPUSurfaceVulkanImpeller context invalid` | ERROR | ✅ | Vulkan Impeller context invalid |
| `software surface unsupported format` | WARNING | ✅ | Software rendering format unsupported |
| `XComponent SurfaceCreated` | INFO | ✅ | XComponent surface creation |
| `XComponent destroyed` | INFO | ✅ | XComponent destruction |
| `frame_gate enabled=` | INFO | ✅ | Frame gate state change |
| `first-frame callback` | INFO | ✅ | First frame callback installed |
| `first-frame fired` | INFO | ✅ | First frame callback fired |
| `first-frame wait cleared` | INFO | ✅ | First frame wait cleared |
| `OH_NativeVSync_Create returned null` | ERROR | ✅ | Vsync creation failed |
| `OH_NativeVSync_RequestFrameWithMultiCallback failed` | ERROR | ✅ | Vsync request failed |
| `FlutterWatchdog: FlutterUiThread is not alive` | ERROR | ✅ | UI thread blocked (no response for 10 seconds) |

---

## FAQ

### Why do I see `rasterizer no surface, frame dropped (kNotSetUp)` at startup, but the app works fine?

**A**: This is **normal startup timing**. The flow is:
1. The Dart engine starts first and begins requesting frames
2. The XComponent's `onLoad` / `OnSurfaceCreated` triggers afterwards
3. Before (2) completes, the rasterizer has no surface, so frames are dropped
4. Once `NotifyCreate` → `Rasterizer::Setup` completes, subsequent frames render normally

This log is **printed only once** (guarded by `static bool logged` in the code).

### Why don't I see the `Rasterizer::Setup done` log, but the screen is normal?

**A**: When the **Impeller Vulkan** backend is used, the surface may be initialized through an independent path (not via `Rasterizer::Setup`). In this case:
- `Rasterizer::Setup` may not be called
- But the Vulkan surface binds directly to the XComponent through `OHOSurfaceVulkanImpeller`
- As long as `XComponent.onLoad` triggers `onSurfaceCreated()`, the Vulkan path works normally

**Recommendation**: The ArkTS side should still call `flutterView?.notifyCreate(nativeWindow)` to ensure compatibility with all paths.

### Seeing the `Animator RequestFrame skipped (semaphore busy)` log at startup?

**A**: This log **does not exist in the current code**. When `pending_frame_semaphore_.TryWait()` fails, `RequestFrame` in `animator.cc` only records a `TRACE_EVENT` (for systrace analysis) and does not output any `WARNING` level logs.

If you see this log in older engine versions, an extra `FML_LOG(WARNING)` had been added at that time; this log appeared frequently due to the startup timing race and has been removed.

### How can I confirm the first frame was actually rendered successfully?

**A**: 
- **Release builds**: search for the `first-frame fired` log (platform_view_ohos.cpp)
- **ArkTS side**: listen for the `FlutterView.onFirstFrame` callback
- If it appears after `Rasterizer::Setup done` and no new ERROR logs appear, the rendering pipeline is working end to end

### Why is `FML_LOG(INFO)` not printed in Release, but `LOGI` is?

**A**: 
- `FML_LOG(INFO)` is controlled by `min_log_level`, which defaults to `kLogWarning` in Release mode, so `INFO` level messages are filtered out
- The `LOGI` macro (`ohos_logging.h`) calls `OH_LOG_Print(LOG_INFO)` directly, unaffected by `min_log_level`, so it is always visible in Release
- `OHOS_LOGI` in `shell/common` works the same way: it calls `OH_LOG_Print` directly and is always visible in Release

### White screen: `OhosMain init done` appears, but there are no Flutter rendering logs afterwards?

**A**: This indicates a **Dart layer initialization or execution exception**, not a Flutter Engine rendering pipeline issue. Possible causes:
1. `WidgetsFlutterBinding.ensureInitialized()` not called correctly
2. A custom `WidgetsFlutterBinding` overrode `initInstances()`, causing incomplete initialization
3. `runApp()` not called, or an exception occurring before the call
4. A Platform Channel was invoked before the Engine was ready, blocking the Dart side

**Investigation Directions**:
- Check Dart layer logs (`print` output)
- Check for `FlutterWatchdog: FlutterUiThread is not alive` (appears after 10 seconds)
- Check whether the ArkTS side correctly called `flutterView?.notifyCreate(nativeWindow)`

---

## Diagnosis Checklist

When encountering a white screen or rendering exception, check in the following order:

- [ ] 1. Search "OhosMain init done" → confirm engine initialization
- [ ] 2. Search "BuildRunConfiguration failed" / "Unable to load the kernel blob" → confirm Dart kernel loading
- [ ] 3. Search "Rasterizer::Setup done" → confirm surface binding (Impeller may not have this log)
- [ ] 4. Search "SetDisplayWindow result=" → confirm the surface binding result
- [ ] 5. Search new ERROR logs → locate the specific failure point
- [ ] 6. Check XComponent lifecycle logs ("XComponent SurfaceCreated" / "XComponent destroyed")
- [ ] 7. Check for persistent kNotSetUp/GPU unavailable/AcquireFrame null
- [ ] 8. Check ERROR logs from ohos_surface_*.cpp / gpu_surface_*.cc → GPU context issues
- [ ] 9. Check "SurfaceFrame::Submit failed" / "submit_callback" → frame submission issues
- [ ] 10. Check vsync_waiter_ohos.cpp logs → frame scheduling issues
- [ ] 11. Check "frame_gate enabled=" → GPU reclaim state machine
- [ ] 12. Check FlutterWatchdog logs → whether the UI thread is blocked
- [ ] 13. If there are no rendering logs after OhosMain init done → check Dart layer initialization

---

## Appendix: Source File Index

| Module | File | Key Function |
|---|---|---|
| OHOS Entry | `shell/platform/ohos/ohos_main.cpp` | Engine initialization |
| Shell Holder | `shell/platform/ohos/ohos_shell_holder.cpp` | Shell creation and launch |
| PlatformView | `shell/platform/ohos/platform_view_ohos.cpp` | Surface binding, lifecycle, GPU reclaim |
| XComponent | `shell/platform/ohos/ohos_xcomponent_adapter.cpp` | OS surface callbacks |
| Vsync | `shell/platform/ohos/vsync_waiter_ohos.cpp` | Frame synchronization |
| Engine | `shell/common/engine.cc` | Dart render request handling |
| Animator | `shell/common/animator.cc` | Frame scheduling |
| Rasterizer | `shell/common/rasterizer.cc` | Rendering execution |
| SurfaceFrame | `flow/surface_frame.cc` | Frame submission |
| Shell | `shell/common/shell.cc` | Viewport management, first frame wait |
| GPU Surface GL | `shell/gpu/gpu_surface_gl_impeller.cc` | GL Impeller GPU surface |
| GPU Surface Vulkan | `shell/gpu/gpu_surface_vulkan_impeller.cc` | Vulkan Impeller GPU surface |
| OHOS GL Context | `shell/platform/ohos/ohos_context_gl_skia.cpp` | GL Skia context |
| OHOS Vulkan Context | `shell/platform/ohos/ohos_context_vulkan_impeller.cpp` | Vulkan Impeller context |
| OHOS GL Env | `shell/platform/ohos/ohos_environment_gl.cpp` | EGL environment initialization |
| OHOS GL Impeller Surface | `shell/platform/ohos/ohos_surface_gl_impeller.cpp` | GL Impeller surface |
| OHOS GL Skia Surface | `shell/platform/ohos/ohos_surface_gl_skia.cpp` | GL Skia surface |
| OHOS Vulkan Surface | `shell/platform/ohos/ohos_surface_vulkan_impeller.cpp` | Vulkan Impeller surface |
| OHOS Software Surface | `shell/platform/ohos/ohos_surface_software.cpp` | Software rendering surface |

---

## Practical Case Comparison Analysis

### Case: Normal Startup vs White Screen Startup Log Comparison

#### Normal Startup (4log.txt)

```log
[INFO]  OhosMain init done, rendering_api=2
[WARN]  Unknown GPU Driver Vendor: 6629
[WARN]  engin Render frame_size is empty          ← normal startup timing (Release visible since v3)
[WARN]  engin Render device_pixel_ratio <= 0, dpr=1
[INFO]  Rasterizer::Setup done, surface_valid=true
[INFO]  first-frame fired
[ERROR] cannot get pixelmap orientation:401        ← image decode warning
[ERROR] Failed to SetPresentInfo                   ← present-to-screen warning
[ERROR] FlutterWatchdog: FlutterUiThread is not alive  ← appears after 10 seconds
```

**Characteristics**: After `OhosMain init done`, there are complete rendering flow logs (engine Render, Rasterizer::Setup, first-frame fired, image decode, SetPresentInfo).

#### White Screen Startup (3log.txt)

```log
[INFO]  OhosMain init done, rendering_api=2
[WARN]  Unknown GPU Driver Vendor: 6629
[ERROR] FlutterWatchdog: FlutterUiThread is not alive  ← appears after 10 seconds
```

**Characteristics**: After `OhosMain init done`, there are **no** Flutter rendering flow logs at all, and UI thread blocking appears after 10 seconds.

#### Diagnosis Conclusion

| Comparison Item | Normal Startup | White Screen Startup | Conclusion |
|--------|---------|---------|------|
| OhosMain init | ✅ | ✅ | Engine initialization successful |
| engine Render | ✅ | ❌ | White screen did not reach Render |
| Rasterizer::Setup | ✅ | ❌ | Surface not bound in the white screen case |
| first-frame fired | ✅ | ❌ | First frame not fired in the white screen case |
| image decode | ✅ | ❌ | Images not loaded in the white screen case |
| SetPresentInfo | ✅ | ❌ | Not presented to screen in the white screen case |
| FlutterWatchdog | ✅ | ✅ | Present in both, not the root cause |

**Root Cause Inference**: In the white screen scenario, the Dart layer is **completely stuck** after `OhosMain init done` and never reaches the `Engine::Render` stage. This is a typical **Dart layer initialization exception**, not a Flutter Engine rendering pipeline issue.

**Investigation Directions**:
1. Check whether the Dart layer `main()` is executed
2. Check whether `WidgetsFlutterBinding.ensureInitialized()` is called correctly
3. Check whether a custom `WidgetsFlutterBinding` overrode `initInstances()`
4. Check whether a Platform Channel was invoked before the Engine was ready
