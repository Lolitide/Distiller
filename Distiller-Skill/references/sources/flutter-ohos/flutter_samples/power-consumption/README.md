# 降负载和功耗优化

## 文档目录

| 文档 | 说明 |
| --- | --- |
| [LTPO 降负载方案](./power-consumption-ltpo.md) | LTPO 智能刷新：在交互时提升帧率，空闲时回落低功耗档位。 |
| [0 脏区跳过渲染](./power-consumption-skip-dirty-region.md) | 0 脏区跳过渲染：页面无变化时直接跳过后续绘制和提交。 |
| [简单遮挡剔除](./power-consumption-occlusion-culling.md) | Impeller 简单遮挡剔除：丢弃被纯色覆盖的无效绘制命令。 |
| [页面不可见时暂停绘制](./power-consumption-eliminate-redundant-drawing.md) | 页面不可见时暂停绘制：防止 WebView / PlatformView 产生冗余绘制。 |
