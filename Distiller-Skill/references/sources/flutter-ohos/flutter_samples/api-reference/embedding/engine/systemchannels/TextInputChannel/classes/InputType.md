[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: InputType

A text input type.

## Constructors

### Constructor

> **new InputType**(`type`, `isSigned`, `isDecimal`): `InputType`

Constructs a new InputType instance.

#### Parameters

##### type

`TextInputType`

The text input type

##### isSigned

`boolean`

Whether the input is signed

##### isDecimal

`boolean`

Whether the input is decimal

#### Returns

`InputType`

## Properties

### isDecimal

> **isDecimal**: `boolean`

Whether the input accepts decimal numbers.

***

### isSigned

> **isSigned**: `boolean`

Whether the input accepts signed numbers.

***

### type

> **type**: `TextInputType`

The text input type.

## Methods

### fromJson()

> `static` **fromJson**(`json`): `InputType`

Creates an InputType instance from JSON.

#### Parameters

##### json

`Any`

The JSON object

#### Returns

`InputType`

A new InputType instance

#### Throws

Error if the input type is not recognized
