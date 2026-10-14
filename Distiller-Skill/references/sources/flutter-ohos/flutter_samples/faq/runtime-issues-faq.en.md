# ohos Runtime Issues

<a id="section704946"></a>

## Runtime Error /data/storage/el1/bundle/entry/ets/modules.abc After Building for OpenHarmony

**Symptom:**

A runtime error occurs after Flutter builds for OpenHarmony.

Error message:

```log
com.wit.appzoo_flutter_v2 is about to exit due to RuntimeError
Error type:ReferenceError
Error name:ReferenceError
Error message:cannot find record 'pkg_modules/.ohpm/connectivity_plus@fhy6p0gmf3puymhvkbu4hxvnutt4mn48tk2kirtanmi=/pkg_modules/connectivity_plus/index', please check the request path.'/data/storage/el1/bundle/entry/ets/modules.abc'.
Stacktrace:
SourceMap is not initialized yet
#00 pc 00000000005fcc0c /system/lib64/platformsdk/libark_jsruntime.so(5144aa99644b9dba57555adfb9e0ede6)
#01 pc 00000000005fd128 /system/lib64/platformsdk/libark_jsruntime.so(5144aa99644b9dba57555adfb9e0ede6)
#02 pc 00000000002ac540 /system/lib64/platformsdk/libark_jsruntime.so(5144aa99644b9dba57555adfb9e0ede6)
```

**Cause:**

`/data/storage/el1/bundle/entry/ets/modules.abc` may fail because the abc file cannot run properly due to an SDK and image mismatch. The root cause of this symptom is a version mismatch between the SDK tools and the image.

**Solution:**

It is recommended to use an SDK version that matches the phone image version; please provide screenshots of the current phone version and IDE version. If the versions do match, provide the complete logs.

---

<a id="section179086"></a>

## Sudden Exit at Run Time After the app Package Is Installed Successfully

**Symptom:**

The app package installs successfully but the app suddenly exits at run time. Depending on the crash stack, there are three common types:

Stack 1 (attachToNative):

```log
#20 at attachToNative (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterNapi.ts:60:1)
#21 at attachToNapi (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:97:1)
#22 at init (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:88:1)
```

Stack 2 (mprotect):

```log
Reason:Signal:SIGABR(SI_TKILL)@0x01317b3d0000ba50 from:47696:20020029
LastFatalMessage:.../.../flutter/third_part/dart/runtime/vm/virtual_memory_posix.cc:611:error:mprotect failed:22(Invalid argument)
```

Stack 3 (Accessibility):

```log
#00000000003aeb4 /system/lib64/libace_ndk.z.so(ArkUI_AccessibilityProvide::SendAccessibilityAsyncEvent(ArkUI_AccessibilityEventInfo*, void(*)(int))+32)(09034f01ea7d526dbbeb194081953e0a)
#000000000314d80 _ZL23bw_pt_rect_32_hair_procRK9PtProRecPK7SkPointiP9SkBlitter
/home/hazy/work/engine_build/engine_daily/src/out/ohos_release_arm64/../../third_party/skia/src/core/SkSraw.cpp:161
#000000000314d80 _ZNK6sKDraw10drawPointsEN8SkCanvas9PointModeEmPK7SkPointRK7SkPaintP12SkBaseDevice
/home/hazy/work/engine_build/engine_daily/src/out/ohos_release_arm64/../../third_party/skia/src/core/SkSraw.cpp:487
......
```

**Cause:**

- Stack 1: The app store release package uses the debug version of flutter.har.
- Stack 2: When the stack involves `virtual_memory` or `mprotect`, the cause is usually insufficient permissions, locked memory pages, or system resource limits. After API 12, the control policy for execution permission on anonymous memory changed, and phone apps are prohibited from requesting anonymous memory.
- Stack 3: When the stack involves `Accessibility`, it is usually an accessibility fault: enabling accessibility and then cold-starting the Flutter page causes the accessibility bridge class to be invoked before the accessibility service is registered, resulting in a null pointer and a sudden exit. In this scenario, the partner upgraded the API but did not upgrade the Flutter SDK accordingly, so some already-fixed issues were not included.

**Solution:**

- Stack 1: You are advised to repackage the release version of flutter.har before the app store release by running `flutter build hap --release`. For details, see [Signing and Release Issues](./signing-and-release-faq.en.md#section823290).
- Stack 2: When using Dart FFI, avoid functions that request anonymous memory, such as `Pointer.fromFunction` and `NativeCallable.isolateLocal`. This issue has been fixed in later versions: [fluttertpc_dart_sdk#12](https://gitcode.com/CPF-Flutter/fluttertpc_dart_sdk/pull/12).
- Stack 3: Fixed in later versions: [flutter_engine#592](https://gitcode.com/CPF-Flutter/flutter_engine/pull/592).

---

<a id="section721639"></a>

## White Screen After the App Is Built Successfully and Installed

**Symptom:**

The app is built successfully but shows a white screen after installation.

Log information:

```log
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x00000086e3272bf8
LastFatalMessage:Thread:547846269584[FATAL:flutter/runtime/dart_vm_initializer.cc] Error while initializing the Dart VM: Wrong full snapshot version, expected '8af474944053df1f0a3be6e6165fa7cf' found 'adb4292f3ec25074ca70abcd2d5c7251'
```

**Cause:**

The engine artifacts used do not match the run mode, resulting in a white screen.

**Solution:**

The engine artifacts used in the run or build command must be consistent with the run mode. Reference commands:

```shell
flutter run -d <device-id> --debug
flutter run -d <device-id> --release
flutter run -d <device-id> --profile
```

---

<a id="section721640"></a>

## White Screen or Sudden Exit Caused by Enabling Obfuscation

**Symptom:**

The app is built and runs successfully in debug mode but suddenly exits in release mode.

**Cause:**

After obfuscation is enabled for a Flutter project on HarmonyOS, the sudden exit usually occurs because ArkTS code obfuscation renames method names, property names, or file paths while the runtime still accesses them by their original names, causing a white screen or crash. The obfuscation configuration takes effect only in release mode, not in debug mode, which is why the app works in debug mode but suddenly exits in release mode.

**Solution:**

If this is caused by enabling code obfuscation — the obfuscation configuration does not take effect in debug mode, only in release mode — manually turn off the code obfuscation switch in each module of the project. If partial code obfuscation is required, configure the obfuscation retention options, then rebuild and release the app package.

To disable code obfuscation: find the `arkOptions` node in each module's `build-profile.json5` configuration file and set the `enable` property in the `obfuscation` property to `false`. For details, see [Obfuscation Configuration](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-build-obfuscation#section18326541833). Configuration example:

```json5
"arkOptions": {
  "obfuscation": {
    "ruleOptions": {
      "enable": false,
      "files": []
    }
  }
}
```

To troubleshoot obfuscation errors, see [Obfuscation FAQs](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/source-obfuscation-questions) and [Restoring Error Stacks](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/source-obfuscation-guide#%E6%8A%A5%E9%94%99%E6%A0%88%E8%BF%98%E5%8E%9F).

---

<a id="section382914"></a>

## Brief One-Frame Black/White Screen Flash at Run Time After the app Package Is Installed

**Symptom:**

After the app package is installed, a brief one-frame black/white screen flash appears at run time during startup, page switching, and other scenarios.

**Cause:**

The flutter page does not set `.backgroundColor(Color.Transparent)`, so the background color differs from the layer below during switching, causing the flash frame.

**Solution:**

Check whether the flutter page sets the `.backgroundColor(Color.Transparent)` property; if not, add this property:

```ts
FlutterPage({ viewId: this.topViewId, xComponentType: XComponentType.TEXTURE })
  .height('50%')
  .backgroundColor(Color.Transparent)
```

---

<a id="section518237"></a>

## Safe Area Abnormality at the Top of the Page

**Symptom:**

Elements such as the status bar at the top of the page overlap or are obscured, and the safe area height is obtained as 0.

**Cause:**

The current page is in Flutter full-screen mode but `setUseFullScreen` is not configured, causing area folding on foldable phones or in other scenarios.

**Solution:**

If the current page is in Flutter full-screen mode, configure `setUseFullScreen` to avoid area folding on foldable phones or in other scenarios:

```ts
export class EngineBindings implements DataModelObserver {
  // ...
  constructor(context: common.Context, delegate: EngineBindingsDelegate) {
    // ...
    FlutterManager.getInstance().setUseFullScreen(true, this.context);
  }
}
```

Reference documentation: [How to Use the Multi-Engine FlutterEngineGroup](../hybrid-development/using-flutter-engine-group.en.md)

Reference demo: [multiple_flutters](../../../add_to_app/multiple_flutters/multiple_flutters_ohos/entry/src/main/ets/pages/EngineBindings.ets)
