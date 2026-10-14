[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: FlutterEngineProvider

Interface for providing FlutterEngine instances.
Implementations of this interface can provide custom FlutterEngine instances.

## Extended by

- [`Host`](../../FlutterAbilityAndEntryDelegate/interfaces/Host.md)

## Methods

### provideFlutterEngine()

> **provideFlutterEngine**(`context`): `any`

Provides a FlutterEngine instance for the given context.

#### Parameters

##### context

`Context`

The application context

#### Returns

`any`

A FlutterEngine instance, or null if no engine should be provided
