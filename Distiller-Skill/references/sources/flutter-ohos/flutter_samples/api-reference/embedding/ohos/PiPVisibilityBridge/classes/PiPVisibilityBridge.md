[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: PiPVisibilityBridge

Process-global PiP visibility bridge.

`window.getGlobalWindowMode()` is a process-level API whose result is
identical regardless of which UIAbility calls it, so a single polling
timer and a single `pipVisible` flag are sufficient.

Multiple UIAbilities are handled via a `shownCount` reference counter:
polling only runs when *all* abilities are hidden (shownCount == 0).

## Constructors

### Constructor

> **new PiPVisibilityBridge**(): `PiPVisibilityBridge`

#### Returns

`PiPVisibilityBridge`

## Methods

### register()

> **register**(`listener`): `void`

#### Parameters

##### listener

`PiPVisibilityListener`

#### Returns

`void`

***

### unregister()

> **unregister**(`listener`): `void`

#### Parameters

##### listener

`PiPVisibilityListener`

#### Returns

`void`

***

### updateAbilityShown()

> **updateAbilityShown**(`shown`): `void`

#### Parameters

##### shown

`boolean`

#### Returns

`void`

***

### getInstance()

> `static` **getInstance**(): `PiPVisibilityBridge`

#### Returns

`PiPVisibilityBridge`
