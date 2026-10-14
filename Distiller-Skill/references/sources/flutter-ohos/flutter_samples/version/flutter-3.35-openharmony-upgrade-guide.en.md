# Flutter OH 3.35 Upgrade Guide

> **Document version**: 1.0.0-draft  
> **Applicable upgrade paths**: 3.7(dev) / 3.22.x / 3.27.x → 3.35.x  
> **Last updated**: 2026-06-01  
> **Target platform**: OpenHarmony API 12+

Flutter-ohos is an OpenHarmony-adapted version built on the Flutter SDK. This document is intended for developers building apps with the Flutter-ohos framework and provides complete guidance for upgrading from **3.7 (dev), 3.22.x, or 3.27.x** to **3.35.x**.

> **Tip**: Flutter-ohos is a third-party framework with no hard binding to the OpenHarmony system. The minimum runtime requirement is **OpenHarmony API 12+**.

---

## Upgrade Benefits Overview

Upgrading to Flutter 3.35 delivers **12 OpenHarmony-specific optimizations** plus new features from upstream Flutter 3.35. Developers starting from different versions will gain different amounts of new benefits.

### Version Gap Overview

For details on the branches/tags corresponding to each Flutter-ohos version, see [Flutter-OH Version Evolution Planning and Branch Strategy](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)

| Starting point | Versions crossed | Cumulative breaking changes | Migration difficulty |
|------|-----------|----------------------|---------|
| 3.7 → 3.35 | 9 versions (3.10/3.13/3.16/3.19/3.22/3.24/3.27/3.29/3.32) | ~45 items | **High** |
| 3.22 → 3.35 | 4 versions (3.24/3.27/3.29/3.32) | ~20 items | **Medium** |
| 3.27 → 3.35 | 3 versions (3.29/3.32/3.35) | ~16 items | **Medium-low** |

### Developer-Perceived Dimensions

| Dimension | Optimizations included | Developer perception | Benchmark data |
|------|-----------|-----------|---------------|
| **Smoother** | Impeller + dirty region rendering + occlusion culling + LTPO | More stable frame rates, lower GPU load | Rasterization time **reduced by ~13%** |
| **Lower power consumption** | LTPO + elimination of WebView background idling + skipping GPU display submission | Less wasted computation, lower power consumption | — |
| **Lower memory usage** | DMA release + VMA adjustment + reduced preloading | Substantially lower memory in the background | Graphics memory during the preloading stage reduced by **~40+MB** |
| **Faster startup** | Rendering pipeline preloading + BiSheng compilation | Faster first-frame response | — |
| **Faster loading** | Zero-copy images | Faster loading in image-heavy scenarios | 9-grid image loading completion time **reduced by 100ms** |

### New Benefits by Upgrade Path

| Optimization | 3.7→3.35 | 3.22→3.35 | 3.27→3.35 |
|--------|:--------:|:--------:|:--------:|
| Impeller rendering engine | **New** | Already available | Already available |
| Rendering pipeline preloading | **New** | Already available | Already available |
| Zero-copy image encoding/decoding | **New** | Already available (1.0.5) | Already available |
| BiSheng compiler optimization | **New** | **New** | **New** |
| Impeller occlusion culling | **New** | Already available (1.0.4) | Already available |
| Impeller dirty region rendering | **New** | Already available | Already available |
| Skip GPU display submission at zero dirty region | **New** | **New** | **New** |
| Eliminate WebView background idling | **New** | **New** | **New** |
| LTPO variable frame rate | **New** | **New** | **New** |
| Release DMA when going to the background | **New** | **New** | **New** |
| VMA memory block size adjustment | **New** | **New** | **New** |
| Reduced preloading memory (~40MB) | **New** | **New** | **New** |

- **3.7→3.35**: All 12 items are new benefits
- **3.22→3.35**: 5 already available + 7 new benefits
- **3.27→3.35**: 6 already available + 6 new benefits

### Details of the 12 Optimizations

**Performance optimizations (5 items)**:

| # | Optimization | Description | Source |
|---|--------|------|------|
| 1 | Impeller rendering engine | Vulkan backend replaces OpenGL ES; precompiled shaders + optimized caching eliminate jank | Introduced in 3.22+ |
| 2 | Rendering pipeline preloading | NativeImage offscreen rendering region; preloads FlutterEngine in advance to avoid first-frame overhead | Introduced in 3.22+ |
| 3 | Zero-copy image encoding/decoding | Image decoding uses system APIs that do not copy memory, speeding up image-heavy page loading | 3.22.1-ohos-1.0.5 |
| 4 | BiSheng compiler optimization | The BiSheng compiler optimizes the runtime speed of C++ object code and supports PGO | 3.22.1-ohos-1.1.1 |
| 5 | Impeller occlusion culling | Layer-level occlusion culling; skips rendering when a solid-color layer covers earlier elements | 3.22.1-ohos-1.0.4 |

**Workload optimizations (4 items)**:

| # | Optimization | Description | Source |
|---|--------|------|------|
| 6 | Impeller dirty region rendering | Repaints only the changed regions, using VK_KHR_incremental_present | Introduced in 3.22+ |
| 7 | Skip GPU display submission at zero dirty region | Skips rendering when no repaint is needed, reducing unnecessary GPU work | 3.22.1-ohos-1.1.1 |
| 8 | Eliminate WebView background idling | Pauses animation/texture refresh when the WebView is not visible and resumes automatically when it becomes visible again | 3.22.1-ohos-1.1.1 |
| 9 | LTPO variable frame rate | Dynamic frame rate control; avoids pointlessly ramping up to 120 fps after touch; enabled by default | 3.27.5-ohos-1.0.6 |

**Memory optimizations (3 items)**:

| # | Optimization | Description | Source |
|---|--------|------|------|
| 10 | Release DMA memory when going to the background | Calls TeardownOnScreenContext to release DMA buffers when the app goes to the background | 3.22.4-ohos-1.1.3 |
| 11 | VMA memory block size adjustment | Reduces the graphics memory allocation block size (perferredLargeHeapBlockSize), lowering memory usage | 3.22.1-ohos-1.1.1 |
| 12 | Reduced memory during the preloading stage | Graphics buffers reduced from 6 to 2, cutting graphics memory during the preloading stage by ~40+MB | 3.27.4-ohos-1.0.5 |

---

## 1. Pre-Upgrade Preparation

> **Core principle**: Backing up your work, confirming the current version, and pre-checking dependency compatibility before upgrading are the three key steps to a smooth upgrade.

### 1.1 Confirm the Current and Target Versions

Before starting the upgrade, confirm the Flutter-ohos SDK version you are currently using and the state of your project dependencies.

#### 1.1.1 Check the Flutter SDK Version

```bash
flutter --version
```

Example expected output:

```
Flutter 3.27.2-ohos • channel stable
Framework • revision xxxxxxxxxx (2024-12-01)
Engine • revision xxxxxxxxxx
Dart SDK version: 3.6.0
```

#### 1.1.2 Check Project Dependency Versions

```bash
cd your_project
cat pubspec.yaml | grep -A 5 dependencies
flutter pub outdated
```

> **Note**: `flutter pub outdated` lists all updatable dependency packages. Focus on whether there are version conflicts incompatible with 3.35.

### 1.2 Environment and Tool Requirements

#### 1.2.1 Hard Requirements

| Component | Minimum requirement | Description |
|-----------------|-------------------|------------|
| **OpenHarmony API** | API 12 | The device/emulator must support API 12 or later |
| **Flutter-ohos SDK** | 3.7 / 3.22 / 3.27 | The currently installed source version |
| **Git** | Any version | Used for branch switching or cloning |

#### 1.2.2 No Strict Version Requirements

As a third-party framework, Flutter-ohos has **no hard binding** to the underlying toolchain. The following tools can all be used within reasonable ranges:

| Tool | Version policy |
|-----------|---------------------------|
| DevEco Studio | No minimum version requirement; the latest stable version is recommended |
| hvigor | Managed automatically along with DevEco Studio |
| JDK | No specific version requirement |
| Node.js/npm | Only affects DevEco Studio plugins; no Flutter-related constraints |

> **Recommendation**: Although there is no hard version requirement, keep DevEco Studio reasonably up to date for better hvigor and OpenHarmony SDK support.

### 1.3 Choose an Upgrade Strategy and Back Up

Upgrading the Flutter-ohos SDK offers **two fundamentally different paths**, and the backup strategy differs depending on which one you choose. Decide on the upgrade option before backing up.

- **Option 1: Switch branches in the existing directory** — Run `git checkout` directly in the current SDK directory to switch to the 3.35 branch, then clean the cache and re-initialize. The old version is not retained (rollback is possible only through git history), and rolling back requires re-downloading the cache (~1-2GB).
- **Option 2: Download into a new directory** — Use `git clone` to download the 3.35 repository into a separate directory and configure a new PATH environment variable. The old SDK is **fully retained**; rolling back only requires switching PATH and takes effect immediately.

> **How to choose**: Few team projects, limited disk space, and a team-wide agreement to upgrade in sync → **choose Option 1**. Multiple pilot projects in parallel, inconsistent upgrade pacing across projects, or concerns about upgrade risk → **choose Option 2**.
>
> For the core differences between the two options, detailed steps, and rollback plans, see **Chapter 2 Environment Upgrade**.

#### 1.3.1 Back Up Project Code (required for both options)

It is **strongly recommended** that you commit your project code to a version control system (such as Git) before upgrading:

```bash
cd your_project
git add -A
git commit -m "backup: pre-upgrade to Flutter 3.35"
```

> Project code is the only asset that may be modified during the upgrade; version control is the last line of defense for rollback.

#### 1.3.2 SDK Backup for Option 1 (perform before switching branches)

Option 1 modifies the existing SDK directory directly. Before upgrading, make sure the following information is backed up:

```bash
cd $FLUTTER_ROOT

# Record the current branch name
git branch --show-current > ~/flutter_backup_branch.txt

# Record the current commit hash (for precise rollback)
git rev-parse HEAD > ~/flutter_backup_commit.txt

# Check uncommitted local changes (if any)
git status
```

> **Key reminder**: Rolling back from Option 1 requires re-downloading `bin/cache` (~1-2GB), which takes a long time. If you are concerned about upgrade risk, choose Option 2 directly.

#### 1.3.3 SDK Backup for Option 2 (optional)

Option 2 downloads 3.35 into a separate directory via `git clone`, leaving the existing SDK **completely unaffected**, so no extra backup is needed. Just make sure you remember the current SDK path so you can restore PATH if necessary:

```bash
# Record the current Flutter SDK path
echo $FLUTTER_ROOT > ~/flutter_backup_path.txt
```

### 1.4 Third-Party Library Compatibility Pre-Check

Before upgrading, make sure the third-party libraries your project depends on have been adapted for version 3.35.

#### 1.4.1 Consult the Official Compatibility List

Visit [Flutter-ohos third-party library verification progress](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md) to check the adaptation status of each plugin.

#### 1.4.2 Check Dependencies in pubspec.yaml

```yaml
# pubspec.yaml example
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.4.0    # Verify whether it supports 3.35
  video_player: ^2.8.0       # Verify whether it supports 3.35
  dio: ^5.4.0                # Pure Dart library, usually compatible out of the box
```

#### 1.4.3 Compatibility Checklist

| Check item | Action | Status |
|-------------------|-------------|-------------|
| Consult the third-party library verification progress document | Visit the link above | ☐ To check |
| Confirm platform plugins (with native code) | Check whether an ohos implementation exists | ☐ To check |
| Pure Dart libraries | Usually compatible out of the box; no changes needed | ☐ Confirmed |
| v1 embedding plugins | v1 was removed in 3.29; upgrade to v2 required | ☐ To check |
| In-house plugins | Check whether they use the v1 embedding | ☐ To check |

> **Tip**: Pure Dart packages (such as `dio`, `provider`, and `bloc`) do not involve platform native code and are usually compatible across Flutter versions out of the box.

---

## 2. Environment Upgrade

Upgrading the Flutter-ohos SDK offers **two fundamentally different paths**. Choose the one that best fits your situation.

> ⚠️ **Important**: Flutter OH **does not yet support the `flutter upgrade` command**. Running it will pull from the official Flutter channel, break the OpenHarmony-adapted environment, and cause errors. Always use the `git clone` / `git checkout` approach described below for version switching. Do **not** use `flutter upgrade`.

### 2.1 Upgrade Option Comparison

| Dimension | Option 1: Switch branches in the existing directory | Option 2: Download into a new directory |
|----------------|-------------|-------------|
| **Core operation** | `git checkout` to switch branches + clean the cache | `git clone` into a new directory + change PATH |
| **Old version retention** | Not retained (recoverable via git) | Fully retained |
| **Disk usage** | Low (Git reuses objects) | High (two SDK copies) |
| **PATH change** | No modification needed | Must be modified |
| **Rollback speed** | Slow (requires branch switch + cache re-download) | Fast (just change PATH) |
| **Applicable scenarios** | Team-wide upgrade, few projects | Multi-project pilots, long-term maintenance of the old version |

### 2.2 Option 1: Switch Branches in the Existing SDK Directory

#### Applicable scenarios

- Only 1-2 projects, all willing to upgrade in sync
- Limited disk space that cannot hold two SDK copies
- The team has agreed that everyone upgrades at the same time

#### Steps

```bash
# Step 1: Confirm the current branch
cd $FLUTTER_ROOT
git branch
git status

# Step 2: Fetch remote branches
git fetch origin

# Step 3: Switch to the target branch (replace the branch name with the actually released 3.35 branch)
git checkout 3.35.x-ohos
# Or create a local tracking branch
git checkout -b 3.35.x-ohos origin/3.35.x-ohos

# Step 4: Force-clean the cache (critical!)
rm -rf bin/cache

# Step 5: Re-initialize the environment
flutter doctor
# This command automatically downloads the Dart SDK, engine artifacts, and flutter_tools dependencies

# Step 6: Verify the version
flutter --version
```

> ⚠️ **Warning**: `bin/cache` contains the version-bound Dart SDK and engine artifacts. It **must be deleted**; leftover files will cause bizarre errors (such as "Wrong full snapshot version").

#### Rollback plan

```bash
cd $FLUTTER_ROOT
git checkout dev              # or 3.27.2-ohos / 3.22.5-ohos
rm -rf bin/cache
flutter doctor                # Re-initialize the old version environment
```

### 2.3 Option 2: Download 3.35 into a New Directory

#### Applicable scenarios

- Multiple projects, with upgrades to be verified one by one
- Need to maintain the old and new versions in parallel
- Significant concern about upgrade risk, requiring rollback to be available at any time

#### Steps

```bash
# Step 1: Clone the new version into a separate directory (replace the branch name with the actually released 3.35 branch)
git clone -b 3.35.x-ohos \
  https://gitcode.com/CPF-Flutter/flutter_flutter.git \
  ~/flutter_ohos_3.35

# Step 2: Configure environment variables
export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com
export PATH=~/flutter_ohos_3.35/bin:$PATH

# Step 3: Verify the path
which flutter
flutter --version

# Step 4: Initialize the environment
flutter doctor
```

#### Tips for multi-version coexistence

Switch versions quickly with shell aliases:

```bash
# Add to ~/.bashrc / ~/.zshrc
alias flutter37='export PATH=/opt/flutter_ohos_dev/bin:$PATH && flutter --version'
alias flutter322='export PATH=/opt/flutter_ohos_322/bin:$PATH && flutter --version'
alias flutter327='export PATH=/opt/flutter_ohos_327/bin:$PATH && flutter --version'
alias flutter335='export PATH=/opt/flutter_ohos_335/bin:$PATH && flutter --version'
```

#### Rollback plan

```bash
# Option A: Roll back in the current terminal
export PATH=/opt/flutter_ohos_327/bin:$PATH
flutter --version  # Confirm the rollback

# Option B: Delete the new version
rm -rf ~/flutter_ohos_3.35
```

### 2.4 Configure FLUTTER_STORAGE_BASE_URL

Regardless of which option you choose, you must configure the Huawei Cloud mirror URL after upgrading:

```bash
export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com
```

Add it to `~/.bashrc` or `~/.zshrc` to make it persistent:

```bash
echo 'export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com' >> ~/.bashrc
source ~/.bashrc
```

### 2.5 Cache Cleanup and Project Rebuild

Regardless of the upgrade option, the following steps are **mandatory**:

```bash
# 1. Project-level cleanup (perform for each project)
cd your_project
flutter clean                 # Deletes build/ and .dart_tool/
rm -rf .ohos                  # Deletes the ohos build artifacts
flutter pub get               # Re-downloads dependencies

# 2. SDK-level cleanup (for those who upgraded via Option 1)
rm -rf $FLUTTER_ROOT/bin/cache

# 3. Fully restart DevEco Studio
# The IDE may cache the old SDK path; make sure to restart
```

### 2.6 Verify the Installation

```bash
flutter --version             # Confirm the version is 3.35.x-ohos
flutter doctor                # Confirm there are no errors/warnings
flutter devices               # Confirm OpenHarmony devices can be detected
```

Build verification:

```bash
cd your_project
flutter build hap --debug     # Verify the debug build
```

---

## 3. Project Configuration Migration

> **Core principle**: Flutter 3.35 brings not only framework-level changes but also updates to project configuration files. Check each of the following configurations to ensure compatibility with the target version.

### 3.1 pubspec.yaml Changes

#### 3.1.1 SDK Constraint Update

Update the Flutter SDK constraint in `pubspec.yaml` to 3.35:

```yaml
# Before upgrade
environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: ">=3.27.0"

# After upgrade
environment:
  sdk: '>=3.9.0 <4.0.0'
  flutter: ">=3.35.0"
```

> **Note**: The Dart SDK version moves from 3.6 (3.27) to 3.9 (3.35); update the constraint accordingly.

#### 3.1.2 Dependency Version Check

```bash
flutter pub outdated
```

Based on the output, update dependency packages that have version conflicts.

#### 3.1.3 Compatibility of Pure Dart Packages

Pure Dart packages (without `android/`, `ios/`, or `ohos/` directories) are usually **compatible out of the box**:

```yaml
# Usually no changes needed
dependencies:
  dio: ^5.4.0
  provider: ^6.1.0
  bloc: ^8.1.0
```

### 3.2 analysis_options.yaml Changes

If your project uses a custom `analysis_options.yaml`, you may need to update the rules for Dart 3.9:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
```

### 3.3 Android Configuration Migration

#### 3.3.1 Default abiFilters Setting (3.35 Breaking Change)

Starting with Flutter 3.35, `abiFilters` is set by default in Android builds. If your project has a custom configuration, check for conflicts:

```gradle
// android/app/build.gradle
android {
    defaultConfig {
        ndk {
            // Set by default in 3.35; declare explicitly to override
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
}
```

> **Impact**: Most OpenHarmony developers do not modify Android configuration directly; this change usually takes effect automatically.

### 3.4 OpenHarmony Configuration Migration

#### 3.4.1 build-profile.json5

Check and update `ohos/build-profile.json5`:

```json5
{
  "app": {
    "signingConfigs": [],
    "compileSdkVersion": 12,          // Ensure >= 12
    "compatibleSdkVersion": "5.0.0",
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "buildModeSet": [             // Required for profile mode
          "debug",
          "profile",
          "release"
        ]
      }
    ]
  }
}
```

> **Note**: The `buildModeSet` field must be declared when compiling in profile mode; otherwise you will hit the `Build mode 'profile' is not declared` error.

#### 3.4.2 oh-package.json5

Check that the aliases of dependency packages are consistent:

```json5
{
  "dependencies": {
    "@ohos/flutter_ohos": "har/flutter.har",
    "@ohos/flutter_module": "har/flutter_module.har"
  },
  "overrides": {
    "@ohos/flutter_ohos": "har/flutter.har"
  }
}
```

> **Compatibility tip**: If `oh-package.json5` reports errors after the upgrade, check whether the aliases match the `name` field inside the HAR packages.

#### 3.4.3 module.json5

Usually no modification is needed, but confirm that `deviceTypes` includes the target device types:

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["phone", "tablet"]
  }
}
```

## 4. Code Migration Guide

> **Core principle**: Code migration is the core of the upgrade. Run `dart fix --apply` first for automatic fixes, then handle the remaining breaking changes manually.

### 4.1 Automated Migration: dart fix

```bash
cd your_project
flutter pub get
dart fix --apply          # Automatically fixes about 60-80% of simple migrations
flutter analyze           # Check the remaining issues
```

### 4.2 Migration Checklists by Starting Version

#### From 3.27 → 3.35 (smallest span)

| Priority | Breaking Change | Scope of impact | Migration approach |
|:------:|----------------|---------|---------|
| 🔴 P0 | Removal of the v1 Android Embedding (3.29) | Plugins with native code | Migrate to v2 manually |
| 🔴 P0 | `Radio` redesign (3.35) | All radio button UIs | Replace with `RadioGroup` |
| 🟡 P1 | `Form` no longer supports slivers (3.35) | `CustomScrollView` + `Form` | Wrap with `SliverToBoxAdapter` |
| 🟡 P1 | Theme normalization updates (3.35) | Custom theme code | Adjust to the new APIs |
| 🟢 P2 | `DropdownButtonFormField.value` → `initialValue` | Dropdown forms | Rename the parameter |

#### From 3.22 → 3.35 (medium span)

In addition to the above, pay attention to:

| Priority | Breaking Change | Scope of impact | Migration approach |
|:------:|----------------|---------|---------|
| 🔴 P0 | Color wide gamut support (3.27) | Color handling code | `.opacity` → `.a` |
| 🔴 P0 | `SystemUiMode` defaults to Edge-to-Edge (3.27) | Full screen/status bar | Set the mode explicitly |
| 🟡 P1 | `InputDecoration.collapsed` parameter cleanup | Input field styling | Remove invalid parameters |
| 🟢 P2 | `.flutter-plugins` → `.flutter-plugins-dependencies` | CI scripts | Update file references |

#### From 3.7 → 3.35 (largest span)

In addition to the above, pay attention to:

| Priority | Breaking Change | Scope of impact | Migration approach |
|:------:|----------------|---------|---------|
| 🔴 P0 | `MaterialState` → `WidgetState` (3.22) | All custom interactive widgets | Global replacement |
| 🔴 P0 | Removal of APIs deprecated before v3.19 (3.22) | Legacy codebases | Fix item by item |
| 🟡 P1 | `PageView.controller` is now nullable | Code using PageView | Add null checks |
| 🟡 P1 | `MemoryAllocations` → `FlutterMemoryAllocations` | Memory monitoring | Rename |
| 🟢 P2 | Deep links flag change (3.27) | Deep linking | Adjust to the new API |

### 4.3 Detailed Migration for Key Breaking Changes

#### 4.3.1 MaterialState → WidgetState (3.22)

**Impact**: All custom buttons and interactive widgets that use `MaterialState`.

```dart
// Before upgrade
MaterialButton(
  style: ButtonStyle(
    backgroundColor: MaterialStateProperty.all(Colors.blue),
  ),
)

// After upgrade
MaterialButton(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.all(Colors.blue),  // ← replace
  ),
)
```

**Batch replacement command**:

```bash
grep -rl "MaterialState" lib/ | xargs sed -i 's/MaterialState/WidgetState/g'
```

#### 4.3.2 Color Wide Gamut API Migration (3.27)

```dart
// Before upgrade
Color myColor = Colors.red;
double alpha = myColor.opacity;
Color faded = myColor.withOpacity(0.5);

// After upgrade
Color myColor = Colors.red;
double alpha = myColor.a;                          // ← .opacity → .a
Color faded = myColor.withValues(alpha: 0.5);      // ← withOpacity() → withValues()
```

#### 4.3.3 Removal of the v1 Android Embedding (3.29)

**How to check**:

```bash
grep -r "io.flutter.embedding.android.FlutterActivity" android/
grep -r "PluginRegistry.Registrar" android/
```

**Migration direction**: Migrate `FlutterActivity` to `FlutterFragmentActivity`, and `PluginRegistry.Registrar` to the `FlutterPlugin` interface.

> **OpenHarmony special reminder**: Some ohos plugins may reuse Android v1 embedding code. After upgrading, check whether the plugin source code has been adapted to v2.

#### 4.3.4 Radio Redesign (3.35)

```dart
// Before upgrade
Radio<int>(
  value: 1,
  groupValue: selectedValue,
  onChanged: (value) => setState(() => selectedValue = value),
)

// After upgrade
RadioGroup<int>(
  value: selectedValue,
  onChanged: (value) => setState(() => selectedValue = value),
  child: Radio<int>(value: 1),
)
```

#### 4.3.5 The Form Widget No Longer Supports Slivers (3.35)

```dart
// Before upgrade (will produce an error)
CustomScrollView(
  slivers: [
    Form(child: SliverList(...)),
  ],
)

// After upgrade
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(
      child: Form(child: ...),
    ),
  ],
)
```

#### 4.3.6 DropdownButtonFormField Parameter Rename (3.35)

```dart
// Before upgrade
DropdownButtonFormField(
  value: selectedItem,
  onChanged: (value) {},
)

// After upgrade
DropdownButtonFormField(
  initialValue: selectedItem,
  onChanged: (value) {},
)
```

#### 4.3.7 Theme Normalization Updates (3.35)

```dart
// Before upgrade
AppBarTheme(color: Colors.blue)

// After upgrade
AppBarTheme(backgroundColor: Colors.blue)
```

### 4.4 Post-Migration Verification

```bash
flutter analyze
flutter format --set-exit-if-changed lib/
flutter test
flutter build hap --debug
flutter build hap --profile
flutter build hap --release
```

---

## 5. Plugin and Dependency Adaptation

### 5.1 Third-Party Library Compatibility Check

Visit [Flutter-ohos third-party library verification progress](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md) to check the adaptation status.

**Quick self-check**:

```bash
# List all dependencies that contain platform code
flutter pub deps --style tree | grep -E "android|ios|ohos"
```

### 5.2 Upgrading In-House Plugins

#### Migrating from the v1 Android Embedding to v2

**Characteristics of v1 code**:

```java
public class MyPlugin implements PluginRegistry.Registrar {
    public static void registerWith(Registrar registrar) { }
}
```

**After migrating to v2**:

```java
public class MyPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) { }
    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) { }
}
```

#### OpenHarmony Plugin Structure Check

Check the ohos directory structure of your in-house plugins:

```
my_plugin/
├── lib/
├── ohos/
│   └── src/main/ets/
│       └── MyPlugin.ets
├── pubspec.yaml
```

> If `module.json5` or `build-profile.json5` is missing, `flutter pub get` may report errors.

### 5.3 Common Plugin Migration Example

#### Platform Channel Code Example

```typescript
// ohos/src/main/ets/MyPlugin.ets
import { MethodChannel } from '@ohos/flutter_ohos';

export default class MyPlugin {
  attachToEngine(binding: FlutterPluginBinding) {
    const channel = new MethodChannel(
      binding.getBinaryMessenger(),
      'my_plugin/channel'
    );
    channel.setMethodCallHandler((call, result) => {
      if (call.method === 'getBatteryLevel') {
        result.success(this.getBatteryLevel());
      } else {
        result.notImplemented();
      }
    });
  }
}
```

### 5.4 Resolving Dependency Conflicts

```bash
flutter pub get
flutter pub deps --style tree
```

Temporary conflict resolution:

```yaml
dependency_overrides:
  some_plugin: ^2.0.0
```

> **Warning**: `dependency_overrides` is for temporary debugging only. The long-term solution is to upgrade the main dependency or wait for the plugin author to release a compatible version.

---

## 6. Build and Verification

### 6.1 Verifying the Three Build Modes

#### Debug mode

```bash
flutter clean
flutter pub get
flutter build hap --debug
```

#### Profile mode

```bash
flutter build hap --profile
```

> Prerequisite: `profile` mode has been declared in `ohos/build-profile.json5` (see 3.4.1).

#### Release mode

```bash
flutter build hap --release
```

### 6.2 Flutter Module Scenario (HAR Build)

```bash
flutter build har --debug
flutter build har --profile
flutter build har --release
```

**Artifact locations**:

| Artifact | Path |
|-----|------|
| `flutter.har` | `.ohos/har/flutter.har` |
| `flutter_module.har` | `.ohos/har/flutter_module.har` |

### 6.3 Smoke Test Checklist

| Test item | Test method | Pass criteria |
|-------|---------|---------|
| Startup test | Cold-start the app | The first frame is rendered within the expected time |
| Page navigation | Navigate to the main pages | No crashes, no white screens |
| List scrolling | Fast-swipe a long list | No obvious jank or frame dropping |
| Image loading | Open an image-intensive page | Images display normally, no OOM |
| Input test | Type in a text field and bring up the soft keyboard | Input works and the keyboard does not block the view |
| Back gesture | System back / side-swipe back | The page returns normally with no exceptions |
| Background restore | Send the app to the background and restore it | State is restored correctly, no crash |
| WebView | Open a page containing a WebView | Content loads normally |

### 6.4 Performance Regression Testing Recommendations

Compare the following metrics before and after the upgrade:

| Metric | Test tool | Test method |
|-----|---------|---------|
| Startup time to first frame | Systrace / custom instrumentation | Record the time from `onCreate` to the first frame |
| Average FPS | DevTools Performance | Scroll the core pages for 30 seconds |
| PSS memory | `hidumper` | Sample 5 minutes after startup |
| Background memory | `hidumper` | Sample 1 minute after going to the background |
| App package size | `ls -lh` | Compare release HAP sizes |

> **Known performance improvements (benchmark-verified)**:
> - Half-screen popup with image waterfall: rasterization time down **~13%**, frame build time unchanged
> - 9-grid image page: page load completion time reduced by **100ms**
> - 3.35 preloading memory optimization: graphics buffers 6→2, saving **~40MB**

---

## 7. FAQ and Troubleshooting

### 7.1 Compilation Error Quick Reference

| Error message | Possible cause | Solution |
|---------|---------|---------|
| `Wrong full snapshot version` | Old version left over in `bin/cache` | `rm -rf $FLUTTER_ROOT/bin/cache` |
| `The SDK license agreement is not accepted` | The OHOS SDK license has not been accepted | Run `ohsdkmgr` to accept the license |
| `Build mode 'profile' is not declared` | `build-profile.json5` is missing `profile` | Add `"profile"` to `buildModeSet` |
| `Can not found module.json5` | Incomplete ohos directory structure in the plugin | Check whether the plugin has been adapted for the ohos platform |
| `Schema validate failed` (hvigor) | `srcPath` format does not match the schema | Check the path configuration in `build-profile.json5` |
| `flutter command not found` | Incorrect PATH configuration | Confirm that the `flutter` executable path is in PATH |

### 7.2 Runtime Exception Troubleshooting

| Symptom | Possible cause | Troubleshooting steps |
|---------|---------|---------|
| White screen/black screen | Impeller incompatibility / emulator limitations | Try `--no-enable-impeller`; confirm the device supports Vulkan |
| Crash at startup | Engine version mismatch / leftover cache | Run `flutter clean` + delete `bin/cache` |
| Out-of-memory (OOM) | Images not released / memory leaks | Analyze with DevTools Memory; limit the ImageCache size |
| Severe frame dropping | Complex widget rebuilds / missing `const` | Locate the issue with the Performance Overlay; add `const` constructors |

### 7.3 DevEco Studio Issues

| Issue | Solution |
|-----|---------|
| The IDE cannot recognize the Flutter SDK | Restart DevEco Studio; check the Flutter SDK path configuration |
| Emulator white screen | The emulator only supports Mac (arm64) and does not yet support Vulkan; test on a real device |
| `hvigor` build failure | Check the `~/.npmrc` configuration; confirm the hvigor version matches DevEco Studio |
| Signing failure | Check the signing configuration; debug builds require developer mode to be enabled or a switch to formal signing |

### 7.4 Universal Cache Cleanup Formula

```bash
# 1. Project-level cleanup
flutter clean
rm -rf .ohos

# 2. SDK-level cleanup (for those who upgraded via Option 1)
rm -rf $FLUTTER_ROOT/bin/cache

# 3. Re-initialize
flutter pub get
flutter build hap --debug
```

### 7.5 Rollback Plans

#### Rollback for Option 1 upgraders

```bash
cd $FLUTTER_ROOT
git checkout dev          # or 3.27.2-ohos / 3.22.5-ohos
rm -rf bin/cache
flutter doctor
```

#### Rollback for Option 2 upgraders

```bash
export PATH=/opt/flutter_ohos_327/bin:$PATH
flutter --version
```

---

## Appendix A: Version Mapping Table

| Flutter-ohos version | Upstream Flutter version | Dart SDK version | Key features |
|------------------|----------------|--------------|---------|
| 3.7 (dev) | ~3.7 | ~3.3 | Early adaptation version |
| 3.22.x-ohos | 3.22.x | 3.4 | Impeller introduction, rendering pipeline preloading |
| 3.27.x-ohos | 3.27.x | 3.6 | Color wide gamut, VMA memory optimization |
| **3.35.x-ohos** | **3.35.x** | **3.9** | **40MB preloading memory reduction, most complete optimization matrix** |

---

## Appendix B: Complete Breaking Changes Index

### Released in Flutter 3.35

| Change | Affected code | Migration approach |
|--------|--------------|-----------|
| Component theme normalization | `AppBarTheme.color` | Use `backgroundColor` |
| Deprecate `DropdownButtonFormField.value` | `DropdownButtonFormField` | Replace with `initialValue` |
| Redesigned `Radio` widget | `Radio`, `RadioListTile` | Use `RadioGroup` |
| `Form` no longer supports sliver | `Form` in `CustomScrollView` | Wrap with `SliverToBoxAdapter` |
| Default `abiFilters` in Android | `android/app/build.gradle` | Takes effect automatically |
| `$FLUTTER_ROOT/version` moved | Scripts that read the version file | Use `bin/cache/flutter.version.json` |

### Released in Flutter 3.32

| Change | Affected code | Migration approach |
|--------|--------------|-----------|
| `.flutter-plugins-dependencies` replaces `.flutter-plugins` | CI scripts | Update file references |
| Localized messages to source | `flutter_gen` package | Remove `flutter_gen` from `analysis_options.yaml` |

### Released in Flutter 3.29

| Change | Affected code | Migration approach |
|--------|--------------|-----------|
| Removal of v1 Android Embedding | Plugins with native code | Migrate to the v2 Embedding |

### Released in Flutter 3.27

| Change | Affected code | Migration approach |
|--------|--------------|-----------|
| Color wide gamut support | `Color.opacity`, `withOpacity()` | Use `.a`, `withValues()` |
| `SystemUiMode` default Edge-to-Edge | Full-screen apps | Set `SystemUiMode` explicitly |

### Released in Flutter 3.22

| Change | Affected code | Migration approach |
|--------|--------------|-----------|
| `MaterialState` → `WidgetState` | All interactive widgets | Global replacement |

---

## Appendix C: Reference Resources

| Resource | Link |
|-----|------|
| Flutter-ohos official repository | https://gitcode.com/CPF-Flutter/flutter_flutter |
| Flutter 3.35 Release Notes | https://docs.flutter.dev/release/release-notes/release-notes-3.35.0 |
| Flutter Breaking Changes | https://docs.flutter.dev/release/breaking-changes |
| Flutter-ohos third-party library verification progress | https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md |
| OHOS hybrid development Module documentation | https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/hybrid-development/using-module.md |
| Flutter Engine ohos branch | https://gitcode.com/CPF-Flutter/flutter_engine |

---

> **End of document**
>
> If you have questions, submit feedback in [flutter_flutter Issues](https://gitcode.com/CPF-Flutter/flutter_flutter/issues).
