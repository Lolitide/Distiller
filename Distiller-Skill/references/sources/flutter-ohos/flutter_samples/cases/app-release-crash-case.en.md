# App Store Release and Launch Sudden Exit Scenarios

## I. Analysis of the Sudden Exit on Launch Scenario After Beta Testing or Official App Store Release

1. Fault description

   The app launches and runs normally on the local device, but exits suddenly on launch after being released for beta testing or official app store release.

2. Error stack trace

   ```log
   Device info:HUAWEI Mate 60
   Build info:BRA-AL00 5.0.0.150(SP8C00E150R4P30)
   Fingerprint:9e0ffabdb981862b88d947a5956da3ca583c6a76a88b191ffb4d3ced7e9d7b78
   Module name:com.example.flutter
   Version:1.0.1
   VersionCode:1000001
   PreInstalled:No
   Foreground:Yes
   Timestamp:2025-07-11 11:14:20.185
   Pid:4358
   Uid:20020018
   Process name:com.example.flutter
   Process life time:11s
   Reason:Signal:SIGABRT(SI_TKILL)@0x01317b3200001106 from:4358:20020018
   LastFatalMessage:../../third_party/dart/runtime/vm/virtual_memory_posix.cc: 74: error: mmap failed: 22 (Invalid argument)
   Fault thread info:
   Tid:4358, Name:ths.wifi_camera
   #00 pc 0000000000199e5c /system/lib/ld-musl-aarch64.so.1(raise+228)(c66b0063d30004b77342b1dde06f68b1)
   #01 pc 0000000000146f8c /system/lib/ld-musl-aarch64.so.1(abort+20)(c66b0063d30004b77342b1dde06f68b1)
   #02 pc 0000000003d1271c /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #03 pc 0000000003f0c98c /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #04 pc 0000000003f0c7e8 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #05 pc 0000000003f29038 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #06 pc 0000000003f29cd0 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #07 pc 0000000003f2a418 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #08 pc 0000000003f2129c /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #09 pc 0000000003e002a0 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #10 pc 0000000003e2e1a8 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #11 pc 0000000003e2e4b0 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #12 pc 0000000003eece5c /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #13 pc 0000000003eecc28 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #14 pc 0000000003d98974 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #15 pc 0000000003d98bc0 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #16 pc 0000000003c915a0 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #17 pc 0000000003c8cba4 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #18 pc 0000000003c8c0c0 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #19 pc 0000000003c92154 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #20 pc 0000000003ab02fc /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #21 pc 0000000003ab042c /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #22 pc 0000000002174c70 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #23 pc 000000000211f640 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #24 pc 0000000002113074 /data/storage/el1/bundle/libs/arm64/libflutter.so(fedfd138e5142725b25cd00c996876ca4c0ef7c6)
   #25 pc 000000000003e9e4 /system/lib64/platformsdk/libace_napi.z.so(panda::JSValueRef ArkNativeFunctionCallBack<true>(panda::JsiRuntimeCallInfo*)+212)(85e70f1f5cf0e81468ec141fc2f4922c)
   #26 pc 0000000000404b2c /system/lib64/module/arkcompiler/stub.an(RTStub_PushCallArgsAndDispatchNative+40)
   #27 at attachToNative (entry|@ohos/flutter_ohos|1.0.0-e7a98130f5|src/main/ets/embedding/engine/FlutterNapi.ts:87:1)
   #28 at attachToNapi (entry|@ohos/flutter_ohos|1.0.0-e7a98130f5|src/main/ets/embedding/engine/FlutterEngine.ts:119:1)
   #29 at init (entry|@ohos/flutter_ohos|1.0.0-e7a98130f5|src/main/ets/embedding/engine/FlutterEngine.ts:109:1)
   ```

   

3. Problem scenario analysis

   **Problem localization**
   - From the error log reported by the app market, the keywords SI_TKILL, raise+228, and abort+20 are identified. These are assertion logs, indicating that flutter.har is a debug build. An officially released package should be compiled with release, and assertions should not appear in the log.
   - The keyword attachToNative on line 27. This has a security impact: release apps published to the app store have JIT capabilities disabled (the ability to request executable anonymous memory in C++). This affects Flutter apps, which no longer support requesting anonymous memory with execute permission, causing the debug version to exit suddenly at runtime.
   - A release package is much smaller than a debug package; you can check the size of the submitted app package.

   **Cause analysis**
   A Flutter app compiled and packaged with debug has no execute permission for anonymous memory, which causes a sudden exit on launch.

4. Solution

   The officially released package must be compiled with release:

   ```bash
   # Build the HAP package in release mode
   flutter build hap --release
   ```



---

## II. Analysis of the Sudden Exit on Launch Scenario When the Latest Flutter Code Is Not Used

1. Fault description

   The app exits suddenly after launch when built with an old version of the flutter code.

2. Error stack trace

   ```log
   HiLog :
   ...
   FlutterEngine : Thread :385496703040 [FATAL:flutter/runtime/dart_vm_initializer.cc(89)]
   Error while initializing the Dart VM: Wrong full snapshot version, expected '25523e38d22932934b1f691de39b5c14' found 'd20albe77c3d3c41b2a5accaeelce549'
   FlutterEngine: FML KILL PROCESS 
   ...
   ```

   

3. Problem scenario analysis
   **Problem localization**
   The `Error while initializing the Dart VM: Wrong full snapshot version` problem persists after deleting the cache and rebuilding, so it should be related to version adaptation.
   **Cause analysis**
   The latest version of the code is not being used.

4. Solution

   ① Set the environment variable `export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com`;
   
   ② Delete the cache under the `/bin/cache` directory;
   
   ③ Pull the latest code and run `flutter clean` to clear the project build cache;
   
   ④ Run `flutter run -d $DEVICE (device id) --debug`.
