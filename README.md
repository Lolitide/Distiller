# 知了 · 后端（qqbot-backend）

把 **QQ 群聊**里的通知/待办/活动整理成结构化条目，供「知了」App 拉取。
本仓库分支 `be-demo` 只放**后端**与其交付文档，不含 HarmonyOS 前端工程。

> 后端跑在 PC 上（Windows），机器人进程收群消息 → 内存窗口（30 分钟）→
> 规则 + 本地大模型解析 → 候选流 → App 轮询取回。**聊天正文不落盘。**

---

## 1. 三层分工

| 层 | 位置 | 负责 | 出网 |
| --- | --- | --- | --- |
| **规则层** | `pipeline_proto.py` / `candidate_engine.py` / `card_fields.py` | 噪声过滤、时间归一化、去重、聚类、优先级、重复规则、幂等 ID、游标 | 否 |
| **AI 层** | `llm_parse.py` / `llm_worker.py`（Ollama 本地模型） | 语义判断：分类、标题、摘要、时间/地点**原话**、需带物品 | 否（本机模型） |
| **推送层** | `push_sender.py`（华为 Push Kit） | 新提醒时"叫醒"设备；**只搬运标题/摘要，不产内容** | 是（华为网关） |

模型给的所有「原话类」字段都要过**原文子串校验**（`_despace` 后比对），不是原文里逐字出现的就清空——
实测幻觉率 1.3%，全部被这道闸拦下。

---

## 2. 目录

```
qqbot-backend/
├── server.py               # HTTP 路由（中继 v1/v2 全部接口）+ push_loop / lexicon_loop
├── relay.py                # 设备/绑定/订阅/30 分钟内存窗口/附件过路/RelayStore
├── candidate_engine.py     # 去重 → 聚类 → 候选流（rev_seq + 窗口指纹闸）
├── card_fields.py          # 卡片字段：level/category/channel/due/repeat/certainty/missing
├── pipeline_proto.py       # 规则层：噪声、时间归一化（cn2an）、分句取标题
├── llm_parse.py            # Ollama 调用、prompt 变体、validate 安全闸
├── llm_worker.py           # 消息级解析 worker（线程池 + 缓存）
├── profile_summarize.py    # 用户画像归纳（无状态 + 词表安全闸）
├── group_lexicon.py        # 按群领域词表（只落「词+次数+类别」）
├── push_sender.py          # Push Kit：服务账号 JWT(PS256) → v3/{项目ID}/messages:send
├── office_extract.py       # docx/xlsx/pptx/pdf 文本抽取（pdf 为 pypdf 软依赖）
├── botpy_main.py           # QQ 机器人主进程（qq-botpy）
├── main.py / diag.py / check.py
├── database.py             # 控制台用 SQLite（bot.db，运行期生成）
├── corpus_analysis.py      # 真实语料基线分析（改 classify 前后必跑）
├── eval_llm.py             # 模型评测（eval_set.json）
├── make_labeling_kit.py    # 生成人工标注工具
├── web/index.html          # Web 控制台（单文件）
├── console.bat             # 生产启动（127.0.0.1）
├── console-dev.bat         # 联调启动（0.0.0.0 + 允许注入假消息）
├── test_*.py               # 13 个测试
└── requirements.txt
```

---

## 3. 快速开始

```powershell
cd qqbot-backend
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt

copy .env.example .env      # 填 QQBOT_APP_ID / QQBOT_SECRET / 控制台口令
```

启动（Windows）：

| 脚本 | 用途 |
| --- | --- |
| `console.bat` | 日常：控制台监听 `127.0.0.1` |
| `console-dev.bat` | 联调：监听 `0.0.0.0`（手机连同一 Wi-Fi）+ `QQBOT_DEV_INGEST=1` |

机器人 `botpy_main.py` 是**独立子进程**：在网页点「启动」，或 `POST /api/start`。

> 控制台有 HTTP Basic Auth（`QQBOT_CONSOLE_USER` / `QQBOT_CONSOLE_PASSWORD`），
> 联调模式会把端口暴露到局域网，别在公共网络上开。

### 本地模型（AI 层）

```powershell
ollama pull qwen3.5:9b
ollama serve
```

默认 `qwen3.5:9b`。首次加载约 7GB，预热超时 `WARMUP_TIMEOUT=180s`。
**换模型前必须先跑评测**（§5）。模型不可用时自动降级为规则路径，不会 500。

---

## 4. 测试

```powershell
cd qqbot-backend
.venv\Scripts\python.exe -X utf8 test_pipeline.py
.venv\Scripts\python.exe -X utf8 test_candidates.py
.venv\Scripts\python.exe -X utf8 test_candidates_api.py
.venv\Scripts\python.exe -X utf8 test_parse_api.py
.venv\Scripts\python.exe -X utf8 test_attachment_api.py
.venv\Scripts\python.exe -X utf8 test_message_update_api.py
.venv\Scripts\python.exe -X utf8 test_relay.py
.venv\Scripts\python.exe -X utf8 test_group_lexicon.py
.venv\Scripts\python.exe -X utf8 test_botpy_attachments.py
.venv\Scripts\python.exe -X utf8 test_profile_api.py
.venv\Scripts\python.exe -X utf8 test_push_api.py
.venv\Scripts\python.exe -X utf8 test_parse_degraded.py
.venv\Scripts\python.exe -X utf8 test_auth_codes.py
.venv\Scripts\python.exe -X utf8 test_llm_e2e.py    # 需要本机 Ollama
```

性能与标注相关脚本：

```powershell
.venv\Scripts\python.exe -X utf8 test_burst.py        # 50 条突发：优先级/降级/耗时
.venv\Scripts\python.exe -X utf8 eval_prescreen.py    # 规则预筛 A/B（236 条，会调模型）
```

人工标注（约 40 分钟 / 300 段）：

```powershell
.venv\Scripts\python.exe -X utf8 make_labeling_kit.py --n 300
# 双击 labeling\labeler.html 标注 → 导出 JSON
.venv\Scripts\python.exe -X utf8 eval_labels.py labeling\labels_YYYY-MM-DD.json
```

`eval_labels.py` 输出 precision / recall / F1，并列出误报、漏报与「预筛会跳过的该提醒片段」。

测试会写 `_tmp_test/`（已被 `.gitignore` 忽略）。

---

## 5. 评测与语料基线

```powershell
.venv\Scripts\python.exe -X utf8 corpus_analysis.py        # 语料目录默认 ..\聊天记录
.venv\Scripts\python.exe -X utf8 eval_llm.py qwen3.5:9b    # 不传参数 = 只测当前 MODEL
```

2026-10 在 **29.6 万条真实群聊 / 22 个群**上的基线：

| 指标 | 值 |
| --- | --- |
| 待办 | 2.3% |
| 通知 | 1.0% |
| 出行计划 | 0.1% |
| 系统消息拦下 | 18,137 条 |

评测集 `eval_set.json`（56 条人工设计，六类齐全）。**动 `classify` 前后必须重跑基线**，别只看单测。

### 5.1 性能与调优开关

| 环境变量 | 默认 | 作用 |
| --- | --- | --- |
| `QQBOT_LLM_PRESCREEN` | `1` | 明显闲聊跳过模型（236 条实测：跳过 38%，无误伤可执行项） |
| `QQBOT_LLM_WORKERS` | `1` | 解析工作线程数（Ollama 需 `OLLAMA_NUM_PARALLEL` 才有真并行） |
| `QQBOT_PUSH_COOLDOWN` | `1800` | 同一 (设备, 候选) 的推送冷却秒数；`0` 关闭 |
| `QQBOT_FEEDBACK_RANK` | `1` | 用 accept/dismiss 计数微调 priority、压掉反复被忽略的类型 |

运行指标见 `/health` 的 `llm` / `push` 块（队列深度、调用数、降级数、最近耗时、推送成败）。


> 真实语料抽样集 `eval_set_real.json`（180 条）**不入库**：它含聊天原文。
> 需要时在本地用生成脚本重建，`eval_llm.py` 会自动把它拼进评测集。

---

## 6. 推送（可选）

不配也能跑，只是 App 在后台收不到提醒（退回前台轮询）。

```powershell
$env:QQBOT_PUSH_SA = ".\service_account.json"
$env:QQBOT_PUSH_PROJECT_ID = "<AGC 项目 ID>"
```

- `service_account.json` 是**项目级**服务账号凭证，**绝不入库**（已在 `.gitignore`）。
- URL 必须 `v3/{项目ID}/messages:send`（不是 APPID），`target.token` 必须是数组，
  `notification.category` 必填（默认 `WORK`）。
- AGC 侧需：推送服务 + 精准推送能力 + 自分类权益；否则返回 `80300002`。
- 想"只通知不带内容"：`QQBOT_PUSH_INCLUDE_TEXT=0`。

---

## 7. 隐私红线（改代码前先读）

1. **群消息正文只存内存 30 分钟**，不落盘、不进日志；候选同样不落盘。
2. 允许落盘的非路由数据**只有三类**：
   - 按群领域词表 `group_lexicon.json`：**只有「词 + 次数 + 类别」**，无正文；
   - 设备/绑定/订阅/推送 Token（`relay_store.json`）：`DELETE /my/data` 一键清除；
   - 端侧画像（不在本仓库，只在本机 `preferences`）。
3. `/parse` 与 `/profile` 是**无状态**的：只处理、不存储、不进窗口、不进候选流。
4. `/attachment` 的附件字节 90 秒短缓存，不落盘。
5. 唯一"内容交给第三方"的地方是 **Push 的 title/body**（经华为网关），可用开关关掉。
6. 候选反馈计数（accept/dismiss）**只在内存**里，不落盘、不存正文；`DELETE /my/data` 时随进程退出即清。

逐字段清单见 `机器人通道_交付文档/06_后端能力与AI-Kit分工.md` §6。

**本仓库不含**：`.env`、`.relay_key`、`service_account.json`、`relay_store.json`、
`group_lexicon.json`、`bot.db`、聊天记录、真实语料评测集。

---

## 8. 依赖与出处

| 依赖 | 用途 | 许可证 |
| --- | --- | --- |
| `qq-botpy-v2` / `qqbot-agent-sdk` | QQ 机器人 | 见 PyPI |
| `cn2an` | 中文数字 → 阿拉伯数字（缺失时回退内置实现） | MIT |
| `pypdf` | PDF 文本抽取（软依赖，缺失时该分支 501） | MIT |
| `cryptography` | Push Kit JWT（PS256）签名 | Apache-2.0 OR BSD-3-Clause |
| `httpx` / `aiohttp` / `aiosqlite` / `python-dotenv` | HTTP / 异步 / SQLite / .env | 各自见 PyPI |

模型：默认 `qwen3.5:9b`，许可证 **Apache-2.0**（本机 `ollama show qwen3.5:9b --license` 实测）。
完整清单见 [THIRD_PARTY_NOTICES.md](qqbot-backend/THIRD_PARTY_NOTICES.md)。App 在「设置 → 关于」
标注「摘要与分类由我们服务器上的 Qwen 模型生成（Apache-2.0）」。

---

## 9. 文档

| 文件 | 内容 |
| --- | --- |
| `AGENTS.md` | 协作与工作规约（取证纪律、测试要求、隐私红线、模型评测方法） |
| `机器人通道_交付文档/00_给AI的说明_先读这个.md` | 从哪读起、边界在哪 |
| `机器人通道_交付文档/05_API接口文档.md` | **接口契约**（v1 + v2 全部端点） |
| `机器人通道_交付文档/06_后端能力与AI-Kit分工.md` | 后端能力三档 + **逐字段隐私清单** |
| `机器人通道_交付文档/07_前后端对接方案.md` | 字段映射、接口落位、Push 后台送达 |
| `机器人通道_交付文档/01..04` | 开发指南 / v1 速查 / 类型定义 / v2 草案（历史） |

---

## 10. 已知短板

- 消息回执未实现（需公网 HTTPS 回调）。
- 群文件不参与 AI（只读消息正文；手动添加的文件才会抽取文本）。
- 解析是单线程队列：模型约 3s/条，短时涌入 50 条会排队。
- 画像只展示，**不参与**候选排序（首版刻意）。
- 前端 App 不在本分支。
