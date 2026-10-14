# 简单遮挡剔除

这项优化属于 Flutter OHOS 低功耗和渲染减负方案中的一类"渲染层裁剪"能力。它的目标不是降低显示刷新率，而是在 Impeller 的绘制阶段，识别出那些被更高优先级的纯色覆盖对象完全遮挡的绘制命令，并直接丢弃这些无效命令，从而减少实际 GPU 处理量、降低命令提交成本，以及避免在视觉不变的情况下重复执行低价值绘制。

![](../media/power-consumption/occlusion-culling.png)

<p align="center"><strong>图1</strong> 简单遮挡剔除示意</p>

---

## 功耗测试工具

### 1. Trace / 渲染链路分析

重点观察：

- 是否在纯色覆盖场景中减少了无效绘制命令；
- 是否减少了渲染 pass 的持续执行时间；
- 是否能看到 `Canvas::AddRenderEntityToCurrentPass` 之前的命令被直接丢弃。

对于 Impeller 这类底层优化，Trace 往往是最直接的验证工具，因为它能直接体现绘制命令是否被裁剪。

### 2. 关键路径检查

建议重点检查以下路径：

- `Canvas::DrawRect`
- `Canvas::DrawCircle`
- `Canvas::AddRenderEntityWithFiltersToCurrentPass`
- `Canvas::AddRenderEntityToCurrentPass`
- `InlinePassContext::Deactive`

其中，最有意义的入口就是 `Canvas::AddRenderEntityToCurrentPass`，因为这里直接决定了是否对前一个 render pass 执行遮挡剔除。

### 3. 功耗与渲染观测建议

建议在以下场景中对比：

- 大面积纯色背景或纯色覆盖区域；
- 固定 UI 背景被后续不透明内容完全覆盖；
- 被裁剪的对象不影响最终画面但可能带来多余命令；
- 页面中存在大量无意义渲染命令的场景。

---

## 使用场景

简单遮挡剔除更适合以下典型场景：

| 场景 | 适配价值 | 典型表现 |
| --- | --- | --- |
| 纯色背景覆盖 | 避免重复绘制旧背景层 | 后续纯色直接覆盖，无需保留旧命令 |
| 固定卡片/面板区域 | 降低大面积无效绘制 | 视觉不变但命令被裁剪 |
| 大面积静态 UI | 减少重复提交和渲染 | GPU 尺寸和耗时下降 |
| 背景和前景分层明显的界面 | 只保留可见层 | 低价值渲染被直接剔除 |

适用时机包括：

- 当前绘制实体覆盖了整个目标区域；
- 前一绘制内容被后续纯色完全覆盖；
- 无需保留旧渲染结果，只需留下最终可见颜色。

这类场景下，遮挡剔除会比"全量重绘"更轻量，尤其适合提升大面积静态页面的渲染效率。

## 前置条件

### 1 版本要求

该方案依赖于 Impeller 的 canvas 处理逻辑与 render pass 的状态管理能力。若当前引擎版本未包含该逻辑，或者在某些路径上没有清理旧 pass，可能导致优化无法生效，或者在特殊矩形裁剪场景下出现异常。Flutter 升级请参照[升级文档](../version/flutter-oh-upgrade-guide.md)。

### 2 关键技术点

本次优化核心依赖以下能力：

- 能识别实体是否是纯色且覆盖当前 render target；
- 能判断前一 pass 是否被后续纯色覆盖；
- 能在渲染过程中丢弃无效 command；
- 能在保留视觉输出的同时重置旧 pass 状态。

### 3 关键修改点

关键修改集中在下面几处：

- `Canvas::AddRenderEntityToCurrentPass` 中新增 occlusion culling 判断；
- `InlinePassContext::Deactive()` 新增用于失活旧 pass；
- 在 `GetClipHeight() == 0` 条件下，允许对纯色实体执行简单剔除；
- 仅在 `BlendMode::kSource`、`kClear`、以及 opaque `kSourceOver` 条件下启用该逻辑。

### 详情

#### 1 优化对象：被纯色覆盖的旧绘制

本次优化的关键思想是：

> 若某个实体本身就是一个纯色覆盖，且它覆盖了当前 render target 的大部分或全部区域，那么在该实体之前记录的旧绘制命令，往往已经不再需要保留。

这类情况常见于：

- 背景色刷新；
- 卡片/容器纯色重绘；
- 复杂 UI 在某一帧中先绘制了一层旧内容，再以单色覆盖层代替。

#### 2 Occlusion Culling 的具体判定

关键判定逻辑：

```cpp
std::optional<Color> maybe_color = entity.AsBackgroundColor(
    render_passes_.back().inline_pass_context->GetTexture()->GetSize());

if (maybe_color.has_value()) {
  if (render_passes_.back().IsApplyingClearColor()) {
    // 处理清除色场景
  } else {
    if (GetClipHeight() == 0 &&
        (entity.GetBlendMode() == BlendMode::kSource ||
         entity.GetBlendMode() == BlendMode::kClear ||
         (entity.GetBlendMode() == BlendMode::kSourceOver &&
          maybe_color.value().IsOpaque()))) {
      // 丢弃之前的 pass，并以纯色实体代替
    }
  }
}
```

其中，`GetClipHeight() == 0` 是一个重要条件，表示当前裁剪区域已处于无有效高度区间，可安全认为旧区域不需要保留。这样可避免在实际裁剪影响渲染面积时误判掉有效绘制。

#### 3 如何降低无效渲染

在传统渲染中，如果旧 pass 仍然继续保留，后续 pipeline 可能还会继续执行：

- 记录之前的绘制命令；
- 继续参与后续 pass 的组合；
- 进行无效的混合或覆盖处理。

而简化版遮挡剔除在此处做了更直接的处理：

1. 识别当前实体为可见的纯色覆盖；
2. 判断既有 render pass 可能已经被覆盖；
3. 丢弃旧 pass；
4. 设置新的色附件；
5. 让目前的纯色实体直接成为最终内容。

这种策略本质上是"前置裁剪"，它可以减少无意义的绘制命令和后续组合成本。

---

## 适配流程

1. 确认当前 Flutter 引擎包含 Impeller 的纯色底层裁剪逻辑。
2. 检查绘制节点是否存在大面积纯色覆盖或前后层完全遮挡的场景。
3. 在渲染链路中定位 `Canvas::AddRenderEntityToCurrentPass` 的执行路径。
4. 确认当前场景下 `GetClipHeight() == 0` 与 blend mode 组合满足优化条件。
5. 跟踪是否存在旧 pass 被主动 deactive 的行为。
6. 对比优化前后渲染 command 数量和 GPU 利用率。

---

## 验证流程

1. 选取一张纯色背景覆盖度较高的页面，观察是否存在明显无效渲染。
2. 启动 Trace 或性能分析工具，确认命令被降到更少的执行量。
3. 检查旧 render pass 是否确实被跳过，而不是仅仅减少了某些后续操作。
4. 观察渲染输出是否保持一致，不发生视觉错误。
5. 对比优化前后的 GPU 时间、Pass 数量和提交成本。
6. 在有裁剪、遮挡和透明度变化的页面中，确认优化不会影响真实绘制结果。

---

## 总结

"简单遮挡剔除"并不是通过降低刷新率来节省功耗，而是从渲染命令层面对无效绘制进行裁剪。它的核心思想是：

- 如果某层的绘制内容之后会被更明确、更高价值的纯色内容完全覆盖；
- 那么保留下来的旧内容没有继续绘制的必要；
- 直接丢弃旧渲染命令，减少后续组合和提交成本。

> 本文档最新改动位于：[仓库链接地址](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-occlusion-culling.md)
