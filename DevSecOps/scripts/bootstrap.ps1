<#
.SYNOPSIS
  Windows-friendly bootstrap for the DevSecOps lab (Docker Compose + optional kind).
  Prefer Ansible on WSL/Linux when available: ansible-playbook ansible/playbooks/bootstrap-lab.yml
#>
[CmdletBinding()]
param(
    [switch]$WithKind,
    [switch]$WithMonitoring
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $Root "docker\lab-compose.yml"))) {
  $Root = $PSScriptRoot
  if (-not (Test-Path (Join-Path $Root "docker\lab-compose.yml"))) {
    $Root = (Resolve-Path ".").Path
  }
}

Set-Location $Root
Write-Host "==> Repo root: $Root"

# Vault template
$vaultExample = Join-Path $Root "ansible\group_vars\all\vault.yml.example"
$vaultFile = Join-Path $Root "ansible\group_vars\all\vault.yml"
if (-not (Test-Path $vaultFile)) {
  Copy-Item $vaultExample $vaultFile
  Write-Host "Created ansible/group_vars/all/vault.yml from example — encrypt with ansible-vault before real use."
}

# .env for compose
$envExample = Join-Path $Root ".env.example"
$envFile = Join-Path $Root ".env"
if (-not (Test-Path $envFile)) {
  Copy-Item $envExample $envFile
}

# Directories
@(
  "backups\snapshots", "backups\git", "backups\lab"
) | ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $Root $_) | Out-Null }

Write-Host "==> Starting Jenkins + registry (docker compose)"
docker compose -f docker/lab-compose.yml --env-file .env up -d

if ($WithKind) {
  if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    throw "kind not found. Install https://kind.sigs.k8s.io/ then re-run with -WithKind"
  }
  $clusters = kind get clusters 2>$null
  if ($clusters -notcontains "devsecops") {
    kind create cluster --name devsecops --config ansible/files/kind-config.yaml
  }
  kubectl apply -f - @"
apiVersion: v1
kind: Namespace
metadata:
  name: demo-dev
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
"@
  kubectl apply -f k8s/
  if (Get-Command helm -ErrorAction SilentlyContinue) {
    helm repo add kyverno https://kyverno.github.io/kyverno/ 2>$null
    helm repo update
    helm upgrade --install kyverno kyverno/kyverno --namespace kyverno --create-namespace --wait
    kubectl apply -f security/policies/kyverno/
  }
}

if ($WithMonitoring -and (Get-Command helm -ErrorAction SilentlyContinue)) {
  bash monitoring/install.sh
  kubectl apply -f monitoring/dashboard-configmap.yaml
  kubectl apply -f monitoring/servicemonitor.yaml
}

Write-Host @"

Lab started.
  Jenkins:  http://localhost:8081
  Registry: localhost:5000
  Encrypt vault: ansible-vault encrypt ansible/group_vars/all/vault.yml
  Hooks:      .\backup\install-hooks.ps1
  Watcher:    .\backup\watch.ps1
"@
