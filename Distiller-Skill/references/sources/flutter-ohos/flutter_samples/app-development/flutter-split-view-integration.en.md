# Flutter Split View (Parallel View) Integration Guide

> **Version Note:** The split view (Parallel View) feature is supported since Flutter `3.35.8-ohos-1.0.3`.

## 1. Split View Feature Overview

Flutter split view feature provides portrait/landscape adaptive split layout for applications, achieving left-right split display effects similar to tablet/foldable screen devices:

| Screen State | Layout Behavior |
|--------------|-----------------|
| Landscape/Wide screen | Both sides displayed simultaneously: home page on left + detail page on right |
| Portrait/Narrow screen | Single pane display, intelligently switching between home and detail page |
| Foldable screen unfolded | Automatically switches to split layout |
| Foldable screen folded | Automatically switches to single pane layout |

**Feature Highlights:**
- Automatically adapts to screen size changes, no application code modification required
- Split view feature is disabled by default, enabled through configuration file

**Example Application:**
For a complete example, see [split_view_sample](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/split_view_sample), which implements 8 routing schemes to test split view behavior across different routing paradigms.

**Split View Support Scope:**
- The split view feature currently supports both Navigator-based routing and Router-based declarative routing (including RouterDelegate, RouterConfig, go_router library, etc.)
- Router mode is implemented based on single NavigatorState + dual Overlay, unified handling at Navigator level, transparent to application layer.
- **Known Limitations:**
  - go_router compatibility is theoretically supported, recommend thorough validation

**Preview:**

![split_view_picture.png](../media/rendering-engine/split_view_picture.png)

## 2. Split View Activation Instructions

Split view is disabled by default. The application only needs to place the `split_config.json` configuration file at the specified location and set `enableWideWindowSplit` or `enableSquareWindowSplit` to `true` to enable split view. SDK automatically loads this configuration file at application startup, without any initialization operations in Dart code. The configuration file can also specify home page route name, fullscreen page list and other options, see details below for each configuration item.

### 2.1 Configuration File Location

```
ohos/entry/src/main/resources/rawfile/split_config.json
```

### 2.2 Configuration File Content

```json
{
  "splitOptions": {
    "enableWideWindowSplit": false,
    "enableSquareWindowSplit": true,
    "homePage": "/",
    "fullScreenPages": ["/videoPlayer", "/imageViewer"],
    "enableReducedContainerSize": true,
    "supportLandscapeFullscreen": true
  }
}
```

| Configuration Item | Type | Default Value | Description |
|--------------------|------|---------------|-------------|
| `enableWideWindowSplit` | bool | false | Wide screen device split view toggle |
| `enableSquareWindowSplit` | bool | false | Square screen device split view toggle |
| `homePage` | String? | null | Home page route name, null for auto-detection |
| `fullScreenPages` | List<String> | [] | List of route names for pages requiring forced fullscreen display |
| `enableReducedContainerSize` | bool | true | Component width displayed based on half of screen width |
| `supportLandscapeFullscreen` | bool | true | Whether to display fullscreen in landscape mode |

### 2.3 Configuration Item Details

#### enableWideWindowSplit

**Function Description:** Wide window split view toggle, controls whether to enable split layout on wide screen devices.

| Value | Effect |
|-------|--------|
| `true` | Split layout enabled on wide screen devices |
| `false` (default) | Split layout not enabled on wide screen devices |

**Applicable Scenarios:**
- `true`: Suitable for tablets, PCs, foldable screens in unfolded state and other wide screen devices where split layout is desired in landscape mode
- `false`: Suitable for applications that do not want to enable split view on wide screens

**Trigger Conditions:**
- Screen width > 600dp and height > 600dp
- Screen aspect ratio > 1.2
- Landscape orientation

#### enableSquareWindowSplit

**Function Description:** Square screen split view toggle, controls whether to enable split layout on square screen devices.

| Value | Effect |
|-------|--------|
| `true` | Split layout enabled on square screen devices |
| `false` (default) | Split layout not enabled on square screen devices |

**Applicable Scenarios:**
- `true`: Suitable for square screen devices (such as dual-foldable screens in unfolded state) where split layout is desired on square screens
- `false`: Suitable for applications that do not want to enable split view on square screens

**Trigger Conditions:**
- Screen width > 600dp and height > 600dp
- Screen aspect ratio and inverse aspect ratio both less than 1.2

#### homePage

**Function Description:** Specifies the route name of the home page for split layout home page identification.

| Value | Effect |
|-------|--------|
| Route name (e.g., `/home`) | Explicitly specifies home page route, split view uses this page as the fixed left-side page |
| `` (default) | Auto-detect home page |

**Applicable Scenarios:**
- Explicitly specified route name: Suitable for applications with a clear home page, ensuring the correct page is always displayed on the left side of split view
- Auto-detection: Suitable for simple applications using Navigator-based routing, where SDK automatically determines the home page

> ⚠️ Important: Router mode (RouterDelegate, RouterConfig, go_router) does NOT support auto-detection. The homePage field is required for Router mode applications. Leaving it empty will cause split view to malfunction.

**Navigator Mode Configuration:**

Navigator mode requires that the homePage value in configuration file matches the route configuration in code, set as follows:

```dart
// Method 1: Using home parameter
return MaterialApp(
  home: const HomePage(),
  onGenerateRoute: (RouteSettings settings) {
    switch (settings.name) {
      case '/first':
        return MaterialPageRoute(builder: (_) => const FirstPage(), settings: settings);
      // ... other page
      default:
        return MaterialPageRoute(builder: (_) => const UnknownPage(), settings: settings);
    }
  },
  // routes: { *** } routes parameter is mutually exclusive with onGenerateRoute parameter
);

// Method 2: Using initialRoute and onGenerateRoute
return MaterialApp(
  initialRoute: '/splash',
  onGenerateRoute: (settings) {
    if (settings.name == '/home') {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => HomePage(), // Set to the settings.name of home page in configuration file, i.e., '/home'
      );
    }
    // ...other pages
  }
);

// Method 3: Using initialRoute and routes table
return MaterialApp(
  initialRoute: '/splash',
  routes: {
    "/home": (context) => const HomePage(), // Set to the key name of home page in configuration file, i.e., '/home'
    // ...other pages
  }
);

```

**Router Mode Configuration:**

Router mode (RouterDelegate, RouterConfig) uses `Page` objects to manage routes, where route name is determined by `Page.name` property:

```dart
// Page configuration in RouterDelegate / RouterConfig
pages: [
  MaterialPage(
    name: '/home',  // Page.name determines RouteSettings.name
    child: HomePage(),
  ),
]
```

**go_router Mode Configuration:**

go_router uses `GoRoute` to define routes, where route name is determined by `GoRoute.name` property.

Note: When a page lacks the name parameter, go_router library generates RouteSettings.name using the path parameter.

```dart
// go_router route configuration
GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      name: '/home',  // GoRoute.name determines RouteSettings.name, must match homePage in configuration file
      builder: (context, state) => HomePage(),
    ),
  ],
)
```

**Auto-detection Logic:**
In Navigator route mode, when `homePage` is configured as empty, SDK automatically determines the home page in the following order:
1. `home` parameter of MaterialApp/CupertinoApp
2. `/home`, `/`, `/index` routes in the `routes` array
3. Route specified by `initialRoute` parameter
4. If none of the above exist, an error occurs and the application exits

Router route mode does not support auto-detecting the home page.

**Notes:**
> - Use `Navigator.pushNamed` or `MaterialPageRoute(settings: ...)` with route name for navigation to correctly determine if the target page is the home page

#### fullScreenPages

**Function Description:** Specifies a list of route names for pages requiring forced fullscreen display.

| Value | Effect |
|-------|--------|
| Route name list (e.g., `["/videoPlayer"]`) | Automatically switches to fullscreen single pane layout when entering these pages |
| `[]` (default) | No fullscreen pages |

**Applicable Scenarios:**
- Video playback pages, image viewing pages, game pages and other scenarios requiring fullscreen display
- After entering fullscreen pages, split layout is automatically disabled, and automatically restored when exiting

**Notes:**
- Multiple route names separated by commas
- Use `Navigator.pushNamed` or `MaterialPageRoute(settings: ...)` with route name for navigation to correctly determine if the target page is a forced fullscreen page

#### enableReducedContainerSize

**Function Description:** Controls the width value returned by MediaQuery in split view mode.

| Value | Effect |
|-------|--------|
| `true` (default) | When split view is active, MediaQuery returns width as half of screen width |
| `false` | MediaQuery returns unchanged width, still the actual screen width |

**Applicable Scenarios:**
- `true`: Suitable for scenarios where application components need to adapt layout based on split view width, width obtained through `MediaQuery.of(context).size.width` automatically adapts to half of screen
- `false`: Suitable for scenarios where application handles width adaptation itself, or does not need MediaQuery width constraints

**Technical Implementation:**
- When `enableReducedContainerSize: true` and split view is active, SDK modifies width constraints through MediaQuery, making component-obtained width half of screen width
- Application can obtain adapted width value through `MediaQuery.of(context).size.width`

#### supportLandscapeFullscreen

**Function Description:** Controls the trigger condition for landscape fullscreen display.

| Value | Effect |
|-------|--------|
| `true` (default) | When a page is forced to landscape, split view is automatically disabled and switches to fullscreen single pane display |
| `false` | Split layout is maintained even when page is forced to landscape |

**Applicable Scenarios:**
- `true`: Suitable for applications with pages that actively request landscape display, and where the application has already implemented layout design for landscape orientation, not wanting split view to change the landscape layout design
- `false`: Suitable for applications without pages that actively request landscape display, or even if actively requesting landscape still want split view to be effective

**Trigger Conditions:**
- Page has set forced landscape orientation (`SystemChrome.setPreferredOrientations`)
- And `supportLandscapeFullscreen: true`

**Flutter API for Requesting Display Orientation:**

Flutter applications request screen orientation from the native system through `SystemChrome.setPreferredOrientations`. If the parameters do not include portrait orientation (i.e., only landscapeLeft/landscapeRight), it is considered that the application actively requests landscape.

**Combined Usage:**
- Can be used together with `fullScreenPages` configuration item
- `fullScreenPages` controls fullscreen by route name, `supportLandscapeFullscreen` controls fullscreen by screen orientation

### 2.4 Configuration Examples

**Basic Configuration (Auto-detect home page):**
```json
{
  "splitOptions": {
    "enableWideWindowSplit": true
  }
}
```

**Specify home page and fullscreen pages:**
```json
{
  "splitOptions": {
    "enableWideWindowSplit": true,
    "homePage": "/home",
    "fullScreenPages": ["/videoPlayer", "/imageViewer"]
  }
}
```

## 3. Important Notes

### 3.1 Route Forwarding Execution Flow

Split view feature divides application execution into two phases, routes are managed by single NavigatorState, distributed to left and right sides through Overlay:

| Phase | Condition | Left Display | Right Display | Route Navigation Behavior |
|-------|-----------|--------------|---------------|---------------------------|
| Phase 1 | Home page not displayed | Target page (splash page/login page etc.) | Placeholder page | **Display on left Overlay**, right unchanged |
| Phase 2 | Home page displayed | Home page | Detail page or placeholder page | **Distribute to right Overlay for display** |

**Execution Flow Description:**

1. **Phase 1 - Home page not displayed:**
   - Application startup may go through splash page, login page and other intermediate pages
   - All page navigations are distributed to left Overlay
   - Right side keeps placeholder page unchanged
   - No route forwarding

2. **Phase transition - Home page displayed:**
   - When home page is actually displayed (navigate to home page or return to home page)
   - SDK detects current route name matches configured home page route name
   - Automatically switches to Phase 2 mode

3. **Phase 2 - Home page displayed:**
   - Left side fixed to display home page
   - All subsequent detail page navigations are automatically distributed to right Overlay for display
   - Right side dynamically switches detail page content

**Key Points:**
- Only after home page is displayed, detail pages will be distributed to right side
- In splash page → login page → home page flow, the first two pages are displayed on left
- After home page is displayed, clicking on detail items will be shown on right side
- Route history is maintained in single NavigatorState, left and right Overlay are only responsible for visual presentation

### 3.2 Route Configuration Scheme Selection

Split view feature supports the following route configuration schemes:

| Scheme | Routing Method | Configuration Items | Split View Compatibility | Restriction Description |
|--------|----------------|---------------------|--------------------------|-------------------------|
| Scheme 1 | Navigator (MaterialApp) | `initialRoute` + `onGenerateRoute` | ✅ Fully compatible | Recommended, supports complete flow |
| Scheme 2 | Navigator (MaterialApp) | `initialRoute` + `routes` | ✅ Fully compatible | Supports splash page → login page → home page flow |
| Scheme 3 | Navigator (MaterialApp) | `home` + `onGenerateRoute` | ⚠️ Partially compatible | **Does not support splash/login page flow**, starts directly into home page |
| Scheme 4 | Navigator (MaterialApp) | `home` + `routes` | ⚠️ Partially compatible | **Does not support splash/login page flow**, starts directly into home page |
| Scheme 5 | Navigator (CupertinoApp) | Same as Scheme 1-4 | ✅ Fully compatible | Equivalent to MaterialApp |
| Scheme 6 | Router (MaterialApp.router) | `RouterDelegate` + `pages` | ✅ Supported |  |
| Scheme 7 | Router (MaterialApp.router) | `RouterConfig` | ✅ Supported |  |
| Scheme 8 | Router (MaterialApp.router) | `go_router` library | ✅ Supported | Overlay scheme works for go_router's `_CustomNavigator` wrapper, recommend thorough validation |

**Reason for Restriction:**
- `home` directly specifies the home Widget, application starts directly into home page
- Cannot use `initialRoute: '/splash'` to set splash page as startup page

**Recommendations:**
- For applications requiring splash page/login page flow, use Scheme 1 or Scheme 2
- Simple applications can directly use Scheme 3 or Scheme 4
- Router mode preferentially uses Scheme 8 (GoRouter library)

### 3.3 Route API Usage Restrictions

#### 3.3.1 Route settings Parameter

**Must preserve the `settings` parameter, otherwise split view functionality is limited:**

| Route Creation Method | settings | Route Name | Split View Function |
|-----------------------|----------|------------|---------------------|
| `MaterialPageRoute(settings: settings, ...)` | ✅ Present | Valid | ✅ Can identify home/fullscreen page |
| `MaterialPageRoute(builder: ...)` | ❌ Missing | null | ⚠️ Cannot identify home/fullscreen page |
| `Navigator.pushNamed('/detail')` | ✅ Automatic | '/detail' | ✅ Can identify home/fullscreen page |

**Impact of Missing settings:**
- Cannot determine if route is home page → `homePage` configuration ineffective
- Cannot determine if route is fullscreen page → `fullScreenPages` configuration ineffective
- Split view default behavior still works, but special page identification fails

**Correct Usage:**
```dart
// ✅ Recommended: Use pushNamed
Navigator.pushNamed(context, '/detail');

// ✅ Recommended: Preserve settings in onGenerateRoute
onGenerateRoute: (settings) {
  return MaterialPageRoute(
    settings: settings,  // Preserve settings
    builder: (context) => DetailPage(),
  );
}

// ✅ Recommended: Manually set RouteSettings
Navigator.push(
  context,
  MaterialPageRoute(
    settings: RouteSettings(name: '/detail'),
    builder: (context) => DetailPage(),
  ),
);

// ❌ Avoid: Not setting settings
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DetailPage(),  // Cannot identify route name
  ),
);
```

#### 3.3.2 Supported Route APIs

All Navigator route APIs are supported, split view behavior as follows:

| API | Phase 1 Behavior | Phase 2 Behavior |
|-----|------------------|------------------|
| `push(Route)` | Push to left Overlay | Push to right Overlay |
| `pushNamed(String)` | Push to left Overlay | Push to right Overlay |
| `pushReplacement(Route)` | Replace on left Overlay | ⚠️ When initiated from home page, becomes normal push (see below) |
| `pushAndRemoveUntil(Route, predicate)` | Push to left Overlay and clear stack | ⚠️ When initiated from home page, becomes normal push (see below) |
| `pop()` | Dialog priority → right → left | Dialog priority → right → left |
| `canPop()` | Right priority check | Right priority check |
| `maybePop()` | Right priority | Right priority |

**Special Behavior of `pushReplacement` / `pushAndRemoveUntil` from Home Page:**

When left side displays home page, left side is fixed as home page. When calling `pushReplacement` or `pushAndRemoveUntil` from home page, since home page cannot be replaced or removed (otherwise left side would be blank), SDK will **downgrade to normal `push`**, detail page still distributed to right Overlay. This is known behavior, not a bug.

#### 3.3.3 Unsupported Route Patterns

**Does not support ternary expression for home page determination:**
```dart
// ❌ Not supported: Cannot identify
MaterialApp(
  home: isLoggedIn ? HomePage() : LoginPage(),
);

// ✅ Correct approach: Use initialRoute + route table
MaterialApp(
  initialRoute: isLoggedIn ? '/home' : '/login',
  routes: {
    '/login': (context) => LoginPage(),
    '/home': (context) => HomePage(),
  },
);
```

### 3.4 Dialog Handling Notes

In split view mode, PopupRoute (dialogs, menus, etc.) automatically displays on the side with content:

| Right Side Status | Dialog Position | Mask Layer |
|-------------------|-----------------|------------|
| Placeholder page | Left side | Right side covered synchronously |
| Detail page | Right side | Left side covered synchronously |

**No Extra Handling Required:**
- SDK automatically determines dialog position
- SDK automatically adds synchronized mask layer
- Mask layer automatically removed when dialog closes

**Notes:**
- Dialog push/pop triggers Overlay operations on both left and right sides
- **`useRootNavigator` Difference:** `showModalBottomSheet`, `showMenu`, `showSearch` and other APIs default `useRootNavigator: false`, in split view scenario need to explicitly set to `true`, to correctly display mask layer. Especially important in mixed routing scenarios (such as navigating from a Navigator page to a Router page)

```dart
// ❌ Incorrect mask layer in split view
showModalBottomSheet(
  context: context,
  builder: (context) => SheetContent(),
);

// ✅ Need to explicitly set useRootNavigator: true
showModalBottomSheet(
  context: context,
  useRootNavigator: true,  // Key
  builder: (context) => SheetContent(),
);
```

### 3.5 Lifecycle Notes

**Lifecycle Callbacks Maintain Original Behavior:**

Split view mode adopts a single NavigatorState + dual Overlay approach, where route lifecycle callbacks behave consistently with normal Flutter applications:

- Routes are managed uniformly in a single NavigatorState
- RouteObserver/RouteAware usage remains unchanged, requiring no additional handling
- `didPush`, `didPop`, `didPopNext`, `didChangeNext` and other callbacks trigger according to Flutter standard behavior

### 3.6 Page Transition Animation Notes

Split view mode supports custom PageRoute animations:

| Animation Type | Support Status |
|----------------|----------------|
| MaterialPageRoute | ✅ Supported |
| CupertinoPageRoute | ✅ Supported |
| Custom PageRoute | ✅ Supported |
| No animation route | ✅ Supported |

### 3.7 Back Gesture Notes

System back key/gesture back is automatically handled by SDK:

**Back Priority:**
1. Dialog is displaying → Close dialog
2. Right Overlay has poppable route → Right side pop
3. Left Overlay has poppable route → Left side pop
4. Both sides cannot pop → Exit application

**No Extra Handling Required:**
- SDK automatically intercepts `didPopRoute`
- Back logic executes in single NavigatorState's route history by Overlay distribution order
- Back logic executes by priority
- Application can customize back behavior through `WillPopScope`

### 3.8 Fullscreen Page Notes

Some pages (such as video playback) require forced fullscreen:

**Configuration Method:**
```json
{
  "splitOptions": {
    "fullScreenPages": ["/videoPlayer", "/imageViewer"]
  }
}
```

**Effects:**
- Enter fullscreen page: Automatically switches to single pane layout
- Leave fullscreen page: Restores split layout

### 3.9 Screen Rotation/Foldable Screen Notes

SDK automatically monitors screen changes:

| Scenario | Automatic Behavior |
|----------|-------------------|
| Portrait → Landscape | Single pane → Split view |
| Landscape → Portrait | Split view → Single pane |
| Foldable screen unfolded | Single pane → Split view |
| Foldable screen folded | Split view → Single pane |

**Split View Activation Conditions:**
- Width > 600dp and height > 600dp
- Determined by different configuration items based on whether screen is wide or square

**No Extra Handling Required:**
- `didChangeMetrics()` automatically triggers
- Route stack and state fully preserved

**Common Problem Troubleshooting:**

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| Split view not working | Configuration file not enabled | Check `enableWideWindowSplit: true` |
| Home page identification error | `homePage` configuration error | Configure according to Section 2.3 homePage item instructions |
| Detail page not forwarding | `settings` missing | Ensure preserving settings parameter |
| Fullscreen page still in split view | `fullScreenPages` not configured | Add route name to configuration list |
| RouterConfig system back key exits application | `RootBackButtonDispatcher` not set | Set `RootBackButtonDispatcher()` in `RouterConfig` |
| Dialog mask layer not showing | `useRootNavigator` not set | `showModalBottomSheet` etc. need to explicitly set `useRootNavigator: true`, see Section 3.4 |
| GoRouter fullscreen page not working | `GoRoute.name` doesn't match configuration | Ensure `GoRoute.name` matches `fullScreenPages` configuration exactly (e.g., `/video`) |
| `pushReplacement` from home page behaves abnormally | Home page cannot be replaced | This is known behavior, SDK downgrades to normal push, see Section 3.3.2 explanation |