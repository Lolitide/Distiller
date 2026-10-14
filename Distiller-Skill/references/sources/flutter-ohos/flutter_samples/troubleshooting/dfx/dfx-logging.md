# 日志抓取与过滤指南

> 返回 [README.md](README.md)

---

## 1. 三套日志体系（日志从哪里来？）

Flutter OHOS 平台的日志来自三个不同的"源头"，就像一栋楼有三个楼层，每个楼层的人说话你都需要不同的方式去听：

| 日志来源 | Tag（标签） | 谁产生的 | 典型内容 | 什么时候看 |
|---------|------------|---------|---------|-----------|
| **引擎内部** | 映射到 HiLog | Flutter 引擎的 C++ 代码 | 崩溃堆栈、卡死检测、GPU 回收 | 排查崩溃、卡死、黑屏 |
| **平台 C++ 层** | `XComFlutterOHOS_Native` | OHOS 平台的 C++ 代码 | 引擎初始化、NAPI 调用 | 排查引擎初始化问题 |
| **ETS 嵌入层** | `Flutter` | ArkTS 代码 | MethodChannel、插件异常、生命周期 | 排查插件/通道问题 |

> **新手提示**：不确定看哪个？用这条命令看全部 Flutter 日志：
> ```bash
> hdc shell hilog | grep -E "Flutter|XComFlutter|flutter"
> ```

---

## 2. 日志抓取方法

### 2.1 基本流程（按这 4 步操作就行）

```bash
# 1. 清空历史日志（清掉旧的，只留复现后的新日志）
hdc shell hilog -r

# 2. 复现问题（操作你的应用，触发 bug）

# 3. 抓取日志（按 Ctrl+C 停止抓取）
hdc shell hilog > flutter_log.txt

# 4. 从日志中筛选 Flutter 相关的内容
hdc shell hilog | grep -E "Flutter|XComFlutter|flutter" > flutter_filtered.txt
```

> **新手提示**：
> - `hilog` 就是 OHOS 的日志系统，类似 Android 的 `logcat`
> - `grep` 是文本搜索工具，`-E` 表示用正则表达式匹配
> - `>` 表示把输出保存到文件

### 2.2 实时监控日志（边操作边看日志）

```bash
# 实时看全部 Flutter 日志
hdc shell hilog | grep -E "Flutter|XComFlutter|flutter"

# 实时看崩溃日志
hdc shell hilog | grep -E "Caught signal|Unhandled exception|FLUTTER_"

# 实时看卡死日志
hdc shell hilog | grep -E "FlutterWatchdog|not alive|HiCollie"

# 实时看 GPU 回收日志
hdc shell hilog | grep -E "GpuReclaim|Surface"

# 实时看外接纹理日志
hdc shell hilog | grep -E "external_texture|NativeImage|texture_id"
```

### 2.3 抓取到设备文件再拉到电脑

```bash
# 把日志保存到设备文件
hdc shell "hilog > /data/local/tmp/flutter_log.txt"

# 拉取到电脑
hdc file recv /data/local/tmp/flutter_log.txt ./flutter_log.txt
```

### 2.4 抓取崩溃日志（tombstone）

Native 崩溃时系统会生成 tombstone 文件（比 hilog 更详细）：

```bash
# 查看崩溃日志文件
hdc shell ls /data/log/faultlog/

# 拉取到电脑
hdc file recv /data/log/faultlog/faultlog-xxx ./faultlog.txt
```

### 2.5 抓取卡死日志（APP_FREEZE）

UI 线程卡死 6 秒时系统生成 APP_FREEZE 事件：

```bash
hdc shell ls /data/log/faultlog/
hdc file recv /data/log/faultlog/appfreeze-xxx ./appfreeze.txt
```

---

## 3. 日志过滤方法

### 3.1 按问题类型过滤（最常用）

不知道用哪条？对照你的现象选：

| 问题类型 | 过滤命令 |
|---------|---------|
| 崩溃（应用闪退） | `hdc shell hilog \| grep -E "Caught signal\|Unhandled exception\|FLUTTER_DART_EXCEPTION\|FLUTTER_ETS_EXCEPTION"` |
| 卡死（无响应） | `hdc shell hilog \| grep -E "FlutterWatchdog\|not alive\|HiCollie\|THREAD_STUCK\|APP_FREEZE"` |
| 卡顿/丢帧 | `hdc shell hilog \| grep -E "JANK\|jank\|missed\|frame"` |
| 内存（OOM） | `hdc shell hilog \| grep -E "heap memory\|memory\|OOM\|threshold"` |
| GPU（黑屏） | `hdc shell hilog \| grep -E "GpuReclaim\|Surface"` |
| Vsync | `hdc shell hilog \| grep -E "vsync\|Vsync\|Poll error"` |
| 外接纹理 | `hdc shell hilog \| grep -E "external_texture\|NativeImage\|texture_id\|frame gate"` |
| 引擎生命周期 | `hdc shell hilog \| grep -E "FLUTTER_ENGINE_CREATE\|FLUTTER_ENGINE_DESTROY"` |
| 平台通道 | `hdc shell hilog \| grep -E "handlePlatformMessage\|MethodChannel\|Failed to handle"` |

### 3.2 按 Tag 过滤

```bash
# 只看引擎 C++ 日志
hdc shell hilog -T XComFlutterOHOS_Native

# 只看 ArkTS 日志
hdc shell hilog -T Flutter
```

### 3.3 按级别过滤

```bash
hdc shell hilog -b D  # 全部日志（Debug 及以上）
hdc shell hilog -b I  # 只看 Info 及以上
hdc shell hilog -b W  # 只看 Warn 及以上
hdc shell hilog -b E  # 只看 Error 及以上
```

### 3.4 组合过滤技巧

```bash
# 搜索多个关键词（OR 关系）
hdc shell hilog | grep -E "GpuReclaim|frame gate|Surface REBUILT"

# 排除噪音（NOT 关系）
hdc shell hilog | grep -E "Flutter" | grep -v "flutter::"

# 只看某个时间段
hdc shell hilog | grep "08-03 10:3[0-5]"  # 10:30-10:35 的日志

# 统计关键词出现次数
hdc shell hilog | grep -c "is not alive"  # 卡死了几次
```

---

## 4. 日志级别说明

### 4.1 不同级别的含义

| 级别 | 数值 | 通俗理解 | 什么时候看 |
|------|------|---------|-----------|
| DEBUG | 3 | 最详细的调试信息 | 开发调试时 |
| INFO | 4 | 关键流程节点 | 确认流程是否正常 |
| WARN | 5 | 警告（可恢复的问题） | 检查潜在问题 |
| ERROR | 6 | 错误（功能失败） | 排查问题 |
| FATAL | 7 | 致命（不可恢复） | 必须修复 |

> **新手提示**：排查问题时建议开启 DEBUG 级别：`hdc shell hilog -b D`

### 4.2 Release 模式下 ETS 日志看不到？

Release/Profile 模式默认只输出 WARN 及以上。如果需要看更详细的日志：

```typescript
import Log from '@ohos.flutter.ohos/src/main/ets/util/Log';
Log.setLogLevel(HiLog.LogLevel.DEBUG);
```

---

## 5. HiTrace 抓取（分析卡顿专用）

### 5.1 什么是 HiTrace？

HiTrace 是性能追踪工具，记录每一帧的耗时。类似 Chrome DevTools 的 Performance 录制。

### 5.2 抓取方法

```bash
# 抓取 10 秒的 Trace（在这 10 秒内复现问题）
hdc shell hitrace --trace_clock boottime -t 10 flutter -o /data/local/tmp/trace.ftrace

# 拉取到电脑
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# 用 Chrome 打开：访问 chrome://tracing → 点 Load → 选文件
```

### 5.3 同时抓取多个类别

```bash
# Flutter + 调度信息（分析线程阻塞）
hdc shell hitrace --trace_clock boottime -t 30 flutter sched -o /data/local/tmp/trace.ftrace
```

### 5.4 Trace 里搜索什么？

| 搜索关键词 | 看什么 | 正常表现 |
|-----------|--------|---------|
| `flutter::Frame` | 每一帧的耗时 | <16ms |
| `Flutter Lost Frames` | 丢帧计数 | 值为 0 |
| `Flutter Hitch Time` | 丢帧详情 | 不出现 |
| `feedFlutterWatchdog` | UI 线程心跳 | 每 3 秒一次 |
| `feedFlutterRasterWatchdog` | Raster 线程心跳 | 每 3 秒一次 |

> 快捷键：`w` 放大、`s` 缩小、`a` 左移、`d` 右移

---

## 6. DFX 关键日志一览

### 6.1 崩溃相关

| 搜索这个关键字 | 含义 | 严重程度 |
|--------------|------|---------|
| `Caught signal SIGSEGV` | 引擎访问了非法内存 | 致命 |
| `Caught signal SIGABRT` | 引擎断言失败/堆破坏 | 致命 |
| `Unhandled exception` | Dart 代码有未捕获异常 | 致命 |
| `Failed to handle method call` | ETS 插件异常 | 中 |

### 6.2 卡死相关

| 搜索这个关键字 | 含义 | 严重程度 |
|--------------|------|---------|
| `is not alive` | 某个线程卡死了 | 致命 |
| `m_is_six_second_event = false` | 卡死 3 秒（第一阶段） | 严重 |
| `m_is_six_second_event = true` | 卡死 6 秒（第二阶段，可能弹窗） | 致命 |
| `thread may be blocked, do not report` | 防误报跳过（正常） | — |

### 6.3 内存/GPU 相关

| 搜索这个关键字 | 含义 | 严重程度 |
|--------------|------|---------|
| `Dart heap memory usage exceeds threshold` | Dart 内存超 1.5GB | 高 |
| `GpuReclaim` + `kAggressive` | GPU 资源被回收 | 正常（退后台时） |
| `GpuReclaim` + `kRestore` | GPU 资源恢复 | 正常（回前台时） |
| `Surface REBUILT` | Surface 重建成功 | 正常 |
| `SetDisplayWindow failed` | Surface 重建失败 | **异常** |

### 6.4 外接纹理相关

| 搜索这个关键字 | 含义 | 严重程度 |
|--------------|------|---------|
| `No DlImage available` | 无可绘制画面（黑屏） | 中 |
| `frame gate enabled` | 后台帧闸门开启 | 正常 |
| `skip one frame(slow consumer)` | 消费过慢跳帧 | 中 |
| `PlatformViewVisibleAreaEventCallback` | 可见区域变化 | — |

### 6.5 Vsync 相关

| 搜索这个关键字 | 含义 | 严重程度 |
|--------------|------|---------|
| `vsync_handle_ is nullptr` | Vsync 句柄无效 | 致命 |
| `AwaitVSync...failed` | Vsync 请求失败 | 致命 |
| `Failed to dlopen libnative_vsync.so` | Vsync 库加载失败 | 致命 |

---

## 7. 常见问题

### Q1: 抓不到 Flutter 日志？

| 原因 | 解决方法 |
|------|---------|
| 日志级别没开 | `hdc shell hilog -b D` |
| hilog 服务没运行 | `hdc shell hilog -v` 查状态，`hdc shell hilog -r` 清空重试 |
| 设备没连接 | `hdc list targets` 确认设备 |

### Q2: Release 模式看不到详细日志？

```typescript
// 在应用入口设置日志级别
Log.setLogLevel(HiLog.LogLevel.DEBUG);
```

### Q3: HiAppEvent 事件在哪里看？

```bash
# 方法 1：搜索上报日志
hdc shell hilog | grep "OH_HiAppEvent_Write"

# 方法 2：搜索特定事件
hdc shell hilog | grep -E "FLUTTER_DART_EXCEPTION|OTHER_JANK|FLUTTER_STABILITY_EVENT"

# 方法 3：查看 faultlog 目录
hdc shell ls /data/log/faultlog/
```

### Q4: Trace 文件怎么分析？

1. Chrome 浏览器访问 `chrome://tracing`
2. 点 `Load` 加载 `.ftrace` 文件
3. 搜索 `flutter::` 看帧耗时
4. 搜索 `Flutter Lost Frames` 看丢帧
5. 快捷键：`w` 放大、`s` 缩小

### Q5: 日志太多看不过来？

```bash
# 按问题类型过滤（见 §3.1）
hdc shell hilog | grep -E "Caught signal|Unhandled exception"

# 排除噪音
hdc shell hilog | grep -E "Flutter" | grep -v "flutter::"

# 按时间段过滤
hdc shell hilog | grep "08-03 10:3[0-5]"

# 保存到文件后离线分析
hdc shell hilog > flutter_log.txt
```

### Q6: HiAppEvent 事件上报失败？

| 错误日志 | 含义 | 解决方法 |
|---------|------|---------|
| `API version too low` | 系统 API 太低 | 需 API 18+ |
| `reportFrameworkMemAnomaly_ is nullptr` | 内存上报 API 不足 | 需 API 26+ |
| `flush isValid_ false` | HiAppEvent 没初始化 | 检查 SO 库加载 |

### Q7: 怎么确认日志属于哪个线程？

| 搜索关键词 | 对应线程 |
|-----------|---------|
| `FlutterUiThread` / `feedFlutterWatchdog` | UI 线程 |
| `FlutterRasterThread` / `feedFlutterRasterWatchdog` | Raster 线程 |
| `FlutterPlatformThread` / `feedFlutterPlatformWatchdog` | Platform 线程 |
