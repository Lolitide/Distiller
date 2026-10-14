# 内存与 GPU 问题定位指南

> 返回 [README.md](README.md)

---

## 1. 问题类型

本文档覆盖以下问题：

| 问题 | 你看到的现象 | 日志关键词 | 通俗解释 |
|------|------------|-----------|---------|
| **Dart 内存超限** | 应用卡顿、OOM 闪退 | `Dart heap memory usage exceeds threshold` | 你的 Dart 代码用了太多内存（>1.5GB） |
| **GPU 上下文丢失** | 黑屏、白屏、渲染异常 | `GpuReclaim` | 退后台时系统回收了 GPU 资源 |
| **引擎生命周期异常** | 引擎创建/销毁异常 | `FLUTTER_ENGINE_CREATE/DESTROY` | 引擎没正常创建或被意外销毁 |
| **Vsync 管道故障** | 不渲染、渲染卡顿 | `vsync` / `Poll error` | 垂直同步信号出问题了 |

---

## 2. Dart 内存超限

### 2.1 通俗解释

Flutter 引擎每隔 10 秒检查一次 Dart 代码用了多少内存。如果超过了 **1.5GB**，就会报警并记录到日志。

> **打个比方**：就像你家水表，每隔 10 秒看一次用水量，如果超过 1.5 吨就报警。

| 参数 | 值 | 说明 |
|------|-----|------|
| 阈值 | 1.5 GB (1536 MB) | 超过这个值就报警 |
| 检查间隔 | 10 秒 | 每 10 秒检查一次 |
| 触发次数 | 单次 | 报警一次后就停止监控了 |

> **注意**：1.5GB 是引擎的检测阈值，但系统级 OOM（内存不足杀进程）可能在更低的内存量时发生——系统看的是整体内存压力，不只是 Dart 的。

### 2.2 具体现象

| 你看到的现象 | 严重程度 | 说明 |
|-------------|---------|------|
| 应用越来越卡 | 中 | GC（垃圾回收）频繁启动，每次 GC 暂停 UI 线程 |
| 应用 OOM 闪退（被系统杀） | 高 | 系统内存不足，直接杀进程 |
| Old Space 持续增长不回落 | 高 | 内存泄漏！对象一直不被释放 |
| 报警后不再监控 | — | 单次触发机制，需重启引擎恢复 |
| 只有 HiLog 没有 HiAppEvent | 中 | 系统 API < 26 |

### 2.3 怎么排查？

**第 1 步**：搜索日志确认是否触发

```bash
hdc shell hilog | grep -E "heap memory|threshold|FrameworkMemAnomaly"
```

**典型日志**：
```
W Flutter: Dart heap memory usage exceeds threshold: total = 1600 MB (old = 1200 MB, new = 400 MB)
```

**怎么读这行日志？**
- `total = 1600 MB` → 总共用了 1600MB（超过 1.5GB 阈值了）
- `old = 1200 MB` → Old Space（长期存活的对象）用了 1200MB
  - **如果 old 持续增长不回落 = 内存泄漏！**
- `new = 400 MB` → New Space（新创建的临时对象）用了 400MB
  - **new 高但 GC 后回落 = 正常，只是短时间分配太多**

**第 2 步**：判断是哪种内存问题

| 内存分布 | 诊断 | 怎么办 |
|---------|------|--------|
| old 高且持续增长 | 内存泄漏 | 检查 `dispose()` 是否正确释放资源 |
| new 高但 GC 后降 | 短时间大量分配 | 优化批量操作，减少临时对象 |
| old + new 都高 | 综合问题 | 先治泄漏，再优化分配 |

**第 3 步**：用 DevTools Memory 精确定位

```bash
flutter run --ohos
# 浏览器打开 DevTools → Memory 标签
# 复现问题前后各抓一次 Heap Snapshot（内存快照）
# 对比两次快照，看哪些对象增加了 → 那就是泄漏的
```

### 2.4 常见原因和修复方法

#### 原因 1：图片缓存太多

**现象**：加载很多图片后内存涨了，页面退出后不回落。

**排查**：
```dart
// 检查图片缓存使用量
print(PaintingBinding.instance.imageCache.currentSize);       // 缓存了多少张图片
print(PaintingBinding.instance.imageCache.currentSizeBytes);  // 缓存占多少字节
```

**修复**：
```dart
// 方法 1：限制图片缓存大小
PaintingBinding.instance.imageCache.maximumSize = 100;           // 默认 1000 张
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;  // 50MB，默认 100MB

// 方法 2：大图用 cacheWidth/cacheHeight 限制解码尺寸
Image.network(
  url,
  cacheWidth: (screenWidth * devicePixelRatio).toInt(),  // 不要解码全尺寸
  cacheHeight: (screenHeight * devicePixelRatio).toInt(),
);
```

#### 原因 2：大列表没有懒加载

**现象**：长列表页面内存暴涨。

**修复**：
```dart
// ❌ 错误：一次性构建所有子项（1000 个全构建了）
ListView(children: items.map((e) => ItemWidget(e)).toList());

// ✅ 正确：懒加载，只构建可见的
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// ✅ 更好：加 itemExtent 进一步优化
ListView.builder(
  itemExtent: 80.0,  // 固定高度，引擎不用测量每个 item
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);
```

#### 原因 3：资源没释放（内存泄漏）

**现象**：页面退出后内存不回落，反复进出页面内存持续增长。

**修复**：确保在 `dispose()` 中释放所有资源：
```dart
class _MyPageState extends State<MyPage> {
  late StreamSubscription _sub;
  late AnimationController _controller;
  late TextEditingController _textController;

  @override
  void dispose() {
    // 必须释放！否则就是内存泄漏
    _sub.cancel();             // 取消 Stream 订阅
    _controller.dispose();     // 释放动画控制器
    _textController.dispose(); // 释放文本控制器
    super.dispose();
  }
}
```

#### 原因 4：Isolate 没关闭

**现象**：用了 `Isolate.spawn` 后内存不释放。

**修复**：
```dart
Isolate? isolate;

Future<void> startWork() async {
  final receivePort = ReceivePort();
  isolate = await Isolate.spawn(_entryPoint, receivePort.sendPort);
}

void stopWork() {
  isolate?.kill(priority: Isolate.immediate);  // 用完后关闭
  isolate = null;
}

// 提示：compute() 会自动管理 Isolate 生命周期，优先使用
final result = await compute(_heavyTask, data);
```

### 2.5 注意事项

- 内存监控是**单次触发**：报警一次后就停止了，需要重启引擎才能恢复监控
- 1.5GB 是引擎的检测阈值，系统 OOM 可能在更低内存时发生
- **Old Space 持续增长 = 内存泄漏**（最重要的判断依据）

---

## 3. GPU 上下文丢失

### 3.1 通俗解释

当应用退到后台或系统内存不足时，OHOS 系统会回收 GPU 资源（为了省电/省内存）。这就像你工作时电脑突然关机了——你的"工作环境"（GPU 上下文）丢了。

Flutter 引擎会自动处理这个过程：
- **退后台时**：清理 GPU 资源（`kAggressive`，激进回收）
- **回前台时**：重建 GPU 上下文（`kRestore`，恢复）

重建期间画面会短暂黑屏，这是**正常行为**。但如果重建失败，就会持续黑屏。

### 3.2 具体现象

| 你看到的现象 | 严重程度 | 说明 |
|-------------|---------|------|
| 退后台再回前台，短暂黑屏后恢复 | 正常 | GPU 回收后成功恢复 |
| 回前台后持续黑屏/白屏 | 高 | Surface 重建失败了 |
| 回前台后画面卡顿几秒 | 中 | 重建耗时较长 |
| 图片显示异常 | 低 | 图片缓存被清理了（正常），需要重新加载 |
| 退后台后视频/纹理不更新 | 正常 | 帧闸门开启（正常行为） |
| 反复黑屏闪烁 | 中 | 生命周期状态抖动（频繁切换前后台） |

### 3.3 怎么排查？

**第 1 步**：搜索 GPU 回收日志

```bash
hdc shell hilog | grep "GpuReclaim"
```

**第 2 步**：按时间线分析（正常的"退后台→回前台"流程）

```
[T+0]   GpuReclaim: Lifecycle Resumed -> Paused        ← 退后台了
[T+0]   GpuReclaim: Restore -> Aggressive              ← 决定：回收 GPU
[T+0]   GpuReclaim: ExecuteAggressive - deferring 1000ms  ← 延迟 1 秒执行（等 PiP 检测）
[T+0]   GpuReclaim: Sending memoryPressure            ← 通知 Dart 清理图片缓存
[T+0]   GpuReclaim: [Raster] Surface torn down        ← GPU 资源已释放

[T+N]   GpuReclaim: Lifecycle Paused -> Resumed       ← 回前台了
[T+N]   GpuReclaim: Aggressive -> Restore             ← 决定：恢复
[T+N]   GpuReclaim: Rebuilding onscreen context       ← 正在重建
[T+N]   GpuReclaim: [Raster] Surface REBUILT          ← 重建成功！画面恢复
```

> **看到 `Surface REBUILT` 就是成功了**。如果看到 `SetDisplayWindow failed` 就是失败了。

### 3.4 常见问题和修复方法

#### 问题 1：回前台后持续黑屏

**排查**：搜索 `SetDisplayWindow failed during rebuild`

| 原因 | 怎么修 |
|------|--------|
| Surface 重建失败 | 检查 native_window 是否还有效 |
| 重建未执行 | 检查 `ExecuteRestore` 日志是否存在 |
| 应用层 `onDestroy` 被过早调用 | 确保 `FlutterPage.onDestroy` 在真正销毁时才调用 |

**应用层检查**（FlutterPage.ets）：
```typescript
// 确保 onLoad/onDestroy 正确配对
.onLoad((context) => {
  this.flutterView = FlutterManager.getInstance().getFlutterView(this.viewId);
  this.surfaceLifecycleToken = this.flutterView?.onSurfaceCreated() ?? 0;
})
.onDestroy(() => {
  // 必须在真正销毁时才调用，不能提前
  this.flutterView?.onSurfaceDestroyed(this.surfaceLifecycleToken);
  this.flutterView = null;
})
```

#### 问题 2：退后台后纹理/视频还在耗电

**排查**：搜索 `frame gate enabled`

| 原因 | 怎么修 |
|------|--------|
| 生命周期没正确传到引擎 | 确保 `onPageShow`/`onPageHide` 被正确调用 |
| 插件没实现暂停逻辑 | 插件实现 `onInactive()`/`onActive()`（详见 [dfx-texture.md](dfx-texture.md) §7） |

**应用层检查**：
```typescript
// FlutterAbilityAndEntryDelegate.ets 必须转发页面可见性
onPageShow() {
  this.flutterView?.onPageVisibilityChanged(true);
}
onPageHide() {
  this.flutterView?.onPageVisibilityChanged(false);
}
```

#### 问题 3：图片显示异常

**原因**：GPU 回收时图片缓存被清理了（`Sending memoryPressure`），重新显示时需要重新解码。

**修复**：
```dart
// 回前台后预加载关键图片
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    precacheImage(AssetImage('assets/key_image.png'), context);
  }
}
```

### 3.5 关键日志速查

| 日志 | 通俗解释 | 正常吗 |
|------|---------|--------|
| `GpuReclaim: Restore -> Aggressive` | 系统开始回收 GPU | 正常（退后台时） |
| `GpuReclaim: Aggressive -> Restore` | 系统开始恢复 GPU | 正常（回前台时） |
| `Surface torn down` | GPU 资源已释放 | 正常 |
| `Surface REBUILT` | 重建成功 | 正常 |
| `SetDisplayWindow failed` | 重建失败 | **异常！** |
| `frame gate enabled` | 帧闸门开启 | 正常（退后台时） |
| `Sending memoryPressure` | 通知清理图片缓存 | 正常 |
| `Deferred aggressive cancelled - PiP visible` | PiP 可见，取消回收 | 正常（PiP 场景） |

---

## 4. 引擎生命周期

### 4.1 通俗解释

Flutter 引擎是整个应用的核心。就像汽车的发动机——发动机没启动，车就开不了；发动机意外熄火，车就抛锚了。

| 事件 | 通俗解释 | 触发时机 |
|------|---------|---------|
| `FLUTTER_ENGINE_CREATE` | 发动机启动了 | 应用启动 / 引擎初始化 |
| `FLUTTER_ENGINE_DESTROY` | 发动机关闭了 | 应用退出 / 引擎销毁 |

### 4.2 具体现象

| 你看到的现象 | 严重程度 | 说明 |
|-------------|---------|------|
| 应用启动后白屏 | 高 | 引擎没创建成功 |
| 应用闪退（无 Dart 异常） | 高 | 引擎意外销毁 |
| 内存持续增长 | 高 | 引擎重复创建但没销毁 |
| 内存监控不工作 | 中 | 引擎创建时没启动监控 |

### 4.3 怎么排查？

```bash
hdc shell hilog | grep -E "FLUTTER_ENGINE_CREATE|FLUTTER_ENGINE_DESTROY"
```

**检查 CREATE 和 DESTROY 是否成对**：正常情况应该是 1:1 配对的。如果 CREATE 多于 DESTROY，说明有引擎没被销毁（内存泄漏）。

### 4.4 常见问题和修复方法

#### 问题 1：引擎创建失败（白屏）

| 原因 | 怎么修 |
|------|--------|
| Flutter 配置错误 | 检查 `flutter_ohos.json5` 配置 |
| Dart bundle 加载失败 | 检查 `flutter_assets` 是否完整打包 |
| SO 库加载失败 | 检查 `libflutter.so` 是否正确打包 |

#### 问题 2：引擎重复创建（内存泄漏）

```typescript
// ❌ 错误：每次都创建新引擎
getEngine(): FlutterEngine {
  return new FlutterEngine(context);  // 每次都 new！
}

// ✅ 正确：复用引擎
private flutterEngine: FlutterEngine | null = null;

getEngine(): FlutterEngine {
  if (this.flutterEngine === null) {
    this.flutterEngine = new FlutterEngine(context);
  }
  return this.flutterEngine;
}
```

---

## 5. Vsync 管道故障

### 5.1 通俗解释

Vsync（垂直同步）是驱动屏幕刷新的核心信号。你可以把它理解为"节拍器"——每秒打 60 次拍子，Flutter 跟着拍子画帧。如果节拍器坏了，Flutter 就不知道什么时候该画帧了。

### 5.2 具体现象

| 你看到的现象 | 严重程度 | 对应日志 |
|-------------|---------|---------|
| 完全不渲染（画面静止） | 致命 | `vsync_handle_ is nullptr` |
| 偶发卡顿 | 中 | `AwaitVSync...failed` |
| 帧率无法设置（120fps 无效） | 中 | `SetExpectedFrameRateRange failed` |
| 不渲染 + 卡死 | 致命 | `Failed to dlopen libnative_vsync.so` |

### 5.3 怎么排查？

```bash
hdc shell hilog | grep -E "vsync|Vsync|VSync|Poll error"
```

| 日志 | 通俗解释 | 严重程度 |
|------|---------|---------|
| `vsync_handle_ is nullptr` | Vsync 句柄无效（节拍器没装上） | 致命 |
| `AwaitVSync...failed:` | 请求 Vsync 失败（节拍器不响了） | 致命 |
| `Failed to dlopen libnative_vsync.so` | Vsync 库加载失败 | 致命 |
| `SetExpectedFrameRateRange failed` | 帧率设置失败 | 中 |
| `Poll error:` | 消息循环出错 | 中 |

### 5.4 常见问题和修复方法

| 问题 | 原因 | 怎么修 |
|------|------|--------|
| 完全不渲染 | Vsync 库没加载 | 确认设备系统版本支持 NativeVSync API |
| 偶发卡顿 | 系统繁忙导致 Vsync 请求偶尔失败 | 引擎有重试机制，频繁失败需检查系统状态 |
| 120fps 无效 | 设备或系统不支持 | 确认设备支持 120fps，系统 API 支持帧率设置 |

---

## 6. 排查清单

### 内存问题

- [ ] 搜索 `Dart heap memory` 确认是否触发
- [ ] 看 `old` 和 `new` 值判断是泄漏还是大量分配
- [ ] old 持续增长 → 用 DevTools Memory 抓快照找泄漏
- [ ] 检查图片缓存、列表懒加载、dispose 释放

### GPU 问题

- [ ] 搜索 `GpuReclaim` 看完整的回收/恢复流程
- [ ] 检查是否有 `Surface REBUILT`（成功）或 `SetDisplayWindow failed`（失败）
- [ ] 检查退后台是否有 `frame gate enabled`（正常）
- [ ] 检查回前台是否有 `ExecuteReclaimRestore`（正常）
- [ ] 检查应用层 `onPageShow`/`onPageHide` 是否正确转发

### 引擎生命周期

- [ ] 搜索 `FLUTTER_ENGINE_CREATE` / `FLUTTER_ENGINE_DESTROY`
- [ ] 检查是否 1:1 配对
- [ ] 多引擎场景检查是否复用

### Vsync 问题

- [ ] 搜索 `vsync` / `Poll error`
- [ ] 检查 `vsync_handle_ is nullptr` 是否出现
- [ ] 检查 `libnative_vsync.so` 是否加载成功
