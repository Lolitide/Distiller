# External Texture Troubleshooting Guide

> Back to [README.en.md](README.en.md)

---

## 1. What Is an External Texture?

### 1.1 Plain-Language Explanation

An external texture is a mechanism that lets the native side (video player, camera, animation, etc.) "feed" frames to Flutter for display.

> **Analogy**: imagine a "frame conveyor belt":
> - The **producer** (video player/camera) puts frames onto the belt one by one
> - The **consumer** (Flutter engine) takes frames off the belt and paints them to the screen
>
> If something goes wrong with the belt (production outpaces consumption, the producer stops, or the consumer gets stuck), the picture will black out, stutter, or freeze.

### 1.2 When Are External Textures Used?

| Scenario | Producer | Typical Problem |
|------|--------|---------|
| Video playback | Video player plugin | Black screen/janky picture |
| Camera preview | Camera plugin | Preview does not update |
| Animation playback | Animation plugin | Janky animation |
| WebView | WebView plugin | Picture does not update |
| Live streaming | Live streaming SDK | Picture latency/jank |

### 1.3 Problem Type Quick Reference

| Symptom You See | Possible Cause | Section to Read |
|-------------|-----------|-----------|
| Video/camera picture is black | Texture creation failed / producer produced no frames | §5 |
| Picture stops updating after the first frame | Frame gate enabled / Surface destroyed / onInactive triggered by mistake | §6, §7 |
| Janky picture/frame dropping | Consumption too slow / frames skipped | §8 |
| Stretched/distorted picture | Size change did not converge | §9 |
| App crashes | Texture still accessed after release | §10 |
| Still draining power in the background | Visible area monitoring not enabled | §7 |

---

## 2. External Texture Architecture

### 2.1 The Frame Conveyor Belt Model

```
Native producer            Flutter consumer
(video/camera/animation)   (Raster thread)
      │                        │
      │ write frames to window │ take frames from the window
      ▼                        ▼
┌──────────────────────────────────────┐
│   OH_NativeImage buffer queue        │
│   (the frame conveyor belt)          │
└──────────────────────────────────────┘
      │                        │
      │  "New frame ready!"    │  create a GPU image
      ▼                        ▼
 Notify Flutter to redraw     Paint to the screen
```

| Role | Plain-Language Description | Implementation |
|------|---------|--------|
| Producer | The one who puts frames onto the belt | The native side obtains the window via surfaceId and writes to it |
| Consumer | The one who takes frames off the belt and paints them to the screen | `OHOSExternalTexture` (Raster thread) |
| Conveyor belt | The buffer queue in the middle | `OH_NativeImage` BufferQueue |

### 2.2 The Two Rendering Backends

| Backend | When It Is Used | Plain-Language Description |
|------|-----------|---------|
| OpenGL ES | `RenderingApi = kOpenGLES` | Displays frames with a GL texture |
| Vulkan (Impeller) | `RenderingApi = kImpellerVulkan` | Synchronizes frames with a Vulkan semaphore |

> On registration, `RegisterExternalTexture api type <N> texture_id <id>` is printed; `N` is the rendering backend number.

### 2.3 Developer APIs

If you are a plugin developer, you use external textures through `TextureRegistry`:

| Method | Purpose | When to Use It |
|------|------|-----------|
| `registerTexture(id)` | Registers a texture and returns the surfaceId | When creating a video/camera texture |
| `registerPixelMap(pixelMap)` | Registers a static image texture | To display a single image |
| `unregisterTexture(id)` | Unregisters a texture | When no longer needed (**stop the producer before unregistering!**) |
| `setTextureBufferSize(id,w,h)` | Sets the producer window size | When the frame size changes |
| `setExternalNativeImagePtr(id,img)` | Replaces the texture with an external NativeImage | Advanced usage |

---

## 3. Texture Lifecycle

### 3.1 Registration Flow (Creating the Conveyor Belt)

```
registerTexture(textureId)
│
├─ Create OH_NativeImage (create the conveyor belt)
│  ├─ Success → continue
│  └─ Failure → log "OH_NativeImage_Create() failed"
│
├─ Acquire NativeWindow (get the conveyor belt entrance)
│  ├─ Success → continue
│  └─ Failure → log "OH_NativeImage_AcquireNativeWindow() failed"
│
├─ Get surfaceId (the address for the producer to use)
│  └─ Failure → log "OH_NativeImage_GetSurfaceId() failed"
│
└─ Register with the engine
   → log "RegisterExternalTexture api type N texture_id X"
```

**Success logs**:
```
I Flutter:  RegisterExternalTexture api type 2 texture_id 1
I Flutter: OH_NativeImage_AcquireNativeWindow() success
I Flutter: OH_NativeImage_GetSurfaceId() success, surfaceId = 12345678
```

### 3.2 Unregistration Flow (Tearing Down the Conveyor Belt)

> **Order matters!** Always stop the producer first, then unregister the texture. Otherwise the producer keeps putting frames onto a belt that has already been torn down, and the app will crash.

```
✅ Correct order:
1. Stop the producer (pause the video/camera)
2. Call unregisterTexture

❌ Wrong order:
1. Call unregisterTexture (the conveyor belt is torn down)
2. The producer is still writing → crash!
```

---

## 4. Frame Scheduling (How the Conveyor Belt Runs)

### 4.1 Frame Sequence Number Mechanism

The engine tracks frame production and consumption with two counters:

| Counter | Plain-Language Description | Meaning |
|--------|---------|------|
| `now_new_frame_seq_num` | "How many frames were produced" | Number of frames produced by the producer |
| `now_paint_frame_seq_num` | "How many frames were painted" | Number of frames already painted by the consumer |

If "produced" is far greater than "painted", consumption cannot keep up, and the engine will **actively skip frames** (drop some older frames and paint only the newest ones) to stay in real time.

### 4.2 Frame Skip Policy

| Buffer Queue Size | Skip Threshold | Plain-Language Description |
|------------|---------|---------|
| ≤ 5 | size - 1 | Normal scenarios; keeps 1 buffer |
| > 5 | size * 2/3 | Video/camera scenarios; keeps more buffers |

**Frame skip logs**:
```
I Flutter: external_texture skip one frame(slow consumer): ... buffer_queue_size 5 max_jank_frame 4
I Flutter: MarkNewFrameAvailable avail-seq 120 paint-seq 100 texture_id 1
```

> `skip one frame(slow consumer)` = consumption is too slow, so some frames were skipped

---

## 5. Texture Black Screen / Not Displayed

### 5.1 Troubleshooting Flow

```
Black screen
│
├─ Search for "RegisterExternalTexture api type"
│  └─ Not found → the texture was never registered; check the registerTexture call
│
├─ Search for "OH_NativeImage_Create() failed"
│  └─ Found → creation failed; check system resources
│
├─ Search for "OH_NativeImage_GetSurfaceId() failed"
│  └─ Found → failed to get the surfaceId; the texture was not really registered
│
├─ Search for "No DlImage available"
│  └─ Found → there are no frames on the conveyor belt (the producer produced none)
│     ├─ Check whether the native side has written data to the surfaceId
│     └─ Check whether the Texture widget's size is 0
│
└─ Check whether the rendering backend matches
```

### 5.2 Common Causes and Fixes

| Cause | Plain-Language Description | Fix |
|------|---------|--------|
| Texture not registered | `registerTexture` was never called at all | Check the registration code |
| NativeImage creation failed | Insufficient system resources | Check system resources |
| Producer produced no frames | Video has not started playing / camera not started | Make sure the producer has started writing |
| Texture widget size is 0 | The frame area is 0x0 | Check the widget layout |
| Wrong surfaceId | The producer wrote to the wrong surfaceId | Confirm the surfaceId is passed correctly |

---

## 6. Frame Gate

### 6.1 Plain-Language Explanation

When the app goes to the background, the engine turns on the "frame gate" — it **keeps draining frames from the conveyor belt (to keep the producer from blocking) but no longer schedules redraws** (the user cannot see them anyway).

> **Analogy**: it is like a parcel locker — after you go to the background, parcels keep being placed into the locker (the queue is drained), but you stop picking them up (no rendering). Once you return to the foreground, pickup resumes as normal.

### 6.2 State Transitions

| When | Frame Gate State | Log |
|------|-----------|------|
| Goes to background | Enabled (drains but does not render) | `frame gate enabled, drain-only for texture X` |
| Returns to foreground | Disabled (back to normal) | `ExecuteReclaimRestore - restoring foreground state` |

### 6.3 Troubleshooting "Texture Not Updating"

If the texture does not update after returning from the background to the foreground:

1. Search for `frame gate enabled` → confirm whether the frame gate is still enabled
2. Search for `ExecuteReclaimRestore` → confirm whether it has been restored
3. Search for `Surface REBUILT` → confirm whether the Surface was rebuilt successfully
4. Search for `NotifyDestroyed` → confirm whether the Surface has been destroyed

---

## 7. Visible Area Monitoring

### 7.1 Plain-Language Explanation

Version 3.35 adds a "visible area monitoring" feature. When a PlatformView (a native component embedded in Flutter) becomes invisible, texture production can be **paused automatically** (for example, pausing video/animation), avoiding wasted power while invisible.

> **Analogy**: it is like a TV pausing playback automatically when you walk away.

### 7.2 How to Enable It

It is **off** by default (`enable=false`); the plugin must override `getPlatformViewVisibleAreaEventOptions()` to enable it:

```typescript
// Override in your PlatformView subclass
getPlatformViewVisibleAreaEventOptions(): PlatformViewVisibleAreaEventOptions {
  return {
    enable: true,                              // Enable monitoring
    ratios: [0.0, 1.0],                        // Visible ratio thresholds
    expectedUpdateInterval: 1000,              // Expected callback interval (ms)
    onInactiveThreshold: 0.0,                  // onInactive() (pause) is triggered when the visible ratio is ≤ this value
    onActiveThreshold: 1.0,                    // onActive() (resume) is triggered when the visible ratio is ≥ this value
  } as PlatformViewVisibleAreaEventOptions;
}

// Pause texture production (for example, pause the video)
onInactive(): void {
  this.videoPlayer?.pause();
}

// Resume texture production
onActive(): void {
  this.videoPlayer?.play();
}
```

### 7.3 Key Logs

```
I Flutter: setPlatformViewVisibleAreaEventCallback surfaceId:12345, enable:true
I Flutter: PlatformViewVisibleAreaEventCallback surfaceId:12345, isExpanding:false, currentRatio:0
```

| Log | Meaning |
|------|------|
| `isExpanding:false, currentRatio:0` | Became invisible; `onInactive()` is triggered (pause) |
| `isExpanding:true, currentRatio:1` | Fully visible; `onActive()` is triggered (resume) |

---

## 8. Texture Jank / Frame Dropping

### 8.1 Troubleshooting Flow

```
Janky picture
│
├─ Search for "skip one frame(slow consumer)"
│  └─ Found → consumption is too slow; the engine is skipping frames
│     ├─ Check whether the Raster thread is blocked by other tasks
│     └─ Check whether buffer_queue_size is too small
│
├─ Search for "MarkNewFrameAvailable avail-seq"
│  ├─ avail-seq does not grow → the producer produced no frames
│  └─ avail-seq grows but paint-seq does not → the Raster thread is stuck
│
├─ Search for "GpuReclaim"
│  └─ Found → interrupted by a GPU reclaim (see dfx-memory.en.md for details)
│
└─ Search for "get error buffer queue size"
   └─ Found → buffer queue anomaly (>100)
```

---

## 9. Stretched / Distorted Picture

### 9.1 Troubleshooting

Search for `size change` related logs:

| Log | Meaning |
|------|------|
| `size change took N frames` | The size change completed within N frames (normal) |
| `stop size change state: frame > 10` | The size change took more than 10 frames (abnormal) |
| `direct release size changed buffer` | The buffer size changed but the drawing area did not (stretch protection) |

**Fix**: Make sure `setTextureBufferSize` and `notifyTextureResizing` are called consistently.

---

## 10. Crash from Texture Access

### 10.1 Plain-Language Explanation

It is like throwing away a parcel box while someone is still reaching into it for their things — of course that causes trouble.

**Common causes**:
1. The native side keeps writing to the surfaceId after `unregisterTexture`
2. An external NativeImage was released prematurely
3. GPU resources are still referenced after the GPU context was destroyed

**Fix**: **Stop the producer first, then unregister the texture**:
```typescript
// ✅ Correct order
stopProducer();                               // stop first
textureRegistry.unregisterTexture(textureId); // unregister second
```

> See [dfx-crash.en.md](dfx-crash.en.md) §2.6, scenario 2 for details.

---

## 11. Log Keyword Quick Reference

| Search This Keyword | Meaning | Severity |
|--------------|------|---------|
| `RegisterExternalTexture api type` | Texture registration | — |
| `OH_NativeImage_Create() failed` | Creation failed | High |
| `No DlImage available` | No drawable image (black screen) | Medium |
| `frame gate enabled, drain-only` | Background frame gate enabled | Normal |
| `skip one frame(slow consumer)` | Frame skipped due to slow consumption | Medium |
| `MarkNewFrameAvailable avail-seq` | Frame sequence number monitoring | — |
| `OnGrContextCreated texture_id` | GPU context rebuild | — |
| `size change took N frames` | Size change completed | Normal |
| `PlatformViewVisibleAreaEventCallback` | Visible area changed | — |
| `UnRegisterExternalTexture` | Texture unregistration | — |
| `~OHOSExternalTexture` | Texture destruction | — |

---

## 12. Troubleshooting Checklists

### Black Screen / Not Displayed

- [ ] Search for `RegisterExternalTexture` to confirm the texture is registered
- [ ] Search for `OH_NativeImage_Create() failed` to confirm creation succeeded
- [ ] Search for `No DlImage available` to confirm whether frames are present
- [ ] Check whether the native side has written data to the surfaceId
- [ ] Check whether the Texture widget's size is 0

### Not Updating

- [ ] Search for `frame gate enabled` to check the frame gate state
- [ ] Search for `NotifyDestroyed` to check whether the Surface is alive
- [ ] Search for `OnGrContextCreated/Destroyed` to check the GPU context
- [ ] Search for `PlatformViewVisibleAreaEventCallback` to check whether it was paused by `onInactive`

### Jank

- [ ] Search for `skip one frame` to identify the frame skip type
- [ ] Search for `MarkNewFrameAvailable avail-seq` to compare production/consumption sequence numbers
- [ ] Search for `GpuReclaim` to check whether it accompanies a GPU reclaim

### Background Behavior

- [ ] Search for `frame gate enabled` to confirm the frame gate is enabled
- [ ] Search for `ExecuteReclaimRestore` to confirm restoration after returning to the foreground
- [ ] Check whether `onInactive`/`onActive` are implemented
