# 多设备适配问题定位指南

> 返回 [README.md](README.md)

---

## 1. 概述

Flutter OHOS 多设备适配涉及分栏(SplitView)、安全区域避让、折叠屏 DisplayFeature、多窗口、DPI 缩放、LTPO 自适应刷新等多个子系统。这些子系统的问题通常表现为布局异常、避让失效、帧率不正确等，不会直接导致崩溃或卡死，但严重影响用户体验。

### 1.1 问题分类

| 问题类型 | 典型症状 | 本文章节 |
|---------|---------|---------|
| 分栏不生效/异常 | 宽屏未分栏、主页识别错误、弹窗蒙层缺失 | [§2](#2-分栏splitview问题) |
| 安全区域避让失效 | 内容被状态栏/挖孔/窗口按钮遮挡 | [§3](#3-安全区域避让问题) |
| 折叠屏适配异常 | 折痕区域未避让、DisplayFeature 缺失 | [§4](#4-折叠屏-displayfeature-问题) |
| DPI 缩放异常 | 界面过大/过小、自定义 DPI 不生效 | [§5](#5-dpi-缩放问题) |
| LTPO 帧率异常 | 滑动帧率不提升、转场帧率不切换 | [§6](#6-ltpo-自适应刷新问题) |
| 多窗口/自由窗口异常 | 窗口缩放布局不刷新、窗口按钮遮挡 | [§7](#7-多窗口自由窗口问题) |

### 1.2 快速定位流程

```
多设备适配异常
│
├─ 分栏不生效
│  ├─ 搜索 HiLog: "SplitView" / "split_view"
│  │  → 检查配置解析日志，详见 §2
│  └─ 搜索 HiLog: "split_view_config_system"
│     → 检查引擎推送配置，详见 §2.3
│
├─ 内容被系统 UI 遮挡
│  ├─ 搜索 HiLog: "avoidAreaChangeCallback"
│  │  → 检查避让区域更新，详见 §3
│  └─ 搜索 HiLog: "windowTitleButtonRect" / "windowDecor"
│     → 检查窗口装饰避让，详见 §3.3
│
├─ 折叠屏折痕未避让
│  ├─ 搜索 HiLog: "displayFeatures" / "Fold status"
│  │  → 检查 DisplayFeature 构建，详见 §4
│  └─ 搜索 HiLog: "foldStatusChange"
│     → 检查折叠状态监听，详见 §4.2
│
├─ 界面尺寸异常
│  ├─ 搜索 HiLog: "device pixel ratio" / "densityUpdate"
│  │  → 检查 DPI 缩放，详见 §5
│  └─ 搜索 HiLog: "windowSizeChangeCallback"
│     → 检查窗口尺寸变化，详见 §5.2
│
├─ 帧率不随场景变化
│  ├─ 搜索 HiLog: "LTPO" / "velocity" / "nativevsync"
│  │  → 检查 LTPO 速度上报，详见 §6
│  └─ 检查 framesconfig.json 配置文件
│     → 详见 §6.3
│
└─ 窗口缩放布局不刷新
   └─ 搜索 HiLog: "windowSizeChangeCallback" / "avoidAreaChange"
      → 检查窗口变化回调，详见 §7
```

---

## 2. 分栏(SplitView)问题

### 2.1 分栏不生效

**排查步骤**：

**第 1 步**：确认配置文件存在且正确

```bash
# 检查配置文件是否存在
hdc shell ls /data/app/.../entry/resources/rawfile/split_config.json
```

配置文件位置：`ohos/entry/src/main/resources/rawfile/split_config.json`

**第 2 步**：搜索配置解析日志

```bash
hdc shell hilog | grep -E "SplitView|split_view|SplitViewConfig"
```

| 日志关键字 | 含义 | 正常/异常 |
|-----------|------|----------|
| `SplitView: Main page determined by config homePage: /home` | 通过 homePage 配置识别主页 | ✅ 正常 |
| `SplitView: Main page determined by widget.home` | 通过 home 参数识别主页 | ✅ 正常 |
| `SplitView: Main page determined by routes: /home` | 通过 routes 识别主页 | ✅ 正常 |
| `SplitView: Main page determined by initialRoute` | 通过 initialRoute 识别主页 | ✅ 正常 |
| `SystemChannel config parse failed: ...` | 配置 JSON 解析失败 | ❌ 异常 |
| `SplitViewConfig: Failed to decode placeholder icon: ...` | 占位图标 base64 解码失败 | ⚠️ 非致命 |
| `SplitViewConfig: Some fullScreenPages items are not strings` | fullScreenPages 配置项类型错误 | ⚠️ 部分失效 |
| `Cannot determine main page for split screen` | 无法识别主页（抛出 FlutterError） | ❌ 异常 |

**第 3 步**：确认触发条件

分栏激活需同时满足：
- 逻辑宽度 > 600vp **且** 逻辑高度 > 600vp
- 宽高比 > 1.2（宽屏模式）或 宽高比 ≤ 1.2（方屏模式）
- 对应配置项已启用（`enableWideWindowSplit` / `enableSquareWindowSplit`）

### 2.2 主页识别错误

**常见原因**：

| 原因 | 现象 | 解决方案 |
|------|------|---------|
| Router 模式未配置 homePage | 主页无法识别，分栏不工作 | Router 模式**必须**填写 homePage |
| MaterialPageRoute 未保留 settings | 路由名为 null，无法匹配主页/全屏页 | `MaterialPageRoute(settings: settings, ...)` |
| GoRoute.name 与配置不匹配 | 全屏页面不生效 | 确保 `GoRoute.name` 与 `fullScreenPages` 完全一致 |
| 三元表达式判断主页 | 无法识别 | 使用 `initialRoute` + 路由表替代 |

**调试方法**：开启 SplitView 主页决策日志（默认在 debug 模式自动输出）：

```bash
hdc shell hilog | grep "SplitView: Main page"
```

### 2.3 引擎配置推送问题

ETS 引擎在 Dart isolate 启动后通过 `flutter/split_view_config_system` 通道主动推送配置。

```bash
hdc shell hilog | grep -E "split_view_config_system|SplitViewConfigSystem"
```

**异常情况**：
- 配置文件 `split_config.json` 不存在 → 引擎推送空配置
- app 图标获取失败 → `placeholderIconData` 为空，占位页无图标
- Dart isolate 未启动 → 推送消息丢失

### 2.4 弹窗蒙层不显示

**问题**：分栏模式下 `showModalBottomSheet` / `showMenu` / `showSearch` 蒙层不正确。

**原因**：这些 API 默认 `useRootNavigator: false`，分栏场景下需显式设为 `true`。

```dart
// ❌ 分栏下蒙层不正确
showModalBottomSheet(context: context, builder: (context) => SheetContent());

// ✅ 需显式设置
showModalBottomSheet(
  context: context,
  useRootNavigator: true,
  builder: (context) => SheetContent(),
);
```

### 2.5 分栏排查清单

- [ ] 确认 `split_config.json` 存在于 `rawfile/` 目录
- [ ] 确认 `enableWideWindowSplit` 或 `enableSquareWindowSplit` 设为 `true`
- [ ] 搜索 HiLog `SplitView` 确认配置已加载
- [ ] 确认窗口逻辑宽高均 > 600vp
- [ ] Router 模式确认 `homePage` 已配置
- [ ] 确认 `MaterialPageRoute` 保留了 `settings` 参数
- [ ] 确认 `showModalBottomSheet` 等设置了 `useRootNavigator: true`
- [ ] 确认 `fullScreenPages` 中的路由名与代码中一致

---

## 3. 安全区域避让问题

### 3.1 避让区域不更新

Flutter OHOS 通过 `FlutterView.ets` 监听四种避让区域变化：

```bash
hdc shell hilog | grep -E "avoidAreaChangeCallback|avoidArea"
```

**正常日志**（对应 OHOS `AvoidAreaType` 四种类型）：
```
# 1. TYPE_SYSTEM：系统栏（状态栏 + 三键导航栏）
I Flutter: avoidAreaChangeCallback, type=TYPE_SYSTEM, area={topRect: {height: 36}, bottomRect: {height: 28}, ...}

# 2. TYPE_CUTOUT：挖孔/刘海区域
I Flutter: avoidAreaChangeCallback, type=TYPE_CUTOUT, area={topRect: {height: 84}, leftRect: {width: 0}, rightRect: {width: 0}, ...}

# 3. TYPE_NAVIGATION_INDICATOR：手势导航条（底部 HOME 条）
I Flutter: avoidAreaChangeCallback, type=TYPE_NAVIGATION_INDICATOR, area={bottomRect: {height: 24}, ...}

# 4. TYPE_KEYBOARD：软键盘
I Flutter: avoidAreaChangeCallback, type=TYPE_KEYBOARD, area={bottomRect: {height: 280}}
```

> **新手提示**：四种类型不是每次都会全部触发，系统会按当前 UI 状态只推送发生变化的类型。例如挖孔机型的 `TYPE_CUTOUT` 通常只在启动/旋转屏幕时上报一次；`TYPE_KEYBOARD` 只在键盘弹出/收起时上报。

**异常排查**：

| 现象 | 可能原因 | 解决方案 |
|------|---------|---------|
| 避让区域始终为 0 | 未调用 `setWindowLayoutFullScreen(true)` | EntryAbility 中设置全屏布局 |
| 横竖屏切换后避让未更新 | FlutterView 未收到 `avoidAreaChange` | 检查回调注册是否成功 |
| 分屏场景避让错误 | 使用了缓存的 padding 值 | 使用 `MediaQuery.of(context).padding` 实时获取 |
| 键盘弹出后避让不恢复 | `viewInsets` 未清零 | 检查 `onKeyboardAreaChange` 逻辑 |
| 挖孔区域未避让（内容被遮挡） | 未监听 `TYPE_CUTOUT` 或 `SafeArea` 顶部未生效 | 确认 `setWindowLayoutFullScreen(true)` 已开启，使用 `SafeArea(top: true)` |
| 底部内容被手势条遮挡 | 未监听 `TYPE_NAVIGATION_INDICATOR` 或底部 padding 取 0 | `SafeArea(bottom: true)`，横竖屏切换后重新读取 `MediaQuery.viewPadding.bottom` |

**关键日志**：
```
# FlutterView 非活跃时忽略避让变化（正常行为）
D Flutter: <viewId> is not active. Ignoring avoid area change.
```

### 3.2 全屏模式避让异常

全屏模式（`SystemUiMode.immersive`）下避让区域处理逻辑不同：

| 模式 | padding 行为 | viewInsets 行为 |
|------|-------------|----------------|
| 非全屏 | 取自定义值或 0 | 取 keyboardAvoidArea |
| 全屏 | 取 systemAvoidArea | 取 keyboardAvoidArea |

**排查**：检查 `onAreaChange` 方法中的全屏判断逻辑：

```bash
hdc shell hilog | grep -E "onAreaChange|setFullScreen|UseFullScreen"
```

### 3.3 窗口装饰避让问题（PC 自由多窗）

PC 自由多窗口模式下，窗口标题栏按钮（最大化/最小化/关闭）可能遮挡内容。

```bash
hdc shell hilog | grep -E "windowTitleButtonRect|windowDecor|handleWindowDecorSafeArea"
```

**关键日志**：

| 日志 | 含义 |
|------|------|
| `windowTitleButtonRectChangeCallback {...}` | 窗口装饰按钮区域变化 |
| `Failed to get window status: ...` | 获取窗口状态失败（异常） |
| `Failed to check window decor visibility support` | 检查窗口装饰支持失败 |

**限制条件**：
- 仅 API 18+ 支持
- 仅自由多窗口模式生效（`isWindowDecorSafeAreaAvoidSupported` 返回 true）
- MAXIMIZE 模式跳过避让（窗口菜单栏临时显示）

**常见问题**：
- 退出自由多窗口模式后避让不生效 → 检查 `windowTitleButtonRectChangeCallback` 是否触发
- 状态栏隐藏后内容上移 → `setSpecificSystemBarEnabled` 中隐藏 status 时自动设置 `setPaddingTop`

### 3.4 避让排查清单

- [ ] 搜索 HiLog `avoidAreaChangeCallback` 确认避让区域更新（应覆盖 TYPE_SYSTEM/TYPE_CUTOUT/TYPE_NAVIGATION_INDICATOR/TYPE_KEYBOARD 四种）
- [ ] 确认 `setWindowLayoutFullScreen(true)` 已设置
- [ ] 检查全屏/非全屏模式下的 padding 取值逻辑
- [ ] 挖孔机型确认 `TYPE_CUTOUT` 已触发并用于顶部 SafeArea
- [ ] 手势导航机型确认 `TYPE_NAVIGATION_INDICATOR` 已触发并用于底部 SafeArea
- [ ] 搜索 `windowTitleButtonRect` 确认窗口装饰避让（PC）
- [ ] 确认使用 `MediaQuery.of(context).padding` 而非缓存值
- [ ] 确认 `SafeArea` 的 top/bottom 参数随全屏状态切换

---

## 4. 折叠屏 DisplayFeature 问题

### 4.1 DisplayFeature 缺失

Flutter OHOS 通过 `MediaQuery.of(context).displayFeatures` 获取屏幕特征（挖孔、折痕等）。

```bash
hdc shell hilog | grep -E "displayFeature|displayFeatures|cutoutInfo"
```

**正常日志**：
```
D Flutter: device displayFeatures is : [{"bound":{...},"type":3,"state":0}]
```

**type 值含义**：0=UNKNOWN, 1=FOLD, 2=HINGE, 3=CUTOUT

### 4.2 折叠状态监听

```bash
hdc shell hilog | grep -E "foldStatus|Fold status|foldStatusChange"
```

**正常日志**：
```
D Flutter: Fold status change to {"status":1}  // 1=展开, 2=折叠, 3=半折叠
```

**折叠状态码**：

| 状态码 | 含义 |
|--------|------|
| 0 | UNKNOWN |
| 1 | 完全展开（FLAT） |
| 2 | 完全折叠 |
| 3 | 半折叠（悬停态） |

### 4.3 FOLD 功能未生效

**已知限制**：FOLD（折痕）功能在 `FlutterView.ets` 的 `buildDisplayFeatures` 中**被注释**，因 OHOS `getCurrentFoldCreaseRegion` API 存在 bug（折痕区域不准确、displayId 比对失败）。当前仅 CUTOUT（挖孔）生效。

**影响**：
- `DisplayFeatureType.fold` 和 `DisplayFeatureType.hinge` 不会被填充
- `DisplayFeatureSubScreen` 组件无法基于折痕避让
- 折叠屏展开态的折痕区域需通过平台通道手动获取

**替代方案**：通过 MethodChannel 获取折痕区域：

```dart
final creaseRegion = await MethodChannel('fold_status_detector')
    .invokeMethod('getCreaseRegion');
// 返回 [top, height] 折痕位置信息
```

### 4.4 折叠屏排查清单

- [ ] 搜索 HiLog `displayFeatures` 确认 DisplayFeature 已构建
- [ ] 搜索 HiLog `Fold status change` 确认折叠状态监听正常
- [ ] 确认当前仅 CUTOUT 生效（FOLD 被注释）
- [ ] 如需折痕避让，确认已通过平台通道获取折痕区域
- [ ] 确认 `DisplayFeatureSubScreen` 使用了正确的 displayFeatures

---

## 5. DPI 缩放问题

### 5.1 devicePixelRatio 不更新

```bash
hdc shell hilog | grep -E "device pixel ratio|devicePixelRatio|densityUpdate|dpiScale"
```

**关键日志**：

| 日志 | 含义 |
|------|------|
| `Device pixel ratio updated: 3.0` | DPI 更新成功 |
| `Resetting device pixel ratio to system default: 3.0` | 重置为系统默认 DPI |
| `Scaling device pixel ratio by factor 0.85: 2.55` | 按缩放因子调整 DPI |
| `Error updating device pixel ratio: ...` | DPI 更新失败（异常） |
| `densityUpdateCallback: customDensity=..., sysDensity=...` | 密度变化回调 |

### 5.2 自定义 DPI 不生效

自定义 DPI 通过 `flutter/displaymetrics` 通道的 `updateDpiScale` 方法设置。

**排查步骤**：

1. 确认 `DisplayMetricsChannel` 已注册
2. 搜索日志确认 DPI 缩放调用：

```bash
hdc shell hilog | grep -E "displaymetrics|updateDpiScale|customDpi"
```

3. 确认路由切换时自定义 DPI 重置逻辑：

```bash
hdc shell hilog | grep -E "customDpiActive|currentUri|setCurrentUri"
```

**关键行为**：路由切换（push start）时，如果 routeName 与当前 URI 不同，会重置自定义 DPI：
```
setCurrentUri('')  → 清空当前 URI
setCustomDpiActive(false)  → 关闭自定义 DPI
```

### 5.3 窗口尺寸变化导致 DPI 异常

```bash
hdc shell hilog | grep -E "windowSizeChangeCallback"
```

**正常日志**：
```
I Flutter: windowSizeChangeCallback: width=..., height=..., lastHeight=...
I Flutter: windowSizeChangeCallback devicePixelRatio: 3.0
I Flutter: windowSizeChangeCallback: Updated devicePixelRatio to 3.0
```

**异常日志**：
```
E Flutter: windowSizeChangeCallback error: ...
```

### 5.4 DPI 排查清单

- [ ] 搜索 HiLog `device pixel ratio` 确认 DPI 更新
- [ ] 搜索 `densityUpdateCallback` 确认密度变化监听
- [ ] 搜索 `updateDpiScale` 确认自定义 DPI 调用
- [ ] 确认路由切换时 DPI 重置逻辑正常
- [ ] 搜索 `windowSizeChangeCallback` 确认窗口尺寸变化处理
- [ ] 确认 `AdaptiveDpiColumn` 仅在 Release 模式生效

---

## 6. LTPO 自适应刷新问题

### 6.1 LTPO 不工作

**前提条件**：
- OpenHarmony API 20+
- 系统刷新率设为"智能"
- `framesconfig.json` 中 `SWITCH` 为 1
- 系统帧率策略已云推

**排查步骤**：

```bash
hdc shell hilog | grep -E "LTPO|ltpo|nativevsync|sendVelocity|checkLTPO"
```

**关键日志**：

| 日志 | 含义 | 级别 |
|------|------|------|
| `[LTPO] Notifying the VSync signal may require a high frame rate.` | LTPO 请求高帧率 | 引擎内部 |
| `LTPO: Check switch status timed out, assuming ltpoOff` | LTPO 开关检查超时 | debugPrint |
| `LTPO: Failed to check switch status: ...` | LTPO 开关检查失败 | debugPrint |
| `LTPO abnormal velocity detected: ... px/s from ...` | 异常速度（>16000px/s） | debugPrint（仅 Debug） |
| `LTPO[scroll]...: ... px/s` | 速度上报详情 | debugPrint（需开启 `debugPrintLTPO`） |

### 6.2 速度上报链路

LTPO 速度上报完整链路：

```
Dart 侧速度产生
├─ 页面转场（routes.dart）→ recordTranslateVelocity(source: pageTransition)
├─ Hero 动画（heroes.dart）→ recordTranslateVelocity(source: pageTransition)
├─ 滚动（gestures）→ recordTranslateVelocity(source: scroll)
└─ Widget 动画 → recordTranslateVelocity(source: widget)
     │
     ├─ LTPODetector 检测异常速度（Debug 模式，>16000px/s 告警）
     │
     └─ 每帧 _sendAllTranslateVelocity → SystemChannels.nativeVsync.invokeMethod('sendVelocity')
          │
          └─ NativeVsyncChannel.ets → FlutterNapi.animationVoting(TRANSLATE, velocity)
               │
               └─ 系统根据 framesconfig.json 速度-帧率映射表决策实际帧率
```

**验证速度上报**：

```dart
// 在 Dart 代码中开启 LTPO 调试日志
WidgetsBinding.instance.debugPrintLTPO = true;
```

### 6.3 framesconfig.json 配置问题

**配置文件位置**：`ohos/entry/src/main/resources/rawfile/framesconfig.json`

```json
{
  "SWITCH": 1,
  "TRANSLATE": [
    { "serial_number": 1, "min": 800, "max": -1, "preferred_fps": 90 },
    { "serial_number": 2, "min": 77, "max": 800, "preferred_fps": 120 },
    { "serial_number": 3, "min": 46, "max": 77, "preferred_fps": 90 },
    { "serial_number": 4, "min": 10, "max": 46, "preferred_fps": 72 },
    { "serial_number": 5, "min": 0, "max": 10, "preferred_fps": 60 }
  ],
  "SCALE": [],
  "ROTATION": []
}
```

**常见配置问题**：

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| LTPO 完全不工作 | `SWITCH` 为 0 | 改为 `1` |
| 帧率始终 60 | 文件不存在或路径错误 | 确认在 `rawfile/` 目录下 |
| 帧率切换不正确 | 速度区间配置有误 | 使用默认配置，不建议修改 |
| SCALE/ROTATION 不生效 | 当前未实现 | 仅 TRANSLATE 生效 |

### 6.4 Navigator 转场 Trace

页面转场（push/pop）会通过 `hiTraceMeter` 输出性能 Trace：

```bash
hdc shell hitrace --trace_clock boottime -t 10 flutter -o /data/local/tmp/trace.ftrace
```

**在 Trace 中搜索**：

| Trace 事件 | 含义 |
|-----------|------|
| `flutter::NAVIGATOR_PUSH` | 页面 push 转场（start → finish） |
| `flutter::NAVIGATOR_POP` | 页面 pop 转场（start → finish） |

**Navigator activity 日志**：

```bash
hdc shell hilog | grep -E "reportNavigatorActivity|NAVIGATOR"
```

**异常日志**：

| 日志 | 含义 |
|------|------|
| `reportNavigatorActivity, args is null or not a Map` | 参数格式错误 |
| `reportNavigatorActivity, incorrect parameter activity` | activity 参数缺失 |
| `reportNavigatorActivity, incorrect parameter status` | status 参数缺失 |

### 6.5 LTPO 排查清单

- [ ] 确认系统版本 ≥ API 20
- [ ] 确认系统刷新率设为"智能"
- [ ] 确认 `framesconfig.json` 存在且 `SWITCH` 为 1
- [ ] 搜索 HiLog `LTPO` 确认开关状态正常
- [ ] 开启 `debugPrintLTPO = true` 确认速度上报
- [ ] 搜索 `LTPO abnormal velocity` 检查异常速度
- [ ] 抓取 HiTrace 检查 `flutter::NAVIGATOR_PUSH/POP` 转场耗时
- [ ] 确认 `sendVelocity` 调用正常（搜索 `nativevsync`）
- [ ] 联系接口人确认系统帧率策略已云推

---

## 7. 多窗口/自由窗口问题

### 7.1 窗口尺寸变化布局不刷新

```bash
hdc shell hilog | grep -E "windowSizeChangeCallback|windowRectChange|windowStatusChange"
```

**关键回调**：

| 回调 | 日志关键字 | 作用 |
|------|-----------|------|
| `windowSizeChangeCallback` | `windowSizeChangeCallback` | 窗口尺寸变化（更新 DPI） |
| `windowRectChangeCallback` | `windowRectChange` | 窗口位置变化 |
| `windowStatusChangeCallback` | `windowStatusChange` | 窗口状态变化（全屏/分屏等） |

**布局不刷新的常见原因**：

- 未监听 `WidgetsBindingObserver.didChangeMetrics`
- 使用了缓存的 `MediaQuery` 值
- 分栏激活状态未更新（`_checkScreenSizeAndSetSplitScreen`）

### 7.2 自由多窗沉浸式异常

**重要**：自由多窗沉浸式**不能用** `setWindowLayoutFullScreen`，必须用：
- `setWindowDecorVisible(false)` — 隐藏状态栏
- `setWindowTitleButtonVisible(false, false, false)` — 隐藏窗口按钮

**排查**：

```bash
hdc shell hilog | grep -E "setWindowDecorVisible|setWindowTitleButtonVisible|WindowDecor"
```

### 7.3 多窗口排查清单

- [ ] 搜索 `windowSizeChangeCallback` 确认窗口变化回调
- [ ] 确认 `WidgetsBindingObserver.didChangeMetrics` 已实现
- [ ] 确认使用 `MediaQuery.of(context)` 实时获取尺寸
- [ ] 确认自由多窗沉浸式使用 `setWindowDecorVisible` 而非 `setWindowLayoutFullScreen`
- [ ] 搜索 `windowTitleButtonRect` 确认窗口装饰避让

---

## 8. HiLog 关键字速查表

| HiLog 关键字 | 问题类型 | 含义 | 来源文件 |
|-------------|---------|------|---------|
| `SplitView: Main page determined by` | 分栏 | 主页识别方式 | app.dart |
| `SystemChannel config parse failed` | 分栏 | 配置解析失败 | split_view_config_loader.dart |
| `SplitViewConfig: Failed to decode placeholder icon` | 分栏 | 占位图标解码失败 | split_view_config.dart |
| `Cannot determine main page for split screen` | 分栏 | 无法识别主页（致命） | app.dart |
| `avoidAreaChangeCallback, type=TYPE_SYSTEM` | 避让 | 系统栏（状态栏+三键导航栏）变化 | FlutterView.ets |
| `avoidAreaChangeCallback, type=TYPE_CUTOUT` | 避让 | 挖孔/刘海区域变化 | FlutterView.ets |
| `avoidAreaChangeCallback, type=TYPE_NAVIGATION_INDICATOR` | 避让 | 手势导航条变化 | FlutterView.ets |
| `avoidAreaChangeCallback, type=TYPE_KEYBOARD` | 避让 | 软键盘弹出/收起 | FlutterView.ets |
| `is not active. Ignoring avoid area change` | 避让 | 非活跃视图忽略避让 | FlutterView.ets |
| `windowTitleButtonRectChangeCallback` | 避让 | 窗口装饰按钮变化 | FlutterView.ets |
| `handleWindowDecorSafeArea` | 避让 | 窗口装饰避让处理 | FlutterManager.ets |
| `Failed to get window status` | 避让 | 获取窗口状态失败 | FlutterManager.ets |
| `device displayFeatures is :` | 折叠屏 | DisplayFeature 构建结果 | FlutterView.ets |
| `Fold status change to` | 折叠屏 | 折叠状态变化 | FlutterView.ets |
| `Device pixel ratio updated:` | DPI | DPI 更新成功 | FlutterView.ets |
| `Resetting device pixel ratio` | DPI | 重置为系统默认 | FlutterView.ets |
| `Scaling device pixel ratio by factor` | DPI | 按因子缩放 | FlutterView.ets |
| `Error updating device pixel ratio` | DPI | DPI 更新失败 | FlutterView.ets |
| `densityUpdateCallback: customDensity=` | DPI | 密度变化回调 | FlutterView.ets |
| `windowSizeChangeCallback: width=` | 多窗口 | 窗口尺寸变化 | FlutterView.ets |
| `windowSizeChangeCallback error:` | 多窗口 | 窗口尺寸变化异常 | FlutterView.ets |
| `[LTPO] Notifying the VSync` | LTPO | LTPO 请求高帧率 | FlutterView.ets |
| `LTPO: Check switch status timed out` | LTPO | 开关检查超时 | binding.dart |
| `LTPO: Failed to check switch status` | LTPO | 开关检查失败 | binding.dart |
| `LTPO abnormal velocity detected:` | LTPO | 异常速度告警 | binding.dart |
| `reportNavigatorActivity, args is null` | 转场 | 导航上报参数错误 | NavigationChannel.ets |

---

## 9. Trace 分析

### 9.1 多设备相关 Trace 事件

```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace
```

在 Chrome `chrome://tracing` 中搜索：

| Trace 事件 | 含义 | 分析用途 |
|-----------|------|---------|
| `flutter::NAVIGATOR_PUSH` | 页面 push 转场 | 转场动画耗时 |
| `flutter::NAVIGATOR_POP` | 页面 pop 转场 | 返回动画耗时 |
| `Flutter Lost Frames` | 丢帧计数 | 转场/分栏切换丢帧 |
| `Flutter Hitch Time` | 丢帧详情 | 帧耗时分因 |
| `feedFlutterWatchdog` | 线程心跳 | 线程是否正常 |

### 9.2 分栏切换 Trace 分析

分栏激活/取消时，关注以下时间线：
1. `windowSizeChangeCallback` 触发 → DPI 更新
2. `didChangeMetrics` 回调 → `_checkScreenSizeAndSetSplitScreen` 判断
3. `SplitViewManager.setSplitViewActive` → `notifyListeners`
4. `buildOverlayLayout` → 重建 Overlay 布局

如果分栏切换卡顿，在 Trace 中查看上述步骤的耗时。

### 9.3 LTPO 帧率切换验证

1. 开启"显示刷新频率"（开发者选项）
2. 打开应用中带有滚动组件的页面
3. 页面抛滑，观察帧率变化：120 → 90 → 60
4. 如帧率不变化，按 §6 排查步骤检查

---

## 10. 日志级别说明

| 模式 | 可见日志级别 | 说明 |
|------|------------|------|
| Debug | DEBUG + INFO + WARN + ERROR | 所有日志可见 |
| Profile | WARN + ERROR | DEBUG/INFO 被过滤 |
| Release | WARN + ERROR | DEBUG/INFO 被过滤 |

> **注意**：Dart 侧的 `debugPrint` 仅在 Debug 模式输出。
> ETS 侧 `Log.d`/`Log.i` 在 Release/Profile 模式被过滤。
> 排查多设备问题时建议使用 Debug 模式。

### 开启 Dart 侧调试日志

```dart
// 开启 LTPO 调试日志
WidgetsBinding.instance.debugPrintLTPO = true;

// SplitView 日志默认在 Debug 模式自动输出
// 无需额外开关
```

---

## 11. 多设备适配排查总清单

- [ ] 抓取全量日志：`hdc shell hilog > flutter_log.txt`
- [ ] 搜索 `SplitView` 确认分栏配置加载和主页识别
- [ ] 搜索 `avoidAreaChangeCallback` 确认避让区域更新
- [ ] 搜索 `displayFeatures` 确认 DisplayFeature 构建
- [ ] 搜索 `Fold status change` 确认折叠状态监听
- [ ] 搜索 `device pixel ratio` 确认 DPI 更新
- [ ] 搜索 `windowSizeChangeCallback` 确认窗口变化处理
- [ ] 搜索 `LTPO` 确认自适应刷新状态
- [ ] 搜索 `windowTitleButtonRect` 确认窗口装饰避让（PC）
- [ ] 确认 `split_config.json` 和 `framesconfig.json` 配置正确
- [ ] 抓取 HiTrace 分析转场和帧率：`hdc shell hitrace --trace_clock boottime -t 30 flutter`
- [ ] 记录问题发生的设备类型和操作场景
