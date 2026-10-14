# Flutter OH Upgrade Guide

This upgrade guide applies to all OpenHarmony-adapted Flutter versions, helping developers complete version switching smoothly when upgrading, migrating, or maintaining a Flutter OH project. Follow the steps to perform the upgrade based on your current version and target version.

> ⚠️ **Important reminder**: Flutter OH **does not yet support the `flutter upgrade` command**. Running this command directly pulls the official Channel, which breaks the OpenHarmony-adapted environment and causes errors. Always use the `git clone` / `git checkout` approach described in this document to switch versions, and never use `flutter upgrade`.

---

## I. Version Overview

Released and maintained OpenHarmony-adapted versions. To obtain a stable version, it is recommended to check it out based on a version tag:

| Upstream community version | OpenHarmony-adapted stable version      | Version tag                                 |
| -------------------------- | --------------------------------------- | ------------------------------------------- |
| 3.41.9                     | 3.41.9-ohos-x.x.x                       | `3.41.10-ohos-x.x.x`                        |
| 3.35.7                     | 3.35.8-ohos-x.x.x                       | `3.35.8-ohos-X.X.X`                         |
| 3.27.4                     | 3.27.4-ohos-x.x.x                       | `3.27.5-ohos-X.X.X`                         |
| 3.22.0 / 3.22.3            | 3.22.0-ohos-x.x.x / 3.22.3-ohos 1.1.3   | `3.22.1-ohos-X.X.X` / `3.22.4-ohos-x.x.x`   |
| 3.7.12                     | 3.7.12-ohos-x.x.x                       | `3.7.12-ohos-X.X.X`                         |

> For the complete version evolution plan and branching strategy, see [Flutter-OH Version Evolution Planning and Branch Strategy](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md);

**Notes on SDK selection**

Flutter-OH is adapted for OpenHarmony based on specific version points of the upstream community Flutter. After adaptation, the version branches evolve independently, focusing on fixes and capability enhancements for the HarmonyOS side, and are not synchronized with subsequent upstream community releases.

- HarmonyOS development: use the OpenHarmony-adapted [flutter_flutter](https://gitcode.com/CPF-Flutter/flutter_flutter) SDK.
- To obtain the latest community fixes, the [upstream community Flutter SDK](https://docs.flutter.cn/) is recommended when developing for Android and iOS.

---

## II. Applicable Upgrade Scenarios

- **Minor version upgrade**: upgrading between adapted versions within the same Flutter OH major version (for example, 3.27.4-ohos-1.0.0 → 3.27.4-ohos-1.0.3)
- **Major version upgrade**: upgrading across Flutter OH major versions (for example, 3.22.0-ohos → 3.27.4-ohos)

---

## III. Pre-Upgrade Preparation

### 1. Environment checklist

- **Back up the project code and dependency configurations** (`pubspec.yaml`, `pubspec.lock`, and the entire project directory)
- **Confirm the environment required by the target version ([DevEco Studio](https://developer.huawei.com/consumer/cn/download/deveco-studio), [OpenHarmony SDK](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos))**
- **Read the [Release Note](https://docs.flutter.dev/release/release-notes) of the target version to learn about Breaking Changes and new features**
- **Check the [OpenHarmony compatibility](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md) of third-party libraries to confirm that the plugins you use support the target version**

### 2. Obtain the new version of the SDK

```shell
# Option 1: clone the specified branch
git clone -b {target-branch} https://gitcode.com/CPF-Flutter/flutter_flutter.git

# Option 2: check out the specified tag
git clone https://gitcode.com/CPF-Flutter/flutter_flutter.git
cd flutter_flutter
git checkout {version-tag}

# Example: obtain the br_3.27.4-ohos-1.0.4 version
git clone -b br_3.27.4-ohos-1.0.4 https://gitcode.com/CPF-Flutter/flutter_flutter.git
```

---

## IV. General Upgrade Process

### 1. Environment verification

```shell
# Verify the Flutter environment
flutter doctor -v

# Expected output:
# [✓] Flutter (Channel unknown, 3.27.4-ohos-xxx, ...)
# [✓] OpenHarmony toolchain - develop for OpenHarmony devices
```

### 2. Project upgrade steps

**Step 1: Clean up the old version cache**

```shell
# Enter the old project directory
cd your_project

# Clean the build cache
flutter clean

# Delete the global cache (recommended when switching major versions)
flutter pub cache clean

# Delete the Flutter SDK cache (if environment variables were switched)
rm -rf $FLUTTER_HOME/bin/cache
```

**Step 2: Update the SDK reference**

Make sure the subsequent commands are executed with the new version of the Flutter SDK:

```shell
# Verify the flutter version in use
flutter --version
```

**Step 3: Update project dependencies**

```shell
# Update the dependency versions in pubspec.yaml
# 1. Modify the SDK version constraint
# environment:
#   sdk: '>=3.0.0 <4.0.0'  # Adjust according to the target version

# 2. Update the third-party library versions

# 3. Fetch the dependencies
flutter pub get
```

**Step 4: OpenHarmony platform-specific adaptation**

```shell
# Regenerate the ohos platform code (if needed)
flutter create --platforms ohos .

# Open the ohos directory with DevEco Studio
# Signing: File → Project Structure → Project → Signing Configs
```

**Step 5: Build verification**

```shell
# Build the debug version
flutter build hap --debug

# Build the release version
flutter build hap --release

# Install to the device
hdc install build/ohos/entry/outputs/default/entry-default-signed.hap
```

---

## V. Upgrade Notes for Each Version

### 1. Minor version upgrade

> Upgrading within the same Flutter OH major version

A minor version upgrade usually only requires:

1. Pull the latest code or switch to the new tag
2. Run `flutter clean`
3. Run `flutter pub get`
4. Rebuild and verify

### 2. Major version upgrade

> Upgrading across Flutter OH major versions

- Check whether the environment configuration of the version you are upgrading to has changed
- Read the compatibility change notes of the upgrade version [[View]](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/oh-3.35.7-dev/release-notes/changelog)
- Read the new features and changes of the official Flutter version [[View]](https://docs.flutter.dev/release/breaking-changes)
- Upgrade third-party libraries to the corresponding versions [[View]](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md)

---

- Feedback: you are welcome to submit issues to the [Flutter framework repository](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) and to the various Flutter third-party libraries.
