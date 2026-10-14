# ohos 运行问题

<a id="section704946"></a>

## 编译 OpenHarmony 后运行出现运行时错误 /data/storage/el1/bundle/entry/ets/modules.abc

**现象：**

flutter 编译 OpenHarmony 后运行出现运行时错误。

报错信息：

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

**原因：**

`/data/storage/el1/bundle/entry/ets/modules.abc` 可能是 SDK 与镜像不匹配导致 abc 文件无法正常运行，该现象根本原因是 SDK 工具与镜像版本不匹配。

**解决方案：**

推荐使用匹配的 SDK 与手机镜像版本；请提供当前手机版本和 ide 版本截图。若版本是匹配的，请提供完整日志。

---

<a id="section179086"></a>

## app 包安装成功后，运行闪退

**现象：**

app 包安装成功后运行闪退。根据 crash 堆栈不同，常见有以下三类：

堆栈一（attachToNative）：

```log
#20 at attachToNative (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterNapi.ts:60:1)
#21 at attachToNapi (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:97:1)
#22 at init (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:88:1)
```

堆栈二（mprotect）：

```log
Reason:Signal:SIGABR(SI_TKILL)@0x01317b3d0000ba50 from:47696:20020029
LastFatalMessage:.../.../flutter/third_part/dart/runtime/vm/virtual_memory_posix.cc:611:error:mprotect failed:22(Invalid argument)
```

堆栈三（Accessibility）：

```log
#00000000003aeb4 /system/lib64/libace_ndk.z.so(ArkUI_AccessibilityProvide::SendAccessibilityAsyncEvent(ArkUI_AccessibilityEventInfo*, void(*)(int))+32)(09034f01ea7d526dbbeb194081953e0a)
#000000000314d80 _ZL23bw_pt_rect_32_hair_procRK9PtProRecPK7SkPointiP9SkBlitter
/home/hazy/work/engine_build/engine_daily/src/out/ohos_release_arm64/../../third_party/skia/src/core/SkSraw.cpp:161
#000000000314d80 _ZNK6sKDraw10drawPointsEN8SkCanvas9PointModeEmPK7SkPointRK7SkPaintP12SkBaseDevice
/home/hazy/work/engine_build/engine_daily/src/out/ohos_release_arm64/../../third_party/skia/src/core/SkSraw.cpp:487
......
```

**原因：**

- 堆栈一：上线包使用了 debug 版本的 flutter.har。
- 堆栈二：涉及 `virtual_memory`、`mprotect` 字段时，通常是由于权限不足、内存页锁定或系统资源限制导致；API12 后匿名内存执行权限管控策略变更，手机应用被禁止申请匿名内存。
- 堆栈三：涉及 `Accessibility` 字段时，通常是无障碍功能异常，开启无障碍再冷启动 flutter 页面导致先调用无障碍 bridge 类再注册无障碍服务，造成空指针闪退；此场景中伙伴升级 api 后却未同步升级更新 flutter sdk，导致部分已修复问题未更新。

**解决方案：**

- 堆栈一：建议上线前重新打包 release 版本的 flutter.har，执行命令 `flutter build hap --release`。详见 [签名与发布问题](./signing-and-release-faq.md#section823290)。
- 堆栈二：使用 Dart FFI 时，应避免使用 `Pointer.fromFunction`、`NativeCallable.isolateLocal` 等会申请匿名内存的函数。后续版本已修复此问题：[fluttertpc_dart_sdk#12](https://gitcode.com/CPF-Flutter/fluttertpc_dart_sdk/pull/12)。
- 堆栈三：后续版本已修复：[flutter_engine#592](https://gitcode.com/CPF-Flutter/flutter_engine/pull/592)。

---

<a id="section721639"></a>

## 应用编译成功，安装后出现白屏

**现象：**

应用编译成功，安装后出现白屏。

日志信息：

```log
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x00000086e3272bf8
LastFatalMessage:Thread:547846269584[FATAL:flutter/runtime/dart_vm_initializer.cc] Error while initializing the Dart VM: Wrong full snapshot version, expected '8af474944053df1f0a3be6e6165fa7cf' found 'adb4292f3ec25074ca70abcd2d5c7251'
```

**原因：**

使用的 engine 产物和运行模式不一致，导致运行白屏。

**解决方案：**

运行或编译命令中，使用的 engine 产物和运行模式需要保持一致。参考命令：

```shell
flutter run -d <device-id> --debug
flutter run -d <device-id> --release
flutter run -d <device-id> --profile
```

---

<a id="section721640"></a>

## 开启混淆导致白屏/闪退

**现象：**

应用编译成功运行出现"debug 正常、release 闪退"的现象。

**原因：**

Flutter 项目在 HarmonyOS 上开启混淆后闪退，通常是因为 ArkTS 代码混淆导致方法名、属性名或文件路径被重命名，而运行时仍按原始名称进行访问，从而引发白屏/崩溃。混淆配置仅在 release 模式下生效，debug 模式下不生效，因此容易出现"debug 正常、release 闪退"的现象。

**解决方案：**

如果是由于开启了代码混淆所致，而混淆配置在 debug 模式下是不生效的，只在 release 模式下生效，需要手动将项目中每个模块的代码混淆开关关闭；如果需要开启局部代码混淆，则可以通过配置混淆保留选项，最后重新打 App 包上架。

关闭代码混淆：在各个模块的 `build-profile.json5` 配置文件中找到 `arkOptions` 节点，并修改 `obfuscation` 属性中的 `enable` 属性设置为 `false`，具体参考 [混淆配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-build-obfuscation#section18326541833)，配置示例：

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

对于混淆报错的地方，请通过 [混淆常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/source-obfuscation-questions) 和 [报错栈还原](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/source-obfuscation-guide#%E6%8A%A5%E9%94%99%E6%A0%88%E8%BF%98%E5%8E%9F) 进行排查。

---

<a id="section382914"></a>

## app 包安装成功后，运行时出现短暂一帧的闪黑屏/白屏

**现象：**

app 包安装成功后，运行时在启动、页面切换等场景下出现短暂一帧的闪黑屏/白屏。

**原因：**

flutter page 页面未设置 `.backgroundColor(Color.Transparent)`，切换时背景色与下层不一致导致闪帧。

**解决方案：**

检查 flutter page 页面是否设置属性 `.backgroundColor(Color.Transparent)`，没有的话添加此属性设置：

```ts
FlutterPage({ viewId: this.topViewId, xComponentType: XComponentType.TEXTURE })
  .height('50%')
  .backgroundColor(Color.Transparent)
```

---

<a id="section518237"></a>

## 页面顶部区域出现安全避让区异常

**现象：**

页面顶部区域状态栏等出现重叠、遮挡，安全避让区获取高度为 0。

**原因：**

当前页面处于 Flutter 全屏模式但未进行 `setUseFullScreen` 设置，导致在折叠屏手机或其他场景中出现区域折叠。

**解决方案：**

如果当前页面处于 Flutter 全屏模式，则需要进行 `setUseFullScreen` 设置，以避免在折叠屏手机或其他场景中出现区域折叠：

```ts
export class EngineBindings implements DataModelObserver {
  // ...
  constructor(context: common.Context, delegate: EngineBindingsDelegate) {
    // ...
    FlutterManager.getInstance().setUseFullScreen(true, this.context);
  }
}
```

可参考文档：[如何使用多引擎 FlutterEngineGroup](../hybrid-development/using-flutter-engine-group.md)

可参考 demo：[multiple_flutters](../../../add_to_app/multiple_flutters/multiple_flutters_ohos/entry/src/main/ets/pages/EngineBindings.ets)
