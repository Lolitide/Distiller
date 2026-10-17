# 知了 · 机器人通道（鸿蒙 App 端）

克隆代码：git clone -b QQBot-Subcribe-News --single-branch https://github.com/Lolitide/Distiller

本仓库是「知了」HarmonyOS 应用的**机器人通道**部分：订阅 QQ 群、通过本机 HTTP 轮询把机器人转发的群消息取回 App，展示、转成待办。

> **分工**：本仓库**只包含 App（鸿蒙端）**。后端（QQ 机器人 + 中继服务，`qqbot-backend`）**只在作者电脑上运行，不随本仓库分发**。别人拿到本仓库后**只测 App**，把 App 的服务器地址指向作者提供的后端地址即可，自己不用跑后端。

---

## 一、把 App 搬到另一台电脑 / 新工程：要拷贝哪些文件

### ✅ 需要拷贝（核心工程文件）

```
AppScope/                    # 应用级配置 + 图标资源
entry/                       # 主模块
  ├── src/                   # 源码：ets/（页面、服务）+ resources/
  ├── build-profile.json5
  ├── hvigorfile.ts
  ├── oh-package.json5
  └── obfuscation-rules.txt
hvigor/                      # 构建工具配置
build-profile.json5          # 根构建配置（SDK 版本、签名、模块）
code-linter.json5
hvigorfile.ts
oh-package.json5             # 依赖声明
oh-package-lock.json5        # 依赖锁定（可选，但建议带上）
.gitignore
机器人通道_交付文档/          # 需求/接口文档（可选，便于理解功能）
```

### ❌ 不要拷贝（自动生成 / 本机相关）

```
.hvigor/                     # 构建缓存
.idea/                       # IDE 配置
.cache/                      # 缓存
oh_modules/                  # 已安装依赖（新机 ohpm install 会重新生成）
local.properties             # 本机 SDK 路径（新机自动生成，别拷）
entry/build/                 # 构建产物
.git/                        # git 历史（要保留历史就整个 clone，别手工拷）
```

> 以上目录都已写进 `.gitignore`，直接 `git clone` 仓库不会包含它们；只有「手工复制文件」时才需要留意别带上。

---

## 二、拷过去之后要改的东西

1. **后端地址**（最重要）
   `entry/src/main/ets/common/Config.ets` 里的 `Config.baseUrl`，默认是 `http://192.168.1.104:8730`，改成**作者提供的后端地址**（后端只在作者电脑上跑，测试者不用自己起后端）。
   也可以不改代码：App 的「首次设置页」和「设置页」都能直接填服务器地址。

2. **签名配置**（真机运行 / 上架必须）
   根目录 `build-profile.json5` 的 `signingConfigs`，配成你自己的证书（DevEco Studio → File → Project Structure → Signing Configs 自动登录生成）。

3. **SDK 版本**
   若新电脑 SDK 版本不同，改根目录 `build-profile.json5` 里的 `targetSdkVersion` / `compatibleSdkVersion`。

---

## 三、打开与运行

1. DevEco Studio → Open **直接包含 `build-profile.json5` 的那一层目录**（也就是仓库根目录）。
2. 等它自动 Sync（或手动执行 `ohpm install`）。
3. 配置签名（见上）。
4. 连设备/模拟器 → Run。

> ⚠️ 打开错层级 = 工程同步失败，见第五节。`git clone` 会把仓库放进以仓库名命名的子目录，别在外层打开。

---

## 四、别人怎么连后端（不用自己跑后端）

后端跑在**作者电脑**上，你（测试者）拿到本仓库后**不需要自己跑后端**，只要把 App 的服务器地址填成作者给你的地址即可：

- 同一 Wi-Fi：`http://<作者电脑局域网 IP>:8730`
- 公网：`https://<作者提供的域名或公网地址>`

App 是纯 HTTP 轮询（1 秒），不需要 WebSocket / 推送 / 长连接。

> 后端如何启动、如何部署，见后端项目 `qqbot-backend`（不包含在本仓库，也已加入 `.gitignore`，不会被误提交）。

---

## 五、AI必读（想快速了解本项目，就照这个顺序做）

> 如果你是 AI，或者刚接手这个仓库：**先别翻源码**。按下面 4 步走，半小时内能建立完整心智模型，
> 然后想改哪块再去看对应文件，避免一上来读几千行 ets 抓不到重点。

### 第 1 步：先搞清楚「这个仓库是什么、不是什么」

- 本仓库**只有 App 端**（鸿蒙 / ArkTS）。后端（QQ 机器人 + 中继服务）**不在仓库里**，也别去实现它——
  它只跑在作者电脑上，App 填它的地址即可。
- 所以：**看到接口调用，就去读文档，不要试图在仓库里找服务端实现。**
- 判断功能能不能用的唯一标准：接口能不能按 `05_API接口文档.md` 正常返回。

### 第 2 步：按这个顺序读文档（都在 `机器人通道_交付文档/`）

| 顺序 | 文件 | 读它是为了搞清 |
| :-- | :-- | :-- |
| ① | `00_给AI的说明_先读这个.md` | 文档清单、阅读顺序、三条边界 |
| ② | `07_前后端对接方案.md` | **先读 §0 和 §3**：三个「任务」的区别、后端字段怎么落到本机 `Task` |
| ③ | `05_API接口文档.md` | 每个接口的请求 / 响应 / 错误码 / 上限（**契约以此为准**） |
| ④ | `06_后端能力与AI-Kit分工.md` | 后端能给什么、端侧 Kit 该干什么、隐私红线 |
| ⑤ | `02_接口速查_冻结版.md`、`03_接口类型定义_Types.ets.md` | v1 接口速查、可直接抄的 ArkTS 类型 |

### 第 3 步：记住这三条结论，不然一定写错

1. **不能有推送**：QQ 平台已下线主动消息，只有「用户订阅 + App 主动轮询」。
   **不要设计 WebSocket / 长连接 / 服务端推送。**
2. **正文只在服务端内存留 30 分钟**，App 取回后**必须存本机**。
   附件已按这条落实：轮询拉到带附件的新消息就**趁窗口**把图片/文件落到沙箱
   （`common/AttachmentStore.ets`，`filesDir/attachments/<群>/<msg_id>_<序号>`），
   **落了盘的就一直能看**（默认 200MB 上限、按最旧优先淘汰，随「清空本机消息」一起删）。
   但**没来得及落盘**的（App 没在前台轮询到那条消息）超过 30 分钟就找不回。
3. **三个「任务」不是一回事**：本机 `Task`（落库、用户可见）／云端 `BotTask`／后端内存窗口——
   靠 `client_task_id` / `candidate_id` 对齐，**别写成一个模型**（详见 `07` §0）。

### 第 4 步：想跑起来看效果

1. DevEco Studio **打开「直接包含 `build-profile.json5` 的那一层目录」**——打开它的父目录会「工程同步失败」，这是本项目最常见的坑。
   对应日志特征（`idea.log`）：
   ```
   WARN - ProjectModelLoader - can not find ProjectModelHandler <你打开的那个文件夹名>
   WARN - OhosSyncInvoker - load project data error. Cause:project model is null
   ```
2. 把 `Config.ets` 的 `baseUrl`（或 App 内「首次设置页 / 设置页」）填成作者给的后端地址。
3. 版本要求：本工程 `compatibleSdkVersion` 为 `6.1.1(24)`、`targetSdkVersion` 为 `26.0.0`，
   需要 DevEco Studio 6.x + 对应 API 的 SDK；版本过旧会同步失败，装新 SDK 或改根目录 `build-profile.json5`。
4. 真机运行需要先配自己的签名（`build-profile.json5` 的 `signingConfigs`，为空是正常的，只是不能上真机）。
5. 依赖下载失败时，在工程根目录执行 `ohpm install` 看具体报错。
