[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: PlatformPluginCallback

Callback implementation for handling platform messages from Flutter.

## Implements

- [`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md)

## Constructors

### Constructor

> **new PlatformPluginCallback**(): `PlatformPluginCallback`

#### Returns

`PlatformPluginCallback`

## Properties

### applicationContext

> **applicationContext**: `any` = `null`

The application context.

***

### callbackId

> **callbackId**: `number` = `null`

The callback ID for system configuration changes.

***

### context

> **context**: `any` = `null`

The application context.

***

### currentTheme

> **currentTheme**: [`SystemChromeStyle`](../../../embedding/engine/systemchannels/PlatformChannel/classes/SystemChromeStyle.md) = `null`

The current system UI theme style.

***

### flutterView

> **flutterView**: [`FlutterView`](../../../view/FlutterView/classes/FlutterView.md) = `null`

The FlutterView instance for padding control.

***

### lastWindow

> **lastWindow**: `any` = `null`

The last window reference.

***

### mainWindow

> **mainWindow**: `any` = `null`

The main window for system UI operations.

***

### platform

> **platform**: [`PlatformPlugin`](PlatformPlugin.md) = `null`

The PlatformPlugin instance this callback is associated with.

***

### platformChannel

> **platformChannel**: `any` = `null`

The PlatformChannel for communication with Flutter.

***

### platformPluginDelegate

> **platformPluginDelegate**: [`PlatformPluginDelegate`](../interfaces/PlatformPluginDelegate.md) = `null`

The delegate for platform-specific behavior.

***

### showBarOrNavigation

> **showBarOrNavigation**: (`"status"` \| `"navigation"`)[]

Array indicating which system bars should be shown ('status' and/or 'navigation').

***

### uiAbilityContext

> **uiAbilityContext**: `any` = `null`

The UIAbility context for platform operations.

## Methods

### clipboardHasStrings()

> **clipboardHasStrings**(): `boolean`

Checks if the clipboard contains string data.

#### Returns

`boolean`

True if clipboard has strings, false otherwise

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`clipboardHasStrings`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#clipboardhasstrings)

***

### getClipboardData()

> **getClipboardData**(`result`): `void`

Gets data from the system clipboard.

#### Parameters

##### result

[`MethodResult`](../../common/MethodChannel/interfaces/MethodResult.md)

The method result callback.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`getClipboardData`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#getclipboarddata)

***

### playSystemSound()

> **playSystemSound**(`soundType`): `void`

Plays a system sound.

#### Parameters

##### soundType

[`SoundType`](../../../embedding/engine/systemchannels/PlatformChannel/enumerations/SoundType.md)

The type of sound to play.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`playSystemSound`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#playsystemsound)

***

### popSystemNavigator()

> **popSystemNavigator**(): `void`

Pops the system navigator (goes back in navigation stack).

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`popSystemNavigator`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#popsystemnavigator)

***

### restoreSystemUiOverlays()

> **restoreSystemUiOverlays**(): `void`

Restores the system UI overlays to their previous state.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`restoreSystemUiOverlays`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#restoresystemuioverlays)

***

### setApplicationSwitcherDescription()

> **setApplicationSwitcherDescription**(`description`): `void`

Sets the application switcher description (mission label).

#### Parameters

##### description

[`AppSwitcherDescription`](../../../embedding/engine/systemchannels/PlatformChannel/classes/AppSwitcherDescription.md)

The app switcher description.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`setApplicationSwitcherDescription`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#setapplicationswitcherdescription)

***

### setClipboardData()

> **setClipboardData**(`text`, `result`): `void`

Sets data to the system clipboard.

#### Parameters

##### text

`string`

The text to set

##### result

[`MethodResult`](../../common/MethodChannel/interfaces/MethodResult.md)

The method result callback

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`setClipboardData`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#setclipboarddata)

***

### setPreferredOrientations()

> **setPreferredOrientations**(`ohosOrientation`, `result`): `void`

Sets the preferred screen orientation.

#### Parameters

##### ohosOrientation

`number`

The orientation value.

##### result

[`MethodResult`](../../common/MethodChannel/interfaces/MethodResult.md)

The method result callback.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`setPreferredOrientations`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#setpreferredorientations)

***

### setSystemChromeEnabledSystemUIMode()

> **setSystemChromeEnabledSystemUIMode**(`mode`): `void`

Sets the system UI mode (fullscreen, immersive, etc.).

#### Parameters

##### mode

[`SystemUiMode`](../../../embedding/engine/systemchannels/PlatformChannel/enumerations/SystemUiMode.md)

The system UI mode to set

#### Returns

`void`

***

### setSystemChromeEnabledSystemUIOverlays()

> **setSystemChromeEnabledSystemUIOverlays**(`overlays`): `void`

Sets which system UI overlays should be enabled.

#### Parameters

##### overlays

[`SystemUiOverlay`](../../../embedding/engine/systemchannels/PlatformChannel/enumerations/SystemUiOverlay.md)[]

Array of overlays to enable

#### Returns

`void`

***

### setSystemChromeSystemUIOverlayStyle()

> **setSystemChromeSystemUIOverlayStyle**(`systemChromeStyle`): `void`

Sets the system UI overlay style with colors and brightness.

#### Parameters

##### systemChromeStyle

[`SystemChromeStyle`](../../../embedding/engine/systemchannels/PlatformChannel/classes/SystemChromeStyle.md)

The style configuration

#### Returns

`void`

***

### setSystemUiChangeListener()

> **setSystemUiChangeListener**(): `void`

Sets up a listener for system UI changes.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`setSystemUiChangeListener`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#setsystemuichangelistener)

***

### setSystemUiOverlayStyle()

> **setSystemUiOverlayStyle**(`systemUiOverlayStyle`): `void`

Sets the system UI overlay style (colors, brightness, etc.).

#### Parameters

##### systemUiOverlayStyle

[`SystemChromeStyle`](../../../embedding/engine/systemchannels/PlatformChannel/classes/SystemChromeStyle.md)

The style to apply.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`setSystemUiOverlayStyle`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#setsystemuioverlaystyle)

***

### shouldHideWindowDecor()

> **shouldHideWindowDecor**(): `boolean`

Determines whether to hide window decoration based on system UI overlay settings.

#### Returns

`boolean`

True to hide window decoration, false to show it

***

### showSystemOverlays()

> **showSystemOverlays**(`overlays`): `void`

Shows the specified system UI overlays.

#### Parameters

##### overlays

[`SystemUiOverlay`](../../../embedding/engine/systemchannels/PlatformChannel/enumerations/SystemUiOverlay.md)[]

Array of overlays to show.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`showSystemOverlays`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#showsystemoverlays)

***

### showSystemUiMode()

> **showSystemUiMode**(`mode`): `void`

Sets the system UI mode.

#### Parameters

##### mode

[`SystemUiMode`](../../../embedding/engine/systemchannels/PlatformChannel/enumerations/SystemUiMode.md)

The system UI mode to set.

#### Returns

`void`

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`showSystemUiMode`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#showsystemuimode)

***

### vibrateHapticFeedback()

> **vibrateHapticFeedback**(`feedbackType`): `Promise`\<`void`\>

Triggers haptic feedback vibration.

#### Parameters

##### feedbackType

[`HapticFeedbackType`](../../../embedding/engine/systemchannels/PlatformChannel/enumerations/HapticFeedbackType.md)

The type of haptic feedback

#### Returns

`Promise`\<`void`\>

#### Implementation of

[`PlatformMessageHandler`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md).[`vibrateHapticFeedback`](../../../embedding/engine/systemchannels/PlatformChannel/interfaces/PlatformMessageHandler.md#vibratehapticfeedback)
