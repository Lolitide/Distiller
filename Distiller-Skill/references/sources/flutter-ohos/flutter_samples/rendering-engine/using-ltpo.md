# 如何使用 LTPO 功能

## 简介

> **版本说明：** LTPO 特性自 Flutter `3.27.5-ohos-1.0.6` 版本开始支持。

LTPO 功能是指屏幕动态帧率，在屏幕刷新率设置为"智能"时，应用可根据当前场景自动切换合适的帧率。

Flutter 框架帧率现状：在屏幕刷新率设置为"智能"时，其帧率策略与屏幕刷新率设置为"高"时一致。手指触摸屏幕时，屏幕刷新率为 120 帧；手指离开屏幕后，屏幕刷新率保持 3s 的 120 帧；3s 后无操作，屏幕刷新率降低为 60 帧。

> **注意**：LTPO 特性依赖 OpenHarmony API 20，请在 API 20 及以上的 ROM 中验证。

---

## 适配场景

| 序号 | 场景 |
| ---- | ---- |
| 1 | 自定义平移动画 |
| 2 | 转场平移动画 |
| 3 | 滚动列表抛滑 |
| 4 | 轮播图 |

---

## 前置条件

| 依赖顺序 | 依赖项 | 说明 |
| ---- | ---- | ---- |
| 1 | [DevEco Studio](#deveco-studio) | IDE 工具 |
| 2 | [flutter_flutter](#flutter-flutter) | 集成了 LTPO 功能的 Flutter SDK |
| 3 | [LTPO 配置文件](#frames-config) | 配置 LTPO 功能开关和帧率策略 |
| 4 | [匹配版本要求](#version-requirement) | 系统能力支持的最低版本 |

---

## 详情

### <a id="deveco-studio"></a>DevEco Studio

DevEco Studio 需要更新到新版本，点击下方链接下载最新 DevEco Studio。

下载地址：[DevEco Studio](https://developer.huawei.com/consumer/cn/download/deveco-studio)

### <a id="flutter-flutter"></a>flutter_flutter

LTPO 功能跟随 flutter_flutter 代码仓版本发布，请使用 flutter_flutter 代码仓的 `3.27.5-ohos-1.0.6` 分支进行具备 LTPO 功能的 Flutter 应用开发。

代码仓：[flutter_flutter 3.27.5-ohos-1.0.6](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/3.27.5-ohos-1.0.6)

### <a id="frames-config"></a>LTPO 配置文件

LTPO 配置文件包含动态帧率开关、平移动画的帧率映射表，以及缩放和旋转的帧率映射表。

| 子项 | 描述 | 类型 |
| ---- | ---- | ---- |
| SWITCH | 动态帧率开关 | 整型。0-关闭；1-开启 |
| TRANSLATE | 平移动画的帧率映射表，<br>不建议修改帧率映射表中的元素。 | 数组。每个元素由序号、最小速度、最大速度、期望帧率组成。 |
| SCALE | 缩放动画的帧率映射表，<br>不建议修改帧率映射表中的元素。<br>当前未实现 | 数组。每个元素由序号、最小速度、最大速度、期望帧率组成。 |
| ROTATION | 旋转动画的帧率映射表，<br>不建议修改帧率映射表中的元素。<br>当前未实现 | 数组。每个元素由序号、最小速度、最大速度、期望帧率组成。 |

当前帧率映射表：

| 序号 | 最低滑动速度 | 最高滑动速度 | 帧率 |
| ---- | ---- | ---- | ---- |
| 1 | 800 | 无限大 | 90 |
| 2 | 77 | 800 | 120 |
| 3 | 46 | 77 | 90 |
| 4 | 10 | 46 | 72 |
| 5 | 0 | 10 | 60 |

> **注意**：实际屏幕帧率由系统决策。

配置文件 `framesconfig.json` 存放在 ArkUI 应用工程中 Flutter 模块的 `src/main/resources/rawfile` 目录下，与 `flutter_assets` 同级目录。

详细说明：

1. `framesconfig.json` 是 LTPO 的配置文件，可配置使能开关，当前默认使能。
2. 配置文件预置了平移动画的速率映射帧率挡位，根据动画的平移速率来决定屏幕刷新率。默认映射帧率挡位配置，不推荐改动。
3. 配置文件预置在模板应用工程中，默认存在新建的 Flutter 应用工程中。已存在的 Flutter 应用工程，需要适配切换 Flutter 3.27 版本或更高版本，并手动拷贝 `framesconfig.json` 文件到应用工程 `ohos/entry/src/main/resources/rawfile` 路径下。

其原型文件：[framesconfig.json](https://gitcode.com/CPF-Flutter/flutter_flutter/blob/3.27.5-ohos-1.0.6/packages/flutter_tools/templates/app_shared/ohos.tmpl/entry/src/main/resources/base/profile/framesconfig.json)

### <a id="version-requirement"></a>匹配版本要求

打开"设置"，进入"关于本机"，查看软件版本是否为 `6.0.0.110（SP96C00E110R4P8）` 及以上。

---

## 适配流程

**步骤 1：** 更新 [DevEco Studio](#deveco-studio) IDE 工具，至少使用 DevEco Studio 6.0.0 Release 版本，其中包含所依赖的 API 20 接口。

**步骤 2：** 下载适配了 LTPO 功能的 [flutter_flutter](#flutter-flutter) 代码仓，并添加进环境变量。

**步骤 3：** 命令行窗口执行 `flutter doctor -v`，确认 Flutter 路径是否为适配了 LTPO 功能的 flutter_flutter 代码仓，其分支是否为 `3.27.5-ohos-1.0.6` 及以上，确保适配应用是 Flutter 3.27 版本。

**步骤 4：** 确认应用工程里的 LTPO 配置文件 [framesconfig.json](#frames-config) 是否存在。如果是新建的 Flutter 应用工程，LTPO 配置文件默认存在应用模板里；如果是已存在的应用工程，需要手动拷贝 `framesconfig.json` 文件到应用工程 `ohos/entry/src/main/resources/rawfile` 路径下。

**步骤 5：** 确认 LTPO 配置文件使能开关打开。请查看 `framesconfig.json` 文件 `SWITCH` 选项是否为 1，不为 1 则修改为 1。

---

## 验证流程

1. 检查手机版本是否匹配版本要求。不匹配的情况下，联系接口人推送系统版本。
2. 当前系统有帧率策略管控，需要联系接口人进行系统帧率策略云推。
3. 开启"智能"刷新。"设置" > "显示和亮度" > "屏幕刷新率"。
4. 开启"显示刷新频率"。"设置" > "系统" > "开发者选项"，调试那一栏下。开启后左上角显示两个数字，左侧为帧率挡位（期望帧率），右侧为实时帧率，主要关注左侧的数字（如果只有一个数字，即为帧率挡位）。
5. 打开应用中带有 Flutter 框架的滚动组件页面。
6. 页面抛滑。
7. 观察抛滑过程，可以看到显示帧率根据页面滑动速度从 120 fps 先降低到 90 fps，最后停止滑动后降低到 60 fps。效果见下图：

![](../media/rendering-engine/rendering-engine-22.png)
![](../media/rendering-engine/rendering-engine-18.png)
![](../media/rendering-engine/rendering-engine-16.png)

<p align="center"><strong>图1</strong> 抛滑过程帧率变化（120 → 90 → 60 fps）</p>

- 左侧数字为帧率挡位（期望帧率），右侧为实时帧率。
- 滑动速度越快挡位越高；停止滑动后降至 60 fps。
- 实际屏幕帧率由系统决策。

---

## 常见问题

### 动画页面切换后台后未暂停，屏幕刷新率未下降怎么办？

有以下建议：

#### 合理选择标签页页面的 TabController

TabController 的创建有两种形式，一种是使用系统的 `DefaultTabController`，第二种是自己定义一个 `TabController` 实现 `SingleTickerProviderStateMixin`。

1. 无状态控件（StatelessWidget）搭配 `DefaultTabController`。
2. 有状态控件（StatefulWidget）搭配 `TabController`。

```dart
class TabsPage extends StatefulWidget {
  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      vsync: this,
      length: 3, // 设置 TabBarView 数量
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBar(
        controller: _tabController,
        tabs: <Widget>[],
      ),
    );
  }
}
```

#### TabView 页签切换停止动画

有状态控件（StatefulWidget）生命周期 `deactivate`，当框架从树中移除此 State 对象时将会调用此方法。可在此生命周期回调 `deactivate` 对 `AnimationController` 进行 stop 操作。

如果是一个基于 `this` 的 vsync 周期循环的动画，重新进入页面后会自动播放，无须手动启动动画。

```dart
class AnimationPage extends StatefulWidget {
  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void deactivate() {
    super.deactivate();
    _controller.stop();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..addListener(() {
      setState(() {});
    })..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 参考资料

- 可变帧率简介：[displaysync-overview](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/graphics/displaysync-overview.md)
- 基于 LTPO 的低功耗设计：[bpta-ltpo-description](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-ltpo-description)
- NativeVSync 开发指导 (C/C++)：[native-vsync-guidelines](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/graphics/native-vsync-guidelines.md)
- NativeVsync 函数参考：[capi-native-vsync-h](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-native-vsync-h.md)
