# Developing a Flutter Plugin

This document describes how to develop a Flutter native plugin on the OpenHarmony platform, covering the end-to-end workflow of creating a plugin project, declaring platform support, implementing Dart and ArkTS native code, and registering, building, and running the plugin.

## Prerequisites

- The [Flutter OH development environment](../getting-started/flutter-oh-env-setup.en.md) has been set up.

## Development Steps

### Step 1: Create a Plugin Project

Use the `flutter create` command to create a plugin project that supports Android, iOS, and ohos at the same time:

```sh
flutter create --org com.example --template=plugin --platforms=android,ios,ohos hello
```

After creation, the plugin root directory structure is as follows:

```text
hello/
├── lib/                              # Dart API implementation
│   ├── hello.dart                    # Public API for application developers
│   ├── hello_method_channel.dart      # MethodChannel implementation
│   └── hello_platform_interface.dart # Platform interface abstraction (federated plugin pattern)
├── ohos/                             # ohos platform module (an HAR module, not a project)
│   ├── oh-package.json5             # Module dependency configuration
│   ├── hvigorfile.ts                # hvigor build script (harTasks)
│   ├── build-profile.json5          # Build configuration
│   ├── index.ets                    # Module export entry
│   ├── local.properties             # Auto-generated; do not edit manually or commit
│   ├── .gitignore                   # Ignore build artifacts such as build/
│   └── src/main/
│       ├── module.json5             # Module configuration (name, type=har)
│       └── ets/components/plugin/
│           └── HelloPlugin.ets       # ArkTS native plugin implementation
├── android/                          # Android platform implementation
├── ios/                              # iOS platform implementation
├── example/                          # Example app (example/ohos is a complete hvigor host project)
│   └── ohos/
│       ├── hvigorfile.ts            # appTasks + flutterHvigorPlugin
│       ├── hvigorconfig.ts          # injectNativeModules (automatically injects plugin source nodes)
│       └── entry/                    # Entry module
│           └── src/main/ets/entryability/EntryAbility.ets
├── test/                             # Dart unit tests
└── pubspec.yaml
```

### Step 2: Declare the ohos Platform in pubspec.yaml

The `flutter create --template=plugin --platforms=ohos` **template automatically generates** the `plugin.platforms` configuration, so **manual changes are usually unnecessary**:

```yaml
flutter:
  plugin:
    platforms:
      android:
        pluginClass: HelloPlugin
      ohos:
        pluginClass: HelloPlugin
      ios:
        pluginClass: HelloPlugin
```

Field description:

| Field          | Applicable Platform | Description                                                         |
| ------------- | -------- | ------------------------------------------------------------ |
| `pluginClass` | All     | The name of the native plugin implementation class, which must match the return value of `getUniqueClassName()` in ArkTS. Based on this name, the framework looks up and instantiates the plugin among the classes exported by `index.ets`. |

### Step 3: Implement the Plugin

**Step 3.1: Define the Dart API**

By default, `flutter create` adopts the **federated plugin pattern**, which separates the public API, the platform interface abstraction, and the channel implementation into three files.

`lib/hello.dart` is the public API for application developers and delegates to the platform interface:

```dart
import 'hello_platform_interface.dart';

class Hello {
  Future<String?> getPlatformVersion() {
    return HelloPlatform.instance.getPlatformVersion();
  }
}
```

`lib/hello_method_channel.dart` is the MethodChannel implementation, where the channel that communicates with the native side is created:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hello_platform_interface.dart';

/// An implementation of [HelloPlatform] that uses method channels.
class MethodChannelHello extends HelloPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('hello');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
```

> **Note:** The channel names on the Dart side and the native side (`'hello'` in the preceding example, which is the same as the plugin name by default) must be exactly the same; otherwise, calls cannot reach the native implementation. To use a custom name, change it in both places accordingly.

**Step 3.2: Implement the ohos Native Code (ArkTS)**

Implement the ohos platform native logic in `ohos/src/main/ets/components/plugin/HelloPlugin.ets`. A native plugin class must implement the `FlutterPlugin` interface and receive calls from the Dart side through a `MethodChannel`:

```ts
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';

const CHANNEL_NAME = 'hello';

export default class HelloPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  // Return the plugin class name, used for registration and deduplication
  getUniqueClassName(): string {
    return 'HelloPlugin';
  }

  // Create the channel and register the method handler when the engine is attached
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  // Release resources when the engine is detached
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
  }

  // Handle method calls from the Dart side
  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'getPlatformVersion':
        result.success('OpenHarmony');
        break;
      default:
        result.notImplemented();
        break;
    }
  }
}
```

**Key interfaces**:

| Interface / Method | Description |
| --- | --- |
| `FlutterPlugin` | The fundamental plugin interface; you must implement `onAttachedToEngine` / `onDetachedFromEngine` / `getUniqueClassName`. |
| `MethodCallHandler` | Handles `MethodChannel` method calls; implement `onMethodCall(call, result)`. |
| `StreamHandler` | Handles `EventChannel` event streams; implement `onListen` / `onCancel`, which are used to continuously push events to the Dart side. |
| `AbilityAware` | Implement this when you need to access the Ability context; obtain the Ability through `onAttachedToAbility`. |
| `binding.getApplicationContext()` | Obtains the ohos `Context` in `onAttachedToEngine`, which is used to call system capabilities (files, permissions, and so on). |

For the `MethodResult` callback, choose one of the three options: `result.success(value)` returns a successful result; `result.error(code, message, details)` returns an error; `result.notImplemented()` indicates an unimplemented method.

**Step 3.3: Export the Plugin Class (index.ets)**

The `ohos/index.ets` file of the ohos module exports the plugin class by default so that the toolchain can locate the implementation by package name:

```ts
import HelloPlugin from './src/main/ets/components/plugin/HelloPlugin';
export default HelloPlugin;
```

`"main": "index.ets"` in `ohos/oh-package.json5` points to this entry:

```json5
{
  "name": "hello",
  "version": "1.0.0",
  "description": "Please describe the basic information.",
  "main": "index.ets",
  "author": "",
  "license": "Apache-2.0",
  "dependencies": {}
}
```

### Step 4: Register and Run

**Step 4.1: Automatic Registration (Recommended)**

After the plugin is declared in the `pubspec.yaml` of the host project, the toolchain automatically generates `GeneratedPluginRegistrant.ets` when `flutter pub get` is executed. This file imports each plugin class by package name and adds the plugins to the engine's plugin list in `registerWith`:

```ts
// Generated file; do not edit manually
import { FlutterEngine } from '@ohos/flutter_ohos';
import HelloPlugin from 'hello';

export class GeneratedPluginRegistrant {
  static registerWith(flutterEngine: FlutterEngine) {
    flutterEngine.getPlugins()?.add(new HelloPlugin());
  }
}
```

The host `EntryAbility` needs to call it only once to register all declared plugins:

```ts
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
```

**Step 4.2: Manual Registration**

For a local plugin class that is defined directly in the application and not declared in `pubspec.yaml`, you can register it manually in `configureFlutterEngine`:

```ts
this.addPlugin(new HelloPlugin());
```

**Step 4.3: Build and Run**

You are advised to open the `hello/example/ohos` directory in DevEco Studio to build and run the project:

1. Configure signing: `File -> Project Structure -> Signing Configs -> Automatically generate signature`.
2. Run the project, or use the command line:

```sh
cd hello/example
flutter pub get
flutter build hap --debug        # Build only
flutter run -d <device-id>      # Build, install, and run
```

## Adding ohos Platform Support to an Existing Plugin Project

If an existing `plugin`-type plugin does not yet support ohos, run the following command in the plugin root directory to generate the scaffolding:

```sh
flutter create . --template=plugin --platforms=ohos
```

After running the command, complete the following in sequence:

1. Add the `ohos` configuration to `flutter.plugin.platforms` in `pubspec.yaml` (see Step 2).
2. Implement the native plugin code in the generated `ohos/` directory (see Step 3.2).
3. Export the plugin class through `ohos/index.ets` (see Step 3.3).
