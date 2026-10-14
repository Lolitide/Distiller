# ohos 引擎产物编译问题

[flutter_engine 环境编译配置参考](https://gitcode.com/CPF-Flutter/flutter_engine/blob/master/README.md)

<a id="section765205"></a>

## Flutter OpenHarmony 化引擎编译环境推荐配置版本

**现象：**

需要准备 Flutter OpenHarmony 化引擎的编译环境。

**原因：**

引擎编译依赖特定版本的 Python、Java、DevEco 工具链与 Xcode，版本不匹配会导致编译失败。

**解决方案：**

推荐配置版本：

1. Python 3.8-3.11，3.12 版本会出现报错
2. Java 17
3. DevEco-Studio / command-line-tools，5.0.3.300+
   - 包含了 ohpm、hvigorw、node、OpenHarmony SDK
4. Xcode 14.3

---

<a id="section374081"></a>

## 如何生成 flutter.har

**现象：**

需要生成 `flutter.har` 引擎产物供应用集成使用。

**原因：**

引擎产物编译成功后会产出 `flutter.har`，但 so 文件需单独复制到 embedding 层目录后再编译。

**解决方案：**

1. 引擎产物编译成功后，会生成 `flutter.har`（`src/out/ohos_debug_unopt_arm64/flutter.har`）
2. 复制需要的 so 文件（`libflutter.so`，profile 模式需要额外复制 `libvmservice_snapshot.so`）到 `flutter_embedding/flutter/ohos` 目录后再编译，具体步骤参考 [flutter_engine 文档](https://gitcode.com/CPF-Flutter/flutter_engine#embedding%E5%B1%82%E4%BB%A3%E7%A0%81%E6%9E%84%E5%BB%BA%E6%8C%87%E5%AF%BC)

---

<a id="section825475"></a>

## 使用 DevEco-Studio 调试 engine

**现象：**

需要在 DevEco Studio 中调试 Flutter engine（C++ 层）代码。

**原因：**

engine 为 C++ 实现，需要借助支持 native 调试的工具链进行断点与单步调试。

**解决方案：**

参考官方指引 [Debugging-the-engine](https://github.com/flutter/engine/blob/main/docs/Debugging-the-engine.md)，在 DevEco Studio 中配置 native 调试并附加到 engine 进程。

在 DevEco Studio 中新建 Native 调试配置，指定 engine 源码与符号表路径，附加到目标进程后即可在 C++ 层断点调试。
