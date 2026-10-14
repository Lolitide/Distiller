# 性能调优-内存分析与优化实践

## 1. 概述

本文面向 HarmonyOS 上 Flutter 应用开发者，给出统一的内存分析方法。内容由以下部分组成：

- [内存基础知识](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-memory-basic-knowledge)（采用 HarmonyOS 官方说明）。
- 工具使用说明（[HiDumper](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hidumper)、[HiProfiler](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiprofiler)、[Flutter DevTools Memory](https://docs.flutter.dev/tools/devtools/memory#memory-view-guide)）。
- 基于 HiDumper 的退后台释放 DMA 实践。

## 2. 内存基础知识

### 2.1 总量指标

HarmonyOS 在[内存基础知识](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-memory-basic-knowledge)中介绍了内存指标之间的关系，并对各指标进行详细说明：

- `VSS`：进程占用的虚拟内存大小。
- `RSS`：当前加载到物理内存的进程内存。
- `PSS`：共享页按比例分摊后的内存大小。
- `USS`：进程私有内存。
- `Swap`：物理内存不足时换出的内存页。

在应用排查中，`PSS` 更准确地反映了多进程环境下的内存使用。。

### 2.2 组成分项

应用内存组成包括：

- 栈（Stack）
- mmap 分配区域
- 共享库（Shared Libraries）
- 堆（Heap）
- Heap Alloc / Heap Free
- ArkTS Heap
- Native Heap
- Anonymous Page other
- FilePage Other
- GL（图形内存）
- BSS/Data/Text/RO Data Segment
- Guard Pages

Flutter 应用仍运行在该系统内存模型之上。分析时先看系统总量与分项，再定位到 Flutter 运行时对象。

## 3. 工具与可观测内存

### 3.1 [HiDumper](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hidumper)

#### 使用方式

```bash
# 1) 查看系统内存
hdc shell "hidumper --mem"

# 2) 查看进程内存, pid为目标应用进程号
hdc shell "hidumper --mem <pid> --show-dmabuf"

# 3) 查询虚拟机堆内存, pid为目标应用进程号
hdc shell "hidumper --mem-jsheap <pid>"
```

#### 主要用于观察

- 进程 `PSS Total`（总量）。
- 进程分项（如 ArkTS Heap、Native Heap、GL、FilePage Other 等）。


HiDumper 适合用于系统侧总量和分项分析，是内存排查的基础工具。

### 3.2 [DevEco Profiler](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiprofiler)

根据 HarmonyOS 文档（[分析内存占用问题](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-analyze-memory-problem)）说明，DevEco Profiler 可用于 Native 内存与内核态内存分析。

#### Native 内存分析

操作步骤：

- 参考文档（[分析native内存](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-analyze-memory-problem)）中的操作步骤

可分析的信息：

- 堆内存分配/释放记录。
- memory mapping 信息。
- 调用栈（支持统计模式与非统计模式）。

文档定义的 Native 内存主要包括：

- `malloc/new/realloc/calloc` 申请的堆内存。
- `mmap` 映射的内存地址空间。

#### 内核态内存分析

操作步骤：

- 参考文档（[分析内核态内存](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-kernel-memory-analysis)）中的操作步骤

文档给出的内存类型说明：

- `FilePage Other`：应用使用的 ashmem 内存。
- `GL`：应用使用的 GPU 内存。
- `Graph`：应用使用的 ION 内存。

### 3.3 [Flutter DevTools Memory](https://docs.flutter.dev/tools/devtools/memory#memory-view-guide)

#### 使用方式

- 参考指导：[Memory view guide](https://docs.flutter.dev/tools/devtools/memory#memory-view-guide)。
- 打开 Flutter DevTools 的 Memory 视图。
- 通过时间线观察内存变化。
- 使用快照、对比与分配跟踪能力定位对象增长。

#### 主要可见指标（Memory 视图）

- `RSS`
- `Allocated`
- `Dart/Flutter`（Heap）
- `Dart/Flutter Native`
- `GC`
- `Raster Cache`

#### 适用范围

Flutter DevTools 主要用于 Dart/Flutter 运行时内存分析（对象、堆、外部内存等）。
进程总量与系统分项建议以 HiDumper / DevEco Profiler 为准。

## 4. 实践：使用 [HiDumper](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hidumper) 验证退后台释放 DMA


以 Flutter 创建的默认应用为例：
```bash
flutter create _newdemo
```
通过hidumper获取进程整体内存情况：
```bash
hdc shell "hidumper --mem \$(pidof com.example.u_newdemo) --show-dmabuf"
```
观察进程内存占用情况发现，在前台和进入后台时，DMA均持有6个Buffer，在后台占用了大量内存，可以考虑退后台回收DMA内存。

下图为进程进入后台的内存情况：

![](../media/performance/performance-20.png) 

通过回收DMA，仅保留1个buffer，在后台节省了5个Buffer的内存占用。

下图为优化后，进程进入后台的内存情况：

![](../media/performance/performance-21.png) 
