# ensure-bom.ps1 - make .ps1 files UTF-8 WITH BOM.
#
# Why: Windows PowerShell 5.1 decodes a BOM-less .ps1 file as ANSI/GBK, which
# mangles any non-ASCII text and produces bogus parse errors. Editors and
# generators that write UTF-8 without BOM (including the agent's write/edit
# tools) therefore break these scripts. PowerShell 7+ is not affected, but a BOM
# is harmless there, so this script is safe to run unconditionally on any machine.
#
# This file itself is ASCII-only on purpose, so it runs correctly no matter what.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ensure-bom.ps1 -Path tools\build-references.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\ensure-bom.ps1 -Path tools\*.ps1
#
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string[]]$Path
)

$ErrorActionPreference = 'Stop'
$noBom = New-Object System.Text.UTF8Encoding($false)
$withBom = New-Object System.Text.UTF8Encoding($true)

$resolved = @()
foreach ($p in $Path) {
  # -Path expands wildcards; -LiteralPath does not. Try -Path first, fall back for
  # paths that contain wildcard characters but exist literally.
  $items = $null
  if ($p -match '[\*\?\[]') { $items = Get-Item -Path $p -ErrorAction SilentlyContinue }
  if ($null -eq $items) { $items = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue }
  if ($null -eq $items) { $items = Get-ChildItem -Path $p -ErrorAction SilentlyContinue }
  if ($null -eq $items) { Write-Warning "not found: $p"; continue }
  foreach ($it in $items) {
    if ($it.PSIsContainer) { $resolved += (Get-ChildItem -LiteralPath $it.FullName -Filter *.ps1 -File) }
    else { $resolved += $it }
  }
}

foreach ($f in $resolved) {
  $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $text = [System.IO.File]::ReadAllText($f.FullName, $noBom)
  [System.IO.File]::WriteAllText($f.FullName, $text, $withBom)
  $state = if ($hasBom) { 'already' } else { 'ADDED  ' }
  Write-Host ("[{0}] {1}  ({2:N0} bytes)" -f $state, $f.FullName, (Get-Item -LiteralPath $f.FullName).Length)
}
