[**Flutter ETS API Documentation v1.0.0**](../../../../../README.md)

***

# Class: TaskState

Represents the state of a task to be executed in a background task queue.

## Constructors

### Constructor

> **new TaskState**(`handler`, `message`, ...`args`): `TaskState`

Constructs a new TaskState instance.

#### Parameters

##### handler

[`SendableBinaryMessageHandler`](../../../../../plugin/common/SendableBinaryMessageHandler/interfaces/SendableBinaryMessageHandler.md)

The message handler to execute

##### message

`ArrayBuffer`

The message data as an ArrayBuffer

##### args

...`Object`[]

Additional arguments to pass to the handler

#### Returns

`TaskState`

## Properties

### args

> **args**: `Object`[]

Additional arguments to pass to the handler.

***

### handler

> **handler**: [`SendableBinaryMessageHandler`](../../../../../plugin/common/SendableBinaryMessageHandler/interfaces/SendableBinaryMessageHandler.md)

The message handler to execute.

***

### message

> **message**: `ArrayBuffer`

The message data as an ArrayBuffer.
