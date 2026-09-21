# Backup & restore runbook

Automated backups protect **uncommitted work** and **lab state**. Git history alone is not enough.

## Triggers

| Trigger | Script / job | Output |
|---------|--------------|--------|
| File change (~30s debounce) | `backup/watch.ps1` | `backups/snapshots/YYYY-MM-DD_HH-mm-ss/` |
| Every Git commit | `backup/hooks/post-commit` | `backups/git/HEAD-<hash>.bundle` |
| Daily Jenkins cron | See `jenkins/jobs/lab-backup.md` | `backups/lab/` |

## Exclusions (never backed up)

- `.git/`, `backups/` (avoid recursion)
- `.gradle/`, `build/`, `node_modules/`
- `.env`, `*.vault-pass`, `kubeconfig`, credentials

## Snapshot (manual)

```powershell
.\backup\snapshot.ps1
```

## Watcher (auto)

```powershell
.\backup\watch.ps1
# Debounce: 30 seconds of idle after last change
```

## Restore files

```powershell
.\backup\restore.ps1 -Snapshot 2026-09-21_16-20-00
# Creates a safety copy of the current tree under backups/pre-restore-* first
```

List available snapshots:

```powershell
Get-ChildItem backups\snapshots
```

## Restore Git history (bundle)

```powershell
git bundle verify backups\git\HEAD-<hash>.bundle
git clone backups\git\HEAD-<hash>.bundle restored-repo
# or: git fetch backups\git\HEAD-<hash>.bundle main:restored-main
```

## Helm rollback (deploy)

```powershell
helm history demo-api -n demo-dev
helm rollback demo-api -n demo-dev
```

## Retention

| Type | Keep |
|------|------|
| File snapshots | 20 |
| Git bundles | 10 |
| Lab archives | 7 |

```powershell
.\backup\retention.ps1
```

## Limits

- Backups are **local only** (not offsite).
- Do not store Vault passwords or Jenkins credentials in archives.
- Test restore at least once after enabling backups.
