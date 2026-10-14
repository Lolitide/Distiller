# Signing and Release Issues

<a id="section425680"></a>

## Automatic Signing Error in a Flutter OH Project

**Symptom:**

Automatic signing of a Flutter OH project reports an error in DevEco Studio.

**Cause:**

The bundle name in `AppScope/app.json5` is not compliant, causing automatic signing to fail.

**Solution:**

- Use DevEco Studio to open the ohos directory in the Flutter project.
- Open the `AppScope > app.json5` file and check whether the bundle name is compliant.
- After the bundle name is corrected, sync the project.
- Run `flutter build hap --debug` or `flutter build hap --release` again to build the application.

---

<a id="section380470"></a>

## Running flutter build hap --release Resets the versionName Field in app.json

**Symptom:**

After you check the `versionName` field in `app.json` and then run `flutter build hap --release` to build a package, the field is reset to `1.0.0` again.

**Cause:**

Under the current specification, the default build uses the version number `1.0.0`.

**Solution:**

To specify `versionName` and `versionCode`, you can add the version to the build command:

```shell
flutter build hap --build-name=4.0.3 --build-number=10000
```

---

<a id="section710370"></a>

## Release Build Abnormality (Sudden Exit or Still in Debug Mode)

**Symptom:**

After the application is built with `flutter build hap --release`, one of the following may occur when it is installed and run:

- **Sudden exit on startup:** The debug package can be installed and started normally, while the release package exits immediately on startup after installation.
- **Still in debug mode:** The release package is close to the debug package in size, without an obvious reduction; the application behaves the same as the debug package (for example, it still supports hot reload, and DevTools can still connect).

**Cause:**

The build artifacts actually use the **debug version of `flutter.har`** instead of the release version. Common causes include:

- `Build Mode` in DevEco Studio is not set to `release`
- Debug-mode artifacts remain in the build cache
- After debugging alternately on the emulator and a real device, artifacts of the wrong architecture are cached

**Troubleshooting points:**

- The release package should be significantly smaller than the debug package. Taking a pure Flutter application as the baseline, the release package is about 10%–20% of the debug package in size; if the release package is close to the debug package in size (for example, the release package is greater than 50% of the debug package), the debug version of `flutter.har` was most likely used.

  > Taking a pure application created with Flutter OH 3.27 as a reference:
  >
  > - Debug package: 118M
  > - Release package: 16.5M
  > - The release package is about 14% of the debug package

- If assertion logs such as `SI_TKILL`, `raise+228`, and `abort+20` appear in crash logs, the `flutter.har` in use is the debug version. Assertion logs should not appear in a release build.

- Open `DevEco Studio → Product` and check whether `Build Mode` is `release`:

  ![image-20260316151248895](../media/getting-started/getting-started-09.png)

  <p align="center"><strong>Figure 1</strong> Checking the DevEco Studio Build Mode</p>

**Solution:**

1. In `DevEco Studio → Product`, set `Build Mode` to `release`.

2. Clean the build cache:

```shell
# Clean the Flutter build cache
cd <project>
flutter clean

# Delete the cache in the ohos directory
cd ohos
rm -rf oh_modules

# Delete the cache in the entry directory
cd entry
rm -rf build
rm -rf oh_modules
```

3. Rebuild the release package:

```shell
flutter build hap --release --target-platform ohos-arm64
```

4. Verify the build result:
   - The release package should be significantly smaller than the debug package (pure application reference values: about 118M for debug, about 16.5M for release, that is, release is about 10%–20% of debug).
   - No assertion-related information should appear in crash logs.

For more build guidance, see [Flutter OH App Build and Run Guide](../app-development/flutter-oh-app-build-guide.en.md)

---

<a id="section823290"></a>

## An App Store Release Package Uses the debug Version of flutter.har, Causing Sudden Exit at Runtime

**Symptom:**

The app store release package exits suddenly at runtime.

Log:

```log
#20 at attachToNative (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterNapi.ts:60:1)
#21 at attachToNapi (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:97:1)
#22 at init (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:88:1)
```

**Cause:**

The app store release package uses the debug version of flutter.har, causing sudden exit at runtime.

**Solution:**

Before the app store release, you are advised to rebuild the release version of flutter.har by running the command `flutter build hap --release`.

---

<a id="section433647"></a>

## Permissions and Profile

**Symptom:**

You need to understand the relationship between permissions and the signing Profile.

**Cause:**

Development and debugging and release have different requirements on permission signing: during debugging, permissions can be granted to a temporary signing; during release, permissions must be declared through a release Profile.

**Solution:**

- During development and debugging, permissions can be granted in the temporary signing file.
- To release an application, you need to [apply for a release Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090).
