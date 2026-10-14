# Flutter OH Hot Reload Guide

Hot reload allows modified Dart code to be injected into the running Dart VM while the app is running, so you can quickly preview the effect of code changes without recompiling the HAP or restarting the app. Flutter OH inherits the upstream Flutter hot reload mechanism, which is triggered after connecting to a device with `flutter run` in Debug mode.

Hot reload preserves the current app state and route stack, making it suitable for iteration scenarios such as Widget style adjustments and logic branch changes. Use hot restart when state resets or native code changes are involved.

## Core Concepts

| Term | Description |
| ---- | ---- |
| Hot Reload | Incrementally compiles the modified Dart source into a kernel file and injects it into the running Dart VM, preserving the app state and route stack |
| Hot Restart | Restarts the Dart VM and re-runs the `main()` entry point, resetting the app state without reinstalling the HAP |
| Cold Restart | Rebuilds and installs the HAP and launches the app; applicable when native code or resources have changed |

> [!NOTE]
>
> Hot reload and hot restart are available only in Debug mode. Release / Profile mode uses AOT compilation and does not support hot reload.

## Prerequisites

- You have completed the [Flutter OH environment setup guide](../getting-started/flutter-oh-env-setup.en.md).
- An OpenHarmony physical device is connected, or an emulator is running.

The hot reload workflow differs depending on the project type:

- **Standalone Flutter app**: A regular Flutter project created with `flutter create --platforms ohos`. Launch it directly with `flutter run` and trigger hot reload from the interactive terminal. See [Scenario 1: Standalone Flutter App](#scenario-1-standalone-flutter-app).
- **flutter_module hybrid development app**: The `flutter_module` is embedded in an OpenHarmony project as a submodule. Trigger hot reload by connecting to the running OpenHarmony app with `flutter attach`. Both source-code dependency and HAR dependency integration are supported. See [Scenario 2: flutter_module Hybrid Development App](#scenario-2-flutter_module-hybrid-development-app).

## Scenario 1: Standalone Flutter App

This applies to standalone Flutter projects created with `flutter create --platforms ohos`. Use `flutter run` to compile, install, and launch the app; hot reload is triggered from the `flutter run` interactive terminal.

### Step 1: Launch the App in Debug Mode

Go to the project root directory and run `flutter run` to compile, install, and launch the app in Debug mode:

```bash
# Launch in Debug mode (debug is the default, so --debug can be omitted)
flutter run --debug -d <deviceId>
```

> **Note**: `<deviceId>` is the device ID, which you can obtain with `flutter devices` or `hdc list targets`.

Once the app has launched, the terminal enters interactive mode and prints output similar to the following:

```log
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

### Step 2: Modify the Dart Code

Modify the Dart source code in your editor. The following example changes the page title text in `lib/main.dart`:

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('当前点击次数:$_counter'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Change `Text('当前点击次数:$_counter')` to any new text and save the file.

### Step 3: Trigger Hot Reload

Press `r` in the `flutter run` interactive terminal to trigger hot reload. The terminal prints output similar to the following:

```log
Hot reload performed in 1,234ms.
```

The device screen refreshes immediately, the modified Dart code takes effect, and the app's page state and route stack remain unchanged.

### Step 4: Trigger a Hot Restart (As Needed)

When your changes involve any of the following, hot reload cannot fully take effect. Press `R` to trigger a hot restart:

- The `main()` entry point logic has changed
- Global variable initial values or singleton construction logic has changed
- State initialization in lifecycle callbacks such as `initState` / `dispose` has changed
- The code logic depends on the app startup state, and behavior is unexpected after hot reload

A hot restart resets the app state but does not require reinstalling the HAP, so it is significantly faster than a cold restart.

## Scenario 2: flutter_module Hybrid Development App

In an Add-to-App hybrid development scenario, the `flutter_module` runs as a submodule embedded in an OpenHarmony project. The OpenHarmony app is launched separately by DevEco Studio or `hvigorw`, unlike the `flutter run` launch flow of a standalone Flutter app, so you need to connect to the running OpenHarmony app with `flutter attach` to trigger hot reload. Both integration methods — source-code dependency and HAR dependency — are supported, and the workflow is the same.

### Hot Reload via flutter attach

With a source-code dependency, the hvigor plugin `injectNativeModules` injects the `flutter_module` and each plugin's source code into the OpenHarmony project for compilation. With a HAR dependency, the OpenHarmony project references prebuilt HAR artifacts. In both cases, the Debug app starts the Dart VM Service along with the OpenHarmony app process, which `flutter attach` can discover and connect to, enabling hot reload.

#### Step 1: Launch the OpenHarmony App

In DevEco Studio, click ![run](../media/icons/run-icon.svg) to run the OpenHarmony project, or build and install from the OpenHarmony project root directory:

```bash
# Build the HAP package
hvigorw assembleHap --no-daemon -p product=default -p buildMode=debug

# Install to the device
hdc install build/default/outputs/default/entry-default-signed.hap

# Launch the app (replace with your bundle name and ability name)
hdc shell aa start -a EntryAbility -b com.example.demo
```

After the app launches, the Flutter page displays normally and the Dart VM has started along with the OpenHarmony app process, so it can now be connected by `flutter attach`.

#### Step 2: Attach to the Running Dart VM

Go to the `flutter_module` project directory and run `flutter attach` to connect to the Dart VM running on the device:

```bash
cd my_flutter_module
# -d specifies the device ID, which you can obtain with flutter devices
flutter attach -d <deviceId>
```

Once connected, the terminal enters interactive mode and prints the same hot reload prompts as `flutter run`:

```log
Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
c Clear the screen
q Quit (terminate the application on the device).
```

#### Step 3: Modify the Dart Code and Trigger Hot Reload

Modify and save the Dart source code under `flutter_module/lib/`, then press `r` in the `flutter attach` interactive terminal to trigger hot reload. The device screen refreshes immediately while the app state and route stack remain unchanged. Hot restart (`R`) also works in this scenario.

The scope and limitations of hot reload are the same as for a standalone Flutter app; see [Hot Reload Support Scope](#hot-reload-support-scope). Changes to ArkTS / Native code in the OpenHarmony project do not support hot reload — rebuild and rerun the OpenHarmony app instead.

> [!WARNING]
>
> `flutter attach` only connects to an already-running Dart VM; it does not rebuild or install the OpenHarmony HAP. If you modify `pubspec.yaml` dependencies or native code, press `q` to quit attach, rebuild the OpenHarmony app, and then attach again.

### Running flutter_module Standalone (Optional)

Besides connecting to the OpenHarmony app with `flutter attach`, you can also launch the `flutter_module` directly as a standalone Flutter project; the hot reload workflow is identical to that of a standalone Flutter app. This approach suits independent development and debugging of the `flutter_module`'s own Dart code, without launching the OpenHarmony app.

The `flutter_module` is itself a runnable Flutter project with its own `lib/main.dart` entry point. Run `flutter run` in the `flutter_module` directory to install and launch it as a standalone app on the device:

```bash
cd flutter_module
# Launch the module standalone in Debug mode; the hot reload interaction is identical to a standalone Flutter app
flutter run --debug -d <deviceId>
```

After launch, the terminal enters interactive mode. Modify the Dart source code under `lib/` and press `r` to trigger hot reload; hot restart (`R`) also works.

> [!IMPORTANT]
>
> The standalone approach is intended for developing and debugging the `flutter_module`'s own Dart code. Because the `main.dart` entry used when running standalone may differ from the Widget actually loaded by the OpenHarmony project, native interactions on the OpenHarmony side (Platform Channel, embedding container, page navigation, etc.) must still be verified in the OpenHarmony project. After development is complete, run `flutter build har` to rebuild the HAR artifacts, update the OpenHarmony project dependency, and then perform a full regression in the OpenHarmony project.

## Using Hot Reload in an IDE

Besides the command-line interaction, Flutter OH hot reload can also be triggered from an IDE, in the same way as with a regular Flutter project.

### Using VS Code

1. Open the project directory and press `F5`, or click the start button in the Run panel, to launch the app in Debug mode.
2. Modify and save the Dart code, then press `Ctrl + Shift + F5` (`Cmd + Shift + F5` on macOS) to trigger hot reload, or click the hot reload icon in the debug toolbar.

> **Note**: The Flutter extension is required. If you use a local engine, configure the `--local-engine` parameter in the `args` of `.vscode/launch.json`. See [Debugging Dart Code](./debugging-dart-code.en.md).

**flutter_module hybrid development scenario**: The OpenHarmony app is launched by DevEco Studio, so in VS Code you need a `flutter attach` configuration to connect to the running Dart VM. Add the following to `.vscode/launch.json` in the `flutter_module` directory:

```json5
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "flutter_module (attach)",
      "request": "attach",
      "type": "dart",
      // The device ID can be obtained with flutter devices; can be omitted when only one device is connected
      "deviceId": "<deviceId>"
    }
  ]
}
```

### Using Android Studio / DevEco Studio

1. Open the project and select the connected OpenHarmony device from the device drop-down list.
2. Click the run button to launch the app.
3. Modify and save the Dart code, then click the hot reload button (lightning icon) in the toolbar to trigger hot reload.

> [!NOTE]
>
> DevEco Studio is for debugging ArkTS / Native code; hot reload of the Flutter-side Dart code relies on the Flutter plugin. Changes to ArkTS / Native code do not support hot reload and require a rebuild and rerun.

## Hot Reload Support Scope

| Change Type | Hot Reload | Hot Restart | Cold Restart |
| -------- | ------ | ------ | ------ |
| Dart Widget style / layout | Supported | Supported | Supported |
| Dart business logic / method implementations | Supported | Supported | Supported |
| Dart file addition / removal | Partially supported | Supported | Supported |
| `main()` entry point logic | Not supported | Supported | Supported |
| `pubspec.yaml` dependency changes | Not supported | Not supported | Supported |
| ArkTS / Native (C/C++) code | Not supported | Not supported | Supported |
| Resource files (images / fonts / configuration) | Not supported | Not supported | Supported |
| Rendering engine switching (Impeller / Skia) | Not supported | Not supported | Supported |

## FAQ

### Hot Reload Not Responding

**Symptom**: After pressing `r`, the terminal shows no `Hot reload performed` output and the device screen does not refresh.

**Troubleshooting steps**:

1. Confirm the app was launched in Debug mode and the `flutter run` terminal is in the interactive state (not suspended in the background).
2. Confirm the changes are to Dart source code under `lib/`, not to native code or resource files.
3. Confirm the file has been saved and the IDE shows no unsaved marker.
4. Check whether the terminal is occupied by another process, and try pressing `Enter` to resume interaction.

### UI Unchanged After Hot Reload

**Symptom**: The terminal reports a successful hot reload, but the device screen does not show the modified content.

**Troubleshooting steps**:

1. Confirm the modified Widget is on the currently visible route page, not on a page that has not been loaded.
2. Confirm the change does not involve `const` constant constructors. `const` Widgets are not rebuilt during hot reload; remove `const` or use hot restart.
3. Confirm the change does not depend on initialization logic in `initState`; such changes require a hot restart to take effect.

### Abnormal State After Hot Reload

**Symptom**: After hot reload, the app exhibits state corruption, layout anomalies, or null pointer exceptions.

**Troubleshooting steps**:

1. State preserved by hot reload may conflict with the new code logic; press `R` to trigger a hot restart.
2. If the problem persists, press `q` to quit and run `flutter run` again for a cold restart.
3. Avoid caching object references in `State` that are tightly coupled to the Widget tree structure; such references may become invalid when hot reload rebuilds the Widget tree.

### flutter attach Connection Failure in the flutter_module Scenario

**Symptom**: Running `flutter attach` reports a connection timeout or no running app found, and the terminal shows no hot reload interactive prompts.

**Troubleshooting steps**:

1. Confirm the OpenHarmony app has been launched in Debug mode and is running normally on the device, with the Flutter page visible. Release / Profile artifacts do not include the Dart VM Service and cannot be attached to.
2. Confirm `flutter attach` was run in the `flutter_module` project directory, not in the OpenHarmony project directory.
3. Confirm the device is recognized by `hdc list targets` and appears as an `ohos-arm64` device in the `flutter devices` list.
4. With a source-code dependency, confirm `flutter pub get` has been run in the `flutter_module` directory and the injected `.ohos` artifacts are up to date.
5. If multiple devices are connected, explicitly specify the target device with `flutter attach -d <deviceId>`.
