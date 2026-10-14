# Flutter OH Project Directory Structure

This document describes the directory structure of a Flutter OH project created with `flutter create --platforms ohos` and the responsibilities of its key files, helping developers quickly locate configuration, entry code, and dependency artifacts. It covers app-level configuration, module build configuration, the entry Ability and pages, Impeller rendering configuration, and dependency directories.

## Overall Project Structure

After you run `flutter create --platforms ohos <projectName>`, an `ohos/` directory is generated in the project root directory. The overall structure is as follows:

```
<projectName>/
├── lib/                                # Dart business code (reused across platforms)
├── ohos/                               # OpenHarmony platform code
│   ├── AppScope/                       # App-level configuration
│   │   ├── app.json5                   # App global configuration (bundleName, version, icon)
│   │   └── resources/base/            # App-level resources (string, media)
│   ├── entry/                          # Main entry module
│   │   ├── build-profile.json5         # Module build configuration (apiType, targets)
│   │   ├── hvigorfile.ts               # Module Hvigor build script
│   │   ├── oh-package.json5            # Module dependency configuration
│   │   └── src/
│   │       ├── main/
│   │       │   ├── ets/                # ArkTS code
│   │       │   │   ├── entryability/
│   │       │   │   │   └── EntryAbility.ets               # Entry Ability (extends FlutterAbility)
│   │       │   │   ├── pages/
│   │       │   │   │   └── Index.ets                      # Main page (FlutterPage hosts the view)
│   │       │   │   └── plugins/
│   │       │   │       └── GeneratedPluginRegistrant.ets # Plugin registry (auto-generated; do not edit manually)
│   │       │   ├── module.json5                           # Module configuration (name, type, device types, permissions)
│   │       │   └── resources/base/
│   │       │       ├── element/                           # Resources such as strings and colors
│   │       │       ├── media/                             # Media resources such as icons
│   │       │       └── profile/
│   │       │           ├── buildinfo.json5                # Impeller rendering switch
│   │       │           └── main_pages.json                # Page routing (pages/Index)
│   │       └── ohosTest/                                  # Test code
│   ├── build-profile.json5             # Project build configuration (signingConfigs, products, buildModeSet)
│   ├── hvigorfile.ts                   # Hvigor script (injects flutter-hvigor-plugin)
│   ├── hvigorconfig.ts                 # Hvigor plugin configuration (injectNativeModules injects native modules)
│   ├── oh-package.json5                # Project dependency configuration
│   └── package.json                    # Node dependencies (flutter-hvigor-plugin)
└── pubspec.yaml                        # Flutter dependency configuration
```

> The `@ohos/flutter_ohos` module in `oh_modules/` (generated after a build) is the framework adaptation layer artifact. It contains the implementations of core classes such as `FlutterAbility`, `FlutterEntry`, `FlutterEngine`, and `FlutterView`, and is automatically injected and pulled by `flutter-hvigor-plugin` (see `hvigorfile.ts` and `hvigorconfig.ts`) during the build. No manual management is required.

## Key Configuration Files

| File | Path | Responsibility |
|------|------|------|
| `app.json5` | `ohos/AppScope/app.json5` | App global configuration: `bundleName` (package name), `versionName`, `versionCode`, etc. |
| `build-profile.json5` (project) | `ohos/build-profile.json5` | Project build configuration: signing information (`signingConfigs`), SDK version, and the set of build modes (`buildModeSet`) |
| `build-profile.json5` (module) | `ohos/entry/build-profile.json5` | Module build configuration: target products, compilation parameters, etc. |
| `oh-package.json5` (project) | `ohos/oh-package.json5` | Project dependency and override configuration |
| `oh-package.json5` (module) | `ohos/entry/oh-package.json5` | Module dependencies; declares `@ohos/flutter_ohos` |
| `module.json5` | `ohos/entry/src/main/module.json5` | Module configuration: module name, type (`entry`), `deviceTypes`, and entry Ability |
| `buildinfo.json5` | `ohos/entry/src/main/resources/base/profile/buildinfo.json5` | Rendering engine switch: `enable_impeller` controls the Impeller / Skia toggle |

### app.json5

App-level global configuration. `bundleName` is the unique identifier of the app and must be filled in properly for signing and release:

```json5
{
  "app": {
    "bundleName": "com.example.<projectName>",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0"
  }
}
```

### build-profile.json5

Project build configuration. Signing information is written to `signingConfigs` after automatic signing in DevEco Studio. `buildModeSet` declares the supported build modes; the new template includes three by default: `debug`, `profile`, and `release`:

```json5
{
  "signingConfigs": [ /* Populated after automatic signing */ ],
  "buildModeSet": [
    { "name": "debug" },
    { "name": "profile" },
    { "name": "release" }
  ]
}
```

### oh-package.json5

The module dependency configuration declares `@ohos/flutter_ohos`; after ohpm resolves it, the corresponding `flutter.har` engine artifact is pulled:

```json5
{
  "dependencies": {
    "@ohos/flutter_ohos": "har/flutter.har"
  }
}
```

### buildinfo.json5

Rendering engine configuration, which switches the rendering backend through `enable_impeller`. Impeller is enabled by default in newly created projects:

```json5
{
  "string": [
    {
      "name": "enable_impeller",
      "value": "true"
    }
  ]
}
```

> Set it to `"false"` to use the Skia rendering backend. For the conditions under which the switch takes effect and related precautions, see the [Impeller and Skia Rendering Engine Switching Guide](../rendering-engine/rendering-engine-switching.en.md).

## Entry Code Files

| File | Path | Responsibility |
|------|------|------|
| `EntryAbility.ets` | `ohos/entry/src/main/ets/entryability/EntryAbility.ets` | Entry Ability; extends `FlutterAbility`; the framework automatically creates and manages the `FlutterEngine` and registers plugins |
| `Index.ets` | `ohos/entry/src/main/ets/pages/Index.ets` | Main page; hosts the Flutter rendering content through the `FlutterPage` component |
