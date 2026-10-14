# Flutter Engine Asynchronous Creation and Destruction Guide

Flutter adds the ability to create and destroy engines asynchronously.

```ts
// Create an engine asynchronously; related file: FlutterEngineGroup.ets
createAndRunEngineByOptionsAsync(options: Options): Promise<FlutterEngine> {
    // ...
}
// Destroy an engine asynchronously; related file: FlutterEngine.ets
destroyAsync(): Promise<void> {
    // ...
}
```

## Use Cases

Scenarios that require creating multiple Flutter engines while preventing the engine creation and destruction flows from blocking the main thread.

## Usage Example

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
    // The page path must be declared in the main_pages.json configuration file; a missing entry causes a white screen.
    // Configuration file path: ohos/entry/src/main/resources/base/profile/main_pages.json
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
// `FlutterEngineGroup` manages multiple Flutter engines and supports asynchronous creation.
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
    // Ensure the loader required by the Flutter engine is ready
    engines.checkLoader(this.context, []);
    // DartEntrypoint.createDefault() can only be called after the environment required by the Flutter engine is ready; otherwise an exception is thrown.
    let options: Options = new Options(this.context).setDartEntrypoint(DartEntrypoint.createDefault());
    // Asynchronously create the Flutter engine object
    engines.createAndRunEngineByOptionsAsync(options).then((engine) => {
      if (!this.isAlive) {
        engine?.destroySync();
        return;
      }
      this.engine = engine;
      // Engine-related lifecycle handling
      engine?.getLifecycleChannel()?.appIsResumed()
      engine?.getAbilityControlSurface()?.attachToAbility(uiAbility);
      // flutterView-related lifecycle handling
      this.flutterView?.onWindowCreated();
      this.flutterView?.attachToFlutterEngine(engine);
      // Register plugins
      GeneratedPluginRegistrant.registerWith(engine);
      [new CustomPlugin(), new BatteryPlugin(), new PicturePlugin()]
        .forEach(item => {
          engine.getPlugins()?.add(item);
        })
      // Register the PlatformViewFactory
      // engine.getPlatformViewsController()?.getRegistry().registerViewFactory(viewTypeId, factory)
    })
  }

  aboutToDisappear(): void {
    this.isAlive = false;
    // flutterView-related lifecycle handling
    this.flutterView?.detachFromFlutterEngine()
    this.flutterView?.onDestroy()
    // Engine-related lifecycle handling
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

## Related Verification Scenarios

1. The counter interface created by `flutter create async_engine_demo`
2. PlatformView-related scenarios
   1. Native components
   2. Image display
   3. Video playback
   4. WebView

[Reference demo](../../../ohos/async_engine_demo)
