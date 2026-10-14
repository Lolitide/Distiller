[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterManager

Singleton manager for Flutter views and UI abilities.
This class manages the lifecycle of FlutterView instances and their association with UI abilities.

## Constructors

### Constructor

> **new FlutterManager**(): `FlutterManager`

#### Returns

`FlutterManager`

## Methods

### addDragEnterCb()

> **addDragEnterCb**(`callback`): `number`

Adds a drag enter callback.

#### Parameters

##### callback

[`DragDropCallback`](../interfaces/DragDropCallback.md)

The drag enter callback

#### Returns

`number`

The callback ID

***

### addDragLeaveCb()

> **addDragLeaveCb**(`callback`): `number`

Adds a drag leave callback.

#### Parameters

##### callback

[`DragDropCallback`](../interfaces/DragDropCallback.md)

The drag leave callback

#### Returns

`number`

The callback ID

***

### addDragMoveCb()

> **addDragMoveCb**(`callback`): `number`

Adds a drag move callback.

#### Parameters

##### callback

[`DragDropCallback`](../interfaces/DragDropCallback.md)

The drag move callback

#### Returns

`number`

The callback ID

***

### addDropCb()

> **addDropCb**(`callback`): `number`

Adds a drop callback.

#### Parameters

##### callback

[`DragDropCallback`](../interfaces/DragDropCallback.md)

The drop callback

#### Returns

`number`

The callback ID

***

### clear()

> **clear**(): `void`

Clears all FlutterView instances.

#### Returns

`void`

***

### createFlutterView()

> **createFlutterView**(`context`): [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

Creates a new FlutterView instance.
It's suggested to keep 'oh_flutter_' as the prefix for xcomponent_id.
Otherwise it might affect the performance.

#### Parameters

##### context

`Context`

The context for creating the view

#### Returns

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

A new FlutterView instance

***

### deleteFlutterView()

> **deleteFlutterView**(`viewId`, `flutterView?`): `void`

Deletes a FlutterView from the list.

#### Parameters

##### viewId

`string`

The view ID

##### flutterView?

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

Optional FlutterView instance to verify

#### Returns

`void`

***

### getDragEnterCbs()

> **getDragEnterCbs**(): `List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

Gets all drag enter callbacks.

#### Returns

`List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

A list of drag enter callbacks

***

### getDragLeaveCbs()

> **getDragLeaveCbs**(): `List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

Gets all drag leave callbacks.

#### Returns

`List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

A list of drag leave callbacks

***

### getDragMoveCbs()

> **getDragMoveCbs**(): `List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

Gets all drag move callbacks.

#### Returns

`List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

A list of drag move callbacks

***

### getDropCbs()

> **getDropCbs**(): `List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

Gets all drop callbacks.

#### Returns

`List`\<[`DragDropCallback`](../interfaces/DragDropCallback.md)\>

A list of drop callbacks

***

### getFlutterView()

> **getFlutterView**(`viewId`): [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

Gets a FlutterView by ID.

#### Parameters

##### viewId

`string`

The view ID

#### Returns

[`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)

The FlutterView instance, or null if not found

***

### getFlutterViewList()

> **getFlutterViewList**(): `Map`\<`String`, [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)\>

Gets all FlutterView instances.

#### Returns

`Map`\<`String`, [`FlutterView`](../../../../view/FlutterView/classes/FlutterView.md)\>

A map of all FlutterView instances by ID

***

### getFullScreenListener()

> **getFullScreenListener**(): [`FullScreenListener`](../interfaces/FullScreenListener.md)

Gets the full screen listener.

#### Returns

[`FullScreenListener`](../interfaces/FullScreenListener.md)

The FullScreenListener instance

***

### getNextFlutterViewId()

> **getNextFlutterViewId**(`idOffset`): `string`

Gets the next FlutterView ID that will be used.

#### Parameters

##### idOffset

`number` = `0`

Optional offset to add to the index

#### Returns

`string`

The next FlutterView ID string

***

### getUIAbility()

> **getUIAbility**(`context?`): `UIAbility`

Gets a UIAbility by context, or returns the first one if no context is provided.

#### Parameters

##### context?

`Context`

Optional context to search for

#### Returns

`UIAbility`

The UIAbility instance

***

### getWindowId()

> **getWindowId**(`context`): `number`

Get window ID for notifyPageChanged.

#### Parameters

##### context

`Context`

The context to get UIAbility

#### Returns

`number`

The window ID, or 0 if failed

***

### getWindowStage()

> **getWindowStage**(`uiAbility`): `WindowStage`

Gets the WindowStage for a UIAbility.

#### Parameters

##### uiAbility

`UIAbility`

The UIAbility

#### Returns

`WindowStage`

The associated WindowStage

***

### handleWindowDecorSafeArea()

> **handleWindowDecorSafeArea**(`flutterViewId`, `context?`): `void`

Adjusts FlutterView top padding to avoid window decoration overlap.

#### Parameters

##### flutterViewId

`string`

The FlutterView ID

##### context?

`any`

Optional context, defaults to first UIAbility

#### Returns

`void`

***

### hasFlutterView()

> **hasFlutterView**(`viewId`): `boolean`

Checks if a FlutterView exists with the given ID.

#### Parameters

##### viewId

`string`

The view ID to check

#### Returns

`boolean`

True if the view exists, false otherwise

***

### isWindowDecorSafeAreaAvoidSupported()

> **isWindowDecorSafeAreaAvoidSupported**(`context?`): `boolean`

Checks if window decoration safe area avoidance is supported on the current device.
Returns true only when the device is in freeform multi-window mode and supports window decoration.

#### Parameters

##### context?

`any`

Optional context, defaults to first UIAbility

#### Returns

`boolean`

True if window decoration safe area avoidance is supported, false otherwise

***

### popUIAbility()

> **popUIAbility**(`uiAbility`): `void`

Removes a UIAbility from the list.

#### Parameters

##### uiAbility

`UIAbility`

The UIAbility to remove

#### Returns

`void`

***

### popWindowStage()

> **popWindowStage**(`uiAbility`): `void`

Removes the WindowStage association for a UIAbility.

#### Parameters

##### uiAbility

`UIAbility`

The UIAbility

#### Returns

`void`

***

### pushUIAbility()

> **pushUIAbility**(`uiAbility`): `void`

Pushes a UIAbility to the list.

#### Parameters

##### uiAbility

`UIAbility`

The UIAbility to add

#### Returns

`void`

***

### pushWindowStage()

> **pushWindowStage**(`uiAbility`, `windowStage`): `void`

Associates a WindowStage with a UIAbility.

#### Parameters

##### uiAbility

`UIAbility`

The UIAbility

##### windowStage

`WindowStage`

The WindowStage to associate

#### Returns

`void`

***

### removeDragEnterCb()

> **removeDragEnterCb**(`id`): `void`

Removes a drag enter callback.

#### Parameters

##### id

`number`

The callback ID to remove

#### Returns

`void`

***

### removeDragLeaveCb()

> **removeDragLeaveCb**(`id`): `void`

Removes a drag leave callback.

#### Parameters

##### id

`number`

The callback ID to remove

#### Returns

`void`

***

### removeDragMoveCb()

> **removeDragMoveCb**(`id`): `void`

Removes a drag move callback.

#### Parameters

##### id

`number`

The callback ID to remove

#### Returns

`void`

***

### removeDropCb()

> **removeDropCb**(`id`): `void`

Removes a drop callback.

#### Parameters

##### id

`number`

The callback ID to remove

#### Returns

`void`

***

### setFullScreenListener()

> **setFullScreenListener**(`listener`): `void`

Sets the full screen listener.

#### Parameters

##### listener

[`FullScreenListener`](../interfaces/FullScreenListener.md)

The FullScreenListener instance

#### Returns

`void`

***

### setSpecificSystemBarEnabled()

> **setSpecificSystemBarEnabled**(`flutterViewId`, `specificSystemBar`, `isVisible`, `enableAnimation?`, `context?`): `void`

Sets the visibility of a specific system bar and applies safe area padding.
When hiding a system bar, automatically applies padding to avoid content being covered.

#### Parameters

##### flutterViewId

`string`

The ID of the FlutterView to apply padding

##### specificSystemBar

System bar type: 'status' for status bar, 'navigation' for three-key navigation bar, 'navigationIndicator' for gesture navigation bar

`"status"` | `"navigation"` | `"navigationIndicator"`

##### isVisible

`boolean`

True to show, false to hide

##### enableAnimation?

`boolean`

Whether to enable animation effect, optional

##### context?

`Context`

Optional context, uses the first UIAbility if not provided

#### Returns

`void`

***

### setUseFullScreen()

> **setUseFullScreen**(`use`, `context?`): `void`

Sets whether to use full screen mode.

#### Parameters

##### use

`boolean`

Whether to use full screen

##### context?

`any`

Optional context

#### Returns

`void`

***

### useFullScreen()

> **useFullScreen**(): `boolean`

Checks if full screen mode is enabled.

#### Returns

`boolean`

True if full screen is enabled, false otherwise

***

### getInstance()

> `static` **getInstance**(): `FlutterManager`

Gets the singleton instance of FlutterManager.

#### Returns

`FlutterManager`

The singleton FlutterManager instance
