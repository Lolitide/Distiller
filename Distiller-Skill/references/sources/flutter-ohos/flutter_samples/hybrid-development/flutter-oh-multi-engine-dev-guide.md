# Flutter OH 多引擎场景开发指导

本文介绍在 Flutter OH 多引擎场景下，如何通过 `FlutterEngineGroup` 创建多个共享 Dart isolate 的引擎实例，并在原生 ArkTS 页面中分别嵌入不同 Dart 入口的 Flutter 视图。适用于分屏双 Flutter 视图、多页面独立引擎等场景。

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)
- 已安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 工具

## 使用步骤

### 第一步：创建 Flutter 应用

执行 `flutter create demo` 创建 Flutter 应用

### 第二步：Flutter 端配置

- **打开创建的 Flutter 应用，创建多个 Dart 页面**

- **在 `lib/main.dart` 中定义多页面路由**

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '多引擎集成',
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

### 第三步：ArkTS 端集成

- **创建多引擎，分别指定不同 Dart 入口**

`entry/src/main/ets/pages/Index.ets`：

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

  // 创建Engine  
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
          // TODO: 异常处理
        }
      }
    }

  }

  build() {
    Stack() {
      Column() {
        Button('跳转Page1')
          .onClick(() => {
            try {
              FlutterEngineCache.getInstance().get('/page1')?.getNavigationChannel()?.pushRoute('/page1')
            router.pushUrl({ url: 'pages/Flutter', params: { route: '/page1' } })
          } catch (err) {
            // TODO: 异常处理
          }
          })

        Button('跳转Page2')
          .onClick(() => {
            try {
              FlutterEngineCache.getInstance().get('/page2')?.getNavigationChannel()?.pushRoute('/page2')
            router.pushUrl({ url: 'pages/Flutter', params: { route: '/page2' } })
          } catch (err) {
            // TODO: 异常处理
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

- **在 `entry/src/main/ets/pages` 下新建页面 Flutter.ets，页面里加载对应 FlutterEngine**

```ts
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

以上示例代码展示了多引擎的实现方式。