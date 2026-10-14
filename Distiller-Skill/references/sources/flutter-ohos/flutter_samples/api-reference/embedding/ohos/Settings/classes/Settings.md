[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: Settings

Manages and sends system settings to Flutter.
This class handles theme mode, text scale factor, and other system preferences.

## Constructors

### Constructor

> **new Settings**(`settingsChannel`): `Settings`

Constructs a new Settings instance.

#### Parameters

##### settingsChannel

`any`

The SettingsChannel instance, or null

#### Returns

`Settings`

## Properties

### settingsChannel

> **settingsChannel**: `any`

The SettingsChannel for sending settings to Flutter, or null if not set.

## Methods

### getTextScaleFactor()

> **getTextScaleFactor**(): `number`

Gets the text scale factor from system settings.

#### Returns

`number`

The text scale factor value

***

### getThemeMode()

> **getThemeMode**(`mediaQuery`): [`PlatformBrightness`](../../../engine/systemchannels/SettingsChannel/enumerations/PlatformBrightness.md)

Gets the current theme mode (light or dark).

#### Parameters

##### mediaQuery

`MediaQuery`

The MediaQuery instance for detecting dark mode

#### Returns

[`PlatformBrightness`](../../../engine/systemchannels/SettingsChannel/enumerations/PlatformBrightness.md)

The platform brightness mode

***

### sendSettings()

> **sendSettings**(`mediaQuery`): `void`

Sends current system settings to Flutter.

#### Parameters

##### mediaQuery

`MediaQuery`

The MediaQuery instance for detecting theme mode

#### Returns

`void`
