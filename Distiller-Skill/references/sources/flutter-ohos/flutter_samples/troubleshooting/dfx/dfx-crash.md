# 崩溃问题定位指南

> 返回 [README.md](README.md)

---

## 1. 三种崩溃类型

Flutter OHOS 应用闪退可能来自三个不同的"层"，就像一栋楼有三层，每一层着火的原因和灭火方法都不同：

| 崩溃类型 | 发生在哪一层 | 日志关键词 | 常见原因 |
|---------|------------|-----------|---------|
| **Native 崩溃** | 引擎底层（C++ 代码） | `Caught signal SIG*` | 空指针、GPU 驱动崩溃、内存被破坏 |
| **Dart 异常** | 你的 Dart 代码 | `Unhandled exception` | 类型错误、数组越界、空指针 |
| **ETS 异常** | ArkTS 插件代码 | `Failed to handle` | MethodChannel 回调中出错 |

> **新手提示**：
> - **Dart 异常**是最常见的，通常是你代码里的 bug，比如变量为 null 还调用了方法
> - **Native 崩溃**比较严重，可能是引擎 bug 或 GPU 驱动问题
> - **ETS 异常**通常不致命（不会闪退），但会导致某个功能用不了

### 快速判断流程

```
应用闪退了
│
├─ 在日志里搜索 "Caught signal"
│  ├─ 搜到了 → 引擎底层崩溃 → 看本文 §2
│  └─ 没搜到 ↓
│
├─ 在日志里搜索 "Unhandled exception"
│  ├─ 搜到了 → 你的 Dart 代码有 bug → 看本文 §3
│  └─ 没搜到 ↓
│
├─ 在日志里搜索 "FLUTTER_ETS_EXCEPTION"
│  ├─ 搜到了 → ArkTS 插件有 bug → 看本文 §4
│  └─ 没搜到 → 回去抓全量日志，重新排查
```

> **怎么搜日志？** 如果你还不会抓日志，先看 [dfx-logging.md](dfx-logging.md) 或 [README.md](README.md) §2。

---

## 2. Native 崩溃（引擎底层崩溃）

### 2.1 什么是 Native 崩溃？

Native 崩溃是 Flutter 引擎的 C++ 代码发生了严重错误。你可以理解为"引擎自己崩了"。这通常比 Dart 异常更严重，因为引擎一旦崩溃，整个应用就直接闪退了，没有机会做任何清理工作。

引擎在启动时会注册"信号处理器"（就像安装了烟雾报警器），当崩溃发生时，报警器会记录下崩溃信息并输出到日志。

### 2.2 崩溃信号类型（报警器响了，是什么类型的火？）

| 信号 | 名称 | 通俗解释 | 常见原因 |
|------|------|---------|---------|
| SIGSEGV | 段错误 | 引擎访问了不该访问的内存 | 空指针、对象已被释放但还在用 |
| SIGABRT | 异常终止 | 引擎自己调用 `abort()` "自杀"了 | 代码里的断言（assert）失败了、内存被破坏 |
| SIGFPE | 浮点异常 | 数学运算出错 | 除以零了 |
| SIGBUS | 总线错误 | 内存对齐有问题 | DMA buffer 被提前释放 |
| SIGTERM | 软件终止 | 系统让进程退出 | 系统资源限制 |
| SIGPIPE | 管道断裂 | 往已经关闭的管道写数据 | IPC 通信通道断了 |

> **新手只需要记住**：**SIGSEGV（最常见）** = 空指针或访问了已释放的内存；**SIGABRT** = 引擎内部检查发现了问题主动退出。

### 2.3 具体现象（我怎么知道是 Native 崩溃？）

| 你看到的现象 | 可能的信号 | 严重程度 | 说明 |
|-------------|----------|---------|------|
| 应用无征兆突然闪退，没有任何 Dart 报错 | SIGSEGV | 致命 | 最常见，引擎访问了非法内存 |
| 闪退前日志里有 `CHECK failed` 或 `assert` | SIGABRT | 致命 | 引擎内部的断言检查失败了 |
| 画面花屏/绿屏后闪退 | SIGSEGV | 致命 | GPU 内存被破坏 |
| 退后台再回前台后闪退 | SIGSEGV | 致命 | GPU 上下文丢失后仍渲染 |
| 闪退时堆栈里有 `GPU` / `Rasterizer` | SIGSEGV/SIGABRT | 致命 | GPU 驱动崩溃 |
| 闪退时堆栈里有 `Texture` / `external_texture` | SIGSEGV | 致命 | 纹理被释放后还在访问 |

### 2.4 日志长什么样？

在日志中搜索 `Caught signal`，你会看到类似这样的内容：

```
E Flutter: Caught signal SIGSEGV during program execution.
E Flutter: Frame 0: 0x7f8b2c3d4e50 FlutterRenderer::DrawFrame
E Flutter: Frame 1: 0x7f8b2c3d4f60 Shell::OnDrawFrame
E Flutter: Frame 2: 0x7f8b2c3d5070 fml::MessageLoopImpl::Run
```

**怎么读这些日志？**
- **第一行** `Caught signal SIGSEGV` → 告诉你是段错误（空指针类问题）
- **后面的 Frame 行** → 这是崩溃时的"调用栈"，就像侦探追踪线索一样
  - `Frame 0` 是崩溃发生的最直接位置
  - `Frame 1`、`Frame 2` 是调用链的上层
  - 函数名对应引擎源码，能帮你判断是哪块功能出了问题

### 2.5 怎么排查？（分 4 步走）

**第 1 步**：搜索日志，拿到完整堆栈

```bash
hdc shell hilog | grep -A 30 "Caught signal"
```

> `-A 30` 表示搜到关键词后再往后看 30 行，这样能看到完整的调用栈。

**第 2 步**：根据信号类型判断问题方向

| 信号 | 排查方向 | 具体要找什么 |
|------|---------|------------|
| SIGSEGV | 空指针 / 悬垂指针 | 搜索 `GpuReclaim`（GPU 回收）、`UnRegisterExternalTexture`（纹理注销） |
| SIGABRT | 断言失败 / 堆破坏 | 搜索 `CHECK failed`、`DCheck failed` |
| SIGFPE | 除零运算 | 检查尺寸计算、帧率计算中是否有 0 值 |
| SIGBUS | 内存映射失效 | 检查 DMA buffer 是否被提前释放 |

**第 3 步**：根据堆栈中的函数名判断是哪块出了问题

- 堆栈里的函数名直接对应引擎源码的文件名
- 如果函数名显示 `Unknown`，需要用 `addr2line` 工具把地址翻译成源码行号：
  ```bash
  addr2line -e libflutter.so -f -C 0x7f8b2c3d4e50
  ```
- **重点关注 Frame 0**（最顶层），那是崩溃发生的直接位置

**第 4 步**：搜索崩溃**之前**的日志（找到"导火索"）

```bash
# 崩溃前 5-10 秒的日志通常包含触发原因
hdc shell hilog | grep -B 50 "Caught signal"
```

> `-B 50` 表示搜到关键词后再往前看 50 行。就像查案要看案发前的监控录像一样。

### 2.6 常见崩溃场景和修复方法

#### 场景 1：GPU 驱动崩溃

**怎么认出它？** 堆栈里有 `GPUSurface`、`Rasterizer`、`SkSurface` 这些词。

**可能的原因和修复方法**：

| 原因 | 怎么排查 | 怎么修 |
|------|---------|--------|
| GPU 回收后没恢复就渲染 | 搜索 `GpuReclaim`，看是否有 `Surface REBUILT` | 确保 `OnGrContextCreated` 完成后再渲染（详见 [dfx-memory.md](dfx-memory.md) §3） |
| Surface 重建失败 | 搜索 `SetDisplayWindow failed` | 检查 native_window 是否还有效 |
| Vulkan 驱动 bug | 检查是否用 Vulkan 后端 | 尝试切换到 OpenGL ES 后端 |
| 着色器太复杂 | 检查是否有复杂的自定义 Shader | 简化 Fragment Shader |

#### 场景 2：纹理释放后还在访问

**怎么认出它？** 堆栈里有 `Texture`、`external_texture`、`OHOSExternalTexture`。

**通俗解释**：就像你把一个快递箱扔了，但还有人去箱子里拿东西——当然会出问题。

| 原因 | 怎么排查 | 怎么修 |
|------|---------|--------|
| 注销纹理后原生侧还在写入 | 搜索 `UnRegisterExternalTexture` | **先停生产者，再注销纹理**（顺序很重要） |
| 外部 NativeImage 被提前释放 | 搜索 `SetExternalNativeImage` | 确保外部资源的生命周期比纹理长 |
| GPU 上下文销毁后还引用 GPU 资源 | 搜索 `OnGrContextDestroyed` | 确认 `OnTextureUnregistered` 释放了资源 |

**正确的注销顺序**（详见 [dfx-texture.md](dfx-texture.md) §3）：
```typescript
// 第 1 步：先停止原生侧的生产（比如暂停视频播放）
stopProducer();
// 第 2 步：再注销纹理
textureRegistry.unregisterTexture(textureId);
```

#### 场景 3：引擎重复释放

**怎么认出它？** 堆栈里有 `~Shell`、`Destroy`，信号是 SIGABRT。

**通俗解释**：就像你退房时把钥匙还了，又还了一次——前台就懵了。

| 原因 | 怎么排查 | 怎么修 |
|------|---------|--------|
| 多次调用 `engine.destroy()` | 搜索 `FLUTTER_ENGINE_DESTROY` 出现次数 | 加 null 检查，确保只销毁一次 |
| 分栏模式误触发 `onDestroy` | 检查 `FlutterPage.onDestroy` 调用时机 | 分栏模式下检查是否被误调用 |

```typescript
// 正确的写法：加 null 检查
onAbilityDestroy() {
  this.flutterEngine?.destroy();
  this.flutterEngine = null;  // 防止重复销毁
}
```

#### 场景 4：Skia 渲染异常

**怎么认出它？** 堆栈里有 `SkCanvas`、`SkSurface`、`GrDirectContext`。

| 原因 | 怎么排查 | 怎么修 |
|------|---------|--------|
| CustomPainter 访问了已释放资源 | 检查 CustomPainter 是否持有外部引用 | 确保不持有会被释放的外部资源 |
| GPU 上下文丢失后继续渲染 | 搜索 `GpuReclaim` | 在 `OnGrContextDestroyed` 后暂停渲染 |
| Picture 跨 isolate 传递 | 检查是否在 isolate 间传递 Picture | 用 `toImage` 转换后再传递 |

---

## 3. Dart 异常（你的代码有 bug）

### 3.1 什么是 Dart 异常？

这是最常见的崩溃原因——你的 Dart 代码里有未被 `try-catch` 捕获的异常。比如你调用了 `null.toString()`，或者访问了 `list[100]` 但列表只有 10 个元素。

当 Dart 异常未被捕获时，会导致 isolate 退出，应用闪退。引擎会自动捕获并记录到日志。

> **新手提示**：Dart 异常是最容易修的崩溃类型，因为日志里会直接告诉你出错的是哪一行代码。

### 3.2 具体现象

| 你看到的现象 | 严重程度 | 说明 |
|-------------|---------|------|
| 应用闪退，日志有 `Unhandled exception` | 高 | 最常见，你的 Dart 代码有未捕获的异常 |
| 异常信息不完整（被截断） | 中 | 错误信息超长（>4096 字符）被截断了 |
| 只有 HiLog 没有 HiAppEvent | 中 | 系统 API 版本太低（< 18） |
| 异步代码里的异常 | 高 | `Future` 没 `await` 或没 `.catchError` |

### 3.3 日志长什么样？

**HiLog 输出**：
```
E Flutter: Unhandled exception:
E Flutter: type 'Null' is not a subtype of type 'String'
E Flutter: #0      main (package:myapp/main.dart:12:5)
E Flutter: #1      _runMain (package:myapp/main.dart:8:3)
```

**怎么读这些日志？**
- 第一行 `Unhandled exception:` → 告诉你这是未捕获的 Dart 异常
- 第二行 `type 'Null' is not a subtype of type 'String'` → 这就是错误原因：你试图把 null 当成 String 用
- `#0 main (package:myapp/main.dart:12:5)` → 这是出错的代码位置！
  - `#0` 是第 0 帧（最直接的出错位置）
  - `package:myapp/main.dart` → 你的 `main.dart` 文件
  - `12:5` → 第 12 行第 5 列

> **新手提示**：直接打开日志里标注的文件和行号，通常一眼就能看出问题。

### 3.4 怎么排查？（分 4 步走）

**第 1 步**：搜索日志，拿到完整堆栈

```bash
hdc shell hilog | grep -A 30 "Unhandled exception"
```

**第 2 步**：打开日志里标注的代码文件，定位到出错的行

- 格式：`#帧号 函数名 (文件路径:行号:列号)`
- 从 `#0` 开始看，找到 `package:你的应用名/` 开头的行——那就是你的代码
- `dart:` 和 `package:flutter/` 开头的是框架代码，通常不是你的问题

**第 3 步**：根据异常类型判断原因

| 异常类型 | 通俗解释 | 常见场景 | 怎么修 |
|---------|---------|---------|--------|
| `NoSuchMethodError` | 在 null 上调用了方法 | `null.toString()` | 加空判断：`obj?.toString()` |
| `TypeError` | 类型不匹配 | `value as String` 但 value 是 null | 用安全转换：`value?.toString() ?? ''` |
| `RangeError` | 索引越界了 | `list[100]` 但列表只有 10 个元素 | 加边界检查 |
| `StateError` | 对象状态不对 | 读已关闭的 StreamController | 检查对象状态 |
| `FormatException` | 格式不对 | `json.decode('invalid')` | 检查输入格式 |
| `Stack Overflow` | 栈溢出 | 递归没有终止条件 | 加递归终止条件 |
| `LateInitializationError` | late 变量没初始化就用了 | `late String s;` 然后直接用 `s` | 确保使用前已赋值 |

**第 4 步**：用 DevTools 调试（更直观）

```bash
flutter run --ohos
# 在浏览器打开 DevTools
# 开启 "Stop on uncaught exceptions"（遇到未捕获异常时暂停）
# 复现问题，调试器会在出错的地方暂停，你可以看到所有变量的值
```

### 3.5 常见 Dart 异常和修复方法

#### 问题 1：空指针（最常见！）

**出错代码**：
```dart
// 假设 user 可能为 null
String name = user.name.toUpperCase();  // 如果 user 是 null，这里就崩了
```

**修复方法**：
```dart
// 方法 1：用 ?. 安全调用（推荐）
String name = user?.name?.toUpperCase() ?? 'unknown';

// 方法 2：先判断再使用
if (user != null) {
  String name = user.name.toUpperCase();
}
```

#### 问题 2：异步异常没捕获

**出错代码**：
```dart
// 这个异常不会被 try-catch 捕获，因为它没有 await！
Future.delayed(Duration(seconds: 1), () {
  throw Exception('异步出错');
});  // 没有 await，异常会丢失或导致闪退
```

**修复方法**：
```dart
// 方法 1：加 await + try-catch
try {
  await Future.delayed(Duration(seconds: 1), () {
    throw Exception('异步出错');
  });
} catch (e, s) {
  print('捕获到异常: $e\n$s');
}

// 方法 2：用 catchError
Future.delayed(Duration(seconds: 1), () {
  throw Exception('异步出错');
}).catchError((e, s) {
  print('捕获到异常: $e\n$s');
});

// 方法 3（推荐）：全局兜底，在 main 中用 runZonedGuarded
runZonedGuarded(() {
  runApp(MyApp());
}, (error, stackTrace) {
  // 所有未捕获的异常都会到这里
  print('全局捕获: $error\n$stackTrace');
});
```

#### 问题 3：类型转换出错

**出错代码**：
```dart
// 如果 JSON 里 name 是 null，这里就崩了
String name = json['name'] as String;

// 如果 JSON 里 price 是 100（int），这里也崩了
double price = json['price'] as double;
```

**修复方法**：
```dart
// 安全的字符串转换
String name = json['name']?.toString() ?? '';

// 安全的数字转换（int 和 double 都能处理）
double price = (json['price'] as num)?.toDouble() ?? 0.0;
```

#### 问题 4：数组越界

**出错代码**：
```dart
var item = items[index];  // 如果 index 超出范围就崩了
```

**修复方法**：
```dart
// 方法 1：加边界检查
if (index >= 0 && index < items.length) {
  var item = items[index];
}

// 方法 2：用 elementAtOrNull（Dart 3.0+）
var item = items.elementAtOrNull(index);  // 越界返回 null 而不是崩溃
```

#### 问题 5：MethodChannel 回调里出错

**出错代码**：
```dart
// 如果 _loadData() 抛异常，应用就闪退了
_methodChannel.setMethodCallHandler((call) async {
  if (call.method == 'getData') {
    return _loadData();  // 这里抛异常会导致闪退
  }
});
```

**修复方法**：
```dart
_methodChannel.setMethodCallHandler((call) async {
  try {
    if (call.method == 'getData') {
      return await _loadData();
    }
  } catch (e, s) {
    print('MethodChannel 出错: $e\n$s');
    return null;  // 返回默认值，不要让异常跑出去
  }
});
```

### 3.6 注意事项

- 错误信息最长 4096 字符，超出会被截断（如果信息不完整，去 HiLog 里搜完整的）
- 堆栈最长 8192 字符，超出会被截断
- 系统 API 低于 18 时不会生成 HiAppEvent 事件（但 HiLog 仍然有）

---

## 4. ETS 异常（ArkTS 插件层异常）

### 4.1 什么是 ETS 异常？

ETS 是 ArkTS 的简称（OHOS 的编程语言）。当你的 ArkTS 插件代码在处理 MethodChannel 消息时出错，就会产生 ETS 异常。

> **新手提示**：
> - ETS 异常通常**不会导致应用闪退**（被 try-catch 捕获了）
> - 但会导致**某个功能用不了**（比如 MethodChannel 调用无响应）
> - 如果你在用第三方插件，这个问题可能是插件代码的 bug

### 4.2 具体现象

| 你看到的现象 | 严重程度 | 说明 |
|-------------|---------|------|
| MethodChannel 调用无响应 | 中 | 插件 handler 出错，没返回结果 |
| 某个功能突然用不了 | 中 | ETS 异常被捕获但功能失败 |
| 应用没闪退但功能异常 | 低 | ETS 异常不会导致闪退 |
| MethodChannel 返回 error | 低 | 插件捕获异常后返回了错误信息 |

### 4.3 日志长什么样？

**HiLog 输出**（搜索 `Failed to handle` 或 `FLUTTER_ETS_EXCEPTION`）：
```
E Flutter: MethodChannel# Failed to handle method call
E Flutter: TypeError: Cannot read property 'length' of undefined
E Flutter:     at MethodChannel.onMessage (MethodChannel.ets:227:15)
```

**怎么读这些日志？**
- `Failed to handle method call` → MethodChannel 消息处理失败
- `TypeError: Cannot read property 'length' of undefined` → 你试图读取一个 undefined 的 length 属性
- `at MethodChannel.onMessage (MethodChannel.ets:227:15)` → 出错位置在 MethodChannel.ets 文件第 227 行

### 4.4 怎么排查？

**第 1 步**：搜索 ETS 异常日志

```bash
hdc shell hilog | grep -E "FLUTTER_ETS_EXCEPTION|Failed to handle|Uncaught exception in"
```

**第 2 步**：根据 CONTEXT 确定异常发生在哪个环节

| CONTEXT 值 | 通俗解释 | 排查方向 |
|-----------|---------|---------|
| `MethodChannel.onMessage` | 插件接收消息时出错 | 检查插件的 `onMethodCall` 方法 |
| `MethodChannel.reply` | 处理返回结果时出错 | 检查 Dart 侧的回调代码 |
| `DartMessenger.invokeHandler` | 二进制消息处理出错 | 检查 BinaryMessageHandler |
| `DartMessenger.handlePlatformMessageResponse` | 消息回复处理出错 | 检查 BinaryReply 回调 |

**第 3 步**：打开出错的 ETS 文件，定位到行号

- STACK_TRACE 格式：`at 函数名 (文件:行号:列号)`
- 重点关注 `undefined` / `null` 访问

### 4.5 常见原因和修复方法

#### 问题 1：MethodChannel 参数为 undefined

**出错代码**（ArkTS 插件）：
```typescript
// 如果 call.argument("name") 返回 undefined，下面就崩了
onMethodCall(call: MethodCall, result: MethodResult): void {
  const name: string = call.argument("name");
  const length = name.length;  // undefined.length → 崩溃
}
```

**修复方法**：
```typescript
onMethodCall(call: MethodCall, result: MethodResult): void {
  const name = call.argument("name");
  // 先判空！
  if (name === undefined || name === null) {
    result.error("INVALID_ARGS", "name 参数不能为空", null);
    return;
  }
  const length = (name as string).length;
}
```

#### 问题 2：消息编解码不匹配

**现象**：Dart 侧和 ETS 侧使用不同的 Codec（编解码器），导致参数解析失败。

**修复方法**：
```dart
// 确保两侧使用相同的 Codec
// Dart 侧默认用 StandardMethodCodec
// ETS 侧也用 StandardMethodCodec（默认）

// 如果用了自定义 Codec，确保两侧一致
// 检查参数类型是否匹配：
// Dart int    ↔ ETS number
// Dart String ↔ ETS string
// Dart bool   ↔ ETS boolean
// Dart List   ↔ ETS Array
// Dart Map    ↔ ETS object
```

### 4.6 特点

- ETS 异常**不会导致应用闪退**（被 try-catch 捕获了）
- `MethodChannel.onMessage` 捕获后会自动返回 error 给 Dart 侧
- `DartMessenger.invokeHandler` 捕获后会发送空回复
- 但功能会受影响（消息处理失败）

---

## 5. 崩溃排查清单

遇到崩溃时，按这个清单一步步来：

### 第一步：确认崩溃类型

- [ ] 抓取全量日志：`hdc shell hilog > flutter_log.txt`
- [ ] 搜索 `Caught signal` → 有就是 Native 崩溃（§2）
- [ ] 搜索 `Unhandled exception` → 有就是 Dart 异常（§3）
- [ ] 搜索 `FLUTTER_ETS_EXCEPTION` / `Failed to handle` → 有就是 ETS 异常（§4）

### 第二步：如果是 Native 崩溃

- [ ] 记录信号类型（SIGSEGV? SIGABRT?）
- [ ] 记录堆栈中的函数名和地址
- [ ] 函数名是 `Unknown` 的用 `addr2line` 解析
- [ ] 搜索崩溃前 50 行日志找"导火索"：`grep -B 50 "Caught signal"`
- [ ] 搜索 `GpuReclaim` 确认是否和 GPU 有关
- [ ] 搜索 `UnRegisterExternalTexture` 确认是否和纹理有关

### 第三步：如果是 Dart 异常

- [ ] 阅读完整堆栈，找到 `package:你的应用名/` 的行
- [ ] 打开对应的代码文件和行号
- [ ] 确认异常类型（空指针? 类型错误? 越界?）
- [ ] 检查是否是异步异常（Future 没 await / 没 catchError）
- [ ] 用 DevTools 的 "Stop on uncaught exceptions" 调试

### 第四步：如果是 ETS 异常

- [ ] 根据 CONTEXT 确定异常发生环节
- [ ] 打开对应的 ETS 文件和行号
- [ ] 检查参数是否为 undefined / null
- [ ] 检查 MethodChannel 参数类型是否匹配

### 通用

- [ ] 记录崩溃前的操作场景（点了什么按钮、进了什么页面）
- [ ] 检查是否能稳定复现（能复现的 bug 最好修）

---

## 6. HiAppEvent 事件参数

### 6.1 FLUTTER_DART_EXCEPTION

| 参数 | 类型 | 限制 | 说明 |
|------|------|------|------|
| `frameworkName` | String | — | 固定 `"FLUTTER"` |
| `errorMsg` | String | ≤4096 字符 | 异常错误信息 |
| `stackTrace` | String | ≤8192 字符 | 异常堆栈 |
| `pid` | Int64 | — | 进程 ID |
| `timeStamp` | Int64 | — | 事件时间 (UTC ms) |

### 6.2 FLUTTER_ETS_EXCEPTION

| 参数 | 类型 | 说明 |
|------|------|------|
| `EVENT_NAME` | String | 固定 `"FLUTTER_ETS_EXCEPTION"` |
| `CONTEXT` | String | 异常发生环节（见 §4.4） |
| `ERROR_MSG` | String | 异常错误信息 |
| `STACK_TRACE` | String | 异常堆栈 |
