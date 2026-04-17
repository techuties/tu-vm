#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://oweb.tu.lan}"
TOKEN="${LANGGRAPH_SUPERVISOR_TOKEN:-${MCP_GATEWAY_TOKEN:-}}"
TENANT_ID="${TENANT_ID:-default-tenant}"
ACTOR_ID="${ACTOR_ID:-smoke-tester}"
CONVERSATION_ID="${CONVERSATION_ID:-smoke-conversation}"
INTENT_HASH="${INTENT_HASH:-smoke-intent-$(date +%s)}"

scheme="${BASE_URL%%://*}"
authority_path="${BASE_URL#*://}"
authority="${authority_path%%/*}"
base_host="${authority%%:*}"
base_port="${authority##*:}"
if [[ "$authority" == "$base_host" ]]; then
  if [[ "$scheme" == "https" ]]; then
    base_port="443"
  else
    base_port="80"
  fi
fi

curl_resolve=()
if [[ ! "$base_host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && ! getent hosts "$base_host" >/dev/null 2>&1; then
  resolve_ip="${SMOKE_RESOLVE_IP:-127.0.0.1}"
  echo "Host '${base_host}' not resolvable locally, using --resolve ${base_host}:${base_port}:${resolve_ip}"
  curl_resolve=(--resolve "${base_host}:${base_port}:${resolve_ip}")
fi

if [[ -z "$TOKEN" ]]; then
  echo "LANGGRAPH_SUPERVISOR_TOKEN or MCP_GATEWAY_TOKEN must be set" >&2
  exit 1
fi

echo "[1/4] LangGraph health check"
curl -ksS "${curl_resolve[@]}" "${BASE_URL}/api/langgraph/health" >/dev/null

echo "[2/4] MCP health check"
curl -ksS "${curl_resolve[@]}" -H "Authorization: Bearer ${TOKEN}" "${BASE_URL}/api/mcp/health" >/dev/null

echo "[3/4] Deterministic read-only call"
resp="$(curl -ksS "${curl_resolve[@]}" -X POST "${BASE_URL}/api/langgraph/execute" \
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
if str(data.get("status")) != "ok":
    raise SystemExit(f"Unexpected read-only status: {data.get('status')}")
print("Read-only verification passed.")
PY

echo "[4/4] Controlled write-deny check (confirm guard)"
write_resp="$(curl -ksS "${curl_resolve[@]}" -X POST "${BASE_URL}/api/langgraph/execute" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenantId\": \"${TENANT_ID}\",
    \"actorId\": \"${ACTOR_ID}\",
    \"conversationId\": \"${CONVERSATION_ID}\",
    \"intentHash\": \"${INTENT_HASH}-write\",
    \"tool\": \"n8n_create_workflow\",
    \"arguments\": {\"name\": \"smoke-should-block\", \"nodes\": [], \"connections\": {}}
  }")"

python3 - <<'PY' "$write_resp"
import json, sys
raw = sys.argv[1]
message = raw
try:
    data = json.loads(raw)
    if isinstance(data, dict):
        message = str(data.get("detail", raw))
except Exception:
    pass
if "confirm=true is required" not in message:
    raise SystemExit(f"Write guard not enforced. Response: {raw}")
print("Write-deny verification passed.")
PY
