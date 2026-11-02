# 06 · Task 契约 ↔ API 接口冲突清单（待议）

> **用途**：2026-10-15 讨论用。汇总 App 本地 `Task` 契约（`entry/src/main/ets/model/Models.ets`）与后端接口文档
> `05_API接口文档.md`（＋同目录 `知了设计UI/` 8 张设计稿）之间的口径分叉。
> **「结论」栏已由后端侧回填（2026-10-15）**：逐条裁定 + 终版 Task 模型 + 转换映射 + 联调步骤，
> 全文见同目录 **`07_前后端对接方案.md`**；会上按 07 过一遍即可，有异议改 07。
>
> **这不是「谁写错了」**：两份文档各自演进，`Task` 契约的枚举抄自 `docs/开发指南.md` §9.2/§9.3，
> 而 API 文档是后端契约的口径 —— 分叉是必然的，现在收口代价最小。
>
> **权威性判断**：`05_API接口文档.md` 明写「候选流是**任务列表的唯一数据源**」，所以**字段取值以它为准**；
> `Task` 是本地落库/展示模型，可以带它没有的字段（如 `repeat` / `estimatedHours`）。

---

## 0. 两份口径的原样摘录

### A. 本地 `Task` 契约（当前代码，15 个字段）

| 字段 | 类型 | 必填 | 说明 / 对应 `开发指南` §9.2 列 |
| --- | --- | --- | --- |
| `id` | number | 必填 | 非用户填；§9.2 `id`（AUTOINCREMENT 主键） |
| `status` | `TaskStatus` | 必填 | 非用户填；§9.2 `status`（NOT NULL） |
| `title` | string | **必填** | §9.2 `title` |
| `steps` | `TaskStep[]` | 可选 | §9.2 无此列 |
| `dueAt` | number(ms) | 可选 | 到期；§9.2 `due_at` |
| `remindAt` | number(ms) | 可选 | 提醒；§9.2 `remind_at` |
| `reminderId` | number | 可选 | 已发布的本地提醒键；§9.2 `reminder_id`。右侧「响铃提醒」开关由它派生 |
| `repeat` | `TaskRepeat` | 可选 | §9.2 `repeat` |
| `repeatText` | string | 可选 | 「自定义」重复时自填 |
| `estimatedHours` | number | 可选 | §9.2 无此列 |
| `priority` | `TaskPriority` | **必填** | 紧急程度；§9.2 `priority` |
| `source` | string | 可选 | **来源通道**（QQ/微信/自定义）；§9.2 `source` |
| `category` | string | 可选 | 作业/考试/自定义；§9.2 无此列 |
| `tags` | string[] | 可选 | §9.2 无此列 |
| `detail` | string | 可选 | 备注；§9.2 `detail` |

当前枚举取值：
- `TaskStatus`：`PENDING_CONFIRM`(0) 待确认 / `CONFIRMED`(1) 已确认 / `IN_PROGRESS`(2) 进行中 / `COMPLETED`(3) 已完成 / `EXPIRED`(4) 已过期（只有系统能写）/ `DELETED`(5) 已删除
- `TaskPriority`：`NORMAL`(0) / `IMPORTANT`(1) / `URGENT`(2)
- `TaskRepeat`：`NONE` / `DAILY` / `WEEKLY` / `MONTHLY` / `CUSTOM`
- `TaskStep`：`{ content: string }`

### B. API 侧的 `Candidate`（§2.1，`GET /api/relay/candidates` 返回数组的元素）

`candidate_id`(幂等 ID) · `rev_seq` · `thread_id` · `kind`(待办/通知/活动/出行计划/闲聊/忽略) ·
`priority`(urgent/high/normal/later) · `title` · `summary`(综合总结 ≤120 字) · `time_text` ·
`time_normalized` · `time_unresolved` · `place` · `who` · `deadline` · `items[]` · `steps[]` ·
`tags[]` · `confidence`(0~1) · `engine`(llm/rules) · `source{group_openid, group_label, senders[], msg_ids[], count, first_ts, last_ts}` · `created_at`

另：§1.8 的消息 `parse` 结构里有 `kind` **和** `category` 两个字段。

---

## 1. 冲突清单（7 条）

### C1 ⭐ `priority` 的值域和类型都对不上

| 项 | 内容 |
| --- | --- |
| **API 口径** | `urgent` / `high` / `normal` / `later` —— **4 档、字符串**（§2.1） |
| **契约口径** | `NORMAL`(0) / `IMPORTANT`(1) / `URGENT`(2) —— **3 档、数字**（抄自 `开发指南` §9.2 的列注释） |
| **佐证** | API 文档 §4 的筛选口径正是 `priority=='urgent'`（紧急）/ `priority=='later'`（暂缓）→ 这两档 API 认，我们的枚举里没有 |
| **影响** | 紧急程度是确认页的必填项、任务列表筛选器要用、配色可能要按档位区分；改晚了 → 落库数据 + 全部筛选逻辑重做 |
| **选项** | ① 全面改用 API 的 4 档（字符串枚举），`§9.2` 的列注释同步改；② 保留 3 档，把 `later` 折进 `NORMAL`（丢信息）；③ 做映射表（两套并存，最难看） |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）：采选项①** —— 全面改用 API 4 档字符串 `urgent/high/normal/later`，`§9.2` 列注释同步改。终版定义见 `07_前后端对接方案.md` §1 C1 / §4.2 |

### C2 ⭐ 状态模型：`done` 布尔 vs 六态状态机

| 项 | 内容 |
| --- | --- |
| **API 口径** | §4 筛选写的是 `done==false` / `done==true`（**布尔**） |
| **契约口径** | `TaskStatus` **6 态**（待确认/已确认/进行中/已完成/已过期/已删除，抄自 `开发指南` §9.3，且声明「已过期只有系统能写」） |
| **影响** | 决定「任务列表怎么筛、卡片怎么灰、组头怎么计数（未完成 x 项 / 共 y 项）」这一整条；也决定本地表结构 |
| **选项** | ① 本地保留 6 态，`done = (status === COMPLETED)`，API 侧不参与（推荐，因为「已过期/已删除/待确认」业务上确实要）；② 全面退回 `done` 布尔；③ 定一套新状态机并同时改 `开发指南` §9.3 |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）：采选项①** —— 本地保留 6 态，`done` 为派生值不落库；初始态规则：候选 `confidence<0.6`→`PENDING_CONFIRM`，手动添加→`CONFIRMED`。见 `07` §1 C2 |

### C3 ⭐ `source` 同名不同义

| 项 | 内容 |
| --- | --- |
| **API 口径** | `source` 是**溯源对象**：`{group_openid, group_label, senders[], msg_ids[], count, first_ts, last_ts}` |
| **契约口径** | `source` 是**来源通道字符串**（QQ / 微信 / 自定义），对应 `开发指南` §9.2 的「来源通道」 |
| **影响** | 两个字段同名，序列化/反序列化时极易互相覆盖；「查看原话」等功能依赖溯源对象 |
| **选项** | ① 契约的通道字段改名（如 `sourceChannel`），`source` 让给溯源对象；② 溯源对象改名（如 `origin`），契约保持；③ 溯源只存在候选侧、转 Task 时丢弃（则「查看原话」只能靠候选缓存） |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）：采选项①** —— 通道字段改名 `sourceKind`（`'qq'|'manual_text'|'manual_image'|'manual_voice'`，与契约草案 §5.3 一致）；溯源不整对象搬，拆四个扁平字段进 Task（见 C4）。见 `07` §1 C3 |

### C4 ⭐ 缺 `candidate_id` 与 `msg_ids` → 两件事现在做不了

| 项 | 内容 |
| --- | --- |
| **API 依赖** | `POST /feedback` 请求体要 `candidate_id`（§2.3）；任务详情「查看原话」要按 `sourceMsgIds` 回溯（§1.8 / §4），值来自候选的 `source.msg_ids` |
| **契约现状** | 15 个字段里**没有地方存**这两个 |
| **影响** | ①「候选 → 本地 Task」转完之后，**反馈回传做不了**；②**「查看原话」做不了**（这是设计稿 `任务详情.svg` 的明确功能） |
| **选项** | ① 加 `candidateId: string` + `sourceMsgIds: string[]` 两个字段（本地存、不上云）；② 另建一张「候选溯源」表以 `task_id` 关联；③ 放弃这两个功能 |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）：采选项①（扩为四字段）** —— `sourceCandidateId`/`sourceMsgIds`/`sourceGroupOpenid`/`sourceGroupLabel`（后两个是「查看原话」和卡片「来源于 XX」要用的）。`m_` 临时候选 id 也照存（feedback 只计数）。见 `07` §1 C4 |

### C5 缺 `kind` / `who`，`place` 也没落

| 项 | 内容 |
| --- | --- |
| **API 口径** | 候选有 `kind`（待办/通知/活动/出行计划/闲聊/忽略）、`who`、`place` |
| **契约口径** | 只有 `category`（作业/考试/自定义）；`开发指南` §9.2 有 `location` 但**没进契约** |
| **注意** | **`kind` 和 `category` 是两个概念**（`parse` 里两者同时出现），别合并 |
| **影响** | 候选转 Task 时 `kind` 无处存放（判决「闲聊/忽略」不转任务时可能就不需要）；`who`/`place` 影响详情页展示 |
| **选项** | ① 加 `kind`；② `place` 落进 `location`；③ `who` 要不要加 |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）** —— `kind` **不进 Task**：它是转换闸信号（闲聊/忽略不给转任务入口），不是任务属性；`place` → 新增 `location` 字段（`§9.2` 本有此列）；`who` 不单独建字段，追加进 `note`。见 `07` §1 C5 |

### C6 `time_normalized` 与 `deadline` 是两个字段，我们只有一个坑

| 项 | 内容 |
| --- | --- |
| **API 口径** | 候选同时给 `time_text`（原文「后天」）+ `time_normalized`（事件时间 `2026-10-15`）+ `deadline`（截止）三个 |
| **契约口径** | 只有 `dueAt`(到期) 与 `remindAt`(提醒) |
| **影响** | 转换时 `deadline` 大概能进 `dueAt`，但 `time_normalized`（「这件事什么时候发生」）**没有地方放** —— 而它恰恰是分组要用的时间之一 |
| **选项** | ① 加 `eventAt`（事件时间）字段；② 用 `dueAt` 兼收（语义会糊）；③ 只留原文 `time_text` 给详情页展示 |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）：采选项②** —— `dueAt` 兼收：`deadline` 优先，其次 `time_normalized`；落选者与 `time_text` 原话进 `note`；`time_unresolved` → `dueAt` 留空让用户填。MVP 不加 `eventAt`。见 `07` §1 C6 |

### C7 候选有、契约没有的其它字段

| 字段 | API 含义 | 要不要进契约 |
| --- | --- | --- |
| `summary` | 综合总结 ≤120 字 | **与契约的 `detail`（备注）不是一回事**，是否要一个独立字段 |
| `items[]` | 与 `steps[]` 并列的条目 | 是否与 `steps` 合并 |
| `confidence` | 0~1 置信度 | `§9.2` 是持久化列；详情页要不要展示 |
| `engine` | llm / rules | 同上 |
| `thread_id` | 族（多消息聚类）ID | 关系到「一个候选来自多条消息」的去重 |
| `rev_seq` | 候选修订序号（游标） | upsert 用，本地要不要留 |
| **结论（会上填）** | ✅ **已裁定（2026-10-15）** —— `summary`/`items[]` 并进 `note`（`detail` 改名 `note`，items 追加「需带：」）；`confidence`/`engine` **不进 Task**（详情页角标从候选缓存按 `sourceCandidateId` 反查）；`thread_id`/`rev_seq` **不进 Task**（活在候选 upsert 缓存层）。见 `07` §1 C7 | |

---

## 2. 不算冲突，但转换层必须写死约定（2 条）

### N1 时间格式
- API 通用约定：`YYYY-MM-DD HH:mm:ss`（**字符串**）
- 契约：**毫秒时间戳**
- → repository 层必须做双向往返转换（时区/本地化最容易错，单独写测试）
- ✅ **已裁定**：repository 一层集中转换；API 纯日期 `"YYYY-MM-DD"` → 当地 00:00 的 ms；往返一致性单测必写。见 `07` §2 N1

### N2 分组「待定」的措辞
- API 文档 §4：「都空 → **待定**」
- 目前实现的分组标题用的是「**未安排日期**」
- → 统一成一个词（这条随时可改，不影响结构）
- ✅ **已裁定**：统一「待定」，现有文案改掉。见 `07` §2 N2

---

## 3. 已经一致、不用议（3 条）

1. **分组口径完全一致**：API §4「按生效时间（`dueAt` 优先，其次 `remindAt`，都空 → 待定）」＝ 已实现的分组规则
2. **`title` / `tags` / `steps` 三个字段两端同名同义**
3. **候选不提供 `repeat` / `estimatedHours`**（`category` 只在 `parse` 里出现）→ 说明这几项**由用户在确认页自己填**，与「候选 → 确认页 → 本地 Task」的流程一致

---

## 4. 要一并确认的前置问题

| # | 问题 | 说明 |
| --- | --- | --- |
| P1 | **`/candidates` 后端未实现** | ✅ **已实现（2026-10-15 前）**：去重/聚类/`rev_seq` 游标/upsert 全有，`test_candidates_api.py` 覆盖。**不用 mock，直接联调**（步骤见 `07` §7） |
| P2 | **`/health` 的 `capabilities` 未实现** | ✅ **已实现**：`api_version:2`；`capabilities` 恒含 `candidates/parse/feedback`，模型在线追加 `ocr`。降级分支可真跑 |
| P3 | **契约若改，`开发指南` §9.2/§9.3 要同步** | 需同步条目清单已列：`priority` 4 档字符串、`status` 6 态+派生 `done`、`repeat`→`repeatRule`、`estimatedHours`→`estimateMinutes`、`detail`→`note`、补 `location`/溯源四字段。归属谢忠宇，清单见 `07` §6 |
| P4 | **本地 `Task` 的归属** | `Models.ets` 归谢忠宇（袁正锟草稿）。`07` §4.2 给出终版 ArkTS 定义可直接替换，合入前需谢忠宇过目 |

---

## 5. 影响面速查（改哪个冲突会动到哪些地方）

| 冲突 | 会动到 |
| --- | --- |
| C1 `priority` | `model/Models.ets`、`mock/MockTasks.ets`、任务列表筛选、任务卡片配色、`开发指南` §9.2 |
| C2 状态模型 | `model/Models.ets`、`viewmodel/TaskListViewModel.ets`（分组/计数）、任务卡片完成态、筛选、`开发指南` §9.3 |
| C3 `source` | `model/Models.ets`、`mock/MockTasks.ets`、确认页（来源下拉）、任务卡片描述行（「来源于 XX」）、repository |
| C4 溯源 | `model/Models.ets`、repository（本地表）、任务详情「查看原话」、`POST /feedback` |
| C5 `kind`/`place`/`who` | `model/Models.ets`、确认页、任务详情 |
| C6 时间字段 | `model/Models.ets`、`viewmodel/TaskListViewModel.ets`（按天分组）、确认页时间选择 |
| C7 其它 | `model/Models.ets`、repository、任务详情 |

---

*生成：2026-10-14 · 对照版本：`05_API接口文档.md`（325 行）＋ 本地 `Task` 契约（`dee3d96` 时点，15 字段）*
*结论回填：2026-10-15 · 裁定全文见 `07_前后端对接方案.md`（后端 `/parse` 已实现，P1/P2 消除）*
