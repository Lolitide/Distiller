# 方案介绍-性能优化-预加载渲染管线

## 一、从页面转场白屏说起

从原生页面点击按钮到 Flutter 页面完全显示，往往需要超过 300 ms。
这是最常见的场景：资讯列表点进详情、商品卡片打开购买页、设置菜单进入二级页面。用户点击后看到的"白屏等待"，开发者优化一般会关注Dart代码本身——减少 widget 嵌套、推迟非必要初始化，但存在一部分首帧耗时来自于引擎侧，因为点击瞬间Flutter引擎初始化、图形链路冷启动：加载创建渲染表面、建立显示通道、预热 GPU 流水线，这些重活全堆在页面出现之后。
在鸿蒙化的Flutter中，预加载渲染管线（WarmUp Pipeline）的做法很直接：在点击前完成引擎运行 + GPU 预热 + 离屏渲染准备；点击后优先复用预热结果，失败则平滑补帧。

我们构造了一个原生页面跳转到简单Flutter页面的demo应用，用于重点关注引擎侧的耗时。在Mate 60 Pro下，预加载渲染管线可以把点击按钮到页面完全显示从115.9 ms压到72.1 ms，相较标准路径下降约37.8%；把引擎绑定到鸿蒙XComponent到首帧显示从88.2ms压到67.8ms，下降约23.1%。并且我们还做了针对预渲染阶段的内存优化，通过精简 buffer 申请带来的内存节省40 MB+。

## 二、技术实现：三种模式对比，看 WarmUp Pipeline 到底多做了什么

在 鸿蒙化Flutter应用开发过程中，通常可以选择以下三个模式来打开Flutter页面：
standard：最基础的模式。每次进入页面都从零创建 FlutterEngine，不做缓存，也不做预热。这是 Flutter 默认的启动行为，也是首帧最慢的路径。
cached_engine：社区常见的优化方案。页面出现前先把 FlutterEngine 创建好并运行起来，相当于提前把 Dart VM 和框架初始化做完。
warmup_pipeline：鸿蒙化Flutter的预加载渲染管线。页面出现前不仅准备好 Engine，还通过 FlutterEnginePreload 把 GPU 预热、离屏渲染、窗口切换一起前移，形成完整的"预热-接管"闭环。

![三种模式对比](../media/performance/performance-22.png)


我们用同一个 demo 做了三组对照，每组 10 轮，采样口径统一为：

- `tapToFirstFrame`：原生页点击进入 Flutter 页，到 Flutter 正常首帧完成
- `attachToFirstFrame`：`FlutterView.attachToFlutterEngine(...)` 到 Flutter 正常首帧完成

实验结果如下：

| 模式 | tap 平均值 | tap P90 | attach 平均值 | attach P90 |
|---|---:|---:|---:|---:|
| standard | 115.9 ms | 119 ms | 88.2 ms | 92 ms |
| cached_engine | 93.6 ms | 98 ms | 89.0 ms | 94 ms |
| warmup_pipeline | 72.1 ms | 73 ms | 67.8 ms | 69 ms |

从这组结果可以看到两点。

第一，`cached_engine` 确实能把一部分准备成本前移。和标准路径相比，`tapToFirstFrame` 从 115.9 ms 降到了 93.6 ms，下降约 19.2%。这说明“提前把 engine 准备好”是有收益的。

第二，真正把差距拉开的，是 WarmUp Pipeline。和标准路径相比，`tapToFirstFrame` 下降约 37.8%，`attachToFirstFrame` 下降约 23.1%；即便对比已经做过 engine 缓存的 `cached_engine`，`tapToFirstFrame` 仍然再下降约 23.0%，`attachToFirstFrame` 再下降约 23.8%。这说明 WarmUp Pipeline 优化的不是“引擎准备”这一段，而是连同图形链路一起前移了。

### 关键技术点1: 离屏预热，把 GPU 冷启动从首帧路径里拿出去

预加载入口在 ArkTS 侧。`FlutterEnginePreload.preloadEngine(...)` 会先完成 engine 初始化和 Dart 运行，然后通过 `xComponentPreDraw(...)` 把预加载请求送到 Native。真正的关键动作发生在 `PlatformViewOHOS`：
- 构造时异步调用 `PrepareGpuSurface()`，提前准备 `GPUSurface`
- `Preload(width, height)` 在 raster 线程里进入离屏预热
- `OHOSSurface::PrepareOffscreenWindow(width, height)` 创建离屏 `NativeWindow`

这一步非常重要。WarmUp Pipeline做的不是“提前 new 一个 engine”，而是让 engine 在页面还不可见时，就已经拿到了一个可用的离屏渲染目标。对于 Vulkan/Impeller 路径来说，重的不是“画这一帧”，而是第一次把图形运行时真正拉起来。把这段前移，首帧就不必再承担整套 GPU 冷启动成本。

### 关键技术点2: 预热不等于上屏，但必须为上屏做好准备

预加载做得太重，又会让离屏阶段自己变成新的负担。我们在实现中专门做了一个取舍：预热阶段优先把最贵的初始化动作做完，但又尽量避免为了“提前画一张完整图片”而付出过高资源成本。

离屏预热最容易让人误判的地方，是以为“只要提前渲一帧，正式显示时就一定能直接搬过去”。事实并不是这样。真实窗口和离屏窗口并不天然等价，尺寸、buffer 状态、窗口句柄都可能不同。`OHOSSurface` 会记录离屏窗口尺寸、预加载标记以及最近一次离屏 buffer 状态；而 Vulkan 路径除了创建离屏窗口，还会通过 `PrepareGpuSurface()` 提前构建耗时的 GPU surface/pipeline。这样一来，等真实窗口出现时，系统不是从零开始，而是带着一套“已就绪但未正式上屏”的图形上下文进入下一阶段。

### 关键技术点3: 内存优化，预加载阶段只保留2个渲染buffer

在预加载阶段不再按正式显示态申请 6 个 buffer，而是只申请 2 个 buffer；等页面真正显示时，再销毁这 2 个预加载 buffer，并重新申请 6 个显示 buffer。

之所以能这么做，是因为预加载阶段的目标并不是长时间维持完整显示能力，而是完成引擎启动、图形链路预热和首帧前关键资源准备。换句话说，预加载阶段需要的是“够用的最小 buffer 集合”，而不是和正式上屏完全等价的 buffer 配置。

![buffer申请流程](../media/performance/performance-23.png)

如果在预加载阶段直接占住 6 个 buffer，等真实页面attach时，这批 buffer仍然要销毁，再按显示态重新申请 6 个新 buffer。这样一来，预加载阶段额外多持有的 4 个 buffer，并不会转化成显示收益，反而只是增加了一段离屏常驻内存。相当于把一段“最终还会被销毁”的中间态资源压缩到了最低。这个调整带来了 40 MB 以上的内存节省。

### 关键技术点4: 正式上屏，优先复用，失败补帧，不赌单一路径

当页面真正 attach 到 engine 后，`FlutterView.attachToFlutterEngine(...)` 会把真实页面和预加载好的 engine 重新接起来；随后 `NotifyCreate(native_window)` 把真实窗口交给 Native 渲染层，进入 `SetDisplayWindow(...)`。

当前实现里，真实窗口到来后会分成两条路径：

1. 如果离屏结果和正式窗口条件匹配，就优先复用离屏结果。
2. 如果不匹配，或者复用失败，就立即标记需要补帧，重新调度一帧正式渲染。

这套方案不是“必须复用成功才成立”，而是“能复用就直接受益，不能复用也平滑降级”。这对稳定性很关键。首帧优化最怕的是为了抢几十毫秒而引入一条脆弱路径，一旦窗口条件变化、尺寸不一致、buffer 迁移失败，反而把显示正确性搞丢。鸿蒙化Flutter 这里采用的是更务实的策略：**先争取复用，再保证正确。**

### trace分析

![图 3：预加载渲染管线 Trace 对比](../media/performance/performance-24.png)

上图展示的是预加载场景下点击按钮触发flutter页面打开的关键线程时间线。从这张图里我们可以看出：

第一，主线程上并没有与Engine创建相关的trace点，页面出现前先把 FlutterEngine 创建好并运行起来。

第二，真正进入首帧提交阶段时，raster 线程剩余要做的工作更短了。

## 三、开发者如何使用：三个更有业务价值的场景

如果你的首页或者首个 Flutter 页面打开频率很高，最适合在应用启动后的空闲时机预加载。

```ts
import FlutterEnginePreload from '.../FlutterEnginePreload';

await FlutterEnginePreload.preloadEngine(context, {
  initialRoute: '/home',
});

const engine = FlutterEngineCache.getInstance().get('feed_tab');
if (engine != null) {
  flutterView.attachToFlutterEngine(engine);
}
```

页面真正展示时，再把 `FlutterView` attach 到对应 engine。这样做的意义非常直接：首页第一次打开时，不再从零开始拉起整条图形链路。

这类做法的收益通常非常直观。用户看到的是“点开就有内容”，而不是“点开后等系统把一整条渲染链路补起来”。

### 什么时候不建议开

预加载不是免费的，尤其不适合以下场景：

- 低频页面，用户可能一整次会话都不会进入
- 内存敏感设备，预加载带来的常驻资源压力高于收益
- 生命周期很短的页面，预加载还没回本，页面就已经销毁