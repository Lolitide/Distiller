# DFX 事件目录参考

> 返回 [README.md](README.md)

本文档列出 Flutter OHOS 平台通过 HiAppEvent 上报的全部 DFX 事件及其参数，供开发者查阅。

> **新手提示**：HiAppEvent 事件就像"结构化的崩溃报告"——比普通日志更有条理，包含了问题类型、时间戳、参数等信息。你可以把它理解为系统自动帮你填写的"bug 报告单"。

---

## 1. 事件总览

| 事件名 | 问题类型 | 通俗解释 | 最低 API | 详细文档 |
|--------|---------|---------|---------|---------|
| `FLUTTER_DART_EXCEPTION` | Dart 异常 | 你的 Dart 代码有 bug | API 18 | [dfx-crash.md](dfx-crash.md) §3 |
| `FLUTTER_STABILITY_EVENT` | 稳定性事件 | 引擎检测到不稳定（卡死/GPU丢失等） | API 18 | 见 §3 |
| `FLUTTER_ETS_EXCEPTION` | ETS 异常 | ArkTS 插件代码有 bug | API 18 | [dfx-crash.md](dfx-crash.md) §4 |
| `OTHER_JANK` | 丢帧 | 某一帧画太慢了 | API 18 | [dfx-performance.md](dfx-performance.md) |
| `OTHER_JANK_STAT` | 丢帧统计 | 一段时间内的丢帧汇总 | API 18 | [dfx-performance.md](dfx-performance.md) |
| `OTHER_JANK_SCROLL` | 滑动丢帧 | 滑动时某帧超过 50ms | API 18 | [dfx-performance.md](dfx-performance.md) |
| FrameworkMemAnomaly | 内存超限 | Dart 内存超过 1.5GB | API 26 | [dfx-memory.md](dfx-memory.md) §2 |

> **新手提示**：如果搜不到某些事件，可能是系统 API 版本太低。HiLog 日志不受 API 版本限制，始终可用。

---

## 2. FLUTTER_DART_EXCEPTION（Dart 代码异常）

**什么时候触发**：你的 Dart 代码有未被 try-catch 捕获的异常。

| 参数 | 类型 | 限制 | 说明 | 怎么用 |
|------|------|------|------|--------|
| `frameworkName` | String | — | 固定 `"FLUTTER"` | 标识 |
| `errorMsg` | String | ≤4096 字符 | 错误信息 | 确定是什么异常 |
| `stackTrace` | String | ≤8192 字符 | 堆栈 | 定位到代码行 |
| `pid` | Int64 | — | 进程 ID | 关联进程 |
| `timeStamp` | Int64 | — | 事件时间 | 发生时刻 |

### 怎么读 errorMsg？

| errorMsg 示例 | 异常类型 | 通俗解释 | 怎么修 |
|--------------|---------|---------|--------|
| `type 'Null' is not a subtype of type 'String'` | TypeError | 试图把 null 当 String 用 | 加空判断 |
| `NoSuchMethodError: ... was called on null` | NoSuchMethodError | 在 null 上调方法 | 用 `?.` 安全调用 |
| `RangeError: Index value 'N' is out of range` | RangeError | 数组越界 | 加边界检查 |
| `Bad state: Stream has already been listened to` | StateError | Stream 状态不对 | 检查 Stream 状态 |

**详细排查方法**：参考 [dfx-crash.md](dfx-crash.md) §3

---

## 3. FLUTTER_STABILITY_EVENT（稳定性事件）

**什么时候触发**：引擎检测到不稳定情况（线程卡死、GPU 丢失、引擎创建/销毁）。

这是一个"大类"事件，通过 `eventName` 字段区分具体是什么问题：

| eventName | 通俗解释 | 严重程度 | 详细文档 |
|-----------|---------|---------|---------|
| `FLUTTER_THREAD_STUCK` | 某个线程卡死了 | 致命 | [dfx-appfreeze.md](dfx-appfreeze.md) |
| `FLUTTER_GPU_CONTEXT_LOSS` | GPU 资源被系统回收 | 高 | [dfx-memory.md](dfx-memory.md) §3 |
| `FLUTTER_ENGINE_CREATE` | Flutter 引擎创建了 | — | [dfx-memory.md](dfx-memory.md) §4 |
| `FLUTTER_ENGINE_DESTROY` | Flutter 引擎销毁了 | — | [dfx-memory.md](dfx-memory.md) §4 |

### 怎么读 description？

#### FLUTTER_THREAD_STUCK

| description 内容 | 通俗解释 | 后续会发生什么 |
|-----------------|---------|--------------|
| `Flutter UI thread stuck. isSixSecondEvent=false` | UI 线程卡了 3 秒 | 只记录，不弹窗 |
| `Flutter UI thread stuck. isSixSecondEvent=true` | UI 线程卡了 6 秒 | 可能弹"应用无响应"弹窗 |
| `Flutter Raster thread stuck. isSixSecondEvent=false` | Raster 线程卡了 | 只记录 |
| `Flutter Platform thread stuck. isSixSecondEvent=false` | Platform 线程卡了 | 只记录 |

#### FLUTTER_GPU_CONTEXT_LOSS

**怎么排查**：搜索 `GpuReclaim` 看完整的回收/恢复流程，检查 `Surface REBUILT` 是否成功。详见 [dfx-memory.md](dfx-memory.md) §3。

#### FLUTTER_ENGINE_CREATE / FLUTTER_ENGINE_DESTROY

**怎么排查**：检查 CREATE 和 DESTROY 是否 1:1 配对。详见 [dfx-memory.md](dfx-memory.md) §4。

---

## 4. FLUTTER_ETS_EXCEPTION（ArkTS 插件异常）

**什么时候触发**：ArkTS 插件代码在处理 MethodChannel 消息时出错。

| 参数 | 说明 | 怎么用 |
|------|------|--------|
| `CONTEXT` | 异常发生在哪个环节 | 确定出错位置 |
| `ERROR_MSG` | 错误信息 | 确定异常类型 |
| `STACK_TRACE` | 堆栈 | 定位到代码行 |

### CONTEXT 值含义

| CONTEXT | 通俗解释 | 排查方向 |
|---------|---------|---------|
| `MethodChannel.onMessage` | 插件接收消息时出错 | 检查插件的 `onMethodCall` |
| `MethodChannel.reply` | 处理返回结果时出错 | 检查 Dart 侧回调 |
| `DartMessenger.invokeHandler` | 二进制消息处理出错 | 检查消息处理器 |
| `DartMessenger.handlePlatformMessageResponse` | 消息回复出错 | 检查回复回调 |

> **特点**：ETS 异常通常不会导致闪退（被 try-catch 了），但会导致功能用不了。

**详细排查方法**：参考 [dfx-crash.md](dfx-crash.md) §4

---

## 5. OTHER_JANK（单次丢帧）

**什么时候触发**：非滑动场景下某一帧画太慢了。

| 参数 | 说明 | 怎么判断 |
|------|------|---------|
| `missedFrames` | 丢了多少帧 | 1-3 轻微，>3 严重 |
| `startTime` / `endTime` | 丢帧时间范围 | 定位发生时刻 |

**详细排查方法**：参考 [dfx-performance.md](dfx-performance.md)

---

## 6. OTHER_JANK_STAT（丢帧统计）

**什么时候触发**：非滑动场景下累计丢了最多 10 帧后批量上报。

| 参数 | 说明 | 怎么判断 |
|------|------|---------|
| `totalMissedFrames` | 总共丢了多少帧 | 丢帧总量 |
| `maxFrameTime` | 最严重的一帧画了多久（毫秒） | <16ms 正常，>50ms 严重 |
| `maxMissedFrameRate` | 对应的帧率 | 60/120 正常，低值说明帧率不达标 |

### 怎么判断严重程度？

| maxFrameTime | 严重程度 | 用户感受 |
|-------------|---------|---------|
| <16ms | 正常 | 无感知 |
| 16-50ms | 轻微 | 偶有顿挫 |
| 50-100ms | 明显 | 可感知卡顿 |
| >100ms | 严重 | 严重卡顿 |

---

## 7. OTHER_JANK_SCROLL（滑动丢帧）

**什么时候触发**：滑动时某一帧超过 50ms。

| 参数 | 说明 | 怎么用 |
|------|------|--------|
| `maxFrameTime` | 最严重的一帧画了多久 | >50ms 用户能感知 |
| `totalMissedFrames` | 滑动期间丢了多少帧 | 配合 totalFrames 算丢帧率 |
| `totalFrames` | 滑动期间总帧数 | 算丢帧率 |
| `recentScrollCount` | 上次上报后的滑动次数 | 1 = 每次滑动都丢帧 |
| `frameId` | 最严重丢帧的帧号 | 在 Trace 中定位 |

### 怎么算丢帧率？

```
丢帧率 = totalMissedFrames / totalFrames
```

| 丢帧率 | 严重程度 | 用户感受 |
|--------|---------|---------|
| <5% | 正常 | 无感知 |
| 5-10% | 轻微 | 偶有顿挫 |
| 10-30% | 明显 | 明显卡顿 |
| >30% | 严重 | 严重影响体验 |

**详细排查方法**：参考 [dfx-performance.md](dfx-performance.md) §4.3

---

## 8. FrameworkMemAnomaly（内存超限）

**什么时候触发**：Dart 内存超过 1.5GB（仅 API 26+）。

| 参数 | 说明 |
|------|------|
| `description` | 格式：`Dart heap memory usage exceeds threshold: total = X MB (old = Y MB, new = Z MB)` |

### 怎么读 description？

| 字段 | 含义 | 分析方向 |
|------|------|---------|
| `total` | 总内存 | 总使用量 |
| `old` | Old Space（长期对象） | **持续增长 = 内存泄漏！** |
| `new` | New Space（临时对象） | 高但 GC 后降 = 正常 |

> **注意**：仅 API 26+ 上报，低版本只有 HiLog。触发后停止监控，需重启引擎恢复。

**详细排查方法**：参考 [dfx-memory.md](dfx-memory.md) §2

---

## 9. 怎么查看这些事件？

### 方法 1：通过 hilog 搜索

```bash
# 搜索所有 HiAppEvent 上报
hdc shell hilog | grep "OH_HiAppEvent_Write"

# 搜索特定事件
hdc shell hilog | grep "FLUTTER_DART_EXCEPTION"
hdc shell hilog | grep "FLUTTER_STABILITY_EVENT"
hdc shell hilog | grep "OTHER_JANK"
hdc shell hilog | grep "FrameworkMemAnomaly"
```

### 方法 2：查看 faultlog 目录

```bash
# 崩溃日志
hdc shell ls /data/log/faultlog/
hdc file recv /data/log/faultlog/faultlog-xxx ./faultlog.txt

# 卡死日志
hdc file recv /data/log/faultlog/appfreeze-xxx ./appfreeze.txt
```

### 事件上报失败怎么办？

| 错误日志 | 通俗解释 | 解决方法 |
|---------|---------|---------|
| `API version too low` | 系统 API 太低 | 需 API 18+ |
| `reportFrameworkMemAnomaly_ is nullptr` | 内存上报 API 不足 | 需 API 26+ |
| `flush isValid_ false` | HiAppEvent 没初始化 | 检查 SO 库加载 |

---

## 10. API 版本要求

| 功能 | 最低 API | 低于此版本 | 替代方案 |
|------|---------|-----------|---------|
| HiAppEvent 事件上报 | API 18 | 不生成任何事件 | 用 HiLog |
| HiTrace 扩展接口 | API 19 | 没有丢帧详情 Trace | 只有丢帧计数 |
| 内存异常上报 | API 26 | 不上报 FrameworkMemAnomaly | 搜索 HiLog `heap memory` |

> HiLog 日志不受 API 版本限制，始终可用。

---

## 11. 事件关联速查（看到这个事件，去哪查？）

| 看到的事件 | 问题是什么 | 排查步骤 | 去哪个文档 |
|-----------|-----------|---------|-----------|
| `FLUTTER_DART_EXCEPTION` | Dart 代码异常 | 搜索 `Unhandled exception` 看堆栈 | [dfx-crash.md](dfx-crash.md) §3 |
| `FLUTTER_ETS_EXCEPTION` | ETS 插件异常 | 根据 CONTEXT 确定位置 | [dfx-crash.md](dfx-crash.md) §4 |
| `FLUTTER_THREAD_STUCK` (UI) | UI 线程卡死 | 看卡死前 5-10 秒日志 | [dfx-appfreeze.md](dfx-appfreeze.md) §3 |
| `FLUTTER_GPU_CONTEXT_LOSS` | GPU 丢失 | 搜索 `GpuReclaim` 看流程 | [dfx-memory.md](dfx-memory.md) §3 |
| `OTHER_JANK` | 丢帧 | 抓 HiTrace 分析帧耗时 | [dfx-performance.md](dfx-performance.md) |
| `OTHER_JANK_SCROLL` | 滑动丢帧 | 算丢帧率，抓 Trace | [dfx-performance.md](dfx-performance.md) §4.3 |
| `FrameworkMemAnomaly` | 内存超限 | 看 old/new 分布，用 DevTools | [dfx-memory.md](dfx-memory.md) §2 |
