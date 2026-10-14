# ohos 应用编译问题

<a id="section486961"></a>

## 使用 Flutter 命令行编译构建应用报错

**现象：**

使用 `flutter build hap --release` 命令行编译构建应用时报错：

```log
> hvigor ERROR: ENOENT: no such file or directory, stat `xxx\ohos\entry\oh_modules\flutter_native_x86_64`
```

**原因：**

调试阶段有交替使用模拟器和真机设备，使用了模拟器的缓存。

**解决方案：**

1. 编译构建命令指定平台架构：

   ```bash
   flutter build hap --release --target-platform ohos-arm64
   ```

2. 手动删除项目里以下缓存文件：

   ```text
ohos/
├── .dart_tool 
├── .build
├── ohos
│   ├── entry/
│   │   ├── build
│   │   ├── oh_modules
│   └─ oh_modules
   ```

   重新执行编译构建命令 `flutter build hap --release`。

---

<a id="section608960"></a>

## 拷贝或克隆其他 Flutter OH 项目到本地后无法运行

**现象：**

从其他开发者或 Git 仓库拷贝/克隆 Flutter 项目后，编译运行时报错。

**原因：**

原项目的 Flutter 版本、依赖锁定或构建缓存与本地环境不一致。

**解决方案：**

- 检查 Flutter OH 项目与本地 Flutter 版本的兼容性

  打开项目 `pubspec.yaml` 文件，查看 sdk 版本：

   ```yaml
   environment:
     sdk: '版本号'
   ```

  终端执行 `flutter doctor` 查看本地 Flutter 环境版本，看是否和项目版本兼容，若不兼容需修改。

- 删除 `pubspec.lock` 并重新获取依赖：

  ```bash
  # Windows
  del pubspec.lock
  # macOS/Linux
  rm pubspec.lock

  flutter clean
  flutter pub get
  ```

  > **说明：** `pubspec.lock` 是依赖锁定文件，原项目的环境可能与你本地不同，删除后让 pub 根据当前环境重新解析依赖版本。

- 清理构建缓存：

  ```bash
  flutter clean
  ```

  删除 `build/`、`dart_tool/`、`ohos/oh_modules`、`ohos/entry/build` 等缓存目录。

---

<a id="section198530"></a>

## 配置别名，简化日常开发的编译命令

**现象：**

日常开发频繁输入较长的 `flutter build`/`flutter run` 命令，希望简化。

**原因：**

OpenHarmony 化的编译运行命令较长（尤其带 `--local-engine` 参数时），重复输入效率低。

**解决方案：**

在环境变量配置文件中配置别名，简化 Flutter OpenHarmony 化日常使用的命令：

- windows，使用 `Git Bash` 可以执行常见的 linux 命令。（使用方式：鼠标右键点击文件管理器中的空白处，左键点击 Git Bash Here）
- linux，修改 `~/.bash_profile`。
- mac，修改 `~/.bash_profile`，并在 `~/.zshrc` 中加上 `source ~/.bash_profile`。

```bash
# --local-engine 参数可选，指向自行编译的 engine 产物，建议在 linux/mac 环境使用
export ENGINE_DIR=~/ohos/engine
export ENGINE_DEBUG=$ENGINE_DIR/src/out/ohos_debug_unopt_arm64
export ENGINE_PROFILE=$ENGINE_DIR/src/out/ohos_profile_arm64
export ENGINE_RELEASE=$ENGINE_DIR/src/out/ohos_release_arm64

alias fbuildD="flutter build hap --local-engine=$ENGINE_DEBUG --debug"
alias fbuildP="flutter build hap --local-engine=$ENGINE_PROFILE --profile"
alias fbuildR="flutter build hap --local-engine=$ENGINE_RELEASE --release"
alias frunD="flutter run -d $(hdc list targets) --local-engine=$ENGINE_DEBUG --debug"
alias frunP="flutter run -d $(hdc list targets) --local-engine=$ENGINE_PROFILE --profile"
alias frunR="flutter run -d $(hdc list targets) --local-engine=$ENGINE_RELEASE --release"
```

配置完成后，重新打开终端窗口，在 flutter 工程目录中即可使用别名编译或运行：

```bash
flutter create hello --platforms ohos
cd hello
# 编译 debug 版本
fbuildD
# 运行 debug 版本
frunD
```

---

<a id="section610061"></a>

## 应用编译成功，安装后出现白屏的情况

**现象：**

应用编译成功，安装后出现白屏。

**原因：**

使用的 engine 产物和运行模式不一致，导致 Dart VM 初始化时 snapshot 版本不匹配，出现白屏。详见 [ohos 运行问题](./runtime-issues-faq.md#section721639)。

**解决方案：**

确保运行或编译命令中 engine 产物与目标模式一致，详见 [ohos 运行问题](./runtime-issues-faq.md#section721639)。

---

<a id="section904254"></a>

## 应用编译报错，flutter 插件结构重构前的版本使用了重构后的插件库

**现象：**

编译报错，日志：

```log
Oops; flutter has exited unexpectedly: "type 'Null' is not a subtype of type 'List<dynamic>' in type cast".
```

**原因：**

flutter 插件结构重构前后版本不兼容，旧版本 flutter_flutter 使用了重构后的插件库。

**解决方案：**

flutter_flutter 更新到 master 或 dev 的最新版本。（`45bd5e627e1f1e5f4d335f205781565f576acc60`，2024-05-10）

---

<a id="section729405"></a>

## Flutter 编译插件时引入预编译 so 包，so 包未打入 har 包

**现象：**

使用 DevEco 工具查看编译后的 har 包目录下未找到引入的 so 包，导致功能调用异常。

**原因：**

so 包放置的路径不对，导致编译时未打入 har 包。

**解决方案：**

可参考 [FFI 插件开发文档](../plugin-and-package/developing-an-ffi-plugin.md) 中关于预编译 so 包的放置路径。

---

<a id="section173896"></a>

## flutter pub get 依赖冲突报错

**现象：**

执行 `flutter pub get` 时报依赖冲突错误，典型日志：

```log
Resolving dependencies...
Because flutter_cache_manager >=3.0.0-nullsafety.0 <3.3.2 depends on path_provider from hosted and flutter_cache_manager depends on path_provider from git, flutter_cache_manager >=3.0.0-nullsafety.0 <3.3.2 forbidden.
So because xxx depends on flutter_cache_manager 3.3.1, version solving failed.
pub get failed
exit code: 1
```

**原因：**

`path_provider` 的 hosted 版本与 git 版本来源冲突，导致依赖求解失败。

**解决方案：**

使用 `dependency_overrides` 消除依赖冲突，详见 [plugin-adaptation-faq](./plugin-adaptation-faq.md#section152730)。

---

<a id="section813672"></a>

## flutter 三方库依赖错误

**现象：**

日志信息：

```log
Error:error:AbiSpecificInteger'Int32' is missing mapping for 'ohos_arm64'.
Dart snapshot generator failed with exit code 254
Target ohos_aot_profile_ohos-arm64 failed: Exception: AOT snapshotter exited with code 254.
```

**原因：**

这类报错一般是未使用 OpenHarmony 社区适配的三方库。

**解决方案：**

查看 yaml 文件的三方库依赖，通过文档查找对应的三方库地址 [OpenHarmony 平台已适配三方库](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md)。

---

<a id="section961487"></a>

## The SDK license agreement is not accepted

**现象：**

日志信息：

```log
hvigor install success.
> hvigor ERROR: Cause: The SDK license agreement is not accepted.
```

**原因：**

ohos 工程的结构还是 api11 的，但是使用的 sdk 是 api12 的，这种情况下就会出现这个报错信息。

**解决方案：**

将 ohos 工程结构升级为 api12。

操作步骤：

1. DevEco-Studio -> Migrate Assistant -> 5.0.0 -> Migrate
2. DevEco-Studio -> File -> Project Structure -> Compatible SDK -> 5.0.0(12)

---

<a id="section225581"></a>

## 通过 flutter build hap --release 编译版本会导致 app.json versionName 字段重置

**现象：**

查看 `app.json` 下的 `versionName` 字段，执行 `flutter build hap --release` 编译后，该字段被重置为 `1.0.0`。

**原因：**

当前规格默认 build 会使用 `1.0.0` 版本号。

**解决方案：**

在 build 指令时指定 `versionName` 和 `versionCode`，详见 [signing-and-release-faq](./signing-and-release-faq.md#section380470)。

---

<a id="section284801"></a>

## 应用编译报错 flutter 工程和依赖的插件工程不在同一个磁盘

**现象：**

日志信息：

```log
ohpm ERROR: Found exception: xxx is not in the same file system as the current project, reached retry limit or non retryable error encountered.
```

**原因：**

flutter 工程和依赖的插件工程不在同一个磁盘，这种情况下就会出现这个报错信息。

**解决方案：**

Windows 环境下 flutter 工程和依赖的插件工程需要在同一个磁盘。

---

<a id="section769910"></a>

## Note that you need plugins to import files that are not JavaScript

**现象：**

日志信息：

```log
> hvigor ERROR: Failed :entry:default@CompileArkTS...
> hvigor ERROR: Unexpected token (Note that you need plugins to import files that are not JavaScript)
```

**原因：**

DevEco Studio 由低版本升级到高版本，这种情况下就会出现这个报错信息。

**解决方案：**

修改 `hvigor-config.json5` 配置文件：

```json5
{ 
  "modelVersion": "5.0.0",
  "dependencies": {
  },
  "properties": {
    "ohos.nativeResolver": false
  }
}
```

---

<a id="section555584"></a>

## DevEco 工具同步或者运行 Flutter 新模板工程依赖的插件与 SDK 不在一个磁盘

**现象：**

日志信息：

```log
> hvigor ERROR: The srcPath is not a relative path: xxxx

* Try the following:
> Make sure the srcPath in the hvigorconfig.ts file of the project is a relative path.
```

**原因：**

新模板工程编译构建中，flutter-hvigor-plugin 插件使用 [hvigorConfig.includeNode](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-api#section558816280274) 添加三方库源码作为节点，relativePath 无法生成跨磁盘的相对路径，导致传入的参数 [srcPath 为绝对路径](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-compiling-and-building-138)。

**解决方案：**

[应用编译报错 flutter 工程和依赖的插件工程不在同一个磁盘](#section284801)
