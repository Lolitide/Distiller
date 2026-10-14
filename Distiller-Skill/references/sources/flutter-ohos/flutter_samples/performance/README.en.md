# Performance Optimization

For an OpenHarmony Flutter project, you can use DevTools to debug the Dart code. For details, see <a href="https://docs.flutter.dev/tools/devtools" style="text-decoration:none !important">Flutter and Dart DevTools</a>.

## Document Directory

| Document | Description |
| --- | --- |
| [Performance Analysis and Issue Demarcation](perf-delimitation-guide.en.md) | Locate which module causes perf issues |
| [Performance Analysis: Sorting the Thread Sequence](perf-analysis-threads-sequence.en.md) | Flutter rendering threads and their order |
| [Performance Analysis: Frame Rendering Tracing](perf-frame-rendering-tracking.en.md) | Track individual frames for jank/lost frames |
| [Performance Analysis: Swipe Response Latency](perf-sliding-response-time.en.md) | Trace analysis and latency optimization for swipe scenarios |
| [Image Loading Performance Tuning](perf-tuning-image-loading.en.md) | Image preloading, caching, and optimization |
| [Performance Tuning - Memory Analysis and Optimization Practices](perf-tuning-memory-analysis.en.md) | Memory profiling for Flutter on HarmonyOS |
| [Performance Tuning - BiSheng Compiler PGO](perf-tuning-bisheng-pgo.en.md) | Boost runtime performance via BiSheng compiler PGO |
| [Solution - Performance Optimization: Preload Render Pipeline](perf-optimization-preload-render-pipeline.en.md) | Fix page transition white-screen issues |

## Environment Configurations

If **http_proxy** and **https_proxy** are set in the environment variables, **no_proxy** should also be set.

```bash
export no_proxy=::1,127.0.0.1,localhost
```

You can run the `flutter doctor -v` command to check whether the Flutter development environment is properly configured.  

