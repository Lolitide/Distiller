[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: TouchEventId

Represents a unique identifier corresponding to a touch event.

## Constructors

### Constructor

> **new TouchEventId**(`id`): `TouchEventId`

Constructs a new TouchEventId instance.

#### Parameters

##### id

`number`

The ID value

#### Returns

`TouchEventId`

## Methods

### getId()

> **getId**(): `number`

Gets the ID value.

#### Returns

`number`

The ID value

***

### createUnique()

> `static` **createUnique**(): `TouchEventId`

Creates a unique TouchEventId with an auto-incremented ID.

#### Returns

`TouchEventId`

A new unique TouchEventId instance

***

### from()

> `static` **from**(`id`): `TouchEventId`

Creates a TouchEventId from a given ID.

#### Parameters

##### id

`number`

The ID value

#### Returns

`TouchEventId`

A new TouchEventId instance
