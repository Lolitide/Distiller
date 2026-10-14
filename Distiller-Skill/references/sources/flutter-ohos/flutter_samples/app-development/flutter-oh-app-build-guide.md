# Flutter OH 应用构建与运行指导

本文档介绍如何在 OpenHarmony 平台上创建、签名、构建、安装与运行 Flutter 应用，涵盖 debug/profile/release 三种构建模式、Impeller 渲染引擎配置、本地 Engine 构建等内容。

---

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)

---

## 使用步骤

### 第一步：创建应用

```bash
# 方式一：仅创建 ohos 平台工程
flutter create --platforms ohos <projectName>

# 方式二：同时创建 android、ios、ohos 多平台工程
flutter create <projectName>
```

创建完成后，工程根目录下会生成 `ohos/` 目录，关键结构如下：

```text
<projectName>/
├── lib/                    # Dart 业务代码
├── ohos/                   # OpenHarmony 平台代码
│   ├── AppScope/
│   │   └── app.json5       # 应用全局配置（包名、版本等）
│   ├── build-profile.json5  # 构建配置（签名、SDK 版本、构建模式）
│   ├── hvigorfile.ts       # Hvigor 构建脚本
│   ├── hvigorconfig.ts     # Hvigor 插件配置
│   ├── oh-package.json5    # 项目依赖配置
│   └── entry/              # 主入口模块
│       ├── build-profile.json5
│       ├── oh-package.json5
│       └── src/main/
│           ├── ets/        # ArkTS 代码
│           ├── module.json5
│           └── resources/base/profile/
│               └── buildinfo.json5  # Impeller 渲染配置
└── pubspec.yaml
```

---

### 第二步：配置签名

在构建或运行到真机之前，需要对项目进行签名：

1. 使用 **DevEco Studio** 打开 `<projectName>/ohos` 目录
2. 点击 **File → Project Structure → Project → Signing Configs**
3. 勾选 **Automatically generate signature** 自动生成签名
4. 点击 **OK** 保存

---

### 第三步：构建应用

#### 构建模式

| 模式        | 命令参数            | 适用场景       |
| ----------- | ------------------- | -------------- |
| **debug**   | `--debug`           | 日常开发调试   |
| **profile** | `--profile`         | 性能分析与调优 |
| **release** | `--release`（默认） | 正式发布       |

#### 构建命令

```bash
# 进入工程根目录
cd <projectName>

# Debug 构建
flutter build hap --debug

# Profile 构建
flutter build hap --profile

# Release 构建（默认模式）
flutter build hap --release
```

```bash
# 跳过签名，构建未签名 HAP（需手动签名后才能安装到设备）
flutter build hap --release --no-codesign
```

#### 构建产物路径

| 签名状态 | 产物文件名                   | 路径                            |
| -------- | ---------------------------- | ------------------------------- |
| 已签名   | `entry-default-signed.hap`   | `<projectName>/build/ohos/hap/` |
| 未签名   | `entry-default-unsigned.hap` | `<projectName>/build/ohos/hap/` |

#### 指定版本号

默认构建会将 `app.json5` 中的 `versionName` 重置为 `1.0.0`。如需指定版本号，使用以下参数：

```bash
flutter build hap --release --build-name=4.0.3 --build-number=10000
```

| 参数                   | 说明           | 对应 app.json5 字段 |
| ---------------------- | -------------- | ------------------- |
| `--build-name=<x.y.z>` | 用户可见版本号 | `versionName`       |
| `--build-number=<n>`   | 内部版本号     | `versionCode`       |

#### 指定目标架构

默认目标平台为 `ohos-arm64`（真机）。如果调试阶段交替使用了模拟器和真机，可能因缓存架构不匹配导致编译报错，建议显式指定：

```bash
flutter build hap --release --target-platform ohos-arm64
```

| 可选架构     | 说明                        |
| ------------ | --------------------------- |
| `ohos-arm64` | 64 位 ARM，真机默认（推荐） |
| `ohos-arm`   | 32 位 ARM                   |
| `ohos-x64`   | x86_64，模拟器场景          |

---

### 第四步：Impeller 渲染引擎配置

当前 Flutter OH 平台支持 **Impeller**（Vulkan 后端）和 **Skia** 两种渲染模式，默认开启 Impeller。

#### 配置文件位置

```text
ohos/entry/src/main/resources/base/profile/buildinfo.json5
```

#### 配置内容

```json5
{
  "string": [
    {
      "name": "enable_impeller",
      "value": "true"    // "true" 启用 Impeller，"false" 切换为 Skia
    }
  ]
}
```

| 值        | 渲染引擎           | 最低版本           |
| --------- | ------------------ | ------------------ |
| `"true"`  | Impeller（Vulkan） | Flutter OH 3.22.0+ |
| `"false"` | Skia               | Flutter OH 3.7.12+ |

> **注意**：修改配置后需重新构建项目才能生效，仅热重载（Hot Reload）不会切换渲染引擎。

#### 旧工程适配

新建工程默认开启 Impeller。对于旧工程，将上述 `buildinfo.json5` 文件复制到工程对应路径下并修改 `value` 值即可。如果不添加该配置文件，默认开启 Impeller。

---

### 第五步：使用本地 Engine 构建

如需使用自行编译的 Flutter Engine 产物构建应用，需同时指定 Engine 产物路径和 Host Engine 产物路径：

```bash
# 进入工程根目录编译
flutter build hap --target-platform ohos-arm64 --<debug|release|profile> [--local-engine=src/out/<engine产物目录> --local-engine-host=src/out/<engine host目录>/]
```

| 参数                  | 说明                                                         |
| --------------------- | ------------------------------------------------------------ |
| `--target-platform`   | 目标平台                                                     |
| `--local-engine`      | Engine 构建产物名称，相对于 `--local-engine-src-path` 的 `out/` 目录（如 `ohos_release_arm64`） |
| `--local-engine-host` | Host Engine 构建产物名称（如 `host_release`）。默认自动推断，仅在跨平台构建时需手动指定 |

各构建模式对应的 Engine 产物名称（实际名称以 Engine 构建输出目录为准）：

| 构建模式    | `--local-engine`     | `--local-engine-host` |
| ----------- | -------------------- | --------------------- |
| **debug**   | `ohos_debug_arm64`   | `host_debug`          |
| **profile** | `ohos_profile_arm64` | `host_profile`        |
| **release** | `ohos_release_arm64` | `host_release`        |

---

### 第六步：安装与运行

#### 发现设备

```bash
flutter devices
```

预期输出示例：

```log
9CN0123608000xxx (mobile) • 9CN0123608000xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26
```

#### 安装 HAP 包

```bash
# 指定设备安装
hdc -t <device-id> install <hap file path>

# 示例
hdc -t 9CN0123608000xxx install build/ohos/hap/entry-default-signed.hap
```

#### 直接运行

无需手动构建 HAP，可直接使用 `flutter run` 在设备上运行：

```bash
# Debug 模式运行
flutter run --debug -d <device-id>

# Release 模式运行
flutter run --release -d <device-id>

# 使用本地 Engine 运行
flutter run --debug \
  -d <device-id> \
  --local-engine=ohos_debug_arm64 \
  --local-engine-host=host_debug
```

#### 验证构建结果

1. 执行 `flutter devices`，预期列表中出现 ohos 设备且架构为 `ohos-arm64`。
2. 执行 `flutter build hap --debug`，预期产物 `build/ohos/hap/entry-default-signed.hap` 生成且无 error。
3. `hdc install` 安装后启动应用，预期首帧正常渲染、控制台无报错。
