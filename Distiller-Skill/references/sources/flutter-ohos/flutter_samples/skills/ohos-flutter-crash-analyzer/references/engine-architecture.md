# Flutter Engine 架构说明

## 整体架构

Flutter Engine 采用分层架构设计，主要包含以下层次：

```
┌─────────────────────────────────────┐
│        Flutter Framework (Dart)      │
├─────────────────────────────────────┤
│           Dart Runtime               │
├─────────────────────────────────────┤
│         Flutter Engine (C++)         │
├─────────────────────────────────────┤
│       Platform Embedder              │
├─────────────────────────────────────┤
│         Operating System             │
└─────────────────────────────────────┘
```

## 核心模块

### 1. FML (Flutter Meta Language Library)
**路径**: `fml/`

**功能**：
- 提供基础工具类和平台抽象
- 消息循环 (MessageLoop)
- 任务运行器 (TaskRunner)
- 日志系统
- 内存管理工具

**关键类**：
- `fml::MessageLoop` - 消息循环
- `fml::TaskRunner` - 任务调度
- `fml::Thread` - 线程封装
- `fml::RefPtr` - 智能指针

### 2. Shell
**路径**: `shell/`

**功能**：
- Engine 和 Framework 的协调者
- 管理线程模型
- 平台嵌入层接口
- 生命周期管理

**关键类**：
- `shell::Shell` - 核心协调器
- `shell::Engine` - Dart 引擎管理
- `shell::PlatformView` - 平台视图抽象
- `shell::Rasterizer` - 光栅化器

**线程模型**：

Flutter Engine 采用四线程架构：
1. **Platform Thread** - 平台交互、主线程
2. **UI Thread** - Dart 代码执行
3. **Raster Thread** - GPU 光栅化
4. **IO Thread** - 资源加载、异步任务

详细线程规则和任务调度 → 参见 [`§线程安全`](#线程安全) 章节

### 3. Flow (Compositor)
**路径**: `flow/`

**功能**：
- 场景图合成
- 图层树管理
- 光栅化任务调度

**关键类**：
- `flow::LayerTree` - 图层树
- `flow::CompositorContext` - 合成上下文
- `flow::DiffContext` - 差异计算

### 4. Display List
**路径**: `display_list/`

**功能**：
- 绘制操作记录
- 显示列表缓存
- 渲染优化

**关键类**：
- `DisplayList` - 显示列表
- `DisplayListBuilder` - 构建器
- `DisplayListCanvasRecorder` - 记录器

### 5. Impeller (新一代渲染引擎)
**路径**: `impeller/`

**功能**：
- 现代 GPU 渲染引擎
- 替代 Skia
- 更好的性能和可预测性

**关键组件**：
- `impeller::Context` - 渲染上下文
- `impeller::Renderer` - 渲染器
- `impeller::CommandBuffer` - 命令缓冲
- `impeller::Pipeline` - 渲染管线

### 6. Runtime
**路径**: `runtime/`

**功能**：
- Dart VM 管理
- Isolate 管理
- Snapshot 加载

**关键类**：
- `runtime::DartVM` - Dart 虚拟机
- `runtime::DartIsolate` - Dart Isolate
- `runtime::DartSnapshot` - 快照管理

### 7. Common
**路径**: `common/`

**功能**：
- 公共工具类
- 设置管理
- 运行时变量

**关键类**：
- `common::Settings` - 配置管理
- `common::RuntimeInfo` - 运行时信息

### 8. Platform Embedder
**路径**: `shell/platform/`

**子目录**：
- `ohos/` - 鸿蒙平台

**功能**：
- 平台特定的初始化
- 窗口管理
- 输入事件处理
- 插件系统

## 数据流

### 渲染流程

```
1. Widget Tree (Dart)
   ↓
2. Element Tree (Dart)
   ↓
3. RenderObject Tree (Dart)
   ↓
4. Layer Tree (Dart)
   ↓
5. Scene Builder (Dart -> C++)
   ↓
6. Display List (C++)
   ↓
7. Layer Tree (C++)
   ↓
8. Rasterization (C++)
   ↓
9. GPU Rendering
```

### 输入事件流

```
1. Platform Event
   ↓
2. Platform Embedder
   ↓
3. Shell (Platform Thread)
   ↓
4. Engine (UI Thread)
   ↓
5. Framework (Dart)
```

## 内存管理

### RefPtr 智能指针
- 基于引用计数的智能指针
- 线程安全的引用计数
- 自动内存管理

### 关键原则
1. 对象所有权明确
2. 循环引用避免
3. 线程安全保证
4. 生命周期管理

## 线程安全

### 线程规则
1. UI Thread - Dart 代码执行
2. Raster Thread - GPU 光栅化
3. IO Thread - 资源加载
4. Platform Thread - 平台交互

### 任务调度
- 使用 `fml::TaskRunner` 进行跨线程任务调度
- 确保线程安全的访问
- 避免死锁

## 崩溃常见位置

### 高风险模块
1. **Shell 初始化** - `shell/common/shell.cc`
2. **Engine 启动** - `shell/common/engine.cc`
3. **Rasterizer 渲染** - `shell/common/rasterizer.cc`
4. **Platform View** - `shell/platform/*/`
5. **Impeller 渲染** - `impeller/`
6. **消息循环** - `fml/message_loop.cc`
7. **任务调度** - `fml/task_runner.cc`

### 常见崩溃类型
1. **空指针访问** - 对象未初始化或已销毁
2. **线程安全违规** - 跨线程访问未加锁
3. **内存访问错误** - 越界、野指针、重复释放
4. **资源泄漏** - 引用计数错误
5. **死锁** - 锁顺序问题

## 调试技巧

### 日志系统
```cpp
FML_LOG(INFO) << "Message";
FML_LOG(WARNING) << "Warning";
FML_LOG(ERROR) << "Error";
FML_DLOG(INFO) << "Debug message";  // 仅 Debug 模式
```

### 断言
```cpp
FML_CHECK(condition) << "Error message";  // 始终检查
FML_DCHECK(condition) << "Debug message";  // 仅 Debug 模式
```

### 性能追踪
- 使用 `fml::tracing::TraceEvent`
- 支持 Chrome Tracing 格式