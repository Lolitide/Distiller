# OHOS Flutter Crash Analyzer Skill

## Metadata

| 属性 | 值 |
|------|------|
| **Name** | ohos-flutter-crash-analyzer |
| **Version** | 1.2.0 |
| **Author** | quanhonghui |
| **Created** | 2026-04-10 |
| **Updated** | 2026-06-23 |
| **License** | Apache-2.0 |
| **Status** | Stable |
| **Repository** | [CPF-Flutter/flutter_samples](https://gitcode.com/CPF-Flutter/flutter_samples) |

### Tags

`flutter` `flutter-engine` `crash-analysis` `harmonyos` `ohos` `native-crash` `stack-trace` `debugging` `cpp-crash` `jscrash`

### Platforms

- ✅ HarmonyOS
- ✅ OHOS

### Categories

- Debugging
- Crash Analysis
- Flutter Engine
- Mobile Development

---

## 简介

这是一个专门用于分析 Flutter Engine（特别是鸿蒙平台）崩溃问题的 AI 技能。通过系统化的分析流程，帮助开发者快速定位问题根源、查找上游修复方案，并提供精准的修复建议。

## 功能特性

✅ **堆栈信息解析** - 自动解析崩溃堆栈，提取关键信息（完整支持 Native C++，基础支持 ArkTS JS）  
✅ **源码定位** - 在 Flutter Engine 源码中精确定位问题代码  
✅ **社区追踪** - 自动查找上游 Flutter/Google 社区的相关 issue 和 PR  
✅ **流程可视化** - 用 Mermaid 图展示调用链、数据流、线程模型等  
✅ **精准修复** - 提供详细的修复方案和代码示例  
✅ **HarmonyOS 支持** - 专门针对 HarmonyOS 平台的崩溃分析和调试工具支持  

## 使用方法

### 方式一：直接调用

向 AI 提供崩溃信息，并说明需要使用 crash analyzer skill：

```
分析这个崩溃：
[粘贴崩溃堆栈信息]
```

AI 会自动识别并使用此技能进行分析。

### 方式二：明确指定

明确要求使用此技能：

```
使用 ohos-flutter-crash-analyzer skill 分析以下崩溃：
[崩溃信息]
```

## 输入格式

### 必需信息

1. **崩溃堆栈** - 完整的堆栈信息（至少 Top 10-20 帧）
2. **崩溃类型** - SIGSEGV、SIGABRT 等（如果能从堆栈中识别）
3. **环境信息** - Flutter 版本、Engine 版本、平台等

### 可选信息

1. **场景描述** - 崩溃发生时的操作场景
2. **相关日志** - 崩溃前后的日志
3. **复现步骤** - 如何复现崩溃
4. **设备信息** - 设备型号、操作系统版本

### 示例输入

```
崩溃分析请求：

崩溃类型：SIGSEGV

堆栈信息：
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 12345, tid: 12346, name: '1.raster'
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0

Backtrace:
#00 pc 0000000000a1b234 /lib/libflutter_engine.so (flutter::Rasterizer::Draw+234)
#01 pc 00000000009f87e1 /lib/libflutter_engine.so (flutter::Shell::OnEngineBeginFrame+89)
...

环境信息：
- Flutter: 3.10.0
- Engine: 3.10.0
- Platform: OHOS 3.1
- Device: Huawei Mate 60 Pro

场景：
在页面切换时偶现崩溃
```

## 输出格式

技能会生成详细的分析报告，包含以下部分：

### 1. 崩溃概述
- 崩溃类型
- 涉及模块
- 影响范围
- 严重程度

### 2. 堆栈分析
- 完整堆栈信息
- 关键堆栈帧解读
- 错误消息分析

### 3. 源码分析
- 问题代码定位
- 代码逻辑分析
- 根本原因分析

### 4. 社区追踪结果
- 相关 Issues
- 相关 PRs
- 上游修复状态
- 版本要求

### 5. 概念流程图
使用 Mermaid 生成：
- 调用链图
- 数据流图
- 线程模型图
- 生命周期图

### 6. 修复方案

**方案一：应用上游补丁（推荐）**
- 补丁来源
- 适用版本
- 具体步骤
- 验证方法

**方案二：本地修复**
- 修改位置
- 代码示例
- 测试方案
- 风险评估

**方案三：临时规避**
- 规避方法
- 适用场景
- 副作用说明

### 7. 预防措施
- 代码规范建议
- 测试覆盖建议
- 监控告警建议

## 技能能力

### 支持的崩溃类型

- ✅ 空指针崩溃 (SIGSEGV - Null Pointer)
- ✅ 内存访问崩溃 (SIGSEGV - Memory Access)
- ✅ 断言失败 (SIGABRT - Assertion Failed)
- ✅ 线程相关问题 (Race Condition, Deadlock)
- ✅ 资源泄漏 (Memory Leak, Resource Leak)
- ✅ 初始化问题 (Initialization Failure)

### 堆栈解析工具

本技能集成以下堆栈解析工具：

#### addr2line 工具
- **用途**: 将崩溃堆栈中的地址转换为源码位置
- **用法**: `addr2line -C -f -e libflutter_engine.so 0xa1b234`
- **输出**: 函数名、源文件、行号
- **优势**: 简单快速，适合单个地址解析

#### ndk-stack 工具
- **用途**: 批量解析整个崩溃堆栈
- **用法**: `ndk-stack -sym ./symbols -dump crash.log`
- **输出**: 完整的堆栈信息，包含所有帧的源码位置
- **优势**: 自动化批量解析，适合完整崩溃分析

#### 批量解析脚本
- **用途**: 自动化处理崩溃日志，批量解析所有地址
- **用法**: `./batch_parse.sh crash.log libflutter_engine.so`
- **输出**: 格式化的解析结果，易于阅读和分析
- **优势**: 可定制，支持多库解析

**详细使用方法**：[堆栈解析指南](references/stack-parsing-guide.md)

### 符号表管理

**符号表（Symbol Table）说明**:
- 包含调试信息的特殊 .so 文件
- 记录函数名、源文件、行号等调试信息
- 必须与崩溃版本匹配才能正确解析

**符号表准备流程**:
```bash
# 1. 编译 Flutter Engine Debug 版本
cd flutter_engine
./tools/gn --ohos --arm64 --unoptimized
ninja -C out/ohos_debug_unopt_arm64

# 2. 获取符号表
cp out/ohos_debug_unopt_arm64/libflutter_engine.so ./symbols/

# 3. 验证符号表
file libflutter_engine.so  # 应显示 "not stripped"
nm -C libflutter_engine.so | grep Rasterizer  # 应显示函数符号
```

**符号表要求**:
- ✅ 使用 `--unoptimized` 参数编译
- ✅ 与崩溃版本号匹配
- ✅ 与崩溃 ABI（arm64/arm）匹配
- ✅ 包含调试信息（未 stripped）

### 支持的模块

- ✅ FML (Foundation Library)
- ✅ Shell (Engine Coordinator)
- ✅ Flow (Compositor)
- ✅ Display List
- ✅ Impeller (New Renderer)
- ✅ Runtime (Dart VM)
- ✅ Platform Embedder (HarmonyOS/OHOS)

### 支持的平台

- ✅ HarmonyOS - **重点支持**
- ✅ OHOS

### HarmonyOS 平台特性

本技能针对 HarmonyOS 平台提供了专门的支持：

#### 崩溃日志格式解析

HarmonyOS 崩溃日志包含特定字段：
- **Build fingerprint** - 设备型号和系统版本
- **pid/tid/thread name** - 进程线程信息
- **signal/code/fault addr** - 崩溃信号和故障地址
- **Cause** - 崩溃原因描述
- **Registers** - 寄存器状态（如 x0 寄存器）
- **Stack Trace** - Native 或 JS 堆栈

#### 崩溃类型支持

支持 HarmonyOS 特有的崩溃类型：
- **Native Crash (C++ Crash)** - ✅ 完整支持：深度分析流程、源码定位、社区追踪
- **JS Crash (ArkTS Crash)** - ⚠️ 基础支持：崩溃识别、错误类型分类、基础 sourcemap 映射（详见 [SKILL.md 支持范围说明](./SKILL.md#支持范围说明))

#### 调试工具集成

支持 HarmonyOS 特定调试工具：
- **HiChecker** - 线程安全、性能、安全检测
- **HiLog** - HarmonyOS 日志系统
- **HiAppEvent** - 应用事件打点和上报
- **FaultLogger** - 崩溃日志查询
- **addr2line/ndk-stack** - Native 堆栈地址解析

#### NAPI 特性

HarmonyOS 使用 NAPI（Native API）进行 ArkTS 与 C++ 之间的交互：
- 对象生命周期管理机制特殊
- 跨语言边界（ArkTS -> C++）转换需要特别处理
- 需要正确管理 NAPI 引用（napi_ref）

#### 官方文档参考

集成华为开发者官方文档：
- [HarmonyOS 应用稳定性-C++Crash 最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-scenario-stability-cppcrash)
- [HarmonyOS 应用稳定性-JSCrash 最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-scenario-stability-jscrash)
- [HarmonyOS 崩溃信号处理指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines)
- [HarmonyOS 崩溃日志分析指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/jscrash-guidelines)

详细指南：[HarmonyOS 崩溃分析指南](references/harmonyos-crash-guide.md)

示例案例：[HarmonyOS 平台崩溃分析示例](examples/example-harmonyos-crash.md)

## 目录结构

```
ohos-flutter-crash-analyzer/
├── SKILL.md                      # 技能主文档（包含 YAML metadata）
├── README.md                     # 本文件（使用说明）
├── metadata.json                 # 结构化元数据文件 ⭐
├── references/                   # 参考资源
│   ├── engine-architecture.md    # Flutter Engine 架构说明
│   ├── search-keywords.md        # 崩溃搜索关键词
│   ├── harmonyos-crash-guide.md  # HarmonyOS 崩溃分析指南
│   └── stack-parsing-guide.md    # Flutter 堆栈解析指南
└── examples/                     # 分析案例
    ├── example-sigsegv-analysis.md      # SIGSEGV 分析示例
    └── example-harmonyos-crash.md       # HarmonyOS 平台崩溃示例
```

## 依赖要求

### 必需

- Flutter Engine 源码仓库
- Git（用于搜索上游 PR）
- 基础的 C++ 知识
- 基础的 Flutter 架构知识

### 可选

- GDB/LLDB 调试器（用于深入调试）
- Chrome DevTools（用于性能分析）

## 最佳实践

### 提供高质量输入

1. **完整的堆栈信息**
   - 至少包含 Top 10-20 帧
   - 包含寄存器信息
   - 包含内存映射信息

2. **准确的环境信息**
   - 明确的 Flutter 版本
   - 明确的 Engine 版本
   - 明确的平台和设备

3. **清晰的问题描述**
   - 复现步骤
   - 发生频率
   - 影响范围

### 充分利用输出

1. **优先考虑推荐方案**
   - 上游补丁通常是最佳选择
   - 本地修复次之
   - 临时规避仅作应急

2. **理解根本原因**
   - 阅读源码分析部分
   - 参考流程图理解调用链
   - 学习相关概念

3. **实施预防措施**
   - 根据建议改进代码
   - 增加测试覆盖
   - 部署监控告警

## 版本历史

- **v1.0.0** (2026-04-10)
  - 初始版本发布
  - 支持 Flutter Engine 崩溃分析
  - 支持 HarmonyOS 平台特性分析
  - 集成 addr2line 和 ndk-stack 堆栈解析工具
  - 支持上游社区 Issue 和 PR 追踪
  - 生成 Mermaid 流程图
  - 提供多层次修复方案

- **v1.1.0** (2026-05-15)
  - 新增 JS Crash (ArkTS) 基础支持
  - 添加支持范围说明（完整支持 Native C++，基础支持 ArkTS JS）
  - 新增 ArkTS 运行时错误类型表
  - 新增 NAPI ↔ ArkTS 关联分析要点
  - 补充 JS 堆栈 sourcemap 映射流程

- **v1.2.0** (2026-06-23)
  - 优化文档职责划分（harmonyos-crash-guide.md vs stack-parsing-guide.md）
  - 消除重复内容，使用交叉引用替代
  - 修正责任归属判断逻辑漏洞（新增 Engine防御不足类别 + 三步验证流程）
  - 修正 ndk-stack 适用性说明（从绝对禁止改为有限适用）
  - 优化示例文档说明（虚构链接改为占位符）
  - 优化防御性处理说明（明确区分防御性代码与根因修复）

## 许可证

本技能基于 Flutter Engine 源码和社区最佳实践整理，遵循 Apache 2.0 许可证。