# OpenHarmony应用集成Flutter指导

本文介绍如何将 Flutter 模块以 **Add-to-App** 方式集成到 OpenHarmony 原生应用中：创建 Flutter 模块，通过 HAR 产物依赖或源码依赖两种方式配置项目依赖，在 ArkUI 页面中加载并显示 Flutter 页面。适用于「OpenHarmony 原生应用为主、部分页面使用 Flutter」的场景。

---

## 前置条件

- 完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)
- 已创建 OpenHarmony 原生项目（或按下方步骤创建）

---

## 创建 OpenHarmony 应用项目

### 第一步：创建项目

打开 DevEco Studio，选择 `File → New → Create Project` 创建项目。

### 第二步：查看项目目录结构

项目创建完成后，以下文件与集成 Flutter 相关：

```text
Project/
├── oh-package.json5                    # 项目依赖配置
└── entry/                              # 主模块目录
    ├── oh-package.json5               # 主模块依赖配置
    └── src/main/
        ├── ets/
        │   ├── entryability/
        │   │   └── EntryAbility.ets   # 主模块 Ability
        │   └── pages/
        │       └── Index.ets          # 页面代码
        └── resources/base/profile/
            └── main_pages.json         # 页面路由配置
```

---

## 集成 Flutter 模块

Flutter 模块接入宿主工程有两种方式，可按场景选择其一：

| 方式 | 说明 | 适用场景 |
|------|------|---------|
| HAR 产物依赖 | 引用 `flutter build har` 构建出的 HAR 包 | 稳定发布、CI 构建、Flutter 模块改动不频繁 |
| 源码依赖 | 通过 hvigor 插件动态注入 module 及插件源码编译 | 开发联调，改源码即生效，免反复构建与拷贝 HAR |

两种方式仅在「集成」阶段二选一，后续「加载显示 Flutter 页面」步骤完全一致。下文先完成共用的创建步骤，再分别说明两种方式的依赖配置。

### 第一步：创建 Flutter 模块

在项目根目录下执行：

```bash
flutter create -t module flutter_module
```

执行完成后，项目根目录下生成 `flutter_module` 模块。

> [!NOTE]
>
> 若选用源码依赖方式，创建模块后还需在 `flutter_module` 目录执行 `flutter pub get`，以生成 `.ohos` 注入产物（含 hvigor 插件入口 `include_flutter`）。

### 方式一：HAR 产物依赖

> 适用：稳定发布、CI 构建、Flutter 模块改动不频繁的场景。

#### 第二步：构建 Flutter 模块

进入 `flutter_module` 目录，执行构建命令：

```bash
# 调试版本
flutter build har --debug

# 正式版本
flutter build har --release
```

构建完成后，打开 `flutter_module/build/ohos/har/` 目录，以 debug 构建为例：

```text
debug/
├── arm64_v8a_debug.har
├── flutter_embedding_debug.har
└── flutter_module.har
```

生成 3 个 HAR 文件即构建成功。release 构建产物位于 `release/` 子目录，文件名后缀为 `_release`。

> [!WARNING]
>
> 需将构建生成的 HAR 文件拷贝至项目根路径 `Project/har/` 下。若各模块各自引用 HAR 文件而不统一存放，打包时会重复引入，导致包体积增大。

#### 第三步：配置项目依赖

1. 修改主项目 `oh-package.json5`

   打开 `Project/oh-package.json5`，在 `overrides` 节点添加以下内容（路径需替换为实际 HAR 包路径，以 debug 构建为例）：

   ```json5
   "overrides": {
     "@ohos/flutter_ohos": "file:./har/flutter_embedding_debug.har",
     "flutter_native_arm64_v8a": "file:./har/arm64_v8a_debug.har",
     "@ohos/flutter_module": "file:./har/flutter_module.har"
   }
   ```

   > [!NOTE]
   >
   > release 构建请将文件名后缀 `_debug` 替换为 `_release`。

2. 修改 `entry` 模块 `oh-package.json5`

   打开 `Project/entry/oh-package.json5`，在 `dependencies` 节点添加以下内容：

   ```json5
   "dependencies": {
     "@ohos/flutter_ohos": "",
     "flutter_native_arm64_v8a": "",
     "@ohos/flutter_module": ""
   }
   ```

3. 同步依赖

   在 DevEco Studio 中执行 `Sync Now`，或在项目根目录执行：

   ```bash
   ohpm install
   ```

   执行完成后，`Project/entry` 目录下生成 `oh_modules` 依赖缓存目录，即集成成功。

### 方式二：源码依赖

> 适用：开发联调场景。修改 `flutter_module` 或插件源码后重新运行宿主工程即生效，无需重复构建与拷贝 HAR。

源码依赖通过 hvigor 插件 `flutterHvigorPlugin` 与 `injectNativeModules`，将 `flutter_module` 的 `.ohos` 源码模块及各插件 `ohos/` 源码模块动态注入宿主工程 hvigor 节点，对齐 Android / iOS Add-to-App 的 `:flutter` 子模块 include 机制。

#### 第二步：配置 hvigor 插件注入源码

1. 在宿主工程根目录新建（或修改）`hvigorfile.ts`，引入并注册 `flutterHvigorPlugin`：

   ```ts
   import { appTasks } from '@ohos/hvigor-ohos-plugin';
   // 路径需替换为 flutter_module/.ohos 的实际相对位置
   import { flutterHvigorPlugin, getFlutterProjectPath } from './flutter_module/.ohos/include_flutter';

   export default {
     system: appTasks,
     plugins: [flutterHvigorPlugin(getFlutterProjectPath(), 1)]
   }
   ```

2. 在宿主工程根目录新建（或修改）`hvigorconfig.ts`，调用 `injectNativeModules` 注入源码节点：

   ```ts
   import { injectNativeModules, getFlutterProjectPath } from './flutter_module/.ohos/include_flutter';

   injectNativeModules(__dirname, getFlutterProjectPath(), 1)
   ```

3. 移除宿主工程 `oh-package.json5` 中 `dependencies` 与 `overrides` 的 Flutter 相关依赖（如不存在则跳过）。

4. 从宿主工程 `build-profile.json5` 的 modules 中移除 `flutter_module`（若曾以模块形式引入）。

#### 第三步：配置 entry 模块依赖

打开 `Project/entry/oh-package.json5`，在 `dependencies` 节点添加以下内容：

```json5
"dependencies": {
  "@ohos/flutter_ohos": "",
  "@ohos/flutter_module": ""
}
```

> **注意**：以上为必须添加的依赖，**不指定版本号或路径，直接使用空字符串 `""`**；版本与路径由宿主 `oh-package.json5` 的 `overrides` 统一解析，插件源码由 `injectNativeModules` 在构建期动态注入，无需在 `dependencies` 中声明。

---

## 加载显示 Flutter 页面

完成 Flutter 模块集成后，即可在 ArkUI 页面中加载并显示 Flutter 页面。以下步骤实现 Ability 生命周期接入、引擎配置、页面创建与路由跳转。

### 第一步：集成 Ability 生命周期

在 `EntryAbility` 中调用 `FlutterManager` 完成注册与注销，实现 `ExclusiveAppComponent` 接口供插件获取宿主上下文：

```ts
// EntryAbility.ets
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ExclusiveAppComponent, FlutterManager } from '@ohos/flutter_ohos';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {
  detachFromFlutterEngine(): void {
  }

  getAppComponent(): UIAbility {
    return this;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onDestroy(): void {
    FlutterManager.getInstance().popUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindowSync().setWindowLayoutFullScreen(true);
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    windowStage.loadContent('pages/Index');
  }

  onWindowStageDestroy(): void {
    FlutterManager.getInstance().popWindowStage(this);
  }
}
```

> **注意**：`pushUIAbility` / `popUIAbility` 与 `pushWindowStage` / `popWindowStage` 必须成对调用，遗漏 `pop` 会导致后续页面 `viewId` 绑定异常。

### 第二步：实现 FlutterEntry 类

创建 `MyFlutterEntry` 继承 `FlutterEntry`，重写 `configureFlutterEngine` 完成插件注册：

```ts
// MyFlutterEntry.ets
import { FlutterEngine, FlutterEntry } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class MyFlutterEntry extends FlutterEntry {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    // 如需注册自定义插件，在此调用 this.delegate?.addPlugin(new CustomPlugin());
  }
}
```

### 第三步：创建 Flutter 页面

新建 `FlutterIndex.ets` 页面，在 ArkUI 组件生命周期中调用 `FlutterEntry` 同名方法，并通过 `FlutterPage` 组件绑定 `viewId`：

```ts
// pages/FlutterIndex.ets
import { FlutterPage, FlutterView } from '@ohos/flutter_ohos';
import MyFlutterEntry from '../entry/MyFlutterEntry';

@Entry
@Component
struct FlutterIndex {
  private flutterEntry: MyFlutterEntry | null = null;
  private flutterView?: FlutterView;

  aboutToAppear(): void {
    this.flutterEntry = new MyFlutterEntry(getContext(this));
    this.flutterEntry.aboutToAppear();
    this.flutterView = this.flutterEntry.getFlutterView();
  }

  onPageShow(): void {
    this.flutterEntry?.onPageShow();
  }

  onPageHide(): void {
    this.flutterEntry?.onPageHide();
  }

  aboutToDisappear(): void {
    this.flutterEntry?.aboutToDisappear();
    this.flutterEntry = null;
    this.flutterView = undefined;
  }

  onBackPress(): boolean {
    this.flutterEntry?.onBackPress();
    return true;
  }

  build() {
    Stack() {
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
    .width('100%')
    .height('100%')
  }
}
```

### 第四步：注册页面路由

打开 `entry/src/main/resources/base/profile/main_pages.json`，注册新增的 `FlutterIndex` 页面：

```json
{
  "src": [
    "pages/Index",
    "pages/FlutterIndex"
  ]
}
```

### 第五步：导航跳转

在原生页面（如 `Index.ets`）中添加按钮，通过路由跳转至 Flutter 页面：

```ts
// pages/Index.ets
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Button('打开 Flutter 页面')
        .onClick(() => {
          router.push({ url: 'pages/FlutterIndex' });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

运行项目后，原生首页显示，点击「打开 Flutter 页面」按钮即可跳转至 Flutter 页面。

---

## 常见问题

### 问题：集成 flutter_module 后，entry 下没有生成 oh_modules 缓存目录

需要在项目根路径下执行 `ohpm install`，而不是在 `entry` 目录下执行。

### 问题：修改了 flutter_module 代码后没有生效

采用 **HAR 产物依赖**方式时，修改 `flutter_module` 业务代码后，需要在 `flutter_module` 目录下重新执行 `flutter build har --debug`（或 `--release`）更新 HAR 包。若 HAR 包单独存放在项目根路径 `har/` 目录下，还需将新生成的 HAR 文件拷贝至该目录替换旧文件，并在 DevEco Studio 中执行 `Sync Now` 或 `ohpm install` 刷新依赖。

若需频繁修改 Flutter 模块或插件源码，建议改用 [源码依赖方式](#方式二源码依赖)，修改后重新运行宿主工程即生效，免去反复构建与拷贝 HAR 的成本。

### 问题：多模块项目打包体积过大

将多个 `module` 构建出的 HAR 文件统一放到项目根路径 `har/` 目录下，通过 `overrides` 统一引用，避免各模块各自引入导致重复打包。

