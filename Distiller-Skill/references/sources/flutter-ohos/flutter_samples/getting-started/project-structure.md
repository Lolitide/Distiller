# Flutter OH 工程目录结构

本文档说明使用 `flutter create --platforms ohos` 创建的 Flutter OH 工程的目录结构与关键文件职责，帮助开发者快速定位配置、入口代码与依赖产物。涵盖应用级配置、模块构建配置、入口 Ability 与页面、Impeller 渲染配置以及依赖目录。

## 工程整体结构

执行 `flutter create --platforms ohos <projectName>` 后，工程根目录下会生成 `ohos/` 目录，整体结构如下：

```
<projectName>/
├── lib/                                # Dart 业务代码（多端复用）
├── ohos/                               # OpenHarmony 平台代码
│   ├── AppScope/                       # 应用级配置
│   │   ├── app.json5                   # 应用全局配置（bundleName、版本、图标）
│   │   └── resources/base/            # 应用级资源（string、media）
│   ├── entry/                          # 主入口模块
│   │   ├── build-profile.json5         # 模块构建配置（apiType、targets）
│   │   ├── hvigorfile.ts               # 模块 Hvigor 构建脚本
│   │   ├── oh-package.json5            # 模块依赖配置
│   │   └── src/
│   │       ├── main/
│   │       │   ├── ets/                # ArkTS 代码
│   │       │   │   ├── entryability/
│   │       │   │   │   └── EntryAbility.ets               # 入口 Ability（继承 FlutterAbility）
│   │       │   │   ├── pages/
│   │       │   │   │   └── Index.ets                      # 主页面（FlutterPage 承载视图）
│   │       │   │   └── plugins/
│   │       │   │       └── GeneratedPluginRegistrant.ets # 插件注册表（自动生成，勿手改）
│   │       │   ├── module.json5                           # 模块配置（名称、类型、设备类型、权限）
│   │       │   └── resources/base/
│   │       │       ├── element/                           # 字符串、颜色等资源
│   │       │       ├── media/                             # 图标等媒体资源
│   │       │       └── profile/
│   │       │           ├── buildinfo.json5                # Impeller 渲染开关
│   │       │           └── main_pages.json                # 页面路由（pages/Index）
│   │       └── ohosTest/                                  # 测试代码
│   ├── build-profile.json5             # 项目构建配置（signingConfigs、products、buildModeSet）
│   ├── hvigorfile.ts                   # Hvigor 脚本（注入 flutter-hvigor-plugin）
│   ├── hvigorconfig.ts                 # Hvigor 插件配置（injectNativeModules 注入原生模块）
│   ├── oh-package.json5                # 项目依赖配置
│   └── package.json                    # Node 依赖（flutter-hvigor-plugin）
└── pubspec.yaml                        # Flutter 依赖配置
```

> `oh_modules/`（构建后生成）中的 `@ohos/flutter_ohos` 为框架适配层产物，包含 `FlutterAbility`、`FlutterEntry`、`FlutterEngine`、`FlutterView` 等核心类的实现，由 `flutter-hvigor-plugin`（见 `hvigorfile.ts` 与 `hvigorconfig.ts`）在构建时自动注入并拉取，无需手动管理。

## 关键配置文件

| 文件 | 路径 | 职责 |
|------|------|------|
| `app.json5` | `ohos/AppScope/app.json5` | 应用全局配置：`bundleName`（包名）、`versionName`、`versionCode` 等 |
| `build-profile.json5`（项目） | `ohos/build-profile.json5` | 项目构建配置：签名信息（`signingConfigs`）、SDK 版本、构建模式集合（`buildModeSet`） |
| `build-profile.json5`（模块） | `ohos/entry/build-profile.json5` | 模块构建配置：目标产品、编译参数等 |
| `oh-package.json5`（项目） | `ohos/oh-package.json5` | 项目依赖与覆盖配置 |
| `oh-package.json5`（模块） | `ohos/entry/oh-package.json5` | 模块依赖，声明 `@ohos/flutter_ohos` |
| `module.json5` | `ohos/entry/src/main/module.json5` | 模块配置：模块名、类型（`entry`）、`deviceTypes`、入口 Ability |
| `buildinfo.json5` | `ohos/entry/src/main/resources/base/profile/buildinfo.json5` | 渲染引擎开关：`enable_impeller` 控制 Impeller / Skia 切换 |

### app.json5

应用级全局配置，`bundleName` 为应用唯一标识，签名与发布时须规范填写：

```json5
{
  "app": {
    "bundleName": "com.example.<projectName>",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0"
  }
}
```

### build-profile.json5

项目构建配置，签名信息在 DevEco Studio 自动签名后写入 `signingConfigs`。`buildModeSet` 声明支持的构建模式，新模板默认包含 `debug`、`profile`、`release` 三种：

```json5
{
  "signingConfigs": [ /* 自动签名后填充 */ ],
  "buildModeSet": [
    { "name": "debug" },
    { "name": "profile" },
    { "name": "release" }
  ]
}
```

### oh-package.json5

模块依赖配置声明 `@ohos/flutter_ohos`，由 ohpm 解析后拉取对应的 `flutter.har` 引擎产物：

```json5
{
  "dependencies": {
    "@ohos/flutter_ohos": "har/flutter.har"
  }
}
```

### buildinfo.json5

渲染引擎配置，通过 `enable_impeller` 切换渲染后端。新建工程默认开启 Impeller：

```json5
{
  "string": [
    {
      "name": "enable_impeller",
      "value": "true"
    }
  ]
}
```

> 设为 `"false"` 使用 Skia 渲染后端；切换的生效条件与注意事项详见 [Impeller 与 Skia 渲染引擎切换指南](../rendering-engine/rendering-engine-switching.md)。

## 入口代码文件

| 文件 | 路径 | 职责 |
|------|------|------|
| `EntryAbility.ets` | `ohos/entry/src/main/ets/entryability/EntryAbility.ets` | 入口 Ability，继承 `FlutterAbility`，框架自动创建并管理 `FlutterEngine` 并注册插件 |
| `Index.ets` | `ohos/entry/src/main/ets/pages/Index.ets` | 主页面，通过 `FlutterPage` 组件承载 Flutter 渲染画面 |
