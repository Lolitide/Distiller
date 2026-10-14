# Dart Stack Symbolization

## Overview

When a Flutter application freezes (AppFreeze) or crashes (CppCrash) in Release or Profile mode, the related logs usually contain the Dart-layer stack information (the libapp.so part). However, the stack addresses obtained are hexadecimal offsets, and you cannot directly see the specific Dart functions and line numbers. You need to use the `flutter symbolize` tool to convert the raw stack addresses into readable Dart source code locations.

## Tool

- **Tool**: `flutter symbolize`
- **Input**: the stack file to be symbolized + the symbol file
- **Output**: the symbolized stack file

## Command

```bash
flutter symbolize -i <stack-file> -d <symbol-file> -o <output-file>
```

## Obtaining the Symbol File

The symbol file is generated during the packaging phase. When building the HAP package, append the `--split-debug-info` parameter (which strips debug info; you need to pass in a folder path), for example:

```bash
flutter build hap --release --split-debug-info=./debug-info
```

During packaging, the symbol information is separated from `libapp.so` and generated in the specified directory, for example: `./debug-info/app.ohos-arm64.symbols`

## Generating the Stack File

AppFreeze logs, CppCrash logs, or trace files captured by Hiprofiler usually contain the Dart-layer stack information (the libapp.so part), but it needs to be converted into a format recognized by the `flutter symbolize` tool.

Raw stack format (from the log):
```txt
#00 pc 0000000000171698 /data/storage/el1/bundle/libs/arm64/libapp.so(301f78813ec57f68e57e8d5453ab0d89)
#01 pc 00000000001537b4 /data/storage/el1/bundle/libs/arm64/libapp.so(301f78813ec57f68e57e8d5453ab0d89)
...
```

Converted stack format:
```txt
#00 abs 0000000000171698 virt 0000000000171698 libapp.so
#01 abs 00000000001537b4 virt 00000000001537b4 libapp.so
...
```

Notes:
- `#xx`: the frame number in the call stack
- `pc`: program counter - represents the instruction pointer address
- `0000000000xxxxxx`: hexadecimal address
- `/data/storage/.../libapp.so`: shared library path
- `(301f78813ec57f68e57e8d5453ab0d89)`: build fingerprint/hash

## Example: AppFreeze Stack Symbolization

### 1. Prepare the Input File

Save the converted stack as `input.txt`:
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

### 2. Run the Symbolization Command

```bash
flutter symbolize -i input.txt -d app.ohos-arm64.symbols -o symbols.txt
```

### 3. View the Symbolization Result

The content of `symbols.txt` is as follows:
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
#16     RendererBinding.dispatchEvent (D:/Flutter/flutter/rendering/binding.dart:473:11)
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

After symbolization, you can clearly see:
- The crash occurred in the `_MyHomePageState._dartFreeze` method in `main.dart`
- Specific line numbers: line 41 and line 44
- The complete call chain: from the Dart layer to the Flutter framework and then to the native layer

## Impact of the split-debug-info Parameter

### Size Reduction

With the `--split-debug-info` parameter, the symbol information is separated from `app.so`, slightly reducing the application size.

### DevTools Cannot Connect

DevTools relies on the symbol file for debugging. Adding this parameter will cause DevTools to be unable to connect to the application. It is recommended to use it in Release mode.

### No Performance Impact

Tests show that enabling or disabling this parameter has no significant impact on UI and Raster performance.

## Related Links

- Flutter official documentation: https://docs.flutter.dev/reference/flutter-cli
