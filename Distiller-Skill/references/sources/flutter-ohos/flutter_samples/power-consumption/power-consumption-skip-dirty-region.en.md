# 0 Dirty Region Render Skipping

In April 2025, the Vulkan backend of the OHOS Flutter Impeller engine gained support for partial dirty region rendering. The core value of this capability is avoiding repeated rendering and submission when page content has not changed, thereby reducing GPU workload, lowering the load of display refresh, and significantly cutting meaningless computation and power consumption while preserving visual correctness.

In terms of implementation approach, the solution first computes the dirty region of the current frame. If the dirty region is 0, the current frame has no content to update, so subsequent drawing and submission can be skipped entirely, avoiding extra CPU/GPU load. Correspondingly, if the dirty region is not 0, rendering still proceeds along the normal path, thus balancing functional correctness and efficient rendering.

---

## Power Consumption Testing Tools

To verify the load reduction effect of 0 dirty region render skipping, it is recommended to combine the following tools and methods:

### 1. Trace / Profiling Tools

Key points to watch:

- Whether repeated work on the GPU and rendering threads is reduced on static pages or pages without effective changes;
- Whether meaningless draw calls, submissions, and present cycles are reduced;
- Whether the key steps skipped in the rendering pipeline can be observed.

In supported environments, observing the rendering path through Trace directly shows the effect of "skipping subsequent submission entirely when the dirty region is 0".

### 2. Vulkan / Impeller Key Path Check

It is recommended to focus on the following key paths:

- `Rasterizer::Draw`
- `Rasterizer::DrawToSurfaces`
- `Rasterizer::DrawToSurfaceUnsafe`
- `FrameDamage::ComputeClipRect`
- `SurfaceFrame::Submit`
- `KHRSwapchainImplVK::Present`

If the dirty region is 0, subsequent rendering and submission can be directly discarded, avoiding continued execution of the Swapchain flow in no-update scenarios.

### 3. Power Consumption and Rendering Observation Suggestions

Compare the gains in the following scenarios:

- Whether a long-idle stationary page still performs ineffective rendering;
- Whether submissions can be reduced when page content is unchanged but the system still triggers frequent `Present` calls;
- Whether the dirty region computation can quickly identify 0 when multiple static layers are stacked;
- Whether the feature remains stable and reduces energy consumption in pre-rendering or background scenarios.

---

## Usage Scenarios

0 dirty region render skipping is better suited to the following scenarios:

| Scenario | Adaptation Value | Typical Behavior |
| --- | --- | --- |
| Static page idling | Avoids meaningless full-page repaints | Skips subsequent rendering and submission entirely when the page is unchanged |
| Pages with complex layer hierarchies but stable content | Updates only the changed areas | Updates only the effective dirty region, reducing GPU burden |
| Pre-rendering scenarios | Avoids unnecessary background drawing | Logically stable without relying on full rendering |

### Adaptation Dependencies

#### 1 Flutter OHOS Version Requirements

This solution depends on the Impeller Vulkan backend's support for partial dirty region rendering. Earlier versions may lack the corresponding optimization or miss exception fixes, so developers should first confirm that the current Flutter environment already includes this capability. For Flutter upgrades, refer to the [upgrade guide](../version/flutter-oh-upgrade-guide.en.md).

#### 2 Key Capabilities Already Supported

In the current version, this solution's implementation mainly covers:

- Maintaining historical dirty region information for each swapchain image;
- Updating the damage area on each drawn frame;
- Limiting the drawing scope by setting the render area during the rendering stage;
- Telling the system the dirty region location via `VK_KHR_incremental_present` during the present stage;
- Skipping subsequent drawing and submission paths when the dirty region is 0.

### Details

#### 1 Solution Background

In April 2025, the Vulkan backend of the OHOS Flutter Impeller engine gained support for partial dirty region rendering.

- [Impeller dirty region rendering support #753](https://gitcode.com/CPF-Flutter/flutter_engine/pull/753)
- [Support partial refresh of external textures #872](https://gitcode.com/CPF-Flutter/flutter_engine/pull/872)
- [Fix for dirty region rendering exceptions in pre-rendering scenarios #1009](https://gitcode.com/CPF-Flutter/flutter_engine/pull/1009)

The specific implementation at that time:

1. Maintain per-image historical dirty region information for the swapchain, updated on each drawn frame;
2. Add the ability to set the render area; the render area is set to the buffer's dirty region;
3. During actual rendering, restrict the area to the render area from step 2;
4. Modify some flows to accommodate the fact that the Vulkan backend does not need to blit proactively (the Vulkan backend can use the swapchain image directly as the MSAA resolve texture target, so no additional Blit is needed, and certain transform flows are unnecessary);
5. During present, use `VK_KHR_incremental_present`, fill the dirty region information into `PresentInfo`, and inform the system of the dirty region location.

Code call chain:

```text
Rasterizer::Draw
  └─ Rasterizer::DrawToSurfaces
       └─ Rasterizer::DrawToSurfaceUnsafe
            ├─ GPUSurfaceVulkanImpeller::AcquireFrame // GPUSurfaceVulkanImpeller maintains the historical dirty region table damage_
            │    ├─ KHRSwapchainImplVK::AcquireNextDrawable
            │    │    └─ vk::Device::acquireNextImageKHR // 1. The swapchain acquires an image_index (1 of 6) to determine the image; a NativeWindowBuffer is requested here
            │    │
            │    └─ SurfaceFrame::FramebufferInfo // 2. Fetch the historical dirty region damage_[image_index] and construct the FramebufferInfo
            │
            ├─ CompositorContext::ScopedFrame::Raster
            │    ├─ FrameDamage::ComputeClipRect // 3. Compute the dirty region {historical dirty regions, current frame layer_tree, previous frame layer_tree}
            │    ├─ LayerTree::Preroll // Traverse the layers to check readiness
            │    └─ LayerTree::Paint // Generate the drawing operation records
            │
            └─ SurfaceFrame::Submit
                 ├─ SurfaceFrame::EncodeCallback
                 │    ├─ damage_update // 4. Update the historical dirty region table damage_
                 │    ├─ RenderTarget::SetRenderArea // 5. Notify the GPU side of the dirty region rendering optimization
                 │    └─ impeller::RenderToOnscreen // Rasterize and write into the Vulkan cmd buffer
                 │
                 └─ KHRSwapchainImplVK::Present
                      ├─ vk::GraphicsQueueVK::Submit // Submit the Vulkan cmd buffer
                      ├─ vk::PresentInfoKHR::setPNext // 6. Notify the Vulkan side of the dirty region rendering optimization
                      └─ vk::GraphicsQueueVK::Present // Present to screen; ultimately writes into the NativeWindowBuffer
```

<!-- TODO: images need to be migrated from media/performance/ to media/power-consumption/ -->
![Dirty region rendering flow](../media/performance/performance-25.png)

<p align="center"><strong>Figure 1</strong> Dirty region rendering flow</p>

Trace behavior:

![Rendering trace 0](../media/performance/performance-26.png)

<p align="center"><strong>Figure 2</strong> Trace of continued rendering even when the dirty region is 0 under the baseline implementation</p>

This shows that under the baseline implementation, even when the page is stable and the dirty region stays 0, the rendering pipeline still goes through swapchain acquire, damage update, submit, and present. In terms of power consumption, this means the system keeps performing redundant work even though the visual output is unchanged.

#### 2 Optimization Approach

The optimization approach is:

> Compute the dirty region; if the dirty region is 0, skip the subsequent step `SurfaceFrame::Submit`.

This requires the system to accurately determine, before each frame is drawn, whether the current frame contains an effective update area. If the full raster and submission actions are skipped directly when nothing has changed, meaningless work can be greatly reduced.

The difficulties are:

- Dirty region computation depends on historical dirty region information, while the swapchain uses a round-robin strategy, and `image_index` depends on the random result of `acquireNextImageKHR`;
- Vulkan swapchain rotation requires images to be properly presented after being acquired, otherwise subsequent flows may block waiting on fences.

Therefore, the solution needs to identify the "all historical dirty regions are 0" state without breaking swapchain integrity, and skip the subsequent ineffective rendering steps accordingly.

The solution approach:

> When all areas in the historical dirty region array `damage_` are 0, no matter which `ImageKHR` the swapchain acquires for the current frame, its historical dirty region value logically stays 0. At this point, computing the dirty region depends only on `<current frame layer_tree, previous frame layer_tree>`, without calling `vk::Device::acquireNextImageKHR` in advance.

#### 3 Concrete Solution

> PR: https://gitcode.com/CPF-Flutter/flutter_flutter/pull/888

Traverse the historical dirty region table `damage_`; when all dirty region areas are 0, computing the dirty region can ignore the historical dirty regions: {~~historical dirty regions~~, current frame layer_tree, previous frame layer_tree}.

Code call chain:

```text
Rasterizer::Draw
  └─ Rasterizer::DrawToSurfaces
       └─ Rasterizer::DrawToSurfaceUnsafe
            ├─ [+] When all historical dirty regions are 0, FrameDamage::ComputeClipRect; when the dirty region is 0, Discard this layer_tree and skip the subsequent steps
            ├─ GPUSurfaceVulkanImpeller::AcquireFrame // GPUSurfaceVulkanImpeller maintains the historical dirty region table damage_
            │    ├─ KHRSwapchainImplVK::AcquireNextDrawable
            │    │    └─ vk::Device::acquireNextImageKHR // 1. The swapchain acquires an image_index (1 of 6) to determine the image; a NativeWindowBuffer is requested here
            │    │
            │    └─ SurfaceFrame::FramebufferInfo // 2. Fetch the historical dirty region damage_[image_index] and construct the FramebufferInfo
            │
            ├─ CompositorContext::ScopedFrame::Raster
            │    ├─ FrameDamage::ComputeClipRect // 3. Compute the dirty region <historical dirty regions, current frame layer_tree, previous frame layer_tree>
            │    │    └─ [+] When all historical dirty regions are 0, it was already computed earlier, so no recomputation is needed
            │    ├─ LayerTree::Preroll // Traverse the layers to check readiness
            │    └─ LayerTree::Paint // Generate the drawing operation records
            │
            └─ SurfaceFrame::Submit
                 ├─ SurfaceFrame::EncodeCallback
                 │    ├─ damage_update // 4. Update the historical dirty region table damage_
                 │    ├─ RenderTarget::SetRenderArea // 5. Notify the GPU side of the dirty region rendering optimization
                 │    └─ impeller::RenderToOnscreen // Rasterize and write into the Vulkan cmd buffer
                 │
                 └─ KHRSwapchainImplVK::Present
                      ├─ vk::GraphicsQueueVK::Submit // Submit the Vulkan cmd buffer
                      ├─ vk::PresentInfoKHR::setPNext // 6. Notify the Vulkan side of the dirty region rendering optimization
                      └─ vk::GraphicsQueueVK::Present // Present to screen; ultimately writes into the NativeWindowBuffer
```

![0 dirty region render skipping flow](../media/performance/performance-27.png)

<p align="center"><strong>Figure 3</strong> 0 dirty region render skipping flow</p>

Trace behavior after the optimization:

![Rendering trace 0](../media/performance/performance-28.png)

<p align="center"><strong>Figure 4</strong> Trace of rendering being skipped when the dirty region is 0 after the optimization</p>

#### 4 Key Implementation Mechanism

The key idea of the solution is:

> When all areas in the historical dirty region array `damage_` are 0, no matter which `ImageKHR` the swapchain acquires for the current frame, its historical dirty region value logically stays 0. At this point, computing the dirty region only needs to rely on the current frame's layer tree and the previous frame's layer tree, without forcibly executing `acquireNextImageKHR` in advance.

This avoids acquiring the next frame's image early in no-change scenarios, keeps the swapchain rotation logic stable, and reduces unnecessary resource usage.

#### 5 Significance for Power Consumption Optimization

The core value of this solution is not lowering the frame rate at the business layer, but cutting "meaningless rendering" out of the underlying rendering pipeline. When page content has no effective changes, the system can directly skip the subsequent draw, submit, and present work, avoiding continued CPU/GPU consumption while visual correctness is preserved.

This is especially valuable for:

- Pages with long-duration static content display;
- Business scenarios with complex UI but stable content;
- Background and inactive pages in low-interaction states;
- Apps that need to balance visual correctness against lower power consumption.

#### 6 Trace Behavior

Before the optimization:

- Swapchain and present flows are still accessed in no-change scenarios;
- The rendering thread still performs meaningless submissions;
- The GPU and display pipeline still bear repeated work.

After the optimization:

- When the dirty region is 0, subsequent draw/submit actions are skipped;
- Ineffective rendering and submission actions are significantly reduced;
- A shorter, cleaner rendering pipeline can be observed in the Trace.

---

## Adaptation Process

1. Confirm that the current Flutter OHOS version already includes the Vulkan/Impeller dirty region rendering capability.
2. Check whether the project uses supported backends and platform capabilities, ensuring the swapchain, present, and dirty region update logic all execute properly.
3. Start Trace or a performance debugging tool on the pages to observe.
4. Observe whether stable pages still trigger meaningless rendering and submission when content is unchanged.
5. When page content is stable and the dirty region is 0, confirm that the system skips the subsequent rendering and submission steps.
6. Compare GPU usage, execution time, and heat before and after the optimization to confirm the load reduction gains.

---

## Verification Process

1. Enter the page and make sure the UI is stationary or changing very little.
2. Observe whether the page still shows repeated rendering and `Present` when there are no updates.
3. Use Trace to confirm that `FrameDamage::ComputeClipRect` returns 0 under throttled conditions.
4. Check whether the subsequent rendering and submission steps are directly discarded.
5. Compare power consumption and rendering time before and after the optimization to confirm the load reduction effect.
6. Verify that complex pages still render correctly in partial update scenarios without sacrificing functionality.

---

## Summary

The essence of the 0 dirty region render skipping solution is cutting "meaningless rendering" out of the rendering pipeline. Rather than relying on high-level business logic to lower the frame rate, it improves underlying rendering efficiency so the system directly skips subsequent work when there is no content update, achieving more stable and more economical power optimization.

This solution is most valuable in the following areas:

- Pages with long-duration static content display;
- Business scenarios with complex UI but stable content;
- Background and inactive pages in low-interaction states;
- Apps that need to balance visual correctness against lower power consumption.

> For the latest changes to this document, see [repository link](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-skip-dirty-region.md)
