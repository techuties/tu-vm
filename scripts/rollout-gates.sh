#!/usr/bin/env bash
set -euo pipefail

PROOF_PATH="${1:-/var/lib/docker/volumes/tu-vm_mcp_gateway_data/_data/proof-store.json}"
WINDOW_HOURS="${WINDOW_HOURS:-24}"
MIN_CLAIMED_VERIFY_RATE="${MIN_CLAIMED_VERIFY_RATE:-99.9}"
MAX_MISMATCH_RATE="${MAX_MISMATCH_RATE:-0.1}"

if [[ ! -f "$PROOF_PATH" ]]; then
  echo "Proof store not found: $PROOF_PATH" >&2
  exit 1
fi

python3 - <<'PY' "$PROOF_PATH" "$WINDOW_HOURS" "$MIN_CLAIMED_VERIFY_RATE" "$MAX_MISMATCH_RATE"
import datetime as dt
import json
import sys

path = sys.argv[1]
window_hours = float(sys.argv[2])
min_claimed_verify_rate = float(sys.argv[3])
max_mismatch_rate = float(sys.argv[4])

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
if not isinstance(data, list):
    raise SystemExit("Proof store is not a list")

cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(hours=window_hours)
rows = []
for item in data:
    ts = item.get("verifiedAt") or item.get("supervisorTimestamp")
    if not ts:
        continue
    try:
        parsed = dt.datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
    except Exception:
        continue
    if parsed >= cutoff:
        rows.append(item)

if not rows:
    raise SystemExit("No proof rows in selected time window")

claimed_rows = [r for r in rows if bool(r.get("claimed", False))]
verified_rows = [r for r in claimed_rows if bool((r.get("verificationEvidence") or {}).get("verified", False))]
mismatch_rows = [r for r in claimed_rows if not bool((r.get("verificationEvidence") or {}).get("verified", False))]

claimed_verify_rate = (len(verified_rows) / len(claimed_rows) * 100.0) if claimed_rows else 100.0
mismatch_rate = (len(mismatch_rows) / len(claimed_rows) * 100.0) if claimed_rows else 0.0

print(f"window_rows={len(rows)}")
print(f"claimed_rows={len(claimed_rows)}")
print(f"claimed_verify_rate={claimed_verify_rate:.3f}")
print(f"mismatch_rate={mismatch_rate:.3f}")

if claimed_verify_rate < min_claimed_verify_rate:
    raise SystemExit(f"Gate failed: claimed_verify_rate {claimed_verify_rate:.3f} < {min_claimed_verify_rate:.3f}")
if mismatch_rate > max_mismatch_rate:
    raise SystemExit(f"Gate failed: mismatch_rate {mismatch_rate:.3f} > {max_mismatch_rate:.3f}")

print("Rollout gates: PASS")
PY
