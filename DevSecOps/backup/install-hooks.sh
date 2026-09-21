#!/usr/bin/env bash
# Install local git hooks (post-commit backup bundle)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/.git/hooks"
cp "$ROOT/backup/hooks/post-commit" "$ROOT/.git/hooks/post-commit"
chmod +x "$ROOT/.git/hooks/post-commit"
echo "Installed post-commit hook → backups/git/*.bundle"
