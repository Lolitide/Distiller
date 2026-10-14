<!-- 手写文档（非生成物）：改这个文件本身，不会被 tools\build-references.ps1 覆盖 -->

# 14 · FlutterUI 参考导航（Flutter on HarmonyOS）

**回答什么**：能不能用 Flutter 做这个应用的界面？真文档在哪？

---

## 一、先把话说清楚（最重要的一节）

> **Flutter for OpenHarmony 是社区 / TPC（三方组件）适配，不是华为一方能力。**
> 证据：devecocli 本地官方文档库（`$HOME\.local\share\deveco-cli\docs\`）里**没有任何 Flutter UI 文档**，只有零星提及。全库 `grep -i flutter` 命中 76 行，全是顺带一提 —— 性能 Trace 里的 `libflutter.so`、三方框架接入名单里的一行链接、测试能力「不支持 Flutter 应用」之类。
> **所以本文不是本地语料索引，而是外部上游指针。**
> 「本地库里没有」这个判定是对**生成这份副本时的那台机器上的库快照**（`.version` = `1.2.0`）做的 —— 你自己的库可能是别的快照，判定方法见 `09-文档新鲜度与升级.md` §3。

| 问题 | 回答 | 依据 |
| :-- | :-- | :-- |
| 是一方能力吗 | **不是**。官方把它归入「三方开发框架接入」名单，和 React Native、uni-app 并列 | `official/开发指南/Live_View_Kit_实况窗服务/Live_View_Kit常见问题/三方开发框架接入的问题/liveview-faq-2.md`（直链 `atomgit.com/CPF-Flutter`）、`official/开发指南/Account_Kit_华为账号服务/Account_Kit常见问题/三方开发框架接入华为账号一键登录/account-faq-18.md` |
| 本地库里有 Flutter 指南吗 | 只有 **1 篇**，而且是「Flutter 框架 + H5 接入智能填充」，正文 25 行、没有环境搭建内容，只外链到 `gitcode.com/openharmony-tpc/flutter_samples` 的**旧编号树** | `official/开发指南/Scenario_Fusion_Kit_融合场景服务/智能填充服务/三方框架_H5接入智能填充/Flutter框架_H5接入智能填充/scenario-fusion-flutter.md` |
| 本地库里有 Flutter 性能/稳定性内容吗 | 有 4 篇「故障可用 Flutter 栈定位」的，但它们讲的是鸿蒙侧 DFX，不是 Flutter 开发 | `official/FAQ/技术质量/性能/flutter页面滑动卡顿/faqs-performance-1.md`、`official/FAQ/技术质量/性能/折线图等复杂图表页面操作浏览丢帧/faqs-performance-39.md`、`official/FAQ/技术质量/稳定性/CppCrash问题定位/faq-stability-10.md`、`official/FAQ/技术质量/稳定性/JsCrash问题定位/faq-stability-13.md` |
| 本地库说 Flutter 能不能被测试 | **不能**：「当前版本仅支持 Stage 模型开发的 HarmonyOS 应用」 | `official/FAQ/常见问题/是否支持对使用Flutter等三方框架开发的应用进行测试/faqs-deveco-testing-faq-5.md`；另见 `official/FAQ/专项测试/性能基础质量测试/报告中为什么会出现未执行检测/faqs-performance-basic-quality-test-1.md`（「不支持 Flutter 应用及第三方自研的自定义控件识别」） |
| 还有哪些顺带提及 | `official/版本说明/已解决和已知的问题/known-issues-baseline.md`、`official/API参考/调测调优/Performance_Analysis_Kit_性能分析服务/C_API/头文件/hiappevent_h/capi-hiappevent-h.md`（`OH_FLUTTER_DART` 枚举）、`official/最佳实践/功耗场景优化案例/Vsync低功耗优化/bpta-vsync-power-optimization.md`、`official/开发指南/ArkWeb_方舟Web/同层渲染/同层渲染/web-same-layer.md`、`official/开发指南/专项测试/DevEco_Testing/稳定性测试/stability-testing.md`、`official/FAQ/编译构建/集成第三方字节码HAR包报错汇总/faqs-compiling-and-building-222.md`（`flutter build hap` 报错） | —— |
| 本地镜像在哪 | `references\sources\flutter-ohos\`。**这个目录是否已落盘、落了多少，自己看**：`Test-Path references\sources\flutter-ohos` + 数一下 md 篇数（`(Get-ChildItem references\sources\flutter-ohos -Recurse -File -Filter *.md).Count`）。写作本文时它是**空的**（该子目录不存在）；**核对本文时已经不是空的**（实测 607 篇 md），`-Only sources -Apply` 显然已经跑过 | 本文 |
| 与项目规则的关系 | **冲突**：项目要求「零三方依赖」。Flutter 需要独立 SDK、独立引擎 so、独立插件体系 | 项目 README |
| 结论 | **仅供参考，不走主路径。** 不要为 Distiller 规划 Flutter 方案 | 本文 |

---

## 二、上游来源表（只有这三个，都是 2026-10-12 从生成副本的那台机器上 HTTP 抓取验证可达的）

| 上游 | 分支 / 树 | 拿什么 | 抓取方式 |
| :-- | :-- | :-- | :-- |
| `gitcode.com/CPF-Flutter/flutter_samples` | `master`，树 `docs/ohos/` | **规范文档主目录**，15 个主题组 | 原文：`https://raw.gitcode.com/CPF-Flutter/flutter_samples/raw/master/<path>`（已验证 HTTP 200）；枚举：`https://gitcode.com/api/v5/repos/CPF-Flutter/flutter_samples/contents/<path>` |
| `gitcode.com/CPF-Flutter/flutter_flutter` | **`oh-3.35.7-release`**（默认分支，不是 `master`） | `README.md`（环境搭建 / 构建命令 / 指令表 / 20 条 FAQ）、`CHANGELOG_OHOS.md`；对应上游 **Flutter 3.35.7**；许可 **BSD-3-Clause**（已核 `LICENSE`） | 原文：`https://raw.gitcode.com/CPF-Flutter/flutter_flutter/raw/oh-3.35.7-release/README.md` |
| `gitcode.com/CPF-Flutter/docs` | `main` | `ThirdpartyLibrarites.md`（已鸿蒙化的 Flutter 三方库矩阵，170+ 条，按 3.7 / 3.22 / 3.27 / 3.35 分列推荐版本）、`README.md` | 原文：`https://raw.gitcode.com/CPF-Flutter/docs/raw/main/ThirdpartyLibrarites.md` |

**只认 `CPF-Flutter`。** `openharmony-tpc` 与 `openharmony-sig` 是同一内容的组织别名（本地官方文档里的老链接就指向 `openharmony-tpc`），爬取时按 `CPF-Flutter` 钉死，别名只作回退。依据：`flutter_flutter` README 顶部「仓库迁移公告：Flutter OH 相关仓库已整体迁移至 CPF-Flutter 组织」；`liveview-faq-2.md` 也已改指 `atomgit.com/CPF-Flutter`（atomgit 是同期域名）。

> **Flutter 侧的权威仓库是 <https://gitcode.com/CPF-Flutter/flutter_flutter>**（本次由用户指定）。
> 它的 README 是「环境搭建 → 构建 → 指令表 → FAQ」的总入口，也是本文 §五 命令表的唯一来源。
> 本地镜像：`references/sources/flutter-ohos/flutter_flutter/README.md` 与 `.../CHANGELOG_OHOS.md`。

### 二.1 上游 `flutter_flutter` README 指向的其他文章（本地镜像位）

以 `flutter_flutter` 的 README 为准，它显式链出的文章如下。**能镜像的都镜像了**（路径相对 `references/sources/flutter-ohos/`）；
镜像不了的（gitcode wiki、站外站点）只记 URL，理由见 `## 未取证`。

| README 里的标题 | 本地镜像 | 上游 URL |
| :-- | :-- | :-- |
| Flutter OH 开发文档（总入口） | `flutter_samples/_root/README.md` | `.../CPF-Flutter/flutter_samples/blob/master/README.md` |
| 文档树索引（与上一份同名不同文件） | `flutter_samples/README.md` | `.../flutter_samples/blob/master/docs/ohos/README.md` |
| 环境搭建指导 | `flutter_samples/getting-started/flutter-oh-env-setup.md` | `.../docs/ohos/getting-started/flutter-oh-env-setup.md` |
| 应用构建指导 | `flutter_samples/app-development/flutter-oh-app-build-guide.md` | `.../docs/ohos/app-development/flutter-oh-app-build-guide.md` |
| Engine 构建指导 | `flutter_samples/getting-started/flutter-oh-engine-build-guide.md` | `.../docs/ohos/getting-started/flutter-oh-engine-build-guide.md` |
| 版本升级指导 | `flutter_samples/version/flutter-oh-upgrade-guide.md` | `.../docs/ohos/version/flutter-oh-upgrade-guide.md` |
| 更多 FAQ | `flutter_samples/faq/README.md` | `.../docs/ohos/faq/README.md` |
| 更新 Flutter plugin 工程结构 | `flutter_samples/plugin-and-package/update-flutter-plugin-structure.md` | `.../docs/ohos/plugin-and-package/update-flutter-plugin-structure.md` |
| 三方库适配列表 | `docs/ThirdpartyLibrarites.md` | `.../CPF-Flutter/docs/blob/main/ThirdpartyLibrarites.md` |
| Flutter 官方开发指南与 API 文档 | —（站外，未镜像） | <https://docs.flutter.dev/> |
| 迁移公告（wiki） | —（wiki 不可 raw 抓） | `.../flutter_flutter/wiki/…仓库迁移公告…` |
| 版本规划与分支策略（wiki） | —（同上） | `.../flutter_flutter/wiki/Flutter-OH版本演进规划和分支策略.md` |
| 代码合入流程（wiki） | —（同上） | `.../flutter_flutter/wiki/Flutter_OH仓库代码合入流程.md` |
| 跨平台框架白皮书 | —（站外） | `openharmonycrossplatform.csdn.net/6a1d3e4810ee7a33f276c2c5.html` |
| DevEco `build-profile.json5` 配置（FAQ 第 3 条外链） | —（`developer.huawei.com` 是 SPA，抓不了） | `.../harmonyos-guides/ide-hvigor-build-profile-app#section45865492619` |
| hdc 远程访问 hdc server（FAQ 第 5 条外链） | —（站外） | `docs.openharmony.cn/.../subsys-toolchain-hdc-guide.md` |

**README 里另外两条值得记的事实**：当前适配基于上游 **Flutter 3.35.7**（commit `adc90106…`）；**Engine 源码自 3.35.7 起已并入仓库 `engine/` 目录，无需再单独克隆 Engine 仓库**。稳定版本以 tag 获取，形如 `3.47.4-ohos-1.0.0`、`3.35.8-ohos-1.0.4`；版本对应关系见 README「版本规划」表（3.35→2026/03、3.41→2026/06、3.44→2026/09、3.47→2026/12，均为**预估**）。

---

## 三、`docs/ohos/` 目录导航（15 组）

> 上游路径列 = `<repo>/docs/ohos/<组>/<slug>.md`；**本地镜像位 = `references\sources\flutter-ohos\<同上的 docs/ohos 之后部分>`** —— 先确认它已经落盘（见 §一 表里那条自检），别对着一个空目录找文件。
> 证据强度：`docs/ohos/` 根目录与 `getting-started/`、`hybrid-development/` 两组已用 contents API **目录级**枚举并交叉校验；其余 13 组的文件清单来自 `docs/ohos/README.md`（上游自称「Flutter OH 文档索引」），**未做目录级交叉校验**。

| # | 组 | 代表文件（真实 slug） | 为什么读 |
| :-- | :-- | :-- | :-- |
| 1 | `getting-started/` | `overview.md`、`architecture.md`、`project-structure.md`、`flutter-oh-env-setup.md`、`flutter-oh-engine-build-guide.md`、`openharmony-device-guide.md`、`fvm-introduction.md` | 唯一入口：框架介绍、架构、工程目录、DevEco 环境搭建、真机运行、FVM 多版本管理 |
| 2 | `app-development/` | `flutter-oh-core-objects.md`、`flutter-oh-app-lifecycle.md`、`ohos-integrate-flutter.md`、`flutter-oh-app-build-guide.md`、`hvigor-plugin-build.md`、`flutter-ohos-integration.md`、`flutter-split-view-integration.md` | 核心对象、生命周期、构建与签名、Impeller 开关；`flutter-split-view-integration.md` 是折叠屏平行视界 |
| 3 | `hybrid-development/` | `using-flutter-page.md`、`using-flutter-entry.md`、`using-flutter-channel.md`、`using-platform-view.md`、`platform-view-same-layer-rendering.md`、`using-module.md` | **混合开发核心**：FlutterPage/FlutterEntry 嵌页、Channel 双向通信、PlatformView 与同层渲染（已目录级校验） |
| 4 | `plugin-and-package/` | `flutter-library-ohos-check.md`、`ohos-flutter-lib-adaptation.md`、`developing-plugin.md`、`developing-an-ffi-plugin.md`、`update-flutter-plugin-structure.md` | 判断一个 pub 包是否需要鸿蒙适配、以及怎么适配 —— 直接决定「零三方依赖」会不会破 |
| 5 | `rendering-engine/` | `rendering-engine-switching.md`、`flutter-external-texture.md`、`using-ltpo.md`、`rendering-pipeline-and-exception-diagnosis-guide.md` | Impeller / Skia 切换、外接纹理（视频/相机）、LTPO 帧率、渲染异常诊断 |
| 6 | `performance/` | `README.md`、`perf-delimitation-guide.md`、`perf-frame-rendering-tracking.md`、`perf-tuning-memory-analysis.md`、`perf-optimization-preload-render-pipeline.md` | 性能定界 → 线程 → 单帧追踪 → 内存 → 预加载渲染管线（治转场白屏） |
| 7 | `power-consumption/` | `power-consumption-ltpo.md`、`power-consumption-skip-dirty-region.md`、`power-consumption-occlusion-culling.md`、`power-consumption-eliminate-redundant-drawing.md` | 降负载四件套：LTPO、0 脏区跳过、遮挡剔除、不可见时暂停绘制 |
| 8 | `debugging/` | `hot-reload-guide.md`、`debugging-dart-code.md`、`native-arkts-debugging-guide.md`、`flutter-cppcrash-stack-analysis.md`、`memory-and-stability-troubleshooting.md` | 热重载、Dart/ArkTS 双端断点、CppCrash 堆栈符号化 |
| 9 | `troubleshooting/` | `README.md`、`dfx/README.md`、`dfx/dfx-crash.md`、`dfx/dfx-appfreeze.md`、`dfx/dfx-performance.md`、`dfx/dfx-memory.md`、`dfx/dfx-logging.md`、`dfx/dfx-texture.md`、`dfx/dfx-multi-device.md` | 基于 HiAppEvent/HiLog/HiCollie/HiTrace 的问题定位方法论，比 FAQ 系统 |
| 10 | `faq/` | `README.md`（含 `#environment-setup`、`#engine-compilation`、`#app-build`、`#signing-and-release`、`#code-development`、`#plugin-adaptation`、`#rendering-and-ui`、`#runtime-issues`、`#crash-and-debug`、`#permission-and-security` 十个锚点） | 环境/构建/签名/插件/渲染/权限 一页打尽 |
| 11 | `cases/` | `app-release-crash-case.md`、`huawei-id-login-case.md`、`module-debugging-case.md`、`multi-device-responsive-dpi-guide.md`、`webview-white-screen-case.md` | 真实场景复盘；`multi-device-responsive-dpi-guide.md` 讲多设备 DPI 与断点 |
| 12 | `api-reference/` | `flutter-ohos-api-guide.md`、`README.md` | `FlutterAbility` / `FlutterEntry` / `FlutterEngine` / `FlutterView` 的 API 说明 |
| 13 | `version/` | `flutter-oh-upgrade-guide.md`、`flutter-3.35-openharmony-upgrade-guide.md` | 版本升级路径；版本规划另有 wiki 页（**wiki 不可抓**，见 §六） |
| 14 | `skills/` | `README.md` | 上游配套的 AI 技能索引（崩溃分析、性能诊断等） |
| 15 | `media/` | 上游存在的目录，但**内容类型与文件数未取证** | 爬取配置里建议排除 |

---

## 四、坑一：同一仓库里有两棵树，别爬错

`flutter_samples` 仓库里**同时**存在：

| 树 | 状态 | 依据 |
| :-- | :-- | :-- |
| `docs/ohos/` | ✅ **规范位置**，本文 §三 全部基于它 | `docs/ohos/README.md` = 「Flutter OH 文档索引」；contents API 列出的 15 个组与之一致 |
| `ohos/docs/`（`01_framework`、`02_architecture`、`03_environment` … 编号目录） | ❌ **旧树，已被取代** | 本地官方文档 `scenario-fusion-flutter.md` 第 8 行仍直链 `.../blob/br_3.7.12-ohos-1.1.0/ohos/docs/03_environment/openHarmony-flutter环境搭建指导.md` —— 既指向旧树、又是旧 tag |

**爬取时按 `docs/ohos/` 取，并按 `master` 分支取。** 遇到 `ohos/docs/` 的链接一律视为过期。

---

## 五、构建 / 运行命令（逐字引自上游 `flutter_flutter` README「支持指令」表）

来源：`https://raw.gitcode.com/CPF-Flutter/flutter_flutter/raw/oh-3.35.7-release/README.md`

| 用途 | 命令（原文） |
| :-- | :-- |
| 环境检测 | `flutter doctor` |
| 环境配置 | `flutter config --<key> <value>` |
| 创建新项目 | `flutter create --platforms [ohos,android,ios] --org <org> <appName>` |
| 创建 module 模板 | `flutter create -t module <module_name>` |
| 创建 plugin 模板 | `flutter create -t plugin --platforms [ohos,android,ios] <plugin_name>` |
| 创建 plugin_ffi 模板 | `flutter create -t plugin_ffi --platforms [ohos,android,ios] <plugin_name>` |
| 查找设备 | `flutter devices` |
| 安装应用 | `flutter install -t <deviceId> <hap文件路径>` |
| 资源打包 | `flutter assemble` |
| 构建（测试） | `flutter build hap --debug [--target-platform ohos-arm64] [--local-engine=<兼容ohos的debug engine产物路径>]` |
| 构建（正式） | `flutter build hap --release [--target-platform ohos-arm64] [--local-engine=<兼容ohos的release engine产物路径>]` |
| 运行 | `flutter run [--local-engine=<兼容ohos的engine产物路径>]`；README 的 FAQ 第 10 条里出现过 `flutter run -d $DEVICE --debug` |
| 调试模式附加 | `flutter attach` |
| 截屏 | `flutter screenshot` |
| 取依赖 / 清理 | `flutter pub get` / `flutter clean` / `flutter pub cache clean` |

README FAQ 第 12 条明确：**构建 Hap 直接 `flutter build hap` 即可，不再需要 `--local-engine` 参数**（直接从云端取编译产物）。README 的 20 条 FAQ 里还有两条高频坑：切换 `FLUTTER_STORAGE_BASE_URL` 后必须删 `<flutter>/bin/cache` 并 `flutter clean`；SDK 许可未接受时用 `./ohsdkmgr install ets:9 js:9 native:9 previewer:9 toolchains:9 --sdk-directory='<path>' --accept-license`。

---

## 六、抓取运维观察（2026-10-12，生成副本的那台机器上实测）

| 观察 | 结论 |
| :-- | :-- |
| `developer.huawei.com/consumer/cn/doc/**` | **JS-only SPA，不可爬**。本次实测 `.../harmonyos-guides/web-page-loading-with-web-components` 返回 HTTP 200，但正文只有 `文档中心` 四个字（一个 SPA 外壳）。**因此对这类 URL 做 slug 探测毫无意义** —— 任何 slug 都会 200 并返回同一个壳 |
| gitcode 匿名 contents API | 快速连续调用约 **100 次**后会开始返回 **HTTP 429**。枚举要放慢（加间隔），不要并发打 |
| `git/trees/<sha>?recursive=1` | **坏的** —— 只返回根节点，拿不到递归树。要目录清单只能用 contents API 逐层走 |
| gitcode **wiki** 页 | **不能 raw 抓**。实测 `gitcode.com/CPF-Flutter/flutter_flutter/wiki/<page>.md` 返回 HTTP 200，但正文只是同一个 SPA 外壳（`AtomGit - 全球开发者的开源社区...`）。**所以版本规划、代码合入流程这类只存在于 wiki 的内容，本次拿不到** |
| raw 取文件 | ✅ 可用，两种形式都通：按分支 `https://raw.gitcode.com/<owner>/<repo>/raw/<branch>/<path>`；按 blob `https://raw.gitcode.com/<owner>/<repo>/blobs/<sha>/<path>`（contents API 的 `download_url` 给的就是后者） |

---

## 七、诚实的限制

- 本地官方文档库快照 `.version` = `1.2.0`（**生成这份副本的那台机器的库**）；本文 §一 的「本地库里没有 Flutter UI 文档」只对该快照成立 —— 你自己机器上是哪个快照，看 `09-文档新鲜度与升级.md` §3。
- `docs/ohos/` 下 md 的**精确总数没有枚举出来**（受 429 限流所限），只完整枚举了根目录与两个子目录。
- **本文没有任何内容在机器上跑过** —— 没装 Flutter SDK、没跑 `flutter doctor`、没构建过 HAP。全部是文档与 HTTP 抓取结论。

## 未取证

1. **`docs/ohos/` 下 md 的精确总数**；13 个组的文件清单只来自 `docs/ohos/README.md` 索引，**未做目录级交叉校验**（只校验了 `getting-started/`、`hybrid-development/`）。
2. **`media/` 组的内容**：类型、文件数、是否全是图片 —— 未枚举。
3. **`CHANGELOG_OHOS.md` 的内容**：未抓取，本文因此说不出 OH 适配改了引擎的哪些部分。
4. **`references\sources\flutter-ohos\` 的完整性**：这个目录**已经落盘**（核对时实测 607 篇 md；`flutter_samples\` 下是**去掉 `docs/ohos/` 前缀**的 14 个组 + `README.md` / `README.en.md`，另两个仓库落成 `docs\`、`flutter_flutter\`）。但本文写作时它是空的 —— 所以 §三 各组的文件清单**没有对着实际文件逐条核过**；另外 §三 表格里的 `media/` 组**在镜像里根本不存在**（与「爬取配置里建议排除」一致）。
5. **upstream wiki 页正文**：不可 raw 抓（见 §六），所以版本规划、分支策略、代码合入流程的具体内容未知。
6. **Flutter 接入对 HAP 体积 / 内存的量化影响**：没有官方数字，本地官方库也没有。
7. **Flutter OH 的商用合规结论**：`flutter_flutter` 的 `LICENSE` 是 BSD-3-Clause（已核），但「以社区适配版的引擎打进商业闭源 App」的完整合规边界未取证。
8. **`flutter_flutter` 的 `oh-3.35.7-release` 是否真的是默认分支**：README 与仓库结构一致指向该分支，但未通过 API 读仓库默认分支字段确认。
