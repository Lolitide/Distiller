---
name: ohos-flutter-crash-analyzer
description: Analyze Flutter Engine crashes on HarmonyOS/OHOS, locate source code, and track upstream fixes. Use for (1)HarmonyOS crash stack parsing (2)addr2line source location (3)NAPI crash analysis (4)Mermaid call chain diagrams. Keywords: SIGSEGV,SIGABRT,SIGSYS,SIGXCPU,SIGXFSZ,flt:crash,flt:engine,NAPI crash,libflutter.so,addr2line,native crash analysis,harmonyos crash,ohos crash
trigger: |
  User message contains crash stack trace (with pc addresses, .so file paths)
  Or user mentions crash signals: SIGSEGV/SIGABRT/SIGSYS/SIGXCPU/SIGXFSZ
  Or user mentions: Flutter Engine crash/native crash/libflutter_engine.so/addr2line
  Or user mentions: HarmonyOS crash analysis/OHOS crash/NAPI crash
  Or user asks to analyze crash log/stack trace/崩溃日志/堆栈
  Or user provides crash information with Build fingerprint/pid/tid/signal
---

# Flutter Engine 崩溃分析

## 支持范围说明

| 崩溃类型 | 支持程度 | 说明 |
|---------|---------|------|
| **Native C++ Crash** | ✅ 完全支持 | 深度分析流程、源码定位、社区追踪、修复方案 |
| **JS Crash (ArkTS)** | ⚠️ 基础支持 | 崩溃信号识别、错误类型分类、基础 sourcemap 映射 |
| **混合崩溃 (NAPI ↔ ArkTS)** | ⚠️ 部分支持 | NAPI 参数检查、关联分析要点，不含完整跨语言追踪流程 |

**JS Crash 基础支持内容**：
- ✅ 崩溃信号识别和日志格式解析
- ✅ 常见 ArkTS 运行时错误类型识别
- ✅ 基础 sourcemap 映射指引
- ⚠️ **不包含**：完整的 NAPI ↔ ArkTS 关联分析流程、复杂跨语言崩溃根因追踪

**如需深度 JS Crash 分析**，参考：
- [HarmonyOS 应用稳定性-JSCrash 最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-scenario-stability-jscrash)
- [HarmonyOS 崩溃日志分析指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/jscrash-guidelines)

---

## 崩溃类型识别（第一步必须完成）

**MANDATORY: 遇到崩溃时，先查下表确定分析路径**

| 信号 | fault_addr | 首要怀疑 | 检查顺序 | 参考章节 |
|------|-----------|---------|---------|---------|
| SIGSEGV | 0x0 | 空指针 | ①对象生命周期 ②线程安全 ③初始化顺序 | [空指针分析](references/harmonyos-crash-guide.md#空指针) |
| SIGSEGV | 非0x0 | 野指针/越界 | ①数组边界 ②释放后使用 ③指针运算 | [内存访问分析](references/harmonyos-crash-guide.md#内存越界) |
| SIGABRT | - | 断言失败 | ①前置条件 ②状态一致性 ③并发冲突 | [断言分析](references/harmonyos-crash-guide.md#断言失败) |
| HarmonyOS SIGSYS | - | NAPI调用错误 | **必须**检查NAPI参数类型匹配 | [NAPI问题](references/harmonyos-crash-guide.md#sigsys) |
| HarmonyOS SIGXCPU | - | CPU超限 | 检查死循环/计算密集型任务 | [资源限制](references/harmonyos-crash-guide.md#sigxcpu) |

**HarmonyOS 特定信号**:
- SIGSYS (31): 系统调用参数错误，NAPI层常见
- SIGXCPU (24): CPU时间超限，通常是死循环
- SIGXFSZ (25): 文件大小超限

---

## NEVER Do（专家经验）

### NEVER 假设堆栈完整
- **原因**: 优化编译可能内联函数，堆栈可能只有3-5帧
- **正确做法**: 使用 `addr2line -C -f -e libflutter_engine.so <addr>` 双向验证源码

### NEVER 忽略 HarmonyOS 特定信号
 - **原因**: SIGSYS/SIGXCPU/SIGXFSZ 是 HarmonyOS 特有信号
 - **正确做法**: 遇到这些信号**必须**查阅 [harmonyos-crash-guide.md §HarmonyOS 特定信号](references/harmonyos-crash-guide.md)

### NEVER 在没有符号表时猜测
- **原因**: libflutter_engine.so 地址在不同版本映射完全不同
- **正确做法**: 
  1. 从崩溃日志提取 Engine commit hash
  2. 编译对应版本符号表: `./tools/gn --ohos --arm64 --unoptimized`
  3. 或从官方下载匹配版本

### NEVER 只修复崩溃点而不检查根因
- **原因**: 崩溃点往往是症状，真正问题在调用链上游
- **正确做法**: 生成 Mermaid 调用链图，追踪完整的资源管理和生命周期

### NEVER 应用上游补丁前不验证版本
- **原因**: Flutter Engine commit hash 必须精确匹配
- **正确做法**: 
  1. 崩溃日志中提取 Engine 版本
  2. GitHub 查找对应 commit
  3. 验证补丁适用版本范围

### NEVER 在 HarmonyOS 平台套用其他平台调试经验
- **原因**: NAPI ≠ JNI，ArkTS ≠ JavaScript，线程模型不同
- **正确做法**: 遇到 HarmonyOS 崩溃**必须**先查阅 [HarmonyOS 关键差异](#harmonyos-关键差异)

---

## 重要注意事项（有限适用性）

### ndk-stack 在 HarmonyOS 的适用性限制

> **重要**: 此规则为**有限适用性**而非绝对禁止。ndk-stack 在纯 Native C++ 场景可用，但在 NAPI 混合堆栈场景不可用。

- **限制原因**: ndk-stack 不支持 NAPI 堆栈格式，无法识别 NAPI 调用边界
- **适用范围**: 
  - ✅ 纯 Native C++ 堆栈（无 NAPI 调用）可用
  - ❌ 混合堆栈（Native + NAPI/ArkTS）不可用，NAPI 堆栈帧会被误解析或跳过
- **正确做法**: 
  - 纯 Native 崩溃：可以使用 ndk-stack 批量解析
  - NAPI 相关崩溃：必须使用 addr2line 或 HarmonyOS 专用脚本
  - 无法确定时：优先使用 addr2line 单帧解析验证
- **判断方法**: 崩溃日志含 `napi_`、`ArkTS` 关键字或 SIGSYS 信号 → 不适用

---

## 强制加载触发器

### 场景触发器（立即加载，不等分析步骤）

**遇到以下场景时，立即加载对应参考**:

| 场景识别 | 立即加载章节 | 原因 |
|---------|------------|------|
| SIGSYS 信号出现 | `harmonyos-crash-guide.md` §HarmonyOS 特定信号 | HarmonyOS 特有信号，Agent不知道 |
| NAPI 相关崩溃 | `harmonyos-crash-guide.md` §NAPI ↔ ArkTS 关联分析要点 | NAPI ↔ ArkTS 关联分析要点 Claude不知道 |
| addr2line 返回 `??` | `stack-parsing-guide.md` §常见问题 > Q1 | 符号表不匹配时的处理方案 |
| 模块名不认识 | `engine-architecture.md` §核心模块 对应章节 | Claude 可能不熟悉 Flutter Engine 模块职责 |

### 分析步骤中的 MANDATORY 读取

**第一步：识别崩溃类型**
 - **MANDATORY**: 读取 [`references/harmonyos-crash-guide.md`](references/harmonyos-crash-guide.md) §崩溃信号说明 章节（信号表 + HarmonyOS 特定信号）
 - **Do NOT** 全量读取，按需读取相关章节

**第二步：源码定位**
 - **MANDATORY**: 读取 [`references/stack-parsing-guide.md`](references/stack-parsing-guide.md) §堆栈解析方法 章节（addr2line 使用方法 + ndk-stack 适用性）
 - 当遇到 HarmonyOS 平台问题时：读取 §HarmonyOS 适配 章节

**第三步：模块定位**
 - 当需要理解模块职责时：读取 [`references/engine-architecture.md`](references/engine-architecture.md) §核心模块 对应章节
 - FML 模块：§FML (Flutter Meta Language Library)
 - Shell 模块：§Shell
 - Impeller 模块：§Impeller (新一代渲染引擎)

**第四步：社区追踪**
 - 使用 [`references/search-keywords.md`](references/search-keywords.md) 中的关键词搜索
 - 按崩溃类型选择关键词组合

**Do NOT Load**:
- example 案例（仅在遇到类似问题时参考）
- 完整架构文档（不需要理解整个引擎时）
- report-template.md（Agent知道如何生成报告）

---

## 错误处理与降级方案

### addr2line 返回 `??` 或 `??:0`

**问题**: 符号表版本不匹配或丢失
**表现**: `addr2line` 输出 `??` 或 `??:0`

**降级方案**:
1. **提取版本**: 从崩溃日志查找 `Engine commit hash` 或 `Flutter version`
2. **编译符号表**: 
   ```bash
   ./tools/gn --ohos --arm64 --unoptimized
   ninja -C out/ohos_debug_unopt_arm64
   ```
3. **源码定位**（符号表不可用时）:
   - 使用 `grep` 在源码中搜索崩溃帧的函数名
   - 通过调用链推测崩溃位置
   - 提取关键代码段进行逻辑分析

### GitHub 搜索无相关 Issue/PR

**问题**: 找不到已知修复方案
**表现**: Flutter/Flutter Engine issues 搜索返回空结果

**降级方案**:
1. **扩大关键词**: 使用 [`search-keywords.md`](references/search-keywords.md) 中的组合关键词
2. **社区论坛**: 搜索 Flutter 中文社区、Stack Overflow
3. **本地修复**: 
   - 基于源码分析实现修复
   - 添加防御性代码（空指针检查、边界验证）
   - 提供风险评估和测试方案

### 符号表无法编译或获取

**问题**: 无法获取对应版本的符号表
**原因**: Engine 源码不可用、编译环境缺失、版本过旧

**降级方案**:
1. **官方符号表**: 查找 Flutter 官方预编译符号表（如果有）
2. **函数名定位**: 
   - 从堆栈提取函数名（部分堆栈会显示符号）
   - 使用 `grep` 在任意版本源码中搜索同名函数
   - 分析函数逻辑推测崩溃原因
3. **保守修复**: 
   - 提供更保守的修复方案（防御性代码而非直接修复）
   - 强调需要充分测试验证

### HarmonyOS 堆栈格式不标准

**问题**: 堆栈格式特殊，无法直接解析
**表现**: 堆栈缺少 pc 地址，或地址格式不同

**降级方案**:
1. **格式识别**: 
   - 检查堆栈是否包含 HarmonyOS 特定格式
   - 识别 `FaultLogger` 日志格式
2. **手动解析**: 
   - 从日志提取关键信息（模块名、函数名）
   - 使用 HiLog、HiChecker 等工具补充信息
3. **平台求助**: 
   - 查阅 HarmonyOS 官方文档
   - 使用 HarmonyOS 社区资源

---

## 分析思维模型（三问法）

每个崩溃都要回答：

### WHY 现在崩溃？
- 触发条件是什么？
- 是偶发还是必现？
- 有什么前置操作？

### WHY 在这里崩溃？
- 为什么是这个代码路径？
- 调用链上游做了什么？
- 数据状态是什么？

### WHY 没在别处崩溃？
- 防御机制在哪里？
- 为什么其他路径正常？
- 边界条件是什么？

**思维流程**:
```
崩溃点 → 溯源（谁调用的） → 根因（为什么会到这） → 修复（如何防止）
   ↑                                                           ↓
   └─────────────── 验证假设（能解释所有现象吗？） ←─────────────────┘
```

---

## HarmonyOS 关键差异（必须记住）

| 维度 | HarmonyOS | 说明 |
|------|-----------|------|
| Native API | NAPI | 参数类型检查更严格 |
| 脚本语言 | ArkTS | 运行时与 JavaScript 不同 |
| 崩溃信号 | POSIX标准 + SIGSYS/SIGXCPU/SIGXFSZ | 需查 HarmonyOS 专用文档 |
| 堆栈解析 | addr2line + 自定义脚本 | 工具链特定 |
| 调试工具 | HiChecker/HiLog/FaultLogger | 平台专用工具 |

**HarmonyOS 崩溃日志关键字段**:
```
Build fingerprint: 设备型号+系统版本
pid: 12345, tid: 12346, name: 'thread_name'
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
Cause: [原因描述]
```

---

## 工具使用速查

### addr2line（最常用）
```bash
addr2line -C -f -e libflutter_engine.so 0xa1b234
```

### HarmonyOS 工具
- **HiChecker**: 检测线程、性能、安全问题
- **HiLog**: 日志输出和分析
- **FaultLogger**: 获取崩溃日志
- 详细使用: [harmonyos-crash-guide.md](references/harmonyos-crash-guide.md)

---

## 输出要求（必须包含）

**报告第一行必须给出问题归属结论**：

```markdown
# Flutter Engine 崩溃分析报告

**问题归属**: Engine问题

（后续内容...）
```

**判断标准**：

| 问题归属 | 判断依据 | 示例 |
|---------|---------|------|
| **Engine问题** | • 崩溃发生在Engine内部代码路径<br>• 堆栈全是Engine模块（shell/flow/fml等）<br>• 无应用层直接调用<br>• Engine内部逻辑错误（空指针、内存泄漏、断言失败）<br>• **排除**：应用参数组合导致不变量破坏的情况 | Rasterizer析构崩溃、Pipeline内部断言失败、Engine内存泄漏、Shell线程管理错误 |
| **Engine防御不足** | • API参数都合法但组合导致Engine内部崩溃<br>• Engine缺少边界情况的防御性检查<br>• **可通过调整应用层参数规避**<br>• Engine应增加防御性代码或参数验证 | 合法布局参数组合导致计算崩溃、边界值（infinity/max）导致异常、缺少空值/范围检查 |
| **应用使用问题** | • 崩溃发生在应用层代码<br>• 错误使用Engine API（参数错误、生命周期错误）<br>• 应用层并发访问冲突<br>• 应用层资源管理不当<br>• 应用直接调用的API返回错误后未处理 | 传递nullptr给Engine API、错误的线程调用、未等待Engine初始化完成、传递负值给尺寸参数 |
| **无法确定** | • 堆栈不完整<br>• 信息不足以判断<br>• Engine和应用交互边界崩溃<br>• 需要更多上下文信息 | 堆栈只有2-3帧、缺少关键日志、崩溃在NAPI边界 |

**判断流程（三步验证）**：

```
步骤1: 检查堆栈 → 确定崩溃位置
  ↓
步骤2: 检查API使用 → 单个参数是否合法？
  ↓ (都合法)
步骤3: 参数组合验证 → 能否通过调整应用参数规避？
  ↓ (能规避)          ↓ (不能规避)
Engine防御不足        Engine问题
```

**关键区分点**：

| 区分维度 | Engine问题 | Engine防御不足 | 应用使用问题 |
|---------|-----------|---------------|------------|
| API参数 | 全合法 | 全合法 | 有非法参数 |
| 参数组合 | 无冲突 | 有冲突（但各自合法） | 有冲突（含非法值） |
| 规避方式 | 修复Engine | 应用调整参数 或 Engine增加防御 | 修复应用调用 |
| 上游Issue | 应提交 | 可提交（建议防御性代码） | 不应提交 |

**Engine防御不足的处理建议**：

1. **短期规避**：应用层调整参数组合，避免触发边界情况
2. **长期修复**：向Flutter社区提交Issue，建议Engine增加防御性检查
3. **报告标注**：明确说明"可通过应用层调整规避，建议Engine增加防御"

**示例场景分析**：

```dart
// 场景1: Engine问题（不可规避）
// Engine内部空指针崩溃，与应用参数无关
Rasterizer::Draw(layer_tree)  // layer_tree合法，但Engine内部对象为null
→ 归属：Engine问题

// 场景2: Engine防御不足（可规避）
// 合法参数组合导致崩溃
Container(width: 100, height: double.infinity)  // 两个参数都合法
→ Engine布局计算崩溃（缺少对infinity的防御）
→ 归属：Engine防御不足
→ 规避：应用改用具体数值，或提交Issue让Engine增加检查

// 场景3: 应用使用问题
// 非法参数导致崩溃
Container(width: -10)  // 参数非法（负值）
→ 归属：应用使用问题
```

**必须包含**:

1. **问题归属判断**（报告第一行，明确指出责任方）
2. **崩溃类型判断**（基于信号 + fault_addr）
3. **根因假设**（验证过的）
4. **源码位置**（文件:行号，或函数名）
5. **修复方案**（至少一个）
6. **验证方法**（如何确认修复有效）

**可选**:
- Mermaid 调用链图（复杂崩溃必须）
- 社区 issue/PR 链接（已知问题）
- 代码示例（修复方案涉及代码修改时）
- 错误处理说明（遇到降级方案时）

---

## 参考资源（按需加载）

- [`references/harmonyos-crash-guide.md`](references/harmonyos-crash-guide.md) - HarmonyOS 崩溃信号、日志格式、调试工具（702 行）
- [`references/stack-parsing-guide.md`](references/stack-parsing-guide.md) - addr2line、符号表编译、批量解析脚本（991 行）
- [`references/engine-architecture.md`](references/engine-architecture.md) - Flutter Engine 模块架构（244 行）
- [`references/search-keywords.md`](references/search-keywords.md) - GitHub issue 搜索关键词（417 行）
- [`references/analysis-workflow.md`](references/analysis-workflow.md) - 详细分析流程、检查清单、场景速查（376 行）
- [`references/report-template.md`](references/report-template.md) - 报告模板、Mermaid 图规范、代码示例（261 行）
- [`examples/`](examples/) - 历史崩溃分析案例（1586 行）