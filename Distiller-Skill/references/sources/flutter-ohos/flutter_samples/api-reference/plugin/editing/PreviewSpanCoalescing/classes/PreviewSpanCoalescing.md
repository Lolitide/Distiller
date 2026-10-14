[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PreviewSpanCoalescing

## Constructors

### Constructor

> **new PreviewSpanCoalescing**(): `PreviewSpanCoalescing`

#### Returns

`PreviewSpanCoalescing`

## Methods

### overwriteSpanIfTextMismatch()

> `static` **overwriteSpanIfTextMismatch**(`stringCache`, `leftIdx`, `rightIdx`, `expected`): [`PreviewSpanOverwriteResult`](../interfaces/PreviewSpanOverwriteResult.md)

When [leftIdx, rightIdx) substring differs from expected preview text, replace that span with `expected`.

#### Parameters

##### stringCache

`string`

##### leftIdx

`number`

##### rightIdx

`number`

##### expected

`string`

#### Returns

[`PreviewSpanOverwriteResult`](../interfaces/PreviewSpanOverwriteResult.md)

***

### repairPreviewSpanIfDrifted()

> `static` **repairPreviewSpanIfDrifted**(`stringCache`, `leftIdx`, `rightIdx`, `previewText`): [`PreviewSpanRepairResult`](../interfaces/PreviewSpanRepairResult.md)

If cache[leftIdx, rightIdx) disagrees with preview text, rewrite span; if already equal but rightIdx lags, fix right only.

#### Parameters

##### stringCache

`string`

##### leftIdx

`number`

##### rightIdx

`number`

##### previewText

`string`

#### Returns

[`PreviewSpanRepairResult`](../interfaces/PreviewSpanRepairResult.md)

***

### syncCacheRightToPreviewLength()

> `static` **syncCacheRightToPreviewLength**(`stringCache`, `leftIdx`, `previewTextLen`, `oldRightIdx`): [`PreviewSpanSyncResult`](../interfaces/PreviewSpanSyncResult.md)

Align right index with preview length; remove stale UTF-16 units [computedRightIdx, oldRightIdx) when preview shrinks.

#### Parameters

##### stringCache

`string`

##### leftIdx

`number`

##### previewTextLen

`number`

##### oldRightIdx

`number`

#### Returns

[`PreviewSpanSyncResult`](../interfaces/PreviewSpanSyncResult.md)
