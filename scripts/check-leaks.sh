#!/usr/bin/env bash
# Pre-commit guard: block personal / device-identifying info from entering the public repo.
# Install per clone:  ln -sf ../../scripts/check-leaks.sh .git/hooks/pre-commit
# ponytail: greps staged text for two patterns; add patterns here if a new leak class appears.
set -euo pipefail

# Absolute home paths, and BLE MAC addresses (aa:bb:cc:dd:ee:ff).
patterns='(/Users/|/home/[a-z]|([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})'

# Only scan staged, added/changed text lines — not the whole file, not deletions.
# Self-exclude this script (it defines the patterns), and skip lines marked `leak-ok`
# (for docs that legitimately show an example path/MAC).
hits=$(git diff --cached --no-color -U0 -- . ':(exclude)scripts/check-leaks.sh' \
  | grep -E '^\+' | grep -vE '^\+\+\+' \
  | grep -vE 'leak-ok' \
  | grep -EnI "$patterns" || true)

if [ -n "$hits" ]; then
  echo "check-leaks: refusing commit — staged changes contain personal/device info:" >&2
  echo "$hits" >&2
  echo "Fix (relative paths, gitignored device config) or override with: git commit --no-verify" >&2
  exit 1
fi
