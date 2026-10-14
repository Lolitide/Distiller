[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PreviewTextStringMerge

Stateless helpers for preview text merging, tail-shrink picking, and caret mapping.

## Constructors

### Constructor

> **new PreviewTextStringMerge**(): `PreviewTextStringMerge`

#### Returns

`PreviewTextStringMerge`

## Methods

### applyFullBodySuffixStitch()

> `static` **applyFullBodySuffixStitch**(`ctx`): `void`

Stitch suffix-only IME full-body when caret inside preview.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### applyLocalFullBodyPreviewMerge()

> `static` **applyLocalFullBodyPreviewMerge**(`ctx`): `void`

Full-body preview merge: shrink uses local one-step rules (`L'R`, `getImePreviewBackspaceDeleteRange`, `pick…`).
When the IME body is a **strict UTF-16 prefix** shorter than `prev` and the caret lies **in the removed suffix**
(`offset >= len(ime)`), use **`ime`** so pre-edit text matches candidates (e.g. `z'n'x'h` + `z'n'x` at tail — local
bk can wrongly yield `z'n'h`). If the caret is still **inside** the kept prefix (`offset < len(ime)`), keep local bk.
Growth / same-length updates use the IME callback string as the whole body. `ListenableEditingState` forces full IMC sync.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### collapseConsecutiveImeApostrophesInPreview()

> `static` **collapseConsecutiveImeApostrophesInPreview**(`text`): `string`

Mid-preview edits must not leave adjacent IME apostrophe-like code units (`''`, `'`+U+2019, …);
fold every consecutive pair to one ASCII `'` (e.g. letter delete at `h'|s` after skipping `'`).

#### Parameters

##### text

`string`

#### Returns

`string`

***

### collapseConsecutiveImeApostrophesInPreviewAndCaret()

> `static` **collapseConsecutiveImeApostrophesInPreviewAndCaret**(`previewText`, `caretRel`): [`PreviewCollapseApostropheCaretResult`](../interfaces/PreviewCollapseApostropheCaretResult.md)

Same as [collapseConsecutiveImeApostrophesInPreview](#collapseconsecutiveimeapostrophesinpreview), but keeps a preview-relative caret
aligned when code units before it are removed (pairs at `runStart`,`runStart+1` → one `'` at `runStart`).

#### Parameters

##### previewText

`string`

##### caretRel

`number`

#### Returns

[`PreviewCollapseApostropheCaretResult`](../interfaces/PreviewCollapseApostropheCaretResult.md)

***

### computeEffectiveTextAfterShrinkRules()

> `static` **computeEffectiveTextAfterShrinkRules**(`ctx`): `void`

Preview body after merge; no IME-vs-local effective override.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### correctDuplicativeOpeningTextSplice()

> `static` **correctDuplicativeOpeningTextSplice**(`ctx`): `void`

Undo mistaken “duplicative opening” range splice for segmented pinyin.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### detectSingleInsertOffsetInPreview()

> `static` **detectSingleInsertOffsetInPreview**(`prev`, `next`): `number`

If prev→next is one contiguous insert of delta code units at some offset, return that offset; else -1.

#### Parameters

##### prev

`string`

##### next

`string`

#### Returns

`number`

***

### dropMisleadingSpanEndSpliceForMidCaret()

> `static` **dropMisleadingSpanEndSpliceForMidCaret**(`ctx`): `void`

Drop misleading span-end range when caret is left of splice (tap mid-preview + Backspace).

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### fixBareApostropheInsertWithoutSegmentMarker()

> `static` **fixBareApostropheInsertWithoutSegmentMarker**(`ctx`): `void`

prev has no `'` but IME full body adds segment apostrophes — rebare-append at caret.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### fixUtf16SuffixAppendAtMidCaret()

> `static` **fixUtf16SuffixAppendAtMidCaret**(`ctx`): `void`

Full-body: IME appends at UTF-16 end while caret is mid — rotate insertion to caret.
Aligns insert product rule (new text left of caret; caret after insert), not tail-only append.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### initPreviewRangeSplice()

> `static` **initPreviewRangeSplice**(`ctx`, `rangeStart`, `rangeEnd`): `void`

OHOS: range.start/end ≥ 0 → splice inside previous preview string.
When the preview span does not start at document 0 (`oldLeft > 0`), `range` is usually in **document** coordinates;
convert splice bounds by subtracting `oldLeft` when `rangeStart >= oldLeft` so mid-preview insert (e.g. doc 6..11 + ime) maps to
preview 0..5, not mistaken preview indices 6..11 (clamped) which yield `z'm'z'y`.

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

##### rangeStart

`number`

##### rangeEnd

`number`

#### Returns

`void`

***

### isImePreviewApostropheLikeChar()

> `static` **isImePreviewApostropheLikeChar**(`segmentChar`): `boolean`

Matches TextUtils.isOnlyImePreviewApostropheRun: common IME segment apostrophe code units (incl. non-ASCII).

#### Parameters

##### segmentChar

`string`

#### Returns

`boolean`

***

### pickCaretLeftDeleteForImePreviewTailShrink()

> `static` **pickCaretLeftDeleteForImePreviewTailShrink**(`prev`, `offset`): `string`

When the caret is not at the preview end: enforce **preview invariant 1** (one Backspace step
left of the caret only), do not accept IME “tail shrink” substitutes.
- If `[delPlain,offset)` is apostrophes only: take plainBk if it does not introduce illegal `''`
  (x'|j→xj); else try ext so ext does not swallow the syllable’s first letter leaving only j.
- After plain deletes one char, if x''z appears: try collapsing first `''`→`'`, unless `''`
  bridged a letter in prev; then consider extended Backspace.

#### Parameters

##### prev

`string`

##### offset

`number`

#### Returns

`string`

***

### previewBareForTailShrinkCompare()

> `static` **previewBareForTailShrinkCompare**(`text`): `string`

Strip IME pinyin segment markers `'` before deciding if only the preview tail was removed.
Otherwise abc'de'f'g → abc'de'f is not a strict UTF-16 prefix (trailing `'` vs none), and
mid-string caret correction would be missed.

#### Parameters

##### text

`string`

#### Returns

`string`

***

### previewCaretAfterDeletionUsingBareStrings()

> `static` **previewCaretAfterDeletionUsingBareStrings**(`prev`, `next`, `caretInPrev`): `number`

e.g. a'b'l'c → abc: non-contiguous UTF-16 deletes break previewCaretAfterSingleDeletion; post-Backspace
clamp pins mid-string caret to end. Recompute delete geometry on bare strings without `'` and map back to next UTF-16.

#### Parameters

##### prev

`string`

##### next

`string`

##### caretInPrev

`number`

#### Returns

`number`

***

### previewCaretAfterInsertionAtLocalCaret()

> `static` **previewCaretAfterInsertionAtLocalCaret**(`prev`, `next`, `caretInPrev`): `number`

When LCP-based insert detection fails, assume delta code units were inserted at local caret caretInPrev (common IME behavior).

#### Parameters

##### prev

`string`

##### next

`string`

##### caretInPrev

`number`

#### Returns

`number`

***

### previewCaretAfterSingleDeletion()

> `static` **previewCaretAfterSingleDeletion**(`prev`, `next`, `caretInPrev`): `number`

IME shortens preview once: assume one contiguous delete of delLen code units; returns folded caret
after the deleted block under **invariant 1**; -1 if geometry cannot be recognized.

#### Parameters

##### prev

`string`

##### next

`string`

##### caretInPrev

`number`

#### Returns

`number`

***

### previewCaretAfterSingleInsertion()

> `static` **previewCaretAfterSingleInsertion**(`prev`, `next`, `caretInPrev`): `number`

IME lengthens preview once: assume delta code units inserted at insStart; returns folded caret under
**invariant 2** (right of the new insertion); -1 if unrecognized.

#### Parameters

##### prev

`string`

##### next

`string`

##### caretInPrev

`number`

#### Returns

`number`

***

### previewHasConsecutiveImeApostropheRun()

> `static` **previewHasConsecutiveImeApostropheRun**(`text`): `boolean`

Whether two adjacent apostrophe-like code units exist (mixing U+2019 with ASCII breaks indexOf("''")).

#### Parameters

##### text

`string`

#### Returns

`boolean`

***

### previewIndexOfFirstConsecutiveImeApostropheRun()

> `static` **previewIndexOfFirstConsecutiveImeApostropheRun**(`text`): `number`

#### Parameters

##### text

`string`

#### Returns

`number`

***

### previewIntroducesNewConsecutiveApostropheRun()

> `static` **previewIntroducesNewConsecutiveApostropheRun**(`prev`, `candidate`): `boolean`

Whether candidate introduces a new illegal consecutive-apostrophe run that prev did not have.

#### Parameters

##### prev

`string`

##### candidate

`string`

#### Returns

`boolean`

***

### previewMapCaretAfterPreviewRangeReplace()

> `static` **previewMapCaretAfterPreviewRangeReplace**(`prevLen`, `rangeStart`, `rangeEnd`, `insLen`, `caretInPrev`): `number`

After IME replaces preview range [rangeStart, rangeEnd) with `insLen` UTF-16 code units (this callback’s text),
map the **old-string** folded caret into the new string. When rangeStart===rangeEnd it is pure insert
(delSpan=0): caret at and right of the insertion point shifts by insLen.

#### Parameters

##### prevLen

`number`

##### rangeStart

`number`

##### rangeEnd

`number`

##### insLen

`number`

##### caretInPrev

`number`

#### Returns

`number`

***

### previewSharedUtf16PrefixLen()

> `static` **previewSharedUtf16PrefixLen**(`prev`, `candidate`): `number`

UTF-16 shared prefix length between prev and candidate (code-unit equality).

#### Parameters

##### prev

`string`

##### candidate

`string`

#### Returns

`number`

***

### previewStitchSuffixOnlyImeFullBodyIfNeeded()

> `static` **previewStitchSuffixOnlyImeFullBodyIfNeeded**(`prevPreview`, `imeText`, `caretRelInPreview`): `string`

In full-preview callbacks the IME sometimes sends only the UTF-16 suffix of the previous preview
(not a strict-prefix tail trim); splicing blindly drops the left syllables
(e.g. prev=a'h'x'j's, ime=x'j's). When both contain `'` segments and the folded caret is near
the suffix start, treat text as a suffix and restore full prev.

#### Parameters

##### prevPreview

`string`

##### imeText

`string`

##### caretRelInPreview

`number`

#### Returns

`string`

***

### repairPreviewRangeSpliceWhenDisagreesWithLocalOneStepBackspace()

> `static` **repairPreviewRangeSpliceWhenDisagreesWithLocalOneStepBackspace**(`ctx`): `void`

Mid-preview Backspace: OHOS may deliver a range splice (start/end) + short `ime` that stitches garbage
(e.g. `z'm'h'z'y'a` + replace [4,9) with `z'm` → `z'm'z'm'a`) while the caret is inside the preview. One local
`getImePreviewBackspaceDeleteRange` step at the caret (e.g. delete `h` → `z'm'z'y'a`) matches product rules; if it
disagrees with the splice merge, drop the splice and use the local string (non–full-body so later steps do not
re-run tail-shrink on the wrong IME payload).

#### Parameters

##### ctx

[`PreviewTextMergeContext`](../../PreviewTextMergeContext/classes/PreviewTextMergeContext.md)

#### Returns

`void`

***

### shouldKeepSuffixForCaretLeftUnitInLApostropheRThreePreview()

> `static` **shouldKeepSuffixForCaretLeftUnitInLApostropheRThreePreview**(`prevPreview`, `offsetInPreview`): `boolean`

Exactly `L'R` (three UTF-16 units: non-apostrophe, IME apostrophe-like, non-apostrophe) with the caret
immediately before `R`. One user unit left of the caret is `L'` (marker is not deleted alone); result is `R`
(`z'|a`→`a`, `x'|h`→`h`).

#### Parameters

##### prevPreview

`string`

##### offsetInPreview

`number`

#### Returns

`boolean`
