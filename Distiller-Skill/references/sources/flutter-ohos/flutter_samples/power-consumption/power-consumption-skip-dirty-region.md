# 0 脏区跳过渲染

2025 年 4 月，OHOS 版 Flutter Impeller 引擎 Vulkan 后端支持了局部脏区渲染能力。该能力的核心价值，是在页面内容未发生变化时，避免重复进行渲染和提交，从而减少 GPU 工作量、降低显示刷新的负载，并在保持视觉正确性的前提下显著降低无意义的计算和功耗。

从实现思路上看，方案会先计算当前帧的脏区。如果脏区为 0，说明当前帧没有需要更新的内容，那么可以直接跳过后续绘制和提交流程，避免带来额外的 CPU/GPU 负载。对应地，若脏区不为 0，则仍按正常路径执行渲染，由此兼顾功能正确性和高效渲染。

---

## 功耗测试工具

为了验证 0 脏区跳过渲染的降负载效果，建议结合以下工具和方法：

### 1. Trace / 性能分析工具

关键关注：

- 是否在静态页面或无有效变化页面中减少了 GPU 和渲染线程的重复工作；
- 是否减少了无意义 draw call、提交和 present 周期；
- 是否能观察到渲染链路中被跳过的关键步骤。

在支持的环境中，通过 Trace 观察渲染路径，可直观看到"0 脏区时直接跳过后续提交"的效果。

### 2. Vulkan / Impeller 关键路径检查

建议重点检查以下关键路径：

- `Rasterizer::Draw`
- `Rasterizer::DrawToSurfaces`
- `Rasterizer::DrawToSurfaceUnsafe`
- `FrameDamage::ComputeClipRect`
- `SurfaceFrame::Submit`
- `KHRSwapchainImplVK::Present`

如果脏区为 0，则后续的渲染与提交可以直接被丢弃，避免在无更新场景下继续执行 Swapchain 流程。

### 3. 功耗与渲染观测建议

建议在以下场景中比较收益：

- 一张静止页面长时间停留时，是否仍继续进行无效渲染；
- 页面内容无变化但系统仍会触发频繁 `Present` 时，是否能减少提交；
- 多个静态图层叠加时，脏区计算是否能快速识别为 0；
- 预渲染或后台场景下，功能是否仍保持稳定并降低能耗。

---

## 使用场景

0 脏区跳过渲染更适合以下场景：

| 场景 | 适配价值 | 典型表现 |
| --- | --- | --- |
| 静态页面停留 | 避免无意义整个页面重绘 | 页面无变化时直接跳过后续渲染提交 |
| 层级复杂但内容稳定的页面 | 仅在变化区域更新 | 仅更新有效脏区，减少 GPU 负担 |
| 预渲染场景 | 避免不必要的后台绘制 | 逻辑上稳定但不会依赖全量渲染 |

### 适配依赖

#### 1 Flutter OHOS 版本要求

该方案依赖于 Impeller Vulkan 后端对局部脏区渲染能力的支持。若使用早期版本，可能缺少对应优化或存在异常修复缺失，因此开发者应优先确认当前 Flutter 环境已包含此能力。Flutter 升级请参照[升级文档](../version/flutter-oh-upgrade-guide.md)。

#### 2 已支持的关键能力

在当前版本中，该方案的实现主要覆盖：

- 为 swapchain 的每个 image 维护历史脏区信息；
- 在每帧绘制时更新损伤区域；
- 在渲染阶段通过设置渲染区域限制绘制范围；
- 在 present 阶段，通过 `VK_KHR_incremental_present` 告诉系统脏区位置；
- 在脏区为 0 时跳过后续绘制和提交路径。

### 详情

#### 1 方案背景

2025 年 4 月，OHOS 版 Flutter Impeller 引擎 Vulkan 后端支持了局部脏区渲染能力。

- [Impeller脏区渲染能力支持 #753](https://gitcode.com/CPF-Flutter/flutter_engine/pull/753)
- [支持外接纹理局部刷新 #872](https://gitcode.com/CPF-Flutter/flutter_engine/pull/872)
- [预渲染情况下脏区渲染异常修复 #1009](https://gitcode.com/CPF-Flutter/flutter_engine/pull/1009)

当时具体实现方式：

1. 为 swapchain 的每个 image 维护自己的历史脏区信息，并在每帧绘制时更新；
2. 添加渲染区域的设置能力，渲染区域被设置为 buffer 的脏区；
3. 在实际渲染时，将区域限定到第 2 步的渲染区域上；
4. 修改部分流程，以适应 Vulkan 后端不需要主动 blit 的特点（Vulkan 后端可以将 swapchain image 直接作为 MSAA 的 resolve texture 目标，不需要额外进行 Blit，因此某些 transform 的流程不需要）；
5. present 时，使用 `VK_KHR_incremental_present`，在 `PresentInfo` 中填入脏区信息，告知系统脏区位置。

代码调用链：

```text
Rasterizer::Draw
  └─ Rasterizer::DrawToSurfaces
       └─ Rasterizer::DrawToSurfaceUnsafe
            ├─ GPUSurfaceVulkanImpeller::AcquireFrame // GPUSurfaceVulkanImpeller 维护了历史脏区表 damage_
            │    ├─ KHRSwapchainImplVK::AcquireNextDrawable 
            │    │    └─ vk::Device::acquireNextImageKHR // 1. swapchain 获取 image_index（6 选 1），确定 image，此处会请求 NativeWindowBuffer
            │    │
            │    └─ SurfaceFrame::FramebufferInfo // 2. 拿到历史脏区 damage_[image_index]，构造 FramebufferInfo
            │ 
            ├─ CompositorContext::ScopedFrame::Raster
            │    ├─ FrameDamage::ComputeClipRect // 3. 计算脏区 {历史脏区, 当前帧 layer_tree, 上一个帧 layer_tree}
            │    ├─ LayerTree::Preroll // 遍历 layer 检查是否就绪
            │    └─ LayerTree::Paint // 生成绘制操作记录
            │
            └─ SurfaceFrame::Submit
                 ├─ SurfaceFrame::EncodeCallback 
                 │    ├─ damage_update // 4. 更新历史脏区表 damage_
                 │    ├─ RenderTarget::SetRenderArea // 5. 通知 GPU 侧脏区渲染优化
                 │    └─ impeller::RenderToOnscreen // 光栅化，写入 Vulkan cmd buffer
                 │
                 └─ KHRSwapchainImplVK::Present
                      ├─ vk::GraphicsQueueVK::Submit // 提交 Vulkan cmd buffer
                      ├─ vk::PresentInfoKHR::setPNext // 6. 通知 Vulkan 侧脏区渲染优化
                      └─ vk::GraphicsQueueVK::Present // 上屏，最终会写入 NativeWindowBuffer
```

<!-- TODO: 图片需从 media/performance/ 迁移到 media/power-consumption/ 目录 -->
![脏区渲染流程图](../media/performance/performance-25.png)

<p align="center"><strong>图1</strong> 脏区渲染流程</p>

trace 现象：

![渲染 trace 0](../media/performance/performance-26.png)

<p align="center"><strong>图2</strong> 基线实现下脏区为 0 仍继续渲染的 trace</p>

这说明在基线实现下，即使页面稳定、脏区保持为 0，渲染链路仍会继续走 swapchain acquire、damage update、submit 和 present 等过程。对功耗来说，这意味着即使视觉输出未变化，系统仍在执行冗余工作。

#### 2 优化思路

优化思路为：

> 计算脏区，如果脏区为 0，则跳过后续步骤 `SurfaceFrame::Submit`。

这要求在每帧绘制前，系统能够准确判断当前帧是否存在有效更新区域。若在无变化状态下就直接跳过完整 raster 和提交动作，就可以大幅减少无意义的工作。

难点在于：

- 脏区计算依赖历史脏区信息，而 swapchain 采用循环使用策略，`image_index` 取决于 `acquireNextImageKHR` 的随机结果；
- Vulkan swapchain 轮转要求图像在 acquire 后必须被正确 present，否则后续流程可能阻塞、等待 fence。

因此，方案需要在保持 swapchain 完整性不被破坏的前提下，识别"历史脏区全部为 0"的状态，并据此跳过后续无效渲染步骤。

解决思路：

> 当历史脏区数组 `damage_` 中所有区域都为 0 时，无论当前帧 swapchain 获取哪个 `ImageKHR`，其历史脏区值都从逻辑上保持为 0。此时计算脏区只依赖 `<当前帧 layer_tree, 上一个帧 layer_tree>`，无需提前调用 `vk::Device::acquireNextImageKHR`。

#### 3 具体方案

> PR：https://gitcode.com/CPF-Flutter/flutter_flutter/pull/888

遍历历史脏区表 `damage_`，当所有脏区区域都为 0 时，计算脏区可以忽略历史脏区：{~~历史脏区~~, 当前帧 layer_tree, 上一个帧 layer_tree}。

代码调用链：

```text
Rasterizer::Draw
  └─ Rasterizer::DrawToSurfaces
       └─ Rasterizer::DrawToSurfaceUnsafe
            ├─ 【+】历史脏区全部为 0 时，FrameDamage::ComputeClipRect；脏区为 0 时，Discard 本次 layer_tree，并跳过后续步骤
            ├─ GPUSurfaceVulkanImpeller::AcquireFrame // GPUSurfaceVulkanImpeller 维护了历史脏区表 damage_
            │    ├─ KHRSwapchainImplVK::AcquireNextDrawable 
            │    │    └─ vk::Device::acquireNextImageKHR // 1. swapchain 获取 image_index（6 选 1），确定 image，此处会请求 NativeWindowBuffer
            │    │
            │    └─ SurfaceFrame::FramebufferInfo // 2. 拿到历史脏区 damage_[image_index]，构造 FramebufferInfo
            │ 
            ├─ CompositorContext::ScopedFrame::Raster
            │    ├─ FrameDamage::ComputeClipRect // 3. 计算脏区 <历史脏区, 当前帧 layer_tree, 上一个帧 layer_tree>
            │    │    └─ 【+】历史脏区全部为 0 时，之前已经计算过，因此无需重复计算
            │    ├─ LayerTree::Preroll // 遍历 layer 检查是否就绪
            │    └─ LayerTree::Paint // 生成绘制操作记录
            │
            └─ SurfaceFrame::Submit
                 ├─ SurfaceFrame::EncodeCallback 
                 │    ├─ damage_update // 4. 更新历史脏区表 damage_
                 │    ├─ RenderTarget::SetRenderArea // 5. 通知 GPU 侧脏区渲染优化
                 │    └─ impeller::RenderToOnscreen // 光栅化，写入 Vulkan cmd buffer
                 │
                 └─ KHRSwapchainImplVK::Present
                      ├─ vk::GraphicsQueueVK::Submit // 提交 Vulkan cmd buffer
                      ├─ vk::PresentInfoKHR::setPNext // 6. 通知 Vulkan 侧脏区渲染优化
                      └─ vk::GraphicsQueueVK::Present // 上屏，最终会写入 NativeWindowBuffer
```

![0脏区跳过渲染流程图](../media/performance/performance-27.png)

<p align="center"><strong>图3</strong> 0 脏区跳过渲染流程</p>

优化后的 trace 现象：

![渲染 trace 0](../media/performance/performance-28.png)

<p align="center"><strong>图4</strong> 优化后脏区为 0 时跳过渲染的 trace</p>

#### 4 关键实现机制

方案的关键思路是：

> 当历史脏区数组 `damage_` 中所有区域都为 0 时，无论当前帧 swapchain 获取哪个 `ImageKHR`，其历史脏区值都从逻辑上保持为 0。此时计算脏区只需依赖当前帧 layer tree 和上一帧 layer tree，而无需提前强制执行 `acquireNextImageKHR`。

这能够避免在无变化场景下提前获取下一帧图像、保持 swapchain 轮转逻辑稳定，同时减少不必要的资源占用。

#### 5 对功耗优化的意义

该方案的核心价值，不是靠业务层去降帧率，而是把"无意义渲染"从底层渲染链路中裁掉。页面内容没有有效变化时，系统可以直接跳过后续的 draw、submit 和 present 工作，避免在视觉正确的前提下继续消耗 CPU/GPU 资源。

这对以下场景尤其有价值：

- 长时间静态展示页面；
- 复杂 UI 但内容稳定的业务场景；
- 低交互状态中的后台和非活跃页面；
- 需要在视觉正确与功耗降低之间做平衡的应用。

#### 6 Trace 现象

优化前：

- 无变化场景下仍会继续访问 swapchain 和 present 流程；
- 渲染线程仍存在无意义的提交动作；
- GPU 与显示链路依旧承受重复工作。

优化后：

- 当脏区为 0 时，后续 draw/submit 行为被跳过；
- 无效的渲染和提交动作明显减少；
- Trace 中可以观察到更短、更清晰的渲染链路。

---

## 适配流程

1. 确认当前 Flutter OHOS 版本已包含 Vulkan/Impeller 的脏区渲染能力。
2. 检查工程是否使用支持的后端和平台能力，确保 swapchain、present 与脏区更新逻辑均可正常执行。
3. 在需要观察的页面中启动 Trace 或性能调试工具。
4. 观察稳定页面在无内容变化时是否仍会触发无意义渲染与提交。
5. 在页面内容稳定、脏区为 0 时，确认系统是否跳过后续渲染和提交步骤。
6. 对比优化前后的 GPU 占用、执行时间和发热表现，确认降负载收益。

---

## 验证流程

1. 进入页面，确保界面处于静止或低变化状态。
2. 观察页面是否在无更新时仍出现重复渲染和 `Present`。
3. 通过 Trace 确认 `FrameDamage::ComputeClipRect` 在节流条件下返回 0。
4. 检查后续渲染和提交步骤是否被直接丢弃。
5. 对比优化前后功耗和渲染时间，确认降负载效果。
6. 验证复杂页面在局部更新场景下，仍能正确渲染且不牺牲功能表现。

---

## 总结

0 脏区跳过渲染方案的本质，是把"无意义渲染"从渲染链路中裁掉。它不是依赖高层业务逻辑去降低帧率，而是提升底层渲染效率，让系统在无内容更新时直接跳过后续工作，从而实现更稳、更省的功耗优化。

该方案对以下领域最有价值：

- 长时间静态展示页面；
- 复杂 UI 但内容稳定的业务场景；
- 低交互状态中的后台和非活跃页面；
- 需要在视觉正确和功耗降低之间做平衡的应用。

> 本文档最新改动位于：[仓库链接地址](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-skip-dirty-region.md)
