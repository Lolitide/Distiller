# 签名与发布问题

<a id="section425680"></a>

## Flutter OH 项目自动签名报错

**现象：**

Flutter OH 项目在 DevEco Studio 中自动签名报错。

**原因：**

`AppScope/app.json5` 中包名不规范，导致自动签名无法通过。

**解决方案：**

- 使用 DevEco Studio 打开 Flutter 项目里的 ohos 目录
- 打开 `AppScope > app.json5` 文件检查包名是否规范
- 规范包名后，同步项目
- 重新执行 `flutter build hap --debug` 或 `flutter build hap --release` 编译构建应用

---

<a id="section380470"></a>

## 通过 flutter build hap --release 编译版本会导致 app.json versionName 字段重置

**现象：**

查看 `app.json` 下的 `versionName` 字段，然后执行 `flutter build hap --release` 编译版本进行出包，发现该字段再次被重置为 `1.0.0`。

**原因：**

当前规格，默认 build 会使用 `1.0.0` 这个版本号。

**解决方案：**

需要指定 `versionName` 和 `versionCode`，可以在 build 指令时加上指定版本：

```shell
flutter build hap --build-name=4.0.3 --build-number=10000
```

---

<a id="section710370"></a>

## Release 构建异常（闪退或仍处于调试模式）

**现象：**

使用 `flutter build hap --release` 构建应用后，安装运行可能出现以下任一表现：

- **启动闪退：** debug 包可正常安装和启动，release 包安装后启动即闪退。
- **仍处于调试模式：** release 包体积与 debug 包相近、未明显缩小；应用行为与 debug 包一致（如支持热重载、DevTools 可连接等）。

**原因：**

构建产物中实际使用的是 **debug 版本的 `flutter.har`**，而非 release 版本。常见原因包括：

- DevEco Studio 的 `Build Mode` 未设置为 `release`
- 构建缓存中残留了 debug 模式的产物
- 交替使用模拟器和真机调试后，缓存了错误架构的产物

**排查要点：**

- release 包的体积应该明显小于 debug 包。以一个纯净的 Flutter 应用作为基准来看，release 包体积约为 debug 包体积的 10%~20%；如果应用 release 包体积与 debug 包体积相近（如 release 包大于 debug 包的 50%），则很可能使用了 debug 版的 `flutter.har`。

  > 以 Flutter OH 3.27 版本创建一个纯净应用为参考：
  >
  > - debug 包：118M
  > - release 包：16.5M
  > - release 包约为 debug 包的 14%

- crash 日志中出现 `SI_TKILL`、`raise+228`、`abort+20` 等断言日志，表示 `flutter.har` 使用的是 debug 版本，release 构建的包不应该出现断言日志。

- 打开 `DevEco Studio → Product`，检查 `Build Mode` 是否是 `release`：

  ![image-20260316151248895](../media/getting-started/getting-started-09.png)

  <p align="center"><strong>图1</strong> DevEco Studio Build Mode 检查</p>

**解决方案：**

1. 在 `DevEco Studio → Product` 里将 `Build Mode` 选择为 `release`

2. 清理构建缓存：

```shell
# 清理 Flutter 构建缓存
cd <project>
flutter clean

# 删除 ohos 目录下的缓存
cd ohos
rm -rf oh_modules

# 删除 entry 目录下的缓存
cd entry
rm -rf build
rm -rf oh_modules
```

3. 重新构建 release 包：

```shell
flutter build hap --release --target-platform ohos-arm64
```

4. 验证构建结果：
   - release 包体积应明显小于 debug 包（纯净应用参考值：debug 约 118M，release 约 16.5M，release 约为 debug 的 10%~20%）
   - crash 日志中不应出现断言对应信息

更多构建指导可参考：[Flutter OH 应用构建与运行指导](../app-development/flutter-oh-app-build-guide.md)

---

<a id="section823290"></a>

## 上线包使用了 debug 版本的 flutter.har 导致运行闪退

**现象：**

上线包运行闪退。

日志信息：

```log
#20 at attachToNative (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterNapi.ts:60:1)
#21 at attachToNapi (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:97:1)
#22 at init (entry|@ohos/flutter_ohos|1.0.0-115ba6b8be|src/main/ets/embedding/engine/FlutterEngine.ts:88:1)
```

**原因：**

上线包使用了 debug 版本的 flutter.har，导致运行期闪退。

**解决方案：**

建议上线前重新打包 release 版本的 flutter.har，执行命令 `flutter build hap --release`。

---

<a id="section433647"></a>

## 权限与 Profile

**现象：**

需要了解权限与签名 Profile 的关系。

**原因：**

开发调试与发布对权限签名的要求不同：调试时可授权到临时签名，发布时需通过发布 Profile 申明权限。

**解决方案：**

- 开发调试时，权限可以授权到临时签名文件里。
- 发布应用时，需要 [申请发布 Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-release-profile-0000002248341090)。
