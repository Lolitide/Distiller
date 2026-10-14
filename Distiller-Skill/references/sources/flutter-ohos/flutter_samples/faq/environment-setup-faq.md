# 环境问题

[Flutter OH 开发环境搭建指导](../getting-started/flutter-oh-env-setup.md)

<a id="section792878"></a>

## 执行 Flutter 命令时报错 Error: The Flutter directory is not a clone of the GitHub project

**现象：**

执行 Flutter 命令（例如 `flutter doctor -v`）时报错：

```log
Error: The Flutter directory is not a clone of the GitHub project.
```

**原因：**

Flutter OH SDK 不是通过 `git clone` 获取的，通常是通过网页下载 ZIP 压缩包并解压。该方式不会包含 `.git` 目录，而 Flutter 工具启动时依赖 Git 元数据，因此命令会在执行前直接退出。

**解决方案：**

改用 `git clone` 获取源码，并切换到目标分支或 tag。

---

<a id="section792879"></a>

## 执行 Flutter 命令时报错 Error: Unable to find git in your PATH

**现象：**

执行 Flutter 命令（例如 `flutter doctor -v`）时报错：

```log
Error: Unable to find git in your PATH.
```

**原因：**

Git 未安装，或 Git 可执行文件所在目录未加入 `PATH`。

**解决方案：**

1. 安装 Git。
2. 将 Git 的 `cmd` 目录加入 `PATH`，例如 `C:\Program Files\Git\cmd`。
3. 重新打开终端后执行 `git --version` 确认可用。

---

<a id="section792877"></a>

## 遇到 [!] No Hmos SDK found. Try setting the HOS_SDK_HOME enviroment variable. 报错

**现象：**

执行 Flutter 命令时报错 `[!] No Hmos SDK found. Try setting the HOS_SDK_HOME enviroment variable.`。

**原因：**

未配置 ohos-sdk 路径。

**解决方案：**

1. 获取 `DevEco Studio` 工具自带的 SDK 路径，例：`D:\Huawei\DevEco Studio\sdk`
2. 执行以下命令，配置 flutter 的 ohos-sdk 路径：

   ```shell
   flutter config --ohos-sdk "D:\Huawei\DevEco Studio\sdk"
   ```

3. 执行以下命令，检查配置是否成功：

   ```shell
   flutter config --list
   ```

   输出以下内容则配置成功：

   ```shell
   All Settings:
     ohos-sdk: D:\Huawei\DevEco Studio\sdk
   ```

---

<a id="section808944"></a>

## 断网环境 flutter pub get 执行失败

**现象：**

断网环境下执行 `flutter pub get` 失败。

**原因：**

断网环境下无法从远程仓库获取依赖。

**解决方案：**

加上 `--offline` 参数，完整命令：

```shell
flutter pub get --offline
```

---

<a id="section677748"></a>

## 【Windows】flutter pub get 报错 Package not available（长路径问题）

**现象：**

报错日志：

```log
Package not available (the pubspec for shared_preferences 2.5.3 from git has version 2.2.0)
```

**原因：**

第一次运行 `flutter pub get` 时，会将 `https://gitcode.com/CPF-Flutter/flutter_packages.git` 的整个项目拉到本地缓存（即使你只需要 `shared_preferences`）。由于部分插件文件路径过长，超出了 Windows 默认的路径长度限制（260 字符），导致拉取后无法切换分支，只能停留在默认的 master 分支，因此出现版本不匹配的报错。

缓存路径取决于 `PUB_CACHE` 环境变量：

- 未设置 `PUB_CACHE` 时，默认路径为 `C:\Users\[用户名]\AppData\Local\Pub\Cache\git\flutter_packages-xxx`
- 设置了 `PUB_CACHE` 时（如 `D:\pub-cache`），路径为 `%PUB_CACHE%\git\flutter_packages-xxx`

**解决方案：**

**方案一（推荐）：设置 PUB_CACHE 环境变量到较短路径**

将 `PUB_CACHE` 设置到盘符根目录（如 `D:\pub-cache`），从根源上缩短路径长度，减少长路径问题的发生：

1. 在系统环境变量中添加 `PUB_CACHE`，值设为 `D:\pub-cache`（或其他盘符的短路径）
2. 删除原有缓存目录，重新执行 `flutter pub get`

**方案二：启用 Windows 长路径支持**

1. 打开 `gpedit.msc` → 计算机配置 → 管理模板 → 系统 → 文件系统 → 启用「启用 Win32 长路径」
2. 以管理员身份运行 cmd，执行：

   ```shell
   git config --system core.longpaths true
   ```

3. 在缓存目录的 `git\` 子目录下查找以 `flutter_packages` 开头的目录，将其删除，重新执行 `flutter pub get`

---

<a id="section764574"></a>

## mac 环境 release 版本的应用编译失败

**现象：**

报错日志：

```log
ProcessPackageException: ProcessException: Found candidates, but lacked sufficient permissions to execute "/Users/xxx/ohos/src/out/ohos_release_arm64/clang_arm4/dart".
  Command: /Users/xxx/ohos/src/out/ohos_release_arm64/clang_arm4/dart
```

**原因：**

mac 环境下编译产物缺少执行权限。

**解决方案：**

1. 添加执行权限：

   ```shell
   chmod -R +x /Users/xxx/ohos/src/out/ohos_release_arm64/*
   ```

2. 手动点击 `src/out/ohos_release_arm64/clang_arm64` 目录下的 `dart` 和 `gen_snapshot`，在「设置 → 隐私与安全 → 安全性」中允许程序运行

---

<a id="section404296"></a>

## flutter 从 Windows 复制到 linux 或 mac 环境后无法运行

**现象：**

报错日志：

```log
curl: (3) Illegal characters found in URL
xxx/flutter_flutter/bin/internal/update_dart_sdk.sh: line 156: return: can only return from a function or sourced script
curl: (3) Illegal characters found in URL
```

**原因：**

Windows 上的换行符（CRLF）和 linux/mac（LF）不一致导致的。

**解决方案：**

1. 将单个文件中的换行符由 CRLF（`\r\n`）替换为 LF（`\n`）：

   ```shell
   sed -i "s/\r//" target_file
   ```

2. 批量替换 `bin/dart`、`bin/*.sh` 和 `bin/internal/*.version` 中的换行符：

   ```shell
   cd flutter
   # linux环境执行
   sed -i "s/\r//" bin/dart $(find bin -name "*.sh") $(find bin -name "*.version")
   # mac环境执行
   sed -i "" "s/\r//" bin/dart $(find bin -name "*.sh") $(find bin -name "*.version")
   ```

---

<a id="section491334"></a>

## ~/.npmrc 的配置

**现象：**

需要配置 npm 镜像源与代理。

**原因：**

ohpm 与 npm 默认源在国内访问受限，需配置镜像源以加速依赖下载。

**解决方案：**

在 `~/.npmrc` 文件中配置镜像源与代理：

```ini
registry=https://repo.huaweicloud.com/repository/npm/
@ohos:registry=https://repo.harmonyos.com/npm/
strict-ssl=false
# 设置代理
# http_proxy=http://user:password@host:8080
# https_proxy=http://user:password@host:8080
```

---

<a id="section531573"></a>

## ~/.ohpmrc 的配置

**现象：**

需要配置 ohpm 镜像源与代理。

**原因：**

ohpm 默认源在国内访问受限，需配置镜像源以加速 OpenHarmony 三方库下载。

**解决方案：**

在 `~/.ohpmrc` 文件中配置镜像源与代理：

```ini
registry=https://repo.harmonyos.com/ohpm/
strict_ssl=false
# 设置代理
# http_proxy=http://user:password@host:8080
# https_proxy=http://user:password@host:8080
```

---

<a id="section766721"></a>

## 模拟器运行默认计数器应用闪退

**现象：**

在模拟器上运行 Flutter 默认计数器应用时出现闪退。

**原因：**

`FloatingActionButton` 在模拟器上不支持。详见 [模拟器与真机的差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-specification)。

**解决方案：**

在 `lib/main.dart` 中注释 `FloatingActionButton` 后再运行到模拟器上。

---

<a id="section563397"></a>

## [ios][release] GeneratedPluginRegistrant.m Module not found

**现象：**

iOS release 构建时报 `GeneratedPluginRegistrant.m Module not found`。

**原因：**

pubspec.yaml 中新增了 flutter 插件，但是 Podfile 中没有新增插件对应的 pod 引用。

**解决方案：**

```shell
rm ios/podfile && flutter clean && flutter run -d <ios_device>
```

参考链接：[GeneratedPluginRegistrant.m Module not found](https://github.com/flutter/flutter/issues/43986)

---

<a id="section146178"></a>

## 【Windows】flutter doctor -v 无反应

**现象：**

配置好环境变量后，执行 `flutter doctor -v` 没有反应。

执行结果有 Flutter 和 OpenHarmony（表明基础环境配置正确，这两个平台均被支持）。

![](../media/faq/error.png)

<p align="center"><strong>图1</strong> flutter doctor -v 执行结果</p>

**原因：**

可能是没有配置好代理。

**解决方案：**

1. 在系统环境变量中配置 `http_proxy`、`https_proxy`、`no_proxy` 环境变量
2. `http_proxy` 参考 DevEco 代理配置
3. `https_proxy` 可以等于 `http_proxy`
4. `no_proxy` 参考 DevEco 代理配置外，还需要添加：
   - `localhost`
   - `::1`
   - `127.0.0.1`

---

<a id="section900001"></a>

## 执行 flutter upgrade 报错

**现象：**

执行 `flutter upgrade` 报错，环境损坏。

**原因：**

Flutter OH 暂未适配 `flutter upgrade` 命令，执行后会尝试从官方 Flutter Channel 拉取并覆盖当前 OpenHarmony 适配环境，导致环境损坏并报错。

**解决方案：**

请勿使用 `flutter upgrade`，改用以下方式进行版本切换：

```shell
# 方式1：克隆指定分支
git clone -b {目标分支名} https://gitcode.com/CPF-Flutter/flutter_flutter.git

# 方式2：在现有 SDK 目录切换分支
cd $FLUTTER_ROOT
git checkout {目标分支名}
rm -rf bin/cache
flutter doctor
```

详见 [Flutter OH 版本升级指导](../version/flutter-oh-upgrade-guide.md)。
