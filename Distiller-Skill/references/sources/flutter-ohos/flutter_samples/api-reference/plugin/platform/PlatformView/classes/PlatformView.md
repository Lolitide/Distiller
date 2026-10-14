[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Abstract Class: PlatformView

A handle to an DynamicView to be embedded in the Flutter hierarchy.

## Constructors

### Constructor

> **new PlatformView**(): `PlatformView`

#### Returns

`PlatformView`

## Methods

### dispose()

> `abstract` **dispose**(): `void`

Disposes this platform view.

The PlatformView object is unusable after this method is called.

Plugins implementing PlatformView must clear all references to the DynamicView object and
the PlatformView after this method is called. Failing to do so will result in a memory leak.

References related to the DynamicView attached in onFlutterViewAttached
must be released in dispose() to avoid memory leaks.

#### Returns

`void`

***

### getPlatformViewVisibleAreaEventOptions()

> **getPlatformViewVisibleAreaEventOptions**(): [`PlatformViewVisibleAreaEventOptions`](PlatformViewVisibleAreaEventOptions.md)

#### Returns

[`PlatformViewVisibleAreaEventOptions`](PlatformViewVisibleAreaEventOptions.md)

***

### getType()

> **getType**(): `string`

Gets the type of this platform view.

#### Returns

`string`

The view type string

***

### getView()

> `abstract` **getView**(): `WrappedBuilder`\<\[[`Params`](Params.md)\]\>

Returns the DynamicView to be embedded in the Flutter hierarchy.

#### Returns

`WrappedBuilder`\<\[[`Params`](Params.md)\]\>

***

### onActive()

> **onActive**(): `void`

#### Returns

`void`

***

### onFlutterViewAttached()

> **onFlutterViewAttached**(`dvModel`): `void`

Called by the FlutterEngine that owns this PlatformView when the DynamicView responsible
for rendering a Flutter UI is associated with the FlutterEngine.

This means that our associated FlutterEngine can now render a UI and interact with the user.

Some platform views may have unusual dependencies on the DynamicView that renders Flutter
UIs, such as unique keyboard interactions. That DynamicView is provided here for those
purposes. Use of this DynamicView should be avoided if it is not absolutely necessary, because
depending on this DynamicView will tend to make platform view code more brittle to future
changes.

#### Parameters

##### dvModel

[`DVModel`](../../../../view/DynamicView/dynamicView/classes/DVModel.md)

The DynamicView model associated with the Flutter view

#### Returns

`void`

***

### onFlutterViewDetached()

> **onFlutterViewDetached**(): `void`

Called by the FlutterEngine that owns this PlatformView when the DynamicView responsible
for rendering a Flutter UI is detached and disassociated from the FlutterEngine.

This means that our associated FlutterEngine no longer has a rendering surface, or a user
interaction surface of any kind.

This platform view must release any references related to the DynamicView that was
provided in onFlutterViewAttached.

#### Returns

`void`

***

### onInactive()

> **onInactive**(): `void`

#### Returns

`void`

***

### onInputConnectionLocked()

> **onInputConnectionLocked**(): `void`

Callback fired when the platform's input connection is locked, or should be used.

This hook only exists for rare cases where the plugin relies on the state of the input
connection. This probably doesn't need to be implemented.

#### Returns

`void`

***

### onInputConnectionUnlocked()

> **onInputConnectionUnlocked**(): `void`

Callback fired when the platform input connection has been unlocked.

This hook only exists for rare cases where the plugin relies on the state of the input
connection. This probably doesn't need to be implemented.

#### Returns

`void`
