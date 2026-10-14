# HarmonyOS 崩溃分析指南

> **文档职责说明**：本文档专注于**HarmonyOS 平台特有内容**。
> - ✅ 崩溃类型分类、信号体系（含 HarmonyOS 特定信号）、日志格式、NAPI 相关分析
> - ❌ 不包含：addr2line/ndk-stack 详细使用方法、符号表编译流程、批量解析脚本
> 
> **相关参考**：
> - addr2line/ndk-stack 详细使用 → [`stack-parsing-guide.md`](stack-parsing-guide.md) §堆栈解析方法 章节
> - 符号表准备和编译 → [`stack-parsing-guide.md`](stack-parsing-guide.md) §符号表（Symbol Table）的准备 章节
> - 批量解析脚本 → [`stack-parsing-guide.md`](stack-parsing-guide.md) §完整解析流程 章节

本文档整理自华为开发者官方文档，专门针对 HarmonyOS 平台的崩溃分析方法。

## 崩溃类型分类

### 1. C++ Crash（Native Crash）

**特点**：
- 发生在 Native 层（C/C++ 代码）
- 通常涉及系统信号（SIGSEGV、SIGABRT 等）
- 堆栈信息包含 Native 函数调用

**常见原因**：
- 空指针访问
- 内存越界
- 野指针访问
- 栈溢出
- 除零错误
- 断言失败

### 2. JS Crash（ArkTS Crash）

**特点**：
- 发生在 ArkTS 层
- 通常涉及 JavaScript 运行时错误
- 堆栈信息包含 ArkTS 函数调用

**常见原因**：
- 空对象访问
- 类型错误
- 范围错误
- 语法错误
- 异步错误未捕获

**⚠️ 支持程度说明**：

> 本 Skill 对 JS Crash 提供**基础支持**：
> - ✅ 崩溃信号识别和日志格式解析
> - ✅ 常见错误类型识别
> - ✅ 基础 sourcemap 映射指引
> - ⚠️ **不包含**：完整的 NAPI ↔ ArkTS 关联分析流程、复杂跨语言崩溃根因追踪
> 
> 如需深度 JS Crash 分析，建议参考：
> - [HarmonyOS 应用稳定性-JSCrash 最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-scenario-stability-jscrash)
> - [HarmonyOS 崩溃日志分析指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/jscrash-guidelines)

#### ArkTS 常见运行时错误类型

| 错误类型 | 典型错误信息 | 常见根因 |
|---------|-------------|---------|
| TypeError | `undefined is not a function` | 对象未初始化、类型不匹配 |
| TypeError | `Cannot read property 'x' of undefined` | 空对象访问、链式调用未判空 |
| RangeError | `Maximum call stack size exceeded` | 无限递归、循环调用 |
| ReferenceError | `x is not defined` | 变量未声明、作用域错误 |
| SyntaxError | `Unexpected token` | 代码语法错误（编译时发现） |
| Error | `Uncaught (in promise)` | 异步错误未捕获、Promise rejection 未处理 |

#### NAPI ↔ ArkTS 关联分析要点

**关键判断**：JS Crash 是否与 Native 层有关？

| 现象 | 判断 | 分析方向 |
|------|------|---------|
| 堆栈中包含 `napi_` 函数 | ✅ NAPI 相关 | 检查 NAPI 参数传递、回调触发时机 |
| 错误发生在 NAPI 回调中 | ✅ NAPI 相关 | 检查 Native 层回调触发逻辑 |
| 纯 ArkTS 代码堆栈 | ❌ 纯 ArkTS | 按 ArkTS 错误类型分析 |
| Native 层崩溃后触发 JS 错误 | ⚠️ 关联崩溃 | Native 崩溃是根因，JS Crash 是副作用 |

**NAPI 回调崩溃分析步骤**：
1. 检查 Native 层触发回调时 ArkTS 对象状态
2. 验证 NAPI 参数类型匹配（避免 TypeError）
3. 确认回调注册时机和生命周期管理
4. 检查跨线程调用（ArkTS 主线程 ≠ Native Worker 线程）

## 崩溃信号说明

### POSIX 标准信号

| 信号 | 编号 | 说明 | 常见原因 |
|------|------|------|----------|
| SIGSEGV | 11 | 段错误 | 空指针、内存越界、野指针 |
| SIGABRT | 6 | 程序中止 | assert 失败、abort() 调用 |
| SIGFPE | 8 | 浮点异常 | 除零、浮点溢出 |
| SIGBUS | 10 | 总线错误 | 内存对齐错误 |
| SIGILL | 4 | 非法指令 | 指令错误、代码损坏 |
| SIGTRAP | 5 | 跟踪陷阱 | 调试断点 |

### HarmonyOS 特定信号

| 信号 | 说明 | 处理方式 |
|------|------|----------|
| SIGSYS | 系统调用错误 | 检查系统调用参数 |
| SIGXCPU | CPU 时间超限 | 优化计算密集型任务 |
| SIGXFSZ | 文件大小超限 | 检查文件写入逻辑 |

## 崩溃日志解析

### 日志格式

HarmonyOS 崩溃日志通常包含以下部分：

```
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
Build fingerprint: 'Huawei/OHOS/Device:Version'
Revision: '0'
ABI: 'arm64'
pid: 12345, tid: 12346, name: 'thread_name'  >>> package_name <<<
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
Cause: [原因描述]
    
    [寄存器信息]
    
Backtrace:
    [堆栈信息]

CrashDump:
    [详细转储信息]
```

### 关键字段解析

#### Build fingerprint
- 构建信息，包含设备型号、系统版本
- 用于确认问题是否平台特定

#### pid / tid
- `pid`: 进程 ID
- `tid`: 线程 ID
- `name`: 线程名称
- 用于定位崩溃线程

#### signal / code
- `signal`: 崩溃信号类型
- `code`: 具体错误码
- 用于判断崩溃原因

#### fault addr
- 故障内存地址
- `0x0`: 通常表示空指针
- 非法地址: 可能是野指针或越界

#### Cause
- 崩溃原因描述
- 提供更详细的信息

### 堆栈解析

#### Native 堆栈

```
#00 pc 0000000000a1b234  /system/lib/libxxx.so (function_name+234)
#01 pc 00000000009f87e1  /system/lib/libyyy.so (another_function+89)
```

- `#00`: 栈顶，崩溃点
- `pc`: 程序计数器（相对地址）
- 后面是库文件路径和函数名

#### JS 堆栈

```
Error: undefined is not a function
    at anonymous (entry/src/main/ets/pages/Index.ets:10:5)
    at handleClick (entry/src/main/ets/pages/Home.ets:25:12)
    at onClick (entry/src/main/ets/components/Button.ets:15:9)
```

- 显示文件路径、行号、列号
- 从上到下是调用链

## 崩溃分析流程

### 第一步：收集信息

**必需信息**：
1. 完整的崩溃日志
2. 设备型号和系统版本
3. 应用版本
4. 复现步骤

**可选信息**：
1. 用户操作日志
2. 网络请求日志
3. 崩溃前后的截图/录屏
4. 设备性能数据（CPU、内存）

### 第二步：定位崩溃类型

**识别方法**：
1. 查看 `signal` 字段确定信号类型
2. 查看 `code` 字段确定具体原因
3. 查看 `Cause` 字段获取详细描述

**示例**：
```
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
→ 空指针访问

signal 11 (SIGSEGV), code 2 (SEGV_ACCERR), fault addr 0x7fff1234
→ 内存访问权限错误

signal 6 (SIGABRT), code 0 (SI_USER)
→ 程序主动中止（可能是 assert）
```

### 第三步：解析堆栈

**Native 堆栈解析**：

> **完整工具使用指南** → [`stack-parsing-guide.md`](stack-parsing-guide.md)
> - addr2line 详细用法（基本 + 批量 + HarmonyOS NDK）→ §堆栈解析方法 > addr2line 工具
> - ndk-stack 使用方法和 HarmonyOS 适用性限制 → §堆栈解析方法 > ndk-stack 工具
> - 符号表准备和验证 → §符号表（Symbol Table）的准备

**HarmonyOS 特有注意事项** ⚠️:
- **ndk-stack 适用性限制**：纯 Native C++ ✅，NAPI 混合堆栈 ❌（详见 [`stack-parsing-guide.md` §HarmonyOS 适用性说明](stack-parsing-guide.md)）
- **工具链差异**：HarmonyOS 使用 addr2line + 自定义脚本，而非 ndk-stack（详见 [`SKILL.md HarmonyOS 关键差异`](../SKILL.md#harmonyos-关键差异))

**最简命令示例**：
```bash
# addr2line 单帧解析（推荐，适用于所有 HarmonyOS 崩溃）
addr2line -C -f -e libflutter_engine.so 0xa1b234
```

**JS 堆栈解析**：

#### 基础解析（未混淆代码）

ArkTS 堆栈已包含文件路径和行号，直接查看即可：

```
Error: undefined is not a function
    at handleClick (entry/src/main/ets/pages/Home.ets:25:12)
```

- 文件路径：`entry/src/main/ets/pages/Home.ets`
- 行号：`25`
- 列号：`12`

#### Sourcemap 映射（混淆代码）

如果应用发布时使用了代码混淆（HAR/HAP 包），堆栈显示的是混淆后的位置：

```
Error: TypeError
    at a (entry/build/default/outputs/default/entry-default-signed.hap:1:1234)
```

**映射步骤**：

1. **定位 sourcemap 文件**：
   ```bash
   # HAR/HAP 包解压后通常在：
   # build/default/outputs/default/*.map.js
   # 或应用构建输出目录
   
   find build/ -name "*.map.js" -o -name "*.map"
   ```

2. **使用映射工具**：
   ```bash
   # 使用 source-map 工具（Node.js）
   npm install -g source-map
   
   # 映射行号和列号
   source-map lookup <sourcemap文件> <行号> <列号>
   
   # 示例
   source-map lookup build/default/outputs/default/ets.map.js 1 1234
   ```

3. **输出结果**：
   ```
   Original position:
     source: pages/Home.ets
     line: 25
     column: 12
     name: handleClick
   ```

**注意事项**：
- Sourcemap 文件通常只在 Debug 构建中生成
- Release 构建可能不包含 sourcemap，需提前保留
- HarmonyOS 的 sourcemap 格式可能与标准 JavaScript sourcemap 有差异
- 如果找不到 sourcemap，无法精确定位源码位置

#### 堆栈帧解析要点

| 堆栈帧格式 | 解析方法 |
|-----------|---------|
| `at anonymous (file.ets:10:5)` | 看文件名和行号，anonymous 表示匿名函数 |
| `at handleClick (file.ets:25:12)` | 看函数名和位置，handleClick 是函数名 |
| `at Object.method (file.ets:30:8)` | Object.method 表示对象方法 |
| `at lambda (file.ets:15:3)` | lambda 表示箭头函数 |

### 第四步：分析代码

**关键点**：
1. 定位到源码位置
2. 分析函数逻辑
3. 检查变量状态
4. 确认执行路径

### 第五步：查找根因

**分析方法**：
1. 检查指针有效性
2. 检查数组边界
3. 检查资源生命周期
4. 检查线程安全性
5. 检查内存对齐

### 第六步：验证修复

**验证步骤**：
1. 本地复现崩溃
2. 应用修复方案
3. 再次测试确认修复
4. 进行回归测试
5. 进行压力测试

## 常见崩溃场景

### 场景一：空指针访问

**日志特征**：
```
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
```

**分析要点**：
1. 检查指针是否初始化
2. 检查对象生命周期
3. 检查跨线程访问
4. 检查返回值检查

**示例代码**：
```cpp
// 问题代码
void process(Data* data) {
    int value = data->field;  // 崩溃：data 为 null
}

// 修复代码
void process(Data* data) {
    if (data == nullptr) {
        return;  // 添加空指针检查
    }
    int value = data->field;
}
```

### 场景二：数组越界

**日志特征**：
```
signal 11 (SIGSEGV), code 2 (SEGV_ACCERR), fault addr 0x7fff1234
```

**分析要点**：
1. 检查数组索引范围
2. 检查容器大小
3. 检查迭代器有效性

**示例代码**：
```cpp
// 问题代码
int get(vector<int>& vec, int index) {
    return vec[index];  // 崩溃：index 可能越界
}

// 修复代码
int get(vector<int>& vec, int index) {
    if (index < 0 || index >= vec.size()) {
        return -1;  // 添加边界检查
    }
    return vec[index];
}
```

### 场景三：野指针

**日志特征**：
```
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0xdeadbeef
```

**分析要点**：
1. 检查对象是否已释放
2. 检查智能指针使用
3. 检查资源管理策略

**示例代码**：
```cpp
// 问题代码
class Widget {
    Data* data;
public:
    void init() {
        data = new Data();
    }
    void cleanup() {
        delete data;
        // data 成为野指针
    }
    void process() {
        data->method();  // 崩溃：访问野指针
    }
};

// 修复代码
class Widget {
    std::unique_ptr<Data> data;
public:
    void init() {
        data = std::make_unique<Data>();
    }
    void cleanup() {
        data.reset();  // 自动置空
    }
    void process() {
        if (data) {
            data->method();  // 安全访问
        }
    }
};
```

### 场景四：断言失败

**日志特征**：
```
signal 6 (SIGABRT), code 0 (SI_USER)
Cause: CHECK failed: condition
```

**分析要点**：
1. 理解断言条件
2. 检查状态一致性
3. 检查并发冲突

**示例代码**：
```cpp
// 问题代码
void set_value(int v) {
    CHECK(v >= 0 && v <= 100);  // 崩溃：v 超出范围
    value_ = v;
}

// 修复代码
void set_value(int v) {
    if (v < 0 || v > 100) {
        LOG(ERROR) << "Invalid value: " << v;
        return;  // 或抛出异常
    }
    value_ = v;
}
```

### 场景五：线程安全问题

**日志特征**：
```
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR)
堆栈显示多线程并发访问
```

**分析要点**：
1. 检查共享资源访问
2. 检查锁的使用
3. 检查对象生命周期
4. 检查线程安全注解

**示例代码**：
```cpp
// 问题代码
class Counter {
    int count_ = 0;
public:
    void increment() {
        count_++;  // 崩溃：非原子操作，线程不安全
    }
};

// 修复代码
class Counter {
    std::atomic<int> count_{0};
public:
    void increment() {
        count_.fetch_add(1, std::memory_order_relaxed);  // 原子操作
    }
};

// 或使用互斥锁
class Counter {
    std::mutex mutex_;
    int count_ = 0;
public:
    void increment() {
        std::lock_guard<std::mutex> lock(mutex_);
        count_++;
    }
};
```

### 场景六：JS 空对象访问

**日志特征**：
```
Error: Cannot read property 'xxx' of undefined
    at anonymous (entry/src/main/ets/pages/Index.ets:10:5)
```

**分析要点**：
1. 检查对象是否初始化
2. 检查可选链操作符
3. 检查异步数据加载

**示例代码**：
```typescript
// 问题代码
interface User {
    name: string;
    address?: {
        city: string;
    };
}

function getCity(user: User): string {
    return user.address.city;  // 崩溃：address 可能为 undefined
}

// 修复代码
function getCity(user: User): string {
    return user.address?.city ?? "Unknown";  // 使用可选链和空值合并
}
```

### 场景七：JS 类型错误

**日志特征**：
```
TypeError: xxx is not a function
    at handleClick (entry/src/main/ets/pages/Home.ets:25:12)
```

**分析要点**：
1. 检查变量类型
2. 检查函数定义
3. 检查导入导出

**示例代码**：
```typescript
// 问题代码
function processData(data: any) {
    data.save();  // 崩溃：data 可能没有 save 方法
}

// 修复代码
function processData(data: any) {
    if (typeof data.save === 'function') {
        data.save();
    } else {
        console.error('data.save is not a function');
    }
}
```

## 调试工具

### 1. HiChecker

**功能**：检测线程、性能、安全等问题

**使用方法**：
```typescript
import hichecker from '@ohos.hichecker';

// 启用检测
hichecker.enableChecker(hichecker.CheckerType.THREAD_SAFETY);

// 设置规则
hichecker.addRule(hichecker.RuleType.WARN, 'com.example.app');
```

> **官方文档参考**：[HiChecker API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-hichecker-V5)

### 2. HiLog

**功能**：日志输出和分析

**使用方法**：
```typescript
import hilog from '@ohos.hilog';

hilog.info(0x0000, 'TAG', 'Message: %{public}s', 'value');
hilog.error(0x0000, 'TAG', 'Error occurred');
```

### 3. HiAppEvent

**功能**：应用事件打点

**使用方法**：
```typescript
import hiAppEvent from '@ohos.hiAppEvent';

hiAppEvent.write({
    domain: 'com.example.app',
    name: 'CRASH_EVENT',
    eventType: hiAppEvent.EventType.FAULT,
    params: {
        'crash_type': 'SIGSEGV',
        'crash_addr': '0x0'
    }
});
```

### 4. FaultLogger

**功能**：获取崩溃日志

**使用方法**：
```typescript
import faultLogger from '@ohos.faultLogger';

// 查询崩溃日志（异步调用）
async function getCrashLogs() {
  try {
    const logs = await faultLogger.query(
      faultLogger.FaultType.CPP_CRASH,  // Native 崩溃日志
      0,    // startTime
      10    // limit
    );
    
    for (const log of logs) {
      console.log('Crash log:', JSON.stringify(log));
      console.log('Full log path:', log.fullLogPath);  // 官方 API 字段名
    }
  } catch (error) {
    console.error('Query crash logs failed:', error);
  }
}
```

> **官方文档参考**：[FaultLogger API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-faultlogger-V5)

**注意**：
- `query()` 返回 `Promise<Array<FaultLogInfo>>`，必须使用 `await`
- `FaultType.CPP_CRASH`：Native C++ 崩溃
- `FaultType.JS_CRASH`：ArkTS 崩溃
- 字段名：`fullLogPath`（而非 `logPath`）

### 5. Debug

**功能**：调试断言和跟踪

**使用方法**：
```cpp
#include <debugger.h>

// 断言
DEBUG_ASSERT(condition, "message");

// 跟踪
DEBUG_TRACE("Function called with param: %d", param);
```

## 最佳实践

### 代码规范

#### C++ 代码

1. **空指针检查**
```cpp
// 使用智能指针
std::unique_ptr<Data> data = std::make_unique<Data>();

// 使用前检查
if (ptr) {
    ptr->method();
}

// 使用引用避免空指针
void process(Data& data);  // 引用不能为 null
```

2. **边界检查**
```cpp
// 使用 at() 而不是 []
vec.at(index);  // at() 会抛出异常

// 手动检查
if (index >= 0 && index < vec.size()) {
    vec[index];
}
```

3. **资源管理**
```cpp
// 使用 RAII
{
    std::lock_guard<std::mutex> lock(mutex_);
    // 自动释放锁
}

// 使用智能指针
std::shared_ptr<Data> data = std::make_shared<Data>();
```

4. **线程安全**
```cpp
// 使用互斥锁
std::mutex mutex_;
int counter_;

void increment() {
    std::lock_guard<std::mutex> lock(mutex_);
    counter_++;
}

// 使用原子操作
std::atomic<int> counter_{0};
counter_.fetch_add(1);
```

#### ArkTS 代码

1. **空值检查**
```typescript
// 使用可选链
let city = user?.address?.city;

// 使用空值合并
let name = user?.name ?? "Unknown";

// 使用类型守卫
if (user && typeof user === 'object') {
    // 安全访问
}
```

2. **类型安全**
```typescript
// 使用接口定义类型
interface User {
    name: string;
    age: number;
}

// 使用类型检查
function process(data: unknown) {
    if (typeof data === 'object' && data !== null) {
        // 安全访问
    }
}
```

3. **异常处理**
```typescript
try {
    await riskyOperation();
} catch (error) {
    console.error('Operation failed:', error);
    // 错误处理
}
```

### 测试规范

1. **单元测试**
```cpp
TEST(DataTest, NullPointer) {
    Data* data = nullptr;
    EXPECT_NO_THROW(process(data));
}
```

2. **压力测试**
```cpp
for (int i = 0; i < 10000; i++) {
    // 并发测试
    std::thread t([&]() {
        counter.increment();
    });
    threads.push_back(std::move(t));
}
```

3. **模糊测试**
```cpp
void fuzzTest(const uint8_t* data, size_t size) {
    // 随机输入测试
    process(data, size);
}
```

### 监控规范

1. **日志监控**
```cpp
// 关键路径添加日志
LOG(INFO) << "Processing started";
LOG(ERROR) << "Failed to process: " << error;
```

2. **性能监控**
```cpp
auto start = std::chrono::high_resolution_clock::now();
process();
auto end = std::chrono::high_resolution_clock::now();
auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
LOG(INFO) << "Process took " << duration.count() << "ms";
```

3. **崩溃上报**
```typescript
// 使用 HiAppEvent 上报
hiAppEvent.write({
    domain: 'com.example.app',
    name: 'CRASH',
    eventType: hiAppEvent.EventType.FAULT,
    params: {
        'crash_type': 'SIGSEGV',
        'timestamp': Date.now()
    }
});
```

## 参考资料

- [HarmonyOS 应用稳定性-C++Crash 场景化最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-scenario-stability-cppcrash)
- [HarmonyOS 应用稳定性-JSCrash 场景化最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-scenario-stability-jscrash)
- [HarmonyOS 应用崩溃信号处理指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines)
- [HarmonyOS 应用崩溃日志分析指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/jscrash-guidelines)