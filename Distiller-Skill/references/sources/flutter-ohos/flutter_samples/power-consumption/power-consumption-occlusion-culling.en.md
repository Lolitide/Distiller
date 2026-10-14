# Simple Occlusion Culling

This optimization is a type of "rendering-layer culling" capability within the Flutter OHOS low-power and rendering load reduction solutions. Its goal is not to lower the display refresh rate, but to identify, during Impeller's drawing stage, drawing commands that are completely occluded by higher-priority solid-color covering objects, and to directly discard these ineffective commands — thereby reducing actual GPU processing, lowering command submission costs, and avoiding repeatedly executing low-value drawing when the visuals are unchanged.

![](../media/power-consumption/occlusion-culling.png)

<p align="center"><strong>Figure 1</strong> Simple occlusion culling schematic</p>

---

## Power Consumption Testing Tools

### 1. Trace / Rendering Pipeline Analysis

Focus on:

- Whether ineffective drawing commands are reduced in solid-color covering scenarios;
- Whether the sustained execution time of render passes is reduced;
- Whether commands before `Canvas::AddRenderEntityToCurrentPass` can be observed being directly discarded.

For low-level optimizations like this one in Impeller, Trace is often the most direct verification tool, because it directly shows whether drawing commands are culled.

### 2. Key Path Check

It is recommended to focus on the following paths:

- `Canvas::DrawRect`
- `Canvas::DrawCircle`
- `Canvas::AddRenderEntityWithFiltersToCurrentPass`
- `Canvas::AddRenderEntityToCurrentPass`
- `InlinePassContext::Deactive`

Among these, the most meaningful entry point is `Canvas::AddRenderEntityToCurrentPass`, because it directly determines whether occlusion culling is performed on the previous render pass.

### 3. Power Consumption and Rendering Observation Suggestions

Compare in the following scenarios:

- Large solid-color backgrounds or solid-color covering areas;
- Fixed UI backgrounds completely covered by subsequent opaque content;
- Culled objects that do not affect the final picture but may bring extra commands;
- Pages containing a large number of meaningless rendering commands.

---

## Usage Scenarios

Simple occlusion culling is better suited to the following typical scenarios:

| Scenario | Adaptation Value | Typical Behavior |
| --- | --- | --- |
| Solid-color background covering | Avoids repeatedly drawing the old background layer | Subsequent solid color covers directly; old commands need not be retained |
| Fixed card/panel areas | Reduces large-area ineffective drawing | Visuals unchanged but commands are culled |
| Large-area static UI | Reduces repeated submission and rendering | GPU footprint and duration decrease |
| Interfaces with clearly separated background and foreground | Keeps only the visible layer | Low-value rendering is directly culled |

Applicable timings include:

- The current draw entity covers the entire target area;
- Previously drawn content is completely covered by a subsequent solid color;
- Old rendering results need not be retained; only the final visible color needs to remain.

In these scenarios, occlusion culling is lighter than "full repaint", and is particularly suitable for improving the rendering efficiency of large-area static pages.

## Prerequisites

### 1 Version Requirements

This solution depends on Impeller's canvas processing logic and the state management capability of render passes. If the current engine version does not include this logic, or old passes are not cleaned up on certain paths, the optimization may not take effect, or exceptions may occur in special rectangular clipping scenarios. For Flutter upgrades, refer to the [upgrade guide](../version/flutter-oh-upgrade-guide.en.md).

### 2 Key Technical Points

The core of this optimization depends on the following capabilities:

- Being able to identify whether an entity is a solid color and covers the current render target;
- Being able to determine whether the previous pass is covered by a subsequent solid color;
- Being able to discard invalid commands during rendering;
- Being able to reset old pass state while preserving visual output.

### 3 Key Modification Points

Key modifications are concentrated in the following places:

- Added an occlusion culling check in `Canvas::AddRenderEntityToCurrentPass`;
- `InlinePassContext::Deactive()` was added to deactivate old passes;
- Under the `GetClipHeight() == 0` condition, simple culling of solid-color entities is allowed;
- The logic is enabled only under `BlendMode::kSource`, `kClear`, and opaque `kSourceOver`.

### Details

#### 1 Optimization Target: Old Drawing Covered by Solid Color

The key idea of this optimization is:

> If an entity is itself a solid-color cover, and it covers most or all of the current render target, then the old drawing commands recorded before that entity are often no longer worth retaining.

Such cases commonly occur in:

- Background color refreshes;
- Solid-color redraws of cards/containers;
- Complex UI that first draws a layer of old content in a frame, then replaces it with a single-color covering layer.

#### 2 Concrete Determination of Occlusion Culling

Key determination logic:

```cpp
std::optional<Color> maybe_color = entity.AsBackgroundColor(
    render_passes_.back().inline_pass_context->GetTexture()->GetSize());

if (maybe_color.has_value()) {
  if (render_passes_.back().IsApplyingClearColor()) {
    // Handle the clear-color scenario
  } else {
    if (GetClipHeight() == 0 &&
        (entity.GetBlendMode() == BlendMode::kSource ||
         entity.GetBlendMode() == BlendMode::kClear ||
         (entity.GetBlendMode() == BlendMode::kSourceOver &&
          maybe_color.value().IsOpaque()))) {
      // Discard the previous passes and replace them with the solid-color entity
    }
  }
}
```

Here, `GetClipHeight() == 0` is an important condition: it means the current clip area is already in a range with no effective height, so it is safe to consider the old area unnecessary to retain. This avoids mistakenly discarding valid drawing when the actual clipping affects the rendered area.

#### 3 How to Reduce Ineffective Rendering

In traditional rendering, if old passes are still retained, the subsequent pipeline may continue to:

- Record previous drawing commands;
- Keep participating in the composition of subsequent passes;
- Perform ineffective blending or covering.

The simplified occlusion culling handles this more directly:

1. Identify the current entity as a visible solid-color cover;
2. Determine that the existing render passes may already be covered;
3. Discard the old passes;
4. Set up the new color attachment;
5. Let the current solid-color entity directly become the final content.

This strategy is essentially "upfront culling"; it reduces meaningless drawing commands and subsequent composition costs.

---

## Adaptation Process

1. Confirm that the current Flutter engine contains Impeller's underlying solid-color culling logic.
2. Check whether the drawing nodes involve large-area solid-color coverage or scenarios where front and back layers completely occlude each other.
3. Locate the execution path of `Canvas::AddRenderEntityToCurrentPass` in the rendering pipeline.
4. Confirm that the combination of `GetClipHeight() == 0` and the blend mode satisfies the optimization conditions in the current scenario.
5. Track whether old passes are being actively deactivated.
6. Compare the number of rendering commands and GPU utilization before and after the optimization.

---

## Verification Process

1. Select a page with a high degree of solid-color background coverage, and check for obviously ineffective rendering.
2. Start Trace or a profiling tool, and confirm that commands are reduced to a smaller execution volume.
3. Check whether old render passes are actually skipped, rather than merely having some subsequent operations reduced.
4. Observe whether the rendering output stays consistent with no visual errors.
5. Compare GPU time, pass count, and submission cost before and after the optimization.
6. On pages with clipping, occlusion, and opacity changes, confirm that the optimization does not affect the actual drawing results.

---

## Summary

"Simple occlusion culling" does not save power by lowering the refresh rate; instead, it culls ineffective drawing at the rendering command level. Its core idea is:

- If a layer's drawn content will later be completely covered by clearer, higher-value solid-color content;
- Then the retained old content no longer needs to be drawn;
- Directly discard the old rendering commands to reduce subsequent composition and submission costs.

> For the latest changes to this document, see [repository link](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-occlusion-culling.md)
