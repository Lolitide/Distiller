[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterShellArgs

Encapsulates arguments for the Flutter shell.
This class provides methods to parse and manage command-line arguments
that are passed to the Flutter engine during initialization.

## Constructors

### Constructor

> **new FlutterShellArgs**(): `FlutterShellArgs`

#### Returns

`FlutterShellArgs`

## Properties

### args

> **args**: `Set`\<`string`\>

Command-line arguments for the Flutter shell.

***

### ARG\_CACHE\_SKSL

> `static` **ARG\_CACHE\_SKSL**: `string` = `"--cache-sksl"`

***

### ARG\_DART\_FLAGS

> `static` **ARG\_DART\_FLAGS**: `string` = `"--dart-flags="`

***

### ARG\_DISABLE\_SERVICE\_AUTH\_CODES

> `static` **ARG\_DISABLE\_SERVICE\_AUTH\_CODES**: `string` = `"--disable-service-auth-codes"`

***

### ARG\_DUMP\_SHADER\_SKP\_ON\_SHADER\_COMPILATION

> `static` **ARG\_DUMP\_SHADER\_SKP\_ON\_SHADER\_COMPILATION**: `string` = `"--dump-skp-on-shader-compilation"`

***

### ARG\_ENABLE\_DART\_PROFILING

> `static` **ARG\_ENABLE\_DART\_PROFILING**: `string` = `"--enable-dart-profiling"`

***

### ARG\_ENABLE\_IMPELLER

> `static` **ARG\_ENABLE\_IMPELLER**: `string` = `"--enable-impeller"`

***

### ARG\_ENABLE\_SOFTWARE\_RENDERING

> `static` **ARG\_ENABLE\_SOFTWARE\_RENDERING**: `string` = `"--enable-software-rendering"`

***

### ARG\_ENDLESS\_TRACE\_BUFFER

> `static` **ARG\_ENDLESS\_TRACE\_BUFFER**: `string` = `"--endless-trace-buffer"`

***

### ARG\_KEY\_CACHE\_SKSL

> `static` **ARG\_KEY\_CACHE\_SKSL**: `string` = `"cache-sksl"`

***

### ARG\_KEY\_DART\_FLAGS

> `static` **ARG\_KEY\_DART\_FLAGS**: `string` = `"dart-flags"`

***

### ARG\_KEY\_DISABLE\_SERVICE\_AUTH\_CODES

> `static` **ARG\_KEY\_DISABLE\_SERVICE\_AUTH\_CODES**: `string` = `"disable-service-auth-codes"`

***

### ARG\_KEY\_DUMP\_SHADER\_SKP\_ON\_SHADER\_COMPILATION

> `static` **ARG\_KEY\_DUMP\_SHADER\_SKP\_ON\_SHADER\_COMPILATION**: `string` = `"dump-skp-on-shader-compilation"`

***

### ARG\_KEY\_ENABLE\_DART\_PROFILING

> `static` **ARG\_KEY\_ENABLE\_DART\_PROFILING**: `string` = `"enable-dart-profiling"`

***

### ARG\_KEY\_ENABLE\_IMPELLER

> `static` **ARG\_KEY\_ENABLE\_IMPELLER**: `string` = `"enable-impeller"`

***

### ARG\_KEY\_ENABLE\_SOFTWARE\_RENDERING

> `static` **ARG\_KEY\_ENABLE\_SOFTWARE\_RENDERING**: `string` = `"enable-software-rendering"`

***

### ARG\_KEY\_ENDLESS\_TRACE\_BUFFER

> `static` **ARG\_KEY\_ENDLESS\_TRACE\_BUFFER**: `string` = `"endless-trace-buffer"`

***

### ARG\_KEY\_MSAA\_SAMPLES

> `static` **ARG\_KEY\_MSAA\_SAMPLES**: `string` = `"msaa-samples"`

***

### ARG\_KEY\_OBSERVATORY\_PORT

> `static` **ARG\_KEY\_OBSERVATORY\_PORT**: `string` = `"observatory-port"`

***

### ARG\_KEY\_PROFILE\_STARTUP

> `static` **ARG\_KEY\_PROFILE\_STARTUP**: `string` = `"profile-startup"`

Want / ability parameter key for enabling **startup profiling**. When set (typically boolean `true`), `fromWant` adds
`ARG_PROFILE_STARTUP` (`--profile-startup`) to the shell arguments passed to the Flutter engine, enabling VM / Dart
profiling during startup (same purpose as Flutter’s `--profile-startup` flag). Use when analyzing cold start or
first-frame performance.

***

### ARG\_KEY\_PURGE\_PERSISTENT\_CACHE

> `static` **ARG\_KEY\_PURGE\_PERSISTENT\_CACHE**: `string` = `"purge-persistent-cache"`

***

### ARG\_KEY\_SKIA\_DETERMINISTIC\_RENDERING

> `static` **ARG\_KEY\_SKIA\_DETERMINISTIC\_RENDERING**: `string` = `"skia-deterministic-rendering"`

***

### ARG\_KEY\_START\_PAUSED

> `static` **ARG\_KEY\_START\_PAUSED**: `string` = `"start-paused"`

***

### ARG\_KEY\_TRACE\_SKIA

> `static` **ARG\_KEY\_TRACE\_SKIA**: `string` = `"trace-skia"`

***

### ARG\_KEY\_TRACE\_SKIA\_ALLOWLIST

> `static` **ARG\_KEY\_TRACE\_SKIA\_ALLOWLIST**: `string` = `"trace-skia-allowlist"`

***

### ARG\_KEY\_TRACE\_STARTUP

> `static` **ARG\_KEY\_TRACE\_STARTUP**: `string` = `"trace-startup"`

***

### ARG\_KEY\_TRACE\_SYSTRACE

> `static` **ARG\_KEY\_TRACE\_SYSTRACE**: `string` = `"trace-systrace"`

***

### ARG\_KEY\_USE\_TEST\_FONTS

> `static` **ARG\_KEY\_USE\_TEST\_FONTS**: `string` = `"use-test-fonts"`

***

### ARG\_KEY\_VERBOSE\_LOGGING

> `static` **ARG\_KEY\_VERBOSE\_LOGGING**: `string` = `"verbose-logging"`

***

### ARG\_MSAA\_SAMPLES

> `static` **ARG\_MSAA\_SAMPLES**: `string` = `"--msaa-samples="`

***

### ARG\_OBSERVATORY\_PORT

> `static` **ARG\_OBSERVATORY\_PORT**: `string` = `"--observatory-port="`

***

### ARG\_PROFILE\_STARTUP

> `static` **ARG\_PROFILE\_STARTUP**: `string` = `"--profile-startup"`

Full shell flag forwarded to the engine: `--profile-startup`. Normally supplied indirectly via `ARG_KEY_PROFILE_STARTUP`
in the launch `Want`; you can also append it manually when building a `FlutterShellArgs` instance.

***

### ARG\_PURGE\_PERSISTENT\_CACHE

> `static` **ARG\_PURGE\_PERSISTENT\_CACHE**: `string` = `"--purge-persistent-cache"`

***

### ARG\_SKIA\_DETERMINISTIC\_RENDERING

> `static` **ARG\_SKIA\_DETERMINISTIC\_RENDERING**: `string` = `"--skia-deterministic-rendering"`

***

### ARG\_START\_PAUSED

> `static` **ARG\_START\_PAUSED**: `string` = `"--start-paused"`

***

### ARG\_TRACE\_SKIA

> `static` **ARG\_TRACE\_SKIA**: `string` = `"--trace-skia"`

***

### ARG\_TRACE\_SKIA\_ALLOWLIST

> `static` **ARG\_TRACE\_SKIA\_ALLOWLIST**: `string` = `"--trace-skia-allowlist="`

***

### ARG\_TRACE\_STARTUP

> `static` **ARG\_TRACE\_STARTUP**: `string` = `"--trace-startup"`

***

### ARG\_TRACE\_SYSTRACE

> `static` **ARG\_TRACE\_SYSTRACE**: `string` = `"--trace-systrace"`

***

### ARG\_USE\_TEST\_FONTS

> `static` **ARG\_USE\_TEST\_FONTS**: `string` = `"--use-test-fonts"`

***

### ARG\_VERBOSE\_LOGGING

> `static` **ARG\_VERBOSE\_LOGGING**: `string` = `"--verbose-logging"`

## Methods

### add()

> **add**(`arg`): `void`

Adds an argument to the set of shell arguments.

#### Parameters

##### arg

`string`

The argument string to add

#### Returns

`void`

***

### remove()

> **remove**(`arg`): `void`

Removes an argument from the set of shell arguments.

#### Parameters

##### arg

`string`

The argument string to remove

#### Returns

`void`

***

### toArray()

> **toArray**(): `string`[]

Converts the set of arguments to an array.

#### Returns

`string`[]

An array containing all shell arguments

***

### checkArg()

> `static` **checkArg**(`argKey`, `argFlag`, `want`, `flutterShellArgs`): `void`

Checks if an argument exists in the Want parameters and adds it to FlutterShellArgs if present.

#### Parameters

##### argKey

`string`

The key to look for in the Want parameters

##### argFlag

`string`

The command-line flag to add if the argument is present

##### want

`Want`

The Want object containing the parameters

##### flutterShellArgs

`FlutterShellArgs`

The FlutterShellArgs instance to add the flag to

#### Returns

`void`

***

### fromWant()

> `static` **fromWant**(`want`): `FlutterShellArgs`

Parses arguments from a Want object and creates a FlutterShellArgs instance.

#### Parameters

##### want

`Want`

The Want object containing the parameters

#### Returns

`FlutterShellArgs`

A FlutterShellArgs instance with parsed arguments
