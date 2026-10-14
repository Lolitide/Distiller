[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: FlutterApplicationInfo

Contains application information for Flutter initialization.
This class holds configuration data such as AOT library names, snapshot data paths,
asset directories, and build mode information.

## Constructors

### Constructor

> **new FlutterApplicationInfo**(`aotSharedLibraryName`, `vmSnapshotData`, `isolateSnapshotData`, `flutterAssetsDir`, `domainNetworkPolicy`, `nativeLibraryDir`, `automaticallyRegisterPlugins`): `FlutterApplicationInfo`

Constructs a new FlutterApplicationInfo instance.

#### Parameters

##### aotSharedLibraryName

`string`

Name of the AOT shared library, or null to use default

##### vmSnapshotData

`string`

Name of the VM snapshot data file, or null to use default

##### isolateSnapshotData

`string`

Name of the isolate snapshot data file, or null to use default

##### flutterAssetsDir

`string`

Directory containing Flutter assets, or null to use default

##### domainNetworkPolicy

`string`

Domain network policy, or null for empty string

##### nativeLibraryDir

`string`

Directory containing native libraries

##### automaticallyRegisterPlugins

`boolean`

Whether to automatically register plugins

#### Returns

`FlutterApplicationInfo`

## Properties

### aotSharedLibraryName

> **aotSharedLibraryName**: `string`

Name of the AOT shared library.

***

### automaticallyRegisterPlugins

> **automaticallyRegisterPlugins**: `boolean`

Whether to automatically register plugins.

***

### domainNetworkPolicy

> **domainNetworkPolicy**: `string`

Domain network policy configuration.

***

### flutterAssetsDir

> **flutterAssetsDir**: `string`

Directory containing Flutter assets.

***

### isDebugMode

> **isDebugMode**: `boolean`

Whether the application is running in debug mode.

***

### isolateSnapshotData

> **isolateSnapshotData**: `string`

Name of the isolate snapshot data file.

***

### isProfile

> **isProfile**: `boolean`

Whether the application is running in profile mode.

***

### nativeLibraryDir

> **nativeLibraryDir**: `string`

Directory containing native libraries.

***

### vmSnapshotData

> **vmSnapshotData**: `string`

Name of the VM snapshot data file.
