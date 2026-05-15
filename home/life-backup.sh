#!/usr/bin/env bash
set -euo pipefail

cd "$HOME/Documents/Life"

git add -A
if ! git diff --cached --quiet; then
    git commit -q -m "auto $(date -u +%FT%TZ)"
fi
git push -q origin main
