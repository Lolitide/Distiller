[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: LocalizationChannel

Channel for handling localization-related communication between Flutter and OpenHarmony.
This channel manages locale information and string resource retrieval.

## Implements

- [`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

## Constructors

### Constructor

> **new LocalizationChannel**(`dartExecutor`): `LocalizationChannel`

Constructs a new LocalizationChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`LocalizationChannel`

## Methods

### onMethodCall()

> **onMethodCall**(`call`, `result`): `void`

Handles method calls from Dart.

#### Parameters

##### call

`MethodCall`

The method call from Dart

##### result

[`MethodResult`](../../../../../plugin/common/MethodChannel/interfaces/MethodResult.md)

The result callback to send a response

#### Returns

`void`

#### Implementation of

[`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md).[`onMethodCall`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md#onmethodcall)

***

### sendLocales()

> **sendLocales**(`locales`): `void`

Sends locale information to Flutter.

#### Parameters

##### locales

`string`[]

Array of locale strings to send

#### Returns

`void`

***

### setLocalizationMessageHandler()

> **setLocalizationMessageHandler**(`localizationMessageHandler`): `void`

Sets the localization message handler for processing localization requests.

#### Parameters

##### localizationMessageHandler

[`LocalizationMessageHandler`](../interfaces/LocalizationMessageHandler.md)

The LocalizationMessageHandler instance

#### Returns

`void`
