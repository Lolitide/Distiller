[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: ListenableEditingState

Text/selection/composing + OHOS preview span; mirrors Android ListenableEditingState. Flutter sync via `updateTextInputState` / `TextInputMethodHandlerImpl.setEditingState`.

## Constructors

### Constructor

> **new ListenableEditingState**(`TextInputChannel`, `client`, `keyEventChannel?`): `ListenableEditingState`

Constructs a new ListenableEditingState instance.

#### Parameters

##### TextInputChannel

`any`

The TextInputChannel for communication, possibly null

##### client

`number`

The client ID

##### keyEventChannel?

`KeyEventChannel`

Optional KeyEventChannel for key event handling

#### Returns

`ListenableEditingState`

## Methods

### addEditingStateListener()

> **addEditingStateListener**(`listener`): `void`

Adds a listener to be notified of editing state changes.

#### Parameters

##### listener

[`EditingStateWatcher`](../interfaces/EditingStateWatcher.md)

The listener to add

#### Returns

`void`

***

### applyExternalDocumentSelectionWhilePreviewStaging()

> **applyExternalDocumentSelectionWhilePreviewStaging**(`docStart`, `docEnd`): `void`

Flutter/Framework writes selection while preview staging: update both document coords and internal relative pair.

#### Parameters

##### docStart

`number`

##### docEnd

`number`

#### Returns

`void`

***

### beginBatchEdit()

> **beginBatchEdit**(): `void`

Begins a batch edit operation.
Multiple edits can be batched together to reduce notifications.

#### Returns

`void`

***

### captureEditingSnapshot()

> **captureEditingSnapshot**(): [`EditingStateSnapshot`](../interfaces/EditingStateSnapshot.md)

Capture current native editing state (single truth for Framework: full cache + selection + composing).

#### Returns

[`EditingStateSnapshot`](../interfaces/EditingStateSnapshot.md)

***

### clearBatchDeltas()

> **clearBatchDeltas**(): `void`

Clears all batched text editing deltas.

#### Returns

`void`

***

### clearPreviewStagingFieldsOnly()

> **clearPreviewStagingFieldsOnly**(): `void`

Clear preview staging metadata only; do not change mStringCache (use when body was already written by caller).

#### Returns

`void`

***

### clearPreviewTextContents()

> **clearPreviewTextContents**(): `void`

Clears all preview text contents and resets related indices.

#### Returns

`void`

***

### coalescePreviewSpanWithCache()

> **coalescePreviewSpanWithCache**(): `void`

Align mRightIdx with mPreviewText and rewrite [leftIdx,rightIdx) in cache from mPreviewText (metadata wins).
Call before IME setPreviewText / pushing display to Flutter so lagging rightIdx does not duplicate tail via substring(rightIdx)
(candidates OK but field gains chars / misaligns on second Backspace).

#### Returns

`void`

***

### commitLeadingLatinPreviewWhenCaretOutsideSpan()

> **commitLeadingLatinPreviewWhenCaretOutsideSpan**(): `boolean`

Collapsed caret strictly before leftIdx or after rightIdx; span is ASCII `'` + lowercase latin tail [2,8];
char before leftIdx is BMP CJK; only supported tail today is `hao` → `好`. Caller should apply selection first.

#### Returns

`boolean`

true if span was replaced (staging cleared via `handleInsertTextEvent`).

***

### consumeImcFullSyncAfterPreviewInsert()

> **consumeImcFullSyncAfterPreviewInsert**(): `boolean`

#### Returns

`boolean`

***

### consumeStaleEndEchoSkipCredit()

> **consumeStaleEndEchoSkipCredit**(): `void`

Call when a Framework selection echo pinned at preview end was skipped; decrements remaining skip budget.

#### Returns

`void`

***

### discardPreviewStagingMetadata()

> **discardPreviewStagingMetadata**(): `void`

Drop preview session: clear staging metadata only; do not merge preview into mStringCache (Flutter updateTextInputState usually follows).

#### Returns

`void`

***

### endBatchEdit()

> **endBatchEdit**(): `void`

Ends a batch edit operation and notifies listeners of all changes.

#### Returns

`void`

***

### endDeletion()

> **endDeletion**(`code`): `void`

Marks the end of a deletion operation.

#### Parameters

##### code

`number`

The key code that triggered the deletion

#### Returns

`void`

***

### extractBatchTextEditingDeltas()

> **extractBatchTextEditingDeltas**(): `ArrayList`\<[`TextEditingDelta`](../../TextEditingDelta/classes/TextEditingDelta.md)\>

Extracts and clears the batch of text editing deltas.

#### Returns

`ArrayList`\<[`TextEditingDelta`](../../TextEditingDelta/classes/TextEditingDelta.md)\>

A list of TextEditingDelta objects representing the changes

***

### getComposingEnd()

> **getComposingEnd**(): `number`

Gets the current composing region end position.

#### Returns

`number`

The composing end position, or -1 if no composing region

***

### getComposingStart()

> **getComposingStart**(): `number`

Gets the current composing region start position.

#### Returns

`number`

The composing start position, or -1 if no composing region

***

### getIsCursorIdxOutOfPreviewTextRange()

> **getIsCursorIdxOutOfPreviewTextRange**(): `boolean`

Gets whether the cursor index is out of the preview text range.

#### Returns

`boolean`

True if the cursor is out of range, false otherwise

***

### getLeftIdxOfPreviewTextRange()

> **getLeftIdxOfPreviewTextRange**(): `number`

Gets the left index of the preview text range in the string cache.

#### Returns

`number`

The left index of the preview text range

***

### getLeftTextOfCursor()

> **getLeftTextOfCursor**(`length`): `string`

Gets the text to the left of the cursor.

#### Parameters

##### length

`number`

The maximum number of characters to return

#### Returns

`string`

The text to the left of the cursor

***

### getPreviewText()

> **getPreviewText**(): `string`

Gets the current preview text from the input method.

#### Returns

`string`

The preview text

***

### getPreviewTextEnd()

> **getPreviewTextEnd**(): `number`

Gets the end position of the preview text in the original text.

#### Returns

`number`

The preview text end position

***

### getPreviewTextStart()

> **getPreviewTextStart**(): `number`

Gets the start position of the preview text in the original text.

#### Returns

`number`

The preview text start position

***

### getRightIdxOfPreviewTextRange()

> **getRightIdxOfPreviewTextRange**(): `number`

Gets the right index of the preview text range in the string cache.

#### Returns

`number`

The right index of the preview text range

***

### getRightTextOfCursor()

> **getRightTextOfCursor**(`length`): `string`

Gets the text to the right of the cursor.

#### Parameters

##### length

`number`

The maximum number of characters to return

#### Returns

`string`

The text to the right of the cursor

***

### getSelectionEnd()

> **getSelectionEnd**(): `number`

Gets the current selection end position.

#### Returns

`number`

The selection end position

***

### getSelectionStart()

> **getSelectionStart**(): `number`

Gets the current selection start position.

#### Returns

`number`

The selection start position

***

### getSelectionString()

> **getSelectionString**(): `string`

Gets the currently selected text.

#### Returns

`string`

The selected text, or empty string if selection is invalid

***

### getSkipFlutterStaleEndEchoRemaining()

> **getSkipFlutterStaleEndEchoRemaining**(): `number`

#### Returns

`number`

***

### getStagingComposedText()

> **getStagingComposedText**(): `string`

Current displayed full text (during preview this is the sole local string, including preview run).

#### Returns

`string`

***

### getStringCache()

> **getStringCache**(): `string`

Gets the current text content.

#### Returns

`string`

The text string

***

### handleDeleteEvent()

> **handleDeleteEvent**(`leftOrRight`, `length`, `enableDeltaModel`): `void`

Handles a delete event from the input method.

#### Parameters

##### leftOrRight

`boolean`

True for delete right (forward delete), false for delete left (backspace)

##### length

`number`

The number of characters to delete

##### enableDeltaModel

`boolean`

Whether delta model is enabled

#### Returns

`void`

***

### handleExtendActionEvent()

> **handleExtendActionEvent**(`action`): `void`

Handles extended actions like select all, cut, copy, and paste.

#### Parameters

##### action

`ExtendAction`

The action to perform

#### Returns

`void`

***

### handleFunctionKey()

> **handleFunctionKey**(`functionKey`): `void`

Handles a function key event from the input method.

#### Parameters

##### functionKey

`FunctionKey`

The function key that was pressed

#### Returns

`void`

***

### handleInsertPreviewTextEvent()

> **handleInsertPreviewTextEvent**(`text`, `range`): `void`

IME `setPreviewText`: merge into `mStringCache` span [leftIdx,rightIdx), fold apostrophes, map caret. Rules live in
`PreviewTextStringMerge` + `applyImePreviewCaretAfterMerge`; sets `mImcFullSyncAfterPreviewInsert` for handler sync.

#### Parameters

##### text

`string`

##### range

`Range`

#### Returns

`void`

***

### handleInsertTextEvent()

> **handleInsertTextEvent**(`text`, `options?`): `void`

Handles insertion of final text from the input method.

#### Parameters

##### text

`string`

The text to insert

##### options?

[`PreviewInsertOptions`](../interfaces/PreviewInsertOptions.md)

Optional policy for preview commit (e.g. English preview range + suffix). Applied by caller.

#### Returns

`void`

***

### handleMoveCursorEvent()

> **handleMoveCursorEvent**(`direction`): `void`

Handles cursor movement events in 2D text.

#### Parameters

##### direction

`Direction`

The direction to move the cursor

#### Returns

`void`

***

### handleNewlineEvent()

> **handleNewlineEvent**(): `void`

Handles a newline event from the input method.

#### Returns

`void`

***

### handleSelectByMovementEvent()

> **handleSelectByMovementEvent**(`movement`): `void`

Handles text selection changes with cursor movement.

#### Parameters

##### movement

`Movement`

The movement that triggers the selection change

#### Returns

`void`

***

### handleSelectByRangeEvent()

> **handleSelectByRangeEvent**(`range`): `void`

Handles a text selection by range event.

#### Parameters

##### range

`Range`

The range to select

#### Returns

`void`

***

### isPreviewStagingActive()

> **isPreviewStagingActive**(): `boolean`

True when document preview span leftIdx < rightIdx (independent of whether `mPreviewText` is temporarily empty).

#### Returns

`boolean`

***

### markSkipNextFlutterSelectionApplyOnce()

> **markSkipNextFlutterSelectionApplyOnce**(): `void`

#### Returns

`void`

***

### notifyListener()

> **notifyListener**(`listener`, `textChanged`, `selectionChanged`, `composingChanged`): `void`

Notifies a single listener of editing state changes.

#### Parameters

##### listener

[`EditingStateWatcher`](../interfaces/EditingStateWatcher.md)

The listener to notify

##### textChanged

`boolean`

Whether the text has changed

##### selectionChanged

`boolean`

Whether the selection has changed

##### composingChanged

`boolean`

Whether the composing region has changed

#### Returns

`void`

***

### notifyListenersIfChangedSince()

> **notifyListenersIfChangedSince**(`before`): `void`

Diff vs snapshot for text / selection / composing, then notify (same idea as Android replace tail + endBatchEdit).

#### Parameters

##### before

[`EditingStateSnapshot`](../interfaces/EditingStateSnapshot.md)

#### Returns

`void`

***

### notifyListenersIfNeeded()

> **notifyListenersIfNeeded**(`textChanged`, `selectionChanged`, `composingChanged`): `void`

Notifies all listeners if any changes have occurred.

#### Parameters

##### textChanged

`boolean`

Whether the text has changed

##### selectionChanged

`boolean`

Whether the selection has changed

##### composingChanged

`boolean`

Whether the composing region has changed

#### Returns

`void`

***

### removeEditingStateListener()

> **removeEditingStateListener**(`listener`): `void`

Removes an editing state listener.

#### Parameters

##### listener

[`EditingStateWatcher`](../interfaces/EditingStateWatcher.md)

The listener to remove

#### Returns

`void`

***

### replace()

> **replace**(`start`, `end`, `tb`, `tbStart`, `tbEnd`): `void`

Replaces a range of text with new text.

#### Parameters

##### start

`number`

The start position of the range to replace

##### end

`number`

The end position of the range to replace

##### tb

`String`

The replacement text

##### tbStart

`number`

The start position within the replacement text

##### tbEnd

`number`

The end position within the replacement text

#### Returns

`void`

***

### setComposingEnd()

> **setComposingEnd**(`newComposingEnd`): `void`

Sets the composing region end position.

#### Parameters

##### newComposingEnd

`number`

The new composing end position, or -1 to clear

#### Returns

`void`

***

### setComposingStart()

> **setComposingStart**(`newComposingStart`): `void`

Sets the composing region start position.

#### Parameters

##### newComposingStart

`number`

The new composing start position, or -1 to clear

#### Returns

`void`

***

### setIsCursorIdxOutOfPreviewTextRange()

> **setIsCursorIdxOutOfPreviewTextRange**(`hasChanged`): `void`

Sets whether the cursor index is out of the preview text range.

#### Parameters

##### hasChanged

`boolean`

True if the cursor is out of range, false otherwise

#### Returns

`void`

***

### setPreviewText()

> **setPreviewText**(`previewText`): `void`

Sets the preview text.

#### Parameters

##### previewText

`string`

The preview text to set

#### Returns

`void`

***

### setPreviewTextEnd()

> **setPreviewTextEnd**(`previewTextEnd`): `void`

Sets the end position of the preview text.

#### Parameters

##### previewTextEnd

`number`

The end position

#### Returns

`void`

***

### setPreviewTextStart()

> **setPreviewTextStart**(`previewTextStart`): `void`

Sets the start position of the preview text.

#### Parameters

##### previewTextStart

`number`

The start position

#### Returns

`void`

***

### setSelectionEnd()

> **setSelectionEnd**(`newSelectionEnd`): `void`

Sets the selection end position.

#### Parameters

##### newSelectionEnd

`number`

The new selection end position

#### Returns

`void`

***

### setSelectionStart()

> **setSelectionStart**(`newSelectionStart`): `void`

Sets the selection start position.

#### Parameters

##### newSelectionStart

`number`

The new selection start position

#### Returns

`void`

***

### setStringCache()

> **setStringCache**(`newStringCache`): `void`

Sets the text content.

#### Parameters

##### newStringCache

`string`

The new text content

#### Returns

`void`

***

### startDeleting()

> **startDeleting**(`code`): `void`

Marks the start of a deletion operation.

#### Parameters

##### code

`number`

The key code that triggered the deletion

#### Returns

`void`

***

### updatePreviewTextRange()

> **updatePreviewTextRange**(`leftIdx`, `rightIdx`): `void`

Updates the preview text range indices.

#### Parameters

##### leftIdx

`number`

The left index in the string cache

##### rightIdx

`number`

The right index in the string cache

#### Returns

`void`

***

### updateTextInputState()

> **updateTextInputState**(`state`): `void`

Updates the text input state from Flutter.

#### Parameters

##### state

[`TextEditState`](../../../../embedding/engine/systemchannels/TextInputChannel/classes/TextEditState.md)

The new text edit state

#### Returns

`void`

***

### isImeSegmentApostropheLikeChar()

> `static` **isImeSegmentApostropheLikeChar**(`segmentChar`): `boolean`

IME-style syllable boundary: ASCII `'` and common Unicode apostrophe variants.

#### Parameters

##### segmentChar

`string`

#### Returns

`boolean`
