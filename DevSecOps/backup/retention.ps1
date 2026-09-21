<#
.SYNOPSIS
  Keep N newest snapshots, git bundles, and lab archives.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$KeepSnapshots = 20,
    [int]$KeepBundles = 10,
    [int]$KeepLab = 7
)

$ErrorActionPreference = "Stop"

function Trim-Folder($path, $keep, $filter = "*") {
    if (-not (Test-Path $path)) { return }
    $items = Get-ChildItem $path -Filter $filter | Sort-Object LastWriteTime -Descending
    $items | Select-Object -Skip $keep | ForEach-Object {
        Write-Host "Removing old backup: $($_.FullName)"
        Remove-Item $_.FullName -Recurse -Force
    }
}

Trim-Folder (Join-Path $RepoRoot "backups\snapshots") $KeepSnapshots
Trim-Folder (Join-Path $RepoRoot "backups\git") $KeepBundles "*.bundle"
Trim-Folder (Join-Path $RepoRoot "backups\lab") $KeepLab

Write-Host "Retention applied (snapshots=$KeepSnapshots, bundles=$KeepBundles, lab=$KeepLab)"
