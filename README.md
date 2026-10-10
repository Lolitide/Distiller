# 知了 · 校园信息助手

> 基于 HarmonyOS 的校园信息智能整理与提醒应用。西安交通大学《移动应用开发》课程项目。

校园通知先出现在 QQ 群里，刷得快、没有重要性区分，重要消息常常是「看到了但没记住」，直到截止前才想起来。**这个应用只做一件事：把你看到的那些消息，变成你自己那份待办清单里带时间的条目，并在到期前提醒你。**

`Distiller` 是「蒸馏」的意思——把一段啰嗦的群消息，蒸出「什么事项、什么时候截止」。

## 1. 团队与周期

| 成员 | 主要职责 | 主要交付物 |
| :-- | :-- | :-- |
| 架构（组长） | 架构与范围冻结、进度把控；QQ 机器人接入与解析链路、字段约定；解析页与确认页 | 需求与范围文档、机器人接入与字段约定、确认页实现、每周进度记录 |
| 界面 | 界面与交互；首次启动、首页时间线、任务列表与详情、设置页；视觉规范与素材 | 页面原型、ArkUI 页面实现、应用图标与商店截图 |
| 需求方 | 系统能力集成；分享接收、文字识别与语音、系统 AI 能力接入、提醒、本地存储；测试与缺陷跟踪 | 能力接入代码、本地数据模型、真机测试记录与缺陷清单 |

**周期 4 周**，原则是「先验证可行性，再跑通闭环，最后补异常和上架」：

| 周 | 出口条件（一句话） |
| :-- | :-- |
| 第 1 周 | 冻结范围；六页静态原型；假数据跑通「粘贴 → 解析 → 确认 → 任务」；**真机验证代理提醒、系统 AI 抽取、机器人中继三项能力** |
| 第 2 周 | 能交给同学试用的版本：真解析、真存储、真提醒 |
| 第 3 周 | 异常路径补齐；5–10 名同学真机试用；收齐反馈与修复清单 |
| 第 4 周 | 隐私政策、图标与截图、签名打包、提交审核；答辩材料 |

详细到天级的排期、每张任务卡、风险与兜底方案在 **[docs/开发指南.md](docs/开发指南.md)**。

## 2. 当前状态

| 项 | 状态 |
| :-- | :-- |
| 工程骨架 | 已建（`devecocli create` 的 Empty Ability 模板），`devecocli build` 通过 |
| 书面材料 | 开发指南 + 取证台账 + 三份调查笔记已入库（见 `docs/`） |
| 页面实现 | 未开始。当前只有模板自带的 `pages/Index.ets` 占位页 |
| 真机验证 | **未开始**。团队只有界面一台 HarmonyOS 6.0.2(22) 手机，本开发机上 `devecocli device list` 为 `No active devices` |
| 云中继 | 未开始。需要 AGC 账号先完成实名认证（W1-T11） |

**第 1 周的第一个阻塞项是代理提醒**：官方文档明确「部分设备上代理提醒增加了管控机制，应用无法直接使用」，需要向华为申请代理提醒权限，审批约 8 个工作日。**W1-T06 必须在第 1 周前两天提交**，别拖到末期才发现没有退路。

## 3. 怎么构建和跑

工具链统一用 `devecocli`（本机 v1.2.0），不要手搓 `hvigorw` / `ohpm` / `hdc`。

```text
# 构建（默认 product=default、build-mode=debug）
devecocli build

# 只构建 entry 模块 / 建 release 包
devecocli build --modules entry
devecocli build --build-mode release

# 清理
devecocli build clean

# 装到设备上跑（多设备时必须显式 --device）
devecocli device list
devecocli run --module entry --device <sn>

# 看日志 / 只看崩溃
devecocli log --level E
devecocli log --crash
```

产物路径：`entry/build/default/outputs/default/*.hap`（debug）。

**注意**：当前 `build-profile.json5` 的 `signingConfigs` 为空，构建会给出

```text
WARN: Will skip sign 'hos_hap'. No signingConfigs profile is configured in current project.
```

——也就是说**能构建、产物未签名**。要装到真机上必须先在 DevEco Studio 里配置自动签名（见开发指南 §10 与 §9.5）。

**环境前提**：本机 SDK 为 HarmonyOS 26.0.0 Beta2（`apiVersion 26`），与工程的 `targetSdkVersion 6.0.2(22)` 兼容。

## 4. 目录结构

```text
Distiller/
├── AppScope/                     # 应用级配置：bundleName com.xjtu.distiller、版本号、图标
├── entry/                        # 唯一模块
│   └── src/main/
│       ├── module.json5          # 权限、扩展能力、页面注册（唯一改动点）
│       ├── ets/
│       │   ├── entryability/     # EntryAbility
│       │   ├── entrybackupability/
│       │   ├── pages/            # A_* 一级页 / B_* 二级页
│       │   ├── viewmodel/        # 每个页面一个 ViewModel
│       │   ├── model/            # 数据结构与字段约定
│       │   ├── repository/       # 数据库与首选项访问
│       │   ├── service/          # 能力封装，按子域分目录，每个子域一个 index.ets 桶导出
│       │   │   ├── ai/           #   文字识别 / 语音 / 实体抽取（动态引入）
│       │   │   ├── system/       #   提醒、通知授权、权限申请
│       │   │   ├── backend/      #   bot 中继的契约与字段约定
│       │   │   └── cloud/        #   云端拉取与回写（唯一能碰云端的地方）
│       │   └── utils/            # Theme.ets 等，色彩与尺寸的单一真值源
│       └── resources/
├── docs/                         # 开发指南、取证台账、调查笔记（见下）
├── tools/
│   └── sync-docs.ps1             # 从权威源同步书面材料
├── build-profile.json5           # 工程级：products / modules / SDK 版本
├── oh-package.json5              # 运行时依赖保持为空（零三方库）
└── hvigorfile.ts
```

`pages/` 用 `A_`（一级页）/ `B_`（二级页）前缀，路由走「单入口 + 内部 Navigation」，`main_pages.json` 只注册入口页。

## 5. 书面材料

全部在 **[docs/](docs/)**，从 [docs/README.md](docs/README.md) 进：

| 文件 | 一句话 |
| :-- | :-- |
| [docs/开发指南.md](docs/开发指南.md) | 排期、分工、任务卡、工程落位、风险与兜底。**每天开工前看** |
| [docs/99-附录-取证台账.md](docs/99-附录-取证台账.md) | 每条平台结论的原文出处与 SDK 行号，以及明确写出的「未取证」清单 |
| [docs/_调查/01-分享接收取证.md](docs/_调查/01-分享接收取证.md) | 分享接收的两种形态取舍与落地片段 |
| [docs/_调查/02-无障碍读屏取证.md](docs/_调查/02-无障碍读屏取证.md) | 无障碍读屏为什么做不了 |
| [docs/_调查/03-OCR-ASR与模拟器约束取证.md](docs/_调查/03-OCR-ASR与模拟器约束取证.md) | 图片识别与语音识别的硬约束、无真机时的替代手段 |
| [docs/大学信息源_开题报告.tex](docs/大学信息源_开题报告.tex) | 立项依据、竞品对比、明确不做的清单 |

> [!note] 权威源
> `开发指南.md` 与 `99-附录-取证台账.md` 的权威副本在 `E:\Program_File\HMOS_proj\Distiller-DOC\`。仓库里的是同步副本，改完源文件跑 `powershell -File tools\sync-docs.ps1 -Apply` 回灌。

## 6. 动手前必须知道的几条

这几条都已在 [docs/99-附录-取证台账.md](docs/99-附录-取证台账.md) 取证，写代码前先看，能省掉整段返工。

| 事项 | 结论 |
| :-- | :-- |
| 代理提醒 | 手机上**存在管控**，要申请；单个应用有效提醒**不超过 30 个**；配额不足时错误码 `1700002`。兜底路径是 Calendar Kit |
| 无障碍读屏 | **做不了**：相关接口自 API 12 全部废弃，官方原文「系统不再开放相关能力」，审核指南 2.10 还把「开启辅助功能」列为禁止诱导项。这条通道已从排期砍掉 |
| 图片文字识别 | **不支持模拟器**，且模拟器上静态 import 会让应用直接闪退；输入必须是 `RGBA_8888` 的 PixelMap。要用**动态引入** |
| 实体抽取 | 同样**不支持模拟器**；文本上限 1000 字符；`EntityType` 只有 10 类，**没有「事项」这一类**，事项提取是我们自己的规则 |
| 分享接收 | 文本与图片两种承载形态官方并列支持，注册片段与取值 API 一字不差；图片以 `record.uri` 传来，**不是 PixelMap** |
| 云端中继 | 用 Cloud Foundation Kit（云函数 + 云数据库），不自建、不租服务器；连接方式走 WebSocket，**不依赖公网入口** |
| 数据边界 | 云上只存十个字段，`raw_text` / `raw_json` / 发送者 / 群号 / 消息 id **一律不出手机** |

## 7. 一句话记住

**第 1 周的任务不是写代码，是把「代理提醒能不能用」和「机器人中继走不走得通」这两件不确定的事问出答案——所以先把 W1-T06 提交上去，再去搭页面。**
