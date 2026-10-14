# Flutter OH 开发板运行指南

本文指导如何在 OpenHarmony 开发板（如润和大禹 HH-SCDAYU200，CPU: RK3568）上运行 Flutter OH 工程。当前 Flutter OH 云端产物仅提供 64 位 so 包，而开发板每日构建镜像为 32 位系统包，因此需要使用 32 位 Flutter har 包。由于 Flutter 当前 **不支持 32 位 har 包**，本文内容仅供验证用途；如需在开发板上实际运行，请本地编译 32 位产物。

## 前置条件

- 已完成 [《Flutter OH 开发环境搭建指导》](./flutter-oh-env-setup.md) 中的开发环境配置。
- 已准备 OpenHarmony 开发板（如润和大禹 HH-SCDAYU200 2GB+32GB，CPU: RK3568）及 USB 数据线。
- 开发板已烧录 OpenHarmony 系统镜像（版本 6.0）。

## 环境信息

| 项目 | 版本 / 型号 |
| --- | --- |
| Flutter 版本 | 3.7.12-ohos-1.1.7 |
| 开发板型号 | 润和大禹系列 HH-SCDAYU200 2GB+32GB，CPU: RK3568 |
| 开发板系统镜像版本 | 6.0 |
| 每日构建地址 | [每日构建 | OpenHarmony CI](https://dcp.openharmony.cn/workbench/cicd/dailybuild/dailylist) |

> [!WARNING]
> 当前每日构建的开发板仅有历史版本，目前可刷版本为 **32 位系统包**，因此需要 **32 位的 Flutter har 包**。
>
> 当前文档仅供验证用途，因为 Flutter 目前 **不支持 32 位 har 包**。如果开发者感兴趣，可自行在本地搭建进行编译，参考下方「[自编译 Engine（可选）](#自编译-engine可选)」章节。

---

## 步骤说明

### 第一步：安装 Flutter OH 3.7 版本

- 使用版本：flutter 3.7
- 下载地址：[flutter_flutter 3.7](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/dev)

### 第二步：下载每日构建镜像并烧录 6.0 版本

- 烧录教程详见：[烧录教程](https://blog.csdn.net/dengjin20104042056/article/details/148291131)

### 第三步：修改沙箱文件（可选）

- 如果开发板有 `64 位 lib64`，需要修改沙箱文件（目前烧录的开发板系统没有，不修改也可）。
- 参考文档：[《OpenHarmony 设备运行指导》](./openharmony-device-guide.md)

### 第四步：替换 32 位 so 包

当前 Flutter OH 云端产物 so 包为 **64 位**，如果开发板是 **32 位**，则需要使用 **32 位 so 包**。

**3.7 版本 32 位包**：使用压缩文件中的 **har 包**替换对应路径下的 har 包。

[已编译 har 包](https://gitcode.com/lx123546879/flutter_engine_arm_3_7/tree/3.7.12-ohos-1.0.0/har32)

![已编译 har 包下载页面](../media/rendering-engine/rendering-engine-02.png)

### 第五步：创建 Flutter Demo 并调整配置

使用命令创建一个简单 demo：

```bash
# 1. 创建 Flutter Demo 工程
flutter create <projectName>
```

修改部分配置文件：

![修改配置文件](../media/rendering-engine/rendering-engine-04.png)

将 `HarmonyOS` 字段值改为 `OpenHarmony`：

![修改 HarmonyOS 字段](../media/rendering-engine/rendering-engine-05.png)

编译命令：

```bash
# 1. 编译 hap 包（调试版本）
flutter build hap --debug
```

手动添加 try catch 或注释部分代码（视具体情况而定）：

![添加 try catch](../media/rendering-engine/rendering-engine-06.png)

使用 **DevEco Studio** 工具连接开发板后点击运行。

> [!WARNING]
>
> 当前 Flutter 不支持 32 位 har 包，仅用于验证用途。
> 开发者可自行搭建本地环境编译，参考下方「[自编译 Engine（可选）](#自编译-engine可选)」章节。

---

## 自编译 Engine（可选）

如需在开发板上实际运行 32 位 Flutter 应用，建议直接使用以下 PR，pick 到本地 engine，自行编译本地 32 位产物。

- PR 地址：[flutter 3.7 arm 支持](https://gitcode.com/hezySign/flutter_engine/tree/arm_support_3.7)
- 编译命令：

```bash
# 1. 构建arm架构engine产物
./ohos -t debug --ohos-cpu arm
```

> 3.7 版本直接修改 patch 文件后，需要执行 `gclient sync -f`，然后再编译 engine 产物。

### 主要修改点

1. cflags 和 ldflags 目标架构修改为 arm
2. 修改 arm 判断条件解决报错
3. 新增 patch 文件，用于在同步/构建流程中自动打补丁
4. arm32 交叉构建加了降级兜底逻辑（用空 snapshot 占位），绕开 Dart JIT 字长不匹配问题
5. 增加部分 try catch 解决部分运行报错
6. 增加一些宏进行日志打印兼容，避免因 `int64_t` 格式符差异导致编译警告或失败
7. 增加 gn_args 对 ohos 的处理
8. 具体修改 PR：[flutter_engine 修改 PR](https://gitcode.com/hezySign/flutter_engine/commit/2ac8d8336899ac31594db8a7b5aa4565cdbf9564?ref=arm_support_3.7)