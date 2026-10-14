# 负载异常与功耗问题定位指南

> 返回 [README.md](README.md)

> 当用户说"手机发烫"、"电量掉得快"、"后台也在偷偷耗电"时，多半是应用在持续吃 CPU。
> 本文档教你从"感觉烫/卡"到"实锤热点"的完整方法：进程线程 → hiperf 采样 → 火焰图 → 优化。

---

## 1. 什么是负载异常和功耗问题？

### 1.1 通俗解释

Flutter 应用跑起来要消耗 CPU，就像汽车要烧油。正常情况下，应用只在需要刷新画面、处理交互时才消耗 CPU；画面不动时，CPU 应该闲下来。**负载异常**就是 CPU 一直高占用，**功耗问题**就是这种高占用导致发热、耗电。

> **打个比方**：一辆车在等红灯时应该怠速（CPU 占用低），如果你的车在等红灯时还在狂踩油门（CPU 一直高占用），既费油（耗电）又会过热（发烫）。

### 1.2 两种问题场景

| 场景 | 触发条件 | 通俗解释 | 排查难点 |
|------|---------|---------|---------|
| **前台高负载** | 应用在前台时某进程持续占用 CPU | 用着用着就烫手，可能伴随卡顿 | 找到"哪条线程在忙、忙在哪段代码" |
| **后台功耗异常** | 应用退到后台后仍频繁唤醒/跑任务 | 没打开应用，电量却掉得快 | 抓到"后台还在跑什么、多久醒一次" |

> **新手提示**：前台高负载和卡顿经常同时出现（CPU 被占满 → 帧画不完 → 丢帧）。如果已经排查过丢帧（见 [dfx-performance.md](dfx-performance.md)）发现不是 Dart/GPU 单帧慢，那就要怀疑是"持续高负载"在拖累整体。

### 1.3 具体现象

| 你看到的现象 | 严重程度 | 可能的原因 |
|-------------|---------|-----------|
| 手机发烫（特别是应用运行一段时间后） | 中 | 持续高频重绘 / 后台轮询 |
| 电量掉得快 | 中 | 后台任务未暂停 / 高频定时器 |
| 应用越用越卡 | 中 | GC 频繁（对象创建过多）+ CPU 热点 |
| 列表滑动整体偏卡（不是偶发顿挫） | 中 | 滑动过程中持续高 CPU 热路径 |
| 静止页面 CPU 仍不回落 | 高 | 空闲状态还在重绘 / 后台线程忙轮询 |
| 系统因功耗杀后台 | 高 | 后台功耗超标被系统回收 |

### 1.4 快速定位流程

```
应用发烫 / 耗电快 / 持续高 CPU
│
├─ 确认是哪个进程在吃 CPU
│  → hdc shell top -H -p {进程id}，找高频线程
│
├─ 确认是前台还是后台触发
│  → 前台：看是否持续重绘 / 重计算
│  → 后台：看是否定时器 / 轮询 / 动画没停
│
├─ 用 hiperf 抓指令数采样
│  → hdc shell hiperf record -e hw-instructions ...
│
├─ 生成火焰图，找顶部持续变宽的函数
│  → 宽度 = 采样时间占比，越宽越是热点
│
└─ 交叉比对 HiTrace / HiLog / HiAppEvent
   → 看是否伴随丢帧事件、是否有后台 trace
```

---

## 2. 常用采集手段

### 2.1 进程和线程信息

先确认目标进程是否持续占用 CPU：

```bash
# 找到 Flutter 应用进程
hdc shell ps -A | grep flutter

# 按线程看 CPU 占用（{进程id} 替换为上一步拿到的 PID）
hdc shell top -H -p {进程id}
```

如果存在明显的高频线程，重点看：

| 关注点 | 说明 |
|--------|------|
| UI 线程是否被阻塞 | 被阻塞的 UI 线程通常不会高 CPU，但重计算会 |
| Raster / GPU 相关线程是否持续高占用 | 持续高占用多半是画面在不停重绘 |
| 是否有后台线程在忙轮询 | 比如 while(true) 里不停检查状态 |
| 是否有线程频繁唤醒但实际无业务收益 | 定时器/轮询间隔过小，CPU 频繁被唤醒 |

> **新手提示**：`top -H` 的 `-H` 表示按线程展开。如果看到某个线程 CPU 占用持续 >30%（且应用没在刷新画面），基本可以锁定是它。

### 2.2 CPU 指令数采集（hiperf）

OHOS 平台下可以通过 `hiperf` 采集单个进程的 CPU 指令数，适合定位"哪些路径在持续消耗 CPU"。

```bash
# 采集 30 秒指令数采样（在这 30 秒内复现问题）
hdc shell "hiperf record -e hw-instructions -p {进程id} -f 1000 -d 30 -o /data/local/tmp/perf.data"

# 把采样数据拉到电脑
hdc file recv /data/local/tmp/perf.data
```

| 参数 | 含义 |
|------|------|
| `-e hw-instructions` | 以硬件指令数作为采样事件（谁执行的指令多，谁就是热点） |
| `-p {进程id}` | 只采这个进程 |
| `-f 1000` | 采样频率 1000Hz（每秒采 1000 次） |
| `-d 30` | 采集时长 30 秒 |
| `-o /data/local/tmp/perf.data` | 输出到设备路径 |

建议在以下场景采集：

- 列表滑动/滚动（持续操作场景）
- 复杂动画/切页（瞬时高负载场景）
- 长时间停留页面的空闲状态（验证空闲是否真的空闲——这是抓功耗的关键场景）

### 2.3 采样数据处理与 FlameGraph 分析

采集到 `perf.data` 后，需要把数据转成可分析的堆栈格式，然后生成火焰图：

```bash
# 以 perf/FlameGraph 工具链为例
perf script -i perf.data > perf.stacks
stackcollapse-perf.pl perf.stacks > perf.folded
flamegraph.pl perf.folded > perf.svg
```

用浏览器打开 `perf.svg` 即可看到火焰图。

> **新手提示**：火焰图是什么？它把程序运行时每个函数的耗时画成一层层的"火焰"，**横轴宽度 = 该函数被采样到的次数（即耗时占比）**。越宽的"色块"就是越大的热点，找到最宽的那个基本就锁定元凶了。

### 2.4 HiTrace / HiLog / HiAppEvent 交叉排查

只看 CPU 占用还不够，要结合 trace 和日志判断"这段时间应用到底在干什么"：

```bash
# 抓取 trace（复现问题场景时，建议 30 秒）
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace
```

日志采集：

```bash
hdc shell hilog | grep -Ei "jank|frame|flutter|cpu|power"
```

交叉比对的方法：

| 数据源 | 看什么 | 交叉比对结论 |
|--------|--------|-------------|
| `top -H` | 哪条线程 CPU 高 | 锁定线程 |
| `hiperf` 火焰图 | 该线程的热点函数 | 锁定代码路径 |
| HiTrace | 这段时间有没有帧在画 | 有帧 → 前台重绘；无帧 → 后台偷跑 |
| HiLog | 有没有丢帧/纹理事件 | 伴随 `OTHER_JANK` → 已影响流畅度 |

---

## 3. 如何解读 CPU 高负载和功耗异常

### 3.1 从火焰图看什么

火焰图的核心是"**宽度 = 采样时间占比**"，重点关注：

| 关注点 | 说明 | 怎么看 |
|--------|------|--------|
| 哪个函数在火焰图顶部持续变宽 | 顶部 = 实际在执行的函数 | 最宽的色块就是热点 |
| 哪些栈路径在反复出现 | 反复出现 = 同一类操作被高频执行 | 看是否有重复的调用栈模式 |
| 是否是同一类操作被反复执行 | 比如 build/layout 被反复触发 | 顺栈往下找根因 |

> **新手避坑**：火焰图顶部变宽的函数往往是"结果"而不是"原因"。比如顶部是 `decodeImage`，要顺栈往下找是谁在反复调用它——可能是 `build` 里每帧都 `Image.network` 重新解码。**修根因，别修表象**。

### 3.2 功耗异常的典型信号

Flutter 应用功耗异常的典型信号：

| 信号 | 怎么发现 | 通俗解释 |
|------|---------|---------|
| 页面在静默状态下依然频繁重绘 | 火焰图里有持续的 build/paint；trace 里帧没停 | 画面明明没变，引擎还在不停画 |
| 存在后台任务没有暂停 | 退后台后 `top -H` 仍见高频线程 | 应用都退到后台了，还在干活 |
| 有持续轮询或高频定时器 | 火焰图里反复出现 timer/poll 栈 | 隔几十毫秒就醒一次，CPU 没法深度睡眠 |

---

## 4. Flutter 侧常见热点

### 4.1 Dart 侧高负载（UI 线程）

| 热点 | 通俗解释 | 怎么发现 |
|------|---------|---------|
| `build` 方法里做重计算/对象创建 | 每帧都在干重活 | 火焰图顶部持续变宽指向 build |
| 列表项构建过多、频繁重建 | 一滚动就重建几百个 Widget | Track Widget Builds（见 [dfx-jank-latency.md](dfx-jank-latency.md) §3） |
| UI 线程里做 JSON 解析/图片处理/复杂布局测量 | 同步重活阻塞主线程 | 火焰图出现 `jsonDecode` / `decodeImage` 等 |

```dart
// ❌ build 里做重计算，每帧都跑一遍
Widget build(BuildContext context) {
  final result = heavyCalc(data);   // 每次 build 都算
  return Text('$result');
}

// ✅ 重活移出 build，结果缓存起来
class _MyState extends State<MyWidget> {
  late final int _result;

  @override
  void initState() {
    super.initState();
    _result = heavyCalc(data);      // 只算一次
  }

  @override
  Widget build(BuildContext context) => Text('$_result');
}
```

### 4.2 渲染与绘制热点（Raster 线程）

| 热点 | 通俗解释 | 怎么发现 |
|------|---------|---------|
| `CustomPainter` / `Canvas` 过于复杂 | 每帧画的东西太多太复杂 | Raster 线程 CPU 持续高 |
| 过度重绘、过度遮盖、过多图层 | 同一像素被画了好几遍 | Repaint Rainbow 满屏闪（见 [dfx-jank-latency.md](dfx-jank-latency.md) §3.4） |
| 动画频繁触发重绘 | 动画一直在跑，画面一直在重画 | 火焰图里持续出现 paint 栈 |

> **新手提示**：如果应用根本不该有动画（比如静止页面），Raster 线程却持续高占用，几乎可以断定是"无效重绘"——某个 Widget 在不停 rebuild/repaint。详见 §5.1 的修复方法。

### 4.3 图片、纹理与资源管理

| 热点 | 通俗解释 | 关联文档 |
|------|---------|---------|
| 大图未经缩放/缓存直接解码 | 4K 图塞进 200px 卡片，解码炸 | [dfx-performance.md](dfx-performance.md) §4.2 |
| 同一图片重复解码或频繁加载 | 没走缓存，每帧都重新解码 | [dfx-memory.md](dfx-memory.md) |
| 页面切换时纹理未及时释放 | 离开页面后视频/相机纹理还在产帧 | [dfx-texture.md](dfx-texture.md) |

---

## 5. 常见优化建议

### 5.1 降低无效渲染（治前台高负载）

无效渲染 = 画面没变却在不停重画，是前台高负载最常见的原因。

```dart
// ❌ 静态子树每帧跟着父级重建
Widget build(_) => Column(children: [Header(), ...]);

// ✅ const 构造，Flutter 直接复用实例
Widget build(_) => Column(children: [const Header(), ...]);
```

| 手段 | 作用 | 代码示例 |
|------|------|---------|
| `const` 构造函数 | 静态子树不重建 | `const Header()` |
| `ValueKey` | 精确控制哪些 Widget 需要更新 | `ItemCell(e, key: ValueKey(e.id))` |
| `RepaintBoundary` | 隔离高频重绘区域，防止拖全页 | `RepaintBoundary(child: AnimatedThing())` |
| 减少滚动中的复杂绘制/重新布局 | 列表给 `itemExtent` / `prototypeItem` | 见 [dfx-jank-latency.md](dfx-jank-latency.md) §4.3 |
| 高频动画用更轻量的实现 | 别用 `Opacity` 动画，用 `FadeTransition` | 见 [dfx-jank-latency.md](dfx-jank-latency.md) §4.2 |

> **新手避坑**：`RepaintBoundary` 本身占内存，**别满屏乱包**——只包"局部高频重绘"的区域（进度条、动画、刷新指示器）。

### 5.2 降低后台和空闲状态功耗（治后台功耗）

后台功耗的核心是：**应用不可见时，该停的都要停**。

| 手段 | 通俗解释 | 代码思路 |
|------|---------|---------|
| 页面不可见时暂停动画和资源刷新 | 没人看就别画 | 监听 `WidgetsBindingObserver.didChangeAppLifecycleState`，`paused` 时停动画 |
| 后台切换时释放不必要的纹理和图形资源 | 视频离开页面要停 | 见 [dfx-texture.md](dfx-texture.md) §6 |
| 避免定时器/轮询在后台持续工作 | 后台别 `Timer.periodic` 跑 | `paused` 时 `timer.cancel()`，`resumed` 时再建 |
| 对 WebView / PlatformView 做可见性控制 | 嵌入的网页也要跟着停 | 监听可见区域回调 |

```dart
// ✅ 监听前后台切换，及时暂停/恢复
class _MyPageState extends State<MyPage> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();   // 退后台就停
    } else if (state == AppLifecycleState.resumed) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _poll() { /* ... */ }

  @override
  Widget build(BuildContext context) => /* ... */;
}
```

### 5.3 优化图片和资源加载

| 手段 | 作用 | 代码示例 |
|------|------|---------|
| 使用适当尺寸的图片 | 别让引擎解码超大图 | `Image.network(url, cacheWidth: 200, cacheHeight: 200)` |
| 对大图做缓存和预加载 | 避免重复解码 | 用 `precacheImage` |
| 避免在 UI 线程中执行重解码 | 解码移到 isolate | `compute(_decode, data)` |
| 释放不再使用的图片对象和纹理 | 防止内存和 CPU 双泄漏 | 离开页面 `dispose` / 清理 `ImageCache` |

详见 [dfx-performance.md](dfx-performance.md) §4.2 和 [dfx-memory.md](dfx-memory.md)。

### 5.4 降低跨语言调用开销

| 手段 | 作用 |
|------|------|
| 合并频繁的插件调用 | 10 次 MethodChannel 调用合成 1 次批量调用 |
| 将重计算或 IO 操作移到后台线程/Isolate | 主线程只负责渲染，重活用 `compute` 卸载 |

```dart
// ❌ 列表里每个 item 都单独调一次原生
for (final e in items) {
  await platform.invokeMethod('fetch', e.id);
}

// ✅ 一次性批量请求
final all = await platform.invokeMethod('fetchBatch', items.map((e) => e.id).toList());
```

---

## 6. 排查清单

### 第一步：确认负载异常

- [ ] `hdc shell ps -A | grep flutter` 找到目标进程
- [ ] `hdc shell top -H -p {进程id}` 看哪条线程 CPU 高
- [ ] 确认是前台触发、后台触发，还是前后台切换触发
- [ ] 复现步骤是否稳定

### 第二步：采样定位热点

- [ ] `hiperf record -e hw-instructions -p {进程id} -d 30` 抓指令数采样
- [ ] 生成火焰图（`perf script` → `stackcollapse-perf.pl` → `flamegraph.pl`）
- [ ] 火焰图顶部是否一致收敛到某个函数/栈路径
- [ ] 是否存在明显的 CPU 热路径

### 第三步：交叉比对

- [ ] 抓 HiTrace 看这段时间有没有帧在画（前台重绘 / 后台偷跑）
- [ ] 抓 HiLog 看是否伴随 `OTHER_JANK` / 纹理事件
- [ ] 静止页面 CPU 是否仍不回落（验证是否有无效重绘）

### 第四步：对症优化

- [ ] 前台高负载：`const` / `RepaintBoundary` / 列表懒加载 / 图片按尺寸解码
- [ ] 后台功耗：前后台切换监听、暂停动画/定时器/轮询、释放纹理
- [ ] 跨语言调用：合并插件调用、`compute` 卸载重活
- [ ] 复测验证：火焰图热点消失、`top -H` 占用回落、功耗数据达标

---

## 7. 相关文档

| 文档 | 关联内容 |
|------|---------|
| [dfx-performance.md](dfx-performance.md) | 丢帧检测机制——负载过高会演变为丢帧 |
| [dfx-jank-latency.md](dfx-jank-latency.md) | DevTools / FrameTiming / trace 链分析方法（定位热点函数的利器） |
| [dfx-memory.md](dfx-memory.md) | GC 频繁导致的卡顿、GPU 上下文丢失 |
| [dfx-texture.md](dfx-texture.md) | 视频/相机纹理未释放导致的后台功耗 |
| [dfx-logging.md](dfx-logging.md) | HiLog / HiTrace 抓取方法 |
| [README.md](README.md) | 回到导航选择其他问题类型 |

---

## 8. 参考与延伸

- Flutter 官方性能总览与最佳实践（docs.flutter.dev/perf、docs.flutter.dev/perf/best-practices）
- DevTools Performance 视图使用指南（docs.flutter.dev/tools/devtools/performance）
- hiperf / FlameGraph 工具链使用（OpenHarmony 官方文档）
- SmartPerf 性能测试工具使用指南（华为开发者官网 / OpenHarmony 官方文档）
- DevEco Profiler 性能分析指南（developer.huawei.com）
- 华为应用体验质量标准：功耗相关术语定义（developer.huawei.com）
