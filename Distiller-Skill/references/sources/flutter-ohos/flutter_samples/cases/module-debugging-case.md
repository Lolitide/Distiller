# Flutter module 调试案例

## 一、故障现场描述

Flutter社区从3.32版本开始，默认开启线程合并，即 1.ui 线程和应用的UI线程合并，这样会提升 1.ui 线程的线程优先级，从而提升性能。线程合并开启时，Dart 代码的断点调试会阻塞应用UI线程。应用如果不是通过调试模式运行，会因为应用的 Watchdog 机制，UI 线程阻塞会导致触发 THREAD_BLOCK_6S 事件，应用闪退，Flutter 出现 device lost。当开发者手动点击图标启动应用时，手机不知道这个应用要进行调试，应用 Watchdog会开启，不允许UI线程阻塞，导致崩溃。

这个问题可以通过操作避免，Flutter attach之后，通过 DevEco Studio的调试模式去启动应用，应用就会以调试模式运行，也就不会有线程上报 THREAD_BLOCK_6S的问题。应用的debug包不代表调试模式，该操作方法需要应用重新运行。

---

## 二、报错堆栈信息

```log
Reason:BUSSINESS_THREAD_BLOCK_6S
appfreeze:com.xxx.app BUSSINESS_THREAD_BLOCK_6S at 20250924172744
STRINGID:BUSSINESS_THREAD_BLOCK_6S
......
DOMAIN = AAFWK
EVENTNAME = BUSSINESS_THREAD_BLOCK_3S

线程1(Tid:65131, Name:com.hnair.app):
#00 pc 0000000000156a74 /system/lib/ld-musl-aarch64.so.1(epoll_wait+80)
#01 pc 00000000000192bc ...(EpollIoWaiter::WaitFor...)
#02 pc 0000000000021660 ...(EventQueue::WaitUnilLocked...)
#03 pc 0000000000022fdc ...(EventQueueBase::GetEvent()+216)
#04 pc 000000000002cf60 ...(EventRunnerImpl::Run()+928)
#05 pc 00000000000302f0 ...(EventRunner::Run()+528)
#06 pc 00000000000b9ca0 ...(MainThread::Start()+400)

线程2(Tid:150, Name:RSRenderThread):等待事件(epoll_wait),标准的渲染线程空闲状态
线程3(Tid:227, Name:gpu-async-work):等待条件变量,标准的GPU工作线程空闲状态
```

---

## 三、问题场景分析

【问题定位】

通过当前堆栈信息，主线程正在执行epoll_wait。在HarmonyOS(和 Android类似)的应用框架中，这是主线程消息循环的空闲状态。它正在等待新的消息（如ui事件生命周期回调等）进入队列。既然主线程是‘空闲’的它就没有在做耗时操作（没有死循环，没有在执行沉重的业务逻辑，没有在等待锁）一个空闲的主线程理论上会立刻响应系统的ping/pong心跳检测，不应该触发BUSSINESS_THREAD_BLOCK_6S（业务线程阻塞6s）。唯一可能就是整个进程或主线程被外部强制挂起，不再参与CPU调度。在正常的开发场景中导致这种情况最常见的原因是使用了某种调试工具，命中了断点。

排除其他可能性：
   死锁：堆栈信息应该停留在pthread_mutex_lock 或 pthread_cond_wait等锁相关的调用中
   CPU抢占/饥饿：如果因为CPU被其他高优先级线程占满，主线程堆栈通常会显示在某个具体业务代码的执行点，而不会待在消息循环的epoll_wait里
   其他线程阻塞：看报错明确指向的是Tid:65131（主线程），而RSRenderThread和gpu-async-worke的堆栈也是正常的等待状态，没有异常死锁迹象

【原因分析】

分析总结：结合”主线程处于消息循环空闲态（epoll_wait）“ + ”系统判定其阻塞超过6秒未响应“这一典型特征，可以判定这并非应用本身的业务BUG，而是因为在调试过程中打断了应用的正常运行（命中断点）。导致系统看门狗误杀。

---

## 四、解决方案

以 [multiple_flutters](https://gitcode.com/CPF-Flutter/flutter_samples/tree/master/add_to_app/multiple_flutters) Demo 为例：

1. 完成 module 的编译集成

2. 使用 DevEco Studio 工具打开 multiple_flutters_ohos 项目，连接真机或模拟器

   ![打开 multiple_flutters_ohos 项目](../media/module-debugging-case/module-debugging-case-01.png)

   <p align="center"><strong>图1</strong> 打开 multiple_flutters_ohos 项目</p>

3. 打开 Project Structure -> Signing Configs ，配置签名

   ![配置签名](../media/module-debugging-case/module-debugging-case-02.png)

   <p align="center"><strong>图2</strong> 配置签名</p>

4. 点击 DevEco Studio 工具 debug 按钮运行应用

   ![点击 debug 按钮运行应用](../media/module-debugging-case/module-debugging-case-03.png)

   <p align="center"><strong>图3</strong> 点击 debug 按钮运行应用</p>

5. 应用debug启动成功后，使用 Android Studio 工具打开 multiple_flutters_module 工程

   ![使用 Android Studio 打开 module 工程](../media/module-debugging-case/module-debugging-case-04.png)

   <p align="center"><strong>图4</strong> 使用 Android Studio 打开 module 工程</p>

6. 点击 Android Studio 工具栏 Flutter Attach 按钮，等待连接

   ![点击 Flutter Attach 按钮等待连接](../media/module-debugging-case/module-debugging-case-05.png)

   <p align="center"><strong>图5</strong> 点击 Flutter Attach 按钮等待连接</p>

7. 在需要调试的代码处设置断点后，等待连接

   ![设置断点等待连接](../media/module-debugging-case/module-debugging-case-06.png)

   <p align="center"><strong>图6</strong> 设置断点等待连接</p>

8. 打开 flutter module 页面，连接成功

   ![打开 module 页面连接成功](../media/module-debugging-case/module-debugging-case-07.png)

   <p align="center"><strong>图7</strong> 打开 module 页面连接成功</p>

9. 成功进入断点，不会出现闪退。即可正常调试
