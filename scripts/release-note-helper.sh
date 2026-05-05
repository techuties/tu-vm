#!/usr/bin/env bash
# Emit a changelog-ready bullet list from commits after a git tag (operator notes still manual).
# Usage:
#   ./scripts/release-note-helper.sh           # uses latest reachable tag
#   ./scripts/release-note-helper.sh v2.0.0    # explicit baseline tag
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE="${1:-}"
if [[ -z "$BASE" ]]; then
  BASE="$(git describe --tags --abbrev=0 2>/dev/null || true)"
fi
if [[ -z "$BASE" ]]; then
  echo "Usage: $0 <tag-or-revision>" >&2
  echo "No tag found; pass e.g. ./scripts/release-note-helper.sh v2.0.0" >&2
  exit 1
fi

echo "## Pending changes since ${BASE}"
echo ""
echo "### Commits (copy into CHANGELOG / release notes as appropriate)"
git log "${BASE}..HEAD" --pretty=format:'- %s (%h)' --no-merges
echo ""
echo ""
echo "### Operator impact / migrations"
echo "_Fill manually: compose/env/nginx/helper behaviour operators must know._"
