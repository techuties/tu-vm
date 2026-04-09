import asyncio
import hashlib
import json
import logging
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx
from fastapi import FastAPI, Header, HTTPException
from langgraph.graph import END, StateGraph
from pydantic import BaseModel, Field
from typing_extensions import TypedDict


logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("langgraph-supervisor")

app = FastAPI(title="LangGraph Supervisor", version="1.0.0")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _env_bool(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


class ExecutePayload(BaseModel):
    tenantId: str
    actorId: str
    conversationId: str
    intentHash: str
    tool: str
    arguments: dict[str, Any] = Field(default_factory=dict)
    requestId: str | None = None


class SupervisorState(TypedDict, total=False):
    payload: ExecutePayload
    idempotencyKey: str
    gatewayResult: dict[str, Any]
    envelope: dict[str, Any]
    verified: bool
    claimed: bool
    status: str
    result: dict[str, Any]
    auditRecord: dict[str, Any]


class JsonStore:
    def __init__(self, path_env: str, default_path: str) -> None:
        self.path = Path(os.getenv(path_env, default_path))
        self.lock = asyncio.Lock()

    def _load(self) -> list[dict[str, Any]]:
        data: list[dict[str, Any]] = []
        if self.path.exists():
            try:
                loaded = json.loads(self.path.read_text(encoding="utf-8"))
                if isinstance(loaded, list):
                    data = loaded
            except Exception:
                logger.exception("Failed reading %s", self.path)
        return data

    def _save(self, data: list[dict[str, Any]]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        tmp.replace(self.path)

    async def append(self, item: dict[str, Any], max_items: int = 20000) -> None:
        async with self.lock:
            data = self._load()
            data.append(item)
            if len(data) > max_items:
                data = data[-max_items:]
            self._save(data)

    async def lookup(self, key: str, value: str) -> dict[str, Any] | None:
        async with self.lock:
            for item in reversed(self._load()):
                if str(item.get(key, "")) == value:
                    return item
        return None


store = JsonStore("LANGGRAPH_AUDIT_PATH", "/var/lib/langgraph-supervisor/audit.json")
checkpoint_store = JsonStore("LANGGRAPH_CHECKPOINT_PATH", "/var/lib/langgraph-supervisor/checkpoints.json")
dedupe_store = JsonStore("LANGGRAPH_DEDUPE_PATH", "/var/lib/langgraph-supervisor/dedupe.json")


MCP_GATEWAY_URL = os.getenv("MCP_GATEWAY_URL", "http://ai_mcp_gateway:9002").rstrip("/")
MCP_GATEWAY_TOKEN = os.getenv("MCP_GATEWAY_TOKEN", "").strip()
STRICT_VERIFY = _env_bool("LANGGRAPH_STRICT_VERIFY", True)
WRITE_TOOLS = {
    "n8n_create_workflow",
    "n8n_update_workflow",
    "n8n_activate_workflow",
    "n8n_deactivate_workflow",
    "n8n_create_and_activate_workflow",
    "n8n_run_webhook",
}


def _idempotency_key(payload: ExecutePayload) -> str:
    stable = {
        "tenantId": payload.tenantId,
        "conversationId": payload.conversationId,
        "intentHash": payload.intentHash,
        "tool": payload.tool,
        "arguments": payload.arguments,
    }
    raw = json.dumps(stable, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


async def _gateway_invoke(payload: ExecutePayload) -> dict[str, Any]:
    if not MCP_GATEWAY_TOKEN:
        raise HTTPException(status_code=500, detail="MCP_GATEWAY_TOKEN missing for langgraph-supervisor")
    invoke_payload = {
        "tool": payload.tool,
        "arguments": payload.arguments,
        "tenantId": payload.tenantId,
        "actorId": payload.actorId,
        "conversationId": payload.conversationId,
        "intentHash": payload.intentHash,
        "requestId": payload.requestId or str(uuid.uuid4()),
    }
    headers = {
        "Authorization": f"Bearer {MCP_GATEWAY_TOKEN}",
        "Content-Type": "application/json",
        "X-LangGraph-Supervised": "1",
    }
    async with httpx.AsyncClient(timeout=45.0) as client:
        resp = await client.post(f"{MCP_GATEWAY_URL}/invoke", headers=headers, json=invoke_payload)
    if resp.status_code >= 400:
        raise HTTPException(status_code=resp.status_code, detail=f"Gateway invoke failed: {resp.text[:500]}")
    return resp.json()


def node_request_validation(state: SupervisorState) -> SupervisorState:
    payload = state["payload"]
    for field in ("tenantId", "actorId", "conversationId", "intentHash", "tool"):
        if not getattr(payload, field, "").strip():
            raise HTTPException(status_code=400, detail=f"{field} is required")
    state["idempotencyKey"] = _idempotency_key(payload)
    return state


async def node_tool_invocation(state: SupervisorState) -> SupervisorState:
    payload: ExecutePayload = state["payload"]
    state["gatewayResult"] = await _gateway_invoke(payload)
    return state


def _extract_envelope(gateway_result: dict[str, Any]) -> dict[str, Any]:
    content = gateway_result.get("content", [])
    if not content:
        return {}
    first = content[0] if isinstance(content[0], dict) else {}
    text = str(first.get("text", "{}"))
    try:
        return json.loads(text)
    except Exception:
        return {"raw": text}


def node_execution_verification(state: SupervisorState) -> SupervisorState:
    payload: ExecutePayload = state["payload"]
    envelope = _extract_envelope(state.get("gatewayResult", {}))
    state["envelope"] = envelope
    if payload.tool in WRITE_TOOLS:
        verified = bool((envelope.get("verificationEvidence") or {}).get("verified", False))
        state["verified"] = verified
        if STRICT_VERIFY and not verified:
            state["claimed"] = False
            state["status"] = "unverified"
            return state
    state["verified"] = True
    return state


def node_result_normalization(state: SupervisorState) -> SupervisorState:
    payload: ExecutePayload = state["payload"]
    envelope = state.get("envelope", {})
    state["result"] = {
        "schemaVersion": "v1",
        "requestId": envelope.get("requestId", payload.requestId or str(uuid.uuid4())),
        "tenantId": payload.tenantId,
        "actorId": payload.actorId,
        "conversationId": payload.conversationId,
        "intentHash": payload.intentHash,
        "tool": payload.tool,
        "claimed": bool(envelope.get("claimed", state.get("verified", False))),
        "status": envelope.get("status", "ok"),
        "verifiedAt": envelope.get("verifiedAt", _now_iso()),
        "verificationEvidence": envelope.get("verificationEvidence", {}),
        "result": envelope.get("result", {}),
        "idempotencyKey": state.get("idempotencyKey", ""),
    }
    return state


def node_proof_emission(state: SupervisorState) -> SupervisorState:
    result = state.get("result", {})
    result["supervisorTimestamp"] = _now_iso()
    state["auditRecord"] = result
    return state


workflow = StateGraph(SupervisorState)
workflow.add_node("requestValidation", node_request_validation)
workflow.add_node("toolInvocation", node_tool_invocation)
workflow.add_node("executionVerification", node_execution_verification)
workflow.add_node("resultNormalization", node_result_normalization)
workflow.add_node("proofEmission", node_proof_emission)
workflow.set_entry_point("requestValidation")
workflow.add_edge("requestValidation", "toolInvocation")
workflow.add_edge("toolInvocation", "executionVerification")
workflow.add_edge("executionVerification", "resultNormalization")
workflow.add_edge("resultNormalization", "proofEmission")
workflow.add_edge("proofEmission", END)
graph = workflow.compile()


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "ok": True,
        "strict_verify": STRICT_VERIFY,
        "gateway_url": MCP_GATEWAY_URL,
        "write_tools": sorted(WRITE_TOOLS),
    }


@app.post("/execute")
async def execute(payload: ExecutePayload, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    if not MCP_GATEWAY_TOKEN:
        raise HTTPException(status_code=500, detail="Missing MCP_GATEWAY_TOKEN")
    # Empty LANGGRAPH_SUPERVISOR_TOKEN must not disable auth; fall back to MCP_GATEWAY_TOKEN (documented behavior).
    _lg = (os.getenv("LANGGRAPH_SUPERVISOR_TOKEN") or "").strip()
    expected = _lg if _lg else MCP_GATEWAY_TOKEN.strip()
    if not expected:
        raise HTTPException(status_code=500, detail="Missing supervisor auth token")
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if token != expected:
        raise HTTPException(status_code=401, detail="Invalid token")
    idempotency_key = _idempotency_key(payload)
    if payload.tool in WRITE_TOOLS:
        prior = await dedupe_store.lookup("idempotencyKey", idempotency_key)
        if prior:
            replay = dict(prior)
            replay["deduped"] = True
            return replay

    run_id = str(uuid.uuid4())
    await checkpoint_store.append(
        {
            "runId": run_id,
            "requestId": payload.requestId or "",
            "tenantId": payload.tenantId,
            "conversationId": payload.conversationId,
            "tool": payload.tool,
            "idempotencyKey": idempotency_key,
            "stage": "received",
            "timestamp": _now_iso(),
        }
    )

    state: SupervisorState = {"payload": payload}
    out = await graph.ainvoke(state)
    result = out.get("result", {})
    result["runId"] = run_id
    result["idempotencyKey"] = result.get("idempotencyKey") or idempotency_key
    await store.append(result)
    await checkpoint_store.append(
        {
            "runId": run_id,
            "requestId": result.get("requestId", payload.requestId or ""),
            "tenantId": payload.tenantId,
            "conversationId": payload.conversationId,
            "tool": payload.tool,
            "idempotencyKey": idempotency_key,
            "stage": "completed",
            "status": result.get("status", "ok"),
            "claimed": bool(result.get("claimed", False)),
            "timestamp": _now_iso(),
        }
    )
    if payload.tool in WRITE_TOOLS:
        await dedupe_store.append(result)
    return result
