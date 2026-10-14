# Environment Issues

[Flutter OH Development Environment Setup Guide](../getting-started/flutter-oh-env-setup.en.md)

<a id="section792878"></a>

## Flutter Commands Fail with Error: The Flutter directory is not a clone of the GitHub project

**Symptom:**

An error is reported when running a Flutter command (for example, `flutter doctor -v`):

```log
Error: The Flutter directory is not a clone of the GitHub project.
```

**Cause:**

The Flutter OH SDK was not obtained through `git clone`; it was typically downloaded from the web as a ZIP archive and extracted. This method does not include the `.git` directory, while the Flutter tool relies on Git metadata at startup, so the command exits before execution.

**Solution:**

Use `git clone` to obtain the source code instead, and switch to the target branch or tag.

---

<a id="section792879"></a>

## Flutter Commands Fail with Error: Unable to find git in your PATH

**Symptom:**

An error is reported when running a Flutter command (for example, `flutter doctor -v`):

```log
Error: Unable to find git in your PATH.
```

**Cause:**

Git is not installed, or the directory containing the Git executable has not been added to `PATH`.

**Solution:**

1. Install Git.
2. Add Git's `cmd` directory to `PATH`, for example `C:\Program Files\Git\cmd`.
3. Reopen the terminal and run `git --version` to confirm that Git is available.

---

<a id="section792877"></a>

## Error: [!] No Hmos SDK found. Try setting the HOS_SDK_HOME enviroment variable.

**Symptom:**

An error is reported when running a Flutter command: `[!] No Hmos SDK found. Try setting the HOS_SDK_HOME enviroment variable.`

**Cause:**

The ohos-sdk path is not configured.

**Solution:**

1. Obtain the SDK path bundled with `DevEco Studio`, for example: `D:\Huawei\DevEco Studio\sdk`
2. Run the following command to configure the flutter ohos-sdk path:

   ```shell
   flutter config --ohos-sdk "D:\Huawei\DevEco Studio\sdk"
   ```

3. Run the following command to check whether the configuration succeeded:

   ```shell
   flutter config --list
   ```

   The configuration succeeds if the following output is displayed:

   ```shell
   All Settings:
     ohos-sdk: D:\Huawei\DevEco Studio\sdk
   ```

---

<a id="section808944"></a>

## flutter pub get Fails in an Offline Environment

**Symptom:**

`flutter pub get` fails when executed in an offline environment.

**Cause:**

In an offline environment, dependencies cannot be fetched from remote repositories.

**Solution:**

Add the `--offline` parameter. Complete command:

```shell
flutter pub get --offline
```

---

<a id="section677748"></a>

## [Windows] flutter pub get Reports Package not available (Long Path Issue)

**Symptom:**

Error log:

```log
Package not available (the pubspec for shared_preferences 2.5.3 from git has version 2.2.0)
```

**Cause:**

The first time `flutter pub get` runs, the entire project at `https://gitcode.com/CPF-Flutter/flutter_packages.git` is pulled into the local cache (even if you only need `shared_preferences`). Because some plugin file paths are too long and exceed the default Windows path length limit (260 characters), the branch cannot be switched after pulling and only the default master branch remains, resulting in the version mismatch error.

The cache path depends on the `PUB_CACHE` environment variable:

- If `PUB_CACHE` is not set, the default path is `C:\Users\[username]\AppData\Local\Pub\Cache\git\flutter_packages-xxx`
- If `PUB_CACHE` is set (for example to `D:\pub-cache`), the path is `%PUB_CACHE%\git\flutter_packages-xxx`

**Solution:**

**Option 1 (recommended): Set the PUB_CACHE environment variable to a shorter path**

Set `PUB_CACHE` to a short path at the drive root (for example `D:\pub-cache`) to fundamentally shorten the path length and reduce the occurrence of long path issues:

1. Add `PUB_CACHE` to the system environment variables, with the value set to `D:\pub-cache` (or another short path on a different drive)
2. Delete the original cache directory and run `flutter pub get` again

**Option 2: Enable Windows long path support**

1. Open `gpedit.msc` → Computer Configuration → Administrative Templates → System → File System → enable "Enable Win32 long paths"
2. Run cmd as administrator and execute:

   ```shell
   git config --system core.longpaths true
   ```

3. In the `git\` subdirectory of the cache directory, find the directory whose name starts with `flutter_packages`, delete it, and run `flutter pub get` again

---

<a id="section764574"></a>

## Building a Release App Fails in the macOS Environment

**Symptom:**

Error log:

```log
ProcessPackageException: ProcessException: Found candidates, but lacked sufficient permissions to execute "/Users/xxx/ohos/src/out/ohos_release_arm64/clang_arm4/dart".
  Command: /Users/xxx/ohos/src/out/ohos_release_arm64/clang_arm4/dart
```

**Cause:**

In the macOS environment, the build artifacts lack the execution permission.

**Solution:**

1. Add the execution permission:

   ```shell
   chmod -R +x /Users/xxx/ohos/src/out/ohos_release_arm64/*
   ```

2. Manually click `dart` and `gen_snapshot` in the `src/out/ohos_release_arm64/clang_arm64` directory and allow the programs to run in "Settings → Privacy & Security → Security"

---

<a id="section404296"></a>

## flutter Copied from Windows to Linux or macOS Cannot Run

**Symptom:**

Error log:

```log
curl: (3) Illegal characters found in URL
xxx/flutter_flutter/bin/internal/update_dart_sdk.sh: line 156: return: can only return from a function or sourced script
curl: (3) Illegal characters found in URL
```

**Cause:**

The newline character on Windows (CRLF) is inconsistent with that on Linux/macOS (LF).

**Solution:**

1. Replace the newline character CRLF (`\r\n`) with LF (`\n`) in a single file:

   ```shell
   sed -i "s/\r//" target_file
   ```

2. Batch-replace the newline characters in `bin/dart`, `bin/*.sh`, and `bin/internal/*.version`:

   ```shell
   cd flutter
   # Run in the Linux environment
   sed -i "s/\r//" bin/dart $(find bin -name "*.sh") $(find bin -name "*.version")
   # Run in the macOS environment
   sed -i "" "s/\r//" bin/dart $(find bin -name "*.sh") $(find bin -name "*.version")
   ```

---

<a id="section491334"></a>

## Configuring ~/.npmrc

**Symptom:**

The npm mirror registry and proxy need to be configured.

**Cause:**

The default ohpm and npm registries have limited access in China, so mirror registries need to be configured to speed up dependency downloads.

**Solution:**

Configure the mirror registry and proxy in the `~/.npmrc` file:

```ini
registry=https://repo.huaweicloud.com/repository/npm/
@ohos:registry=https://repo.harmonyos.com/npm/
strict-ssl=false
# Set a proxy
# http_proxy=http://user:password@host:8080
# https_proxy=http://user:password@host:8080
```

---

<a id="section531573"></a>

## Configuring ~/.ohpmrc

**Symptom:**

The ohpm mirror registry and proxy need to be configured.

**Cause:**

The default ohpm registry has limited access in China, so a mirror registry needs to be configured to speed up OpenHarmony third-party library downloads.

**Solution:**

Configure the mirror registry and proxy in the `~/.ohpmrc` file:

```ini
registry=https://repo.harmonyos.com/ohpm/
strict_ssl=false
# Set a proxy
# http_proxy=http://user:password@host:8080
# https_proxy=http://user:password@host:8080
```

---

<a id="section766721"></a>

## Default Counter App Suddenly Exits When Running on the Emulator

**Symptom:**

The default Flutter counter app suddenly exits when running on the emulator.

**Cause:**

`FloatingActionButton` is not supported on the emulator. For details, see [Differences Between the Emulator and a Real Device](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-specification).

**Solution:**

Comment out `FloatingActionButton` in `lib/main.dart` before running the app on the emulator.

---

<a id="section563397"></a>

## [ios][release] GeneratedPluginRegistrant.m Module not found

**Symptom:**

The `GeneratedPluginRegistrant.m Module not found` error occurs during an iOS release build.

**Cause:**

A Flutter plugin was added to pubspec.yaml, but the pod reference for the newly added plugin is missing from the Podfile.

**Solution:**

```shell
rm ios/podfile && flutter clean && flutter run -d <ios_device>
```

Reference link: [GeneratedPluginRegistrant.m Module not found](https://github.com/flutter/flutter/issues/43986)

---

<a id="section146178"></a>

## [Windows] flutter doctor -v Does Not Respond

**Symptom:**

After the environment variables are configured, `flutter doctor -v` does not respond.

The execution result contains Flutter and OpenHarmony (indicating that the basic environment is correctly configured and both platforms are supported).

![](../media/faq/error.png)

<p align="center"><strong>Figure 1</strong> flutter doctor -v execution result</p>

**Cause:**

The proxy may not be properly configured.

**Solution:**

1. Configure the `http_proxy`, `https_proxy`, and `no_proxy` environment variables in the system environment variables
2. For `http_proxy`, refer to the DevEco proxy configuration
3. `https_proxy` can be the same as `http_proxy`
4. In addition to the DevEco proxy configuration, `no_proxy` also needs the following added:
   - `localhost`
   - `::1`
   - `127.0.0.1`

---

<a id="section900001"></a>

## Error When Running flutter upgrade

**Symptom:**

Running `flutter upgrade` reports an error and breaks the environment.

**Cause:**

Flutter OH does not yet support the `flutter upgrade` command. Running it attempts to pull from the official Flutter channel and overwrite the current OpenHarmony-adapted environment, breaking the environment and causing the error.

**Solution:**

Do not use `flutter upgrade`. Use one of the following methods to switch versions instead:

```shell
# Method 1: Clone a specific branch
git clone -b {target_branch_name} https://gitcode.com/CPF-Flutter/flutter_flutter.git

# Method 2: Switch branches in the existing SDK directory
cd $FLUTTER_ROOT
git checkout {target_branch_name}
rm -rf bin/cache
flutter doctor
```

For details, see [Flutter OH Version Upgrade Guide](../version/flutter-oh-upgrade-guide.en.md).
