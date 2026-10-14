[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PreviewTextMergeContext

Working state for one IME `setPreviewText` / preview merge pass.
Fields are updated in order by PreviewTextStringMerge pipeline steps.

## Constructors

### Constructor

> **new PreviewTextMergeContext**(): `PreviewTextMergeContext`

#### Returns

`PreviewTextMergeContext`

## Properties

### effectiveText

> **effectiveText**: `string` = `''`

Final preview body written to cache and mPreviewText.

***

### hadActivePreview

> **hadActivePreview**: `boolean` = `false`

***

### imeFullBodyMode

> **imeFullBodyMode**: `boolean` = `false`

***

### imeText

> **imeText**: `string` = `''`

Raw IME callback text.

***

### oldLeft

> **oldLeft**: `number` = `0`

Document offset of preview left bound at merge entry.

***

### previewRangeSpliceEnd

> **previewRangeSpliceEnd**: `number` = `0`

***

### previewRangeSpliceInsLen

> **previewRangeSpliceInsLen**: `number` = `0`

***

### previewRangeSpliceStart

> **previewRangeSpliceStart**: `number` = `0`

Half-open [start, end) inside previous preview string for IME range splice.

***

### previewRangeSpliceUsed

> **previewRangeSpliceUsed**: `boolean` = `false`

***

### prevLen

> **prevLen**: `number` = `0`

***

### prevPreview

> **prevPreview**: `string` = `''`

Preview string before this merge.

***

### selEnd

> **selEnd**: `number` = `0`

***

### selStart

> **selStart**: `number` = `0`

***

### textForMerge

> **textForMerge**: `string` = `''`

Candidate full preview body after range-splice / corrections.
