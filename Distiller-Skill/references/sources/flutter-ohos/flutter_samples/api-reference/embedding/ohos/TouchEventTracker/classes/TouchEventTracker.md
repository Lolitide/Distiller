[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: TouchEventTracker

Tracks touch events and provides unique identifiers for them.
This class maintains a singleton instance for managing touch event tracking.

## Constructors

### Constructor

> **new TouchEventTracker**(): `TouchEventTracker`

Constructs a new TouchEventTracker instance.

#### Returns

`TouchEventTracker`

## Methods

### pop()

> **pop**(`eventId`): `TouchEvent`

Returns the TouchEvent corresponding to the eventId while discarding all the motion events
that occurred prior to the event represented by the eventId.

#### Parameters

##### eventId

[`TouchEventId`](TouchEventId.md)

The TouchEventId to retrieve

#### Returns

`TouchEvent`

The TouchEvent corresponding to the eventId

***

### track()

> **track**(`event`): [`TouchEventId`](TouchEventId.md)

Tracks the event and returns a unique TouchEventId identifying the event.

#### Parameters

##### event

`TouchEvent`

The touch event to track

#### Returns

[`TouchEventId`](TouchEventId.md)

A unique TouchEventId for the event

***

### getInstance()

> `static` **getInstance**(): `TouchEventTracker`

Gets the singleton instance of TouchEventTracker.

#### Returns

`TouchEventTracker`

The singleton TouchEventTracker instance
