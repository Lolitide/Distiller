# Crash Analysis and Debugging Issues

[Cpp Crash Stack Analysis Guide](../debugging/flutter-cppcrash-stack-analysis.en.md)

<a id="section789191"></a>

## Debugging the Engine with DevEco Studio

**Symptom:**

You need to debug Flutter engine (C++ layer) code in DevEco Studio.

**Cause:**

The engine is implemented in C++, so a toolchain that supports native debugging is required for breakpoints and stepping.

**Solution:**

Follow the official guide [Debugging-the-engine](https://github.com/flutter/engine/blob/main/docs/Debugging-the-engine.md) to configure native debugging in DevEco Studio and attach to the engine process.

---

<a id="section453839"></a>

## Sudden Exit on Flutter Project Startup

**Symptom:**

The Flutter project suddenly exits after startup.

**Cause:**

Check the top frames of the crash log for the following information. If it is present, the cause may be a mismatch between the mode used to build the hap file and the mode of the built engine — for example, building a release hap package while using the debug engine.

Crash information:

```log
Reason:Signal:SIGABRT(SI_TKILL).............................
........................................................
#01 pc 000000000014710c /system/lib/ld-musl-aarch64.so.1(abort+20).............
........................................................
........................................................
........................................................
```

**Solution:**

Ensure that the mode used to build the hap file matches the engine mode in use (a release package uses the release engine, and a debug package uses the debug engine).

---

<a id="section552653"></a>

## Providing a Reproducible Demo

**Symptom:**

When reporting a crash or abnormal issue, you need to provide a reproducible demo for troubleshooting.

**Cause:**

A complete project is large and contains many redundant files, which makes quick troubleshooting difficult; simplify it before providing it.

**Solution:**

When providing the demo, you can use git to remove unneeded files and reduce the archive size:

```sh
git init
git add -A
git commit -m "init"
git clean -dfx
```
