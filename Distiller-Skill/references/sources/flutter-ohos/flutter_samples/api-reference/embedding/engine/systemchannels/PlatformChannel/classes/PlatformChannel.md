[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: PlatformChannel

Channel for handling platform-level communication between Flutter and OpenHarmony.
This channel manages system UI, clipboard, haptic feedback, orientation, and other platform services.

## Constructors

### Constructor

> **new PlatformChannel**(`dartExecutor`, `flutterNapi`): `PlatformChannel`

Constructs a new PlatformChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

##### flutterNapi

`FlutterNapi`

#### Returns

`PlatformChannel`

## Properties

### channel

> **channel**: `MethodChannel`

The MethodChannel for platform-level communication with Flutter.

***

### flutterNapi

> **flutterNapi**: `FlutterNapi`

***

### platformMessageHandler

> **platformMessageHandler**: [`PlatformMessageHandler`](../interfaces/PlatformMessageHandler.md) = `null`

The platform message handler for processing platform requests, or null if not set.

## Methods

### decodeOrientations()

> **decodeOrientations**(`encodedOrientations`): `number`

Decodes orientation strings into OpenHarmony orientation values.

#### Parameters

##### encodedOrientations

`string`[]

Array of encoded orientation strings

#### Returns

`number`

The decoded orientation value

***

### getBrightnessFromValue()

> **getBrightnessFromValue**(`encodedName`): [`Brightness`](../enumerations/Brightness.md)

Gets a Brightness from an encoded name.

#### Parameters

##### encodedName

`string`

The encoded brightness name

#### Returns

[`Brightness`](../enumerations/Brightness.md)

The Brightness

#### Throws

Error if the brightness name is not recognized

***

### getClipboardContentFormatFromValue()

> **getClipboardContentFormatFromValue**(`encodedName`): [`PLAIN_TEXT`](../enumerations/ClipboardContentFormat.md#plain_text)

Gets a ClipboardContentFormat from an encoded name.

#### Parameters

##### encodedName

`string`

The encoded format name

#### Returns

[`PLAIN_TEXT`](../enumerations/ClipboardContentFormat.md#plain_text)

The ClipboardContentFormat, or PLAIN_TEXT if not found

***

### getDeviceOrientationFromValue()

> **getDeviceOrientationFromValue**(`encodedName`): [`DeviceOrientation`](../enumerations/DeviceOrientation.md)

Gets a DeviceOrientation from an encoded name.

#### Parameters

##### encodedName

`string`

The encoded orientation name

#### Returns

[`DeviceOrientation`](../enumerations/DeviceOrientation.md)

The DeviceOrientation

#### Throws

Error if the orientation name is not recognized

***

### getFeedbackTypeFromValue()

> **getFeedbackTypeFromValue**(`encodedName`): [`HapticFeedbackType`](../enumerations/HapticFeedbackType.md)

Gets a HapticFeedbackType from an encoded name.

#### Parameters

##### encodedName

`string`

The encoded feedback type name

#### Returns

[`HapticFeedbackType`](../enumerations/HapticFeedbackType.md)

The HapticFeedbackType, or STANDARD if not found

***

### getScrollActivityFromValue()

> **getScrollActivityFromValue**(`activity`): [`ScrollActivity`](../enumerations/ScrollActivity.md)

Gets a ScrollActivity from an encoded activity string.

#### Parameters

##### activity

`string`

The encoded activity string

#### Returns

[`ScrollActivity`](../enumerations/ScrollActivity.md)

The ScrollActivity

#### Throws

Error if the activity string is not recognized

***

### getSystemUiModeFromValue()

> **getSystemUiModeFromValue**(`encodedName`): [`SystemUiMode`](../enumerations/SystemUiMode.md)

Gets a SystemUiMode from an encoded name.

#### Parameters

##### encodedName

`string`

The encoded mode name

#### Returns

[`SystemUiMode`](../enumerations/SystemUiMode.md)

The SystemUiMode

#### Throws

Error if the mode name is not recognized

***

### getSystemUiOverlayFromValue()

> **getSystemUiOverlayFromValue**(`encodedName`): [`SystemUiOverlay`](../enumerations/SystemUiOverlay.md)

Gets a SystemUiOverlay from an encoded name.

#### Parameters

##### encodedName

`string`

The encoded overlay name

#### Returns

[`SystemUiOverlay`](../enumerations/SystemUiOverlay.md)

The SystemUiOverlay

#### Throws

Error if the overlay name is not recognized

***

### setPlatformMessageHandler()

> **setPlatformMessageHandler**(`platformMessageHandler`): `void`

Sets the platform message handler for processing platform requests.

#### Parameters

##### platformMessageHandler

[`PlatformMessageHandler`](../interfaces/PlatformMessageHandler.md)

The PlatformMessageHandler instance, or null to remove

#### Returns

`void`

***

### systemChromeChanged()

> **systemChromeChanged**(`areOverlaysVisible`): `void`

Notifies Flutter that system chrome overlays have changed.

#### Parameters

##### areOverlaysVisible

`boolean`

Whether system overlays are visible

#### Returns

`void`
