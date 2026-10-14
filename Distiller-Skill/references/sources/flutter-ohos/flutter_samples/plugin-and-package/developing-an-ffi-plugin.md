# 开发FFI plugin

可参考 [开发 FFI 插件](https://flutter.cn/docs/packages-and-plugins/developing-packages#plugin-ffi)。

本文介绍如何在 OpenHarmony 平台开发 FFI 插件，包含预编译 so 动态库的放置、har 打包与验证、发布到 git 并被宿主工程通过 git 依赖引入的端到端流程。

## 前置条件

在开始前，请确认本机环境已就绪：

1. **Flutter ohos 工具链**：执行 `flutter --version` 应能看到形如 `3.x.x-ohos-x.x.x` 的版本号（带 `-ohos-` 后缀），且 `flutter doctor` 中 `HarmonyOS toolchain` 一行为 `[✓]`。
2. **DevEco Studio + OHOS SDK**：通过 DevEco Studio 安装 OpenHarmony/HarmonyOS SDK。环境变量 `DEVECO_SDK_HOME` 指向 SDK 根目录。hvigorw、ohpm、Node 等随 DevEco 一并安装，无需单独配置。
3. **工程路径必须为纯 ASCII**：hvigor 构建系统要求工程所在路径仅包含字母、数字、连字符（`-`）、下划线（`_`）、点（`.`）、英文括号（`()`）、空格或 `@`。**路径含中文等非 ASCII 字符会直接构建失败**（详见常见问题）。这是最常见的环境类阻塞问题，中文用户尤需注意。
4. **LLVM/libclang（可选，仅当需要重新生成 Dart 绑定时）**：`package:ffigen` 依赖 libclang 动态库。若你修改了 `src/*.h` 并要重跑 ffigen，需安装 LLVM 并设置 `LIBCLANG_PATH`，或在 `ffigen.yaml` 中配置 `llvm-path`（详见第四步）。仅使用模板自带的预生成绑定时不需要。

> [!TIP]
> 第六步的 har 打包**不需要**应用签名；但 [步骤 7.3](#step-7-3) 的 `flutter build hap` 验证步骤**需要**先配置调试签名（见 [步骤 7.3](#step-7-3)）。

## 使用步骤

### 第一步：创建 package

```sh
flutter create --template=plugin_ffi hello --platforms=android,ios,ohos
```

创建完成后，插件根目录结构：

```text
hello/
├── lib/                          # Dart 接口实现（含模板预生成的 hello_bindings_generated.dart）
├── src/                          # 跨平台 C/C++ 原生源码（含 CMakeLists.txt）
├── ohos/                         # ohos 平台工程（har 模块）
│   └── src/main/                 # 模块代码（cpp/、module.json5）
├── android/                      # Android 平台工程
├── ios/                          # iOS 平台工程
├── example/                      # 示例 App（其 example/ohos 是完整的 hvigor 宿主工程，用于构建/验证插件 har）
├── ffigen.yaml                   # ffigen 配置
└── pubspec.yaml
```

### 第二步：在 pubspec.yaml 中指定平台

`flutter create --template=plugin_ffi` **模板已自动生成** `plugin.platforms` 配置，**通常无需手改**，仅在需要增删平台时编辑：

```yaml
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ohos:
        ffiPlugin: true
      ios:
        ffiPlugin: true
```

`ffiPlugin: true` 表示由工具链负责原生代码的构建与打包（`dart:ffi` 所必需）。

### 第三步：放置预编译 so 文件

若插件包含预编译的 so 动态库（而非从 `src/` 下的 C/C++ 源码现场编译），需将其放置到插件对应的 `ohos/libs/<abi>` 目录下。支持的 abi 目录包括：

- `arm64-v8a`（真机）
- `x86_64`（模拟器）

目录结构示例：

```text
ohos/
├── build-profile.json5
├── oh-package.json5
├── hvigorfile.ts
├── src/main/
└── libs/
    ├── arm64-v8a/
    │   └── libhello.so
    └── x86_64/
        └── libhello.so
```

<a id="step-3-1"></a>**步骤 3.1：移除 externalNativeOptions**

`flutter create --template=plugin_ffi` 生成的 `ohos/build-profile.json5` 默认配置了 `externalNativeOptions`，会从 `../src/CMakeLists.txt` 现场编译 C 源码生成 so。**使用预编译 so 时应将其移除**，避免构建系统找不到 CMake 源码而报错，或现场编译产物覆盖预编译 so。

修改前（模板默认）：

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "../src/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "",
    }
  },
  "targets": [
    { "name": "default" }
  ]
}
```

修改后（使用预编译 so）：

```json5
{
  "apiType": "stageMode",
  "buildOption": {
  },
  "targets": [
    { "name": "default" }
  ]
}
```

> [!TIP]
> 若希望从 C/C++ 源码现场编译 so（而非预编译），保留 `externalNativeOptions` 即可，无需放置 `libs/` 目录。OHOS SDK 已自带 cmake/ninja（构建任务 `BuildNativeWithCmake` / `BuildNativeWithNinja`），**无需在宿主机单独安装 cmake**。

#### so 打入 har 的机制

OpenHarmony 的 hvigor 构建系统在打包 har 模块时，会自动将模块根目录下 `libs/<abi>/` 中的 `.so` 文件打包进 har 产物（位于 har 内的 `libs/<abi>/` 路径），无需在 `build-profile.json5` 中额外配置。

> [!IMPORTANT]
> so 文件应放在 `ohos/libs/<abi>/`（即 ohos 模块根目录下的 `libs/`）。放在其他位置（如 `ohos/src/main/libs/<abi>/`）虽然也会被打进 har，但其在 har 内的路径为 `src/main/libs/<abi>/`，**不在 OpenHarmony 运行期的 so 搜索路径 `libs/<abi>/` 中**，会导致运行期 `dlopen failed`。请始终使用 `ohos/libs/<abi>/`。

> [!TIP]
> 预编译路径与源码编译路径的产物差异：源码编译（保留 `externalNativeOptions`）时，hvigor 会**自动**把 C++ 运行时 `libc++_shared.so` 一并打入 har；预编译路径则只打包你手动放进 `ohos/libs/` 的文件。若你的预编译 so 依赖 C++ 运行时（`libc++_shared.so`），需一并放进 `ohos/libs/<abi>/`，否则运行期会因缺符号而加载失败。

### 第四步：绑定本地原生代码

为了使用本地原生代码，需要在 Dart 中进行绑定。

为了避免手工编写，它们由头文件 (src/hello.h) 中的 package:ffigen 生成。`flutter create --template=plugin_ffi` **已预生成** `lib/hello_bindings_generated.dart`，开箱即用。**只有当你修改了 `src/hello.h` 后，才需要**运行以下指令重新生成绑定：

```sh
dart run ffigen --config ffigen.yaml
```

> [!IMPORTANT]
> ffigen 依赖 **LLVM 的 libclang 动态库**。若运行时报 `Couldn't find dynamic library in default locations`，请先安装 LLVM（Windows 可装 [llvm-project releases](https://github.com/llvm/llvm-project/releases) 或随 Visual Studio/DevEco 自带的版本），再任选一种方式让 ffigen 找到它：
>
> - 设置环境变量 `LIBCLANG_PATH` 指向 `libclang` 所在目录（Windows 下为 `libclang.dll` 所在目录）；
> - 或在 `ffigen.yaml` 中增加 `llvm-path: ['<LLVM 安装路径>']`。

### 第五步：调用本地原生代码

运行时间很短的本地原生函数可以在任何 isolate 中直接调用。例如，请查看 `lib/hello.dart` 中的 sum。

运行时间较长的本地原生函数应在 [helper isolate](https://dart.cn/guides/language/concurrency#background-workers) 上调用，以避免在 Flutter 应用程序中掉帧。例如，请查看 `lib/hello.dart` 中的 sumAsync。

### 第六步：打包 har 并验证 so

**步骤 6.1：打包 har**

**方式 A：DevEco Studio（GUI）**

使用 DevEco Studio 打开插件的 `example/ohos` 目录，定位到插件 ohos 模块，点击 `Build > Make Module 'xxx'` 进行打包。

**方式 B：命令行（CI/CD 友好）**

在 `example/ohos` 目录下执行 hvigorw 的 `assembleHar` 任务即可单独打包插件的 har（**不需要应用签名**）：

```sh
# 在 example/ohos 目录下执行
hvigorw assembleHar --no-daemon -p product=default -p buildMode=debug
```

打包成功后，har 产物位于：

```text
ohos/build/default/outputs/default/<plugin_name>.har
```

**步骤 6.2：验证 har 内含 so**

har 本质是 **tar.gz** 格式（gzip 压缩的 tar 归档）。可用以下命令查看 har 内是否包含 so（`tar` 命令在 Linux/macOS 自带，Windows 10+ 也自带 `tar.exe`）：

```sh
# 全平台通用
tar -tzf <plugin_name>.har | grep "\.so"
```

预期输出应包含 `package/libs/arm64-v8a/libhello.so` 等条目。若为空，说明 so 未打入 har，请回退检查第三步的目录位置与 `build-profile.json5` 配置。

> [!IMPORTANT]
> 当前 hvigor 工具链产出的 har 为 **tar.gz**（不是 zip）。请勿使用 `unzip` 或 .NET 的 `[System.IO.Compression.ZipFile]::OpenRead`，它们会因无法识别归档而失败。

### 第七步：发布到 git 并通过 git 依赖引入

<a id="step-7-1"></a>**步骤 7.1：提交到 git 前的检查（.gitignore）**

> [!NOTE]
> 这是"本地 path 依赖正常、git 引入后 har 未打入 so"**最常见的原因**。

提交前务必确认：

1. **so 文件已被 git 跟踪**。模板自带的 `ohos/.gitignore` 不会忽略 `*.so`，但若在仓库根 `.gitignore` 中误加 `*.so` 或 `libs/`，会导致 so 不被提交；他人通过 git 引入时 `ohos/libs/` 为空，自然无法打入 har。检查方法：

   ```sh
   git ls-files | grep "\.so"
   # 应能看到 ohos/libs/arm64-v8a/libhello.so 等条目
   ```

   若为空，需用 `git add -f ohos/libs/arm64-v8a/libhello.so` 强制添加，并修正 `.gitignore`：

   ```text
   # 错误写法（会忽略所有 so，导致预编译 so 无法提交）
   *.so
   ```

   如需仅忽略 Flutter 引擎 so，应精确指定，例如：

   ```text
   # 仅忽略引擎/产物 so，不影响插件的预编译 so
   **/libs/arm64-v8a/libflutter.so
   **/libs/arm64-v8a/libapp.so
   **/libs/arm64-v8a/libvmservice_snapshot.so
   ```

2. **har 构建产物不要提交**。模板自带的 `ohos/.gitignore` 已包含 `/build`（har 产物落在 `build/` 下，会被忽略）。建议再补一行 `**.har` 兜底，避免误提交：

   ```text
   **.har
   /build
   ```

**步骤 7.2：宿主工程通过 git 依赖引入**

在宿主工程的 `pubspec.yaml` 中通过 git 依赖引入 FFI 插件：

```yaml
dependencies:
  hello:
    git:
      url: https://gitcode.com/<org>/hello_ohos.git
      path: hello            # 若插件在仓库子目录，指定 path；根目录则省略
      ref: v1.0.0            # 指定分支/tag/commit
```

执行 `flutter pub get` 后，pub 会将插件源码克隆到 PUB 缓存。flutter_ohos 工具会将插件的 ohos 模块作为 hvigor 节点纳入宿主工程构建（源码方式，而非预构建 har），构建时从插件源码的 `ohos/libs/<abi>/` 取 so 打入最终 hap。

> [!TIP]
> 因此，**so 是否存在于 git 仓库的 `ohos/libs/<abi>/` 中，直接决定 git 依赖能否打入 so**。本地 path 依赖时，so 直接取自本地磁盘（不经 git），所以即使 so 未提交也能正常工作——这正是两类引入方式表现不一致的根因。

<a id="step-7-3"></a>**步骤 7.3：验证**

hap 构建需要调试签名，har 则不需要。若尚未配置签名，请先用 DevEco Studio 打开宿主 `ohos` 工程，`File > Project Structure > Signing Configs` 勾选 `Automatically generate signature`（会在 `build-profile.json5` 写入 `signingConfigs`），或手动填写已有签名材料。

```sh
flutter pub get
flutter build hap --debug
# 或 flutter run -d <device-id>
```

构建产物 hap 内应包含插件 so，可在设备上运行验证 ffi 调用是否正常。若需确认 hap 内含 so，可在 DevEco Studio 的 `Build > Build Hap(s)` 后查看 `entry/build/default/outputs/default/entry-default-signed.hap`（同样为 tar.gz 格式，可用步骤 6.2 方法检查）。

## 常见问题

### 构建报错：Invalid project path / 路径含中文

**现象**：`flutter build hap` 或 `hvigorw` 报 `Invalid project path. Current path does not match ...` 并列出允许字符集，路径中的中文显示为乱码。

**原因**：hvigor 要求工程路径仅含 ASCII 字符（字母、数字、`-`、`_`、`.`、英文括号、空格、`@`）。中文文件夹名（如“新建文件夹”）会被拒绝。

**解决**：将工程移动到纯 ASCII 路径（如 `C:\dev\hello`）后重新构建。

### 本地 path 依赖正常，git 依赖后 har 未打入 so

**现象**：插件本地通过 `path` 依赖引入，so 正常打入 har/hap；改为 `git` 依赖后，构建产物内不含 so。

**原因与排查**（按概率从高到低）：

1. **so 未提交到 git（最常见）**：用 `git ls-files | grep "\.so"` 确认 so 已被跟踪；检查仓库根与 `ohos/.gitignore` 是否忽略了 `*.so` 或 `libs/`。详见 [步骤 7.1](#step-7-1)。
2. **so 目录位置错误**：so 必须在 `ohos/libs/<abi>/`（ohos 模块根的 `libs/`）。放在 `ohos/src/main/libs/` 等位置虽会打入 har，但不在运行期搜索路径 `libs/<abi>/`，运行期 `dlopen` 会失败。详见 [第三步](#第三步放置预编译-so-文件)。
3. **未移除 externalNativeOptions**：若使用预编译 so 但 `ohos/build-profile.json5` 仍保留 `externalNativeOptions` 指向不存在的 CMake 源码，构建会报错或跳过 prebuilt libs 的打包。请按 [步骤 3.1](#step-3-1) 移除。
4. **abi 不匹配**：so 必须放在与目标设备匹配的 abi 目录下。真机为 `arm64-v8a`，模拟器为 `x86_64`。

### har 内 so 路径与运行期加载路径不一致

OpenHarmony 运行期从 hap 的 `libs/<abi>/` 下加载 so。若在 har 中 so 位于 `libs/<abi>/` 但运行期仍报 `dlopen failed`，请检查 so 的依赖项（用 `readelf -d libhello.so` 查看依赖的其他 so 是否也存在、是否需要随包附带 `libc++_shared.so`）、以及 so 的编译架构（arm64）是否与设备一致。

### ffigen 报错：Couldn't find dynamic library

**现象**：执行 `dart run ffigen --config ffigen.yaml` 报 `Couldn't find dynamic library in default locations`。

**原因**：ffigen 依赖 LLVM 的 libclang，本机未安装或未被 ffigen 找到。

**解决**：安装 LLVM 并设置 `LIBCLANG_PATH` 环境变量，或在 `ffigen.yaml` 中配置 `llvm-path`。详见 [第四步](#第四步绑定本地原生代码)。若未修改 `src/*.h`，可直接使用模板预生成的 `lib/hello_bindings_generated.dart`，无需重跑 ffigen。

## 延伸阅读

1. [Flutter Packages 的开发和提交](https://flutter.cn/docs/packages-and-plugins/developing-packages)
2. [开发 FFI 插件](https://flutter.cn/docs/packages-and-plugins/developing-packages#plugin-ffi)
3. [OpenHarmony 文档](https://docs.openharmony.cn/pages/v6.0/zh-cn/application-dev/application-dev-guide.md)
4. [HarmonyOS 文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/start-overview)
