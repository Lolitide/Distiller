[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: KeyData

Represents key event data for communication between OpenHarmony and Flutter.
This class can serialize and deserialize key data to/from binary format.

## Constructors

### Constructor

> **new KeyData**(`buffer?`): `KeyData`

Constructs a new KeyData instance.

#### Parameters

##### buffer?

`ArrayBuffer`

Optional ArrayBuffer to deserialize key data from

#### Returns

`KeyData`

## Properties

### character

> **character**: `string` = `null`

Character representation of the key, or null if not applicable.

***

### deviceType

> **deviceType**: [`DeviceType`](../enumerations/DeviceType.md) = `DeviceType.KKEYBOARD`

Type of the input device.

***

### isSynthesized

> **isSynthesized**: `boolean` = `false`

Whether this key event was synthesized.

***

### logicalKey

> **logicalKey**: `number` = `0`

Logical key code.

***

### physicalKey

> **physicalKey**: `number` = `0`

Physical key code.

***

### timestamp

> **timestamp**: `number` = `0`

Timestamp of the key event.

***

### type

> **type**: [`Type`](../enumerations/Type.md) = `Type.KDOWN`

Type of the key event (KDOWN, KUP, or KREPEAT).

***

### CHANNEL

> `static` **CHANNEL**: `string` = `"flutter/keydata"`

## Methods

### toBytes()

> **toBytes**(): `ArrayBuffer`

Serializes this KeyData instance to a binary ArrayBuffer.

#### Returns

`ArrayBuffer`

The serialized key data as an ArrayBuffer
