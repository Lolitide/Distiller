# OpenHarmony Device Running Guide

This document describes how to compile, install, and run a Flutter OH application on an OpenHarmony device, covering the complete workflow of device connection, project creation, signing configuration, and building, installing, and running.

## Step 1: Connect and Discover the Device

### 1.1 Enter Developer Mode and Enable USB Debugging

Connect a real device to the computer using a USB cable. On the device, go to Settings and tap the version number repeatedly to enter developer mode, then enable USB debugging in Developer options.

### 1.2 Confirm the Device Connection Using hdc

Use `hdc` to confirm that the device is connected:

```bash
hdc list targets
```

The expected output is the device serial number, for example:

```log
700000xxx
```

> If there is no output, check the USB connection and whether debugging mode is enabled, and make sure the SDK `toolchains` directory containing `hdc` has been added to `PATH`.

### 1.3 Confirm Device Recognition Using Flutter

Then use Flutter to confirm that the device has been recognized:

```bash
flutter devices
```

Sample expected output for different device types:

```log
# Phone
9CN0123608000xxx (mobile) • 9CN0123608000xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26

# Tablet
ABC0123456789xxx (tablet) • ABC0123456789xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26

# PC/2-in-1
DEF0123456789xxx (desktop) • DEF0123456789xxx • ohos-arm64 • Ohos OpenHarmony-6.1.0.26
```

## Step 2: Create a Flutter Project

```bash
# Option 1: Create a project with only the ohos platform
flutter create --platforms ohos <projectName>

# Option 2: Create a multi-platform project covering android, ios, and ohos
flutter create <projectName>
```

After creation, an `ohos/` directory is generated in the project root directory, containing OpenHarmony project files such as `entry/`, `AppScope/`, and `build-profile.json5`.

## Step 3: Configure Target Device Types (module.json5)

An OpenHarmony project declares the device types supported by the application through the `deviceTypes` field in `module.json5`. A newly created project contains only `phone` by default. To run on a tablet or PC, you need to manually add the corresponding device type.

File path: `<projectName>/ohos/entry/src/main/module.json5`

`deviceTypes` values for different device types:

| Device Type       | deviceTypes |
| -------------- | ----------------- |
| Phone/foldable       | `phone`           |
| Tablet           | `tablet`          |
| PC/2-in-1      | `2in1`            |

To support all devices at the same time, configure `deviceTypes` as follows:

```json5
{
  "module": {
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ]
  }
}
```

## Step 4: Configure Signing

Before running on a real device, you need to sign the project:

1. Open the `<projectName>/ohos` directory in **DevEco Studio**.
2. Choose **File → Project Structure → Project → SigningConfigs**.
3. Select **Automatically generate signature** to generate the signature automatically.
4. Click **OK** to save.

## Step 5: Build a HAP Package

Go to the project root directory and choose a build mode as needed:

```bash
cd <projectName>

# Debug build (supports hot reload; for daily development and debugging)
flutter build hap --debug

# Release build (AOT compilation, smallest size; for official release)
flutter build hap --release
```

The build artifacts are located in the `<projectName>/build/ohos/hap/` directory:

| Signing Status | Artifact File Name                   |
| -------- | ---------------------------- |
| Signed   | `entry-default-signed.hap`   |
| Unsigned   | `entry-default-unsigned.hap` |

## Step 6: Install and Run on a Real Device

Choose any one of the following methods to deploy the application to the device:

**Option 1: Run directly (recommended; the most convenient for development and debugging)**

There is no need to manually build a HAP. Use `flutter run` directly to compile, install, and launch:

```bash
# Run in debug mode
flutter run --debug -d <deviceId>

# Run in release mode
flutter run --release -d <deviceId>
```

**Option 2: Manually install the HAP package**

First build the HAP package as described in Step 5, then install it using `hdc`:

```bash
hdc -t <deviceId> install <projectName>/build/ohos/hap/entry-default-signed.hap
```

After the installation is complete, tap the application icon on the device home screen to launch it, or start it with the following command:

```bash
hdc shell aa start -a EntryAbility -b <bundleName>
```

**Option 3: Run using DevEco Studio**

Open the `ohos` directory in DevEco Studio, select the connected real device in the device list, and click the run button. DevEco Studio then compiles, installs, and launches the application automatically.
