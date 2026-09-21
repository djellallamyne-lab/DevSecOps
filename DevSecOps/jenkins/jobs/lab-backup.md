# Jenkins cron job — lab state backup (document for JCasC / manual job)

Create a freestyle or pipeline job `lab-backup` with cron `H 2 * * *` that runs:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="${WORKSPACE:-.}"
STAMP=$(date +%Y-%m-%d_%H-%M-%S)
OUT="$ROOT/backups/lab/$STAMP"
mkdir -p "$OUT"

# Helm values (no secrets if you keep them vaulted and not in values)
helm get values demo-api -n demo-dev > "$OUT/helm-values.yaml" || true
helm get manifest demo-api -n demo-dev > "$OUT/helm-manifest.yaml" || true

# Namespace dump (no Secrets data if possible — use names only)
kubectl get all,cm,ing,netpol,sa -n demo-dev -o yaml > "$OUT/demo-dev.yaml" || true

# Copy JCasC from repo (already in Git — snapshot for lab correl)
cp -r jenkins/casc "$OUT/casc" || true

tar -czf "$OUT.tgz" -C "$ROOT/backups/lab" "$STAMP"
rm -rf "$OUT"

# Retention
if command -v pwsh >/dev/null; then
  pwsh -File backup/retention.ps1
fi
```

Never archive Jenkins credentials.xml or Ansible vault password files.
