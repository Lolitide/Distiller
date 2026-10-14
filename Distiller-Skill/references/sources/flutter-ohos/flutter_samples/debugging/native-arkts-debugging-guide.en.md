
# OpenHarmony Flutter Native Code Breakpoint Debugging Guide

## I. Prerequisites

- DevEco Studio installed
- A Flutter OH application project created

---

## II. Debugging the ohos Platform Code of the Project

### 1. Open the ohos Directory of the Flutter Project

- Use DevEco Studio to open the **ohos** directory of the Flutter project

  ![image-20260304153524106](../media/getting-started/getting-started-01.png)

- Open the file you want to debug

  ![image-20260304155007948](../media/getting-started/getting-started-02.png)

### 2. Set Breakpoints

- Click to the left of the line number; a red dot indicates a breakpoint

  ![image-20260304155111347](../media/getting-started/getting-started-03.png)

- You can set breakpoints at key locations such as function entries, variable assignments, and event callbacks

### 3. Start Debugging

- Select a real device or an emulator as the run target

  ![image-20260304160606033](../media/getting-started/getting-started-06.png)

- Click the **Debug** button (the green bug icon) on the toolbar

  ![image-20260304155150674](../media/getting-started/getting-started-04.png)

- The project is automatically compiled and deployed; the program pauses automatically when it hits a breakpoint

  ![image-20260304160542535](../media/getting-started/getting-started-05.png) 

---

## III. Debugging the Flutter ohos Platform Cache Code

### 1. Debugging the Flutter SDK ohos Adaptation Layer Cache Code

- Open the Flutter SDK ohos adaptation layer cache path

  Path: `project\ohos\oh_modules\.ohpm\@ohos+flutter_ohos\oh_modules\@ohos\flutter_ohos`

![image-20260304164348899](../media/getting-started/getting-started-07.png)

- Open the SDK cache file you want to debug, then follow step 2 above to debug

### 2. Debugging the Third-Party Library Cache Code Used by the Flutter OH Application

- The ohos adaptation layer cache code of third-party libraries is located under `project\ohos\oh_modules\.ohpm\`

  ![image-20260307183215487](../media/getting-started/getting-started-08.png)

- Open the third-party library code you want to debug, then follow step 2 above to debug

---

## IV. Common Issues and Solutions

1. **Breakpoints not hit**
   - Check whether it is a debug build
   - Confirm that the breakpoint is set on the actual execution path

2. **Cannot step into ArkTS code**
   - Check whether the ArkTS files are correctly compiled and deployed

3. **Debugging lags or crashes**
   - Debugging on a real device is recommended; emulator performance is limited

---

## V. References

- [DevEco Studio ArkTS Debugging Official Documentation](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-debug-arkts)
