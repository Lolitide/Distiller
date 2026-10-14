[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: FlutterView

Main view class for rendering Flutter content in OpenHarmony applications.
This class manages the Flutter engine, viewport metrics, keyboard handling,
and all interactions between Flutter and the native platform.

## Constructors

### Constructor

> **new FlutterView**(`viewId`, `context`): `FlutterView`

Constructs a new FlutterView instance.

#### Parameters

##### viewId

`string`

The unique identifier for this view

##### context

`Context`

The application context

#### Returns

`FlutterView`

## Methods

### addFirstFrameListener()

> **addFirstFrameListener**(`listener`): `void`

Adds a listener for the first frame event.

#### Parameters

##### listener

[`FirstFrameListener`](../interfaces/FirstFrameListener.md)

The listener to add

#### Returns

`void`

***

### addFirstPreloadFrameListener()

> **addFirstPreloadFrameListener**(`listener`): `void`

Adds a listener for the first preload frame event.

#### Parameters

##### listener

[`FirstPreloadFrameListener`](../interfaces/FirstPreloadFrameListener.md)

The listener to add

#### Returns

`void`

***

### attachToFlutterEngine()

> **attachToFlutterEngine**(`flutterEngine`): `void`

Attaches this view to a Flutter engine.

#### Parameters

##### flutterEngine

`FlutterEngine`

The FlutterEngine to attach to

#### Returns

`void`

***

### detachFromFlutterEngine()

> **detachFromFlutterEngine**(): `void`

Detaches this view from the Flutter engine.
Cleans up all engine-related resources.

#### Returns

`void`

***

### enableFrameCache()

> **enableFrameCache**(`cacheEnable`): `void`

Enables or disables frame caching.

#### Parameters

##### cacheEnable

`boolean`

True to enable frame cache, false to disable

#### Returns

`void`

***

### getActive()

> **getActive**(): `boolean`

Gets the active state of the view.

#### Returns

`boolean`

True if active, false otherwise

***

### getDVModel()

> **getDVModel**(): [`DVModel`](../../DynamicView/dynamicView/classes/DVModel.md)

Gets the DynamicView model.

#### Returns

[`DVModel`](../../DynamicView/dynamicView/classes/DVModel.md)

The DVModel instance

***

### ~~getEmbeddingNodeController()~~

> **getEmbeddingNodeController**(): [`EmbeddingNodeController`](../../../embedding/ohos/EmbeddingNodeController/classes/EmbeddingNodeController.md)

Gets the embedding node controller.

#### Returns

[`EmbeddingNodeController`](../../../embedding/ohos/EmbeddingNodeController/classes/EmbeddingNodeController.md)

The EmbeddingNodeController instance

#### Deprecated

since 3.7

***

### getId()

> **getId**(): `string`

Gets the view ID.

#### Returns

`string`

The view ID

***

### getKeyboardHeight()

> **getKeyboardHeight**(): `number`

Gets the current keyboard height from the cached keyboard avoid area.

#### Returns

`number`

The keyboard height in pixels, or `0` if the keyboard is not visible or avoid-area data is absent.

***

### getPlatformView()

> **getPlatformView**(): [`PlatformView`](../../../plugin/platform/PlatformView/classes/PlatformView.md) \| `undefined`

Gets the platform view.

#### Returns

[`PlatformView`](../../../plugin/platform/PlatformView/classes/PlatformView.md) \| `undefined`

The `PlatformView` instance, or `undefined` if not set.

***

### ~~getPlatformViewSize()~~

> **getPlatformViewSize**(): [`PlatformViewParas`](PlatformViewParas.md)

Gets the platform view size.

#### Returns

[`PlatformViewParas`](PlatformViewParas.md)

The PlatformViewParas instance

#### Deprecated

since 3.7

***

### getSurfaceId()

> **getSurfaceId**(): `string`

Gets the surface ID.

#### Returns

`string`

The surface ID

***

### getWrappedBuilder()

> **getWrappedBuilder**(): `any`

Gets the wrapped builder.

#### Returns

`any`

The WrappedBuilder instance, or undefined if not set

***

### hasRenderedFirstFrame()

> **hasRenderedFirstFrame**(): `boolean`

Checks if the first frame has been rendered.

#### Returns

`boolean`

True if the first frame has been rendered, false otherwise

***

### isAttachedToFlutterEngine()

> **isAttachedToFlutterEngine**(): `boolean`

Checks if this view is attached to a Flutter engine.

#### Returns

`boolean`

True if attached, false otherwise

***

### isSameEngineShellHolderId()

> **isSameEngineShellHolderId**(`id`): `boolean`

Checks if this view is attached to an engine with the specified shell holder ID.

#### Parameters

##### id

`number`

The shell holder ID to check

#### Returns

`boolean`

True if attached to an engine with the specified ID, false otherwise

***

### onAreaChange()

> **onAreaChange**(`newArea`, `setFullScreen`): `void`

Called when the view area changes.
Updates viewport metrics based on the new area and avoid areas.

#### Parameters

##### newArea

`any`

The new area, or null to use current display dimensions

##### setFullScreen

`boolean` = `false`

Whether to set fullscreen mode

#### Returns

`void`

***

### onDestroy()

> **onDestroy**(): `void`

Called when the view is being destroyed.
Cleans up all event listeners and resources.

#### Returns

`void`

***

### onDevicePixelRatioChange()

> **onDevicePixelRatioChange**(`dpiScaleFactor`): `void`

Called when the device pixel ratio should be updated from a density scale factor.
Refreshes display information, updates the text input channel device pixel ratio when a Flutter engine is attached,
recomputes viewport device pixel ratio, and triggers `onAreaChange` when the ratio actually changes.

Registered on `Context.eventHub` for the `changeDevicePixelRatio` event; also invoked internally when
`uiObserver` reports a density update (custom density relative to system density).

#### Parameters

##### dpiScaleFactor

`number`

Multiplier applied to the current system display `densityPixels` to compute the new device pixel ratio,
or `-1` to reset to the system default.

#### Returns

`void`

***

### onFirstFrame()

> **onFirstFrame**(`isPreload`): `void`

Called when the first frame is rendered.
Notifies all registered listeners.

#### Parameters

##### isPreload

`number` = `0`

1 for preload frame, 0 for normal first frame

#### Returns

`void`

***

### onKeyEvent()

> **onKeyEvent**(`event`): `boolean`

Handles key events.

#### Parameters

##### event

`KeyEvent`

The key event

#### Returns

`boolean`

True if the event was handled, false otherwise

***

### onKeyPreIme()

> **onKeyPreIme**(`event`): `boolean`

Handles key events before they reach the input method editor.

#### Parameters

##### event

`KeyEvent`

The key event

#### Returns

`boolean`

True if the event was handled, false otherwise

***

### onMouseWheel()

> **onMouseWheel**(`eventType`, `event`): `void`

Handles mouse wheel events.

#### Parameters

##### eventType

`string`

The event type

##### event

`PanGestureEvent`

The pan gesture event

#### Returns

`void`

***

### onStatusBarClick()

> **onStatusBarClick**(`err`, `subscriber`): `void`

Handles status-bar click subscription setup for OpenHarmony common events.

Registered as the callback for `commonEventManager.createSubscriber` with event `usual.event.CLICK_STATUSBAR`.
Stores the subscriber and subscribes so each delivered status-bar tap forwards to Flutter via
[`StatusBarClickChannel.sendClick`](../../../embedding/engine/systemchannels/StatusBarClickChannel/classes/StatusBarClickChannel.md).

#### Parameters

##### err

`BusinessError`

Business error from the common-event subsystem when creating the subscriber, if any; otherwise unused on success.

##### subscriber

`CommonEventSubscriber`

The common-event subscriber instance that receives `usual.event.CLICK_STATUSBAR` events.

#### Returns

`void`

***

### onSurfaceCreated()

> **onSurfaceCreated**(): `number`

Called when the rendering surface is created.
Marks the surface as available and processes pending messages.

#### Returns

`number`

Monotonic surface generation token for this `FlutterView`: each call sets `activeSurfaceLifecycleToken = ++surfaceLifecycleToken`
(integer counter on the view). Successive creations on the same view get strictly increasing values until
`Number.MAX_SAFE_INTEGER` wrap (not expected in practice). Pass this value to `onSurfaceDestroyed` for that surface;
a matching destroy resets the active token to `0`; a stale destroy with an older token is ignored. The token is only
for ordering on this view instance—not a security identifier and not shared across `FlutterView` instances.

#### Threading

In typical ArkUI applications, `XComponent` `onLoad` / `onDestroy` run on the **UI thread**. The reference
embedding (`FlutterSurface` in [`FlutterPage`](../../../embedding/ohos/FlutterPage/README.md)) calls
`onSurfaceCreated` / `onSurfaceDestroyed` from those callbacks, so token generation and comparison run on that
thread. `FlutterView` does **not** use locks or atomics for the token or `isXComponentAttachedToEngine`; call these
methods from the same thread as your `XComponent` lifecycle, or provide your own synchronization.

The token addresses **out-of-order delivery** (for example a new surface’s `onLoad` before an old surface’s
`onDestroy` when the same `FlutterView` is reused during fast navigation). It does not by itself make the API safe
if `onSurfaceCreated` and `onSurfaceDestroyed` are invoked concurrently from **different** threads without external
sync—such races could still corrupt attachment state.

***

### onSurfaceDestroyed()

> **onSurfaceDestroyed**(`surfaceLifecycleToken?`): `void`

Called when the rendering surface is destroyed.
Marks the surface as unavailable and detaches from the engine.

#### Parameters

##### surfaceLifecycleToken?

`number`

Optional token returned by `onSurfaceCreated` for this surface instance. When provided and it does not match the
active generation, this call is ignored (guards out-of-order destroy after recreation). Prefer passing the token
whenever your embedding tracks surface lifecycle (for example the [`FlutterPage`](../../../embedding/ohos/FlutterPage/README.md) embedding).
Omit only when the token is unavailable; omitting skips the stale-callback guard.

#### Threading

Same contract as `onSurfaceCreated`: prefer the UI / `XComponent` callback thread. Without external synchronization,
do not call this concurrently with `onSurfaceCreated` from another thread.

#### Returns

`void`

***

### onWindowCreated()

> **onWindowCreated**(): `void`

Called when the window is created.
Initializes the UIContext and sends settings to Flutter.

#### Returns

`void`

***

### preDraw()

> **preDraw**(`width`, `height`): `void`

Called before drawing a frame.

#### Parameters

##### width

`number` = `0`

The width of the drawing area, defaults to display width

##### height

`number` = `0`

The height of the drawing area, defaults to display height

#### Returns

`void`

***

### removeFirstFrameListener()

> **removeFirstFrameListener**(`listener`): `void`

Removes a first frame listener.

#### Parameters

##### listener

[`FirstFrameListener`](../interfaces/FirstFrameListener.md)

The listener to remove

#### Returns

`void`

***

### removeFirstPreloadFrameListener()

> **removeFirstPreloadFrameListener**(`listener`): `void`

Removes a first preload frame listener.

#### Parameters

##### listener

[`FirstPreloadFrameListener`](../interfaces/FirstPreloadFrameListener.md)

The listener to remove

#### Returns

`void`

***

### sendSettings()

> **sendSettings**(): `void`

Sends system settings to Flutter.

#### Returns

`void`

***

### setActive()

> **setActive**(`value`): `void`

Sets the active state of the view.

#### Parameters

##### value

`boolean`

True to activate, false to deactivate

#### Returns

`void`

***

### setCheckAiBar()

> **setCheckAiBar**(`check`): `void`

Sets whether to check AI bar area.

#### Parameters

##### check

`boolean`

True to check AI bar area, false otherwise

#### Returns

`void`

***

### setCheckFullScreen()

> **setCheckFullScreen**(`check`): `void`

Sets whether to check fullscreen mode.

#### Parameters

##### check

`boolean`

True to check fullscreen, false otherwise

#### Returns

`void`

***

### setCheckGesture()

> **setCheckGesture**(`check`): `void`

Sets whether to check gesture area.

#### Parameters

##### check

`boolean`

True to check gesture area, false otherwise

#### Returns

`void`

***

### setCheckKeyboard()

> **setCheckKeyboard**(`check`): `void`

Sets whether to check keyboard area.

#### Parameters

##### check

`boolean`

True to check keyboard area, false otherwise

#### Returns

`void`

***

### setPaddingBottom()

> **setPaddingBottom**(`paddingBottom?`): `void`

Sets the bottom padding value.

#### Parameters

##### paddingBottom?

`number`

The bottom padding value, or undefined to use default

#### Returns

`void`

***

### setPaddingTop()

> **setPaddingTop**(`paddingTop?`): `void`

Sets the top padding value.

#### Parameters

##### paddingTop?

`number`

The top padding value, or undefined to use default

#### Returns

`void`

***

### setPlatformView()

> **setPlatformView**(`platformView`): `void`

Sets the platform view.

#### Parameters

##### platformView

`PlatformView`

The PlatformView instance

#### Returns

`void`

***

### setSurfaceId()

> **setSurfaceId**(`surfaceId`): `void`

Sets the surface ID for rendering.

#### Parameters

##### surfaceId

`string`

The surface ID

#### Returns

`void`

***

### setTouchSlopCallbackValue()

> **setTouchSlopCallbackValue**(`callback`): `void`

Sets the callback for getting touch slop value.

#### Parameters

##### callback

`callbackNumber`

The callback function that returns the touch slop value

#### Returns

`void`

***

### setWrappedBuilder()

> **setWrappedBuilder**(`wrappedBuilder`): `void`

Sets the wrapped builder for platform views.

#### Parameters

##### wrappedBuilder

`WrappedBuilder`\<\[[`Params`](../../../plugin/platform/PlatformView/classes/Params.md)\]\>

The WrappedBuilder instance

#### Returns

`void`
