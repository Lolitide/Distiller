# 开发Flutter Plugin

本文介绍如何在 OpenHarmony 平台上开发 Flutter 原生插件（Native Plugin），涵盖创建插件项目、声明平台支持、实现 Dart 与 ArkTS 原生代码、注册与编译运行的端到端流程。

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)。

## 开发步骤

### 第一步：创建插件项目

使用 `flutter create` 指令创建一个同时支持 Android、iOS 和 ohos 的插件项目：

```sh
flutter create --org com.example --template=plugin --platforms=android,ios,ohos hello
```

创建完成后，插件根目录结构：

```text
hello/
├── lib/                              # Dart 接口实现
│   ├── hello.dart                    # 面向应用开发者的公共 API
│   ├── hello_method_channel.dart      # MethodChannel 实现
│   └── hello_platform_interface.dart # 平台接口抽象（federated 插件模式）
├── ohos/                             # ohos 平台模块（har module，非 project 工程）
│   ├── oh-package.json5             # 模块依赖配置
│   ├── hvigorfile.ts                # hvigor 构建脚本（harTasks）
│   ├── build-profile.json5          # 构建配置
│   ├── index.ets                    # 模块导出入口
│   ├── local.properties             # 自动生成，勿手动编辑、勿提交
│   ├── .gitignore                   # 忽略 build/ 等产物
│   └── src/main/
│       ├── module.json5             # 模块配置（name、type=har）
│       └── ets/components/plugin/
│           └── HelloPlugin.ets       # ArkTS 原生插件实现
├── android/                          # Android 平台实现
├── ios/                              # iOS 平台实现
├── example/                          # 示例 App（其 example/ohos 是完整的 hvigor 宿主工程）
│   └── ohos/
│       ├── hvigorfile.ts            # appTasks + flutterHvigorPlugin
│       ├── hvigorconfig.ts          # injectNativeModules（自动注入插件源码节点）
│       └── entry/                    # 入口模块
│           └── src/main/ets/entryability/EntryAbility.ets
├── test/                             # Dart 单元测试
└── pubspec.yaml
```

### 第二步：在 pubspec.yaml 中声明 ohos 平台

`flutter create --template=plugin --platforms=ohos` **模板已自动生成** `plugin.platforms` 配置，**通常无需手改**：

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

字段说明：

| 字段          | 适用平台 | 含义                                                         |
| ------------- | -------- | ------------------------------------------------------------ |
| `pluginClass` | 全部     | 原生插件实现类名，需与 ArkTS 中 `getUniqueClassName()` 返回值一致。框架据此在 `index.ets` 导出的类中查找并实例化插件。 |

### 第三步：实现插件

**步骤 3.1：定义 Dart API**

`flutter create` 默认采用 **federated 插件模式**，将公共 API、平台接口抽象与通道实现分离到三个文件中。

`lib/hello.dart` 是面向应用开发者的公共 API，委托给平台接口：

```dart
import 'hello_platform_interface.dart';

class Hello {
  Future<String?> getPlatformVersion() {
    return HelloPlatform.instance.getPlatformVersion();
  }
}
```

`lib/hello_method_channel.dart` 是 MethodChannel 实现，在此创建与原生侧通信的通道：

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

> **说明：** Dart 侧与原生侧的 channel 名称（上例中为 `'hello'`，默认与插件名相同）必须完全一致，否则调用无法到达原生实现。如需自定义名称，两处需同步修改。

**步骤 3.2：实现 ohos 原生代码（ArkTS）**

在 `ohos/src/main/ets/components/plugin/HelloPlugin.ets` 中实现 ohos 平台原生逻辑。一个原生插件类需实现 `FlutterPlugin` 接口，并通过 `MethodChannel` 接收 Dart 侧调用：

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

  // 返回插件类名，用于注册与去重
  getUniqueClassName(): string {
    return 'HelloPlugin';
  }

  // 引擎附加时创建 channel 并注册方法处理器
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  // 引擎分离时释放资源
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
  }

  // 处理来自 Dart 侧的方法调用
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

**关键接口说明**：

| 接口 / 方法 | 作用 |
| --- | --- |
| `FlutterPlugin` | 插件基础接口，需实现 `onAttachedToEngine` / `onDetachedFromEngine` / `getUniqueClassName`。 |
| `MethodCallHandler` | 处理 `MethodChannel` 方法调用，实现 `onMethodCall(call, result)`。 |
| `StreamHandler` | 处理 `EventChannel` 事件流，实现 `onListen` / `onCancel`，用于向 Dart 侧持续推送事件。 |
| `AbilityAware` | 需访问 Ability 上下文时实现，通过 `onAttachedToAbility` 获取 Ability。 |
| `binding.getApplicationContext()` | 在 `onAttachedToEngine` 中获取 ohos `Context`，用于调用系统能力（文件、权限等）。 |

`MethodResult` 回调三选一：`result.success(value)` 返回成功结果；`result.error(code, message, details)` 返回错误；`result.notImplemented()` 表示未实现的方法。

**步骤 3.3：导出插件类（index.ets）**

ohos 模块的 `ohos/index.ets` 默认导出插件类，使工具链能按包名找到实现：

```ts
import HelloPlugin from './src/main/ets/components/plugin/HelloPlugin';
export default HelloPlugin;
```

`ohos/oh-package.json5` 中 `"main": "index.ets"` 指向该入口：

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

### 第四步：注册与运行

**步骤 4.1：自动注册（推荐）**

当插件在宿主工程 `pubspec.yaml` 中声明后，执行 `flutter pub get` 时工具链会自动生成 `GeneratedPluginRegistrant.ets`。该文件按包名引入各插件类，并在 `registerWith` 中将其加入引擎插件列表：

```ts
// 生成文件，请勿手动编辑
import { FlutterEngine } from '@ohos/flutter_ohos';
import HelloPlugin from 'hello';

export class GeneratedPluginRegistrant {
  static registerWith(flutterEngine: FlutterEngine) {
    flutterEngine.getPlugins()?.add(new HelloPlugin());
  }
}
```

宿主 `EntryAbility` 只需调用一次即可完成所有已声明插件的注册：

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

**步骤 4.2：手动注册**

对于未在 `pubspec.yaml` 中声明、直接定义在应用内的本地插件类，可在 `configureFlutterEngine` 中手动注册：

```ts
this.addPlugin(new HelloPlugin());
```

**步骤 4.3：编译运行**

建议使用 DevEco Studio 打开 `hello/example/ohos` 目录编译运行：

1. 配置签名：`File -> Project Structure -> Signing Configs -> Automatically generate signature`。
2. 运行项目，或使用命令行：

```sh
cd hello/example
flutter pub get
flutter build hap --debug        # 仅构建
flutter run -d <device-id>      # 构建并安装运行
```

## 为现有插件项目补齐 ohos 平台

若现有 `plugin` 类型插件尚未支持 ohos，可在插件根目录执行以下指令补齐脚手架：

```sh
flutter create . --template=plugin --platforms=ohos
```

执行后需依次完成：

1. 在 `pubspec.yaml` 的 `flutter.plugin.platforms` 中补充 `ohos` 配置（参考第二步）。
2. 在生成的 `ohos/` 目录中实现原生插件代码（参考步骤 3.2）。
3. 通过 `ohos/index.ets` 导出插件类（参考步骤 3.3）。
