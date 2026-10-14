[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: FlutterEngineConfigurator

Interface for configuring FlutterEngine instances.
Implementations can customize engine setup and cleanup.

## Extended by

- [`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md)

## Properties

### cleanUpFlutterEngine()

> **cleanUpFlutterEngine**: (`flutterEngine`) => `void`

Cleans up a FlutterEngine instance.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine to clean up

#### Returns

`void`

***

### configureFlutterEngine()

> **configureFlutterEngine**: (`flutterEngine`) => `void`

Configures a FlutterEngine instance.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine to configure

#### Returns

`void`
