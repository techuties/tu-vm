#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[pre-push] Running local smoke checks..."

echo "[1/4] git worktree integrity + required files"
unstaged_deleted="$(git diff --name-only --diff-filter=D | wc -l | tr -d ' ')"
staged_deleted="$(git diff --cached --name-only --diff-filter=D | wc -l | tr -d ' ')"
total_deleted=$((unstaged_deleted + staged_deleted))

if [[ "$total_deleted" -gt 0 ]] && [[ "${ALLOW_TRACKED_DELETIONS:-0}" != "1" ]]; then
  echo "[pre-push] ERROR: tracked file deletions detected (unstaged=${unstaged_deleted}, staged=${staged_deleted})."
  echo "[pre-push] Set ALLOW_TRACKED_DELETIONS=1 only when deletions are intentional."
  echo "[pre-push] Unstaged deletions:"
  git diff --name-only --diff-filter=D || true
  echo "[pre-push] Staged deletions:"
  git diff --cached --name-only --diff-filter=D || true
  exit 1
fi

for required in "tu-vm.sh" "docker-compose.yml" "README.md" "env.example"; do
  if [[ ! -f "$required" ]]; then
    echo "[pre-push] ERROR: required file missing: $required"
    exit 1
  fi
done

echo "[2/4] scripts/smoke-test.sh (compose render, bash -n, check-config)"
./scripts/smoke-test.sh

echo "[3/4] ./tu-vm.sh help"
./tu-vm.sh help >/dev/null

echo "[4/4] git status sanity"
git status --short --branch >/dev/null

echo "[pre-push] All checks passed."
