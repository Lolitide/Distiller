# Flutter App OpenHarmony Integration Guide

This document describes how to extend an existing Flutter app (already supporting iOS/Android) to support the OpenHarmony platform: add an ohos directory to the existing project while maintaining multi-platform code reuse.

---

## Prerequisites

- [Flutter OH Development Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md) has been completed
- A Flutter app project that compiles and runs properly (already supporting iOS/Android)

---

## Starting the Adaptation

### 1. Back Up the Existing Project

```bash
cp -r your_flutter_project your_flutter_project_backup
```

### 2. Add OpenHarmony Support

Navigate to your Flutter project directory and run the following command:

```bash
cd your_flutter_project

# Add ohos platform support to the existing project
flutter create --platforms ohos .
```

After the command succeeds, an ohos directory is added to the project with the following structure:

```text
your_flutter_project/
├── android/              # Android platform code
├── ios/                  # iOS platform code
├── ohos/                 # OpenHarmony platform code (new)
│   ├── build-profile.json5
│   ├── hvigorfile.ts
│   ├── local.properties
│   ├── entry/            # Main entry module
│   │   ├── build-profile.json5
│   │   ├── hvigorfile.ts
│   │   ├── oh-package.json5
│   │   └── src/
│   │       ├── main/
│   │       │   ├── ets/
│   │       │   │   ├── entryability/
│   │       │   │   │   └── EntryAbility.ets      # Main entry Ability
│   │       │   │   └── pages/
│   │       │   │       └── Index.ets             # Main page
│   │       │   └── resources/                    # Resource files
│   │       └── ohosTest/                         # Test code
│   └── ohos/           # Flutter engine module
├── lib/               # Dart business code (multi-platform reuse)
├── test/
├── pubspec.yaml
└── ...
```

### 3. Configure Project Signing

Open the `ohos` directory in DevEco Studio:

1. Select **File → Project Structure → Project → Signing Configs**
2. Check **Automatically generate signature** to generate the signature automatically
3. Click **OK** to save

### 4. Adapt pubspec.yaml

- Adjust the SDK constraints according to the target Flutter OH version:

```yaml
# Flutter 3.27.4-ohos version
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.27.0"

# Flutter 3.22.0-ohos version
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.22.0"
```

- Fetch dependencies

```bash
flutter clean
flutter pub get
```

---

## Third-Party Library Adaptation

> Before adapting, check [third-party libraries adapted for the OpenHarmony platform](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md) to see whether the third-party libraries your project depends on have been adapted for OpenHarmony. If a library you use has not been adapted, submit an [issue](https://gitcode.com/org/CPF-Flutter/issues) for feedback.

### 1. Replace with OpenHarmony-Compatible Versions

```yaml
dependencies:
  # Original configuration (official Pub version, does not support OpenHarmony)
  # path_provider: ^2.1.0
  
  # New configuration (OpenHarmony-adapted version)
  path_provider:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/path_provider/path_provider"
      ref: "br_path_provider-v2.1.5_ohos"  # Adjust to the actual version
  
  shared_preferences:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences"
      ref: "br_shared_preferences-v2.5.4_ohos"
  
  url_launcher:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/url_launcher/url_launcher"
      ref: "br_url_launcher-v6.3.2_ohos"
```

### 2. Plugins That Require Manual Adaptation

If the project uses in-house plugins or plugins that have not yet been adapted for OpenHarmony, you need to add OpenHarmony platform implementations for them.

For adaptation guidance, see [Developing a Flutter Plugin](../plugin-and-package/developing-plugin.en.md)

### 3. Platform Check Code Adaptation

If the code contains platform checks, add the OpenHarmony branch. `defaultTargetPlatform` is recommended; avoid `Platform.isOhos`:

```dart
import 'package:flutter/foundation.dart';

// Original code
if (defaultTargetPlatform == TargetPlatform.android) {
  // Android-specific logic
} else if (defaultTargetPlatform == TargetPlatform.iOS) {
  // iOS-specific logic
}

// After adaptation - add the OpenHarmony platform check
if (defaultTargetPlatform == TargetPlatform.android) {
  // Android-specific logic
} else if (defaultTargetPlatform == TargetPlatform.iOS) {
  // iOS-specific logic
} else if (defaultTargetPlatform == TargetPlatform.ohos) {
  // OpenHarmony-specific logic
}
```

If the code also needs to compile with the upstream community Flutter SDK, `defaultTargetPlatform == TargetPlatform.ohos` causes an error because this enum value does not exist there; use `Platform.operatingSystem == 'ohos'` (not `Platform.isOhos`) instead so the code compiles with both SDKs:

```dart
import 'dart:io';

if (Platform.operatingSystem == 'ohos') {
  // OpenHarmony-specific logic
}
```

### 4. Pure Dart Third-Party Libraries

Pure Dart third-party libraries usually run on OpenHarmony without modification. However, if the code contains platform checks, you still need to add the OpenHarmony platform check as described in **Step 3** above.

---

## Build and Run

### 1. Connect a Device

```bash
# View connected devices
flutter devices

# Example of expected output
# 9CN0123608000xxx (mobile) • 9CN0123608000xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26
```

### 2. Run and Debug

```bash
# Run on an OpenHarmony device
flutter run -d <device_id>

# Or use the shorthand (if only one device is connected)
flutter run
```

### 3. Build a HAP Package

```bash
# Debug version
flutter build hap --debug

# Release version
flutter build hap --release
```

### 4. Install the HAP Package

```bash
# Install using the hdc tool
hdc install build\ohos\hap\entry-default-signed.hap

# Or specify a device
hdc -t <device_id> install build\ohos\hap\entry-default-signed.hap
```

---

## Feedback

- Issue feedback: You are welcome to submit issues in the [Flutter framework repository](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) and in the repositories of the Flutter third-party libraries.
