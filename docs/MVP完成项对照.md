# 知了 MVP 完成项对照

> 基准文档：`C:\Users\91224\Desktop\HM_Cicada\验收表-MVP功能-Lite.md`（62 条未通过项）
> 代码分支：`feature/mvp-completion`（提交 `9e8458f`、`7992f3a`）
> 记录时间：2026-10-25
> 说明：本文只记录**本分支实际完成**的条目；`feature/Gantt` 已回退到 `d463f48`，只保留甘特相关历史。

## 一、总览

本轮按「先闭环 P0，再补 P1 体验」推进，完成两部分：

1. **第一批**：持久化、四档时间线、状态机、提醒/日历/通知、确认闸、反馈、重绑修复。
2. **第二批**：解析失败重试面板、低可信字段高亮、提醒失败提示、通知引导修复、幽灵提醒清理。

### 已关闭（验收项）

| 类别 | 编号 |
| --- | --- |
| 前端 | FE-08、FE-09、FE-15、FE-28、FE-29、FE-30、FE-34、FE-37、FE-39、FE-40、FE-41、FE-47、FE-48、FE-49、FE-51、FE-52、FE-71、FE-75、FE-79 |
| 后端 | BE-05、BE-20、BE-21、BE-28 |
| 缺口 | GAP-01、GAP-02、GAP-03、GAP-04、GAP-05、GAP-07、GAP-08、GAP-09、GAP-10 |

### 部分完成

| 编号 | 已完成部分 | 尚缺 |
| --- | --- | --- |
| FE-35 | 确认前不落库、字段可编辑、低可信高亮、失败重试 | 确认面内不重复展示原文；原文对照在任务详情页（`TaskRawTextCard`） |
| GAP-12 | 反馈回传已接（采纳/忽略） | Push 令牌与下发（FE-76/BE-25/26） |
| GAP-16 | 本文件补充了最新状态 | README、范围冻结等其他文档尚未同步 |

## 二、前端完成明细

### 1. 列表与时间线

| 编号 | 验收项 | 状态 | 实现与证据 |
| --- | --- | --- | --- |
| FE-08 | 组内 priority → level → 时间排序 | ✅ | `TaskListViewModel.compareInGroup()`，组内先按 `priority` 降序，再 `level` 降序，最后时间升序 |
| FE-09 | 今天 / 明天 / 本周 / 更远四档 | ✅ | `TaskListViewModel.groupByBucket()` + `TaskGroupHeader.bucketLabel()`；「未安排」独立置顶 |

### 2. 增删改查与状态

| 编号 | 验收项 | 状态 | 实现与证据 |
| --- | --- | --- | --- |
| FE-15 | 粘贴原文落进 `rawText` | ✅ | `AddTaskTextInput` 写入 `draft.rawText`，`AddTaskDraft.toTask()` 原样落库 |
| FE-28 | 状态流转到「进行中」 | ✅ | 详情页「开始执行」→ `TaskListStore.startTask()` 写 `IN_PROGRESS`；卡片显示「进行中」胶囊 |
| FE-29 | 系统自动标记「已过期」 | ✅ | `TaskListStore.expireOverdue()` 启动与每分钟扫描；改期到未来自动退回 `CONFIRMED` |
| FE-30 | 编辑结果重启后仍在 | ✅ | `TaskRepository` 改 `filesDir/tasks.json`（schema 3）；详情页 `aboutToDisappear → saveNow()` 落盘；真机重装后任务仍在 |

### 3. 解析与 AI 抽取

| 编号 | 验收项 | 状态 | 实现与证据 |
| --- | --- | --- | --- |
| FE-34 | 粘贴群消息得到候选字段 | ✅ | `RelayApi.parseText` + `ManualParseService` + `AddTaskDraft.applyParsed()`：名称/时间/地点/标签自动填表 |
| FE-35 | 确认页：可编辑 + 低可信 + 重试 | 🟡 | 以「添加任务」半模态作确认面，保存前不落库；字段可改；低可信与失败重试见 FE-40/41。原文对照移到详情页 `TaskRawTextCard` |
| FE-37 | 图片文字识别 | ✅ | `OcrService.recognizeUri()` 端侧识别；截图来源点「AI 预填」后进入同一解析确认流程 |
| FE-39 | 原文对照 | ✅ | 详情页新增 `TaskRawTextCard`，展示 `Task.rawText`（最多 5 条群消息拼接） |
| FE-40 | 低可信字段高亮 | ✅ | `AddTaskSheet` 低可信提示；`AddTaskAttributeChips` 到期芯片警示色 +「待核对」；`TaskInfoCard` 地点「待核对」；手动改期后恢复普通样式 |
| FE-41 | 解析失败 / 超时 / 断网可执行提示 | ✅ | `AddTaskSheet.parseErrorCard()` 按 `no_server/network/not_supported/unauthorized/bad_response/bad_json` 分类，提供「重试」「手动填写」 |

### 4. 提醒 / 通知 / 日历

| 编号 | 验收项 | 状态 | 实现与证据 |
| --- | --- | --- | --- |
| FE-47 | 到点真的响 | ✅ | `ReminderService.publish()`（`reminderAgentManager`，日历型提醒）；`module.json5` 声明 `PUBLISH_AGENT_REMINDER`；真机到点验证通过 |
| FE-48 | 完成 / 删除 / 改期撤销提醒 | ✅ | `ReminderCoordinator.reconcile()` 按任务表对账；完成/删除/改期后撤旧发新或直接撤销句柄 |
| FE-49 | 日历兜底 | ✅ | `CalendarService` 创建「知了」账户并写日程（到期时刻为 start，提前量为 reminderTime），完成/删除/过期时删除 |
| FE-51 | 通知被拒后引导设置 | ✅ | `NotificationService.ensureEnabled()` + 启动「去开启」对话框；改用 API 13 `openNotificationSettings`（原 API 26 接口在本机抛 801） |
| FE-52 | 30 条上限与 1700002 提示 | ✅ | `ReminderCoordinator` 捕获 1700002 → 回滚 `alarm`；`TaskListStore` 回调 → toast「提醒数量已达上限…」；启动清理幽灵提醒修复误报 |

### 5. 绑定 / 原文 / 反馈

| 编号 | 验收项 | 状态 | 实现与证据 |
| --- | --- | --- | --- |
| FE-71 | 群消息原文回填 | ✅ | `SyncService` 拉 `/messages` 建索引，按 `source.msg_ids` 拼 `rawText`；详情页可见 |
| FE-75 | 采纳 / 忽略回传 | ✅ | `FeedbackService.send()` 调 `POST /feedback`；详情页「有用 / 忽略」入口 |
| FE-79 | 轮询覆盖本地编辑 | ✅ | `Task.userEdited` + `TaskListStore.mergeIncoming()` 跳过内容字段；改过内容的任务只同步服务端派生字段 |

## 三、后端 / 契约完成明细

| 编号 | 验收项 | 状态 | 实现与证据 |
| --- | --- | --- | --- |
| BE-05 | 身份失效可区分错误码 | ✅ | 后端返回 `unauthorized`；`SyncService` 识别后清身份、停止轮询，并提示重新绑定 |
| BE-20 | `POST /api/relay/parse` 客户端可用 | ✅ | `RelayApi.parseText/parseImage` + `ManualParseService` 已接通 |
| BE-21 | `POST /api/relay/feedback` 有调用点 | ✅ | `FeedbackService` 传 `candidate_id/action/group_openid/kind` |
| BE-28 | 解析降级可识别 | ✅ | 后端 `/parse` 返回 `degraded`；`BackendTypes` 消费，`AddTaskSheet` 显示「规则降级解析」 |

## 四、缺口关闭情况

| 编号 | 状态 | 说明 |
| --- | --- | --- |
| GAP-01 | ✅ | 确认闸：解析只填草稿，点「保存」才落库 |
| GAP-02 | ✅ | 粘贴 → 解析 → 确认 → 任务链路打通 |
| GAP-03 | ✅ | 提醒全链路接通（发布/撤销/上限/权限） |
| GAP-04 | ✅ | 日历账户与日程写入 |
| GAP-05 | ✅ | 文件持久化 + 页面离开落盘 + 轮询脏字段保护 |
| GAP-07 | ✅ | 四档时间线 |
| GAP-08 | ✅ | 组内 priority/level/time 排序 |
| GAP-09 | ✅ | `IN_PROGRESS` 入口与 `EXPIRED` 自动写入 |
| GAP-10 | ✅ | 详情页原文卡 |
| GAP-12 | 🟡 | 反馈已接；Push 未接 |

## 五、尚未完成（后续批次）

| 批次 | 条目 |
| --- | --- |
| 第三批（计划中） | FE-42/43/44（分享接收）、FE-57（云端字段清单 + 同步开关）、FE-59（首次启动引导）、FE-66（绑定轮询超时）、GAP-11/13/15/17 |
| 第四批 | FE-76 / BE-25/26（Push Kit、条件交付）、FE-60（导出）、FE-80（子任务统计口径）、GAP-14（单元测试）、GAP-16（文档同步） |
| 明确不实现 | FE-36（端侧实体抽取）、BE-27（云数据库 BotTask）、FE-56/61/62（解析三档、读屏、通知栏订阅） |

## 六、验证记录

- `arkts_check`：本轮改动文件无 ArkTS 严格模式错误。
- `devecocli build`：BUILD SUCCESSFUL。
- 真机（华为畅享 70X，`com.xjtu.distiller`）：
  - 第一批：新建/编辑/完成/删除、四档分组、板板拖动、重启持久化、绑定与重绑、提醒与日历；
  - 第二批：断网解析失败卡与重试、低可信时间/地点标记、改期后警示消失、提醒上限提示、通知设置跳转。
- 后端：本轮未改后端代码；此前 12 个回归脚本为全绿基线，第三批涉及绑定超时时会重新跑 `test_relay.py` 等。
