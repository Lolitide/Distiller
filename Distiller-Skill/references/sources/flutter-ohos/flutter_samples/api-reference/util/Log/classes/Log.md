[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Class: Log

Basic log class

## Constructors

### Constructor

> **new Log**(): `Log`

#### Returns

`Log`

## Methods

### d()

> `static` **d**(`tag`, `format`, ...`args`): `void`

Outputs debug-level logs.

#### Parameters

##### tag

`string`

The log tag

##### format

`string`

The log format string

##### args

...`Object`[]

The log parameters

#### Returns

`void`

#### Since

7

***

### e()

> `static` **e**(`tag`, `format`, ...`args`): `void`

Outputs error-level logs.

#### Parameters

##### tag

`string`

The log tag

##### format

`string`

The log format string

##### args

...`Object`[]

The log parameters

#### Returns

`void`

#### Since

7

***

### f()

> `static` **f**(`tag`, `format`, ...`args`): `void`

Outputs fatal-level logs.

#### Parameters

##### tag

`string`

The log tag

##### format

`string`

The log format string

##### args

...`Object`[]

The log parameters

#### Returns

`void`

#### Since

7

***

### i()

> `static` **i**(`tag`, `format`, ...`args`): `void`

Outputs info-level logs.

#### Parameters

##### tag

`string`

The log tag

##### format

`string`

The log format string

##### args

...`Object`[]

The log parameters

#### Returns

`void`

#### Since

7

***

### setLogLevel()

> `static` **setLogLevel**(`level`): `void`

Sets the log level.

#### Parameters

##### level

`LogLevel`

The log level

#### Returns

`void`

***

### w()

> `static` **w**(`tag`, `format`, ...`args`): `void`

Outputs warning-level logs.

#### Parameters

##### tag

`string`

The log tag

##### format

`string`

The log format string

##### args

...`Object`[]

The log parameters

#### Returns

`void`

#### Since

7
