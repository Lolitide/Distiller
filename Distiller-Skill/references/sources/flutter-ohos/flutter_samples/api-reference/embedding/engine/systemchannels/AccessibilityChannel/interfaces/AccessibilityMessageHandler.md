[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Interface: AccessibilityMessageHandler

Interface for handling accessibility messages.

## Extends

- [`AccessibilityDelegate`](../../../FlutterNapi/interfaces/AccessibilityDelegate.md)

## Methods

### accessibilityStateChange()

> **accessibilityStateChange**(`state`): `void`

Called when the accessibility state changes.

#### Parameters

##### state

`Boolean`

Whether accessibility is enabled

#### Returns

`void`

#### Inherited from

[`AccessibilityDelegate`](../../../FlutterNapi/interfaces/AccessibilityDelegate.md).[`accessibilityStateChange`](../../../FlutterNapi/interfaces/AccessibilityDelegate.md#accessibilitystatechange)

***

### announce()

> **announce**(`message`): `void`

Announces a message to the user.

#### Parameters

##### message

`string`

The message to announce

#### Returns

`void`

***

### onLongPress()

> **onLongPress**(`nodeId`): `void`

Handles a long press event on an accessibility node.

#### Parameters

##### nodeId

`number`

The ID of the accessibility node

#### Returns

`void`

***

### onTap()

> **onTap**(`nodeId`): `void`

Handles a tap event on an accessibility node.

#### Parameters

##### nodeId

`number`

The ID of the accessibility node

#### Returns

`void`

***

### onTooltip()

> **onTooltip**(`nodeId`): `void`

Handles a tooltip event.

#### Parameters

##### nodeId

`string`

The tooltip node ID

#### Returns

`void`
