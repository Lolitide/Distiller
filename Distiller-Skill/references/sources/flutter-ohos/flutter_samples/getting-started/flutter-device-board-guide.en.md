# Flutter OH Development Board Running Guide

This guide describes how to run a Flutter OH project on an OpenHarmony development board (such as the Runhe Dayu HH-SCDAYU200, CPU: RK3568). The current Flutter OH cloud artifacts provide only 64-bit so packages, while the development board's daily-build image is a 32-bit system package, so 32-bit Flutter har packages are required. Because Flutter currently **does not support 32-bit har packages**, the content of this guide is for verification purposes only; to actually run on a development board, build the 32-bit artifacts locally.

## Prerequisites

- The development environment has been configured as described in the [Flutter OH Development Environment Setup Guide](./flutter-oh-env-setup.en.md).
- An OpenHarmony development board (such as the Runhe Dayu HH-SCDAYU200 2GB+32GB, CPU: RK3568) and a USB cable have been prepared.
- The OpenHarmony system image (version 6.0) has been flashed onto the development board.

## Environment Information

| Item | Version / Model |
| --- | --- |
| Flutter version | 3.7.12-ohos-1.1.7 |
| Development board model | Runhe Dayu series HH-SCDAYU200 2GB+32GB, CPU: RK3568 |
| Development board system image version | 6.0 |
| Daily build address | [Daily Build | OpenHarmony CI](https://dcp.openharmony.cn/workbench/cicd/dailybuild/dailylist) |

> [!WARNING]
> The daily builds currently available for the development board include only historical versions, and the currently flashable version is a **32-bit system package**, so a **32-bit Flutter har package** is required.
>
> This document is for verification purposes only, because Flutter currently **does not support 32-bit har packages**. If you are interested, you can set up a local environment and compile by yourself. See the "[Self-Compiled Engine (Optional)](#self-compiled-engine-optional)" section below.

---

## Steps

### Step 1: Install Flutter OH Version 3.7

- Version used: flutter 3.7
- Download address: [flutter_flutter 3.7](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/dev)

### Step 2: Download the Daily-Build Image and Flash Version 6.0

- For the flashing tutorial, see: [Flashing Tutorial](https://blog.csdn.net/dengjin20104042056/article/details/148291131)

### Step 3: Modify the Sandbox Files (Optional)

- If the development board has `64-bit lib64`, you need to modify the sandbox files (the currently flashed development board system does not have it, so no modification is required).
- Reference document: [OpenHarmony Device Running Guide](./openharmony-device-guide.en.md)

### Step 4: Replace the 32-Bit so Packages

The so packages in the current Flutter OH cloud artifacts are **64-bit**. If the development board is **32-bit**, you need to use **32-bit so packages**.

**32-bit package for version 3.7**: Use the **har package** in the compressed file to replace the har package under the corresponding path.

[Compiled har packages](https://gitcode.com/lx123546879/flutter_engine_arm_3_7/tree/3.7.12-ohos-1.0.0/har32)

![Compiled har package download page](../media/rendering-engine/rendering-engine-02.png)

### Step 5: Create a Flutter Demo and Adjust the Configuration

Use the following command to create a simple demo:

```bash
# 1. Create the Flutter demo project
flutter create <projectName>
```

Modify some configuration files:

![Modify the configuration files](../media/rendering-engine/rendering-engine-04.png)

Change the value of the `HarmonyOS` field to `OpenHarmony`:

![Modify the HarmonyOS field](../media/rendering-engine/rendering-engine-05.png)

Build command:

```bash
# 1. Build the HAP package (debug version)
flutter build hap --debug
```

Manually add try-catch or comment out some code (depending on the actual situation):

![Add try-catch](../media/rendering-engine/rendering-engine-06.png)

Use **DevEco Studio** to connect to the development board and click Run.

> [!WARNING]
>
> Flutter currently does not support 32-bit har packages; this is for verification purposes only.
> You can set up a local environment and compile by yourself. See the "[Self-Compiled Engine (Optional)](#self-compiled-engine-optional)" section below.

---

## Self-Compiled Engine (Optional)

To actually run a 32-bit Flutter application on a development board, it is recommended to directly use the following PR: pick it onto your local engine and build the local 32-bit artifacts yourself.

- PR address: [flutter 3.7 arm support](https://gitcode.com/hezySign/flutter_engine/tree/arm_support_3.7)
- Build command:

```bash
# 1. Build the arm-architecture engine artifacts
./ohos -t debug --ohos-cpu arm
```

> For version 3.7, after directly modifying the patch file, you need to run `gclient sync -f` and then build the engine artifacts.

### Main Changes

1. Changed the target architecture in cflags and ldflags to arm
2. Modified the arm condition checks to resolve errors
3. Added a patch file to automatically apply patches during the sync/build process
4. Added fallback logic for the arm32 cross-build (using an empty snapshot as a placeholder) to bypass Dart JIT word-length mismatches
5. Added some try-catch blocks to resolve some runtime errors
6. Added some macros for log-printing compatibility to avoid compilation warnings or failures caused by `int64_t` format specifier differences
7. Added gn_args handling for ohos
8. For the specific changes, see the PR: [flutter_engine modification PR](https://gitcode.com/hezySign/flutter_engine/commit/2ac8d8336899ac31594db8a7b5aa4565cdbf9564?ref=arm_support_3.7)
