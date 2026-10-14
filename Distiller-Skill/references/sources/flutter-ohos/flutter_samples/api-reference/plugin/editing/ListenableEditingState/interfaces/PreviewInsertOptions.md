[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Interface: PreviewInsertOptions

Options for inserting text when committing preview (e.g. English preview add space).
Policy is applied by the caller (Handler/Coordinator), not by the state.

## Properties

### appendSuffix?

> `optional` **appendSuffix**: `string`

***

### previewEnd?

> `optional` **previewEnd**: `number`

***

### previewStart?

> `optional` **previewStart**: `number`

***

### retainPreviewRangeAfterCommit?

> `optional` **retainPreviewRangeAfterCommit**: `boolean`

When true, keep [leftIdx,rightIdx) preview span metadata after replace so a following IME insertText (e.g. CJK candidate)
can still replace the pinyin span. Used by finishTextPreview when committing a leading-segment-marker tail like `'hao`.

***

### usePreviewRange

> **usePreviewRange**: `boolean`
