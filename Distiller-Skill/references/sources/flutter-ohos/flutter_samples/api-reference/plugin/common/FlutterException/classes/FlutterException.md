[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterException

Exception class for Flutter platform channel errors.
This class represents errors that occur during communication between Flutter and the platform.

## Implements

- `Error`

## Constructors

### Constructor

> **new FlutterException**(`code`, `message`, `details`): `FlutterException`

Constructs a new FlutterException instance.

#### Parameters

##### code

`string`

The error code

##### message

`string`

The error message

##### details

`Any`

Additional error details

#### Returns

`FlutterException`

## Properties

### code

> **code**: `string`

The error code.

***

### details

> **details**: `Any`

Additional error details.

***

### message

> **message**: `string`

The error message.

#### Implementation of

`Error.message`

***

### name

> **name**: `string` = `""`

The error name.

#### Implementation of

`Error.name`

***

### stack?

> `optional` **stack**: `string`

Optional stack trace for the error.

#### Implementation of

`Error.stack`
