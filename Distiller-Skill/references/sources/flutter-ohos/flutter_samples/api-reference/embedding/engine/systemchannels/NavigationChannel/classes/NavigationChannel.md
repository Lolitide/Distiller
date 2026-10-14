[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: NavigationChannel

Channel for handling navigation-related communication between Flutter and OpenHarmony.
This channel manages route navigation, including setting initial routes, pushing routes,
and popping routes.

## Constructors

### Constructor

> **new NavigationChannel**(`dartExecutor`, `context?`): `NavigationChannel`

Constructs a new NavigationChannel instance.

#### Parameters

##### dartExecutor

`DartExecutor`

The DartExecutor for sending messages to Dart

##### context?

`Context`

The application context

#### Returns

`NavigationChannel`

## Methods

### popRoute()

> **popRoute**(): `void`

Pops the current route from the navigation stack.

#### Returns

`void`

***

### pushRoute()

> **pushRoute**(`route`): `void`

Pushes a new route onto the navigation stack.

#### Parameters

##### route

`string`

The route string to push

#### Returns

`void`

***

### pushRouteInformation()

> **pushRouteInformation**(`route`): `void`

Pushes route information onto the navigation stack.

#### Parameters

##### route

`string`

The route information string to push

#### Returns

`void`

***

### setInitialRoute()

> **setInitialRoute**(`initialRoute`): `void`

Sets the initial route for navigation.

#### Parameters

##### initialRoute

`string`

The initial route string

#### Returns

`void`

***

### setMethodCallHandler()

> **setMethodCallHandler**(`handler`): `void`

Sets a custom method call handler for navigation events.

#### Parameters

##### handler

[`MethodCallHandler`](../../../../../plugin/common/MethodChannel/interfaces/MethodCallHandler.md)

The MethodCallHandler to handle navigation method calls

#### Returns

`void`
