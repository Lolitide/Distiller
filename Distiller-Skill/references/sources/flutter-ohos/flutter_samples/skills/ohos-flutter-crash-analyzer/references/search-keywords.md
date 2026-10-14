# 崩溃搜索关键词

本文档整理了在不同崩溃场景下，用于搜索上游社区 Issue 和 PR 的关键词。

## 崩溃类型关键词

### 1. 空指针崩溃 (SIGSEGV - Null Pointer)

**英文关键词**：
```
null pointer dereference
nullptr crash
SIGSEGV
crash null
access violation null
```

**组合关键词**：
```
null pointer + [module_name]
nullptr crash + [version]
SIGSEGV + [function_name]
```

**示例搜索**：
- "null pointer dereference shell"
- "nullptr crash impeller"
- "SIGSEGV fml MessageLoop"

### 2. 内存访问崩溃 (SIGSEGV - Memory Access)

**英文关键词**：
```
memory access violation
segmentation fault
bad memory access
out of bounds
buffer overflow
use after free
double free
dangling pointer
wild pointer
```

**组合关键词**：
```
memory crash + [module]
buffer overflow + [component]
use after free + [class_name]
```

**示例搜索**：
- "use after free layer tree"
- "buffer overflow display list"
- "memory access violation impeller"

### 3. 断言失败 (SIGABRT - Assertion Failed)

**英文关键词**：
```
assertion failed
CHECK failed
DCHECK failed
assert crash
SIGABRT
```

**组合关键词**：
```
assertion failed + [condition]
CHECK failed + [file_name]
DCHECK + [function_name]
```

**示例搜索**：
- "CHECK failed is_valid"
- "assertion failed task runner"
- "DCHECK failed raster thread"

### 4. 线程相关问题

**英文关键词**：
```
thread safety
race condition
deadlock
thread check
wrong thread
not on thread
task runner
message loop
```

**组合关键词**：
```
thread safety + [class]
race condition + [module]
deadlock + [component]
```

**示例搜索**：
- "thread safety RefPtr"
- "race condition shell"
- "not on platform thread"

### 5. 资源泄漏

**英文关键词**：
```
memory leak
resource leak
reference leak
handle leak
file descriptor leak
```

**组合关键词**：
```
memory leak + [component]
resource leak + [module]
```

**示例搜索**：
- "memory leak texture"
- "resource leak platform view"

### 6. 初始化问题

**英文关键词**：
```
not initialized
initialization failed
constructor crash
startup crash
initialization order
```

**组合关键词**：
```
initialization failed + [module]
not initialized + [variable]
startup crash + [platform]
```

**示例搜索**：
- "initialization failed engine"
- "startup crash android"

## 模块关键词

### FML 模块
```
fml
message loop
task runner
thread
ref ptr
logging
```

### Shell 模块
```
shell
engine
platform view
rasterizer
animator
```

### Flow 模块
```
flow
layer tree
compositor
diff context
```

### Impeller 模块
```
impeller
renderer
context
pipeline
command buffer
```

### Platform Embedder
```
platform embedder
[platform_name]: android, ios, macos, windows, linux, ohos
surface
view
window
```

## 平台特定关键词

### 鸿蒙 (OHOS)
```
ohos
harmonyos
openharmony
napi
arkui
```

## 版本关键词

> **动态构建建议**：版本关键词应根据实际使用的 Flutter/Engine 版本动态构建。以下列出常用版本，实际分析时应使用崩溃日志中的具体版本号。

### Flutter 版本

**主流版本**（截至 2026-06）：
```
flutter:3.0
flutter:3.10
flutter:3.13
flutter:3.16
flutter:3.19
flutter:3.22
flutter:3.24
flutter:3.27
flutter:3.29
```

**使用示例**：
```
repo:flutter/flutter is:issue "crash" "3.22"
repo:flutter/engine is:issue "regression" milestone:3.27
```

### Engine 版本

**标准 Engine 版本**：
```
engine:3.0
engine:3.10
engine:3.13
engine:3.16
engine:3.19
engine:3.22
engine:3.24
engine:3.27
```

**HarmonyOS/OHOS 专用版本** ⚠️：
```
engine:3.10.0-ohos
engine:3.13.0-ohos
engine:3.16.0-ohos
engine:3.19.0-ohos
engine:3.22.0-ohos
ohos
harmonyos flutter
```

**使用示例**：
```
# 搜索 OHOS 特定版本问题
repo:flutter/engine is:issue "3.13.0-ohos" "SIGSYS"

# 搜索 HarmonyOS 平台崩溃
repo:flutter/engine is:issue "harmonyos" "NAPI"
```

### 版本范围关键词
```
regression        # 版本回归问题
broke in          # 在某版本开始崩溃
works in          # 在某版本正常工作
since version     # 从某版本开始
fixed in          # 在某版本修复
```

### 版本号提取方法

**从崩溃日志提取版本**：
```bash
# Flutter 版本
grep "Flutter version" crash.log

# Engine commit hash（更精确）
grep "Engine commit" crash.log
grep "Build fingerprint" crash.log  # HarmonyOS 设备版本

# 使用 commit hash 搜索（推荐，最精确）
repo:flutter/engine is:issue "abc123def"  # 实际 commit hash
```

**HarmonyOS 版本识别**：
```
Build fingerprint: 'Huawei/OHOS/Mate60Pro:3.1.0...'
→ HarmonyOS 3.1.0，需搜索 OHOS 专用 Engine 版本
```

## 场景关键词

### 渲染相关
```
rendering
draw
paint
gpu
vulkan
metal
opengl
skia
impeller
```

### 输入相关
```
input
touch
mouse
keyboard
gesture
```

### 生命周期相关
```
lifecycle
pause
resume
destroy
background
foreground
```

### 网络相关
```
network
http
websocket
socket
download
```

### 插件相关
```
plugin
method channel
event channel
platform channel
message channel
```

## 搜索策略

### 1. 精确搜索
使用堆栈中的完整函数名或类名：
```
"Shell::RunEngine"
"Rasterizer::Draw"
```

### 2. 模块搜索
结合崩溃类型和模块名：
```
"SIGSEGV" + "impeller"
"null pointer" + "fml"
```

### 3. 版本搜索
限定 Flutter 或 Engine 版本：
```
"crash" label:"v3.10"
"regression" milestone:3.16
```

### 4. 状态过滤
查找已修复的 Issue：
```
is:issue is:closed
is:pr is:merged
```

### 5. 时间范围
限定时间范围：
```
created:>2023-01-01
updated:>2024-01-01
```

## GitHub 搜索技巧

### 在 Flutter 仓库搜索
```
repo:flutter/flutter [keywords]
```

### 在 Engine 仓库搜索
```
repo:flutter/engine [keywords]
```

### 搜索 Issue
```
is:issue [keywords]
```

### 搜索 PR
```
is:pr [keywords]
```

### 组合搜索示例
```
repo:flutter/engine is:issue is:closed "SIGSEGV" "impeller"
repo:flutter/flutter is:issue "null pointer" "fml"
repo:flutter/engine is:pr is:merged "thread safety"
```

## 搜索优先级

### 高优先级
1. 精确匹配函数名或类名
2. 崩溃类型 + 核心模块
3. 包含完整错误消息

### 中优先级
1. 崩溃类型 + 模块
2. 关键词组合
3. 版本范围

### 低优先级
1. 单个关键词
2. 广泛搜索
3. 相关但不精确的描述

## 常用搜索模板

### 模板 1：空指针崩溃
```
repo:flutter/engine is:issue "SIGSEGV" "[module_name]"
repo:flutter/engine is:issue "null pointer" "[class_name]"
```

### 模板 2：线程问题
```
repo:flutter/engine is:issue "thread safety" "[module_name]"
repo:flutter/engine is:issue "not on thread" "[function_name]"
```

### 模板 3：渲染问题
```
repo:flutter/engine is:issue "crash" "impeller"
repo:flutter/engine is:issue "gpu crash" "rasterizer"
```

### 模板 4：平台特定
```
repo:flutter/engine is:issue "[platform_name]" "crash"
repo:flutter/flutter is:issue "[platform_name]" "engine"
```

## 注意事项

1. **关键词选择**：优先使用英文关键词
2. **版本限定**：明确标注 Flutter 和 Engine 版本
3. **平台限定**：如果是平台特定问题，标注平台
4. **状态筛选**：同时搜索 open 和 closed issue
5. **多仓库搜索**：同时在 flutter/flutter 和 flutter/engine 仓库搜索
6. **时间范围**：根据问题发生时间限定搜索范围