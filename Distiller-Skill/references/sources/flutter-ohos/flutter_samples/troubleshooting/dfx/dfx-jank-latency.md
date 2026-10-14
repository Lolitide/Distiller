# 滑动卡顿丢帧与时延问题分析指南

> 返回 [README.md](README.md)

> 当用户说"这列表怎么又卡了"时，八成不是网络在摸鱼，而是帧在暗中掉链子。
> 本文档教你从"感觉卡"到"实锤"的完整方法：渲染模型 → 卡顿定位 → 工具使用 → 时延量测。

---

## 1. 渲染模型：一帧的时间去哪了？

### 1.1 渲染流水线：Build → Layout → Paint → Composite

每一帧画面都要经过四个阶段才能显示到屏幕上，就像工厂的流水线：

```
Build → Layout → Paint → Composite（光栅化）
 │       │        │         │
 │       │        │         └─ Raster 线程：把画面变成像素，交给 GPU 上屏
 │       │        └─ UI 线程：生成绘制指令（Layer 树）
 │       └─ UI 线程：确定每个组件的大小和位置
 └─ UI 线程：执行你的 Dart 代码，更新 Widget 树
```

| 阶段 | 在哪条线程 | 做什么 | 慢了会怎样 |
|------|-----------|--------|-----------|
| **Build** | UI 线程 | 执行 Dart 代码，更新 Widget 树 | Dart 代码太复杂 |
| **Layout** | UI 线程 | 确定每个组件的大小和位置 | 布局层级太深 |
| **Paint** | UI 线程 | 生成绘制指令（Layer 树） | 绘制指令太多 |
| **Composite** | Raster 线程 | 把 Layer 树变成像素，经鸿蒙 RenderService 合成上屏 | 画面太复杂（大图/模糊/大量图层） |

> **新手提示**：排查卡顿的第一步，就是搞清楚**哪条线程超时了**——是 UI 线程（Dart 代码慢）还是 Raster 线程（绘制太重）。

### 1.2 帧预算

屏幕每秒刷新 60 次（或 90/120 次），每一帧必须在规定时间内画完：

| 屏幕刷新率 | 帧预算 | 通俗解释 |
|-----------|--------|---------|
| 60Hz | **16.6ms** | 每帧要在 16.6 毫秒内画完 |
| 90Hz | **11.1ms** | 每帧要在 11.1 毫秒内画完 |
| 120Hz | **8.3ms** | 每帧要在 8.3 毫秒内画完 |

如果某一帧没在帧预算内画完，这帧就"丢了"（丢帧/Jank），用户看到的就是"卡了一下"。

> **打个比方**：就像翻页动画书，每秒翻 60 页才能看起来流畅。如果某一页你翻了 50 毫秒才翻完，动画就会"卡"一下。

### 1.3 四个必须分清的指标

| 指标 | 通俗解释 | 怎么看 | 注意事项 |
|------|---------|--------|---------|
| **FPS / 丢帧率** | 整体流畅度 | Overlay 或 SmartPerf | **平均值会掩盖偶发大卡顿**，要看 P90/P99 帧耗时 |
| **帧耗时** | 每一帧画了多久 | DevTools Frames 图表 | UI 和 Raster 要分开看 |
| **响应时延** | 触摸到首帧反馈的时间 | trace 链 / 打点 | >100ms 用户感觉"迟钝" |
| **完成时延** | 操作到彻底完成的时间 | 打点（t2-t0） | 响应合格不代表完成合格 |

> **新手避坑**：别被平均 FPS 骗了！平均 55fps 看着不错，但如果有几帧花了 200ms，用户绝对觉得卡。要看 P90/P99 帧耗时和超时帧计数。

### 1.4 响应时延 vs 完成时延

这是华为应用体验质量标准里的两个重要指标，用户说"卡"很多时候是这两个时延出了问题：

| 指标 | 通俗解释 | 用户感受阈值 | 举例 |
|------|---------|------------|------|
| **响应时延** | 从用户触摸到**首个画面反馈**的时间 | >100ms 感觉"迟钝" | 点了按钮，100ms 后界面才有反应 |
| **完成时延** | 从用户操作到**整个操作彻底完成**的时间 | 视场景而定 | 点开详情页，白屏 2 秒才出内容 |

> **新手区分**：
> - 响应时延是"点了有没有立刻有反应"——主线程被阻塞会导致响应慢
> - 完成时延是"操作有没有彻底完成"——数据加载慢、首屏构建太大会导致完成慢
> - 响应时延可能合格（点了立刻有动画），但完成时延崩了（动画完了内容还没出来）

---

## 2. 触摸事件到上屏的全链路

### 2.1 触摸事件的传送链

当你手指滑动屏幕时，事件要经过一条很长的"传送链"才能变成画面：

```
手指按下
│
├─ mmi_service（多模交互服务）
│  └─ 立即转发给应用主线程（DispatchTouchEvent, type=0）
│
├─ 手指滑动（move 事件, type=2）
│  └─ 不立即转发！由 vsync 信号门控，随帧节奏派发：
│     mmi_service → VSyncGennerator → DVSync-app → 应用主线程
│
├─ TouchSlop 滑动阈值
│  └─ 系统判定"开始滑动"的最小位移，默认 18vp
│     位移没超过阈值，不触发滑动
│
├─ 首帧一帧延迟
│  └─ 超过阈值后触发更新，但绘制要等下一帧
│     所以滑动开始的第一帧天然要多等一帧
│
└─ 渲染送显
   └─ 1.ui → 1.raster → render_service → RSUniRenderThread → RSHardwareThread → 屏幕显示
```

### 2.2 滑动响应时延的标准口径

**滑动响应时延 = 从 mmi_service 的手指按下 trace → 到滑动首帧在 RSHardwareThread 渲染结束**

这是华为应用体验质量标准对外出数的口径。Flutter 侧打点只能量到其中一段，两边对齐后数据才算数。

### 2.3 DevEco Profiler trace 链分析

用 DevEco Profiler 抓 trace 后，按以下顺序收藏 11 个线程，就能追任意一帧从触摸到送显的全链路：

```
VSyncGennerator → DVSync-app → mmi_service → 应用主线程
→ 1.ui → 1.raster → DVSync-rs → render_service
→ RSUniRenderThread → RSHardwareThread → dpu_gfx_primary
```

跨进程追帧的两个标识符：
- `frame_number`：关联 1.ui ↔ 1.raster
- `ReuseBuffer / acquire buffer`：关联 1.raster ↔ render_service

> **新手提示**：为什么"滑动响应时延"要以 trace 链为准？因为从手指按下到画面上屏，经过了系统服务和多个线程，只有 trace 链能完整覆盖。

---

## 3. 卡顿定位三板斧

> 整体打法：**Overlay 看走势（哪条线程红）→ DevTools 定界（哪个阶段超时）→ 逐帧实锤（具体是谁）**

### 3.1 板斧 A：Performance Overlay 看走势（最便宜）

一行代码开启，屏幕顶部出现两条柱状图：

```dart
MaterialApp(
  showPerformanceOverlay: true,  // 开启性能监控浮层
  home: MyApp(),
);
```

| 柱状图位置 | 代表什么 | 变红说明 |
|-----------|---------|---------|
| **上方** | Raster 线程（GPU 绘制） | 绘制太重（大图、模糊、saveLayer） |
| **下方** | UI 线程（Dart 代码） | Dart 代码慢（build/layout/paint） |
| **两条都红** | 两条线程都超时 | 一般是重建过大引发的连锁反应 |

> **新手提示**：开了 Overlay 后操作你的应用，哪条杠变红就知道是哪条线程的问题了。

### 3.2 板斧 B：DevTools Performance 定界

```bash
flutter run --profile  # 必须用 profile 模式！Debug 数据不准
```

在浏览器打开 DevTools → **Performance** 页：

- **Flutter Frames** 图表中，超预算的帧会标红（Shader 编译导致的掉帧还有专门标记）
- 点选某一帧，下方分开展示 **UI** 与 **Raster** 两条时间线
- **哪条长就是哪条在摸鱼**

### 3.3 板斧 C：逐帧实锤，揪出元凶

在 DevTools Performance 页勾上 **Enhance Tracing** 三件套：

| 勾选什么 | 看什么 | 找什么 |
|---------|--------|--------|
| **Track Widget Builds** | 每个 Widget 的 build 耗时 | "重建大户"——哪些 Widget 不该重建却在重建 |
| **Track Layouts** | 布局耗时 | layout 阶段的重灾区 |
| **Track Paints** | 绘制耗时 | paint 阶段的重灾区 |

> 拿到"超时帧 + 具体 Widget / 具体阶段"，Flutter 侧证据链就闭合了。如果怀疑问题出在平台调度而非 Dart 代码，再用 §5 的 DevEco Profiler trace 链分析。

### 3.4 其他 DevTools 工具

| 工具 | 用途 | 适合场景 |
|------|------|---------|
| **CPU Profiler** | 采样看 Dart 函数级耗时 | 找 build 阶段里的"内鬼函数" |
| **Widget Inspector → Repaint Rainbow** | 重绘区域会变色闪动 | 谁在全屏乱闪，谁就是 repaint 大户 |

---

## 4. 常见"卡顿真凶"与修复方法

### 4.1 Build 阶段高频坑（UI 线程）

#### 🕳️ setState 粒度过大：一处变化，全页重建

**症状**：Track Widget Builds 里整页 Widget 都在重建。

**修复**：状态下沉到最小范围 + 静态部分 `const`（完整 Demo 见 §7）。

#### 🕳️ 缺 const：同样的子树每帧重复构建

```dart
// ❌ 每次父级重建，这个静态头也跟着重来
Widget build(_) => Column(children: [Header(), ...]);

// ✅ const 构造，Flutter 直接复用实例，build 阶段瞬间瘦身
Widget build(_) => Column(children: [const Header(), ...]);
```

#### 🕳️ 在 build 里干重活

build 里同步读文件、解析 JSON、跑复杂计算——build 是"纯函数气质"的地方，重活请出门右转 `compute`（见 §7 Demo 2）。

### 4.2 Raster 阶段高频坑（GPU 线程）

#### 🕳️ Clip.antiAliasWithSaveLayer

名字里写明白了，每次裁剪都开 saveLayer，Raster 直接起飞。除非万不得已，用默认的 `Clip.antiAlias`。

#### 🕳️ 动画中的 Opacity

```dart
// ❌ 动画里直接用 Opacity，容易触发 saveLayer
Opacity(opacity: anim.value, child: heavyChild);

// ✅ 官方推荐：用 FadeTransition / AnimatedOpacity
FadeTransition(opacity: anim, child: heavyChild);
```

静态半透明更省事：直接给颜色加 alpha（`const Color(0x80FFFFFF)`），一层 Opacity 都不用。

#### 🕳️ 大面积模糊与大阴影

`BackdropFilter` / `ImageFiltered` 的成本与模糊面积正相关，只用在卡片级小区域，别糊全屏。

#### 🕳️ RepaintBoundary 用错方向

局部高频重绘的区域（进度条、动画）用它隔离，防止拖着全页重绘；但它本身占内存，**别满屏乱包**。

### 4.3 列表高频坑

#### 🕳️ 不定高 + 无 prototype

每次滚动都要现算每个 item 的高度。

```dart
// ✅ 定高列表直接给 itemExtent；不定高就给 prototypeItem 打个样
ListView.builder(
  itemExtent: 56,
  itemCount: data.length,
  itemBuilder: (context, i) => ItemCell(data[i]),
);
```

#### 🕳️ 一次性构建几百个 item

```dart
// ❌ 全构建了
ListView(children: items.map((e) => ItemWidget(e)).toList());

// ✅ 换 builder 懒加载
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);
```

#### 🕳️ itemBuilder 里同步 IO / 重组数据

itemBuilder 会在滚动中被高频调用，里面只允许轻量组装。

### 4.4 图片高频坑

#### 🕳️ 4K 原图塞进 200px 的卡片

解码和显存双重爆炸，分分钟掉帧。

```dart
// ✅ 按显示尺寸解码
Image.network(url, cacheWidth: 200, cacheHeight: 200);
```

### 4.5 时延类高频坑（响应/完成时延主战场）

#### 🕳️ 主线程同步重活

大 JSON 解析、批量读写、加解密全在 UI 线程 → 点击后首帧直接迟到。

**修复**：`compute` / Isolate 卸载（见 §7 Demo 2）。

#### 🕳️ 首屏一次性全量构建

新页面一次性 build 几百个 Widget，完成时延必炸。

**修复**：分页 / 懒加载 / 骨架屏先给响应，数据渐进填充。

### 4.6 Shader 编译 Jank（第一次必卡的那种）

**现象**：每个新动画 / 新页面第一次必掉帧，DevTools 标注 "Shader Compilation Jank"。

**通俗解释**：Skia 渲染管线里，某类绘制第一次出现时要现编译 shader（着色器），就像第一次做某道菜要现找菜谱。

| 后端 | 怎么治 |
|------|--------|
| **Impeller**（推荐） | 引擎启动期预编译 shader，基本根治 |
| **Skia** | 用 `--cache-sksl` 捕获 + 打包预热（Flutter 官方文档有完整流程） |

---

## 5. 怎么量时延？（把"感觉卡"变成数据）

### 5.1 方法 1：FrameTiming API（开发期自查）

```dart
import 'package:flutter/scheduler.dart';

void startFrameWatch() {
  SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
    const budget = Duration(milliseconds: 16); // 60Hz 帧预算
    for (final t in timings) {
      if (t.buildDuration > budget || t.rasterDuration > budget) {
        // 超时帧：可读取 t.buildDuration / t.rasterDuration / t.totalSpan
        // 落日志或上报，攒多了就是丢帧率
      }
    }
  });
}
```

配合打点量化时延：
- 手势回调记 **t0**
- 首帧 `addPostFrameCallback` 记 **t1**
- 数据就绪且渲染稳定记 **t2**

| 时延 | 计算 | 通俗解释 |
|------|------|---------|
| 响应时延 | t1 - t0 | 点了到有反应花了多久 |
| 完成时延 | t2 - t0 | 点了到彻底完成花了多久 |

### 5.2 方法 2：系统 trace 链（标准出数口径）

用 **DevEco Profiler** 抓 trace，按 §2.3 的 11 线程链追帧。

| 工具 | 用途 | 适合场景 |
|------|------|---------|
| **DevEco Profiler** | trace 分析，时延实锤 | 开发期深度分析 |
| **SmartPerf**（Host 端 / 设备端 SP_daemon） | 按包名采集 FPS、丢帧、CPU 等 | 脱离 IDE 的场景化巡检，适合走查和回归留档 |

> **时延口径**：对外出数以 trace 链为准（`mmi_service` 按下 → `RSHardwareThread` 首帧渲染结束）；FrameTiming 打点是开发期自查；高速相机可作仲裁手段。

### 5.3 方法 3：自动化回归（防劣化）

```dart
testWidgets('list scroll perf', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  await tester.binding.traceAction(() async {
    await tester.fling(find.byType(Scrollable), const Offset(0, -600), 8000);
    await tester.pumpAndSettle();
  }, reportKey: 'scrolling_timeline');
});
```

跑完得到帧耗时统计（build/raster 的平均、P90），塞进 CI 做基线巡检，回归劣化直接报警。

---

## 6. 性能分析大前提

> **一切性能结论以 profile 模式 + 鸿蒙真机为准！**

| 模式 | 能不能用于性能分析 | 原因 |
|------|-----------------|------|
| **Debug** | ❌ 不能 | 有断言、JIT、额外检查，数据不准 |
| **Profile** | ✅ 可以 | release 级优化 + 可观测 |
| **Release** | ⚠️ 缺调试信息 | 适合线上，不适合分析 |

```bash
flutter run --profile  # 性能分析一律用这个
```

> 建议备一台**中低端鸿蒙真机**做基线——在高端机上感觉不到的卡顿，在中低端机上会暴露。

---

## 7. 可复用的 Demo 片段

### Demo 1：整页 setState → 局部刷新（治掉帧）

```dart
// ❌ 问题：一个计数器变化，Header 和长列表全跟着重建
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
        HeavyHeader(),                    // 无辜躺枪，每次跟着重建
        Expanded(child: HeavyList()),     // 无辜躺枪 ×2
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
// ✅ 修复：可变状态下沉到最小子树，静态部分全部 const 化
class GoodPage extends StatelessWidget {
  const GoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        HeavyHeader(),               // const 构造，不再重复重建
        Expanded(child: HeavyList()),
        Counter(),                   // 只有它自己会 rebuild
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
      mainAxisAlignment: MainAxisAlignment.center,
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

复测对比：Track Widget Builds 里每次点击的重建数量，从"整页"降到"1 个子树"。

### Demo 2：首屏完成时延爆炸 → compute 卸载（治时延）

```dart
// ❌ 问题：大 JSON 在主线程解析 + 映射，点击后首帧迟到一个身位
Future<List<Item>> loadItems() async {
  final raw = await rootBundle.loadString('assets/items.json'); // 大文件
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Item.fromJson).toList(); // 全在 UI 线程
}
```

```dart
// ✅ 修复：解析下沉到后台 Isolate，主线程只负责渲染
import 'package:flutter/foundation.dart'; // compute

Future<List<Item>> loadItems() async {
  final raw = await rootBundle.loadString('assets/items.json');
  return compute(_parseItems, raw); // compute 要求顶层或静态函数
}

List<Item> _parseItems(String raw) {
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Item.fromJson).toList();
}
```

修完后同场景打点：**完成时延 t2 - t0 显著回落**，响应时延也不再被解析拖住。

---

## 8. 30 分钟实操剧本

**场景**：用户反馈"列表滑起来一卡一卡的"，怀疑重建过大或图片太大。

| 步骤 | 时间 | 做什么 | 看什么 |
|------|------|--------|--------|
| 1. 复现 + 看走势 | 5 分钟 | profile 包真机跑，开 Overlay，无限滚动 | 下方 UI 红、上方偶尔红 → Dart 侧为主 |
| 2. DevTools 定界 | 10 分钟 | 录 Performance，勾 Track Widget Builds | `ItemCell` 的父级整树重建 + `Image.network` 全是原图 |
| 3. 修复 | 10 分钟 | 数据拆独立 Widget + `const` + `itemExtent` + 图片 `cacheWidth/cacheHeight` | — |
| 4. 验证 + 出数 | 5 分钟 | 同场景复测 | Overlay 全绿、P90 回到预算内、超时帧清零；抓 trace 量响应时延，SmartPerf 留档 |

---

## 9. 性能自检清单

**Dart / Flutter 侧**

- [ ] 状态是否下沉到最小范围？静态子树有没有 `const`？
- [ ] build 里有没有同步 IO / 解析 / 复杂计算？重活是否 `compute` 卸载？
- [ ] 列表是否用 `builder` 懒加载？定高给了 `itemExtent`，不定高给了 `prototypeItem`？
- [ ] 图片是否按显示尺寸解码（`cacheWidth/cacheHeight`）？
- [ ] 有没有 `Clip.antiAliasWithSaveLayer`、动画版 `Opacity`、大面积模糊？
- [ ] 高频重绘局部是否用 `RepaintBoundary` 隔离（且没有滥用）？
- [ ] 首屏是否全量构建？有没有骨架屏 / 分页先给响应？

**工程 & 环境**

- [ ] 一切性能结论以 **profile + 鸿蒙真机** 为准；debug 数据不进报告
- [ ] 核心滑动 / 转场场景是否有 `traceAction` + SmartPerf 双基线？
- [ ] 丢帧率、P90 帧耗时、响应 / 完成时延有没有趋势图？
- [ ] 打点代码是否常驻（可开关）？线上灰度能不能捞回时延数据？

---

## 10. FAQ

**Q1：debug 模式卡得要死，是问题吗？**
不一定是。debug 有断言和 JIT 开销，一切结论以 profile 包为准。

**Q2：Overlay 两条杠怎么分工？**
上方是 Raster（GPU）线程，下方是 UI 线程，图上有文字标注；红柱 = 超帧预算。

**Q3：DevTools 标了 "Shader Compilation Jank"，怎么治？**
Skia 首次编译 shader 导致。所用 OHOS 引擎版本支持 Impeller 就优先开；Skia 后端则用 `--cache-sksl` 预热。

**Q4：响应 / 完成时延怎么测才算"标准口径"？**
滑动响应时延以 trace 链为准：mmi_service 按下 → 滑动首帧在 RSHardwareThread 渲染结束（自动化测试看 `dpu_gfx_primary`）；Flutter 侧打点（t0 触摸 → t1 首帧 → t2 稳定）是开发期自查，两边对齐后按华为应用体验质量标准的术语出报告。

**Q5：平均 FPS 看着挺高，用户还说卡？**
平均值会掩盖偶发大卡顿。看 P90/P99 帧耗时和超时帧计数，别被均值骗了。

---

## 11. 相关文档

| 文档 | 关联内容 |
|------|---------|
| [dfx-performance.md](dfx-performance.md) | 丢帧检测机制与 HiAppEvent 事件参数 |
| [dfx-appfreeze.md](dfx-appfreeze.md) | 卡死问题（卡顿严重时会演变为卡死） |
| [dfx-memory.md](dfx-memory.md) | GPU 上下文丢失导致的卡顿 |
| [dfx-texture.md](dfx-texture.md) | 外接纹理消费过慢导致的卡顿 |
| [dfx-logging.md](dfx-logging.md) | HiTrace 抓取方法 |

---

## 12. 参考与延伸

- Flutter 官方性能总览与最佳实践（docs.flutter.dev/perf、docs.flutter.dev/perf/best-practices）
- DevTools Performance 视图使用指南（docs.flutter.dev/tools/devtools/performance）
- Impeller 渲染引擎（docs.flutter.dev/perf/impeller）
- FrameTiming API（api.flutter.dev，scheduler 库）
- 鸿蒙 trace 级深挖（配套三篇，flutter_samples/docs/ohos/performance）：
  - [性能分析第一步-梳理线程顺序](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-analysis-threads-sequence.md)
  - [性能分析-帧渲染跟踪](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-frame-rendering-tracking.md)
  - [性能分析-滑动响应时延](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/performance/perf-sliding-response-time.md)
- SmartPerf 性能测试工具使用指南（华为开发者官网 / OpenHarmony 官方文档）
- DevEco Profiler 性能分析指南（developer.huawei.com）
- 华为应用体验质量标准：响应时延 / 完成时延术语定义（developer.huawei.com）
