---
name: distiller-dev
description: |
  知了（Distiller）校园信息助手 —— HarmonyOS 应用的项目开发技能。把项目的调研结论、平台硬约束、
  工程规约，以及**用得到的官方鸿蒙文档全量本地副本**固化在一起，让 agent 写码前就地取证、不必联网、
  不必回翻散落的调研笔记。含 ArkUI / 鸿蒙7 新 UI 能力 / WebUI(ArkWeb) / Flutter 四路 UI 参考与可复制模板。

  触发场景：
  (1) 在 Distiller / 知了 项目里写码、改页面、改配置（module.json5 / build-profile.json5 / oh-package.json5）
  (2) 分享接收、实体抽取、OCR、语音识别、代理提醒、日历兜底、通知授权、云函数中继、QQ 机器人
  (3) 分层与状态管理决策（MVVM、ArkUI V2 装饰器、跨页状态）
  (4) 查 ArkUI 组件 / 属性 / 状态管理 V2 的真实用法与签名
  (5) 想用鸿蒙 7（API 26.0.0）的新 UI 能力（沉浸光感、系统材质、容器断点、懒加载瀑布流、全局复用池、闪控窗）
  (6) 想评估 WebUI（ArkWeb 混合开发）或 Flutter 跨平台路线
  (7) 编译报错、真机验证、日志排查
  (8) 需要回答「这条平台结论的官方依据是什么」或「哪些结论其实还没取证」
---

# 知了 / Distiller · 项目开发技能

> **本技能不替代 ArkUI 通用专家技能**，它补的是它们没有的东西：**这个项目的约定**与**这个项目用得到的那批官方文档的本地副本**。

## 0. 技术基线（动手前先对齐）

> **这个技能是给小组三个人共用的，但每台机器环境不同。**
> §0.1 是**项目事实**，与机器无关，照做即可；
> §0.2 是**本机环境**，**必须先探测再动手** —— 绝不要把下面出现的任何路径、版本号、设备状态当成"全组都一样"。
> 唯一权威的探针块在 `references/01-项目基线.md` §1.1，别处不重复贴。

### 0.1 项目基线（团队共享，机器无关）

| 项 | 值 |
| :-- | :-- |
| 应用 | 知了 · 校园信息助手 / Distiller |
| bundleName | `com.xjtu.distiller` |
| 目标运行环境 | **HarmonyOS 6.0.2(22) 手机**（`deviceTypes: ["phone"]`） |
| 工程 SDK 版本 | `targetSdkVersion` = `compatibleSdkVersion` = `"6.0.2(22)"` |
| 模块 | **只有 `entry`** |
| 依赖 | **零三方依赖**（根与 entry 的 `dependencies` 都是空） |
| 签名 | `signingConfigs: []` → 产物是 `entry-default-unsigned.hap`，**装不进真机** |
| 工具链 | `devecocli` 是统一入口，**不手搓** `hvigorw` / `ohpm` / `hdc`。子命令：`create` / `build` / `run` / `device` / `emulator` / `log` / `docs` / `skills` / `check` / `ui` / `auth` / `signature` / `init` / `serve` / `update` |
| 协作工具 | 三人**共用一个仓库**，所以同一时刻只改自己名下的文件（见 `01-项目基线.md` 文件归属表） |

### 0.2 本机环境（**自己探测，不要照抄**）

下表左边是"要知道什么"，右边是"怎么查"。**探测结果各人不同**，也可能是随时变化的（设备插拔、模拟器启停、CLI 升级）。

| 要知道 | 怎么查 |
| :-- | :-- |
| CLI 版本 | `devecocli --version` |
| 有没有可用设备 | `devecocli device list` |
| 有哪些模拟器、什么状态 | `devecocli emulator list` |
| **SDK 根在哪** | 见下方 warning —— 这一项最容易踩坑 |
| shell 能力 | `$PSVersionTable.PSVersion` ；`Get-Command pwsh -ErrorAction SilentlyContinue` |
| 文档库在哪、什么版本 | 见 `references/09-文档新鲜度与升级.md` |

> [!warning] `$env:DEVECO_SDK_HOME` **不保证指向真 SDK**
> 实测：本机它指向 `<...>\DevEco Studio beta\sdk`，那里面**只有 `licenses` 与 `system-image`（系统镜像）**，
> 真 SDK 在它的**兄弟目录** `<...>\DevEco Studio beta\DevEco Studio\sdk\default`。
> 所以别写 `$env:DEVECO_SDK_HOME\default`。判断一个目录是不是 SDK 根，看它下面有没有 `openharmony\ets\api` 或 `hms\ets\api`。
> 完整探法（实测可用）写在 `references/01-项目基线.md` §1.1。
>
> **`tools/build-references.ps1` 已按这套逻辑自动探测 SDK**：它依次试 `DEVECO_SDK_HOME` 本身 / 它的 `default` / 它父目录下的多种形态，
> 都不中才退到写死的最后一条并给出提示。找不到时**只跳过 sdk 这条产出线**，其余照常。

> [!note] 为什么 §0.2 不写具体值
> 早先版本这里写死了「本机 SDK = `D:\Coding\...`、`device list` = No active devices、模拟器均 stopped、只有 PowerShell 5.1」。
> 那些是**写这份技能时那台机器**的状态，对队友既不成立、也会随设备插拔而失效 —— 会让人照着错的前提干活。
> 现在一律改成"怎么查"。**需要举例时**，请明确标注"这是某一台机器的实测值"。

## 1. 目录导航

| 文件 | 内容 | 什么时候翻 |
| :-- | :-- | :-- |
| `references/01-项目基线.md` | 项目身份、分层目录与文件归属、命名编号、主题真值源、提交规范 | 开工前；不确定某个文件该放哪、归谁 |
| `references/02-编码规约.md` | ArkUI V2、动态 import、service 契约、路由、数据字段纪律、linter | 动手写码前 |
| **`references/03-能力速查.md`** | **能力 → 硬约束 → 出处** 的速查表 | **写任何涉及平台能力的代码之前**（第一顺位） |
| `references/04-验证闭环.md` | check → build → 产物 → run → log 的命令与判据 | 每次改完 |
| `references/05-已知坑.md` | 平台坑 + Windows/工具链坑 | 撞到怪问题时；以及每次写脚本前 |
| `references/06-未取证清单.md` | ~60 条未取证/未验证/有冲突项 | 想把某条结论当事实用之前；答辩前 |
| `references/07-官方文档索引.md` | 【生成】官方文档副本全量表 + 文档库指纹 | 想知道某篇在哪、这份副本有多新 |
| `references/08-SDK签名索引.md` | 【生成】Kit 桶导出 + `.d.ts` 声明大纲（带行号） | 要查真实签名、`@since`、`@permission` |
| `references/09-文档新鲜度与升级.md` | 文档库机制 + 升级 runbook | 需要刷新文档快照时 |
| `references/10-漂移报告.md` | 【生成】跨版本逐文件漂移（`-Check [-Against <历史指纹>]`） | 升级文档库之后 |
| **`references/11-鸿蒙7新UI能力.md`** | 鸿蒙 7 新 UI 能力 + 版本门槛 + 示例指向 | 想用 26.0.0 的能力，或想动 `targetSdkVersion` |
| `references/12-UI参考导航.md` | ArkUI 阅读顺序 + 按任务查表 + API 分类 | 做 UI 时找文档 |
| `references/13-WebUI参考导航.md` | ArkWeb 混合开发导航 | 评估/使用 WebUI 路线 |
| `references/14-FlutterUI参考导航.md` | Flutter on HarmonyOS 导航 + 风险声明 | 评估 Flutter 路线 |
| `references/15-复核报告.md` | 【生成】`03`/`06` 的结论在新库里还成不成立（`-Revalidate`） | 升级文档库之后 |
| `references/official/` | 【生成】官方文档副本，路径即 documentId | 取证 |
| `references/project/` | 【生成】项目调研文档镜像 | 需要原始调研口径时 |
| `references/sources/flutter-ohos/` | 【生成】gitcode 上的 Flutter OH 文档树 | Flutter 参考 |
| `references/examples/` | 【生成】官方示例片段（含出处与行号） | 找可抄的代码 |
| `templates/` | 手写的可复制片段（**6 个模板已过语法检查，0 error**；见 `06-未取证清单.md` #67–70） | 直接抄进工程 |
| `tools/` | 爬取、SDK 索引、示例抽取、安装脚本 | 维护本技能 |

> **`templates/*.ets` 的验证状态（2026-10-12 实测更新）**
> 6 个模板已全部送 `mcp__deveco__check`，**0 error**（`dynamic-import.ets` 那个唯一的 error 是暂存路径导致 —— `Cannot find module '../common/ServiceResult'`，真实工程里两者同层即消失）。
> 过程中**修掉一个真缺陷**：`global-reuse-pool.ets` 的 `@Builder toolbar()` 撞了 `CustomComponent` 的保留成员名，报 2416/2345，已改名并复检（见 `05-已知坑.md` P5）。
> **但语法通过 ≠ 能跑** —— 运行期仍是空白。抄进 `entry/src/main/ets/` 之后**必须再走一遍第 4 节的验证闭环**；
> 各模板末尾带一份「真机验证清单」，可作为验证阶段的任务来源。
> 送检方法见 `05-已知坑.md` T8：模板在 skill 包内，要**临时拷进 entry 模块**才送得进去（放在工程根的裸目录里 LSP 不返回诊断，不算通过）。

## 2. 十条硬约束（违反即不通过）

1. **状态管理只用 V2**：`@ComponentV2` / `@Local` / `@Param` / `@Event` / `@ObservedV2` / `@Trace`。**不与 V1 混用**。组件复用一律用 **`@ReusableV2`**（不是 V1 的 `@Reusable`）—— 官方混用矩阵里「V2 父 + V1 复用子」的结果是**子组件根本不创建**，属功能性故障。
2. **AI 能力（NLU / OCR / ASR）必须动态 `import()`**，禁止顶层 `import` —— 否则模拟器上会**直接闪退**（报错模板见 `05-已知坑.md`）。这层包装只放在 `service/ai/`。
3. **调用链固定 `页面 → ViewModel → service → repository`，不跳层。** 页面不直接调系统能力。
4. **`service/cloud/` 是唯一能碰云端的地方**，只从 `repository/` 读、只往 `repository/` 写；云返回对象必须先过字段白名单，不许直接交给页面。
5. **页面里不许出现裸色值 `'#RRGGBB'` 或裸尺寸**，一切取值来自 `utils/Theme.ets`（单一真值源）。这条是拒绝合并的理由。
6. **权限申请只在 `service/system/`**，页面只拿「已授权 / 未授权 / 被拒绝」三态。
7. **提醒对外只暴露「发布 / 撤销 / 查询」**，页面与 ViewModel 里不许出现 `if (用了日历)` 这类分支。
8. **数据字段纪律**：`raw_text` / `raw_json` 必须存且**永不上云**；缺失字段进 `missing_fields`，**不编造**；周期存平台原样的 `repeat`，**不存 `rrule`**。
9. **`notificationId` 必须与任务 id 建立确定性映射**，不许随手取随机数（相同的 id 会互相覆盖）。
10. **AI 三件套统一返回「成功 / 失败 + 错误码」**，不许把异常抛到页面层。

## 3. 取证纪律（本技能存在的理由）

**查到再写，查不到就说查不到。** 顺序：

1. 先查 `references/03-能力速查.md`；
2. 再在 `references/official/` 里按关键词搜（副本路径就是 documentId）；
3. 再查 `references/08-SDK签名索引.md` 拿真实签名与 `@since`；
4. 还查不到 → 用 `devecocli docs search <kw> --catalog harmonyos-guides|harmonyos-references|... --format json --limit 5` 反查；
5. **仍然查不到 → 明确写「未取证」**，并把它加进 `references/06-未取证清单.md`。**绝不允许凭记忆编造 API / 参数 / 版本。**

三条附加规则：
- `06-未取证清单.md` 里的条目**一律不得当作事实**，不得用于排期或实现依据。
- 引用官方文档时**给出 documentId**，别只写「官方文档说」。
- **注意文档快照日期**：`07-官方文档索引.md` 与 `09-文档新鲜度与升级.md` 表头有 `.version` 与 `docsZipSha256`。快照会过时。

## 4. 验证闭环（每次改动都走）

完整命令与判据见 `references/04-验证闭环.md`，最小闭环：

```text
1) mcp__deveco__check          传**相对工程根**的路径（绝对路径会被拒）
   → 返回「没有有效的 .ets 文件」或「No diagnostics collected」**不算通过**，改走 2)
2) devecocli build --modules entry
   → 产物 entry/build/default/outputs/default/entry-default-unsigned.hap
   → 文件名里的 unsigned 意味着**装不进真机**，看到就别去 devecocli run
3) 有设备时：devecocli device list → devecocli run --module entry --device <sn>
4) 排查：devecocli log --level E / --crash / --level I --bundle-name com.xjtu.distiller --follow
```

**「做完」的定义**：`mcp__deveco__check` 无新增报错 **且** `devecocli build` 通过。

**不许谎报**：没有设备就只说「编译通过，未做运行验证」；跑挂了就贴证据。

## 5. 改动纪律

- 一人一时只改**自己名下**的文件；改别人的，先在该文件顶部留 `TODO(你的名字): 原因`。
- 提交信息**必须带任务号**：`[W1-T03] 六页静态原型`。**没有任务号的提交不接受。**
- 不许提交编译不过的代码，也不许用注释把它「弄过」。
- 仓库内**一律 LF 行尾**（`.gitattributes` 已锁），否则会出现「整个文件都改了」的假 diff。
- **写 `.ps1` 必须带 UTF-8 BOM** —— PS 5.1 会把无 BOM 的 UTF-8 当 ANSI 解析，中文全乱、报一堆假语法错。用 `tools/ensure-bom.ps1` 修。
- **永远不要手改 `~\.local\share\deveco-cli\docs`** —— devecocli 换版本会整库 `rm -rf` 重解。要留证据就留进本技能的 `references/`。

## 6. UI 能力选用规则（重点）

本项目 `targetSdkVersion = 6.0.2(22)`，而**鸿蒙 7 = API 26.0.0**。官方原文：

> 「此变更已做版本隔离，变更仅在应用的targetSdkVersion设置为大于等于26.0.0时生效。」

所以：

- **默认走「显式调用新增 API」**，不轻易动 `targetSdkVersion`。26 新增 API 多标注 `@since 26.0.0`，**在 6.0.2(22) 上的降级行为官方没有说明**（见 `06-未取证清单.md` #60）。
- **任何 26 能力在没跑过 26 设备前，一律标注「未验证」**，不许声称验证过。想用就用 `devecocli emulator list` 看自己手上有没有 7.0.0 模拟器（本机组装时是 stopped，不在开发机上），或在真机上验 —— 拿不到就老实写「未验证」。
- **若要把 `targetSdkVersion` 提到 26**，先知道代价：会一次性吞下全部 UX 行为变更 —— 表单类组件触摸热区 **28vp → 32vp**、内置文本换行与行高策略、字体升级导致的排版位移。**先排一次全页面走查**（重点：360vp 宽度下的紧凑布局）。
- 具体能力清单与本地文档路径见 `references/11-鸿蒙7新UI能力.md`。

## 7. 文档刷新

```powershell
cd E:\Program_File\Skill\Distiller-Skill
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1            # 演练
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Apply     # 落盘
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Check     # 只读比对漂移
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Revalidate -Apply
```

- `-Profile project` 只爬项目主链路（约 1000 篇 / 6.6 MB）；默认 `-Profile all` 约 3800 篇 / 约 45 MB。
- **改清单改 `tools/reference-manifest.json`，不要手改生成物。**
- 文档库要升级先看 `references/09-文档新鲜度与升级.md` 的 runbook（**升级是全局动作，由人在终端执行**）。
