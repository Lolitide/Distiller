# 如何使用混合开发 module

本文介绍如何在 OpenHarmony 工程中引用  `flutter_module` 

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)。
- 已使用 DevEco Studio 创建 OpenHarmony 原生工程。

## 准备 flutter_module 工程

### 第一步：创建 flutter_module

```bash
# 在宿主工程同级目录下创建 Flutter 子模块工程
flutter create -t module flutter_module
```

### 第二步：构建产物

```bash
cd flutter_module
# 生成 .ohos 工程结构与 HAR 产物
flutter build har --debug
cd -
```

> [!NOTE]
>
> HAR 依赖方式消费其中生成的 HAR 产物（位于 `flutter_module/build/ohos/har/debug/`，release 在 `release/`）；源码依赖方式仅消费生成的 `.ohos` 工程结构。

### 第三步：拷贝入口文件到宿主

将 `flutter_module` 生成的 `EntryAbility` 与默认首页拷贝到宿主工程，作为后续加载 Flutter 页面的入口：

```bash
cp flutter_module/.ohos/entry/src/main/ets/entryability/EntryAbility.ets MyApplication/entry/src/main/ets/entryability/EntryAbility.ets
cp flutter_module/.ohos/entry/src/main/ets/pages/Index.ets MyApplication/entry/src/main/ets/pages/Index.ets
```

## 集成方式

OpenHarmony 工程引用 `flutter_module` 有两种方式，按场景选择：

| 方式 | 适用场景 | 改源码是否即时生效 |
|------|---------|------------------|
| HAR 产物依赖 | 稳定发布、module 与宿主分离维护 | 否，需重新构建并替换 HAR |
| 源码依赖（推荐） | 开发联调、频繁改动 module / 插件 | 是，重新运行宿主即生效 |

### 方式一：引用 HAR 产物

#### 第一步：复制 HAR 文件

将构建产物中的 HAR 文件统一拷贝到宿主工程根路径 `har/` 目录：

```bash
cp -r flutter_module/build/ohos/har/debug/* MyApplication/har/
```

> [!WARNING]
>
> 各模块单独引用 HAR 而不统一存放至 `har/` 目录，会导致重复打包、包体积增大。务必统一放到 `har/` 目录通过 `overrides` 引用。

#### 第二步：配置 oh-package.json5

在 `MyApplication/oh-package.json5` 的 `overrides` 中引用 HAR（以 debug 为例，release 将文件名后缀 `_debug` 替换为 `_release`）：

```json5
{
  "overrides": {
    "@ohos/flutter_ohos": "file:./har/flutter_embedding_debug.har",
    "flutter_native_arm64_v8a": "file:./har/arm64_v8a_debug.har",
    "@ohos/flutter_module": "file:./har/flutter_module.har"
  }
}
```

并在 `entry/oh-package.json5` 的 `dependencies` 中声明（不指定版本，由 `overrides` 统一解析）：

```json5
{
  "dependencies": {
    "@ohos/flutter_ohos": "",
    "flutter_native_arm64_v8a": "",
    "@ohos/flutter_module": ""
  }
}
```

#### 第三步：配置签名并运行

在 DevEco Studio 中配置 `MyApplication` 签名后运行。签名与安装步骤参见 [OpenHarmony 设备运行指导](../getting-started/openharmony-device-guide.md)。

### 方式二：源码依赖（推荐）

宿主通过 hvigor 插件 `injectNativeModules` 直接编译 `flutter_module` 及各插件 `ohos/` 源码，改源码即生效，免去反复构建与拷贝 HAR。对齐 Android / iOS Add-to-App 的 `:flutter` 子模块 include 机制。

#### 第一步：在宿主注册 hvigor 插件

在宿主 `hvigorconfig.ts`（不存在则新建）调用 `injectNativeModules`，并在 `hvigorfile.ts` 注册 `flutterHvigorPlugin`，路径指向 `flutter_module` 的 `.ohos/include_flutter`：

```ts
// hvigorconfig.ts
import { injectNativeModules, getFlutterProjectPath } from './path/flutter_module/.ohos/include_flutter';

injectNativeModules(__dirname, getFlutterProjectPath(), 1)
```

```ts
// hvigorfile.ts
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { flutterHvigorPlugin, getFlutterProjectPath } from './path/flutter_module/.ohos/include_flutter';

export default {
  system: appTasks,
  plugins:[flutterHvigorPlugin(getFlutterProjectPath(), 1)]
}
```

#### 第二步：清理旧配置

- `MyApplication/build-profile.json5`：移除 `flutter_module` 模块声明（由插件动态注入）。
- `MyApplication/oh-package.json5`：移除 `dependencies` 与 `overrides` 中的 flutter 相关依赖（如不存在则无需处理）。

#### 第三步：声明 entry 依赖

在 `entry/oh-package.json5` 的 `dependencies` 中添加（空字符串，不指定版本 / 路径）：

```json5
{
  "dependencies": {
    "@ohos/flutter_ohos": "",
    "@ohos/flutter_module": ""
  }
}
```

> [!NOTE]
>
> 插件源码由 `injectNativeModules` 在构建期注入，无需在 `dependencies` 中声明；仅当本模块直接调用某插件 API 时才追加该插件依赖，如 `"plugin_x": ""`。

> [!WARNING]
>
> 本步声明的两项依赖是入口引用 `@ohos/flutter_module` / `@ohos/flutter_ohos` 的解析前提，缺失会导致编译报错「找不到 '@ohos/flutter_module'」。这两项并非远端仓库包，而是 hvigor 插件 `injectNativeModules` 在构建期通过 `includeNode` 注入的本地源码节点，因此**不要单独执行 `ohpm install` 刷新依赖**——ohpm 不经过 hvigor，看不到注入的本地节点，会去远端仓库查找并返回 404。请统一使用 DevEco Studio 的 **Sync Now** 或 `hvigorw assembleHap` 触发依赖解析。

#### 第四步：配置签名并运行

在 DevEco Studio 中配置签名后运行。源码变更后的重建流程见 [构建与验证](../app-development/hvigor-plugin-build.md#构建与验证)。

<details>
<summary>早期手动拷贝源码方式（legacy，不推荐）</summary>

早期版本可通过手动拷贝 `flutter_module` 源码目录、在 `build-profile.json5` 的 `modules` 注册模块、并以 `./flutter_module` 路径在 `oh-package.json5` 引用实现源码依赖。该方式配置繁琐、改源码需重复拷贝，建议改用上述 hvigor 插件方式。

</details>

## 验证流程

1. 在 DevEco Studio 中执行 `Sync Now`，或在宿主工程根目录执行 `ohpm install`（**源码依赖方式请勿单独执行 `ohpm install`**，改用 `Sync Now` 或 `hvigorw`，原因见方式二·第三步）。
2. 配置签名后运行；或在宿主工程目录执行：

   ```bash
   hvigorw assembleHap --no-daemon -p product=default -p buildMode=debug
   ```

3. 应用启动后能正常进入 Flutter 页面，即集成成功。

## 常见问题

### 问题：集成后 entry 下没有生成 oh_modules 缓存目录

需在项目根路径执行 `ohpm install`，而不是在 `entry` 目录下执行。

### 问题：编译报错「找不到 '@ohos/flutter_module'」

源码依赖方式下 `@ohos/flutter_module` 由 hvigor 插件 `injectNativeModules` 在构建期通过 `includeNode` 注入为本地源码节点，远端仓库不存在该包。出现该报错通常是以下原因之一：

- `entry/oh-package.json5` 的 `dependencies` 未声明 `"@ohos/flutter_module": ""`（见方式二·第三步），导致该包未链接进 `entry/oh_modules`；补上后重新构建即可。
- 单独执行了 `ohpm install` 刷新依赖：ohpm 不经过 hvigor，看不到注入的本地节点，会去远端仓库查找并返回 404。请改用 DevEco Studio 的 **Sync Now** 或 `hvigorw assembleHap` 触发依赖解析。

> [!NOTE]
>
> HAR 依赖方式下 `@ohos/flutter_module` 来自 `har/` 目录的 HAR 产物，`ohpm install` 可正常解析；本条仅针对源码依赖方式。

### 问题：修改 flutter_module 代码后没有生效

- **源码依赖方式**：Dart 改动后在 `flutter_module` 目录执行 `flutter pub get` 刷新 `.ohos` 注入产物，再重新运行宿主工程。
- **HAR 依赖方式**：在 `flutter_module` 目录重新执行 `flutter build har --debug`（或 `--release`），将新生成 HAR 拷贝至 `har/` 目录替换旧文件，并在 DevEco Studio 中执行 `Sync Now` 刷新依赖。

### 问题：HAR 依赖与源码依赖能否混用

不建议混用。源码依赖由插件注入 module 与插件源码，若同时在 `oh-package.json5` 手动引用 HAR 会产生重复符号或版本冲突。两种方式二选一。
