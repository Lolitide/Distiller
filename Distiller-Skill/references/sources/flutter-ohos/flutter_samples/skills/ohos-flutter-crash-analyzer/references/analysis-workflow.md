# 分析工作流程与检查清单

## 分析流程概览

当用户提供崩溃信息时，按以下步骤系统分析：

```
输入崩溃信息 → 识别类型 → 定位源码 → 追踪上游 → 输出报告
      ↓              ↓           ↓          ↓          ↓
   完整堆栈      信号+addr    addr2line    GitHub     模板填充
```

---

## 详细步骤

### 第一步：堆栈信息解析

#### 输入要求
- **必须**: 完整的崩溃堆栈
- **可选**: 崩溃发生时的场景描述
- **可选**: 相关日志

#### 解析操作
1. **识别崩溃类型**（SIGSEGV、SIGABRT、ASSERT 等）
   - HarmonyOS: 解析 `fault addr` 和 `Cause` 字段
2. **提取关键堆栈帧**（Top 10-20 frames）
   - Native Crash: 解析 pc（程序计数器）和相对地址
   - JS Crash: 解析文件路径、行号、列号
3. **识别涉及的模块**（fml、shell、flow、impeller、skia 等）
4. **标记源码文件和行号**
5. **提取错误消息和断言信息**
6. **HarmonyOS 特定字段**:
   - Build fingerprint（设备型号、系统版本）
   - pid/tid/thread name（进程线程信息）
   - signal code（具体错误码）
   - HarmonyOS 特定信号（SIGSYS、SIGXCPU、SIGXFSZ）

#### HarmonyOS 堆栈格式示例
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
    #00 pc 0000000000a1b234 /system/lib64/libflutter_engine.so
    #01 pc 00000000009f5678 /system/lib64/libflutter_engine.so
```

---

### 第二步：源码定位

#### 地址提取
从堆栈中提取 pc 值：
```
#00 pc 0000000000a1b234 /system/lib64/libflutter_engine.so
→ 地址：0xa1b234
```

#### 符号表准备
**必须**: 获取带调试信息的 libflutter_engine.so

编译方法：
```bash
# Flutter Engine 编译（HarmonyOS）
./tools/gn --ohos --arm64 --unoptimized
ninja -C out/ohos_debug_unopt_arm64

# 产物路径
out/ohos_debug_unopt_arm64/libflutter_engine.so
```

**关键**: 符号表版本必须与崩溃版本匹配

#### 地址解析
单地址解析：
```bash
addr2line -C -f -e libflutter_engine.so 0xa1b234
# 输出: shell/common/rasterizer.cc:156 (函数名)
```

批量解析：
```bash
# 提取所有地址（跨平台兼容，BSD/grep 和 GNU grep 均支持）
grep -oE 'pc [0-9a-f]+' crash.log | awk '{print "0x"$2}' > addresses.txt

# 批量解析
while read addr; do
  addr2line -C -f -e libflutter_engine.so $addr
done < addresses.txt
```

#### 源码阅读
定位到源码文件后：
1. 使用 `glob` 搜索文件位置
2. 使用 `grep` 搜索关键函数
3. 使用 `read` 阅读源码实现
4. 分析代码逻辑和问题

---

### 第三步：上游社区追踪

#### GitHub 搜索策略

**Flutter Issues**: https://github.com/flutter/flutter/issues  
**Flutter Engine Issues**: https://github.com/flutter/engine/issues  
**Flutter Engine PRs**: https://github.com/flutter/engine/pulls

#### 搜索关键词组合
- 崩溃类型 + 模块名: `SIGSEGV rasterizer`
- 函数名 + 崩溃: `Rasterizer::Draw crash`
- 版本号 + 问题: `flutter 3.15 null pointer`

#### 搜索目标
1. 是否已有相同问题的 Issue
2. 是否已有修复 PR
3. 修复的 commit hash
4. 适用版本范围
5. 相关讨论和解决方案

#### 提取关键信息
- Issue 编号和标题
- 修复 PR 编号
- 修复 commit hash
- Flutter 版本要求
- 补丁内容

---

### 第四步：概念流程图生成

#### 图表类型选择

| 分析维度 | Mermaid 类型 | 用途 |
|---------|-------------|------|
| 调用链 | `graph TD` | 从应用层到崩溃点的调用路径 |
| 数据流 | `graph LR` | 数据如何流转到崩溃点 |
| 线程模型 | `graph TD` | 多线程交互和同步关系 |
| 生命周期 | `stateDiagram` | 对象状态变化和销毁时机 |

#### 绘制要点
1. **崩溃点**: 用红色高亮，特殊形状标记
2. **调用路径**: 主路径用粗线，分支用细线
3. **关键节点**: 崩溃相关的函数/模块
4. **线程标注**: 用颜色区分不同线程

---

### 第五步：修复方案输出

#### 方案优先级
1. **方案一**: 应用上游补丁（推荐，最可靠）
2. **方案二**: 本地修复（可控，需测试）
3. **方案三**: 临时规避（应急，有副作用）

#### 方案一：应用上游补丁
步骤：
1. 从 GitHub PR 获取补丁
2. 验证补丁适用版本
3. 应用到本地 Engine 源码
4. 编译并测试
5. 验证崩溃消失

#### 方案二：本地修复
步骤：
1. 定位问题代码
2. 分析修复策略
3. 编写修复代码
4. 本地测试验证
5. 风险评估

#### 方案三：临时规避
适用场景：
- 无法立即更新 Engine
- 需要快速上线
- 补丁暂未发布

方法：
- 添加防御性代码
- 延迟触发操作
- 限制问题场景

---

## 自动化检查清单

分析完成前必须检查：

### 堆栈解析
- [ ] 崩溃类型是否明确（SIGSEGV/SIGABRT/SIGSYS 等）
- [ ] fault_addr 是否提取（0x0 vs 非0x0）
- [ ] 关键堆栈帧是否提取（Top 10-20）
- [ ] 模块是否识别（fml/shell/flow 等）

### 源码定位
- [ ] 地址是否转换为文件:行号
- [ ] 源码是否阅读分析
- [ ] 函数逻辑是否理解
- [ ] 根因是否明确

### 社区追踪
- [ ] Flutter Issues 是否搜索
- [ ] Flutter Engine Issues 是否搜索
- [ ] 相关 PR 是否查找
- [ ] 补丁版本是否验证

### 报告输出
- [ ] 崩溃类型判断是否说明
- [ ] 根因假设是否验证
- [ ] 源码位置是否明确
- [ ] 修复方案是否提供（至少一个）
- [ ] 验证方法是否说明

### HarmonyOS 特定检查
- [ ] Build fingerprint 是否解析
- [ ] HarmonyOS 特定信号是否识别
- [ ] NAPI 相关是否检查
- [ ] 平台差异是否考虑

---

## 常见崩溃场景速查

### 空指针崩溃（SIGSEGV + fault_addr=0x0）

**分析要点**:
1. 检查指针来源和初始化时机
2. 分析对象生命周期
3. 检查线程安全性
4. 确认资源管理策略

**常见原因**:
- 对象已销毁但仍在使用
- 初始化顺序问题
- 跨线程访问未加锁
- 资源竞争条件

**检查工具**:
- `fml::RefPtr` 是否正确使用
- 对象销毁时机追踪
- 线程同步检查

---

### 内存访问崩溃（SIGSEGV + fault_addr≠0x0）

**分析要点**:
1. 检查内存分配和释放
2. 分析指针运算
3. 检查数组边界
4. 确认内存对齐

**常见原因**:
- 访问已释放内存
- 数组越界访问
- 野指针访问
- 内存对齐问题

**检查工具**:
- 内存追踪工具
- ASAN 检测
- 指针运算分析

---

### 断言失败（SIGABRT）

**分析要点**:
1. 理解断言条件
2. 分析断言触发的条件
3. 检查前置假设
4. 确认数据一致性

**常见原因**:
- 状态不一致
- 条件假设错误
- 数据损坏
- 并发冲突

**检查工具**:
- 断言条件分析
- 前置条件检查
- 状态追踪

---

### 线程相关问题

**分析要点**:
1. 识别涉及的线程
2. 分析同步机制
3. 检查锁的使用
4. 分析任务队列

**常见原因**:
- 死锁
- 竞态条件
- 线程安全违规
- 任务队列溢出

**检查工具**:
- 线程模型图
- 锁依赖分析
- 任务队列检查

---

### NAPI 调用错误（HarmonyOS SIGSYS）

**分析要点**:
1. 检查 NAPI 参数类型
2. 分析参数数量匹配
3. 检查回调函数签名
4. 确认线程上下文

**常见原因**:
- 参数类型不匹配
- 参数数量错误
- 回调函数签名错误
- 跨线程调用未同步

**检查工具**:
- NAPI 类型检查
- 参数验证
- 线程上下文检查

---

## 调试工具清单

### 通用工具
- **addr2line**: 地址转源码位置
- **ndk-stack**: 堆栈批量解析（仅适用于纯 Native C++ 堆栈）
- **gdb**: 调试器（本地调试）

### HarmonyOS 工具
- **HiChecker**: 线程、性能、安全检测
- **HiLog**: 日志输出和分析
- **HiAppEvent**: 应用事件打点
- **FaultLogger**: 崩溃日志获取
- **DevEco Studio**: IDE 调试功能

### Flutter Engine 工具
- **FML logging**: 源码日志追踪
- **--unoptimized**: 编译保留调试信息
- **symbols**: 符号表文件

---

## 验证测试方法

### 修复验证步骤
1. 编译带修复的 Engine
2. 运行原崩溃场景
3. 验证崩溃消失
4. 性能回归测试
5. 边界场景测试

### 测试覆盖
- 原崩溃场景（必须）
- 相似场景（应该）
- 边界条件（建议）
- 性能基准（可选）

### 文档记录
- 崩溃分析过程
- 修复方案选择理由
- 测试结果
- 版本要求