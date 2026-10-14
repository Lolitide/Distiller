# Flutter OH 热重载操作指导

热重载（Hot Reload）允许在应用运行期间将修改后的 Dart 代码注入正在运行的 Dart VM，无需重新编译 HAP 或重启应用即可快速查看代码变更效果。Flutter OH 沿用上游 Flutter 的热重载机制，在 Debug 模式下通过 `flutter run` 连接设备后触发。

热重载保留当前应用状态与路由栈，适用于 Widget 样式调整、逻辑分支修改等迭代场景；当涉及状态重置或原生代码变更时需使用热重启（Hot Restart）。

## 核心概念

| 术语 | 说明 |
| ---- | ---- |
| Hot Reload（热重载） | 将修改后的 Dart 源码增量编译为 kernel 文件注入运行中的 Dart VM，保留应用状态与路由栈 |
| Hot Restart（热重启） | 重启 Dart VM 并重新运行 `main()` 入口，重置应用状态，但无需重新安装 HAP |
| Cold Restart（冷启动） | 重新构建、安装 HAP 并启动应用，适用于原生代码或资源变更场景 |

> [!NOTE]
>
> 热重载与热重启仅适用于 Debug 模式。Release / Profile 模式使用 AOT 编译，无法进行热重载。

## 前置条件

- 已完成  [Flutter OH 开发环境搭建指导](../getting-started/flutter-oh-env-setup.md)。
- 已连接 OpenHarmony 真机或启动模拟器。

根据项目形态不同，热重载的操作路径存在差异：

- **独立 Flutter 应用**：通过 `flutter create --platforms ohos` 创建的普通 Flutter 工程，使用 `flutter run` 直接启动并在交互终端触发热重载，详见 [场景一：独立 Flutter 应用](#场景一独立-flutter-应用)。
- **flutter_module 混合开发应用**：`flutter_module` 作为子模块嵌入 OpenHarmony 工程，通过 `flutter attach` 连接运行中的 OpenHarmony 应用触发热重载，源码依赖与 HAR 依赖方式均支持，详见 [场景二：flutter_module 混合开发应用](#场景二flutter_module-混合开发应用)。

## 场景一：独立 Flutter 应用

适用于通过 `flutter create --platforms ohos` 创建的独立 Flutter 工程。使用 `flutter run` 编译、安装并启动应用，热重载在 `flutter run` 交互终端中触发。

### 第一步：以 Debug 模式启动应用

进入工程根目录，执行 `flutter run` 以 Debug 模式编译、安装并启动应用：

```bash
# Debug 模式启动（默认即 debug，--debug 可省略）
flutter run --debug -d <deviceId>
```

> **说明**：`<deviceId>` 为设备 ID，可通过 `flutter devices` 或 `hdc list targets` 获取。

启动完成后，终端进入交互模式，输出类似如下提示：

```log
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

### 第二步：修改 Dart 代码

在编辑器中修改 Dart 源码。以下示例修改 `lib/main.dart` 中的页面标题文本：

```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('当前点击次数:$_counter'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

修改 `Text('当前点击次数:$_counter')` 为任意新文本后保存文件。

### 第三步：触发热重载

在 `flutter run` 交互终端中按下 `r` 键触发热重载，终端输出类似如下：

```log
Hot reload performed in 1,234ms.
```

此时设备屏幕即时刷新，已修改的 Dart 代码生效，应用的页面状态与路由栈保持不变。

### 第四步：触发热重启（按需）

当修改涉及以下场景时，热重载无法完整生效，需按下 `R` 键触发热重启：

- 修改了 `main()` 函数入口逻辑
- 修改了全局变量初始化值或单例对象构造逻辑
- 修改了 `initState` / `dispose` 等生命周期回调中的状态初始化
- 代码逻辑依赖应用启动状态，热重载后行为不符合预期

热重启会重置应用状态，但无需重新安装 HAP，启动速度显著快于冷启动。

## 场景二：flutter_module 混合开发应用

在 Add-to-App 混合开发场景中，`flutter_module` 作为子模块嵌入 OpenHarmony 工程运行。OpenHarmony 应用由 DevEco Studio 或 `hvigorw` 独立启动，与独立 Flutter 应用的 `flutter run` 启动方式不同，需通过 `flutter attach` 连接运行中的 OpenHarmony 应用触发热重载。源码依赖与 HAR 依赖两种集成方式均支持，操作流程一致。

### 通过 flutter attach 热重载

源码依赖方式下，hvigor 插件 `injectNativeModules` 将 `flutter_module` 及各插件源码注入 OpenHarmony 工程编译；HAR 依赖方式下，OpenHarmony 工程引用预编译的 HAR 产物。两种方式构建出的 Debug 应用均会随 OpenHarmony 应用进程启动 Dart VM Service，`flutter attach` 可据此发现并连接，进而实现热重载。

#### 第一步：启动 OpenHarmony 应用

在 DevEco Studio 中点击 ![运行](../media/icons/run-icon.svg)运行 OpenHarmony 工程，或在 OpenHarmony 工程根目录执行构建并安装：

```bash
# 构建 HAP 包
hvigorw assembleHap --no-daemon -p product=default -p buildMode=debug

# 安装到设备
hdc install build/default/outputs/default/entry-default-signed.hap

# 启动应用（替换为你的包名和 Ability 名）
hdc shell aa start -a EntryAbility -b com.example.demo
```

应用启动后 Flutter 页面正常显示，Dart VM 已随 OpenHarmony 应用进程启动，此时可被 `flutter attach` 连接。

#### 第二步：attach 连接运行中的 Dart VM

进入 `flutter_module` 工程目录，执行 `flutter attach` 连接设备上正在运行的 Dart VM：

```bash
cd my_flutter_module
# -d 指定设备 ID，可通过 flutter devices 获取
flutter attach -d <deviceId>
```

连接成功后，终端进入交互模式，输出与 `flutter run` 一致的热重载提示：

```log
Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
c Clear the screen
q Quit (terminate the application on the device).
```

#### 第三步：修改 Dart 代码并触发热重载

修改 `flutter_module/lib/` 下的 Dart 源码后保存，在 `flutter attach` 交互终端中按下 `r` 键触发热重载，设备屏幕即时刷新，应用状态与路由栈保持不变。热重启（`R`）同样适用于此场景。

热重载的生效范围与限制与独立 Flutter 应用一致，详见 [热重载支持范围](#热重载支持范围)。OpenHarmony 工程中的 ArkTS / Native 代码变更不支持热重载，需重新构建并运行 OpenHarmony 应用。

> [!WARNING]
>
> `flutter attach` 仅连接已运行的 Dart VM，不会重新构建或安装 OpenHarmony HAP。若修改了 `pubspec.yaml` 依赖或原生代码，需按 `q` 退出 attach，重新构建 OpenHarmony 应用后再 attach。

### 独立运行 flutter_module（可选）

除通过 `flutter attach` 连接 OpenHarmony 应用外，也可将 `flutter_module` 作为独立 Flutter 工程直接启动，热重载流程与独立 Flutter 应用完全一致。该方式适用于 `flutter_module` 自身 Dart 代码的独立开发与调试，无需启动 OpenHarmony 应用。

`flutter_module` 本身是可独立运行的 Flutter 工程，自带 `lib/main.dart` 入口。直接在 `flutter_module` 目录下执行 `flutter run` 即可将其作为独立应用安装到设备并启动：

```bash
cd flutter_module
# Debug 模式独立启动 module，热重载交互与独立 Flutter 应用一致
flutter run --debug -d <deviceId>
```

启动后终端进入交互模式，修改 `lib/` 下 Dart 源码后按 `r` 键即可触发热重载，热重启（`R`）同样适用。

> [!IMPORTANT]
>
> 独立运行方式用于 `flutter_module` 自身 Dart 代码的开发与调试。由于独立运行时的 `main.dart` 入口与 OpenHarmony 工程实际加载的 Widget 可能不同，OpenHarmony 侧的原生交互（Platform Channel、嵌入容器、路由跳转等）仍需在 OpenHarmony 工程中验证。开发完成后，执行 `flutter build har` 重新构建 HAR 产物并更新 OpenHarmony 工程依赖，再于 OpenHarmony 工程中完整回归。

## 在 IDE 中使用热重载

除命令行交互外，Flutter OH 热重载也可通过 IDE 触发，操作方式与常规 Flutter 项目一致。

### 使用 VS Code

1. 打开项目目录，按 `F5` 或点击运行面板的启动按钮，以 Debug 模式启动应用。
2. 修改 Dart 代码后保存，按 `Ctrl + Shift + F5`（macOS 为 `Cmd + Shift + F5`）触发热重载，或点击调试工具栏的热重载图标。

> **说明**：需安装 Flutter 扩展。若使用本地 Engine，在 `.vscode/launch.json` 的 `args` 中配置 `--local-engine` 参数，详见 [调试 Dart 代码](./debugging-dart-code.md)。

**flutter_module 混合开发场景**：OpenHarmony 应用由 DevEco Studio 启动，VS Code 中需使用 `flutter attach` 配置连接已运行的 Dart VM。在 `flutter_module` 目录的 `.vscode/launch.json` 中添加：

```json5
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "flutter_module (attach)",
      "request": "attach",
      "type": "dart",
      // 设备 ID 可通过 flutter devices 获取，仅一台设备时可省略
      "deviceId": "<deviceId>"
    }
  ]
}
```

### 使用 Android Studio / DevEco Studio

1. 打开项目，在设备下拉列表中选择已连接的 OpenHarmony 设备。
2. 点击运行按钮启动应用。
3. 修改 Dart 代码后保存，点击工具栏的热重载按钮（闪电图标）触发热重载。

> [!NOTE]
>
> DevEco Studio 用于调试 ArkTS / Native 代码，Flutter 侧 Dart 代码的热重载依赖 Flutter 插件支持。ArkTS / Native 代码修改不支持热重载，需重新构建运行。

## 热重载支持范围

| 变更类型 | 热重载 | 热重启 | 冷启动 |
| -------- | ------ | ------ | ------ |
| Dart Widget 样式 / 布局 | 支持 | 支持 | 支持 |
| Dart 业务逻辑 / 方法实现 | 支持 | 支持 | 支持 |
| Dart 新增 / 删除文件 | 部分支持 | 支持 | 支持 |
| `main()` 入口逻辑 | 不支持 | 支持 | 支持 |
| `pubspec.yaml` 依赖变更 | 不支持 | 不支持 | 支持 |
| ArkTS / Native（C/C++）代码 | 不支持 | 不支持 | 支持 |
| 资源文件（图片 / 字体 / 配置） | 不支持 | 不支持 | 支持 |
| 渲染引擎切换（Impeller / Skia） | 不支持 | 不支持 | 支持 |

## 常见问题

### 热重载无响应

**现象**：按下 `r` 键后终端无 `Hot reload performed` 输出，设备界面未刷新。

**排查要点**：

1. 确认应用以 Debug 模式启动，`flutter run` 终端处于交互状态（非后台挂起）。
2. 确认修改的是 `lib/` 目录下的 Dart 源码，非原生代码或资源文件。
3. 确认文件已保存，IDE 无未保存标记。
4. 检查终端是否被其他进程占用，尝试按 `Enter` 键恢复交互。

### 热重载后界面未变化

**现象**：终端提示热重载成功，但设备界面未显示修改后的内容。

**排查要点**：

1. 确认修改的 Widget 处于当前可见的路由页面，非未加载的页面。
2. 确认修改未涉及 `const` 常量构造。`const` Widget 在热重载时不会重建，需移除 `const` 或使用热重启。
3. 确认修改未依赖 `initState` 中的初始化逻辑，此类修改需热重启生效。

### 热重载后状态异常

**现象**：热重载后应用出现状态错乱、布局异常或空指针异常。

**排查要点**：

1. 热重载保留旧状态可能与新代码逻辑冲突，尝试按下 `R` 键热重启。
2. 若问题持续，执行 `q` 退出后重新 `flutter run` 冷启动。
3. 避免在 `State` 中缓存与 Widget 树结构强耦合的对象引用，热重载重建 Widget 树时此类引用可能失效。

### flutter_module 场景下 flutter attach 连接失败

**现象**：执行 `flutter attach` 后提示连接超时或未发现运行中的应用，终端无热重载交互提示。

**排查要点**：

1. 确认 OpenHarmony 应用已以 Debug 模式启动并在设备上正常运行，Flutter 页面已可见。Release / Profile 产物不含 Dart VM Service，无法被 attach。
2. 确认 `flutter attach` 在 `flutter_module` 工程目录下执行，而非 OpenHarmony 工程目录。
3. 确认设备已通过 `hdc list targets` 识别，`flutter devices` 列表中出现 `ohos-arm64` 设备。
4. 源码依赖方式下，确认已在 `flutter_module` 目录执行过 `flutter pub get`，`.ohos` 注入产物为最新。
5. 若多设备连接，通过 `flutter attach -d <deviceId>` 显式指定目标设备。
