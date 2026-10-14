# Flutter OH 3.35 升级指导

> **文档版本**：1.0.0-draft  
> **适用路径**：3.7(dev) / 3.22.x / 3.27.x → 3.35.x  
> **最后更新**：2026-06-01  
> **目标平台**：OpenHarmony API 12+

Flutter-ohos 是基于 Flutter SDK 的 OpenHarmony 适配版本。本文档供使用 Flutter-ohos 框架开发应用的开发者参考，提供从 **3.7（dev）、3.22.x 或 3.27.x** 版本升级至 **3.35.x** 的完整指导。

> **提示**：Flutter-ohos 为三方框架，与 OpenHarmony 系统无强绑定关系，最低运行要求为 **OpenHarmony API 12+**。

---

## 升级收益概述

升级到 Flutter 3.35 可获得 **12 项 OpenHarmony 特有优化** + 上游 Flutter 3.35 新特性。不同起始版本的开发者将获得不同数量的新增收益。

### 版本差距全景图

Flutter-ohos 各版本对应的分支/标签详情请参考：[Flutter-OH 版本演进规划和分支策略](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)

| 起点 | 跨越版本数 | 累计 Breaking Changes 数 | 迁移难度 |
|------|-----------|----------------------|---------|
| 3.7 → 3.35 | 9 个版本 (3.10/3.13/3.16/3.19/3.22/3.24/3.27/3.29/3.32) | ~45 项 | **高** |
| 3.22 → 3.35 | 4 个版本 (3.24/3.27/3.29/3.32) | ~20 项 | **中** |
| 3.27 → 3.35 | 3 个版本 (3.29/3.32/3.35) | ~16 项 | **中低** |

### 开发者感知维度

| 维度 | 包含优化项 | 开发者感知 | Benchmark 数据 |
|------|-----------|-----------|---------------|
| **更流畅** | Impeller + 脏区渲染 + 遮挡剔除 + LTPO | 帧率更稳、GPU 负载更低 | 光栅化耗时**下降约 13%** |
| **更省电** | LTPO + WebView 后台空跑 + 跳过 GPU 送显 | 减少无效计算，降低功耗 | — |
| **更省内存** | DMA 释放 + VMA 调整 + 预加载减少 | 后台内存大幅降低 | 预加载阶段图形内存减少**约 40+MB** |
| **更快启动** | 渲染管线预加载 + 毕昇编译 | 首帧响应更快 | — |
| **更快加载** | 图片零拷贝 | 多图片场景提速 | 9 宫格图片加载完成耗时**减少 100ms** |

### 各升级路径新增收益

| 优化项 | 3.7→3.35 | 3.22→3.35 | 3.27→3.35 |
|--------|:--------:|:--------:|:--------:|
| Impeller 渲染引擎 | **新增** | 已有 | 已有 |
| 渲染管线预加载 | **新增** | 已有 | 已有 |
| 图片编解码零拷贝 | **新增** | 已有(1.0.5) | 已有 |
| 毕昇编译优化 | **新增** | **新增** | **新增** |
| Impeller 遮挡剔除 | **新增** | 已有(1.0.4) | 已有 |
| Impeller 脏区渲染 | **新增** | 已有 | 已有 |
| 脏区 0 跳过 GPU 送显 | **新增** | **新增** | **新增** |
| WebView 消除后台空跑 | **新增** | **新增** | **新增** |
| LTPO 可变帧率 | **新增** | **新增** | **新增** |
| 退后台释放 DMA | **新增** | **新增** | **新增** |
| VMA 内存块大小调整 | **新增** | **新增** | **新增** |
| 预加载内存减少(~40MB) | **新增** | **新增** | **新增** |

- **3.7→3.35**：全部 12 项均为新增收益
- **3.22→3.35**：5 项已有 + 7 项新增收益
- **3.27→3.35**：6 项已有 + 6 项新增收益

### 12 项优化详细说明

**性能优化类（5 项）**：

| # | 优化项 | 说明 | 来源 |
|---|--------|------|------|
| 1 | Impeller 渲染引擎 | Vulkan 后端替代 OpenGL ES，预编译着色器+优化缓存消除卡顿 | 3.22+ 引入 |
| 2 | 渲染管线预加载 | NativeImage 离屏渲染区，提前预加载 FlutterEngine 避免首帧开销 | 3.22+ 引入 |
| 3 | 图片编解码零拷贝 | 图片解码使用不拷贝内存的系统接口，提升多图片页面加载速度 | 3.22.1-ohos-1.0.5 |
| 4 | 毕昇编译优化 | 毕昇编译器优化 C++ 目标代码运行速度，支持 PGO | 3.22.1-ohos-1.1.1 |
| 5 | Impeller 遮挡剔除 | layer 层级遮挡剔除，纯色 layer 覆盖前面元素时跳过渲染 | 3.22.1-ohos-1.0.4 |

**负载优化类（4 项）**：

| # | 优化项 | 说明 | 来源 |
|---|--------|------|------|
| 6 | Impeller 脏区渲染 | 仅重绘变化区域，使用 VK_KHR_incremental_present | 3.22+ 引入 |
| 7 | 脏区 0 跳过 GPU 送显 | 无重绘需求时跳过渲染，减少不必要的 GPU 工作 | 3.22.1-ohos-1.1.1 |
| 8 | WebView 消除后台空跑 | WebView 不可见时暂停动画/纹理刷新，恢复可见时自动恢复 | 3.22.1-ohos-1.1.1 |
| 9 | LTPO 可变帧率 | 动态帧率控制，避免触摸后无意义拉高至 120 帧，默认开启 | 3.27.5-ohos-1.0.6 |

**内存优化类（3 项）**：

| # | 优化项 | 说明 | 来源 |
|---|--------|------|------|
| 10 | 退后台释放 DMA 内存 | 切后台时调用 TeardownOnScreenContext 释放 DMA 缓存 | 3.22.4-ohos-1.1.3 |
| 11 | VMA 内存块大小调整 | 减小图形内存申请块大小(perferredLargeHeapBlockSize)，降低内存占用 | 3.22.1-ohos-1.1.1 |
| 12 | 预加载阶段内存减少 | 图形 buffer 从 6 个调整为 2 个，减少预加载阶段图形内存约 40+MB | 3.27.4-ohos-1.0.5 |

---

## 1. 升级前准备

> **核心理念**：升级前做好备份、确认当前版本、预检依赖兼容性，是确保平滑升级的关键三步。

### 1.1 确认当前版本与目标版本

在开始升级前，请先确认当前使用的 Flutter-ohos SDK 版本和项目依赖状态。

#### 1.1.1 检查 Flutter SDK 版本

```bash
flutter --version
```

预期输出示例：

```
Flutter 3.27.2-ohos • channel stable
Framework • revision xxxxxxxxxx (2024-12-01)
Engine • revision xxxxxxxxxx
Dart SDK version: 3.6.0
```

#### 1.1.2 检查项目依赖版本

```bash
cd your_project
cat pubspec.yaml | grep -A 5 dependencies
flutter pub outdated
```

> **注意**：`flutter pub outdated` 将列出所有可更新的依赖包，重点关注是否有与 3.35 不兼容的版本冲突。

### 1.2 环境与工具要求

#### 1.2.1 硬性要求

| 组件 | 最低要求 | 说明 |
|-----------------|-------------------|------------|
| **OpenHarmony API** | API 12 | 设备/模拟器必须支持 API 12 及以上 |
| **Flutter-ohos SDK** | 3.7 / 3.22 / 3.27 | 当前已安装的源版本 |
| **Git** | 任意版本 | 用于分支切换或克隆 |

#### 1.2.2 无强版本要求

Flutter-ohos 作为三方框架，与底层工具链**无强绑定关系**。以下工具在合理范围内均可使用：

| 工具 | 版本策略 |
|-----------|---------------------------|
| DevEco Studio | 无最低版本要求，建议使用当前最新稳定版 |
| hvigor | 跟随 DevEco Studio 自动管理 |
| JDK | 无特定版本要求 |
| Node.js/npm | 仅影响 DevEco Studio 插件，无 Flutter 相关约束 |

> **建议**：虽无硬性版本要求，但建议 DevEco Studio 保持较新版本，以获得更好的 hvigor 和 OpenHarmony SDK 支持。

### 1.3 选择升级策略与备份

Flutter-ohos SDK 升级提供**两种本质不同的路径**，备份策略因选择的方式而异。请在备份前确定升级方式。

- **方式一：现有目录切换分支** —— 直接在当前 SDK 目录执行 `git checkout` 切换至 3.35 分支，清理缓存后重新初始化。旧版本不保留（仅 git 历史可回退），回滚需重新下载缓存（约 1~2GB）。
- **方式二：新建目录下载** —— 通过 `git clone` 将 3.35 代码仓下载到独立目录，配置新的 PATH 环境变量。旧版本 SDK **完全保留**，回滚只需切换 PATH 即可即时生效。

> **如何选择**：团队项目少、磁盘空间有限、已统一约定全员同步升级 → **选方式一**。多项目并行试点、各项目升级节奏不一致、对升级风险有顾虑 → **选方式二**。
>
> 两种方式的核心差异、详细操作步骤及回滚方案见 **第 2 章 环境升级**。

#### 1.3.1 项目代码备份（两种方式均需执行）

**强烈建议**在升级前将项目代码提交到版本控制系统（如 Git）：

```bash
cd your_project
git add -A
git commit -m "backup: pre-upgrade to Flutter 3.35"
```

> 项目代码是升级过程中唯一可能被修改的资产，版本控制是回滚的最后一道防线。

#### 1.3.2 方式一的 SDK 备份（切分支前执行）

方式一会直接修改现有 SDK 目录，升级前请确认以下信息已备份：

```bash
cd $FLUTTER_ROOT

# 记录当前分支名
git branch --show-current > ~/flutter_backup_branch.txt

# 记录当前提交哈希（用于精确回滚）
git rev-parse HEAD > ~/flutter_backup_commit.txt

# 查看未提交的本地修改（如有）
git status
```

> **关键提醒**：方式一回滚时需要重新下载 `bin/cache`（约 1~2GB），回滚时间较长。如果对升级风险有顾虑，建议直接选择方式二。

#### 1.3.3 方式二的 SDK 备份（可选）

方式二通过 `git clone` 将 3.35 下载到独立目录，现有 SDK **完全不受影响**，因此无需额外备份。只需确保记得当前 SDK 的路径，以便必要时恢复 PATH：

```bash
# 记录当前 Flutter SDK 路径
echo $FLUTTER_ROOT > ~/flutter_backup_path.txt
```

### 1.4 三方库兼容性预检

升级前，务必确认项目依赖的三方库已适配 3.35 版本。

#### 1.4.1 查阅官方兼容性清单

访问 [Flutter-ohos 三方库验证进度](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md) 查询各插件的适配状态。

#### 1.4.2 检查 pubspec.yaml 中的依赖

```yaml
# pubspec.yaml 示例
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.4.0    # 需确认是否支持 3.35
  video_player: ^2.8.0       # 需确认是否支持 3.35
  dio: ^5.4.0                # 纯 Dart 库，通常天然兼容
```

#### 1.4.3 兼容性检查清单

| 检查项 | 操作 | 状态 |
|-------------------|-------------|-------------|
| 查阅三方库验证进度文档 | 访问上述链接 | ☐ 待检查 |
| 确认平台插件（含原生代码） | 检查是否有 ohos 实现 | ☐ 待检查 |
| 纯 Dart 库 | 通常天然兼容，无需修改 | ☐ 已确认 |
| v1 Embedding 插件 | 3.29 已移除 v1，需升级至 v2 | ☐ 待检查 |
| 自研插件 | 检查是否使用 v1 embedding | ☐ 待检查 |

> **提示**：纯 Dart 包（如 `dio`、`provider`、`bloc`）不涉及平台原生代码，通常在不同 Flutter 版本间天然兼容。

---

## 2. 环境升级

Flutter-ohos SDK 升级提供**两种本质不同的路径**。请根据实际场景选择最合适的方式。

> ⚠️ **重要提醒**：Flutter OH **暂未适配 `flutter upgrade` 命令**，直接执行该命令会因拉取官方 Channel 而破坏 OpenHarmony 适配环境并报错。请务必使用下文所述的 `git clone` / `git checkout` 方式进行版本切换，切勿使用 `flutter upgrade`。

### 2.1 升级方式对比

| 维度 | 方式一：现有目录切换分支 | 方式二：新建目录下载 |
|----------------|-------------|-------------|
| **核心操作** | `git checkout` 切换分支 + 清缓存 | `git clone` 到新目录 + 改 PATH |
| **旧版本留存** | 不保留（git 可回退） | 完全保留 |
| **磁盘占用** | 低（Git 复用对象） | 高（两份 SDK） |
| **PATH 变更** | 无需修改 | 必须修改 |
| **回滚速度** | 慢（需切分支 + 重下缓存） | 快（改 PATH 即可） |
| **适用场景** | 团队统一升级、项目少 | 多项目试点、需长期维护旧版 |

### 2.2 方式一：现有 SDK 目录切换分支

#### 适用场景

- 只有 1~2 个项目，且都愿意同步升级
- 磁盘空间有限，无法容纳两份 SDK
- 团队已统一约定全员同时升级

#### 操作步骤

```bash
# Step 1: 确认当前分支
cd $FLUTTER_ROOT
git branch
git status

# Step 2: 获取远程分支
git fetch origin

# Step 3: 切换目标分支（分支名请替换为实际发布的 3.35 分支）
git checkout 3.35.x-ohos
# 或创建本地跟踪分支
git checkout -b 3.35.x-ohos origin/3.35.x-ohos

# Step 4: 强制清理缓存（关键！）
rm -rf bin/cache

# Step 5: 重新初始化环境
flutter doctor
# 此命令会自动下载 Dart SDK、Engine 产物、flutter_tools 依赖

# Step 6: 验证版本
flutter --version
```

> ⚠️ **警告**：`bin/cache` 包含版本绑定的 Dart SDK 和引擎产物，**必须删除**，残留将导致诡异错误（如 "Wrong full snapshot version"）。

#### 回滚方案

```bash
cd $FLUTTER_ROOT
git checkout dev              # 或 3.27.2-ohos / 3.22.5-ohos
rm -rf bin/cache
flutter doctor                # 重新初始化旧版本环境
```

### 2.3 方式二：新建目录下载 3.35

#### 适用场景

- 有多个项目，希望逐个验证升级
- 需要并行维护新旧版本
- 对升级风险担忧较大，需要随时可回滚

#### 操作步骤

```bash
# Step 1: 克隆新版本到独立目录（分支名请替换为实际发布的 3.35 分支）
git clone -b 3.35.x-ohos \
  https://gitcode.com/CPF-Flutter/flutter_flutter.git \
  ~/flutter_ohos_3.35

# Step 2: 配置环境变量
export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com
export PATH=~/flutter_ohos_3.35/bin:$PATH

# Step 3: 验证路径
which flutter
flutter --version

# Step 4: 初始化环境
flutter doctor
```

#### 多版本共存技巧

通过 Shell alias 快速切换版本：

```bash
# 添加到 ~/.bashrc / ~/.zshrc
alias flutter37='export PATH=/opt/flutter_ohos_dev/bin:$PATH && flutter --version'
alias flutter322='export PATH=/opt/flutter_ohos_322/bin:$PATH && flutter --version'
alias flutter327='export PATH=/opt/flutter_ohos_327/bin:$PATH && flutter --version'
alias flutter335='export PATH=/opt/flutter_ohos_335/bin:$PATH && flutter --version'
```

#### 回滚方案

```bash
# 方式 A：当前终端回滚
export PATH=/opt/flutter_ohos_327/bin:$PATH
flutter --version  # 确认已回退

# 方式 B：删除新版本
rm -rf ~/flutter_ohos_3.35
```

### 2.4 配置 FLUTTER_STORAGE_BASE_URL

无论采用哪种方式，升级后必须配置华为云镜像地址：

```bash
export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com
```

添加到 `~/.bashrc` 或 `~/.zshrc` 实现持久化：

```bash
echo 'export FLUTTER_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com' >> ~/.bashrc
source ~/.bashrc
```

### 2.5 缓存清理与项目重建

无论采用哪种升级方式，以下步骤**必须执行**：

```bash
# 1. 项目级清理（每个项目执行）
cd your_project
flutter clean                 # 删除 build/ 和 .dart_tool/
rm -rf .ohos                  # 删除 ohos 编译产物
flutter pub get               # 重新下载依赖

# 2. SDK 级清理（方式一升级者）
rm -rf $FLUTTER_ROOT/bin/cache

# 3. DevEco Studio 完全重启
# IDE 可能缓存旧 SDK 路径，务必重启
```

### 2.6 验证安装

```bash
flutter --version             # 确认版本为 3.35.x-ohos
flutter doctor                # 确认无错误/警告
flutter devices               # 确认能发现 OpenHarmony 设备
```

编译验证：

```bash
cd your_project
flutter build hap --debug     # 验证 debug 编译
```

---

## 3. 工程配置迁移

> **核心理念**：Flutter 3.35 不仅带来框架层变更，还涉及工程配置文件的更新。请逐项检查以下配置，确保与目标版本兼容。

### 3.1 pubspec.yaml 变更

#### 3.1.1 SDK 约束更新

将 `pubspec.yaml` 中的 Flutter SDK 约束升级至 3.35：

```yaml
# 升级前
environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: ">=3.27.0"

# 升级后
environment:
  sdk: '>=3.9.0 <4.0.0'
  flutter: ">=3.35.0"
```

> **说明**：Dart SDK 版本从 3.6（3.27）升级至 3.9（3.35），请同步更新约束。

#### 3.1.2 依赖版本检查

```bash
flutter pub outdated
```

根据输出，更新存在版本冲突的依赖包。

#### 3.1.3 纯 Dart 包的兼容性

纯 Dart 包（无 `android/`、`ios/`、`ohos/` 目录）通常**天然兼容**：

```yaml
# 通常无需修改
dependencies:
  dio: ^5.4.0
  provider: ^6.1.0
  bloc: ^8.1.0
```

### 3.2 analysis_options.yaml 变更

如果项目使用了自定义的 `analysis_options.yaml`，可能需要更新规则以适配 Dart 3.9：

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
```

### 3.3 Android 配置迁移

#### 3.3.1 abiFilters 默认设置（3.35 Breaking Change）

Flutter 3.35 开始在 Android 构建中默认设置 `abiFilters`。如果项目有自定义配置，请检查冲突：

```gradle
// android/app/build.gradle
android {
    defaultConfig {
        ndk {
            // 3.35 默认设置，如需覆盖请显式声明
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
}
```

> **影响**：大多数 OpenHarmony 开发者不直接修改 Android 配置，此变更通常自动生效。

### 3.4 OpenHarmony 配置迁移

#### 3.4.1 build-profile.json5

检查并更新 `ohos/build-profile.json5`：

```json5
{
  "app": {
    "signingConfigs": [],
    "compileSdkVersion": 12,          // 确保 >= 12
    "compatibleSdkVersion": "5.0.0",
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "buildModeSet": [             // profile 模式必需
          "debug",
          "profile",
          "release"
        ]
      }
    ]
  }
}
```

> **注意**：`buildModeSet` 字段在 profile 模式下编译时必须声明，否则会遇到 `Build mode 'profile' is not declared` 错误。

#### 3.4.2 oh-package.json5

检查依赖包的别名（alias）一致性：

```json5
{
  "dependencies": {
    "@ohos/flutter_ohos": "har/flutter.har",
    "@ohos/flutter_module": "har/flutter_module.har"
  },
  "overrides": {
    "@ohos/flutter_ohos": "har/flutter.har"
  }
}
```

> **兼容性提示**：升级后若 `oh-package.json5` 报错，请检查 alias 是否与 HAR 包内 `name` 字段一致。

#### 3.4.3 module.json5

通常无需修改，但需确认 `deviceTypes` 包含目标设备类型：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["phone", "tablet"]
  }
}
```

## 4. 代码迁移指南

> **核心理念**：代码迁移是升级的核心工作。建议先运行 `dart fix --apply` 自动修复，再手动处理剩余的 Breaking Changes。

### 4.1 自动化迁移：dart fix

```bash
cd your_project
flutter pub get
dart fix --apply          # 自动修复约 60~80% 的简单迁移
flutter analyze           # 查看剩余问题
```

### 4.2 按起始版本分类的迁移清单

#### 从 3.27 → 3.35（跨度最小）

| 优先级 | Breaking Change | 影响范围 | 迁移方式 |
|:------:|----------------|---------|---------|
| 🔴 P0 | v1 Android Embedding 移除（3.29） | 含原生代码的插件 | 手动迁移至 v2 |
| 🔴 P0 | `Radio` 重新设计（3.35） | 所有单选按钮 UI | 替换为 `RadioGroup` |
| 🟡 P1 | `Form` 不再支持 sliver（3.35） | `CustomScrollView` + `Form` | 包 `SliverToBoxAdapter` |
| 🟡 P1 | 主题标准化更新（3.35） | 自定义主题代码 | 按新 API 调整 |
| 🟢 P2 | `DropdownButtonFormField.value` → `initialValue` | 下拉表单 | 重命名参数 |

#### 从 3.22 → 3.35（跨度中等）

在上述基础上，额外关注：

| 优先级 | Breaking Change | 影响范围 | 迁移方式 |
|:------:|----------------|---------|---------|
| 🔴 P0 | Color wide gamut 支持（3.27） | 颜色处理代码 | `.opacity` → `.a` |
| 🔴 P0 | `SystemUiMode` 默认 Edge-to-Edge（3.27） | 全屏/状态栏 | 显式设置模式 |
| 🟡 P1 | `InputDecoration.collapsed` 参数清理 | 输入框样式 | 移除无效参数 |
| 🟢 P2 | `.flutter-plugins` → `.flutter-plugins-dependencies` | CI 脚本 | 更新文件引用 |

#### 从 3.7 → 3.35（跨度最大）

在上述基础上，额外关注：

| 优先级 | Breaking Change | 影响范围 | 迁移方式 |
|:------:|----------------|---------|---------|
| 🔴 P0 | `MaterialState` → `WidgetState`（3.22） | 所有自定义交互组件 | 全局替换 |
| 🔴 P0 | 移除 v3.19 前弃用 API（3.22） | 老旧代码库 | 逐项修复 |
| 🟡 P1 | `PageView.controller` nullable | 使用 PageView 的代码 | 添加 null 检查 |
| 🟡 P1 | `MemoryAllocations` → `FlutterMemoryAllocations` | 内存监控 | 重命名 |
| 🟢 P2 | Deep links flag 变更（3.27） | 深度链接 | 按新 API 调整 |

### 4.3 关键 Breaking Changes 迁移详解

#### 4.3.1 MaterialState → WidgetState（3.22）

**影响**：所有使用 `MaterialState` 的自定义按钮、交互组件。

```dart
// 升级前
MaterialButton(
  style: ButtonStyle(
    backgroundColor: MaterialStateProperty.all(Colors.blue),
  ),
)

// 升级后
MaterialButton(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.all(Colors.blue),  // ← 替换
  ),
)
```

**批量替换命令**：

```bash
grep -rl "MaterialState" lib/ | xargs sed -i 's/MaterialState/WidgetState/g'
```

#### 4.3.2 Color Wide Gamut API 迁移（3.27）

```dart
// 升级前
Color myColor = Colors.red;
double alpha = myColor.opacity;
Color faded = myColor.withOpacity(0.5);

// 升级后
Color myColor = Colors.red;
double alpha = myColor.a;                          // ← .opacity → .a
Color faded = myColor.withValues(alpha: 0.5);      // ← withOpacity() → withValues()
```

#### 4.3.3 v1 Android Embedding 移除（3.29）

**检查方法**：

```bash
grep -r "io.flutter.embedding.android.FlutterActivity" android/
grep -r "PluginRegistry.Registrar" android/
```

**迁移方向**：将 `FlutterActivity` 迁移至 `FlutterFragmentActivity`，将 `PluginRegistry.Registrar` 迁移至 `FlutterPlugin` 接口。

> **OpenHarmony 特别提醒**：部分 ohos 插件可能复用了 Android 的 v1 embedding 代码，升级后需检查插件源码是否已适配 v2。

#### 4.3.4 Radio 重新设计（3.35）

```dart
// 升级前
Radio<int>(
  value: 1,
  groupValue: selectedValue,
  onChanged: (value) => setState(() => selectedValue = value),
)

// 升级后
RadioGroup<int>(
  value: selectedValue,
  onChanged: (value) => setState(() => selectedValue = value),
  child: Radio<int>(value: 1),
)
```

#### 4.3.5 Form Widget 不再支持 Sliver（3.35）

```dart
// 升级前（将报错）
CustomScrollView(
  slivers: [
    Form(child: SliverList(...)),
  ],
)

// 升级后
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(
      child: Form(child: ...),
    ),
  ],
)
```

#### 4.3.6 DropdownButtonFormField 参数重命名（3.35）

```dart
// 升级前
DropdownButtonFormField(
  value: selectedItem,
  onChanged: (value) {},
)

// 升级后
DropdownButtonFormField(
  initialValue: selectedItem,
  onChanged: (value) {},
)
```

#### 4.3.7 主题标准化更新（3.35）

```dart
// 升级前
AppBarTheme(color: Colors.blue)

// 升级后
AppBarTheme(backgroundColor: Colors.blue)
```

### 4.4 迁移后验证

```bash
flutter analyze
flutter format --set-exit-if-changed lib/
flutter test
flutter build hap --debug
flutter build hap --profile
flutter build hap --release
```

---

## 5. 插件与依赖适配

### 5.1 三方库兼容性检查

访问 [Flutter-ohos 三方库验证进度](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md) 查询适配状态。

**快速自检**：

```bash
# 列出所有含平台代码的依赖
flutter pub deps --style tree | grep -E "android|ios|ohos"
```

### 5.2 自研插件升级

#### v1 Android Embedding 迁移至 v2

**v1 代码特征**：

```java
public class MyPlugin implements PluginRegistry.Registrar {
    public static void registerWith(Registrar registrar) { }
}
```

**v2 迁移后**：

```java
public class MyPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) { }
    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) { }
}
```

#### OpenHarmony 插件结构检查

检查自研插件的 ohos 目录结构：

```
my_plugin/
├── lib/
├── ohos/
│   └── src/main/ets/
│       └── MyPlugin.ets
├── pubspec.yaml
```

> 若缺少 `module.json5` 或 `build-profile.json5`，可能导致 `flutter pub get` 报错。

### 5.3 常见插件迁移示例

#### 平台通道（Platform Channel）代码示例

```typescript
// ohos/src/main/ets/MyPlugin.ets
import { MethodChannel } from '@ohos/flutter_ohos';

export default class MyPlugin {
  attachToEngine(binding: FlutterPluginBinding) {
    const channel = new MethodChannel(
      binding.getBinaryMessenger(),
      'my_plugin/channel'
    );
    channel.setMethodCallHandler((call, result) => {
      if (call.method === 'getBatteryLevel') {
        result.success(this.getBatteryLevel());
      } else {
        result.notImplemented();
      }
    });
  }
}
```

### 5.4 依赖冲突解决

```bash
flutter pub get
flutter pub deps --style tree
```

临时解决冲突：

```yaml
dependency_overrides:
  some_plugin: ^2.0.0
```

> **警告**：`dependency_overrides` 仅用于临时调试，长期解决方案是升级主依赖或等待插件作者发布兼容版本。

---

## 6. 构建与验证

### 6.1 三种构建模式验证

#### Debug 模式

```bash
flutter clean
flutter pub get
flutter build hap --debug
```

#### Profile 模式

```bash
flutter build hap --profile
```

> 前置条件：`ohos/build-profile.json5` 已声明 `profile` 模式（参见 3.4.1）。

#### Release 模式

```bash
flutter build hap --release
```

### 6.2 Flutter Module 场景（HAR 构建）

```bash
flutter build har --debug
flutter build har --profile
flutter build har --release
```

**产物位置**：

| 产物 | 路径 |
|-----|------|
| `flutter.har` | `.ohos/har/flutter.har` |
| `flutter_module.har` | `.ohos/har/flutter_module.har` |

### 6.3 冒烟测试清单

| 测试项 | 测试方法 | 通过标准 |
|-------|---------|---------|
| 启动测试 | 冷启动应用 | 首帧在预期时间内渲染完成 |
| 页面导航 | 跳转主要页面 | 无崩溃、无白屏 |
| 列表滚动 | 长列表快速滑动 | 无明显卡顿、掉帧 |
| 图片加载 | 打开图片密集型页面 | 图片正常显示、无 OOM |
| 输入测试 | 文本框输入、软键盘弹出 | 输入正常、键盘不遮挡 |
| 返回手势 | 系统返回/侧滑返回 | 页面正常返回、无异常 |
| 后台恢复 | 压后台后恢复 | 状态恢复正确、不崩溃 |
| WebView | 打开含 WebView 的页面 | 内容正常加载 |

### 6.4 性能回归测试建议

建议在升级前后对比以下指标：

| 指标 | 测试工具 | 测试方法 |
|-----|---------|---------|
| 启动首帧时间 | Systrace / 自定义埋点 | 记录 `onCreate` 到首帧的时间 |
| 平均 FPS | DevTools Performance | 滑动核心页面 30 秒 |
| PSS 内存 | `hidumper` | 启动后 5 分钟采样 |
| 后台内存 | `hidumper` | 退后台 1 分钟后采样 |
| 包体积 | `ls -lh` | 对比 release HAP 大小 |

> **已知性能提升（Benchmark 验证）**：
> - 半屏弹窗图片瀑布流：光栅化耗时下降 **~13%**，帧构建时长持平
> - 9宫格图片页面：页面加载完成耗时减少 **100ms**
> - 3.35 预加载内存优化：图形 Buffer 6→2，节省 **~40MB**

---

## 7. 常见问题与排查

### 7.1 编译错误速查表

| 错误信息 | 可能原因 | 解决方案 |
|---------|---------|---------|
| `Wrong full snapshot version` | `bin/cache` 残留旧版本 | `rm -rf $FLUTTER_ROOT/bin/cache` |
| `The SDK license agreement is not accepted` | OHOS SDK License 未接受 | 执行 `ohsdkmgr` 接受 License |
| `Build mode 'profile' is not declared` | `build-profile.json5` 缺少 `profile` | 添加 `"profile"` 到 `buildModeSet` |
| `Can not found module.json5` | 插件 ohos 目录结构不完整 | 检查插件是否已适配 ohos 平台 |
| `Schema validate failed` (hvigor) | `srcPath` 格式不符合 schema | 检查 `build-profile.json5` 路径配置 |
| `flutter command not found` | PATH 配置错误 | 确认 `flutter` 可执行文件路径在 PATH 中 |

### 7.2 运行时异常排查

| 异常现象 | 可能原因 | 排查步骤 |
|---------|---------|---------|
| 白屏/黑屏 | Impeller 不兼容 / 模拟器限制 | 尝试 `--no-enable-impeller`；确认设备支持 Vulkan |
| 启动崩溃 | Engine 版本不匹配 / cache 残留 | 执行 `flutter clean` + 删除 `bin/cache` |
| 内存溢出 OOM | 图片未释放 / 内存泄漏 | 使用 DevTools Memory 分析；限制 ImageCache 大小 |
| 掉帧严重 | 复杂 Widget 重建 / 未使用 const | 使用 Performance Overlay 定位；添加 `const` 构造函数 |

### 7.3 DevEco Studio 相关问题

| 问题 | 解决方案 |
|-----|---------|
| IDE 无法识别 Flutter SDK | 重启 DevEco Studio；检查 Flutter SDK 路径配置 |
| 模拟器白屏 | 模拟器仅支持 Mac(arm64)，且暂不支持 Vulkan；使用真机测试 |
| `hvigor` 构建失败 | 检查 `~/.npmrc` 配置；确认 hvigor 版本与 DevEco Studio 匹配 |
| 签名失败 | 检查签名配置；debug 版本需开启开发者模式或更换正式签名 |

### 7.4 缓存清理万能公式

```bash
# 1. 项目级清理
flutter clean
rm -rf .ohos

# 2. SDK 级清理（方式一升级者）
rm -rf $FLUTTER_ROOT/bin/cache

# 3. 重新初始化
flutter pub get
flutter build hap --debug
```

### 7.5 回滚方案

#### 方式一升级者回滚

```bash
cd $FLUTTER_ROOT
git checkout dev          # 或 3.27.2-ohos / 3.22.5-ohos
rm -rf bin/cache
flutter doctor
```

#### 方式二升级者回滚

```bash
export PATH=/opt/flutter_ohos_327/bin:$PATH
flutter --version
```

---

## 附录 A：版本映射表

| Flutter-ohos 版本 | Flutter 上游版本 | Dart SDK 版本 | 主要特性 |
|------------------|----------------|--------------|---------|
| 3.7 (dev) | ~3.7 | ~3.3 | 早期适配版本 |
| 3.22.x-ohos | 3.22.x | 3.4 | Impeller 引入、渲染管线预加载 |
| 3.27.x-ohos | 3.27.x | 3.6 | Color Wide Gamut、VMA 内存优化 |
| **3.35.x-ohos** | **3.35.x** | **3.9** | **预加载内存缩减 40MB、优化矩阵最完整** |

---

## 附录 B：Breaking Changes 完整索引

### Released in Flutter 3.35

| Change | 影响代码 | 迁移方式 |
|--------|--------------|-----------|
| Component theme normalization | `AppBarTheme.color` | 使用 `backgroundColor` |
| Deprecate `DropdownButtonFormField.value` | `DropdownButtonFormField` | 替换为 `initialValue` |
| Redesigned `Radio` widget | `Radio`, `RadioListTile` | 使用 `RadioGroup` |
| `Form` no longer supports sliver | `Form` in `CustomScrollView` | 用 `SliverToBoxAdapter` 包裹 |
| Default `abiFilters` in Android | `android/app/build.gradle` | 自动生效 |
| `$FLUTTER_ROOT/version` moved | 读取版本文件的脚本 | 使用 `bin/cache/flutter.version.json` |

### Released in Flutter 3.32

| Change | 影响代码 | 迁移方式 |
|--------|--------------|-----------|
| `.flutter-plugins-dependencies` replaces `.flutter-plugins` | CI 脚本 | 更新文件引用 |
| Localized messages to source | `flutter_gen` 包 | 从 `analysis_options.yaml` 移除 `flutter_gen` |

### Released in Flutter 3.29

| Change | 影响代码 | 迁移方式 |
|--------|--------------|-----------|
| Removal of v1 Android Embedding | 含原生代码的插件 | 迁移至 v2 Embedding |

### Released in Flutter 3.27

| Change | 影响代码 | 迁移方式 |
|--------|--------------|-----------|
| Color wide gamut support | `Color.opacity`, `withOpacity()` | 使用 `.a`, `withValues()` |
| `SystemUiMode` default Edge-to-Edge | 全屏应用 | 显式设置 `SystemUiMode` |

### Released in Flutter 3.22

| Change | 影响代码 | 迁移方式 |
|--------|--------------|-----------|
| `MaterialState` → `WidgetState` | 所有交互组件 | 全局替换 |

---

## 附录 C：参考资源

| 资源 | 链接 |
|-----|------|
| Flutter-ohos 官方仓库 | https://gitcode.com/CPF-Flutter/flutter_flutter |
| Flutter 3.35 Release Notes | https://docs.flutter.dev/release/release-notes/release-notes-3.35.0 |
| Flutter Breaking Changes | https://docs.flutter.dev/release/breaking-changes |
| Flutter-ohos 三方库验证进度 | https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md |
| OHOS 混合开发 Module 文档 | https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/hybrid-development/using-module.md |
| Flutter Engine ohos 分支 | https://gitcode.com/CPF-Flutter/flutter_engine |

---

> **文档结束**
>
> 如有问题，请在 [flutter_flutter Issues](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) 提交反馈。
