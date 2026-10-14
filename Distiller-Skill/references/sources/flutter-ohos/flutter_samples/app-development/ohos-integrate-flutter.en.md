# Integrating Flutter into OpenHarmony Apps

This document describes how to integrate a Flutter module into an OpenHarmony native app using the **Add-to-App** approach: create a Flutter module, configure project dependencies via either HAR artifact dependencies or source code dependencies, and load and display a Flutter page in an ArkUI page. It applies to scenarios where the OpenHarmony native app is primary and only some pages use Flutter.

---

## Prerequisites

- Complete the [Flutter OH Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md)
- An OpenHarmony native project has been created (or create one following the steps below)

---

## Creating an OpenHarmony App Project

### Step 1: Create the Project

Open DevEco Studio and select `File → New → Create Project` to create a project.

### Step 2: Review the Project Directory Structure

After the project is created, the following files are related to Flutter integration:

```text
Project/
├── oh-package.json5                    # Project dependency configuration
└── entry/                              # Main module directory
    ├── oh-package.json5               # Main module dependency configuration
    └── src/main/
        ├── ets/
        │   ├── entryability/
        │   │   └── EntryAbility.ets   # Main module Ability
        │   └── pages/
        │       └── Index.ets          # Page code
        └── resources/base/profile/
            └── main_pages.json         # Page routing configuration
```

---

## Integrating the Flutter Module

There are two ways to integrate a Flutter module into the host project; choose one based on your scenario:

| Approach | Description | Use Case |
|------|------|---------|
| HAR artifact dependency | References the HAR packages built by `flutter build har` | Stable releases, CI builds, infrequent changes to the Flutter module |
| Source code dependency | Dynamically injects the module and plugin source code for compilation via a hvigor plugin | Development and joint debugging; source changes take effect immediately, without repeatedly building and copying HARs |

Choose only one of the two approaches at the "integration" stage; the subsequent "load and display the Flutter page" steps are identical. The sections below first cover the shared creation step, then describe the dependency configuration for each approach.

### Step 1: Create the Flutter Module

Execute in the project root directory:

```bash
flutter create -t module flutter_module
```

After execution completes, the `flutter_module` module is generated in the project root directory.

> [!NOTE]
>
> If you choose the source code dependency approach, after creating the module you also need to run `flutter pub get` in the `flutter_module` directory to generate the `.ohos` injection artifacts (including the hvigor plugin entry `include_flutter`).

### Approach 1: HAR Artifact Dependency

> Applies to: stable releases, CI builds, and scenarios where the Flutter module changes infrequently.

#### Step 2: Build the Flutter Module

Navigate to the `flutter_module` directory and run the build command:

```bash
# Debug build
flutter build har --debug

# Release build
flutter build har --release
```

After the build completes, open the `flutter_module/build/ohos/har/` directory; taking the debug build as an example:

```text
debug/
├── arm64_v8a_debug.har
├── flutter_embedding_debug.har
└── flutter_module.har
```

If 3 HAR files are generated, the build succeeded. Release build artifacts are located in the `release/` subdirectory, with the `_release` filename suffix.

> [!WARNING]
>
> The generated HAR files must be copied to `Project/har/` under the project root path. If each module references its own HAR files instead of storing them in one place, they will be included redundantly during packaging, increasing the package size.

#### Step 3: Configure Project Dependencies

1. Modify the main project's `oh-package.json5`

   Open `Project/oh-package.json5` and add the following under the `overrides` node (replace the paths with the actual HAR package paths; taking the debug build as an example):

   ```json5
   "overrides": {
     "@ohos/flutter_ohos": "file:./har/flutter_embedding_debug.har",
     "flutter_native_arm64_v8a": "file:./har/arm64_v8a_debug.har",
     "@ohos/flutter_module": "file:./har/flutter_module.har"
   }
   ```

   > [!NOTE]
   >
   > For a release build, replace the `_debug` filename suffix with `_release`.

2. Modify the `entry` module's `oh-package.json5`

   Open `Project/entry/oh-package.json5` and add the following under the `dependencies` node:

   ```json5
   "dependencies": {
     "@ohos/flutter_ohos": "",
     "flutter_native_arm64_v8a": "",
     "@ohos/flutter_module": ""
   }
   ```

3. Sync dependencies

   Run `Sync Now` in DevEco Studio, or execute in the project root directory:

   ```bash
   ohpm install
   ```

   After execution completes, the `oh_modules` dependency cache directory is generated under `Project/entry`, which means the integration succeeded.

### Approach 2: Source Code Dependency

> Applies to: development and joint debugging scenarios. After modifying `flutter_module` or plugin source code, simply rerun the host project for the changes to take effect — no repeated HAR building and copying required.

The source code dependency uses the hvigor plugins `flutterHvigorPlugin` and `injectNativeModules` to dynamically inject the `.ohos` source modules of `flutter_module` and the `ohos/` source modules of each plugin into the host project's hvigor nodes, aligning with the `:flutter` submodule include mechanism of Android / iOS Add-to-App.

#### Step 2: Configure the hvigor Plugin to Inject Source Code

1. Create (or modify) `hvigorfile.ts` in the host project root directory to import and register `flutterHvigorPlugin`:

   ```ts
   import { appTasks } from '@ohos/hvigor-ohos-plugin';
   // Replace the path with the actual relative location of flutter_module/.ohos
   import { flutterHvigorPlugin, getFlutterProjectPath } from './flutter_module/.ohos/include_flutter';

   export default {
     system: appTasks,
     plugins: [flutterHvigorPlugin(getFlutterProjectPath(), 1)]
   }
   ```

2. Create (or modify) `hvigorconfig.ts` in the host project root directory and call `injectNativeModules` to inject the source code nodes:

   ```ts
   import { injectNativeModules, getFlutterProjectPath } from './flutter_module/.ohos/include_flutter';

   injectNativeModules(__dirname, getFlutterProjectPath(), 1)
   ```

3. Remove the Flutter-related dependencies from `dependencies` and `overrides` in the host project's `oh-package.json5` (skip if none exist).

4. Remove `flutter_module` from the modules in the host project's `build-profile.json5` (if it was ever imported as a module).

#### Step 3: Configure the entry Module Dependencies

Open `Project/entry/oh-package.json5` and add the following under the `dependencies` node:

```json5
"dependencies": {
  "@ohos/flutter_ohos": "",
  "@ohos/flutter_module": ""
}
```

> **Note**: These are the dependencies that must be added — **do not specify a version number or path; use the empty string `""` directly**. Versions and paths are resolved uniformly by the host `oh-package.json5`'s `overrides`, and plugin source code is dynamically injected at build time by `injectNativeModules`, so it does not need to be declared in `dependencies`.

---

## Loading and Displaying a Flutter Page

After the Flutter module is integrated, you can load and display a Flutter page in an ArkUI page. The following steps wire up the Ability lifecycle, engine configuration, page creation, and route navigation.

### Step 1: Integrate the Ability Lifecycle

Call `FlutterManager` in `EntryAbility` to complete registration and unregistration, and implement the `ExclusiveAppComponent` interface so plugins can obtain the host context:

```ts
// EntryAbility.ets
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ExclusiveAppComponent, FlutterManager } from '@ohos/flutter_ohos';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {
  detachFromFlutterEngine(): void {
  }

  getAppComponent(): UIAbility {
    return this;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onDestroy(): void {
    FlutterManager.getInstance().popUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindowSync().setWindowLayoutFullScreen(true);
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    windowStage.loadContent('pages/Index');
  }

  onWindowStageDestroy(): void {
    FlutterManager.getInstance().popWindowStage(this);
  }
}
```

> **Note**: `pushUIAbility` / `popUIAbility` and `pushWindowStage` / `popWindowStage` must be called in pairs; omitting a `pop` causes abnormal `viewId` binding on subsequent pages.

### Step 2: Implement the FlutterEntry Class

Create `MyFlutterEntry` extending `FlutterEntry` and override `configureFlutterEngine` to complete plugin registration:

```ts
// MyFlutterEntry.ets
import { FlutterEngine, FlutterEntry } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class MyFlutterEntry extends FlutterEntry {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    // To register custom plugins, call this.delegate?.addPlugin(new CustomPlugin()); here
  }
}
```

### Step 3: Create the Flutter Page

Create a new `FlutterIndex.ets` page, call the `FlutterEntry` methods with the same names in the ArkUI component lifecycle, and bind the `viewId` through the `FlutterPage` component:

```ts
// pages/FlutterIndex.ets
import { FlutterPage, FlutterView } from '@ohos/flutter_ohos';
import MyFlutterEntry from '../entry/MyFlutterEntry';

@Entry
@Component
struct FlutterIndex {
  private flutterEntry: MyFlutterEntry | null = null;
  private flutterView?: FlutterView;

  aboutToAppear(): void {
    this.flutterEntry = new MyFlutterEntry(getContext(this));
    this.flutterEntry.aboutToAppear();
    this.flutterView = this.flutterEntry.getFlutterView();
  }

  onPageShow(): void {
    this.flutterEntry?.onPageShow();
  }

  onPageHide(): void {
    this.flutterEntry?.onPageHide();
  }

  aboutToDisappear(): void {
    this.flutterEntry?.aboutToDisappear();
    this.flutterEntry = null;
    this.flutterView = undefined;
  }

  onBackPress(): boolean {
    this.flutterEntry?.onBackPress();
    return true;
  }

  build() {
    Stack() {
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
    .width('100%')
    .height('100%')
  }
}
```

### Step 4: Register the Page Route

Open `entry/src/main/resources/base/profile/main_pages.json` and register the new `FlutterIndex` page:

```json
{
  "src": [
    "pages/Index",
    "pages/FlutterIndex"
  ]
}
```

### Step 5: Navigate to the Page

In the native page (for example, `Index.ets`), add a button that navigates to the Flutter page via routing:

```ts
// pages/Index.ets
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Button('Open Flutter Page')
        .onClick(() => {
          router.push({ url: 'pages/FlutterIndex' });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

After the project runs, the native home page is displayed; tap the "Open Flutter Page" button to navigate to the Flutter page.

---

## FAQ

### Issue: After integrating flutter_module, the oh_modules cache directory is not generated under entry

You need to run `ohpm install` in the project root directory, not in the `entry` directory.

### Issue: Changes to flutter_module code do not take effect

With the **HAR artifact dependency** approach, after modifying the `flutter_module` business code, you need to rerun `flutter build har --debug` (or `--release`) in the `flutter_module` directory to update the HAR packages. If the HAR packages are stored separately in the `har/` directory at the project root path, you also need to copy the newly generated HAR files to that directory to replace the old ones, and run `Sync Now` or `ohpm install` in DevEco Studio to refresh the dependencies.

If you frequently modify the Flutter module or plugin source code, consider switching to the [source code dependency approach](#approach-2-source-code-dependency); after each change, simply rerun the host project for it to take effect, avoiding the cost of repeatedly building and copying HARs.

### Issue: Multi-module project package size is too large

Place the HAR files built from multiple `module`s uniformly in the `har/` directory at the project root path and reference them uniformly via `overrides`, to avoid each module importing them separately and causing redundant packaging.
