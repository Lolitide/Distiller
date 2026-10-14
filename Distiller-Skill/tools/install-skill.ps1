<#
.SYNOPSIS
  把本技能安装到 agent 的技能根（默认 ~\.agents\skills\distiller-dev）。

.DESCRIPTION
  权威源：本仓库根（E:\Program_File\Skill\Distiller-Skill）
  安装目标：$HOME\.agents\skills\<name>\

  DSH 只在这些根的**一级子目录**里找技能，且要求子目录下直接有 SKILL.md：
    <项目根>\.dsh\skills
    <项目根>\.agents\skills
    ~\.dsh\skills
    ~\.agents\skills      <- 本脚本默认目标
  references/ 下的几千篇 md 不会被当成技能（发现逻辑不递归），所以是安全的。

  默认演练，不加 -Apply 不落盘。装完要**新开一个会话**，技能目录才会刷新。

.PARAMETER Target
  安装目录，默认 $HOME\.agents\skills\distiller-dev。

.PARAMETER Link
  用目录联接（junction）代替复制，便于边改边生效。代价是目标目录不再是独立副本。

.PARAMETER Apply
  真正写盘。

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-skill.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-skill.ps1 -Apply
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\install-skill.ps1 -Link -Apply
#>
[CmdletBinding()]
param(
  [string]$Target = '',
  [switch]$Link,
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Target)) {
  $Target = Join-Path $env:USERPROFILE '.agents\skills\distiller-dev'
}

$Source = Split-Path -Parent $PSScriptRoot
$srcSkill = Join-Path $Source 'SKILL.md'

Write-Host ''
Write-Host 'Distiller-Skill · install' -ForegroundColor Cyan
Write-Host "  Source : $Source"
Write-Host "  Target : $Target"
Write-Host "  Mode   : $(if ($Link) { 'JUNCTION' } else { 'COPY' })   $(if ($Apply) { 'APPLY（写盘）' } else { 'DRY-RUN（不落盘）' })"
Write-Host ''

if (-not (Test-Path -LiteralPath $srcSkill)) {
  Write-Host "  x 源里没有 SKILL.md：$srcSkill" -ForegroundColor Red
  Write-Host '    先写 SKILL.md 再安装。'
  exit 2
}

# 统计
$all = @(Get-ChildItem -LiteralPath $Source -Recurse -File -Force)
$bytes = ($all | Measure-Object Length -Sum).Sum
Write-Host "  源内容：$($all.Count) 个文件 / $([math]::Round($bytes/1MB,1)) MB"

# 目标父目录必须在 DSH 的技能根里（防止手滑写到别处）
$parent = Split-Path -Parent $Target
$home_agents = Join-Path $env:USERPROFILE '.agents\skills'
$home_dsh = Join-Path $env:USERPROFILE '.dsh\skills'
$okParent = $false
foreach ($r in @($home_agents, $home_dsh)) {
  if ([System.IO.Path]::GetFullPath($parent).TrimEnd('\') -ieq [System.IO.Path]::GetFullPath($r).TrimEnd('\')) { $okParent = $true }
}
if (-not $okParent) {
  Write-Host "  ! 目标父目录不在已知技能根里：$parent" -ForegroundColor Yellow
  Write-Host "    已知根：$home_agents ；$home_dsh"
  Write-Host '    这是允许的（-Target 可自定义），但 DSH 不会自动发现它，除非该根已配置为技能目录。'
}

if (-not $Apply) {
  Write-Host ''
  Write-Host "  演练：会把 $($all.Count) 个文件写入 $Target"
  if (Test-Path -LiteralPath $Target) {
    $exist = @(Get-ChildItem -LiteralPath $Target -Recurse -File -Force)
    Write-Host "  目标已存在（$($exist.Count) 个文件），-Apply 时会先整目录删除再写。"
  }
  Write-Host ''
  Write-Host '演练结束（未写入任何文件）。确认无误后加 -Apply。' -ForegroundColor Yellow
  exit 0
}

# ---- 落盘 ----
if (Test-Path -LiteralPath $Target) {
  Write-Host '  删除已有目标…'
  Remove-Item -LiteralPath $Target -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $parent | Out-Null

if ($Link) {
  try {
    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
    Write-Host "  + 已建立目录联接：$Target -> $Source" -ForegroundColor Green
  } catch {
    Write-Host "  ! 建立联接失败（$($_.Exception.Message)），回退为复制。" -ForegroundColor Yellow
    $Link = $false
  }
}
if (-not $Link) {
  Copy-Item -LiteralPath $Source -Destination $Target -Recurse -Force
  Write-Host "  + 已复制 $($all.Count) 个文件到 $Target" -ForegroundColor Green
}

$tgtSkill = Join-Path $Target 'SKILL.md'
if (-not (Test-Path -LiteralPath $tgtSkill)) {
  Write-Host "  x 安装后目标里没有 SKILL.md，安装失败。" -ForegroundColor Red
  exit 3
}

$tgtFiles = @(Get-ChildItem -LiteralPath $Target -Recurse -File -Force)
$tgtBytes = ($tgtFiles | Measure-Object Length -Sum).Sum
Write-Host "  校验：$($tgtFiles.Count) 个文件 / $([math]::Round($tgtBytes/1MB,1)) MB，SKILL.md 存在。"
Write-Host ''
Write-Host '  **新开一个会话**，技能目录里才会出现 distiller-dev。' -ForegroundColor Cyan
