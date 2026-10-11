# 知了 · 机器人通道（鸿蒙 App 端）

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
AI交付_机器人通道/            # 需求/接口文档（可选，便于理解功能）
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
   `entry/src/main/ets/common/Config.ets` 里的 `Config.baseUrl`，默认是 `http://192.168.1.106:8730`，改成**作者提供的后端地址**（后端只在作者电脑上跑，测试者不用自己起后端）。
   也可以不改代码：App 的「首次设置页」和「设置页」都能直接填服务器地址。

2. **签名配置**（真机运行 / 上架必须）
   根目录 `build-profile.json5` 的 `signingConfigs`，配成你自己的证书（DevEco Studio → File → Project Structure → Signing Configs 自动登录生成）。

3. **SDK 版本**
   若新电脑 SDK 版本不同，改根目录 `build-profile.json5` 里的 `targetSdkVersion` / `compatibleSdkVersion`。

---

## 三、打开与运行

1. DevEco Studio → Open 本工程根目录。
2. 等它自动 Sync（或手动执行 `ohpm install`）。
3. 配置签名（见上）。
4. 连设备/模拟器 → Run。

---

## 四、别人怎么连后端（不用自己跑后端）

后端跑在**作者电脑**上，你（测试者）拿到本仓库后**不需要自己跑后端**，只要把 App 的服务器地址填成作者给你的地址即可：

- 同一 Wi-Fi：`http://<作者电脑局域网 IP>:8730`
- 公网：`https://<作者提供的域名或公网地址>`

App 是纯 HTTP 轮询（1 秒），不需要 WebSocket / 推送 / 长连接。

> 后端如何启动、如何部署，见后端项目 `qqbot-backend`（不包含在本仓库，也已加入 `.gitignore`，不会被误提交）。
