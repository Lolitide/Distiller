# FVM (Flutter Version Management) Usage Guide

FVM (Flutter Version Management) is used to manage multiple Flutter SDK versions on the same development machine. It can lock a Flutter OH branch or tag for each project, and can also install and switch official Flutter SDK versions (such as `stable` and `3.24.0`) at the same time without mutual interference — and without adding `flutter_flutter/bin` to the system `PATH`. This document walks you through the end-to-end process of installing, binding, and running a Flutter OH version with FVM, as well as how to switch to the official community Flutter SDK within a project.

## Prerequisites

- Install Git.
- Complete the [Flutter OH environment setup](./flutter-oh-env-setup.en.md).

## Installing FVM

FVM provides multiple installation methods. Just choose one based on your platform. The platform support and dependencies of each method are as follows:

| Method | Platform | Dependencies |
| --- | --- | --- |
| Official installation script | macOS / Linux | `curl`, `tar` |
| Homebrew | macOS | Homebrew |
| Chocolatey / standalone package from GitHub Releases | Windows | Chocolatey; or download the zip package directly |
| `dart pub global activate` | Cross-platform | An existing Dart SDK |

> Flutter-OH developers usually already have the Dart SDK that comes with Flutter, so `dart pub global activate fvm` works on Windows without installing an extra package manager. It is the easiest path.

> The `fvm fork` subcommand requires a relatively new version of FVM. After installation, run `fvm fork list` to verify; if an unknown-command error is reported, upgrade FVM to the latest version using the methods above before continuing.

**Method 1: Official installation script (macOS/Linux, recommended)**

```sh
curl -fsSL https://fvm.app/install.sh | bash
```

To specify an FVM version:

```sh
curl -fsSL https://fvm.app/install.sh | bash -s -- <version>
```

**Method 2: Homebrew (macOS)**

```sh
brew install fvm
```

**Method 3: Chocolatey or standalone zip package (Windows)**

Install [Chocolatey](https://chocolatey.org) first, and then run:

```powershell
choco install fvm
```

Or download the standalone zip package for your architecture from [FVM GitHub Releases](https://github.com/leoafarias/fvm/releases), extract it, and add its `bin` directory to `PATH`.

**Method 4: Global activation via `dart pub` (cross-platform, recommended on Windows)**

```sh
dart pub global activate fvm
```

When FVM is installed via `dart pub`, you need to add the bin directory of the pub cache to `PATH`. The bin directory is located under the pub cache; **if the `PUB_CACHE` environment variable is set, it takes precedence**:

| Platform | Default bin Directory | If `PUB_CACHE` Is Set |
| --- | --- | --- |
| macOS / Linux | `~/.pub-cache/bin` | `$PUB_CACHE/bin` |
| Windows | `%LOCALAPPDATA%\Pub\Cache\bin` | `%PUB_CACHE%\bin` |

You should be able to find `fvm` (`fvm.bat` on Windows) in this bin directory. After adding it to `PATH`, **reopen the terminal** and run `fvm --version` to verify. If a "command not found" error is reported, the bin directory usually was not added to `PATH` correctly. You can run `which fvm` (macOS/Linux) or `where fvm` (Windows) to troubleshoot.

## Usage Steps

### Step 1: Register Flutter OH as a Fork Alias

FVM registers custom repositories with `fvm fork add <alias> <url>`. Register the Flutter OH source code (`https://gitcode.com/CPF-Flutter/flutter_flutter.git`) as the alias `flutter_ohos`:

```sh
# Register the Flutter OH repository as a fork alias
fvm fork add flutter_ohos https://gitcode.com/CPF-Flutter/flutter_flutter.git
```

- `<alias>` (`flutter_ohos`): a custom alias, referenced as `flutter_ohos/<version>` afterwards.
- `<url>`: the URL of a Git repository, which must end with `.git`.

View the registered forks:

```sh
# View registered forks
fvm fork list
```

### Step 2: Install a Specified Flutter OH Branch or Tag

After registering the alias, you can install any branch or tag just like an official version. For branch selection, see [Flutter-OH Version Evolution Plan and Branch Strategy](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md).

```sh
# Install the dev branch of flutter_ohos
fvm install flutter_ohos/dev
```

After the installation is complete, view the locally installed versions to confirm that `flutter_ohos/dev` is ready:

```sh
# View locally installed versions
fvm list
```

> Branches such as `dev` are continuously updated. To refresh to the latest commit later, simply run `fvm install flutter_ohos/dev` again, and FVM will update the code of the corresponding version in the cache and refresh the symlink.

### Step 3: Bind a Version in the Project

Go to the root directory of the Flutter project and bind the version installed in the previous step:

```sh
# Enter the project directory
cd my_app
# Bind the flutter_ohos/dev version
fvm use flutter_ohos/dev
```

After the command is executed, the following are added to the project root directory:

| Path | Description |
| --- | --- |
| `.fvm/flutter_sdk` | A symlink pointing to the corresponding SDK version in the fvm cache |
| `.fvmrc` | Records the bound version for team sharing |

> `.fvmrc` is intended for team sharing and should be committed to the repository; `.fvm/flutter_sdk` is a local symlink and should be added to `.gitignore`:

```gitignore
.fvm/flutter_sdk
```

> Creating symlinks on Windows requires the corresponding permission: enable Developer Mode in "System Settings → Developer options", or run the terminal as an administrator before executing `fvm use`; otherwise the symlink creation fails.

After pulling the code, team members only need to run `fvm install` in the project root directory, and FVM will automatically pull the version agreed in `.fvmrc` and create the symlink.

### Step 4: Run Flutter Commands

In the project directory where a version is bound, use `fvm flutter <command>` to invoke that version of Flutter:

```sh
# Verify the environment
fvm flutter doctor -v
# Create a project
fvm flutter create --platforms ohos my_app
# Run on a device
fvm flutter run --debug -d <deviceId>
```

> To use the global `flutter` command directly instead of `fvm flutter`, run `fvm global flutter_ohos/dev` to set that version as the global default.

### Step 5 (Optional): Configure the IDE to Use the Locked Version

To let Android Studio / VS Code automatically use the FVM-locked version, point the Flutter SDK path to the in-project symlink `.fvm/flutter_sdk`:

- **VS Code**: add the following to `.vscode/settings.json`:

  ```json
  {
    "dart.flutterSdkPath": ".fvm/flutter_sdk"
  }
  ```

- **Android Studio**: in Preferences → Languages & Frameworks → Flutter, set the SDK path to `<project_path>/.fvm/flutter_sdk`.

- **DevEco Studio**: DevEco Studio is used to open and build the `ohos` module and does not directly read the Flutter SDK path, so no configuration is needed here. Flutter-side commands (`create`/`run`/`build`, etc.) are still invoked via `fvm flutter <command>`; for the process of building in DevEco and installing to devices, see [OpenHarmony Device Running Guide](./openharmony-device-guide.en.md).

`fvm use` attempts to write the VS Code configuration by default; if it does not take effect, set it manually as described above.

## Switching Between Flutter OH and the Official Community Flutter

FVM natively supports the official Flutter channels (`stable`, `beta`, `master`) and any formal release (such as `3.24.0`), which can be installed without registering a fork:

```sh
# Install the official stable channel
fvm install stable
# Install a specified version tag
fvm install 3.24.0
```

Switching the bound version within a project overwrites `.fvmrc` and the `.fvm/flutter_sdk` symlink:

```sh
# Switch to the official stable
fvm use stable
# Switch back to Flutter OH
fvm use flutter_ohos/dev
```

`fvm list` shows the locally installed versions, with official versions and OH versions listed side by side. When switching, just reference them with `fvm use <version>`.

> After switching versions, it is recommended to run `fvm flutter doctor -v` again to confirm the environment. The dependency caches and `pubspec.lock` of OH and official Flutter may differ. If dependency exceptions occur after a cross-version switch, run `fvm flutter pub get` to refresh them.

> To use the official Flutter instead of OH as the global default, run `fvm global stable`; to do the opposite, run `fvm global flutter_ohos/dev`.

> Note the interaction with the section "What If I Want to Use Flutter OH Globally?" below: `fvm config --flutter-url` changes the default pull repository of **all** subsequent `fvm install` commands (including channels such as `stable`/`beta`/`master` and version tags such as `3.24.0`) — FVM enables the git cache by default, and all installations clone from the git cache at that URL. If it has been pointed to the OH repository, restore the default URL before installing official versions: `fvm config --flutter-url https://github.com/flutter/flutter.git`.

## Verification Process

1. Run `fvm --version`. If a version number is printed, FVM is ready.
2. Run `fvm list`. `flutter_ohos/dev` should appear in the list.
3. In the project directory where a version is bound, run `fvm flutter doctor -v`. The Flutter item should be `[✓]`.
4. Check that the project root directory contains the `.fvm/flutter_sdk` symlink and that it points to the directory corresponding to `flutter_ohos/dev` in the fvm cache.

## Common Command Quick Reference

| Command | Description |
| --- | --- |
| `fvm fork add <alias> <url>` | Register a custom Flutter repository alias |
| `fvm fork list` | View registered fork aliases |
| `fvm fork remove <alias>` | Remove a fork alias |
| `fvm install <alias>/<version>` | Install a branch/tag of a specified fork |
| `fvm install stable`, `fvm install <version>` | Install an official Flutter channel or formal version (such as `stable` or `3.24.0`) |
| `fvm use <version>` | Bind a specified version to the current project (generates the `.fvm/` configuration) |
| `fvm use <version> --force` | Force overwrite of the current configuration |
| `fvm list` | View locally installed versions |
| `fvm remove <version>` | Remove a local version |
| `fvm global <version>` | Set a version as the system-wide global default |
| `fvm flutter <command>` | Run a Flutter command with the project-locked version |
| `fvm dart <command>` | Run a dart command with the project-locked version |
| `fvm doctor` | Check the FVM configuration status of the current project and environment |

## FAQ

### Slow or Failed Pulling During `fvm install`?

The OH repository URL (`gitcode.com`) is already a mirror in China, so git pulling is normally fast. If you still encounter problems, troubleshoot by case:

**Case 1: Slow pub dependency download** — set the pub and storage mirrors (these environment variables must be kept long-term):

```sh
# Set pub mirrors
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

**Case 2: Slow or failed git pulling of the repository itself** — you can configure a Git proxy; or manually run `git clone` to put the OH source code into FVM's cache directory (run `fvm list` to view the cache path), name the directory with the `custom_` prefix as described in the FVM documentation, and then reference it with `fvm use custom_<name>`.

### `flutter doctor` Still Reports That Flutter Cannot Be Found After FVM Is Used?

You need to invoke it via `fvm flutter doctor`. To use the global `flutter` command directly, run `fvm global flutter_ohos/dev` to set that version as the global default.

### Does FVM Conflict with the `git clone` Method in the Environment Setup Guide?

No. The two differ only in how the Flutter OH source code is obtained: FVM installs it into a unified cache directory and references it via symlinks, while `git clone` puts it in a directory of your choice. Either one is fine on the same machine, and **it is not recommended to add the `bin` directories of both Flutter installations to `PATH` at the same time**.

### What If I Want to Use Flutter OH Globally?

Just set that version as the global default:

```sh
# Set flutter_ohos/dev as the global default
fvm global flutter_ohos/dev
```

Afterwards, running `flutter` or `dart` directly in any directory uses that OH version, and it does not affect the version locked in projects via `fvm use` (see the `fvm global` note in Step 4).
