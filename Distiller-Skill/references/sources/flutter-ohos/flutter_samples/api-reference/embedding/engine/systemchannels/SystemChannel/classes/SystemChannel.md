[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: SystemChannel

System channel for communicating system-level events between OpenHarmony and Flutter.
This channel handles events such as memory pressure warnings.

## Constructors

### Constructor

> **new SystemChannel**(`dartExecutor`): `SystemChannel`

Constructs a new SystemChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

#### Returns

`SystemChannel`

## Properties

### channel

> **channel**: `BasicMessageChannel`\<`object`\>

The BasicMessageChannel for sending system-level messages to Flutter.

## Methods

### sendMemoryPressureWarning()

> **sendMemoryPressureWarning**(): `void`

Sends a memory pressure warning to the Flutter framework.

#### Returns

`void`
