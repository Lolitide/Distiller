# 如何使用多引擎 FlutterEngineGroup

本文介绍如何使用 `FlutterEngineGroup` 在 OpenHarmony 应用中创建多个 Flutter 引擎实例，实现同页面或不同页面中同时嵌入多个 Flutter 视图。

`FlutterEngineGroup` 创建的引擎共享同一 Dart isolate，比独立创建多个引擎更高效。适用于分屏双 Flutter 视图、列表中嵌入多个 Flutter 视图等场景。

## 核心概念

| 术语 | 说明 |
|------|------|
| `FlutterEngineGroup` | 引擎组，通过 `createAndRunEngineByOptions()` 创建共享 isolate 的引擎实例 |
| `EngineBindings` | 封装单个引擎的生命周期管理（attach/detach）与通信通道 |
| `FlutterView` | 由 `FlutterManager.createFlutterView()` 创建的渲染视图，每个引擎对应一个 |
| `DataModel` | 单例数据模型，通过观察者模式实现多引擎间数据同步 |
| `@pragma('vm:entry-point')` | Dart 侧声明多个入口函数，不同引擎可运行不同入口 |

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)。
- 已创建 OHOS 工程。

## 实现步骤

### 一、原生侧（ArkTS）

#### 1. EntryAbility 继承 UIAbility 

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

#### 2. 创建 FlutterEngineGroup 与 EngineBindings

`EngineBindings` 是核心封装类，管理单个引擎的创建、附着、分离和通信。`FlutterEngineGroup` 在模块级创建为单例，所有 `EngineBindings` 实例共享同一引擎组。

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
    // 全屏模式，避免折叠屏等场景下出现区域塌陷
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
    // 按顺序执行：1.检查加载器 2.创建引擎 3.通知生命周期 4.附着Ability 5.绑定View 6.注册插件
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

    // 创建通信通道，与 Dart 侧交互
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

#### 3. DataModel 共享数据

`DataModel` 是单例，通过观察者模式实现多引擎间数据同步。每个 `EngineBindings` 注册为 observer，`DataModel.increase()` 时通知所有 observer，observer 通过 `MethodChannel` 将新值推送给 Dart 侧。

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

#### 4. 单引擎页面 SingleFlutterPage

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

#### 5. 双引擎页面 DoubleFlutterPage

双引擎页面的关键：为每个 FlutterPage 创建独立的 `EngineBindings` 实例，分别 attach/detach。

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

### 二、创建 Flutter Module 工程

Dart 侧代码需放在独立的 Flutter Module 工程中，编译后生成 har 包供 OHOS 工程引用。

```sh
# 创建 Flutter Module 工程
flutter create -t module multiple_flutters_module
cd multiple_flutters_module
```

### 三、Dart 侧

Dart 侧通过 `@pragma('vm:entry-point')` 声明多个入口函数，不同引擎可运行不同入口。通过 `MethodChannel('multiple-flutters')` 与原生侧通信。

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
        // 接收原生侧推送的计数更新
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
    // 将数据变更通知原生侧
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

## 编译运行

### 1. 构建 Flutter Module

```sh
cd multiple_flutters_module
flutter build har --debug
```

>  产物位于 `build/ohos/har/debug/`，将 har 文件复制到 OHOS 工程的 `har/` 目录。

### 2. 构建 OHOS 工程

```sh
cd multiple_flutters_ohos
ohpm install
hvigorw assembleHap --no-daemon -p product=default -p buildMode=debug
```

### 3. 配置签名并运行

使用 DevEco Studio 打开 `multiple_flutters_ohos`，通过 **File → Project Structure → Signing Configs** 勾选 Automatically generate signature，然后运行。

## Demo 参考

完整 demo 请参考 [multiple_flutters](../../../add_to_app/multiple_flutters/)
