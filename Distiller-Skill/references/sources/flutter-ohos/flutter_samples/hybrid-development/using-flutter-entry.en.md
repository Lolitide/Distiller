# Using FlutterEntry in Hybrid Development

On the HarmonyOS (OHOS) platform, Flutter hybrid development requires embedding Flutter pages into native ArkTS pages via `FlutterEntry`, and managing the lifecycle of the Flutter engine, including creation, destruction, and page navigation.

This guide introduces how to use `FlutterEntry` to implement hybrid development and navigation between native pages and Flutter pages, covering both basic usage and integration with `Navigation`.

---

## Core Concepts

| Term | Description |
|------|------|
| `FlutterEntry` | Core class provided by flutter_ohos, responsible for managing the lifecycle of the Flutter engine within native pages, including engine creation, plugin registration, view retrieval, etc. |
| `FlutterView` | The Flutter rendering view object created by `FlutterEntry`, obtained via `getFlutterView()`, used to embed Flutter content into ArkTS pages |
| `FlutterPage` | ArkTS UI component that takes a `viewId` parameter and displays Flutter rendering content in a native page |
| `UIAbility` | HarmonyOS application component, similar to Android's Activity, serving as the application entry and window management carrier |
| `ExclusiveAppComponent` | Application component interface defined by flutter_ohos; UIAbility must implement this interface to bind with the Flutter engine |
| `FlutterManager` | Global manager provided by flutter_ohos, responsible for maintaining the stack relationship between UIAbility and WindowStage, ensuring the Flutter engine is correctly associated with its host |
| `NavPathStack` | The path stack for HarmonyOS Navigation, used to manage page navigation and back navigation |
| `NavFlutterEntry` | A custom class extending `FlutterEntry`, used in Navigation scenarios to handle the native back behavior of `SystemNavigator.pop()` |

### Hybrid Development Page Navigation Flow

```
Native page → Create FlutterEntry → Initialize Flutter engine → Get FlutterView → Render FlutterPage
                                                                          ↑
Native page navigation (router / Navigation) → FlutterEntry.aboutToAppear() → Engine starts
Native page back → FlutterEntry.aboutToDisappear() → Engine destroyed or cache recycled
```

---

## Prerequisites

- The project has integrated the `flutter_ohos` plugin, and relevant classes can be imported via `@ohos/flutter_ohos`.
- Flutter version 3.22 or above.
- Basic understanding of HarmonyOS `UIAbility` and `Navigation` concepts.

---

## Usage Steps

### Step 1: Make EntryAbility Extend UIAbility and Implement ExclusiveAppComponent

In hybrid development, `UIAbility` is the host component for the Flutter engine. `FlutterManager` needs to be aware of the creation and destruction of UIAbility to correctly manage the binding between the Flutter engine and the window. Therefore, `EntryAbility` must implement the `ExclusiveAppComponent<UIAbility>` interface and call the corresponding `FlutterManager` methods in key lifecycle callbacks.

#### Why Implement ExclusiveAppComponent

`ExclusiveAppComponent` is an application component interface defined by flutter_ohos. It requires the host to provide two methods: `getAppComponent()` and `detachFromFlutterEngine()`. `FlutterManager` uses this interface to obtain the real UIAbility instance for:
- Binding the correct UIAbility context when creating the engine
- Unbinding the UIAbility from the Flutter engine when destroying the engine
- Distinguishing the ownership of different UIAbilities in multi-engine scenarios

#### Complete Code Example

```ts
import { FlutterManager } from '@ohos/flutter_ohos';
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ExclusiveAppComponent } from '@ohos/flutter_ohos/src/main/ets/embedding/ohos/ExclusiveAppComponent';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {

  detachFromFlutterEngine(): void {
    // Called when the Flutter engine is unbound from this UIAbility
    // Default: no action needed. Implement cleanup logic here if required
  }

  getAppComponent(): UIAbility {
    // Return the current UIAbility instance for FlutterManager to obtain the host component
    return this;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // Push the current UIAbility onto the FlutterManager management stack
    // FlutterManager will obtain the context via the top UIAbility when creating the engine
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onDestroy(): void | Promise<void> {
    // Pop the current UIAbility from the FlutterManager management stack
    // Ensure the association with this UIAbility is cleaned up when the engine is destroyed
    FlutterManager.getInstance().popUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Set fullscreen layout to ensure the Flutter page renders correctly
    windowStage.getMainWindowSync().setWindowLayoutFullScreen(true);

    // Push the WindowStage onto the FlutterManager management stack
    // FlutterManager needs the WindowStage to bind the Flutter rendering surface
    FlutterManager.getInstance().pushWindowStage(this, windowStage);

    // Load the native entry page
    windowStage.loadContent('pages/Index');
  }

  onWindowStageDestroy() {
    // Pop the WindowStage from the FlutterManager management stack
    FlutterManager.getInstance().popWindowStage(this);
  }
}
```

#### Key Notes

| Method | When to Call | Purpose |
|------|----------|------|
| `pushUIAbility` | `onCreate` | Registers the UIAbility with FlutterManager so the host context can be obtained when creating the engine |
| `popUIAbility` | `onDestroy` | Removes the UIAbility from FlutterManager, cleaning up the association when the engine is destroyed |
| `pushWindowStage` | `onWindowStageCreate` | Registers the window stage with FlutterManager, used to bind the Flutter rendering surface |
| `popWindowStage` | `onWindowStageDestroy` | Removes the window stage from FlutterManager |
| `setWindowLayoutFullScreen` | `onWindowStageCreate` | Sets fullscreen layout; Flutter pages require a fullscreen rendering area by default |

> **Note**: `pushUIAbility` and `pushWindowStage` must be called as early as possible in `onCreate` and `onWindowStageCreate` respectively. Otherwise, when creating a FlutterEntry later, FlutterManager will not be able to obtain the correct host information, which may cause engine creation failure or rendering anomalies.

---

### Step 2: Extend FlutterEntry and Register Plugins

`FlutterEntry` is the core entry class provided by flutter_ohos, responsible for managing the creation and initialization of the Flutter engine. Developers need to extend `FlutterEntry` and register plugins in the `configureFlutterEngine` method, similar to the role of `FlutterActivity.configureFlutterEngine` on Android.

#### Why Extend FlutterEntry

- `FlutterEntry` only creates the engine by default and does not automatically register any plugins.
- `GeneratedPluginRegistrant.registerWith()` automatically binds all plugins generated via `flutter pub get` (such as path_provider, shared_preferences, etc.) to the engine.
- Custom plugins (such as `BatteryPlugin`) need to be added manually via `this.delegate?.addPlugin()`.

#### Complete Code Example

```ts
import { FlutterEntry, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '@ohos/flutter_ohos';
import { BatteryPlugin } from './BatteryPlugin';

export default class MyFlutterEntry extends FlutterEntry {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    // Must call super to ensure the parent class initialization logic runs correctly
    super.configureFlutterEngine(flutterEngine);

    // Register all auto-generated plugins (path_provider, shared_preferences, etc.)
    // This step cannot be omitted; otherwise, Dart code calling plugins will throw an error
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    // Register custom plugins
    this.delegate?.addPlugin(new BatteryPlugin());
  }
}
```

#### Plugin Registration Notes

| Registration Method | Applicable Scenario | Description |
|----------|----------|------|
| `GeneratedPluginRegistrant.registerWith(engine)` | All pub dependency plugins | Auto-generated based on the project's `pubspec.yaml`; registers the native implementations of all standard Flutter plugins |
| `this.delegate?.addPlugin(new CustomPlugin())` | Developer-defined custom plugins | Manually register custom FlutterPlugin implementation classes |

> **Important**: `GeneratedPluginRegistrant.registerWith(flutterEngine)` cannot be omitted. If this call is skipped, all Flutter plugins imported via `pubspec.yaml` (such as url_launcher, shared_preferences, etc.) will throw a `MissingPluginException` when called from the Dart side.

---

### Step 3: Using FlutterEntry with FlutterView

In an ArkTS page, you need to create a `FlutterEntry` instance, obtain its `FlutterView`, and embed the Flutter rendering content into the native page via the `FlutterPage` component. You also need to properly manage the `FlutterEntry` lifecycle in the page's lifecycle callbacks.

#### Lifecycle Correspondence

| ArkTS Page Lifecycle | FlutterEntry Method | Purpose |
|---------------------|-------------------|------|
| `aboutToAppear` | `aboutToAppear()` | Creates and initializes the Flutter engine, obtains the FlutterView |
| `aboutToDisappear` | `aboutToDisappear()` | Destroys or recycles Flutter engine resources |
| `onPageShow` | `onPageShow()` | Restores the Flutter page's visible state, handles engine recovery logic |
| `onPageHide` | `onPageHide()` | Pauses the Flutter page, handles engine pause logic |
| `onBackPress` | Passed via `eventHub` | Passes the back event to the Flutter side, letting Flutter decide whether to pop |

#### Complete Code Example (Simple Page Navigation Scenario)

```ts
import { FlutterEntry, FlutterView } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos/src/main/ets/view/FlutterPage';
import { common } from '@kit.AbilityKit';
import { Log } from '@ohos/flutter_ohos';

@Entry
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  private flutterEntry: FlutterEntry | null = null;
  private flutterView?: FlutterView

  aboutToAppear() {
    Log.d("Flutter", "Index aboutToAppear===");

    // Create a custom FlutterEntry instance
    this.flutterEntry = new MyFlutterEntry(getContext(this))

    // Initialize the Flutter engine (create engine, register plugins, start Dart entry)
    this.flutterEntry.aboutToAppear()

    // Get the FlutterView for rendering Flutter content
    this.flutterView = this.flutterEntry.getFlutterView()
  }

  aboutToDisappear() {
    Log.d("Flutter", "Index aboutToDisappear===");

    // Destroy the Flutter engine or recycle resources
    this.flutterEntry?.aboutToDisappear()
  }

  // Navigation lifecycle corresponds to onPageShow
  onPageShow() {
    Log.d("Flutter", "Index onPageShow===");
    this.flutterEntry?.onPageShow()
  }

  // Navigation lifecycle corresponds to onPageHide
  onPageHide() {
    Log.d("Flutter", "Index onPageHide===");
    this.flutterEntry?.onPageHide()
  }

  build() {
    Stack() {
      // Use the FlutterPage component to render Flutter content
      // viewId comes from FlutterView and is the unique identifier of the Flutter rendering surface
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
  }

  onBackPress(): boolean {
    // Pass the back event to the Flutter side via eventHub
    // The Flutter side listens for this event and decides whether to execute Navigator.pop()
    // Return true to indicate the app handles the back event itself, bypassing the system default behavior
    this.context.eventHub.emit('EVENT_BACK_PRESS')
    return true
  }
}
```

#### Key Notes

1. **`FlutterPage`'s `viewId` parameter**: `viewId` is the unique identifier of the FlutterView, obtained via `this.flutterView?.getId()`. `FlutterPage` uses this ID to find the corresponding Flutter rendering surface and draws the content into the native page.

2. **Back key handling**: In hybrid development, the back key behavior is jointly determined by Flutter and native code. The back event is passed to the Flutter side via `eventHub.emit('EVENT_BACK_PRESS')`, and the Flutter side decides whether to execute `Navigator.pop()` by listening for this event. When there are no more pages to pop on the Flutter side, the native side handles the back behavior.

3. **Lifecycle must be called completely**: If `aboutToAppear` or `aboutToDisappear` is omitted, the engine may not be created properly or resources may not be released, potentially causing memory leaks or a white screen.

---

## Using FlutterEntry with Navigation

In HarmonyOS applications, using `Navigation` + `NavPathStack` for page navigation is recommended. In this scenario, `FlutterEntry` needs to be used with `NavDestination`, and a custom `NavFlutterEntry` is needed to handle the native back behavior of `SystemNavigator.pop()` on the Flutter side.

### Why NavFlutterEntry Is Needed

In a simple page navigation scenario, Flutter's `SystemNavigator.pop()` will directly exit the application. However, in a Navigation scenario, developers typically expect `SystemNavigator.pop()` to perform `NavPathStack.pop()` (i.e., navigate back to the previous native page) rather than exiting the entire application. Therefore, you need to extend `FlutterEntry` to create a `NavFlutterEntry` and override the `popSystemNavigator()` method to map Flutter's exit behavior to Navigation's back behavior.

### Complete Code Example

```ts
import { FlutterEntry, FlutterView } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos/src/main/ets/view/FlutterPage';
import { common } from '@kit.AbilityKit';
import { Log } from '@ohos/flutter_ohos';

@Builder
export function PageThreeBuilder() {
  PageThree()
}

@Component
export struct PageThree {
  private context = getContext(this) as common.UIAbilityContext
  private flutterEntry: FlutterEntry | null = null;
  private flutterView?: FlutterView
  pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      // Render Flutter content within NavDestination
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      // Initialize FlutterEntry after NavDestination is ready
      this.init(context)
    })
    .onDisAppear(() => {
      // Destroy engine resources when NavDestination disappears
      this.flutterEntry?.aboutToDisappear()
    })
    .onShown(() => {
      // Restore the Flutter page when NavDestination is visible
      this.flutterEntry?.onPageShow()
    })
    .onHidden(() => {
      // Pause the Flutter page when NavDestination is not visible
      this.flutterEntry?.onPageHide()
    })
    .onBackPressed(() => {
      // Pass the back event to the Flutter side for handling
      this.context.eventHub.emit('EVENT_BACK_PRESS')
      return true
    })
  }

  init(context: NavDestinationContext) {
    // Get the path stack from NavDestinationContext
    let pathStack = context.pathStack
    this.pathStack = pathStack;

    // Get navigation parameters from the path stack
    let array = pathStack.getParamByName('pageThree') as Array<Record<string, Object>>;
    let params: Record<string, Object> = array.length > 0 ? array[0] : {};

    // Create NavFlutterEntry, passing context, params, and pathStack
    // params is used to pass routing parameters to the Flutter side
    // pathStack is used to handle the native back behavior of SystemNavigator.pop()
    this.flutterEntry = new NavFlutterEntry(getContext(this), params, pathStack)
    this.flutterEntry.aboutToAppear()
    this.flutterView = this.flutterEntry.getFlutterView()
  }
}

class NavFlutterEntry extends FlutterEntry {
  pathStack?: NavPathStack;

  constructor(context: Context, params: Record<string, Object> = {}, pathStack?: NavPathStack) {
    // Pass params to FlutterEntry for configuring the engine's initial route and other parameters
    super(context, params)
    this.pathStack = pathStack;
  }

  popSystemNavigator(): boolean {
    // Override this method to map Flutter's SystemNavigator.pop()
    // to Navigation's pathStack.pop()
    // Return true to indicate it has been handled; no need to fall through to the system default exit behavior
    if (this.pathStack) {
      this.pathStack.pop();
      return true;
    }
    // If there is no pathStack, use the default behavior (exit the app)
    return false;
  }
}
```

### Navigation Scenario Lifecycle Correspondence

| NavDestination Lifecycle | FlutterEntry Method | Description |
|--------------------------|-------------------|------|
| `onReady` | `aboutToAppear()` | Creates the engine when NavDestination is ready; NavDestinationContext is available at this point |
| `onDisAppear` | `aboutToDisappear()` | Destroys the engine when NavDestination is removed from the navigation stack |
| `onShown` | `onPageShow()` | Restores the Flutter page when NavDestination is visible |
| `onHidden` | `onPageHide()` | Pauses the Flutter page when NavDestination is not visible |
| `onBackPressed` | `eventHub.emit('EVENT_BACK_PRESS')` | Passes the back key event to Flutter |

### Navigation Route Parameter Passing

In Navigation, parameters can be passed to the Flutter page via `NavPathStack`:

1. **Native-side parameter passing**: Pass parameters via `pathStack.pushPathByName('pageThree', params)`
2. **FlutterEntry receiving**: In the `init` method, retrieve parameters via `pathStack.getParamByName('pageThree')` and pass them to the `NavFlutterEntry` constructor
3. **Flutter-side receiving**: When the Flutter engine initializes, it can obtain the initial route path via the `route` parameter, and can also receive custom parameters passed from native via `MethodChannel`

> **Note**: In the Navigation scenario, `FlutterEntry` initialization must be performed in the `onReady` callback, not in `aboutToAppear`. This is because `NavDestinationContext` (which contains pathStack and routing parameters) is only available during `onReady`. Initializing too early will result in the inability to obtain the correct navigation context.

---

## Comparison of the Two Approaches

| Feature | Simple Page Navigation (router) | Navigation |
|------|------------------------|------------------|
| Applicable scenario | Simple page navigation, single-page Flutter embedding | Multi-page navigation, complex page flow |
| FlutterEntry initialization timing | `aboutToAppear` | `onReady` |
| Back key handling | `eventHub.emit('EVENT_BACK_PRESS')` | `eventHub.emit('EVENT_BACK_PRESS')` + `NavFlutterEntry.popSystemNavigator()` |
| SystemNavigator.pop behavior | Exits the app | `pathStack.pop()` (navigate back) |
| Route parameter passing | router params | NavPathStack params |
| Engine destruction timing | `aboutToDisappear` | `onDisAppear` |
| Recommendation | Usable for simple scenarios | Recommended (HarmonyOS officially recommends Navigation) |

---

## Precautions

1. **FlutterEntry lifecycle must be called completely**: `aboutToAppear` and `aboutToDisappear` must be called in pairs. Omitting `aboutToDisappear` will cause engine resources to not be released, resulting in memory leaks. Omitting `aboutToAppear` will cause the engine to not be created, resulting in a white screen.

2. **onPageShow / onPageHide cannot be omitted**: These two methods control the visibility state of the Flutter engine. Omitting them will cause the Flutter page to continue rendering when switching to the background or being covered, wasting performance resources.

3. **FlutterEntry initialization order**: You must call `aboutToAppear()` first, then call `getFlutterView()`. `getFlutterView()` depends on the engine being already created; calling it before the engine is initialized will return an invalid viewId.

4. **EntryAbility must implement ExclusiveAppComponent**: If `EntryAbility` does not implement this interface or does not call FlutterManager's push/pop methods in `onCreate`/`onDestroy`, the Flutter engine will not be able to obtain the correct host context when created, which may cause engine creation failure.

5. **init timing in Navigation scenario**: `FlutterEntry` must be initialized in `NavDestination.onReady`, not in the component constructor or `aboutToAppear`. `onReady` is the only time when `NavDestinationContext` is available.

6. **onBackPress must return true**: Both `onBackPress()` and `onBackPressed()` must return `true`, indicating that the app handles the back event itself. If `false` is returned, the system will execute the default back behavior (exit the page or app), skipping the Flutter side's back handling logic.

7. **Plugin registration cannot be omitted**: `GeneratedPluginRegistrant.registerWith(flutterEngine)` must be called in `configureFlutterEngine`. Omitting it will cause all Flutter plugin native implementations to be unbound, and Dart-side calls will throw `MissingPluginException`.

8. **setWindowLayoutFullScreen**: Setting fullscreen layout in `onWindowStageCreate` is a prerequisite for normal Flutter page rendering. If fullscreen is not set, the Flutter page may have layout offset or fail to cover the entire screen.

---

## FAQ

### Q1: White screen, Flutter content not displaying

**Possible causes**:
- `FlutterEntry.aboutToAppear()` not called or called in the wrong order
- `EntryAbility` does not correctly implement the `ExclusiveAppComponent` interface
- `FlutterManager.pushUIAbility()` or `pushWindowStage()` not called at the correct time
- `FlutterPage`'s `viewId` is empty or invalid

**Troubleshooting steps**:
1. Check whether `aboutToAppear()` is correctly called in the page lifecycle
2. Check whether `FlutterManager.getInstance().pushUIAbility(this)` is called in `EntryAbility.onCreate`
3. Check whether `getFlutterView()` is called after `aboutToAppear()`
4. Check the logs for engine creation failure error messages

### Q2: Flutter plugin call throws MissingPluginException

**Do not immediately assume `registerWith` was missed.** `MissingPluginException` on OHOS has 3 categories of root causes (lifecycle missing `attachToAbility`, missing `registerWith` call, plugin missing ohos platform layer); the exception log alone cannot distinguish them.

Please troubleshoot following the "root cause decision tree" in [Flutter Plugin MissingPluginException](../faq/plugin-adaptation-faq.en.md#section592016).

> Precaution item 7 in this document (missing `GeneratedPluginRegistrant.registerWith` call) is only one category of root cause (root cause A). Do not skip troubleshooting root cause C (lifecycle).

### Q3: SystemNavigator.pop() exits the entire app instead of navigating back in the Navigation scenario

**Possible cause**: Using a regular `FlutterEntry` instead of `NavFlutterEntry`, or `NavFlutterEntry.popSystemNavigator()` is not correctly implemented.

**Solution**: Extend `FlutterEntry` to create a `NavFlutterEntry`, override the `popSystemNavigator()` method, call `pathStack.pop()` in the method, and return `true`.

### Q4: Flutter content not updating or stuck after page switching

**Possible cause**: `onPageShow` / `onPageHide` not correctly called, causing the engine to not restore the visible state.

**Solution**: Ensure `flutterEntry?.onPageShow()` and `flutterEntry?.onPageHide()` are called when the page's visibility changes.

---

## Demo Reference

For the complete demo, refer to [flutter_page_sample2](../../../ohos/flutter_page_sample2/).

| Demo | Description | Key File Location |
|------|------|-------------|
| flutter_page_sample2 | Complete example of both simple page navigation and Navigation approaches | `pages/Index.ets`, `pages/PageThree.ets` |
