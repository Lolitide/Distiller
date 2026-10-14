[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: DefaultHandler

Default implementation of AccessibilityMessageHandler.
Handles accessibility events and forwards them to the native Flutter engine.

## Implements

- [`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md)

## Constructors

### Constructor

> **new DefaultHandler**(`flutterNapi`): `DefaultHandler`

Constructs a new DefaultHandler instance.

#### Parameters

##### flutterNapi

`FlutterNapi`

The FlutterNapi instance for native communication

#### Returns

`DefaultHandler`

## Methods

### accessibilityStateChange()

> **accessibilityStateChange**(`state`): `void`

Called when accessibility state changes.

#### Parameters

##### state

`Boolean`

The new accessibility state

#### Returns

`void`

#### Implementation of

[`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md).[`accessibilityStateChange`](../interfaces/AccessibilityMessageHandler.md#accessibilitystatechange)

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

#### Implementation of

[`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md).[`announce`](../interfaces/AccessibilityMessageHandler.md#announce)

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

#### Implementation of

[`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md).[`onLongPress`](../interfaces/AccessibilityMessageHandler.md#onlongpress)

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

#### Implementation of

[`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md).[`onTap`](../interfaces/AccessibilityMessageHandler.md#ontap)

***

### onTooltip()

> **onTooltip**(`message`): `void`

Handles a tooltip event.

#### Parameters

##### message

`string`

The tooltip message

#### Returns

`void`

#### Implementation of

[`AccessibilityMessageHandler`](../interfaces/AccessibilityMessageHandler.md).[`onTooltip`](../interfaces/AccessibilityMessageHandler.md#ontooltip)
