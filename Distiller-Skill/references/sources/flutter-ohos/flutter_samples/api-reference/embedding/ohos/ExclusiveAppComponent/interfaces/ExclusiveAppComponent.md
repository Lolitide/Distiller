[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: ExclusiveAppComponent\<T\>

Interface for app components that exclusively attach to a FlutterEngine.

## Type Parameters

### T

`T`

The type of the underlying app component

## Methods

### detachFromFlutterEngine()

> **detachFromFlutterEngine**(): `void`

Called when another App Component is about to become attached to the
FlutterEngine this App Component is currently attached to.

This App Component's connections to the FlutterEngine
are still valid at the moment of this call.

#### Returns

`void`

***

### getAppComponent()

> **getAppComponent**(): `T`

Retrieves the App Component behind this exclusive App Component.

#### Returns

`T`

The app component
