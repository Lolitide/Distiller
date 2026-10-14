[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: SettingsChannel

Channel for sending system settings to Flutter.
This channel manages settings such as text scale factor, platform brightness, and other system preferences.

## Constructors

### Constructor

> **new SettingsChannel**(`dartExecutor`): `SettingsChannel`

Constructs a new SettingsChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`SettingsChannel`

## Methods

### startMessage()

> **startMessage**(): `MessageBuilder`

Starts building a settings message.

#### Returns

`MessageBuilder`

A MessageBuilder instance for constructing the settings message
