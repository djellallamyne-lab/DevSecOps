<#
.SYNOPSIS
  Watch the repo for changes and snapshot after 30s of idle writes.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$DebounceSeconds = 30
)

$ErrorActionPreference = "Stop"
$snapshotScript = Join-Path $PSScriptRoot "snapshot.ps1"
$timer = $null
$sync = [hashtable]::Synchronized(@{ pending = $false })

function Schedule-Snapshot {
    if ($script:timer) {
        $script:timer.Stop()
        $script:timer.Dispose()
    }
    $script:timer = New-Object System.Timers.Timer ($DebounceSeconds * 1000)
    $script:timer.AutoReset = $false
    Register-ObjectEvent -InputObject $script:timer -EventName Elapsed -Action {
        & $Event.MessageData
    } -MessageData $snapshotScript | Out-Null
    $script:timer.Start()
    Write-Host "[$(Get-Date -Format o)] change detected — snapshot in ${DebounceSeconds}s if idle"
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $RepoRoot
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [IO.NotifyFilters]"FileName, DirectoryName, LastWrite, Size"
$watcher.Filter = "*.*"
$watcher.EnableRaisingEvents = $true

$handler = {
    $path = $Event.SourceEventArgs.FullPath
    if ($path -match '\\backups\\|\.git\\|\\\.gradle\\|\\build\\') { return }
    Schedule-Snapshot
}

Register-ObjectEvent $watcher Created -Action $handler | Out-Null
Register-ObjectEvent $watcher Changed -Action $handler | Out-Null
Register-ObjectEvent $watcher Deleted -Action $handler | Out-Null
Register-ObjectEvent $watcher Renamed -Action $handler | Out-Null

Write-Host "Watching $RepoRoot (debounce ${DebounceSeconds}s). Ctrl+C to stop."
try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
}
