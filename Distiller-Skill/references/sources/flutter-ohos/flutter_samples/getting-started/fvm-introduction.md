# FVM (Flutter Version Management) 使用指导

FVM（Flutter Version Management）用于在同一台开发机上管理多个 Flutter SDK 版本，可为每个项目锁定一个 Flutter OH 分支或 tag，也可同时安装并切换官方 Flutter SDK 版本（如 `stable`、`3.24.0`），互不影响，且无需将 `flutter_flutter/bin` 加入系统 `PATH`。本文以端到端流程介绍如何用 FVM 安装、绑定并运行 Flutter OH 版本，以及如何在项目内切换到官方社区 Flutter SDK。

## 前置条件

- 安装 Git
- 已完成 [Flutter OH 开发环境搭建](./flutter-oh-env-setup.md)

## 安装 FVM

FVM 提供多种安装方式，按平台选择其一即可。各方式的平台支持与依赖项如下：

| 方式 | 平台 | 依赖项 |
| --- | --- | --- |
| 官方安装脚本 | macOS / Linux | `curl`、`tar` |
| Homebrew | macOS | Homebrew |
| Chocolatey / GitHub Releases 独立包 | Windows | Chocolatey；或直接下 zip 包 |
| `dart pub global activate` | 跨平台 | 已有 Dart SDK |

> Flutter-OH 开发者通常已随 Flutter 获得 Dart SDK，因此 `dart pub global activate fvm` 在 Windows 上无需额外安装包管理器即可使用，是最省事的途径。

> `fvm fork` 子命令需要较新版本的 FVM。安装后可执行 `fvm fork list` 验证；若提示未知命令，请按上述方式升级到最新版 FVM 后再继续。

**方式一：官方安装脚本（macOS/Linux，推荐）**

```sh
curl -fsSL https://fvm.app/install.sh | bash
```

如需指定 FVM 版本：

```sh
curl -fsSL https://fvm.app/install.sh | bash -s -- <version>
```

**方式二：Homebrew（macOS）**

```sh
brew install fvm
```

**方式三：Chocolatey 或独立压缩包（Windows）**

需先安装 [Chocolatey](https://chocolatey.org)，再执行：

```powershell
choco install fvm
```

或从 [FVM GitHub Releases](https://github.com/leoafarias/fvm/releases) 下载对应架构的 zip 独立包，解压后将其 `bin` 目录加入 `PATH`。

**方式四：通过 `dart pub` 全局激活（跨平台，Windows 推荐）**

```sh
dart pub global activate fvm
```

通过 `dart pub` 安装时，需将 pub cache 的 bin 目录加入 `PATH`。该 bin 目录位于 pub cache 下，**若设置了 `PUB_CACHE` 环境变量则以其为准**：

| 平台 | 默认 bin 目录 | 若设置了 `PUB_CACHE` |
| --- | --- | --- |
| macOS / Linux | `~/.pub-cache/bin` | `$PUB_CACHE/bin` |
| Windows | `%LOCALAPPDATA%\Pub\Cache\bin` | `%PUB_CACHE%\bin` |

在该 bin 目录下应能找到 `fvm`（Windows 为 `fvm.bat`）。加入 `PATH` 后**重开终端**，执行 `fvm --version` 验证；若提示"找不到命令"，通常是 bin 目录未正确加入 `PATH`，可用 `which fvm`（macOS/Linux）或 `where fvm`（Windows）排查。

## 使用步骤

### 第一步：注册 Flutter OH 为 fork 别名

FVM 通过 `fvm fork add <alias> <url>` 注册自定义仓库。将 Flutter OH 源码（`https://gitcode.com/CPF-Flutter/flutter_flutter.git`）注册为 `flutter_ohos` 别名：

```sh
# 注册 Flutter OH 仓库为 fork 别名
fvm fork add flutter_ohos https://gitcode.com/CPF-Flutter/flutter_flutter.git
```

- `<alias>`（`flutter_ohos`）：自定义别名，后续以 `flutter_ohos/<version>` 引用。
- `<url>`：须以 `.git` 结尾的 Git 仓库地址。

查看已注册的 fork：

```sh
# 查看已注册的 fork
fvm fork list
```

### 第二步：安装指定的 Flutter OH 分支或 tag

注册别名后，可像官方版本一样安装任意分支或 tag。分支选择请参阅 [Flutter-OH 版本演进规划和分支策略](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)。

```sh
# 安装 flutter_ohos 的 dev 分支
fvm install flutter_ohos/dev
```

安装完成后查看本地已安装版本，确认 `flutter_ohos/dev` 已就绪：

```sh
# 查看本地已安装版本
fvm list
```

> `dev` 等分支会持续更新。日后若要刷新到最新提交，重新执行 `fvm install flutter_ohos/dev` 即可，FVM 会更新缓存中对应版本的代码并刷新软链。

### 第三步：在项目中绑定版本

进入 Flutter 工程根目录，绑定上一步安装的版本：

```sh
# 进入项目目录
cd my_app
# 绑定 flutter_ohos/dev 版本
fvm use flutter_ohos/dev
```

执行后项目根目录下新增：

| 路径 | 说明 |
| --- | --- |
| `.fvm/flutter_sdk` | 指向 fvm 缓存中对应版本 SDK 的软链 |
| `.fvmrc` | 记录绑定的版本，供团队共享 |

> `.fvmrc` 用于团队共享，应提交到版本库；`.fvm/flutter_sdk` 是本地软链，应加入 `.gitignore` 忽略：

```gitignore
.fvm/flutter_sdk
```

> Windows 上创建软链需具备相应权限：在「系统设置 → 开发者选项」中开启「开发者模式」，或以管理员身份运行终端后再执行 `fvm use`，否则软链创建会失败。

团队成员拉取代码后，只需在项目根目录执行 `fvm install`，FVM 即按 `.fvmrc` 约定的版本自动拉取并创建软链。

### 第四步：运行 Flutter 命令

在绑定了版本的项目目录下，使用 `fvm flutter <command>` 调用该版本的 Flutter：

```sh
# 验证环境
fvm flutter doctor -v
# 创建工程
fvm flutter create --platforms ohos my_app
# 运行到设备
fvm flutter run --debug -d <deviceId>
```

> 若希望直接使用全局 `flutter` 命令而非 `fvm flutter`，执行 `fvm global flutter_ohos/dev` 将该版本设为全局默认。

### 第五步（可选）：配置 IDE 使用锁定版本

让 Android Studio / VS Code 自动使用 FVM 锁定的版本，将 Flutter SDK 路径指向项目内软链 `.fvm/flutter_sdk`：

- **VS Code**：在 `.vscode/settings.json` 中加入：

  ```json
  {
    "dart.flutterSdkPath": ".fvm/flutter_sdk"
  }
  ```

- **Android Studio**：在 Preferences → Languages & Frameworks → Flutter 中，将 SDK 路径设为 `<项目路径>/.fvm/flutter_sdk`。

- **DevEco Studio**：DevEco Studio 用于打开并构建 `ohos` 模块，不直接读取 Flutter SDK 路径，无需在此配置。Flutter 侧命令（`create`/`run`/`build` 等）仍通过 `fvm flutter <command>` 调用；在 DevEco 中编译、安装到设备的流程参见 [《OpenHarmony 设备运行指导》](./openharmony-device-guide.md)。

`fvm use` 执行时默认会尝试写入 VS Code 配置；如未生效可手动按上述设置。

## 在 Flutter OH 与官方社区 Flutter 之间切换

FVM 原生支持官方 Flutter 通道（`stable`、`beta`、`master`）及任意正式 release（如 `3.24.0`），无需注册 fork 即可安装：

```sh
# 安装官方 stable 通道
fvm install stable
# 安装指定版本 tag
fvm install 3.24.0
```

在项目内切换绑定版本，会覆盖 `.fvmrc` 与 `.fvm/flutter_sdk` 软链：

```sh
# 切到官方 stable
fvm use stable
# 切回 Flutter OH
fvm use flutter_ohos/dev
```

`fvm list` 可查看本地已安装版本，官方版本与 OH 版本并列展示，切换时按 `fvm use <version>` 引用即可。

> 切换版本后建议重新执行 `fvm flutter doctor -v` 确认环境。OH 与官方 Flutter 的依赖缓存、`pubspec.lock` 可能不同，跨版本切换后若遇依赖异常，可执行 `fvm flutter pub get` 刷新。

> 若希望全局默认使用官方 Flutter 而非 OH，执行 `fvm global stable`；反之执行 `fvm global flutter_ohos/dev`。

> 注意与下文「想全局都使用 Flutter OH，怎么配置？」一节的交互：`fvm config --flutter-url` 会改变后续**所有** `fvm install` 命令（含 `stable`/`beta`/`master` 等通道以及 `3.24.0` 等版本 tag）的默认拉取仓库——FVM 默认开启 git 缓存，所有安装均从该 URL 克隆 git 缓存。若已将其指向 OH 仓库，安装官方版本前请先恢复默认地址：`fvm config --flutter-url https://github.com/flutter/flutter.git`。

## 验证流程

1. 执行 `fvm --version`，能输出版本号说明 FVM 已就绪。
2. 执行 `fvm list`，列表中应出现 `flutter_ohos/dev`。
3. 在已绑定版本的项目目录执行 `fvm flutter doctor -v`，Flutter 一项应为 `[✓]`。
4. 检查项目根目录存在 `.fvm/flutter_sdk` 软链，且指向 fvm 缓存中 `flutter_ohos/dev` 对应的目录。

## 常用命令速查

| 命令 | 说明 |
| --- | --- |
| `fvm fork add <alias> <url>` | 注册一个自定义 Flutter 仓库别名 |
| `fvm fork list` | 查看已注册的 fork 别名 |
| `fvm fork remove <alias>` | 移除 fork 别名 |
| `fvm install <alias>/<version>` | 安装指定 fork 的某个分支/tag |
| `fvm install stable`、`fvm install <version>` | 安装官方 Flutter 通道或正式版本（如 `stable`、`3.24.0`） |
| `fvm use <version>` | 在当前项目绑定指定版本（生成 `.fvm/` 配置） |
| `fvm use <version> --force` | 强制覆盖当前配置 |
| `fvm list` | 查看本地已安装的版本 |
| `fvm remove <version>` | 移除某个本地版本 |
| `fvm global <version>` | 将某版本设为系统全局默认 |
| `fvm flutter <command>` | 使用项目锁定的版本执行 Flutter 命令 |
| `fvm dart <command>` | 使用项目锁定的版本执行 dart 命令 |
| `fvm doctor` | 检查当前项目与环境的 FVM 配置状态 |

## 常见问题

### `fvm install` 时拉取缓慢或失败？

OH 仓库地址（`gitcode.com`）已为国内镜像，正常情况下 git 拉取较快。若仍遇到问题，分两种情况排查：

**情况一：pub 依赖下载缓慢**——设置 pub 与存储镜像（环境变量需长期保留）：

```sh
# 设置 pub 镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

**情况二：git 拉取仓库本身缓慢或失败**——可配置 Git 代理；或手动 `git clone` OH 源码到 FVM 的缓存目录（执行 `fvm list` 可查看缓存路径），按 FVM 文档以 `custom_` 前缀命名目录，再用 `fvm use custom_<name>` 引用。

### 使用 FVM 后 `flutter doctor` 仍提示找不到 Flutter？

需通过 `fvm flutter doctor` 调用。若希望直接使用全局 `flutter` 命令，执行 `fvm global flutter_ohos/dev` 将该版本设为全局默认。

### FVM 与环境搭建文档中的 `git clone` 方式冲突吗？

不冲突。两者只是获取 Flutter OH 源码的方式不同：FVM 安装到统一缓存目录并通过软链引用，`git clone` 则放到自选目录。同一台机器上二选一即可，**不建议同时将两套 Flutter 的 `bin` 目录加入 `PATH`**。

### 想全局都使用 Flutter OH，怎么配置？

将该版本设为全局默认即可：

```sh
# 将 flutter_ohos/dev 设为全局默认
fvm global flutter_ohos/dev
```

此后在任意目录直接执行 `flutter`、`dart` 均使用该 OH 版本，且不影响项目内通过 `fvm use` 锁定的版本（参见第四步 `fvm global` 说明）。
