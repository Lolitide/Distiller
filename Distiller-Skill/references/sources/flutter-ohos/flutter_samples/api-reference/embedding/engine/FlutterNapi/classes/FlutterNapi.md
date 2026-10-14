[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterNapi

Provides Flutter NAPI interface for ArkTS.
This class serves as the bridge between the ArkTS layer and the native Flutter engine,
handling initialization, message passing, viewport management, and lifecycle events.

## Constructors

### Constructor

> **new FlutterNapi**(): `FlutterNapi`

#### Returns

`FlutterNapi`

## Properties

### accessibilityDelegate

> **accessibilityDelegate**: [`AccessibilityDelegate`](../interfaces/AccessibilityDelegate.md) = `null`

The accessibility delegate for handling accessibility events, or null if not set.

***

### hasImplemented

> **hasImplemented**: `boolean` = `false`

Whether the native methods have been implemented.

***

### isDisplayingFlutterUi

> **isDisplayingFlutterUi**: `boolean` = `false`

Whether Flutter UI is currently being displayed.

***

### isPreloadedFlutterUi

> **isPreloadedFlutterUi**: `boolean` = `false`

Whether Flutter UI has been preloaded.

***

### isRunningDart

> **isRunningDart**: `boolean` = `false`

Whether Dart code is currently running.

***

### localizationPlugin

> **localizationPlugin**: `any` = `null`

The localization plugin for handling locale information, or null if not set.

***

### nativeShellHolderId

> **nativeShellHolderId**: `number` = `null`

The native shell holder ID, or null if not attached.

***

### platformMessageHandler

> **platformMessageHandler**: [`PlatformMessageHandler`](../../dart/PlatformMessageHandler/interfaces/PlatformMessageHandler.md) = `null`

The platform message handler for receiving messages from Dart, or null if not set.

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

***

### addEngineLifecycleListener()

> **addEngineLifecycleListener**(`engineLifecycleListener`): `void`

Adds an engine lifecycle listener.

#### Parameters

##### engineLifecycleListener

[`EngineLifecycleListener`](../../FlutterEngine/interfaces/EngineLifecycleListener.md)

The EngineLifecycleListener to add

#### Returns

`void`

***

### attachToNative()

> **attachToNative**(): `void`

Attaches this FlutterNapi instance to the native engine.
This must be called before using most FlutterNapi methods.

#### Returns

`void`

***

### checkAndReloadFont()

> **checkAndReloadFont**(): `void`

Checks and reloads fonts for this engine instance.

#### Returns

`void`

***

### checkImplemented()

> **checkImplemented**(`methodName`): `boolean`

Checks if the native methods are implemented.

#### Parameters

##### methodName

`string` = `""`

Optional method name for logging

#### Returns

`boolean`

true if methods are implemented, false otherwise

***

### computePlatformResolvedLocale()

> **computePlatformResolvedLocale**(`strings`): `string`[]

Computes the platform-resolved locale from the given locale strings.
Invoked by native to obtain the results of OpenHarmony's locale resolution algorithm.

#### Parameters

##### strings

`string`[]

Array of locale strings

#### Returns

`string`[]

Array of resolved locale strings

***

### detachFromNativeAndReleaseResources()

> **detachFromNativeAndReleaseResources**(): `void`

Detaches this FlutterNapi instance from the native engine and releases all resources.

#### Returns

`void`

***

### dispatchEmptyPlatformMessage()

> **dispatchEmptyPlatformMessage**(`channel`, `responseId`): `void`

Dispatches an empty platform message to Dart.

#### Parameters

##### channel

`String`

The channel name for the message

##### responseId

`number`

The response ID for receiving a reply

#### Returns

`void`

***

### dispatchPlatformMessage()

> **dispatchPlatformMessage**(`channel`, `message`, `position`, `responseId`): `void`

Sends a platform message with data from OpenHarmony to Flutter over the given channel.

#### Parameters

##### channel

`String`

The channel name for the message

##### message

`ArrayBuffer`

The message data as an ArrayBuffer

##### position

`number`

The position in the message buffer

##### responseId

`number`

The response ID for receiving a reply

#### Returns

`void`

***

### dispatchSemanticsAction()

> **dispatchSemanticsAction**(`virtualViewId`, `action`, `responseId`): `void`

Dispatches a semantics action to the native engine.

#### Parameters

##### virtualViewId

`number`

The virtual view ID

##### action

[`Action`](../../systemchannels/AccessibilityChannel/enumerations/Action.md)

The semantics action to dispatch

##### responseId

`number`

The response ID for the reply

#### Returns

`void`

***

### enableFrameCache()

> **enableFrameCache**(`enable`): `void`

Enables or disables frame caching for improved performance.

#### Parameters

##### enable

`boolean`

Whether to enable frame caching

#### Returns

`void`

***

### getSystemLanguages()

> **getSystemLanguages**(): `void`

Gets the system language list from the platform.

#### Returns

`void`

***

### ~~getTextureNativeWindowId()~~

> **getTextureNativeWindowId**(`textureId`): `number`

#### Parameters

##### textureId

`number`

#### Returns

`number`

#### Deprecated

since 3.22

#### Useinstead

FlutterNapi#getTextureNativeWindowPtr

***

### getTextureNativeWindowPtr()

> **getTextureNativeWindowPtr**(`textureId`): `bigint`

Gets the native window pointer for a texture.

#### Parameters

##### textureId

`number`

The texture ID

#### Returns

`bigint`

The native window pointer as a bigint, or BigInt("0") if not available

***

### handlePlatformMessage()

> **handlePlatformMessage**(`channel`, `message`, `replyId`, `messageData`): `void`

Called by native on any thread to handle a platform message from Dart.

#### Parameters

##### channel

`string`

The channel name for the message

##### message

`ArrayBuffer`

The message data as an ArrayBuffer

##### replyId

`number`

The reply ID for responding to the message

##### messageData

`number`

Additional message data

#### Returns

`void`

***

### handlePlatformMessageResponse()

> **handlePlatformMessageResponse**(`replyId`, `reply`): `void`

Called by native to respond to a platform message that we sent.

#### Parameters

##### replyId

`number`

The response ID that was sent with the original message

##### reply

`ArrayBuffer`

The reply data as an ArrayBuffer

#### Returns

`void`

***

### init()

> **init**(`context`, `args`, `bundlePath`, `appStoragePath`, `engineCachesPath`, `initTimeMillis`): `void`

Initializes the Flutter engine with the specified parameters.

#### Parameters

##### context

`Context`

The application context

##### args

`string`[]

Command-line arguments for the Flutter engine

##### bundlePath

`string`

Path to the Flutter bundle

##### appStoragePath

`string`

Path to the application storage directory

##### engineCachesPath

`string`

Path to the engine caches directory

##### initTimeMillis

`number`

Initialization time in milliseconds

#### Returns

`void`

***

### invokePlatformMessageEmptyResponseCallback()

> **invokePlatformMessageEmptyResponseCallback**(`responseId`): `void`

Invokes an empty response callback for a platform message.

#### Parameters

##### responseId

`number`

The response ID that was sent with the original message

#### Returns

`void`

***

### invokePlatformMessageResponseCallback()

> **invokePlatformMessageResponseCallback**(`responseId`, `message`, `position`): `void`

Invokes a response callback with data for a platform message.

#### Parameters

##### responseId

`number`

The response ID that was sent with the original message

##### message

`ArrayBuffer`

The reply data as an ArrayBuffer

##### position

`number`

The position in the message buffer

#### Returns

`void`

***

### isAttached()

> **isAttached**(): `boolean`

Checks if this FlutterNapi instance is attached to the native engine.

#### Returns

`boolean`

true if attached, false otherwise

***

### nativeDispatchSemanticsAction()

> **nativeDispatchSemanticsAction**(`virtualViewId`, `action`, `responseId`): `void`

Native method for dispatching a semantics action.

#### Parameters

##### virtualViewId

`number`

The virtual view ID

##### action

[`Action`](../../systemchannels/AccessibilityChannel/enumerations/Action.md)

The semantics action to dispatch

##### responseId

`number`

The response ID for the reply

#### Returns

`void`

***

### nativeSetAccessibilityFeatures()

> **nativeSetAccessibilityFeatures**(`accessibilityFeatureFlags`, `responseId`): `void`

Native method for setting accessibility features.

#### Parameters

##### accessibilityFeatureFlags

`number`

The accessibility feature flags

##### responseId

`number`

The response ID for the reply

#### Returns

`void`

***

### notifyLowMemoryWarning()

> **notifyLowMemoryWarning**(): `void`

Notifies the Flutter engine of a low memory warning.

#### Returns

`void`

***

### NotifyPageChanged()

> **NotifyPageChanged**(`pageName`, `pageNameLen`, `windowID`): `number`

Notifies the system that the current UI page changed (`OH_AbilityRuntime_NotifyPageChanged`). Requires API 23+.
Used by [`NavigationChannel`](../../systemchannels/NavigationChannel/classes/NavigationChannel.md) with the current route URI and the window id from `FlutterManager`.

#### Parameters

##### pageName

`string`

Page identifier passed to the OS notifier (for example the current route URI).

##### pageNameLen

`number`

Length of `pageName` in the form expected by the native API. The navigation embedding uses `pageName.length`
(ArkTS string length in UTF-16 code units). Custom callers must keep this consistent with the string contents and OHOS API rules.

##### windowID

`number`

Id of the hosting window (from `FlutterManager.getInstance().getWindowId(context)`).

#### Returns

`number`

`0` on success, non-zero on failure. May be `0` when the API is not supported on older SDKs.

***

### notifyTextureResizing()

> **notifyTextureResizing**(`textureId`, `width`, `height`): `void`

Notifies the Flutter engine that a texture is being resized.

#### Parameters

##### textureId

`number`

The texture ID

##### width

`number`

The new width

##### height

`number`

The new height

#### Returns

`void`

***

### onApplicationLocaleChanged()

> **onApplicationLocaleChanged**(`locale`): `void`

Called by native when the application locale is changed via dart:ui setApplicationLocale.

#### Parameters

##### locale

`string`

The application locale in BCP 47 format

#### Returns

`void`

***

### onAxisEvent()

> **onAxisEvent**(`strings`): `void`

Handles axis events (scroll wheel, etc.) from the platform.

#### Parameters

##### strings

`string`[]

Array of strings containing axis event data

#### Returns

`void`

***

### onFirstFrame()

> **onFirstFrame**(`isPreload`): `void`

Called by native to notify that the first Flutter frame has been rendered.

#### Parameters

##### isPreload

`number`

Whether this is a preload frame (1) or a regular frame (0)

#### Returns

`void`

***

### onMouseEvent()

> **onMouseEvent**(`strings`): `void`

Handles mouse events from the platform.

#### Parameters

##### strings

`string`[]

Array of strings containing mouse event data

#### Returns

`void`

***

### onPreEngineRestart()

> **onPreEngineRestart**(): `void`

Called by native when the engine is about to restart.
Notifies all registered lifecycle listeners.

#### Returns

`void`

***

### onTouchEvent()

> **onTouchEvent**(`strings`): `void`

Handles touch events from the platform.

#### Parameters

##### strings

`string`[]

Array of strings containing touch event data

#### Returns

`void`

***

### preSpawn()

> **preSpawn**(`entrypointFunctionName`, `pathToEntrypointFunction`, `initialRoute`, `entrypointArgs`): `FlutterNapi`

Pre-spawns a new FlutterNapi instance for later use.

#### Parameters

##### entrypointFunctionName

`string`

Name of the entrypoint function

##### pathToEntrypointFunction

`string`

Path to the entrypoint function

##### initialRoute

`string`

Initial route for navigation

##### entrypointArgs

`string`[]

Arguments to pass to the entrypoint function

#### Returns

`FlutterNapi`

A new FlutterNapi instance that will be used on the next spawn call

***

### processPendingMessages()

> **processPendingMessages**(): `void`

Processes all pending messages that were queued during preloading.

#### Returns

`void`

***

### registerPixelMap()

> **registerPixelMap**(`textureId`, `pixelMap`): `void`

Registers a PixelMap as a texture in the Flutter engine.

#### Parameters

##### textureId

`number`

The texture ID

##### pixelMap

`PixelMap`

The PixelMap to register

#### Returns

`void`

***

### registerTexture()

> **registerTexture**(`textureId`): `number`

Registers a texture in the Flutter engine.

#### Parameters

##### textureId

`number`

The texture ID to register

#### Returns

`number`

The registered texture ID, or 0 if registration fails

***

### removeEngineLifecycleListener()

> **removeEngineLifecycleListener**(`engineLifecycleListener`): `void`

Removes an engine lifecycle listener.

#### Parameters

##### engineLifecycleListener

[`EngineLifecycleListener`](../../FlutterEngine/interfaces/EngineLifecycleListener.md)

The EngineLifecycleListener to remove

#### Returns

`void`

***

### resetExternalTexture()

> **resetExternalTexture**(`textureId`, `need_surfaceId`): `number`

Resets an external texture.

#### Parameters

##### textureId

`number`

The texture ID

##### need\_surfaceId

`boolean`

Whether a surface ID is needed

#### Returns

`number`

The surface ID if needed, or 0 otherwise

***

### runBundleAndSnapshotFromLibrary()

> **runBundleAndSnapshotFromLibrary**(`bundlePath`, `entrypointFunctionName`, `pathToEntrypointFunction`, `assetManager`, `entrypointArgs`): `void`

Runs a Flutter bundle and snapshot from a library.

#### Parameters

##### bundlePath

`string`

Path to the Flutter bundle

##### entrypointFunctionName

`string`

Name of the entrypoint function

##### pathToEntrypointFunction

`string`

Path to the entrypoint function

##### assetManager

`ResourceManager`

Resource manager for accessing assets

##### entrypointArgs

`string`[]

Arguments to pass to the entrypoint function

#### Returns

`void`

***

### setAccessibilityDelegate()

> **setAccessibilityDelegate**(`delegate`, `responseId`): `void`

Sets the accessibility delegate for handling accessibility events.

#### Parameters

##### delegate

[`AccessibilityDelegate`](../interfaces/AccessibilityDelegate.md)

The AccessibilityDelegate instance

##### responseId

`number`

The response ID for the reply

#### Returns

`void`

***

### setAccessibilityFeatures()

> **setAccessibilityFeatures**(`accessibilityFeatureFlags`, `responseId`): `void`

Sets accessibility features and sends a response.

#### Parameters

##### accessibilityFeatureFlags

`number`

The accessibility feature flags

##### responseId

`number`

The response ID for the reply

#### Returns

`void`

***

### SetAnimationStatus()

> **SetAnimationStatus**(`animationStatus`): `void`

Reports scroll / list animation phase to the native shell (for example hiAppEvent / tracing integration).
Embedders normally drive this through `PlatformChannel` scroll handling rather than calling this directly.

#### Parameters

##### animationStatus

`number`

Status code forwarded to native: `0` = scroll or fling **started**, `1` = scroll or fling **ended**
(same values as the internal `AnimationStatus` enum used in `PlatformChannel`). Other values are not defined by this embedding.

#### Returns

`void`

***

### SetDVsyncSwitch()

> **SetDVsyncSwitch**(`isEnable`): `void`

Sets the D-VSync switch state.

#### Parameters

##### isEnable

`boolean`

Whether to enable D-VSync

#### Returns

`void`

***

### ~~setExternalNativeImage()~~

> **setExternalNativeImage**(`textureId`, `native_image`): `boolean`

#### Parameters

##### textureId

`number`

##### native\_image

`number`

#### Returns

`boolean`

#### Deprecated

since 3.22

#### Useinstead

FlutterNapi#setExternalNativeImagePtr

***

### setExternalNativeImagePtr()

> **setExternalNativeImagePtr**(`textureId`, `native_image_ptr`): `boolean`

Sets an external native image pointer for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### native\_image\_ptr

`bigint`

The native image pointer as a bigint

#### Returns

`boolean`

true if successful, false otherwise

***

### setFlutterNavigationAction()

> **setFlutterNavigationAction**(`shellHolderId`, `isNavigate`): `void`

Sets the Flutter navigation action state.

#### Parameters

##### shellHolderId

`number`

The shell holder ID

##### isNavigate

`boolean`

Whether navigation is active

#### Returns

`void`

***

### setFontWeightScale()

> **setFontWeightScale**(`fontWeightScale`): `void`

Sets the font weight scale for text rendering.

#### Parameters

##### fontWeightScale

`number`

The font weight scale factor

#### Returns

`void`

***

### setLocalizationPlugin()

> **setLocalizationPlugin**(`localizationPlugin`): `void`

Sets the localization plugin for handling locale information.

#### Parameters

##### localizationPlugin

`any`

The LocalizationPlugin instance, or null to remove

#### Returns

`void`

***

### setPipVisible()

> **setPipVisible**(`visible`): `void`

#### Parameters

##### visible

`boolean`

#### Returns

`void`

***

### setPlatformMessageHandler()

> **setPlatformMessageHandler**(`platformMessageHandler`): `void`

Sets the platform message handler for receiving messages from Dart.

#### Parameters

##### platformMessageHandler

[`PlatformMessageHandler`](../../dart/PlatformMessageHandler/interfaces/PlatformMessageHandler.md)

The PlatformMessageHandler instance, or null to remove

#### Returns

`void`

***

### setPreloading()

> **setPreloading**(): `void`

Sets the preloading state, preventing message handling until ready.

#### Returns

`void`

***

### SetQosOnLowMemory()

> **SetQosOnLowMemory**(`lowMemoryLevel`): `void`

Sets the QoS (Quality of Service) level when low memory is detected.

#### Parameters

##### lowMemoryLevel

`number`

The low memory level

#### Returns

`void`

***

### setSemanticsEnabled()

> **setSemanticsEnabled**(`enabled`): `void`

Sets whether semantics are enabled.

#### Parameters

##### enabled

`boolean`

Whether to enable semantics

#### Returns

`void`

***

### setSemanticsEnabledWithRespId()

> **setSemanticsEnabledWithRespId**(`enabled`, `responseId`): `void`

Sets whether semantics are enabled and sends a response.

#### Parameters

##### enabled

`boolean`

Whether to enable semantics

##### responseId

`number`

The response ID for the reply

#### Returns

`void`

***

### setTextureBackGroundColor()

> **setTextureBackGroundColor**(`textureId`, `color`): `void`

Sets the background color for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### color

`number`

The color value in ARGB format

#### Returns

`void`

***

### setTextureBackGroundPixelMap()

> **setTextureBackGroundPixelMap**(`textureId`, `pixelMap`): `void`

Sets the background PixelMap for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### pixelMap

`PixelMap`

The PixelMap to use as background

#### Returns

`void`

***

### setTextureBufferSize()

> **setTextureBufferSize**(`textureId`, `width`, `height`): `void`

Sets the buffer size for a texture.

#### Parameters

##### textureId

`number`

The texture ID

##### width

`number`

The width of the buffer

##### height

`number`

The height of the buffer

#### Returns

`void`

***

### setViewportMetrics()

> **setViewportMetrics**(`devicePixelRatio`, `physicalWidth`, `physicalHeight`, `physicalPaddingTop`, `physicalPaddingRight`, `physicalPaddingBottom`, `physicalPaddingLeft`, `physicalViewInsetTop`, `physicalViewInsetRight`, `physicalViewInsetBottom`, `physicalViewInsetLeft`, `systemGestureInsetTop`, `systemGestureInsetRight`, `systemGestureInsetBottom`, `systemGestureInsetLeft`, `physicalTouchSlop`, `displayFeaturesBounds`, `displayFeaturesType`, `displayFeaturesState`): `void`

Sets the viewport metrics for the Flutter view.

#### Parameters

##### devicePixelRatio

`number`

The device pixel ratio

##### physicalWidth

`number`

Physical width in pixels

##### physicalHeight

`number`

Physical height in pixels

##### physicalPaddingTop

`number`

Top padding in physical pixels

##### physicalPaddingRight

`number`

Right padding in physical pixels

##### physicalPaddingBottom

`number`

Bottom padding in physical pixels

##### physicalPaddingLeft

`number`

Left padding in physical pixels

##### physicalViewInsetTop

`number`

Top view inset in physical pixels

##### physicalViewInsetRight

`number`

Right view inset in physical pixels

##### physicalViewInsetBottom

`number`

Bottom view inset in physical pixels

##### physicalViewInsetLeft

`number`

Left view inset in physical pixels

##### systemGestureInsetTop

`number`

Top system gesture inset

##### systemGestureInsetRight

`number`

Right system gesture inset

##### systemGestureInsetBottom

`number`

Bottom system gesture inset

##### systemGestureInsetLeft

`number`

Left system gesture inset

##### physicalTouchSlop

`number`

Physical touch slop value

##### displayFeaturesBounds

`number`[]

Array of display feature bounds

##### displayFeaturesType

`number`[]

Array of display feature types

##### displayFeaturesState

`number`[]

Array of display feature states

#### Returns

`void`

***

### spawn()

> **spawn**(`entrypointFunctionName`, `pathToEntrypointFunction`, `initialRoute`, `entrypointArgs`): `FlutterNapi`

Spawns a new FlutterNapi instance from this instance.

#### Parameters

##### entrypointFunctionName

`string`

Name of the entrypoint function

##### pathToEntrypointFunction

`string`

Path to the entrypoint function

##### initialRoute

`string`

Initial route for navigation

##### entrypointArgs

`string`[]

Arguments to pass to the entrypoint function

#### Returns

`FlutterNapi`

A new FlutterNapi instance

***

### unregisterTexture()

> **unregisterTexture**(`textureId`): `void`

Unregisters a texture from the Flutter engine.

#### Parameters

##### textureId

`number`

The texture ID to unregister

#### Returns

`void`

***

### updateDensity()

> **updateDensity**(`densityPixels`): `void`

Updates the pixel density of the display.

#### Parameters

##### densityPixels

`number`

The pixel density value (dots per inch)

#### Returns

`void`

***

### updateRefreshRate()

> **updateRefreshRate**(`refreshRateFPS`): `void`

Updates the refresh rate for the Flutter engine.

#### Parameters

##### refreshRateFPS

`number`

The refresh rate in frames per second

#### Returns

`void`

***

### updateSize()

> **updateSize**(`width`, `height`): `void`

Updates the size of the Flutter view.

#### Parameters

##### width

`number`

The new width in pixels

##### height

`number`

The new height in pixels

#### Returns

`void`

***

### xComponentAttachFlutterEngine()

> **xComponentAttachFlutterEngine**(`xcomponentId`): `void`

Attaches a FlutterEngine to an XComponent.

#### Parameters

##### xcomponentId

`string`

The XComponent ID

#### Returns

`void`

***

### xComponentDetachFlutterEngine()

> **xComponentDetachFlutterEngine**(`xcomponentId`): `void`

Detaches a FlutterEngine from an XComponent.

#### Parameters

##### xcomponentId

`string`

The XComponent ID

#### Returns

`void`

***

### xComponentDisPatchMouseWheel()

> **xComponentDisPatchMouseWheel**(`xcomponentId`, `eventType`, `event`): `void`

Dispatches a mouse wheel event from an XComponent to the Flutter engine.

#### Parameters

##### xcomponentId

`string`

The XComponent ID

##### eventType

`string`

The type of the mouse wheel event

##### event

`PanGestureEvent`

The pan gesture event containing mouse wheel data

#### Returns

`void`

***

### xComponentPreDraw()

> **xComponentPreDraw**(`xcomponentId`, `width`, `height`): `void`

Pre-renders an XComponent.

#### Parameters

##### xcomponentId

`string`

The XComponent ID

##### width

`number`

The width of the component

##### height

`number`

The height of the component

#### Returns

`void`

***

### animationVoting()

> `static` **animationVoting**(`type`, `velocity`): `void`

Sends screen scrolling velocity to the native engine.

#### Parameters

##### type

`number`

The animation type

##### velocity

`number`

The current screen scrolling velocity

#### Returns

`void`

***

### checkLTPOSwitchState()

> `static` **checkLTPOSwitchState**(): `number`

Checks the LTPO (Low Temperature Polycrystalline Oxide) switch state.

#### Returns

`number`

The LTPO switch state value

***

### nativeLookupCallbackInformation()

> `static` **nativeLookupCallbackInformation**(`handle`): [`FlutterCallbackInformation`](../../../../view/FlutterCallbackInformation/classes/FlutterCallbackInformation.md)

Looks up callback information for a given handler.

#### Parameters

##### handle

`number`

The handler number

#### Returns

[`FlutterCallbackInformation`](../../../../view/FlutterCallbackInformation/classes/FlutterCallbackInformation.md)

The FlutterCallbackInformation, or null if not found

***

### prefetchDefaultFontManager()

> `static` **prefetchDefaultFontManager**(): `void`

Prefetches the default font manager.
This should be called before using fonts in the Flutter engine.

#### Returns

`void`

***

### prefetchFramesCfg()

> `static` **prefetchFramesCfg**(): `void`

Prefetches the frame rate configuration file.

#### Returns

`void`

***

### unicodeIsEmoji()

> `static` **unicodeIsEmoji**(`code`): `boolean`

Checks if a Unicode code point is an emoji.

#### Parameters

##### code

`number`

The Unicode code point

#### Returns

`boolean`

true if the code point is an emoji, false otherwise

***

### unicodeIsEmojiModifier()

> `static` **unicodeIsEmojiModifier**(`code`): `boolean`

Checks if a Unicode code point is an emoji modifier.

#### Parameters

##### code

`number`

The Unicode code point

#### Returns

`boolean`

true if the code point is an emoji modifier, false otherwise

***

### unicodeIsEmojiModifierBase()

> `static` **unicodeIsEmojiModifierBase**(`code`): `boolean`

Checks if a Unicode code point is an emoji modifier base.

#### Parameters

##### code

`number`

The Unicode code point

#### Returns

`boolean`

true if the code point is an emoji modifier base, false otherwise

***

### unicodeIsRegionalIndicatorSymbol()

> `static` **unicodeIsRegionalIndicatorSymbol**(`code`): `boolean`

Checks if a Unicode code point is a regional indicator symbol.

#### Parameters

##### code

`number`

The Unicode code point

#### Returns

`boolean`

true if the code point is a regional indicator symbol, false otherwise

***

### unicodeIsVariationSelector()

> `static` **unicodeIsVariationSelector**(`code`): `boolean`

Checks if a Unicode code point is a variation selector.

#### Parameters

##### code

`number`

The Unicode code point

#### Returns

`boolean`

true if the code point is a variation selector, false otherwise

***

### videoVoting()

> `static` **videoVoting**(`seconds`, `frameCount`): `void`

Sends video frame count to the native engine.

#### Parameters

##### seconds

`number`

The time duration in seconds

##### frameCount

`number`

The number of frames within the specified time duration

#### Returns

`void`
