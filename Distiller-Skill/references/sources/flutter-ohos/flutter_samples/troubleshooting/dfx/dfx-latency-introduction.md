# Flutter 点击响应和完成时延分析介绍

## 1. 概述

用户反馈"页面卡"时，有两类常见的**时延**问题：响应时延过长和完成时延过长。

响应时延一般指的是从手指触摸事件产生，到屏幕上出现**第一个可见反馈帧**的时间。Flutter 里这通常对应：触摸事件经系统分发到 Flutter 主线程 → 主线程处理并触发 rebuild → 生成 Layer tree → 渲染线程栅格化 → 送屏。

完成时延一般指的是从用户操作开始，到整个操作**彻底完成**（页面渲染稳定、数据全部展示）的时间。它包含响应时延，还包括数据加载、图片解码、复杂布局等后续工作。

## 2. Flutter 渲染管线介绍

Flutter 渲染一帧，大致经过四个阶段：

| 阶段 | 做什么 | 大致耗在哪条线程 |
| --- | --- | --- |
| **Build** | 根据状态变化构建/更新 Widget 树、Element 树 | UI 线程（主线程） |
| **Layout** | RenderObject 树计算每个节点的大小和位置 | UI 线程 |
| **Paint** | 生成绘制指令，构建 Layer tree | UI 线程 |
| **Composite** | 将 Layer tree 栅格化成像素，输出到屏幕 | Raster 线程（渲染线程/GPU 线程） |

其中**UI 线程**：运行 Dart VM，执行你的 Dart 代码和 Flutter 框架代码，产出 Layer tree；**Raster 线程**：接收 Layer tree，调用 Skia 或 Impeller 进行栅格化与合成，最终送屏。

性能分析时，两条线程的时间都要看：UI 线程耗时过长，说明 Dart 层有性能问题；Raster 线程耗时过长，说明绘制太重（阴影、模糊、大图、saveLayer 等）。

后续主要分析都围绕 UI 线程和 Raster 线程展开，需要先学会通过trace确认它们的 tid。通过查看 trace 的线程清单，重点关注以下角色分类：

| 角色 | 典型线程名 | 说明 |
|---|---|---|
| `flutter_ui` | `1.ui`、`root.1.ui`、`root.N.ui` | Flutter UI 线程，运行 Dart 代码 |
| `platform_main` | 应用包名（如 `.my_app`） | 应用主线程 |
| `flutter_raster` | `1.raster`、`root.1.raster` | Flutter Raster 线程，执行光栅化 |

> **Flutter 3.35+ 线程合并**：从 Flutter 3.35 版本起，OHOS 平台上 UI 线程与应用主线程可能合并为同一条线程，线程名为应用包名（如 `.complex_layout`），被归类为 `platform_main` 而非 `flutter_ui`。此时不能仅靠线程名判断 UI 线程，而应通过搜索 `flutter::Animator::BeginFrame` trace 来定位——该 slice 所在的 tid 即为 UI 线程。

## 3. 基于 OHOS平台Trace 的点击响应/完成时延定位

### 3.1 响应时延：首帧上屏
| trace name | 字段 | 说明 |
|---|---|---|
| `DispatchTouchEvent` | type 字段：0=按下、1=抬起、2=移动 | 触摸事件分发。 <br> 点击场景下通常只有一对 down/up，中间可能有少量 move。如果 trace 中有多段点击，每对 down/up 对应一次点击。 |


![DevEco Profiler 中点击窗口的 trace 示意](../media/latency/latency-3-1-click_window.png)



从**触摸起点**（点击场景取 `type=1` 离手、触摸/滑动场景取 `type=0` 按下）开始，向后查找首个完整的渲染帧链路：`Animator::BeginFrame` → `GPURasterizer::Draw` → `RSMainThread::DoComposition` → `RSHardwareThread::CommitAndReleaseLayers`。首帧到达 `CommitAndReleaseLayers` 的时刻即为**响应时延终点**。

### 3.2 完成时延：首屏稳定


从首帧上屏后继续向后查看，直到帧渲染活动趋于稳定——即 `Animator::BeginFrame` 和 `GPURasterizer::Draw` 不再连续出现，或帧间隔恢复正常刷新周期。最后一帧上屏的时刻即为**完成时延终点**。

![](../media/latency/latency-3-2-first_frame.png)

响应时延由多个环节串联组成，需要逐段度量耗时，找出最长的瓶颈环节：

| 环节 | 起止 trace | 高耗时含义 | 下一步深挖方向 |
|---|---|---|---|
| **多模输入** | 没有对应的trace_name，但是有对应的线程`mmi_service` | 系统侧触摸事件 | 不涉及 |
| **触摸事件分发** | `mmi_service` → `DispatchTouchEvent type=1/0` | 系统侧分发触摸事件到应用接收 | 不涉及 |
| **事件分发** | `DispatchTouchEvent type=1` → `Engine::DispatchPointerDataPacket` | 系统层事件分发延迟 | 检查 `touchEventDispatch`、系统侧事件积压 |
| **Vsync 等待** | `Engine::DispatchPointerDataPacket` → `VsyncFireCallback` | 触摸发生在两个 Vsync 之间，需等下一个 | 正常现象；若 >1 帧预算则异常 |
| **UI 线程处理** | `VsyncFireCallback` → `Animator::BeginFrame` → 完成 build/layout/paint | Dart 层 build 过重或被同步重活阻塞 | 检查 `begin_frame_` / `draw_frame_`，确认 BUILD/LAYOUT/PAINT 哪个阶段最重 |
| **Raster 栅格化** | `GPURasterizer::Draw` | 绘制过重或 shader/glyph 冷编译 | 检查 `CreateGlyphAtlas`、`Load/Compile Shaders`、`SurfaceFrame::Submit` |
| **应用→渲染服务** | `SurfaceFrame::Submit` → `RSMainThread::ProcessCommandUni[pid,seq]` | 引擎到渲染服务的提交与调度延迟 | 用 transactionFlag↔pid,seq 对齐、查 buffer 可用性 |
| **合成上屏** | `RSMainThread::DoComposition` → `CommitAndReleaseLayers` | 系统层合成负载重 | 检查合成器层级、fence 等待 |

> 多数情况下瓶颈在 **UI 线程处理**段（build 过重或同步重活阻塞）或 **Raster 栅格化**段（shader/glyph 冷编译）。事件分发和 Vsync 等待通常较短，若这两段长则属于系统层问题。


### 3.3 UI 线程瓶颈

在收窄窗口内，按 UI 线程 tid 过滤 slices，重点关注以下 slice，确认哪个阶段最重：

| slice 名称 | 说明 | 指向的根因 |
|---|---|---|
| `BUILD` | Widget 树的构建阶段 | 首屏一次性构建过多、setState 触发大范围重建、itemBuilder 创建重量级 Widget |
| `LAYOUT` | RenderObject 树的布局阶段 | 首屏布局复杂、使用 `IntrinsicHeight` / `IntrinsicWidth`、大量 Flex/Stack 嵌套 |
| `PAINT` | 生成绘制指令 | 绘制指令复杂、大量裁剪/复杂 `CustomPaint` |
| `Animate` | 动画回调执行 | 动画回调中做重计算 |
| `PlatformConfiguration` | 平台配置/消息处理 | Platform Channel 同步调用阻塞 |
| `BeginFrame` 整体长但子 slice 不明显 | 一帧开始，调度 BUILD/LAYOUT/PAINT 各阶段 | 主线程被同步重活阻塞（如 JSON 解析、文件 IO、复杂计算） |

如果上述 slices 中缺少 `BUILD`/`LAYOUT`/`PAINT`，说明 trace 未启用 `--trace-systrace`，UI 线程归因有限。需在 `FlutterLoader.ets` 中添加 `--trace-systrace` 引擎参数后重新采集。

#### 根因1：主线程做同步重活

##### 现象

点击页面后白屏/卡死一会儿，然后内容一次性出来。完成时延很长。

##### Trace 判定信号

点击后若 UI 线程成为瓶颈，且出现以下特征，高度怀疑主线程在做同步重活：

| trace 特征 | 说明 |
|---|---|
| `BeginFrame` 整体长，但 `BUILD`/`LAYOUT`/`PAINT` 子 slice 不明显 | UI 线程被其他同步任务占用，没有明显在构建/布局/绘制 |
| `PlatformConfiguration` / `DartIsolate::HandleMessage` 等 slice 异常长 | 主线程正在处理大量平台消息或 Dart 消息 |
| 点击后 `Animator::BeginFrame` 迟迟不出现，或首帧远超帧预算 | 首帧被同步重活阻塞，无法及时开始渲染 |
| 期间 `GPURasterizer::Draw` 几乎无活动 | Raster 线程在等待 UI 线程产出 Layer tree |

> **注意**：trace 只能判断“主线程被阻塞”，无法直接显示阻塞来源是 JSON 解析、文件 IO 还是复杂计算，需结合代码确认。

##### 代码验证

打开按钮点击或页面入口对应的处理函数，检查是否存在以下同步重活：

- `jsonDecode` / `xmlDecode` 等大体积数据解析
- `rootBundle.loadString` / `File.readAsStringSync` 等同步文件读取
- 复杂数学运算、大量字符串处理、图片编码等 CPU 密集型操作
- 在 `setState` 之前同步执行上述操作

若存在，则确认本根因。

##### 修复

把重活放到 Isolate 里：

```dart
import 'package:flutter/foundation.dart';

Future<List<Item>> loadItems() async {
  final raw = await rootBundle.loadString('assets/items.json');
  return compute(_parseItems, raw); // compute 把解析放到后台 Isolate
}

List<Item> _parseItems(String raw) {
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Item.fromJson).toList();
}
```

##### 案例

两案例用 1 亿次整数循环模拟"主线程同步重活"（约 0.5~2s），按钮点击触发计算，对比同步阻塞与 Isolate 后台计算的点击响应差异。

**问题案例：同步阻塞 UI 线程**

![](../media/latency/latency-3-3-1-problem_example.png)

点击按钮后直接在主线程同步执行 1 亿次循环，loading 指示器来不及渲染，按钮卡在按下状态直到计算结束：

```dart
const _heavyIterations = 100000000; // 1 亿次循环，约 0.5~2s

// 顶层函数，供 compute() 在后台 Isolate 中调用
int _heavyWork(int iterations) {
  var result = 0;
  for (var i = 0; i < iterations; i++) {
    result = (result + i * 31) & 0x7FFFFFFF;
  }
  return result;
}

class _SyncBadTabState extends State<_SyncBadTab> {
  int? _result;

  void _run() {
    // 同步阻塞：loading 指示器不会出现，按钮卡在按下状态
    final result = _heavyWork(_heavyIterations);
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _result == null ? '点击按钮开始计算' : '计算结果：$_result',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _run, child: const Text('同步计算（阻塞 UI）')),
            const SizedBox(height: 8),
            const Text('点击后界面会卡死，直到计算完成', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
```


**修复案例：compute 放到后台 Isolate**

![](../media/latency/latency-3-3-1-fix_example.png)

用 `compute()` 将计算丢到后台 Isolate，主线程立即返回，loading 指示器正常渲染，界面保持响应：

```dart
class _SyncGoodTabState extends State<_SyncGoodTab> {
  int? _result;
  bool _loading = false;

  Future<void> _run() async {
    setState(() => _loading = true);
    final result = await compute(_heavyWork, _heavyIterations);
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _result == null ? '点击按钮开始计算' : '计算结果：$_result',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _run,
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Isolate 计算（不阻塞）'),
            ),
            const SizedBox(height: 8),
            const Text('点击后立即出现 loading，界面保持响应', style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
```

**效果对比**

| | 问题案例 | 修复案例 |
|---|---|---|
| 计算位置 | 主线程同步执行 | 后台 Isolate（`compute`） |
| 点击后首帧 | 卡在按下状态，loading 不出现 | 立即出现 loading 指示器 |
| 界面响应 | 完全卡死至计算结束 | 始终可交互 |
| 完成时延 | 长（计算 + 渲染串行） | 短（计算与渲染并行） |
| hitrace截图 | ![](../media/latency/latency-3-3-1-problem_example_hitrace.png) | ![](../media/latency/latency-3-3-1-fix_example_hitrace.png) |

#### 根因2：首屏一次性构建/加载太多

##### 现象

页面打开后先白屏/转圈，然后内容一次性全部出现，完成时延高。

##### Trace 判定信号

点击跳转后若 UI 线程 `BUILD` 阶段极长，且出现以下特征，高度怀疑首屏一次性构建/加载过多：

| trace 特征 | 说明 |
|---|---|
| 首帧 `BUILD` slice 占比极高，`LAYOUT`/`PAINT` 被顺带拉长 | 首帧需要构建大量 Widget |
| `BUILD` 调用栈中出现大量子节点构建（如 `ListView` 子项、`Wrap` 子项） | 非懒加载导致一次性构建过多 Element |
| 首帧后仍连续多帧出现 `Animator::BeginFrame` + `GPURasterizer::Draw` | 内容分批构建或图片逐帧解码，完成时延被拉长 |
| `DecodeImage` / `ImageDecoder` 相关 slice 在首屏集中出现 | 首帧加载并解码了过多图片 |

> **注意**：trace 能看到“构建量大”，但无法直接区分是 Widget 数量多还是数据加载多，需结合代码确认。

##### 代码验证

检查目标页面的构建逻辑，确认是否存在以下情况：

- 使用 `ListView(children: ...)` / `Column` / `Wrap` 等一次性构建大量子项
- `initState` / `build` 中同步生成或加载大量数据
- 首屏一次性请求并解码所有图片
- 缺少骨架屏或占位，等待全部内容就绪后才上屏

若存在以上情况，则确认本根因。

##### 修复

- 优先显示骨架屏或占位，先给用户反馈；
- 数据分页、图片懒加载；
- 非首屏内容延迟 build。

##### 案例

两案例的 Tab 页各有一个按钮，点击后跳转到列表页面。完成时延从按钮点击开始度量，到列表内容全部渲染稳定为止。对比非懒加载全量构建与骨架屏 + 分批懒加载的完成时延。

**问题案例：非懒加载 ListView，500 个 Widget 一次性全量构建**

![](../media/latency/latency-3-3-2-problem_example.png)

Tab 页展示一个跳转按钮；点击后 `Navigator.push` 进入 `_OverBuildBadListPage`，该页面在 `initState` 中生成 500 条数据，`build` 返回非懒加载 `ListView`，500 个 Widget 全量构建，首帧需等待全部 build 完成：

```dart
class _OverBuildBadTab extends StatelessWidget {
  const _OverBuildBadTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _OverBuildBadListPage()),
            ),
            child: const Text('打开列表页面（非懒加载 500 项）'),
          ),
          const SizedBox(height: 8),
          const Text('点击后白屏，500 项一次性全量构建', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class _OverBuildBadListPageState extends State<_OverBuildBadListPage> {
  late final List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.generate(500, (i) => 'Item $i');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('问题案例')),
      body: ListView(children: _items.map(_buildListItem).toList()),
    );
  }
}
```


**修复案例：骨架屏 + 分批懒加载**

![](../media/latency/latency-3-3-2-fix_example.png)

Tab 页同样展示一个跳转按钮；点击后进入 `_OverBuildGoodListPage`，该页面先渲染骨架屏占位，让首帧快速上屏；再分 10 批、每批 50 条增量加载，用 `ListView.builder` 懒加载：

```dart
class _OverBuildGoodTab extends StatelessWidget {
  const _OverBuildGoodTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _OverBuildGoodListPage()),
            ),
            child: const Text('打开列表页面（骨架屏 + 分批加载）'),
          ),
          const SizedBox(height: 8),
          const Text('点击后骨架屏先上屏，内容逐步填充', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

class _OverBuildGoodListPageState extends State<_OverBuildGoodListPage> {
  final List<String> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIncrementally();
  }

  Future<void> _loadIncrementally() async {
    await Future.delayed(const Duration(milliseconds: 16)); // 先让骨架帧渲染
    for (int batch = 0; batch < 10; batch++) {
      if (!mounted) return;
      setState(() {
        _items.addAll(List.generate(50, (i) => 'Item ${batch * 50 + i}'));
        _loading = false;
      });
      await Future.delayed(Duration.zero); // 让出事件循环，不添加额外延迟
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? ListView.builder(itemCount: 10, itemBuilder: (_, __) => _buildSkeletonItem())
        : ListView.builder(itemCount: _items.length, itemBuilder: (_, i) => _buildListItem(_items[i]));
    return Scaffold(
      appBar: AppBar(title: const Text('修复案例')),
      body: body,
    );
  }
}
```

> 补充：`_buildListItem` 每项含头像、标题、副标题和 2~5 个标签，构建开销远大于纯文本项；`_buildSkeletonItem` 返回灰色圆角占位 `Container`。两案例共用这两个辅助函数，仅加载策略不同。修复案例分批间用 `Future.delayed(Duration.zero)` 让出事件循环，不添加额外延迟，使完成时延主要由实际构建耗时决定。


**效果对比**

| | 问题案例 | 修复案例 |
|---|---|---|
| 跳转方式 | 按钮点击 → `Navigator.push` | 按钮点击 → `Navigator.push` |
| 每项复杂度 | 头像+标题+副标题+标签 | 头像+标题+副标题+标签 |
| 首帧构建 | 500 个复杂项全量 build | 10 个骨架项 |
| ListView 类型 | `ListView(children:)` 非懒加载 | `ListView.builder` 懒加载 |
| 首屏反馈 | 白屏等待全部 build 完成 | 骨架屏立即上屏 |
| 数据加载 | 一次性 500 条 | 分 10 批 × 50 条增量，批间无额外延迟 |
| 完成时延 | 长（500 项首帧阻塞） | 短（首帧快，内容逐步填充） |
| hitrace截图 | ![](../media/latency/latency-3-3-2-problem_example_hitrace.png) | ![](../media/latency/latency-3-3-2-fix_example_hitrace.png) |

####  根因3：setState 粒度太大，整页重建

##### 现象

点击后页面迟迟没有反馈，或者刷新一下要等很久内容才稳定。

##### Trace 判定信号

点击后若 UI 线程 `BUILD` 阶段变长，且出现以下特征，高度怀疑 `setState` 粒度太大：

| trace 特征 | 说明 |
|---|---|
| 点击后 `BUILD` slice 明显变长，但单次 `build` 函数本身并不复杂 | 重建范围过大，而非单个 Widget 过重 |
| `BUILD` 子调用包含大量本不该变化的静态子树 | `setState` 位置过高，导致静态内容也被 rebuild |
| 每次点击都触发几乎相同范围的 `BUILD` | 状态变化影响范围没有收敛 |
| 使用 `--trace-systrace` 后能看到 `LAYOUT`/`PAINT` 也被连带拉长 | rebuild 引发了整页重走 Layout/Paint |

> **注意**：trace 能看到“重建范围大”，但无法直接指出是哪个 `setState` 触发的，需结合代码确认。

##### 代码验证

检查对应页面的状态管理，确认是否存在以下情况：

- `setState` 调用位置在页面根节点或大范围祖先 Widget
- 静态子树未标记 `const`，导致每次 `setState` 都被迫 rebuild
- 状态没有下放到最小变化范围（如计数器状态放在页面级而非组件级）
- 存在 `StatefulWidget` 包裹大量静态内容，仅为了局部刷新

若存在以上情况，则确认本根因。

##### 修复

把状态下放到最小范围，静态子树用 `const` 避免重复构建。

```dart
// ❌ 不好：计数器变了，HeavyHeader 和 HeavyList 被迫重画
class BadPage extends StatefulWidget {
  const BadPage({super.key});
  @override
  State<BadPage> createState() => _BadPageState();
}

class _BadPageState extends State<BadPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeavyHeader(),                 // 没变，却被迫 rebuild
        Expanded(child: HeavyList()),  // 没变，却被迫 rebuild
        Text('$_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

```dart
// ✅ 好：只有 Counter 自己 rebuild，静态部分全部 const
class GoodPage extends StatelessWidget {
  const GoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HeavyHeader(),               // const：Flutter 会直接复用，不再 rebuild
        Expanded(child: HeavyList()),
        Counter(),                   // 变化范围被限制在这个子树
      ],
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key});
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

##### 案例

四个 Tab 对比两种重量级内容的重建开销：**非懒加载**（`Wrap` + 300 项，所有子项均有 Element）和**懒加载**（`GridView.builder` + 500 项，仅可见项有 Element）。每个 Tab 下方均有计数器按钮，+1 时触发 `setState`。

| Tab | 重量级内容 | setState 位置 | +1 后重建范围 |
|---|---|---|---|
| 问题·非懒加载 | `Wrap(300)` | 页面根 | 300 项全部重建 |
| 修复·非懒加载 | `const Wrap(300)` | `_ScopedCounter` 内 | 仅计数器 |
| 问题·懒加载 | `GridView.builder(500)` | 页面根 | 仅可见项重建 |
| 修复·懒加载 | `const GridView.builder(500)` | `_ScopedCounter` 内 | 仅计数器 |

**问题案例：setState 在页面根，重量级静态子树被迫重建**

![](../media/latency/latency-3-3-3-problem_example.png)

`_SetStateBadTab` 是 StatefulWidget，`setState` 在页面根节点。+1 时不仅计数器重建，上方的重量级子树也被迫 rebuild。`useLazy` 参数切换非懒加载与懒加载：

```dart
class _SetStateBadTab extends StatefulWidget {
  final bool useLazy;
  const _SetStateBadTab({this.useLazy = false});
  @override
  State<_SetStateBadTab> createState() => _SetStateBadTabState();
}

class _SetStateBadTabState extends State<_SetStateBadTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.useLazy
              ? const _HeavyStaticContentLazy()
              : const _HeavyStaticContentNonLazy(),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('$_count', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('+1')),
            ],
          ),
        ),
      ],
    );
  }
}
```


**修复案例：静态子树 const，状态下放到最小范围**

![](../media/latency/latency-3-3-3-fix_example.png)

页面改为 `StatelessWidget`，静态子树全部 `const`。计数器状态下沉到独立的 `_ScopedCounter`，+1 时只有它自己 rebuild：

```dart
class _SetStateGoodTab extends StatelessWidget {
  final bool useLazy;
  const _SetStateGoodTab({this.useLazy = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.useLazy
              ? const _HeavyStaticContentLazy()
              : const _HeavyStaticContentNonLazy(),
        ),
        const Padding(padding: EdgeInsets.all(16), child: _ScopedCounter()),
      ],
    );
  }
}

class _ScopedCounterState extends State<_ScopedCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$_count', style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 16),
        ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('+1')),
      ],
    );
  }
}
```

> 补充：两版重量级子树共用 `_buildHeavyCell`（图标+文本）。**非懒加载** `_HeavyStaticContentNonLazy` 用 `SingleChildScrollView` + `Wrap(300项)`，所有子项均有 Element，+1 时全部重建（约 1800 个 Widget 实例，耗时 ~15-20ms）。**懒加载** `_HeavyStaticContentLazy` 用 `GridView.builder(500项)`，仅可见项有 Element，+1 时仅重建约 20 个可见项（<1ms）。修复案例中两者均标记 `const`，Flutter 直接复用已有实例，+1 时不再 rebuild。


**效果对比**

| | 问题·非懒加载 | 修复·非懒加载 |
|---|---|---|
| 重量级内容 | `Wrap(300项)` | `const Wrap(300项)` |
| +1 后重建 | 300 项全部重建 | 仅计数器 |
| +1 重建开销 | ~15-20ms | <1ms |
| 响应时延 | 长（可见 jank） | 短 |
| hitrace截图 | ![](../media/latency/latency-3-3-3-problem_example_hitrace.png) | ![](../media/latency/latency-3-3-3-fix_example_hitrace.png) |

### 3.4 Raster 线程瓶颈

在收窄窗口内，按 Raster 线程 tid 过滤 Flutter/Impeller 相关 slices，重点观察以下 slice 是否出现及其耗时：

| slice 名称 | 说明 | 指向的根因 |
|---|---|---|
| `impeller::CreateGlyphAtlas` / `UpdateAtlasBitmap` | 字形图集的创建与更新 | 字形图集冷启动（首次渲染新字形） |
| `Load/Compile Shaders` / `bisheng_graphic_pipeline_compilation` | 着色器加载与编译 | 着色器冷编译（首次使用新 shader） |
| `SurfaceFrame::Submit` / `Encode` | 帧的提交与编码 | 场景复杂、绘制指令过多 |
| `AcquireNextImageKHR` / `vkQueueSubmit` | GPU 图像获取与命令队列提交 | GPU 资源竞争或驱动瓶颈 |
| `DecodeImage` / `ImageDecoder` 相关 slice | 图片解码 | 图片按原尺寸解码、未使用 `cacheWidth`/`cacheHeight` |

> 其他常见 Raster 瓶颈（大图解码、saveLayer 过度绘制、阴影模糊等）。

#### 根因1：大图按原尺寸解码

##### 现象

点进页面后图片迟迟不显示，或下拉刷新后内容稳定很慢。

##### Trace 判定信号

若点击后 Raster 线程成为瓶颈，且出现以下特征，高度怀疑大图按原尺寸解码：

| trace 特征 | 说明 |
|---|---|
| `GPURasterizer::Draw` 或图片解码相关 slice 明显变长 | 图片解码占用了大量 Raster 线程时间 |
| 出现 `DecodeImage` / `ImageDecoder` / `UploadTexture` 等相关 slice | 引擎正在解码或上传大尺寸图片 |
| UI 线程正常，但首屏图片区域长时间空白或卡顿 | 瓶颈在图片解码，而非 Dart 层构建 |
| 图片首次显示时掉帧，后续滑动正常 | 首次解码成本高，缓存后不再复现 |

> **注意**：trace 能判断“图片解码耗时高”，但无法直接显示图片原始分辨率和显示尺寸的差异，需结合代码确认。

##### 代码验证

检查页面中图片加载相关的代码，确认是否存在以下情况：

- `Image.network` / `Image.memory` / `Image.asset` 等未指定 `cacheWidth` / `cacheHeight`
- 网络/本地图片原始分辨率远大于实际显示尺寸
- 列表中大量图片同时解码，未做懒加载或预加载控制
- 使用了 `ImageCache` 但未限制图片大小

若存在以上情况，则确认本根因。

##### 修复

按目标显示尺寸解码：

```dart
Image.network(
  imageUrl,
  cacheWidth: 200,  // 只解码到 200×200
  cacheHeight: 200,
);
```

##### 案例

两案例的 Tab 页各有一个按钮，点击后跳转到图片列表页面。完成时延从按钮点击开始度量，到图片全部解码并显示为止。图片数据在进入页面时由 `dart:ui` 运行时生成（4000×3000 PNG），**无网络依赖**，确保只对比解码耗时。

**问题案例：无 cacheWidth/cacheHeight，按 4000×3000 原尺寸解码**

![](../media/latency/latency-3-4-1-problem_example.png)

Tab 页展示一个跳转按钮；点击后 `Navigator.push` 进入 `_ImageBadListPage`，`Image.memory` 未指定 `cacheWidth`/`cacheHeight`，图片按 4000×3000 原分辨率解码，但最终只显示 200 高——解码与显存开销全部浪费：

```dart
class _ImageBadTab extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageBadTab({required this.imageBytes});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ImageBadListPage(imageBytes: imageBytes)),
            ),
            child: const Text('加载图片（原尺寸解码）'),
          ),
          const SizedBox(height: 8),
          const Text('4000×3000 原尺寸解码，Raster 线程耗时长', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

class _ImageBadListPage extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageBadListPage({required this.imageBytes, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('问题案例')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8),
          child: Image.memory(imageBytes, height: 200, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
```


**修复案例：指定 cacheWidth/cacheHeight，只解码到显示所需尺寸**

Tab 页同样展示一个跳转按钮；点击后进入 `_ImageGoodListPage`，指定 `cacheWidth: 800`、`cacheHeight: 600`（物理像素），解码到 800×600 即可，解码时间与显存大幅减少：

```dart
class _ImageGoodTab extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageGoodTab({required this.imageBytes});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ImageGoodListPage(imageBytes: imageBytes)),
            ),
            child: const Text('加载图片（缩放解码）'),
          ),
          const SizedBox(height: 8),
          const Text('800×600 缩放解码，Raster 线程耗时短', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

class _ImageGoodListPage extends StatelessWidget {
  final Uint8List imageBytes;
  const _ImageGoodListPage({required this.imageBytes, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修复案例')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8),
          child: Image.memory(
            imageBytes,
            height: 200,
            fit: BoxFit.cover,
            cacheWidth: 800, // 只解码到 800×600（物理像素）
            cacheHeight: 600,
          ),
        ),
      ),
    );
  }
}
```

> 补充：图片数据在进入页面时由 `dart:ui` 运行时生成（`PictureRecorder` + `Canvas` 画渐变+500 个圆 → `toImage` → `toByteData(png)`），生成一次后缓存为 `Uint8List`，两案例共用同一份字节。`cacheWidth`/`cacheHeight` 的单位是物理像素，若设备 DPR=3，逻辑像素 200 高对应物理像素 600，此处取 800 略有富余以保证清晰度。

**效果对比**

| | 问题案例 | 修复案例 |
|---|---|---|
| 跳转方式 | 按钮点击 → `Navigator.push` | 按钮点击 → `Navigator.push` |
| 图片来源 | 运行时生成 4000×3000 PNG | 同一份字节 |
| 解码 API | `Image.memory` | `Image.memory` + `cacheWidth`/`cacheHeight` |
| 解码分辨率 | 4000×3000（原尺寸） | 800×600 |
| 显示尺寸 | 200 高 | 200 高 |
| 解码像素量 | 1200 万 | 48 万（约 1/25） |
| 显存占用 | 高 | 低 |
| 完成时延 | 长（大图解码慢） | 短（解码快，内容尽快稳定） |
| hitrace截图 | ![](../media/latency/latency-3-4-1-problem_example_hitrace.png) | ![](../media/latency/latency-3-4-1-fix_example_hitrace.png) |

##### hitrace细节

下面从hitrace细节去逐一分析。先把UI线程和Raster线程收藏排序，因为本案例涉及图片解码，会有文件读取，还会有IO线程或IO的Worker线程参与。
收藏线程后的概览图如下，问题案例的耗时明显大于修复案例。

| | 问题案例 | 修复案例 |
|---|---|---|
| 线程概览图 | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_1.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_1.png) |


关于图片的原图信息，可以在UI线程中找到。 对比问题案例和修复案例的截图，发现是一致的。
`Image MakeFromDataOHOS`展示原图内存大小，`Image GetInfo:ImageGenerate-0xxxxxxxxx:(size-4000*3000,frame_count-1-duration-0,isHdr-0)`展示解码申请的内存大小。

| | 问题案例 | 修复案例 |
|---|---|---|
| 原图内存大小 | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_2.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_2.png) |
| 原图尺寸大小 | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_3.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_3.png) |


接下来看图片解码申请的耗时和内存大小。 对比下方截图，问题案例的图片解码耗时明显大于修复案例。同时解码申请的内存大小也明显大于修复案例。
`Image CreateExternalTextureSourceOHOS:ImageGenerate-0xxxxxxxx:(size-4000*3000,frame_count-1-duration-0,isHdr-0)`展示解码申请的耗时和原图尺寸大小。对比问题案例和修复案例的截图，发现问题案例的耗时和内存大小明显大于修复案例。 
`vkAllocateMemory: xxxxx`系统侧展示解码图片申请的内存大小。

| | 问题案例 | 修复案例 |
|---|---|---|
| 图片解码耗时 | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_4.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_4.png) |
| 解码申请的内存大小 | ![](../media/latency/latency-3-4-1-image_problem_example_hitrace_5.png) | ![](../media/latency/latency-3-4-1-image_fix_example_hitrace_5.png) |


## 4. 参考与延伸

- Flutter 官方性能文档（https://docs.flutter.dev/perf）
- DevTools Performance 指南（https://docs.flutter.dev/tools/devtools/performance）
- 鸿蒙 性能调优工具简介（https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-insight-description）
- 鸿蒙 trace 级深挖（配套三篇）：
  - [性能分析第一步-梳理线程顺序](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-analysis-threads-sequence.md)
  - [性能分析-帧渲染跟踪](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-frame-rendering-tracking.md)
  - [性能分析-滑动响应时延](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-sliding-response-time.md)