# 卡死冻屏问题定位指南

> 返回 [README.md](README.md)

---

## 1. 什么是应用卡死？

应用卡死（AppFreeze）就是应用"冻住了"——界面不更新、点按钮没反应、滑动没效果。就像电脑死机一样。

Flutter 应用有三个关键线程（可以理解为三个"工人"），任何一个"罢工"了都会导致卡死：

| 线程（工人） | 负责什么 | 卡死时的表现 | 严重程度 |
|-------------|---------|------------|---------|
| **UI 线程** | 运行你的 Dart 代码、构建界面 | 界面完全冻结，触摸无响应 | 致命 |
| **Raster 线程**（画画的工人） | 把界面画成像素交给 GPU | 界面不更新，但触摸可能有响应 | 严重 |
| **Platform 线程**（和系统打交道的工人） | 处理触摸事件、系统消息 | 系统消息阻塞，可能间接卡 UI | 严重 |

> **新手提示**：
> - **UI 线程卡死**是最严重的，6 秒后系统可能会弹出"应用无响应"弹窗或直接杀掉你的应用
> - **Raster 线程**阻塞不会直接被检测到，但会导致帧画不出来，间接把 UI 线程也拖死
> - **Platform 线程**阻塞会导致系统消息（触摸、键盘等）无法处理

### 1.1 卡死检测机制（引擎怎么知道卡死了？）

Flutter 引擎内置了一个"看门狗"（Watchdog），就像一个巡逻保安：

```
保安每 3 秒巡逻一次
│
├─ 给 UI 线程发一个"签到"请求
│
└─ 3 秒后检查：
   ├─ UI 线程签到了 → 正常，继续巡逻
   └─ UI 线程没签到 → 卡死了！触发报警
      ├─ 卡死 3 秒 → 记录一次事件（不弹窗）
      └─ 卡死 6 秒 → 上报系统，可能弹"无响应"弹窗
```

> **注意**：看门狗直接监控的是 **UI 线程**。Raster 和 Platform 线程阻塞会间接导致 UI 线程卡死（比如 Raster 不画帧，UI 线程等着提交帧也卡住了），最终被 UI 线程的看门狗检测到。

### 1.2 两阶段上报（3 秒和 6 秒的区别）

| 阶段 | 卡死时间 | 会发生什么 | 用户能看到吗 |
|------|---------|-----------|------------|
| 第 1 阶段 | 3 秒 | 记录到日志，**不弹窗** | 用户可能感觉到卡，但没弹窗 |
| 第 2 阶段 | 6 秒 | 上报系统，**可能弹"应用无响应"弹窗** | 用户看到弹窗，可选择"等待"或"关闭" |

---

## 2. 怎么定位卡死问题？

### 2.1 快速定位流程

```
应用卡死了
│
├─ 在日志里搜索 "is not alive"
│  └─ 搜到了 "FlutterUiThread is not alive" → UI 线程卡死了 → 看 §3
│
├─ 在日志里搜索 "FLUTTER_THREAD_STUCK"
│  └─ 搜到了 → 看门狗检测到卡死，看 description 确定哪个线程
│
├─ 在日志里搜索 "APP_FREEZE"
│  └─ 搜到了 → UI 线程卡死超过 6 秒，系统要杀进程了
│
└─ 找间接原因（为什么卡死？）
   ├─ 搜索 "GpuReclaim" → GPU 回收导致 Raster 阻塞 → 看 §4
   ├─ 搜索 "handlePlatformMessage" → 平台通道阻塞 → 看 §5
   └─ 搜索 "external_texture" → 纹理回调阻塞 → 看 §4
```

> **最关键的一步**：一定要看**卡死前 5-10 秒的日志**！卡死的原因通常在看门狗报警之前就发生了。就像查车祸事故，要看撞车前的行车记录仪。

---

## 3. UI 线程卡死

### 3.1 怎么确认是 UI 线程卡死？

**搜索命令**：
```bash
hdc shell hilog | grep -E "FlutterUiThread|FlutterWatchdog|HiCollie"
```

**典型日志（你会看到这样的内容）**：
```
[T+3s] E Flutter: FlutterWatchdog: FlutterUiThread is not alive
[T+3s] W Flutter: FlutterWatchdog: calling OH_HiCollie_Report(), m_is_six_second_event = false
[T+3s] I Flutter: FlutterWatchdog: OH_HiCollie_Report() success
[T+3s] HiAppEvent: FLUTTER_STABILITY_EVENT, eventName=FLUTTER_THREAD_STUCK
                  description: "Flutter UI thread stuck. isSixSecondEvent=false"

[T+6s] E Flutter: FlutterWatchdog: FlutterUiThread is not alive
[T+6s] W Flutter: FlutterWatchdog: calling OH_HiCollie_Report(), m_is_six_second_event = true
[T+6s] HiAppEvent: FLUTTER_STABILITY_EVENT, eventName=FLUTTER_THREAD_STUCK
                  description: "Flutter UI thread stuck. isSixSecondEvent=true"
[T+6s] 系统生成 APP_FREEZE 事件（可能弹出"应用无响应"弹窗）
```

**怎么读这些日志？**
- `FlutterUiThread is not alive` → UI 线程 3 秒没响应了
- `m_is_six_second_event = false` → 第 1 阶段（卡死 3 秒），只记录不弹窗
- `m_is_six_second_event = true` → 第 2 阶段（卡死 6 秒），可能弹窗
- `APP_FREEZE` → 系统级卡死事件，可能杀进程

### 3.2 具体现象

| 你看到的现象 | 严重程度 | 说明 |
|-------------|---------|------|
| 界面完全冻结，点哪里都没反应 | 致命 | UI 线程被长时间阻塞 |
| 6 秒后弹出"应用无响应"弹窗 | 致命 | 系统级 APP_FREEZE 触发 |
| 卡了一会儿后自动恢复 | 中 | 3 秒阶段记录但 6 秒前恢复了 |

### 3.3 怎么排查？

**第 1 步**：搜索卡死日志

```bash
hdc shell hilog | grep -E "FlutterUiThread|FlutterWatchdog|FLUTTER_THREAD_STUCK"
```

**第 2 步**：**看卡死前的日志**（这一步最重要！）

```bash
hdc shell hilog > flutter_log.txt
# 在日志文件中找到 "is not alive" 的行，往上翻 5-10 秒的日志
# 那里面通常藏着卡死的"罪魁祸首"
```

**第 3 步**：抓取 HiTrace 分析（如果能复现）

```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace
# 用 Chrome 打开 chrome://tracing → Load 文件
# 搜索 "feedFlutterWatchdog" 检查心跳是否中断
```

### 3.4 常见原因和修复方法

#### 原因 1：Dart 代码里有死循环或死锁

**通俗解释**：你的代码陷入了无限循环，或者两个锁互相等待，UI 线程就永远跑不出来了。

**修复方法**：
```dart
// ❌ 错误：死循环（condition 永远不为 true）
while (true) {
  if (condition) break;
}

// ❌ 错误：死锁（两个锁互相等）
// 线程 A 拿了锁 1，等锁 2
// 线程 B 拿了锁 2，等锁 1
// → 两个线程永远等下去

// ✅ 正确：避免嵌套锁，加超时
await lock.synchronized(() async {
  await someWork();
}, timeout: Duration(seconds: 5));
```

#### 原因 2：在主线程做了耗时操作（文件读写、网络请求）

**通俗解释**：UI 线程就像收银台，如果你在收银台慢慢数钱，后面排队的人就都卡住了。

**修复方法**：
```dart
// ❌ 错误：在主线程同步读大文件
final data = File('large_file.json').readAsStringSync();  // 阻塞 UI！

// ✅ 正确：用异步 IO
final data = await File('large_file.json').readAsString();  // 不阻塞

// ✅ 正确：用 compute() 把耗时任务放到独立线程
final data = await compute(_readFile, 'large_file.json');

// ✅ 正确：分批处理大数据
for (var i = 0; i < list.length; i += batchSize) {
  // 处理一批
  await Future.delayed(Duration.zero);  // 让 UI 有机会响应
}
```

#### 原因 3：复杂计算任务阻塞 UI 线程

**通俗解释**：你在主线程里处理 10 万条数据，当然会卡。

**修复方法**：
```dart
// ❌ 错误：在 UI 线程处理 10 万条数据
List<Data> parseData(String json) {
  final list = jsonDecode(json) as List;
  return list.map((e) => Data.fromJson(e)).toList();  // 10 万条会卡死
}

// ✅ 正确：用 compute 移到独立 isolate
final data = await compute(_parseData, json);
```

#### 原因 4：等待锁/信号量但持有者不释放

**通俗解释**：你等着用洗手间，但里面的人不出来（可能崩溃了），你就永远等着。

**修复方法**：
```dart
// ❌ 错误：无超时等待
await lock.synchronized(() async {
  // 如果持有者崩溃了，锁永远不释放
});

// ✅ 正确：加超时
await lock.synchronized(() async {
  // ...
}, timeout: Duration(seconds: 5)).catchError((e) {
  print('锁超时: $e');
  return null;
});
```

---

## 4. Raster 线程阻塞（画画的工人卡了）

Raster 线程负责把界面"画"成像素。它卡了不会直接被看门狗检测到，但会导致帧画不出来，最终把 UI 线程也拖死。

### 4.1 怎么排查？

**搜索命令**：
```bash
# 搜索 GPU 相关日志（GPU 回收经常导致 Raster 阻塞）
hdc shell hilog | grep -E "GpuReclaim|Teardown|SetDisplayWindow|Surface"

# 搜索外接纹理相关日志
hdc shell hilog | grep -E "external_texture|NativeImage|AcquireNativeWindowBuffer"
```

**抓取 HiTrace 检查 Raster 心跳**：
```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter sched -o /data/local/tmp/trace.ftrace
# 在 Chrome 中搜索 "feedFlutterRasterWatchdog" 检查 Raster 心跳
# 搜索 "flutter::Frame" 检查帧渲染耗时
```

### 4.2 常见原因和修复方法

| 原因 | 通俗解释 | 怎么修 |
|------|---------|--------|
| GPU 管线阻塞 | GPU 忙不过来了 | 详见 [dfx-memory.md](dfx-memory.md) §3 |
| Vulkan 渲染开销大 | Vulkan 后端渲染太慢 | 简化场景，或切 OpenGL ES |
| 纹理回调阻塞 | 纹理的"画面传送带"卡了 | 详见 [dfx-texture.md](dfx-texture.md) §4 |
| 图层太多 | 一帧要画太多层 | 减少 Layer 数量，用 `RepaintBoundary` |
| GPU 回收期间阻塞 | 系统回收 GPU 时 Raster 被卡 | 等待 `Surface REBUILT` 后再渲染 |

---

## 5. Platform 线程阻塞（和系统打交道的工人卡了）

Platform 线程负责和 OHOS 系统交互（处理触摸事件、系统消息等）。它卡了会导致系统消息无法处理。

### 5.1 怎么排查？

**搜索命令**：
```bash
hdc shell hilog | grep -E "handlePlatformMessage|onTouchEvent|MethodChannel|DartMessenger"
```

### 5.2 常见原因和修复方法

#### 原因 1：ArkTS 插件处理 MethodChannel 消息时太慢

**通俗解释**：Platform 线程收到 Dart 发来的消息后，会同步调用 ArkTS 插件处理。如果插件处理太慢（比如同步读文件），Platform 线程就卡住了。

**修复方法**（ArkTS 插件代码）：
```typescript
// ❌ 错误：在 onMethodCall 里同步读文件
onMethodCall(call: MethodCall, result: MethodResult): void {
  const data = fs.readFileSync(path);  // 阻塞！
  result.success(data);
}

// ✅ 正确：用异步 IO
async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
  try {
    const data = await fs.readFile(path);  // 不阻塞
    result.success(data);
  } catch (e) {
    result.error("IO_ERROR", e.message, null);
  }
}
```

#### 原因 2：Platform 线程等待 Raster 线程（同步等待）

引擎中有 6 处地方会让 Platform 线程"同步等待" Raster 线程完成。如果 Raster 线程正忙，Platform 线程就会卡住。

这些等待发生在以下操作中：
- Surface 窗口变化（`NotifySurfaceWindowChanged`）
- 窗口尺寸变化（`NotifyChanged`）
- 引擎销毁（`NotifyDestroyed`）
- 纹理注销（`UnRegisterExternalTexture`）
- 纹理替换（`SetExternalNativeImage`）
- 纹理重置（`ResetExternalTexture`）

**修复方法**：这些是引擎内部的同步等待，开发者能做的是避免在 Raster 线程繁忙时触发这些操作。

#### 原因 3：触摸事件处理太慢

Platform 线程还负责分发触摸事件。如果触摸事件处理太慢，会阻塞 Platform 线程。

**修复方法**：确保 ArkTS 侧的触摸事件处理是轻量的，不要在触摸回调里做耗时操作。

---

## 6. 日志关键字速查表

| 搜索这个关键字 | 含义 | 什么时候出现 |
|--------------|------|------------|
| `FlutterUiThread is not alive` | UI 线程卡死了 | UI 卡死时（每次都有） |
| `calling OH_HiCollie_Report()` | 正在上报关卡 | UI 卡死时 |
| `OH_HiCollie_Report() success` | 上报成功 | UI 卡死时 |
| `m_is_six_second_event = false` | 第 1 阶段（卡死 3 秒） | 卡死 3 秒时 |
| `m_is_six_second_event = true` | 第 2 阶段（卡死 6 秒） | 卡死 6 秒时 |
| `thread may be blocked, do not report` | 防误报跳过 | 高负载时偶尔出现（正常） |
| `FLUTTER_THREAD_STUCK` | 卡死事件 | 每次卡死上报 |
| `APP_FREEZE` | 系统级卡死事件 | 卡死 6 秒时 |
| `GpuReclaim` | GPU 回收（卡死的间接原因） | GPU 相关卡死 |
| `handlePlatformMessage` | 平台消息（卡死的间接原因） | Platform 阻塞 |

---

## 7. HiAppEvent 事件

### 7.1 FLUTTER_THREAD_STUCK

**事件名**：`FLUTTER_STABILITY_EVENT`（类型：FAULT）
**eventName**：`FLUTTER_THREAD_STUCK`

| 参数 | 说明 |
|------|------|
| `frameworkName` | 固定 `"FLUTTER"` |
| `eventName` | 固定 `"FLUTTER_THREAD_STUCK"` |
| `description` | 告诉你是哪个线程卡死了、卡了多久 |
| `pid` | 进程 ID |
| `timeStamp` | 事件时间 |

**description 怎么读？**

| description 内容 | 通俗解释 |
|-----------------|---------|
| `Flutter UI thread stuck. isSixSecondEvent=false` | UI 线程卡了 3 秒（还没弹窗） |
| `Flutter UI thread stuck. isSixSecondEvent=true` | UI 线程卡了 6 秒（可能弹窗了） |
| `Flutter Raster thread stuck. isSixSecondEvent=false` | Raster 线程卡了 |
| `Flutter Platform thread stuck. isSixSecondEvent=false` | Platform 线程卡了 |

### 7.2 系统级 APP_FREEZE

当 UI 线程卡死 6 秒时，系统会生成 `APP_FREEZE` 事件。这是系统级的，由 HiCollie 服务直接生成。可能导致：
- 应用无响应弹窗（用户可选"等待"或"关闭"）
- 系统自动杀进程

---

## 8. 排查清单

### 第一步：确认卡死

- [ ] 抓取全量日志：`hdc shell hilog > flutter_log.txt`
- [ ] 搜索 `is not alive` 确认哪个线程卡死
- [ ] 搜索 `FLUTTER_THREAD_STUCK` 查看事件详情
- [ ] 搜索 `APP_FREEZE` 确认是否触发系统事件
- [ ] **查看卡死前 5-10 秒的日志**（最重要！）

### 第二步：找原因

- [ ] 搜索 `GpuReclaim` → 是否 GPU 回收导致
- [ ] 搜索 `external_texture` → 是否纹理回调阻塞
- [ ] 搜索 `handlePlatformMessage` → 是否平台通道阻塞
- [ ] 检查 Dart 代码是否有死循环/死锁
- [ ] 检查是否有同步 IO/网络请求在主线程
- [ ] 检查是否有复杂计算阻塞 UI 线程

### 第三步：HiTrace 分析

- [ ] 抓取 Trace：`hdc shell hitrace --trace_clock boottime -t 30 flutter`
- [ ] 搜索 `feedFlutterWatchdog` 检查 UI 心跳
- [ ] 搜索 `feedFlutterRasterWatchdog` 检查 Raster 心跳
- [ ] 搜索 `flutter::Frame` 查看帧渲染耗时
- [ ] 记录卡死时的操作场景

---

## 9. Trace 分析技巧

### 9.1 正常的心跳（健康的）

正常情况下，`feedFlutterWatchdog` 每 3 秒出现一次，就像心电图一样规律：

```
[0.0s] feedFlutterWatchdog     ← UI 心跳 ✓
[0.0s] feedFlutterRasterWatchdog  ← Raster 心跳 ✓
[3.0s] feedFlutterWatchdog     ← UI 心跳 ✓
[3.0s] feedFlutterRasterWatchdog  ← Raster 心跳 ✓
```

### 9.2 异常的心跳（卡死了）

如果 UI 线程卡死，心跳就"断"了：

```
[0.0s] feedFlutterWatchdog     ← 最后一次正常心跳
[3.0s] runHiCollieStuckDetectionTask  ← 保安发现 UI 没签到
[6.0s] runHiCollieStuckDetectionTask  ← 还是没签到，触发 6 秒报警
（feedFlutterWatchdog 不再出现 = UI 线程卡死了）
```

### 9.3 抓取和分析 Trace

```bash
# 抓取 30 秒的 Trace（在这 30 秒内复现卡死）
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# 用 Chrome 浏览器打开
# 访问 chrome://tracing → 点击 Load → 选择 trace.ftrace
# 快捷键：w 放大、s 缩小、a 左移、d 右移
```
