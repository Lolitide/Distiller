# Flutter OH 升级指导

本升级指导适用于所有基于 OpenHarmony 适配的 Flutter 版本，帮助开发者在进行 Flutter OH 项目升级、迁移或维护时顺利完成版本切换。请根据当前版本和目标版本，按步骤执行升级操作。

> ⚠️ **重要提醒**：Flutter OH **暂未适配 `flutter upgrade` 命令**，直接执行该命令会因拉取官方 Channel 而破坏 OpenHarmony 适配环境并报错。请务必使用本文档所述的 `git clone` / `git checkout` 方式进行版本切换，切勿使用 `flutter upgrade`。

---

## 一. 版本说明

已发布并维护的 OpenHarmony 适配版本，推荐基于版本tag获取稳定版：

| 源社区版本      | OpenHarmony 适配稳定版本              | 版本 tag                                  |
| --------------- | ------------------------------------- | ----------------------------------------- |
| 3.41.9          | 3.41.9-ohos-x.x.x                     | `3.41.10-ohos-x.x.x`                      |
| 3.35.7          | 3.35.8-ohos-x.x.x                     | `3.35.8-ohos-X.X.X`                       |
| 3.27.4          | 3.27.4-ohos-x.x.x                     | `3.27.5-ohos-X.X.X`                       |
| 3.22.0 / 3.22.3 | 3.22.0-ohos-x.x.x / 3.22.3-ohos 1.1.3 | `3.22.1-ohos-X.X.X` / `3.22.4-ohos-x.x.x` |
| 3.7.12          | 3.7.12-ohos-x.x.x                     | `3.7.12-ohos-X.X.X`                       |

> 完整版本与分支策略详见 [版本演进规划与分支策略](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md)；

**关于 SDK 选型的说明**

Flutter-OH 基于源社区 Flutter 的特定版本节点适配 OpenHarmony，适配后的版本分支独立演进，聚焦于鸿蒙端的修复与能力增强，不随源社区后续版本同步更新。

- 鸿蒙端开发：使用适配 OpenHarmony 的 [flutter_flutter](https://gitcode.com/CPF-Flutter/flutter_flutter) SDK。
- 为获取最新社区修复，面向 Android、iOS 端开发时，推荐使用[源社区 Flutter SDK](https://docs.flutter.cn/)。

---

## 二. 升级适用场景

- **小版本升级**：同一 Flutter OH 大版本下的适配版本升级（如 3.27.4-ohos-1.0.0 → 3.27.4-ohos-1.0.3）
- **大版本升级**：跨 Flutter OH 大版本升级（如 3.22.0-ohos → 3.27.4-ohos）

---

## 三. 升级前准备

### 1. 环境检查清单

- **备份项目代码与依赖配置**（`pubspec.yaml`、`pubspec.lock`、整个项目目录）
- **确认目标版本配套环境（[DevEco Studio](https://developer.huawei.com/consumer/cn/download/deveco-studio)、[OpenHarmony SDK](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos)）**
- **查阅目标版本 [Release Note](https://docs.flutter.dev/release/release-notes)**，了解 Breaking Changes 和新特性
- **检查三方库 [OpenHarmony兼容性](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md)**，确认使用的插件支持目标版本

### 2. 获取新版本 SDK

```shell
# 方式1：克隆指定分支
git clone -b {目标分支名} https://gitcode.com/CPF-Flutter/flutter_flutter.git

# 方式2：切换到指定 Tag
git clone https://gitcode.com/CPF-Flutter/flutter_flutter.git
cd flutter_flutter
git checkout {版本Tag}

# 示例：获取 br_3.27.4-ohos-1.0.4 版本
git clone -b br_3.27.4-ohos-1.0.4 https://gitcode.com/CPF-Flutter/flutter_flutter.git
```

---

## 四. 通用升级流程

### 1. 环境验证

```shell
# 验证 Flutter 环境
flutter doctor -v

# 预期输出：
# [✓] Flutter (Channel unknown, 3.27.4-ohos-xxx, ...)
# [✓] OpenHarmony toolchain - develop for OpenHarmony devices
```

### 2. 项目升级步骤

**步骤 1：清理旧版本缓存**

```shell
# 进入旧项目目录
cd your_project

# 清理构建缓存
flutter clean

# 删除全局缓存（切换大版本时建议执行）
flutter pub cache clean

# 删除 flutter SDK 缓存（如有环境变量切换）
rm -rf $FLUTTER_HOME/bin/cache
```

**步骤 2：更新 SDK 引用**

确保使用新版本的 Flutter SDK 执行后续命令：

```shell
# 验证使用的 flutter 版本
flutter --version
```

**步骤 3：更新项目依赖**

```shell
# 更新 pubspec.yaml 中的依赖版本
# 1. 修改 SDK 版本约束
# environment:
#   sdk: '>=3.0.0 <4.0.0'  # 根据目标版本调整

# 2. 更新三方库版本

# 3. 获取依赖
flutter pub get
```

**步骤 4：OpenHarmony平台特定适配**

```shell
# 重新生成 ohos 平台代码（如需要）
flutter create --platforms ohos .

# DevEco Studio 工具打开 ohos 目录
# 签名 File → Project Structure → Project → Signing Configs
```

**步骤 5：编译验证**

```shell
# 调试版本编译
flutter build hap --debug

# 正式版本编译
flutter build hap --release

# 安装到设备
hdc install build/ohos/entry/outputs/default/entry-default-signed.hap
```

---

## 五. 各版本升级注意事项

### 1. 小版本升级

> 同一 Flutter OH 大版本内进行升级

小版本升级通常只需：

1. 拉取最新代码或切换到新 Tag
2. 执行 `flutter clean`
3. 执行 `flutter pub get`
4. 重新编译验证

### 2. 大版本升级

> 跨 Flutter OH 大版本升级

- 检查升级版本的环境配置是否有变化
- 查阅升级版本的兼容性变更说明 [[查看]](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/oh-3.35.7-dev/release-notes/changelog)
- 查阅官方 Flutter 版本新增特性与变更 [[查看]](https://docs.flutter.dev/release/breaking-changes)
- 三方库升级到对应的版本 [[查看]](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md)

---

- 问题反馈：欢迎在 [Flutter框架仓库](https://gitcode.com/CPF-Flutter/flutter_flutter/issues) 以及各个Flutter三方库提交 issue。