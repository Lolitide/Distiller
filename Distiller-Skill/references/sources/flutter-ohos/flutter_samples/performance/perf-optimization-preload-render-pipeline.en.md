# Solution - Performance Optimization: Preload Render Pipeline

## 1. Starting from page transition white-screen

From the moment a user taps a button on a native page to the moment the Flutter page is fully displayed, it often takes more than 300 ms.

This is the most common scenario: tapping a news list item to open the detail page, opening a purchase page from a product card, or entering a secondary page from the settings menu. The "white-screen wait" the user sees after tapping is usually addressed by developers through the Dart code itself — reducing widget nesting, deferring non-essential initialization. But part of the first-frame cost comes from the engine side, because at the moment of the tap the Flutter engine initializes and the graphics pipeline cold-starts: loading and creating the render surface, establishing the display channel, and warming up the GPU pipeline — all this heavy work piles up after the page appears.

In HarmonyOS Flutter, the preload render pipeline (WarmUp Pipeline) approach is straightforward: complete engine run-up + GPU warm-up + off-screen render preparation before the tap; after the tap, preferentially reuse the warmed-up results, and fall back to smooth frame compensation on failure.

We built a demo application that navigates from a native page to a simple Flutter page to focus on the engine-side cost. On a Mate 60 Pro, the preload render pipeline reduces the time from tapping the button to the page being fully displayed from 115.9 ms to 72.1 ms, a drop of about 37.8% compared with the standard path; and it reduces the time from engine binding to the HarmonyOS XComponent to the first frame from 88.2 ms to 67.8 ms, a drop of about 23.1%. We also did a memory optimization targeting the pre-render stage; by streamlining buffer allocation, we saved 40 MB+ of memory.

## 2. Technical implementation: comparing three modes to see what WarmUp Pipeline actually does extra

When developing HarmonyOS Flutter applications, you can usually choose among the following three modes to open a Flutter page:

- **standard**: the most basic mode. Every time you enter a page, a FlutterEngine is created from scratch, with no caching and no warm-up. This is Flutter's default startup behavior and the slowest path for the first frame.
- **cached_engine**: a common optimization in the community. Before the page appears, the FlutterEngine is created and started, which completes the Dart VM and framework initialization in advance.
- **warmup_pipeline**: the preload render pipeline of HarmonyOS Flutter. Before the page appears, it not only prepares the engine but also moves GPU warm-up, off-screen rendering, and window switching forward together via `FlutterEnginePreload`, forming a complete "warm-up → takeover" loop.

![Three modes comparison](../media/performance/performance-22.png)


We ran three groups of comparisons on the same demo, 10 rounds per group, with a unified sampling definition:

- `tapToFirstFrame`: from tapping on the native page to enter the Flutter page, to the completion of the Flutter normal first frame.
- `attachToFirstFrame`: from `FlutterView.attachToFlutterEngine(...)` to the completion of the Flutter normal first frame.

Results:

| Mode | tap mean | tap P90 | attach mean | attach P90 |
|---|---:|---:|---:|---:|
| standard | 115.9 ms | 119 ms | 88.2 ms | 92 ms |
| cached_engine | 93.6 ms | 98 ms | 89.0 ms | 94 ms |
| warmup_pipeline | 72.1 ms | 73 ms | 67.8 ms | 69 ms |

Two observations from these results.

First, `cached_engine` does move part of the preparation cost forward. Compared with the standard path, `tapToFirstFrame` drops from 115.9 ms to 93.6 ms, a decrease of about 19.2%. This shows that "preparing the engine in advance" pays off.

Second, what really widens the gap is the WarmUp Pipeline. Compared with the standard path, `tapToFirstFrame` drops by about 37.8% and `attachToFirstFrame` by about 23.1%; even compared with `cached_engine`, which already caches the engine, `tapToFirstFrame` still drops by about 23.0% and `attachToFirstFrame` by about 23.8%. This shows that WarmUp Pipeline optimizes beyond just the "engine preparation" stage — it moves the entire graphics pipeline forward.

### Key technical point 1: Off-screen warm-up — move the GPU cold start out of the first-frame path

The preload entry is on the ArkTS side. `FlutterEnginePreload.preloadEngine(...)` first completes engine initialization and Dart execution, and then sends the preload request to Native via `xComponentPreDraw(...)`. The key actions happen in `PlatformViewOHOS`:

- `PrepareGpuSurface()` is called asynchronously during construction to prepare the `GPUSurface` in advance.
- `Preload(width, height)` enters off-screen warm-up on the raster thread.
- `OHOSSurface::PrepareOffscreenWindow(width, height)` creates the off-screen `NativeWindow`.

This step is critical. What WarmUp Pipeline does is not "new an engine in advance" — it lets the engine obtain a usable off-screen render target while the page is still not visible. For the Vulkan/Impeller path, the expensive part is not "drawing this frame" but the first time the graphics runtime is truly pulled up. Moving this forward means the first frame no longer bears the full GPU cold-start cost.

### Key technical point 2: Warm-up is not the same as presenting to screen, but you must be ready for presenting

Making the preload too heavy turns the off-screen stage itself into a new burden. We deliberately made a trade-off in the implementation: in the warm-up stage, prioritize completing the most expensive initialization actions, but avoid paying too high a resource cost just to "draw a complete image in advance".

The most easily misjudged part of off-screen warm-up is the assumption that "as long as one frame is rendered in advance, it can be directly carried over to the formal display". That is not the case. A real window and an off-screen window are not inherently equivalent: their size, buffer state, and window handle may all differ. `OHOSSurface` records the off-screen window size, the preload flag, and the most recent off-screen buffer state; the Vulkan path, besides creating the off-screen window, also builds the costly GPU surface/pipeline in advance via `PrepareGpuSurface()`. This way, when the real window appears, the system does not start from scratch but enters the next stage with a "ready but not yet on-screen" graphics context.

### Key technical point 3: Memory optimization — keep only 2 render buffers during the preload stage

During the preload stage, instead of allocating 6 buffers as in the formal display state, only 2 buffers are allocated; when the page is actually displayed, the 2 preload buffers are destroyed and 6 display buffers are reallocated.

The reason this works is that the goal of the preload stage is not to maintain full display capability for a long time, but to complete engine start-up, graphics pipeline warm-up, and key first-frame resource preparation. In other words, the preload stage needs "a sufficient minimal buffer set", not a buffer configuration fully equivalent to the on-screen state.

![Buffer allocation flow](../media/performance/performance-23.png)

If 6 buffers were held during the preload stage, those buffers would still have to be destroyed when the real page attaches, and 6 new display buffers would be reallocated. The 4 extra buffers held during preload would not translate into display benefits but only add a period of off-screen resident memory. This is equivalent to compressing an intermediate-state resource that "would eventually be destroyed" to the minimum. This adjustment brought 40 MB+ of memory savings.

### Key technical point 4: Formal on-screen — prefer reuse, fall back to frame compensation, do not bet on a single path

When the page is actually attached to the engine, `FlutterView.attachToFlutterEngine(...)` reconnects the real page to the preloaded engine; then `NotifyCreate(native_window)` hands the real window to the Native render layer, entering `SetDisplayWindow(...)`.

In the current implementation, after the real window arrives, it splits into two paths:

1. If the off-screen result matches the formal window conditions, reuse the off-screen result preferentially.
2. If they do not match, or reuse fails, immediately mark a compensating frame as needed and reschedule a formal render frame.

This scheme is not "valid only if reuse succeeds"; it is "reuse when possible to benefit directly, and degrade gracefully when not". This is critical for stability. The biggest risk in first-frame optimization is introducing a fragile path to save tens of milliseconds; once window conditions change, sizes mismatch, or buffer migration fails, display correctness is lost. HarmonyOS Flutter adopts a more pragmatic strategy here: **aim for reuse first, then guarantee correctness.**

### Trace analysis

![Figure 3: Preload render pipeline trace comparison](../media/performance/performance-24.png)

The figure above shows the key thread timeline triggered by tapping a button to open the Flutter page in the preload scenario. From this figure we can see:

First, there are no engine-creation-related trace points on the main thread; before the page appears, the FlutterEngine is created and started in advance.

Second, when actually entering the first-frame submission stage, the remaining work on the raster thread is shorter.

## 3. How developers use it: three scenarios with more business value

If your home page or the first Flutter page is opened frequently, the best fit is to preload during idle time after application startup.

```ts
import FlutterEnginePreload from '.../FlutterEnginePreload';

await FlutterEnginePreload.preloadEngine(context, {
  initialRoute: '/home',
});

const engine = FlutterEngineCache.getInstance().get('feed_tab');
if (engine != null) {
  flutterView.attachToFlutterEngine(engine);
}
```

When the page is actually displayed, attach the `FlutterView` to the corresponding engine. The benefit is direct: the first time the home page opens, the entire graphics pipeline is no longer pulled up from scratch.

The payoff from this approach is usually very intuitive. What the user sees is "tap and content is there", rather than "tap and then wait for the system to assemble a whole rendering pipeline".

### When it is not recommended to enable

Preloading is not free, and is especially unsuitable for the following scenarios:

- Low-frequency pages that a user may never enter during a session.
- Memory-sensitive devices, where the resident resource pressure from preloading outweighs the benefit.
- Pages with a very short lifecycle, where the page is destroyed before the preload has paid off.
