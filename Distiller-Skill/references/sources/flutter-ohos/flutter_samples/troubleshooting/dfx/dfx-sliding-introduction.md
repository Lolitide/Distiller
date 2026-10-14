# Flutter 页面滑动卡顿与掉帧问题介绍

## 1. 概述

用户反馈"页面卡"时，最常见的一类是**滑动或动画卡顿**：画面不连贯、一顿一顿。这在 Flutter 里通常对应**掉帧（Jank）**——某一帧生成耗时超过帧预算，屏幕只能继续显示上一帧。

**60Hz** 表示屏幕每秒刷新 60 次，相邻两次刷新间隔约 **16.6ms**；**90Hz** 约 **11.1ms**；**120Hz** 约 **8.3ms**。

## 2. Flutter 的渲染管线介绍

Flutter 渲染一帧，大致经过四个阶段：

| 阶段 | 做什么 | 大致耗在哪条线程 |
| --- | --- | --- |
| **Build** | 根据状态变化构建/更新 Widget 树、Element 树 | UI 线程（主线程） |
| **Layout** | RenderObject 树计算每个节点的大小和位置 | UI 线程 |
| **Paint** | 生成绘制指令，构建 Layer tree | UI 线程 |
| **Composite** | 将 Layer tree 栅格化成像素，输出到屏幕 | Raster 线程（渲染线程/GPU 线程） |


其中**UI 线程**：运行 Dart VM，执行你的 Dart 代码和 Flutter 框架代码，产出 Layer tree；**Raster 线程**：接收 Layer tree，调用 Skia 或 Impeller 进行栅格化与合成，最终送屏。

性能分析时，两条线程的时间都要看：
- UI 线程耗时过长，说明 Dart 层有性能问题
- Raster 线程耗时过长，说明绘制太重（阴影、模糊、大图、saveLayer 等）。

后续主要分析都围绕 UI 线程和 Raster 线程展开，需要先学会通过trace确认它们的 tid。通过查看 trace 的线程清单，重点关注以下角色分类：

| 角色 | 典型线程名 | 说明 |
|---|---|---|
| `flutter_ui` | `1.ui`、`root.1.ui`、`root.N.ui` | Flutter UI 线程，运行 Dart 代码 |
| `platform_main` | 应用包名（如 `.my_app`） | 应用主线程 |
| `flutter_raster` | `1.raster`、`root.1.raster` | Flutter Raster 线程，执行光栅化 |

> **Flutter 3.35+ 线程合并**：从 Flutter 3.35 版本起，OHOS 平台上 UI 线程与应用主线程可能合并为同一条线程，线程名为应用包名（如 `.complex_layout`），被归类为 `platform_main` 而非 `flutter_ui`。此时不能仅靠线程名判断 UI 线程，而应通过搜索 `flutter::Animator::BeginFrame` trace 来定位——该 slice 所在的 tid 即为 UI 线程。



## 3. 基于 OHOS平台Trace 的滑动丢帧定位

**渲染链路概览**：下面这条链路展示了“手指触屏 → Flutter 处理 → 系统合成 → 屏幕上屏”的完整过程。每个 trace 对应其中一个关键节点，便于快速理解全貌。

> **可控性提示**：链路中大部分事件由系统或 Flutter 框架自动产生，应用代码无法直接改动；只有 `Animator::BeginFrame`（对应 Dart 层 BUILD/LAYOUT/PAINT）和 `GPURasterizer::Draw`（对应 Raster 线程绘制负载）的耗时，会被应用代码的复杂度间接影响，是性能优化的主要发力点。

| trace name | 作用 | 所属线程/模块 | 可控性 / 说明 |
|---|---|---|---|
| `originEventHandle`或者不存在 | 系统收到手指触摸/滑动事件的原始输入 | 系统的多模输入子系统 `mmi_service` | 系统事件，不可改动，仅用于定位输入起点 |
| `DispatchTouchEvent` <br> id:N, pointX=XXX pointY=XXX type=x | 系统将触摸事件派发给应用主线程 <br> type 0-按下 1-抬起 2-移动 | 应用主线程/应用包名 | 系统事件，不可改动 |
| `Shell::OnPlatformViewDispatchPointerDataPacket` | Flutter Shell 层收到平台视图传来的触摸数据包 | 应用主线程/应用包名 | Flutter 框架事件，不可改动 |
| `Engine::DispatchPointerDataPacket` | Flutter 引擎将触摸数据包分发到 Dart 层处理 | UI 线程 | Flutter 框架事件，不可改动 |
| `flutter::VsyncFireCallback` | 收到垂直同步信号，通知 Flutter 可以开始渲染下一帧 | OS_VSyncThread | 系统 VSync 信号，不可改动 |
| `Animator::BeginFrame` | Flutter 动画器开始一帧的构建、布局、绘制 | UI 线程 | **应用代码可优化**：减少 rebuild、layout、paint 开销 |
| `GPURasterizer::Draw` | 将 UI 线程生成的 Layer tree 栅格化为像素 | Raster 线程 | **应用绘制负载可优化**：避免 saveLayer、重阴影、大图、过度模糊 |
| `oh_flutter_1Surface` | Flutter 向系统提交当前帧的图形 buffer | Flutter → RenderService | 框架事件，不可改动，用于观察 buffer 生产/消费是否匹配 |
| `RSMainThread::DoComposition` | RenderService 对多个窗口/图层进行合成 | render_service | 系统合成事件，不可改动 |
| `RenderFrame` | GPU 执行真正的像素绘制 | GPU | GPU 执行，不可改动 |
| `RSHardwareThread::CommitAndReleaseLayers` | 把合成好的图层提交给显示硬件，释放过期 buffer | render_service / 显示硬件 | 系统/硬件事件，不可改动 |

### 3.1 识别滑动过程

分析滑动丢帧的前提是先确定"哪一段 trace 是滑动"。DevEco Profiler 抓取的 trace 通常长达数秒到数十秒，包含应用启动、空闲、滑动、停止等多个阶段。只有先把滑动区间圈出来，后续的丢帧定位才有意义。

`flutter::APP_LIST_FLING`是应用代码主动埋点的滑动生命周期标记。如果 trace 中存在该 slice，它覆盖了手指拖滑和惯性滑动的完整过程。在 trace 中搜索 `APP_LIST_FLING`，取其 start 和 end 时间戳，直接作为后续丢帧分析的时间窗口。

![滑动窗口](../media/sliding/sliding-3-1-sliding_window.png)

> **注意**：`APP_LIST_FLING` 包含手指拖滑和惯性滑动全过程。但在特殊情况下，该标记可能未完全覆盖实际滑动过程（如滑动开始前埋点未触发、或滑动结束后惯性仍持续），此时需要结合触摸事件链扩展窗口。

### 3.2 识别丢帧位置

#### 3.2.1 定位丢帧

在滑动窗口内定位丢帧。有两种方法，优先使用第一种：

**方法一：通过 `flutter::SceneDisplayLag` 快速定位**

Flutter 提供了 `flutter::SceneDisplayLag` trace 来标识渲染管线中出现的丢帧。在滑动窗口内搜索该 trace，可以直接定位丢帧发生的时间点，无需逐帧对比耗时。

![丢帧标识](../media/sliding/sliding-3-2-1-scene_display_lag.png)


**方法二：通过render_service 快速查阅**

render_service 提供了 两个trace泳道来说明buffer消费情况。收藏两个泳道，快速查阅两个泳道不重合或空隙的时间点。

| 泳道 | 说明 |
|---|---|
| `oh_flutter_1Surface` | flutter提交的生产buffer及其数量。名字通常是`oh_flutter_`开头+数字+`Surface`结尾 |
| `render_service` | 消费flutter提交的buffer |

![surface丢帧判断](../media/sliding/sliding-3-2-1-surface_render_service.png)

#### 3.2.2 判断瓶颈点

ui线程和raster线程耗时长短没有一个基准，根据慢帧的指标分布，判断瓶颈在哪条线程：

| 指标特征 | 瓶颈线程 | 下一步深挖方向 |
|---|---|---|
| `ui` 远大于 `raster` | **UI 线程** | 检查 `Animator::BeginFrame` → `begin_frame_` / `draw_frame_`，确认 BUILD/LAYOUT/PAINT 哪个阶段最重 |
| `raster` 远大于 `ui` | **Raster 线程** | 检查 `GPURasterizer::Draw` 子调用栈，确认是 shader 编译、图片解码、saveLayer 还是 fence 等待 |
| `ui` 和 `raster` 都高 | **连锁反应** | 通常是 UI 层重建过大拖累 Raster，先治 UI 线程 |
| `ui`/`raster` 都小，但存在丢帧 | **UI 线程或主线程** | 检查`DartIsolate::HandleMessage`、`Animator::AwaitVSync`、fence 等待、binder 阻塞 |


锁定最慢帧后，确认两个线程的帧号`frame_number:`是否相同。以其时间戳为中心收窄窗口，分别查看 UI 线程和 Raster 线程在该窗口内的 slices，找到最耗时的 slice。根据耗时和调用栈信息，判断是 UI 线程还是 Raster 线程的瓶颈。

| 标记 | trace name | 说明 |
|---|---|---|
| 起点 | `flutter::Animator::BeginFrame` | UI线程绘制 |
| 终点 | `flutter::GPURasterizer::Draw` | Raster线程光栅化 |


![单帧绘制](../media/sliding/sliding-3-2-2-flutter_frame.png)


**主要分支一：UI 线程瓶颈**

在收窄窗口内，按 UI 线程 tid 过滤 slices，重点关注 `BUILD`、`LAYOUT`、`PAINT`、`Animate`、`BeginFrame`、`PlatformConfiguration` 等名称的 slice，确认哪个阶段最重。

| slice 名称 | 说明 | 指向的根因 |
|---|---|---|
| `BUILD` | Widget 树的构建阶段 | 列表项构建复杂、`itemBuilder` 中创建重量级 Widget、`setState` 触发大范围重建、动画导致每帧 rebuild |
| `LAYOUT` | RenderObject 树的布局阶段 | 列表不定高（参见 [4.1 根因：ListView 不定高](#41-根因listview-不定高)）、嵌套复杂 Flex/Stack、使用 `IntrinsicHeight` / `IntrinsicWidth` 等强制固有尺寸测量 |
| `PAINT` | 生成绘制指令 | 绘制指令复杂、大量裁剪/复杂 `CustomPaint`、子树未用 `RepaintBoundary` 隔离导致重绘扩散 |
| `Animate` | 动画回调执行 | 动画回调中做重计算、`AnimatedBuilder` 未复用 `child`、每帧 `setState` 重建大量 Widget |
| `PlatformConfiguration` | 平台配置/消息处理 | Platform Channel 同步调用阻塞、大量平台消息集中处理 |
| `BeginFrame` | 一帧开始，调度 BUILD/LAYOUT/PAINT 各阶段 | Dart 主线程被其他消息阻塞（如 `DartIsolate::HandleMessage`）、同步耗时操作、主线程与 Raster 线程 sync 等待 |

![UI瓶颈](../media/sliding/sliding-3-2-2-ui_bottleneck.png)


> **图片注意事项**：截图应展示 UI 线程在慢帧窗口内的调用栈展开，标注 BUILD/LAYOUT/PAINT 各阶段耗时。如未开启 `--trace-systrace` 则标注缺少这些阶段。应用开发者可以通过flutter内置工具devtools细看耗时原因。


**主要分支二：Raster 线程瓶颈**

在收窄窗口内，按 Raster 线程 tid 过滤 Flutter/Impeller 相关 slices，重点观察以下 slice 是否出现及其耗时：

| slice 名称 | 说明 | 指向的根因 |
|---|---|---|
| `impeller::CreateGlyphAtlas` / `UpdateAtlasBitmap` | 字形图集的创建与更新 | 字形图集冷启动（首次渲染新字形） |
| `Load/Compile Shaders` / `bisheng_graphic_pipeline_compilation` | 着色器加载与编译 | 着色器冷编译（首次使用新 shader） |
| `SurfaceFrame::Submit` / `Encode` | 帧的提交与编码 | 场景复杂、绘制指令过多 |
| `AcquireNextImageKHR` / `vkQueueSubmit` | GPU 图像获取与命令队列提交 | GPU 资源竞争或驱动瓶颈 |

![raster瓶颈](../media/sliding/sliding-3-2-2-raster_bottleneck.png)

## 4 常见根因和修复方案

### 4.1 根因：ListView 不定高

#### 现象

长列表快速滑动时掉帧，低端机尤其明显。Flutter 不知道每一项的高度，滚动时每出现一项都要重新测量，`itemBuilder` 会被高频调用，测量成本被放大。

#### Trace 判定信号

在滑动窗口内，若 UI 线程成为瓶颈，且出现以下特征，高度怀疑是 ListView 不定高：

| trace 特征 | 说明 |
|---|---|
| UI 线程 `LAYOUT` 阶段占比明显高于 `BUILD` / `PAINT` | 每项进入视口时都要测量高度，布局耗时被放大 |
| 调用栈中出现 `RenderSliverList.performLayout` / `childLayout` | 使用的是变高列表实现，逐项测量子节点 |
| 未出现 `RenderSliverFixedExtentList` | 未通过 `itemExtent` / `prototypeItem` 固定高度 |
| 快速滑动时 `BUILD` + `LAYOUT` 密集交替出现 | 新 item 不断进入视口，每次都要 build + layout 测高 |

> **注意**：trace 只能给出高度怀疑信号，无法直接显示“未设置 `itemExtent`”。最终根因需结合代码确认。

#### 代码验证

打开对应页面源码，检查 `ListView.builder` / `ListView.separated` 等是否缺少以下任一属性：

- `itemExtent`：固定高度
- `prototypeItem`：提供一条高度样板

若二者均未设置，且列表项高度确实随内容变化，则可确认本根因。

#### 修复

固定高度直接给 `itemExtent`：

```dart
ListView.builder(
  itemCount: data.length,
  itemExtent: 56, // 每一项高度 56，跳过测量
  itemBuilder: (context, i) => ItemCell(data[i]),
);
```

高度不固定时也可用 `prototypeItem` 提供一份样板。

#### 案例


**问题案例：不定高，逐项测量**

| | 问题案例 | 修复案例 |
|---|---|---|
| 说明 | 不定高，逐项测量 | 定高，跳过测量 |
| 截图 | ![](../media/sliding/sliding-4-1-problem_example.png) | ![](../media/sliding/sliding-4-1-fix_example.png) |

```dart
Widget _buildBadListView() {
  return ListView.builder(
    itemCount: itemCount,
    // 未设置 itemExtent，每一项高度需实时测量
    itemBuilder: (context, index) =>
        _buildItem(index, fixedHeight: false),
  );
}
```

未设置 `itemExtent` 时，ListView 使用 `RenderSliverList`（变高列表），滚动偏移无法直接计算，每出现一项都要 build + layout 测一次高度。标签数量 2~7 个、是否换行不一，导致每项高度在约 99~130px 之间变化，快速滑动时测量成本被放大，存在丢帧。

![](../media/sliding/sliding-4-1-problem_hitrace_jank.png)

**修复案例：定高，跳过测量**

```dart
Widget _buildGoodListView() {
  return ListView.builder(
    itemCount: itemCount,
    itemExtent: 136, // 固定高度（足以容纳两行标签），跳过逐项测量
    itemBuilder: (context, index) =>
        _buildItem(index, fixedHeight: true),
  );
}
```

设置 `itemExtent` 后，ListView 切换为 `RenderSliverFixedExtentList`，滚动偏移 = `index * 136`，无需逐项测量即可定位可见区域。内容与问题案例完全一致，只是较短项底部留白——这是固定高度换取流畅度的预期权衡。

两案例共用同一个 `_buildItem`，仅 `mainAxisSize` 不同——不定高案例用 `.min`（收缩到内容 → 高度参差），定高案例用 `.max`（填满 `itemExtent`）：

```dart
Widget _buildItem(int index, {required bool fixedHeight}) {
  final tagCount = (index % 6) + 2; // 2 ~ 7 个标签
  return Container(
    margin: _itemMargin,
    padding: _itemPadding,
    decoration: _itemDecorations[index % _itemDecorations.length],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text('Item $index', style: _titleStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(tagCount, _buildTag),
        ),
      ],
    ),
  );
}
```

> 补充：`itemExtent` 只消除了"量高度定位"的开销，每一项进入视口时 build + layout 仍会执行。为控制单项构建成本，两案例还共同做了以下处理：
>
> - 标签用轻量 `Container` + `Text` 替代 `Chip`，避免 `Chip` 内部 `Material`/`InkWell`/shape 裁剪开销；
> - 背景装饰 `BoxDecoration` + 颜色 shade 预计算为 `static final` 列表，不在每次 `itemBuilder` 调用时新建；
> - 样式、边距均提为 `static const`，全局共享不重建。

**效果对比**

| | 问题案例 | 修复案例 |
|---|---|---|
| `itemExtent` | 未设置 | 136 |
| 每项高度 | 随标签数量/换行变化（约 99~130px） | 固定 136px |
| 滚动定位 | 逐项 build+layout 测高度 | `index * 136` 直接定位 |
| 快速滑动 | 存在丢帧 | 流畅 |
| hitrace截图 | ![](../media/sliding/sliding-4-1-problem_hitrace.png) | ![](../media/sliding/sliding-4-1-fix_example_hitrace.png) |

### 4.2 根因：过度绘制/离屏缓冲

#### 现象

静态看正常，滑动或动画时掉帧，只有 Raster 线程耗时长。

#### Trace 判定信号

若滑动时 UI 线程正常，但 Raster 线程成为瓶颈，且出现以下特征，高度怀疑过度绘制 / 离屏缓冲：

| trace 特征 | 说明 |
|---|---|
| `GPURasterizer::Draw` 占比显著高于 `Animator::BeginFrame` | 绘制负载重，问题在 Raster 线程 |
| `GPURasterizer::Draw` 子调用中出现 `saveLayer` | 存在离屏缓冲，通常是裁剪、Opacity、阴影等触发 |
| 出现 `BackdropFilter` / `ImageFilter` 相关 slice | 全屏或大面积模糊导致逐像素卷积 |
| 动画场景下每帧 `GPURasterizer::Draw` 都很长 | 动画每帧都触发重绘，saveLayer / 模糊成本被放大 |
| 排除 shader 编译（无 `Load/Compile Shaders`） | 说明不是着色器冷编译，而是绘制本身过重 |

> **注意**：trace 能告诉你“存在 saveLayer / 模糊 / 绘制过重”，但无法直接指出是哪一个 Widget 触发的。具体 Widget 需结合代码或 DevTools 的 Repaint Rainbow 等工具定位。

#### 代码验证

回到对应页面代码，重点检查可见 item 及其动画子树中是否存在以下高耗操作：

- `Clip.antiAliasWithSaveLayer`（包括 `ClipRRect` 等使用 `antiAliasWithSaveLayer`）
- 动画中直接使用 `Opacity` Widget
- 大面积 `BackdropFilter` / `ImageFiltered` 模糊
- 复杂 `BoxShadow`（大 `blurRadius` / `spreadRadius`）
- 缺少 `RepaintBoundary` 导致动画重绘向父级扩散

#### 修复

- 圆角用默认裁剪，避免 `antiAliasWithSaveLayer`；
- 动画中需要透明度变化时，用 `FadeTransition` / `AnimatedOpacity` 替代直接动画 `Opacity`；
- 静态半透明直接改颜色 alpha，少用 Opacity Widget；
- 模糊只用于小区域；
- 高频重绘的局部区域用 `RepaintBoundary` 隔离，但别滥用。

#### 案例

50 个 item 各自循环播放透明度动画（0.3↔1.0，2s），两案例动画参数完全相同，差别只在 Widget 选型和裁剪/模糊/阴影配置。
![](../media/sliding/sliding-4-2-occlusion_case.png)

**问题案例：四重 saveLayer 叠加**

动画驱动用 `AnimatedBuilder` + 裸 `Opacity`，opacity 每帧变化触发 paint 阶段 `saveLayer`：

```dart
@override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Opacity(
        opacity: _animation.value,  // 每帧变化 → saveLayer
        child: child,
      );
    },
    child: _buildBadContent(widget.index),
  );
}
```

内容层还叠加了另外三个 saveLayer / 高耗操作：

```dart
Widget _buildBadContent(int index) {
  return ClipRRect(
    clipBehavior: Clip.antiAliasWithSaveLayer,    // ① 离屏裁剪
    borderRadius: _overdrawClipRadius,
    child: Container(
      // ...
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: ...),
        boxShadow: const [
          BoxShadow(blurRadius: 12, spreadRadius: 2, ...),  // ③ 大面积阴影
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(               // ② 全区域高斯模糊
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Center(child: Text('Item $index', style: _overdrawTextStyle)),
        ],
      ),
    ),
  );
}
```

每个可见 item 每帧 = `Opacity` saveLayer + `antiAliasWithSaveLayer` saveLayer + 全区域 `BackdropFilter` 模糊 + 大面积阴影重绘，Raster 线程迅速过载。

**修复案例：逐项消除 saveLayer**

```dart
@override
Widget build(BuildContext context) {
  return RepaintBoundary(              // ④ 隔离重绘范围
    child: FadeTransition(            // ①→合成层 opacity，不 saveLayer
      opacity: _animation,
      child: _buildGoodContent(widget.index),
    ),
  );
}
```

```dart
Widget _buildGoodContent(int index) {
  return ClipRRect(
    clipBehavior: Clip.hardEdge,     // ②→硬边裁剪，不 saveLayer
    borderRadius: _overdrawClipRadius,
    child: Container(
      // ...
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: ...),
        boxShadow: const [
          BoxShadow(blurRadius: 6, spreadRadius: 0, ...),  // ③→缩小阴影
        ],
      ),
      child: Center(
        child: Text('Item $index', style: _overdrawTextStyle),
      ),
    ),
  );
}
```

核心改动：

- `Opacity` → `FadeTransition`：opacity 下沉到合成层（`OpacityLayer`），子树只 paint 一次，之后每帧仅 compositor 调整 layer opacity，paint 阶段不再 `saveLayer`；
- `antiAliasWithSaveLayer` → `hardEdge`：直接在 paint 时跳过裁剪区域外像素，不开离屏 buffer；
- `BackdropFilter` 直接移除：背景只是渐变，模糊无实际视觉收益，删掉省掉逐像素卷积；
- `BoxShadow` 缩小（blur 12→6, spread 2→0）：减少阴影重绘面积；
- 外层 `RepaintBoundary`：动画只脏标记自己的 layer，不向父级 ListView 传播。

> 补充：`AnimatedBuilder` 的 `child` 参数应传入不变的内容（如上 `_buildBadContent`），而非在 builder 内部每次调用——这样 Widget tree 只构建一次。问题案例虽仍因 `Opacity` 触发 saveLayer，但至少避免了每帧重建子树的开销。

**效果对比**

| 开销来源 | 问题案例 | 修复案例 |
|---|---|---|
| 透明度动画 | `Opacity` → paint 阶段 saveLayer | `FadeTransition` → 合成层调 opacity |
| 圆角裁剪 | `antiAliasWithSaveLayer` → 离屏 buffer | `hardEdge` → 直接裁剪 |
| 背景模糊 | 全区域 `BackdropFilter` sigma=8 | 移除 |
| 阴影 | blur 12 / spread 2 | blur 6 / spread 0 |
| 重绘隔离 | 无显式 `RepaintBoundary` | 有 `RepaintBoundary` |
| 快速滑动 | Raster 线程红，明显掉帧 | 流畅 |
| hitrace截图 | ![](../media/sliding/sliding-4-2-problem_example_hitrace.png) | ![](../media/sliding/sliding-4-2-fix_example_hitrace.png) |

## 5. 参考与延伸

- Flutter 官方性能文档（https://docs.flutter.dev/perf）
- DevTools Performance 指南（https://docs.flutter.dev/tools/devtools/performance）
- 鸿蒙 性能调优工具简介（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-insight-description）
- 鸿蒙 trace 级深挖（配套三篇）：
  - [性能分析第一步-梳理线程顺序](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-analysis-threads-sequence.md)
  - [性能分析-帧渲染跟踪](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-frame-rendering-tracking.md)
  - [性能分析-滑动响应时延](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-sliding-response-time.md)
