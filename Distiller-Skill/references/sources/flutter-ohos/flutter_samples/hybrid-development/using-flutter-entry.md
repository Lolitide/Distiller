# 如何使用混合开发添加跳转 FlutterEntry

在 HarmonyOS（OHOS）平台上进行 Flutter 混合开发时，需要通过 `FlutterEntry` 将 Flutter 页面嵌入到原生 ArkTS 页面中，并管理 Flutter 引擎的创建、销毁以及页面跳转等生命周期行为。

本指南介绍如何使用 `FlutterEntry` 实现原生页面与 Flutter 页面之间的混合开发与跳转，包括基础用法以及与 `Navigation` 的集成方式。

---

## 核心概念

| 术语 | 说明 |
|------|------|
| `FlutterEntry` | flutter_ohos 提供的核心类，负责管理 Flutter 引擎在原生页面中的生命周期，包括引擎创建、插件注册、视图获取等 |
| `FlutterView` | `FlutterEntry` 创建的 Flutter 渲染视图对象，通过 `getFlutterView()` 获取，用于在 ArkTS 页面中嵌入 Flutter 内容 |
| `FlutterPage` | ArkTS UI 组件，接收 `viewId` 参数，将 Flutter 渲染内容展示到原生页面中 |
| `UIAbility` | HarmonyOS 应用组件，类似 Android 的 Activity，是应用入口和窗口管理的载体 |
| `ExclusiveAppComponent` | flutter_ohos 定义的应用组件接口，UIAbility 需实现该接口以与 Flutter 引擎绑定 |
| `FlutterManager` | flutter_ohos 提供的全局管理器，负责维护 UIAbility 和 WindowStage 的栈关系，确保 Flutter 引擎与宿主正确关联 |
| `NavPathStack` | HarmonyOS Navigation 导航的路径栈，用于管理页面跳转与返回 |
| `NavFlutterEntry` | 继承自 `FlutterEntry` 的自定义类，用于 Navigation 导航场景中处理 `SystemNavigator.pop()` 的原生侧返回行为 |

### 混合开发页面跳转流程

```
原生页面 → 创建 FlutterEntry → 初始化 Flutter 引擎 → 获取 FlutterView → 渲染 FlutterPage
                                                                         ↑
原生页面跳转（router / Navigation） → FlutterEntry.aboutToAppear() → 引擎启动
原生页面返回 → FlutterEntry.aboutToDisappear() → 引擎销毁或缓存回收
```

---

## 使用前提

- 项目已集成 `flutter_ohos` 插件，可通过 `@ohos/flutter_ohos` 引入相关类。
- Flutter 版本需 3.22 及以上。
- 了解 HarmonyOS `UIAbility` 和 `Navigation` 基础概念。

---

## 使用步骤

### 第一步：EntryAbility 继承 UIAbility 并实现 ExclusiveAppComponent

在混合开发中，`UIAbility` 是 Flutter 引擎的宿主组件。`FlutterManager` 需要感知 UIAbility 的创建与销毁，以正确管理 Flutter 引擎与窗口的绑定关系。因此，`EntryAbility` 必须实现 `ExclusiveAppComponent<UIAbility>` 接口，并在关键生命周期回调中调用 `FlutterManager` 的对应方法。

#### 为什么要实现 ExclusiveAppComponent

`ExclusiveAppComponent` 是 flutter_ohos 定义的应用组件接口，它要求宿主提供 `getAppComponent()` 和 `detachFromFlutterEngine()` 两个方法。`FlutterManager` 通过该接口获取真实的 UIAbility 实例，用于：
- 在引擎创建时绑定正确的 UIAbility 上下文
- 在引擎销毁时解绑 UIAbility 与 Flutter 引擎的关系
- 在多引擎场景中区分不同 UIAbility 的归属

#### 完整代码示例

```ts
import { FlutterManager } from '@ohos/flutter_ohos';
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { ExclusiveAppComponent } from '@ohos/flutter_ohos/src/main/ets/embedding/ohos/ExclusiveAppComponent';

export default class EntryAbility extends UIAbility implements ExclusiveAppComponent<UIAbility> {

  detachFromFlutterEngine(): void {
    // 当 Flutter 引擎与该 UIAbility 解绑时调用
    // 默认可不处理，如需在解绑时执行清理逻辑可在此实现
  }

  getAppComponent(): UIAbility {
    // 返回当前 UIAbility 实例，供 FlutterManager 获取宿主组件
    return this;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 将当前 UIAbility 推入 FlutterManager 管理栈
    // FlutterManager 会在引擎创建时通过栈顶 UIAbility 获取上下文
    FlutterManager.getInstance().pushUIAbility(this);
  }

  onDestroy(): void | Promise<void> {
    // 将当前 UIAbility 从 FlutterManager 管理栈弹出
    // 确保引擎销毁时能正确清理与该 UIAbility 的关联
    FlutterManager.getInstance().popUIAbility(this);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 设置全屏布局，确保 Flutter 页面能完整渲染
    windowStage.getMainWindowSync().setWindowLayoutFullScreen(true);

    // 将 WindowStage 推入 FlutterManager 管理栈
    // FlutterManager 需要 WindowStage 来绑定 Flutter 渲染表面
    FlutterManager.getInstance().pushWindowStage(this, windowStage);

    // 加载原生入口页面
    windowStage.loadContent('pages/Index');
  }

  onWindowStageDestroy() {
    // 将 WindowStage 从 FlutterManager 管理栈弹出
    FlutterManager.getInstance().popWindowStage(this);
  }
}
```

#### 关键说明

| 方法 | 调用时机 | 作用 |
|------|----------|------|
| `pushUIAbility` | `onCreate` | 将 UIAbility 注册到 FlutterManager，引擎创建时可获取宿主上下文 |
| `popUIAbility` | `onDestroy` | 从 FlutterManager 移除 UIAbility，引擎销毁时清理关联 |
| `pushWindowStage` | `onWindowStageCreate` | 将窗口舞台注册到 FlutterManager，用于绑定 Flutter 渲染表面 |
| `popWindowStage` | `onWindowStageDestroy` | 从 FlutterManager 移除窗口舞台 |
| `setWindowLayoutFullScreen` | `onWindowStageCreate` | 设置全屏布局，Flutter 页面默认需要全屏渲染区域 |

> **注意**：`pushUIAbility` 和 `pushWindowStage` 必须分别在 `onCreate` 和 `onWindowStageCreate` 中尽早调用，否则后续创建 FlutterEntry 时 FlutterManager 无法获取正确的宿主信息，可能导致引擎创建失败或渲染异常。

---

### 第二步：继承 FlutterEntry 并注册插件

`FlutterEntry` 是 flutter_ohos 提供的核心入口类，负责管理 Flutter 引擎的创建和初始化。开发者需要继承 `FlutterEntry` 并在 `configureFlutterEngine` 方法中注册插件，类似于 Android 侧 `FlutterActivity.configureFlutterEngine` 的作用。

#### 为什么需要继承 FlutterEntry

- `FlutterEntry` 默认仅创建引擎，不自动注册任何插件。
- `GeneratedPluginRegistrant.registerWith()` 会将所有通过 `flutter pub get` 生成的插件（如 path_provider、shared_preferences 等）自动绑定到引擎。
- 自定义插件（如 `BatteryPlugin`）需要通过 `this.delegate?.addPlugin()` 手动添加。

#### 完整代码示例

```ts
import { FlutterEntry, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '@ohos/flutter_ohos';
import { BatteryPlugin } from './BatteryPlugin';

export default class MyFlutterEntry extends FlutterEntry {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    // 必须调用 super，确保父类初始化逻辑正常执行
    super.configureFlutterEngine(flutterEngine);

    // 注册所有自动生成的插件（path_provider、shared_preferences 等）
    // 这一步不可省略，否则 Dart 代码调用插件时会报错
    GeneratedPluginRegistrant.registerWith(flutterEngine);

    // 注册自定义插件
    this.delegate?.addPlugin(new BatteryPlugin());
  }
}
```

#### 插件注册说明

| 注册方式 | 适用场景 | 说明 |
|----------|----------|------|
| `GeneratedPluginRegistrant.registerWith(engine)` | 所有 pub 依赖的插件 | 根据项目 `pubspec.yaml` 自动生成，注册所有标准 Flutter 插件的原生端实现 |
| `this.delegate?.addPlugin(new CustomPlugin())` | 开发者自定义插件 | 手动注册自定义的 FlutterPlugin 实现类 |

> **重要**：`GeneratedPluginRegistrant.registerWith(flutterEngine)` 不可省略。如果省略此调用，所有通过 `pubspec.yaml` 引入的 Flutter 插件（如 url_launcher、shared_preferences 等）在 Dart 侧调用时会报 `MissingPluginException` 错误。

---

### 第三步：FlutterEntry 与 FlutterView 配合使用

在 ArkTS 页面中，需要创建 `FlutterEntry` 实例，获取其 `FlutterView`，并通过 `FlutterPage` 组件将 Flutter 渲染内容嵌入原生页面。同时需要在页面生命周期回调中正确管理 `FlutterEntry` 的生命周期。

#### 生命周期对应关系

| ArkTS 页面生命周期 | FlutterEntry 方法 | 作用 |
|---------------------|-------------------|------|
| `aboutToAppear` | `aboutToAppear()` | 创建并初始化 Flutter 引擎，获取 FlutterView |
| `aboutToDisappear` | `aboutToDisappear()` | 销毁或回收 Flutter 引擎资源 |
| `onPageShow` | `onPageShow()` | 恢复 Flutter 页面可见状态，处理引擎恢复逻辑 |
| `onPageHide` | `onPageHide()` | 暂停 Flutter 页面，处理引擎暂停逻辑 |
| `onBackPress` | 通过 `eventHub` 传递 | 将返回事件传递给 Flutter 侧，由 Flutter 决定是否 pop |

#### 完整代码示例（普通页面跳转场景）

```ts
import { FlutterEntry, FlutterView } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos/src/main/ets/view/FlutterPage';
import { common } from '@kit.AbilityKit';
import { Log } from '@ohos/flutter_ohos';

@Entry
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  private flutterEntry: FlutterEntry | null = null;
  private flutterView?: FlutterView

  aboutToAppear() {
    Log.d("Flutter", "Index aboutToAppear===");

    // 创建自定义 FlutterEntry 实例
    this.flutterEntry = new MyFlutterEntry(getContext(this))

    // 初始化 Flutter 引擎（创建引擎、注册插件、启动 Dart 入口）
    this.flutterEntry.aboutToAppear()

    // 获取 FlutterView，用于渲染 Flutter 内容
    this.flutterView = this.flutterEntry.getFlutterView()
  }

  aboutToDisappear() {
    Log.d("Flutter", "Index aboutToDisappear===");

    // 销毁 Flutter 引擎或回收资源
    this.flutterEntry?.aboutToDisappear()
  }

  // Navigation 的生命周期对应 onPageShow
  onPageShow() {
    Log.d("Flutter", "Index onPageShow===");
    this.flutterEntry?.onPageShow()
  }

  // Navigation 的生命周期对应 onPageHide
  onPageHide() {
    Log.d("Flutter", "Index onPageHide===");
    this.flutterEntry?.onPageHide()
  }

  build() {
    Stack() {
      // 使用 FlutterPage 组件渲染 Flutter 内容
      // viewId 来自 FlutterView，是 Flutter 渲染表面的唯一标识
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
  }

  onBackPress(): boolean {
    // 将返回事件通过 eventHub 传递给 Flutter 侧
    // Flutter 侧监听该事件后决定是否执行 Navigator.pop()
    // 返回 true 表示由应用自行处理返回事件，不走系统默认行为
    this.context.eventHub.emit('EVENT_BACK_PRESS')
    return true
  }
}
```

#### 关键说明

1. **`FlutterPage` 的 `viewId` 参数**：`viewId` 是 FlutterView 的唯一标识，通过 `this.flutterView?.getId()` 获取。`FlutterPage` 根据该 ID 找到对应的 Flutter 渲染表面，将内容绘制到原生页面中。

2. **返回键处理**：在混合开发中，返回键的行为由 Flutter 和原生共同决定。通过 `eventHub.emit('EVENT_BACK_PRESS')` 将返回事件传递给 Flutter 侧，Flutter 侧通过监听该事件来决定是否执行 `Navigator.pop()`。当 Flutter 侧没有更多页面可返回时，再由原生侧处理返回行为。

3. **生命周期必须完整调用**：如果遗漏 `aboutToAppear` 或 `aboutToDisappear`，会导致引擎无法正常创建或资源无法释放，可能造成内存泄漏或页面白屏。

---

## 配合 Navigation 使用 FlutterEntry

在 HarmonyOS 应用中，推荐使用 `Navigation` + `NavPathStack` 进行页面导航。此场景下，`FlutterEntry` 需要配合 `NavDestination` 使用，并通过自定义 `NavFlutterEntry` 处理 Flutter 侧 `SystemNavigator.pop()` 的原生返回行为。

### 为什么需要 NavFlutterEntry

在普通页面跳转场景中，Flutter 的 `SystemNavigator.pop()` 会直接退出应用。但在 Navigation 导航场景中，开发者通常希望 `SystemNavigator.pop()` 执行的是 `NavPathStack.pop()`（即返回上一个原生页面），而非退出整个应用。因此需要继承 `FlutterEntry` 创建 `NavFlutterEntry`，重写 `popSystemNavigator()` 方法，将 Flutter 的退出行为映射为 Navigation 的返回行为。

### 完整代码示例

```ts
import { FlutterEntry, FlutterView } from '@ohos/flutter_ohos';
import { FlutterPage } from '@ohos/flutter_ohos/src/main/ets/view/FlutterPage';
import { common } from '@kit.AbilityKit';
import { Log } from '@ohos/flutter_ohos';

@Builder
export function PageThreeBuilder() {
  PageThree()
}

@Component
export struct PageThree {
  private context = getContext(this) as common.UIAbilityContext
  private flutterEntry: FlutterEntry | null = null;
  private flutterView?: FlutterView
  pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      // 在 NavDestination 中渲染 Flutter 内容
      FlutterPage({ viewId: this.flutterView?.getId() })
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      // NavDestination 就绪后初始化 FlutterEntry
      this.init(context)
    })
    .onDisAppear(() => {
      // NavDestination 消失时销毁引擎资源
      this.flutterEntry?.aboutToDisappear()
    })
    .onShown(() => {
      // NavDestination 可见时恢复 Flutter 页面
      this.flutterEntry?.onPageShow()
    })
    .onHidden(() => {
      // NavDestination 不可见时暂停 Flutter 页面
      this.flutterEntry?.onPageHide()
    })
    .onBackPressed(() => {
      // 将返回事件传递给 Flutter 侧处理
      this.context.eventHub.emit('EVENT_BACK_PRESS')
      return true
    })
  }

  init(context: NavDestinationContext) {
    // 从 NavDestinationContext 获取路径栈
    let pathStack = context.pathStack
    this.pathStack = pathStack;

    // 从路径栈获取跳转参数
    let array = pathStack.getParamByName('pageThree') as Array<Record<string, Object>>;
    let params: Record<string, Object> = array.length > 0 ? array[0] : {};

    // 创建 NavFlutterEntry，传入 context、params 和 pathStack
    // params 用于传递路由参数给 Flutter 侧
    // pathStack 用于处理 SystemNavigator.pop() 的原生返回行为
    this.flutterEntry = new NavFlutterEntry(getContext(this), params, pathStack)
    this.flutterEntry.aboutToAppear()
    this.flutterView = this.flutterEntry.getFlutterView()
  }
}

class NavFlutterEntry extends FlutterEntry {
  pathStack?: NavPathStack;

  constructor(context: Context, params: Record<string, Object> = {}, pathStack?: NavPathStack) {
    // 将 params 传递给 FlutterEntry，用于配置引擎的初始路由等参数
    super(context, params)
    this.pathStack = pathStack;
  }

  popSystemNavigator(): boolean {
    // 重写此方法，将 Flutter 侧的 SystemNavigator.pop()
    // 映射为 Navigation 的 pathStack.pop()
    // 返回 true 表示已处理，不需要再走系统默认退出行为
    if (this.pathStack) {
      this.pathStack.pop();
      return true;
    }
    // 如果没有 pathStack，走默认行为（退出应用）
    return false;
  }
}
```

### Navigation 场景生命周期对应关系

| NavDestination 生命周期 | FlutterEntry 方法 | 说明 |
|--------------------------|-------------------|------|
| `onReady` | `aboutToAppear()` | NavDestination 就绪时创建引擎，此时可获取 NavDestinationContext |
| `onDisAppear` | `aboutToDisappear()` | NavDestination 从导航栈移除时销毁引擎 |
| `onShown` | `onPageShow()` | NavDestination 可见时恢复 Flutter 页面 |
| `onHidden` | `onPageHide()` | NavDestination 不可见时暂停 Flutter 页面 |
| `onBackPressed` | `eventHub.emit('EVENT_BACK_PRESS')` | 返回键事件传递给 Flutter |

### Navigation 路由参数传递

在 Navigation 导航中，可以通过 `NavPathStack` 将参数传递给 Flutter 页面：

1. **原生侧传参**：通过 `pathStack.pushPathByName('pageThree', params)` 传递参数
2. **FlutterEntry 接收**：在 `init` 方法中通过 `pathStack.getParamByName('pageThree')` 获取参数，并将参数传给 `NavFlutterEntry` 构造函数
3. **Flutter 侧接收**：Flutter 引擎初始化时，可通过 `route` 参数获取初始路由路径，也可通过 `MethodChannel` 接收原生传递的自定义参数

> **注意**：在 Navigation 场景中，`FlutterEntry` 的初始化必须在 `onReady` 回调中执行，不能在 `aboutToAppear` 中执行。因为 `NavDestinationContext`（包含 pathStack 和路由参数）仅在 `onReady` 时才可用。过早初始化会导致无法获取正确的导航上下文。

---

## 两种使用方式对比

| 特性 | 普通页面跳转（router） | Navigation 导航 |
|------|------------------------|------------------|
| 适用场景 | 简单页面跳转，单页面 Flutter 嵌入 | 多页面导航，复杂页面流转 |
| FlutterEntry 初始化时机 | `aboutToAppear` | `onReady` |
| 返回键处理 | `eventHub.emit('EVENT_BACK_PRESS')` | `eventHub.emit('EVENT_BACK_PRESS')` + `NavFlutterEntry.popSystemNavigator()` |
| SystemNavigator.pop 行为 | 退出应用 | `pathStack.pop()`（返回上一页） |
| 路由参数传递 | router params | NavPathStack params |
| 引擎销毁时机 | `aboutToDisappear` | `onDisAppear` |
| 推荐程度 | 简单场景可用 | 推荐（HarmonyOS 官方推荐 Navigation） |

---

## 注意事项

1. **FlutterEntry 生命周期必须完整调用**：`aboutToAppear` 和 `aboutToDisappear` 必须成对调用。遗漏 `aboutToDisappear` 会导致引擎资源未释放，造成内存泄漏。遗漏 `aboutToAppear` 会导致引擎未创建，页面白屏。

2. **onPageShow / onPageHide 不可省略**：这两个方法控制 Flutter 引擎的可见性状态。省略会导致 Flutter 页面在切换后台或被覆盖时仍持续渲染，浪费性能资源。

3. **FlutterEntry 初始化顺序**：必须先调用 `aboutToAppear()`，再调用 `getFlutterView()`。`getFlutterView()` 依赖引擎已创建，在引擎未初始化时调用会返回无效的 viewId。

4. **EntryAbility 必须实现 ExclusiveAppComponent**：如果 `EntryAbility` 未实现该接口或未在 `onCreate`/`onDestroy` 中调用 `FlutterManager` 的 push/pop 方法，Flutter 引擎在创建时无法获取正确的宿主上下文，可能导致引擎创建失败。

5. **Navigation 场景中 init 时机**：必须在 `NavDestination.onReady` 中初始化 `FlutterEntry`，不能在组件构造函数或 `aboutToAppear` 中初始化。`onReady` 才是 `NavDestinationContext` 可用的时机。

6. **onBackPress 返回 true**：`onBackPress()` 和 `onBackPressed()` 都必须返回 `true`，表示由应用自行处理返回事件。如果返回 `false`，系统会执行默认返回行为（退出页面或应用），跳过 Flutter 侧的返回处理逻辑。

7. **插件注册不可省略**：`GeneratedPluginRegistrant.registerWith(flutterEngine)` 必须在 `configureFlutterEngine` 中调用。省略会导致所有 Flutter 插件的原生端实现未绑定，Dart 侧调用时报 `MissingPluginException`。

8. **setWindowLayoutFullScreen**：在 `onWindowStageCreate` 中设置全屏布局是 Flutter 页面正常渲染的前提条件。如果不设置全屏，Flutter 页面可能出现布局偏移或无法覆盖整个屏幕的问题。

---

## 常见问题

### Q1：页面白屏，Flutter 内容不显示

**可能原因**：
- `FlutterEntry.aboutToAppear()` 未调用或调用顺序错误
- `EntryAbility` 未正确实现 `ExclusiveAppComponent` 接口
- `FlutterManager.pushUIAbility()` 或 `pushWindowStage()` 未在正确时机调用
- `FlutterPage` 的 `viewId` 为空或无效

**排查步骤**：
1. 检查 `aboutToAppear()` 是否在页面生命周期中正确调用
2. 检查 `EntryAbility.onCreate` 中是否调用了 `FlutterManager.getInstance().pushUIAbility(this)`
3. 检查 `getFlutterView()` 是否在 `aboutToAppear()` 之后调用
4. 检查日志中是否有引擎创建失败的错误信息

### Q2：Flutter 插件调用报 MissingPluginException

**不要直接认定是 `registerWith` 漏调**。`MissingPluginException` 在 OHOS 上有 3 类根因（生命周期缺 `attachToAbility`、漏调 `registerWith`、插件缺 ohos 平台层），仅看异常日志无法区分。

请按"根因排查决策树"顺序排查，详见 [Flutter 插件调用报 MissingPluginException](../faq/plugin-adaptation-faq.md#section592016)。

> 本文档"注意事项"第 7 条所述（漏调 `GeneratedPluginRegistrant.registerWith`）仅是其中一类根因（根因 A），请勿跳过根因 C（生命周期）的排查。

### Q3：Navigation 场景中 SystemNavigator.pop() 退出整个应用而非返回上一页

**可能原因**：使用了普通的 `FlutterEntry` 而非 `NavFlutterEntry`，或 `NavFlutterEntry.popSystemNavigator()` 未正确实现。

**解决方案**：继承 `FlutterEntry` 创建 `NavFlutterEntry`，重写 `popSystemNavigator()` 方法，在方法中调用 `pathStack.pop()` 并返回 `true`。

### Q4：页面切换后 Flutter 内容不更新或卡住

**可能原因**：`onPageShow` / `onPageHide` 未正确调用，导致引擎未恢复可见状态。

**解决方案**：确保在页面可见性变化时调用 `flutterEntry?.onPageShow()` 和 `flutterEntry?.onPageHide()`。

---

## Demo 参考

完整 demo 请参考 [flutter_page_sample2](../../../ohos/flutter_page_sample2/)。

| Demo | 说明 | 关键文件位置 |
|------|------|-------------|
| flutter_page_sample2 | 普通页面跳转与 Navigation 导航两种方式完整示例 | `pages/Index.ets`、`pages/PageThree.ets` |
