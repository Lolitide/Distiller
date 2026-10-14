# 页面不可见时暂停绘制

冗余绘制通常表现为：页面处于不可见、局部不可见或处于后台状态时，仍继续执行平台视图刷新、动画持续生成纹理、WebView 反复重绘等动作，导致 CPU/GPU 资源浪费、功耗增加以及设备发热。为了降低这类无意义工作，Flutter OHOS 引入了"页面不可见时暂停"和"WebView/PlatformView 防冗余绘制"的方案。

---

## 功耗测试工具

### 1. 页面可见性与生命周期检查

可确认：

- 页面不可见时，Flutter 是否收到 `paused`；
- 页面重新可见时，是否收到 `resumed`；
- 页面可见区域完全不可见时，是否能触发暂停逻辑。

### 2. PlatformView / WebView 纹理生成状态检查

可确认：

- WebView、视频或动画类平台视图在页面不可见时，是否仍继续生成外部纹理；
- 可见区变化监听是否能在阈值条件下触发 `onInactive()`；
- 重新回到可视区域后，是否自动恢复 `onActive()`。

### 3. 功耗观测建议

建议在以下场景下观察：

- 页面置于后台或不可见 视图区域后，GPU/CPU 是否快速下降；
- WebView 和动画页面在不可见时是否仍不断绘制或提交；
- 页面再次重新显示时，是否恢复正常刷新，而不是持续空跑；
- 同一 Engine 被多个宿主共享时，是否能够正确聚合 visible 状态，避免重复派发生命周期。

---

## 使用场景

防冗余绘制方案适用于以下典型场景：

- 页面切换至后台；
- 页面被移出可视区域，且占比低于阈值；
- WebView 或动画型平台视图没有有效可见内容时；
- 需要降低 GPU 与纹理持续生成负载的页面。

## 前置条件

### API 等级说明

区域可见性监听能力依赖 API 20 以上环境，低版本设备上该监听不会生效。

### flutter_flutter

此功能依赖 Flutter SDK 代码仓中的版本适配能力，建议使用支持此功能的 Flutter 分支。Flutter 升级请参照[升级文档](../version/flutter-oh-upgrade-guide.md)。

### 页面级可见性开关

本方案中，默认行为已开启不可见暂停能力：

<!-- TODO: 待补充 import 语句 -->

```ts
shouldPauseWhenInvisible = true
```

开发者可在 `FlutterPage` 中显式控制：

```ts
FlutterPage({
  viewId: this.viewId,
  shouldPauseWhenInvisible: false
})
```

说明：

- `true`：启用可见区域监听；页面不可见或区域完全不可见时，可能触发 paused；
- `false`：不使用区域可见性监听；生命周期主要由页面 show/hide 路径控制。

### PlatformView 可见区事件

关键接口包括：

- `PlatformViewVisibleAreaEventOptions`
- `getPlatformViewVisibleAreaEventOptions()`
- `onInactive()`
- `onActive()`

对 `EmbeddingNodeController` 和 `PlatformViewsController` 做了增强：

- 页面可见区域变化时，触发 visible area callback；
- 当页面从"可见"转为"不可见"时，调用 `platformView.onInactive()`；
- 当页面重新进入可见区，调用 `platformView.onActive()`；
- 当 `top` / `left` 均变成 `NaN`，且此前仍为正常值时，判定页面已从可见转不可见。

### 详情

#### 1 页面不可见时暂停的设计目标

页面不可见时暂停能力的目的，是为了避免"Flutter 页面虽然未销毁，但在后台或不可见状态下仍然继续执行生命周期/动画/纹理生成"等无效行为。这样做的收益包括：

- 不再对后台页面不断请求新纹理；
- 降低 UI 线程和渲染线程上的无意义工作；
- 减少后台发热和功耗；
- 避免在页面不可见期出现不必要的绘制和显示更新。

对一个共享 Engine 的多宿主场景，这一能力尤其重要，因为多个宿主会复用同一套 Flutter 运行时资源，必须确保可见性聚合正确。

#### 2 WebView / PlatformView 防冗余绘制机制

- 监听 `commonEvent.setOnVisibleAreaApproximateChange`；
- 根据 `ratios`、`expectedUpdateInterval` 等参数判断当前平台视图是否进入低可见区；
- 若当前可见比例低于 `onInactiveThreshold` 且视图正在收缩，则调用 `onInactive()`；
- 若当前可见比例高于 `onActiveThreshold` 且视图正在扩张，则调用 `onActive()`。

#### 3 关键判定逻辑

在 `PlatformViewsController` 中，新增了一段判断：

> 当 `top` 和 `left` 均为 `NaN`，但之前为正常值时，说明当前页面已经从可见状态切换到了不可见状态。

这类判断用于：

- 区分正常的布局参数和页面中断/移除场景；
- 便于在更接近真实用户视角变化的时刻，及时调用 `notifyPlatformViewInvisible()`；
- 让平台视图提前进入 `onInactive()`，从而减少其持续绘制。

同时，`EmbeddingNodeController` 中还有一个 `notifyPlatformViewInvisible()` 入口，用于集中处理平台视图不可见时的暂停操作。

#### 4 页面可见性聚合

共享 Engine 的情况下，多宿主间可能存在多个页面同时存在，但仅有部分页面真正显示在用户前台。为避免"某个宿主状态错乱导致重复恢复/暂停"，此次方案设计了聚合机制：

- 监听页面区域变化；
- 判断当前页面是否真的进入不可见状态；
- 若该状态会影响平台视图，统一调度 `paused/resumed` 或 `onInactive()/onActive()`。

这样可以避免多个宿主竞争导致的重复或错误生命周期事件，同时减少无意义渲染和动画资源占用。

---

## 适配流程

### 第一步：确认设备 API 等级

确认目标设备支持 API 20+，否则可见性监听不会生效。

### 第二步：检查可见性开关配置

在页面接入层检查是否启用 `shouldPauseWhenInvisible`，优先使用默认 `true` 配置。

### 第三步：确认 PlatformView 生命周期回调

若页面中存在 WebView、平台视图或视频动画，需要确认其 `onInactive()` / `onActive()` 逻辑已实现。

### 第四步：注册可见区事件回调

在 `EmbeddingNodeController` 或对应宿主中确认 `setPlatformViewVisibleAreaEventCallback()` 已注册。

### 第五步：接入 NaN 判定逻辑

在 `PlatformViewsController` 中确认 `NaN` 判定和迁移逻辑已接入。

### 第六步：验证暂停行为

运行页面，并观察页面不可见后是否自动触发暂停行为。

### 第七步：验证恢复逻辑

重新回到页面后，确认恢复逻辑是否正常启动，并验证是否减少无意义绘制。

---

## 总结

防冗余绘制方案的核心目标，是在"页面或平台视图不再对用户可见时"，立即停掉不必要的 UI 更新、动画和纹理生成动作，从而减少无效渲染和功耗。

这项能力的价值体现在：

- 页面不可见时及时触发 `paused` / `onInactive()`；
- 页面重新可见时自动恢复 `resumed` / `onActive()`；
- WebView、视频和动画型平台视图不再后台空跑；
- 共享 Engine 场景下也能正确聚合状态与恢复逻辑。

对于 Flutter OHOS 开发者而言，这类能力非常关键，它可帮助应用在后台和非可见状态下保持较低的功耗，并在用户重新返回页面时快速恢复正常体验。

---

## 示例代码

### 1. 页面级默认开关

```ts
FlutterPage({
  viewId: this.viewId,
  shouldPauseWhenInvisible: true
})
```

> 本文档最新改动位于：[仓库链接地址](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-eliminate-redundant-drawing.md)
