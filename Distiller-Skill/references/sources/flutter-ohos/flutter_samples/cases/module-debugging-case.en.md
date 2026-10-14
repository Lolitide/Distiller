# Flutter Module Debugging Case Study

## I. Fault Description

Starting from version 3.32, the Flutter community enables thread merging by default; that is, the 1.ui thread is merged with the app's UI thread. This raises the thread priority of the 1.ui thread and improves performance. When thread merging is enabled, breakpoint debugging of Dart code blocks the app's UI thread. If the app is not launched in debug mode, the app's Watchdog mechanism causes the blocked UI thread to trigger a THREAD_BLOCK_6S event, the app exits suddenly, and Flutter reports device lost. When the developer manually starts the app by tapping its icon, the phone does not know that this app is going to be debugged; the app's Watchdog is enabled and does not allow the UI thread to be blocked, resulting in a crash.

This problem can be avoided with the following procedure: after a Flutter attach, start the app through DevEco Studio's debug mode. The app then runs in debug mode, and no thread reports the THREAD_BLOCK_6S problem. A debug build of the app does not mean the app is in debug mode; this procedure requires the app to be launched again.

---

## II. Error Stack Trace

```log
Reason:BUSSINESS_THREAD_BLOCK_6S
appfreeze:com.xxx.app BUSSINESS_THREAD_BLOCK_6S at 20250924172744
STRINGID:BUSSINESS_THREAD_BLOCK_6S
......
DOMAIN = AAFWK
EVENTNAME = BUSSINESS_THREAD_BLOCK_3S

Thread 1 (Tid:65131, Name:com.hnair.app):
#00 pc 0000000000156a74 /system/lib/ld-musl-aarch64.so.1(epoll_wait+80)
#01 pc 00000000000192bc ...(EpollIoWaiter::WaitFor...)
#02 pc 0000000000021660 ...(EventQueue::WaitUnilLocked...)
#03 pc 0000000000022fdc ...(EventQueueBase::GetEvent()+216)
#04 pc 000000000002cf60 ...(EventRunnerImpl::Run()+928)
#05 pc 00000000000302f0 ...(EventRunner::Run()+528)
#06 pc 00000000000b9ca0 ...(MainThread::Start()+400)

Thread 2 (Tid:150, Name:RSRenderThread): waiting for an event (epoll_wait), the standard idle state of a rendering thread
Thread 3 (Tid:227, Name:gpu-async-work): waiting on a condition variable, the standard idle state of a GPU worker thread
```

---

## III. Problem Scenario Analysis

**Problem localization**

Based on the current stack information, the main thread is executing epoll_wait. In the HarmonyOS (similar to Android) application framework, this is the idle state of the main thread's message loop. It is waiting for new messages (such as UI event lifecycle callbacks) to enter the queue. Since the main thread is "idle", it is not doing anything time-consuming (no infinite loop, no heavy business logic, not waiting on a lock). An idle main thread should, in theory, immediately respond to the system's ping/pong heartbeat detection and should not trigger BUSSINESS_THREAD_BLOCK_6S (business thread blocked for 6s). The only possibility is that the entire process or the main thread has been forcibly suspended by something external and no longer participates in CPU scheduling. In a normal development scenario, the most common cause of this situation is that a debugging tool is being used and a breakpoint has been hit.

Ruling out other possibilities:
   Deadlock: the stack should be stuck in lock-related calls such as pthread_mutex_lock or pthread_cond_wait
   CPU preemption/starvation: if the CPU is fully occupied by other high-priority threads, the main thread stack usually shows a specific business code execution point instead of sitting in epoll_wait of the message loop
   Other thread blocking: the reported error clearly points to Tid:65131 (the main thread), while the stacks of RSRenderThread and gpu-async-work are also in a normal waiting state, with no sign of an abnormal deadlock

**Cause analysis**

Analysis summary: combining the typical characteristics of "the main thread is in the message-loop idle state (epoll_wait)" + "the system determines that it has been blocked and unresponsive for more than 6 seconds", we can conclude that this is not a business bug in the app itself. It is caused by the debugging process interrupting the normal execution of the app (a breakpoint was hit), which led the system watchdog to kill the app by mistake.

---

## IV. Solution

Taking the [multiple_flutters](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/add_to_app/multiple_flutters) demo as an example:

1. Complete the compilation and integration of the module

2. Open the multiple_flutters_ohos project with DevEco Studio and connect a physical device or emulator

   ![Open the multiple_flutters_ohos project](../media/module-debugging-case/module-debugging-case-01.png)

   <p align="center"><strong>Figure 1</strong> Open the multiple_flutters_ohos project</p>

3. Open Project Structure -> Signing Configs and configure signing

   ![Configure signing](../media/module-debugging-case/module-debugging-case-02.png)

   <p align="center"><strong>Figure 2</strong> Configure signing</p>

4. Click the debug button of DevEco Studio to run the app

   ![Click the debug button to run the app](../media/module-debugging-case/module-debugging-case-03.png)

   <p align="center"><strong>Figure 3</strong> Click the debug button to run the app</p>

5. After the app starts successfully in debug mode, open the multiple_flutters_module project with Android Studio

   ![Open the module project with Android Studio](../media/module-debugging-case/module-debugging-case-04.png)

   <p align="center"><strong>Figure 4</strong> Open the module project with Android Studio</p>

6. Click the Flutter Attach button in the Android Studio toolbar and wait for the connection

   ![Click the Flutter Attach button and wait for the connection](../media/module-debugging-case/module-debugging-case-05.png)

   <p align="center"><strong>Figure 5</strong> Click the Flutter Attach button and wait for the connection</p>

7. Set breakpoints in the code that needs to be debugged, then wait for the connection

   ![Set breakpoints and wait for the connection](../media/module-debugging-case/module-debugging-case-06.png)

   <p align="center"><strong>Figure 6</strong> Set breakpoints and wait for the connection</p>

8. Open the flutter module page; the connection succeeds

   ![Open the module page; the connection succeeds](../media/module-debugging-case/module-debugging-case-07.png)

   <p align="center"><strong>Figure 7</strong> Open the module page; the connection succeeds</p>

9. The breakpoints are hit successfully without a sudden exit, and you can debug normally
