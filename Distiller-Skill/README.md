# Distiller-Skill

「知了 · 校园信息助手」HarmonyOS 项目的开发技能包。

- `SKILL.md` —— 技能入口（技术基线、目录导航、十条硬约束、取证纪律、验证闭环、UI 能力选用规则）
- `references/` —— 01–06 手写规约与清单；07/08/10 生成索引；09 升级 runbook；11–14 UI / 鸿蒙7 / WebUI / Flutter 导航
- `references/official/` `references/project/` `references/sources/` `references/examples/` —— **生成物，勿手改**
- `templates/` —— 可直接抄进工程的片段
- `tools/` —— 生成与安装脚本

---

## 1. 怎么用

**作为文档直接读**：先看 `SKILL.md` §0 技术基线与 §2 十条硬约束，再看 `references/03-能力速查.md`。

**作为 agent 技能加载**：安装到 `~\.agents\skills\distiller-dev`，然后**新开一个会话**。

```powershell
cd <这个包所在的目录>          # 生成副本时是 E:\Program_File\Skill\Distiller-Skill；以你自己的 clone 位置为准
powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-skill.ps1          # 演练
powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-skill.ps1 -Apply   # 装
```

DSH 只在四个根的一级子目录里找技能，且要求子目录下直接有 `SKILL.md`：
`<项目根>\.dsh\skills`、`<项目根>\.agents\skills`、`~\.dsh\skills`、`~\.agents\skills`。
`references/` 下几千篇 md **不会**被当成技能（发现逻辑不递归），所以是安全的。

加 `-Link` 可用目录联接代替复制（便于边改边生效）。

---

## 2. 重新生成 references

**真值源是 `tools\reference-manifest.json`。改清单，不要手改生成物。**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1              # 演练
powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Apply       # 落盘

# 只跑某一条产出线
-Only official | project | sources | sdk | samples

# 只跑某个分组 / 精简档
-Group main,ui,web,seven,flutter
-Profile project        # 只 main/core，约 1000 篇 / 6.6 MB
-Profile project-wide   # main 全量
-Profile ui             # ui + web + seven
-Profile all            # 默认，约 3800 篇 / 约 45 MB

# 只读模式
-Check                  # 当前文档库 vs _provenance.json，输出漂移三张表
-Revalidate -Apply      # 回扫 03/06 的结论在新库里还能不能命中
-FingerprintOnly -Apply # 只算逐文件 sha256（升级文档库**之前**先跑这个）
-ExtractSamples -Apply  # 抽官方示例片段到 references\examples\
```

四条产出线：**official**（本机 devecocli 文档库 → 路径即 documentId）、**project**（Distiller-DOC 调研文档镜像）、
**sources**（gitcode 上的 Flutter for OpenHarmony 文档树，唯一联网来源）、**sdk**（`.d.ts` 声明大纲，带行号）。

脚本只写生成物；写盘前会断言目标不在手写集合（`SKILL.md` / `README.md` / `references\01..06,09,11..14` / `templates\` / `tools\`）内。

---

## 3. 文档新鲜度（重要）

**官方文档副本是快照，不是活链接。** 文档由 **devecocli 的 npm 包**携带（包内 `docs.zip`），
换 CLI 版本时会把 `~\.local\share\deveco-cli\docs` **整库 `rm -rf` 重解**。没有 `devecocli docs update`。

所以：

- 判断「这份副本有多新」**看 `references\07-官方文档索引.md` 表头的指纹表**（`.version` / `docsZipSha256` / `builtAt`），不要看文件时间。
  ⚠️ 那是**生成这份副本的机器**上、当时那份库的指纹 —— **你自己的库不会是同一个快照**。想知道「我机器上的库是什么版本」，读你自己的 `~\.local\share\deveco-cli\docs\.version`，并见 `references\09-文档新鲜度与升级.md` §3。
- 要刷新 → 按 `references\09-文档新鲜度与升级.md` 的 runbook 走。**升级是全局 npm 动作，由人在终端执行。**
- **不要本地并存两个 devecocli 版本** —— store 路径硬编码走 `os.homedir()`，两个版本会互相抢着 `rm -rf`。

---

## 4. Windows / PowerShell 约定

> **先确认你的 shell 是哪一个**（三台机器不一定一样）：
> ```powershell
> $PSVersionTable.PSVersion.ToString()                          # 主版本 5 还是 7
> Get-Command pwsh -ErrorAction SilentlyContinue                # 有输出 = 装了 PS 7；输出为空 = 只有 powershell.exe
> ```

- **若**你的 shell 是 **Windows PowerShell 5.1**（主版本 `5`）：**`.ps1` 文件必须带 UTF-8 BOM**。无 BOM 的 UTF-8 会被 PS 5.1 当 ANSI 解码，中文全乱、报一堆假语法错（`Unexpected token`）。
  **判定方法**：脚本报 `Unexpected token` 且中文变乱码，就是这个原因 —— 不是脚本逻辑写错了。
  用 `tools\ensure-bom.ps1` 修：

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\ensure-bom.ps1 -Path tools\*.ps1
  ```
  （该脚本自身是纯 ASCII，所以无 BOM 也能跑；它也是**幂等**的 —— 已经带 BOM 的文件不会被重复加 BOM。）

- **若是 PowerShell 7+**（主版本 `7` 及以上）：这一条通常不适用（PS 7 默认按 UTF-8 读脚本）。
  **未实测** —— 本仓库生成时手上只有 PS 5.1；拿不准就照样跑一次上面那条 BOM 修复，无害。

- 脚本内所有正文读写走 `[System.IO.File]::ReadAllText/WriteAllText` 显式指定 UTF-8；**不要用 `Get-Content` / `Set-Content` / `Out-File` 处理正文** —— 会引入 CRLF 与 BOM，也会在无 BOM 时按 ANSI 误解码。**这条与 shell 版本无关，三台机器一致。**
- 生成的 md / json 一律 **UTF-8 无 BOM、只用 `\n`**。**同上，与 shell 版本无关。**

---

## 5. 已知限制

- `references/sources/flutter-ohos/` 来自 gitcode：匿名 contents API 约 **100 次快速调用后返回 429**，脚本已内置间隔与退避重试；`git/trees/<sha>?recursive=1` 不可用（只返根树），所以走逐层枚举。
- `developer.huawei.com/consumer/cn/doc/**` 是 **JS 单页应用**，任何 URL 都返回同一个约 1754 字节外壳，**无法抓取**，slug 探测也无意义。本地文档库才是权威 slug 表。
- Flutter for OpenHarmony 是**社区/TPC 适配，不是华为第一方能力**；本地官方文档库里几乎没有 Flutter 内容。详见 `references/14-FlutterUI参考导航.md`。
