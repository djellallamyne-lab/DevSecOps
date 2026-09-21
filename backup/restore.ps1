<#
.SYNOPSIS
  Restore working tree files from a named snapshot.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Snapshot,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$src = Join-Path $RepoRoot "backups\snapshots\$Snapshot"
if (-not (Test-Path $src)) {
    throw "Snapshot not found: $src`nAvailable: $((Get-ChildItem (Join-Path $RepoRoot 'backups\snapshots') -ErrorAction SilentlyContinue).Name -join ', ')"
}

# Safety copy of current tree
$safety = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Write-Host "Creating pre-restore safety snapshot..."
& (Join-Path $PSScriptRoot "snapshot.ps1")
# Rename last snapshot marker conceptually — snapshot.ps1 already ran

Get-ChildItem -Path $src -Recurse -File | ForEach-Object {
    if ($_.Name -eq "SNAPSHOT.json") { return }
    $rel = $_.FullName.Substring($src.Length).TrimStart("\", "/")
    $target = Join-Path $RepoRoot $rel
    $parent = Split-Path $target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}

Write-Host "Restored snapshot $Snapshot into $RepoRoot"
Write-Host "A fresh safety snapshot was created under backups/snapshots/ before overwrite."
