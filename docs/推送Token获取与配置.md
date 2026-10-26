# 知了 Push 推送：Token 获取与配置说明

> 给项目所有者（项目所有者）看的操作说明。
> 结论先说：**后端要的不是一段固定的 token，而是一份「服务账号密钥 JSON」文件**；后端用它现场签 JWT。
> 另外还有一个「设备 Push Token」，由 App 自动获取并上报，不需要人工填。

---

## 0. 先分清三种“token”

| 名称 | 谁产生 | 用在哪 | 是否需要人工拿 |
| --- | --- | --- | --- |
| **服务账号密钥 JSON** | AGC / API Console | 后端签 JWT，调用华为 Push 网关 | **需要**（本文重点） |
| **JWT 鉴权令牌** | 后端用上面的私钥现签 | 放在 `Authorization: Bearer ...` | 不需要人工拿，后端自动生成、缓存 1 小时 |
| **设备 Push Token** | 手机端 `pushService.getToken()` | 后端推送时的 `target.token` | 不需要人工填，App 自动上报 |

> 本文说的“找项目所有者要 token”，准确说是要 **服务账号密钥 JSON 文件**（里面含 `private_key`），不是一段 JWT。

---

## 1. 这个文件从哪来（项目所有者操作）

依据：官方《基于服务账号生成鉴权令牌》与《开通推送服务》。

1. 用**项目所有者/管理员**的华为账号登录 AppGallery Connect（AGC），选择「开发与服务」。
2. 找到「知了 / Distiller」所属的**项目**，确认应用包名是 `com.xjtu.distiller`。
3. 左侧「增长 > 推送服务」→「立即开通」。
   - 数据处理位置：手机设备仅支持中国境内，按提示设为**中国**。
   - 若项目已经开通过推送服务，这一步可跳过。
4. **重新申请调试/发布 Profile 并签名**（非常关键）：
   - 推送权益开通后，必须用**重新申请**的 Profile 重新签名；旧签名不会带推送权益。
   - 手动签名：AGC 申请调试证书 → 注册调试设备 → 重新申请调试 Profile → DevEco 手动签名。
   - 自动签名：DevEco 里开通 Push Kit 开放能力后自动重签。
   - 没做这一步，手机会报「推送权益未开通 / 设备不支持推送」。
5. 打开 **API Console**（AGC 项目内的 API 凭证入口），选择该项目 → 创建「**服务账号密钥**」→ 下载 JSON。
   - 官方原文：在华为开发者联盟的 API Console 上选择所在项目，创建“服务账号密钥”凭证，并下载推送服务 API 的服务账号密钥文件。
6. 核对文件里的 `project_id` 与 AGC「项目设置」里的项目 ID 一致。
   - 项目 ID 查看：AGC → 项目列表 → 对应项目 → 左侧「项目设置」。

下载到的文件长这样（已脱敏）：

```json
{
  "project_id": "*****",
  "key_id": "*****",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "sub_account": "*****",
  "auth_uri": "",
  "token_uri": "",
  "auth_provider_cert_uri": "",
  "client_cert_uri": ""
}
```

**只需要这四个字段**：`project_id`、`key_id`、`private_key`、`sub_account`。
`private_key` 是敏感私钥，别发群里、别进 Git。

---

## 2. 拿到后填到哪（部署后端的人操作）

后端代码：`qqbot-backend/push_sender.py`。

推荐用**文件路径**，不要直接把 JSON 贴进代码：

1. 把 JSON 存到服务器上的一个**仓库外**目录，例如：
   `C:\secrets\zhiliao-push-service-account.json`
2. 设置环境变量（启动后端前）：
   ```powershell
   setx QQBOT_PUSH_SA "C:\secrets\zhiliao-push-service-account.json"
   ```
   或在当前 PowerShell 会话里：
   ```powershell
   $env:QQBOT_PUSH_SA = "C:\secrets\zhiliao-push-service-account.json"
   ```
3. 也支持直接给 JSON 字符串（不推荐，容易泄进日志）：
   `QQBOT_PUSH_SA_JSON`
4. 如果文件里没有 `project_id`，可额外设置：
   `QQBOT_PUSH_PROJECT_ID`
5. 重启后端（`server.py` / 控制台）。

后端会做什么：
- 用 `key_id` + `private_key` + `sub_account` 按 **PS256** 签一个 1 小时有效的 JWT；
- 请求头 `Authorization: Bearer <JWT>`；
- 调 `https://push-api.cloud.huawei.com/v3/{project_id}/messages:send`；
- 请求体里 `target.token` 放**设备上报的 Push Token**。

官方依据：Push Kit《基于服务账号生成鉴权令牌》、请求体 `target.token` 说明。

---

## 3. 填完怎么确认（不依赖手机）

1. 重启后端。
2. 访问 `GET /api/relay/health`，`capabilities` 里应出现 `push`。
   - 没有 `push` = 服务账号文件没读到 / `project_id` 缺失。
3. 设备上报后，`POST /api/relay/push/token` 返回：
   ```json
   { "ok": true, "data": { "registered": true, "push_ready": true } }
   ```
   - `push_ready=false` = 服务端还没配好；`true` = 可以下发。
4. App「设置 → 推送通道」显示「已就绪」。
5. 真机联调建议后端发测试消息时带 `testMessage: true`，避免被每日频控。

---

## 4. App 端还需要什么

App 不需要你填任何 token。它会在启动/同步开启时：
1. `pushService.getToken()` 取设备 Push Token；
2. 调 `POST /api/relay/push/token` 上报；
3. 后端保存「设备 → token」，新候选出现时推送。

前提仍然是：
- AGC 已开通「推送服务」；
- 安装包用的是**开通后重新申请的 Profile** 签名；
- 用户允许通知。

常见错误码：
- `1000900012`：推送权益未开通 / 签名没带推送权益；
- `1000900010`：应用身份非法（包名、签名或 AGC 配置不匹配）；
- `1000900014`：设备不支持取 token（模拟器常见）。

---

## 5. 安全与交接

- 服务账号 JSON 只放在后端机器，**不要提交 Git、不要发群**。
- 建议用 1Password/企业微信私聊等安全方式传；传完可删除聊天记录。
- 如果私钥泄露：在 API Console 删除该服务账号密钥，重新创建一份，后端换文件并重启。
- 这份密钥只用于「服务端 → 华为推送网关」鉴权，不包含用户数据，也不能读取群消息。

---

## 6. 给项目所有者的最短话术

> 知了要用华为 Push Kit 发通知。麻烦用项目所有者账号登录 AGC：
> 1）在「增长 > 推送服务」确认已开通；
> 2）用开通后的 Profile 重新签一下 `com.xjtu.distiller`；
> 3）在 API Console 给这个项目创建「服务账号密钥」，下载 JSON；
> 4）把 JSON 私聊发我（含 project_id/key_id/private_key/sub_account）。
> 这不是登录 token，是服务端调华为推送网关用的密钥文件，别发群里。

---

## 7. 出处

- 《基于服务账号生成鉴权令牌》：`开发指南/Push_Kit_推送服务/端云调试/基于服务账号生成鉴权令牌/push-jwt-token`
- 《开通推送服务》：`开发指南/Push_Kit_推送服务/开发准备/开通推送服务/push-config-setting`
- 《使用入门》（完整流程与签名要求）：`开发指南/Push_Kit_推送服务/使用入门/push-gettingstart`
- 后端实现：`qqbot-backend/push_sender.py`、`server.py` 的 `/push/token` 与 `push_loop`
- App 实现：`entry/src/main/ets/service/system/PushTokenService.ets`、`service/cloud/PushRegistrar.ets`
