# Multi-Device Adaptation Issue Locating Guide

> Back to [README.en.md](README.en.md)

---

## 1. Overview

Flutter OHOS multi-device adaptation involves multiple subsystems: split view (SplitView), safe area avoidance, foldable DisplayFeature, multi-window, DPI scaling, LTPO adaptive refresh, and more. Problems in these subsystems usually manifest as layout anomalies, failed avoidance, or incorrect frame rates. They do not directly cause crashes or freezes, but they severely hurt the user experience.

### 1.1 Issue Classification

| Issue type | Typical symptoms | Section in this document |
|---------|---------|---------|
| Split view not working/abnormal | No split view on wide screens, wrong home page detection, missing modal barrier | [§2](#2-splitview-issues) |
| Safe area avoidance not working | Content occluded by the status bar/punch-hole/window buttons | [§3](#3-safe-area-avoidance-issues) |
| Foldable adaptation anomalies | Crease area not avoided, DisplayFeature missing | [§4](#4-foldable-displayfeature-issues) |
| DPI scaling anomalies | UI too large/small, custom DPI not taking effect | [§5](#5-dpi-scaling-issues) |
| LTPO frame rate anomalies | Frame rate does not rise while scrolling, does not switch during transitions | [§6](#6-ltpo-adaptive-refresh-issues) |
| Multi-window/free window anomalies | Layout does not refresh on window scaling, occluded by window buttons | [§7](#7-multi-window--free-window-issues) |

### 1.2 Quick Locating Flow

```
Multi-device adaptation anomaly
│
├─ Split view not working
│  ├─ Search HiLog: "SplitView" / "split_view"
│  │  → Check the configuration parsing logs, see §2
│  └─ Search HiLog: "split_view_config_system"
│     → Check the engine configuration push, see §2.3
│
├─ Content occluded by system UI
│  ├─ Search HiLog: "avoidAreaChangeCallback"
│  │  → Check avoid area updates, see §3
│  └─ Search HiLog: "windowTitleButtonRect" / "windowDecor"
│     → Check window decoration avoidance, see §3.3
│
├─ Foldable crease not avoided
│  ├─ Search HiLog: "displayFeatures" / "Fold status"
│  │  → Check DisplayFeature construction, see §4
│  └─ Search HiLog: "foldStatusChange"
│     → Check fold status listening, see §4.2
│
├─ Abnormal UI size
│  ├─ Search HiLog: "device pixel ratio" / "densityUpdate"
│  │  → Check DPI scaling, see §5
│  └─ Search HiLog: "windowSizeChangeCallback"
│     → Check window size changes, see §5.2
│
├─ Frame rate does not change with the scenario
│  ├─ Search HiLog: "LTPO" / "velocity" / "nativevsync"
│  │  → Check LTPO velocity reporting, see §6
│  └─ Check the framesconfig.json configuration file
│     → See §6.3
│
└─ Layout does not refresh on window scaling
   └─ Search HiLog: "windowSizeChangeCallback" / "avoidAreaChange"
      → Check window change callbacks, see §7
```

---

## 2. SplitView Issues

### 2.1 Split View Not Working

**Troubleshooting steps**:

**Step 1**: Confirm the configuration file exists and is correct

```bash
# Check whether the configuration file exists
hdc shell ls /data/app/.../entry/resources/rawfile/split_config.json
```

Configuration file location: `ohos/entry/src/main/resources/rawfile/split_config.json`

**Step 2**: Search for configuration parsing logs

```bash
hdc shell hilog | grep -E "SplitView|split_view|SplitViewConfig"
```

| Log keyword | Meaning | Normal/Abnormal |
|-----------|------|----------|
| `SplitView: Main page determined by config homePage: /home` | Home page identified by the homePage config | ✅ Normal |
| `SplitView: Main page determined by widget.home` | Home page identified by the home parameter | ✅ Normal |
| `SplitView: Main page determined by routes: /home` | Home page identified by routes | ✅ Normal |
| `SplitView: Main page determined by initialRoute` | Home page identified by initialRoute | ✅ Normal |
| `SystemChannel config parse failed: ...` | Configuration JSON parse failure | ❌ Abnormal |
| `SplitViewConfig: Failed to decode placeholder icon: ...` | Placeholder icon base64 decode failure | ⚠️ Non-fatal |
| `SplitViewConfig: Some fullScreenPages items are not strings` | fullScreenPages config item has the wrong type | ⚠️ Partially ineffective |
| `Cannot determine main page for split screen` | Cannot determine the home page (throws FlutterError) | ❌ Abnormal |

**Step 3**: Confirm the trigger conditions

Split view activation requires all of the following:
- Logical width > 600vp **and** logical height > 600vp
- Aspect ratio > 1.2 (wide-screen mode) or aspect ratio ≤ 1.2 (square-screen mode)
- The corresponding config item is enabled (`enableWideWindowSplit` / `enableSquareWindowSplit`)

### 2.2 Wrong Home Page Detection

**Common causes**:

| Cause | Symptom | Solution |
|------|------|---------|
| Router mode without homePage configured | Home page cannot be identified; split view does not work | homePage is **mandatory** in Router mode |
| MaterialPageRoute does not preserve settings | Route name is null; cannot match the home page/full-screen pages | `MaterialPageRoute(settings: settings, ...)` |
| GoRoute.name does not match the config | Full-screen pages do not take effect | Ensure `GoRoute.name` exactly matches `fullScreenPages` |
| Ternary expression deciding the home page | Cannot be identified | Use `initialRoute` + a route table instead |

**Debug method**: Enable the SplitView home page decision logs (output automatically in debug mode by default):

```bash
hdc shell hilog | grep "SplitView: Main page"
```

### 2.3 Engine Configuration Push Issues

After the Dart isolate starts, the ETS engine actively pushes the configuration through the `flutter/split_view_config_system` channel.

```bash
hdc shell hilog | grep -E "split_view_config_system|SplitViewConfigSystem"
```

**Abnormal cases**:
- The configuration file `split_config.json` does not exist → the engine pushes an empty configuration
- Failed to obtain the app icon → `placeholderIconData` is empty and the placeholder page has no icon
- Dart isolate not started → the pushed message is lost

### 2.4 Modal Barrier Not Showing

**Problem**: In split view mode, the barrier of `showModalBottomSheet` / `showMenu` / `showSearch` is incorrect.

**Cause**: These APIs default to `useRootNavigator: false`; in split view scenarios it must be set to `true` explicitly.

```dart
// ❌ Wrong: barrier is incorrect under split view
showModalBottomSheet(context: context, builder: (context) => SheetContent());

// ✅ Right: set it explicitly
showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  builder: (context) => SheetContent(),
);
```

### 2.5 Split View Checklist

- [ ] Confirm `split_config.json` exists in the `rawfile/` directory
- [ ] Confirm `enableWideWindowSplit` or `enableSquareWindowSplit` is set to `true`
- [ ] Search HiLog for `SplitView` to confirm the configuration is loaded
- [ ] Confirm both window logical width and height are > 600vp
- [ ] In Router mode, confirm `homePage` is configured
- [ ] Confirm `MaterialPageRoute` preserves the `settings` parameter
- [ ] Confirm `showModalBottomSheet` and similar set `useRootNavigator: true`
- [ ] Confirm the route names in `fullScreenPages` match the code

---

## 3. Safe Area Avoidance Issues

### 3.1 Avoid Areas Not Updating

Flutter OHOS listens for four kinds of avoid area changes through `FlutterView.ets`:

```bash
hdc shell hilog | grep -E "avoidAreaChangeCallback|avoidArea"
```

**Normal logs** (corresponding to the four OHOS `AvoidAreaType` types):
```
# 1. TYPE_SYSTEM: system bars (status bar + three-button navigation bar)
I Flutter: avoidAreaChangeCallback, type=TYPE_SYSTEM, area={topRect: {height: 36}, bottomRect: {height: 28}, ...}

# 2. TYPE_CUTOUT: punch-hole/notch area
I Flutter: avoidAreaChangeCallback, type=TYPE_CUTOUT, area={topRect: {height: 84}, leftRect: {width: 0}, rightRect: {width: 0}, ...}

# 3. TYPE_NAVIGATION_INDICATOR: gesture navigation bar (bottom HOME bar)
I Flutter: avoidAreaChangeCallback, type=TYPE_NAVIGATION_INDICATOR, area={bottomRect: {height: 24}, ...}

# 4. TYPE_KEYBOARD: soft keyboard
I Flutter: avoidAreaChangeCallback, type=TYPE_KEYBOARD, area={bottomRect: {height: 280}}
```

> **Tip for beginners**: Not all four types are triggered every time; the system pushes only the types that changed based on the current UI state. For example, on punch-hole devices `TYPE_CUTOUT` is usually reported only once at startup/screen rotation, and `TYPE_KEYBOARD` is reported only when the keyboard appears/disappears.

**Troubleshooting**:

| Symptom | Possible cause | Solution |
|------|---------|---------|
| Avoid areas always 0 | `setWindowLayoutFullScreen(true)` not called | Set full-screen layout in EntryAbility |
| Avoid area not updated after rotation | FlutterView did not receive `avoidAreaChange` | Check that the callback registration succeeded |
| Wrong avoidance in split-screen scenarios | Cached padding values used | Read `MediaQuery.of(context).padding` in real time |
| Avoid area not restored after the keyboard appears | `viewInsets` not reset to zero | Check the `onKeyboardAreaChange` logic |
| Punch-hole area not avoided (content occluded) | `TYPE_CUTOUT` not listened to, or `SafeArea` top not taking effect | Confirm `setWindowLayoutFullScreen(true)` is enabled and use `SafeArea(top: true)` |
| Bottom content occluded by the gesture bar | `TYPE_NAVIGATION_INDICATOR` not listened to, or bottom padding is 0 | `SafeArea(bottom: true)`; re-read `MediaQuery.viewPadding.bottom` after rotation |

**Key log**:
```
# Avoid area changes are ignored when FlutterView is inactive (normal behavior)
D Flutter: <viewId> is not active. Ignoring avoid area change.
```

### 3.2 Avoidance Anomalies in Full-Screen Mode

In full-screen mode (`SystemUiMode.immersive`), avoid area handling follows different logic:

| Mode | padding behavior | viewInsets behavior |
|------|-------------|----------------|
| Non-full-screen | Custom value or 0 | keyboardAvoidArea |
| Full-screen | systemAvoidArea | keyboardAvoidArea |

**Troubleshooting**: Check the full-screen decision logic in the `onAreaChange` method:

```bash
hdc shell hilog | grep -E "onAreaChange|setFullScreen|UseFullScreen"
```

### 3.3 Window Decoration Avoidance Issues (PC Free Multi-Window)

In PC free multi-window mode, the window title bar buttons (maximize/minimize/close) may occlude content.

```bash
hdc shell hilog | grep -E "windowTitleButtonRect|windowDecor|handleWindowDecorSafeArea"
```

**Key logs**:

| Log | Meaning |
|------|------|
| `windowTitleButtonRectChangeCallback {...}` | Window decoration button area changed |
| `Failed to get window status: ...` | Failed to get the window status (abnormal) |
| `Failed to check window decor visibility support` | Checking window decoration support failed |

**Constraints**:
- Supported only on API 18+
- Effective only in free multi-window mode (`isWindowDecorSafeAreaAvoidSupported` returns true)
- Avoidance is skipped in MAXIMIZE mode (the window menu bar is shown temporarily)

**Common issues**:
- Avoidance not working after exiting free multi-window mode → check whether `windowTitleButtonRectChangeCallback` is triggered
- Content moves up after the status bar is hidden → `setPaddingTop` is set automatically when status is hidden in `setSpecificSystemBarEnabled`

### 3.4 Avoidance Checklist

- [ ] Search HiLog for `avoidAreaChangeCallback` to confirm avoid area updates (should cover all four types: TYPE_SYSTEM/TYPE_CUTOUT/TYPE_NAVIGATION_INDICATOR/TYPE_KEYBOARD)
- [ ] Confirm `setWindowLayoutFullScreen(true)` is set
- [ ] Check the padding value logic in full-screen/non-full-screen modes
- [ ] On punch-hole devices, confirm `TYPE_CUTOUT` is triggered and used for the top SafeArea
- [ ] On gesture navigation devices, confirm `TYPE_NAVIGATION_INDICATOR` is triggered and used for the bottom SafeArea
- [ ] Search `windowTitleButtonRect` to confirm window decoration avoidance (PC)
- [ ] Confirm `MediaQuery.of(context).padding` is used instead of cached values
- [ ] Confirm the `SafeArea` top/bottom parameters switch with the full-screen state

---

## 4. Foldable DisplayFeature Issues

### 4.1 DisplayFeature Missing

Flutter OHOS obtains screen features (punch-hole, crease, etc.) through `MediaQuery.of(context).displayFeatures`.

```bash
hdc shell hilog | grep -E "displayFeature|displayFeatures|cutoutInfo"
```

**Normal log**:
```
D Flutter: device displayFeatures is : [{"bound":{...},"type":3,"state":0}]
```

**type value meanings**: 0=UNKNOWN, 1=FOLD, 2=HINGE, 3=CUTOUT

### 4.2 Fold Status Listening

```bash
hdc shell hilog | grep -E "foldStatus|Fold status|foldStatusChange"
```

**Normal log**:
```
D Flutter: Fold status change to {"status":1}  // 1=unfolded, 2=folded, 3=half-folded
```

**Fold status codes**:

| Status code | Meaning |
|--------|------|
| 0 | UNKNOWN |
| 1 | Fully unfolded (FLAT) |
| 2 | Fully folded |
| 3 | Half-folded (stand mode) |

### 4.3 FOLD Feature Not Working

**Known limitation**: The FOLD (crease) feature is **commented out** in `buildDisplayFeatures` in `FlutterView.ets`, because the OHOS `getCurrentFoldCreaseRegion` API has a bug (inaccurate crease region, displayId comparison failures). Currently only CUTOUT (punch-hole) works.

**Impact**:
- `DisplayFeatureType.fold` and `DisplayFeatureType.hinge` are never populated
- The `DisplayFeatureSubScreen` widget cannot avoid the crease
- The crease region on an unfolded foldable must be obtained manually through a platform channel

**Alternative**: Obtain the crease region through a MethodChannel:

```dart
final creaseRegion = await MethodChannel('fold_status_detector')
    .invokeMethod('getCreaseRegion');
// Returns [top, height] crease position information
```

### 4.4 Foldable Checklist

- [ ] Search HiLog for `displayFeatures` to confirm DisplayFeature is built
- [ ] Search HiLog for `Fold status change` to confirm fold status listening works
- [ ] Confirm only CUTOUT currently works (FOLD is commented out)
- [ ] If crease avoidance is required, confirm the crease region is obtained through a platform channel
- [ ] Confirm `DisplayFeatureSubScreen` uses the correct displayFeatures

---

## 5. DPI Scaling Issues

### 5.1 devicePixelRatio Not Updating

```bash
hdc shell hilog | grep -E "device pixel ratio|devicePixelRatio|densityUpdate|dpiScale"
```

**Key logs**:

| Log | Meaning |
|------|------|
| `Device pixel ratio updated: 3.0` | DPI updated successfully |
| `Resetting device pixel ratio to system default: 3.0` | Reset to the system default DPI |
| `Scaling device pixel ratio by factor 0.85: 2.55` | DPI adjusted by a scale factor |
| `Error updating device pixel ratio: ...` | DPI update failed (abnormal) |
| `densityUpdateCallback: customDensity=..., sysDensity=...` | Density change callback |

### 5.2 Custom DPI Not Taking Effect

Custom DPI is set through the `updateDpiScale` method of the `flutter/displaymetrics` channel.

**Troubleshooting steps**:

1. Confirm `DisplayMetricsChannel` is registered
2. Search the logs to confirm the DPI scaling call:

```bash
hdc shell hilog | grep -E "displaymetrics|updateDpiScale|customDpi"
```

3. Confirm the custom DPI reset logic on route switches:

```bash
hdc shell hilog | grep -E "customDpiActive|currentUri|setCurrentUri"
```

**Key behavior**: On a route switch (push start), if the routeName differs from the current URI, the custom DPI is reset:
```
setCurrentUri('')  → clears the current URI
setCustomDpiActive(false)  → disables custom DPI
```

### 5.3 DPI Anomalies Caused by Window Size Changes

```bash
hdc shell hilog | grep -E "windowSizeChangeCallback"
```

**Normal logs**:
```
I Flutter: windowSizeChangeCallback: width=..., height=..., lastHeight=...
I Flutter: windowSizeChangeCallback devicePixelRatio: 3.0
I Flutter: windowSizeChangeCallback: Updated devicePixelRatio to 3.0
```

**Abnormal log**:
```
E Flutter: windowSizeChangeCallback error: ...
```

### 5.4 DPI Checklist

- [ ] Search HiLog for `device pixel ratio` to confirm DPI updates
- [ ] Search `densityUpdateCallback` to confirm density change listening
- [ ] Search `updateDpiScale` to confirm custom DPI calls
- [ ] Confirm the DPI reset logic on route switches works normally
- [ ] Search `windowSizeChangeCallback` to confirm window size change handling
- [ ] Confirm `AdaptiveDpiColumn` takes effect only in Release mode

---

## 6. LTPO Adaptive Refresh Issues

### 6.1 LTPO Not Working

**Prerequisites**:
- OpenHarmony API 20+
- System refresh rate set to "Smart"
- `SWITCH` is 1 in `framesconfig.json`
- The system frame rate policy has been pushed via cloud configuration

**Troubleshooting steps**:

```bash
hdc shell hilog | grep -E "LTPO|ltpo|nativevsync|sendVelocity|checkLTPO"
```

**Key logs**:

| Log | Meaning | Level |
|------|------|------|
| `[LTPO] Notifying the VSync signal may require a high frame rate.` | LTPO requests a high frame rate | Engine internal |
| `LTPO: Check switch status timed out, assuming ltpoOff` | LTPO switch check timed out | debugPrint |
| `LTPO: Failed to check switch status: ...` | LTPO switch check failed | debugPrint |
| `LTPO abnormal velocity detected: ... px/s from ...` | Abnormal velocity (>16000px/s) | debugPrint (Debug only) |
| `LTPO[scroll]...: ... px/s` | Velocity reporting details | debugPrint (requires `debugPrintLTPO` enabled) |

### 6.2 Velocity Reporting Chain

Complete LTPO velocity reporting chain:

```
Velocity generated on the Dart side
├─ Page transition (routes.dart) → recordTranslateVelocity(source: pageTransition)
├─ Hero animation (heroes.dart) → recordTranslateVelocity(source: pageTransition)
├─ Scrolling (gestures) → recordTranslateVelocity(source: scroll)
└─ Widget animation → recordTranslateVelocity(source: widget)
     │
     ├─ LTPODetector detects abnormal velocity (Debug mode, alert above 16000px/s)
     │
     └─ Every frame _sendAllTranslateVelocity → SystemChannels.nativeVsync.invokeMethod('sendVelocity')
          │
          └─ NativeVsyncChannel.ets → FlutterNapi.animationVoting(TRANSLATE, velocity)
               │
               └─ The system decides the actual frame rate from the velocity-to-frame-rate mapping in framesconfig.json
```

**Verifying velocity reporting**:

```dart
// Enable LTPO debug logs in Dart code
WidgetsBinding.instance.debugPrintLTPO = true;
```

### 6.3 framesconfig.json Configuration Issues

**Configuration file location**: `ohos/entry/src/main/resources/rawfile/framesconfig.json`

```json
{
  "SWITCH": 1,
  "TRANSLATE": [
    { "serial_number": 1, "min": 800, "max": -1, "preferred_fps": 90 },
    { "serial_number": 2, "min": 77, "max": 800, "preferred_fps": 120 },
    { "serial_number": 3, "min": 46, "max": 77, "preferred_fps": 90 },
    { "serial_number": 4, "min": 10, "max": 46, "preferred_fps": 72 },
    { "serial_number": 5, "min": 0, "max": 10, "preferred_fps": 60 }
  ],
  "SCALE": [],
  "ROTATION": []
}
```

**Common configuration problems**:

| Problem | Cause | Solution |
|------|------|---------|
| LTPO not working at all | `SWITCH` is 0 | Change it to `1` |
| Frame rate always 60 | File missing or wrong path | Confirm it is under the `rawfile/` directory |
| Incorrect frame rate switching | Wrong velocity range configuration | Use the default configuration; modification is not recommended |
| SCALE/ROTATION not working | Not implemented yet | Only TRANSLATE works |

### 6.4 Navigator Transition Trace

Page transitions (push/pop) output performance traces through `hiTraceMeter`:

```bash
hdc shell hitrace --trace_clock boottime -t 10 flutter -o /data/local/tmp/trace.ftrace
```

**Search in the trace**:

| Trace event | Meaning |
|-----------|------|
| `flutter::NAVIGATOR_PUSH` | Page push transition (start → finish) |
| `flutter::NAVIGATOR_POP` | Page pop transition (start → finish) |

**Navigator activity logs**:

```bash
hdc shell hilog | grep -E "reportNavigatorActivity|NAVIGATOR"
```

**Abnormal logs**:

| Log | Meaning |
|------|------|
| `reportNavigatorActivity, args is null or not a Map` | Wrong parameter format |
| `reportNavigatorActivity, incorrect parameter activity` | Missing activity parameter |
| `reportNavigatorActivity, incorrect parameter status` | Missing status parameter |

### 6.5 LTPO Checklist

- [ ] Confirm the system version is ≥ API 20
- [ ] Confirm the system refresh rate is set to "Smart"
- [ ] Confirm `framesconfig.json` exists and `SWITCH` is 1
- [ ] Search HiLog for `LTPO` to confirm the switch state is normal
- [ ] Enable `debugPrintLTPO = true` to confirm velocity reporting
- [ ] Search `LTPO abnormal velocity` to check for abnormal velocity
- [ ] Capture HiTrace to check `flutter::NAVIGATOR_PUSH/POP` transition durations
- [ ] Confirm `sendVelocity` is called normally (search `nativevsync`)
- [ ] Contact the interface owner to confirm the system frame rate policy has been pushed via cloud configuration

---

## 7. Multi-Window / Free Window Issues

### 7.1 Layout Not Refreshing on Window Size Changes

```bash
hdc shell hilog | grep -E "windowSizeChangeCallback|windowRectChange|windowStatusChange"
```

**Key callbacks**:

| Callback | Log keyword | Purpose |
|------|-----------|------|
| `windowSizeChangeCallback` | `windowSizeChangeCallback` | Window size change (updates DPI) |
| `windowRectChangeCallback` | `windowRectChange` | Window position change |
| `windowStatusChangeCallback` | `windowStatusChange` | Window status change (full-screen/split-screen, etc.) |

**Common causes of layout not refreshing**:

- `WidgetsBindingObserver.didChangeMetrics` not listened to
- Cached `MediaQuery` values used
- Split view activation state not updated (`_checkScreenSizeAndSetSplitScreen`)

### 7.2 Free Multi-Window Immersive Mode Anomalies

**Important**: Free multi-window immersive mode **must not** use `setWindowLayoutFullScreen`; use the following instead:
- `setWindowDecorVisible(false)` — hides the status bar
- `setWindowTitleButtonVisible(false, false, false)` — hides the window buttons

**Troubleshooting**:

```bash
hdc shell hilog | grep -E "setWindowDecorVisible|setWindowTitleButtonVisible|WindowDecor"
```

### 7.3 Multi-Window Checklist

- [ ] Search `windowSizeChangeCallback` to confirm window change callbacks
- [ ] Confirm `WidgetsBindingObserver.didChangeMetrics` is implemented
- [ ] Confirm `MediaQuery.of(context)` is used to obtain sizes in real time
- [ ] Confirm free multi-window immersive mode uses `setWindowDecorVisible` instead of `setWindowLayoutFullScreen`
- [ ] Search `windowTitleButtonRect` to confirm window decoration avoidance

---

## 8. HiLog Keyword Quick Reference

| HiLog keyword | Issue type | Meaning | Source file |
|-------------|---------|------|---------|
| `SplitView: Main page determined by` | Split view | How the home page was identified | app.dart |
| `SystemChannel config parse failed` | Split view | Configuration parse failure | split_view_config_loader.dart |
| `SplitViewConfig: Failed to decode placeholder icon` | Split view | Placeholder icon decode failure | split_view_config.dart |
| `Cannot determine main page for split screen` | Split view | Cannot determine the home page (fatal) | app.dart |
| `avoidAreaChangeCallback, type=TYPE_SYSTEM` | Avoidance | System bar (status bar + three-button navigation bar) change | FlutterView.ets |
| `avoidAreaChangeCallback, type=TYPE_CUTOUT` | Avoidance | Punch-hole/notch area change | FlutterView.ets |
| `avoidAreaChangeCallback, type=TYPE_NAVIGATION_INDICATOR` | Avoidance | Gesture navigation bar change | FlutterView.ets |
| `avoidAreaChangeCallback, type=TYPE_KEYBOARD` | Avoidance | Soft keyboard shown/hidden | FlutterView.ets |
| `is not active. Ignoring avoid area change` | Avoidance | Inactive view ignores avoidance | FlutterView.ets |
| `windowTitleButtonRectChangeCallback` | Avoidance | Window decoration button change | FlutterView.ets |
| `handleWindowDecorSafeArea` | Avoidance | Window decoration avoidance handling | FlutterManager.ets |
| `Failed to get window status` | Avoidance | Failed to get window status | FlutterManager.ets |
| `device displayFeatures is :` | Foldable | DisplayFeature build result | FlutterView.ets |
| `Fold status change to` | Foldable | Fold status change | FlutterView.ets |
| `Device pixel ratio updated:` | DPI | DPI updated successfully | FlutterView.ets |
| `Resetting device pixel ratio` | DPI | Reset to system default | FlutterView.ets |
| `Scaling device pixel ratio by factor` | DPI | Scaled by factor | FlutterView.ets |
| `Error updating device pixel ratio` | DPI | DPI update failed | FlutterView.ets |
| `densityUpdateCallback: customDensity=` | DPI | Density change callback | FlutterView.ets |
| `windowSizeChangeCallback: width=` | Multi-window | Window size change | FlutterView.ets |
| `windowSizeChangeCallback error:` | Multi-window | Window size change error | FlutterView.ets |
| `[LTPO] Notifying the VSync` | LTPO | LTPO requests a high frame rate | FlutterView.ets |
| `LTPO: Check switch status timed out` | LTPO | Switch check timed out | binding.dart |
| `LTPO: Failed to check switch status` | LTPO | Switch check failed | binding.dart |
| `LTPO abnormal velocity detected:` | LTPO | Abnormal velocity alert | binding.dart |
| `reportNavigatorActivity, args is null` | Transition | Navigation report parameter error | NavigationChannel.ets |

---

## 9. Trace Analysis

### 9.1 Multi-Device Related Trace Events

```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace
```

Search in Chrome `chrome://tracing`:

| Trace event | Meaning | Analysis use |
|-----------|------|---------|
| `flutter::NAVIGATOR_PUSH` | Page push transition | Transition animation duration |
| `flutter::NAVIGATOR_POP` | Page pop transition | Back navigation animation duration |
| `Flutter Lost Frames` | Dropped frame count | Frame drops during transitions/split view switches |
| `Flutter Hitch Time` | Dropped frame details | Frame duration breakdown |
| `feedFlutterWatchdog` | Thread heartbeat | Whether threads are healthy |

### 9.2 Split View Switch Trace Analysis

When split view is activated/deactivated, watch the following timeline:
1. `windowSizeChangeCallback` triggered → DPI updated
2. `didChangeMetrics` callback → `_checkScreenSizeAndSetSplitScreen` decision
3. `SplitViewManager.setSplitViewActive` → `notifyListeners`
4. `buildOverlayLayout` → rebuilds the Overlay layout

If split view switching is janky, check the duration of the steps above in the trace.

### 9.3 LTPO Frame Rate Switching Verification

1. Enable "Show refresh rate" (developer options)
2. Open a page with scrollable components in the app
3. Fling-scroll the page and watch the frame rate change: 120 → 90 → 60
4. If the frame rate does not change, follow the troubleshooting steps in §6

---

## 10. Log Level Notes

| Mode | Visible log levels | Notes |
|------|------------|------|
| Debug | DEBUG + INFO + WARN + ERROR | All logs visible |
| Profile | WARN + ERROR | DEBUG/INFO filtered out |
| Release | WARN + ERROR | DEBUG/INFO filtered out |

> **Note**: `debugPrint` on the Dart side is output only in Debug mode.
> `Log.d`/`Log.i` on the ETS side are filtered out in Release/Profile mode.
> Debug mode is recommended when troubleshooting multi-device issues.

### Enabling Dart-Side Debug Logs

```dart
// Enable LTPO debug logs
WidgetsBinding.instance.debugPrintLTPO = true;

// SplitView logs are output automatically in Debug mode by default
// No extra switch needed
```

---

## 11. Multi-Device Adaptation Master Checklist

- [ ] Capture full logs: `hdc shell hilog > flutter_log.txt`
- [ ] Search `SplitView` to confirm split view configuration loading and home page detection
- [ ] Search `avoidAreaChangeCallback` to confirm avoid area updates
- [ ] Search `displayFeatures` to confirm DisplayFeature construction
- [ ] Search `Fold status change` to confirm fold status listening
- [ ] Search `device pixel ratio` to confirm DPI updates
- [ ] Search `windowSizeChangeCallback` to confirm window change handling
- [ ] Search `LTPO` to confirm adaptive refresh status
- [ ] Search `windowTitleButtonRect` to confirm window decoration avoidance (PC)
- [ ] Confirm `split_config.json` and `framesconfig.json` are configured correctly
- [ ] Capture HiTrace to analyze transitions and frame rates: `hdc shell hitrace --trace_clock boottime -t 30 flutter`
- [ ] Record the device type and interaction scenario where the problem occurred
