[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: Configuration

A text editing configuration.

## Constructors

### Constructor

> **new Configuration**(`obscureText`, `autocorrect`, `enableSuggestions`, `enableIMEPersonalizedLearning`, `enableDeltaModel`, `inputType`, `inputAction`, `actionLabel`, `autofill`, `contentListString`, `deviceKind`, `fields`): `Configuration`

Constructs a new Configuration instance.

#### Parameters

##### obscureText

`boolean`

Whether text should be obscured

##### autocorrect

`boolean`

Whether autocorrect is enabled

##### enableSuggestions

`boolean`

Whether suggestions are enabled

##### enableIMEPersonalizedLearning

`boolean`

Whether IME personalized learning is enabled

##### enableDeltaModel

`boolean`

Whether delta model is enabled

##### inputType

[`InputType`](InputType.md)

The input type

##### inputAction

`Number`

The input action

##### actionLabel

`String`

The action label

##### autofill

`boolean`

Whether autofill is enabled

##### contentListString

\[\]

Content commit MIME types

##### deviceKind

[`PointerDeviceKind`](../../../../ohos/OhosTouchProcessor/enumerations/PointerDeviceKind.md)

The pointer device kind

##### fields

`Configuration`[]

Array of field configurations

#### Returns

`Configuration`

## Properties

### actionLabel

> **actionLabel**: `String` = `""`

The label for the action button.

***

### autocorrect

> **autocorrect**: `boolean` = `false`

Whether autocorrect is enabled.

***

### autofill

> **autofill**: `boolean` = `false`

Whether autofill is enabled.

***

### contentCommitMimeTypes

> **contentCommitMimeTypes**: `String`[] = `[]`

MIME types for content commit operations.

***

### deviceKind

> **deviceKind**: [`PointerDeviceKind`](../../../../ohos/OhosTouchProcessor/enumerations/PointerDeviceKind.md) = `PointerDeviceKind.UNKNOWN`

The kind of pointer device being used.

***

### enableDeltaModel

> **enableDeltaModel**: `boolean` = `false`

Whether delta model is enabled for text editing.

***

### enableIMEPersonalizedLearning

> **enableIMEPersonalizedLearning**: `boolean` = `false`

Whether IME personalized learning is enabled.

***

### enableSuggestions

> **enableSuggestions**: `boolean` = `false`

Whether suggestions are enabled.

***

### fields

> **fields**: `Configuration`[] = `[]`

Array of field configurations for autofill.

***

### inputAction

> **inputAction**: `Number` = `0`

The input action to perform when the user submits.

***

### inputType

> **inputType**: [`InputType`](InputType.md) = `null`

The input type for the text field, or null if not set.

***

### obscureText

> **obscureText**: `boolean` = `false`

Whether text should be obscured (e.g., for password fields).

## Methods

### fromJson()

> `static` **fromJson**(`json`): `Configuration`

Creates a Configuration instance from JSON.

#### Parameters

##### json

`Any`

The JSON object

#### Returns

`Configuration`

A new Configuration instance

***

### fromMap()

> `static` **fromMap**(`map`): `Configuration`

Creates a Configuration instance from a map.

#### Parameters

##### map

`Map`\<`String`, `Any`\>

The map containing configuration data

#### Returns

`Configuration`

A new Configuration instance
