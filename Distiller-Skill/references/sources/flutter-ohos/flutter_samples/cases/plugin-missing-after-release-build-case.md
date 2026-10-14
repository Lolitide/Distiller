# 引入插件失效问题场景案例

## 一、故障现场描述

APP 应用在打包 release 版本发布后，在进行验证时发现插件缺失情况，导致功能不能下载使用。主要是 flutter_downloader 插件丢失，导致下载资源功能无法使用。

![插件缺失现象](../media/faq/image-20260331155337940.png)

<p align="center"><strong>图1</strong> 插件缺失现象</p>

---

## 二、报错堆栈信息

```log
现象：release 打包发布后验证时，flutter_downloader 插件缺失，下载资源功能无法使用
错误：调用插件方法时抛出 MissingPluginException（插件未注册成功）
```

---

## 三、问题场景分析

【问题定位】

APP 应用在打包 release 版本发布后，插件（flutter_downloader）缺失，导致下载功能无法使用。定位到两个关键原因。

【原因分析】

1. flutter 初始化绑定问题

   APP 应用是采用继承 WidgetFlutterBinding，重写 initInstance 方法的方式进行 flutter 初始化绑定，这种情况下在异步执行过程会导致初始化未结束时就执行插件的注册和绑定，造成插件丢失。

2. 代码执行顺序问题

   插件注册是异步过程，如果在未注册完成的情况下进行插件初始化，会导致插件做异常处理，从而初始化失败，影响插件的使用。

---

## 四、解决方案

1. flutter 初始化绑定问题

   如果使用继承 WidgetFlutterBinding 的方式，可以在重写的 initInstance 方法中手动执行初始化绑定 `WidgetsFlutterBinding.ensureInitialized();`，不依赖继承过来的自动初始化。

```dart
// BoostFlutterBinding 为业务侧自定义 Mixin，负责将插件注册绑定收敛到统一入口
class CustomFlutterBinding extends WidgetsFlutterBinding with BoostFlutterBinding {
    @override 
    void initInstances() {             
        super.initInstances(); 
        WidgetsFlutterBinding.ensureInitialized(); 
        renderView.automaticSystemUiAdjustment = false; 
    } 
}
```

如果使用普通模式，可以直接在应用的启动函数中，进行 flutter 初始化绑定，更简洁直接：

```dart
void main() async {
    // 必须首先调用！初始化 Flutter 绑定 
    WidgetsFlutterBinding.ensureInitialized(); 
    // 应用运行
    runApp(const MyApp()); 
}
```

2. 代码执行顺序问题

   插件在执行初始化前，可以使用 `await` 等待初始化注册完成后再进行插件使用：

```dart
import 'package:flutter/material.dart'; 
import 'package:flutter_downloader/flutter_downloader.dart'; 
void main() async { 
    // 必须首先调用！初始化 Flutter 绑定 
    WidgetsFlutterBinding.ensureInitialized(); 
    await init(); 
    runApp(const MyApp()); 
} 
void init() async { 
    try { 
        // 等待初始化完成
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

