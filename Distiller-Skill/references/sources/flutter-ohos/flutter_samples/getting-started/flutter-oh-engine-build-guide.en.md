# Flutter OH Engine Build Guide

This guide describes how to build Flutter Engine artifacts that support OpenHarmony devices. It is intended for developers who need to make custom Engine modifications. If you only need to build applications from the Engine artifacts, you can simply run `flutter build hap`; the Engine artifacts are pulled from the cloud automatically, so there is no need to compile them yourself.

## Build Environment Requirements

### 1.1 Operating System Support

| Operating System | Support Scope |
|------------------|---------------|
| Linux | Fully supports Engine builds |
| macOS | Fully supports Engine builds |
| Windows | Only supports building `gen_snapshot` |

### 1.2 Prerequisite Checklist

Before you start the build, confirm that the following environment items are ready:

| Environment Item | Version/Requirement | Verification Command |
|------------------|---------------------|----------------------|
| JDK | 17 or later | `java -version` |
| Python | 3.8 – 3.11 (3.12 has compatibility issues) | `python3 --version` |
| Node.js | v14.19.1 or later, and earlier than v17.0.0 | `node -v` |
| DevEco Studio | 5.0.3.300 or later | — |
| Xcode | 14.3 or later (macOS only) | `xcodebuild -version` |
| Disk space | 50 GB+ recommended | `df -h` |

### 1.3 Network Requirements

The build process requires access to all URLs listed in the `allowed_hosts` field of the `DEPS_ohos` configuration file:

```text
boringssl.googlesource.com
chrome-infra-packages.appspot.com
chromium.googlesource.com
dart.googlesource.com
flutter.googlesource.com
llvm.googlesource.com
skia.googlesource.com
swiftshader.googlesource.com
gitcode.com/openharmony-sig
```

> If some of the domains are inaccessible, configure a network proxy and try again.

---

### Step 1: Set Up the Engine Build Environment

### 2.1 Install depot_tools

`depot_tools` provides the `gclient` and `gn` build tools:

```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

Add `depot_tools` to the `PATH` environment variable (edit `~/.zshrc` or `~/.bashrc`):

```bash
export PATH=$HOME/depot_tools:$PATH
```

```bash
source ~/.zshrc   # or source ~/.bashrc
```

### 2.2 Install Basic Dependencies

**macOS (Homebrew):**

```bash
brew install git curl unzip
brew install python3   # Must be 3.8–3.11; 3.12 has compatibility issues
brew install pkg-config ninja
```

**Linux:**

```bash
sudo apt install git curl unzip
sudo apt install python3   # Must be 3.8–3.11; 3.12 has compatibility issues
sudo apt install pkg-config ninja-build
```

### 2.3 Configure Engine Build Environment Variables

On top of the [environment setup](./flutter-oh-env-setup.en.md#configure-environment-variables), confirm that the following environment variables are correctly configured (the following is a macOS example; on Linux, change `TOOL_HOME` to the actual installation path):

```bash
# JDK
export JAVA_HOME=<JAVA_HOME path>
export PATH=$JAVA_HOME/bin:$PATH

# DevEco Studio toolchain (including ohpm, hvigor, node, and the OpenHarmony SDK)
export TOOL_HOME=/Applications/DevEco-Studio.app/Contents
export DEVECO_SDK_HOME=$TOOL_HOME/sdk
export PATH=$TOOL_HOME/tools/ohpm/bin:$PATH
export PATH=$TOOL_HOME/tools/hvigor/bin:$PATH
export PATH=$TOOL_HOME/tools/node/bin:$PATH
```

---

### Step 2: Fetch and Sync the Engine Source Code

### 3.1 Configure the .gclient File

The `flutter_flutter` repository ships a built-in `.gclient` template file (`engine/scripts/ohos.gclient`) that you can use directly:

1. Go to the directory of the cloned `flutter_flutter` source code:

   ```bash
   cd flutter_flutter
   ```

2. Copy the template file as `.gclient`:

   ```bash
   cp engine/scripts/ohos.gclient .gclient
   ```

   The `.gclient` file content is as follows:

   ```python
   solutions = [
     {
       "custom_deps": {},
       "deps_file": "DEPS_ohos",
       "managed": False,
       "name": ".",
       "safesync_url": "",
       "url": "https://gitcode.com/openharmony-tpc/flutter_flutter.git",
     },
   ]
   ```

> If you connect to GitCode using SSH, you can change `url` to `git@gitcode.com:openharmony-tpc/flutter_flutter.git`.

### 3.2 Run gclient sync

Run the following command in the directory that contains `.gclient` to sync the source code:

```bash
gclient sync
```

This command syncs the Engine source code and the official packages repository, and runs the `ohos_setup` hook task (which copies the build script `ohos` and other files to the source code root directory).

> [!WARNING]
>
> - The sync process requires access to all URLs listed in `allowed_hosts`. If some domains are inaccessible, configure a network proxy.
> - The sync takes a long time (about 30–60 minutes, depending on the network conditions).
> - If a timeout error occurs, run `gclient sync` again.
> - After the sync completes successfully, the terminal exits automatically.

---

### Step 3: Build the Engine

### 4.1 Run the Build

After the code is synced, the build script `ohos` has been copied automatically to the source code root directory. Run the build command in that directory:

```bash
# 1) View help
./ohos -h

# 2) Build all modes (debug + profile + release; this is the default behavior)
./ohos

# 3) Build only a specific mode
./ohos -t debug      # Debug mode
./ohos -t profile    # Profile mode
./ohos -t release    # Release mode
```

### 4.2 Build Artifacts

The build artifacts are located under the `src/out/` directory. Directories are named `ohos_{mode}{_unopt}_{cpu}`, where debug mode additionally appends the `_unopt` suffix:

| Build Mode | Target Engine Artifacts Directory | Host Engine Artifacts Directory |
|------------|-----------------------------------|---------------------------------|
| **debug** | `src/out/ohos_debug_unopt_arm64/` | `src/out/host_debug_unopt/` |
| **profile** | `src/out/ohos_profile_arm64/` | `src/out/host_profile/` |
| **release** | `src/out/ohos_release_arm64/` | `src/out/host_release/` |

> If you specify a CPU architecture other than `arm64` through `--ohos-cpu`, or specify `arm64` through `--host-cpu`, the artifact directory names change accordingly. Refer to the folders actually generated under the `src/out/` directory.

Verify the build artifacts:

```bash
# 1) Verify the build artifacts (they should include files such as libflutter.so and flutter.har)
ls -la src/out/ohos_release_arm64/
```

### 4.3 Update the Code

To pull the latest code and rebuild, perform the following two steps:

```bash
# 1) Update the Engine source code to the specified branch (without running a build)
./ohos -b master

# 2) Rebuild
./ohos -t release
```

---

### Step 4: Build an Application with a Local Engine

Starting from version 3.22.0, compiling the Engine also generates `local-engine` (target platform) and `local-host-engine` (host platform). When you build an application with a local Engine, you must specify both artifacts:

```bash
flutter build hap \
  --target-platform ohos-arm64 \
  --release \
  --local-engine=ohos_release_arm64 \
  --local-engine-host=host_release
```

**Parameter description:**

| Parameter | Description |
|-----------|-------------|
| `--target-platform` | Target platform: `ohos-arm64` |
| `--release` | Build mode: `--debug`, `--profile`, or `--release` |
| `--local-engine` | Path to the Engine build artifacts |
| `--local-engine-host` | Path to the Host Engine build artifacts |

Artifact names for each build mode:

| Build Mode | `--local-engine` | `--local-engine-host` |
|------------|------------------|-----------------------|
| **debug** | `ohos_debug_unopt_arm64` | `host_debug_unopt` |
| **profile** | `ohos_profile_arm64` | `host_profile` |
| **release** | `ohos_release_arm64` | `host_release` |

**Example:**

```bash
# Assume the engine directory is at ~/engine
flutter build hap \
  --target-platform ohos-arm64 \
  --release \
  --local-engine=ohos_release_arm64 \
  --local-engine-host=host_release
```

---

### Step 5: Build the Embedding-Layer HAR Artifacts

After the Engine build completes, `flutter.har` is located at `src/out/<output_dir>/flutter.har`. To build or rebuild the HAR artifacts separately, use the `har` step of the `ohos` script:

```bash
# 1) Build flutter.har in release mode
./ohos -t release -n har

# 2) Build with unstripped .so files (including debug symbols)
./ohos -t release -n har --har-unstripped
```

---

## FAQ

### How Do I Troubleshoot gclient sync Failures?

| Symptom | Solution |
|---------|----------|
| Connection timeout | Check that the network proxy is working, make sure the URLs in `allowed_hosts` are accessible, and run `gclient sync` again |
| Permission error | Make sure you have read and write permissions on the source code directory |
| Dependency download failure | Check whether the URLs in `allowed_hosts` are accessible, and configure a network proxy if necessary |
| Python-related errors | Confirm that the Python version is 3.8–3.11; version 3.12 has compatibility issues |
| `A required privilege is not held by the client` on Windows | Go to Settings → Developer options and enable Developer Mode |

### How Do I Handle Build Script Errors?

| Symptom | Solution |
|---------|----------|
| `Permission denied` | Run `chmod +x ohos` to add the execute permission |
| `Member notfound:'isOhos'` | Make sure the Dart patches have been applied (the patches are located in `src/flutter/attachment/repos`; apply them with `git apply`, then compile again) |
| Changes to the Embedding layer code do not take effect in the build | Change the timestamp of any C++ file (for example, add a space, save the file, and then delete the space) so that the build system re-detects the change, and then build again |

### What Should I Do If the Dart VM Snapshot Hash Is Inconsistent?

Different operating systems handle line endings differently, which may cause the Dart VM Snapshot Hash to be inconsistent. To check it:

```bash
# 1) Obtain the current Dart VM Snapshot Hash
python3 src/third_party/dart/tools/make_version.py --format='{{SNAPSHOT_HASH}}'
```

If the value obtained is not the expected one, check whether all lines in `src/third_party/dart/runtime/vm/dart.cc` and `src/third_party/dart/runtime/vm/image_snapshot.cc` end with the LF line ending (on Windows, you can use Notepad++ to check this).
