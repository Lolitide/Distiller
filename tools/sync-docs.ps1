<#
.SYNOPSIS
  把权威源文档（Distiller-DOC）同步进仓库的 docs\ 目录。

.DESCRIPTION
  权威源：E:\Program_File\HMOS_proj\Distiller-DOC\
  仓库副本：<仓库根>\docs\

  同步过程中做两处与「仓库内路径」有关的改写，改写是幂等的：

  1. 给 `开发指南.md` 与 `99-附录-取证台账.md` 的 frontmatter 之后插一行
     HTML 注释，声明这是同步副本、权威源在哪。
  2. 把正文里裸写的 `99-附录-取证台账.md` 改写成 `docs/99-附录-取证台账.md`，
     因为仓库里它是 docs/ 的子文件。已经是 `docs/...` 或 `../docs/...` 的不动。

  默认 dry-run：只报告会写哪些文件，不落盘。确认后加 -Apply 才真的写。

.PARAMETER Apply
  真正写入。不加这个开关就只做演练。

.PARAMETER Source
  权威源目录，默认 E:\Program_File\HMOS_proj\Distiller-DOC。

.PARAMETER RepoRoot
  仓库根目录，默认本脚本所在目录的上一级。

.EXAMPLE
  pwsh -File tools\sync-docs.ps1            # 演练
  pwsh -File tools\sync-docs.ps1 -Apply     # 落盘

.NOTES
  只读源、只写仓库副本，不会反向覆盖权威源。
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [string]$Source = '',
  [string]$RepoRoot = ''
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# 默认值在 param 之后解析：Windows PowerShell 5.1 用 -File 启动时，参数绑定阶段
# $PSScriptRoot 还是空串，写在 param 默认值里会直接报错。
if ([string]::IsNullOrWhiteSpace($RepoRoot)) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($Source)) { $Source = Join-Path (Split-Path -Parent $RepoRoot) 'Distiller-DOC' }

if (-not (Test-Path -LiteralPath $Source)) { throw "权威源不存在：$Source" }
$dstRoot = Join-Path $RepoRoot 'docs'
if (-not (Test-Path -LiteralPath $dstRoot)) { throw "仓库 docs 目录不存在：$dstRoot" }

$mirrorMarker = '<!-- 本文件是镜像副本：权威源为 Distiller-DOC\ 下的同名文件，改动请改源文件后运行 tools\sync-docs.ps1 回灌，不要直接编辑本副本。 -->'
$bareLedger = '99-附录-取证台账.md'
$bareLedgerRe = '(?<![/\\])99-附录-取证台账\.md'

# 注意：不能用 function 返回 List[string]。PowerShell 在 return 时会把集合展开成
# 定长 Object[]，后面的 Insert 就会报「Collection was of a fixed size」。
# 所以取行与改写都写成内联循环，让 $lines 始终是同一个可变 List。

# ---- 根级文档：frontmatter 后插镜像声明，并改写裸写的台账文件名 ----
foreach ($name in @('开发指南.md', '99-附录-取证台账.md')) {
  $src = Join-Path $Source $name
  if (-not (Test-Path -LiteralPath $src)) { Write-Warning "源文件缺失，跳过：$src"; continue }

  # 用 ReadAllText 按 LF 拆分、按 LF 拼回。用 Get-Content 的话，Windows PowerShell 5.1
  # 会把行按 CRLF 处理、写出时再把换行变成 CRLF，源文件与副本就对不上字节了。
  $text = [System.IO.File]::ReadAllText($src)
  $rawLines = $text -split "`r?`n"
  # 结尾换行会多切出一个空串，去掉它，写回时在末尾补一个新行
  if ($rawLines.Count -gt 0 -and $rawLines[-1] -eq '') { $rawLines = $rawLines[0..($rawLines.Count - 2)] }
  $lines = [System.Collections.Generic.List[string]]::new()
  $rawLines | ForEach-Object { $lines.Add($_) }

  $hits = ([regex]::Matches($text, $bareLedgerRe)).Count

  if ($lines.Count -eq 0 -or $lines[0] -ne '---') { throw "$name 开头没有 frontmatter，无法定位插入点" }
  $end = -1
  for ($i = 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -eq '---') { $end = $i; break } }
  if ($end -lt 0) { throw "$name 的 frontmatter 没有闭合的 ---" }
  $lines.Insert($end + 1, '')
  $lines.Insert($end + 2, $mirrorMarker)

  $out = ((($lines -join "`n") -replace $bareLedgerRe, "docs/$bareLedger") -replace "`r", '') + "`n"
  $target = Join-Path $dstRoot $name
  if ($Apply) {
    [System.IO.File]::WriteAllText($target, $out, $utf8)
    "写入  $name（改写台账引用 $hits 处）"
  }
  else {
    "演练  $name -> $target（将改写台账引用 $hits 处）"
  }
}

# ---- 调查笔记：原样复制，不插 frontmatter、不改写 ----
$surveyDst = Join-Path $dstRoot '_调查'
New-Item -ItemType Directory -Force -Path $surveyDst | Out-Null
Get-ChildItem -LiteralPath (Join-Path $Source '_调查') -File -Filter '*.md' | ForEach-Object {
  $target = Join-Path $surveyDst $_.Name
  if ($Apply) {
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    "写入  _调查\$($_.Name)"
  }
  else {
    "演练  _调查\$($_.Name) -> $target"
  }
}

if ($Apply) { "完成：仓库副本已与 $Source 对齐" } else { "演练结束（未写入任何文件）。确认无误后加 -Apply。" }
