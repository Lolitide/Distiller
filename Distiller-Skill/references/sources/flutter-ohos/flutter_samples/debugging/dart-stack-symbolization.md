# Dart 堆栈符号化

## 概述

当 Flutter 应用在 Release 或 Profile 模式下发生卡死（AppFreeze）或崩溃（CppCrash）时，相关日志中通常会包含dart层的堆栈信息（libapp.so部分），但获取到的堆栈地址是十六进制偏移量，无法直接看到具体的 Dart 函数和行号。需要使用 `flutter symbolize` 工具将原始堆栈地址转换为可读的 Dart 源代码位置。

## 工具

- **工具**: `flutter symbolize`
- **输入**: 需要符号化的堆栈文件 + 符号文件
- **输出**: 符号化后的堆栈文件

## 命令

```bash
flutter symbolize -i <堆栈文件> -d <符号文件> -o <符号化后输出文件>
```

## 获取符号文件

符号文件在打包阶段生成。构建 HAP 包时追加 `--split-debug-info` 参数（意思是剥离调试信息，需要传入一个文件夹的路径），如：

```bash
flutter build hap --release --split-debug-info=./debug-info
```

打包时会将符号信息从 `libapp.so` 中分离出来，生成在指定目录下，如：`./debug-info/app.ohos-arm64.symbols`

## 生成堆栈文件

AppFreeze 日志、CppCrash 日志或 HiProfiler 抓取的 trace 文件中通常会包含dart层的堆栈信息（libapp.so部分），但需要转换为 `flutter symbolize` 工具可识别的格式。

原始堆栈格式（来自日志）：
```txt
#00 pc 0000000000171698 /data/storage/el1/bundle/libs/arm64/libapp.so(301f78813ec57f68e57e8d5453ab0d89)
#01 pc 00000000001537b4 /data/storage/el1/bundle/libs/arm64/libapp.so(301f78813ec57f68e57e8d5453ab0d89)
...
```

转换后的堆栈格式：
```txt
#00 abs 0000000000171698 virt 0000000000171698 libapp.so
#01 abs 00000000001537b4 virt 00000000001537b4 libapp.so
...
```

说明：
- `#xx`: 调用栈中的帧编号
- `pc`: 程序计数器 - 表示指令指针地址
- `0000000000xxxxxx`: 十六进制地址
- `/data/storage/.../libapp.so`: 共享库路径
- `(301f78813ec57f68e57e8d5453ab0d89)`: 构建指纹/哈希值

## 示例：AppFreeze 堆栈符号化

### 1. 准备输入文件

将转换后的堆栈保存为 `input.txt`：
```txt
#00 abs 0000000000171698 virt 0000000000171698 libapp.so
#01 abs 00000000001537b4 virt 00000000001537b4 libapp.so
#02 abs 0000000000281fe4 virt 0000000000281fe4 libapp.so
#03 abs 000000000023e2b4 virt 000000000023e2b4 libapp.so
#04 abs 000000000022ae88 virt 000000000022ae88 libapp.so
#05 abs 0000000000234b8c virt 0000000000234b8c libapp.so
#06 abs 0000000000237f2c virt 0000000000237f2c libapp.so
#07 abs 0000000000237cd0 virt 0000000000237cd0 libapp.so
#08 abs 0000000000278d3c virt 0000000000278d3c libapp.so
#09 abs 0000000000146204 virt 0000000000146204 libapp.so
#10 abs 000000000024df24 virt 000000000024df24 libapp.so
#11 abs 0000000000146190 virt 0000000000146190 libapp.so
#12 abs 00000000001460f8 virt 00000000001460f8 libapp.so
#13 abs 00000000001458d4 virt 00000000001458d4 libapp.so
#14 abs 000000000027d6a4 virt 000000000027d6a4 libapp.so
#15 abs 0000000000179014 virt 0000000000179014 libapp.so
#16 abs 0000000000178f54 virt 0000000000178f54 libapp.so
#17 abs 0000000000178a40 virt 0000000000178a40 libapp.so
#18 abs 000000000028dadc virt 000000000028dadc libapp.so
#19 abs 000000000025bd20 virt 000000000025bd20 libapp.so
#20 abs 00000000000dffc4 virt 00000000000dffc4 libapp.so
#21 abs 00000000000ec878 virt 00000000000ec878 libapp.so
#22 abs 00000000000ec808 virt 00000000000ec808 libapp.so
#23 abs 00000000000ed5d4 virt 00000000000ed5d4 libapp.so
#24 abs 00000000000dca20 virt 00000000000dca20 libapp.so
```

### 2. 执行符号化命令

```bash
flutter symbolize -i input.txt -d app.ohos-arm64.symbols -o symbols.txt
```

### 3. 查看符号化结果

`symbols.txt` 内容如下：
```txt
#0      _MyHomePageState._dartFreeze (D:/Flutter/demo/flutter_dfx_sample/lib/main.dart:44:5)
#1      _MyHomePageState._dartFreeze (D:/Flutter/demo/flutter_dfx_sample/lib/main.dart:41:3)
#2      _InkResponseState.handleTap (D:/Flutter/flutter_flutter/packages/flutter/lib/src/material/ink_well.dart:1195:3)
#3      GestureRecognizer.invokeCallback (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/recognizer.dart:345:24)
#4      TapGestureRecognizer.handleTapUp (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/tap.dart:737:11)
#5      BaseTapGestureRecognizer._checkUp (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/tap.dart:362:5)
#6      BaseTapGestureRecognizer.handlePrimaryPointer (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/tap.dart:293:7)
#7      PrimaryPointerGestureRecognizer.handleEvent (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/recognizer.dart:706:9)
#8      PrimaryPointerGestureRecognizer.handleEvent (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/recognizer.dart:688:3)
#9      PointerRouter._dispatch (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/pointer_router.dart:97:12)
#10     PointerRouter._dispatchEventToRoutes.<anonymous closure> (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/pointer_router.dart:143:9)
#11     _LinkedHashMapMixin.forEach (third_party/dart/sdk/lib/_internal/vm_shared/lib/compact_hash.dart:764:13)
#12     PointerRouter._dispatchEventToRoutes (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/pointer_router.dart:141:18)
#13     PointerRouter.route (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/pointer_router.dart:131:7)
#14     GestureBinding.handleEvent (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:530:19)
#15     GestureBinding.dispatchEvent (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:499:22)
#16     RendererBinding.dispatchEvent (D:/Flutter/flutter_flutter/packages/flutter/rendering/binding.dart:473:11)
#17     GestureBinding._handlePointerEventImmediately (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:437:7)
#18     GestureBinding.handlePointerEvent (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:394:5)
#19     GestureBinding._flushPointerEventQueue (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:341:7)
#20     GestureBinding._handlePointerDataPacket (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:308:9)
#21     GestureBinding._handlePointerDataPacket (D:/Flutter/flutter_flutter/packages/flutter/lib/src/gestures/binding.dart:300:3)
#22     _invoke1 (lib/ui/hooks.dart:347:13)
#23     PlatformDispatcher._dispatchPointerDataPacket (lib/ui/platform_dispatcher.dart:467:7)
#24     _dispatchPointerDataPacket (lib/ui/hooks.dart:282:31)
#25     _dispatchPointerDataPacket (lib/ui/hooks.dart:280:1)
#26     stub InvokeDartCode+0xd4
```

符号化后可以清晰看到：
- 崩溃发生在 `main.dart` 的 `_MyHomePageState._dartFreeze` 方法
- 具体行号：第 41 行和第 44 行
- 调用链完整：从 Dart 层到 Flutter 框架再到 native 层

## split-debug-info 参数影响

### 体积减少

加上 `--split-debug-info` 参数后，符号信息从 `app.so` 中分离，应用体积略有减小。

### DevTools 无法连接

DevTools 依赖符号文件进行调试。添加此参数后会导致 DevTools 无法连接应用。建议在 Release 模式下使用。

### 性能无影响

测试表明开启和关闭该参数对 UI 和 Raster 性能无明显影响。

## 相关链接

- Flutter 官方文档: https://docs.flutter.dev/reference/flutter-cli
