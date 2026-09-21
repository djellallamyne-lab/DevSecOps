# Install Git hooks on Windows (post-commit → git bundle)
$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$hookDir = Join-Path $RepoRoot ".git\hooks"
$src = Join-Path $PSScriptRoot "hooks\post-commit"
$dest = Join-Path $hookDir "post-commit"
if (-not (Test-Path $hookDir)) {
  throw "Not a git repository (missing .git/hooks). Run from a cloned repo."
}
Copy-Item -Force $src $dest
Write-Host "Installed post-commit hook → backups/git/*.bundle"
