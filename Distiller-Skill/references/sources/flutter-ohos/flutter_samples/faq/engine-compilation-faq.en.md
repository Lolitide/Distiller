# ohos Engine Artifact Compilation Issues

[Reference for the flutter_engine environment build configuration](https://gitcode.com/CPF-Flutter/flutter_engine/blob/master/README.en.md)

<a id="section765205"></a>

## Recommended Environment Configuration Version of the OpenHarmony Flutter Engine

**Symptom:**

The build environment for the Flutter OpenHarmony-adapted engine needs to be prepared.

**Cause:**

Engine compilation depends on specific versions of Python, Java, the DevEco toolchain, and Xcode. Version mismatches cause build failures.

**Solution:**

Recommended configuration versions:

1. Python 3.8-3.11 (an error is reported on version 3.12)
2. Java 17
3. DevEco-Studio / command-line-tools, 5.0.3.300+
   - Includes ohpm, hvigorw, node, and the OpenHarmony SDK
4. Xcode 14.3

---

<a id="section374081"></a>

## Generating the flutter.har File

**Symptom:**

The `flutter.har` engine artifact needs to be generated for use in app integration.

**Cause:**

After the engine artifacts are built successfully, `flutter.har` is produced, but the so files must be copied to the embedding layer directory separately before the build.

**Solution:**

1. After the engine artifacts are built successfully, `flutter.har` is generated (`src/out/ohos_debug_unopt_arm64/flutter.har`).
2. Copy the required so files (`libflutter.so`; in profile mode, additionally copy `libvmservice_snapshot.so`) to the `flutter_embedding/flutter/ohos` directory, and then build. For detailed steps, see the [flutter_engine documentation](https://gitcode.com/CPF-Flutter/flutter_engine/blob/master/README.en.md#code-building-at-the-embedding-layer).

---

<a id="section825475"></a>

## Debugging the Flutter Engine Using DevEco Studio

**Symptom:**

Flutter engine (C++ layer) code needs to be debugged in DevEco Studio.

**Cause:**

The engine is implemented in C++ and requires a toolchain that supports native debugging for breakpoints and step-by-step debugging.

**Solution:**

Follow the official guide [Debugging-the-engine](https://github.com/flutter/engine/blob/main/docs/Debugging-the-engine.md) to configure native debugging in DevEco Studio and attach to the engine process.

Create a native debug configuration in DevEco Studio, specify the engine source code and symbol table paths, and attach to the target process. You can then debug with breakpoints at the C++ layer.
