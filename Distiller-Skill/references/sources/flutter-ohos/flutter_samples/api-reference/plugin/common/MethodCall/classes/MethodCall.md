[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: MethodCall

Command object representing a method call on a MethodChannel.

## Constructors

### Constructor

> **new MethodCall**(`method`, `args`): `MethodCall`

Constructs a new MethodCall instance.

#### Parameters

##### method

`string`

The name of the method to call

##### args

`Any`

The arguments for the method call

#### Returns

`MethodCall`

## Properties

### args

> **args**: `Any`

Arguments for the call.

Consider using the argument() method for cases where a particular run-time type is expected.
Consider using argument(key) when that run-time type is Map or Object.

***

### method

> **method**: `string`

The name of the called method.

## Methods

### argument()

> **argument**(`key`): `Any`

Gets an argument value by key.

#### Parameters

##### key

`string`

The argument key

#### Returns

`Any`

The argument value, or null if not found

#### Throws

Error if the args cannot be cast to a Map or Object

***

### hasArgument()

> **hasArgument**(`key`): `boolean`

Checks if an argument exists for the given key.

#### Parameters

##### key

`string`

The argument key to check

#### Returns

`boolean`

True if the argument exists, false otherwise

#### Throws

Error if the args cannot be cast to a Map or Object
