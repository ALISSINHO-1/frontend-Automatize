#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"

if [[ -z "$REPO_DIR" ]]; then
  echo "[setup] ERROR: Git repository root not found."
  exit 1
fi

echo "[setup] Repo: $REPO_DIR"

mkdir -p "$REPO_DIR/scripts/hooks"

required=(
  "$REPO_DIR/scripts/hooks/commit-hook"
  "$REPO_DIR/scripts/hooks/pre-commit"
  "$REPO_DIR/scripts/hooks/commit-msg"
  "$REPO_DIR/scripts/hooks/post-commit"
  "$REPO_DIR/tool/versioning.sh"
)

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "[setup] ERROR: missing file: $file"
    exit 1
  fi
done

chmod +x \
  "$REPO_DIR/scripts/hooks/commit-hook" \
  "$REPO_DIR/scripts/hooks/pre-commit" \
  "$REPO_DIR/scripts/hooks/commit-msg" \
  "$REPO_DIR/scripts/hooks/post-commit" \
  "$REPO_DIR/tool/versioning.sh"

git -C "$REPO_DIR" config core.hooksPath scripts/hooks

echo "[setup] Hooks installed."
echo "[setup] core.hooksPath=$(git -C "$REPO_DIR" config core.hooksPath)"
echo "[setup] Commit formats: FEAT:, FIX:, CHORE:"
