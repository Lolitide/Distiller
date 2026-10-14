# Debugging Dart code

- DevEco-Studio is used to debug ets code.
- Dart code can be debugged with vscode and Android Studio; simply click the run button to start debugging.

# Debugging Dart code with a specified local engine

  When debugging, you need to add parameters, for example: `--local-engine=/Users/xxx/ohos/engine/src/out/ohos_debug_unopt_arm64`.

## Debugging Dart code with vscode

Create the file `.vscode/launch.json` in the project directory and add the parameters as shown below:

```
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "flutter_sample",
            "request": "launch",
            "type": "dart",
            "args": [
                "--local-engine=/Users/xxx/work/engine_build/engine/src/out/ohos_debug_unopt_arm64"
            ]
        },
        {
            "name": "flutter_sample (profile mode)",
            "request": "launch",
            "type": "dart",
            "flutterMode": "profile",
            "args": [
                "--local-engine=/Users/xxx/work/engine_build/engine/src/out/ohos_profile_arm64"
            ]
        },
        {
            "name": "flutter_sample (release mode)",
            "request": "launch",
            "type": "dart",
            "flutterMode": "release",
            "args": [
                "--local-engine=/Users/xxx/work/engine_build/engine/src/out/ohos_release_arm64"
            ]
        }
    ]
}
```

After the modification is complete, you can debug the Dart code.

## Debugging Dart code with Android Studio

![](../media/debugging/android-run-config.png)

After the parameters are set, you can debug the Dart code.
