# Flutter OHOS 渲染流程与异常诊断教程

> 适用范围：Flutter OHOS 平台（`shell/platform/ohos`）的渲染流程跟踪、白屏等渲染异常定位。
> 目标：帮助开发者和运维人员通过日志理解 Flutter 从启动到首帧渲染的完整流程，并快速定位渲染异常。
> **文档版本**：v4（基于 oh-3.22.3-dev 分支 + 日志系统优化，LOGI 宏修复 Release 可见性，shell/common 新增 OHOS_LOGI）

---

## 渲染流程概览

Flutter OHOS 应用从启动到首帧上屏的完整流程：

```text
[ArkTS] FlutterEntry / FlutterView
   │
   ├──> (1) OhosMain::Init ───────────────────────── ohos_main.cpp
   │        └─ 引擎初始化、渲染 API 选择
   │
   ├──> (2) OHOSShellHolder 创建 ─────────────────── ohos_shell_holder.cpp
   │        ├─ 线程创建 (raster/ui/io)
   │        ├─ Shell::Create
   │        └─ PlatformViewOHOS 创建
   │
   ├──> (3) XComponent Surface 回调 ──────────────── ohos_xcomponent_adapter.cpp
   │        ├─ OnSurfaceCreated (OS 触发)
   │        └─ PlatformViewOHOS::NotifyCreate
   │            └─ SetDisplayWindow → Rasterizer::Setup
   │
   ├──> (4) OHOSShellHolder::Launch ──────────────── ohos_shell_holder.cpp
   │        └─ 启动 Dart Engine、运行 isolate
   │
   ├──> (5) VsyncWaiter 创建 ─────────────────────── vsync_waiter_ohos.cpp
   │        └─ 注册 vsync 回调
   │
   ├──> (6) Dart scheduleFrame → 首帧请求 ────────── engine.cc
   │        └─ Animator::RequestFrame → AwaitVSync
   │
   ├──> (7) Vsync 回调 → BeginFrame ──────────────── animator.cc
   │        └─ Dart window.onBeginFrame → build → render
   │
   ├──> (8) Engine::Render ───────────────────────── engine.cc
   │        └─ 校验 layer_tree → Animator::Render
   │
   └──> (9) Rasterizer::Draw ─────────────────────── rasterizer.cc
            ├─ DoDraw → DrawToSurfaces → DrawToSurfaceUnsafe
            ├─ AcquireFrame → Raster → Submit
            └─ 首帧回调 → FlutterView.onFirstFrame
```

---

## 关键日志节点（按时序）

以下日志分为两类：
- **`LOGI` / `OHOS_LOGI`**：Release 版本可见，用于关键流程节点
- **`FML_LOG(INFO)`**：Debug 版本可见，Release 版本被过滤（`min_log_level = kLogWarning`）

### 阶段 1：引擎初始化

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `OhosMain init done, rendering_api=<api>` | INFO | ohos_main.cpp | ✅ | 引擎初始化完成，api=2 表示 Vulkan Impeller |
| `BuildRunConfiguration failed (kernel/snapshot unreadable)` | ERROR | ohos_shell_holder.cpp | ✅ | 运行配置构建失败，kernel/snapshot 文件不可读 |
| `Unable to load the kernel blob asset.` | ERROR | ohos_shell_holder.cpp | ✅ | kernel blob 资源加载失败 |

**诊断要点**：
- 若 `OhosMain init done` 未出现，检查引擎初始化失败（如 `FML_CHECK` 崩溃、资源加载失败）
- `rendering_api` 值：1=OpenGL, 2=Vulkan, 3=Software
- `BuildRunConfiguration failed` 或 `Unable to load the kernel blob asset` 表示 Dart kernel 文件缺失或损坏，检查 hap 包完整性

### 阶段 2：Surface 绑定

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `Rasterizer::Setup done.` | INFO | rasterizer.cc | ✅ | Rasterizer 已绑定 surface |
| `SetDisplayWindow result=true/false window=<addr>` | INFO | platform_view_ohos.cpp | ✅ | Surface 绑定到 XComponent 的结果 |
| `NotifyCreated called, onscreen_valid=true/false` | INFO | platform_view_ohos.cpp | ✅ | PlatformView 通知创建完成 |

**诊断要点**：
- `Rasterizer::Setup done` 表示 `PlatformViewOHOS::NotifyCreate` → `SetDisplayWindow` → `Rasterizer::Setup` 链路成功
- `SetDisplayWindow result=false` 表示 surface 绑定失败，检查 native_window 是否有效
- **注意**：在 Impeller Vulkan 路径下，`Rasterizer::Setup done` 可能不出现（surface 通过独立路径初始化），但不代表异常

### 阶段 3：Dart 渲染请求

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `Render layer_tree IS NULL` | WARNING | engine.cc | ✅ | Dart 传入的 layer_tree 为 null（严重异常） |
| `engin Render frame_size is empty` | WARNING | engine.cc | ✅ | 启动时 viewport 未就绪，帧被跳过（**预期内，非异常**） |
| `engin Render device_pixel_ratio <= 0, dpr=<value>` | WARNING | engine.cc | ✅ | 启动时 viewport 未就绪，帧被跳过（**预期内，非异常**） |

**诊断要点**：
- `layer_tree IS NULL`：Dart 侧出现严重错误，需检查 Dart 代码
- `frame_size is empty` / `device_pixel_ratio <= 0`：**v3 起 Release 可见**。启动早期（XComponent 就绪前）出现是**正常时序**，若持续出现则异常

### 阶段 4：Rasterizer 渲染

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `rasterizer no surface, frame dropped (kNotSetUp)` | ERROR | rasterizer.cc | ✅ | surface 未就绪，帧被丢弃（**启动时预期内，仅打印一次**） |
| `GPU unavailable (sync switch), frame dropped` | ERROR | rasterizer.cc | ✅ | GPU 被禁用（如后台切换），帧被丢弃 |
| `AcquireFrame returned null.` | ERROR | rasterizer.cc | ✅ | surface 有效但 AcquireFrame 失败（swapchain 失效） |
| `compositor AcquireFrame failed` | ERROR | rasterizer.cc | ✅ | Compositor 无法获取绘制帧 |

**诊断要点**：
- `kNotSetUp`：**仅在启动早期出现一次是正常的**（带 `static bool logged` 保护）。若持续出现或出现在运行中，说明：
  - `Rasterizer::Setup` 未被调用（ArkTS 侧未调用 `notifyCreate`）
  - Surface 被销毁后未重建（如后台/前台切换异常）
- `GPU unavailable`：应用处于后台或 GPU 被系统回收，返回前台后应自动恢复
- `AcquireFrame null`：surface 丢失或 GPU 资源不足，可能需要重启应用

### 阶段 5：帧提交（SurfaceFrame）

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `SurfaceFrame::Submit already submitted` | WARNING | surface_frame.cc | ✅ | 帧被重复提交（逻辑异常） |
| `SurfaceFrame::Submit failed` | ERROR | surface_frame.cc | ✅ | 帧提交失败 |
| `SurfaceFrame::PerformSubmit submit_callback is null` | ERROR | surface_frame.cc | ✅ | 提交回调为空（严重异常） |
| `SurfaceFrame::PerformSubmit submit_callback failed` | ERROR | surface_frame.cc | ✅ | 提交回调执行失败 |

**诊断要点**：
- `already submitted`：同一帧被提交两次，检查 Rasterizer 逻辑
- `submit_callback is null`：Surface 未正确设置提交回调，检查 Surface 实现
- `submit_callback failed`：GPU 提交失败，检查 GL/Vulkan 上下文状态

### 日志抓取与过滤

遇到渲染异常时，按以下流程抓取并过滤日志：

```bash
# 1) 清空历史日志
hdc shell hilog -r
# 2) 复现问题后抓取全量日志（Ctrl+C 停止）
hdc shell hilog > flutter_log.txt
# 3) 过滤 Flutter 渲染日志
hdc shell hilog | grep -E "Flutter|XComponent|rasterizer|Rasterizer|Impeller|Vulkan|frame_gate|first-frame" > flutter_render.txt
```

按问题类型过滤：

```bash
# 引擎初始化 / Surface 绑定
hdc shell hilog | grep -E "OhosMain|Rasterizer::Setup|SetDisplayWindow|NotifyCreated"
# 渲染管线 / 帧提交
hdc shell hilog | grep -E "engin Render|layer_tree|SurfaceFrame|kNotSetUp|AcquireFrame"
# GPU 上下文（GL / Vulkan）
hdc shell hilog | grep -E "eglGetDisplay|eglCreate|ContextVK|GPUSurface|Could not create"
# Vsync / 视口
hdc shell hilog | grep -E "NativeVSync|viewport metrics|frame_gate"
# UI 线程阻塞 / 首帧
hdc shell hilog | grep -E "FlutterWatchdog|first-frame|onFirstFrame"
```

---

## GPU 上下文与 Surface 创建日志

以下日志在 GPU 上下文、EGL/Vulkan Surface 创建阶段输出，用于诊断 GPU 初始化问题。

### GL Skia 路径

| 日志内容 | 级别 | 来源 | 含义 |
|---|---|---|---|
| `eglGetDisplay failed` | ERROR | ohos_environment_gl.cpp | 无法获取 EGL display |
| `eglInitialize failed` | ERROR | ohos_environment_gl.cpp | EGL 初始化失败 |
| `eglCreateWindowSurface returned EGL_NO_SURFACE err=<code>` | ERROR | ohos_context_gl_skia.cpp | 创建窗口 surface 失败 |
| `eglCreatePbufferSurface returned EGL_NO_SURFACE err=<code>` | ERROR | ohos_context_gl_skia.cpp | 创建离屏 surface 失败 |
| `SetNativeWindow onscreen_surface invalid` | ERROR | ohos_surface_gl_skia.cpp | onscreen surface 创建成功但无效 |

### GL Impeller 路径

| 日志内容 | 级别 | 来源 | 含义 |
|---|---|---|---|
| `Could not create EGL display.` | ERROR | ohos_surface_gl_impeller.cpp | EGL display 创建失败 |
| `Could not choose onscreen config.` | ERROR | ohos_surface_gl_impeller.cpp | 无法选择 onscreen EGL 配置 |
| `Could not choose offscreen config.` | ERROR | ohos_surface_gl_impeller.cpp | 无法选择 offscreen EGL 配置 |
| `Could not create onscreen context.` | ERROR | ohos_surface_gl_impeller.cpp | onscreen GL 上下文创建失败 |
| `Could not create offscreen context.` | ERROR | ohos_surface_gl_impeller.cpp | offscreen GL 上下文创建失败 |
| `Could not create offscreen surface.` | ERROR | ohos_surface_gl_impeller.cpp | offscreen surface 创建失败 |
| `Could not make offscreen context current.` | ERROR | ohos_surface_gl_impeller.cpp | 无法激活 offscreen 上下文 |
| `Could not create Impeller context.` | ERROR | ohos_surface_gl_impeller.cpp | Impeller 上下文创建失败 |
| `Could not clear offscreen context.` | ERROR | ohos_surface_gl_impeller.cpp | 无法清除 offscreen 上下文 |
| `Could not add lifecycle listeners` | ERROR | ohos_surface_gl_impeller.cpp | 无法添加生命周期监听 |
| `Could not create onscreen surface.` | ERROR | ohos_surface_gl_impeller.cpp | onscreen surface 创建失败 |
| `GPUSurfaceGLImpeller delegate is null` | ERROR | gpu_surface_gl_impeller.cc | GPU surface delegate 为空 |
| `GPUSurfaceGLImpeller context invalid` | ERROR | gpu_surface_gl_impeller.cc | Impeller 上下文无效 |
| `GPUSurfaceGLImpeller renderer invalid` | ERROR | gpu_surface_gl_impeller.cc | Impeller 渲染器无效 |
| `GPUSurfaceGLImpeller aiks_context invalid` | ERROR | gpu_surface_gl_impeller.cc | Aiks 上下文无效 |

### Vulkan Impeller 路径

| 日志内容 | 级别 | 来源 | 含义 |
|---|---|---|---|
| `ContextVK::Create returned null` | ERROR | ohos_context_vulkan_impeller.cpp | Vulkan Impeller 上下文创建失败 |
| `CreateSurfaceContext returned null` | ERROR | ohos_surface_vulkan_impeller.cpp | Vulkan surface 上下文创建失败 |
| `SetWindowSurface failed` | ERROR | ohos_surface_vulkan_impeller.cpp | Vulkan 窗口 surface 设置失败 |
| `GPUSurfaceVulkanImpeller context invalid` | ERROR | gpu_surface_vulkan_impeller.cc | Vulkan Impeller 上下文无效 |
| `GPUSurfaceVulkanImpeller renderer invalid` | ERROR | gpu_surface_vulkan_impeller.cc | Vulkan 渲染器无效 |
| `GPUSurfaceVulkanImpeller aiks_context invalid` | ERROR | gpu_surface_vulkan_impeller.cc | Vulkan Aiks 上下文无效 |

### Software 路径

| 日志内容 | 级别 | 来源 | 含义 |
|---|---|---|---|
| `software surface unsupported format=<fmt>, frame content skipped` | WARNING | ohos_surface_software.cpp | 软件渲染遇到不支持的像素格式，帧内容被跳过 |

---

## XComponent 与生命周期日志

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `XComponent SurfaceCreated window=<addr> engine_attached=true/false` | INFO | ohos_xcomponent_adapter.cpp | ✅ | XComponent surface 创建完成 |
| `XComponent destroyed, id=<id>` | INFO | ohos_xcomponent_adapter.cpp | ✅ | XComponent 被销毁 |
| `frame_gate enabled=false reason=SurfaceCreated` | INFO | platform_view_ohos.cpp | ✅ | Surface 创建后帧门控关闭 |
| `frame_gate enabled=true reason=ExecuteAggressive` | INFO | platform_view_ohos.cpp | ✅ | 激进回收时帧门控开启 |
| `frame_gate enabled=false reason=PiP_visible` | INFO | platform_view_ohos.cpp | ✅ | PiP 可见时帧门控关闭 |
| `frame_gate enabled=false reason=ExecuteAggressiveCore` | INFO | platform_view_ohos.cpp | ✅ | 激进回收核心执行后帧门控关闭 |
| `first-frame callback.` | INFO | platform_view_ohos.cpp | ✅ | 首帧回调已安装 |
| `first-frame fired` | INFO | platform_view_ohos.cpp | ✅ | 首帧回调已触发 |
| `first-frame wait cleared` | INFO | shell.cc | ✅ | 首帧等待条件已清除 |
| `rebuild skipped, surface=yes/no window=yes/no valid=true/false` | INFO | platform_view_ohos.cpp | ✅ | 跳过 onscreen 上下文重建 |
| `GpuReclaim: [Raster] rebuild SetDisplayWindow failed, no retry` | ERROR | platform_view_ohos.cpp | ✅ | 重建时 SetDisplayWindow 失败 |

---

## Vsync 日志

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `OH_NativeVSync_Create returned null` | ERROR | vsync_waiter_ohos.cpp | ✅ | Vsync 句柄创建失败 |
| `OH_NativeVSync_RequestFrameWithMultiCallback failed: <code>` | ERROR | vsync_waiter_ohos.cpp | ✅ | 请求 vsync 帧回调失败 |

---

## Viewport Metrics 日志

| 日志内容 | 级别 | 来源 | 是否 Release 可见 | 含义 |
|---|---|---|---|---|
| `invalid viewport metrics dpr=<dpr> w=<w> h=<h>` | WARNING | shell.cc | ✅ | 视口参数无效，帧被忽略 |

**诊断要点**：
- 启动早期出现是**正常时序**（XComponent 未就绪）
- 若持续出现或 `dpr <= 0`，检查 ArkTS 侧 viewport 设置

---

## 正常启动日志示例

```log
# 阶段 1: 引擎初始化
[INFO:ohos_main.cpp] OhosMain init done, rendering_api=2

# 阶段 2: XComponent 加载（ArkTS 侧日志）
[INFO:AceXcomponent] XComponent[oh_flutter_1] triggers onLoad and OnSurfaceCreated callback
[INFO:AceXcomponent] XComponent[oh_flutter_1] native OnSurfaceCreated

# 阶段 3: 启动时序竞争（可能出现，属正常）
[ERROR:rasterizer.cc] rasterizer no surface, frame dropped (kNotSetUp)

# 阶段 4: Surface 绑定成功
[INFO:rasterizer.cc] Rasterizer::Setup done.
[INFO:platform_view_ohos.cpp] SetDisplayWindow result=1 window=0x...
[INFO:platform_view_ohos.cpp] NotifyCreated called, onscreen_valid=1

# 阶段 5: 首帧回调
[INFO:platform_view_ohos.cpp] first-frame callback.
[INFO:platform_view_ohos.cpp] first-frame fired
[INFO:shell.cc] first-frame wait cleared

# （后续无新增 ERROR 日志 = 渲染正常）
```

---

## 异常场景诊断

### 场景 1：白屏（首帧迟迟不上屏）

**诊断流程**：

1. **检查引擎是否初始化**
   - 搜索 `OhosMain init done`
   - 未出现 → 引擎初始化失败，查崩溃日志或 `FML_CHECK`

2. **检查 XComponent 是否加载**
   - 搜索 `XComponent` 日志（ArkTS 侧）
   - 未出现 → ArkTS 侧未触发 `onLoad`，检查 FlutterView 配置

3. **检查 Surface 是否绑定**
   - 搜索 `Rasterizer::Setup done`
   - 未出现 → `NotifyCreate` 未被调用，检查 ArkTS 侧是否调用 `flutterView?.notifyCreate(nativeWindow)`

4. **检查是否有持续 kNotSetUp**
   - 若 `kNotSetUp` 日志持续出现（非仅启动时一次）
   - → Surface 绑定失败或持续丢失，检查 `SetDisplayWindow` 返回值

5. **检查 GPU 是否可用**
   - 搜索 `GPU unavailable` → 应用在后台或 GPU 被回收

6. **检查 AcquireFrame 是否失败**
   - 搜索 `AcquireFrame returned null` → swapchain 失效，检查 surface 生命周期

### 场景 2：启动后画面闪烁/花屏

**诊断流程**：

1. 检查 `Rasterizer::Setup done, surface_valid=false`
   - surface 无效但仍尝试渲染 → 检查 EGL/Vulkan 上下文创建日志

2. 检查 `ohos_surface_vulkan_impeller.cpp` 或 `ohos_surface_gl_*.cpp` 的 ERROR 日志

### 场景 3：后台返回后白屏

**诊断流程**：

1. 检查是否有 `GPU unavailable` 日志
   - 返回前台后应自动恢复，若持续出现 → Reclaim 状态机异常

2. 检查 `Rasterizer::Setup done` 是否再次出现
   - 后台/前台切换应触发 surface 重建，若未出现 → `ShouldRebuildOnscreenContext` 返回 false

3. 检查 `PlatformViewOHOS`  reclaim 日志

### 场景 4：Dart 层初始化异常（新增）

**诊断流程**：

1. 检查 `OhosMain init done` 是否出现
   - 出现 → 引擎初始化成功

2. 检查后续是否有 `Rasterizer::Setup done`、`engine Render` 等日志
   - **若 `OhosMain init done` 后长时间无任何 Flutter 渲染日志**
   - → 可能是 Dart 层 `WidgetsBinding` 初始化异常、`runApp()` 未执行、或 Platform Channel 阻塞

3. 检查是否有 `FlutterWatchdog: FlutterUiThread is not alive`
   - 出现 → UI 线程阻塞，需检查 Dart 代码是否有死锁或长时间同步操作

**典型案例**：
- 自定义 `WidgetsFlutterBinding` 重写 `initInstances()` 导致初始化不完整
- 插件在 `initInstances()` 中过早初始化，Platform Channel 未就绪
- `runApp()` 未被调用或调用前发生异常

---

## 日志级别速查

| 日志前缀 | 级别 | 是否 Release 可见 | 出现场景 |
|---|---|---|---|
| `OhosMain init done` | INFO | ✅ | 引擎初始化完成 |
| `BuildRunConfiguration failed` | ERROR | ✅ | kernel/snapshot 文件不可读 |
| `Unable to load the kernel blob asset` | ERROR | ✅ | kernel blob 加载失败 |
| `Rasterizer::Setup done` | INFO | ✅ | Surface 绑定成功 |
| `SetDisplayWindow result=` | INFO | ✅ | Surface 绑定结果 |
| `rasterizer no surface` | ERROR | ✅ | surface 未就绪（**启动时一次为正常**） |
| `GPU unavailable` | ERROR | ✅ | GPU 被禁用 |
| `AcquireFrame returned null` | ERROR | ✅ | swapchain 失效 |
| `compositor AcquireFrame failed` | ERROR | ✅ | Compositor 失败 |
| `SurfaceFrame::Submit already submitted` | WARNING | ✅ | 帧重复提交 |
| `SurfaceFrame::Submit failed` | ERROR | ✅ | 帧提交失败 |
| `SurfaceFrame::PerformSubmit submit_callback is null` | ERROR | ✅ | 提交回调为空 |
| `SurfaceFrame::PerformSubmit submit_callback failed` | ERROR | ✅ | 提交回调执行失败 |
| `Render layer_tree IS NULL` | WARNING | ✅ | Dart 传入 null（异常） |
| `engin Render frame_size is empty` | WARNING | ✅ | 启动时 viewport 未就绪（正常时序） |
| `engin Render device_pixel_ratio <= 0` | WARNING | ✅ | 启动时 viewport 未就绪（正常时序） |
| `invalid viewport metrics` | WARNING | ✅ | 视口参数无效 |
| `eglGetDisplay failed` | ERROR | ✅ | EGL display 获取失败 |
| `eglInitialize failed` | ERROR | ✅ | EGL 初始化失败 |
| `eglCreateWindowSurface returned EGL_NO_SURFACE` | ERROR | ✅ | EGL 窗口 surface 创建失败 |
| `ContextVK::Create returned null` | ERROR | ✅ | Vulkan 上下文创建失败 |
| `CreateSurfaceContext returned null` | ERROR | ✅ | Vulkan surface 上下文创建失败 |
| `SetWindowSurface failed` | ERROR | ✅ | Vulkan 窗口 surface 设置失败 |
| `GPUSurfaceGLImpeller context invalid` | ERROR | ✅ | GL Impeller 上下文无效 |
| `GPUSurfaceVulkanImpeller context invalid` | ERROR | ✅ | Vulkan Impeller 上下文无效 |
| `software surface unsupported format` | WARNING | ✅ | 软件渲染格式不支持 |
| `XComponent SurfaceCreated` | INFO | ✅ | XComponent surface 创建 |
| `XComponent destroyed` | INFO | ✅ | XComponent 销毁 |
| `frame_gate enabled=` | INFO | ✅ | 帧门控状态变更 |
| `first-frame callback` | INFO | ✅ | 首帧回调安装 |
| `first-frame fired` | INFO | ✅ | 首帧回调触发 |
| `first-frame wait cleared` | INFO | ✅ | 首帧等待清除 |
| `OH_NativeVSync_Create returned null` | ERROR | ✅ | Vsync 创建失败 |
| `OH_NativeVSync_RequestFrameWithMultiCallback failed` | ERROR | ✅ | Vsync 请求失败 |
| `FlutterWatchdog: FlutterUiThread is not alive` | ERROR | ✅ | UI 线程阻塞（10秒无响应） |

---

## 常见问题 FAQ

### 为什么启动时看到 `rasterizer no surface, frame dropped (kNotSetUp)`，但应用正常？

**A**: 这是**正常的启动时序**。流程是：
1. Dart 引擎先启动，开始请求帧
2. XComponent 的 `onLoad` / `OnSurfaceCreated` 后触发
3. 在 (2) 完成前，rasterizer 没有 surface，因此帧被丢弃
4. 一旦 `NotifyCreate` → `Rasterizer::Setup` 完成，后续帧正常渲染

此日志**仅打印一次**（代码中使用 `static bool logged` 保护）。

### 为什么没有看到 `Rasterizer::Setup done` 日志，但画面正常？

**A**: 在使用 **Impeller Vulkan** 后端时，surface 可能通过独立路径初始化（不经过 `Rasterizer::Setup`）。此时：
- `Rasterizer::Setup` 可能未被调用
- 但 Vulkan surface 通过 `OHOSurfaceVulkanImpeller` 直接绑定到 XComponent
- 只要 `XComponent.onLoad` 触发了 `onSurfaceCreated()`，Vulkan 路径就能正常工作

**建议**：ArkTS 侧仍应调用 `flutterView?.notifyCreate(nativeWindow)` 以确保所有路径兼容。

### 启动时看到 `Animator RequestFrame skipped (semaphore busy)` 日志？

**A**: 此日志**不存在于当前代码中**。`animator.cc` 的 `RequestFrame` 在 `pending_frame_semaphore_.TryWait()` 失败时仅记录 `TRACE_EVENT`（用于 systrace 分析），不会输出任何 `WARNING` 级别日志。

若你在旧版本引擎中看到此日志，说明当时添加了额外的 `FML_LOG(WARNING)`，该日志因启动时序竞争高频出现，已被移除。

### 如何确认首帧真正渲染成功？

**A**: 
- **Release 版本**：搜索 `first-frame fired` 日志（platform_view_ohos.cpp）
- **ArkTS 侧**：监听 `FlutterView.onFirstFrame` 回调
- 若 `Rasterizer::Setup done` 后出现且再无新增 ERROR 日志，说明渲染管线已通

### 为什么 `FML_LOG(INFO)` 在 Release 中不打印，但 `LOGI` 可以？

**A**: 
- `FML_LOG(INFO)` 受 `min_log_level` 控制，Release 模式下默认为 `kLogWarning`，所以 `INFO` 级别被过滤
- `LOGI` 宏（`ohos_logging.h`）直接调用 `OH_LOG_Print(LOG_INFO)`，不受 `min_log_level` 影响，Release 中始终可见
- `shell/common` 中的 `OHOS_LOGI` 同理，直接调用 `OH_LOG_Print`，Release 中始终可见

### 白屏时 `OhosMain init done` 后出现，但之后没有任何 Flutter 渲染日志？

**A**: 这说明 **Dart 层初始化或执行异常**，而非 Flutter Engine 渲染管线问题。可能原因：
1. `WidgetsFlutterBinding.ensureInitialized()` 未正确调用
2. 自定义 `WidgetsFlutterBinding` 重写了 `initInstances()` 导致初始化不完整
3. `runApp()` 未被调用或调用前发生异常
4. Platform Channel 在 Engine 未就绪时被调用，导致 Dart 侧阻塞

**排查方向**：
- 检查 Dart 层日志（`print` 输出）
- 检查是否有 `FlutterWatchdog: FlutterUiThread is not alive`（10秒后出现）
- 检查 ArkTS 侧是否正确调用了 `flutterView?.notifyCreate(nativeWindow)`

---

## 诊断 Checklist

遇到白屏或渲染异常时，按以下顺序检查：

- [ ] 1. 搜索 "OhosMain init done" → 确认引擎初始化
- [ ] 2. 搜索 "BuildRunConfiguration failed" / "Unable to load the kernel blob" → 确认 Dart kernel 加载
- [ ] 3. 搜索 "Rasterizer::Setup done" → 确认 surface 绑定（Impeller 可能无此日志）
- [ ] 4. 搜索 "SetDisplayWindow result=" → 确认 surface 绑定结果
- [ ] 5. 搜索新增 ERROR 日志 → 定位具体失败点
- [ ] 6. 检查 XComponent 生命周期日志（"XComponent SurfaceCreated" / "XComponent destroyed"）
- [ ] 7. 检查是否有持续的 kNotSetUp/GPU unavailable/AcquireFrame null
- [ ] 8. 检查 ohos_surface_*.cpp / gpu_surface_*.cc 的 ERROR 日志 → GPU 上下文问题
- [ ] 9. 检查 "SurfaceFrame::Submit failed" / "submit_callback" → 帧提交问题
- [ ] 10. 检查 vsync_waiter_ohos.cpp 日志 → 帧调度问题
- [ ] 11. 检查 "frame_gate enabled=" → GPU 回收状态机
- [ ] 12. 检查 FlutterWatchdog 日志 → UI 线程是否阻塞
- [ ] 13. 若 OhosMain init done 后无任何渲染日志 → 检查 Dart 层初始化

---

## 附录：源码文件索引

| 模块 | 文件 | 关键功能 |
|---|---|---|
| OHOS 入口 | `shell/platform/ohos/ohos_main.cpp` | 引擎初始化 |
| Shell Holder | `shell/platform/ohos/ohos_shell_holder.cpp` | Shell 创建与启动 |
| PlatformView | `shell/platform/ohos/platform_view_ohos.cpp` | Surface 绑定、生命周期、GPU 回收 |
| XComponent | `shell/platform/ohos/ohos_xcomponent_adapter.cpp` | OS Surface 回调 |
| Vsync | `shell/platform/ohos/vsync_waiter_ohos.cpp` | 帧同步 |
| Engine | `shell/common/engine.cc` | Dart 渲染请求处理 |
| Animator | `shell/common/animator.cc` | 帧调度 |
| Rasterizer | `shell/common/rasterizer.cc` | 渲染执行 |
| SurfaceFrame | `flow/surface_frame.cc` | 帧提交 |
| Shell | `shell/common/shell.cc` | 视口管理、首帧等待 |
| GPU Surface GL | `shell/gpu/gpu_surface_gl_impeller.cc` | GL Impeller GPU surface |
| GPU Surface Vulkan | `shell/gpu/gpu_surface_vulkan_impeller.cc` | Vulkan Impeller GPU surface |
| OHOS GL Context | `shell/platform/ohos/ohos_context_gl_skia.cpp` | GL Skia 上下文 |
| OHOS Vulkan Context | `shell/platform/ohos/ohos_context_vulkan_impeller.cpp` | Vulkan Impeller 上下文 |
| OHOS GL Env | `shell/platform/ohos/ohos_environment_gl.cpp` | EGL 环境初始化 |
| OHOS GL Impeller Surface | `shell/platform/ohos/ohos_surface_gl_impeller.cpp` | GL Impeller surface |
| OHOS GL Skia Surface | `shell/platform/ohos/ohos_surface_gl_skia.cpp` | GL Skia surface |
| OHOS Vulkan Surface | `shell/platform/ohos/ohos_surface_vulkan_impeller.cpp` | Vulkan Impeller surface |
| OHOS Software Surface | `shell/platform/ohos/ohos_surface_software.cpp` | 软件渲染 surface |

---

## 实战案例对比分析

### 案例：正常启动 vs 白屏启动日志对比

#### 正常启动（4log.txt）

```log
[INFO]  OhosMain init done, rendering_api=2
[WARN]  Unknown GPU Driver Vendor: 6629
[WARN]  engin Render frame_size is empty          ← 启动时序正常（v3 起 Release 可见）
[WARN]  engin Render device_pixel_ratio <= 0, dpr=1
[INFO]  Rasterizer::Setup done, surface_valid=true
[INFO]  first-frame fired
[ERROR] cannot get pixelmap orientation:401        ← 图片解码警告
[ERROR] Failed to SetPresentInfo                   ← 上屏警告
[ERROR] FlutterWatchdog: FlutterUiThread is not alive  ← 10秒后出现
```

**特征**：`OhosMain init done` 后有完整的渲染流程日志（engine Render、Rasterizer::Setup、first-frame fired、image decode、SetPresentInfo）。

#### 白屏启动（3log.txt）

```log
[INFO]  OhosMain init done, rendering_api=2
[WARN]  Unknown GPU Driver Vendor: 6629
[ERROR] FlutterWatchdog: FlutterUiThread is not alive  ← 10秒后出现
```

**特征**：`OhosMain init done` 后**没有任何** Flutter 渲染流程日志，10秒后出现 UI 线程阻塞。

#### 诊断结论

| 对比项 | 正常启动 | 白屏启动 | 结论 |
|--------|---------|---------|------|
| OhosMain init | ✅ | ✅ | 引擎初始化成功 |
| engine Render | ✅ | ❌ | 白屏时未执行到 Render |
| Rasterizer::Setup | ✅ | ❌ | 白屏时 surface 未绑定 |
| first-frame fired | ✅ | ❌ | 白屏时首帧未触发 |
| image decode | ✅ | ❌ | 白屏时未加载图片 |
| SetPresentInfo | ✅ | ❌ | 白屏时未上屏 |
| FlutterWatchdog | ✅ | ✅ | 两者都有，非根因 |

**根因推断**：白屏场景下，Dart 层在 `OhosMain init done` 后**完全卡死**，未执行到 `Engine::Render` 阶段。这是典型的 **Dart 层初始化异常**，而非 Flutter Engine 渲染管线问题。

**排查方向**：
1. 检查 Dart 层 `main()` 是否执行
2. 检查 `WidgetsFlutterBinding.ensureInitialized()` 是否正确调用
3. 检查自定义 `WidgetsFlutterBinding` 是否重写了 `initInstances()`
4. 检查是否有 Platform Channel 在 Engine 未就绪时被调用
