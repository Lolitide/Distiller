# 性能卡顿丢帧问题定位指南

> 返回 [README.md](README.md)

> 本文档侧重从 **DFX 事件层面**（HiAppEvent / HiLog）定位丢帧问题。
> 如需 DevTools Performance 分析、FrameTiming 打点、trace 链时延量测等深度方法，请参考 [dfx-jank-latency.md](dfx-jank-latency.md)。

---

## 1. 什么是丢帧？

### 1.1 通俗解释

Flutter 的目标是每秒画 60 张画（60 帧），也就是每张画要在 **16.6 毫秒**内画完。如果某一张画画得太久，超过 16.6 毫秒，画面就会出现"卡顿"——这就是"丢帧"（JANK）。

> **打个比方**：就像翻页动画书，每秒翻 60 页才能看起来流畅。如果某一页你翻了 50 毫秒才翻完，动画就会"卡"一下。

如果设备支持 120 帧（高刷新率），那每帧要在 **8.3 毫秒**内完成，要求更高。

### 1.2 两种丢帧场景

| 场景 | 触发条件 | 对应事件 | 通俗解释 |
|------|---------|---------|---------|
| **滑动丢帧** | 滑动时某帧 ≥50ms | `OTHER_JANK_SCROLL` | 列表滚动时卡顿 |
| **非滑动丢帧** | 帧渲染超过目标时间 | `OTHER_JANK` + `OTHER_JANK_STAT` | 普通场景卡顿（动画、页面切换等） |

> **新手提示**：滑动丢帧只有在单帧 ≥50ms 时才上报。如果你感觉滑动卡但没搜到事件，可能是每帧都 <50ms 但持续 >16ms，需要抓 Trace 分析。

### 1.3 具体现象

| 你看到的现象 | 严重程度 | 可能的原因 |
|-------------|---------|-----------|
| 列表滚动时有顿挫感 | 中 | 滑动丢帧 |
| 页面切换动画不流畅 | 中 | 非滑动丢帧 |
| 偶尔卡一下然后恢复 | 低 | 偶发丢帧 |
| 持续卡顿不恢复 | 高 | 持续丢帧 |
| 动画播放一卡一卡的 | 中 | 帧渲染慢 |
| 卡顿伴随黑屏/白屏 | 高 | GPU 上下文丢失 |
| 视频/相机画面卡顿 | 中 | 外接纹理消费过慢 |

### 1.4 快速定位流程

```
界面卡顿/不流畅
│
├─ 在日志里搜索 "OTHER_JANK_SCROLL"
│  → 滑动丢帧（滑动时某帧 ≥50ms）
│
├─ 在日志里搜索 "OTHER_JANK" 或 "OTHER_JANK_STAT"
│  → 非滑动丢帧
│
├─ 在日志里搜索 "GpuReclaim"
│  → 确认是否伴随 GPU 回收
│
├─ 在日志里搜索 "skip one frame"
│  → 确认是否纹理消费过慢
│
└─ 抓取 HiTrace 做详细分析
   → 搜索 "Flutter Lost Frames" 和 "Flutter Hitch Time"
```

---

## 2. 丢帧检测机制（引擎怎么知道丢帧了？）

### 2.1 检测流程

```
每一帧画完后
│
├─ 算一下：这帧画了多久？（frame_duration = 结束时间 - 开始时间）
│
├─ 超过目标时间了吗？（>16.6ms 或 >8.3ms）
│  ├─ 没超过 → 正常帧，不管它
│  └─ 超过了 → 丢帧了！记录下来
│
├─ 现在在滑动吗？
│  ├─ 在滑动 → 如果这帧 ≥50ms 就上报 OTHER_JANK_SCROLL
│  │           如果 <50ms 就忽略（输出 "Ignore scroll jank" 日志）
│  └─ 没滑动 → 缓存起来（最多缓存 10 帧）
│     ├─ 缓存满 10 帧 → 批量上报 OTHER_JANK + OTHER_JANK_STAT
│     └─ 没满 → 继续缓存
│
└─ 同时输出 HiTrace（记录丢帧详情）
```

### 2.2 滑动丢帧的阈值

滑动场景下，只有单帧耗时 **≥50ms** 才会上报。如果 <50ms 会被忽略：

```bash
# 日志里会显示被忽略的丢帧
I Flutter: Ignore scroll jank: frameCost=30000us (<50ms)
```

> 30000 微秒 = 30 毫秒，小于 50ms 所以被忽略了。但 30ms 已经超过 16.6ms 的帧预算，用户可能感觉到卡。

---

## 3. 怎么定位丢帧问题？

### 3.1 通过日志定位

**搜索命令**：
```bash
hdc shell hilog | grep -E "OTHER_JANK|JANK|jank|missed"
```

**关键日志**：

| 日志关键字 | 含义 | 什么时候出现 |
|-----------|------|------------|
| `ReportScrollJANKEvent` | 滑动丢帧上报 | 滑动时某帧 ≥50ms |
| `ReportJANKEvent` | 非滑动丢帧上报 | 非滑动丢帧时 |
| `Ignore scroll jank: frameCost=Xus (<50ms)` | 滑动丢帧被忽略 | 滑动丢帧但 <50ms |
| `Vector stops push_back` | 丢帧缓存满了（10 帧） | 连续丢帧超过 10 帧 |
| `skip one frame(slow consumer)` | 纹理消费过慢跳帧 | 外接纹理场景 |

### 3.2 通过 HiAppEvent 定位

| 事件 | 含义 | 重点看哪个参数 |
|------|------|-------------|
| `OTHER_JANK` | 单次丢帧详情 | `missedFrames`（丢了多少帧） |
| `OTHER_JANK_STAT` | 聚合统计 | `maxFrameTime`（最严重的一帧画了多久） |
| `OTHER_JANK_SCROLL` | 滑动丢帧 | `totalMissedFrames` / `totalFrames`（丢帧率） |

### 3.3 通过 HiTrace 定位（最详细）

```bash
# 抓取 30 秒 Trace（在这 30 秒内复现卡顿）
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
hdc file recv /data/local/tmp/trace.ftrace ./trace.ftrace

# 用 Chrome 打开 chrome://tracing → Load 文件
```

**在 Trace 中搜索这些关键词**：

| 搜索关键词 | 看什么 |
|-----------|--------|
| `flutter::Frame` | 每一帧画了多久（超过 16ms 的就是丢帧） |
| `Flutter Lost Frames` | 丢帧计数（值=丢了几帧） |
| `Flutter Hitch Time` | 丢帧详情（帧号、耗时、原因） |
| `feedFlutterWatchdog` | UI 线程心跳（检查是否卡死） |

### 3.4 用 DevTools Performance 分析（最直观）

```bash
flutter run --ohos
# 在浏览器打开 DevTools → Performance 标签
# 点录制 → 复现卡顿 → 停止
# 红色的帧就是丢帧，点开可以看到具体哪一步慢
```

---

## 4. 丢帧分析

> **深度分析**：本节列出常见原因与快速修复。如需用 DevTools Performance Overlay / Track Widget Builds / CPU Profiler 等工具逐帧定位"是哪个 Widget、哪个阶段慢"，请参考 [dfx-jank-latency.md](dfx-jank-latency.md) §3「卡顿定位三板斧」。

### 4.1 判断丢帧严重程度

| 指标 | 正常 | 轻微卡顿 | 严重卡顿 | 用户能感觉到 |
|------|------|---------|---------|------------|
| 单帧耗时 | <16ms | 16-50ms | >50ms | >50ms |
| 丢帧数 | 0 | 1-3 帧 | >3 帧 | >5 帧 |
| 丢帧率 | <5% | 5-10% | >10% | >15% |

### 4.2 常见丢帧原因和修复方法

#### 原因 1：Dart 代码执行太慢

**通俗解释**：你的 `build()` 方法里做了太多事，导致一帧画不完。

**怎么确认**：在 HiTrace 中搜索 `flutter::Frame`，看帧的 UI 线程部分耗时长不长。

**常见情况和修复**：

| 情况 | 怎么修 | 代码示例 |
|------|--------|---------|
| Widget 树太复杂 | 拆分 Widget，多用 `const` | `const Text('hello')` 而不是 `Text('hello')` |
| 每帧都在 rebuild | 控制 rebuild 范围 | 用 `shouldRepaint` / `shouldRebuild` |
| 主线程做重计算 | 用 `compute()` 移到 isolate | `final result = await compute(heavyTask, data);` |
| 布局层级太深 | 简化布局，用 `SizedBox` 固定尺寸 | `SizedBox(height: 80, child: ...)` |

**代码示例**：
```dart
// ❌ 错误：每帧都创建新对象，导致 rebuild
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return Container(
      color: Colors.blue,  // 每次 build 都创建新对象
      child: Text('Item $index'),
    );
  },
);

// ✅ 正确：用 const 和 itemExtent 优化
ListView.builder(
  itemExtent: 80.0,  // 固定高度，引擎不用测量每个 item
  itemCount: 1000,
  itemBuilder: (context, index) => const _ItemTile(),  // const Widget
);
```

#### 原因 2：GPU 渲染太慢

**通俗解释**：Dart 代码跑得很快（build 完了），但 GPU 画得太慢。

**怎么确认**：在 HiTrace 中检查 `flutter::Frame` 的 Raster 部分耗时长不长。

| 情况 | 怎么修 |
|------|--------|
| 图片太大 | 用 `cacheWidth`/`cacheHeight` 限制解码尺寸 |
| 图层太多 | 减少 Layer 数量，用 `RepaintBoundary` 隔离 |
| 着色器编译慢 | 预热 Shader（SkSL warmup） |
| 模糊效果太重 | 减少 `BackdropFilter` 使用范围 |
| 过度绘制 | 用 `RepaintBoundary` 隔离复杂区域 |

**代码示例**：
```dart
// ❌ 错误：加载 4000x3000 的大图，解码很慢
Image.network(url)

// ✅ 正确：限制解码尺寸
Image.network(
  url,
  cacheWidth: (screenWidth * devicePixelRatio).toInt(),
  cacheHeight: (screenHeight * devicePixelRatio).toInt(),
)

// ✅ 用 RepaintBoundary 隔离复杂区域（避免重复绘制）
RepaintBoundary(
  child: ComplexWidget(),
)
```

#### 原因 3：资源加载卡住了 build

**通俗解释**：你在 `build()` 方法里直接加载资源，阻塞了界面构建。

```dart
// ❌ 错误：在 build 里同步加载
Widget build(BuildContext context) {
  final data = loadAssetSync();  // 阻塞 build！
  return Text(data);
}

// ✅ 正确：异步加载
@override
void initState() {
  super.initState();
  _loadData();  // 异步加载
}

Future<void> _loadData() async {
  final data = await rootBundle.loadString('assets/data.json');
  setState(() => _data = data);
}
```

#### 原因 4：内存压力导致 GC（垃圾回收）频繁

**通俗解释**：你创建太多临时对象，Dart 的垃圾回收器频繁启动，每次 GC 都会暂停 UI 线程。

**怎么确认**：搜索 `heap memory` 检查内存使用量（详见 [dfx-memory.md](dfx-memory.md) §2）。

**修复方法**：
- 减少 `build()` 中创建的临时对象
- 多用 `const` 构造函数
- 限制 `ImageCache` 大小
- 复用对象而不是反复创建

#### 原因 5：GPU 上下文丢失

**通俗解释**：应用退后台时 GPU 资源被回收了，回前台后重建期间帧渲染中断。

**怎么确认**：搜索 `GpuReclaim` 日志（详见 [dfx-memory.md](dfx-memory.md) §3）。

#### 原因 6：外接纹理消费过慢

**通俗解释**：视频/相机生产画面太快，Flutter 消费不过来，被迫跳帧。

**怎么确认**：搜索 `skip one frame(slow consumer)`（详见 [dfx-texture.md](dfx-texture.md) §4）。

### 4.3 滑动卡顿专项排查

#### 第 1 步：算丢帧率

从 `OTHER_JANK_SCROLL` 事件中取 `totalMissedFrames` 和 `totalFrames`：

```
丢帧率 = totalMissedFrames / totalFrames
```

| 丢帧率 | 严重程度 | 用户感受 |
|--------|---------|---------|
| <5% | 正常 | 无感知 |
| 5-10% | 轻微 | 偶有顿挫 |
| 10-30% | 明显 | 明显卡顿 |
| >30% | 严重 | 严重影响体验 |

#### 第 2 步：看最严重的一帧

`maxFrameTime` 告诉你最严重的一帧画了多久：

| maxFrameTime | 严重程度 |
|-------------|---------|
| <16ms | 正常 |
| 16-50ms | 轻微 |
| 50-100ms | 明显卡顿 |
| >100ms | 严重卡顿 |

#### 第 3 步：抓 Trace 分析

```bash
hdc shell hitrace --trace_clock boottime -t 30 flutter -o /data/local/tmp/trace.ftrace
```

在 Chrome 中打开后：
1. 搜索 `flutter::Frame` 找到耗时长的帧
2. 展开帧事件，看是 UI 线程慢还是 Raster 线程慢
3. 搜索 `Flutter Hitch Time` 看丢帧详情

---

## 5. HiAppEvent 事件参数

### 5.1 OTHER_JANK（单次丢帧）

| 参数 | 说明 | 怎么用 |
|------|------|--------|
| `missedFrames` | 丢了多少帧 | 1-3 轻微，>3 严重 |
| `startTime` / `endTime` | 丢帧的时间范围 | 定位发生时刻 |

### 5.2 OTHER_JANK_STAT（聚合统计）

| 参数 | 说明 | 怎么用 |
|------|------|--------|
| `totalMissedFrames` | 总共丢了多少帧 | 丢帧总量 |
| `maxFrameTime` | 最严重的一帧画了多久（毫秒） | >50ms 就是严重卡顿 |
| `maxMissedFrameRate` | 对应的帧率 | 60/120 是正常，低值说明帧率没达标 |

### 5.3 OTHER_JANK_SCROLL（滑动丢帧）

| 参数 | 说明 | 怎么用 |
|------|------|--------|
| `maxFrameTime` | 最严重的一帧画了多久 | >50ms 用户能感知 |
| `totalMissedFrames` | 滑动期间丢了多少帧 | 配合 totalFrames 算丢帧率 |
| `totalFrames` | 滑动期间总帧数 | 算丢帧率 |
| `recentScrollCount` | 上次上报后的滑动次数 | 1 = 每次滑动都丢帧 |
| `frameId` | 最严重丢帧的帧号 | 在 Trace 中定位具体帧 |

---

## 6. 排查清单

### 第一步：确认丢帧

- [ ] 抓取全量日志：`hdc shell hilog > flutter_log.txt`
- [ ] 搜索 `OTHER_JANK_SCROLL` → 滑动丢帧
- [ ] 搜索 `OTHER_JANK` / `OTHER_JANK_STAT` → 非滑动丢帧
- [ ] 检查 `maxFrameTime` 确定严重程度
- [ ] 算丢帧率（`totalMissedFrames` / `totalFrames`）

### 第二步：找原因

- [ ] 搜索 `GpuReclaim` → 是否 GPU 回收导致
- [ ] 搜索 `skip one frame` → 是否纹理消费过慢
- [ ] 搜索 `heap memory` → 是否内存压力导致 GC
- [ ] 检查 Dart 代码是否有复杂计算 / 同步 IO 在主线程
- [ ] 检查 Widget 是否过度 rebuild

### 第三步：Trace 分析

- [ ] 抓取 Trace：`hdc shell hitrace --trace_clock boottime -t 30 flutter`
- [ ] 搜索 `flutter::Frame` 分析每帧耗时
- [ ] 区分 UI 线程慢还是 Raster 线程慢
- [ ] 搜索 `Flutter Lost Frames` 看丢帧分布

### 第四步：DevTools 分析

- [ ] 用 DevTools Performance 录制卡顿场景
- [ ] 查看红色帧（丢帧）
- [ ] 分析 Timeline 中的 build/layout/paint 耗时

---

## 7. HiTrace 分析技巧

### 7.1 打开 Trace 文件

1. 把 `.ftrace` 文件拉取到电脑
2. 打开 Chrome 浏览器，访问 `chrome://tracing`
3. 点击 `Load` 加载文件
4. 快捷键：`w` 放大、`s` 缩小、`a` 左移、`d` 右移

### 7.2 搜索什么关键词？

| 搜索关键词 | 看什么 | 正常表现 |
|-----------|--------|---------|
| `flutter::Frame` | 每一帧的耗时 | <16ms |
| `Flutter Lost Frames` | 丢帧计数 | 值为 0 |
| `Flutter Hitch Time` | 丢帧详情 | 不出现 |
| `feedFlutterWatchdog` | UI 心跳 | 每 3 秒一次 |

### 7.3 分析帧耗时

1. 搜索 `flutter::Frame`
2. 看每个 Frame 事件的持续时间
3. 超过 16ms 的就是丢帧
4. 展开帧事件，看是哪部分慢：

| 哪部分慢 | 诊断 | 怎么优化 |
|---------|------|---------|
| UI 线程（build/layout/paint） | Dart 代码慢 | 优化 Widget build、减少 rebuild |
| Raster 线程 | GPU 渲染慢 | 优化图片、简化图层 |
| 两者都慢 | 综合问题 | 先优化 UI，再优化 Raster |

### 7.4 API 版本影响

| API 版本 | Trace 能力 |
|---------|-----------|
| < 19 | 只有丢帧计数，没有详情 |
| ≥ 19 | 同时有计数和详情（推荐） |
