# Developing a Dart Package

A pure Dart package contains only Dart code and does not depend on any native platform implementation. It runs directly on the ohos platform without any OpenHarmony adaptation, making it the type of package with the highest cross-platform reusability.

---

## Creating a Package

```sh
flutter create --template=package hello
```

The generated directory structure is as follows:

```text
hello/
├── lib/                # Public code
│   └── hello.dart      # Entry file (same name as the package)
├── test/               # Unit tests
│   └── hello_test.dart
├── CHANGELOG.md        # Version change log
├── LICENSE             # License
├── README.md           # Documentation
└── pubspec.yaml        # Metadata and dependency declarations
```

> A pure Dart package does not generate native directories such as `ohos/`, `android/`, or `ios/`, and it does not declare the `flutter.plugin` field in `pubspec.yaml`.

---

## Implementing the Package

Write the Dart code under `lib/`.

Example (`lib/hello.dart`):

```dart
class Hello {
  static String greet(String name) => 'Hello, $name!';
}
```

Place the accompanying unit tests under `test/`:

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

## Verifying on an ohos Device

A pure Dart package cannot run on its own; it must be verified through a host app. `--template=package` does not generate an `example/`, so create one manually by following these steps.

### Step 1: Create an example app

Create a Flutter app for the ohos platform in the package directory:

```sh
cd hello
flutter create --platforms=ohos example
```

### Step 2: Reference the package and write verification code

Add the package to `example/pubspec.yaml` as a local path dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hello:
    path: ../
```

Call the package API in `example/lib/main.dart`:

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

### Step 3: Run on an ohos device

```sh
cd example
flutter pub get
flutter run -d <device-id> --debug
```

---

## Platform Detection Code Adaptation

A pure Dart package does not depend on any native implementation. However, if it contains **platform detection logic** (for example, returning different styles by platform or branching between different third-party libraries) and lacks an `ohos` branch, execution falls into the wrong `else` branch at runtime, causing abnormal behavior.

**Problem example**:

```dart
if (Platform.isAndroid) {
  return androidStyle();
} else {
  return iosStyle(); // ohos devices incorrectly execute this branch
}
```

**Adaptation approach**: Add the corresponding branch for ohos. Using `defaultTargetPlatform` is recommended:

```dart
import 'package:flutter/foundation.dart';

if (defaultTargetPlatform == TargetPlatform.android) {
  return androidStyle();
} else if (defaultTargetPlatform == TargetPlatform.ohos) {
  return ohosStyle(); // or reuse androidStyle()
} else {
  return iosStyle();
}
```

---

## FAQ

### Does a pure Dart package need to declare ohos platform support in pubspec.yaml?

No. A pure Dart package does not declare the `flutter.plugin` field; its code is cross-platform and runs on ohos directly. Only plugins need to declare `ohos` under `flutter.plugin.platforms` in `pubspec.yaml`.

### Can a pure Dart library that runs correctly on Android/iOS also run correctly on ohos?

Usually yes. However, if the library contains platform detection logic that lacks an `ohos` branch, it may fall into the wrong `else` branch and behave abnormally. Check it and add the ohos branch as described in [Platform Detection Code Adaptation](#platform-detection-code-adaptation).

### How do I tell whether a library is a pure Dart package or a plugin?

Check whether `pubspec.yaml` contains a `flutter.plugin` declaration, or whether the source code contains native platform directories such as `android/`, `ios/`, or `ohos/`. If it does, the library is a plugin; otherwise, it is a pure Dart library.
