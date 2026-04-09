#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://oweb.tu.lan}"
TOKEN="${LANGGRAPH_SUPERVISOR_TOKEN:-${MCP_GATEWAY_TOKEN:-}}"
TENANT_ID="${TENANT_ID:-default-tenant}"
ACTOR_ID="${ACTOR_ID:-smoke-tester}"
CONVERSATION_ID="${CONVERSATION_ID:-smoke-conversation}"
INTENT_HASH="${INTENT_HASH:-smoke-intent-$(date +%s)}"

if [[ -z "$TOKEN" ]]; then
  echo "LANGGRAPH_SUPERVISOR_TOKEN or MCP_GATEWAY_TOKEN must be set" >&2
  exit 1
fi

echo "[1/3] LangGraph health check"
curl -ksS "${BASE_URL}/api/langgraph/health" >/dev/null

echo "[2/3] MCP health check"
curl -ksS -H "Authorization: Bearer ${TOKEN}" "${BASE_URL}/api/mcp/health" >/dev/null

echo "[3/3] Deterministic read-only call"
resp="$(curl -ksS -X POST "${BASE_URL}/api/langgraph/execute" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenantId\": \"${TENANT_ID}\",
    \"actorId\": \"${ACTOR_ID}\",
    \"conversationId\": \"${CONVERSATION_ID}\",
    \"intentHash\": \"${INTENT_HASH}\",
    \"tool\": \"n8n_list_workflows\",
    \"arguments\": {\"limit\": 1}
  }")"

python3 - <<'PY' "$resp"
import json, sys
raw = sys.argv[1]
data = json.loads(raw)
required = ["tenantId", "tool", "claimed", "status", "verificationEvidence"]
missing = [k for k in required if k not in data]
if missing:
    raise SystemExit(f"Missing keys in response: {missing}")
print("Smoke check passed.")
PY
