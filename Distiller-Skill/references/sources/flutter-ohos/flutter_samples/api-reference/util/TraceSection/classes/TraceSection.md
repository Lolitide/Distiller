[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: TraceSection

Utility class for tracing code sections using hiTraceMeter.
Provides methods to begin and end trace sections with automatic name cropping.

## Constructors

### Constructor

> **new TraceSection**(): `TraceSection`

#### Returns

`TraceSection`

## Properties

### taskId

> `static` **taskId**: `number` = `0`

The current task ID for trace sections.

## Methods

### begin()

> `static` **begin**(`sectionName`): `number`

Wraps Trace.beginSection to ensure that the line length stays below 127 code units.

#### Parameters

##### sectionName

`string`

The string to display as the section name in the trace

#### Returns

`number`

The task ID for this trace section

***

### end()

> `static` **end**(`sectionName`): `void`

Ends a trace section.

#### Parameters

##### sectionName

`string`

The section name to end.

#### Returns

`void`

***

### endWithId()

> `static` **endWithId**(`sectionName`, `id`): `void`

Ends a trace section with a specific task ID.

#### Parameters

##### sectionName

`string`

The section name to end.

##### id

`number`

The task ID to use.

#### Returns

`void`
