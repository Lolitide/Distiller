# How to Use PlatformView

This topic describes how to use PlatformView in a Flutter OH app to embed ArkUI native components that support [same-layer rendering](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-same-layer#%E4%B8%89%E6%96%B9ui%E6%A1%86%E6%9E%B6) into a Flutter page, and how to implement two-way communication between Flutter and the native side through MethodChannel.

---

## Core Concepts

| Term | Description |
|------|------|
| `PlatformView` | Base class provided by flutter_ohos. Developers extend it to implement custom native views and return the `WrappedBuilder` of an ArkUI component in `getView()` |
| `PlatformViewFactory` | Factory class responsible for creating `PlatformView` instances based on the `viewId` and parameters |
| `FlutterPlugin` | Plugin interface. In `onAttachedToEngine`, registers a `PlatformViewFactory` through `getPlatformViewRegistry().registerViewFactory()` |
| `OhosView` | Widget on the Dart side. It associates the PlatformView registered on the native side through `viewType` to embed native components into a Flutter page |
| `MethodChannel` | Two-way communication channel between Flutter and the native side, used to deliver method calls and data |

### Data Flow

The creation and communication flow of PlatformView is as follows:

```mermaid
sequenceDiagram
    participant Dart as Flutter (Dart)
    participant Embed as OHOS Embedding Layer
    participant Plugin as Native Plugin (Factory + PlatformView)
    Note over Embed,Plugin: Prerequisite: onAttachedToEngine calls registerViewFactory(viewType, Factory) to complete registration
    Dart->>Embed: OhosView(viewType, creationParams, creationParamsCodec)
    Embed->>Plugin: Find the Factory by viewType and call create(context, viewId, args)
    Note over Embed: args is creationParams decoded by the Factory codec
    Plugin->>Plugin: new PlatformView(): construct a MethodChannel (name contains viewId) + setMethodCallHandler
    Plugin-->>Embed: Return the PlatformView instance
    Embed->>Plugin: platformView.getView()
    Plugin-->>Embed: Return WrappedBuilder
    Embed->>Embed: Bind the ArkUI component to the viewId view slot for rendering
    Embed-->>Dart: onPlatformViewCreated(viewId) callback
    Dart->>Dart: Create a MethodChannel with the same name (name contains viewId) + setMethodCallHandler
    Note over Dart,Plugin: Creation complete; MethodChannels with the same name on both sides are ready
    Dart->>Plugin: invokeMethod(method, args) to call the native side
    Plugin-->>Dart: Handled in onMethodCall; result.success returns
    Plugin->>Dart: invokeMethod(method, args) proactive push
    Dart-->>Plugin: Received by the setMethodCallHandler callback
```

- **View creation**: At engine startup, `FlutterPlugin.onAttachedToEngine` first calls `registerViewFactory(viewType, PlatformViewFactory)` to complete registration. After the Dart side declares an `OhosView`, the OHOS embedding layer finds the factory by `viewType` and calls `create(context, viewId, args)` (`args` is `creationParams` decoded by the factory codec) to obtain the `PlatformView` instance, whose constructor creates a `MethodChannel` with a name containing the `viewId` suffix and calls `setMethodCallHandler`. The embedding layer then calls `getView()` to retrieve the `WrappedBuilder` and binds the corresponding ArkUI component to the `viewId` view slot for rendering. When this completes, `onPlatformViewCreated(viewId)` is called back on the Dart side, where Dart creates a `MethodChannel` with the same name. Once the channel names on both sides match, communication is ready.
- **Dart calling the native side**: The Dart side initiates method calls through `MethodChannel.invokeMethod()`; the native side receives and handles them in `onMethodCall` and returns results through `result.success()`.
- **Native side calling Dart**: The native side proactively pushes messages through `methodChannel.invokeMethod()`, and the Dart side receives them through the `setMethodCallHandler` callback.

---

## Prerequisites

- [Flutter OH Development Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md) has been completed.
- A Flutter OH app has been created; in this example it is named `platform_demo`.
- The `platform_demo/ohos` project has been opened in DevEco Studio.

---

## Implementation Steps

### Step 1: Implement a Custom PlatformView (Native Side)

Create `CustomView.ets` in the `ohos/entry/src/main/ets/entryability/` directory. It consists of three parts: the ArkUI component, the Builder function, and the PlatformView implementation class.

```ts
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import common from '@ohos.app.ability.common';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';

@Component
struct ButtonComponent {
  @ObjectLink params: Params
  customView: CustomView = this.params.platformView as CustomView
  @StorageLink('numValue') numValue: string = ""

  build() {
    Column() {
      Button("Send data to Flutter")
        .onClick(() => this.customView.sendMessage())
      Text(`Data from Flutter: ${this.numValue}`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Builder
function ButtonBuilder(params: Params) {
  ButtonComponent({ params: params })
}

AppStorage.setOrCreate('numValue', '')

@Observed
export class CustomView extends PlatformView implements MethodCallHandler {
  methodChannel: MethodChannel;
  index: number = 0;

  constructor(context: common.Context, viewId: number, args: ESObject, message: BinaryMessenger) {
    super();
    // Register the message channel; the channel name must match the Dart side (including the viewId suffix)
    this.methodChannel = new MethodChannel(message, `com.rex.custom.ohos/customView${viewId}`, StandardMethodCodec.INSTANCE);
    this.methodChannel.setMethodCallHandler(this);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    // Receive messages sent from the Dart side
    if (call.method === 'getMessageFromFlutterView') {
      AppStorage.setOrCreate('numValue', call.args as string);
      result.success(true);
    }
  }

  public sendMessage = () => {
    // Send a message to the Dart side
    this.methodChannel.invokeMethod('getMessageFromOhosView', 'native - ' + this.index++);
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(ButtonBuilder);
  }

  dispose(): void {}
}
```

The role of each part is as follows:

| Part | Role |
|----------|------|
| `ButtonComponent` | ArkUI component that defines the UI layout and interactions of the native view. It obtains the PlatformView instance through `@ObjectLink params` and shares data with the native side through `@StorageLink('numValue')` |
| `ButtonBuilder` | `@Builder` function that wraps `ButtonComponent` into the builder required by `WrappedBuilder` |
| `CustomView` | Extends `PlatformView` and implements `getView()` to return `WrappedBuilder(ButtonBuilder)`; implements `MethodCallHandler` to handle messages from the Dart side |
| `AppStorage.setOrCreate` | Initializes the shared storage key `numValue`; `ButtonComponent` listens for its changes through `@StorageLink` to update the UI |

### Step 2: Implement PlatformViewFactory (Native Side)

Create `CustomFactory.ets` in the same directory, and instantiate `CustomView` in the `create` method.

```ts
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import PlatformViewFactory from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformViewFactory';
import { CustomView } from './CustomView';
import common from '@ohos.app.ability.common';
import PlatformView from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';

export class CustomFactory extends PlatformViewFactory {
  message: BinaryMessenger;

  constructor(message: BinaryMessenger, createArgsCodes: MessageCodec<Object>) {
    super(createArgsCodes);
    this.message = message;
  }

  public create(context: common.Context, viewId: number, args: Object): PlatformView {
    return new CustomView(context, viewId, args, this.message);
  }
}
```

### Step 3: Implement a FlutterPlugin to Register PlatformViewFactory (Native Side)

Create `CustomPlugin.ets`, implement the `FlutterPlugin` interface, and register `CustomFactory` in `onAttachedToEngine`.

```ts
import  { FlutterPlugin,
  FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import { CustomFactory } from './CustomFactory';

export class CustomPlugin implements FlutterPlugin {
  getUniqueClassName(): string {
    return 'CustomPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    binding.getPlatformViewRegistry()?.
    registerViewFactory('com.rex.custom.ohos/customView', new CustomFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE));
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {}
}
```

### Step 4: Register the Plugin in EntryAbility (Native Side)

Modify `EntryAbility.ets` to extend `FlutterAbility`, and register `GeneratedPluginRegistrant` and the custom `CustomPlugin` in `configureFlutterEngine`.

```ts
import { FlutterAbility } from '@ohos/flutter_ohos'
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import FlutterEngine from '@ohos/flutter_ohos/src/main/ets/embedding/engine/FlutterEngine';
import { CustomPlugin } from './CustomPlugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    this.addPlugin(new CustomPlugin());
  }
}
```

### Step 5: Create the OhosView Wrapper and Controller (Dart Side)

Create `custom_ohos_view.dart` in the `lib/` directory, which contains the `CustomOhosView` widget and `CustomViewController`.

`OhosView` is the key component for bridging a PlatformView. Its core parameters are as follows:

- **`viewType`**: Passed to the native side to identify the PlatformView to be created. It must be the same as the `viewType` registered by `registerViewFactory`.
- **`onPlatformViewCreated`**: Callback invoked when the PlatformView is created successfully. It returns the `viewId`, which is used to establish the `MethodChannel`.
- **`creationParams`**: Initialization parameters passed to the PlatformView. They are passed to the native side after being encoded by `creationParamsCodec`.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef OnViewCreated = Function(CustomViewController);

/// Custom OhosView
class CustomOhosView extends StatefulWidget {
  final OnViewCreated onViewCreated;

  const CustomOhosView(this.onViewCreated, {Key? key}) : super(key: key);

  @override
  State<CustomOhosView> createState() => _CustomOhosViewState();
}

class _CustomOhosViewState extends State<CustomOhosView> {
  @override
  Widget build(BuildContext context) {
    return OhosView(
      viewType: 'com.rex.custom.ohos/customView',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: const <String, String>{'initParams': 'hello world'},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  void _onPlatformViewCreated(int id) {
    widget.onViewCreated(
      CustomViewController._(MethodChannel('com.rex.custom.ohos/customView$id')),
    );
  }
}

class CustomViewController {
  final MethodChannel _channel;
  final StreamController<String> _controller = StreamController<String>();

  CustomViewController._(this._channel) {
    _channel.setMethodCallHandler((call) async {
      // Obtain data from the native side
      if (call.method == 'getMessageFromOhosView') {
        _controller.sink.add(call.arguments as String);
      }
    });
  }

  Stream<String> get customDataStream => _controller.stream;

  // Send data to the native side
  Future<void> sendMessageToOhosView(String message) =>
      _channel.invokeMethod('getMessageFromFlutterView', message);
}
```

### Step 6: Implement the Flutter Page (Dart Side)

Modify `lib/main.dart`: embed the native `CustomOhosView` in the upper half of the screen and place a Flutter button in the lower half to implement two-way data communication.

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'custom_ohos_view.dart';

void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CustomViewController? _controller;
  String _receivedData = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomOhosView((controller) {
              _controller = controller;
              _controller?.customDataStream.listen((data) {
                // Data received from the OHOS side
                setState(() => _receivedData = 'From ohos: $data');
              });
            }),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _controller?.sendMessageToOhosView(
                    'flutter - ${Random().nextInt(10)}',
                  ),
                  child: const Text('Send data to ohos'),
                ),
                Text(_receivedData),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Building and Running

### Configuring the Signature

Open the `platform_demo/ohos` directory in DevEco Studio, choose **File → Project Structure → Project → SigningConfigs**, and select **Automatically generate signature** to complete signing.

### Building and Packaging

Run the following command in the root directory of the `platform_demo` project:

```sh
flutter build hap --debug
```

### Running

After an OHOS device is connected, run:

```sh
flutter run -d <device-id>
```

You can also run the entry module directly in DevEco Studio.

---

## FAQ

### OhosView Shows a White Screen or the Native Component Is Not Rendered

- Check that `viewType` exactly matches the one registered by `registerViewFactory` on the native side.
- Check that `registerViewFactory` is correctly called in `CustomPlugin.onAttachedToEngine`.
- Check that `this.addPlugin(new CustomPlugin())` is called in `EntryAbility.configureFlutterEngine`.
- Check that `CustomView.getView()` correctly returns `WrappedBuilder(ButtonBuilder)`.

### MethodChannel Communication Fails

- Check that the `MethodChannel` name on the Dart side is `com.rex.custom.ohos/customView$viewId` (including the `viewId` suffix) and matches the native side.
- Check that the branch method names in `onMethodCall` match the method names passed to `invokeMethod` on the Dart side.

### Plugin Invocation Reports MissingPluginException

`MissingPluginException` has multiple root causes on the OHOS platform. Troubleshoot it by following the decision tree in [Flutter Plugin Adaptation FAQ](../faq/plugin-adaptation-faq.en.md#section592016).

---

## Demo Reference

For the complete demo, see [platform_demo](../../../ohos/platform_demo/).
