[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: StatusBarClickChannel

System channel that notifies the Flutter framework when the OpenHarmony status bar is tapped.

[`FlutterView`](../../../../../view/FlutterView/classes/FlutterView.md) registers for `usual.event.CLICK_STATUSBAR`
via common-event subscription; when an event is delivered, `sendClick()` invokes `handleScrollToTop` on the Dart
side over channel `flutter/status_bar` (typically scroll-to-top / primary scroll reset behavior).

## Constructors

### Constructor

> **new StatusBarClickChannel**(`binaryMessenger`): `StatusBarClickChannel`

Creates the channel on the given Dart isolate messenger.

#### Parameters

##### binaryMessenger

[`BinaryMessenger`](../../../../../plugin/common/BinaryMessenger/interfaces/BinaryMessenger.md)

Binary messenger from the Dart executor used to send platform messages to Flutter.

#### Returns

`StatusBarClickChannel`

## Methods

### sendClick()

> **sendClick**(): `void`

Sends a status-bar click notification to Flutter by invoking `handleScrollToTop` on `flutter/status_bar`.

Call when the embedding has received a confirmed status-bar click from the system common-event pipeline (for example
after `FlutterView.onStatusBarClick` completes subscription and events arrive). Flutter handles the method on the
framework side; invoke from the appropriate runner/thread context for your embedding.

#### Returns

`void`
