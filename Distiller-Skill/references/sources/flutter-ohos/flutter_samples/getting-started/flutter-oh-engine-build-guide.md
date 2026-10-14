# Flutter OH Engine 构建指导

本指导介绍如何构建支持 OpenHarmony 设备的 Flutter Engine 产物。面向有自定义 Engine 修改需求的开发者。如仅需使用 Engine 产物构建应用，可直接执行 `flutter build hap`，云端会自动拉取 Engine 产物，无需自行编译。

## 构建环境要求

### 1.1 操作系统支持

| 操作系统 | 支持范围 |
|----------|----------|
| Linux | 完整支持 Engine 构建 |
| macOS | 完整支持 Engine 构建 |
| Windows | 仅支持构建 `gen_snapshot` |

### 1.2 前置条件检查清单

在开始构建前，请确认以下环境已就绪：

| 环境项 | 版本/要求 | 验证命令 |
|--------|-----------|----------|
| JDK | 17及以上 | `java -version` |
| Python | 3.8 – 3.11（3.12 存在兼容问题） | `python3 --version` |
| Node.js | v14.19.1 及以上，且低于 v17.0.0 | `node -v` |
| DevEco Studio | 5.0.3.300 及以上 | — |
| Xcode | 14.3 及以上（仅 macOS） | `xcodebuild -version` |
| 磁盘空间 | 建议预留 50GB+ | `df -h` |

### 1.3 网络要求

构建过程需访问 `DEPS_ohos` 配置文件中 `allowed_hosts` 字段列出的全部 URL：

```text
boringssl.googlesource.com
chrome-infra-packages.appspot.com
chromium.googlesource.com
dart.googlesource.com
flutter.googlesource.com
llvm.googlesource.com
skia.googlesource.com
swiftshader.googlesource.com
gitcode.com/openharmony-sig
```

> 如部分域名无法访问，需配置网络代理后重试。

---

### 第一步：搭建 Engine 构建环境

### 2.1 安装 depot_tools

`depot_tools` 提供 `gclient` 与 `gn` 构建工具：

```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

将 `depot_tools` 添加到 `PATH` 环境变量（编辑 `~/.zshrc` 或 `~/.bashrc`）：

```bash
export PATH=$HOME/depot_tools:$PATH
```

```bash
source ~/.zshrc   # 或 source ~/.bashrc
```

### 2.2 安装基础依赖

**macOS（Homebrew）：**

```bash
brew install git curl unzip
brew install python3   # 需为 3.8–3.11，3.12 存在兼容问题
brew install pkg-config ninja
```

**Linux：**

```bash
sudo apt install git curl unzip
sudo apt install python3   # 需为 3.8–3.11，3.12 存在兼容问题
sudo apt install pkg-config ninja-build
```

### 2.3 配置 Engine 构建环境变量

在 [开发环境搭建](./flutter-oh-env-setup.md#配置环境变量) 的基础上，确认以下环境变量已正确配置（以下为 macOS 示例，Linux 请将 `TOOL_HOME` 改为实际安装路径）：

```bash
# JDK
export JAVA_HOME=<JAVA_HOME path>
export PATH=$JAVA_HOME/bin:$PATH

# DevEco Studio 工具链（含 ohpm、hvigor、node、OpenHarmony SDK）
export TOOL_HOME=/Applications/DevEco-Studio.app/Contents
export DEVECO_SDK_HOME=$TOOL_HOME/sdk
export PATH=$TOOL_HOME/tools/ohpm/bin:$PATH
export PATH=$TOOL_HOME/tools/hvigor/bin:$PATH
export PATH=$TOOL_HOME/tools/node/bin:$PATH
```

---

### 第二步：获取与同步 Engine 源码

### 3.1 配置 .gclient 文件

`flutter_flutter` 仓库内置了 `.gclient` 模板文件（`engine/scripts/ohos.gclient`），可直接使用：

1. 进入已克隆的 `flutter_flutter` 源码目录：

   ```bash
   cd flutter_flutter
   ```

2. 将模板文件复制为 `.gclient`：

   ```bash
   cp engine/scripts/ohos.gclient .gclient
   ```

   `.gclient` 文件内容如下：

   ```python
   solutions = [
     {
       "custom_deps": {},
       "deps_file": "DEPS_ohos",
       "managed": False,
       "name": ".",
       "safesync_url": "",
       "url": "https://gitcode.com/openharmony-tpc/flutter_flutter.git",
     },
   ]
   ```

> 如使用 SSH 方式连接 GitCode，可将 `url` 改为 `git@gitcode.com:openharmony-tpc/flutter_flutter.git`。

### 3.2 执行 gclient sync

在 `.gclient` 所在目录执行以下命令同步源码：

```bash
gclient sync
```

此命令会同步 Engine 源码、官方 packages 仓，并执行 `ohos_setup` 钩子任务（将构建脚本 `ohos` 等文件复制到源码根目录）。

> [!WARNING]
>
> - 同步过程需要访问 `allowed_hosts` 中列出的全部 URL，如遇部分域名无法访问，需配置网络代理。
> - 同步时间较长（约 30–60 分钟，视网络情况而定）。
> - 如遇超时错误，请重新执行 `gclient sync`。
> - 同步成功完成后，终端会自动退出。

---

### 第三步：构建 Engine

### 4.1 执行构建

代码同步完成后，构建脚本 `ohos` 已自动复制到源码根目录。在该目录执行构建命令：

```bash
# 1) 查看帮助
./ohos -h

# 2) 构建所有模式（debug + profile + release，默认行为）
./ohos

# 3) 仅构建指定模式
./ohos -t debug      # 调试模式
./ohos -t profile    # 性能分析模式
./ohos -t release    # 发布模式
```

### 4.2 构建产物

构建产物位于 `src/out/` 目录下。目录命名规则为 `ohos_{mode}{_unopt}_{cpu}`，其中 debug 模式额外添加 `_unopt` 后缀：

| 构建模式 | Target Engine 产物目录 | Host Engine 产物目录 |
|---------|----------------------|---------------------|
| **debug** | `src/out/ohos_debug_unopt_arm64/` | `src/out/host_debug_unopt/` |
| **profile** | `src/out/ohos_profile_arm64/` | `src/out/host_profile/` |
| **release** | `src/out/ohos_release_arm64/` | `src/out/host_release/` |

> 如通过 `--ohos-cpu` 指定了非 `arm64` 的架构，或通过 `--host-cpu` 指定了 `arm64`，产物目录名会相应变化。请以 `src/out/` 目录下实际生成的文件夹为准。

验证构建产物：

```bash
# 1) 验证构建产物（应包含 libflutter.so、flutter.har 等文件）
ls -la src/out/ohos_release_arm64/
```

### 4.3 更新代码

如需拉取最新代码后重新构建，分两步执行：

```bash
# 1) 更新 Engine 源码到指定分支（不执行构建）
./ohos -b master

# 2) 重新构建
./ohos -t release
```

---

### 第四步：使用本地 Engine 构建应用

自 3.22.0 版本起，Engine 编译会同时生成 `local-engine`（目标平台）和 `local-host-engine`（主机平台）。使用本地 Engine 构建应用时，需同时指定这两个产物：

```bash
flutter build hap \
  --target-platform ohos-arm64 \
  --release \
  --local-engine=ohos_release_arm64 \
  --local-engine-host=host_release
```

**参数说明：**

| 参数 | 说明 |
|------|------|
| `--target-platform` | 目标平台：`ohos-arm64` |
| `--release` | 构建模式：`--debug`、`--profile` 或 `--release` |
| `--local-engine` | Engine 构建产物路径 |
| `--local-engine-host` | Host Engine 构建产物路径 |

各构建模式对应的产物名称：

| 构建模式 | `--local-engine` | `--local-engine-host` |
|---------|------------------|----------------------|
| **debug** | `ohos_debug_unopt_arm64` | `host_debug_unopt` |
| **profile** | `ohos_profile_arm64` | `host_profile` |
| **release** | `ohos_release_arm64` | `host_release` |

**示例：**

```bash
# 假设 engine 目录在 ~/engine
flutter build hap \
  --target-platform ohos-arm64 \
  --release \
  --local-engine=ohos_release_arm64 \
  --local-engine-host=host_release
```

---

### 第五步：构建 Embedding 层 HAR 产物

Engine 构建完成后，`flutter.har` 位于 `src/out/<output_dir>/flutter.har` 目录下。如需单独构建或重建 HAR 产物，可使用 `ohos` 脚本的 `har` 步骤：

```bash
# 1) 构建 release 模式的 flutter.har
./ohos -t release -n har

# 2) 使用未裁剪的 so 构建（含调试符号）
./ohos -t release -n har --har-unstripped
```

---

## 常见问题

### gclient sync 失败如何排查？

| 现象 | 解决方案 |
|------|----------|
| 连接超时 | 检查网络代理是否正常，确保可访问 `allowed_hosts` 中的 URL，重新执行 `gclient sync` |
| 权限错误 | 确保对源码目录有读写权限 |
| 依赖下载失败 | 检查是否能访问 `allowed_hosts` 中的 URL，必要时配置网络代理 |
| Python 相关报错 | 确认 Python 版本为 3.8–3.11，3.12 版本存在兼容问题 |
| Windows 下 `A required privilege is not held by the client` | 设置 → 开发者选项 → 开启「开发人员模式」 |

### 构建脚本报错如何处理？

| 现象 | 解决方案 |
|------|----------|
| `Permission denied` | 执行 `chmod +x ohos` 添加执行权限 |
| `Member notfound:'isOhos'` | 确保已应用 Dart 补丁（补丁位于 `src/flutter/attachment/repos`，使用 `git apply` 应用后重新编译） |
| 修改 Embedding 层代码后构建未生效 | 修改任意 C++ 文件的时间戳（如添加空格后保存再删除），触发编译系统重新识别后重新构建 |

### Dart VM Snapshot Hash 不一致怎么办？

不同操作系统对换行符处理方式不同，可能导致 Dart VM Snapshot Hash 不一致。检查方法：

```bash
# 1) 获取当前 Dart VM Snapshot Hash
python3 src/third_party/dart/tools/make_version.py --format='{{SNAPSHOT_HASH}}'
```

如获取到的值不是预期值，需检查 `src/third_party/dart/runtime/vm/dart.cc` 和 `src/third_party/dart/runtime/vm/image_snapshot.cc` 文件中所有行是否以 LF 换行符结尾（Windows 可使用 Notepad++ 查看）。
