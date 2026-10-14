# Analyzing Flutter-Related CppCrash Stacks

This article describes how to analyze crash stacks related to `libflutter.so` in the OpenHarmony-ized version of Flutter.

## 1. Introduction

The **llvm-addr2line** tool converts instruction addresses and executable images into file names, function names, and source code line numbers. It is generally applicable to .so libraries that contain symbol information.

## 2. Tool Location

This tool is available under the SDK directory of **DevEco Studio** and **Command Line Tools for OpenHarmony**. The corresponding paths are:

- Windows: sdk/default/openharmony/native/llvm/bin/llvm-addr2line.exe
- Linux/Mac: sdk/default/openharmony/native/llvm/bin/llvm-addr2line

You can add the directory of llvm-addr2line to the PATH environment variable, for example:

```sh
export PATH=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/llvm/bin:$PATH
```

## 3. Usage Command

```sh
llvm-addr2line -f -e so.unstripped/libflutter.so [addr1] [addr2]
```

## 4. How to Obtain the libflutter.so File with Symbols

#### 4.1 Use Locally Built Engine Artifacts

- Debug version
  - src/out/ohos_debug_unopt_arm64/so.unstripped/libflutter.so
- Release version
  - src/out/ohos_release_arm64/so.unstripped/libflutter.so
- Profile version
  - src/out/ohos_profile_arm64/so.unstripped/libflutter.so

#### 4.2 Download from Cloud Artifacts

- In the `flutter_flutter` version you are using, find the commit ID of the `flutter_engine` version being used.
  - It is in the file `flutter_flutter/bin/internal/engine.ohos.har.version`.
- Based on the commit ID 8ef94277f0029e61ff6a96f630d0f10b60330cd8, download the zip file of the corresponding version of libflutter.so
  - Debug version: https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/8ef94277f0029e61ff6a96f630d0f10b60330cd8/ohos-arm64/symbols.zip
  - Release version: https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/8ef94277f0029e61ff6a96f630d0f10b60330cd8/ohos-arm64-release/symbols.zip
  - Profile version: https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/8ef94277f0029e61ff6a96f630d0f10b60330cd8/ohos-arm64-profile/symbols.zip

## 5. Usage Example

Part of the crash log related to libflutter.so:

```log
#00 pc 00000000001b5a34 /system/lib/ld-musl-aarch64.so.1(__timedwait_cp+188)(ef860a9c8bd64e964a4dd4ef838876e1)
#01 pc 00000000001b7a3c /system/lib/ld-musl-aarch64.so.1(__pthread_cond_timedwait+188)(ef860a9c8bd64e964a4dd4ef838876e1)
#02 pc 000000000021d450 /data/storage/el1/bundle/libs/arm64/libflutter.so(85c51e03a4f191b946582701e79e1be4a0c83959)
#03 pc 00000000001f21f4 /data/storage/el1/bundle/libs/arm64/libflutter.so(85c51e03a4f191b946582701e79e1be4a0c83959)
```

With the `so.unstripped/libflutter.so` file that contains symbols, you can convert the addresses in the error stack into specific lines of code.

Run the command:

```sh
llvm-addr2line -f -e so.unstripped/libflutter.so 00000000001b5a34 00000000001b7a3c 000000000021d450 00000000001f21f4
```

Parsed result:

```log
_ZNSt21_LIBCPP_ABI_NAMESPACE21__libcpp_condvar_waitB6v15004EP14pthread_cond_tP15pthread_mutex_t
/home/hazy/tools/ohos-v5.0.3.900/command-line-tools/sdk/default/openharmony/native/llvm/include/c++/v1/__threading_support:335
_ZN7flutter16PlatformViewOHOS13NotifyChangedERK7SkISize
/home/hazy/work/engine_build/engine_daily/src/out/ohos_release_arm64/../../flutter/shell/platform/ohos/platform_view_ohos.cpp:192
```

## Others

- [Analyzing CppCrash](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/cppcrash-guidelines-V5)
- [flutter_flutter](https://gitcode.com/CPF-Flutter/flutter_flutter)
- [flutter_engine](https://gitcode.com/CPF-Flutter/flutter_engine)
