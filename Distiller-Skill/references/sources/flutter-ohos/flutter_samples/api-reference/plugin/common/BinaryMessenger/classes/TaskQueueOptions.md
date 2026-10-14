[**Flutter ETS API Documentation v1.0.0**](../../../../README.md)

***

# Class: TaskQueueOptions

Options that control how a TaskQueue should operate and be created.

## Constructors

### Constructor

> **new TaskQueueOptions**(): `TaskQueueOptions`

#### Returns

`TaskQueueOptions`

## Methods

### getIsSerial()

> **getIsSerial**(): `boolean`

Gets whether tasks should be executed serially.

#### Returns

`boolean`

True if tasks are executed serially, false otherwise

***

### getPriority()

> **getPriority**(): [`TaskPriority`](../enumerations/TaskPriority.md)

Gets the task priority.

#### Returns

[`TaskPriority`](../enumerations/TaskPriority.md)

The current task priority

***

### isSingleThreadMode()

> **isSingleThreadMode**(): `boolean`

Checks if single thread mode is enabled.

#### Returns

`boolean`

True if single thread mode is enabled, false otherwise

***

### setIsSerial()

> **setIsSerial**(`isSerial`): `TaskQueueOptions`

Sets whether tasks should be executed serially.

#### Parameters

##### isSerial

`boolean`

True to execute tasks serially, false for concurrent execution

#### Returns

`TaskQueueOptions`

This TaskQueueOptions instance for method chaining

***

### setPriority()

> **setPriority**(`priority`): `TaskQueueOptions`

Sets the task priority.

#### Parameters

##### priority

[`TaskPriority`](../enumerations/TaskPriority.md)

The task priority to set

#### Returns

`TaskQueueOptions`

This TaskQueueOptions instance for method chaining

***

### setSingleThreadMode()

> **setSingleThreadMode**(`isSingleThread`): `TaskQueueOptions`

Sets single thread mode.

#### Parameters

##### isSingleThread

`boolean`

True to enable single thread mode, false otherwise

#### Returns

`TaskQueueOptions`

This TaskQueueOptions instance for method chaining
