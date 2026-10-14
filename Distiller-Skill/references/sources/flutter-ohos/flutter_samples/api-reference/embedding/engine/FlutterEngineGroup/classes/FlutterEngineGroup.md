[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: FlutterEngineGroup

Represents a collection of FlutterEngines who share resources to allow them to be created
faster and with less memory than calling the FlutterEngine's constructor multiple times.

When creating or recreating the first FlutterEngine in the FlutterEngineGroup, the behavior
is the same as creating a FlutterEngine via its constructor. When subsequent FlutterEngines
are created, resources from an existing living FlutterEngine is re-used.

The shared resources are kept until the last surviving FlutterEngine is destroyed.

Deleting a FlutterEngineGroup doesn't invalidate its existing FlutterEngines, but it eliminates
the possibility to create more FlutterEngines in that group.

## Constructors

### Constructor

> **new FlutterEngineGroup**(): `FlutterEngineGroup`

Constructs a new FlutterEngineGroup instance.

#### Returns

`FlutterEngineGroup`

## Methods

### checkLoader()

> **checkLoader**(`context`, `args`): `void`

Checks and initializes the FlutterLoader if not already initialized.

#### Parameters

##### context

`Context`

The application context

##### args

`string`[]

Command-line arguments for Dart VM initialization

#### Returns

`void`

***

### createAndRunEngineByOptions()

> **createAndRunEngineByOptions**(`options`): `any`

Creates and runs a Flutter engine based on the provided options.
If no engines exist, creates a new engine. Otherwise, spawns from the first engine.

#### Parameters

##### options

[`Options`](Options.md)

Configuration options for engine creation

#### Returns

`any`

The created or spawned FlutterEngine instance

***

### createEngine()

> **createEngine**(`context`, `platformViewsController`): `FlutterEngine`

Creates a new FlutterEngine instance.

#### Parameters

##### context

`Context`

The application context

##### platformViewsController

`PlatformViewsController`

The platform views controller for the engine

#### Returns

`FlutterEngine`

A new FlutterEngine instance

***

### getDefaultEngine()

> **getDefaultEngine**(): `any`

Gets the default (first) engine in this group.

#### Returns

`any`

The default FlutterEngine, or null if no engines exist
