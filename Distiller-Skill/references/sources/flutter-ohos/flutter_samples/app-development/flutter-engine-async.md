# Flutter Engine 异步创建与销毁说明文档

Flutter 新增异步创建和销毁 Engine 的能力

```ts
// 异步创建 engine, 相关文件 FlutterEngineGroup.ets
createAndRunEngineByOptionsAsync(options: Options): Promise<FlutterEngine> {
    // ...
}
// 异步销毁 engine, 相关文件 FlutterEngine.ets
destroyAsync(): Promise<void> {
    // ...
}
```

## 使用场景

需要创建多个Flutter Engine，并避免engine的创建、销毁流程卡住主线程的场景。

## 使用示例

### ohos/entry/src/main/ets/entryability/EntryAbility.ets

```ts
export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {

  detachFromFlutterEngine(): void {
    // throw new Error('Method not implemented.');
  }

  getAppComponent(): UIAbility {
    return this;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onDestroy(): void | Promise<void> {
    FlutterManager.getInstance().popUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindowSync().setWindowLayoutFullScreen(true);
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    // 页面路径需要在配置文件 main_pages.json 中声明，缺失会导致白屏。
    // 配置文件路径: ohos/entry/src/main/resources/base/profile/main_pages.json
    // windowStage.loadContent('pages/Index');
    windowStage.loadContent('pages/FlutterAsyncPage');
  }

  onWindowStageDestroy() {
    FlutterManager.getInstance().popWindowStage(this);
  }
}
```

### ohos/entry/src/main/ets/pages/FlutterAsyncPage.ets

```ts
// `FlutterEngineGroup` 用于管理多个 Flutter 引擎，并支持异步创建。
const engines = new FlutterEngineGroup();

@Entry()
@Preview
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  private flutterView: FlutterView | null = null;
  private engine?: FlutterEngine;
  private isAlive: boolean = false;

  build() {
    Stack() {
      FlutterPage({
        viewId: this.flutterView?.getId(),
        // ...
      })
    }
  }

  aboutToAppear(): void {
    this.isAlive = true;
    this.flutterView = FlutterManager.getInstance().createFlutterView(this.context);
    this.init()
  }

  async init() {
    let uiAbility: EntryAbility = FlutterManager.getInstance().getUIAbility(this.context) as EntryAbility;
    // 确保 Flutter Engine 所需的加载器已就绪
    engines.checkLoader(this.context, []);
    // DartEntrypoint.createDefault() 在 Flutter Engine 所需环境准备就绪后才可调用，否则会抛出异常。
    let options: Options = new Options(this.context).setDartEntrypoint(DartEntrypoint.createDefault());
    // 异步创建 Flutter Engine 对象
    engines.createAndRunEngineByOptionsAsync(options).then((engine) => {
      if (!this.isAlive) {
        engine?.destroySync();
        return;
      }
      this.engine = engine;
      // engine 相关生命周期处理
      engine?.getLifecycleChannel()?.appIsResumed()
      engine?.getAbilityControlSurface()?.attachToAbility(uiAbility);
      // flutterView 相关生命周期处理
      this.flutterView?.onWindowCreated();
      this.flutterView?.attachToFlutterEngine(engine);
      // 注册插件
      GeneratedPluginRegistrant.registerWith(engine);
      [new CustomPlugin(), new BatteryPlugin(), new PicturePlugin()]
        .forEach(item => {
          engine.getPlugins()?.add(item);
        })
      // 注册 PlatformViewFactory
      // engine.getPlatformViewsController()?.getRegistry().registerViewFactory(viewTypeId, factory)
    })
  }

  aboutToDisappear(): void {
    this.isAlive = false;
    // flutterView 相关生命周期处理
    this.flutterView?.detachFromFlutterEngine()
    this.flutterView?.onDestroy()
    // engine 相关生命周期处理
    this.engine?.getLifecycleChannel()?.appIsDetached()
    this.engine?.getAbilityControlSurface()?.detachFromAbility();
    this.engine?.destroyAsync()
    this.engine = undefined;
    this.flutterView = undefined;
  }

  onPageShow(): void {
    this.engine?.getLifecycleChannel()?.appIsResumed()
  }
  
  onPageHide(): void {
    this.engine?.getLifecycleChannel()?.appIsPaused()
  }

  // ...
}

```

## 相关验证场景

1. `flutter create async_engine_demo` 创建的计数器界面
2. PlatformView 相关场景
   1. 原生组件
   2. 图片显示
   3. 视频播放
   4. WebView

[参考demo](../../../ohos/async_engine_demo)
