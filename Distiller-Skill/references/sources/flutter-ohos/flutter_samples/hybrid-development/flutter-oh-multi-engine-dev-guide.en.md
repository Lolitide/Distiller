# Flutter OH Multi-Engine Scenario Development Guide

This document describes how, in Flutter OH multi-engine scenarios, you can use `FlutterEngineGroup` to create multiple engine instances that share a Dart isolate, and embed Flutter views with different Dart entry points in separate native ArkTS pages. It applies to scenarios such as split-screen dual Flutter views and independent engines for multiple pages.

## Prerequisites

- Complete the [Flutter OH Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md)
- Install the [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) tool

## Usage Steps

### Step 1: Create a Flutter Application

Run `flutter create demo` to create a Flutter application.

### Step 2: Flutter-Side Configuration

- **Open the created Flutter application and create multiple Dart pages**

- **Define multi-page routes in `lib/main.dart`**

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-engine integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (context) => HomePage(),
        '/page1': (context) => const page1.MyApp(),
        '/page2': (context) => const page2.MyApp(),
      },
    );
  }
}
```

### Step 3: ArkTS-Side Integration

- **Create multiple engines, each specifying a different Dart entry point**

`entry/src/main/ets/pages/Index.ets`:

```ts
import { router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { FlutterEngineCache, FlutterEngineGroup } from '@ohos/flutter_ohos'

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  private flutterEngineGroup ?: FlutterEngineGroup;
  @LocalStorageLink('viewId') viewId: string = "";

  async aboutToAppear(): Promise<void> {
    await this.createAndCacheEngine();
  }

  // Create the engine
  private async createAndCacheEngine(): Promise<void> {
    this.flutterEngineGroup = new FlutterEngineGroup();

    interface EngineConfig {
      key: string;
      entrypoint: string;
    }

    const engineConfigs: EngineConfig[] = [
      {
        key: "/page1", entrypoint: "lib/page1/main.dart",
      },
      {
        key: "/page2", entrypoint: "lib/page2/main.dart",
      }
    ];

    for (const config of engineConfigs) {
      if (!FlutterEngineCache.getInstance().contains(config.key)) {
        try {
          let flutterEngine = await this.flutterEngineGroup.createEngine(getContext(this), null);
          await flutterEngine.init(getContext(this), null, false);
          FlutterEngineCache.getInstance().put(config.key, flutterEngine);
        } catch (error) {
          // TODO: error handling
        }
      }
    }

  }

  build() {
    Stack() {
      Column() {
        Button('Go to Page1')
          .onClick(() => {
            try {
              FlutterEngineCache.getInstance().get('/page1')?.getNavigationChannel()?.pushRoute('/page1')
            router.pushUrl({ url: 'pages/Flutter', params: { route: '/page1' } })
          } catch (err) {
            // TODO: error handling
          }
          })

        Button('Go to Page2')
          .onClick(() => {
            try {
              FlutterEngineCache.getInstance().get('/page2')?.getNavigationChannel()?.pushRoute('/page2')
            router.pushUrl({ url: 'pages/Flutter', params: { route: '/page2' } })
          } catch (err) {
            // TODO: error handling
          }
          })
      }
    }.width('100%').height('100%').align(Alignment.Center)
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
```

- **Create a new page `Flutter.ets` under `entry/src/main/ets/pages`, and load the corresponding FlutterEngine in the page**

```
import router from '@ohos.router';
import { FlutterPage } from '@ohos/flutter_ohos';
import { FlutterView } from '@ohos/flutter_ohos/src/main/ets/view/FlutterView';
import FlutterEntry from '@ohos/flutter_ohos/src/main/ets/embedding/ohos/FlutterEntry';
import MyFlutterEntry from '../entryability/MyFlutterEntry';

@Entry
@Component
struct Index {
  private flutterEntry: FlutterEntry | null = null;
  private flutterView: FlutterView | undefined = undefined;

  aboutToAppear(): void {
    const context = getContext(this) as Context;
    const params = router.getParams() as Record<string, Object>;
    params["should_attach_engine_to_ability"] = true;
    let routeName = params["route"] as string;
    params["cached_engine_id"] = routeName;
    this.flutterEntry = new MyFlutterEntry(context, params);
    this.flutterEntry.aboutToAppear()
    this.flutterView = this.flutterEntry.getFlutterView();
  }

  aboutToDisappear(): void {
    this.flutterEntry?.aboutToDisappear()
  }

  onPageShow(): void {
    this.flutterEntry?.onPageShow()
  }

  onPageHide(): void {
    this.flutterEntry?.onPageHide()
  }

  build(): void {
    Stack() {
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
  }

  onBackPress(): boolean {
    this.flutterEntry?.onBackPress();
    return true;
  }
}
```

The example code above demonstrates how to implement multiple engines.
