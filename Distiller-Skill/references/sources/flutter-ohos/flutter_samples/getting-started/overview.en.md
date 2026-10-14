# Framework Introduction

## What Flutter is

Flutter is Google’s open-source UI toolkit for building high-performance apps from a single codebase. You use **Dart** and **Widgets** to describe UI and logic, and target platforms such as iOS, Android, Windows, macOS, and Linux. **Hybrid development** with native code on each platform is supported. Flutter is widely adopted and fully open source.

For the canonical description, see [Flutter documentation](https://docs.flutter.dev).

## Flutter on OpenHarmony (Flutter OH)

Beyond Google’s officially listed targets, **Flutter has been ported and productized for OpenHarmony**, often referred to as **Flutter OH** or **OpenHarmony Flutter**. In this form you can:

- **Keep the Flutter app model**: Dart, widgets, `pub` packages, and familiar dev workflows such as hot reload/debugging (subject to the toolchain version you use).
- **Build and run on OpenHarmony**: Use the extended build outputs (e.g. HAR-related artifacts) and host integration to deploy Flutter modules on OpenHarmony devices or emulators.
- **Work with native code**: Embed Flutter pages or modules in OpenHarmony apps (ArkUI / Stage model, etc.), talk to native via **Platform Channels**, **Platform Views**, **multiple engines**, and integrate third-party plugins as needed.

So the **same Flutter stack** is **extended to the OpenHarmony ecosystem** through an adaptation layer and tooling, letting you reuse existing Flutter assets or build hybrid apps from scratch on OpenHarmony devices.

> Note: Engine builds, SDKs, and OpenHarmony-specific flows are maintained by the adaptation community and companion repos. **Upstream Flutter remains defined by Google’s docs**; see the release wiki below for platform differences, schedules, and branches.

## Where this fits in this doc set

- Overall capabilities and layered design: [Flutter OH architecture](../getting-started/architecture.en.md)
- Environment, devices, and build preparation: [Environment setup](../getting-started/README.en.md) and the [OpenHarmony Flutter environment guide](../getting-started/flutter-oh-env-setup.en.md)
- Embedding, channels, performance, FAQ: [Chinese documentation index](../README.md) · [English entry list](../README.en.md)

## Further reading

- [Flutter architectural overview](https://docs.flutter.dev/resources/architectural-overview) (general architecture; read it alongside the OpenHarmony adaptation layer)
- [Flutter OH release notes and branching strategy](https://gitcode.com/CPF-Flutter/flutter_flutter/wiki/Flutter-OH%E7%89%88%E6%9C%AC%E6%BC%94%E8%BF%9B%E8%A7%84%E5%88%92%E5%92%8C%E5%88%86%E6%94%AF%E7%AD%96%E7%95%A5.md) (OpenHarmony adaptation evolution)
