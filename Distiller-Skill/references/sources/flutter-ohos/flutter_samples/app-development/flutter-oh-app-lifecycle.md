# Flutter-OH应用生命周期

## 概述

本文介绍 Flutter-OH（`@ohos/flutter_ohos`）在 OpenHarmony 上的两种集成方式：[**独立 Flutter 应用**（Standalone Flutter app）](https://docs.flutter.dev/get-started/install)与 [**Add-to-App**](https://docs.flutter.dev/add-to-app)。二者为 Flutter 官方定义的主流嵌入路径，Flutter-OH 分别由 `FlutterAbility`、`FlutterEntry` 承载，详见 [Flutter-OH核心对象简介](./flutter-oh-core-objects.md)。

---

## 集成方式

| 集成方式 | 典型应用场景 | 宿主 | Flutter 入口 |
| -------- | -------- | ---- | ------------ |
| **独立 Flutter 应用** | `flutter create` 工程 | `EntryAbility extends FlutterAbility` | `FlutterAbility` 内部创建引擎 |
| **Add-to-App** | 既有鸿蒙 App 内嵌 Flutter 页 | `EntryAbility extends UIAbility` | 页面内 `new FlutterEntry(context)` |

### 独立 Flutter 应用（Standalone Flutter app）

`FlutterAbility` 继承 `UIAbility` 并重写关键生命周期回调，实现 Flutter 接入。

### Add-to-App

宿主保持原生 `UIAbility`，在 ArkUI 页面通过 `FlutterEntry` 嵌入 Flutter 模块。

---

## 生命周期时序概览

本节按两种集成方式给出生命周期链路。独立应用（Standalone Flutter app）FlutterAbility及其子类遵循 [UIAbility 组件生命周期](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-lifecycle-V5)；Add-to-App 的 Flutter 页由 **ArkUI 组件生命周期**驱动，宿主 `UIAbility` 仍遵循 UIAbility 生命周期。

> [!NOTE]
>
> 文中的「生命周期」指从FlutterApp启动到 Flutter 首帧、页面可见性变化、前后台切换直至销毁的原生回调链路。

### 独立 Flutter 应用（Standalone Flutter app）

![](../media/app-development/Flutter-OH-Lifecycle.PNG)

<p align="center"><strong>图1</strong> 独立 Flutter 应用（Standalone Flutter app）生命周期</p>

- **启动**：onCreate 注册 FlutterManager；onWindowStageCreate 加载首页并创建 FlutterEngine；引擎创建完成后触发 configureFlutterEngine，再进入 Dart `main`。
- **前/后台切换**：onForeground / onBackground。
- **退出**：onWindowStageDestroy / onDestroy 释放窗口与引擎，并注销 FlutterManager。

### Add-to-App

![](../media/app-development/Flutter-OH-Lifecycle-Module.PNG)

<p align="center"><strong>图2</strong> 内嵌Flutter页生命周期</p>

系统触发 ArkUI 组件生命周期后，开发者须在对应回调中**主动调用** FlutterEntry同名方法（见 [Add-to-App](#add-to-app)）：

**加载 Flutter 页**

- **aboutToAppear**：创建 FlutterEngine、FlutterView（期间触发 [`configureFlutterEngine`](#引擎配置configureflutterengine)），经 `getFlutterView()` 提供 `viewId`。
- **onPageShow**：恢复渲染（持续至 `onPageHide` 被调用）。

**离开 Flutter 页**

- **onPageHide**：暂停渲染。
- **aboutToDisappear**：销毁 FlutterEngine、FlutterView，释放引擎与视图资源。

---

## 生命周期回调说明

本节从**应用开发者**视角介绍各生命周期回调的触发时机与可扩展点。`FlutterAbility`、`FlutterEntry` 等 Embedding API 由 `@ohos/flutter_ohos` 框架实现，引擎创建、视图绑定、生命周期同步等逻辑由框架自动完成，应用侧开发者通常无需关心其内部实现。核心对象协作关系见 [Flutter-OH核心对象简介](./flutter-oh-core-objects.md)。插件注册等引擎配置见 [第四节](#引擎配置configureflutterengine)。

> **说明**
>
> - 生命周期回调在主线程执行，仅执行必要的轻量操作；耗时任务请异步处理或交由子线程。
> - 重写 `FlutterAbility` / `FlutterEntry` 的生命周期方法时，**必须调用 `super`**，否则框架默认处理与渲染可能异常。不同回调中 `super` 的调用顺序不同：`onForeground` / `onBackground` 等应**先**调用 `super`，再执行开发者逻辑；`onDestroy` 应**后**调用 `super.onDestroy()`，因为 `super` 会销毁引擎，须在引擎销毁前完成数据保存与资源释放。

### 独立 Flutter 应用（Standalone Flutter app）

应用入口为 `EntryAbility extends FlutterAbility`。除下表标注的扩展点外，其余 UIAbility 回调由框架默认处理，一般无需重写。

| 回调 | 触发时机 | 框架默认行为 | 开发者可扩展 |
| ---- | -------- | ------------ | ------------ |
| `onCreate()` | 首次创建 UIAbility 实例 | 注册 `FlutterManager` | 执行整个生命周期仅发生一次的启动逻辑 |
| onWindowStageCreate() | `WindowStage` 创建后、进入前台前 | 创建 FlutterView、`loadContent` 加载首页 | 重写 `pagePath()` 更换首页路径（扩展方法，非生命周期回调） |
| `onForeground()` | 切换至前台、UI 可见之前 | 恢复渲染 | 申请/恢复原生资源/服务（如定位服务） |
| `onBackground()` | UI 完全不可见之后 | 暂停渲染 | 释放无用原生资源/服务 |
| `onWindowStageDestroy()` | 实例销毁前，`WindowStage` 已销毁 | 注销 `WindowStage`、释放窗口资源 | 释放通过 `WindowStage` 获取的资源/服务 |
| `onDestroy()` | UIAbility 实例销毁前（最后一个回调） | 销毁引擎与视图 | 保存数据、释放系统资源/服务 |

#### onCreate()

在首次创建 UIAbility 实例时，系统触发 onCreate()回调。开发者可在该回调中执行整个生命周期中仅发生一次的启动逻辑。框架已完成 `FlutterManager` 注册（引擎在 `onWindowStageCreate` 中创建），通常无需重写；若需扩展，须调用 `super.onCreate()`。

#### onWindowStageCreate()

UIAbility 实例创建完成之后，在进入前台之前，系统创建 WindowStage回调。框架在此完成 `FlutterView` 创建与首页加载。如需更换首页路径，重写 `pagePath()` 扩展方法即可（非生命周期回调）。

#### onForeground()

在 UIAbility 切换至前台且 UI 可见之前，系统触发 onForeground()回调。框架恢复渲染。开发者可在该回调中申请系统资源，或重新申请在onBackground 中释放的资源（例如恢复定位）。**必须调用 `super.onForeground()`**。

#### onBackground()

在 UIAbility 的 UI 完全不可见之后，系统触发 onBackground回调。框架暂停渲染。开发者可在该回调中释放 UI 不可见时的无用资源（例如停止定位）。`onBackground()` 执行时间较短，请勿执行保存用户数据或数据库事务等耗时操作。**必须调用 `super.onBackground()`**。

#### onWindowStageDestroy()

在 UIAbility 实例销毁之前，系统触发 onWindowStageDestroy回调。框架释放窗口相关资源。开发者可在该回调中释放通过 `WindowStage` 获取的自定义资源。该回调在 `WindowStage` 销毁后执行，此时 `WindowStage` 不可使用。

#### onDestroy()

在 UIAbility 实例销毁之前，系统触发 onDestroy回调。这是 UIAbility 接收到的最后一个生命周期回调。框架销毁引擎与视图。开发者可在该回调中进行系统资源释放、数据保存等操作；**须先完成自定义逻辑，再调用 `super.onDestroy()`**，避免引擎已销毁时数据尚未保存完毕。

以下为 `EntryAbility` 扩展示例，涵盖上述回调及 `pagePath()`：

```ts
// EntryAbility.ets
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { FlutterAbility } from '@ohos/flutter_ohos';

export default class EntryAbility extends FlutterAbility {
  pagePath(): string {
    return 'pages/CustomIndex'  // 默认为 'pages/Index'，非生命周期回调
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam)
    // 执行整个生命周期中仅发生一次的启动逻辑，例如解析 Want 启动参数
  }

  onForeground(): void {
    super.onForeground()
    // 申请系统需要的资源，或重新申请在 onBackground() 中释放的资源
    // 例如：恢复定位、重新订阅传感器
  }

  onBackground(): void {
    super.onBackground()
    // 释放 UI 不可见时无用的资源
    // 例如：停止定位、取消传感器订阅
  }

  onWindowStageDestroy(): void {
    super.onWindowStageDestroy()
    // 释放通过 WindowStage 获取的自定义资源
    // 例如：注销在 onWindowStageCreate 中订阅的 windowStageEvent
  }

  onDestroy(): void {
    // 保存用户数据、释放自定义原生资源
    // 注意：super.onDestroy() 会销毁引擎，须在上述逻辑完成后再调用；
    // 与 onForeground/onBackground 中 super 优先调用不同
    super.onDestroy()
  }
}
```

### Add-to-App

宿主 `UIAbility` 保持原生实现，须在 `onCreate` / `onWindowStageCreate` / `onWindowStageDestroy` / `onDestroy` 中调用 `FlutterManager` 的 `push` / `pop` 方法完成注册与注销，且 `loadContent` 加载**原生主导航**而非 Flutter 首页。

以下为 Add-to-App 宿主 `EntryAbility` 示例，展示 `FlutterManager` 的注册与注销：

```ts
// EntryAbility.ets（Add-to-App 宿主 UIAbility）
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
    // 1. 注册 UIAbility，供 Embedding 通过 context 查找 Ability
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 2. 注册 WindowStage，并加载原生主导航页（非 Flutter 首页）
    FlutterManager.getInstance().pushWindowStage(this, windowStage);
    windowStage.loadContent('pages/MainPage');
  }

  onWindowStageDestroy(): void {
    // 3. WindowStage 销毁时注销
    FlutterManager.getInstance().popWindowStage(this);
  }

  onDestroy(): void {
    // 4. UIAbility 销毁时注销
    FlutterManager.getInstance().popUIAbility(this);
  }
}
```

> **注意**：`pushUIAbility` / `popUIAbility` 与 `pushWindowStage` / `popWindowStage` **必须成对调用**；遗漏 `pop` 会导致后续页面 `viewId` 绑定异常、插件上下文解析错误。实现 `ExclusiveAppComponent` 接口可让插件通过 `getAppComponent()` 获取宿主 `UIAbility` 上下文。

#### 宿主前后台与 FlutterEntry

Add-to-App 存在**两套生命周期**：宿主 `UIAbility` 的 `onForeground` / `onBackground` 处理 Ability 级原生资源；Flutter 引擎的渲染启停由 ArkUI 页面的 `onPageShow` / `onPageHide` 驱动，**二者不自动桥接**。

Flutter 页面以 ArkUI 组件为载体嵌入。系统触发 ArkUI 组件生命周期后，开发者须在对应回调中**主动调用** `FlutterEntry` 同名方法，框架据此完成引擎与视图的生命周期管理：

| ArkUI 组件回调 | 触发时机 | 开发者须调用 | 效果 |
| -------------- | -------- | ------------ | ---- |
| `aboutToAppear()` | 组件即将挂载 | `flutterEntry.aboutToAppear()` | 创建引擎与视图（期间回调 `configureFlutterEngine`，见第四节） |
| `onPageShow()` | 页面可见（含 Navigation `onShown`） | `flutterEntry.onPageShow()` | 恢复渲染 |
| `onPageHide()` | 页面被遮挡或离开（含 `onHidden`） | `flutterEntry.onPageHide()` | 暂停渲染 |
| `aboutToDisappear()` | 组件即将卸载（Navigation 可为 `onDisAppear`） | `flutterEntry.aboutToDisappear()` | 销毁引擎与视图 |

使用 `Navigation` 时，须在 `onShown` / `onHidden` / `onDisAppear` 等路由回调中同步调用上表对应的 `FlutterEntry` 方法，确保引擎生命周期与页面可见性一致。

以下为 ArkUI 页面完整示例，在组件生命周期中调用 `FlutterEntry` 同名方法，并通过 `FlutterPage` 绑定 `viewId`：

```ts
// FlutterRoutePage.ets
import { FlutterPage, FlutterView } from '@ohos/flutter_ohos';
import MyFlutterEntry from '../entry/MyFlutterEntry';

@Component
export struct FlutterRoutePage {
  private flutterEntry?: MyFlutterEntry;
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
    this.flutterEntry = undefined;
    this.flutterView = undefined;
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
    .width('100%')
    .height('100%')
  }
}
```

> **注意（Engine 与 FlutterView 绑定）**：**同一 `FlutterEngine` 在活跃态下只能 attach 一个 `FlutterView`**。Add-to-App 多页面导航时，若多个 ArkUI 页面**共享同一 Engine**（如缓存 Engine、`FlutterEngineGroup` 场景），须在离开页面时 detach 当前 `FlutterView`（如在 `aboutToDisappear` / `onPageHide` 中调用 `flutterView.detachFromFlutterEngine()`），在进入新页面后再 attach 新的 `FlutterView`（如在 `aboutToAppear` / `onPageShow` 中调用 `flutterView.attachToFlutterEngine(engine)`）；**切换页面前必须先 detach 再 attach**，否则可能出现黑屏、画面重叠或 Engine 状态错误。各页面独立创建 `FlutterEntry` 时（上文示例），框架会在 Entry 生命周期内自动管理 attach/detach；**共享 Engine 时须自行保证上述约束，并参考以下文档中的代码示例**：
>
> - [如何使用多引擎 FlutterEngineGroup](../hybrid-development/using-flutter-engine-group.md)：`EngineBindings` 封装 `attach()` / `detach()`，在 `aboutToAppear` / `aboutToDisappear` 中调用
> - [Flutter-OH多引擎场景开发指导](../hybrid-development/flutter-oh-multi-engine-dev-guide.md)：多引擎 Add-to-App 端到端示例

---

## 引擎配置（configureFlutterEngine）

`configureFlutterEngine()` 是 Flutter Embedding 提供的**引擎初始化钩子**，不是 UIAbility 或 ArkUI 的生命周期回调。框架在 `FlutterEngine` 创建完成、Dart `main` 执行之前调用它（每引擎一次），供应用注册插件或做引擎级配置。

两种集成方式均通过子类重写此方法扩展，**须调用 `super.configureFlutterEngine()`**。

### 独立 Flutter 应用

在 `EntryAbility.ets` 中重写：

```ts
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
```

### Add-to-App

在 `MyFlutterEntry.ets` 中重写：

```ts
import { FlutterEngine, FlutterEntry } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class MyFlutterEntry extends FlutterEntry {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
  }
}
```
