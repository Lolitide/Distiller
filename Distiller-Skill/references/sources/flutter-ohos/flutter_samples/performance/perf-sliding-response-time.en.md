# Performance Analysis: Swipe Response Latency

This topic describes how to conduct a trace analysis on the swipe response latency for Flutter applications. Make sure you have read [Performance Analysis: Sorting the Thread Sequence](./perf-analysis-threads-sequence.en.md) before continuing.

## Preparations

- You have learned how to use [DevEco Studio Profiler](https://developer.huawei.com/consumer/cn/download/).
- You have a clear understanding of the thread rendering sequence. For details, see [Performance Analysis: Sorting the Thread Sequence](./perf-analysis-threads-sequence.en.md).

## 1. Finger Press
A finger press is the prerequisite for all click or swipe events. From it, important information such as the initial position of the finger and which component is touched can be obtained.


The mmi_service thread triggers multimodal interaction events, and the Flutter application listens for and responds to touch events.


The touch event of finger press is immediately forwarded to the Flutter application.


In the mmi_service thread, the next trace after **package touchEvent** shows **service report touchId: number, type: down**, where the type **down** indicates the touch event of finger press. In the application main thread, the trace of **DispatchTouchEvent** contains detailed coordinates and the touch event type **0**, indicating the touch event of finger press. The traces on the two threads match.

![](../media/performance/performance-11.png)  


## 2. Finger Swipe
The touch event of finger swipe is not immediately forwarded to Flutter applications. Instead, its sending is controlled by the vsync-app signal.


Like the traces of finger press, the mmi_service thread and the application main thread have matching traces; only the type is different, which is **move**, with the value **2**.


The touch event of finger swipe can be passed to the main thread only after being triggered by the vsync-app signal of flutterSyncName. Therefore, the time sequence is as follows: mmi_service > VSyncGennerator > DVSync-app > application main thread. Trace sequence is as follows.

![](../media/performance/performance-12.png)  

- Note: Coordinates of the touch event of the first finger swipe are the same as those of the touch event of finger press.

## 3. TouchSlop
TouchSlop is the minimum swipe distance that can be identified by the system. It is a threshold, which is called the swipe threshold. Users can customize the swipe threshold of a component. The default value is **18**.

By viewing the coordinates of the touch event trace in the application main thread, you can calculate on your own whether the coordinate offset reaches the swipe threshold.


## 4. First Frame of the Swipe Gesture
When the swipe distance of a touch event exceeds the specified swipe threshold, the Flutter application triggers an update. However, the actual drawing operation can be executed only after the next frame arrives. Therefore, after the touch event meets the swipe condition, the rendering of the first frame at the start of the swipe still needs to wait for a one-frame delay.

Trace sequence is as follows.

![](../media/performance/performance-13_en.png)  

## 5. First-Frame Rendering
You need to find out the corresponding trace. For the general rendering process, see [Performance Analysis: Frame Rendering Tracing](./perf-frame-rendering-tracking.en.md).

Frame rendering ends on RSHardwareThread of the RS process. However, during the automatic test, the end identifier of frame rendering is the dpu_gfx_primary thread (dpu_gfx_primary is only a hardware signal and will not be described in detail).

Trace sequence is as follows.

![](../media/performance/performance-14.png)  


Therefore, the swipe response latency is the duration from the time the trace of finger press is recorded in the mmi_service thread to the time the first frame of the swipe gesture finishes rendering.
