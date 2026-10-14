# 性能调优

Flutter OpenHarmony 化的工程也可以使用 DevTools 对 Dart 代码进行调试，具体内容请参考 [DevTools](https://docs.flutter.cn/tools/devtools)。

> 英文版文档见 [README.en.md](README.en.md)

## 文档目录

| 文档 | 说明 |
| --- | --- |
| [性能分析定界指南](./perf-delimitation-guide.md) | 如何定位性能问题所属模块 |
| [性能分析第一步-梳理线程顺序](./perf-analysis-threads-sequence.md) | 介绍 Flutter 渲染相关线程及其顺序 |
| [性能分析-帧渲染跟踪](./perf-frame-rendering-tracking.md) | 单帧追踪方法，用于分析卡顿/丢帧 |
| [性能分析-滑动响应时延](./perf-sliding-response-time.md) | 滑动场景的 trace 分析与时延优化 |
| [性能调优-图片加载](./perf-tuning-image-loading.md) | 图片预加载、缓存等优化手段 |
| [性能调优-内存分析与优化实践](./perf-tuning-memory-analysis.md) | HarmonyOS 上 Flutter 应用的内存分析方法 |
| [性能调优-毕昇编译器开PGO](./perf-tuning-bisheng-pgo.md) | 利用毕昇编译器 PGO 提升运行性能 |
| [方案介绍-性能优化-预加载渲染管线](./perf-optimization-preload-render-pipeline.md) | 解决页面转场白屏问题 |

## 环境配置

如果环境变量中设置了代理 http_proxy 和 https_proxy，需要再设置一个环境变量 no_proxy：

```bash
export no_proxy=::1,127.0.0.1,localhost
```

可以通过 `flutter doctor -v` 命令检测 Flutter 开发环境是否配置正确。
