#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"
COMMIT_COUNT="${COMMIT_COUNT:-20}"
WRITE_MODE=0

if [[ "${1:-}" == "--write" ]]; then
  WRITE_MODE=1
fi

if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "Missing CHANGELOG.md at: $CHANGELOG_FILE" >&2
  exit 1
fi

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must run inside a git repository." >&2
  exit 1
fi

release_date="$(date +%Y-%m-%d)"
commit_lines="$(git log --no-merges -n "$COMMIT_COUNT" --pretty=format:'- %s (`%h`)')"

if [[ -z "$commit_lines" ]]; then
  commit_lines="- No new commits."
fi

read -r -d '' unreleased_block <<EOF || true
## [Unreleased] - ${release_date}

### Changed
${commit_lines}
EOF

if [[ "$WRITE_MODE" -eq 0 ]]; then
  echo "$unreleased_block"
  exit 0
fi

python3 - "$CHANGELOG_FILE" "$unreleased_block" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
block = sys.argv[2].rstrip() + "\n\n"
text = path.read_text()

pattern = re.compile(r"^## \[Unreleased\].*?(?=^## \[|\Z)", re.MULTILINE | re.DOTALL)
if pattern.search(text):
    updated = pattern.sub(block, text, count=1)
else:
    marker = "All notable changes to the TechUties VM project will be documented in this file."
    if marker in text:
        updated = text.replace(marker, marker + "\n\n" + block, 1)
    else:
        updated = "# Changelog\n\n" + block + text

path.write_text(updated)
PY

echo "Updated $CHANGELOG_FILE with Unreleased section."
