---
name: flutter-ohos-insight
description: Analyze DevEco Studio Profiler .insight trace packages for Flutter apps running on OpenHarmony/HarmonyOS/OHOS. Use when Codex needs to diagnose Flutter OHOS performance issues such as jank, slow frames, first-frame delay, UI thread stalls, BUILD/LAYOUT/PAINT timeline phases from --trace-systrace, raster/GPU bottlenecks, fence waits, RenderService delay, htrace scheduling or binder blocking, CPU pressure, GPU usage, energy drain, animation/page transition latency, or any trace captured as a .insight file by DevEco Studio Profiler.

metadata:
  last_modified: 2026-06-23
---

# Flutter OHOS Insight

## Overview

Use the bundled `scripts/insight_analyzer.py` as the primary analyzer for DevEco Studio Profiler `.insight` packages. Treat the audience as Flutter app developers: translate raw trace facts into UI-thread, raster-thread, GPU, platform, RenderService, fence, scheduling, and app-code implications.

## Capture Guidance

For UI-thread diagnosis, first check whether the trace was captured with Flutter systrace timeline enabled. Ask developers to add `--trace-systrace` to the engine startup arguments in `FlutterLoader.ets` before capturing with DevEco Studio Profiler.

This makes the trace much more useful for Flutter jank analysis because UI-thread phases such as `BUILD`, `LAYOUT`, and `PAINT` can appear in the htrace/timeline data. If those phases are absent and the problem is UI-thread jank, report that the current trace has limited Flutter attribution and recommend recapturing with `--trace-systrace`.

## Required Analyzer

Run commands with the trace path before the subcommand:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" overview
```

The sample trace shape is:

```text
/Volumes/data/experiment/trace_helper/insight/Frame_ALN-AL80_com.tencent.wechat_Main Process_20260612T091821.insight
```

Always quote trace paths because DevEco exports often contain spaces.

`<skill-dir>` means the root directory of this skill. If the skill is installed at `~/.codex/skills/flutter-ohos-insight`, the analyzer path is:

```bash
python3 "$HOME/.codex/skills/flutter-ohos-insight/scripts/insight_analyzer.py" "<trace.insight>" overview
```

## Workflow

1. Start with metadata and source coverage:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" overview
```

Confirm app package, process, device, OS/API, capture duration, start timestamp, and available data sources. If htrace, CPU, GPU, or animation sources are missing, state that limitation before diagnosing.

Also inspect thread classification early:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" threads
```

Verify that the Flutter UI thread is classified as `flutter_ui` and the raster thread as `flutter_raster`. Common OHOS Flutter thread names include `1.ui`, `root.1.ui`, `root.N.ui`, and `1.raster`. If `flutter --top-duration` reports suspicious `ui=0.0ms` while the trace has UI-thread `BeginFrame` slices, do not trust that aggregate until thread classification is checked with `threads` and htrace slices.

2. Identify slow Flutter frames:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" flutter --top-duration 20
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" flutter --top-duration 20 --fences
```

Use frame totals and phase times to decide the first branch:

- High `ui` time: inspect Dart/UI thread work, `BUILD`/`LAYOUT`/`PAINT` timeline phases, platform callbacks, channel calls, and scheduler stalls. If those phases are missing, recommend recapturing after adding `--trace-systrace` in `FlutterLoader.ets`.
- High `raster` time: inspect raster thread, Skia/rendering, image upload, shader compilation, and scene complexity.
- High `gpu` or fence time: inspect GPU/RenderService/fence waits and buffer availability.
- High `submit` time: inspect handoff from raster to GPU/RenderService.
- Few framed slices but many unframed slices: use time windows around suspicious frames and htrace filters.

3. Narrow to the suspicious window. Use wall-clock millisecond timestamps from the frame output:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" timeline --start <ms> --end <ms>
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace summary --start <ms> --end <ms>
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace slices --start <ms> --end <ms> --flutter --top-duration 30
```

Keep the window tight enough to cover the slow frame and immediate producer/consumer chain. A good first pass is frame start minus 50 ms to frame end plus 100 ms.

For large htrace captures, avoid broad whole-trace `htrace slices` scans unless needed. Start with a narrow window from a slow frame, then expand only if producer/consumer evidence is missing.

4. Follow the bottleneck branch:

For CPU pressure:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" threads
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" cpu --top 20
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace sched --start <ms> --end <ms> --thread "ui,raster,platform,RenderThread"
```

For UI-thread Flutter phases:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace slices --start <ms> --end <ms> --tid <ui_tid> --name "BUILD|LAYOUT|PAINT|Animate|BeginFrame|Frame|PlatformConfiguration" --top-duration 30
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace slices --start <ms> --end <ms> --thread "1.ui,root.1.ui,ui" --name "BUILD|LAYOUT|PAINT|Animate|BeginFrame|Frame|PlatformConfiguration" --top-duration 30
```

Prefer `--tid` once the UI thread id is known because it is exact. Use `--thread` for discovery or when comparing several likely UI thread names.

For blocking or IPC:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace blocked --start <ms> --end <ms> --top-duration 30
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace binder --start <ms> --end <ms> --top-duration 30
```

For GPU, fences, and RenderService:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" gpu --start <ms> --end <ms>
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" fences --start <ms> --end <ms>
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" htrace slices --start <ms> --end <ms> --name "RenderService|fence|Acquire|Present|gpu|rs" --top-duration 30
```

For transitions and interaction latency:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" animation
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" timeline --start <ms> --end <ms>
```

For power or thermal suspicion:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" energy
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" cpu --top 20
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" gpu
```

5. Use JSON only when structured post-processing helps:

```bash
python3 "<skill-dir>/scripts/insight_analyzer.py" "<trace.insight>" flutter --top-duration 50 --json
```

Do not quote large JSON blobs in the final answer. Extract the relevant frame IDs, timestamps, durations, threads, slices, and blocking chains.

## Interpretation Rules

- Use the analyzer output as evidence. Do not infer a root cause from one metric without corroborating timeline, htrace, CPU/GPU, or fence data.
- For UI-thread jank, prefer traces captured with `--trace-systrace` in `FlutterLoader.ets`; use `BUILD`, `LAYOUT`, and `PAINT` slices to separate widget rebuild cost, layout cost, and paint cost.
- Treat thread classification as part of the evidence. If UI or raster roles look wrong, run `threads`, then rerun `htrace slices` with `--tid` for the specific thread before drawing conclusions.
- Do not assume UI cost is absent just because `flutter --top-duration` shows `ui=0.0ms`; verify the UI thread directly when thread names differ from older traces.
- Distinguish app-side Flutter work from system-side presentation delay. A slow Flutter UI frame is a different fix path than a RenderService or fence wait.
- Convert trace evidence into developer actions: reduce build/layout work, move expensive synchronous work off the UI thread, defer startup work, reduce overdraw/large images, prewarm shaders, avoid blocking platform channels, investigate plugin/native calls, or inspect system/GPU contention.
- Mention frame budget context: 16.7 ms for 60 Hz, 11.1 ms for 90 Hz, 8.3 ms for 120 Hz. Use the device refresh rate only if the trace exposes it; otherwise state thresholds as reference budgets, not as confirmed target.
- Preserve uncertainty. If data sources are missing or frame attribution is incomplete, report the limitation and the next trace to capture.

## Report Shape

Respond in the developer's language when possible. Prefer this structure:

1. **Finding**: one-sentence root-cause hypothesis with confidence.
2. **Evidence**: frame numbers, timestamps, durations, threads/slices, and commands used.
3. **Reasoning**: why the evidence points to UI/raster/GPU/fence/CPU/IPC/energy.
4. **Action**: concrete Flutter/OHOS remediation steps.
5. **Next capture**: only if current evidence is insufficient.

Keep raw command output brief. Include enough numeric evidence for the user to reproduce the conclusion.
