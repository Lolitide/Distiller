# How to Use the LTPO Feature

## Introduction

> **Version Note:** The LTPO feature is supported since Flutter `3.27.5-ohos-1.0.6`.

The LTPO feature refers to dynamic screen frame rate. When the screen refresh rate is set to "Smart", the application can automatically switch to an appropriate frame rate based on the current scenario.

Current Flutter framework frame rate behavior: when the screen refresh rate is set to "Smart", the frame rate strategy is the same as when the screen refresh rate is set to "High". While a finger is touching the screen, the screen refresh rate is 120 fps; after the finger leaves the screen, the screen refresh rate stays at 120 fps for 3 s; if there is no operation for 3 s, the screen refresh rate drops to 60 fps.

> **Note**: The LTPO feature depends on OpenHarmony API 20. Please verify it on ROMs with API 20 or above.

---

## Adaptation Scenarios

| No. | Scenario |
| ---- | ---- |
| 1 | Custom translation animation |
| 2 | Transition translation animation |
| 3 | Scroll list fling |
| 4 | Carousel |

---

## Prerequisites

| Dependency Order | Dependency | Description |
| ---- | ---- | ---- |
| 1 | [DevEco Studio](#deveco-studio) | IDE tool |
| 2 | [flutter_flutter](#flutter-flutter) | Flutter SDK with the LTPO feature integrated |
| 3 | [LTPO configuration file](#frames-config) | Configure the LTPO feature switch and frame rate strategy |
| 4 | [Matching version requirements](#version-requirement) | Minimum version supported by system capabilities |

---

## Details

### <a id="deveco-studio"></a>DevEco Studio

DevEco Studio needs to be updated to a new version. Click the link below to download the latest DevEco Studio.

Download link: [DevEco Studio](https://developer.huawei.com/consumer/cn/download/deveco-studio)

### <a id="flutter-flutter"></a>flutter_flutter

The LTPO feature is released with flutter_flutter repository versions. Use the `3.27.5-ohos-1.0.6` branch of the flutter_flutter repository for Flutter application development with LTPO functionality.

Repository: [flutter_flutter 3.27.5-ohos-1.0.6](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/3.27.5-ohos-1.0.6)

### <a id="frames-config"></a>LTPO Configuration File

The LTPO configuration file contains the dynamic frame rate switch, the frame rate mapping table for translation animations, and the frame rate mapping tables for scaling and rotation.

| Sub-item | Description | Type |
| ---- | ---- | ---- |
| SWITCH | Dynamic frame rate switch | Integer. 0-off; 1-on |
| TRANSLATE | Frame rate mapping table for translation animations,<br>not recommended to modify the elements in the frame rate mapping table. | Array. Each element consists of a sequence number, minimum speed, maximum speed, and expected frame rate. |
| SCALE | Frame rate mapping table for scaling animations,<br>not recommended to modify the elements in the frame rate mapping table.<br>Not currently implemented | Array. Each element consists of a sequence number, minimum speed, maximum speed, and expected frame rate. |
| ROTATION | Frame rate mapping table for rotation animations,<br>not recommended to modify the elements in the frame rate mapping table.<br>Not currently implemented | Array. Each element consists of a sequence number, minimum speed, maximum speed, and expected frame rate. |

Current frame rate mapping table:

| No. | Minimum Slide Speed | Maximum Slide Speed | Frame Rate |
| ---- | ---- | ---- | ---- |
| 1 | 800 | Infinity | 90 |
| 2 | 77 | 800 | 120 |
| 3 | 46 | 77 | 90 |
| 4 | 10 | 46 | 72 |
| 5 | 0 | 10 | 60 |

> **Note**: The actual screen frame rate is decided by the system.

The configuration file `framesconfig.json` is located in the `src/main/resources/rawfile` directory of the Flutter module in the ArkUI application project, at the same level as `flutter_assets`.

Detailed description:

1. `framesconfig.json` is the LTPO configuration file, in which the enable switch can be configured. It is enabled by default.
2. The configuration file presets frame rate tiers mapped from translation speeds for translation animations, determining the screen refresh rate based on the translation speed of the animation. Modifying the default mapped frame rate tier configuration is not recommended.
3. The configuration file is preset in the template application project and exists by default in newly created Flutter application projects. For existing Flutter application projects, you need to switch to Flutter 3.27 or a later version and manually copy the `framesconfig.json` file to the `ohos/entry/src/main/resources/rawfile` path of the application project.

Its prototype file: [framesconfig.json](https://gitcode.com/CPF-Flutter/flutter_flutter/blob/3.27.5-ohos-1.0.6/packages/flutter_tools/templates/app_shared/ohos.tmpl/entry/src/main/resources/base/profile/framesconfig.json)

### <a id="version-requirement"></a>Matching Version Requirements

Open "Settings", go to "About this device", and check whether the software version is `6.0.0.110 (SP96C00E110R4P8)` or above.

---

## Adaptation Process

**Step 1:** Update the [DevEco Studio](#deveco-studio) IDE tool. Use at least DevEco Studio 6.0.0 Release, which includes the required API 20 interfaces.

**Step 2:** Download the [flutter_flutter](#flutter-flutter) repository with the LTPO feature adapted, and add it to the environment variables.

**Step 3:** Run `flutter doctor -v` in a command line window to confirm that the Flutter path is the flutter_flutter repository with the LTPO feature adapted and that its branch is `3.27.5-ohos-1.0.6` or above, ensuring the application being adapted uses Flutter 3.27.

**Step 4:** Confirm that the LTPO configuration file [framesconfig.json](#frames-config) exists in the application project. For a newly created Flutter application project, the LTPO configuration file exists in the application template by default; for an existing application project, you need to manually copy the `framesconfig.json` file to the `ohos/entry/src/main/resources/rawfile` path of the application project.

**Step 5:** Confirm that the LTPO configuration file enable switch is turned on. Check whether the `SWITCH` option in the `framesconfig.json` file is 1; if not, change it to 1.

---

## Verification Process

1. Check whether the phone version meets the matching version requirements. If it does not match, contact the person in charge to push a system version.
2. The current system applies frame rate strategy management. You need to contact the person in charge to perform a system frame rate strategy cloud push.
3. Enable "Smart" refresh. Go to "Settings" > "Display & brightness" > "Screen refresh rate".
4. Enable "Display refresh rate". Go to "Settings" > "System" > "Developer options", under the Debugging section. Once enabled, two numbers are displayed in the upper left corner: the left one is the refresh-rate tier (expected frame rate), and the right one is the real-time frame rate. Focus mainly on the left number (if only one number is displayed, it is the refresh-rate tier).
5. Open a page with Flutter framework scroll components in the application.
6. Fling the page.
7. Observe the fling process: you can see the display frame rate drop from 120 fps to 90 fps depending on the page sliding speed, and finally drop to 60 fps after the sliding stops. The effect is shown in the images below:

![](../media/rendering-engine/rendering-engine-22.png)
![](../media/rendering-engine/rendering-engine-18.png)
![](../media/rendering-engine/rendering-engine-16.png)

<p align="center"><strong>Figure 1</strong> Frame rate changes during fling (120 → 90 → 60 fps)</p>

- The left number is the refresh-rate tier (expected frame rate); the right number is the real-time frame rate.
- The faster the sliding speed, the higher the tier; the rate drops to 60 fps after sliding stops.
- The actual screen frame rate is decided by the system.

---

## Common Issues

### What if an animation page is not paused after switching to the background, and the screen refresh rate does not drop?

Here are some suggestions:

#### Choose an Appropriate TabController for Tab Pages

There are two ways to create a TabController: one is to use the system's `DefaultTabController`; the other is to define your own `TabController` implementing `SingleTickerProviderStateMixin`.

1. Use `DefaultTabController` with stateless widgets (StatelessWidget).
2. Use `TabController` with stateful widgets (StatefulWidget).

```dart
class TabsPage extends StatefulWidget {
  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      vsync: this,
      length: 3, // Set the number of TabBarView items
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBar(
        controller: _tabController,
        tabs: <Widget>[],
      ),
    );
  }
}
```

#### Stop the Animation on TabView Tab Switching

The `deactivate` lifecycle of a stateful widget (StatefulWidget) is called when the framework removes this State object from the tree. You can stop the `AnimationController` in this `deactivate` lifecycle callback.

If it is an animation repeating on the vsync cycle of `this`, it will play automatically when the page is re-entered, so there is no need to start the animation manually.

```dart
class AnimationPage extends StatefulWidget {
  @override
  State<AnimationPage> createState() => _AnimationPageState();
}

class _AnimationPageState extends State<AnimationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void deactivate() {
    super.deactivate();
    _controller.stop();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..addListener(() {
      setState(() {});
    })..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## References

- Introduction to variable frame rate: [displaysync-overview](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/graphics/displaysync-overview.md)
- Low power design based on LTPO: [bpta-ltpo-description](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-ltpo-description)
- NativeVSync development guide (C/C++): [native-vsync-guidelines](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/graphics/native-vsync-guidelines.md)
- NativeVsync function reference: [capi-native-vsync-h](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkgraphics2d/capi-native-vsync-h.md)
