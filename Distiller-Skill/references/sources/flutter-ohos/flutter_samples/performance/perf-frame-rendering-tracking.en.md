# Performance Analysis: Frame Rendering Tracing

When analyzing the performance of a Flutter application, use analysis tools to capture and analyze trace data of the application. Considering that you might need to isolate and track a particular frame, for instance, when dealing with jank or frame loss, this topic describes how to track individual frames.  


## Analysis Tools
Common analysis tools include [DevEco Studio Profiler](https://developer.huawei.com/consumer/cn/download/) (recommended) and [SmartPerf](https://gitcode.com/openharmony-sig/smartperf). For details about how to use the Profiler, see [In-depth Capture for Problem Locating](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/deep-recording-V5).


## Frame Identifier
The rendering process of a frame is roughly as follows.

![](../media/performance/performance-07_en.png)


It is important to understand the frame rendering process and assign an appropriate frame identifier to each unit to match the rendering process.

### First Identifier: frame_number
**frame_number** is the identifier for matching the 1.ui and 1.raster threads.  
Mark the two threads and correlate them for observation. You can then find this identifier on the traces; it is the first frame rendering identifier of a Flutter application.  

- If **frame_number** does not appear in the 1.ui and 1.raster threads, the current frame is not self-rendered by Flutter. In this case, you need to demarcate the performance issue again.

![](../media/performance/performance-08.png)

### Second Identifier: ReuseBuffer or acquire buffer

**ReuseBuffer** is the identifier for matching the 1.raster and render_service threads.  
During the trace of **flutter::SkCanvas::Flush** in the 1.raster thread, a buffer is applied for from the RS process to store the rendered frame content. Click the trace of **binder transaction** to jump to another thread and view the ID of the corresponding **ReuseBuffer**.

![](../media/performance/performance-09.png)


During the trace of **RSMainThread::DoComposition** in the render_service thread, the frame memory in the buffer is obtained. The trace of **acquire buffer sequence** shows that the **ReuseBuffer** ID is the same as the one applied for by the 1.raster thread.

![](../media/performance/performance-10.png)



- Based on the preceding two identifiers, you can identify the frame rendering of a Flutter application on the RS process. However, no trace is provided to identify the subsequent units in the RS process. By default, consecutive thread traces are from the same frame (that is, **render_service**, then **RSUniRenderThread**, and then **RSHardwareThread** are consecutive).
