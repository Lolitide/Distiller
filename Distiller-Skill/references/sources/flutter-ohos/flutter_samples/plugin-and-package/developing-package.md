# 开发 Dart Package

纯 Dart Package 仅含 Dart 代码、不依赖原生平台实现，无需 OpenHarmony 适配即可在 ohos 平台直接运行，是跨平台复用性最高的一类 package。

---

## 创建 Package

```sh
flutter create --template=package hello
```

生成目录结构：

```text
hello/
├── lib/                # 公开代码
│   └── hello.dart      # 入口文件（与 package 同名）
├── test/               # 单元测试
│   └── hello_test.dart
├── CHANGELOG.md        # 版本变更记录
├── LICENSE             # 许可证
├── README.md           # 说明文档
└── pubspec.yaml        # 元数据与依赖声明
```

> 纯 Dart package 不生成 `ohos/`、`android/`、`ios/` 等原生目录，也不在 `pubspec.yaml` 中声明 `flutter.plugin` 字段。

---

## 实现 Package

在 `lib/` 下编写 Dart 代码。

示例（`lib/hello.dart`）：

```dart
class Hello {
  static String greet(String name) => 'Hello, $name!';
}
```

配套单元测试放在 `test/` 下：

```dart
// test/hello_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hello/hello.dart';

void main() {
  test('greet returns greeting message', () {
    expect(Hello.greet('OHOS'), 'Hello, OHOS!');
  });
}
```

```sh
flutter test
```

---

## 在 ohos 设备上验证

纯 Dart package 不能独立运行，需通过宿主应用验证。`--template=package` 不生成 `example/`，按以下步骤手动创建。

### 第一步：创建示例 App

在 package 目录下创建一个 ohos 平台的 Flutter 应用：

```sh
cd hello
flutter create --platforms=ohos example
```

### 第二步：引用 package 并编写验证代码

在 `example/pubspec.yaml` 中以本地路径依赖引入 package：

```yaml
dependencies:
  flutter:
    sdk: flutter
  hello:
    path: ../
```

在 `example/lib/main.dart` 中调用 package 接口：

```dart
import 'package:flutter/material.dart';
import 'package:hello/hello.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(Hello.greet('OHOS')),
        ),
      ),
    );
  }
}
```

### 第三步：运行到 ohos 设备

```sh
cd example
flutter pub get
flutter run -d <device-id> --debug
```

---

## 平台判断代码适配

纯 Dart package 不依赖原生实现，但若内部包含**平台判断逻辑**（如按平台返回不同样式、使用不同第三方库分支）且缺少 `ohos` 分支，运行时会落入错误的 `else` 分支，导致异常行为。

**问题示例**：

```dart
if (Platform.isAndroid) {
  return androidStyle();
} else {
  return iosStyle(); // ohos 设备会错误执行此处
}
```

**适配方式**：为 ohos 补充对应分支，推荐使用 `defaultTargetPlatform`：

```dart
import 'package:flutter/foundation.dart';

if (defaultTargetPlatform == TargetPlatform.android) {
  return androidStyle();
} else if (defaultTargetPlatform == TargetPlatform.ohos) {
  return ohosStyle(); // 或复用 androidStyle()
} else {
  return iosStyle();
}
```

---

## 常见问题

### 纯 Dart package 需要在 pubspec.yaml 中声明 ohos 平台支持吗？

不需要。纯 Dart package 不声明 `flutter.plugin` 字段，代码跨平台通用，ohos 可直接运行。仅插件（plugin）才需在 `pubspec.yaml` 的 `flutter.plugin.platforms` 中声明 `ohos`。

### 在 Android/iOS 上运行正常的纯 Dart 库，在 ohos 上也能正常运行吗？

通常可以。但若库内部包含平台判断逻辑而缺少 `ohos` 分支，可能落入错误的 `else` 分支导致异常。请按 [平台判断代码适配](#平台判断代码适配) 检查并补充 ohos 分支。

### 如何判断一个库是纯 Dart package 还是插件？

查看 `pubspec.yaml` 是否包含 `flutter.plugin` 声明，或检查源码是否包含 `android/`、`ios/`、`ohos/` 等原生平台目录。有则为插件，无则为纯 Dart 库。
