# Flutter OH App Build and Run Guide

This document describes how to create, sign, build, install, and run Flutter apps on the OpenHarmony platform, covering the three build modes (debug/profile/release), Impeller rendering engine configuration, local Engine builds, and more.

---

## Prerequisites

- Complete the [Flutter OH Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md)

---

## Steps

### Step 1: Create the App

```bash
# Option 1: create an ohos-only platform project
flutter create --platforms ohos <projectName>

# Option 2: create a multi-platform project for android, ios, and ohos at once
flutter create <projectName>
```

After creation, an `ohos/` directory is generated in the project root directory, with the following key structure:

```text
<projectName>/
├── lib/                    # Dart business code
├── ohos/                   # OpenHarmony platform code
│   ├── AppScope/
│   │   └── app.json5       # App-wide global configuration (bundle name, version, etc.)
│   ├── build-profile.json5  # Build configuration (signing, SDK version, build modes)
│   ├── hvigorfile.ts       # Hvigor build script
│   ├── hvigorconfig.ts     # Hvigor plugin configuration
│   ├── oh-package.json5    # Project dependency configuration
│   └── entry/              # Main entry module
│       ├── build-profile.json5
│       ├── oh-package.json5
│       └── src/main/
│           ├── ets/        # ArkTS code
│           ├── module.json5
│           └── resources/base/profile/
│               └── buildinfo.json5  # Impeller rendering configuration
└── pubspec.yaml
```

---

### Step 2: Configure Signing

Before building or running on a real device, the project must be signed:

1. Open the `<projectName>/ohos` directory with **DevEco Studio**
2. Click **File → Project Structure → Project → Signing Configs**
3. Check **Automatically generate signature** to generate the signature automatically
4. Click **OK** to save

---

### Step 3: Build the App

#### Build Modes

| Mode        | Command Argument     | Use Case                 |
| ----------- | -------------------- | ------------------------ |
| **debug**   | `--debug`            | Day-to-day development and debugging |
| **profile** | `--profile`          | Performance analysis and tuning |
| **release** | `--release` (default) | Official release        |

#### Build Commands

```bash
# Enter the project root directory
cd <projectName>

# Debug build
flutter build hap --debug

# Profile build
flutter build hap --profile

# Release build (default mode)
flutter build hap --release
```

```bash
# Skip signing and build an unsigned HAP (it must be signed manually before it can be installed on a device)
flutter build hap --release --no-codesign
```

#### Build Artifact Paths

| Signing Status | Artifact File Name             | Path                            |
| -------------- | ------------------------------ | ------------------------------- |
| Signed         | `entry-default-signed.hap`     | `<projectName>/build/ohos/hap/` |
| Unsigned       | `entry-default-unsigned.hap`   | `<projectName>/build/ohos/hap/` |

#### Specifying the Version Number

By default, the build resets `versionName` in `app.json5` to `1.0.0`. To specify a version number, use the following arguments:

```bash
flutter build hap --release --build-name=4.0.3 --build-number=10000
```

| Argument               | Description                  | Corresponding app.json5 Field |
| ---------------------- | ---------------------------- | ----------------------------- |
| `--build-name=<x.y.z>` | User-visible version number  | `versionName`                 |
| `--build-number=<n>`   | Internal version number      | `versionCode`                 |

#### Specifying the Target Architecture

The default target platform is `ohos-arm64` (real devices). If you alternate between an emulator and a real device during debugging, compilation may fail because the cached architecture does not match; specifying the target explicitly is recommended:

```bash
flutter build hap --release --target-platform ohos-arm64
```

| Available Architecture | Description                                  |
| ---------------------- | -------------------------------------------- |
| `ohos-arm64`           | 64-bit ARM, default for real devices (recommended) |
| `ohos-arm`             | 32-bit ARM                                   |
| `ohos-x64`             | x86_64, for emulator scenarios               |

---

### Step 4: Impeller Rendering Engine Configuration

The Flutter OH platform currently supports two rendering modes, **Impeller** (Vulkan backend) and **Skia**, with Impeller enabled by default.

#### Configuration File Location

```text
ohos/entry/src/main/resources/base/profile/buildinfo.json5
```

#### Configuration Contents

```json5
{
  "string": [
    {
      "name": "enable_impeller",
      "value": "true"    // "true" enables Impeller; "false" switches to Skia
    }
  ]
}
```

| Value      | Rendering Engine    | Minimum Version      |
| ---------- | ------------------- | -------------------- |
| `"true"`   | Impeller (Vulkan)   | Flutter OH 3.22.0+   |
| `"false"`  | Skia                | Flutter OH 3.7.12+   |

> **Note**: After modifying this configuration, you must rebuild the project for the change to take effect; a hot reload alone will not switch the rendering engine.

#### Adapting Existing Projects

New projects have Impeller enabled by default. For an existing project, copy the `buildinfo.json5` file above to the corresponding path in your project and change the `value` field. If this configuration file is not added, Impeller is enabled by default.

---

### Step 5: Building with a Local Engine

To build the app with a self-compiled Flutter Engine, you must specify both the Engine artifact path and the Host Engine artifact path:

```bash
# Enter the project root directory to build
flutter build hap --target-platform ohos-arm64 --<debug|release|profile> [--local-engine=src/out/<engine-artifact-dir> --local-engine-host=src/out/<engine-host-dir>/]
```

| Argument               | Description                                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `--target-platform`    | Target platform                                                                                                               |
| `--local-engine`       | Engine build artifact name, relative to the `out/` directory of `--local-engine-src-path` (for example, `ohos_release_arm64`)  |
| `--local-engine-host`  | Host Engine build artifact name (for example, `host_release`). Inferred automatically by default; only specify it manually for cross-platform builds |

Engine artifact names for each build mode (actual names are subject to the Engine build output directory):

| Build Mode  | `--local-engine`     | `--local-engine-host` |
| ----------- | -------------------- | --------------------- |
| **debug**   | `ohos_debug_arm64`   | `host_debug`          |
| **profile** | `ohos_profile_arm64` | `host_profile`        |
| **release** | `ohos_release_arm64` | `host_release`        |

---

### Step 6: Install and Run

#### Discovering Devices

```bash
flutter devices
```

Example expected output:

```log
9CN0123608000xxx (mobile) • 9CN0123608000xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26
```

#### Installing the HAP Package

```bash
# Install on a specific device
hdc -t <device-id> install <hap file path>

# Example
hdc -t 9CN0123608000xxx install build/ohos/hap/entry-default-signed.hap
```

#### Running Directly

There is no need to build the HAP manually; you can run the app on a device directly with `flutter run`:

```bash
# Run in Debug mode
flutter run --debug -d <device-id>

# Run in Release mode
flutter run --release -d <device-id>

# Run with a local Engine
flutter run --debug \
  -d <device-id> \
  --local-engine=ohos_debug_arm64 \
  --local-engine-host=host_debug
```

#### Verifying the Build Result

1. Run `flutter devices`; an ohos device with the `ohos-arm64` architecture is expected to appear in the list.
2. Run `flutter build hap --debug`; the artifact `build/ohos/hap/entry-default-signed.hap` is expected to be generated without any errors.
3. After installing with `hdc install`, launch the app; the first frame is expected to render normally with no errors in the console.
