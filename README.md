# 知了 · 校园信息助手

> 基于 HarmonyOS 的**校园信息智能整理与提醒**应用。把群聊里刷得飞快、看完就忘的通知，变成你自己那份「带时间的待办」。

`Distiller` 是「蒸馏」的意思——把一段啰嗦的群消息，蒸出「什么事项、什么时候截止」。

**技术栈**：HarmonyOS 6.0.2(22) · ArkTS / ArkUI 状态管理 V2 · 零三方依赖
**包名**：`com.xjtu.distiller` · **许可证**：[MIT](LICENSE)

---

## 1. 它解决什么问题

课程通知、社团报名、比赛截止这些事，最先出现在群里：一门课一个群，一个社团还有好几个群。消息刷得快、没有重要性区分，重要的事常常「看到了但没记住」，直到截止前才想起来。

**这个应用只做一件事**：把你看到的那些消息，变成待办清单里带时间的条目，并在到期前提醒你。

数据流：群消息 → 后端解析出「候选」（事项 / 时间 / 地点）→ 手机拉取 → 落成本机任务 → 到期提醒。

---

## 2. 宣传与材料

| 材料 | 文件 | 大小 | 内容 |
| :-- | :-- | --: | :-- |
| 宣传视频 | [`docs/media/Distiller_Promo.mp4`](docs/media/Distiller_Promo.mp4) | 31 MB | 从群消息到待办的主流程、列表／详情／板板三屏、提醒与同步 |
| 说明文档（PPT） | [`docs/media/Distiller-说明文档.pptx`](docs/media/Distiller-说明文档.pptx) | 32 MB | 项目说明、功能拆解与界面演示 |

> 两个文件都在 `docs/media/` 下：mp4 可在 GitHub 页面直接内嵌播放；pptx 需下载后用 PowerPoint / WPS / Keynote 打开。
## 3. 功能

### 已实现

| 模块 | 能力 |
| :-- | :-- |
| 任务列表 | 按天分组（今天 / 明天 / 本周…，「未安排日期」置顶）、待确认消息分组、组展开收起并记忆、顶部筛选 Chip、卡片六态、批量编辑与确认删除、回收站 |
| 任务详情 | 名称原地编辑、步骤增删改查与完成态、属性卡（提醒 / 到期 / 重复）、元信息卡（重要性 / 难度 / 类型 / 地点 / 链接 / 置信度）、标签卡、备注卡、原文对照（只读、可复制） |
| 新建任务 | 半模态三入口（截图 / 录音 / 文本）、AI 预填与低可信提示、属性 chips、标签输入、保存落库 |
| 板板（甘特） | 按类型分轨的甘特视图、可拖时间轴与表头拉条、当前时刻参考线、任务摘要区 |
| 端侧识别 | 图片文字识别（Core Vision Kit）、语音转文字（Core Speech Kit）、端侧文本抽取；三件套在 `service/ai/` |
| 提醒与日历 | 系统代理提醒发布 / 撤销、按提前量在到期前提醒、完成自动撤销；系统提醒不可用时写入自建日历账户兜底并随完成清除 |
| 分享接收 | 注册 `ohos.want.action.sendData`（纯文本 / 富文本 / 图片），其他应用分享进来即进入待确认 |
| 搜索 | 关键词搜索，未输入 / 无结果 / 有结果三态 |
| 设置 | 主题三色、卡片密度、提醒提前量、后端地址与连通性检查、设备注册与绑定、群订阅开关、云端字段白名单页、应用内隐私页与授权撤回、清空本机任务、删除服务端数据 |
| 数据 | CSV / JSON / 剪贴板导出，任务导入，回收站恢复与清空 |
| 推送 | Push Kit Token 注册与通道状态上报 |
| 视觉与主题 | M3 风格、单一真值源的主题系统（`utils/Theme.ets`）、自绘悬浮底部导航、与页面同色的状态栏、首次启动引导 |
| 后端对接 | 设备注册、绑定码、绑定状态、群列表、订阅 / 退订、候选增量拉取（游标）、原文取回、字段白名单回传 |

### 已知边界（如实标注）

| 项 | 现状 |
| :-- | :-- |
| 账号与多设备同步 | **明确不做**：`service/auth/` 只有占位注释，无登录；本机数据即唯一真相 |
| 解析结果 | 由服务端大模型从群消息整理而来，**可能存在偏差**，需用户核对后再保存 |
| 后端依赖 | 中继需自备或在设置里填写地址；未配置时本机功能（任务增删改查、提醒、日历、导入导出）仍可用 |
| 应用市场 | 尚未提审，签名与隐私标签材料仍在准备 |
---

## 4. 构建与运行

工具链统一用 `devecocli`（DevEco 的命令行封装），不建议手搓 `hvigorw` / `ohpm` / `hdc`。

```bash
# 构建（默认 product=default、build-mode=debug）
devecocli build

# 只构建 entry 模块 / 出 release 包
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

产物路径：`entry/build/default/outputs/default/*.hap`。

> **注意**：仓库里 `build-profile.json5` 的 `signingConfigs` 为空，构建会提示
> `WARN: Will skip sign 'hos_hap'. No signingConfigs profile is configured in current project.`
> —— 也就是**能构建、产物未签名**。要装真机需在 DevEco Studio 里配置自动签名。

**环境**：HarmonyOS SDK（`targetSdkVersion` / `compatibleSdkVersion` 均为 `6.0.2(22)`）。

---

## 5. 目录结构

```text
Distiller/
├── AppScope/                  # 应用级配置：bundleName、版本、图标（分层图标）
├── entry/                     # 唯一模块
│   └── src/main/
│       ├── module.json5       # 权限、ability、页面注册
│       ├── ets/
│       │   ├── entryability/          # EntryAbility（窗口、主题预读、系统栏）
│       │   ├── pages/                 # A_* 一级页 / B_* 二级页
│       │   ├── components/            # 可复用组件
│       │   ├── viewmodel/             # 每个页面一个 ViewModel（V2 装饰器）
│       │   ├── model/                 # 数据结构与字段契约
│       │   ├── repository/            # 本地持久化（preferences）
│       │   ├── service/
│       │   │   ├── ai/                #   文字识别 / 语音 / 实体抽取（占位）
│       │   │   ├── backend/           #   后端 HTTP 契约与字段映射
│       │   │   ├── cloud/             #   同步编排（唯一能碰云端的地方）
│       │   │   └── system/            #   系统能力（相册选择等）
│       │   └── utils/                 # Theme.ets（色彩与尺寸单一真值源）等
│       └── resources/
├── docs/
│   └── 使用说明.md            # 第一次跑起来、接后端、常见问题
├── tools/
├── build-profile.json5
├── oh-package.json5           # 运行时依赖为空（零三方库）
└── hvigorfile.ts
```

分层约定：`页面 → ViewModel → service → repository`，页面不直接调系统能力；`service/cloud/` 是唯一能碰云端的地方。

---

## 6. 后端对接

应用不内置任何密钥，中继地址在「设置 → 后端服务」里填写与修改。首次使用流程：

1. 填地址 → 点「检查连通」，成功即提示版本信息；
2. 点「获取绑定码」，在机器人侧输入该码完成绑定；
3. 绑定后在「订阅的群」里打开要接收消息的群；
4. 手机按 5 秒周期增量拉取候选，落成本机任务。

需要对接的端点（手机端契约见 `entry/src/main/ets/service/backend/RelayApi.ets`）：
`/health`、`/device/register`、`/bind/code`、`/bind/status`、`/groups`、`/subscribe`、`/unsubscribe`、`/api/relay/candidates`、`/api/relay/messages`、`/feedback`、`/my/data`、`/my/prefs`、`/push/token`。

---

## 7. 隐私边界

这个应用处理的是**别人在群里说的话**，所以边界写死在代码里：

| 规则 | 说明 |
| :-- | :-- |
| 进得来的是文字，上得云的是字段 | 群消息原文只存本机，**永不上云** |
| 出手机的字段白名单 | 仅任务名、截止时间与原文、地点、重复规则、置信度、状态、来源、创建时间 |
| 绝不出手机 | 聊天原文、发送者、群号、消息 id、图片、语音、用户自写的备注 |
| 采集逐项授权、默认关闭 | 只有用户显式打开某群订阅，该群消息才进入解析 |
| 无账号体系 | 无登录、无多设备同步；本机数据即唯一真相 |
| 清除能力 | 「设置 → 清除本机任务」与「我的数据 → 删除」分别清理本机与云端数据 |

---

## 8. 平台限制（影响功能取舍的硬约束）

| 事项 | 结论 |
| :-- | :-- |
| 代理提醒 | 手机端存在管控，单个应用有效提醒数量有限，超额会返回错误码；不可用时需走日历兜底 |
| 图片文字识别 | 不支持模拟器，且模拟器上静态 `import` 会导致闪退 → 必须动态引入；输入须为 `RGBA_8888` 的 PixelMap |
| 实体抽取 | 同样不支持模拟器；单次文本有长度上限；内置实体类型里**没有「事项」这一类**，事项需自建规则 |
| 分享接收 | 文本与图片两种承载形态官方均支持；图片以 `record.uri` 形式传入，不是 PixelMap |
| 无障碍读屏 | 相关接口已废弃，官方明确不再开放 → 本项目未做 |
| 云端中继 | 采用自托管 HTTP 轮询中继，后端仅在内存保留短时间窗口、原文不落盘 |

---

## 9. 致谢与许可

- 本项目为课程实践项目，界面遵循 HarmonyOS Design（M3 风格）规范。
- 代码以 [MIT License](LICENSE) 开源；欢迎 Issue 与 PR。

> 仓库中不包含任何密钥、签名证书或第三方服务凭据；如需接入华为 AppGallery Connect 等云服务，请自行在本地放置配置文件（已在 `.gitignore` 中排除）。
