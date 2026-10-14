# Building Flutter Projects with the Hvigor Plugin

- The previous approach of directly modifying project configuration files (app.json5, build-profile.json5, oh-package.json5, etc.) has been optimized to dynamically update the configuration through a Hvigor plugin, avoiding potential commit conflicts caused by frequently changed configuration files.
- Builds depend directly on the plugin source code, so when writing the plugin you can modify the source code directly with code completion — an experience consistent with Android and iOS.

## Prerequisites

- Complete the [Flutter OH Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md)
- An existing Flutter app / module / plugin project that compiles and runs correctly
- DevEco Studio and Command Line Tools installed locally

Notes on using the hvigor plugin approach to build Flutter projects:

1. Build artifacts such as APP, HAP, and HAR are all located in the Flutter project's `build/ohos` directory
2. Existing projects need manual adjustments (run `flutter pub get` after the adjustments)

## For Flutter App Projects

### Step 1: Configure ohos/.gitignore

- Add `/package.json` and `/package-lock.json`
- Remove `*.har`
- The auto-generated `har` folder in the project can be deleted as well

### Step 2: Configure ohos/oh-package.json5

- Remove `@ohos/flutter_ohos` from dependencies
- Remove `@ohos/flutter_ohos` and the Flutter plugins from overrides

### Step 3: Configure ohos/hvigorfile.ts

Add the hvigor plugin `flutterHvigorPlugin`:

```ts
import path from 'path'
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { flutterHvigorPlugin } from 'flutter-hvigor-plugin';

export default {
    system: appTasks,
    plugins:[flutterHvigorPlugin(path.dirname(__dirname))]
}
```

### Step 4: Add ohos/hvigorconfig.ts

```ts
import path from 'path'
import { injectNativeModules } from 'flutter-hvigor-plugin';

injectNativeModules(__dirname, path.dirname(__dirname))
```

### Step 5: Modify ohos/entry/hvigorfile.ts

```ts
import { hapTasks } from '@ohos/hvigor-ohos-plugin';
export default {
    system: hapTasks,
    plugins: []
}
```

### Step 6: Configure ohos/entry/oh-package.json5

Remove `@ohos/flutter_ohos` and the Flutter plugins from dependencies.

## For Flutter Module Projects

### Based on HAR Artifacts

1. In the host project's `oh-package.json5`, remove the Flutter-related dependencies from `dependencies` and `overrides` (skip if not present)
2. In the host project's `oh-package.json5`, add all Flutter-built HARs under `overrides` (adjust to the actual paths)

```json5
  "overrides": {
    "@ohos/flutter_ohos": "file:./path/flutter_project/build/ohos/har/release/flutter.har",
    "@ohos/flutter_module": "file:./path/flutter_project/build/ohos/har/release/flutter_module.har",
    "plugin_x": "file:./path/flutter_project/build/ohos/har/release/plugin_x.har",
  }
```

The approach above is inconvenient when the project has many plugins that change frequently. You can add the following code to the host project's `hvigorfile.ts` to dynamically add dependencies:

```ts
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import fs from 'fs'
import path from 'path'
import { OhosPluginId } from '@ohos/hvigor-ohos-plugin';
import { getNode, hvigor } from '@ohos/hvigor'

const directory = 'adjust-to-actual-path'
const keyMap = {
  "flutter": "@ohos/flutter_ohos",
  "flutter_embedding_debug": "@ohos/flutter_ohos",
  "flutter_embedding_profile": "@ohos/flutter_ohos",
  "flutter_embedding_release": "@ohos/flutter_ohos",
  "arm64_v8a_debug": "flutter_native_arm64_v8a",
  "arm64_v8a_profile": "flutter_native_arm64_v8a",
  "arm64_v8a_release": "flutter_native_arm64_v8a",
  "x86_64_debug": "flutter_native_x86_64",
  "x86_64_profile": "flutter_native_x86_64",
  "x86_64_release": "flutter_native_x86_64",
  "flutter_module": "@ohos/flutter_module"
}
const rootNode: HvigorNode = getNode(__filename)
rootNode.afterNodeEvaluate(node => {
  const appContext = node.getContext(OhosPluginId.OHOS_APP_PLUGIN) as OhosAppContext
  if (!appContext) {
    return
  }
  const overrides = appContext.getOverrides() ?? {}
  const dependencies = appContext.getDependenciesOpt() ?? {}
  const files = fs.readdirSync(directory);
  const keys = Object.keys(keyMap)
  for (const file of files) {
    if (path.extname(file).toLowerCase() !== '.har') {
      continue
    }
    const fileName = path.parse(file).name
    const depName = keys.includes(fileName) ? keyMap[fileName] : fileName
    const filePath = `file:${path.join(directory, file)}`
    dependencies[depName] = filePath
    overrides[depName] = filePath
  }
  appContext.setDependenciesOpt(dependencies)
  appContext.setOverrides(overrides)
})

export default {
  system: appTasks,
  plugins: []
}
```

3. In the `oh-package.json5` of `entry` (or another hap module), add the dependencies under `dependencies`:

```json5
  "dependencies": {
    "@ohos/flutter_ohos": "",
    "@ohos/flutter_module": ""
  }
```

> **Note**: These are the dependencies that must be added — **do not specify a version number or path; use the empty string `""` directly**. Versions and paths are resolved uniformly by the host `oh-package.json5`'s `overrides`. If this module directly calls a Flutter plugin's API (indirect dependencies do not need to be added), append that plugin's dependency as well, for example `"plugin_x": ""`.

### Based on Source Code

1. `hvigorconfig.ts` in the host project (create it if it does not exist)

```ts
// This file is located under the .ohos directory of the flutter module project; adjust to the actual path
import { injectNativeModules, getFlutterProjectPath } from './path/flutter_project/.ohos/include_flutter';

injectNativeModules(__dirname, getFlutterProjectPath(), 1)
```

2. In the host project's `hvigorfile.ts`, add the `flutterHvigorPlugin` plugin

```ts
import { appTasks } from '@ohos/hvigor-ohos-plugin';
// This file is located under the .ohos directory of the flutter module project; adjust to the actual path
import { flutterHvigorPlugin, getFlutterProjectPath } from './path/flutter_project/.ohos/include_flutter';

export default {
  system: appTasks,
  plugins:[flutterHvigorPlugin(getFlutterProjectPath(), 1)]
}
```

3. In the host project's `build-profile.json5`, remove `flutter_module`
4. In the host project's `oh-package.json5`, remove the Flutter-related dependencies from `dependencies` and `overrides` (skip if not present)

5. In the `oh-package.json5` of `entry` (or another hap module), add the dependencies under `dependencies`:

```json5
  "dependencies": {
    "@ohos/flutter_ohos": "",
    "@ohos/flutter_module": ""
  }
```

> **Note**: These are the dependencies that must be added — **do not specify a version number or path; use the empty string `""` directly**. Plugin source code is dynamically injected at build time by `injectNativeModules`, so it does not need to be declared in `dependencies`. If this module directly calls a Flutter plugin's API (indirect dependencies do not need to be added), append that plugin's dependency as well, for example `"plugin_x": ""`.

### Build and Verify

After completing the configuration above, build in the host project and verify that the source code dependency takes effect.

1. **Sync dependencies**: Run `Sync Now` in DevEco Studio, or run `ohpm install` in the host project root directory.
2. **Build and run**: Open the host project in DevEco Studio, configure signing, and click the Run button to install it directly to the device; or run in the host project directory:

   ```bash
   hvigorw assembleHap --no-daemon -p product=default -p buildMode=debug
   ```

   For artifact paths for building and installing, and `hdc install` usage, see the [OpenHarmony Device Running Guide](../getting-started/openharmony-device-guide.en.md).
3. **Verify it takes effect**: If the app launches and enters the Flutter page normally, the source code dependency is configured successfully.
4. **Rebuilding after source changes**:

   - After modifying Dart business code in `flutter_module`, run `flutter pub get` in the `flutter_module` directory to refresh the `.ohos` injection artifacts, then rerun the host project.
   - After modifying ArkTS source code in a plugin's `ohos/` directory, since the host depends directly on the source code, simply rerun the host project for the change to take effect — no separate HAR build is needed.

> [!NOTE]
>
> With the source code dependency, `injectNativeModules` dynamically injects the `.ohos` source modules of `flutter_module` and the `ohos/` source modules of each plugin into the host's hvigor nodes, aligning with the `:flutter` submodule include mechanism of Android / iOS Add-to-App; source changes take effect immediately, avoiding the cost of repeatedly building and copying HARs.

## For Flutter Plugin Projects

Note: For an existing Flutter plugin project, making no changes only causes the example to fail to compile; it does not affect the plugin's normal use and compilation in Flutter projects.

### Optional Changes

1. Change the plugin project's `hvigorfile.ts` to:

```ts
import { harTasks } from '@ohos/hvigor-ohos-plugin';
export default {
    system: harTasks,
    plugins: []
}
```

2. In the plugin project's `oh-package.json5`, remove `@ohos/flutter_ohos` from dependencies.

### Required Changes

For adjusting the plugin's example, refer to the Flutter app project section above.
