[**Flutter ETS API Documentation v1.0.0**](../../../README.md)

***

# Function: json5Tojson()

> **json5Tojson**(`json5Text`): `string`

Normalizes JSON5-like text to strict JSON by removing comments only (does not parse or validate JSON).

## Parameters

### json5Text

`string`

Source text that may include `//` or block comments

## Returns

`string`

The same logical content with comments stripped; suitable for `JSON.parse` if the remainder is valid JSON
