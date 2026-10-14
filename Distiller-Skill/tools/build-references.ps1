<#
.SYNOPSIS
  生成 Distiller-Skill 的 references/：官方文档副本、调研文档镜像、Flutter 上游文档树、示例抽取、索引与溯源指纹。

.DESCRIPTION
  真值源：tools\reference-manifest.json（改清单，不要手改生成物）。

  五条产出线：
    official  从本机 devecocli 文档库（~\.local\share\deveco-cli\docs）复制，路径即 documentId
    project   从 Distiller-DOC / Distiller 仓库镜像调研文档
    sources   从 gitcode 拉 Flutter for OpenHarmony 文档树（唯一联网来源）
    sdk       由 SDK .d.ts 生成 references\08-SDK签名索引.md
    samples   从已落地的官方文档里抽取 ArkTS 示例块到 references\examples\

  生成物（**勿手改**）：references\official\、references\project\、references\sources\、
  references\examples\、references\07-官方文档索引.md、references\08-SDK签名索引.md、
  references\10-漂移报告.md、references\15-复核报告.md、references\official\_provenance.json。

  手写物（本脚本永不触碰）：SKILL.md、README.md、references\01..06、09、11..14、templates\、tools\。

  默认演练，不加 -Apply 不落盘。

.PARAMETER Profile
  all（默认）= main + ui + web + seven + flutter；project = 仅 main 的 core；
  project-wide = main 全量；ui = ui + web + seven。

.PARAMETER Group
  自定义分组（覆盖 -Profile 的分组部分）：main / ui / web / seven / flutter。

.PARAMETER Tier
  仅对 main 生效：core（精简）/ wide（追加）/ all（默认）。

.PARAMETER Only
  只跑某一条产出线。

.PARAMETER Resume
  sources 线专用：已存在的文件不再重抓。gitcode 匿名 API 会限流（429），
  限流导致上一次有遗漏时用这个把缺口补上，而不必全量重爬。

.PARAMETER FingerprintOnly
  只解析清单并算出逐文件 sha256，写 _provenance-<版本>.json，不复制任何文档。
  用途：升级文档库之前先留证。

.PARAMETER Check
  只读：当前文档库指纹与 _provenance.json 比对，输出变更/消失/解析不到三张表。不写文件。

.PARAMETER Revalidate
  只读：回扫 03-能力速查.md 与 06-未取证清单.md，输出四张表到 references\15-复核报告.md。

.PARAMETER ExtractSamples
  抽取示例块到 references\examples\（需先 -Apply 落地 official\）。

.PARAMETER DocsZip
  显式指定 docs.zip。默认自动探测（见 Resolve-DocsZip）。

.PARAMETER ExtractDocsZip
  把 docs.zip 解到一个目录，然后用 -DocsRoot 指向它。**1.3.4 起这是刷新文档库的唯一办法。**

  背景：devecocli 1.2.0 会把 docs.zip 解压成 ~\.local\share\deveco-cli\docs 下的 md 目录树，
  而 **1.3.4 改为直接从 docs.zip 里读**（只把 index.zip 解到 <dataDir>\index\data）。
  所以升级 CLI 后，那个 md 目录树**不会被刷新**，还是旧版内容 —— 直接爬它就是把旧库当成新库。
  本参数把 zip 解到一个带版本号的独立目录：既拿到新内容，又留住旧目录用于比对。

.PARAMETER ExtractTarget
  -ExtractDocsZip 的解压目标目录。默认 ~\.local\share\deveco-cli\docs-<zip 内容指纹前 8 位>。

.PARAMETER Apply
  真正写盘。

.PARAMETER Prune
  清理 references\official\ 里的陈旧文件（在目录里但不在本次清单解析结果里）。

  默认**只报告不删除**：清单小改时残留无害。但**跨文档版本**时必须清 ——
  例如 1.2.0 → 1.3.4 有 86 篇页面消失，残留会让 official\ 变成新旧混合体，
  比任何单一版本都糟。跨版本重爬的正确姿势：`-Only official -Apply -Prune`。

.NOTES
  仅支持 Windows PowerShell 5.1 语法。所有正文读写走 [System.IO.File]，
  避免 Get-Content / Set-Content / Out-File 引入 CRLF 与 BOM。

  文档来源随 devecocli 版本变化：
    1.2.0  ~\.local\share\deveco-cli\docs 下的 md 目录树（-DocsRoot 直接指向它）
    1.3.4+ docs.zip 本体（先 -ExtractDocsZip，再用 -DocsRoot 指向解出来的目录）
#>
[CmdletBinding()]
param(
  [ValidateSet('all', 'project', 'project-wide', 'ui')][string]$Profile = 'all',
  [string[]]$Group = @(),
  [ValidateSet('all', 'core', 'wide')][string]$Tier = 'all',
  [ValidateSet('all', 'official', 'project', 'sources', 'sdk', 'samples')][string]$Only = 'all',
  [string]$DocsRoot = '',
  [string]$SdkRoot = '',
  [string]$DocsZip = '',
  [string]$ExtractTarget = '',
  [switch]$ExtractDocsZip,
  [switch]$Resume,
  [switch]$FingerprintOnly,
  [switch]$Check,
  [switch]$Revalidate,
  [switch]$ExtractSamples,
  [string]$Against = '',
  [switch]$Apply,
  [switch]$Prune
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ---------------------------------------------------------------- 路径解析
# 这个技能是给多人共用的，所以路径一律**探测**，不要写死某一台机器的值。
# 本机环境探测（团队成员第一次跑之前先自己确认一遍）：
#   devecocli --version ; devecocli device list ; devecocli emulator list
#   $PSVersionTable.PSVersion ; $env:DEVECO_SDK_HOME

function Test-SdkRoot {
  # 一个可用的 SDK 根至少要有 openharmony 或 hms 的 ets/api
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
  return (Test-Path -LiteralPath (Join-Path $Path 'openharmony\ets\api')) -or
         (Test-Path -LiteralPath (Join-Path $Path 'hms\ets\api'))
}

function Resolve-SdkRoot {
  param([string]$Explicit)
  if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
    if (Test-SdkRoot $Explicit) { return $Explicit }
    Write-Host "  ! -SdkRoot 指定的目录看起来不是 SDK 根（找不到 openharmony\ets\api 或 hms\ets\api）：$Explicit" -ForegroundColor Yellow
    return $Explicit
  }
  $cands = New-Object System.Collections.Generic.List[string]
  # 1) DEVECO_SDK_HOME —— 实测这个变量**不保证指向真 SDK**：
  #    本机它指向 <...>\DevEco Studio beta\sdk，那里面只有 licenses 与 system-image（系统镜像），
  #    真 SDK 在**兄弟目录** <...>\DevEco Studio beta\DevEco Studio\sdk\default。
  #    所以要同时试「它本身 / 它的 default / 它父目录下的若干形态」。
  if ($env:DEVECO_SDK_HOME) {
    $h = $env:DEVECO_SDK_HOME
    $parent = Split-Path $h -Parent
    foreach ($c in @(
      $h,
      (Join-Path $h 'default'),
      (Join-Path $h 'DevEco Studio\sdk\default'),
      (Join-Path $h '..\DevEco Studio\sdk\default'),
      (Join-Path $h '..\sdk\default'),
      (Join-Path $parent 'DevEco Studio\sdk\default'),
      (Join-Path $parent 'sdk\default'),
      (Join-Path $parent 'default')
    )) { $cands.Add($c) }
    # 兄弟目录里再浅搜一层 */sdk/default，覆盖 DevEco 目录名带空格/版本号的写法
    if ($parent -and (Test-Path -LiteralPath $parent)) {
      try {
        Get-ChildItem -LiteralPath $parent -Directory -ErrorAction SilentlyContinue | ForEach-Object {
          $cands.Add((Join-Path $_.FullName 'sdk\default'))
          $cands.Add((Join-Path $_.FullName 'default'))
        }
      } catch { }
    }
  }
  # 2) 常见安装位置
  foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:LOCALAPPDATA, "$env:LOCALAPPDATA\Huawei")) {
    if (-not $base) { continue }
    foreach ($rel in @('Huawei\DevEco Studio\sdk\default', 'DevEco Studio\sdk\default', 'Huawei\Sdk', 'Sdk')) {
      $cands.Add((Join-Path $base $rel))
    }
  }
  # 3) 兜底：写这份脚本的机器上的位置（换机器时基本用不上，留着只是少一次报错）
  $cands.Add('D:\Coding\DevEco\DevEco Studio beta\DevEco Studio\sdk\default')

  foreach ($c in $cands) {
    if (Test-SdkRoot $c) { return ([System.IO.Path]::GetFullPath($c)) }
  }
  return ''
}

if ([string]::IsNullOrWhiteSpace($DocsRoot)) {
  $cands = @((Join-Path $env:USERPROFILE '.local\share\deveco-cli\docs'))
  if ($env:HOME) { $cands += (Join-Path $env:HOME '.local\share\deveco-cli\docs') }
  # 与 devecocli 的 os.homedir() 对齐；两者都找不到就让后面的存在性检查去报错
  $DocsRoot = $cands[0]
  foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { $DocsRoot = $c; break } }
}

$SdkRoot = Resolve-SdkRoot -Explicit $SdkRoot
if ([string]::IsNullOrWhiteSpace($SdkRoot)) {
  Write-Host '  ! 没找到 HarmonyOS SDK 根 —— sdk 这条产出线会被跳过（其余三条不受影响）。' -ForegroundColor Yellow
  Write-Host '    自己探测一下，然后用 -SdkRoot 显式指定：' -ForegroundColor Yellow
  Write-Host '      $env:DEVECO_SDK_HOME' -ForegroundColor Yellow
  Write-Host '      Get-ChildItem "$env:DEVECO_SDK_HOME\default" -ErrorAction SilentlyContinue' -ForegroundColor Yellow
  Write-Host '      Get-ChildItem $env:LOCALAPPDATA\Huawei -Recurse -Filter sdk-pkg.json -Depth 4 -ErrorAction SilentlyContinue' -ForegroundColor Yellow
  Write-Host '    （SDK 根的特征是下面有 openharmony\ets\api 或 hms\ets\api）' -ForegroundColor Yellow
}

# ------------------------------------------------ docs.zip（1.3.4+ 的文档真身）
# 1.3.4 起 devecocli 不再把文档解压成 md 目录树，而是直接从包内 docs.zip 读。
# zip 里的中文条目名**没有设 UTF-8 标志位**，.NET 默认按系统 ANSI（中文 Windows 上是 GBK）解码，
# 于是全变成乱码（`版本说明` → `鐗堟湰璇存槑`）。必须在 Open 时显式传 UTF8Encoding 才正确。
function Resolve-DocsZip {
  param([string]$Explicit)
  if (-not [string]::IsNullOrWhiteSpace($Explicit)) {
    if (Test-Path -LiteralPath $Explicit -PathType Leaf) { return ([System.IO.Path]::GetFullPath($Explicit)) }
    Write-Host "  ! -DocsZip 指定的文件不存在：$Explicit" -ForegroundColor Yellow
    return ''
  }
  $cands = New-Object System.Collections.Generic.List[string]
  # 1.3.4 的分包布局
  $npmRoot = (npm root -g 2>$null | Select-Object -First 1)
  if ($npmRoot -and (Test-Path -LiteralPath $npmRoot)) {
    $deveco = Join-Path $npmRoot '@deveco'
    if (Test-Path -LiteralPath $deveco) {
      # 1.2.0 在同级；1.3.4 嵌套在 deveco-cli\node_modules\@deveco\deveco-cli-common\
      foreach ($p in @(
        (Join-Path $deveco 'deveco-cli\docs.zip'),
        (Join-Path $deveco 'deveco-cli\node_modules\@deveco\deveco-cli-common\docs.zip'),
        (Join-Path $deveco 'deveco-cli-common\docs.zip')
      )) { $cands.Add($p) }
      # 兜底：在 @deveco 下浅层搜一遍
      try {
        Get-ChildItem -LiteralPath $deveco -Recurse -Depth 4 -Filter docs.zip -File -ErrorAction SilentlyContinue |
          ForEach-Object { $cands.Add($_.FullName) }
      } catch { }
    }
  }
  foreach ($c in $cands) { if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { return ([System.IO.Path]::GetFullPath($c)) } }
  return ''
}

function Get-DocsZipInfo {
  param([string]$ZipPath)
  Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Read, $utf8)
  try {
    $md = @($zip.Entries | Where-Object { $_.FullName -like '*.md' })
    return [pscustomobject]@{
      Sha256   = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
      Bytes    = (Get-Item -LiteralPath $ZipPath).Length
      Entries  = $zip.Entries.Count
      MdCount  = $md.Count
      MdBytes  = ($md | Measure-Object Length -Sum).Sum
      Catalogs = @($md | ForEach-Object { ($_.FullName -split '/')[0] } | Group-Object | Sort-Object Count -Descending)
    }
  } finally { $zip.Dispose() }
}

function Expand-DocsZip {
  param([string]$ZipPath, [string]$Target)
  Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Read, $utf8)
  try {
    $n = 0; $bytes = 0
    foreach ($e in $zip.Entries) {
      if ([string]::IsNullOrEmpty($e.Name)) { continue }   # 目录条目
      if ($e.FullName -notlike '*.md' -and $e.FullName -notlike '*.json') { continue }
      # 防路径穿越
      $rel = $e.FullName -replace '/', '\'
      if ($rel -match '\.\.') { continue }
      $dst = Join-Path $Target $rel
      $dir = Split-Path -Parent $dst
      if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $dst, $true)
      $n++; $bytes += $e.Length
    }
    return [pscustomobject]@{ Files = $n; Bytes = $bytes }
  } finally { $zip.Dispose() }
}

if ($ExtractDocsZip) {
  $zipPath = Resolve-DocsZip -Explicit $DocsZip
  if (-not $zipPath) {
    Write-Bad ' 找不到 docs.zip。自己探测一下再显式指定：'
    Write-Host '   npm root -g'
    Write-Host '   Get-ChildItem "$(npm root -g)\@deveco" -Recurse -Depth 4 -Filter docs.zip'
    exit 2
  }
  $info = Get-DocsZipInfo -ZipPath $zipPath
  Write-Host ''
  Write-Host 'docs.zip 抽取' -ForegroundColor Cyan
  Write-Host "  来源   : $zipPath"
  Write-Host "  体积   : $([math]::Round($info.Bytes/1MB,2)) MB（sha256 $($info.Sha256.Substring(0,16))…）"
  Write-Host "  条目   : $($info.Entries)（其中 .md $($info.MdCount) 篇 / 解压后 $([math]::Round($info.MdBytes/1MB,1)) MB）"
  foreach ($c in $info.Catalogs) { Write-Host ("    {0,-12} {1,6}" -f $c.Name, $c.Count) }
  if ([string]::IsNullOrWhiteSpace($ExtractTarget)) {
    $ExtractTarget = Join-Path (Join-Path $env:USERPROFILE '.local\share\deveco-cli') ("docs-" + $info.Sha256.Substring(0, 8))
  }
  Write-Host "  目标   : $ExtractTarget"
  if (-not $Apply) {
    Write-Host ''
    Write-Host '演练结束（未写入任何文件）。确认无误后加 -Apply。' -ForegroundColor Yellow
    exit 0
  }
  $r = Expand-DocsZip -ZipPath $zipPath -Target $ExtractTarget
  Write-Host "  + 已抽取 $($r.Files) 个文件 / $([math]::Round($r.Bytes/1MB,1)) MB" -ForegroundColor Green
  Write-Host ''
  Write-Host '  下一步（爬这份新内容，旧目录保持不动以便比对）：' -ForegroundColor Cyan
  Write-Host "    powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -DocsRoot `"$ExtractTarget`" -Check"
  Write-Host "    powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -DocsRoot `"$ExtractTarget`" -Apply"
  exit 0
}

# 单独的开关要收窄成只跑那一条线，否则 -ExtractSamples 会顺带重爬整棵文档树与 gitcode。
if (-not $PSBoundParameters.ContainsKey('Only')) {
  if ($Check -or $Revalidate -or $FingerprintOnly) { }
  elseif ($ExtractSamples) { $Only = 'samples' }
}

$script:ResumeSources = [bool]$Resume

$SkillRoot = Split-Path -Parent $PSScriptRoot
$RefRoot = Join-Path $SkillRoot 'references'
$ManifestPath = Join-Path $PSScriptRoot 'reference-manifest.json'

# 生成物路径前缀（写盘前用于 assert 不碰手写物）
$GeneratedDirs = @(
  (Join-Path $RefRoot 'official'),
  (Join-Path $RefRoot 'project'),
  (Join-Path $RefRoot 'sources'),
  (Join-Path $RefRoot 'examples')
)
$GeneratedFiles = @(
  (Join-Path $RefRoot '07-官方文档索引.md'),
  (Join-Path $RefRoot '08-SDK签名索引.md'),
  (Join-Path $RefRoot '10-漂移报告.md'),
  (Join-Path $RefRoot '15-复核报告.md')
)

# ---------------------------------------------------------------- 小工具
function Write-Log { param([string]$m) Write-Host $m }
function Write-Warn2 { param([string]$m) Write-Host "  ! $m" -ForegroundColor Yellow }
function Write-Bad { param([string]$m) Write-Host "  x $m" -ForegroundColor Red }
function Write-Ok { param([string]$m) Write-Host "  + $m" -ForegroundColor Green }

function Read-TextRaw {
  param([string]$Path)
  # 显式 UTF-8（带 BOM 也能正确剥掉）。不要用 Get-Content：PS 5.1 在无 BOM 时按 ANSI 解码，
  # 会把 reference-manifest.json 里的中文解成乱码并让 ConvertFrom-Json 失败。
  return [System.IO.File]::ReadAllText($Path, (New-Object System.Text.UTF8Encoding($false)))
}

function Write-TextLfNoBom {
  param([string]$Path, [string]$Text)
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $norm = ($Text -replace "`r`n", "`n") -replace "`r", "`n"
  [System.IO.File]::WriteAllText($Path, $norm, $Utf8NoBom)
}

function Get-Sha256 {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Assert-GeneratedOnly {
  param([string]$Path)
  $full = [System.IO.Path]::GetFullPath($Path)
  foreach ($d in $GeneratedDirs) {
    if ($full.StartsWith([System.IO.Path]::GetFullPath($d), [StringComparison]::OrdinalIgnoreCase)) { return }
  }
  foreach ($f in $GeneratedFiles) {
    if ($full -eq [System.IO.Path]::GetFullPath($f)) { return }
  }
  throw "拒绝对非生成物路径写盘：$full（生成物仅限 references\official|project|sources|examples\ 与 07/08/10）"
}

function Copy-FileVerbatim {
  param([string]$Src, [string]$Dst)
  Assert-GeneratedOnly $Dst
  $dir = Split-Path -Parent $Dst
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Copy-Item -LiteralPath $Src -Destination $Dst -Force
}

# ---------------------------------------------------------------- 清单解析
if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "清单不存在：$ManifestPath" }
$Manifest = (Read-TextRaw $ManifestPath) | ConvertFrom-Json

$GroupPlan = @()
if ($Group.Count -gt 0) {
  $GroupPlan = $Group
  $TierPlan = $Tier
} else {
  switch ($Profile) {
    'project' { $GroupPlan = @('main'); $TierPlan = 'core' }
    'project-wide' { $GroupPlan = @('main'); $TierPlan = 'all' }
    'ui' { $GroupPlan = @('ui', 'web', 'seven'); $TierPlan = 'all' }
    default { $GroupPlan = @('main', 'ui', 'web', 'seven', 'flutter'); $TierPlan = 'all' }
  }
  if ($Tier -ne 'all') { $TierPlan = $Tier }
}

function Select-OfficialEntries {
  $out = @()
  foreach ($e in $Manifest.official) {
    if ($GroupPlan -notcontains $e.group) { continue }
    if ($e.group -eq 'main' -and $TierPlan -ne 'all') {
      $t = if ($e.PSObject.Properties.Name -contains 'tier') { $e.tier } else { 'wide' }
      if ($t -ne $TierPlan) { continue }
    }
    $out += $e
  }
  return $out
}

# ---------------------------------------------------------------- 文档库定位
function Get-DocsIndex {
  # 返回 catalog 名 -> 该 catalog 下所有 .md 的 FileInfo 列表
  $map = @{}
  foreach ($cat in @('开发指南', 'API参考', '最佳实践', 'FAQ', '版本说明', '变更预告')) {
    $p = Join-Path $DocsRoot $cat
    if (Test-Path -LiteralPath $p) {
      $map[$cat] = @(Get-ChildItem -LiteralPath $p -Recurse -File -Filter *.md -ErrorAction SilentlyContinue)
    } else {
      $map[$cat] = @()
    }
  }
  return $map
}

function Get-AllDocs {
  param($Index)
  $all = @()
  foreach ($k in $Index.Keys) { $all += $Index[$k] }
  return $all
}

function Get-RelUnder {
  param([string]$Base, [string]$Full)
  $b = [System.IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
  return [System.IO.Path]::GetFullPath($Full).Substring($b.Length)
}

function Resolve-DocEntry {
  <# 六级降级链。返回 @{ Ok=; Level=; File=; Rel=; Note= } #>
  param($Entry, $Index, $AllDocs)

  $cat = $Entry.catalog
  $prefix = if ($Entry.PSObject.Properties.Name -contains 'path') { $Entry.path } else { '' }
  $slug = $Entry.slug
  $aliases = @()
  if ($Entry.PSObject.Properties.Name -contains 'aliases' -and $Entry.aliases) { $aliases = @($Entry.aliases) }
  $wanted = @($slug) + $aliases

  $inCat = $Index[$cat]
  # 级 1/2：指定 catalog + path 前缀内，先精确 slug 再 aliases
  if ($prefix -ne '') {
    $prefixN = $prefix -replace '/', '\'
    $pre = $inCat | Where-Object { (Get-RelUnder (Join-Path $DocsRoot $cat) $_.FullName).StartsWith($prefixN + '\', [StringComparison]::OrdinalIgnoreCase) }
    foreach ($w in $wanted) {
      $hit = @($pre | Where-Object { $_.Name -eq ($w + '.md') })
      if ($hit.Count -eq 1) { return @{ Ok = $true; Level = if ($w -eq $slug) { '1-exact-inpath' } else { '2-alias-inpath' }; File = $hit[0] } }
      if ($hit.Count -gt 1) { return @{ Ok = $false; Ambiguous = $hit } }
    }
  }
  # 级 3：catalog 全树
  foreach ($w in $wanted) {
    $hit = @($inCat | Where-Object { $_.Name -eq ($w + '.md') })
    if ($hit.Count -eq 1) { return @{ Ok = $true; Level = '3-cat-wide'; File = $hit[0] } }
    if ($hit.Count -gt 1) { return @{ Ok = $false; Ambiguous = $hit } }
  }
  # 级 4：全库
  foreach ($w in $wanted) {
    $hit = @($AllDocs | Where-Object { $_.Name -eq ($w + '.md') })
    if ($hit.Count -eq 1) { return @{ Ok = $true; Level = '4-global'; File = $hit[0] } }
    if ($hit.Count -gt 1) { return @{ Ok = $false; Ambiguous = $hit } }
  }
  # 级 5：侧车 title 模糊
  $titles = @()
  foreach ($f in $inCat) {
    $side = [System.IO.Path]::ChangeExtension($f.FullName, '.json')
    if (Test-Path -LiteralPath $side) {
      try {
        $j = (Read-TextRaw $side) | ConvertFrom-Json
        if ($j.title -and ($j.title -replace '\s', '') -eq ($slug -replace '[-_]', '')) { $titles += $f }
      } catch { }
    }
  }
  if ($titles.Count -eq 1) { return @{ Ok = $true; Level = '5-title'; File = $titles[0] } }
  if ($titles.Count -gt 1) { return @{ Ok = $false; Ambiguous = $titles } }

  return @{ Ok = $false; Missing = $true }
}

function Resolve-DirEntry {
  param($Entry)
  $cat = $Entry.catalog
  $rel = $Entry.path
  $direct = Join-Path (Join-Path $DocsRoot $cat) $rel
  if (Test-Path -LiteralPath $direct -PathType Container) {
    return @{ Ok = $true; Level = '1-exact'; Dir = $direct }
  }
  # 级 2/3：按顶层目录名做 slug 化模糊，唯一才接受
  $catRoot = Join-Path $DocsRoot $cat
  $firstSeg = ($rel -split '[\\/]')[0]
  $norm = ($firstSeg -replace '[-_]', '').ToLowerInvariant()
  $cands = @(Get-ChildItem -LiteralPath $catRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { (($_.Name -replace '[-_]', '').ToLowerInvariant()) -eq $norm })
  if ($cands.Count -eq 1 -and $rel -notmatch '[\\/]') {
    return @{ Ok = $true; Level = '2-dir-fuzzy'; Dir = $cands[0].FullName }
  }
  if ($cands.Count -gt 1) { return @{ Ok = $false; Ambiguous = $cands } }
  return @{ Ok = $false; Missing = $true }
}

# ---------------------------------------------------------------- 文档库指纹
function Get-DocsFingerprint {
  $fp = [ordered]@{
    docsRoot        = $DocsRoot
    exists          = (Test-Path -LiteralPath $DocsRoot)
    storeVersion    = $null
    indexVersion    = $null
    docsZipSha256   = $null
    segmentCount    = $null
    builtAt         = $null
    builtAtLocal    = $null
    mdCount         = 0
    mdBytes         = 0
    cliVersion      = $null
    capturedAtLocal = (Get-Date).ToString('s')
  }
  # 1.2.0 的 md 目录树里没有版本标记，实际版本看 .version 与 `.index\build-meta.json`；
  # 1.3.4+ 的目录树没有这些文件，所以要额外记下 docs.zip 本体的指纹，否则无法判断内容版本。
  $zp = Resolve-DocsZip -Explicit $DocsZip
  if ($zp) {
    try {
      $zi = Get-DocsZipInfo -ZipPath $zp
      $fp['docsZipPath'] = $zp
      $fp['docsZipBytes'] = $zi.Bytes
      $fp['docsZipMdCount'] = $zi.MdCount
      $fp['docsZipSelfSha256'] = $zi.Sha256
      if (-not $fp.docsZipSha256) { $fp.docsZipSha256 = $zi.Sha256 }
    } catch { }
  }
  if (-not $fp.exists) { return $fp }
  $vf = Join-Path $DocsRoot '.version'
  if (Test-Path -LiteralPath $vf) { $fp.storeVersion = (Read-TextRaw $vf).Trim() }
  $bm = Join-Path $DocsRoot '.index\build-meta.json'
  if (Test-Path -LiteralPath $bm) {
    try {
      $j = (Read-TextRaw $bm) | ConvertFrom-Json
      $fp.indexVersion = $j.indexVersion
      $fp.docsZipSha256 = $j.docsZipSha256
      $fp.segmentCount = $j.segmentCount
      $fp.builtAt = $j.builtAt
      try { $fp.builtAtLocal = ([datetimeoffset]::FromUnixTimeMilliseconds([int64]$j.builtAt)).LocalDateTime.ToString('s') } catch { }
    } catch { }
  }
  try { $fp.cliVersion = (& devecocli --version 2>$null | Select-Object -First 1) } catch { }
  $mds = @(Get-ChildItem -LiteralPath $DocsRoot -Recurse -File -Filter *.md -ErrorAction SilentlyContinue)
  $fp.mdCount = $mds.Count
  $fp.mdBytes = ($mds | Measure-Object Length -Sum).Sum
  return $fp
}

# ---------------------------------------------------------------- 07 索引
function Format-Size { param([double]$b) if ($b -ge 1MB) { '{0:N1} MB' -f ($b / 1MB) } else { '{0:N0} KB' -f ($b / 1KB) } }

function New-IndexDoc {
  param($Rows, $Fp)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('<!-- 生成物：由 tools\build-references.ps1 产出，勿手改 -->')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('# 07 · 官方文档索引')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('本表是 `references\official\` 的全量清单。路径列是相对本文件的路径，即 documentId 的可点击形式。')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('## 文档库指纹（用来判断这份副本有多新）')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('| 项 | 值 |')
  [void]$sb.AppendLine('| :-- | :-- |')
  [void]$sb.AppendLine("| 文档库根 | ``$($Fp.docsRoot)`` |")
  [void]$sb.AppendLine("| 文档库版本 ``.version`` | ``$($Fp.storeVersion)`` |")
  [void]$sb.AppendLine("| devecocli 版本 | ``$($Fp.cliVersion)`` |")
  [void]$sb.AppendLine("| 索引版本 ``indexVersion`` | ``$($Fp.indexVersion)`` |")
  [void]$sb.AppendLine("| ``docsZipSha256`` | ``$($Fp.docsZipSha256)`` |")
  [void]$sb.AppendLine("| 索引构建时间 | $($Fp.builtAtLocal) |")
  [void]$sb.AppendLine("| 库内 md 总数 / 体积 | $($Fp.mdCount) / $(Format-Size $Fp.mdBytes) |")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('> 文档库是**随 devecocli npm 包发布的快照**，换版本会整库重解。要刷新先升级 devecocli，再重跑 `tools\build-references.ps1 -Apply`。')

  $missing = @($Rows | Where-Object { -not $_.Ok })
  $byGroup = $Rows | Where-Object { $_.Ok } | Group-Object Group

  foreach ($g in @('main', 'ui', 'web', 'seven', 'flutter')) {
    $gg = @($byGroup | Where-Object { $_.Name -eq $g })
    if ($gg.Count -eq 0) { continue }
    $items = $gg[0].Group
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("## 分组 ``$g``（$($items.Count) 条，$(Format-Size (($items | Measure-Object Bytes -Sum).Sum))）")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| documentId | 篇 | 体积 | 命中级别 | 为什么需要 |')
    [void]$sb.AppendLine('| :-- | --: | --: | :-- | :-- |')
    foreach ($r in ($items | Sort-Object DocumentId)) {
      $why = $r.Why -replace '\|', '\|'
      [void]$sb.AppendLine("| ``$($r.DocumentId)`` | $($r.Files) | $(Format-Size $r.Bytes) | $($r.Level) | $why |")
    }
  }

  [void]$sb.AppendLine('')
  [void]$sb.AppendLine("## 未命中（$($missing.Count) 条）")
  [void]$sb.AppendLine('')
  if ($missing.Count -eq 0) {
    [void]$sb.AppendLine('无。清单里所有条目都在当前文档库里解析到了。')
  } else {
    [void]$sb.AppendLine('下面这些条目在当前文档库里解析不到。**不要凭记忆补内容**——按 `why` 列去官网按标题找，或升级 devecocli 后重跑。')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| 分组 | catalog | 期望路径 / slug | 状态 | 为什么需要 |')
    [void]$sb.AppendLine('| :-- | :-- | :-- | :-- | :-- |')
    foreach ($m in ($missing | Sort-Object Group, DocumentId)) {
      [void]$sb.AppendLine("| $($m.Group) | $($m.Catalog) | ``$($m.DocumentId)`` | $($m.Status) | $($m.Why) |")
    }
  }
  [void]$sb.AppendLine('')
  return $sb.ToString()
}

# ---------------------------------------------------------------- SDK 索引
function New-SdkIndexDoc {
  param($SdkEntries, $SdkRootPath, $Fp)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('<!-- 生成物：由 tools\build-references.ps1 产出，勿手改 -->')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('# 08 · SDK 签名索引')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('行号取自本机 SDK 头文件，可直接回到 DevEco 核对。')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('> [!warning] 行号与本机 SDK 版本绑定')
  [void]$sb.AppendLine('> 这份索引是拿**生成它的那台机器**上的 SDK 生成的。团队成员换了机器或换了 SDK 版本，**行号会漂**。')
  [void]$sb.AppendLine('> 换机器后请自己重跑一条命令刷新本文件：')
  [void]$sb.AppendLine('>')
  [void]$sb.AppendLine('> ```powershell')
  [void]$sb.AppendLine('> powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Only sdk -Apply')
  [void]$sb.AppendLine('> ```')
  [void]$sb.AppendLine('>')
  [void]$sb.AppendLine('> **签名本身**（参数、枚举成员、`@since`）跨版本稳定，可以放心引用；只有 `L<行号>` 需要重新核对。')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine("SDK 根：``$SdkRootPath``")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('## Part 1 · Kit 桶导出（符号来自哪个模块）')
  [void]$sb.AppendLine('')
  $missing = @()
  foreach ($e in $SdkEntries) {
    if ($e.kind -ne 'kit') { continue }
    $p = Join-Path (Join-Path $SdkRootPath "$($e.root)\ets\kits") $e.file
    if (-not (Test-Path -LiteralPath $p)) { $missing += "$($e.root)/ets/kits/$($e.file)"; continue }
    [void]$sb.AppendLine("### ``$($e.root)/ets/kits/$($e.file)``")
    [void]$sb.AppendLine('')
    if ($e.why) { [void]$sb.AppendLine("用途：$($e.why)"); [void]$sb.AppendLine('') }
    [void]$sb.AppendLine('```ts')
    $lines = [System.IO.File]::ReadAllLines($p)
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '^\s*(export|import)\s') { [void]$sb.AppendLine("L$($i+1): $($lines[$i].Trim())") }
    }
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')
  }
  [void]$sb.AppendLine('## Part 2 · 声明大纲（顶层声明 + 类/接口成员 + 行号 + JSDoc 关键标签）')
  [void]$sb.AppendLine('')
  $declRe = '^\s*(export\s+)?(declare\s+)?(function|class|interface|enum|namespace|const|type|let)\s+([A-Za-z_$][\w$]*)'
  $memberRe = '^\s{2,}(static\s+|readonly\s+)?(get\s+|set\s+)?[A-Za-z_$][\w$]*\s*[(:<]'
  foreach ($e in $SdkEntries) {
    if ($e.kind -eq 'kit') { continue }
    $p = Join-Path (Join-Path $SdkRootPath "$($e.root)\ets\api") $e.file
    if (-not (Test-Path -LiteralPath $p)) { $missing += "$($e.root)/ets/api/$($e.file)"; continue }
    $fi = Get-Item -LiteralPath $p
    $big = $fi.Length -gt 200KB
    [void]$sb.AppendLine("### ``$($e.root)/ets/api/$($e.file)``")
    [void]$sb.AppendLine('')
    if ($e.why) { [void]$sb.AppendLine("用途：$($e.why)") }
    $sizeNote = if ($big) { '（超过 200 KB，只出顶层声明、不摘 JSDoc 与类成员）' } else { '（含类/接口成员）' }
    [void]$sb.AppendLine("大小：$(Format-Size $fi.Length)$sizeNote")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('```ts')
    $lines = [System.IO.File]::ReadAllLines($p)
    $inBlock = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $l = $lines[$i]
      $isDecl = $l -match $declRe
      if ($isDecl -and $l -match '\b(class|interface|namespace)\s+[A-Za-z_$]') { $inBlock = $true }
      elseif ($inBlock -and $l -match '^\}') { $inBlock = $false }
      $isMember = (-not $big) -and $inBlock -and ($l -match $memberRe)
      if (-not ($isDecl -or $isMember)) { continue }
      if (-not $big) {
        # 往上找最近的 JSDoc 关键标签
        $tags = @()
        for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 70); $j--) {
          $pl = $lines[$j]
          if ($pl -match $declRe) { break }
          if ($pl -match '^\s*\*\s*@(since|permission|syscap|stagemodelonly|deprecated|systemapi|form|atomicservice)') {
            $tags += ($pl.Trim() -replace '^\*\s*', '')
          }
        }
        if ($tags.Count -gt 0) { [void]$sb.AppendLine("  // $([string]::Join(' | ', ($tags | Select-Object -Unique)))") }
      }
      # 签名续行
      $sig = $l.Trim()
      $k = $i
      while ($k -lt $lines.Count - 1 -and $sig -notmatch '[;{]\s*$' -and $sig.Length -lt 400) { $k++; $sig += ' ' + $lines[$k].Trim() }
      [void]$sb.AppendLine("L$($i+1): $($sig -replace '\s+', ' ')")
    }
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine('')
  }
  if ($missing.Count -gt 0) {
    [void]$sb.AppendLine('## 未找到的 SDK 文件')
    [void]$sb.AppendLine('')
    foreach ($m in ($missing | Select-Object -Unique)) { [void]$sb.AppendLine("- ``$m``") }
    [void]$sb.AppendLine('')
  }
  return $sb.ToString()
}

# ---------------------------------------------------------------- 示例抽取
function Get-ExampleRegions {
  <# 从文档 md 里定位示例区。库内 md 没有 ``` 围栏，代码是裸行块。 #>
  param([string[]]$Lines)

  $codeStart = '^\s*(import\s|@[A-Za-z]|struct\s|export\s|const\s|let\s|var\s|function\s|class\s|enum\s|interface\s|//|/\*|\{|\}|<)'
  $regions = @()
  $i = 0
  while ($i -lt $Lines.Count) {
    if ($Lines[$i] -notmatch $codeStart) { $i++; continue }
    $start = $i
    $j = $i
    $proseRun = 0
    while ($j -lt $Lines.Count) {
      $l = $Lines[$j]
      if ($l -match '^#+\s') { break }
      $isBlank = [string]::IsNullOrWhiteSpace($l)
      $cjk = ([regex]::Matches($l, '[\u4e00-\u9fff]')).Count
      $looksCode = ($l -match '[(){}\[\];=<>]') -or ($l -match '^\s*[.@]') -or ($l -match '\w\s*\.\s*\w')
      $looksProse = ($cjk -ge 2) -and (-not $looksCode)
      if ($isBlank) { $j++; continue }
      if ($looksProse) {
        $proseRun++
        if ($proseRun -ge 2) { break }
      } else {
        $proseRun = 0
      }
      $j++
    }
    # 去掉尾部空行与散文行
    $end = $j - 1
    while ($end -gt $start) {
      $l = $Lines[$end]
      $cjk = ([regex]::Matches($l, '[\u4e00-\u9fff]')).Count
      $looksCode = ($l -match '[(){}\[\];=<>]') -or ($l -match '^\s*[.@]')
      if ([string]::IsNullOrWhiteSpace($l) -or (($cjk -ge 2) -and (-not $looksCode))) { $end--; continue }
      break
    }
    if (($end - $start) -ge 3) {
      $body = @()
      for ($k = $start; $k -le $end; $k++) { $body += $Lines[$k] }
      $codeLines = 0
      foreach ($b in $body) {
        $cjk = ([regex]::Matches($b, '[\u4e00-\u9fff]')).Count
        $looksCode = ($b -match '[(){}\[\];=<>]') -or ($b -match '^\s*[.@]') -or [string]::IsNullOrWhiteSpace($b)
        if ($looksCode -and $cjk -lt 2) { $codeLines++ }
      }
      $ratio = if ($body.Count -gt 0) { $codeLines / $body.Count } else { 0 }
      $regions += [pscustomobject]@{
        Start = $start + 1
        End   = $end + 1
        Lines = $body
        CodeRatio = $ratio
      }
    }
    $i = if ($j -le $i) { $i + 1 } else { $j }
  }
  return $regions
}

function Unescape-DocText {
  param([string]$Text)
  $u = [ordered]@{ '\`' = '`'; '\[' = '['; '\]' = ']'; '\_' = '_'; '\*' = '*'; '\>' = '>' }
  foreach ($k in $u.Keys) { $Text = $Text.Replace($k, $u[$k]) }
  return $Text
}

# ---------------------------------------------------------------- gitcode 同步
# gitcode 的匿名 contents API 实测约 100 次快速调用后开始 429（限流），故：自适应间隔 + 递增退避。
# 实测教训：固定 180ms + 4 次退避（合计 20s）在一次大爬里仍会漏掉 6 个子目录，因此改成自适应：
# 一旦遇到 429 就把基础间隔翻倍（上限 3s），成功后缓慢回落；重试次数提到 6 次（最坏累计约 170s）。
$script:GitDelayMs = 180
function Invoke-GitCodeContents {
  param([string]$Owner, [string]$Repo, [string]$Path)
  $suffix = if ([string]::IsNullOrWhiteSpace($Path)) { '' } else { '/' + $Path.Trim('/') }
  $url = "https://gitcode.com/api/v5/repos/$Owner/$Repo/contents$suffix"
  $last = $null
  for ($try = 1; $try -le 6; $try++) {
    try {
      Start-Sleep -Milliseconds $script:GitDelayMs
      $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 40
      $script:GitDelayMs = [Math]::Max(180, [int]($script:GitDelayMs * 0.8))
      return ($resp.Content | ConvertFrom-Json)
    } catch {
      $last = $_
      $msg = $_.Exception.Message
      if ($msg -match '429|Too Many') {
        $script:GitDelayMs = [Math]::Min(3000, $script:GitDelayMs * 2)
        Start-Sleep -Seconds (5 * $try)
        continue
      }
      throw
    }
  }
  throw $last
}

function Get-GitCodeFileText {
  param([string]$DownloadUrl, [string]$Owner, [string]$Repo, [string]$Branch, [string]$Path)
  # 优先 raw 形式（实测 text/plain;charset=UTF-8）；API 给的 download_url 是 blobs/<sha>，实测为 octet-stream。
  $raw = "https://raw.gitcode.com/$Owner/$Repo/raw/$Branch/$Path"
  for ($try = 1; $try -le 3; $try++) {
    try {
      Start-Sleep -Milliseconds 120
      return (Invoke-WebRequest -Uri $raw -UseBasicParsing -TimeoutSec 60).Content
    } catch {
      if ($try -eq 3 -and $DownloadUrl) {
        return (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing -TimeoutSec 60).Content
      }
      Start-Sleep -Seconds $try
    }
  }
}

function Invoke-GitSync {
  param($Entry, [bool]$DoApply)
  $result = [pscustomobject]@{ Ok = $false; Repo = ''; Files = 0; Bytes = 0; Note = ''; Entries = @(); Skipped = @() }
  $owners = @($Entry.owner) + @($Entry.fallbackOwners)
  $ownerUsed = $null
  foreach ($o in $owners) {
    if ([string]::IsNullOrWhiteSpace($o)) { continue }
    try {
      Invoke-GitCodeContents -Owner $o -Repo $Entry.repo -Path $Entry.root | Out-Null
      $ownerUsed = $o
      break
    } catch {
      Write-Warn2 "gitcode 仓库不可用：$o/$($Entry.repo)（$($_.Exception.Message)）"
    }
  }
  if (-not $ownerUsed) {
    $result.Note = "上游不可达：$($owners -join ', ')/$($Entry.repo)"
    return $result
  }
  $rootNorm = if ($Entry.root) { $Entry.root } else { '' }
  $result.Repo = "$ownerUsed/$($Entry.repo)@$($Entry.branch)/$rootNorm"

  if (-not $DoApply) {
    # dry-run：只验证可达性与根目录可列举。递归枚举要走几百次匿名 API，gitcode 约 100 次就 429，
    # 没必要在演练阶段付这个时间；-Apply 时才真正走全树并自行限速重试。
    try {
      $rootItems = @(Invoke-GitCodeContents -Owner $ownerUsed -Repo $Entry.repo -Path $rootNorm)
      $result.Files = @($rootItems | Where-Object { $_.type -eq 'file' }).Count
      $result.Note = "根目录 $($rootItems.Count) 项（dry-run 未递归枚举，-Apply 时实际抓取）"
      $result.Ok = $true
    } catch {
      $result.Note = "根目录列举失败：$($_.Exception.Message)"
    }
    return $result
  }

  $skipped = @()
  $collected = @()
  if ($Entry.includeFiles) {
    # 只取根目录下点名的文件，不要递归整仓
    try {
      $items = @(Invoke-GitCodeContents -Owner $ownerUsed -Repo $Entry.repo -Path $rootNorm)
      foreach ($it in $items) {
        if ($it.type -eq 'file' -and ($Entry.includeFiles -contains $it.name)) { $collected += $it }
      }
    } catch {
      Write-Warn2 "  根目录列举失败：$($_.Exception.Message)"
    }
  } else {
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue('')
    while ($queue.Count -gt 0) {
      $rel = $queue.Dequeue()
      $apiPath = if ($rel -eq '') { $rootNorm } else { "$rootNorm/$rel" }
      try {
        $items = @(Invoke-GitCodeContents -Owner $ownerUsed -Repo $Entry.repo -Path $apiPath)
      } catch {
        # 单个子目录失败不终止整条线：登记后继续
        $skipped += "$apiPath :: $($_.Exception.Message)"
        Write-Warn2 "  跳过 $apiPath（$($_.Exception.Message)）"
        continue
      }
      foreach ($it in $items) {
        if ($it.type -eq 'dir') {
          if ($Entry.excludeDirs -contains $it.name) { continue }
          if ($rootNorm -eq '') { $queue.Enqueue($it.name) }
          else { $queue.Enqueue($it.path.Substring($rootNorm.Length).TrimStart('/')) }
        } elseif ($it.type -eq 'file') {
          $ext = [System.IO.Path]::GetExtension($it.name).ToLowerInvariant()
          if ($Entry.includeExtensions -and ($Entry.includeExtensions -notcontains $ext)) { continue }
          $collected += $it
        }
      }
    }
  }
  $result.Skipped = $skipped

  $plan = @()
  foreach ($it in ($collected | Sort-Object path -Unique)) {
    $rel = if ($Entry.root -eq '') { $it.name } else { $it.path.Substring($Entry.root.Length).TrimStart('/') }
    if ($Entry.PSObject.Properties.Name -contains 'destPrefix' -and $Entry.destPrefix) { $rel = $Entry.destPrefix + '/' + $rel }
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = $it.name }
    $dst = Join-Path (Join-Path $RefRoot "sources\flutter-ohos\$($Entry.repo)") $rel
    $plan += [pscustomobject]@{ Item = $it; Rel = $rel; Dst = $dst; Sha = $it.sha }
  }
  $result.Entries = $plan
  if ($DoApply) {
    $bytes = 0
    $skippedExisting = 0
    foreach ($p in $plan) {
      # -Resume：已存在的文件不再重抓。限流导致上一次有遗漏时，用这个把缺口补上而不必全量重爬。
      if ($script:ResumeSources -and (Test-Path -LiteralPath $p.Dst)) {
        $bytes += (Get-Item -LiteralPath $p.Dst).Length
        $skippedExisting++
        continue
      }
      $txt = Get-GitCodeFileText -DownloadUrl $p.Item.download_url -Owner $ownerUsed -Repo $Entry.repo -Branch $Entry.branch -Path $p.Item.path
      Assert-GeneratedOnly $p.Dst
      Write-TextLfNoBom -Path $p.Dst -Text $txt
      $bytes += (Get-Item -LiteralPath $p.Dst).Length
    }
    if ($skippedExisting -gt 0) { Write-Host "    （-Resume：跳过已存在的 $skippedExisting 个）" }
    $result.Bytes = $bytes
  }
  $result.Files = $plan.Count
  $result.Ok = $true
  return $result
}

# ================================================================ 主流程
Write-Host ''
Write-Host 'Distiller-Skill · build-references' -ForegroundColor Cyan
Write-Host "  SkillRoot : $SkillRoot"
Write-Host "  DocsRoot  : $DocsRoot"
Write-Host "  SdkRoot   : $SdkRoot"
Write-Host "  Profile   : $Profile    Groups: $([string]::Join(',', $GroupPlan))    Tier: $TierPlan    Only: $Only"
Write-Host "  模式      : $(if ($Apply) { 'APPLY（写盘）' } else { 'DRY-RUN（不落盘）' })"
Write-Host ''

if (-not (Test-Path -LiteralPath $DocsRoot)) {
  Write-Bad "文档库不存在：$DocsRoot"
  Write-Host ''
  Write-Host '  修复方式（任选其一）：'
  Write-Host '    1) 先跑一次 devecocli 让文档库初始化：  devecocli docs catalog'
  Write-Host '    2) 若文档库在别处，显式指定：          .\build-references.ps1 -DocsRoot "<路径>"'
  Write-Host ''
  exit 2
}

$Fp = Get-DocsFingerprint
Write-Host "文档库指纹：.version=$($Fp.storeVersion)  devecocli=$($Fp.cliVersion)  indexVersion=$($Fp.indexVersion)"
Write-Host "            docsZipSha256=$($Fp.docsZipSha256)"
Write-Host "            builtAt=$($Fp.builtAtLocal)  md=$($Fp.mdCount) 体=$(Format-Size $Fp.mdBytes)"
Write-Host ''

$Index = Get-DocsIndex
$AllDocs = Get-AllDocs -Index $Index

# ---------- 解析 official ----------
$entries = @()
if ($Only -eq 'all' -or $Only -eq 'official') { $entries = @(Select-OfficialEntries) }

$rows = @()
$needCopy = @()
$ambiguous = @()
foreach ($e in $entries) {
  if ($e.kind -eq 'dir') {
    $r = Resolve-DirEntry -Entry $e
    $label = "dir  $($e.catalog)/$($e.path)"
  } else {
    $r = Resolve-DocEntry -Entry $e -Index $Index -AllDocs $AllDocs
    $label = "doc  $($e.catalog)/$($e.path)/$($e.slug)"
  }
  if ($r.Ok) {
    if ($e.kind -eq 'dir') {
      $files = @(Get-ChildItem -LiteralPath $r.Dir -Recurse -File -Filter *.md)
      $relBase = Get-RelUnder (Join-Path $DocsRoot $e.catalog) $r.Dir
      $docId = "$($e.catalog)/$relBase"
      $rows += [pscustomobject]@{
        Group = $e.group; Tier = $e.tier; Catalog = $e.catalog; Kind = 'dir'
        DocumentId = $docId; Files = $files.Count; Bytes = ($files | Measure-Object Length -Sum).Sum
        Level = $r.Level; Why = $e.why; Ok = $true; Status = '命中'
      }
      $needCopy += [pscustomobject]@{ Kind = 'dir'; Src = $r.Dir; Cat = $e.catalog; Rel = $relBase; Group = $e.group }
    } else {
      $rel = Get-RelUnder (Join-Path $DocsRoot $e.catalog) $r.File.FullName
      $rows += [pscustomobject]@{
        Group = $e.group; Tier = $e.tier; Catalog = $e.catalog; Kind = 'doc'
        DocumentId = "$($e.catalog)/$($rel -replace '\.md$','')"; Files = 1
        Bytes = $r.File.Length; Level = $r.Level; Why = $e.why; Ok = $true; Status = '命中'
      }
      $needCopy += [pscustomobject]@{ Kind = 'doc'; Src = $r.File.FullName; Cat = $e.catalog; Rel = $rel; Group = $e.group }
    }
  } elseif ($r.Missing) {
    $rows += [pscustomobject]@{
      Group = $e.group; Tier = $e.tier; Catalog = $e.catalog; Kind = $e.kind
      DocumentId = if ($e.kind -eq 'dir') { "$($e.catalog)/$($e.path)" } else { "$($e.catalog)/$($e.path)/$($e.slug)" }
      Files = 0; Bytes = 0; Level = ''; Why = $e.why; Ok = $false; Status = 'MISSING'
    }
  } else {
    $cands = @($r.Ambiguous | ForEach-Object { $_.FullName })
    $ambiguous += [pscustomobject]@{ Label = $label; Candidates = $cands }
    $rows += [pscustomobject]@{
      Group = $e.group; Tier = $e.tier; Catalog = $e.catalog; Kind = $e.kind
      DocumentId = if ($e.kind -eq 'dir') { "$($e.catalog)/$($e.path)" } else { "$($e.catalog)/$($e.path)/$($e.slug)" }
      Files = 0; Bytes = 0; Level = ''; Why = $e.why; Ok = $false; Status = "AMBIGUOUS($($cands.Count))"
    }
  }
}

if ($entries.Count -gt 0) {
  Write-Host "official：清单 $($entries.Count) 条 -> 命中 $(@($rows | Where-Object { $_.Ok }).Count) 条"
  $totF = ($rows | Where-Object { $_.Ok } | Measure-Object Files -Sum).Sum
  $totB = ($rows | Where-Object { $_.Ok } | Measure-Object Bytes -Sum).Sum
  Write-Host "          文件 $totF 篇 / $(Format-Size $totB)"
  foreach ($g in @('main', 'ui', 'web', 'seven')) {
    $gr = @($rows | Where-Object { $_.Ok -and $_.Group -eq $g })
    if ($gr.Count -eq 0) { continue }
    $gf = ($gr | Measure-Object Files -Sum).Sum
    $gb = ($gr | Measure-Object Bytes -Sum).Sum
    Write-Host ("          [{0,-6}] {1,3} 条  {2,5} 篇  {3}" -f $g, $gr.Count, $gf, (Format-Size $gb))
  }
  $miss = @($rows | Where-Object { -not $_.Ok })
  if ($miss.Count -gt 0) {
    Write-Warn2 "未命中 $($miss.Count) 条："
    foreach ($m in $miss) { Write-Warn2 "  [$($m.Group)/$($m.Status)] $($m.DocumentId)" }
  }
  if ($ambiguous.Count -gt 0) {
    Write-Bad "歧义 $($ambiguous.Count) 处（不猜，直接退出）："
    foreach ($a in $ambiguous) {
      Write-Bad "  $($a.Label)"
      foreach ($c in $a.Candidates) { Write-Bad "      $c" }
    }
  }
}

# ---------- core 必须 0 MISSING ----------
$coreMiss = @($rows | Where-Object { -not $_.Ok -and $_.Tier -eq 'core' })
if ($coreMiss.Count -gt 0) {
  Write-Bad "tier=core 有 $($coreMiss.Count) 条未命中，按约定失败退出。"
  exit 3
}
if ($ambiguous.Count -gt 0) { exit 4 }

Write-Host ''

# ---------- FingerprintOnly ----------
if ($FingerprintOnly) {
  $fpRows = @()
  foreach ($c in $needCopy) {
    if ($c.Kind -eq 'doc') {
      $fpRows += [pscustomobject]@{ rel = "$($c.Cat)/$($c.Rel -replace '\\','/')"; sha256 = (Get-Sha256 $c.Src); bytes = (Get-Item -LiteralPath $c.Src).Length }
    } else {
      foreach ($f in (Get-ChildItem -LiteralPath $c.Src -Recurse -File -Filter *.md)) {
        $rel = Get-RelUnder $c.Src $f.FullName
        $fpRows += [pscustomobject]@{ rel = "$($c.Cat)/$($c.Rel)/$($rel -replace '\\','/')"; sha256 = (Get-Sha256 $f.FullName); bytes = $f.Length }
      }
    }
  }
  $out = [pscustomobject]@{ fingerprint = $Fp; entries = $fpRows; count = $fpRows.Count }
  $ver = if ($Fp.storeVersion) { $Fp.storeVersion } else { 'unknown' }
  $target = Join-Path (Join-Path $RefRoot 'official') "_provenance-$ver.json"
  Write-Host "指纹文件条目数：$($fpRows.Count)"
  if ($Apply) {
    Assert-GeneratedOnly $target
    Write-TextLfNoBom -Path $target -Text ($out | ConvertTo-Json -Depth 6)
    Write-Ok "写入 $target"
  } else {
    Write-Host "  演练：将写入 $target"
  }
  exit 0
}

# ---------- Check ----------
if ($Check) {
  # -Against 可指定一份历史指纹（_provenance-<版本>.json），用来回答「跨版本官方改了什么」。
  $provPath = if ($Against) { $Against } else { Join-Path (Join-Path $RefRoot 'official') '_provenance.json' }
  if (-not (Test-Path -LiteralPath $provPath)) {
    Write-Bad "找不到 $provPath，先跑一次 -Apply，或用 -Against 指定一份历史指纹。"
    exit 5
  }
  $prev = (Read-TextRaw $provPath) | ConvertFrom-Json
  Write-Host '=== 指纹比对 ==='
  $keys = @('storeVersion', 'cliVersion', 'indexVersion', 'docsZipSha256', 'mdCount')
  foreach ($k in $keys) {
    $a = $prev.fingerprint.$k; $b = $Fp.$k
    $mark = if ("$a" -eq "$b") { 'same' } else { 'CHANGED' }
    Write-Host ("  {0,-16} {1,-12} -> {2,-12}  {3}" -f $k, "$a", "$b", $mark)
  }
  Write-Host ''
  Write-Host '=== 逐文件 sha256 比对 ==='
  $old = @{}
  $prevItems = if ($prev.PSObject.Properties.Name -contains 'files') { $prev.files } else { $prev.entries }
  foreach ($e in $prevItems) { $old[$e.rel] = $e.sha256 }
  $changed = @(); $gone = @(); $curr = @{}
  foreach ($c in $needCopy) {
    if ($c.Kind -eq 'doc') {
      $rel = "$($c.Cat)/$($c.Rel -replace '\\','/')"; $curr[$rel] = (Get-Sha256 $c.Src)
    } else {
      foreach ($f in (Get-ChildItem -LiteralPath $c.Src -Recurse -File -Filter *.md)) {
        $rel = "$($c.Cat)/$($c.Rel)/$((Get-RelUnder $c.Src $f.FullName) -replace '\\','/')"; $curr[$rel] = (Get-Sha256 $f.FullName)
      }
    }
  }
  foreach ($k in $curr.Keys) {
    if (-not $old.ContainsKey($k)) { $changed += "新增 $k" }
    elseif ($old[$k] -ne $curr[$k]) { $changed += "变更 $k" }
  }
  foreach ($k in $old.Keys) { if (-not $curr.ContainsKey($k)) { $gone += $k } }
  Write-Host "  变更/新增 $($changed.Count) 个："
  foreach ($c in ($changed | Select-Object -First 60)) { Write-Host "    $c" }
  if ($changed.Count -gt 60) { Write-Host "    …（其余 $($changed.Count - 60) 个见 10-漂移报告.md）" }
  Write-Host "  消失 $($gone.Count) 个："
  foreach ($g in ($gone | Select-Object -First 60)) { Write-Host "    $g" }
  Write-Host ''
  Write-Host "  清单条目当前未命中 $(@($rows | Where-Object { -not $_.Ok }).Count) 条"
  if ($Apply) {
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<!-- 生成物：由 tools\build-references.ps1 -Check 产出，勿手改 -->')
    [void]$sb.AppendLine(''); [void]$sb.AppendLine('# 10 · 漂移报告（-Check）'); [void]$sb.AppendLine('')
    [void]$sb.AppendLine("生成时间：$(Get-Date -Format 's')"); [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## 指纹比对'); [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| 项 | 旧 | 新 |'); [void]$sb.AppendLine('| :-- | :-- | :-- |')
    foreach ($k in $keys) { [void]$sb.AppendLine("| $k | ``$($prev.fingerprint.$k)`` | ``$($Fp.$k)`` |") }
    [void]$sb.AppendLine(''); [void]$sb.AppendLine("## 变更/新增文件（$($changed.Count)）"); [void]$sb.AppendLine('')
    foreach ($c in $changed) { [void]$sb.AppendLine("- $c") }
    [void]$sb.AppendLine(''); [void]$sb.AppendLine("## 消失文件（$($gone.Count)）"); [void]$sb.AppendLine('')
    foreach ($g in $gone) { [void]$sb.AppendLine("- ``$g``") }
    Write-TextLfNoBom -Path (Join-Path $RefRoot '10-漂移报告.md') -Text $sb.ToString()
      Write-Ok '写入 10-漂移报告.md'
  }
  exit 0
}

# ---------- Revalidate ----------
if ($Revalidate) {
  Write-Host '=== Revalidate：回扫 03-能力速查.md / 06-未取证清单.md ==='
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('<!-- 生成物：由 tools\build-references.ps1 -Revalidate 产出，勿手改 -->')
  [void]$sb.AppendLine(''); [void]$sb.AppendLine('# 11 · 复核报告（-Revalidate）'); [void]$sb.AppendLine('')
  [void]$sb.AppendLine("基于文档库：.version=$($Fp.storeVersion) / docsZipSha256=$($Fp.docsZipSha256)"); [void]$sb.AppendLine('')

  # slug -> 该 slug 是否在库中（一次建索引，避免 ids x 14125 次线性扫描）
  $slugIndex = @{}
  foreach ($f in $AllDocs) { $slugIndex[$f.Name] = $true }

  foreach ($doc in @('03-能力速查.md', '06-未取证清单.md')) {
    $p = Join-Path $RefRoot $doc
    [void]$sb.AppendLine("## $doc"); [void]$sb.AppendLine('')
    if (-not (Test-Path -LiteralPath $p)) {
      [void]$sb.AppendLine('（文件不存在，跳过）'); [void]$sb.AppendLine(''); continue
    }
    $txt = Read-TextRaw $p
    $ids = [regex]::Matches($txt, '[`【\[]((开发指南|API参考|最佳实践|FAQ|版本说明|变更预告)/[^\s`】\]]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    [void]$sb.AppendLine("引用的 documentId 共 $($ids.Count) 条："); [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| documentId | 本地是否存在 |'); [void]$sb.AppendLine('| :-- | :-- |')
    foreach ($id in $ids) {
      $slug = ($id.Split('/')[-1])
      $mark = if ($slugIndex.ContainsKey($slug + '.md')) { '在' } else { '**不在**' }
      [void]$sb.AppendLine("| ``$id`` | $mark |")
    }
    [void]$sb.AppendLine('')
  }

  [void]$sb.AppendLine('## 未取证关键词回扫'); [void]$sb.AppendLine('')
  $kw = @(
    @('OCR 宽高比', '宽高比'),
    @('OCR 像素总量上限', '像素'),
    @('ASR 与 AudioCapturer 联用', 'AudioCapturer'),
    @('INTERNET 权限是否必需', 'INTERNET'),
    @('分享 uri 读取权限', 'FLAG_AUTH_READ_URI_PERMISSION'),
    @('maxFileSupported 上限', 'maxFileSupported'),
    @('AGC HTTP 触发器公网可达', '触发器'),
    @('云函数免费额度具体数字', '免费额度')
  )
  # 每个文件只读一次，8 个关键词一次扫完（否则是 8 x 14125 次磁盘读取）
  $hits = @{}
  foreach ($k in $kw) { $hits[$k[1]] = 0 }
  Write-Host "  回扫 $($AllDocs.Count) 个文件…"
  foreach ($f in $AllDocs) {
    try {
      $t = Read-TextRaw $f.FullName
      foreach ($k in $kw) { if ($t.Contains($k[1])) { $hits[$k[1]] = $hits[$k[1]] + 1 } }
    } catch { }
  }
  [void]$sb.AppendLine('| 未取证项 | 关键词 | 库内命中页数 |'); [void]$sb.AppendLine('| :-- | :-- | --: |')
  foreach ($k in $kw) { [void]$sb.AppendLine("| $($k[0]) | ``$($k[1])`` | $($hits[$k[1]]) |") }
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('> 命中页数 > 0 只说明**官方文档里有相关内容**，不等于原先的未取证项已被回答。请打开具体页面确认后再改 `06-未取证清单.md`。')
  [void]$sb.AppendLine('')

  if ($Apply) {
    Write-TextLfNoBom -Path (Join-Path $RefRoot '15-复核报告.md') -Text $sb.ToString()
    Write-Ok '写入 15-复核报告.md'
  } else {
    Write-Host $sb.ToString()
  }
  exit 0
}

# ---------- Apply：official / project / sources / sdk / samples ----------
$planFiles = 0
$planBytes = 0
$provFiles = @()

if ($Only -eq 'all' -or $Only -eq 'official') {
  Write-Host '--- official ---'
  foreach ($c in $needCopy) {
    if ($c.Kind -eq 'doc') {
      $dst = Join-Path (Join-Path $RefRoot "official\$($c.Cat)") $c.Rel
      $planFiles++; $planBytes += (Get-Item -LiteralPath $c.Src).Length
      if ($Apply) { Copy-FileVerbatim -Src $c.Src -Dst $dst }
      $provFiles += [pscustomobject]@{ rel = "$($c.Cat)/$($c.Rel -replace '\\','/')"; sha256 = (Get-Sha256 $c.Src); bytes = (Get-Item -LiteralPath $c.Src).Length }
    } else {
      foreach ($f in (Get-ChildItem -LiteralPath $c.Src -Recurse -File -Filter *.md)) {
        $rel = Get-RelUnder $c.Src $f.FullName
        $dst = Join-Path (Join-Path $RefRoot "official\$($c.Cat)") (Join-Path $c.Rel $rel)
        $planFiles++; $planBytes += $f.Length
        if ($Apply) { Copy-FileVerbatim -Src $f.FullName -Dst $dst }
        $provFiles += [pscustomobject]@{ rel = "$($c.Cat)/$($c.Rel)/$($rel -replace '\\','/')"; sha256 = (Get-Sha256 $f.FullName); bytes = $f.Length }
      }
    }
  }
  Write-Host "  官方文档：$planFiles 篇 / $(Format-Size $planBytes)"

  # ---- 陈旧文件清理 ----
  # 默认只报告不删除（安全），因为清单小改时残留无害。但**跨文档版本**时（例如 1.2.0 → 1.3.4
  # 有 86 篇消失），残留会让 official\ 变成新旧混合体，比任何单一版本都糟。所以给一个显式开关。
  $officialRoot = Join-Path $RefRoot 'official'
  if (Test-Path -LiteralPath $officialRoot) {
    $intended = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($c in $needCopy) {
      if ($c.Kind -eq 'doc') { [void]$intended.Add([System.IO.Path]::GetFullPath((Join-Path $officialRoot "$($c.Cat)\$($c.Rel)"))) }
      else {
        foreach ($f in (Get-ChildItem -LiteralPath $c.Src -Recurse -File -Filter *.md)) {
          [void]$intended.Add([System.IO.Path]::GetFullPath((Join-Path $officialRoot "$($c.Cat)\$($c.Rel)\$(Get-RelUnder $c.Src $f.FullName)")))
        }
      }
    }
    $stale = @()
    foreach ($f in (Get-ChildItem -LiteralPath $officialRoot -Recurse -File)) {
      if ($f.Name -like '_provenance*') { continue }   # 指纹文件保留
      if (-not $intended.Contains([System.IO.Path]::GetFullPath($f.FullName))) { $stale += $f }
    }
    if ($stale.Count -gt 0) {
      Write-Warn2 "陈旧文件 $($stale.Count) 个（在 official\ 里但不在本清单解析结果里）"
      foreach ($s in ($stale | Select-Object -First 12)) { Write-Warn2 "    $($s.FullName.Substring($officialRoot.Length + 1))" }
      if ($stale.Count -gt 12) { Write-Warn2 "    …（其余 $($stale.Count - 12) 个）" }
      if ($Prune) {
        foreach ($s in $stale) { Remove-Item -LiteralPath $s.FullName -Force }
        # 删掉空目录
        Get-ChildItem -LiteralPath $officialRoot -Recurse -Directory |
          Sort-Object { $_.FullName.Length } -Descending |
          ForEach-Object { if (@(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0) { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue } }
        Write-Ok "  已清理 $($stale.Count) 个陈旧文件（-Prune）"
      } else {
        Write-Warn2 "  只报告不删除。确认要清掉就加 -Prune："
        Write-Warn2 "    powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Only official -Apply -Prune"
      }
    }
  }
}

if (($Only -eq 'all' -or $Only -eq 'project') -and $Manifest.project) {
  Write-Host '--- project ---'
  $pn = 0; $pb = 0
  foreach ($e in $Manifest.project) {
    if (-not (Test-Path -LiteralPath $e.src)) { Write-Warn2 "源缺失，跳过：$($e.src)"; continue }
    $dstRoot = Join-Path (Join-Path $RefRoot 'project') $e.dst
    if ($e.kind -eq 'dir') {
      foreach ($f in (Get-ChildItem -LiteralPath $e.src -Recurse -File)) {
        $rel = Get-RelUnder $e.src $f.FullName
        $planFiles++; $pn++; $pb += $f.Length; $planBytes += $f.Length
        if ($Apply) { Copy-FileVerbatim -Src $f.FullName -Dst (Join-Path $dstRoot $rel) }
      }
    } else {
      $sz = (Get-Item -LiteralPath $e.src).Length
      $planFiles++; $pn++; $pb += $sz; $planBytes += $sz
      if ($Apply) { Copy-FileVerbatim -Src $e.src -Dst $dstRoot }
    }
  }
  Write-Host "  调研文档：$pn 个 / $(Format-Size $pb)"

  # 这些镜像里嵌了**生成机器的绝对路径**（SDK 根、文档库根），它们是原文的行号引用锚点。
  # 换机器后那些路径解析不了，所以随镜像写一份来源说明，别让人以为路径错了。
  $projReadme = @()
  $projReadme += '<!-- 生成物：由 tools\build-references.ps1 产出，勿手改 -->'
  $projReadme += ''
  $projReadme += '# 调研文档镜像 · 来源与已知限制'
  $projReadme += ''
  $projReadme += "生成时间：$((Get-Date).ToString('s'))"
  $projReadme += ''
  $projReadme += '这里是 `Distiller-DOC\` 与 Distiller 仓库里调研材料的**逐字节镜像**（权威源不在这里，改这里会被下次同步覆盖）。'
  $projReadme += ''
  $projReadme += '## 换机器时要注意的两件事'
  $projReadme += ''
  $projReadme += '1. **里面的绝对路径是生成这份镜像的机器上的路径**（形如 `D:\Coding\DevEco\...`、`C:\Users\<你>\...`）。'
  $projReadme += '   它们原本是"行号引用锚点"，用来精确指到 SDK 头文件或文档库的某一行。**换机器后解析不了是正常的**，'
  $projReadme += '   按 `references/01-项目基线.md` §1.1 探测出你自己的 SDK 根，做同样的路径替换即可。'
  $projReadme += '2. **行号会随 SDK 版本漂移**。`references/08-SDK签名索引.md` 是拿本机 SDK 重新生成的，以它为准；'
  $projReadme += '   镜像里的行号只代表取证当时的版本。重跑一条命令即可刷新：'
  $projReadme += ''
  $projReadme += '   ```powershell'
  $projReadme += '   powershell -NoProfile -ExecutionPolicy Bypass -File tools\build-references.ps1 -Only sdk -Apply'
  $projReadme += '   ```'
  $projReadme += ''
  $projReadme += '## 内容清单'
  $projReadme += ''
  $projReadme += '| 文件 | 说明 |'
  $projReadme += '| :-- | :-- |'
  foreach ($e in $Manifest.project) {
    $why = if ($e.PSObject.Properties.Name -contains 'why') { $e.why } else { '' }
    $projReadme += "| ``$($e.dst -replace '\\','/')`` | $why |"
  }
  $projReadme += ''
  if ($Apply) { Write-TextLfNoBom -Path (Join-Path (Join-Path $RefRoot 'project') '_README.md') -Text ([string]::Join("`n", $projReadme) + "`n") }
}

if (($Only -eq 'all' -or $Only -eq 'sources') -and $Manifest.git) {
  Write-Host '--- sources (gitcode) ---'
  $gitProv = @()
  foreach ($g in $Manifest.git) {
    if ($GroupPlan -notcontains $g.group) { continue }
    $r = Invoke-GitSync -Entry $g -DoApply ([bool]$Apply)
    if ($r.Ok) {
      Write-Host "  $($r.Repo) : $($r.Files) 篇 / $(Format-Size $r.Bytes)"
      $planFiles += $r.Files; $planBytes += $r.Bytes
      foreach ($p in $r.Entries) { $gitProv += [pscustomobject]@{ repo = $r.Repo; path = $p.Rel; sha = $p.Sha } }
    } else {
      Write-Warn2 $r.Note
      $gitProv += [pscustomobject]@{ repo = "$($g.owner)/$($g.repo)"; path = '(unreachable)'; sha = $null }
    }
  }
  $global:GitProv = $gitProv
}

if ($Only -eq 'all' -or $Only -eq 'sdk') {
  Write-Host '--- sdk ---'
  if ([string]::IsNullOrWhiteSpace($SdkRoot) -or -not (Test-Path -LiteralPath $SdkRoot)) {
    Write-Warn2 "未找到 SDK 根，跳过这一条产出线（其余产出线不受影响）。"
    Write-Warn2 "  探测方法见脚本开头注释，或显式指定：-SdkRoot <SDK 根>"
    Write-Warn2 "  注意：08-SDK签名索引.md 里的行号绑定**本机 SDK 版本**，不同机器/不同 SDK 版本的行号会不同。"
  } else {
    $doc = New-SdkIndexDoc -SdkEntries $Manifest.sdk -SdkRootPath $SdkRoot -Fp $Fp
    $anchors = @(
      'L147: function getEntity(text: string, entityConfig?: EntityConfig): Promise<Array<Entity>>;',
      'L115: onDestroy(): void | Promise<void>;'
    )
    $bad = @()
    foreach ($a in $anchors) { if ($doc -notmatch [regex]::Escape($a)) { $bad += $a } }
    if ($bad.Count -gt 0) {
      Write-Bad 'SDK 索引自检断言失败，产物未写入：'
      foreach ($b in $bad) { Write-Bad "  期望包含：$b" }
      exit 6
    }
    Write-Ok '  自检断言通过（@hms.ai.nlp.textProcessing.d.ts:147 / @ohos.app.ability.UIExtensionAbility.d.ts:115）'
    $out = Join-Path $RefRoot '08-SDK签名索引.md'
    if ($Apply) { Write-TextLfNoBom -Path $out -Text $doc; Write-Ok "  写入 $out（$(Format-Size (Get-Item -LiteralPath $out).Length)）" }
    else { Write-Host "  演练：将写入 $out（约 $(Format-Size $doc.Length)）" }
  }
}

if ($Only -eq 'all' -or $Only -eq 'samples' -or $ExtractSamples) {
  if ($ExtractSamples -or $Only -eq 'samples') {
    Write-Host '--- samples ---'
    $n = 0
    $sampleRows = @()
    foreach ($s in $Manifest.samples.sources) {
      $base = Join-Path (Join-Path $DocsRoot $s.catalog) $s.path
      $src = Join-Path $base ($s.slug + '.md')
      # 文档重组会让示例源换位置（1.3.4 就把「沉浸光感」拆成了 4 页）。所以按和 official 一样的思路降级：
      # ① 精确路径 → ② aliases → ③ catalog 全树同 slug 唯一 → ④ 全库同 slug 唯一。
      if (-not (Test-Path -LiteralPath $src)) {
        $alt = @()
        if ($s.PSObject.Properties.Name -contains 'aliases' -and $s.aliases) { $alt = @($s.aliases) }
        foreach ($w in $alt) {
          $c = Join-Path $base ($w + '.md')
          if (Test-Path -LiteralPath $c) { $src = $c; break }
        }
      }
      if (-not (Test-Path -LiteralPath $src)) {
        $pool = @(Get-ChildItem -LiteralPath (Join-Path $DocsRoot $s.catalog) -Recurse -File -Filter ($s.slug + '.md') -ErrorAction SilentlyContinue)
        if ($pool.Count -eq 0) { $pool = @(Get-ChildItem -LiteralPath $DocsRoot -Recurse -File -Filter ($s.slug + '.md') -ErrorAction SilentlyContinue) }
        if ($pool.Count -eq 1) {
          $src = $pool[0].FullName
          Write-Warn2 "示例源按 slug 全树回退命中：$($s.slug) -> $($src.Substring($DocsRoot.Length + 1))"
        }
      }
      if (-not (Test-Path -LiteralPath $src)) { Write-Warn2 "示例源缺失，跳过：$($s.catalog)/$($s.path)/$($s.slug)"; continue }
      $lines = [System.IO.File]::ReadAllLines($src)
      # 必须包 @()：函数返回单元素数组时 PowerShell 会拆成标量，标量的 .Count 在 5.1 下不可靠
      $regions = @(Get-ExampleRegions -Lines $lines)
      if ($regions.Count -eq 0) { Write-Warn2 "未检出示例区：$($s.slug)"; continue }
      $take = @($regions | Select-Object -First ([int]$Manifest.samples.maxBlocksPerPage))
      Write-Host "  $($s.name)：检出 $($regions.Count) 区，取 $($take.Count)（代码占比 $(($take | ForEach-Object { [int]($_.CodeRatio*100) }) -join '%, ')%）"
      $docId = "$($s.catalog)/$($s.path)/$($s.slug)"
      $idx = 0
      foreach ($r in $take) {
        $idx++
        $body = @()
        $body += "// 来源：documentId = $docId"
        $body += "// 行范围：L$($r.Start)-L$($r.End)"
        $body += "// 生成物：tools\build-references.ps1 -ExtractSamples，勿手改"
        $body += "// 注意：官方文档原文摘录，可能夹杂说明行；官方示例常省略 import 与上下文，不保证独立可编译"
        $body += ''
        foreach ($ln in (Unescape-DocText -Text ([string]::Join("`n", $r.Lines))) -split "`n") { $body += $ln }
        $dst = Join-Path (Join-Path (Join-Path $RefRoot 'examples') $s.name) ('{0:d2}.ets' -f $idx)
        $rel = "examples/$($s.name)/$('{0:d2}.ets' -f $idx)"
        $n++
        $text = [string]::Join("`n", $body) + "`n"
        $planFiles++
        $planBytes += [System.Text.Encoding]::UTF8.GetByteCount($text)
        $sampleRows += [pscustomobject]@{
          Name = $s.name; File = $rel; DocumentId = $docId
          Start = $r.Start; End = $r.End; CodeRatio = [int]($r.CodeRatio * 100)
        }
        if ($Apply) { Write-TextLfNoBom -Path $dst -Text $text }
      }
    }
    Write-Host "  示例块合计：$n"

    # examples/INDEX.md —— 让每个示例块都能反查回官方原文的行号
    $isb = New-Object System.Text.StringBuilder
    [void]$isb.AppendLine('<!-- 生成物：由 tools\build-references.ps1 -ExtractSamples 产出，勿手改 -->')
    [void]$isb.AppendLine('')
    [void]$isb.AppendLine('# 示例索引')
    [void]$isb.AppendLine('')
    [void]$isb.AppendLine("共 $($sampleRows.Count) 个示例块，取自 $((@($sampleRows | Group-Object Name)).Count) 个官方页面。")
    [void]$isb.AppendLine('')
    [void]$isb.AppendLine('> **这些是官方文档的原文摘录，不是可编译的完整文件。** 每个文件头注释里写了来源 `documentId` 与行范围，')
    [void]$isb.AppendLine('> 可以回 `references/official/` 的同名路径核对。「代码占比」是抽取器估计的代码行比例：')
    [void]$isb.AppendLine('> 低于 ~50% 的块里夹着说明文字，抄之前先看一眼。**官方示例常省略 import 与上下文，不保证独立可编译。**')
    [void]$isb.AppendLine('')
    [void]$isb.AppendLine('| 能力 / 主题 | 文件 | 源行范围 | 代码占比 | 来源 documentId |')
    [void]$isb.AppendLine('| :-- | :-- | :-- | --: | :-- |')
    foreach ($row in ($sampleRows | Sort-Object Name, File)) {
      [void]$isb.AppendLine("| $($row.Name) | ``$($row.File)`` | L$($row.Start)-L$($row.End) | $($row.CodeRatio)% | ``$($row.DocumentId)`` |")
    }
    [void]$isb.AppendLine('')
    $idxPath = Join-Path (Join-Path $RefRoot 'examples') 'INDEX.md'
    if ($Apply) { Write-TextLfNoBom -Path $idxPath -Text $isb.ToString(); Write-Ok '写入 examples/INDEX.md' }
    else { Write-Host '  演练：将写入 examples/INDEX.md' }
  }
}

# ---------- 07 / provenance ----------
if ($Only -eq 'all' -or $Only -eq 'official') {
  $idx = New-IndexDoc -Rows $rows -Fp $Fp
  $p7 = Join-Path $RefRoot '07-官方文档索引.md'
  if ($Apply) { Write-TextLfNoBom -Path $p7 -Text $idx; Write-Ok "写入 07-官方文档索引.md" } else { Write-Host "  演练：将写入 07-官方文档索引.md（$($rows.Count) 行）" }

  $prov = [pscustomobject]@{
    skill              = $Manifest.skillName
    generatedAt        = (Get-Date).ToString('s')
    profile            = $Profile
    groups             = $GroupPlan
    tier               = $TierPlan
    fingerprint        = $Fp
    files              = $provFiles
    fileCount          = $provFiles.Count
    fileBytes          = ($provFiles | Measure-Object bytes -Sum).Sum
    missing            = @($rows | Where-Object { -not $_.Ok } | ForEach-Object { [pscustomobject]@{ group = $_.Group; documentId = $_.DocumentId; status = $_.Status } })
    git                = if ($global:GitProv) { $global:GitProv } else { @() }
  }
  $pp = Join-Path (Join-Path $RefRoot 'official') '_provenance.json'
  if ($Apply) { Write-TextLfNoBom -Path $pp -Text ($prov | ConvertTo-Json -Depth 6); Write-Ok "写入 _provenance.json（$($provFiles.Count) 个文件条目）" }
  else { Write-Host "  演练：将写入 _provenance.json（$($provFiles.Count) 个文件条目）" }
}

Write-Host ''
Write-Host "合计：$planFiles 篇 / $(Format-Size $planBytes)" -ForegroundColor Cyan
if ($Apply) { Write-Ok '完成。' } else { Write-Host '演练结束（未写入任何文件）。确认无误后加 -Apply。' -ForegroundColor Yellow }
