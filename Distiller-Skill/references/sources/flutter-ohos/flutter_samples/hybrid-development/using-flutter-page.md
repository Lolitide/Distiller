# 如何使用 FlutterPage

本文档介绍如何在原生 ArkUI 页面中通过 `FlutterPage` 嵌入 Flutter 渲染内容。`FlutterPage` 是 `flutter_ohos` 提供的 ArkTS 组件，在独立 Flutter 应用模式下与 `FlutterAbility`（应用入口，负责创建并管理 Flutter 引擎）配合，将 Flutter 画面呈现在宿主页面中，并支持在其上叠加原生 ArkUI 组件。

---

## 核心概念

| 术语 | 说明 |
|------|------|
| `FlutterPage` | ArkTS UI 组件，接收 `viewId` 参数，在原生页面中渲染 Flutter 内容 |
| `viewId` | `FlutterView` 的唯一标识，由 `FlutterAbility` 创建引擎时生成，并通过 `LocalStorage` 注入宿主页面 |
| `FlutterView` | 由 `FlutterAbility` 内部创建的渲染视图对象，`FlutterPage` 根据 `viewId` 与之绑定 |
| `FlutterAbility` | 独立 Flutter 应用的 Ability 级入口，继承 `UIAbility`，内部完成引擎创建、`viewId` 注入与生命周期管理；插件注册通过重写 `configureFlutterEngine` 完成 |

---

## 前置条件

- 已完成 [Flutter OH 开发环境搭建](../getting-started/flutter-oh-env-setup.md)。
- 已创建 Flutter OH 应用，本示例命名为 `page_demo`。
- 已使用 DevEco Studio 打开 `page_demo/ohos` 工程。

---

## 实现步骤

### 第一步：创建承载 FlutterPage 的页面

承载 `FlutterPage` 的页面分两种场景：直接复用工程默认首页 `pages/Index`，或新建一个 Page 作为承载页。两者均需在 `main_pages.json` 中注册路径，区别在于是否新建文件、是否需要重写 `pagePath()`。

#### 场景1：使用默认首页 `pages/Index`

工程创建时已默认生成 `pages/Index.ets`，且 `main_pages.json` 中已注册该路径，因此无需新建文件、无需重写 `pagePath()`，直接在 `pages/Index.ets` 中使用 `FlutterPage` 即可（见第三步）。

1. 确认 `ohos/entry/src/main/resources/base/profile/main_pages.json` 已注册默认首页：

   ```
   {
     "src": [
       "pages/Index"
     ]
   }
   ```

#### 场景2：新建 Page 作为承载页

若需用新建页面承载 `FlutterPage`，需新建文件、注册路径，并在 `EntryAbility` 中重写 `pagePath()` 指向新页面。

1. 右键点击 `ohos/entry/src/main/ets/pages` 目录，选择 **New** → **Page** → **Empty Page** 新建 Page（如 `pages/NewIndex`）。

2. 在 `main_pages.json` 中注册新建 Page：

   ```
   {
     "src": [
     	"pages/Index",
       "pages/NewIndex"	// 注册新建Page
     ]
   }
   ```

3. 在 `EntryAbility` 中重写 `pagePath()`，返回新建页面路径：

   ```ts
   export default class EntryAbility extends FlutterAbility {
     pagePath(): string {
       return 'pages/NewIndex';
     }
   }
   ```

### 第二步：配置 EntryAbility

```ts
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
	// 必须注册插件，省略会导致 MissingPluginException
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
```

> `GeneratedPluginRegistrant` 由 `flutter build har` 自动生成到 `entry/src/main/ets/plugins/`（该文件在 `.gitignore` 中，不入库），构建完成后会出现，无需手写。`FlutterAbility` 会创建引擎，并把 `viewId` 写入页面的 `LocalStorage`。

### 第三步：在页面中使用 FlutterPage

```ts
import { FlutterPage } from '@ohos/flutter_ohos';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct Index {
  @LocalStorageLink('viewId') viewId: string = '';

  build() {
    Stack({ alignContent: Alignment.Top }) {
      FlutterPage({ viewId: this.viewId })
      Text('Components overlaid above FlutterPage').margin(30)
    }
  }
}
```

> `@Entry(storage)` 和 `@LocalStorageLink('viewId')` 用于接收 `FlutterAbility` 注入的 `viewId`，`FlutterPage` 按该 id 画出 Flutter 画面。

---

## 在 FlutterPage 之上叠加原生组件

`FlutterPage` 本质上是渲染表面，可像普通 ArkUI 组件一样放入 `Stack`。通过 `Stack` 的层叠特性，原生组件声明在 `FlutterPage` 之后即可覆盖在 Flutter 内容之上：

```ts
Stack({ alignContent: Alignment.Top }) {
  // 底层：Flutter 渲染内容
  FlutterPage({ viewId: this.viewId })
  // 上层：原生 ArkUI 组件
  Text('Components overlaid above FlutterPage').margin(30)
}
```

常见叠加场景包括：原生顶部导航栏、悬浮按钮、加载弹窗、调试浮层等。叠加组件的事件仍由原生侧处理，不会穿透到 Flutter。

---

## 构建与运行

### 配置签名

使用 DevEco Studio 打开 ohos 工程，选择 **File → Project Structure → Project → SigningConfigs**，勾选 **Automatically generate signature**，完成签名。

### 构建打包

在工程根目录执行：

```sh
flutter build hap --debug
```

### 运行

连接 OHOS 设备后执行：

```sh
flutter run -d <device-id>
```

也可在 DevEco Studio 中直接运行 entry 模块。

---

## Demo 参考

完整 demo 请参考 [flutter_page_sample1](../../../ohos/flutter_page_sample1/)。
