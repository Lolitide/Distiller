# Flutter 分栏功能（平行视界）接入指导

> **版本说明：** 平行视界（分栏）特性自 Flutter `3.35.8-ohos-1.0.3` 版本开始支持。

## 1. 分栏功能说明

Flutter 分栏功能为应用提供横竖屏自适应的分栏布局，实现类似平板/折叠屏设备的左右分栏显示效果：

| 屏幕状态 | 布局表现 |
|----------|----------|
| 横屏/宽屏 | 左右两侧同时显示，左侧主页 + 右侧详情页 |
| 竖屏/窄屏 | 单栏显示，智能切换主页或详情页 |
| 折叠屏展开 | 自动切换为分栏布局 |
| 折叠屏折叠 | 自动切换为单栏布局 |

**功能特点:**
- 自动适应屏幕尺寸变化，无需应用代码修改
- 分栏功能默认关闭，通过配置文件启用

**示例应用：**
完整示例代码请参见 [split_view_sample](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/ohos/split_view_sample)，该 Demo 实现了 8 种路由方案，用于测试分栏功能在不同路由范式下的表现。

**分栏功能支持范围:**
- 当前分栏功能支持基于 Navigator 的路由方式和基于 Router 的声明式路由方式（包括 RouterDelegate、RouterConfig、go_router库等）
- Router 模式基于单 NavigatorState + 双 Overlay 实现，在 Navigator 底层统一处理，对上层透明
- **已知限制：**
  - go_router 兼容性理论上已支持，建议充分验证

**效果图:**

![split_view_picture.png](../media/rendering-engine/split_view_picture.png)

## 2. 分栏开启说明

分栏功能默认关闭，应用只需在指定位置放置 `split_config.json` 配置文件，并将 `enableWideWindowSplit` 或 `enableSquareWindowSplit` 设为 `true` 即可启用分栏。SDK 在应用启动时自动加载该配置文件，无需在 Dart 代码中做任何初始化操作。配置文件中还可以指定主页路由名、全屏页面列表等选项，详见下方各配置项说明。

### 2.1 配置文件位置

```
ohos/entry/src/main/resources/rawfile/split_config.json
```

### 2.2 配置文件内容

```json
{
  "splitOptions": {
    "enableWideWindowSplit": false,
    "enableSquareWindowSplit": true,
    "homePage": "/",
    "fullScreenPages": ["/videoPlayer", "/imageViewer"],
    "enableReducedContainerSize": true,
    "supportLandscapeFullscreen": true
  }
}
```

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `enableWideWindowSplit` | bool | false | 宽屏设备分栏开关 |
| `enableSquareWindowSplit` | bool | false | 方屏设备分栏开关 |
| `homePage` | String? | null | 主页路由名，null 时自动识别主页 |
| `fullScreenPages` | List<String> | [] | 强制全屏显示的页面路由名列表 |
| `enableReducedContainerSize` | bool | true | 组件宽度基于屏幕一半显示 |
| `supportLandscapeFullscreen` | bool | true | 横屏时是否全屏显示 |

### 2.3 配置项详解

#### enableWideWindowSplit

**功能说明：** 宽窗口分栏开关，控制是否在宽屏幕设备上启用分栏布局。

| 值 | 效果 |
|---|---|
| `true` | 宽屏幕设备启用分栏布局 |
| `false`（默认） | 宽屏幕设备不启用分栏布局 |

**适用场景：**
- `true`：适用于平板、pc、折叠屏展开态等宽屏幕设备，希望在横屏状态下显示分栏布局
- `false`：适用于不希望在宽屏幕上启用分栏的应用

**触发条件：**
- 屏幕宽度 > 600dp 且高度 > 600dp
- 屏幕宽高比 > 1.2
- 横屏状态

#### enableSquareWindowSplit

**功能说明：** 方形屏幕分栏开关，控制是否在方形屏幕设备上启用分栏布局。

| 值 | 效果 |
|---|---|
| `true` | 方形屏幕设备启用分栏布局 |
| `false`（默认） | 方形屏幕设备不启用分栏布局 |

**适用场景：**
- `true`：适用于方形屏幕设备（如两折叠屏展开态），希望在方形屏幕上显示分栏布局
- `false`：适用于不希望在方形屏幕上启用分栏的应用

**触发条件：**
- 屏幕宽度 > 600dp 且高度 > 600dp
- 屏幕宽高比、高宽比均小于1.2

#### homePage

**功能说明：** 指定主页的路由名，用于分栏布局的主页识别。

| 值 | 效果 |
|---|---|
| 路由名（如 `/home`） | 明确指定主页路由，分栏以该页面为左侧固定页面 |
| ``（默认） | 自动识别主页 |

**适用场景：**
- 明确指定路由名：适用于有明确主页页面的应用，确保分栏左侧始终显示正确的页面
- 自动识别：适用于使用 Navigator 路由模式的简单应用，由 SDK 自动判断主页

>  ⚠️ 重要提示：Router 路由模式（RouterDelegate、RouterConfig、go_router）不支持自动检测。路由器模式的应用必须填写 homePage 字段。如果留空，分屏视图将无法正常工作。

**Navigator 模式配置：**

Navigator 模式下，配置文件中的 homePage 值需与代码中的路由配置保持一致，按以下方式设置：

```dart
// 方式1：存在home参数
return MaterialApp(
  home: const HomePage(),
  onGenerateRoute: (RouteSettings settings) {
    switch (settings.name) {
      case '/first':
        return MaterialPageRoute(builder: (_) => const FirstPage(), settings: settings);
      // ... 其它页面
      default:
        return MaterialPageRoute(builder: (_) => const UnknownPage(), settings: settings);
    }
  },
  // routes: { *** } routes parameter is mutually exclusive with onGenerateRoute parameter
);


// 方式2：使用initialRoute 和 onGenerateRoute
return MaterialApp(
  initialRoute: '/splash',
  onGenerateRoute: (settings) {
    if (settings.name == '/home') {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => HomePage(), // 配置文件中要设置为主页的settings.name，即'/home'
      );
    }
    // ...其它页面
  }
);

// 方式3：使用initialRoute和 routes 路由表
return MaterialApp(
  initialRoute: '/splash',
  routes: {
    "/home": (context) => const HomePage(), //配置文件中要配置为主页的键名，即'/home'
    // ...其它页面
  }
);

```

**Router 模式配置：**

Router 模式（RouterDelegate、RouterConfig）使用 `Page` 对象管理路由，路由名由 `Page.name` 属性决定：

```dart
// RouterDelegate / RouterConfig 中的 Page 配置
pages: [
  MaterialPage(
    name: '/home',  // Page.name 决定 RouteSettings.name
    child: HomePage(),
  ),
]
```

**go_router 模式配置：**

go_router 使用 `GoRoute` 定义路由，路由名由 `GoRoute.name` 属性决定。

注意：当页面没有name参数时，go_router库会用path参数生成RouteSettings.name。

```dart
// go_router 路由配置
GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      name: '/home',  // GoRoute.name 决定 RouteSettings.name，需与配置文件中的 homePage 一致
      builder: (context, state) => HomePage(),
    ),
  ],
)
```

**自动识别主页逻辑：**
Navigator 路由模式下，当 `homePage` 配置为空时，SDK 会按以下顺序自动判断主页：
1. MaterialApp/CupertinoApp 的 `home` 参数
2. `routes` 数组中的 `/home`、`/`、`/index` 路由
3. `initialRoute` 参数指定的路由
4. 以上都没有则报错退出

Router 路由模式下暂不支持自动识别主页。

**注意事项：**
> - 使用 `Navigator.pushNamed` 或 `MaterialPageRoute(settings: ...)` 携带路由名跳转，才能正确判断目标页面是否是主页

#### fullScreenPages

**功能说明：** 指定需要强制全屏显示的页面路由名列表。

| 值 | 效果 |
|---|---|
| 路由名列表（如 `["/videoPlayer"]`） | 进入这些页面时自动切换为全屏单栏布局 |
| `[]`（默认） | 无全屏页面 |

**适用场景：**
- 视频播放页面、图片查看页面、游戏页面等需要全屏显示的场景
- 进入全屏页面后，分栏布局自动禁用，退出后自动恢复

**注意事项：**
- 多个路由名用逗号分隔
- 使用 `Navigator.pushNamed` 或 `MaterialPageRoute(settings: ...)` 携带路由名跳转，才能正确判断目标页面是否是强制全屏页

#### enableReducedContainerSize

**功能说明：** 控制分栏模式下 MediaQuery 返回的宽度值。

| 值 | 效果 |
|---|---|
| `true`（默认） | 分栏激活时，MediaQuery 返回的宽度为屏幕宽度的一半 |
| `false` | MediaQuery 返回的宽度无变化，仍为实际屏幕宽度 |

**适用场景：**
- `true`：适用于应用组件需要根据分栏宽度自适应布局的场景，通过 `MediaQuery.of(context).size.width` 获取的宽度会自动适配为屏幕一半
- `false`：适用于应用自行处理宽度适配，或不需要 MediaQuery 宽度约束的场景

**技术实现：**
- 当 `enableReducedContainerSize: true` 且分栏激活时，SDK 会通过 MediaQuery 修改宽度约束，使组件获取的宽度为屏幕宽度的一半
- 应用可通过 `MediaQuery.of(context).size.width` 获取适配后的宽度值

#### supportLandscapeFullscreen

**功能说明：** 控制横屏全屏显示的触发条件。

| 值 | 效果 |
|---|---|
| `true`（默认） | 当页面强制横屏时，自动禁用分栏，切换为全屏单栏显示 |
| `false` | 即使页面强制横屏，仍保持分栏布局 |

**适用场景：**
- `true`：适用于应用中存在主动请求以横屏显示的页面，且应用自己已按照横屏方向实现布局设计，不希望分栏改变横屏布局设计。
- `false`：适用于应用没有主动请求横屏显示的页面，或即使主动请求横屏也希望分栏生效。

**触发条件：**
- 页面设置了强制横屏（`SystemChrome.setPreferredOrientations`）
- 同时 `supportLandscapeFullscreen: true`

**Flutter 申请显示方向的 API：**

Flutter 应用通过 `SystemChrome.setPreferredOrientations` 向原生系统申请屏幕方向，如果参数中不包含竖屏方向（即只有 landscapeLeft/landscapeRight），则认为是应用主动要求横屏。

**配合使用：**
- 可与 `fullScreenPages` 配置项配合使用
- `fullScreenPages` 按路由名控制全屏，`supportLandscapeFullscreen` 按屏幕方向控制全屏

### 2.4 配置示例

**基础配置（自动识别主页）：**
```json
{
  "splitOptions": {
    "enableWideWindowSplit": true
  }
}
```

**指定主页和全屏页面：**
```json
{
  "splitOptions": {
    "enableWideWindowSplit": true,
    "homePage": "/home",
    "fullScreenPages": ["/videoPlayer", "/imageViewer"]
  }
}
```

## 3. 注意事项

### 3.1 路由转发执行流程

分栏功能将应用运行划分为两个阶段，路由由单 NavigatorState 统一管理，通过 Overlay 分配到左右两侧显示：

| 阶段 | 条件 | 左侧显示 | 右侧显示 | 路由跳转行为 |
|------|------|----------|----------|--------------|
| 阶段1 | 主页未显示 | 目标页面（开屏页/登录页等） | 占位页 | **在左侧 Overlay 显示**，右侧不变 |
| 阶段2 | 主页已显示 | 主页 | 详情页或占位页 | **分配到右侧 Overlay 显示** |

**执行流程说明：**

1. **阶段1 - 主页未显示：**
   - 应用启动时可能经过开屏页、登录页等中间页面
   - 所有页面跳转都分配到左侧 Overlay
   - 右侧保持占位页不变
   - 不进行路由转发

2. **阶段切换 - 主页显示：**
   - 当主页页面真正显示时（跳转到主页或返回到主页）
   - SDK 检测到当前路由名与配置的主页路由名匹配
   - 自动切换到阶段2模式

3. **阶段2 - 主页已显示：**
   - 左侧固定显示主页
   - 后续所有详情页跳转自动分配到右侧 Overlay 显示
   - 右侧动态切换详情页内容

**关键点：**
- 只有主页显示后，详情页才会分配到右侧
- 开屏页 → 登录页 → 主页 的流程中，前两个页面都在左侧显示
- 主页显示后，点击详情项才会显示在右侧
- 路由历史在单一 NavigatorState 中统一维护，左右 Overlay 仅负责视觉呈现

### 3.2 路由方案选择

分栏功能支持以下路由配置方案：

| 方案 | 路由方式 | 配置项 | 分栏兼容性 | 限制说明 |
|------|----------|--------|------------|----------|
| 方案1 | Navigator (MaterialApp) | `initialRoute` + `onGenerateRoute` | ✅ 完全兼容 | 推荐使用，支持完整流程 |
| 方案2 | Navigator (MaterialApp) | `initialRoute` + `routes` | ✅ 完全兼容 | 支持开屏页 → 登录页 → 主页流程 |
| 方案3 | Navigator (MaterialApp) | `home` + `onGenerateRoute` | ⚠️ 部分兼容 | **不支持开屏页/登录页流程**，启动直接进入主页 |
| 方案4 | Navigator (MaterialApp) | `home` + `routes` | ⚠️ 部分兼容 | **不支持开屏页/登录页流程**，启动直接进入主页 |
| 方案5 | Navigator (CupertinoApp) | 同方案1-4 | ✅ 完全兼容 | 与 MaterialApp 等效 |
| 方案6 | Router (MaterialApp.router) | `RouterDelegate` + `pages` | ✅ 已支持 |  |
| 方案7 | Router (MaterialApp.router) | `RouterConfig` | ✅ 已支持 |  |
| 方案8 | Router (MaterialApp.router) | `go_router` 库 | ✅ 已支持 | Overlay 方案对 go_router 的 `_CustomNavigator` wrapper 生效，建议充分验证 |

**限制原因：**
- `home` 直接指定首页 Widget，应用启动直接进入主页
- 此时无法使用 `initialRoute: '/splash'` 设置开屏页作为启动页面

**建议：**
- 需要开屏页/登录页流程的应用，使用方案1或方案2
- 简单应用可直接使用方案3或方案4
- Router 模式优先使用方案8（GoRouter库）

### 3.3 路由 API 使用限制

#### 3.3.1 Route settings 参数

**必须保留 `settings` 参数，否则分栏功能受限：**

| Route 创建方式 | settings | 路由名 | 分栏功能 |
|----------------|----------|--------|----------|
| `MaterialPageRoute(settings: settings, ...)` | ✅ 有 | 有效 | ✅ 可识别主页/全屏页 |
| `MaterialPageRoute(builder: ...)` | ❌ 无 | null | ⚠️ 无法识别主页/全屏页 |
| `Navigator.pushNamed('/detail')` | ✅ 自动 | '/detail' | ✅ 可识别主页/全屏页 |

**缺少 settings 的影响：**
- 无法判断路由是否为主页 → `homePage` 配置失效
- 无法判断路由是否为全屏页 → `fullScreenPages` 配置失效
- 分栏默认行为仍生效，但特殊页面识别失效

**正确用法：**
```dart
// ✅  推荐：使用 pushNamed
Navigator.pushNamed(context, '/detail');

// ✅ 推荐：onGenerateRoute 中保留 settings
onGenerateRoute: (settings) {
  return MaterialPageRoute(
    settings: settings,  // 保留 settings
    builder: (context) => DetailPage(),
  );
}

// ✅ 推荐：手动设置 RouteSettings
Navigator.push(
  context,
  MaterialPageRoute(
    settings: RouteSettings(name: '/detail'),
    builder: (context) => DetailPage(),
  ),
);

// ❌ 避免：不设置 settings
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DetailPage(),  // 无法识别路由名
  ),
);
```

#### 3.3.2 支持的路由 API

所有 Navigator 路由 API 都支持，分栏行为如下：

| API | 阶段1行为 | 阶段2行为 |
|-----|-----------|-----------|
| `push(Route)` | 左侧 Overlay 推入 | 右侧 Overlay 推入 |
| `pushNamed(String)` | 左侧 Overlay 推入 | 右侧 Overlay 推入 |
| `pushReplacement(Route)` | 左侧 Overlay 替换 | ⚠️ 从主页发起时转为普通 push（详见下方说明） |
| `pushAndRemoveUntil(Route, predicate)` | 左侧 Overlay 推入并清栈 | ⚠️ 从主页发起时转为普通 push（详见下方说明） |
| `pop()` | 弹窗优先 → 右侧 → 左侧 | 弹窗优先 → 右侧 → 左侧 |
| `canPop()` | 右侧优先检查 | 右侧优先检查 |
| `maybePop()` | 右侧优先 | 右侧优先 |

**`pushReplacement` / `pushAndRemoveUntil` 从主页发起时的特殊行为：**

当左侧显示主页后，左侧固定为主页。当从主页调用 `pushReplacement` 或 `pushAndRemoveUntil` 时，由于主页不能被替换或移除（否则左侧空白），SDK 会将其**降级为普通 `push`**，详情页仍分配到右侧 Overlay。这是已知行为而非 bug。

#### 3.3.3 不支持的路由模式

**不支持三元表达式判断主页：**
```dart
// ❌ 不支持：无法识别
MaterialApp(
  home: isLoggedIn ? HomePage() : LoginPage(),
);

// ✅ 正确做法：使用 initialRoute + 路由表
MaterialApp(
  initialRoute: isLoggedIn ? '/home' : '/login',
  routes: {
    '/login': (context) => LoginPage(),
    '/home': (context) => HomePage(),
  },
);
```

### 3.4 弹窗处理注意事项

分栏模式下 PopupRoute（对话框、菜单等）自动显示在有内容的一侧：

| 右侧状态 | 弹窗位置 | 遮罩层 |
|----------|----------|--------|
| 占位页 | 左侧 | 右侧同步遮盖 |
| 详情页 | 右侧 | 左侧同步遮盖 |

**无需额外处理：**
- SDK 自动判断弹窗位置
- SDK 自动添加同步遮罩层
- 弹窗关闭时自动移除遮罩层

**注意事项：**
- 弹窗 push/pop 会触发左右两侧的 Overlay 操作
- **`useRootNavigator` 差异：** `showModalBottomSheet`、`showMenu`、`showSearch` 等 API 默认 `useRootNavigator: false`，在分栏场景下需显式设置为 `true`，才能正确显示蒙层。混合路由场景（如从 Navigator 跳转 Router 页面）下尤其重要

```dart
// ❌ 分栏下蒙层不正确
showModalBottomSheet(
  context: context,
  builder: (context) => SheetContent(),
);

// ✅ 需显式设置 useRootNavigator: true
showModalBottomSheet(
  context: context,
  useRootNavigator: true,  // 关键
  builder: (context) => SheetContent(),
);
```

### 3.5 生命周期注意事项

**生命周期回调保持原有行为：**

分栏模式采用单一 NavigatorState + 双 Overlay 方案，路由生命周期回调的行为与普通 Flutter 应用一致：

- 路由在单一 NavigatorState 中统一管理
- RouteObserver/RouteAware 使用方式不变，无需任何额外处理
- `didPush`、`didPop`、`didPopNext`、`didChangeNext` 等回调按 Flutter 标准行为触发

### 3.6 页面切换动效注意事项

分栏模式支持自定义 PageRoute 动效：

| 动效类型 | 支持状态 |
|----------|----------|
| MaterialPageRoute | ✅ 支持 |
| CupertinoPageRoute | ✅ 支持 |
| 自定义 PageRoute | ✅ 支持 |
| 无动效路由 | ✅ 支持 |

### 3.7 返回手势注意事项

系统返回键/手势返回由 SDK 自动处理：

**返回优先级：**
1. 弹窗正在显示 → 关闭弹窗
2. 右侧 Overlay 有可 pop 路由 → 右侧 pop
3. 左侧 Overlay 有可 pop 路由 → 左侧 pop
4. 两侧都不可 pop → 退出应用

**无需额外处理：**
- SDK 自动拦截 `didPopRoute`
- 返回逻辑在单一 NavigatorState 的路由历史中按 Overlay 分配顺序执行
- 返回逻辑按优先级执行
- 应用可通过 `WillPopScope` 自定义返回行为

### 3.8 全屏页面注意事项

某些页面（如视频播放）需要强制全屏：

**配置方式：**
```json
{
  "splitOptions": {
    "fullScreenPages": ["/videoPlayer", "/imageViewer"]
  }
}
```

**效果：**
- 进入全屏页面：自动切换为单栏布局
- 离开全屏页面：恢复分栏布局

### 3.9 屏幕旋转/折叠屏注意事项

SDK 自动监听屏幕变化：

| 场景 | 自动行为 |
|------|----------|
| 竖屏 → 横屏 | 单栏 → 分栏 |
| 横屏 → 竖屏 | 分栏 → 单栏 |
| 折叠屏展开 | 单栏 → 分栏 |
| 折叠屏折叠 | 分栏 → 单栏 |

**分栏开启条件：**
- 宽度 > 600dp 且 高度 > 600dp
- 根据屏幕是宽屏还是方屏，由不同配置项决定

**无需额外处理：**
- `didChangeMetrics()` 自动触发
- 路由栈和状态完整保留

**常见问题排查：**

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| 分栏不生效 | 配置文件未启用 | 检查 `enableWideWindowSplit: true` |
| 主页识别错误 | `homePage` 配置错误 | 按2.3节homePage项说明配置 |
| 详情页不转发 | `settings` 缺失 | 确保保留 settings 参数 |
| 全屏页面仍分栏 | `fullScreenPages` 未配置 | 添加路由名到配置列表 |
| RouterConfig 系统返回键退出应用 | 未设置 `RootBackButtonDispatcher` | 在 `RouterConfig` 中设置 `RootBackButtonDispatcher()` |
| 弹窗蒙层不显示 | `useRootNavigator` 未设置 | `showModalBottomSheet` 等需显式设置 `useRootNavigator: true`，详见 3.4 节 |
| GoRouter 全屏页不生效 | `GoRoute.name` 与配置不匹配 | 确保 `GoRoute.name` 与 `fullScreenPages` 配置完全一致（如 `/video`） |
| 从主页 `pushReplacement` 行为异常 | 主页不可替换 | 这是已知行为，SDK 降级为普通 push，详见 3.3.2 节说明 |