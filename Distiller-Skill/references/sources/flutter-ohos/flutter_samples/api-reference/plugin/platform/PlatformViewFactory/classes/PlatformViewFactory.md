[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Abstract Class: PlatformViewFactory

Factory for creating platform views.
Subclasses must implement the create method to instantiate platform views.

## Constructors

### Constructor

> **new PlatformViewFactory**(`createArgsCodec`): `PlatformViewFactory`

Constructs a new PlatformViewFactory instance.

#### Parameters

##### createArgsCodec

[`MessageCodec`](../../../common/MessageCodec/interfaces/MessageCodec.md)\<`Any`\>

The codec used to decode the args parameter of create

#### Returns

`PlatformViewFactory`

## Methods

### create()

> `abstract` **create**(`context`, `viewId`, `args`): `PlatformView`

Creates a new platform view to be embedded in the Flutter hierarchy.

#### Parameters

##### context

`Context`

The context to be used when creating the view, this is different than
    FlutterView's context

##### viewId

`number`

Unique identifier for the created instance, this value is known on the Dart side

##### args

`Any`

Arguments sent from the Flutter app. The bytes for this value are decoded using the
    createArgsCodec argument passed to the constructor. This is null if createArgsCodec was
    null, or no arguments were sent from the Flutter app

#### Returns

`PlatformView`

A new PlatformView instance

***

### getCreateArgsCodec()

> **getCreateArgsCodec**(): [`MessageCodec`](../../../common/MessageCodec/interfaces/MessageCodec.md)\<`Any`\>

Returns the codec to be used for decoding the args parameter of create.

#### Returns

[`MessageCodec`](../../../common/MessageCodec/interfaces/MessageCodec.md)\<`Any`\>

The MessageCodec instance
