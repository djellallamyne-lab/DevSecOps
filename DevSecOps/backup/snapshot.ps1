<#
.SYNOPSIS
  Snapshot the repository working tree into backups/snapshots/<timestamp>.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$dest = Join-Path $RepoRoot "backups\snapshots\$timestamp"

$excludeDirs = @(
    ".git", "backups", ".gradle", "build", "node_modules",
    ".idea", ".terraform", "bin", "out"
)
$excludeFiles = @(
    ".env", ".ansible-vault-devsecops", "kubeconfig",
    "*.vault-pass", "credentials.xml"
)

New-Item -ItemType Directory -Force -Path $dest | Out-Null

function ShouldSkip([string]$fullPath, [string]$root) {
    $rel = $fullPath.Substring($root.Length).TrimStart("\", "/")
    foreach ($d in $excludeDirs) {
        if ($rel -eq $d -or $rel.StartsWith("$d\") -or $rel.StartsWith("$d/")) { return $true }
    }
    $name = Split-Path $fullPath -Leaf
    foreach ($pat in $excludeFiles) {
        if ($name -like $pat) { return $true }
    }
    return $false
}

Get-ChildItem -Path $RepoRoot -Recurse -Force -File | ForEach-Object {
    if (ShouldSkip $_.FullName $RepoRoot) { return }
    $rel = $_.FullName.Substring($RepoRoot.Length).TrimStart("\", "/")
    $target = Join-Path $dest $rel
    $parent = Split-Path $target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}

# Write metadata
@{
    timestamp = $timestamp
    source    = $RepoRoot
    host      = $env:COMPUTERNAME
} | ConvertTo-Json | Set-Content (Join-Path $dest "SNAPSHOT.json")

Write-Host "Snapshot created: $dest"

# Apply retention
& (Join-Path $PSScriptRoot "retention.ps1")
