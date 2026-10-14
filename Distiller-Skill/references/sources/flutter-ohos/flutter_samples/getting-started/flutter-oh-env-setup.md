# Flutter OH 开发环境搭建指导

本文指导如何从零搭建 **Flutter OH**（Flutter OpenHarmony 适配版）的开发环境，并端到端验证一个 Flutter 工程能在 OpenHarmony 真机或模拟器上编译与运行。

## 前置条件

开始前请确认以下条件已满足：

- **操作系统**：macOS、Linux、Windows 均可。macOS 用户请先在终端执行 `uname -m` 判断系统架构（`x86_64` 为 x86-64 架构，`arm64` 为 ARM64 架构），并据此选择对应开发套件与镜像。
- **模拟器限制**：DevEco Studio 模拟器当前支持 **macOS（arm64）** 与 **Windows（x64）**，暂不支持 macOS（x86）架构。无受支持设备的用户请准备 OpenHarmony 真机。
- **华为账号**：若需使用模拟器，请准备已完成**实名制认证**的华为账号。

## 安装前置依赖：JDK 17 及以上

OpenHarmony SDK 存在 Java 环境依赖，需先安装 JDK 17 及以上版本。

1. 前往 [Oracle 官网](https://www.oracle.com/cn/java/technologies/downloads/#java17) 或 OpenJDK 官网下载 JDK 17 或更高版本，并按安装向导完成安装。
2. 安装完成后，执行以下命令验证，能正确输出版本信息即表示安装成功：

   ```sh
   java -version
   ```


## 下载并安装 DevEco Studio

DevEco Studio 是 OpenHarmony 官方 IDE，安装后会自带 SDK、ohpm、hvigor、node 等工具链。

### 2.1 下载

前往 [华为开发者联盟 - 工具下载 - DevEco Studio](https://developer.huawei.com/consumer/cn/download/)，根据电脑系统下载最新版 DevEco Studio。

![](../media/getting-started/getting-started-17.png)

### 2.2 安装

解压开发套件压缩包后，运行 DevEco Studio 的安装包文件，按安装向导完成安装。

- macOS 默认路径：`/Applications/DevEco-Studio.app/Contents`
- Windows 默认路径：如 `D:\Huawei\DevEco Studio`

## 获取 Flutter OH 源码

获取 [Flutter OH](https://atomgit.com/CPF-Flutter/flutter_flutter) 源码。版本分支与 tag 的选择请参阅 [Flutter-OH 版本演进规划和分支策略](https://atomgit.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)。

Flutter OH 源码需要通过 Git 克隆获取。

### 通过 Git 克隆获取源码

适用于已安装 Git 且网络可访问 AtomGit 的场景。克隆后可随时切换分支、拉取更新。

   ```sh
   # 1) 克隆 Flutter OH 源码
   git clone https://atomgit.com/CPF-Flutter/flutter_flutter.git
   # 2) 切换到 dev 分支（或按版本配套表选择对应 tag）
   git checkout -b dev origin/dev
   ```

## 配置环境变量

配置前，请先准备好以下路径（在前面步骤中已记录）：

| 占位符 | 含义 | 示例 |
| ------ | ---- | ---- |
| `<JAVA_HOME path>` | JDK 安装路径 | macOS：`/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home` |
| `<DevEco-Studio Path>` | DevEco Studio 安装路径 | macOS：`/Applications/DevEco-Studio.app/Contents`；Windows：`D:\Huawei\DevEco Studio` |
| `<flutter_flutter path>` | Flutter OH 源码路径 | `/Users/<用户名>/ohos/flutter_flutter` |

### 4.1 Mac、Linux

### 第一步：确定当前使用的 Shell

打开终端，执行以下命令查看当前 Shell：

```sh
echo $SHELL
```

- 若输出 `/bin/zsh`，编辑 `~/.zshrc`：

  ```sh
  vim ~/.zshrc
  ```

- 若输出 `/bin/bash`，编辑 `~/.bash_profile`（Linux 一般为 `~/.bashrc`）：

  ```sh
  vim ~/.bash_profile
  ```

### 第二步：在文件中添加环境变量

```sh
# 配置 JDK 17
export JAVA_HOME=<JAVA_HOME path>
export PATH=$JAVA_HOME/bin:$PATH

# 配置 OpenHarmony SDK、ohpm、hvigor、node（TOOL_HOME 即 DevEco Studio 安装路径）
export TOOL_HOME=<DevEco-Studio Path>
export DEVECO_SDK_HOME=$TOOL_HOME/sdk
export PATH=$TOOL_HOME/tools/ohpm/bin:$PATH
export PATH=$TOOL_HOME/tools/hvigor/bin:$PATH
export PATH=$TOOL_HOME/tools/node/bin:$PATH
export HDC_HOME=$TOOL_HOME/sdk/default/openharmony/toolchains    # （可选）hdc 指令

# 配置 Flutter
export PUB_CACHE=~/Pub/Cache
export PATH=<flutter_flutter path>/bin:$PATH
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
# （可选）指定 Flutter OH 仓库地址，避免后续创建工程时因默认 Gitee 地址不一致而报错
export FLUTTER_GIT_URL=https://atomgit.com/CPF-Flutter/flutter_flutter.git
```

### 第三步：保存并退出

按 `Esc` 键进入命令模式，输入 `:wq` 后按 `Enter` 键保存并退出编辑器。

### 第四步：应用配置

执行以下命令重新加载配置使其立即生效（按步骤 1 中所用的 Shell 选择对应命令）：

```sh
source ~/.zshrc         # zsh
source ~/.bash_profile  # bash（macOS）；Linux 一般为 source ~/.bashrc
```

### 4.2 Windows

### 第一步：打开系统环境变量设置

通过以下路径访问环境变量配置界面：

**此电脑**（右键）→ **属性** → **高级系统设置** → **高级** 选项卡 → **环境变量**

### 第二步：配置环境变量

在**环境变量**面板，添加以下配置（均建议设为「系统变量」）：

① 配置 `JDK`

| 变量        | 值                | 作用域       |
| ----------- | ----------------- | ------------ |
| `JAVA_HOME` | `<JAVA_HOME path>` | 系统变量     |
| `Path`      | `%JAVA_HOME%\bin` | 追加到现有值 |

② 配置 `OpenHarmony SDK`、`ohpm`、`hvigor`、`node`（`TOOL_HOME` 即 DevEco Studio 安装路径）

| 变量              | 值                             | 作用域   |
| ----------------- | ------------------------------ | -------- |
| `TOOL_HOME`       | `<DevEco-Studio Path>`         | 系统变量 |
| `DEVECO_SDK_HOME` | `%TOOL_HOME%\sdk`              | 系统变量 |
| `Path`            | `%TOOL_HOME%\tools\ohpm\bin`   | 系统变量 |
| `Path`            | `%TOOL_HOME%\tools\hvigor\bin` | 系统变量 |
| `Path`            | `%TOOL_HOME%\tools\node`       | 系统变量 |

③ 配置 `Flutter`

| 变量                       | 值                              | 作用域   |
| -------------------------- | ------------------------------- | -------- |
| `Path`                     | `<flutter_flutter path>\bin`   | 系统变量 |
| `PUB_CACHE`                | `%USERPROFILE%\Pub\Cache`      | 系统变量 |
| `PUB_HOSTED_URL`           | `https://pub.flutter-io.cn`     | 系统变量 |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` | 系统变量 |
| `FLUTTER_GIT_URL`          | `https://atomgit.com/CPF-Flutter/flutter_flutter.git` | 系统变量（可选） |

配置完成后，**重启终端/命令行窗口**使环境变量生效。

## 验证环境

请确保已按“获取 Flutter OH 源码”一节通过 Git 克隆获取源码，再执行本节验证。

依次执行以下命令，逐项确认工具链是否就绪：

```sh
# 1) 验证 JDK
java -version

# 2) 验证 hdc（设备调试工具）
hdc -v

# 3) 验证 ohpm（OpenHarmony 包管理）
ohpm -v

# 4) 验证 hvigor（构建工具）
hvigorw -v

# 5) 验证 Flutter 与 OpenHarmony SDK 联合配置
flutter doctor -v
```

`flutter doctor -v` 输出中，**Flutter** 与 **HarmonyOS toolchain** 两项均应为 `[√]` 标识。若提示缺少环境，按提示补上相应配置即可。

![](../media/getting-started/doctor1.png)

## 安装与运行模拟器（可选）

若无 OpenHarmony 真机，可在 DevEco Studio 中下载并使用模拟器。

> **限制再次提示**：模拟器当前支持 macOS（arm64）与 Windows（x64），暂不支持 macOS（x86）。详见 [前置条件](#前置条件)。

### 6.1 安装模拟器

在 DevEco Studio 中依次完成以下步骤创建模拟器：

1. 打开设备管理器（Device Manager）。

   ![](../media/getting-started/getting-started-18.png)

2. 点击「新建模拟器」，开始创建模拟器。

   ![](../media/getting-started/getting-started-19.png)

3. 选择设备类型型号（如 Phone）并下载系统镜像。

   ![](../media/getting-started/getting-started-20.png)

   ![](../media/getting-started/getting-started-22.png)

4. 配置模拟器名称等参数。

   ![](../media/getting-started/getting-started-23.png)

5. 完成创建。

   ![](../media/getting-started/getting-started-202608251043.png)

### 6.2 启动模拟器

在设备管理器中点击启动模拟器：

![](../media/getting-started/getting-started-29.png)



![](../media/getting-started/getting-started-20260825104627.png)

模拟器运行效果：

![](../media/getting-started/getting-started-31.png)

## 创建并运行 Flutter 工程

### 7.1 创建与编译工程

```sh
# 1) 创建工程（方式一）：仅创建 ohos 平台
flutter create --platforms ohos <projectName>

# 1) 创建工程（方式二）：创建 android、ios、ohos 三个平台
flutter create <projectName>

# 2) 进入工程根目录编译 hap 包
flutter build hap --debug   # 调试版本
flutter build hap --release # 正式版本
```

编译产物位于 `${projectName}/build/ohos/hap/entry-default-signed.hap`

### 7.2 运行到真机

#### 7.2.1 项目签名

在运行到真机之前，需要对项目进行签名：

在 DevEco Studio 中打开 **File → Project Structure → Signing Configs**，勾选「Automatically generate signature」自动生成签名。

![](../media/getting-started/sign01.png)

#### 7.2.2 运行到真机

通过 `flutter devices` 指令发现真机设备之后，获取 device-id。

方式一：进入项目目录指定构建方式编译 hap 包并安装到 OpenHarmony 手机中。

```sh
flutter run --debug -d <deviceId>
```

方式二：进入工程根目录编译 hap 包，然后安装到 OpenHarmony 手机中。

```sh
# 1) 编译 hap 包
flutter build hap --debug
# 2) 安装到指定设备
hdc -t <deviceId> install <hap file path>
```

方式三：使用 DevEco Studio 选择设备为真机，点击启动。

![](../media/getting-started/getting-started-27.png)

## 常见问题

### 执行 `flutter doctor -v` 时出现 No Hmos SDK 报错？

执行 `flutter doctor -v` 时出现：

```log
[!] No Hmos SDK found. Try setting the HOS_SDK_HOME environment variable.
```

**解决方案**：

1. 获取 DevEco Studio 工具自带的 SDK 路径，例如：
   - macOS：`/Applications/DevEco-Studio.app/Contents/sdk`
   - Windows：`D:\Huawei\DevEco Studio\sdk`

2. 执行以下命令，配置 Flutter 的 ohos-sdk 路径：

   ```sh
   flutter config --ohos-sdk "<SDK path>"
   # 示例（Windows）：
   # flutter config --ohos-sdk "D:\Huawei\DevEco Studio\sdk"
   ```

3. 执行以下命令，检查配置是否成功：

   ```sh
   flutter config --list
   ```

   输出包含如下内容即表示配置成功：

```log
All Settings:
  ohos-sdk: D:\Huawei\DevEco Studio\sdk
```

### 无法创建模拟器？

请使用已完成**实名制认证**的账号进行登录签名后重试。

### macOS x86 架构无法运行模拟器？

由于模拟器当前支持 macOS（arm64）与 Windows（x64），暂不支持 macOS（x86）架构，因此在 macOS x86 上无法运行模拟器。建议使用真机或更换为 macOS arm64 / Windows x64 架构设备。
