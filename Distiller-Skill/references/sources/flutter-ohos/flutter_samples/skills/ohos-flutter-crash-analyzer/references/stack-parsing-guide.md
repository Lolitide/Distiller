# Flutter Engine 崩溃堆栈解析指南

> **文档职责说明**：本文档专注于**堆栈解析工具链**的使用方法。
> - ✅ 符号表准备、addr2line/ndk-stack/GDB 使用、批量解析脚本、自动化工具
> - ❌ 不包含：崩溃信号分类、日志格式详解、HarmonyOS 平台特有内容
> 
> **相关参考**：
> - 崩溃信号分类、日志格式 → [`harmonyos-crash-guide.md`](harmonyos-crash-guide.md)
> - 崩溃分析完整流程 → [`analysis-workflow.md`](analysis-workflow.md)

本文档详细介绍如何解析 Flutter Engine 的 C++ Crash 堆栈，包括符号表的准备和使用方法。

## 一、崩溃堆栈的获取

### 1.1 从设备获取崩溃日志

#### HarmonyOS 设备

**方法一：使用 hdc 工具**
```bash
# 连接设备
hdc shell

# 查看崩溃日志目录
cd /data/log/faultlog/faultlogger/

# 查找最近的崩溃日志
ls -lt | head -20

# 查看具体崩溃日志
cat cppcrash-xxxxx-20240110112345.log
```

**方法二：使用 FaultLogger API**
```typescript
import faultLogger from '@ohos.faultLogger';

// 查询崩溃日志
async function getCrashLogs() {
  const logs = await faultLogger.query(
    faultLogger.FaultType.CPP_CRASH,
    0,    // startTime
    10    // maxCount
  );
  
  for (const log of logs) {
    console.log('Crash log:', log);
    console.log('Full log path:', log.fullLogPath);  // 官方 API 字段名
  }
}
```

**方法三：从 HiAppEvent 获取**
```typescript
import hiAppEvent from '@ohos.hiAppEvent';

// 监听崩溃事件
hiAppEvent.addWatcher({
  name: 'crashWatcher',
  onEvent: (event) => {
    console.log('Crash event:', event);
    // event 包含崩溃信息
  }
});
```

### 1.2 崩溃日志格式概览

HarmonyOS 崩溃日志格式解析请参考：

> **详细日志格式说明** → [`harmonyos-crash-guide.md`](harmonyos-crash-guide.md) 第 63-131 行
> - HarmonyOS 日志格式详解
> - 关键字段解析（pid/tid、signal/code、fault_addr）
> - Native vs JS 堆栈格式差异

**关键信息提取要点**（快速参考）：

| 字段 | 作用 | 示例 |
|------|------|------|
| `signal` | 崩溃信号类型 | `signal 11 (SIGSEGV)` |
| `fault_addr` | 故障地址 | `0x0` 表示空指针 |
| `Stack Trace` | 崩溃堆栈 | `#00 pc 0xa1b234 libflutter_engine.so` |
| `Build fingerprint` | 设备/系统版本 | 用于版本匹配 |

**堆栈帧格式**：
```
#00 pc 0000000000a1b234  /system/lib64/libflutter_engine.so (flutter::Rasterizer::Draw+234)
#01 pc 00000000009f87e1  /system/lib64/libflutter_engine.so (flutter::Shell::OnEngineBeginFrame+89)
```

解析目标：提取 `pc 地址` + `库名`，用于 addr2line 解析。
- `Stack Trace` 部分包含崩溃堆栈
- `pc` 是程序计数器（相对地址）
- `/system/lib64/libflutter_engine.so` 是崩溃库文件
- 函数名和偏移量（如 `flutter::Rasterizer::Draw+234`）

## 二、符号表（Symbol Table）的准备

### 2.1 什么是符号表？

符号表是一个包含调试信息的特殊版本的库文件（.so），包含：
- 函数名称
- 源代码文件名
- 行号信息
- 变量名称
- 数据结构信息

**无符号表**（release 版本）:
```
#00 pc 0000000000a1b234  /system/lib64/libflutter_engine.so (flutter::Rasterizer::Draw+234)
```

**有符号表**（debug 版本）:
```
#00 pc 0000000000a1b234  /path/to/flutter_engine/out/ohos_debug/libflutter_engine.so
    shell/common/rasterizer.cc:234
    void flutter::Rasterizer::Draw(fml::RefPtr<flutter::LayerTree> layer_tree)
```

### 2.2 如何获取符号表？

#### 方法一：从 Flutter Engine 源码编译

```bash
# 克隆 Flutter Engine 源码
git clone https://github.com/flutter/engine.git
cd engine

# 或者克隆 HarmonyOS 适配版本
git clone https://gitcode.com/CPF-Flutter/flutter_engine.git

# 配置构建环境
./tools/gn --ohos --arm64 --unoptimized

# 编译 Debug 版本（包含符号表）
ninja -C out/ohos_debug_unopt_arm64

# 符号表位置
ls out/ohos_debug_unopt_arm64/libflutter_engine.so
```

**关键参数**:
- `--unoptimized`: 生成未优化版本（包含完整调试信息）
- `--arm64`: 针对 arm64 架构（根据设备 ABI 选择）
- `--ohos`: 针对 HarmonyOS 平台

#### 方法二：从云端下载符号表

可以从云端下载对应版本的符号表文件：

**步骤1：获取 Engine 版本**
```bash
# 在 flutter_flutter 项目中查找使用的 engine 版本
cat flutter/bin/internal/engine.ohos.version
# 输出示例：8ef94277f0029e61ff6a96f630d0f10b60330cd8
```

**步骤2：下载符号表**

根据 commit id 下载对应版本：
- **debug 版本**: `https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/<commit-id>/ohos-arm64/symbols.zip`
- **release 版本**: `https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/<commit-id>/ohos-arm64-release/symbols.zip`
- **profile 版本**: `https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/<commit-id>/ohos-arm64-profile/symbols.zip`

**示例**：
```bash
# 下载 debug 版本符号表
curl -O https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/8ef94277f0029e61ff6a96f630d0f10b60330cd8/ohos-arm64/symbols.zip

# 解压
unzip symbols.zip -d symbols/
```

**符号表位置**：
- debug 版本: `src/out/ohos_debug_unopt_arm64/so.unstripped/libflutter.so`
- release 版本: `src/out/ohos_release_arm64/so.unstripped/libflutter.so`
- profile 版本: `src/out/ohos_profile_arm64/so.unstripped/libflutter.so`

#### 方法三：使用构建产物

如果你的项目构建了 Flutter Engine，符号表通常在：

```
项目目录/
├── out/
│   ├── ohos_debug_unopt_arm64/
│   │   ├── libflutter_engine.so       ← Debug 符号表
│   │   └── libflutter_engine.so.dump  ← 符号信息
│   ├── ohos_release_arm64/
│   │   ├── libflutter_engine.so       ← Release 版本（无符号）
│   │   └── libflutter_engine.so.dump  ← 符号信息（如果有）
│   └── symbols/
│       └── libflutter_engine.so       ← 单独的符号表目录
```

### 2.3 符号表验证

**验证符号表是否包含调试信息**:

```bash
# 使用 file 命令查看
file libflutter_engine.so

# 输出应该包含 "not stripped"
libflutter_engine.so: ELF 64-bit LSB shared object, ARM aarch64, ... not stripped

# 使用 nm 命令查看符号
nm -C libflutter_engine.so | grep Rasterizer

# 使用 readelf 查看调试信息
readelf -S libflutter_engine.so | grep debug

# 应该看到 .debug_* 节
```

### 2.4 符号表管理建议

**目录结构**:
```
symbols/
├── arm64/
│   ├── flutter-3.10.0/
│   │   ├── libflutter_engine.so
│   │   └── libflutter_engine.so.dump
│   ├── flutter-3.13.0/
│   │   ├── libflutter_engine.so
│   │   └── libflutter_engine.so.dump
│   └── current/  ← 当前使用的版本
│       └── libflutter_engine.so
├── arm/
│   └── ...
└── x86_64/
    └── ...
```

**版本管理**:
```bash
# 根据崩溃日志中的版本信息选择符号表
# Build fingerprint 或 Timestamp 可以帮助确定版本

# 创建符号表索引文件
echo "Flutter Engine 3.10.0 OHOS arm64" > symbols/arm64/flutter-3.10.0/version.txt
echo "Build date: 2024-01-15" >> symbols/arm64/flutter-3.10.0/version.txt
```

## 三、堆栈解析方法

### 3.1 使用 addr2line 工具

addr2line 是最常用的堆栈解析工具，可以将相对地址转换为源码位置。

#### 基本用法

```bash
# 单个地址解析
addr2line -C -f -e libflutter_engine.so 0xa1b234

# 输出：
flutter::Rasterizer::Draw(fml::RefPtr<flutter::LayerTree>)
shell/common/rasterizer.cc:234
```

**参数说明**:
- `-C`: 解码 C++ 符号名（将 `_Z7...` 转换为可读的函数名）
- `-f`: 显示函数名
- `-e`: 指定可执行文件或库文件
- `0xa1b234`: 相对地址（从堆栈中的 pc 值获取）

#### 批量解析整个堆栈

```bash
# 从崩溃日志提取地址并批量解析
cat crash.log | grep "pc" | awk '{print $3}' | while read addr; do
  addr2line -C -f -e libflutter_engine.so $addr
done

# 或者使用脚本
#!/bin/bash
CRASH_LOG="crash.log"
SYMBOL_SO="libflutter_engine.so"

grep "pc" $CRASH_LOG | while read line; do
  addr=$(echo $line | awk '{print $3}')
  echo "Address: $addr"
  addr2line -C -f -e $SYMBOL_SO $addr
  echo "---"
done
```

#### HarmonyOS 工具链的 llvm-addr2line

**工具位置**：

在 **DevEco Studio** 和 **Command Line Tools for OpenHarmony** 的 SDK 目录下有这个工具：
- **Windows**: `sdk/default/openharmony/native/llvm/bin/llvm-addr2line.exe`
- **Linux/Mac**: `sdk/default/openharmony/native/llvm/bin/llvm-addr2line`

**配置环境变量**：
```bash
export PATH=/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/llvm/bin:$PATH
```

**使用命令**：
```bash
llvm-addr2line -f -e so.unstripped/libflutter.so [addr1] [addr2]
```

**完整示例**：

假设有如下崩溃日志：
```log
#00 pc 00000000001b5a34 /system/lib/ld-musl-aarch64.so.1(__timedwait_cp+188)
#01 pc 00000000001b7a3c /system/lib/ld-musl-aarch64.so.1(__pthread_cond_timedwait+188)
#02 pc 000000000021d450 /data/storage/el1/bundle/libs/arm64/libflutter.so
#03 pc 00000000001f21f4 /data/storage/el1/bundle/libs/arm64/libflutter.so
```

执行解析命令：
```bash
llvm-addr2line -f -e so.unstripped/libflutter.so 00000000001b5a34 00000000001b7a3c 000000000021d450 00000000001f21f4
```

解析结果：
```log
_ZNSt21_LIBCPP_ABI_NAMESPACE21__libcpp_condvar_waitB6v15004EP14pthread_cond_tP15pthread_mutex_t
/home/hazy/tools/ohos-v5.0.3.900/command-line-tools/sdk/default/openharmony/native/llvm/include/c++/v1/__threading_support:335
_ZN7flutter16PlatformViewOHOS13NotifyChangedERK7SkISize
/home/hazy/work/engine_build/engine_daily/src/out/ohos_release_arm64/../../flutter/shell/platform/ohos/platform_view_ohos.cpp:192
```

**说明**：llvm-addr2line 可以将指令地址转换成文件名、函数名和源代码行数，适用于带有 symbol 信息的 so 库。

### 3.2 使用 ndk-stack 工具

ndk-stack 是一个批量堆栈解析工具，可以一次性解析整个堆栈。

#### HarmonyOS 适用性说明 ⚠️

**重要限制**: ndk-stack 在 HarmonyOS 平台有适用性限制：

| 崩溃类型 | ndk-stack 适用性 | 原因 |
|---------|----------------|------|
| 纯 Native C++ 堆栈 | ✅ 可用 | 纯 C++ 堆栈格式，无 NAPI 调用 |
| NAPI/ArkTS 混合堆栈 | ❌ 不可用 | ndk-stack 不识别 NAPI 堆栈格式，会误解析或跳过帧 |
| 无法确定类型 | ⚠️ 需验证 | 先用 addr2line 单帧解析验证结果 |

**判断方法**:
- 崩溃日志中包含 `napi_`、`ArkTS`、`Hilog` 等 HarmonyOS 特有关键字 → 不适用
- 崩溃堆栈全是 C++ 函数名 → 适用
- SIGSYS 信号（NAPI 参数错误） → 不适用

#### 基本用法

```bash
# 使用 ndk-stack
ndk-stack -sym ./symbols -dump crash.log

# 输出：
********** Crash dump **********
Crash reason: SIGSEGV
Crash address: 0x0
...

Stack trace:
  #00 0x000a1b234: flutter::Rasterizer::Draw(fml::RefPtr<flutter::LayerTree>) (shell/common/rasterizer.cc:234)
  #01 0x0009f87e1: flutter::Shell::OnEngineBeginFrame() (shell/common/shell.cc:567)
  ...
```

**参数说明**:
- `-sym`: 符号表目录路径
- `-dump`: 崩溃日志文件路径

#### 符号表目录结构要求

ndk-stack 要求特定的目录结构：

```
symbols/
└── libflutter_engine.so
```

或者：

```
symbols/
└── arm64-v8a/
    └── libflutter_engine.so
```

#### HarmonyOS 适配

HarmonyOS 暂无官方的 ndk-stack 工具，可以使用类似的脚本：

```bash
#!/bin/bash
# ohos-stack.sh - HarmonyOS 堆栈解析脚本

CRASH_LOG=$1
SYMBOL_DIR=$2

echo "Parsing crash log: $CRASH_LOG"
echo "Using symbols from: $SYMBOL_DIR"

# 提取堆栈信息
grep "Stack Trace:" -A 20 $CRASH_LOG | grep "pc" | while read line; do
  # 解析地址和库名（跨平台兼容，使用 awk 替代 grep -oP）
  addr=$(echo $line | awk '{for(i=1;i<=NF;i++) if($i~/^[0x]?[0-9a-f]+$/ && $i!="pc") print (match($i,/^0x/)?$i:"0x"$i)}' | head -1)
  lib=$(echo $line | awk -F'/' '{print $NF}' | grep -oE '[^/]+\.so')
  
  # 解析地址
  if [ -f "$SYMBOL_DIR/$lib" ]; then
    echo "Original: $line"
    addr2line -C -f -e "$SYMBOL_DIR/$lib" $addr
    echo ""
  else
    echo "Symbol file not found: $lib"
  fi
done
```

使用方法：
```bash
chmod +x ohos-stack.sh
./ohos-stack.sh crash.log ./symbols
```

### 3.3 使用 GDB 调试器

GDB 是强大的调试器，也可以用于解析堆栈。

#### 基本用法

```bash
# 启动 GDB
gdb libflutter_engine.so

# 在 GDB 中解析地址
(gdb) info symbol 0xa1b234
flutter::Rasterizer::Draw(fml::RefPtr<flutter::LayerTree>) + 234 in section .text

(gdb) info line *0xa1b234
Line 234 of "shell/common/rasterizer.cc"

# 批量解析
(gdb) python
crash_addresses = [0xa1b234, 0x9f87e1, 0x9f8650]
for addr in crash_addresses:
    print(gdb.execute(f"info symbol {addr}"))
    print(gdb.execute(f"info line *{addr}"))
end
```

#### 使用 GDB 脚本自动化

```python
# parse_crash.py
import gdb

def parse_crash_stack(crash_file, so_file):
    gdb.execute(f"file {so_file}")
    
    with open(crash_file) as f:
        lines = f.readlines()
    
    for line in lines:
        if "pc" in line:
            addr = line.split()[2]
            try:
                symbol = gdb.execute(f"info symbol {addr}", to_string=True)
                line_info = gdb.execute(f"info line *{addr}", to_string=True)
                print(f"Address: {addr}")
                print(f"Symbol: {symbol}")
                print(f"Line: {line_info}")
                print("---")
            except:
                print(f"Failed to parse: {addr}")

# 在 GDB 中执行
(gdb) source parse_crash.py
(gdb) parse_crash_stack "crash.log" "libflutter_engine.so"
```

### 3.4 使用 IDE

#### DevEco Studio

1. 打开 DevEco Studio
2. 导入 Flutter Engine 项目
3. 配置符号表路径
4. 使用调试功能分析崩溃

#### VS Code

使用 "Native Debug" 扩展：
1. 安装 "Native Debug" 扩展
2. 配置符号表路径
3. 粘贴崩溃堆栈
4. 右键选择 "Parse Stack Trace"

## 四、完整解析流程

### 4.1 步骤一：获取崩溃日志

```bash
# HarmonyOS
hdc shell cat /data/log/faultlog/faultlogger/cppcrash-*.log > crash.log

# 或者从应用日志中提取
hdc shell hilog -t crash > crash.log
```

### 4.2 步骤二：准备符号表

```bash
# 确认崩溃引擎版本
cat crash.log | grep "Build fingerprint"

# 编译对应版本的符号表
cd flutter_engine
./tools/gn --ohos --arm64 --unoptimized
ninja -C out/ohos_debug_unopt_arm64

# 复制符号表到工作目录
cp out/ohos_debug_unopt_arm64/libflutter_engine.so ./symbols/
```

### 4.3 步骤三：解析堆栈

```bash
# 方法一：使用 addr2line 逐个解析
addr2line -C -f -e symbols/libflutter_engine.so 0xa1b234

# 方法二：批量解析脚本
./parse_crash_stack.sh crash.log symbols/

# 方法三：使用自动化工具
# ⚠️ ndk-stack 仅适用于纯 Native C++ 堆栈，不适用于 NAPI 混合堆栈
ndk-stack -sym symbols/ -dump crash.log  # HarmonyOS 需先确认无 NAPI 帧
```

### 4.4 步骤四：分析源码

```bash
# 根据解析结果定位源码
# 例如：shell/common/rasterizer.cc:234

cd flutter_engine
vim shell/common/rasterizer.cc +234

# 或者使用 grep 搜索相关代码
grep -n "Rasterizer::Draw" shell/common/rasterizer.cc
```

## 五、实战示例

### 5.1 示例崩溃日志

```
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
Build fingerprint: 'Huawei/OHOS/Mate60Pro:3.1.0'
ABI: 'arm64'

pid: 12345, tid: 12346, name: '1.raster' >>> com.example.app <<<

signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0

Stack Trace:
  #00 pc 0000000000a1b234  /system/lib64/libflutter_engine.so (flutter::Rasterizer::Draw+234)
  #01 pc 00000000009f87e1  /system/lib64/libflutter_engine.so (flutter::Shell::OnEngineBeginFrame+89)
  #02 pc 00000000009f8650  /system/lib64/libflutter_engine.so (flutter::Engine::BeginFrame+112)
  #03 pc 0000000000b12cde  /system/lib64/libflutter_engine.so (dart::Closure::Call+94)
```

### 5.2 解析步骤

**步骤 1**: 提取地址
```bash
# 地址列表
0xa1b234  # Rasterizer::Draw
0x9f87e1  # Shell::OnEngineBeginFrame
0x9f8650  # Engine::BeginFrame
0xb12cde  # dart::Closure::Call
```

**步骤 2**: 准备符号表
```bash
# 编译 debug 版本
cd flutter_engine
./tools/gn --ohos --arm64 --unoptimized
ninja -C out/ohos_debug_unopt_arm64

# 符号表路径
SYMBOL_SO="out/ohos_debug_unopt_arm64/libflutter_engine.so"
```

**步骤 3**: 解析堆栈
```bash
# Frame #0
addr2line -C -f -e $SYMBOL_SO 0xa1b234
# 输出：
flutter::Rasterizer::Draw(fml::RefPtr<flutter::LayerTree>)
shell/common/rasterizer.cc:234

# Frame #1
addr2line -C -f -e $SYMBOL_SO 0x9f87e1
# 输出：
flutter::Shell::OnEngineBeginFrame()
shell/common/shell.cc:567

# Frame #2
addr2line -C -f -e $SYMBOL_SO 0x9f8650
# 输出：
flutter::Engine::BeginFrame()
shell/common/engine.cc:321

# Frame #3
addr2line -C -f -e $SYMBOL_SO 0xb12cde
# 输出：
dart::Closure::Call()
runtime/dart_isolate.cc:89
```

**步骤 4**: 分析源码
```bash
# 查看崩溃代码
vim shell/common/rasterizer.cc +234

# 分析逻辑
# 行234: auto root_layer = layer_tree->root_layer();
# 发现：root_layer() 返回 null，导致空指针崩溃
```

### 5.3 批量解析脚本

```bash
#!/bin/bash
# batch_parse.sh

CRASH_LOG="crash.log"
SYMBOL_SO="libflutter_engine.so"

echo "Parsing Flutter Engine crash stack..."
echo "Symbol file: $SYMBOL_SO"
echo ""

# 提取并解析所有地址
grep "pc" $CRASH_LOG | grep "libflutter_engine.so" | while read line; do
  frame=$(echo $line | awk '{print $1}')
  addr=$(echo $line | awk '{print $3}')
  
  echo "$frame Address: $addr"
  
  # 解析函数名和源码位置
  result=$(addr2line -C -f -e $SYMBOL_SO $addr)
  func=$(echo "$result" | head -1)
  file_line=$(echo "$result" | tail -1)
  
  echo "  Function: $func"
  echo "  Source: $file_line"
  echo ""
done
```

使用方法：
```bash
chmod +x batch_parse.sh
./batch_parse.sh
```

输出：
```
Parsing Flutter Engine crash stack...
Symbol file: libflutter_engine.so

#00 Address: 0xa1b234
  Function: flutter::Rasterizer::Draw(fml::RefPtr<flutter::LayerTree>)
  Source: shell/common/rasterizer.cc:234

#01 Address: 0x9f87e1
  Function: flutter::Shell::OnEngineBeginFrame()
  Source: shell/common/shell.cc:567

#02 Address: 0x9f8650
  Function: flutter::Engine::BeginFrame()
  Source: shell/common/engine.cc:321

#03 Address: 0xb12cde
  Function: dart::Closure::Call()
  Source: runtime/dart_isolate.cc:89
```

## 六、常见问题

### Q1: addr2line 显示 "??:?"

**原因**: 符号表不包含调试信息（stripped）

**解决**:
```bash
# 检查符号表
file libflutter_engine.so

# 如果显示 "stripped"，需要重新编译 unoptimized 版本
./tools/gn --ohos --unoptimized
ninja -C out/ohos_debug_unopt_arm64
```

### Q2: 地址无法解析

**原因**: 地址可能不正确，或者符号表版本不匹配

**解决**:
```bash
# 确认崩溃日志中的 ABI
grep "ABI:" crash.log

# 使用对应架构的符号表
# arm64 -> 使用 arm64 符号表
# arm -> 使用 arm 符号表

# 确认版本匹配
grep "Build fingerprint" crash.log
```

### Q3: 函数名显示为乱码

**原因**: C++ 符号未解码

**解决**:
```bash
# 使用 -C 参数解码符号
addr2line -C -f -e libflutter_engine.so 0xa1b234

# 不要忘记 -C 参数
```

### Q4: 多个库文件崩溃

**原因**: 崩溃涉及多个库（libflutter_engine.so、libohos_platform.so 等）

**解决**:
```bash
# 分别准备所有相关库的符号表
symbols/
├── libflutter_engine.so
├── libohos_platform.so
├── libskia.so
└── libimpeller.so

# 解析时指定对应的库
addr2line -C -f -e symbols/libflutter_engine.so 0xa1b234
addr2line -C -f -e symbols/libohos_platform.so 0x7b1234
```

### Q5: 如何处理 so.dump 文件？

**说明**: .dump 文件是 Breakpad 符号文件，用于 crashpad 等工具

**用法**:
```bash
# Breakpad 工具链
# 使用 minidump_stackwalk
minidump_stackwalk crash.dmp symbols/

# dump 文件通常与 .so 文件同名但扩展名不同
# libflutter_engine.so.dump
```

## 七、进阶技巧

### 7.1 使用脚本自动化

创建完整的解析脚本：

```bash
#!/bin/bash
# flutter_crash_analyzer.sh

set -e

# 参数
CRASH_LOG=${1:-"crash.log"}
SYMBOL_DIR=${2:-"./symbols"}
OUTPUT_DIR=${3:-"./output"}

# 检查文件
if [ ! -f "$CRASH_LOG" ]; then
  echo "Error: Crash log not found: $CRASH_LOG"
  exit 1
fi

if [ ! -d "$SYMBOL_DIR" ]; then
  echo "Error: Symbol directory not found: $SYMBOL_DIR"
  exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 提取崩溃信息
echo "=== Crash Summary ==="
grep "signal" $CRASH_LOG
grep "Cause" $CRASH_LOG
grep "pid" $CRASH_LOG | head -1

echo ""
echo "=== Parsing Stack Trace ==="

# 解析堆栈
output_file="$OUTPUT_DIR/parsed_stack.txt"
grep "Stack Trace:" -A 20 $CRASH_LOG | grep "pc" | while read line; do
  frame=$(echo $line | awk '{print $1}')
  addr=$(echo $line | awk '{print $3}')
  lib=$(echo $line | awk -F'/' '{print $NF}' | grep -oE '[^/]+\.so')
  
  if [ -f "$SYMBOL_DIR/$lib" ]; then
    result=$(addr2line -C -f -e "$SYMBOL_DIR/$lib" $addr)
    echo "$frame $addr -> $result" | tee -a "$output_file"
  else
    echo "$frame $addr -> [Symbol not found: $lib]" | tee -a "$output_file"
  fi
done

echo ""
echo "Output saved to: $output_file"
echo "Analysis complete!"
```

使用方法：
```bash
chmod +x flutter_crash_analyzer.sh
./flutter_crash_analyzer.sh crash.log ./symbols ./output
```

### 7.2 集成到 CI/CD

在自动化测试中集成崩溃分析：

```yaml
# .github/workflows/crash-analysis.yml
name: Crash Analysis

on:
  issues:
    types: [opened]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Download Symbols
        run: |
          wget https://example.com/flutter_engine_symbols.zip
          unzip flutter_engine_symbols.zip -d symbols/
      
      - name: Parse Crash Log
        run: |
          # 从 Issue 中提取崩溃日志
          ./scripts/flutter_crash_analyzer.sh crash.log symbols/
      
      - name: Create Report
        run: |
          # 生成分析报告
          ./scripts/generate_report.sh
      
      - name: Comment on Issue
        uses: actions/github-script@v5
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('output/report.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: report
            });
```

### 7.3 使用 Python 完整自动化

```python
#!/usr/bin/env python3
# flutter_crash_parser.py

import re
import subprocess
import sys
from pathlib import Path

class FlutterCrashParser:
    def __init__(self, symbol_dir):
        self.symbol_dir = Path(symbol_dir)
    
    def parse_crash_log(self, crash_file):
        """解析崩溃日志文件"""
        with open(crash_file) as f:
            content = f.read()
        
        # 提取基本信息
        crash_info = {
            'signal': self._extract_signal(content),
            'pid_tid': self._extract_pid_tid(content),
            'cause': self._extract_cause(content),
            'stack_trace': self._extract_stack_trace(content)
        }
        
        return crash_info
    
    def _extract_signal(self, content):
        """提取信号信息"""
        match = re.search(r'signal (\d+) \((\w+)\), code (\d+) \((\w+)\), fault addr (0x[0-9a-f]+)', content)
        if match:
            return {
                'number': match.group(1),
                'name': match.group(2),
                'code': match.group(3),
                'code_name': match.group(4),
                'fault_addr': match.group(5)
            }
        return None
    
    def _extract_pid_tid(self, content):
        """提取进程线程信息"""
        match = re.search(r'pid: (\d+), tid: (\d+), name: \'([^\']+)\'', content)
        if match:
            return {
                'pid': match.group(1),
                'tid': match.group(2),
                'thread_name': match.group(3)
            }
        return None
    
    def _extract_cause(self, content):
        """提取崩溃原因"""
        match = re.search(r'Cause: \[Fault cause\]:([^\n]+)', content)
        return match.group(1) if match else None
    
    def _extract_stack_trace(self, content):
        """提取堆栈信息"""
        stack_lines = []
        match = re.search(r'Stack Trace:\s+(.*?)\n\n', content, re.DOTALL)
        if match:
            for line in match.group(1).split('\n'):
                if 'pc' in line:
                    stack_lines.append(self._parse_stack_line(line))
        return stack_lines
    
    def _parse_stack_line(self, line):
        """解析单行堆栈"""
        match = re.search(r'#(\d+) pc ([0x0-9a-f]+)\s+(/\S+\.so)', line)
        if match:
            return {
                'frame': match.group(1),
                'address': match.group(2),
                'library': match.group(3)
            }
        return None
    
    def resolve_address(self, address, library):
        """解析地址到源码位置"""
        so_file = self.symbol_dir / library
        if not so_file.exists():
            return f"Symbol file not found: {library}"
        
        try:
            result = subprocess.run(
                ['addr2line', '-C', '-f', '-e', str(so_file), address],
                capture_output=True,
                text=True,
                check=True
            )
            lines = result.stdout.strip().split('\n')
            return {
                'function': lines[0] if len(lines) > 0 else 'Unknown',
                'source': lines[1] if len(lines) > 1 else 'Unknown'
            }
        except subprocess.CalledProcessError:
            return None
    
    def analyze(self, crash_file):
        """完整分析崩溃"""
        crash_info = self.parse_crash_log(crash_file)
        
        print("=== Crash Summary ===")
        print(f"Signal: {crash_info['signal']['name']} ({crash_info['signal']['number']})")
        print(f"Fault Address: {crash_info['signal']['fault_addr']}")
        print(f"Thread: {crash_info['pid_tid']['thread_name']}")
        print(f"Cause: {crash_info['cause']}")
        print()
        
        print("=== Stack Trace ===")
        for stack_item in crash_info['stack_trace']:
            if stack_item:
                print(f"Frame #{stack_item['frame']}")
                print(f"  Address: {stack_item['address']}")
                print(f"  Library: {stack_item['library']}")
                
                resolved = self.resolve_address(stack_item['address'], stack_item['library'])
                if resolved and isinstance(resolved, dict):
                    print(f"  Function: {resolved['function']}")
                    print(f"  Source: {resolved['source']}")
                else:
                    print(f"  {resolved}")
                print()

def main():
    if len(sys.argv) < 3:
        print("Usage: python flutter_crash_parser.py <crash_log> <symbol_dir>")
        sys.exit(1)
    
    crash_file = sys.argv[1]
    symbol_dir = sys.argv[2]
    
    parser = FlutterCrashParser(symbol_dir)
    parser.analyze(crash_file)

if __name__ == '__main__':
    main()
```

使用方法：
```bash
python3 flutter_crash_parser.py crash.log ./symbols
```

## 八、参考资料

- [Breakpad Symbol Files](https://chromium.googlesource.com/breakpad/breakpad/+/master/docs/symbol_files.md)
- [Flutter Engine Build Instructions](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)
- [HarmonyOS 崩溃日志分析](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines)
- [OpenHarmony Flutter Samples](https://gitcode.com/CPF-Flutter/flutter_samples)