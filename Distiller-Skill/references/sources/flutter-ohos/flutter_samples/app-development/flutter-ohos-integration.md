# Flutter 应用 OpenHarmony 接入指导

本文档介绍如何将已有 Flutter 应用（已支持 iOS/Android）扩展支持 OpenHarmony 平台：在现有项目中添加 ohos 目录，保持多端代码复用。

---

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)
- 已有可正常编译运行的 Flutter 应用工程（已支持 iOS/Android）

---

## 开始适配

### 1. 备份现有项目

```bash
cp -r your_flutter_project your_flutter_project_backup
```

### 2. 添加 OpenHarmony 支持

进入你的 Flutter 项目目录，执行以下命令：

```bash
cd your_flutter_project

# 为现有项目添加 ohos 平台支持
flutter create --platforms ohos .
```

执行成功后，项目新增 ohos 目录，结构如下：

```text
your_flutter_project/
├── android/              # Android 平台代码
├── ios/                  # iOS 平台代码
├── ohos/                 # OpenHarmony 平台代码（新增）
│   ├── build-profile.json5
│   ├── hvigorfile.ts
│   ├── local.properties
│   ├── entry/            # 主入口模块
│   │   ├── build-profile.json5
│   │   ├── hvigorfile.ts
│   │   ├── oh-package.json5
│   │   └── src/
│   │       ├── main/
│   │       │   ├── ets/
│   │       │   │   ├── entryability/
│   │       │   │   │   └── EntryAbility.ets      # 主入口 Ability
│   │       │   │   └── pages/
│   │       │   │       └── Index.ets             # 主页面
│   │       │   └── resources/                    # 资源文件
│   │       └── ohosTest/                         # 测试代码
│   └── ohos/           # Flutter 引擎模块
├── lib/               # Dart 业务代码（多端复用）
├── test/
├── pubspec.yaml
└── ...
```

### 3. 配置项目签名

使用 DevEco Studio 打开 `ohos` 目录：

1. 选择 **File → Project Structure → Project → Signing Configs**
2. 勾选 **Automatically generate signature** 自动生成签名
3. 点击 **OK** 保存

### 4. 适配 pubspec.yaml

- 根据目标 Flutter OH 版本调整 SDK 约束：

```yaml
# Flutter 3.27.4-ohos 版本
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.27.0"

# Flutter 3.22.0-ohos 版本
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.22.0"
```

- 获取依赖

```bash
flutter clean
flutter pub get
```

---

## 三方库适配

> 适配前，请先查阅 [OpenHarmony 平台已适配三方库](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md)，检查项目依赖的三方库是否已适配 OpenHarmony 平台。若使用到的三方库未适配，可提交 [issue](https://gitcode.com/org/CPF-Flutter/issues) 反馈。

### 1. 替换为 OpenHarmony 兼容版本

```yaml
dependencies:
  # 原配置（Pub 官方版本，不支持 OpenHarmony）
  # path_provider: ^2.1.0
  
  # 新配置（OpenHarmony 适配版本）
  path_provider:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/path_provider/path_provider"
      ref: "br_path_provider-v2.1.5_ohos"  # 根据实际版本调整
  
  shared_preferences:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/shared_preferences/shared_preferences"
      ref: "br_shared_preferences-v2.5.4_ohos"
  
  url_launcher:
    git:
      url: "https://gitcode.com/CPF-Flutter/flutter_packages.git"
      path: "packages/url_launcher/url_launcher"
      ref: "br_url_launcher-v6.3.2_ohos"
```

### 2. 需自行适配的插件

如果项目使用了自研或尚未适配 OpenHarmony 的插件，需要为其补充 OpenHarmony 平台实现。

适配指导请参考：[开发 Flutter Plugin](../plugin-and-package/developing-plugin.md)

### 3. 平台判断代码适配

如果代码中存在平台判断，需补充 OpenHarmony 分支。推荐使用 `defaultTargetPlatform`，避免使用 `Platform.isOhos`：

```dart
import 'package:flutter/foundation.dart';

// 原代码
if (defaultTargetPlatform == TargetPlatform.android) {
  // Android 特定逻辑
} else if (defaultTargetPlatform == TargetPlatform.iOS) {
  // iOS 特定逻辑
}

// 适配后 - 补充 OpenHarmony 平台判断
if (defaultTargetPlatform == TargetPlatform.android) {
  // Android 特定逻辑
} else if (defaultTargetPlatform == TargetPlatform.iOS) {
  // iOS 特定逻辑
} else if (defaultTargetPlatform == TargetPlatform.ohos) {
  // OpenHarmony 特定逻辑
}
```

若代码还需用上游社区 Flutter SDK 编译，`defaultTargetPlatform == TargetPlatform.ohos` 会因该枚举值不存在而报错；改用 `Platform.operatingSystem == 'ohos'`（非 `Platform.isOhos`）即可两端编译：

```dart
import 'dart:io';

if (Platform.operatingSystem == 'ohos') {
  // OpenHarmony 特定逻辑
}
```

### 4. 纯 Dart 三方库

通常纯 Dart 三方库无需修改即可在 OpenHarmony 上运行。但如果代码中有平台判断，还需参照上面 **第 3 步** 补充 OpenHarmony 平台判断。

---

## 构建与运行

### 1. 连接设备

```bash
# 查看连接的设备
flutter devices

# 预期输出示例
# 9CN0123608000xxx (mobile) • 9CN0123608000xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26
```

### 2. 运行调试

```bash
# 运行到 OpenHarmony 设备
flutter run -d <device_id>

# 或使用简写（如果只有一台设备）
flutter run
```

### 3. 构建 HAP 包

```bash
# 调试版本
flutter build hap --debug

# 正式版本
flutter build hap --release
```

### 4. 安装 HAP 包

```bash
# 使用 hdc 工具安装
hdc install build\ohos\hap\entry-default-signed.hap

# 或指定设备
hdc -t <device_id> install build\ohos\hap\entry-default-signed.hap
```

---

## 问题交流

- 问题反馈：欢迎在 [Flutter 框架仓库](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) 以及各 Flutter 三方库仓库提交 issue。

