[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: PlatformPlugin

Plugin for handling platform-specific functionality in Flutter applications.
This class manages system UI, clipboard, haptic feedback, and other platform services.

## Constructors

### Constructor

> **new PlatformPlugin**(`platformChannel`, `context`, `platformPluginDelegate?`): `PlatformPlugin`

Constructs a new PlatformPlugin instance.

#### Parameters

##### platformChannel

`PlatformChannel`

The PlatformChannel for communication with Flutter.

##### context

`Context`

The application context.

##### platformPluginDelegate?

[`PlatformPluginDelegate`](../interfaces/PlatformPluginDelegate.md)

Optional delegate for platform-specific behavior.

#### Returns

`PlatformPlugin`

## Properties

### callback

> **callback**: [`PlatformPluginCallback`](PlatformPluginCallback.md)

The callback handler for platform messages.

## Methods

### destroy()

> **destroy**(): `void`

Destroys the platform plugin and cleans up resources.

#### Returns

`void`

***

### initWindow()

> **initWindow**(): `void`

Initializes the window references for system UI management.

#### Returns

`void`

***

### setFlutterView()

> **setFlutterView**(`flutterView`): `void`

Binds a FlutterView to this plugin.

#### Parameters

##### flutterView

[`FlutterView`](../../../view/FlutterView/classes/FlutterView.md)

The FlutterView instance

#### Returns

`void`

***

### setSystemChromeChangeListener()

> **setSystemChromeChangeListener**(): `void`

Sets up a listener for system configuration changes.

#### Returns

`void`

***

### setUIAbilityContext()

> **setUIAbilityContext**(`context`): `void`

Sets the UIAbility context for platform operations.

#### Parameters

##### context

`UIAbilityContext`

The UIAbility context

#### Returns

`void`

***

### updateSystemUiOverlays()

> **updateSystemUiOverlays**(): `void`

Updates the system UI overlays (status bar and navigation bar) visibility.

#### Returns

`void`
