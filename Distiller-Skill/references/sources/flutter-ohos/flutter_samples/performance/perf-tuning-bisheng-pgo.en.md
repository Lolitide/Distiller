# Performance Tuning - BiSheng Compiler PGO

## Introduction to the BiSheng Compiler

The BiSheng compiler is a compiler built on the LLVM open-source project. Without requiring any changes to user code, it provides stronger optimization capabilities than mainstream open-source LLVM or GCC compilers, producing binaries with shorter runtime and fewer instructions, which helps improve application smoothness on devices.

For more information, see the [BiSheng documentation](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/bisheng-compiler-V5).

## Introduction to PGO

PGO (Profile-Guided Optimization) collects runtime statistics during execution, and then uses the collected data to optimize program performance in subsequent builds. The basic flow is shown below.

![PGO_process](../media/performance/performance-15.png)

For more information, see the [PGO documentation](https://www.hikunpeng.com/document/detail/zh/kunpengdevps/compiler/opg-bisheng/kunpengbisheng_30_0018.html).

## Using PGO

Enabling PGO relies on the BiSheng compiler. First confirm whether the Flutter artifacts are compiled with the BiSheng compiler.

Using PGO involves the following steps:

1. Build the instrumented artifacts.
2. Run the project with the instrumented artifacts to collect runtime information and generate a profile file.
3. Use the profile file for a second, feedback-guided build.

### Build the instrumented artifacts

Modify the [engine/src/build/config/compiler/BUILD.gn](https://gitcode.com/CPF-Flutter/flutter_flutter/blob/oh-3.35.7-dev/engine/src/build/config/compiler/BUILD.gn) file.

```diff
# Default "optimization on" config. On Windows, this favors size over speed.
config("optimize") {
...
  if (is_ohos) {
    if (enable_lto) {
      cflags += [ "-flto" ]
      ldflags += [ "-flto" ]
    }

    # The compiler-specific optimization options for BiSheng compiler.
    if (enable_lto && !unuse_bisheng) {
      # Relies on LTO optimization
      cflags += [ "-fwhole-program-vtables" ]
    }

    # The compiler-specific optimization options for BiSheng compiler.
    if (!unuse_bisheng) {
      cflags += [
        "-mllvm","--enable-partial-inlining",
+       "-fprofile-generate=/data/storage/el2/base/files",
+       "-mllvm", "-pgo-instrument-entry=true"
      ]
      ldflags += [
        "-Wl,-mllvm,-wholeprogramdevirt-check=fallback",
        "-Wl,--Bsymbolic-functions",
        "-Wl,--aarch64-inline-plt",
        "-Wl,-mllvm,--enable-partial-inlining",
        "-Wl,-mllvm,--tail-dup-placement",
+       "-fprofile-generate=/data/storage/el2/base/files",
+       "-mllvm", "-pgo-instrument-entry=true"
      ]
    }
  }
}
```

`/data/storage/el2/base/files` is a sandbox path. A corresponding `xxx.profraw` file is generated under its mapped path. The mapped path is: `/data/app/el2/100/base/<application bundle name>/files`.

After the build, use the instrumented `.har` file to replace the corresponding platform/mode `.har` file in `flutter_flutter`.

To verify that the instrumentation was applied successfully, use the commands below. Because instrumentation code is added, the size of the `.har` file increases somewhat.

```
llvm-objdump -S xx.so # Check for the llvm_prf field
llvm-objdump -d xx.so # Check the disassembly for the ldr add store code sequence
```

### Collect runtime information

Modify the `build-profile.json5` file in the root directory of the OHOS project so that `debuggable` under the `release` mode in `buildModeSet` is set to `true`. If the production build mode has a custom name, set `debuggable` for that mode to `true` while collecting, and change it back to `false` afterwards.

```diff
{
    "app": {
        ...
        "buildModeSet": [
            {
                "name": "profile",
                "buildOption": {
                "debuggable": false
                }
            },
            {
                "name": "release",
                "buildOption": {
-                "debuggable": false
+                "debuggable": true
                }
            }
        ]
    }
}
```

After modifying the file, build the package with a configuration as close to the production release as possible, for example selecting the `release` mode.

As shown below, click the **Debug** button to build and launch the application.
![](../media/performance/performance-16.png)

Click **lldb** in the debug panel below to enter the lldb tool command line, and click the button on the left to disable breakpoints.
![](../media/performance/performance-17.png)

In the lldb command line, enter `process handle` to list all signal names that may cause the program to pause.
![](../media/performance/performance-18.png)

For each signal, run `process handle [signal name] -s false` so that the application does not pause on any signal and interfere with collection. After running these commands, the signal information is printed immediately, and you can see that the `stop` column is all `false`.

> Note: You can use the [multi-cursor capability](https://code.visualstudio.com/docs/editing/codebasics#_multiple-selections-multicursor) provided by your text editor for efficient batch editing.

![](../media/performance/performance-19.png)

Now, in the lldb command line, run the profile collection command `process signal SIGUSR2` to collect the runtime profile of the application launch or of the period since the previous execution of this command. Running the collection command twice without restarting the application causes the previous collection file to be overwritten by the later one. You can take advantage of this by running the collection command once before and once after a key usage scenario of the application; the resulting profile then covers the key scenario. After running the command, check the out-of-sandbox path corresponding to the output path; a new file ending with `.profraw` should have been generated.

```shell
hdc shell ls /data/app/el2/100/base/[application bundle name]/files/pgoprofraw/
```

Download the `pgoprofraw` folder to your computer:

```shell
hdc file recv /data/app/el2/100/base/[application bundle name]/files/pgoprofraw/ .
```

Use the `llvm-profdata` tool to merge multiple `.profraw` files and convert the format. The `llvm-profdata` tool is in the same directory as the `clang++` shown after `CXX compiler path:` in the build log from step 1. Using a build tool and `llvm-profdata` of different versions may fail to convert due to incompatible data formats.

```shell
/path/to/llvm-profdata merge -output=pgo.profdata ./pgoprofraw/*.profraw
```

The command above generates a `pgo.profdata` file in the current directory.

### Second feedback-guided build

Use the collected profile information to guide the compiler in building a high-performance application. Note that before packaging, you must restore the temporary configuration added in [engine/src/build/config/compiler/BUILD.gn](https://gitcode.com/CPF-Flutter/flutter_flutter/blob/oh-3.35.7-dev/engine/src/build/config/compiler/BUILD.gn). Modify your compile options as shown in the example below.

```diff
# Default "optimization on" config. On Windows, this favors size over speed.
config("optimize") {
...
  if (is_ohos) {
    if (enable_lto) {
      cflags += [ "-flto" ]
      ldflags += [ "-flto" ]
    }

    # The compiler-specific optimization options for BiSheng compiler.
    if (enable_lto && !unuse_bisheng) {
      # Relies on LTO optimization
      cflags += [ "-fwhole-program-vtables" ]
    }

    # The compiler-specific optimization options for BiSheng compiler.
    if (!unuse_bisheng) {
      cflags += [
        "-mllvm","--enable-partial-inlining",
-       "-fprofile-generate=/data/storage/el2/base/files",
-       "-mllvm", "-pgo-instrument-entry=true"
+       "-fprofile-use=${custom path}/pgo.profdata"
      ]
      ldflags += [
        "-Wl,-mllvm,-wholeprogramdevirt-check=fallback",
        "-Wl,--Bsymbolic-functions",
        "-Wl,--aarch64-inline-plt",
        "-Wl,-mllvm,--enable-partial-inlining",
        "-Wl,-mllvm,--tail-dup-placement",
-       "-fprofile-generate=/data/storage/el2/base/files",
-       "-mllvm", "-pgo-instrument-entry=true"
      ]
    }
  }
}
```

The resulting `.har` artifact is the package after PGO optimization is enabled.

Rebuild the application project with this `.har` artifact. Note that in the `build-profile.json5` file in the project root directory, set `debuggable` for the corresponding mode in `buildModeSet` back to `false`.
