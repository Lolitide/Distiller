# Pausing Drawing When the Page Is Invisible

Redundant drawing typically manifests as: when a page is invisible, partially invisible, or in the background, actions such as platform view refreshing, animations continuously generating textures, and WebView redrawing repeatedly keep running, wasting CPU/GPU resources, increasing power consumption, and heating the device. To reduce this kind of meaningless work, Flutter OHOS introduced the "pause when the page is invisible" and "WebView/PlatformView anti-redundant-drawing" solutions.

---

## Power Consumption Testing Tools

### 1. Page Visibility and Lifecycle Check

This can confirm:

- Whether Flutter receives `paused` when the page is invisible;
- Whether `resumed` is received when the page becomes visible again;
- Whether the pause logic can be triggered when the page's visible area is completely invisible.

### 2. PlatformView / WebView Texture Generation Status Check

This can confirm:

- Whether WebView, video, or animation platform views keep generating external textures when the page is invisible;
- Whether the visible area change listener can trigger `onInactive()` under threshold conditions;
- Whether `onActive()` is automatically restored after re-entering the visible area.

### 3. Power Consumption Observation Suggestions

Observe in the following scenarios:

- Whether GPU/CPU usage drops quickly after the page is moved to the background or to an invisible view area;
- Whether WebView and animation pages keep drawing or submitting when invisible;
- Whether normal refreshing resumes when the page is displayed again, instead of continuously running idle;
- When the same Engine is shared by multiple hosts, whether the visible state is correctly aggregated to avoid repeatedly dispatching lifecycle events.

---

## Usage Scenarios

The anti-redundant-drawing solution applies to the following typical scenarios:

- The page switches to the background;
- The page is moved out of the visible area and its ratio falls below the threshold;
- WebView or animation-style platform views have no effectively visible content;
- Pages that need to reduce the load of continuous GPU and texture generation.

## Prerequisites

### API Level Notes

The area visibility listening capability requires an API 20 or later environment; on lower-version devices this listener does not take effect.

### flutter_flutter

This feature depends on the version adaptation capability in the Flutter SDK repository; it is recommended to use a Flutter branch that supports this feature. For Flutter upgrades, refer to the [upgrade guide](../version/flutter-oh-upgrade-guide.en.md).

### Page-Level Visibility Switch

In this solution, the invisible-pause capability is enabled by default:

<!-- TODO: import statement to be added -->

```ts
shouldPauseWhenInvisible = true
```

Developers can explicitly control this in `FlutterPage`:

```ts
FlutterPage({
  viewId: this.viewId,
  shouldPauseWhenInvisible: false
})
```

Notes:

- `true`: enables visible area listening; when the page is invisible or the area is completely invisible, paused may be triggered;
- `false`: does not use area visibility listening; the lifecycle is mainly controlled by the page show/hide path.

### PlatformView Visible Area Events

Key interfaces include:

- `PlatformViewVisibleAreaEventOptions`
- `getPlatformViewVisibleAreaEventOptions()`
- `onInactive()`
- `onActive()`

Enhancements were made to `EmbeddingNodeController` and `PlatformViewsController`:

- Trigger the visible area callback when the page's visible area changes;
- Call `platformView.onInactive()` when the page transitions from "visible" to "invisible";
- Call `platformView.onActive()` when the page re-enters the visible area;
- When both `top` / `left` become `NaN` while previously holding normal values, determine that the page has transitioned from visible to invisible.

### Details

#### 1 Design Goal of Pausing When the Page Is Invisible

The purpose of the pause-when-invisible capability is to avoid ineffective behavior such as "a Flutter page that is not destroyed but keeps executing lifecycle/animation/texture generation while in the background or invisible". The benefits include:

- No longer continuously requesting new textures for background pages;
- Reducing meaningless work on the UI thread and rendering thread;
- Reducing background heat and power consumption;
- Avoiding unnecessary drawing and display updates while the page is invisible.

For multi-host scenarios sharing one Engine, this capability is especially important, because multiple hosts reuse the same set of Flutter runtime resources, and visibility aggregation must be correct.

#### 2 WebView / PlatformView Anti-Redundant-Drawing Mechanism

- Listen to `commonEvent.setOnVisibleAreaApproximateChange`;
- Determine from parameters such as `ratios` and `expectedUpdateInterval` whether the current platform view has entered a low-visibility area;
- If the current visible ratio is below `onInactiveThreshold` and the view is shrinking, call `onInactive()`;
- If the current visible ratio is above `onActiveThreshold` and the view is expanding, call `onActive()`.

#### 3 Key Determination Logic

In `PlatformViewsController`, a new check was added:

> When both `top` and `left` are `NaN` but previously held normal values, it means the current page has switched from the visible state to the invisible state.

This kind of check is used to:

- Distinguish normal layout parameters from page interruption/removal scenarios;
- Call `notifyPlatformViewInvisible()` promptly at the moment closest to the real change in the user's view;
- Let the platform view enter `onInactive()` early, thereby reducing its continuous drawing.

Meanwhile, `EmbeddingNodeController` also has a `notifyPlatformViewInvisible()` entry point for centrally handling pause operations when a platform view is invisible.

#### 4 Page Visibility Aggregation

With a shared Engine, multiple pages may exist simultaneously across multiple hosts, but only some pages are actually displayed in the user's foreground. To avoid "a host with a corrupted state causing repeated resume/pause", this solution introduces an aggregation mechanism:

- Listen for page area changes;
- Determine whether the current page has really become invisible;
- If this state affects platform views, uniformly schedule `paused/resumed` or `onInactive()/onActive()`.

This prevents duplicate or incorrect lifecycle events caused by multiple hosts competing, while reducing meaningless rendering and animation resource usage.

---

## Adaptation Process

### Step 1: Confirm the Device API Level

Confirm that the target device supports API 20+; otherwise the visibility listener will not take effect.

### Step 2: Check the Visibility Switch Configuration

Check whether `shouldPauseWhenInvisible` is enabled in the page integration layer; prefer the default `true` configuration.

### Step 3: Confirm PlatformView Lifecycle Callbacks

If the page contains a WebView, platform view, or video animation, confirm that their `onInactive()` / `onActive()` logic is implemented.

### Step 4: Register the Visible Area Event Callback

Confirm that `setPlatformViewVisibleAreaEventCallback()` is registered in `EmbeddingNodeController` or the corresponding host.

### Step 5: Integrate the NaN Determination Logic

Confirm that the `NaN` determination and migration logic is integrated in `PlatformViewsController`.

### Step 6: Verify the Pause Behavior

Run the page and observe whether the pause behavior is automatically triggered after the page becomes invisible.

### Step 7: Verify the Resume Logic

After returning to the page, confirm that the resume logic starts normally and verify that meaningless drawing is reduced.

---

## Summary

The core goal of the anti-redundant-drawing solution is to immediately stop unnecessary UI updates, animations, and texture generation "when a page or platform view is no longer visible to the user", thereby reducing ineffective rendering and power consumption.

The value of this capability is reflected in:

- Triggering `paused` / `onInactive()` promptly when the page is invisible;
- Automatically restoring `resumed` / `onActive()` when the page becomes visible again;
- WebView, video, and animation platform views no longer running idle in the background;
- Correctly aggregating state and resume logic even in shared Engine scenarios.

For Flutter OHOS developers, such capabilities are critical: they help apps keep power consumption low in background and invisible states, and quickly restore the normal experience when the user returns to the page.

---

## Sample Code

### 1. Page-Level Default Switch

```ts
FlutterPage({
  viewId: this.viewId,
  shouldPauseWhenInvisible: true
})
```

> For the latest changes to this document, see [repository link](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-eliminate-redundant-drawing.md)
