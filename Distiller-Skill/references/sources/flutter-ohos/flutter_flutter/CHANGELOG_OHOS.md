# Changelog

<a id="version20260924"></a>

## 3.35.7+ohos-1.0.5 - `2026-09-24`

### Added

- feat(flex_overflow): dynamic DPI overflow strategy，修复动态DPI下PlatformView点击事件坐标分布异常 [!1958](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1958)
- feat: parseOhosVersion supports +ohos build metadata format [!1765](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1765)
- feat(ohos): 完善GPU资源回收全流程日志埋点 [!1852](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1852)
- add:白屏渲染相关dfx日志 [!1760](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1760)

### Changed

- 【3.35】change(Template): OHOS模板targetSdkVersion升级至26.0.0并统一compatibleSdkVersion至5.0.5(17) [!2027](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2027)
- 【3.35】change(Template): 更新oh flutter图标 [!2070](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2070)

### Fixed

- 【3.35】修复StandardMessageCodec.writeValueInternal绕过子类覆写导致序列化失败 [!2100](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2100)
- fix:Fix the total frame count issue during sliding frame drops [!2080](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2080)
- 【3.35】修复channel传递递归数据导致jscrash [!2011](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2011)
- fix(ohos): restore plugin state after ability recreation [!2042](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2042)
- fix: physicalTouchSlop missing dpr conversion, touchSlop dropped to 1.4 [!2020](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/2020)
- 【3.35】fix(Texture): implement SurfaceTextureEntry.release() via unregisterTexture [!1998](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1998)
- fix(Channel): send fallback error envelope when result decode fails, deliver error envelope when dart handler throws [!1969](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1969)
- fix: unregister preview callbacks, postInputEventWithStrategy支持失败回落postInputEvent [!1984](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1984)
- fix(safearea): correct safe area padding for edgeToEdge and freeform window exit [!1923](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1923)
- fix: pass --route parameter to hdc aa start via --ps route Want parameter [!1901](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1901)
- fix(memory_leak):Fix some memory leakage issues related to HarmonyOS adaptation [!1851](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1851)
- fix(DEPS_ohos): update skia_revision for font alias fix [!1800](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1800)
- fix(Accessibility): expose OHOS semantics to UiTest [!1792](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1792)
- fix: Refactor input method pre-input display [!1748](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1748)
- fix: 取消flutterView断言，避免crash [!1959](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1959)
- fix(input): 修复多引擎场景FlutterView#onWindowCreated未调用,导致输入法弹起时keyboardHeightChangeCallback不执行的问题 [!1941](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1941)
- Fix incorrect deadline time in DartVM [!1803](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1803)
- fix(integration_test): initialize OHOS test results static set [!1779](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1779)

<a id="version20260808"></a>

## 3.35.7-ohos-1.0.4 - `2026-08-17`

### Added

- 支持密码保险箱功能 [!1408](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1408) [!1615](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1615)
- feature: flutter page pause when invisible [!1563](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1563)
- [OHOS] Add DMA zero-copy image decode path with P3 support [!1320](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1320)
- flutter项目Web页面，支持鼠标拖拽调整尺寸 [!1281](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1281)
- [OHOS] Add async APIs for FlutterEngine spawn/destroy to prevent ANR [!1133](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1133)

### Changed

- LTPO feature is enabled by default [!1597](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1597)

### Fixed

- fix: Fix window decoration state not correctly restored after exiting immersive fullscreen on PC [!1738](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1738)
- Flutter 鼠标跨区域拖动 pointerup 丢失修复 [!1725](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1725)
- 【3.35】候选词位置为光标的右下角 [!1734](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1734)
- 同步三方库代码，解决字体内存泄漏问题 [!1718](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1718)
- 手势取消清除遗留finger [!1716](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1716)
- fix(Scaffold): move status bar tap subscription init to initState to prevent leak on ohos [!1701](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1701)
- 调整isActive的判断时机,修复前后台切换ets中的状态更新不及时的问题 [!1683](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1683)
- fix: DT CPP [!1681](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1681)
- 修改分栏功能获取应用图标的方式，从硬编码图片名改为通过资源id获取，避免在自定义图标文件名时失败的问题 [!1680](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1680)
- Fixed: flutter drive execution failure [!1660](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1660)
- fix: prevent incorrect backspace during pre-edit multi-select [!1659](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1659)
- 同步三方库代码，解决鸿蒙化flutter框架编译执行其他平台产物crash的问题 [!1652](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1652)
- fix(Impeller): add missing kB10G10R10A2UNorm Metal pixel format mapping [!1639](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1639)
- 提高分栏功能中，弹窗消失时，主动恢复焦点的逻辑健壮性，解决当弹窗前焦点未聚焦到页面某个组件时，恢复行为异常导致卡死的问题 [!1638](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1638)
- 修改EmbeddingNodeController.ets中可能出现的空指针问题 [!1593](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1593)
- Fixes crash when adding and removing multiple page-based route (#177338) [!1584](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1584)
- Fixed the issue with input status when switching input methods [!1579](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1579)
- Fix the issue where entering Chinese first and then English causes the English to be duplicate [!1554](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1554)
- Fixed the issue where typing English first and then Chinese would get overwritten [!1541](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1541)
- 修复折叠机下避让区域计算错误问题 [!1532](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1532)
- Fixed the issue where deleting numbers to the left would remove two at a time [!1530](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1530)
- 预加载操作执行后,将标记重置为false,避免RecreateSwapchain复用context时仍然走到预加载的判断逻辑中 [!1525](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1525)
- fix adding the webview to the rotating component makes it unclickable and unscrollable [!1465](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1465)
- [OHOS] Fix PixelMap ReadPixels temp buffer cleanup [!1395](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1395)
- Fix the template syntax error problem [!1372](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1372)

### Performance

- Enable static snapshot linking for OHOS debug mode [!1365](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1365)
- ohos开启指针压缩 [!1341](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1341)
- 发送低内存警告，触发图像缓存清理 [!1310](https://gitcode.com/CPF-Flutter/flutter_flutter/merge_requests/1310)

##  3.35.7-ohos-1.0.4-beta

- 分栏功能中，当栈顶是弹窗时，不要拦截pop函数,([4cbb3580a1f](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/4cbb3580a1f98b0b2af6ab88b0a25b8e8c249b6e))
- 修改FlutterView.ets中鸿蒙原生事件调用逻辑,增加isActive状态判断,([6398da76cb8](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/6398da76cb8e8c8b108cccea714799258119e2a3))
- Fix OHOS platform view active touch cancellation,([3b5c89e3579](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/3b5c89e3579d606ea69d9f07b3d74c5163bc39a6))
- 修改静态检查失败的问题,补充版权信息,([3a1dec449af](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/3a1dec449af4f34327e323bea457b7b112007507))
- Fix the issue where Shift + left arrow can only select one character,([6fe60ad2a0b](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/6fe60ad2a0b6df6376ed321dce071442a1e53be0))
- 手机端支持密码保险箱功能,([dc411d6ae69](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/dc411d6ae696edafc23bc98f0df71c237bb11e8c))
- Add ohos in platform_channels_benchmarks,([b4eb510d894](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/b4eb510d89439eef1caafea86a614a261fbfc776))
- Frame Buffer PTS Optimization for Delayed Frame Presentation,([b352bf7e029](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/b352bf7e029688ec36786ea0430b1696611bbef0))
- LTPO Performance Optimization,([db468f6b073](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/db468f6b0738365111abf7a5a96528fc54e2d6fe))
- Add ohos in microbenchmarks,([0be87b40830](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/0be87b408304d64b75533f04d6749755768ae0b1))
- fix NavigationChannel crash,([123ec7f1b4c](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/123ec7f1b4cabd1ba5c2e0a5b373bf6ff78b99d3))
- 切换分栏实现方案，支持router路由方式下的分栏,([77ccfc09364](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/77ccfc09364129bf14b49208b562982e9e45350c))
- fix White screen issue when restoring after minimizing the window,([2cff64a928a](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/2cff64a928aafbbd98bd1cd4e06a1fdb55481b4c))
- [OHOS] Fix PixelMap ReadPixels temp buffer cleanup,([f76e5b91ad7](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/f76e5b91ad7609a1a1a71f4ef9db6012b2f9cf23))
- [OHOS] Restore PixelMap ReadPixels tight-row semantics,([194f88db225](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/194f88db225f1f866204bcbc431e8244ffc82277))
- fix：修复性能雷达滑动丢帧上报字段值问题,([71b4231d67f](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/71b4231d67f8009547d58dd0515f2a148522cfc6))
- chore: Full release supports compiling the Web SDK.,([c753f6eb759](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/c753f6eb75951c385413298132ec660f6f5a74a5))
- Enable static snapshot linking for OHOS debug mode,([cacded20f4a](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/cacded20f4aefa3290974eedfc891d7c25caba37))
- ohos开启指针压缩,([d89c70001c5](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/d89c70001c5317d29ef7f7d39f32fcc13ee56f04))
- Fixed the issue of small mouse scroll step value,([b6fe871a958](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/b6fe871a9589bdc3096c5105f2a0c4134db7cbdd))
- Fix the issue of DPI repeatedly redirecting to the same page,([3c5fac164cb](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/3c5fac164cbb554d32c587ce514fef45065c25cd))
- 开启指针压缩,([0a5c1379f60](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/0a5c1379f60e1692d1ea333575bf0698278bc74a))
- add targetSize,([2008433e755](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/2008433e7555e7baf0b4b49b4f95bb56c7eb908b))
- 修复一定深度的主页调用popuntil问题+模态弹窗无法关闭问题,([4ea25af5030](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/4ea25af50308aa03080bce376a4a9948b8612e99))
- [OHOS] Refine DMA image decode checks,([330360eaa04](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/330360eaa04c4c255609fe6202a648fb8d882137))
- 发送低内存警告，触发图像缓存清理,([8d1f4bc8162](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/8d1f4bc8162a814668871115f280cc0fd757bad8))
- [OHOS] Add DMA zero-copy image decode path with P3 support,([b215d189943](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/b215d18994358ae90ec1885c4ae5fbb5cc4f6f04))
- [OHOS] Add DMA zero-copy image decode path,([087437f2055](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/087437f2055b0711275dcb1e40a666e1e5670555))
- fix:Fix safe area avoidance in tri-fold freeform multi-window mode,([40cbc77ce39](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/40cbc77ce39d6ba1b18b1e941ae2f03454d38f90))
- 修复弹窗问题+优化读取配置文件,([470193ff508](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/470193ff5089804179d944273362d0118c7979fb))
- fix TextField accessibility read content,([3637d438c7f](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/3637d438c7f8e7c4f157b80b6d5f89726e7ec7ac))
- 解决重复builder问题+解决键盘无法重新聚焦问题 +强制pop不能返回+observe多个监听问题,([fbd772c7718](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/fbd772c7718f249597f19b0af4bfc79a06e17852))
- 当配置文件配置项值为空字符串时，要识别为无效值,([dc7fc432b1c](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/dc7fc432b1ca3929bbef86065cdc6e1d138d49a4))
- 修复分栏模式下开启无障碍阅读左分栏无法响应的问题,([18342a85691](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/18342a856915f43bd6a0345d20b8ed48afc5b4d9))
- 防止 SplitViewContainer 在 build 期间调用 setState,避免异常警告,([828b9edc00e](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/828b9edc00e09903020e4bda6ff2de7084b3e0e7))
- 分栏起始页显示图标,([8ab8782924a](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/8ab8782924aa5ddd00a32c77879ca460b236de9a))
- 添加supportLandscapeFullscreen配置项，支持横屏全屏模式,([fbd5e0c0c0a](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/fbd5e0c0c0af55b6c4728b4ceeb5591a929ecae2))
- 添加对配置项enableReducedContainerSize的处理，当设置为true时，MediaQueryData.size宽度值改为一半,([08f97b83eeb](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/08f97b83eeb2ba54f9b7e1a104c70bd5bf405634))
- 添加分栏功能,([74a0122d318](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/74a0122d31866cac5f13a677f63aad009a6913d9))
- flutter项目Web页面，支持鼠标拖拽调整尺寸,([3da64a6e572](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/3da64a6e5722c8d9bde59d6f1ee655e19da189e6))
- fix bots ut,([79abaf10b08](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/79abaf10b088dbe6a6700e76c341929c4b560adc))
- fix flutter_tools ut,([81a822eb386](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/81a822eb386f18f2f67b10b17d71ef58341718d4))
- fix dev/devicelab&dev/tools ut,([653736d810a](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/653736d810aa6d581130dfb65e214f48897d01b3))
- fix material ut,([7b6327cc69c](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/7b6327cc69c826ffed7ef0c0249ad3493a118952))
- Fix the issue of DPI conflicting with Dart's adaptive behavior,([fd22176a6d8](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/fd22176a6d8251c69959f4e96d0f6988e581833f))
- fix Double click the control for the first time and jump to the green box position,([936afd3b22b](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/936afd3b22b1485694d6b53971b573fe59bcddfc))
- fix flutter_driver&flutter_test&integration_test&snippets ut,([7de2a8220bb](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/7de2a8220bba844aff12a8f2c17e07a42fb92416))
- fix ut,([f7b93c5d95c](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/f7b93c5d95cf4f153f24c69872d4875b95219639))
- fix flutter test,([8535e746ae3](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/8535e746ae342909109824564983eddcea43f745))
- add lookupCallbackInformationBigInt,([c419411661e](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/c419411661e7298deaa4876638cb6272d4798040))
- Saves a DeviceHolderVK with the CommandPoolVK,([8100ee73dfb](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/8100ee73dfb68d3acda6b884d4c273438fd3094b))
- fix status bar icons turn gray when statusBarIconBrightness not set,([27ae59f85f4](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/27ae59f85f4d22e706a052310dafe2f51e6485eb))
- fix: shorter candidate would cause preview text issue,([86f43bac30b](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/86f43bac30b2772ff59c67270364c3f8210fcd32))
- Modify the srgb rendering to p3 issue, modify the cpu computing issue, and modify the shadow rendering granularity issue,([ea425617c6b](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/ea425617c6b05edeff4e86d3008a69a3cc54955f))
- fix napi lookupcallbackinformation,([0cadb724b12](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/0cadb724b12112ad46f432f922b5ec1f04fef1d6))
- fix lookupCallbackInformation error,([9fa95485c53](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/9fa95485c53d15f82ab0b8fad6efced2100cb919))
- PlatformViewController解耦FlutterView,([8a72888bab1](https://gitcode.com/CPF-Flutter/flutter_flutter/commit/8a72888bab1e1df799771777f78bd39197177998))

## 3.35.7-ohos-0.0.3
- Addressed the issue where cropping with original dimensions in a transformed coordinate system resulted in a size mismatch.,([2c887c51c4](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/2c887c51c4367b1afd531c5cf91de0e31c306c84))
- pick pr1239修复软键盘直接弹起到界面上问题,([a3d23abde7](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/a3d23abde73a0b62b4078676510856634c991086))
- fix: keyboard home key is not consistent,([12f85cb29b](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/12f85cb29b51f31a511e8b20fc0036751161c47b))
- Remove 'ohpm clean' during compilation process.,([6235a61ce8](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/6235a61ce8b87f7831a62f46ee1dec3f88e01563))
- fix: caplock and return keys are not working with keyboard,([75f1a6d62f](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/75f1a6d62fa21b261848f36de5f9dab17ff4dcc9))
- Fixed: onInactive method was not triggered when the WebView became invisible.,([b5d3c710e8](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/b5d3c710e8326cc8d022bdf9d717c9533c497a97))
- Fix the issue of keyboard popping up and flickering in PlatformView input box,([8b4cedebe1](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/8b4cedebe15e7314f52085f076daf5ba630f37a2))
- 3.35分支修复使用multiply混合模式时，在某些GPU上画面变白/变灰的问题,([565fa79cef](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/565fa79ceff5c4609ec5506049eb435cf2183f21))
- 修复monorepo flutter_audioplayers编译失败找不到.dart_tool/package_config.json问题,([17427eb412](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/17427eb412f70f49f7336a6748d0315c1b6d9a0f))
- Frame gate enabled: keep draining producer queue, but do not schedule,([fa00b55c73](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/fa00b55c73d3bcaa0283d2dcd25fabe87b4f0dc2))
- Fix the issue where the clipboard cannot paste content in a custom format,([f7b2f86905](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/f7b2f86905bbf16de9fe1f6e02e6a17488711ba6))
- [Impeller] Fixed an issue where gradient effects on HarmonyOS devices exhibited clipping. With mediump enabled by default, `IPOrderedDither8x8 uint(dest.x)` and `uint(dest.y)` might experience precision loss on some GPU chips.,([b80f24329d](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/b80f24329dc1b8be5216dc5dfa2b8d2ebfebef18))
- Click the status bar to automatically return to the top,([20fd8f2203](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/20fd8f2203a85a1994aea89e785524690e89082a))
- 毕昇编译器替换，开启优化选项,([4770497a69](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/4770497a69a3a76dde9cd8de378acf64ab9eaae6))
- 毕昇编译器替换，开启优化选项,([0ec1873a71](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/0ec1873a71eb2a78687d4aced5025bd13b2330ce))
- 【oh-3.35.7-dev】SensitiveContentChannel适配,([afee5f1f91](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/afee5f1f91ac98057fc39778bb4126a4c99fa230))
- 修复多PlatformView场景下输入框失焦问题【3.35】,([3d38227557](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/3d382275578448a70c202090eb967818eb36ef4b))
- [impeller] Vulkan backend supports skipping rendering when dirty region is 0.,([d89d4e4b9c](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/d89d4e4b9cc69256f9e2ed01eafd79ee37b1f7b8))
- 【3.35】Add monitor for external textures visible area,([569b4226a9](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/569b4226a9d4e79a459591d84efb03aa5c0d421b))

## 3.35.7-ohos-0.0.2
- 退后台释放DMA资降低内存,([3c16902d6d](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/3c16902d6d36ad07a66dd2e7db8217e14a88b27f))
- 修改Column溢出到Column溢出切换,缩放值不准确问题,([8566144b71](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/8566144b710c4db2f18c1997f57420250bee01e6))
- memory leak,([9133d8c390](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/9133d8c390a880f56f23f17c63bcfc7dd213f1f6))
- Fix cache errors related to YUVConversionVK.,([bafc977c9f](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/bafc977c9f5dca9040a638c6a688090b910ae11e))
- fix: false error log when notify page change successfully,([a0cc88cc68](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/a0cc88cc68b19418c85f7cc706d74d1364ac2426))
- Fixed occasional connection failures in flutter run.,([636156bbb9](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/636156bbb99f4156110ddf00d0af2fddaa46c28e))
- feat: notify OHOS when navigate in Flutter,([f1c523d92e](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/f1c523d92e2a6abc27e5de9d0c8acbb9167fa0e3))
- Run 'bin/et format',([4070fb8db5](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/4070fb8db5dfe15b32425d13bfad6be909d05026))
- 修改napi相关的内存泄露问题,([c76408b848](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/c76408b848583c0854fb13b0a6e23f0b758aea17))
- 增加json5文件注释特性解析支持,([5715503dc6](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/5715503dc61f217f51a9e08e4b412b0f3d769eeb))
- Add HarmonyOS platform detection,([4876bb62c5](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/4876bb62c5abcca51f9de69e6fde25831c832a03))
- 【3.35】滑动丢帧事件上报添加FRAME_ID属性与总帧数属性,([f26d64e2a1](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/f26d64e2a1dab1d0d1371399c8b581edc45cb12d))

## 3.35.7-ohos-0.0.1-canary1
- 修复了 Rect.fromLTRB 显示问题 [fa000541](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/fa0005417c1523219c7b473d2f6f2166efa6ad29?ref=oh-3.35.7-dev&prId=772)
- 解决了在 Windows 系统上执行“flutter clean”命令时无法正确删除构建目录和 oh_modules 目录的问题[a26402fe](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/a26402fe546bf4d88b9dca40d0ab06d48831f25c?ref=oh-3.35.7-dev&prId=772)
- 解决了在 Mac ARM64 系统上进行 Flutter 构建时 gen_snapshot 的路径问题[3dcdf735](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/3dcdf735fbf633e7788d33ff8669c4b50778d140?ref=oh-3.35.7-dev&prId=772)
- 修复了 Dart 跟踪模式下应用程序卡顿的问题[ae07d24d](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/ae07d24da7f084c7218b59f1b593055cbb4bd32c?ref=oh-3.35.7-dev&prId=772)
- 解决了 3.35 版本中测试字段键盘无法缩回的问题[cdaa2f61](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/cdaa2f611f31952d7c58228a81267660e8f91e51?ref=oh-3.35.7-dev&prId=772)
- 解决在剪切操作后无法进行粘贴的问题[d3ddc4e0](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/d3ddc4e0e361c9294ab4d2fd3a43768ea58dae8a?ref=fix_pasting&prId=803)
- 修复ohos平台运行build命令，无法生成指定的文件夹[31d92a8c](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/31d92a8c25389ad554c9f01b6f3176032b68b8d9?ref=oh-3.35.7-dev&prId=797)
- 解决了在AndroidStudio 上某些断点无法断住的问题[c4ae8eff](https://gitcode.com/openharmony-tpc/flutter_flutter/commit/c4ae8eff5d0b41b9ccd6a81ccf026bd02c9c107d?ref=start_paused&prId=820)
