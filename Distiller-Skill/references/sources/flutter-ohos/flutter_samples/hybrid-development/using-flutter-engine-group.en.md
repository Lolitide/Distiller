# Using the Multi-Engine FlutterEngineGroup

This document describes how to use `FlutterEngineGroup` to create multiple Flutter engine instances in an OpenHarmony app, so that multiple Flutter views can be embedded at the same time on the same page or on different pages.

Engines created by `FlutterEngineGroup` share the same Dart isolate, which is more efficient than creating multiple engines independently. It is suitable for scenarios such as split screens with two Flutter views or multiple Flutter views embedded in a list.

## Core Concepts

| Term | Description |
|------|------|
| `FlutterEngineGroup` | Engine group; creates engine instances that share an isolate through `createAndRunEngineByOptions()` |
| `EngineBindings` | Wraps the lifecycle management (attach/detach) of a single engine and its communication channel |
| `FlutterView` | Rendering view created by `FlutterManager.createFlutterView()`, one per engine |
| `DataModel` | Singleton data model that synchronizes data across engines through the observer pattern |
| `@pragma('vm:entry-point')` | Declares multiple entry functions on the Dart side, so different engines can run different entry points |

## Prerequisites

- [Flutter OH environment setup](../getting-started/flutter-oh-env-setup.en.md) has been completed.
- An OHOS project has been created.

## Implementation Steps

### 1. Native Side (ArkTS)

#### 1. EntryAbility Inherits from UIAbility

```ts
import { ExclusiveAppComponent, FlutterManager } from '@ohos/flutter_ohos';
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility>{
  detachFromFlutterEngine(): void {
  }

  getAppComponent(): UIAbility {
    return this;
  }

  static app?: EntryAbility;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FlutterManager.getInstance().pushUIAbility(this);
    EntryAbility.app = this;
  }

  onDestroy(): void | Promise<void> {
    FlutterManager.getInstance().popUIAbility(this);
    EntryAbility.app = undefined;
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindowSync().setWindowLayoutFullScreen(true);
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    windowStage.loadContent('pages/MainPage');
  }

  onWindowStageDestroy() {
    FlutterManager.getInstance().popWindowStage(this);
  }
}
```

#### 2. Creating the FlutterEngineGroup and EngineBindings

`EngineBindings` is the core wrapper class that manages the creation, attachment, detachment, and communication of a single engine. `FlutterEngineGroup` is created as a module-level singleton, and all `EngineBindings` instances share the same engine group.

```ts
import { FlutterEngine, FlutterManager, FlutterView, Log, MethodCall, MethodChannel } from '@ohos/flutter_ohos';
import { DataModel, DataModelObserver } from './DataModel';
import { common } from '@kit.AbilityKit';
import FlutterEngineGroup, { Options } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/FlutterEngineGroup';
import { MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import { DartEntrypoint } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/dart/DartExecutor';
import { GeneratedPluginRegistrant } from '@ohos/flutter_module';
import EntryAbility from '../entryability/EntryAbility';
import TextInputPlugin from '@ohos/flutter_ohos/src/main/ets/plugin/editing/TextInputPlugin';
import PlatformPlugin from '@ohos/flutter_ohos/src/main/ets/plugin/PlatformPlugin';
import UIAbility from '@ohos.app.ability.UIAbility';

const engines: FlutterEngineGroup = new FlutterEngineGroup();

export interface EngineBindingsDelegate {
  onNext(): void;
}

export class EngineBindings implements DataModelObserver {
  private engine?: FlutterEngine;
  private channel?: MethodChannel;
  private context: common.Context;
  private uiAbility: UIAbility;
  private delegate: EngineBindingsDelegate;
  private flutterView: FlutterView;
  protected textInputPlugin?: TextInputPlugin;
  protected platformPlugin?: PlatformPlugin;

  constructor(context: common.Context, delegate: EngineBindingsDelegate) {
    this.context = context;
    this.delegate = delegate;
    this.flutterView = FlutterManager.getInstance().createFlutterView(context);
    this.uiAbility = FlutterManager.getInstance().getUIAbility(context);
    // Full-screen mode, to avoid region collapse on foldable screens and in similar scenarios
    FlutterManager.getInstance().setUseFullScreen(true, this.context);
  }

  getFlutterViewId() {
    return this.flutterView.getId();
  }

  getEngine() {
    return this.engine;
  }

  async attach() {
    if (this.engine) {
      return;
    }
    DataModel.instance.addObserver(this);
    // Execute in order: 1. check the loader 2. create the engine 3. notify the lifecycle 4. attach the Ability 5. bind the View 6. register plugins
    await engines.checkLoader(this.context, []);
    let options: Options = new Options(this.context).setDartEntrypoint(DartEntrypoint.createDefault());
    this.engine = await engines.createAndRunEngineByOptions(options) ?? undefined;
    if (!this.engine) {
      throw new Error("Create engine failed.");
    }
    this.engine.getLifecycleChannel()?.appIsResumed();
    this.textInputPlugin = new TextInputPlugin(this.engine.getTextInputChannel()!, this.flutterView.getId());
    this.platformPlugin = new PlatformPlugin(this.engine.getPlatformChannel()!, this.context);
    this.platformPlugin?.setUIAbilityContext(this.uiAbility?.context);
    if (EntryAbility.app) {
      this.engine.getAbilityControlSurface()?.attachToAbility(EntryAbility.app);
    }
    this.flutterView.attachToFlutterEngine(this.engine);
    GeneratedPluginRegistrant.registerWith(this.engine);

    // Create the communication channel for interacting with the Dart side
    this.channel = new MethodChannel(this.engine.dartExecutor.getBinaryMessenger(), "multiple-flutters");
    this.channel?.invokeMethod("setCount", DataModel.instance.getCounter());
    let delegate = this.delegate;
    this.channel?.setMethodCallHandler({
      onMethodCall(call: MethodCall, result: MethodResult) {
        switch (call.method) {
          case "incrementCount":
            DataModel.instance.increase();
            result.success(null);
            break;
          case "next":
            delegate.onNext();
            result.success(null);
            break;
          default:
            result.notImplemented();
            break;
        }
      }
    })
  }

  detach() {
    if(this.flutterView.isAttachedToFlutterEngine()){
      this.flutterView.detachFromFlutterEngine();
      this.engine?.destroy();
    }
    DataModel.instance.removeObserver(this);
    this.channel?.setMethodCallHandler(null);
  }

  onCountUpdate(newCount: number): void {
    this.channel?.invokeMethod("setCount", newCount);
  }
}
```

#### 3. Sharing Data with DataModel

`DataModel` is a singleton that synchronizes data across engines through the observer pattern. Each `EngineBindings` registers as an observer; when `DataModel.increase()` is called, all observers are notified, and each observer pushes the new value to the Dart side over a `MethodChannel`.

```ts
import { ArrayList } from '@kit.ArkTS';
import { Log } from '@ohos/flutter_ohos';

export interface DataModelObserver {
  onCountUpdate(newCount: number): void;
}

export class DataModel {
  public static instance = new DataModel();
  private counter = 0;
  private observers: ArrayList<DataModelObserver> = new ArrayList();

  private constructor() {
  }

  public increase() {
    this.setCounter(++this.counter);
  }

  public setCounter(newCounter: number): void {
    this.observers.forEach(observer => {
      observer?.onCountUpdate(this.counter);
    });
    this.counter = newCounter;
  }

  public getCounter(): number {
    return this.counter;
  }

  addObserver(observer: DataModelObserver): void {
    this.observers.add(observer);
  }

  removeObserver(observer: DataModelObserver): boolean {
    return this.observers.remove(observer);
  }
}
```

#### 4. Single-Engine Page (SingleFlutterPage)

```ts
import { FlutterPage, Log } from '@ohos/flutter_ohos';
import router from '@ohos.router';
import { EngineBindings } from './EngineBindings';
import { common } from '@kit.AbilityKit';

@Entry()
@Component
struct SingleFlutterPage {
  @State viewId: string = "";
  private context = getContext(this) as common.UIAbilityContext
  private engineBindings: EngineBindings = new EngineBindings(this.context, this);

  onNext() {
    router.pushUrl({ "url": "pages/MainPage" });
  }

  aboutToAppear() {
    this.viewId = this.engineBindings.getFlutterViewId();
    this.engineBindings.attach();
  }

  aboutToDisappear(): void {
    this.engineBindings.detach();
  }

  onPageShow(): void {
    this.engineBindings.getEngine()?.getLifecycleChannel()?.appIsResumed();
    this.engineBindings.getEngine()?.getLifecycleChannel()?.aWindowIsFocused();
  }

  onPageHide(): void {
    this.engineBindings.getEngine()?.getLifecycleChannel()?.noWindowsAreFocused();
    this.engineBindings.getEngine()?.getLifecycleChannel()?.appIsPaused();
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId })
    }
  }
}
```

#### 5. Double-Engine Page (DoubleFlutterPage)

The key point of the double-engine page: create a separate `EngineBindings` instance for each FlutterPage, and attach/detach them separately.

```ts
import { FlutterPage, Log } from '@ohos/flutter_ohos';
import router from '@ohos.router';
import { EngineBindings } from './EngineBindings';
import { common } from '@kit.AbilityKit';

@Entry()
@Component
struct DoubleFlutterPage {
  @State topViewId: string = "";
  @State bottomViewId: string = "";
  private context = getContext(this) as common.UIAbilityContext;
  private topBindings: EngineBindings = new EngineBindings(this.context, this);
  private bottomBindings: EngineBindings = new EngineBindings(this.context, this);

  onNext() {
    router.pushUrl({ "url": "pages/MainPage" });
  }

  aboutToAppear() {
    this.topViewId = this.topBindings.getFlutterViewId();
    this.bottomViewId = this.bottomBindings.getFlutterViewId();
    this.topBindings.attach();
    this.bottomBindings.attach();
  }

  aboutToDisappear(): void {
    this.topBindings.detach();
    this.bottomBindings.detach();
  }

  onPageShow(): void {
    this.topBindings.getEngine()?.getLifecycleChannel()?.appIsResumed();
    this.topBindings.getEngine()?.getLifecycleChannel()?.aWindowIsFocused();
    this.bottomBindings.getEngine()?.getLifecycleChannel()?.appIsResumed();
    this.bottomBindings.getEngine()?.getLifecycleChannel()?.aWindowIsFocused();
  }

  onPageHide(): void {
    this.topBindings.getEngine()?.getLifecycleChannel()?.noWindowsAreFocused();
    this.topBindings.getEngine()?.getLifecycleChannel()?.appIsPaused();
    this.bottomBindings.getEngine()?.getLifecycleChannel()?.noWindowsAreFocused();
    this.bottomBindings.getEngine()?.getLifecycleChannel()?.appIsPaused();
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.topViewId })
        .height('50%')
        .backgroundColor(Color.Transparent)
      FlutterPage({ viewId: this.bottomViewId })
        .height('50%')
        .backgroundColor(Color.Transparent)
    }
  }
}
```

### 2. Creating the Flutter Module Project

The Dart code must be placed in a separate Flutter module project, which is compiled into a har package for the OHOS project to reference.

```sh
# Create the Flutter module project
flutter create -t module multiple_flutters_module
cd multiple_flutters_module
```

### 3. Dart Side

On the Dart side, `@pragma('vm:entry-point')` declares multiple entry functions, so different engines can run different entry points. Communication with the native side goes through `MethodChannel('multiple-flutters')`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp(color: Colors.blue));

@pragma('vm:entry-point')
void topMain() => runApp(const MyApp(color: Colors.green));

@pragma('vm:entry-point')
void bottomMain() => runApp(const MyApp(color: Colors.purple));

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.color});

  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorSchemeSeed: color, useMaterial3: true),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int? _counter = 0;
  late MethodChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = const MethodChannel('multiple-flutters');
    _channel.setMethodCallHandler((call) async {
      if (call.method == "setCount") {
        // Receive the count update pushed from the native side
        setState(() {
          _counter = call.arguments as int?;
        });
      } else {
        throw Exception('not implemented ${call.method}');
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _incrementCounter() {
    // Notify the native side of the data change
    _channel.invokeMethod<void>("incrementCount", _counter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            TextButton(
              onPressed: _incrementCounter,
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                _channel.invokeMethod<void>("next", _counter);
              },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Building and Running

### 1. Build the Flutter Module

```sh
cd multiple_flutters_module
flutter build har --debug
```

>  The artifact is located in `build/ohos/har/debug/`. Copy the har file to the `har/` directory of the OHOS project.

### 2. Build the OHOS Project

```sh
cd multiple_flutters_ohos
ohpm install
hvigorw assembleHap --no-daemon -p product=default -p buildMode=debug
```

### 3. Configure Signing and Run

Open `multiple_flutters_ohos` in DevEco Studio, choose **File → Project Structure → Signing Configs**, select Automatically generate signature, and then run the app.

## Demo Reference

For the complete demo, see [multiple_flutters](../../../add_to_app/multiple_flutters/).
