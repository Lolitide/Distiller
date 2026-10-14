# Flutter OHOS 平台 DFX 问题定位导航

> 面向使用 Flutter OHOS SDK 的应用开发者（包括 Flutter 初学者）
> 遇到问题时，请从下方「故障速查」入口开始

---

## 0. 新手必读：基础概念

在开始排查问题之前，先了解几个基础概念。这些概念在后续文档中会反复出现。

### 0.1 什么是 DFX？

DFX 是 "Design for X" 的缩写，在这里特指**可测试性/可诊断性设计**。简单来说，就是 Flutter 引擎内置了一套"自我监控"机制，当应用出现崩溃、卡死、卡顿、内存泄漏等问题时，引擎会自动记录日志和事件，帮助开发者定位问题原因。

### 0.2 什么是 HiLog / HiAppEvent / HiTrace？

这是 OHOS 系统提供的三套诊断工具，你可以把它们理解为：

| 工具 | 通俗理解 | 类比 |
|------|---------|------|
| **HiLog** | 系统日志，类似 `print()` 输出 | 就像浏览器的 Console |
| **HiAppEvent** | 结构化事件上报，比日志更有条理 | 就像 Crashlytics 的崩溃报告 |
| **HiTrace** | 性能追踪，记录每一帧的耗时 | 就像 Chrome DevTools 的 Performance |

> **新手提示**：排查问题时，第一步永远是**抓取 HiLog 日志**（见 §2），日志里包含了大部分问题的线索。

### 0.3 什么是 hdc？

`hdc` 是 OHOS Device Connector 的缩写，类似于 Android 的 `adb`。它用于在电脑和 OHOS 设备之间传输文件、执行命令。

```bash
# 查看已连接的设备
hdc list targets

# 在设备上执行命令
hdc shell <命令>

# 从设备拉取文件到电脑
hdc file recv <设备路径> <电脑路径>
```

### 0.4 Flutter 的三个线程是什么？

Flutter 应用运行时有三个关键线程，理解它们有助于排查卡死和卡顿问题：

| 线程 | 通俗理解 | 出问题时的表现 |
|------|---------|--------------|
| **UI 线程** | 负责运行你的 Dart 代码、构建 Widget 树 | 界面完全冻结，触摸无响应 |
| **Raster 线程**（光栅化线程） | 负责把 Widget 树绘制成像素，交给 GPU | 界面不更新，但触摸可能有响应 |
| **Platform 线程** | 负责和 OHOS 系统交互（如处理触摸事件、系统消息） | 平台通道通信阻塞，可能间接卡 UI |

### 0.5 一帧是怎么画出来的？（渲染流水线）

每一帧画面都要经过四个阶段才能显示到屏幕上，就像工厂的流水线：

```
Build → Layout → Paint → Composite（光栅化）
 │       │        │         │
 │       │        │         └─ Raster 线程：把画面变成像素，交给 GPU 上屏
 │       │        └─ UI 线程：生成绘制指令（Layer 树）
 │       └─ UI 线程：确定每个组件的大小和位置
 └─ UI 线程：执行你的 Dart 代码，更新 Widget 树
```

> **新手提示**：
> - **Build/Layout/Paint 在 UI 线程**——如果你的 Dart 代码慢了，这里会超时
> - **Composite 在 Raster 线程**——如果画面太复杂（大图、模糊、大量图层），这里会超时
> - 排查卡顿时，第一步就是搞清楚**哪条线程超时了**
> - 详细的分析方法见 [dfx-jank-latency.md](dfx-jank-latency.md)

### 0.6 什么是"帧预算"？

屏幕每秒刷新 60 次（或 90/120 次），每次刷新叫一帧。每一帧必须在规定时间内画完，这个时间就是"帧预算"：

| 屏幕刷新率 | 帧预算 | 通俗解释 |
|-----------|--------|---------|
| 60Hz | **16.6ms** | 每帧要在 16.6 毫秒内画完 |
| 90Hz | **11.1ms** | 每帧要在 11.1 毫秒内画完 |
| 120Hz | **8.3ms** | 每帧要在 8.3 毫秒内画完 |

如果某一帧没在帧预算内画完，这帧就"丢了"（丢帧/Jank），用户看到的就是"卡了一下"。

> **打个比方**：就像翻页动画书，每秒翻 60 页才能看起来流畅。如果某一页你翻了 50 毫秒才翻完，动画就会"卡"一下。

### 0.7 什么是"响应时延"和"完成时延"？

这是华为应用体验质量标准里的两个重要指标，用户说"卡"很多时候是这两个时延出了问题：

| 指标 | 通俗解释 | 用户感受阈值 | 举例 |
|------|---------|------------|------|
| **响应时延** | 从用户触摸到**首个画面反馈**的时间 | >100ms 感觉"迟钝" | 点了按钮，100ms 后界面才有反应 |
| **完成时延** | 从用户操作到**整个操作彻底完成**的时间 | 视场景而定 | 点开详情页，白屏 2 秒才出内容 |

> **新手区分**：
> - 响应时延是"点了有没有立刻有反应"——主线程被阻塞会导致响应慢
> - 完成时延是"操作有没有彻底完成"——数据加载慢、首屏构建太大会导致完成慢
> - 响应时延可能合格（点了立刻有动画），但完成时延崩了（动画完了内容还没出来）
> - 详细的量测方法见 [dfx-jank-latency.md](dfx-jank-latency.md) §5

### 0.8 触摸事件是怎么变成画面的？（触摸到上屏的全链路）

当你手指滑动屏幕时，事件要经过一条很长的"传送链"才能变成画面：

```
手指按下
│
├─ mmi_service（多模交互服务）
│  └─ 立即转发给应用主线程（DispatchTouchEvent）
│
├─ 手指滑动（move 事件）
│  └─ 不立即转发！由 vsync 信号门控，随帧节奏派发：
│     mmi_service → VSyncGennerator → DVSync-app → 应用主线程
│
├─ TouchSlop 滑动阈值
│  └─ 系统判定"开始滑动"的最小位移，默认 18vp
│
└─ 渲染送显
   └─ 1.ui → 1.raster → render_service → RSUniRenderThread → RSHardwareThread → 屏幕显示
```

> **新手提示**：详细的 trace 链分析方法见 [dfx-jank-latency.md](dfx-jank-latency.md) §2。

### 0.9 什么是"外接纹理"？

外接纹理（External Texture）是一种让原生侧（视频播放器、相机、动画等）把画面"喂"给 Flutter 显示的机制。你可以把它理解为一个"画面传送带"：

- **生产者**：视频播放器 / 相机等原生组件，持续产出画面帧
- **消费者**：Flutter 引擎，把画面帧绘制到屏幕上

如果传送带出了问题（生产太快消费不过来、生产者停了、消费者卡了），就会导致画面黑屏、卡顿或冻结。

### 0.10 什么是"GPU 上下文丢失"？

当应用退到后台或系统内存不足时，OHOS 系统会回收 GPU 资源（为了省电/省内存）。这就好比你工作时电脑突然关了机——你的"工作环境"（GPU 上下文）丢了，需要重新启动才能继续工作。Flutter 引擎会自动重建 GPU 上下文，但重建期间画面会短暂黑屏。

---

## 1. 故障速查

### 1.1 我遇到的是什么问题？

根据你看到的现象，找到对应的文档：

| 你看到的现象 | 可能是什么问题 | 去哪个文档 |
|-------------|--------------|-----------|
| 应用闪退、崩溃 | Native 崩溃 / Dart 异常 / ETS 异常 | [dfx-crash.md](dfx-crash.md) |
| 应用卡死、无响应、点不动 | 线程卡死（UI/Raster/Platform） | [dfx-appfreeze.md](dfx-appfreeze.md) |
| 界面卡顿、滑动不流畅 | 丢帧/JANK（帧率不够） | [dfx-performance.md](dfx-performance.md) |
| 点了按钮反应慢、滑动跟手性差 | 响应时延过长（主线程被阻塞） | [dfx-jank-latency.md](dfx-jank-latency.md) |
| 页面打开白屏太久才出内容 | 完成时延过长（首屏构建/数据加载慢） | [dfx-jank-latency.md](dfx-jank-latency.md) |
| 手机发烫、耗电快、CPU 持续高占用 | 负载异常 / 后台功耗（持续重绘、轮询未停） | [dfx-power-load.md](dfx-power-load.md) |
| 内存占用过高、OOM 闪退 | Dart Heap 内存超限 | [dfx-memory.md](dfx-memory.md) |
| 黑屏、白屏、渲染异常 | GPU 上下文丢失（退后台后恢复失败） | [dfx-memory.md](dfx-memory.md) |
| 视频/相机画面黑屏、不更新、卡顿 | 外接纹理问题 | [dfx-texture.md](dfx-texture.md) |
| 分栏不生效/避让失效/折叠屏异常 | 多设备适配问题 | [dfx-multi-device.md](dfx-multi-device.md) |
| 不确定是什么问题 | 先抓全量日志再说 | [dfx-logging.md](dfx-logging.md) |

### 1.2 故障定位决策树

如果你不确定问题类型，可以按以下步骤搜索日志关键词来判断：

```
应用出现异常
│
├─ 应用闪退/崩溃
│  ├─ 日志中搜到 "Caught signal SIG*"
│  │  → 引擎底层 C++ 崩溃（Native 崩溃），详见 dfx-crash.md §2
│  ├─ 日志中搜到 "Unhandled Exception:"
│  │  → 你的 Dart 代码有未捕获的异常，详见 dfx-crash.md §3
│  ├─ 日志中搜到 "FLUTTER_ETS_EXCEPTION"
│  │  → ETS（ArkTS）插件层异常，详见 dfx-crash.md §4
│  └─ 以上都搜不到
│     → 先抓全量日志，详见 dfx-logging.md
│
├─ 应用卡死/无响应
│  ├─ 日志中搜到 "is not alive"
│  │  → 某个线程卡死了，详见 dfx-appfreeze.md
│  ├─ 日志中搜到 "FLUTTER_THREAD_STUCK"
│  │  → 看门狗检测到线程卡死，详见 dfx-appfreeze.md
│  └─ 日志中搜到 "APP_FREEZE"
│     → UI 线程卡死超过 6 秒，系统要杀进程了，详见 dfx-appfreeze.md
│
├─ 界面卡顿/丢帧
│  ├─ 日志中搜到 "OTHER_JANK" 或 "OTHER_JANK_STAT"
│  │  → 非滑动场景丢帧，详见 dfx-performance.md
│  ├─ 日志中搜到 "OTHER_JANK_SCROLL"
│  │  → 滑动场景丢帧，详见 dfx-performance.md
│  ├─ DevTools 中帧标红且只有 UI 线程超时
│  │  → Dart 代码慢（build/layout/paint），详见 dfx-jank-latency.md §4.1
│  ├─ DevTools 中帧标红且只有 Raster 线程超时
│  │  → 绘制太重（大图/模糊/saveLayer），详见 dfx-jank-latency.md §4.2
│  ├─ DevTools 标注 "Shader Compilation Jank"
│  │  → 首次编译着色器导致，详见 dfx-jank-latency.md §4.6
│  └─ 需要更详细分析
│     → 抓取 HiTrace，详见 dfx-performance.md
│
├─ 响应时延 / 完成时延问题
│  ├─ 点击后反应慢（响应时延长）
│  │  → 主线程被重活阻塞，详见 dfx-jank-latency.md §4.5
│  ├─ 页面打开白屏太久（完成时延长）
│  │  → 首屏全量构建 / 数据加载慢，详见 dfx-jank-latency.md §4.5
│  └─ 需要量时延出数
│     → 用 FrameTiming 打点 + 系统 trace 链，详见 dfx-jank-latency.md §5
│
├─ 负载 / 功耗问题（手机发烫、耗电快、CPU 持续高占用）
│  ├─ top -H 发现某线程 CPU 持续高占用
│  │  → 用 hiperf 抓指令数采样 + 火焰图定位热点，详见 dfx-power-load.md §2
│  ├─ 静止页面 CPU 仍不回落
│  │  → 无效重绘（缺 const/RepaintBoundary），详见 dfx-power-load.md §5.1
│  ├─ 退后台后仍在跑任务 / 定时器未停
│  │  → 后台功耗（暂停动画/轮询/纹理），详见 dfx-power-load.md §5.2
│  └─ 伴随 OTHER_JANK 事件
│     → 已影响流畅度，交叉比对 HiTrace/HiLog，详见 dfx-power-load.md §2.4
│
├─ 内存问题
│  ├─ 日志中搜到 "Dart heap memory usage exceeds threshold"
│  │  → Dart 内存超过 1.5GB，详见 dfx-memory.md
│  └─ 日志中搜到 "FrameworkMemAnomaly"
│     → 系统记录了内存异常事件，详见 dfx-memory.md
│
├─ GPU/渲染问题
│  ├─ 日志中搜到 "GpuReclaim" 且包含 "kAggressive"
│  │  → GPU 资源被系统回收了，详见 dfx-memory.md
│  └─ 日志中搜到 "FLUTTER_GPU_CONTEXT_LOSS"
│     → GPU 上下文丢失事件，详见 dfx-memory.md
│
├─ 外接纹理问题（视频/相机画面异常）
│  ├─ 日志中搜到 "No DlImage available" 或 "OH_NativeImage_Create() failed"
│  │  → 纹理创建失败或无画面，详见 dfx-texture.md §5
│  ├─ 日志中搜到 "frame gate enabled, drain-only"
│  │  → 应用在后台，纹理帧被暂停（正常行为），详见 dfx-texture.md §6
│  ├─ 日志中搜到 "skip one frame"
│  │  → 画面生产太快，消费跟不上，详见 dfx-texture.md §8
│  └─ 日志中搜到 "PlatformViewVisibleAreaEventCallback"
│     → 可见区域变化触发了暂停/恢复，详见 dfx-texture.md §7
│
├─ 多设备适配异常
│  ├─ 日志中搜到 "SplitView" 或 "SystemChannel config parse failed"
│  │  → 分栏配置问题，详见 dfx-multi-device.md §2
│  ├─ 日志中搜到 "avoidAreaChangeCallback"
│  │  → 安全区域避让问题，详见 dfx-multi-device.md §3
│  ├─ 日志中搜到 "Fold status change"
│  │  → 折叠屏状态变化，详见 dfx-multi-device.md §4
│  ├─ 日志中搜到 "Device pixel ratio"
│  │  → DPI 缩放问题，详见 dfx-multi-device.md §5
│  ├─ 日志中搜到 "LTPO"
│  │  → 自适应刷新率问题，详见 dfx-multi-device.md §6
│  └─ 日志中搜到 "windowSizeChangeCallback"
│     → 多窗口尺寸变化，详见 dfx-multi-device.md §7
│
└─ 引擎生命周期异常
   └─ 日志中搜到 "FLUTTER_ENGINE_CREATE" 或 "FLUTTER_ENGINE_DESTROY"
      → 引擎被创建或销毁，详见 dfx-memory.md §4
```

> **新手提示**：如果上面的关键词你不知道怎么搜，别急，先看 §2 学会抓日志。

---

## 2. 第一步：抓取日志

无论遇到什么问题，**第一时间抓取日志**是最关键的。就像破案要保护现场一样，日志就是"现场"。

### 2.1 快速抓取全量日志（按这 4 步操作就行）

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
> - `hilog` 就是 OHOS 的日志系统，类似于 Android 的 `logcat`
> - `grep` 是文本搜索工具，`-E` 表示用正则表达式匹配
> - `>` 表示把输出保存到文件

### 2.2 按问题类型过滤日志（只看相关内容，过滤掉噪音）

不知道该用哪条？回到 §1.1 对照你的现象选择：

```bash
# 崩溃相关（应用闪退）
hdc shell hilog | grep -E "Caught signal|Unhandled Exception|FLUTTER_DART_EXCEPTION|FLUTTER_ETS_EXCEPTION"

# 卡死相关（应用无响应）
hdc shell hilog | grep -E "FlutterWatchdog|not alive|HiCollie|THREAD_STUCK"

# 卡顿/丢帧相关（界面不流畅）
hdc shell hilog | grep -E "JANK|jank|missed|frame"

# 内存相关（OOM、内存占用高）
hdc shell hilog | grep -E "heap memory|memory|OOM|threshold"

# GPU 相关（黑屏、白屏）
hdc shell hilog | grep -E "GpuReclaim|GPU|gpu"

# 外接纹理相关（视频/相机画面异常）
hdc shell hilog | grep -E "external_texture|ExternalTexture|NativeImage|DlImage|frame gate|VisibleArea|texture_id"

# 多设备适配相关（分栏、折叠屏等）
hdc shell hilog | grep -E "SplitView|split_view|avoidArea|displayFeature|foldStatus|device pixel ratio|windowSizeChange|LTPO"
```

### 2.3 抓取性能 Trace（分析卡顿专用）

如果界面卡顿但日志看不出问题，需要抓取性能 Trace（类似 Chrome DevTools 的 Performance 录制）：

```bash
# 抓取 10 秒的性能 Trace（在这 10 秒内复现卡顿）
hdc shell hitrace --trace_clock boottime -t 10 flutter -o /data/local/tmp/trace.ftrace

# 把 Trace 文件拉取到电脑
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# 用 Chrome 浏览器打开：访问 chrome://tracing → 点击 Load → 选择 trace.ftrace
```

详细的日志抓取与过滤方法请参考 [dfx-logging.md](dfx-logging.md)。

---

## 3. DFX 事件速查表

Flutter 引擎在运行过程中会自动上报一些"事件"（可以理解为结构化的崩溃报告），每个事件都包含了问题类型、时间戳、进程 ID 等信息。

| 事件名 | 问题类型 | 通俗解释 | 去哪个文档 |
|--------|---------|---------|-----------|
| `FLUTTER_DART_EXCEPTION` | Dart 异常 | 你的 Dart 代码有 bug 导致崩溃 | [dfx-crash.md](dfx-crash.md) |
| `FLUTTER_ETS_EXCEPTION` | ETS 异常 | ArkTS 插件代码有 bug | [dfx-crash.md](dfx-crash.md) |
| `FLUTTER_STABILITY_EVENT` | 稳定性事件 | 引擎检测到不稳定（卡死、GPU丢失等） | 见下方子表 |
| `OTHER_JANK` | 丢帧 | 某一帧渲染太慢，导致卡顿 | [dfx-performance.md](dfx-performance.md) |
| `OTHER_JANK_STAT` | 丢帧统计 | 一段时间内的丢帧汇总 | [dfx-performance.md](dfx-performance.md) |
| `OTHER_JANK_SCROLL` | 滑动丢帧 | 滑动时某一帧超过 50ms | [dfx-performance.md](dfx-performance.md) |
| FrameworkMemAnomaly | 内存超限 | Dart 内存超过 1.5GB | [dfx-memory.md](dfx-memory.md) |

### FLUTTER_STABILITY_EVENT 的子类型

`FLUTTER_STABILITY_EVENT` 是一个"大类"，里面通过 `eventName` 字段区分具体是什么稳定性问题：

| eventName | 通俗解释 | 去哪个文档 |
|-----------|---------|-----------|
| `FLUTTER_THREAD_STUCK` | 某个线程卡死了 | [dfx-appfreeze.md](dfx-appfreeze.md) |
| `FLUTTER_GPU_CONTEXT_LOSS` | GPU 资源被系统回收 | [dfx-memory.md](dfx-memory.md) |
| `FLUTTER_ENGINE_CREATE` | Flutter 引擎创建了 | [dfx-memory.md](dfx-memory.md) |
| `FLUTTER_ENGINE_DESTROY` | Flutter 引擎销毁了 | [dfx-memory.md](dfx-memory.md) |

完整的事件参数说明请参考 [dfx-hiappevent.md](dfx-hiappevent.md)。

---

## 4. HiLog 关键字速查表

在日志中搜索这些关键字，可以快速判断问题类型：

| 搜索这个关键字 | 问题类型 | 含义（通俗解释） |
|--------------|---------|----------------|
| `Caught signal SIGSEGV` | 引擎崩溃 | 引擎访问了非法内存（比如空指针） |
| `Caught signal SIGABRT` | 引擎崩溃 | 引擎内部断言失败或内存被破坏 |
| `Unhandled Exception:` | Dart 异常 | 你的 Dart 代码有未 try-catch 的异常 |
| `is not alive` | 卡死 | 某个线程 3 秒没响应了 |
| `OH_HiCollie_Report() success` | 卡死 | 卡死事件已上报到系统 |
| `Dart heap memory usage exceeds threshold` | 内存超限 | Dart 内存超过 1.5GB |
| `GpuReclaim` + `kAggressive` | GPU 回收 | 系统正在回收 GPU 资源（退后台时正常） |
| `GpuReclaim` + `kRestore` | GPU 恢复 | GPU 资源正在恢复（回前台时正常） |
| `Poll error:` | 消息循环异常 | 系统消息循环出错，可能导致卡死 |
| `AwaitVSync...failed` | Vsync 失败 | 垂直同步信号请求失败，可能导致不渲染 |
| `No DlImage available` | 外接纹理 | 纹理没有可绘制的画面（黑屏） |
| `frame gate enabled` | 外接纹理 | 应用在后台，纹理帧被暂停（正常） |
| `skip one frame` | 外接纹理 | 画面生产太快，跳过了一些帧 |

---

## 5. DFX 能力概览

### 5.1 三套日志体系（日志从哪里来？）

Flutter OHOS 平台的日志来自三个不同的"源头"，了解它们有助于精准过滤：

| 日志来源 | Tag | 谁产生的 | 典型内容 | 什么时候看 |
|---------|-----|---------|---------|-----------|
| **引擎内部** (FML_LOG) | 映射到 HiLog | Flutter 引擎的 C++ 代码 | 崩溃堆栈、卡死检测、GPU 回收 | 排查崩溃、卡死、黑屏 |
| **平台 C++ 层** | `XComFlutterOHOS_Native` | OHOS 平台的 C++ 代码 | 引擎初始化、NAPI 调用 | 排查引擎初始化问题 |
| **ETS 嵌入层** | `Flutter` | ArkTS 代码 | MethodChannel、插件异常、生命周期 | 排查插件/通道问题 |

> **一条命令看全部 Flutter 日志**：
> ```bash
> hdc shell hilog | grep -E "Flutter|XComFlutter|flutter"
> ```

### 5.2 DFX 上报通道（问题信息记录在哪里？）

| 通道 | 通俗理解 | 怎么查看 |
|------|---------|---------|
| **HiLog** | 实时文本日志 | `hdc shell hilog` |
| **HiAppEvent** | 结构化事件（带参数） | `hdc shell hilog \| grep "OH_HiAppEvent_Write"` |
| **HiCollie** | 系统级卡死检测 | 触发系统 APP_FREEZE 事件 |
| **HiTrace** | 性能追踪（每帧耗时） | `hdc shell hitrace ...` |

### 5.3 API 版本要求（有些功能需要高版本系统）

| 功能 | 最低系统 API 版本 | 低于此版本会怎样 |
|------|-----------------|----------------|
| HiAppEvent 事件上报 | API 18 | 不会生成任何 HiAppEvent 事件（但 HiLog 仍可用） |
| HiTrace 扩展接口 | API 19 | 丢帧详情 Trace 不可用 |
| 内存异常上报 (FrameworkMemAnomaly) | API 26 | 不会上报内存异常事件（但 HiLog 仍可用） |

> **新手提示**：HiLog 日志不受 API 版本限制，始终可用。如果发现某些事件搜不到，先检查系统 API 版本。

---

## 6. 文档索引

| 文档 | 讲什么 | 什么时候看 |
|------|--------|----------|
| [dfx-logging.md](dfx-logging.md) | 怎么抓日志、过滤日志 | **所有问题排查的第一步** |
| [dfx-crash.md](dfx-crash.md) | 应用闪退/崩溃怎么查 | 应用闪退、崩溃 |
| [dfx-appfreeze.md](dfx-appfreeze.md) | 应用卡死/无响应怎么查 | 应用点不动、卡死 |
| [dfx-performance.md](dfx-performance.md) | 界面卡顿/丢帧怎么查（DFX 事件层面） | 界面不流畅、滑动卡、查丢帧事件 |
| [dfx-jank-latency.md](dfx-jank-latency.md) | 滑动卡顿丢帧与时延问题深度分析 | 卡顿优化、响应/完成时延量测、DevTools/SmartPerf 使用 |
| [dfx-power-load.md](dfx-power-load.md) | 负载异常与功耗问题怎么查 | 手机发烫、耗电快、CPU 持续高占用、后台偷跑 |
| [dfx-hiappevent.md](dfx-hiappevent.md) | 所有 DFX 事件的完整说明 | 查事件参数含义 |
| [dfx-memory.md](dfx-memory.md) | 内存/OOM/GPU 问题怎么查 | 内存高、OOM、黑屏 |
| [dfx-texture.md](dfx-texture.md) | 外接纹理问题怎么查 | 视频/相机画面异常 |
| [dfx-multi-device.md](dfx-multi-device.md) | 多设备适配问题怎么查 | 分栏、折叠屏、DPI 等 |
