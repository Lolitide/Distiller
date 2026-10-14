# Flutter OH Development Environment Setup Guide

This guide describes how to set up the development environment for **Flutter OH** (the Flutter OpenHarmony adaptation) from scratch, and to verify end to end that a Flutter project can be built and run on an OpenHarmony real device or emulator.

## Prerequisites

Before you start, confirm that the following conditions are met:

- **Operating system**: macOS, Linux, or Windows. macOS users should first run `uname -m` in a terminal to determine the system architecture (`x86_64` indicates the x86-64 architecture, and `arm64` indicates the ARM64 architecture), and then choose the corresponding development suite and image.
- **Emulator limitation**: The DevEco Studio emulator currently supports **macOS (arm64)** and **Windows (x64)**, and does not support the macOS (x86) architecture for now. If you do not have a supported device, prepare an OpenHarmony real device.
- **Huawei account**: To use the emulator, prepare a Huawei account that has completed **real-name authentication**.

## Install the Prerequisite Dependency: JDK 17 or Later

The OpenHarmony SDK has a Java environment dependency, so install JDK 17 or a later version first.

1. Go to the [Oracle website](https://www.oracle.com/cn/java/technologies/downloads/#java17) or the OpenJDK website to download JDK 17 or later, and follow the installation wizard to complete the installation.
2. After the installation is complete, run the following command to verify it. If the version information is printed correctly, the installation succeeded:

   ```sh
   java -version
   ```


## Download and Install DevEco Studio

DevEco Studio is the official OpenHarmony IDE. After installation, it comes with the SDK and toolchains such as ohpm, hvigor, and node.

### 2.1 Download

Go to [Huawei Developer Alliance - Tool Download - DevEco Studio](https://developer.huawei.com/consumer/cn/download/) and download the latest version of DevEco Studio for your computer's operating system.

![](../media/getting-started/getting-started-17.png)

### 2.2 Install

After extracting the development suite archive, run the DevEco Studio installer and follow the installation wizard to complete the installation.

- macOS default path: `/Applications/DevEco-Studio.app/Contents`
- Windows default path: for example, `D:\Huawei\DevEco Studio`

## Obtain the Flutter OH Source Code

Obtain the source code of [Flutter OH](https://atomgit.com/CPF-Flutter/flutter_flutter). For the selection of version branches and tags, see [Flutter-OH Version Evolution Plan and Branch Strategy](https://atomgit.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md).

The Flutter OH source code must be obtained by cloning it with Git.

### Obtain the Source Code by Cloning with Git

This applies when Git is installed and your network can access AtomGit. After cloning, you can switch branches and pull updates at any time.

   ```sh
   # 1) Clone the Flutter OH source code
   git clone https://atomgit.com/CPF-Flutter/flutter_flutter.git
   # 2) Switch to the dev branch (or select the corresponding tag according to the version mapping table)
   git checkout -b dev origin/dev
   ```

## Configure Environment Variables

Before configuration, prepare the following paths (recorded in the previous steps):

| Placeholder | Meaning | Example |
| ------ | ---- | ---- |
| `<JAVA_HOME path>` | JDK installation path | macOS: `/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home` |
| `<DevEco-Studio Path>` | DevEco Studio installation path | macOS: `/Applications/DevEco-Studio.app/Contents`; Windows: `D:\Huawei\DevEco Studio` |
| `<flutter_flutter path>` | Flutter OH source code path | `/Users/<username>/ohos/flutter_flutter` |

### 4.1 Mac, Linux

### Step 1: Determine the Current Shell

Open a terminal and run the following command to check the current shell:

```sh
echo $SHELL
```

- If the output is `/bin/zsh`, edit `~/.zshrc`:

  ```sh
  vim ~/.zshrc
  ```

- If the output is `/bin/bash`, edit `~/.bash_profile` (on Linux it is usually `~/.bashrc`):

  ```sh
  vim ~/.bash_profile
  ```

### Step 2: Add Environment Variables to the File

```sh
# Configure JDK 17
export JAVA_HOME=<JAVA_HOME path>
export PATH=$JAVA_HOME/bin:$PATH

# Configure the OpenHarmony SDK, ohpm, hvigor, and node (TOOL_HOME is the DevEco Studio installation path)
export TOOL_HOME=<DevEco-Studio Path>
export DEVECO_SDK_HOME=$TOOL_HOME/sdk
export PATH=$TOOL_HOME/tools/ohpm/bin:$PATH
export PATH=$TOOL_HOME/tools/hvigor/bin:$PATH
export PATH=$TOOL_HOME/tools/node/bin:$PATH
export HDC_HOME=$TOOL_HOME/sdk/default/openharmony/toolchains    # (Optional) hdc commands

# Configure Flutter
export PUB_CACHE=~/Pub/Cache
export PATH=<flutter_flutter path>/bin:$PATH
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
# (Optional) Specify the Flutter OH repository URL to avoid errors caused by a mismatched default Gitee address when creating projects later
export FLUTTER_GIT_URL=https://atomgit.com/CPF-Flutter/flutter_flutter.git
```

### Step 3: Save and Exit

Press `Esc` to enter command mode, type `:wq`, and then press `Enter` to save the file and exit the editor.

### Step 4: Apply the Configuration

Run the following command to reload the configuration and make it take effect immediately (choose the command for the shell used in step 1):

```sh
source ~/.zshrc         # zsh
source ~/.bash_profile  # bash (macOS); on Linux it is usually source ~/.bashrc
```

### 4.2 Windows

### Step 1: Open the System Environment Variables Settings

Access the environment variable configuration panel through the following path:

**This PC** (right-click) → **Properties** → **Advanced system settings** → **Advanced** tab → **Environment Variables**

### Step 2: Configure Environment Variables

In the **Environment Variables** panel, add the following configuration (it is recommended to set all of them as **system variables**):

① Configure `JDK`

| Variable        | Value                | Scope       |
| ----------- | ----------------- | ------------ |
| `JAVA_HOME` | `<JAVA_HOME path>` | System variable |
| `Path`      | `%JAVA_HOME%\bin` | Append to the existing value |

② Configure the `OpenHarmony SDK`, `ohpm`, `hvigor`, and `node` (`TOOL_HOME` is the DevEco Studio installation path)

| Variable              | Value                             | Scope   |
| ----------------- | ------------------------------ | -------- |
| `TOOL_HOME`       | `<DevEco-Studio Path>`         | System variable |
| `DEVECO_SDK_HOME` | `%TOOL_HOME%\sdk`              | System variable |
| `Path`            | `%TOOL_HOME%\tools\ohpm\bin`   | System variable |
| `Path`            | `%TOOL_HOME%\tools\hvigor\bin` | System variable |
| `Path`            | `%TOOL_HOME%\tools\node`       | System variable |

③ Configure `Flutter`

| Variable                       | Value                              | Scope   |
| -------------------------- | ------------------------------- | -------- |
| `Path`                     | `<flutter_flutter path>\bin`   | System variable |
| `PUB_CACHE`                | `%USERPROFILE%\Pub\Cache`      | System variable |
| `PUB_HOSTED_URL`           | `https://pub.flutter-io.cn`     | System variable |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` | System variable |
| `FLUTTER_GIT_URL`          | `https://atomgit.com/CPF-Flutter/flutter_flutter.git` | System variable (optional) |

After the configuration is complete, **restart the terminal/command line window** for the environment variables to take effect.

## Verify the Environment

Make sure you have obtained the source code by cloning it with Git as described in "Obtain the Flutter OH Source Code" before running the verification in this section.

Run the following commands in sequence and confirm item by item that the toolchain is ready:

```sh
# 1) Verify the JDK
java -version

# 2) Verify hdc (device debugging tool)
hdc -v

# 3) Verify ohpm (OpenHarmony package management)
ohpm -v

# 4) Verify hvigor (build tool)
hvigorw -v

# 5) Verify the combined Flutter and OpenHarmony SDK configuration
flutter doctor -v
```

In the `flutter doctor -v` output, both **Flutter** and **HarmonyOS toolchain** should show the `[√]` mark. If it reports a missing environment, simply follow the prompts to add the corresponding configuration.

![](../media/getting-started/doctor1.png)

## Install and Run an Emulator (Optional)

If you do not have an OpenHarmony real device, you can download and use an emulator in DevEco Studio.

> **Limitation reminder**: The emulator currently supports macOS (arm64) and Windows (x64), and does not support macOS (x86). See [Prerequisites](#prerequisites).

### 6.1 Install the Emulator

Complete the following steps in DevEco Studio to create an emulator:

1. Open Device Manager.

   ![](../media/getting-started/getting-started-18.png)

2. Click "New Emulator" to start creating an emulator.

   ![](../media/getting-started/getting-started-19.png)

3. Select the device type and model (for example, Phone) and download the system image.

   ![](../media/getting-started/getting-started-20.png)

   ![](../media/getting-started/getting-started-22.png)

4. Configure parameters such as the emulator name.

   ![](../media/getting-started/getting-started-23.png)

5. Finish the creation.

   ![](../media/getting-started/getting-started-202608251043.png)

### 6.2 Start the Emulator

In Device Manager, click to start the emulator:

![](../media/getting-started/getting-started-29.png)



![](../media/getting-started/getting-started-20260825104627.png)

The running emulator:

![](../media/getting-started/getting-started-31.png)

## Create and Run a Flutter Project

### 7.1 Create and Build the Project

```sh
# 1) Create a project (option 1): create only the ohos platform
flutter create --platforms ohos <projectName>

# 1) Create a project (option 2): create all three platforms: android, ios, and ohos
flutter create <projectName>

# 2) Go to the project root directory and build the HAP package
flutter build hap --debug   # Debug version
flutter build hap --release # Release version
```

The build artifact is located at `${projectName}/build/ohos/hap/entry-default-signed.hap`

### 7.2 Run on a Real Device

#### 7.2.1 Sign the Project

Before running on a real device, you need to sign the project:

In DevEco Studio, open **File → Project Structure → Signing Configs**, and select "Automatically generate signature" to generate the signature automatically.

![](../media/getting-started/sign01.png)

#### 7.2.2 Run on a Real Device

After the real device is discovered with the `flutter devices` command, obtain the device ID.

Option 1: Go to the project directory, build the HAP package in the specified build mode, and install it on the OpenHarmony phone.

```sh
flutter run --debug -d <deviceId>
```

Option 2: Go to the project root directory, build the HAP package, and then install it on the OpenHarmony phone.

```sh
# 1) Build the HAP package
flutter build hap --debug
# 2) Install it on the specified device
hdc -t <deviceId> install <hap file path>
```

Option 3: Use DevEco Studio to select the real device, and click Run.

![](../media/getting-started/getting-started-27.png)

## FAQ

### What If a No Hmos SDK Error Occurs When Running `flutter doctor -v`?

When running `flutter doctor -v`, the following error appears:

```log
[!] No Hmos SDK found. Try setting the HOS_SDK_HOME environment variable.
```

**Solution**:

1. Obtain the SDK path bundled with the DevEco Studio tools, for example:
   - macOS: `/Applications/DevEco-Studio.app/Contents/sdk`
   - Windows: `D:\Huawei\DevEco Studio\sdk`

2. Run the following command to configure the Flutter ohos-sdk path:

   ```sh
   flutter config --ohos-sdk "<SDK path>"
   # Example (Windows):
   # flutter config --ohos-sdk "D:\Huawei\DevEco Studio\sdk"
   ```

3. Run the following command to check whether the configuration succeeded:

   ```sh
   flutter config --list
   ```

If the output contains the following content, the configuration succeeded:

```log
All Settings:
  ohos-sdk: D:\Huawei\DevEco Studio\sdk
```

### Unable to Create an Emulator?

Sign in with an account that has completed **real-name authentication** and try again.

### Unable to Run the Emulator on the macOS x86 Architecture?

Because the emulator currently supports macOS (arm64) and Windows (x64) but not the macOS (x86) architecture, it cannot run on macOS x86. It is recommended to use a real device or switch to a macOS arm64 / Windows x64 device.
