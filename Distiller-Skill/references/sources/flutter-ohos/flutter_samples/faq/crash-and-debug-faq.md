# Crash 分析与调试问题

[Cpp Crash 栈分析指南](../debugging/flutter-cppcrash-stack-analysis.md)

<a id="section789191"></a>

## 使用 DevEco-Studio 调试 engine

**现象：**

需要在 DevEco Studio 中调试 Flutter engine（C++ 层）代码。

**原因：**

engine 为 C++ 实现，需要借助支持 native 调试的工具链进行断点与单步调试。

**解决方案：**

参考官方指引 [Debugging-the-engine](https://github.com/flutter/engine/blob/main/docs/Debugging-the-engine.md)，在 DevEco Studio 中配置 native 调试并附加到 engine 进程。

---

<a id="section453839"></a>

## Flutter 项目启动闪退

**现象：**

Flutter 项目启动后闪退。

**原因：**

请开发者在 crash 的栈顶日志中查看是否有以下信息，如有，可能是因为编译 hap 文件模式与编译出来的 engine 模式不匹配，如：编译 hap 文件 release 包，但用的是 debug 模式的 engine 引起。

crash 信息：

```log
Reason:Signal:SIGABRT(SI_TKILL).............................
........................................................
#01 pc 000000000014710c /system/lib/ld-musl-aarch64.so.1(abort+20).............
........................................................
........................................................
........................................................
```

**解决方案：**

确保编译 hap 文件的模式与使用的 engine 模式一致（release 包使用 release engine，debug 包使用 debug engine）。

---

<a id="section552653"></a>

## 提供可复现的 demo

**现象：**

反馈 crash 或异常问题时，需要提供可复现的 demo 供定位。

**原因：**

完整工程体积大、冗余文件多，不利于快速定位问题，需精简后再提供。

**解决方案：**

提供 demo 时，可以通过 git 删除不需要的文件，减小压缩包大小：

```sh
git init
git add -A
git commit -m "init"
git clean -dfx
```
