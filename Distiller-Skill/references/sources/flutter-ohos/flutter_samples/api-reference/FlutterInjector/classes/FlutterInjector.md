[**Flutter ETS API Documentation v1.0.0**](../../README.md)

***

# Class: FlutterInjector

Singleton holder for Flutter-related main classes.
Manages instances of FlutterLoader and FlutterNapi, providing centralized access to these core Flutter components.

## Methods

### getFlutterLoader()

> **getFlutterLoader**(): `FlutterLoader`

Gets the FlutterLoader instance.

#### Returns

`FlutterLoader`

The FlutterLoader instance

***

### getFlutterNapi()

> **getFlutterNapi**(): `FlutterNapi`

Gets a FlutterNapi instance.
If a preloaded FlutterNapi exists, it is returned and cleared.
Otherwise, a new FlutterNapi instance is created.

#### Returns

`FlutterNapi`

A FlutterNapi instance

***

### getPreloadFlutterNapi()

> **getPreloadFlutterNapi**(): `FlutterNapi`

Creates a preloaded FlutterNapi instance.
This instance will be returned by the next call to getFlutterNapi().
If a preloaded instance already exists, it will be replaced with a new one.

#### Returns

`FlutterNapi`

The newly created preloaded FlutterNapi instance

***

### getInstance()

> `static` **getInstance**(): `FlutterInjector`

Gets the singleton instance of FlutterInjector.

#### Returns

`FlutterInjector`

The FlutterInjector singleton instance
