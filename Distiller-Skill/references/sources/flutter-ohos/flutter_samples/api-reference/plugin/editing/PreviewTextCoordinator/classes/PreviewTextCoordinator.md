[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PreviewTextCoordinator

Preview display + channel sync; caret-outside merge uses Flutter `TextEditState` vs native doc.

## Constructors

### Constructor

> **new PreviewTextCoordinator**(): `PreviewTextCoordinator`

#### Returns

`PreviewTextCoordinator`

## Methods

### commitPreviewWhenCursorOutOfRange()

> `static` **commitPreviewWhenCursorOutOfRange**(`editable`, `editingState`, `notifySelectionToImc`): `boolean`

Flutter selection strictly after rightIdx: replace [leftIdx, rightIdx) when `editingState` carries a different mid than native.
EOF stale-echo shortcut does not apply if `docMid` has letter+apostrophe syllable boundaries.

#### Parameters

##### editable

[`ListenableEditingState`](../../ListenableEditingState/classes/ListenableEditingState.md)

##### editingState

[`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

##### notifySelectionToImc

[`NotifySelectionToImc`](../type-aliases/NotifySelectionToImc.md)

#### Returns

`boolean`

***

### composeDisplayState()

> `static` **composeDisplayState**(`editable`): [`DisplayState`](../interfaces/DisplayState.md)

Composes the display string and selection when preview text is active:
displayText = leftOfPreview + previewText + rightOfPreview.
Selection follows editable (display coordinates).
Set `composingStart` and `composingEnd` to `-1`: OpenHarmony preview text is not equivalent to Flutter's IME
composing range. Reporting a non-empty composing range while the caret sits inside the preview can cause
Flutter to omit or clip text after the insertion point (collapsed selection).

#### Parameters

##### editable

[`ListenableEditingState`](../../ListenableEditingState/classes/ListenableEditingState.md)

#### Returns

[`DisplayState`](../interfaces/DisplayState.md)

***

### displayStateToTextEditState()

> `static` **displayStateToTextEditState**(`display`): [`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

#### Parameters

##### display

[`DisplayState`](../interfaces/DisplayState.md)

#### Returns

[`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

***

### editingStatesEqualForChannel()

> `static` **editingStatesEqualForChannel**(`a`, `b`): `boolean`

#### Parameters

##### a

[`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

##### b

[`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

#### Returns

`boolean`

***

### safeTextEditStateForNativeDocument()

> `static` **safeTextEditStateForNativeDocument**(`text`, `selectionStart`, `selectionEnd`, `composingStart`, `composingEnd`): [`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

Clamp selection/composing to `text.length` for a safe `TextEditState`.

#### Parameters

##### text

`string`

##### selectionStart

`number`

##### selectionEnd

`number`

##### composingStart

`number`

##### composingEnd

`number`

#### Returns

[`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

***

### shouldSyncWithPreview()

> `static` **shouldSyncWithPreview**(`editable`): `boolean`

True when preview text is supported and the document still has an active preview span [leftIdx, rightIdx).

#### Parameters

##### editable

[`ListenableEditingState`](../../ListenableEditingState/classes/ListenableEditingState.md)

#### Returns

`boolean`

***

### syncEditingState()

> `static` **syncEditingState**(`editable`, `inputTargetId`, `configuration`, `updateChannel`, `updateChannelWithDeltas`, `notifySelectionToImc`, `frameworkSyncMeta?`): `void`

Chooses update path (delta / preview / normal) and performs channel update + IMC notify.
Call this from EditingStateWatcher.didChangeEditingState to keep the listener thin.

#### Parameters

##### editable

[`ListenableEditingState`](../../ListenableEditingState/classes/ListenableEditingState.md)

##### inputTargetId

`number`

##### configuration

[`Configuration`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/Configuration.md)

##### updateChannel

[`UpdateChannelState`](../type-aliases/UpdateChannelState.md)

##### updateChannelWithDeltas

[`UpdateChannelWithDeltas`](../type-aliases/UpdateChannelWithDeltas.md)

##### notifySelectionToImc

[`NotifySelectionToImc`](../type-aliases/NotifySelectionToImc.md)

##### frameworkSyncMeta?

[`FrameworkOutgoingSyncMeta`](../interfaces/FrameworkOutgoingSyncMeta.md)

#### Returns

`void`
