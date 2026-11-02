# 11 · 工程任务书：自有 QQ Bot 接入（BYOB）

> 交给写工程的 AI 执行。\*\*先读 §0 的凭据填写区，再按 §2 → §3 顺序做。\*\*
> 写作日期：2026-10-28
> 适用仓库：`qqbot-backend/`（Python 3.14 venv，Windows 本机）
> 关联文档：\[08\_后端公网部署方案](08\_后端公网部署方案.md)、\[09\_备案办理指南](09\_备案办理指南.md)、\[10\_主体资质与法律风险](10\_主体资质与法律风险.md)

\---

## 0\. 凭据填写区（**由人填写，AI 不要猜、不要改格式**）

```ini
# 复制到 qqbot-backend/.env（该文件已被 .gitignore 排除，不要提交）
QQBOT\_APP\_ID=<<由人填写>>
QQBOT\_SECRET=<<由人填写；只放 .env，不写文档>>
```

补充信息（同样由人填写）：

```ini
BOT\_NICKNAME=知了测试bot
BOT\_CREATED\_BY=3841
```

> ⚠️ \*\*硬性要求\*\*
> 1. AppSecret \*\*只允许\*\*出现在本地 `.env`（或环境变量）里，\*\*不得写进任何 `.py`、测试、文档、日志\*\*。
> 2. 不得把 `.env`、`.env.bak\*`、`\_tmp\_test/` 提交到 git。
> 3. 没有填写凭据时，\*\*不要伪造\*\*、不要用旧 bot 的凭据冒充，直接停下来向人确认。

\---

## 1\. 背景（AI 需要知道的最小上下文）

### 1.1 项目现状

* 应用：**知了**（HarmonyOS 校园信息整理 App），另有 Python 后端。
* 后端关键文件：

  * `server.py`：HTTP 服务（控制台口 `8730` + 公开口 `8731`），并负责拉起机器人子进程。
  * `botpy\_main.py`：机器人进程，连 QQ 网关，收到群/单聊事件后交给 `relay.ingest\_group\_message()`。
  * `relay.py`：**30 分钟内存消息窗口** + 订阅过滤 + 设备/绑定表（`relay\_store.json`）+ 群名词表。
  * `llm\_parse.py` / `llm\_worker.py`：调本机 Ollama（`127.0.0.1:11434`，默认 `qwen3.5:9b`）做受约束 JSON 抽取；不可用时走规则降级。
  * `push\_sender.py`：华为 Push Kit 发送。
* 当前是**单租户**：`botpy\_main.py` 只读 `.env` 里的一组 `QQBOT\_APP\_ID/QQBOT\_SECRET`。

### 1.2 为什么做 BYOB

QQ 平台规则（官方 FAQ 原文）：

> 企业主体公开使用已开放，\*\*个人主体暂不支持公开使用\*\*。个人主体的机器人如需添加群聊，机器人创建者可直接添加\*\*自己是群主/管理员\*\*的群聊；私聊仅可添加「开发体验用户号码」。

腾讯官方另有一条明确支持的路径——**Agent 接入**：用户自己创建 bot，把 bot 接入第三方服务（OpenClaw / Hermes / Workbuddy 等）。官方还提供了扫码拿凭据的 SDK：`@tencent-connect/qqbot-connector`（扫码后返回 `{appId, appSecret}`）。

因此本任务的目标是：**让"用户自己的 bot"能接入我们的后端**，从而绕开"我们必须有企业/个体户主体"的死结。

### 1.3 本任务的边界

|阶段|做什么|改代码吗|
|-|-|-|
|**Stage 1**|用新 bot 的凭据跑通现有链路（私聊、群 @ 入库）|**不改**，只配环境变量|
|**Stage 2（已实装）**|单设备单 Bot：App 填 AppID/AppSecret；后端加密存储 + 租户子进程；私聊直投转发队列；解绑停止|已改|
|**Stage 3（暂缓）**|多 Bot、官方扫码 SDK、群自动采集、崩溃自愈|未做|

> **2026-11-01 实测（新建 bot「白名单测试」）**：新 bot 的 **IP 白名单默认为空**，服务器用自己的 IP 可以直接登录，**不需要用户加白名单**。只有**用户自己设置过 IP 白名单**的 bot，才需要把服务器 IP（如 `152.136.104.21`）加进去；否则会报 `401 / 11298 接口访问源IP不在白名单`。绑定引导按这个写，别让用户以为人人必须加。

\---

## 2\. Stage 1：用新 bot 跑通（0 行代码改动）

### 2.1 环境变量（每条命令都在**同一个 PowerShell 窗口**里执行）

```powershell
cd C:\\Users\\91224\\Desktop\\cicad\_panel\\qqbot-backend

# 备份现有凭据，避免把生产 bot 弄丢
copy .env .env.bak-$(Get-Date -Format yyyyMMdd-HHmm)

# 用隔离的数据与端口，绝不污染生产数据
$env:QQBOT\_RELAY\_STORE  = "C:\\Users\\91224\\Desktop\\cicad\_panel\\qqbot-backend\\\_tmp\_test\\tenant-test.json"
$env:QQBOT\_GROUP\_NAMES  = "C:\\Users\\91224\\Desktop\\cicad\_panel\\qqbot-backend\\\_tmp\_test\\names-test.json"
$env:QQBOT\_CONSOLE\_PORT = "8740"
$env:QQBOT\_PUBLIC\_PORT  = "8741"
$env:QQBOT\_DEV\_INGEST   = "1"
$env:QQBOT\_AUTOSTART\_BOT = "1"
$env:QQBOT\_GROUP\_COLLECT = "1"   # Stage 1 要验证群消息；正式默认 0
```

> 2026-10-28 实测补充：`server.py` 默认**不会**自动拉起 `botpy_main.py`，必须加 `QQBOT_AUTOSTART_BOT=1`，否则只会看到控制台就绪、没有 bot 上线日志。

> 说明：`QQBOT\_RELAY\_STORE` / `QQBOT\_GROUP\_NAMES` 指向 `\_tmp\_test/`，测试期间产生的订阅表与群名缓存不会覆盖生产的 `relay\_store.json`、`group\_names.json`。
> \*\*`bot.db` 路径不可配置\*\*（`server.py` 里写死 `BASE\_DIR/bot.db`），Stage 1 允许共用；测试消息会追加进去，属可接受污染，\*\*不要删表\*\*。

### 2.2 改 `.env`

只改前两行（其余保持原样）：

```ini
QQBOT\_APP\_ID=<<填好的 AppID>>
QQBOT\_SECRET=<<填好的 AppSecret>>
```

### 2.3 启动

```powershell
.\\.venv\\Scripts\\python.exe -X utf8 server.py
```

**必须看到的日志（缺一不可）**：

```
使用 AppID: <填好的 AppID>          # 启动早期打印，确认用的是新 bot
机器人「<BOT\_NICKNAME>」启动成功！
收到网关事件: ready
[控制台] 已启动，PID=...
```

`机器人「...」启动成功！` 里的昵称应与 `BOT_NICKNAME` 一致；后面 `已上线！(id=...)` 的 `id` 是 bot 的 uin，**不是 AppID**，不要拿它和 AppID 对等。确认真实 AppID 看 `使用 AppID: ...` 这一行。

### 2.4 验收项（逐条打勾，每项留证据）

> ⚠️ 下表第 **3–5** 项**只在 `QQBOT_GROUP_COLLECT=1` 时成立**（§2.1 已把它临时设为 1）。
> **正式生产默认是 `0`（不接收群消息）**，不要照这张表去配生产环境。

|#|操作|预期|证据|
|-|-|-|-|
|1|启动|出现 `ready`，昵称/AppID 匹配|日志截图|
|2|管理员 QQ 私聊发「你好」|日志 `\[单聊] ...`，机器人回帮助文案|截图|
|3|群主把 bot 拉进群，并开「获取群内全部消息」+「主动在群聊内发言」|群资料页两项已开启|截图|
|4|群里发普通消息（不 @）|日志 `\[群消息]\[GROUP\_MESSAGE\_CREATE] ...`|日志|
|5|群里 `@bot 你好`|日志 `GROUP\_AT\_MESSAGE\_CREATE` 且消息入库（当前代码不回复群消息）|日志|
|6|重启后端|仍能 `ready`，无需人工干预|日志|
|7|**别人的群**（你不是群主）让群主拉 bot 进群|成功 / 失败，**记录结果**|截图|

> 第 7 项是本次实验的核心：它决定"覆盖范围能否超出自己管理的群"。\*\*结论必须如实记录，不许推测。\*\*

#### 2.4.1 实测记录（2026-10-28，新 bot `1906107486` / 知了测试bot）

- 启动：✅ `使用 AppID: 1906107486`，`机器人「知了测试bot」启动成功！`
- 私聊：✅ 收到 `c2c_message_create` 与 `[单聊] : 你好`，机器人回复帮助文案
- 自己的群：✅ 收到 `group_add_robot`；`@bot` 收到 `GROUP_AT_MESSAGE_CREATE`，`/api/relay/internal/ingest` 返回 200 并入库
- 群内回复：❌ 当前 `botpy_main.py` 只入库/转中继，不调用 `message.reply`，所以 @ 后没有群回复（不是平台拒绝）
- 全量消息模式：⚠️ 测试机为华为手机，QQ 客户端没有该开关，本项跳过
- **非创建者的群主拉 bot 进群：❌ 添加被拒绝**（未产生 `group_add_robot` 事件）
- 结论：个人主体 bot 的群覆盖仍被限制在「创建者自己是群主/管理员」的群；BYOB 只能做「每个群主/每个用户建自己的 bot」，不能用一个 bot 覆盖别人的群。

### 2.5 回滚

```powershell
copy .env.bak-<时间戳> .env
Remove-Item -Recurse -Force \_tmp\_test -ErrorAction SilentlyContinue
```

\---

## 3\. Stage 2：多租户改造（实现任务）

> 前置：Stage 1 的 1–7 项全部通过，且人确认要继续。
>
> **2026-10-28 实测后：第 7 项不通过。Stage 2 只能在「群主/用户自建 bot」模型下继续，不能指望单个 bot 覆盖别人的群；是否投入必须由人重新确认。**
>
> **2026-10-28 人决定：暂不做自动群采集；但先实装「单设备单 Bot + 私聊转发」的最小 BYOB，保证用户绑定后能通过转发收消息。**

### 3.0 已实装的最小版本（2026-10-28）

- App「设置 → 绑定 QQ」改为：复制创建链接到 QQ 内打开 → 输入 AppID / AppSecret → 绑定。
- 新增 `POST /api/relay/tenant/register`：按设备保存 AppID + AES-256-GCM 加密的 AppSecret，并拉起一个 `botpy_main.py` 子进程。
- 新增 `POST /api/relay/tenant/unbind`、`GET /api/relay/tenant/status`。
- `botpy_main.py` 识别 `QQBOT_TENANT_DEVICE_ID`：该 Bot 的私聊文本直接投递到绑定设备的转发队列，不再走配对码。
- **合并转发**：`message_type=101/102` 时优先解析 `content` 里的 `=== 消息 N === / [消息内容] / [发送者]`（部分手机 QQ 的格式），并兼容官方 `msg_elements` 递归结构；每条内层消息单独入队（图片单独入队）。引用消息 `103` 只取当前正文。App 会收到多条待确认，当前不做同类合并/跨消息上下文。
- 主密钥：`QQBOT_SECRET_KEY`（base64 32 字节）必须在 `.env` 中配置；缺失时 `tenant/register` 返回 `secret_key_missing`，不写明文。
- 实测：绑定后给 Bot 发「明天下午三点开会」，后端日志出现 `[转发] BYOB device=... queued=1`，App 进入待确认；重启后端后租户 Bot 自动重新上线。
- 当前限制：一个设备一个 Bot；**自动群采集默认关闭（`QQBOT_GROUP_COLLECT=0`）**，不接收/不落库群消息、不做上下文/聚类；只处理用户私聊转发；多 Bot/扫码绑定仍未做；**私聊未校验发送者是否为 Bot 主人**，任何人给该 Bot 发消息都会进入 owner 设备的转发队列（后续可加一次性 owner 校验码）。


### 3.1 数据模型（已实装）

新增 `tenants.json`（路径可用 `QQBOT\_TENANTS` 覆盖，默认 `qqbot-backend/tenants.json`；该目录整体已被 `.gitignore` 排除）：

```json
{
  "version": 1,
  "tenants": {
    "<device_id>": {
      "app_id": "1906107486",
      "app_secret_enc": "<AES-GCM 密文>",
      "bot_nickname": "",
      "created_at": "2026-10-28 22:37:19",
      "status": "active"
    }
  }
}
```

**当前隔离口径**：

* 以 **`device_id`** 为租户键（一个设备一个 Bot），不是以 `app_id` 为键；同一 AppID 默认不允许绑到另一设备。
* **卸载重装**：新设备提交 **同一 AppID + 同一 AppSecret** 时，服务端停旧 runner、删旧租户/绑定，把 Bot 转移到新 `device_id`；Secret 被重置过则仍报 `bot_already_bound`。
* 私聊转发按 `device_id` 直投 `relay._FORWARDS`，不依赖 QQ `openid`。
* `relay_store.json` 的 `bindings[device_id]` 写 `source=byob`、`app_id=...`、`user_openid=""`。
* 旧单租户模式（`.env` 里的 `QQBOT_APP_ID/SECRET`）仍保留；`QQBOT_MULTI_TENANT` 开关**没有实装**，当前是「旧单租户 + BYOB 租户并存」。

### 3.2 密钥安全（这是本任务的安全红线）

1. **加密存储**：AES-256-GCM；主密钥来自环境变量 `QQBOT_SECRET_KEY`（32 字节，base64）。**主密钥缺失时拒绝保存新 tenant**（fail closed），不得降级为明文。
2. **日志脱敏**：任何日志、异常、HTTP 响应里**不得出现 AppSecret**；错误统一返回「凭据无效」，不回显原值。
3. **最小暴露**：解密只发生在启动/重连该 bot 的那一刻，不放进全局缓存供其他模块读取。
4. **解绑即删**：删除 tenant 时停止子进程并删除 `tenants.json` 记录；按平台运营规范，终止后 **24 小时内**清理该 bot 的数据。

### 3.3 绑定方式（当前：手工填 AppID/AppSecret）

**已实装**：App 复制 `https://q.qq.com/qqbot/openclaw/login.html` 到 QQ 内打开（浏览器直接打开会跳转失败），创建 Bot 后在机器人管理端复制 AppID/AppSecret，填进 App；后端 `POST /api/relay/tenant/register` 加密保存并拉起 runner。

**未实装（后续可选）**：官方 `@tencent-connect/qqbot-connector` 扫码绑定（Node sidecar）。不要用 Python 逆向扫码协议。原计划的接口保留为设计参考：

|方法|路径|说明|
|-|-|-|
|POST|`/api/relay/tenant/qr/start`|返回 `{session\_id, qr\_url, expires\_in}`（未实装）|
|GET|`/api/relay/tenant/qr/status?session=`|`pending` / `success` / `expired`（未实装）|
|GET|`/api/relay/tenant/status`|当前设备租户状态（已实装）|
|POST|`/api/relay/tenant/unbind`|解绑并清数据（已实装）|

### 3.4 Bot runner 池（当前：每设备一个子进程）

* 每个 tenant 一个独立的 `botpy_main.py` 子进程；`tenant_manager.py` 负责启动/停止/读取日志/10 秒内判断是否上线。
* 上限：`QQBOT_MAX_TENANTS`（默认 20）；每 tenant 窗口条数沿用 `relay.WINDOW_MAX`。
* **串行保护**：同一 `device_id` 重新绑定时先停旧进程；同一 `app_id` 不允许起两个 runner。
* 进程崩溃/重启：服务器重启后 `start_all()` 会重新拉起 `tenants.json` 里的租户；单进程异常退出目前不自动重启（后续可补）。

### 3.5 配置

```ini
QQBOT_SECRET_KEY=      # base64(32B)，BYOB 必填；缺失时拒绝绑定
QQBOT_MAX_TENANTS=20   # 租户上限
QQBOT_TENANTS=         # 可选，tenants.json 路径
QQBOT_GROUP_COLLECT=0  # 0=自动群采集关闭（默认）；1=恢复群消息入库/窗口
```

> 旧 `QQBOT_MULTI_TENANT=0/1` 设计未采用：没有它，旧单租户行为也完全不受影响。

\---

## 4\. 验收标准（必须全部可复现）

### 4.1 Stage 1

* §2.4 的 1–7 项全部有证据；第 7 项结论明确。

### 4.2 Stage 2

|#|验收点|
|-|-|
|1|同一设备重复绑定会先停旧 runner；同一 AppID 不会同时起两个进程|
|2|任一租户 Bot 重启/掉线，不影响其他租户与旧单租户 Bot|
|3|`grep` 全部日志与 `tenants.json`，**无明文 AppSecret**（密文可见）|
|4|解绑后：tenant 记录消失、子进程停止、旧凭据不能再收消息；`DELETE /my/data` 同样处理|
|5|未配置 `QQBOT_SECRET_KEY` 时，`tenant/register` 返回 `secret_key_missing`，**不写明文**|
|6|服务器重启后，`tenants.json` 里的租户 Bot 自动重新上线|

### 4.3 回归测试（按 AGENTS.md §3 要求，改完必跑）

```powershell
cd qqbot-backend
.venv\\Scripts\\python.exe -X utf8 test\_relay.py
.venv\\Scripts\\python.exe -X utf8 test\_pipeline.py
.venv\\Scripts\\python.exe -X utf8 test\_candidates.py
.venv\\Scripts\\python.exe -X utf8 test\_candidates\_api.py
.venv\\Scripts\\python.exe -X utf8 test\_auth\_codes.py
.venv\\Scripts\\python.exe -X utf8 test\_parse\_api.py
.venv\\Scripts\\python.exe -X utf8 test\_tenants.py
.venv\\Scripts\\python.exe -X utf8 test\_forward\_merge.py
# 需要本机 Ollama 时才跑：
# .venv\\Scripts\\python.exe -X utf8 test\_llm\_e2e.py
```

**任何一项失败，不得声称"已验证"。**

\---

## 5\. 禁止事项（违反任一条即返工）

1. ❌ 把 AppSecret 写进代码、测试、文档、日志、错误信息。
2. ❌ 提交 `.env`、`.env.bak\*`、`tenants.json`、`\_tmp\_test/`。
3. ❌ 逆向/猜测腾讯扫码协议，或用非官方接口拿凭据。
4. ❌ 改动现有 `/api/relay/*` 的既有语义与字段名（前端与文档已冻结；只允许**新增** BYOB 字段/接口）。
5. ❌ 破坏旧单租户模式：`.env` 的 `QQBOT_APP_ID/SECRET` 仍要能独立启动，不能被 BYOB 改造影响。
6. ❌ 为了让测试过而放宽「不猜缺失字段」「正文不落盘」等既有约束。

\---

## 6\. 排错表（对照现象，先查表再改代码）

|现象|最可能原因|处理|
|-|-|-|
|群里普通消息/ @ 完全没有日志|`QQBOT_GROUP_COLLECT=0`（默认，自动群采集关闭）|预期行为；只有需要恢复采集时才设 `1` 并重启|
|反复重连 / 启动即退|AppID/Secret 错、`.env` 未保存、有多余空格/引号|重存 `.env`，重启；核对该 bot 的管理端凭据|
|私聊有 `\[单聊]` 日志但用户收不到回复|超出被动回复窗口（60 分钟 / 5 次）|让用户重新发一条再回|
|群里 @ 提示"服务状态异常"|手机 QQ 版本旧|升级到最新版|
|群里普通消息**完全没有**日志|群资料页未开「获取群内全部消息」|群主设置后再测|
|群里发不出消息|未开「主动在群聊内发言」|群主设置；注意群主动消息 5 分钟 / 5 次限制|
|`401 not authorized`|凭据错（不是模型 key）|重置 AppSecret 后重填|
|新号不能开公开服务|新账号审核中（约 3 天）/ 未做 QQ 钱包实名|等审核、先实名|
|`secret_key_missing`|服务端 `.env` 没配 `QQBOT_SECRET_KEY`|生成 base64(32B) 写入 `.env`，重启|
|`bot_start_failed`|AppID/AppSecret 错，或 10 秒内没上线|核对凭据；看 `botpy.log` 的 `[tenant:...]` 日志|
|`bot_already_bound`|同一个 AppID 已绑到另一台设备，且 AppSecret 不一致|用同一份 Secret 重装会自动转移；重置过 Secret 需先解绑旧设备|
|App 里点绑定一直转圈|`QQBOT_SECRET_KEY` 缺失/后端未重启|看 `/api/relay/health` 与后端日志|

\---

## 7\. 需要人确认后才能继续的决策点

以下几件事**AI 不得自行决定**，遇到必须停下来问人：

1. Stage 1 第 7 项结果：**已实测——非创建者群主添加被拒绝**，决定「单 Bot 覆盖别人的群」不可行；
2. 是否继续多租户：**已决定先做单设备单 Bot 的 BYOB 最小版**，多 Bot/扫码暂缓；
3. 解绑后数据保留策略（平台要求 24h 内删除，但产品可能想留审计日志）；
4. 是否需要向腾讯申请"扫码页展示平台名称"（需邮件 `qq\_bot\_api@tencent.com`）。

\---

## 8\. 参考（官方）

* QQ Bot 常见问题（个人主体不支持公开使用、只能加自己是群主的群、个人不能升级需新邮箱重注册、封禁不解封）：[https://bot.q.qq.com/wiki/bot\_FAQ/](https://bot.q.qq.com/wiki/bot_FAQ/)
* Agent 接入（用户自建 bot 接入第三方服务、群全量消息设置、扫码绑定）：[https://bot.q.qq.com/wiki/agent-qqbot/](https://bot.q.qq.com/wiki/agent-qqbot/)
* 第三方 Agent 接入 SDK：`@tencent-connect/qqbot-connector`（上文 §3.3）
* 运营规范（数据安全、密钥保管、终止后 24h 删除）：[https://bot.q.qq.com/wiki/business/](https://bot.q.qq.com/wiki/business/)
* 开放平台入驻（企业/个体户/个人三类主体）：[https://q.qq.com/wiki/](https://q.qq.com/wiki/)

