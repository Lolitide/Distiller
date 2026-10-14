# ohos Application Build Issues

<a id="section486961"></a>

## Error When Building an App with the Flutter Command Line

**Symptom:**

An error is reported when building an app with the `flutter build hap --release` command:

```log
> hvigor ERROR: ENOENT: no such file or directory, stat `xxx\ohos\entry\oh_modules\flutter_native_x86_64`
```

**Cause:**

During debugging, the emulator and physical devices were used alternately, and the emulator cache was used.

**Solution:**

1. Specify the platform architecture in the build command:

   ```bash
   flutter build hap --release --target-platform ohos-arm64
   ```

2. Manually delete the following cache files in the project:

   ```text
ohos/
├── .dart_tool
├── .build
├── ohos
│   ├── entry/
│   │   ├── build
│   │   ├── oh_modules
│   └─ oh_modules
   ```

   Re-run the build command `flutter build hap --release`.

---

<a id="section608960"></a>

## A Flutter OH Project Copied or Cloned from Another Source Cannot Run Locally

**Symptom:**

After a Flutter project is copied or cloned from another developer or a Git repository, errors occur during build or run.

**Cause:**

The original project's Flutter version, dependency lock, or build cache does not match the local environment.

**Solution:**

- Check the compatibility between the Flutter OH project and the local Flutter version

  Open the project's `pubspec.yaml` file and check the SDK version:

   ```yaml
   environment:
     sdk: 'version_number'
   ```

  Run `flutter doctor` in the terminal to check the local Flutter environment version and see whether it is compatible with the project version; if not, modify it.

- Delete `pubspec.lock` and re-fetch the dependencies:

  ```bash
  # Windows
  del pubspec.lock
  # macOS/Linux
  rm pubspec.lock

  flutter clean
  flutter pub get
  ```

  > **Note:** `pubspec.lock` is the dependency lock file. The original project's environment may differ from your local one; after deleting it, pub re-resolves the dependency versions based on the current environment.

- Clean the build cache:

  ```bash
  flutter clean
  ```

  Delete cache directories such as `build/`, `dart_tool/`, `ohos/oh_modules`, and `ohos/entry/build`.

---

<a id="section198530"></a>

## Configuring Aliases to Simplify Daily Build Commands

**Symptom:**

In daily development, the long `flutter build`/`flutter run` commands are entered frequently and need to be simplified.

**Cause:**

The OpenHarmony-adapted build and run commands are long (especially with the `--local-engine` parameter), so re-entering them repeatedly is inefficient.

**Solution:**

Configure aliases in the environment variable configuration file to simplify the commands used daily for Flutter OpenHarmony development:

- For Windows, use `Git Bash` to run common Linux commands. (Usage: right-click an empty area in the file manager and left-click Git Bash Here)
- For Linux, edit `~/.bash_profile`.
- For macOS, edit `~/.bash_profile` and add `source ~/.bash_profile` to `~/.zshrc`.

```bash
# The --local-engine parameter is optional and points to self-built engine artifacts; recommended in the Linux/macOS environment
export ENGINE_DIR=~/ohos/engine
export ENGINE_DEBUG=$ENGINE_DIR/src/out/ohos_debug_unopt_arm64
export ENGINE_PROFILE=$ENGINE_DIR/src/out/ohos_profile_arm64
export ENGINE_RELEASE=$ENGINE_DIR/src/out/ohos_release_arm64

alias fbuildD="flutter build hap --local-engine=$ENGINE_DEBUG --debug"
alias fbuildP="flutter build hap --local-engine=$ENGINE_PROFILE --profile"
alias fbuildR="flutter build hap --local-engine=$ENGINE_RELEASE --release"
alias frunD="flutter run -d $(hdc list targets) --local-engine=$ENGINE_DEBUG --debug"
alias frunP="flutter run -d $(hdc list targets) --local-engine=$ENGINE_PROFILE --profile"
alias frunR="flutter run -d $(hdc list targets) --local-engine=$ENGINE_RELEASE --release"
```

After the configuration is complete, reopen the terminal window, and you can use the aliases to build or run in the Flutter project directory:

```bash
flutter create hello --platforms ohos
cd hello
# Build the debug version
fbuildD
# Run the debug version
frunD
```

---

<a id="section610061"></a>

## White Screen After the App Is Built Successfully and Installed

**Symptom:**

The app is built successfully but shows a white screen after installation.

**Cause:**

The engine artifacts used do not match the run mode, so the snapshot version mismatches when the Dart VM initializes, resulting in a white screen. For details, see [ohos Runtime Issues](./runtime-issues-faq.en.md#section721639).

**Solution:**

Ensure that the engine artifacts in the run or build command are consistent with the target mode. For details, see [ohos Runtime Issues](./runtime-issues-faq.en.md#section721639).

---

<a id="section904254"></a>

## Build Error: A Version from Before the Flutter Plugin Structure Restructuring Uses the Restructured Plugin Library

**Symptom:**

A build error occurs. Log:

```log
Oops; flutter has exited unexpectedly: "type 'Null' is not a subtype of type 'List<dynamic>' in type cast".
```

**Cause:**

Versions from before and after the Flutter plugin structure restructuring are incompatible: the older flutter_flutter uses the restructured plugin library.

**Solution:**

Update flutter_flutter to the latest version on master or dev. (`45bd5e627e1f1e5f4d335f205781565f576acc60`, 2024-05-10)

---

<a id="section729405"></a>

## Precompiled so Package Imported When Building a Flutter Plugin Is Not Packaged into the har Package

**Symptom:**

When using the DevEco tool, the imported so package is not found in the built har package directory, causing abnormal function calls.

**Cause:**

The so package is placed in the wrong path, so it is not packaged into the har during the build.

**Solution:**

For the placement path of precompiled so packages, see the [FFI Plugin Development document](../plugin-and-package/developing-an-ffi-plugin.en.md).

---

<a id="section173896"></a>

## flutter pub get Dependency Conflict Error

**Symptom:**

A dependency conflict error is reported when running `flutter pub get`. Typical log:

```log
Resolving dependencies...
Because flutter_cache_manager >=3.0.0-nullsafety.0 <3.3.2 depends on path_provider from hosted and flutter_cache_manager depends on path_provider from git, flutter_cache_manager >=3.0.0-nullsafety.0 <3.3.2 forbidden.
So because xxx depends on flutter_cache_manager 3.3.1, version solving failed.
pub get failed
exit code: 1
```

**Cause:**

The hosted and git sources of `path_provider` conflict, causing dependency resolution to fail.

**Solution:**

Use `dependency_overrides` to resolve the dependency conflict. For details, see [plugin-adaptation-faq](./plugin-adaptation-faq.en.md#section152730).

---

<a id="section813672"></a>

## flutter Third-Party Library Dependency Error

**Symptom:**

Log information:

```log
Error:error:AbiSpecificInteger'Int32' is missing mapping for 'ohos_arm64'.
Dart snapshot generator failed with exit code 254
Target ohos_aot_profile_ohos-arm64 failed: Exception: AOT snapshotter exited with code 254.
```

**Cause:**

This type of error usually occurs when third-party libraries not adapted by the OpenHarmony community are used.

**Solution:**

Check the third-party library dependencies in the yaml file, and find the corresponding third-party library addresses in [Third-Party Libraries Adapted for the OpenHarmony Platform](https://gitcode.com/CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md).

---

<a id="section961487"></a>

## The SDK license agreement is not accepted

**Symptom:**

Log information:

```log
hvigor install success.
> hvigor ERROR: Cause: The SDK license agreement is not accepted.
```

**Cause:**

The ohos project structure is still api11 while the SDK in use is api12, which produces this error.

**Solution:**

Upgrade the ohos project structure to api12.

Steps:

1. DevEco-Studio -> Migrate Assistant -> 5.0.0 -> Migrate
2. DevEco-Studio -> File -> Project Structure -> Compatible SDK -> 5.0.0(12)

---

<a id="section225581"></a>

## Building with flutter build hap --release Resets the versionName Field in app.json

**Symptom:**

Check the `versionName` field in `app.json`; after building with `flutter build hap --release`, the field is reset to `1.0.0`.

**Cause:**

Under the current specification, the build uses the `1.0.0` version number by default.

**Solution:**

Specify `versionName` and `versionCode` in the build command. For details, see [signing-and-release-faq](./signing-and-release-faq.en.md#section380470).

---

<a id="section284801"></a>

## Build Error: The flutter Project and Its Dependent Plugin Projects Are on Different Disks

**Symptom:**

Log information:

```log
ohpm ERROR: Found exception: xxx is not in the same file system as the current project, reached retry limit or non retryable error encountered.
```

**Cause:**

The flutter project and its dependent plugin projects are on different disks, which produces this error.

**Solution:**

In the Windows environment, the flutter project and its dependent plugin projects must be on the same disk.

---

<a id="section769910"></a>

## Note that you need plugins to import files that are not JavaScript

**Symptom:**

Log information:

```log
> hvigor ERROR: Failed :entry:default@CompileArkTS...
> hvigor ERROR: Unexpected token (Note that you need plugins to import files that are not JavaScript)
```

**Cause:**

DevEco Studio was upgraded from a lower version to a higher version, which produces this error.

**Solution:**

Modify the `hvigor-config.json5` configuration file:

```json5
{
  "modelVersion": "5.0.0",
  "dependencies": {
  },
  "properties": {
    "ohos.nativeResolver": false
  }
}
```

---

<a id="section555584"></a>

## DevEco Tool Sync or Run Failure: Plugins Depended On by the New Flutter Template Project and the SDK Are on Different Disks

**Symptom:**

Log information:

```log
> hvigor ERROR: The srcPath is not a relative path: xxxx

* Try the following:
> Make sure the srcPath in the hvigorconfig.ts file of the project is a relative path.
```

**Cause:**

During the build of the new template project, the flutter-hvigor-plugin uses [hvigorConfig.includeNode](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-api#section558816280274) to add third-party library source code as nodes. relativePath cannot generate a relative path across disks, so the [srcPath parameter passed in is an absolute path](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-compiling-and-building-138).

**Solution:**

[Build Error: The flutter Project and Its Dependent Plugin Projects Are on Different Disks](#section284801)
