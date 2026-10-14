# Added Plugins Not Taking Effect Issue Scenario

## I. Fault Description

After the APP was packaged in release and published, verification found that plugins were missing, so features could not be downloaded and used. Mainly, the flutter_downloader plugin was lost, making the resource download feature unavailable.

![Missing plugin symptom](../media/faq/image-20260331155337940.png)

<p align="center"><strong>Figure 1</strong> Missing plugin symptom</p>

---

## II. Error Stack Trace

```log
Symptom: during verification after the release package was published, the flutter_downloader plugin was missing and the resource download feature was unavailable
Error: MissingPluginException is thrown when calling the plugin method (the plugin was not registered successfully)
```

---

## III. Problem Scenario Analysis

**Problem localization**

After the APP was packaged in release and published, the flutter_downloader plugin was missing, making the download feature unavailable. Two key causes were identified.

**Cause analysis**

1. Flutter initialization binding issue

   The APP performs flutter initialization binding by inheriting from WidgetFlutterBinding and overriding the initInstance method. In this case, the asynchronous execution process can cause plugin registration and binding to run before initialization has finished, so the plugin is lost.

2. Code execution order issue

   Plugin registration is an asynchronous process. If a plugin is initialized before registration completes, the plugin performs exception handling, the initialization fails, and the plugin cannot be used.

---

## IV. Solution

1. Flutter initialization binding issue

   If you use the approach of inheriting from WidgetFlutterBinding, you can manually perform the initialization binding in the overridden initInstance method with `WidgetsFlutterBinding.ensureInitialized();`, without relying on the inherited automatic initialization.

```dart
// BoostFlutterBinding is a custom Mixin on the business side that consolidates plugin registration and binding into a unified entry point
class CustomFlutterBinding extends WidgetsFlutterBinding with BoostFlutterBinding {
    @override 
    void initInstances() {             
        super.initInstances(); 
        WidgetsFlutterBinding.ensureInitialized(); 
        renderView.automaticSystemUiAdjustment = false; 
    } 
}
```

If you use the normal mode, you can perform the flutter initialization binding directly in the app's startup function, which is simpler and more direct:

```dart
void main() async {
    // Must be called first! Initialize the Flutter binding 
    WidgetsFlutterBinding.ensureInitialized(); 
    // Run the app
    runApp(const MyApp()); 
}
```

2. Code execution order issue

   Before the plugin is initialized, you can use `await` to wait for initialization and registration to complete, and then use the plugin:

```dart
import 'package:flutter/material.dart'; 
import 'package:flutter_downloader/flutter_downloader.dart'; 
void main() async { 
    // Must be called first! Initialize the Flutter binding 
    WidgetsFlutterBinding.ensureInitialized(); 
    await init(); 
    runApp(const MyApp()); 
} 
void init() async { 
    try { 
        // Wait for initialization to complete
        await FlutterDownloader.initialize(debug: false, ignoreSsl: true); 
    } catch (e) { 
        print("FlutterDownloader.initialize $e"); 
    } 
} 
class MyApp extends StatefulWidget { 
    const MyApp({super.key}); 
    @override 
    State<MyApp> createState() => _MyAppState(); 
} 
class _MyAppState extends State<MyApp> { 
    @override 
    void initState() { 
        super.initState();
     } 
     
     @override 
     Widget build(BuildContext context) { 
         return MaterialApp( 
             title: 'Demo', 
             home: Scaffold(
                 appBar: AppBar( title: const Text('Demo app'), ), 
                 body: const Column(), 
             ),
          ); 
     }
}
```

