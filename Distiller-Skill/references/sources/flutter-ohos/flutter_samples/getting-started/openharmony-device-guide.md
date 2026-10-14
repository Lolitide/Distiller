# OpenHarmony 设备运行指导

本文档介绍如何将 Flutter OH 应用编译、安装并运行到 OpenHarmony 设备上，涵盖设备连接、工程创建、签名配置、构建与安装运行的完整流程。

## 第一步：连接并发现设备

### 1.1 进入开发者模式并开启 USB 调试

使用 USB 线连接真机与电脑，在设备「设置」中连续点击版本号进入开发者模式，并在「开发者选项」中开启 USB 调试。

### 1.2 通过 hdc 确认设备连接

通过 `hdc` 确认设备已连接：

```bash
hdc list targets
```

预期输出设备序列号，例如：

```log
700000xxx
```

> 若无输出，请检查 USB 连接、调试模式是否开启，并确认 `hdc` 所在的 SDK `toolchains` 目录已加入 `PATH`。

### 1.3 通过 Flutter 确认设备识别

随后用 Flutter 确认设备已被识别：

```bash
flutter devices
```

不同设备类型的预期输出示例：

```log
# 手机
9CN0123608000xxx (mobile) • 9CN0123608000xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26

# 平板
ABC0123456789xxx (tablet) • ABC0123456789xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26

# PC/二合一
DEF0123456789xxx (desktop) • DEF0123456789xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26
```

## 第二步：创建 Flutter 工程

```bash
# 方式一：仅创建 ohos 平台工程
flutter create --platforms ohos <projectName>

# 方式二：同时创建 android、ios、ohos 多平台工程
flutter create <projectName>
```

创建完成后，工程根目录下会生成 `ohos/` 目录，其中包含 `entry/`、`AppScope/`、`build-profile.json5` 等 OpenHarmony 工程文件。

## 第三步：配置目标设备类型（module.json5）

OpenHarmony 工程通过 `module.json5` 中的 `deviceTypes` 字段声明应用支持的设备类型。新建工程默认仅包含 `phone`，若要运行到平板或 PC，需要手动补充对应的设备类型。

文件路径：`<projectName>/ohos/entry/src/main/module.json5`

不同设备类型对应的 `deviceTypes` 取值：

| 设备类型       | deviceTypes |
| -------------- | ----------------- |
| 手机/折叠屏       | `phone`           |
| 平板           | `tablet`          |
| PC/二合一      | `2in1`            |

若需同时支持全部设备，将 `deviceTypes` 配置为：

```json5
{
  "module": {
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ]
  }
}
```

## 第四步：配置签名

在运行到真机之前，需要对项目进行签名：

1. 使用 **DevEco Studio** 打开 `<projectName>/ohos` 目录。
2. 点击 **File → Project Structure → Project → SigningConfigs**。
3. 勾选 **Automatically generate signature** 自动生成签名。
4. 点击 **OK** 保存。

## 第五步：构建 HAP 包

进入工程根目录，根据需要选择构建模式：

```bash
cd <projectName>

# Debug 构建（支持热重载，日常开发调试）
flutter build hap --debug

# Release 构建（AOT 编译，体积最小，用于正式发布）
flutter build hap --release
```

构建产物位于 `<projectName>/build/ohos/hap/` 目录下：

| 签名状态 | 产物文件名                   |
| -------- | ---------------------------- |
| 已签名   | `entry-default-signed.hap`   |
| 未签名   | `entry-default-unsigned.hap` |

## 第六步：安装并运行到真机

任选以下方式之一将应用部署到设备：

**方式一：直接运行（推荐，开发调试最便捷）**

无需手动构建 HAP，直接使用 `flutter run` 编译、安装并启动：

```bash
# Debug 模式运行
flutter run --debug -d <deviceId>

# Release 模式运行
flutter run --release -d <deviceId>
```

**方式二：手动安装 HAP 包**

先按第五步构建 HAP 包，再通过 `hdc` 安装：

```bash
hdc -t <deviceId> install <projectName>/build/ohos/hap/entry-default-signed.hap
```

安装完成后，在设备桌面点击应用图标启动，或通过以下命令拉起：

```bash
hdc shell aa start -a EntryAbility -b <bundleName>
```

**方式三：使用 DevEco Studio 运行**

使用 DevEco Studio 打开 `ohos` 目录，在设备列表中选择已连接的真机，点击运行按钮即可自动编译、安装并启动。
