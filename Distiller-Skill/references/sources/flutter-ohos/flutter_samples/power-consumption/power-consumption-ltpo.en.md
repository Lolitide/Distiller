# LTPO Load Reduction Solution

In the OpenHarmony system, the screen refresh rate follows a multi-tier strategy. The LTPO solution in Flutter mainly applies to the "smart" refresh mode: when the user is stationary, idle, or in a low-interaction state, the system prioritizes keeping a lower refresh frequency; when interactions such as scrolling, animations, or flings occur, the app can dynamically raise the frame rate according to the current speed and scene, balancing fluency and power consumption.

---

## Power Consumption Testing Tools

To verify the load reduction effect of LTPO, it is recommended to test with the following tools and methods:

### 1. System Display Settings

Open "Settings" > "Display & brightness" > "Screen refresh rate", and switch the screen refresh rate to "Smart".


### 2. Refresh Rate Display in Developer Options

Open "Settings" > "System" > "Developer options", and enable "Show refresh rate".

Once enabled, two numbers are displayed in the upper-left corner of the screen:

- Left number: target frame rate tier (expected frame rate);
- Right number: real-time frame rate.

By watching the left number, developers can quickly determine whether LTPO is currently lowering or raising the refresh rate as expected.

### 3. Power Consumption Observation Suggestions

Evaluate the power consumption gains with the following methods:

- Compare the frame rate distribution of static pages and scrolling pages under the smart refresh mode;
- Compare system power consumption and heat under "High refresh rate" versus "Smart refresh rate";
- Check whether pages involving list flings, carousels, or Tab switches quickly fall back to 60fps after going idle;
- Verify that animations and interactions still deliver high-frame-rate feedback while the user is interacting.

<!-- TODO: images need to be migrated from media/rendering-engine/ to media/power-consumption/ -->
![](../media/rendering-engine/rendering-engine-22.png)
![](../media/rendering-engine/rendering-engine-18.png)
![](../media/rendering-engine/rendering-engine-16.png)

<p align="center"><strong>Figure 1</strong> Schematic of the frame rate changing with interaction state in smart refresh mode</p>

---

## Usage Scenarios

The LTPO load reduction solution applies to typical scenarios that must balance fluency and low power consumption, and is especially suitable for the following pages and interaction styles:

| Scenario | Adaptation Value | Typical Behavior |
| --- | --- | --- |
| Custom translation animations | Animations stay smooth while dropping to a low-power frame rate when idle | Up to 90fps/120fps while swiping, falling back to 60fps after stopping |
| Transition translation animations | Sufficient frame rate guarantee during page switches, lower power consumption while statically resting | Smooth during page switches, switches back to a low frame rate in background/idle |
| Scrolling list flings | Frame rate raised in real time during flings, quick fallback after the finger lifts | 120fps → 90fps → 60fps decaying with speed |

Typical timings where this applies include:

- When a page is in the background or inactive, animations should not keep consuming high-refresh-rate resources;
- After the user finishes interacting with a page, the system should drop back to a reasonable low-power frame rate as soon as possible;
- Areas displayed statically for long periods do not need to maintain a high refresh frequency.

### Adaptation Dependencies

#### DevEco Studio

Before using the LTPO feature, it is recommended to upgrade to a version that supports API 20, ensuring the build and runtime environment can access the latest display synchronization capabilities and system interface support.

#### flutter_flutter

The LTPO feature depends on the version adaptation capability in the Flutter SDK repository. It is recommended to use a Flutter branch that supports LTPO, ensuring the dynamic frame rate capability and the platform adaptation logic are integrated. For Flutter upgrades, refer to the [upgrade guide](../version/flutter-oh-upgrade-guide.en.md).

### Details

#### LTPO Load Reduction Principle

The core idea of the LTPO load reduction solution is "demand-driven refresh":

- When a page is in a stable view, drop to a lower frame rate tier;
- When interactions such as scrolling, dragging, animations, or flings occur on the page, raise the target frame rate;
- After the interaction ends, fall back to 60fps or lower as soon as possible.

This allows Flutter on the OpenHarmony platform to maintain lower average power consumption without sacrificing responsiveness and visual consistency during interactions.

Typically, LTPO decides the target frame rate for animation and scrolling perception through "speed voting". A higher speed means the page content is moving quickly and the user cares more about motion continuity, so the frame rate is raised; a lower speed means the page is closer to static, and the frame rate can drop to reduce meaningless rendering.

#### Implementation in Flutter

In Flutter, LTPO involves three types of key behaviors:

1. Refresh rate awareness: the app or system can sense the current screen refresh rate mode;
2. Frame rate voting: animation and scrolling events select an appropriate target frame rate tier based on speed;
3. VSync coordination: by working with the platform's display synchronization mechanism, the target frame rate is aligned with the actual display refresh.

This logic resides in the Flutter runtime and the OpenHarmony adaptation layer, where `VsyncWaiterOHOS`, `NativeVsyncChannel`, and the LTPO switch check are the core pieces. Developers usually do not need to modify these underlying implementations directly, but must confirm that the Flutter SDK in use already includes this capability.

#### LTPO Configuration File Description

The core configuration file for LTPO is `framesconfig.json`. It is stored in the `src/main/resources/rawfile` directory of the Flutter module in an ArkUI app project, at the same level as `flutter_assets`.

Adapting this feature does not mandatorily depend on the configuration file; it is enabled by default and available after upgrading to the corresponding version. To disable this feature, developers can add the configuration file and set the `SWITCH` item to `0` to turn it off.

Configuration items include:

| Item | Description | Type |
| --- | --- | --- |
| SWITCH | Dynamic frame rate switch; 0 means off, 1 means on | Integer |
| TRANSLATE | Frame rate mapping table for translation animations | Array |
| SCALE | Frame rate mapping table for scale animations | Array |
| ROTATION | Frame rate mapping table for rotation animations | Array |

Current default frame rate mapping table:

| No. | Minimum Swipe Speed | Maximum Swipe Speed | Frame Rate |
| --- | --- | --- | --- |
| 1 | 800 | Unlimited | 90 |
| 2 | 77 | 800 | 120 |
| 3 | 46 | 77 | 90 |
| 4 | 10 | 46 | 72 |
| 5 | 0 | 10 | 60 |

> **Note**: The final actual screen frame rate is still decided by the system and is not entirely fixed by the configuration table.

Example structure:

```json
{
  "SWITCH": 1,
  "TRANSLATE": [
    { "serial_number": 1, "min": 800, "max": -1, "preferred_fps": 90 },
    { "serial_number": 2, "min": 77, "max": 800, "preferred_fps": 120 },
    { "serial_number": 3, "min": 46, "max": 77, "preferred_fps": 90 },
    { "serial_number": 4, "min": 10, "max": 46, "preferred_fps": 72 },
    { "serial_number": 5, "min": 0, "max": 10, "preferred_fps": 60 }
  ]
}
```

If the app project is newly created, the template usually already carries this file; if the project already exists and requires custom configuration, you need to manually copy it to:

    ohos/entry/src/main/resources/rawfile/framesconfig.json

#### Power Consumption Testing Tools and Observation Methods

To evaluate the actual power consumption gains, complete the following checks on the device:

- Turn on "Smart" refresh;
- Enable "Show refresh rate";
- Fling on a scrolling list page;
- Watch the frame rate gradually drop from `120fps`, finally settling at `60fps` after the page stops;
- Compare heat, battery drain, and experience differences on the same page between "High refresh rate mode" and "Smart mode".

Such verification confirms both whether LTPO takes effect and whether it reduces load at the right moments.

#### Adaptation Process

1. Update DevEco Studio to a version that supports API 20, ensuring all required system capabilities are in place.
2. Download the `flutter_flutter` repository adapted with the LTPO feature, and set it in the environment variables.
3. Run `flutter doctor -v` on the command line to confirm that both the current Flutter path and branch are versions that include LTPO.
4. For custom configuration, confirm in the app project that the `framesconfig.json` file exists at the `ohos/entry/src/main/resources/rawfile` path.
5. Check whether `SWITCH` is `1`; if not, change it to `1`.
6. On the device, open "Settings" > "Display & brightness" > "Screen refresh rate", and switch to "Smart".
7. In the app, open a page with scrolling, animation, or paging logic, and verify that the frame rate changes with the interaction state.

#### Verification Process

1. Check whether the device system version meets the requirements for running LTPO.
2. Confirm that the device has the corresponding display capabilities and policy control permissions; if not, contact the platform contact person to synchronize the system version and policy configuration.
3. Turn on "Smart" refresh, and confirm that the page delivers high-frame-rate feedback during interactions.
4. While flinging or scrolling the page, observe whether the target frame rate tier shown on the left gradually falls back from a higher value.
5. After the interaction stops, observe whether the system falls back to 60fps within about 3 seconds or less.
6. Compare the experience, heat, and power consumption of different pages under high refresh versus smart refresh.

---

## Summary

Flutter's LTPO load reduction solution establishes a coordination layer between OpenHarmony's smart refresh capability and Flutter's animation/scrolling speed awareness. The core problem it solves is not "whether a higher refresh rate is needed", but "which periods deserve sustained high refresh rates, and which periods should promptly fall back to low refresh rates".

This solution is most valuable for the following types of apps:

- Pages with long-duration static content display;
- Frequently scrolled lists;
- App home pages and transition pages with many animations;
- Scenarios that need to strike a balance between reliable experience and low power consumption.

If developers integrate LTPO correctly and combine it with proper page lifecycle control and animation strategies, they can significantly reduce the power consumption caused by meaningless refreshes while keeping interactions smooth.

---

## Sample Code

### Configuration File Example

```json
{
  "SWITCH": 1,
  "TRANSLATE": [
    { "serial_number": 1, "min": 800, "max": -1, "preferred_fps": 90 },
    { "serial_number": 2, "min": 77, "max": 800, "preferred_fps": 120 },
    { "serial_number": 3, "min": 46, "max": 77, "preferred_fps": 90 },
    { "serial_number": 4, "min": 10, "max": 46, "preferred_fps": 72 },
    { "serial_number": 5, "min": 0, "max": 10, "preferred_fps": 60 }
  ]
}
```

> For the latest changes to this document, see [repository link](https://gitcode.com/CPF-Flutter/flutter_samples/blob/master/docs/ohos/power-consumption/power-consumption-ltpo.md)
