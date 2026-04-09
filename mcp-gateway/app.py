import asyncio
import base64
import hashlib
import hmac
import io
import json
import logging
import os
import shlex
import time
import uuid
from collections import defaultdict, deque
from contextlib import AsyncExitStack
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.security import APIKeyHeader, HTTPAuthorizationCredentials, HTTPBearer
from minio import Minio
from minio.error import S3Error
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from pydantic import BaseModel, Field


logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("mcp-gateway")

app = FastAPI(title="MCP Gateway", version="2.0.0")
http_bearer = HTTPBearer(auto_error=False)
api_key_header = APIKeyHeader(name="X-MCP-GATEWAY-TOKEN", auto_error=False)


def _env_bool(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def _env_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or not raw.strip():
        return default
    try:
        return int(raw)
    except (ValueError, TypeError):
        return default


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _normalize_tool(tool: Any) -> dict[str, Any]:
    name = getattr(tool, "name", "")
    description = getattr(tool, "description", "") or ""
    input_schema = getattr(tool, "inputSchema", None)
    if input_schema is None:
        input_schema = getattr(tool, "input_schema", None)
    return {
        "name": name,
        "description": description,
        "inputSchema": input_schema or {"type": "object", "properties": {}},
    }


def _normalize_content_item(item: Any) -> dict[str, Any]:
    if hasattr(item, "model_dump"):
        return item.model_dump()
    if isinstance(item, dict):
        return item
    item_type = getattr(item, "type", "text")
    text = getattr(item, "text", None)
    if text is None:
        text = str(item)
    return {"type": item_type, "text": text}


def _allowed_servers() -> set[str]:
    raw = os.getenv("MCP_ALLOWED_SERVERS", "affine,n8n,kb")
    return {x.strip().lower() for x in raw.split(",") if x.strip()}


def _affine_enabled() -> bool:
    return _env_bool("AFFINE_MCP_ENABLED", True) and "affine" in _allowed_servers()


def _n8n_enabled() -> bool:
    return _env_bool("N8N_MCP_ENABLED", True) and "n8n" in _allowed_servers()


def _kb_enabled() -> bool:
    return _env_bool("KB_MCP_ENABLED", True) and "kb" in _allowed_servers()


class InvokePayload(BaseModel):
    tool: str
    arguments: dict[str, Any] = Field(default_factory=dict)
    tenantId: str | None = None
    actorId: str | None = None
    conversationId: str | None = None
    intentHash: str | None = None
    requestId: str | None = None


class TenantQuota:
    def __init__(self) -> None:
        self.calls = deque()
        self.daily_writes: dict[str, int] = defaultdict(int)
        self.lock = asyncio.Lock()


class QuotaManager:
    def __init__(self) -> None:
        self.max_rpm = _env_int("TENANT_REQUESTS_PER_MINUTE", 120)
        self.max_daily_writes = _env_int("TENANT_DAILY_WRITES", 4000)
        self.max_concurrency = _env_int("TENANT_MAX_CONCURRENCY", 4)
        self._tenant = defaultdict(TenantQuota)
        self._semaphores: dict[str, asyncio.Semaphore] = {}
        self._sem_lock = asyncio.Lock()

    async def _get_semaphore(self, tenant_id: str) -> asyncio.Semaphore:
        async with self._sem_lock:
            if tenant_id not in self._semaphores:
                self._semaphores[tenant_id] = asyncio.Semaphore(self.max_concurrency)
            return self._semaphores[tenant_id]

    async def run_in_slot(self, tenant_id: str, coro):
        sem = await self._get_semaphore(tenant_id)
        async with sem:
            return await coro

    async def check_and_record(self, tenant_id: str, write: bool) -> None:
        data = self._tenant[tenant_id]
        async with data.lock:
            now = time.time()
            while data.calls and now - data.calls[0] > 60:
                data.calls.popleft()
            if len(data.calls) >= self.max_rpm:
                raise HTTPException(status_code=429, detail="TENANT_RATE_LIMIT_EXCEEDED")
            data.calls.append(now)
            if write:
                day = datetime.now(timezone.utc).strftime("%Y-%m-%d")
                data.daily_writes[day] += 1
                if data.daily_writes[day] > self.max_daily_writes:
                    raise HTTPException(status_code=429, detail="TENANT_DAILY_WRITE_LIMIT_EXCEEDED")


class CircuitBreaker:
    def __init__(self) -> None:
        self.threshold = _env_int("N8N_CIRCUIT_FAIL_THRESHOLD", 8)
        self.open_seconds = _env_int("N8N_CIRCUIT_OPEN_SECONDS", 60)
        self.fail_count = 0
        self.open_until = 0.0
        self.lock = asyncio.Lock()

    async def allow(self) -> None:
        async with self.lock:
            if self.open_until > time.time():
                raise HTTPException(status_code=503, detail="CIRCUIT_OPEN")

    async def mark_success(self) -> None:
        async with self.lock:
            self.fail_count = 0
            self.open_until = 0.0

    async def mark_failure(self) -> None:
        async with self.lock:
            self.fail_count += 1
            if self.fail_count >= self.threshold:
                self.open_until = time.time() + self.open_seconds


class JsonStore:
    def __init__(self, path_env: str, default_path: str) -> None:
        self.path = Path(os.getenv(path_env, default_path))
        self.lock = asyncio.Lock()

    def _load(self) -> list[dict[str, Any]]:
        if not self.path.exists():
            return []
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            if isinstance(raw, list):
                return raw
        except Exception:
            logger.exception("Failed loading json store %s", self.path)
        return []

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


class AffineMcpConnection:
    def __init__(self) -> None:
        self._stack: AsyncExitStack | None = None
        self._session: ClientSession | None = None
        self._lock = asyncio.Lock()
        self._connect_lock = asyncio.Lock()

    async def close(self) -> None:
        if self._stack is not None:
            await self._stack.aclose()
        self._stack = None
        self._session = None

    async def _connect(self) -> None:
        if self._session is not None:
            return
        async with self._connect_lock:
            if self._session is not None:
                return
            command = os.getenv("MCP_AFFINE_COMMAND", "npx")
            raw_args = os.getenv("MCP_AFFINE_ARGS", "affine-mcp-server")
            args = shlex.split(raw_args)
            env = os.environ.copy()
            env["AFFINE_BASE_URL"] = os.getenv("AFFINE_BASE_URL", "http://ai_affine:3010")
            affine_token = os.getenv("AFFINE_API_TOKEN", "").strip()
            affine_cookie = os.getenv("AFFINE_COOKIE", "").strip()
            affine_email = os.getenv("AFFINE_EMAIL", "").strip()
            affine_password = os.getenv("AFFINE_PASSWORD", "").strip()
            if affine_token:
                env["AFFINE_API_TOKEN"] = affine_token
            if affine_cookie:
                env["AFFINE_COOKIE"] = affine_cookie
            if affine_email and affine_password:
                env["AFFINE_EMAIL"] = affine_email
                env["AFFINE_PASSWORD"] = affine_password
            if not affine_token and not affine_cookie and not (affine_email and affine_password):
                raise RuntimeError("No AFFiNE auth configured.")
            server_params = StdioServerParameters(command=command, args=args, env=env)
            stack = AsyncExitStack()
            stdio = await stack.enter_async_context(stdio_client(server_params))
            read_stream, write_stream = stdio
            session = await stack.enter_async_context(ClientSession(read_stream, write_stream))
            await session.initialize()
            self._stack = stack
            self._session = session

    async def list_tools(self) -> list[dict[str, Any]]:
        async with self._lock:
            await self._connect()
            assert self._session is not None
            res = await self._session.list_tools()
            return [_normalize_tool(t) for t in getattr(res, "tools", [])]

    async def call_tool(self, name: str, arguments: dict[str, Any]) -> dict[str, Any]:
        async with self._lock:
            await self._connect()
            assert self._session is not None
            res = await self._session.call_tool(name, arguments)
            content = getattr(res, "content", [])
            is_error = bool(getattr(res, "isError", False))
            return {
                "content": [_normalize_content_item(item) for item in content],
                "error": "Tool call failed" if is_error else None,
            }


class N8nApi:
    def __init__(self) -> None:
        self.base_url = os.getenv("N8N_INTERNAL_URL", "http://ai_n8n:5678").rstrip("/")
        self.timeout = float(os.getenv("N8N_API_TIMEOUT_SECONDS", "20"))
        self.api_key = os.getenv("N8N_API_KEY", "").strip()
        self.require_api_key = _env_bool("N8N_REQUIRE_API_KEY", True)
        self.user = os.getenv("N8N_USER", "admin").strip()
        self.password = os.getenv("N8N_PASSWORD", "").strip()
        allowed = os.getenv("N8N_ALLOWED_WORKFLOW_IDS", "").strip()
        self.allowed_workflows = {x.strip() for x in allowed.split(",") if x.strip()}
        self.verify_tls = _env_bool("N8N_TLS_VERIFY", False)

    async def request(
        self,
        method: str,
        path: str,
        request_id: str,
        *,
        json_payload: dict[str, Any] | None = None,
        query: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        headers = {"X-Request-ID": request_id}
        auth = None
        if self.require_api_key and not self.api_key:
            raise HTTPException(
                status_code=503,
                detail="n8n MCP is enabled but N8N_API_KEY is not configured.",
            )
        if self.api_key:
            headers["X-N8N-API-KEY"] = self.api_key
        else:
            auth = (self.user, self.password)
        url = f"{self.base_url}{path}"
        async with httpx.AsyncClient(timeout=self.timeout, verify=self.verify_tls) as client:
            resp = await client.request(method, url, headers=headers, json=json_payload, params=query, auth=auth)
        if resp.status_code >= 400:
            raise HTTPException(status_code=resp.status_code, detail=f"n8n API error: {resp.text[:600]}")
        try:
            return resp.json()
        except (json.JSONDecodeError, ValueError) as exc:
            raise HTTPException(status_code=502, detail=f"n8n returned invalid JSON: {exc}")

    def ensure_allowed_workflow(self, workflow_id: str) -> None:
        if self.allowed_workflows and workflow_id not in self.allowed_workflows:
            raise HTTPException(status_code=403, detail="WORKFLOW_NOT_ALLOWLISTED")


class KnowledgeBaseApi:
    def __init__(self) -> None:
        self.endpoint = os.getenv("KB_MINIO_ENDPOINT", "minio:9000").strip()
        self.access_key = os.getenv("KB_MINIO_ACCESS_KEY", "admin").strip()
        self.secret_key = os.getenv("KB_MINIO_SECRET_KEY", os.getenv("MINIO_ROOT_PASSWORD", "minio123456")).strip()
        self.secure = _env_bool("KB_MINIO_SECURE", False)
        self.public_bucket = os.getenv("KB_PUBLIC_BUCKET", "kb-public").strip() or "kb-public"
        self.private_bucket = os.getenv("KB_PRIVATE_BUCKET", "kb-private").strip() or "kb-private"
        self.index_prefix = os.getenv("KB_INDEX_PREFIX", ".index/").strip() or ".index/"
        if not self.index_prefix.endswith("/"):
            self.index_prefix += "/"
        self.max_object_bytes = _env_int("KB_MAX_OBJECT_BYTES", 10 * 1024 * 1024)
        self.max_extract_chars = _env_int("KB_MAX_EXTRACT_CHARS", 120000)
        self.tika_url = os.getenv("KB_TIKA_URL", "http://tika:9998").rstrip("/")
        self.tika_timeout = float(os.getenv("KB_TIKA_TIMEOUT_SECONDS", "45"))

    def _client(self) -> Minio:
        return Minio(
            self.endpoint,
            access_key=self.access_key,
            secret_key=self.secret_key,
            secure=self.secure,
        )

    def _ensure_bucket_sync(self, bucket: str) -> None:
        client = self._client()
        if not client.bucket_exists(bucket):
            client.make_bucket(bucket)

    async def ensure_bucket(self, bucket: str) -> None:
        await asyncio.to_thread(self._ensure_bucket_sync, bucket)

    @staticmethod
    def _validate_key(key: str) -> str:
        cleaned = key.strip().lstrip("/")
        if not cleaned:
            raise HTTPException(status_code=400, detail="key is required")
        if ".." in cleaned:
            raise HTTPException(status_code=400, detail="invalid key")
        return cleaned

    def _assert_bucket_allowed(self, bucket: str, *, public_request: bool) -> None:
        allowed = {self.public_bucket}
        if not public_request:
            allowed.add(self.private_bucket)
        if bucket not in allowed:
            raise HTTPException(status_code=403, detail="BUCKET_NOT_ALLOWED")

    def _put_object_sync(self, bucket: str, key: str, payload: bytes, content_type: str) -> None:
        client = self._client()
        stream = io.BytesIO(payload)
        client.put_object(bucket, key, stream, length=len(payload), content_type=content_type)

    async def put_object(self, bucket: str, key: str, payload: bytes, content_type: str = "application/octet-stream") -> None:
        await self.ensure_bucket(bucket)
        await asyncio.to_thread(self._put_object_sync, bucket, key, payload, content_type)

    def _get_object_bytes_sync(self, bucket: str, key: str) -> bytes:
        client = self._client()
        resp = client.get_object(bucket, key)
        try:
            return resp.read()
        finally:
            resp.close()
            resp.release_conn()

    async def get_object_bytes(self, bucket: str, key: str) -> bytes:
        return await asyncio.to_thread(self._get_object_bytes_sync, bucket, key)

    def _object_exists_sync(self, bucket: str, key: str) -> bool:
        client = self._client()
        try:
            client.stat_object(bucket, key)
            return True
        except S3Error:
            return False

    async def object_exists(self, bucket: str, key: str) -> bool:
        return await asyncio.to_thread(self._object_exists_sync, bucket, key)

    def _list_objects_sync(self, bucket: str, prefix: str, limit: int) -> list[str]:
        client = self._client()
        rows: list[str] = []
        for obj in client.list_objects(bucket, prefix=prefix, recursive=True):
            rows.append(obj.object_name)
            if len(rows) >= limit:
                break
        return rows

    async def list_objects(self, bucket: str, prefix: str, limit: int) -> list[str]:
        await self.ensure_bucket(bucket)
        return await asyncio.to_thread(self._list_objects_sync, bucket, prefix, limit)

    async def extract_text(self, payload: bytes, request_id: str) -> str:
        headers = {
            "Accept": "text/plain",
            "X-Request-ID": request_id,
            "Content-Type": "application/octet-stream",
        }
        async with httpx.AsyncClient(timeout=self.tika_timeout) as client:
            resp = await client.put(f"{self.tika_url}/tika", headers=headers, content=payload)
        if resp.status_code >= 400:
            raise HTTPException(status_code=502, detail=f"Tika extract failed: {resp.text[:300]}")
        text = resp.text or ""
        if len(text) > self.max_extract_chars:
            text = text[: self.max_extract_chars]
        return text


def _n8n_tool_schemas() -> list[dict[str, Any]]:
    return [
        {
            "name": "n8n_list_workflows",
            "description": "List non-archived n8n workflows. Archived workflows are hidden by default because they are not shown in the n8n UI either. active=false simply means the workflow is not auto-triggered — it is still a normal, editable workflow.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer", "minimum": 1, "maximum": 250, "default": 50},
                    "cursor": {"type": "string"},
                    "includeArchived": {"type": "boolean", "default": False, "description": "If true, include archived workflows in the results. Default: false."},
                },
            },
        },
        {
            "name": "n8n_get_workflow",
            "description": "Get one n8n workflow by id.",
            "inputSchema": {"type": "object", "required": ["id"], "properties": {"id": {"type": "string"}}},
        },
        {
            "name": "n8n_list_executions",
            "description": "List recent n8n executions.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer", "minimum": 1, "maximum": 250, "default": 25},
                    "workflowId": {"type": "string"},
                },
            },
        },
        {
            "name": "n8n_create_workflow",
            "description": "Create n8n workflow. Only use when n8n_list_workflows returns zero matches for the purpose. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["workflow", "confirm"],
                "properties": {
                    "confirm": {"type": "boolean"},
                    "workflow": {
                        "type": "object",
                        "description": "Workflow definition. Required keys: name (string), nodes (array of node objects with type, name, parameters, position), connections (object mapping node outputs to inputs). Optional: settings (object).",
                        "required": ["name", "nodes", "connections"],
                        "properties": {
                            "name": {"type": "string"},
                            "nodes": {"type": "array", "items": {"type": "object"}},
                            "connections": {"type": "object"},
                            "settings": {"type": "object"},
                        },
                    },
                },
            },
        },
        {
            "name": "n8n_update_workflow",
            "description": "Update an existing n8n workflow by replacing its definition. The workflow object fully replaces the old one (nodes, connections, name). Works on both active and inactive workflows. PREFER this over n8n_create_workflow when a similar workflow already exists. Requires id and confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["id", "workflow", "confirm"],
                "properties": {
                    "id": {"type": "string", "description": "The workflow ID to update."},
                    "confirm": {"type": "boolean"},
                    "workflow": {
                        "type": "object",
                        "description": "Replacement workflow definition. Required keys: name (string), nodes (array of node objects with type, name, parameters, position), connections (object mapping node outputs to inputs). Optional: settings (object).",
                        "required": ["name", "nodes", "connections"],
                        "properties": {
                            "name": {"type": "string"},
                            "nodes": {"type": "array", "items": {"type": "object"}},
                            "connections": {"type": "object"},
                            "settings": {"type": "object"},
                        },
                    },
                },
            },
        },
        {
            "name": "n8n_activate_workflow",
            "description": "Activate n8n workflow. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["id", "confirm"],
                "properties": {"id": {"type": "string"}, "confirm": {"type": "boolean"}},
            },
        },
        {
            "name": "n8n_deactivate_workflow",
            "description": "Deactivate n8n workflow. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["id", "confirm"],
                "properties": {"id": {"type": "string"}, "confirm": {"type": "boolean"}},
            },
        },
        {
            "name": "n8n_create_and_activate_workflow",
            "description": "Create + activate n8n workflow in one call. Only use when no matching workflow exists. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["workflow", "confirm"],
                "properties": {
                    "confirm": {"type": "boolean"},
                    "workflow": {
                        "type": "object",
                        "description": "Workflow definition. Required keys: name, nodes, connections. Optional: settings.",
                        "required": ["name", "nodes", "connections"],
                        "properties": {
                            "name": {"type": "string"},
                            "nodes": {"type": "array", "items": {"type": "object"}},
                            "connections": {"type": "object"},
                            "settings": {"type": "object"},
                        },
                    },
                },
            },
        },
        {
            "name": "n8n_run_webhook",
            "description": "Trigger an n8n webhook endpoint. Use 'test: true' for test webhooks during development.",
            "inputSchema": {
                "type": "object",
                "required": ["path"],
                "properties": {
                    "path": {"type": "string", "description": "Webhook path segment, e.g. 'my-webhook'. Must not contain '..' or start with '/'."},
                    "workflowId": {"type": "string", "description": "Optional workflow ID to scope the webhook."},
                    "method": {"type": "string", "enum": ["GET", "POST", "PUT", "PATCH", "DELETE"], "default": "POST"},
                    "test": {"type": "boolean", "default": False},
                    "body": {"type": "object"},
                    "query": {"type": "object"},
                },
            },
        },
        {
            "name": "n8n_get_execution",
            "description": "Get details of an n8n execution by id. Includes node results and error info for debugging.",
            "inputSchema": {"type": "object", "required": ["id"], "properties": {"id": {"type": "string"}}},
        },
        {
            "name": "n8n_delete_execution",
            "description": "Delete an n8n execution by id. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["id", "confirm"],
                "properties": {"id": {"type": "string"}, "confirm": {"type": "boolean"}},
            },
        },
        {
            "name": "n8n_delete_workflow",
            "description": "Permanently delete an n8n workflow by id. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["id", "confirm"],
                "properties": {"id": {"type": "string"}, "confirm": {"type": "boolean"}},
            },
        },
        {
            "name": "n8n_list_credentials",
            "description": "List available n8n credentials (names and types only, no secrets exposed).",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer", "minimum": 1, "maximum": 250, "default": 100},
                },
            },
        },
        {
            "name": "n8n_get_node_types",
            "description": "Look up n8n node type definitions including all parameters, options, defaults, credential requirements, and required fields. ALWAYS call this before creating or updating workflows to get the exact parameter schema for each node you plan to use. Search by keyword or exact type name. Use 'operation' to filter parameters to only those relevant for a specific mode/operation, dramatically reducing response size.",
            "inputSchema": {
                "type": "object",
                "required": ["query"],
                "properties": {
                    "query": {"type": "string", "description": "Search keyword (e.g. 'merge', 'http', 'agent') or exact node type name (e.g. 'n8n-nodes-base.merge', '@n8n/n8n-nodes-langchain.agent')."},
                    "includeParams": {"type": "boolean", "default": True, "description": "If true (default), include full parameter definitions. Set false for a compact list."},
                    "operation": {"type": "string", "description": "Filter parameters to only show those relevant for a specific operation/mode (e.g. 'combinebymatchingfields', 'get', 'post'). Greatly reduces response size for complex nodes."},
                },
            },
        },
        {
            "name": "n8n_diagnose_workflow",
            "description": "Run diagnostics on a workflow: validate all node types exist, check most recent execution for per-node errors, and return actionable fix suggestions. Optionally trigger a test execution via webhook. Call this AFTER creating/updating a workflow to verify correctness.",
            "inputSchema": {
                "type": "object",
                "required": ["id"],
                "properties": {
                    "id": {"type": "string", "description": "Workflow ID to diagnose."},
                    "testPayload": {"type": "object", "description": "If provided AND the workflow has a webhook trigger, sends this payload to the webhook-test endpoint to trigger a live test execution. The per-node results are included in the diagnosis."},
                },
            },
        },
        {
            "name": "n8n_reference",
            "description": "Get n8n reference documentation: expression syntax, common error fixes, and workflow templates. ALWAYS consult 'expressions' before writing any expressions in workflow parameters. Consult 'pitfalls' when an execution fails. Consult 'templates' to see proven workflow patterns before building from scratch.",
            "inputSchema": {
                "type": "object",
                "required": ["topic"],
                "properties": {
                    "topic": {
                        "type": "string",
                        "enum": ["expressions", "pitfalls", "templates", "credentials"],
                        "description": "Reference topic: 'expressions' for n8n expression syntax, 'pitfalls' for common error fixes, 'templates' for workflow patterns, 'credentials' for how to wire credentials into nodes.",
                    },
                },
            },
        },
    ]


def _kb_tool_schemas() -> list[dict[str, Any]]:
    return [
        {
            "name": "kb_list_objects",
            "description": "List objects from knowledge base bucket.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "bucket": {"type": "string"},
                    "prefix": {"type": "string"},
                    "limit": {"type": "integer", "minimum": 1, "maximum": 200, "default": 50},
                },
            },
        },
        {
            "name": "kb_get_object",
            "description": "Get object content (text/base64) from bucket.",
            "inputSchema": {
                "type": "object",
                "required": ["key"],
                "properties": {
                    "bucket": {"type": "string"},
                    "key": {"type": "string"},
                    "asText": {"type": "boolean", "default": True},
                    "maxChars": {"type": "integer", "minimum": 1, "maximum": 200000, "default": 6000},
                },
            },
        },
        {
            "name": "kb_extract_text",
            "description": "Extract text from an object using Tika.",
            "inputSchema": {
                "type": "object",
                "required": ["key"],
                "properties": {"bucket": {"type": "string"}, "key": {"type": "string"}},
            },
        },
        {
            "name": "kb_search",
            "description": "Search indexed knowledge entries.",
            "inputSchema": {
                "type": "object",
                "required": ["query"],
                "properties": {
                    "bucket": {"type": "string"},
                    "query": {"type": "string"},
                    "limit": {"type": "integer", "minimum": 1, "maximum": 100, "default": 20},
                },
            },
        },
        {
            "name": "kb_put_object",
            "description": "Upload text or base64 payload to bucket. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["key", "confirm"],
                "properties": {
                    "bucket": {"type": "string"},
                    "key": {"type": "string"},
                    "confirm": {"type": "boolean"},
                    "text": {"type": "string"},
                    "contentBase64": {"type": "string"},
                    "contentType": {"type": "string"},
                },
            },
        },
        {
            "name": "kb_index_document",
            "description": "Extract and index a document into searchable JSON index. Requires confirm=true.",
            "inputSchema": {
                "type": "object",
                "required": ["key", "confirm"],
                "properties": {
                    "bucket": {"type": "string"},
                    "key": {"type": "string"},
                    "confirm": {"type": "boolean"},
                    "title": {"type": "string"},
                    "tags": {"type": "array", "items": {"type": "string"}},
                },
            },
        },
    ]


affine_conn = AffineMcpConnection()
n8n_api = N8nApi()
kb_api = KnowledgeBaseApi()

_n8n_node_types: list[dict[str, Any]] = []
_node_types_path = Path("/app/n8n_node_types.json")
_node_types_loaded_at: str = ""


def _reload_node_types() -> int:
    """(Re)load node type definitions from disk. Returns count loaded."""
    global _n8n_node_types, _node_types_loaded_at
    if not _node_types_path.exists():
        logger.warning("Node types file not found at %s", _node_types_path)
        return 0
    try:
        data = json.loads(_node_types_path.read_text(encoding="utf-8"))
        if isinstance(data, list):
            _n8n_node_types = data
            _node_types_loaded_at = _now_iso()
            logger.info("Loaded %d n8n node type definitions from %s", len(data), _node_types_path)
            return len(data)
    except Exception:
        logger.exception("Failed to load n8n node types from %s", _node_types_path)
    return 0


_reload_node_types()
quota_manager = QuotaManager()
circuit_breaker = CircuitBreaker()
proof_store = JsonStore("MCP_PROOF_STORE_PATH", "/var/lib/mcp-gateway/proof-store.json")
dedupe_store = JsonStore("MCP_DEDUPE_STORE_PATH", "/var/lib/mcp-gateway/dedupe-store.json")
dlq_store = JsonStore("MCP_DLQ_STORE_PATH", "/var/lib/mcp-gateway/dlq-store.json")
langgraph_supervisor_url = os.getenv("LANGGRAPH_SUPERVISOR_URL", "http://ai_langgraph_supervisor:9010").rstrip("/")
# Empty LANGGRAPH_SUPERVISOR_TOKEN in the environment must fall back to MCP_GATEWAY_TOKEN (getenv default only applies when unset).
_lg_sup_raw = os.getenv("LANGGRAPH_SUPERVISOR_TOKEN") or ""
langgraph_supervisor_token = (_lg_sup_raw.strip() if _lg_sup_raw.strip() else os.getenv("MCP_GATEWAY_TOKEN", "")).strip()


def _request_id(payload: InvokePayload) -> str:
    return payload.requestId.strip() if payload.requestId else str(uuid.uuid4())


def _apply_contract_defaults(payload: InvokePayload, request_id: str) -> None:
    if not (payload.tenantId or "").strip():
        payload.tenantId = os.getenv("MCP_DEFAULT_TENANT_ID", "oweb-default")
    if not (payload.actorId or "").strip():
        payload.actorId = os.getenv("MCP_DEFAULT_ACTOR_ID", "oweb-operator")
    if not (payload.conversationId or "").strip():
        prefix = os.getenv("MCP_DEFAULT_CONVERSATION_PREFIX", "oweb")
        payload.conversationId = f"{prefix}-{request_id[:12]}"
    if not (payload.intentHash or "").strip():
        raw = json.dumps(
            {"tool": payload.tool.strip(), "arguments": payload.arguments},
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
        payload.intentHash = hashlib.sha256(raw).hexdigest()[:16]


def _check_auth(auth_header: str | None) -> None:
    expected_token = os.getenv("MCP_GATEWAY_TOKEN", "").strip()
    if not expected_token:
        raise HTTPException(status_code=500, detail="MCP_GATEWAY_TOKEN is not configured")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split(" ", 1)[1].strip()
    if not hmac.compare_digest(token, expected_token):
        raise HTTPException(status_code=401, detail="Invalid token")


def _auth_header_from_credentials(
    authorization: str | None,
    credentials: HTTPAuthorizationCredentials | None,
    api_key: str | None,
) -> str | None:
    if authorization:
        return authorization
    if credentials:
        return f"{credentials.scheme} {credentials.credentials}"
    if api_key:
        return f"Bearer {api_key}"
    return None


def _write_approval_required() -> bool:
    return _env_bool("MCP_WRITE_APPROVAL_REQUIRED", False)


def _write_approval_tokens() -> set[str]:
    raw = os.getenv("MCP_WRITE_APPROVAL_TOKENS", "").strip()
    return {x.strip() for x in raw.split(",") if x.strip()}


def _enforce_write_approval(tool: str, arguments: dict[str, Any], header_token: str | None) -> None:
    if not _is_write_tool(tool) or not _write_approval_required():
        return
    provided = str(arguments.pop("approvalToken", "")).strip() or str(header_token or "").strip()
    if not provided:
        raise HTTPException(status_code=403, detail="APPROVAL_REQUIRED")
    allowed = _write_approval_tokens()
    if allowed and provided not in allowed:
        raise HTTPException(status_code=403, detail="APPROVAL_INVALID")


def _is_write_tool(tool: str) -> bool:
    return tool in {
        "n8n_create_workflow",
        "n8n_update_workflow",
        "n8n_activate_workflow",
        "n8n_deactivate_workflow",
        "n8n_create_and_activate_workflow",
        "n8n_run_webhook",
        "n8n_delete_workflow",
        "n8n_delete_execution",
        "kb_put_object",
        "kb_index_document",
    }


def _is_supervisor_delegated_tool(tool: str) -> bool:
    return tool.startswith("n8n_") and _is_write_tool(tool)


def _is_kb_tool(tool: str) -> bool:
    return tool.startswith("kb_")


def _is_kb_read_tool(tool: str) -> bool:
    return tool in {"kb_list_objects", "kb_get_object", "kb_extract_text", "kb_search"}


def _dedupe_key(payload: InvokePayload) -> str:
    stable = {
        "tenantId": payload.tenantId,
        "conversationId": payload.conversationId,
        "intentHash": payload.intentHash,
        "tool": payload.tool,
        "arguments": payload.arguments,
    }
    raw = json.dumps(stable, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _sign_proof(item: dict[str, Any]) -> str:
    secret = os.getenv("MCP_PROOF_SIGNING_KEY", os.getenv("MCP_GATEWAY_TOKEN", ""))
    if not secret:
        return ""
    canonical = json.dumps(item, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hmac.new(secret.encode("utf-8"), canonical, hashlib.sha256).hexdigest()


def _as_tool_response(envelope: dict[str, Any]) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": json.dumps(envelope)}], "error": None}


async def _invoke_langgraph_supervisor(payload: InvokePayload, request_id: str) -> dict[str, Any]:
    if not langgraph_supervisor_token:
        raise HTTPException(status_code=500, detail="LangGraph supervisor auth not configured (set MCP_GATEWAY_TOKEN or LANGGRAPH_SUPERVISOR_TOKEN)")
    body = {
        "tenantId": payload.tenantId,
        "actorId": payload.actorId,
        "conversationId": payload.conversationId,
        "intentHash": payload.intentHash,
        "tool": payload.tool,
        "arguments": payload.arguments,
        "requestId": request_id,
    }
    headers = {
        "Authorization": f"Bearer {langgraph_supervisor_token}",
        "Content-Type": "application/json",
        "X-Request-ID": request_id,
    }
    timeout = float(os.getenv("LANGGRAPH_SUPERVISOR_TIMEOUT_SECONDS", "45"))
    async with httpx.AsyncClient(timeout=timeout) as client:
        response = await client.post(f"{langgraph_supervisor_url}/execute", headers=headers, json=body)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=f"LangGraph supervisor error: {response.text[:600]}")
    try:
        data = response.json()
        if not isinstance(data, dict):
            raise ValueError("non-object response")
        return data
    except Exception:
        raise HTTPException(status_code=502, detail="LangGraph supervisor returned invalid JSON")


async def _verify_execution_candidate(workflow_id: str, request_id: str) -> dict[str, Any]:
    n8n_api.ensure_allowed_workflow(workflow_id)
    data = await n8n_api.request("GET", "/api/v1/executions", request_id, query={"workflowId": workflow_id, "limit": 1})
    rows = data.get("data", [])
    if not rows:
        return {"verified": False, "reason": "NO_EXECUTIONS_FOUND"}
    row = rows[0]
    return {
        "verified": True,
        "executionId": str(row.get("id", "")),
        "status": str(row.get("status", "unknown")),
        "finished": bool(row.get("finished", False)),
    }


async def _verify_workflow_state(
    workflow_id: str,
    request_id: str,
    *,
    expected_active: bool | None = None,
) -> dict[str, Any]:
    n8n_api.ensure_allowed_workflow(workflow_id)
    data = await n8n_api.request("GET", f"/api/v1/workflows/{workflow_id}", request_id)
    if not isinstance(data, dict):
        return {"verified": False, "reason": "WORKFLOW_LOOKUP_INVALID"}
    active = bool(data.get("active", False))
    if expected_active is not None and active != expected_active:
        return {
            "verified": False,
            "reason": "WORKFLOW_STATE_MISMATCH",
            "expectedActive": expected_active,
            "actualActive": active,
            "workflowId": workflow_id,
        }
    return {
        "verified": True,
        "reason": "WORKFLOW_STATE_CONFIRMED",
        "workflowId": workflow_id,
        "active": active,
    }


async def _verify_write_result(
    tool: str,
    result: dict[str, Any],
    arguments: dict[str, Any],
    request_id: str,
) -> dict[str, Any]:
    if _is_kb_tool(tool):
        return {
            "verified": bool(result.get("verified", True)),
            "reason": str(result.get("verificationReason", "KB_WRITE_CONFIRMED")),
        }

    workflow_id = str(result.get("workflow_id", "")).strip() or str(arguments.get("id", "")).strip()

    if tool == "n8n_run_webhook":
        endpoint = str(result.get("endpoint", "")).strip()
        return {
            "verified": True,
            "reason": "WEBHOOK_HTTP_2XX",
            "endpoint": endpoint,
            "workflowId": str(result.get("workflow_id", "")).strip(),
        }

    if not workflow_id:
        return {"verified": False, "reason": "NO_WORKFLOW_ID"}

    if tool in {"n8n_create_workflow", "n8n_update_workflow"}:
        return await _verify_workflow_state(workflow_id, request_id)
    if tool in {"n8n_activate_workflow", "n8n_create_and_activate_workflow"}:
        return await _verify_workflow_state(workflow_id, request_id, expected_active=True)
    if tool == "n8n_deactivate_workflow":
        return await _verify_workflow_state(workflow_id, request_id, expected_active=False)
    if tool in {"n8n_delete_workflow", "n8n_delete_execution"}:
        try:
            endpoint = f"/api/v1/workflows/{workflow_id}" if tool == "n8n_delete_workflow" else f"/api/v1/executions/{workflow_id}"
            await n8n_api.request("GET", endpoint, request_id)
            return {"verified": False, "reason": "RESOURCE_STILL_EXISTS", "workflowId": workflow_id}
        except HTTPException as exc:
            if exc.status_code == 404:
                return {"verified": True, "reason": "RESOURCE_DELETED", "workflowId": workflow_id}
            return {"verified": False, "reason": f"VERIFICATION_ERROR: {exc.detail}"}

    return await _verify_execution_candidate(workflow_id, request_id)


def _normalize_aliases(tool: str, arguments: dict[str, Any]) -> dict[str, Any]:
    if tool == "n8n_list_executions" and "workflow_id" in arguments and "workflowId" not in arguments:
        arguments["workflowId"] = arguments.pop("workflow_id")
    return arguments


_N8N_WORKFLOW_ALLOWED_FIELDS = {"name", "nodes", "connections", "settings"}
_N8N_SETTINGS_ALLOWED_FIELDS = {
    "executionOrder", "callerPolicy", "availableInMCP",
    "saveDataSuccessExecution", "saveDataErrorExecution",
    "saveManualExecutions", "timezone", "executionTimeout",
    "maxExecutionTimeout", "saveExecutionProgress",
    "callerIds", "errorWorkflow",
}


def _coerce_workflow(raw: Any) -> dict[str, Any]:
    """Accept a workflow as dict or JSON string; raise 400 otherwise."""
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        raw = raw.strip()
        if raw.startswith("{"):
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, dict):
                    return parsed
            except (json.JSONDecodeError, ValueError):
                pass
    raise HTTPException(status_code=400, detail="workflow must be an object (got %s)" % type(raw).__name__)


def _sanitize_workflow_payload(workflow: dict[str, Any]) -> dict[str, Any]:
    """Keep only fields n8n accepts on create/update; strip everything else."""
    cleaned = {k: v for k, v in workflow.items() if k in _N8N_WORKFLOW_ALLOWED_FIELDS}
    raw_settings = cleaned.get("settings")
    if isinstance(raw_settings, dict):
        cleaned["settings"] = {k: v for k, v in raw_settings.items() if k in _N8N_SETTINGS_ALLOWED_FIELDS}
    else:
        cleaned["settings"] = {}
    if "name" not in cleaned:
        cleaned["name"] = "Untitled Workflow"
    return cleaned


def _validate_workflow_nodes(workflow: dict[str, Any]) -> list[str]:
    """Validate node types and basic structure. Returns list of warnings (empty = ok)."""
    if not _n8n_node_types:
        return []
    known_types = {str(n.get("name", "")) for n in _n8n_node_types}
    known_lower = {t.lower(): t for t in known_types}
    nodes = workflow.get("nodes", [])
    warnings: list[str] = []
    if not isinstance(nodes, list) or len(nodes) == 0:
        warnings.append("Workflow has no nodes.")
        return warnings
    node_names_seen: set[str] = set()
    for i, node in enumerate(nodes):
        if not isinstance(node, dict):
            warnings.append(f"Node {i}: not an object.")
            continue
        ntype = str(node.get("type", ""))
        nname = str(node.get("name", f"node_{i}"))
        if not ntype:
            warnings.append(f"Node '{nname}': missing 'type' field.")
            continue
        if ntype not in known_types and ntype.lower() not in known_lower:
            suffix = ntype.split(".")[-1].lower()
            close = [v for k, v in known_lower.items() if suffix in k][:3]
            hint = f" Did you mean: {', '.join(close)}?" if close else ""
            warnings.append(f"Node '{nname}': unknown type '{ntype}'.{hint}")
        if nname in node_names_seen:
            warnings.append(f"Node '{nname}': duplicate name.")
        node_names_seen.add(nname)
        if "position" not in node:
            warnings.append(f"Node '{nname}': missing 'position' field.")
    connections = workflow.get("connections", {})
    if isinstance(connections, dict):
        for src, conn_data in connections.items():
            if src not in node_names_seen:
                warnings.append(f"Connection from '{src}': source node not found in node list.")
    return warnings


async def _invoke_n8n_tool(tool: str, arguments: dict[str, Any], request_id: str) -> dict[str, Any]:
    if tool == "n8n_list_workflows":
        include_archived = arguments.get("includeArchived", False)
        query = {"limit": int(arguments.get("limit", 50))}
        if arguments.get("cursor"):
            query["cursor"] = str(arguments["cursor"])
        data = await n8n_api.request("GET", "/api/v1/workflows", request_id, query=query)
        raw_list = data if isinstance(data, list) else data.get("data", data.get("results", []))
        if isinstance(raw_list, list):
            summaries = []
            for wf in raw_list:
                if not isinstance(wf, dict):
                    continue
                if not include_archived and wf.get("isArchived"):
                    continue
                nodes = wf.get("nodes", [])
                summaries.append({
                    "id": wf.get("id"),
                    "name": wf.get("name"),
                    "active": wf.get("active"),
                    "nodeCount": len(nodes) if isinstance(nodes, list) else None,
                    "createdAt": wf.get("createdAt"),
                    "updatedAt": wf.get("updatedAt"),
                    "tags": [t.get("name", t) for t in wf.get("tags", []) if isinstance(t, dict)] if wf.get("tags") else [],
                })
            return {"result": summaries, "total": len(summaries)}
        return {"result": data}

    if tool == "n8n_get_workflow":
        workflow_id = str(arguments.get("id", "")).strip()
        if not workflow_id:
            raise HTTPException(status_code=400, detail="id is required")
        n8n_api.ensure_allowed_workflow(workflow_id)
        data = await n8n_api.request("GET", f"/api/v1/workflows/{workflow_id}", request_id)
        return {"result": data}

    if tool == "n8n_list_executions":
        query = {"limit": int(arguments.get("limit", 25))}
        workflow_id = str(arguments.get("workflowId", "")).strip()
        if workflow_id:
            n8n_api.ensure_allowed_workflow(workflow_id)
            query["workflowId"] = workflow_id
        data = await n8n_api.request("GET", "/api/v1/executions", request_id, query=query)
        raw_list = data if isinstance(data, list) else data.get("data", data.get("results", []))
        if isinstance(raw_list, list):
            summaries = []
            for ex in raw_list:
                if not isinstance(ex, dict):
                    continue
                entry: dict[str, Any] = {
                    "id": ex.get("id"),
                    "workflowId": ex.get("workflowId"),
                    "status": ex.get("status", "unknown"),
                    "finished": ex.get("finished"),
                    "startedAt": ex.get("startedAt"),
                    "stoppedAt": ex.get("stoppedAt"),
                    "mode": ex.get("mode"),
                }
                summaries.append(entry)
            return {"result": summaries, "total": len(summaries)}
        return {"result": data}

    if tool == "n8n_create_workflow":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        workflow = _coerce_workflow(arguments.get("workflow"))
        workflow = _sanitize_workflow_payload(workflow)
        validation_warnings = _validate_workflow_nodes(workflow)
        if any("unknown type" in w for w in validation_warnings):
            raise HTTPException(status_code=400, detail="Workflow validation failed: " + "; ".join(validation_warnings))
        data = await n8n_api.request("POST", "/api/v1/workflows", request_id, json_payload=workflow)
        result: dict[str, Any] = {"result": data, "workflow_id": str(data.get("id", ""))}
        if validation_warnings:
            result["warnings"] = validation_warnings
        return result

    if tool == "n8n_update_workflow":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        workflow_id = str(arguments.get("id", "")).strip()
        if not workflow_id:
            raise HTTPException(status_code=400, detail="id is required")
        n8n_api.ensure_allowed_workflow(workflow_id)
        workflow = _coerce_workflow(arguments.get("workflow"))
        workflow = _sanitize_workflow_payload(workflow)
        validation_warnings = _validate_workflow_nodes(workflow)
        if any("unknown type" in w for w in validation_warnings):
            raise HTTPException(status_code=400, detail="Workflow validation failed: " + "; ".join(validation_warnings))
        try:
            data = await n8n_api.request("PUT", f"/api/v1/workflows/{workflow_id}", request_id, json_payload=workflow)
        except HTTPException as put_exc:
            if put_exc.status_code == 400 and "trigger" in str(put_exc.detail).lower():
                await n8n_api.request("POST", f"/api/v1/workflows/{workflow_id}/deactivate", request_id)
                data = await n8n_api.request("PUT", f"/api/v1/workflows/{workflow_id}", request_id, json_payload=workflow)
            else:
                raise
        result = {"result": data, "workflow_id": workflow_id}
        if validation_warnings:
            result["warnings"] = validation_warnings
        return result

    if tool == "n8n_activate_workflow":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        workflow_id = str(arguments.get("id", "")).strip()
        if not workflow_id:
            raise HTTPException(status_code=400, detail="id is required")
        n8n_api.ensure_allowed_workflow(workflow_id)
        data = await n8n_api.request("POST", f"/api/v1/workflows/{workflow_id}/activate", request_id)
        return {"result": data, "workflow_id": workflow_id}

    if tool == "n8n_deactivate_workflow":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        workflow_id = str(arguments.get("id", "")).strip()
        if not workflow_id:
            raise HTTPException(status_code=400, detail="id is required")
        n8n_api.ensure_allowed_workflow(workflow_id)
        data = await n8n_api.request("POST", f"/api/v1/workflows/{workflow_id}/deactivate", request_id)
        return {"result": data, "workflow_id": workflow_id}

    if tool == "n8n_create_and_activate_workflow":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        workflow = _coerce_workflow(arguments.get("workflow"))
        workflow = _sanitize_workflow_payload(workflow)
        validation_warnings = _validate_workflow_nodes(workflow)
        if any("unknown type" in w for w in validation_warnings):
            raise HTTPException(status_code=400, detail="Workflow validation failed: " + "; ".join(validation_warnings))
        created = await n8n_api.request("POST", "/api/v1/workflows", request_id, json_payload=workflow)
        workflow_id = str(created.get("id", "")).strip()
        activated = {"active": False}
        activation_error = None
        if workflow_id:
            n8n_api.ensure_allowed_workflow(workflow_id)
            try:
                activated = await n8n_api.request("POST", f"/api/v1/workflows/{workflow_id}/activate", request_id)
            except HTTPException as act_exc:
                activation_error = str(act_exc.detail)
                logger.warning("Workflow %s created but activation failed: %s", workflow_id, activation_error)
        result = {"result": {"created": created, "activated": activated}, "workflow_id": workflow_id}
        if activation_error:
            result["activationError"] = activation_error
        if validation_warnings:
            result["warnings"] = validation_warnings
        return result

    if tool == "n8n_run_webhook":
        path = str(arguments.get("path", "")).strip().lstrip("/")
        if not path:
            raise HTTPException(status_code=400, detail="path is required")
        if ".." in path or path.startswith("/"):
            raise HTTPException(status_code=400, detail="invalid webhook path")
        method = str(arguments.get("method", "POST")).upper()
        use_test = bool(arguments.get("test", False))
        body = arguments.get("body") if isinstance(arguments.get("body"), dict) else {}
        query = arguments.get("query") if isinstance(arguments.get("query"), dict) else {}
        workflow_id = str(arguments.get("workflowId", "")).strip()
        endpoint = "/webhook-test/" if use_test else "/webhook/"
        candidates = [f"{endpoint}{path}"]
        if workflow_id:
            n8n_api.ensure_allowed_workflow(workflow_id)
            candidates.append(f"{endpoint}{workflow_id}/webhook/{path}")
        seen = set()
        dedup = []
        for c in candidates:
            if c not in seen:
                seen.add(c)
                dedup.append(c)
        last_error: HTTPException | None = None
        for candidate in dedup:
            try:
                result = await n8n_api.request(method, candidate, request_id, json_payload=body, query=query)
                return {"result": result, "endpoint": candidate, "workflow_id": workflow_id}
            except HTTPException as exc:
                if exc.status_code not in {404, 405}:
                    raise
                last_error = exc
        if last_error:
            raise last_error
        raise HTTPException(status_code=404, detail="No matching webhook endpoint")

    if tool == "n8n_get_execution":
        exec_id = str(arguments.get("id", "")).strip()
        if not exec_id:
            raise HTTPException(status_code=400, detail="id is required")
        data = await n8n_api.request("GET", f"/api/v1/executions/{exec_id}", request_id,
                                     query={"includeData": "true"})
        summary: dict[str, Any] = {
            "id": data.get("id"),
            "finished": data.get("finished"),
            "status": data.get("status", "unknown"),
            "workflowId": data.get("workflowId"),
            "startedAt": data.get("startedAt"),
            "stoppedAt": data.get("stoppedAt"),
            "mode": data.get("mode"),
        }
        result_data = data.get("data", {})
        if not isinstance(result_data, dict):
            result_data = {}
        run_data = result_data.get("resultData", {})
        if not isinstance(run_data, dict):
            run_data = {}
        top_error = run_data.get("error")
        if isinstance(top_error, dict):
            summary["error"] = top_error.get("message", str(top_error))
            err_node = top_error.get("node")
            if isinstance(err_node, dict):
                summary["errorNode"] = err_node.get("name", "unknown")
                summary["errorNodeType"] = err_node.get("type", "unknown")
            summary["errorDescription"] = top_error.get("description", "")
        node_results: dict[str, Any] = {}
        for node_name, task_data_list in run_data.get("runData", {}).items():
            if not isinstance(task_data_list, list):
                continue
            last_run = task_data_list[-1] if task_data_list else {}
            node_info: dict[str, Any] = {
                "startTime": last_run.get("startTime"),
                "executionTime": last_run.get("executionTime"),
                "status": "error" if last_run.get("error") else "success",
            }
            if last_run.get("error"):
                err = last_run["error"]
                if isinstance(err, dict):
                    node_info["error"] = err.get("message", str(err))
                    node_info["errorDescription"] = err.get("description", "")
                    node_info["errorHint"] = err.get("hint", "")
                else:
                    node_info["error"] = str(err)
            out_main = last_run.get("data", {}).get("main", [])
            if out_main and isinstance(out_main, list):
                first_branch = out_main[0] if out_main else []
                if isinstance(first_branch, list):
                    node_info["outputCount"] = len(first_branch)
                    if first_branch:
                        sample = first_branch[0].get("json", {}) if isinstance(first_branch[0], dict) else {}
                        node_info["sampleOutput"] = {k: v for i, (k, v) in enumerate(sample.items()) if i < 5}
            node_results[node_name] = node_info
        if node_results:
            summary["nodeResults"] = node_results
        return {"result": summary}

    if tool == "n8n_delete_execution":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        exec_id = str(arguments.get("id", "")).strip()
        if not exec_id:
            raise HTTPException(status_code=400, detail="id is required")
        data = await n8n_api.request("DELETE", f"/api/v1/executions/{exec_id}", request_id)
        return {"result": data}

    if tool == "n8n_delete_workflow":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        workflow_id = str(arguments.get("id", "")).strip()
        if not workflow_id:
            raise HTTPException(status_code=400, detail="id is required")
        n8n_api.ensure_allowed_workflow(workflow_id)
        data = await n8n_api.request("DELETE", f"/api/v1/workflows/{workflow_id}", request_id)
        return {"result": data, "workflow_id": workflow_id}

    if tool == "n8n_list_credentials":
        query = {"limit": int(arguments.get("limit", 100))}
        data = await n8n_api.request("GET", "/api/v1/credentials", request_id, query=query)
        creds = data if isinstance(data, list) else data.get("data", [])
        safe = [{"id": c.get("id"), "name": c.get("name"), "type": c.get("type"), "createdAt": c.get("createdAt")} for c in creds if isinstance(c, dict)]
        return {"result": safe}

    if tool == "n8n_get_node_types":
        search = str(arguments.get("query", "")).strip().lower()
        include_params = arguments.get("includeParams", True)
        filter_operation = str(arguments.get("operation", "")).strip().lower() if arguments.get("operation") else None
        if not search:
            raise HTTPException(status_code=400, detail="query is required")
        matches = []
        for node in _n8n_node_types:
            node_name = str(node.get("name", "")).lower()
            display = str(node.get("displayName", "")).lower()
            desc = str(node.get("description", "")).lower()
            if search == node_name or search in node_name or search in display or search in desc:
                if include_params:
                    entry = dict(node)
                    if filter_operation:
                        filtered_props = []
                        for p in entry.get("properties", []):
                            show_conditions = p.get("displayOptions", {}).get("show", {})
                            if not show_conditions:
                                filtered_props.append(p)
                                continue
                            all_values = []
                            for cond_values in show_conditions.values():
                                if isinstance(cond_values, list):
                                    all_values.extend(str(v).lower() for v in cond_values)
                            if any(filter_operation in v for v in all_values):
                                filtered_props.append(p)
                            elif not all_values:
                                filtered_props.append(p)
                        entry["properties"] = filtered_props
                        entry["_filteredByOperation"] = filter_operation
                    matches.append(entry)
                else:
                    matches.append({
                        "name": node.get("name"),
                        "displayName": node.get("displayName"),
                        "description": node.get("description"),
                        "version": node.get("version"),
                        "credentials": node.get("credentials", []),
                        "paramCount": len(node.get("properties", [])),
                    })
            if len(matches) >= 15:
                break
        return {"result": {"nodes": matches, "matchCount": len(matches), "totalAvailable": len(_n8n_node_types)}}

    if tool == "n8n_diagnose_workflow":
        workflow_id = str(arguments.get("id", "")).strip()
        if not workflow_id:
            raise HTTPException(status_code=400, detail="id is required")
        n8n_api.ensure_allowed_workflow(workflow_id)
        test_body = arguments.get("testPayload")
        wf = await n8n_api.request("GET", f"/api/v1/workflows/{workflow_id}", request_id)
        diag: dict[str, Any] = {
            "workflowId": workflow_id,
            "name": wf.get("name"),
            "active": wf.get("active"),
            "nodeCount": len(wf.get("nodes", [])),
        }
        node_validation = _validate_workflow_nodes(wf)
        diag["structuralWarnings"] = node_validation if node_validation else []

        has_trigger = any(
            "trigger" in str(n.get("type", "")).lower()
            for n in wf.get("nodes", []) if isinstance(n, dict)
        )
        has_code = any(
            n.get("type") in ("n8n-nodes-base.code", "n8n-nodes-base.function", "n8n-nodes-base.functionItem")
            for n in wf.get("nodes", []) if isinstance(n, dict)
        )
        webhook_path = None
        for n in wf.get("nodes", []):
            if isinstance(n, dict) and n.get("type") == "n8n-nodes-base.webhook":
                webhook_path = n.get("parameters", {}).get("path", "")
                break
        diag["hasTrigger"] = has_trigger
        diag["hasCodeNodes"] = has_code
        diag["webhookPath"] = webhook_path
        if has_code:
            code_nodes = [n.get("name") for n in wf.get("nodes", [])
                          if isinstance(n, dict) and n.get("type") in ("n8n-nodes-base.code", "n8n-nodes-base.function", "n8n-nodes-base.functionItem")]
            diag["codeNodeNames"] = code_nodes

        if test_body is not None and webhook_path:
            import asyncio
            test_result: dict[str, Any] = {"triggered": False}
            try:
                body = test_body if isinstance(test_body, dict) else {}
                resp = await n8n_api.request("POST", f"/webhook-test/{webhook_path}", request_id, json_payload=body)
                test_result = {"triggered": True, "response": resp}
            except HTTPException as wh_exc:
                test_result = {"triggered": False, "error": str(wh_exc.detail)}
            diag["testExecution"] = test_result
            if test_result.get("triggered"):
                await asyncio.sleep(2)

        exec_data = await n8n_api.request("GET", "/api/v1/executions", request_id,
                                           query={"workflowId": workflow_id, "limit": "5"})
        exec_list = exec_data if isinstance(exec_data, list) else exec_data.get("data", [])
        exec_summary = []
        node_errors: list[dict[str, Any]] = []
        for ex in (exec_list if isinstance(exec_list, list) else []):
            if not isinstance(ex, dict):
                continue
            exec_entry = {
                "id": ex.get("id"),
                "status": ex.get("status"),
                "startedAt": ex.get("startedAt"),
                "stoppedAt": ex.get("stoppedAt"),
            }
            exec_summary.append(exec_entry)
            if ex.get("status") == "error":
                try:
                    detail = await n8n_api.request("GET", f"/api/v1/executions/{ex['id']}", request_id,
                                                   query={"includeData": "true"})
                    rd = detail.get("data", {}).get("resultData", {}) if isinstance(detail.get("data"), dict) else {}
                    top_err = rd.get("error", {})
                    if isinstance(top_err, dict) and top_err.get("message"):
                        err_entry: dict[str, Any] = {
                            "executionId": ex["id"],
                            "error": top_err.get("message"),
                            "description": top_err.get("description", ""),
                        }
                        err_node = top_err.get("node")
                        if isinstance(err_node, dict):
                            err_entry["nodeName"] = err_node.get("name")
                            err_entry["nodeType"] = err_node.get("type")
                        node_errors.append(err_entry)
                    for nn, tasks in rd.get("runData", {}).items():
                        if not isinstance(tasks, list):
                            continue
                        last = tasks[-1] if tasks else {}
                        if last.get("error"):
                            e = last["error"]
                            node_errors.append({
                                "executionId": ex["id"],
                                "nodeName": nn,
                                "error": e.get("message", str(e)) if isinstance(e, dict) else str(e),
                                "description": e.get("description", "") if isinstance(e, dict) else "",
                            })
                except Exception:
                    logger.debug("Could not fetch execution detail for %s", ex.get("id"))
                if len(node_errors) >= 10:
                    break

        diag["recentExecutions"] = exec_summary
        diag["nodeErrors"] = node_errors

        suggestions = []
        if node_validation:
            suggestions.append("Fix structural warnings: " + "; ".join(node_validation[:3]))
        if not has_trigger:
            suggestions.append("Workflow has no trigger node — it cannot be auto-activated. Add a Webhook, Schedule, or Manual trigger.")
        if has_code:
            suggestions.append(f"Consider replacing Code nodes ({', '.join(diag.get('codeNodeNames', []))}) with native n8n nodes.")
        for ne in node_errors[:3]:
            suggestions.append(f"Fix error in '{ne.get('nodeName', '?')}': {ne.get('error', '?')}")
        if webhook_path and not test_body:
            suggestions.append(f"This workflow has a webhook at '{webhook_path}'. Re-run diagnose with testPayload to trigger a test execution.")
        diag["suggestions"] = suggestions
        return {"result": diag}

    if tool == "n8n_reference":
        topic = str(arguments.get("topic", "")).strip().lower()
        refs: dict[str, Any] = {}

        if topic == "expressions":
            refs = {
                "topic": "n8n Expression Syntax",
                "overview": "n8n uses expressions enclosed in ={{ }} to reference data dynamically. Expressions are JavaScript-based.",
                "syntax": {
                    "current_item": {
                        "pattern": "={{ $json.fieldName }}",
                        "description": "Access a field from the current item's JSON data.",
                        "examples": ["={{ $json.email }}", "={{ $json.body.url }}", "={{ $json.data[0].name }}"],
                    },
                    "other_node": {
                        "pattern": "={{ $('Node Name').item.json.fieldName }}",
                        "description": "Access data from a specific named node. Node name must match exactly (case-sensitive).",
                        "examples": [
                            "={{ $('Fetch Page').item.json.statusCode }}",
                            "={{ $('Set URL').item.json.url }}",
                        ],
                    },
                    "all_items_from_node": {
                        "pattern": "={{ $('Node Name').all() }}",
                        "description": "Get all items from a node as an array.",
                    },
                    "first_last_item": {
                        "pattern": "={{ $('Node Name').first().json.field }} or .last()",
                        "description": "Get first or last item from a node.",
                    },
                    "item_index": {
                        "pattern": "={{ $itemIndex }}",
                        "description": "Current item index (0-based) in the input array.",
                    },
                    "execution_id": {
                        "pattern": "={{ $execution.id }}",
                        "description": "Current execution ID.",
                    },
                    "workflow_id": {
                        "pattern": "={{ $workflow.id }}",
                        "description": "Current workflow ID.",
                    },
                    "date_time": {
                        "pattern": "={{ $now }} or {{ $today }}",
                        "description": "$now is current DateTime, $today is today at midnight. Both are Luxon DateTime objects.",
                        "examples": [
                            "={{ $now.toISO() }}",
                            "={{ $now.minus({days: 7}).toISO() }}",
                            "={{ $today.toFormat('yyyy-MM-dd') }}",
                        ],
                    },
                    "conditionals": {
                        "pattern": "={{ condition ? valueIfTrue : valueIfFalse }}",
                        "description": "Ternary expressions for conditional values.",
                        "examples": ["={{ $json.status === 200 ? 'OK' : 'Failed' }}"],
                    },
                    "helpers": {
                        "$ifEmpty": "={{ $ifEmpty($json.field, 'default') }} — returns default if field is empty/null.",
                        "$if": "={{ $if($json.age > 18, 'adult', 'minor') }} — conditional helper.",
                        "parseInt": "={{ parseInt($json.count) }}",
                        "JSON.stringify": "={{ JSON.stringify($json.data) }}",
                        "JSON.parse": "={{ JSON.parse($json.rawString) }}",
                        "encodeURIComponent": "={{ encodeURIComponent($json.query) }}",
                    },
                    "binary_data": {
                        "pattern": "={{ $binary.data }}",
                        "description": "Access binary data from the current item. Used in file processing nodes.",
                    },
                    "webhook_data": {
                        "body": "={{ $json.body }} — POST body from webhook",
                        "query": "={{ $json.query }} — query parameters from webhook",
                        "headers": "={{ $json.headers }} — request headers from webhook",
                    },
                },
                "critical_rules": [
                    "Node names in expressions MUST exactly match the 'name' field of the node (case-sensitive).",
                    "All expressions MUST be wrapped in ={{ }}. The leading = is required.",
                    "When referencing data from another node, that node must be an upstream ancestor in the workflow connections.",
                    "For HTTP Request node responses: $json contains the parsed response body directly.",
                    "For Webhook trigger: $json.body contains POST data, $json.query contains URL params.",
                ],
            }

        elif topic == "pitfalls":
            refs = {
                "topic": "Common n8n Pitfalls and Fixes",
                "pitfalls": [
                    {
                        "error": "This operation expects the node's input data to contain a binary file 'data'",
                        "cause": "HTML Extract node or similar expects binary input, but receives JSON.",
                        "fix": "Set the upstream HTTP Request node's 'Response Format' to 'File' instead of 'JSON'. Add responseFormat='file' to the httpRequest parameters.",
                    },
                    {
                        "error": "You need to define at least one pair of fields in 'Fields to Match'",
                        "cause": "Merge node in 'Combine by Matching Fields' mode but fieldsToMatch is empty.",
                        "fix": "Add fieldsToMatch parameter with at least one field pair: {\"fieldsToMatch\": {\"values\": [{\"field1\": \"id\", \"field2\": \"id\"}]}}",
                    },
                    {
                        "error": "No property named 'body' exists",
                        "cause": "Trying to access $json.body on an HTTP Request response that returns data directly (not nested under 'body').",
                        "fix": "HTTP Request node responses put data directly in $json, not $json.body. Use $json.title instead of $json.body.title.",
                    },
                    {
                        "error": "Workflow cannot be activated because it has no trigger",
                        "cause": "Attempting to activate a workflow without any trigger node (Webhook, Schedule, Manual, etc.).",
                        "fix": "Add a trigger node. For API-callable workflows: use Webhook trigger. For time-based: use Schedule Trigger. For manual only: use Manual Trigger (but these can't be activated).",
                    },
                    {
                        "error": "Unrecognized node type",
                        "cause": "Using a node type name that doesn't exist in this n8n version.",
                        "fix": "Call n8n_get_node_types to find the correct type name. Common mistakes: 'chatTrigger' should be '@n8n/n8n-nodes-langchain.chatTrigger', 'openai' node vs 'lmChatOpenAi' node.",
                    },
                    {
                        "error": "Could not find property option",
                        "cause": "Using an option value that doesn't exist for a parameter.",
                        "fix": "Call n8n_get_node_types with the node type and check the 'options' array for each parameter. Use the exact 'value' field, not the display 'name'.",
                    },
                    {
                        "error": "The requested webhook was not found",
                        "cause": "Webhook path doesn't match, or workflow is not active (for production webhooks) or not in test mode (for test webhooks).",
                        "fix": "Use test=true for testing. Ensure the webhook path matches exactly. For production, the workflow must be activated first.",
                    },
                    {
                        "error": "Expression references node that doesn't exist",
                        "cause": "$('NodeName') references a node name that doesn't match any node in the workflow.",
                        "fix": "Node names in expressions are case-sensitive and must match exactly. Check all $('...') references against actual node names.",
                    },
                ],
            }

        elif topic == "templates":
            refs = {
                "topic": "Workflow Templates",
                "templates": [
                    {
                        "name": "Webhook → Process → Respond",
                        "description": "API endpoint that receives data, processes it, and returns a response.",
                        "nodes": [
                            {"type": "n8n-nodes-base.webhook", "name": "Webhook", "notes": "Set httpMethod, path, responseMode='responseNode'"},
                            {"type": "n8n-nodes-base.set", "name": "Process Data", "notes": "Transform the incoming data"},
                            {"type": "n8n-nodes-base.respondToWebhook", "name": "Respond", "notes": "Return the processed result"},
                        ],
                        "connections": {"Webhook": {"main": [[{"node": "Process Data"}]]}, "Process Data": {"main": [[{"node": "Respond"}]]}},
                        "key_settings": "Webhook responseMode MUST be 'responseNode' when using Respond to Webhook node.",
                    },
                    {
                        "name": "Schedule → Fetch → Notify",
                        "description": "Periodic job that fetches data from an API and sends a notification.",
                        "nodes": [
                            {"type": "n8n-nodes-base.scheduleTrigger", "name": "Schedule", "notes": "Set rule.interval (e.g., hours=1)"},
                            {"type": "n8n-nodes-base.httpRequest", "name": "Fetch Data", "notes": "Set method, url, authentication if needed"},
                            {"type": "n8n-nodes-base.if", "name": "Check Condition", "notes": "Filter based on response"},
                            {"type": "n8n-nodes-base.httpRequest", "name": "Send Notification", "notes": "POST to Slack/Teams/webhook"},
                        ],
                    },
                    {
                        "name": "AI Agent with Memory",
                        "description": "Conversational AI agent with chat memory and tools.",
                        "nodes": [
                            {"type": "@n8n/n8n-nodes-langchain.chatTrigger", "name": "Chat Trigger", "notes": "Entry point for chat"},
                            {"type": "@n8n/n8n-nodes-langchain.agent", "name": "AI Agent", "notes": "agentType='toolsAgent'"},
                            {"type": "@n8n/n8n-nodes-langchain.lmChatOpenAi", "name": "OpenAI", "notes": "Connect to Agent's 'ai_languageModel' input. Needs openAiApi credential."},
                            {"type": "@n8n/n8n-nodes-langchain.memoryBufferWindow", "name": "Memory", "notes": "Connect to Agent's 'ai_memory' input."},
                        ],
                        "key_settings": "LangChain nodes connect via special inputs (ai_languageModel, ai_memory, ai_tool), NOT the main connection type.",
                    },
                    {
                        "name": "Data Pipeline with Error Handling",
                        "description": "Multi-step data processing with error branch.",
                        "nodes": [
                            {"type": "n8n-nodes-base.manualTrigger", "name": "Start"},
                            {"type": "n8n-nodes-base.httpRequest", "name": "Fetch Data"},
                            {"type": "n8n-nodes-base.if", "name": "Validate", "notes": "Check $json.statusCode or data quality"},
                            {"type": "n8n-nodes-base.set", "name": "Transform", "notes": "On true branch: map/transform fields"},
                            {"type": "n8n-nodes-base.set", "name": "Error Report", "notes": "On false branch: create error message"},
                        ],
                    },
                    {
                        "name": "Webhook with Authentication",
                        "description": "Secured webhook endpoint with header-based auth.",
                        "nodes": [
                            {"type": "n8n-nodes-base.webhook", "name": "Webhook", "notes": "Set authentication='headerAuth', add httpHeaderAuth credential"},
                            {"type": "n8n-nodes-base.set", "name": "Process"},
                            {"type": "n8n-nodes-base.respondToWebhook", "name": "Respond"},
                        ],
                        "key_settings": "The webhook node supports authentication modes: 'headerAuth', 'basicAuth', 'jwtAuth'. Each requires the matching credential type.",
                    },
                ],
            }

        elif topic == "credentials":
            refs = {
                "topic": "Credential Wiring in n8n Workflows",
                "overview": "Each node that requires authentication has a 'credentials' field in its definition. When creating a workflow, wire credentials by adding a 'credentials' object to the node.",
                "format": {
                    "pattern": {"credentials": {"<credentialType>": {"id": "<credentialId>", "name": "<credentialName>"}}},
                    "description": "credentialType comes from the node's credential schema (call n8n_get_node_types to see it). id and name come from n8n_list_credentials.",
                },
                "examples": [
                    {
                        "node_type": "@n8n/n8n-nodes-langchain.lmChatOpenAi",
                        "credential_type": "openAiApi",
                        "wiring": {"credentials": {"openAiApi": {"id": "abc123", "name": "My OpenAI"}}},
                    },
                    {
                        "node_type": "@n8n/n8n-nodes-langchain.lmChatAnthropic",
                        "credential_type": "anthropicApi",
                        "wiring": {"credentials": {"anthropicApi": {"id": "def456", "name": "My Anthropic"}}},
                    },
                    {
                        "node_type": "n8n-nodes-base.httpRequest",
                        "credential_type": "varies — httpBasicAuth, httpHeaderAuth, oAuth2Api, etc.",
                        "wiring": {"credentials": {"httpHeaderAuth": {"id": "ghi789", "name": "API Key Header"}}},
                        "notes": "Set the 'authentication' parameter to match: 'genericCredentialType' then set 'genericAuthType' to the credential type.",
                    },
                    {
                        "node_type": "n8n-nodes-base.webhook",
                        "credential_type": "httpHeaderAuth (for header auth) or httpBasicAuth",
                        "wiring": {"credentials": {"httpHeaderAuth": {"id": "jkl012", "name": "Webhook Auth"}}},
                        "notes": "Set the 'authentication' parameter to 'headerAuth' to enable.",
                    },
                ],
                "workflow": [
                    "1. Call n8n_list_credentials to see available credentials (id, name, type).",
                    "2. Call n8n_get_node_types for each node to see its 'credentials' field (required credential types).",
                    "3. Match credential type from the node definition to a credential from the list.",
                    "4. Add the credentials object to the node definition with the id and name.",
                    "5. If no matching credential exists, tell the user they need to create it in the n8n UI first.",
                ],
            }
        else:
            raise HTTPException(status_code=400, detail=f"Unknown reference topic: {topic}. Use: expressions, pitfalls, templates, credentials")

        return {"result": refs}

    raise HTTPException(status_code=400, detail=f"Unsupported n8n tool: {tool}")


async def _invoke_kb_tool(tool: str, arguments: dict[str, Any], request_id: str, *, public_request: bool) -> dict[str, Any]:
    if not _kb_enabled():
        raise HTTPException(status_code=503, detail="KB tools are disabled")

    bucket = str(arguments.get("bucket", kb_api.public_bucket)).strip() or kb_api.public_bucket
    kb_api._assert_bucket_allowed(bucket, public_request=public_request)

    if tool == "kb_list_objects":
        prefix = str(arguments.get("prefix", "")).strip()
        limit = max(1, min(int(arguments.get("limit", 50)), 200))
        keys = await kb_api.list_objects(bucket, prefix, limit)
        return {"result": {"bucket": bucket, "prefix": prefix, "count": len(keys), "keys": keys}}

    if tool == "kb_get_object":
        key = kb_api._validate_key(str(arguments.get("key", "")))
        as_text = bool(arguments.get("asText", True))
        max_chars = max(1, min(int(arguments.get("maxChars", 6000)), 200000))
        raw = await kb_api.get_object_bytes(bucket, key)
        if as_text:
            text = raw.decode("utf-8", errors="replace")
            if len(text) > max_chars:
                text = text[:max_chars]
            data: dict[str, Any] = {"text": text, "bytes": len(raw)}
        else:
            data = {"contentBase64": base64.b64encode(raw).decode("ascii"), "bytes": len(raw)}
        return {"result": {"bucket": bucket, "key": key, **data}}

    if tool == "kb_extract_text":
        key = kb_api._validate_key(str(arguments.get("key", "")))
        raw = await kb_api.get_object_bytes(bucket, key)
        text = await kb_api.extract_text(raw, request_id)
        return {"result": {"bucket": bucket, "key": key, "text": text, "chars": len(text)}}

    if tool == "kb_search":
        query = str(arguments.get("query", "")).strip().lower()
        if not query:
            raise HTTPException(status_code=400, detail="query is required")
        limit = max(1, min(int(arguments.get("limit", 20)), 100))
        index_keys = await kb_api.list_objects(bucket, kb_api.index_prefix, 500)
        matches: list[dict[str, Any]] = []
        for index_key in index_keys:
            try:
                payload = await kb_api.get_object_bytes(bucket, index_key)
                row = json.loads(payload.decode("utf-8", errors="replace"))
            except Exception:
                continue
            hay = " ".join(
                [
                    str(row.get("title", "")),
                    str(row.get("sourceKey", "")),
                    str(row.get("excerpt", "")),
                    " ".join([str(x) for x in row.get("tags", [])]),
                ]
            ).lower()
            if query in hay:
                matches.append(row)
            if len(matches) >= limit:
                break
        return {"result": {"bucket": bucket, "query": query, "count": len(matches), "matches": matches}}

    if tool == "kb_put_object":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        key = kb_api._validate_key(str(arguments.get("key", "")))
        text = arguments.get("text")
        b64 = arguments.get("contentBase64")
        if text is None and b64 is None:
            raise HTTPException(status_code=400, detail="text or contentBase64 is required")
        if text is not None:
            payload = str(text).encode("utf-8")
            content_type = str(arguments.get("contentType", "text/plain; charset=utf-8")).strip()
        else:
            try:
                payload = base64.b64decode(str(b64), validate=True)
            except Exception:
                raise HTTPException(status_code=400, detail="contentBase64 is invalid")
            content_type = str(arguments.get("contentType", "application/octet-stream")).strip()
        if len(payload) > kb_api.max_object_bytes:
            raise HTTPException(status_code=413, detail="OBJECT_TOO_LARGE")
        await kb_api.put_object(bucket, key, payload, content_type)
        verified = await kb_api.object_exists(bucket, key)
        return {
            "result": {"bucket": bucket, "key": key, "bytes": len(payload), "contentType": content_type},
            "verified": verified,
            "verificationReason": "OBJECT_WRITTEN",
        }

    if tool == "kb_index_document":
        if arguments.get("confirm") is not True:
            raise HTTPException(status_code=400, detail="confirm=true is required")
        key = kb_api._validate_key(str(arguments.get("key", "")))
        raw = await kb_api.get_object_bytes(bucket, key)
        text = await kb_api.extract_text(raw, request_id)
        digest = hashlib.sha256(key.encode("utf-8")).hexdigest()
        index_key = f"{kb_api.index_prefix}{digest}.json"
        entry = {
            "sourceKey": key,
            "title": str(arguments.get("title", key)),
            "tags": [str(x) for x in arguments.get("tags", [])] if isinstance(arguments.get("tags"), list) else [],
            "excerpt": text[:1200],
            "chars": len(text),
            "updatedAt": _now_iso(),
        }
        body = json.dumps(entry, ensure_ascii=True).encode("utf-8")
        await kb_api.put_object(bucket, index_key, body, "application/json")
        verified = await kb_api.object_exists(bucket, index_key)
        return {
            "result": {"bucket": bucket, "key": key, "indexKey": index_key, "chars": len(text)},
            "verified": verified,
            "verificationReason": "INDEX_WRITTEN",
        }

    raise HTTPException(status_code=400, detail=f"Unsupported kb tool: {tool}")


def _n8n_tool_names() -> set[str]:
    return {x["name"] for x in _n8n_tool_schemas()}


def _kb_tool_names() -> set[str]:
    return {x["name"] for x in _kb_tool_schemas()}


async def _policy_check(payload: InvokePayload) -> None:
    if _env_bool("MCP_EXECUTION_KILL_SWITCH", False):
        raise HTTPException(status_code=503, detail="EXECUTION_KILL_SWITCH_ACTIVE")
    if not payload.tenantId.strip():
        raise HTTPException(status_code=400, detail="tenantId is required")
    if not payload.actorId.strip():
        raise HTTPException(status_code=400, detail="actorId is required")
    if len(payload.intentHash.strip()) < 8:
        raise HTTPException(status_code=400, detail="intentHash too short")


async def _record_proof(entry: dict[str, Any]) -> dict[str, Any]:
    signed = dict(entry)
    signed["signature"] = _sign_proof(entry)
    await proof_store.append(signed)
    return signed


@app.on_event("shutdown")
async def shutdown_event() -> None:
    await affine_conn.close()


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "ok": True,
        "affine_enabled": _affine_enabled(),
        "n8n_enabled": _n8n_enabled(),
        "kb_enabled": _kb_enabled(),
        "write_approval_required": _write_approval_required(),
        "allowed_servers": sorted(_allowed_servers()),
        "langgraph_supervisor_enabled": _env_bool("LANGGRAPH_SUPERVISOR_ENABLED", True),
        "langgraph_supervisor_url": langgraph_supervisor_url,
        "nodeTypesCount": len(_n8n_node_types),
        "nodeTypesLoadedAt": _node_types_loaded_at,
    }


@app.post("/admin/reload-node-types")
async def reload_node_types(
    x_mcp_gateway_token: str | None = Depends(api_key_header),
    authorization: str | None = Header(default=None),
) -> dict[str, Any]:
    _check_auth(authorization or (f"Bearer {x_mcp_gateway_token}" if x_mcp_gateway_token else None))
    count = _reload_node_types()
    return {"reloaded": count, "loadedAt": _node_types_loaded_at}


@app.get("/tools")
async def list_tools(
    authorization: str | None = Header(default=None),
    credentials: HTTPAuthorizationCredentials | None = Depends(http_bearer),
    x_mcp_gateway_token: str | None = Depends(api_key_header),
) -> dict[str, Any]:
    _check_auth(_auth_header_from_credentials(authorization, credentials, x_mcp_gateway_token))
    tools: list[dict[str, Any]] = []
    if _affine_enabled():
        try:
            tools.extend(await affine_conn.list_tools())
        except Exception as exc:
            logger.exception("Failed listing AFFiNE tools")
            return JSONResponse(status_code=503, content={"tools": [], "error": str(exc)})
    if _n8n_enabled():
        tools.extend(_n8n_tool_schemas())
    if _kb_enabled():
        tools.extend(_kb_tool_schemas())
    return {"tools": tools}


@app.get("/openapi-tools.json", include_in_schema=False)
async def openapi_tools_spec() -> JSONResponse:
    """Synthetic OpenAPI spec exposing each MCP tool as a POST endpoint."""
    paths: dict[str, Any] = {}
    all_tools: list[dict[str, Any]] = []
    if _n8n_enabled():
        all_tools.extend(_n8n_tool_schemas())
    if _kb_enabled():
        all_tools.extend(_kb_tool_schemas())
    for tdef in all_tools:
        name = tdef["name"]
        tool_desc = tdef.get("description", name)
        paths[f"/call/{name}"] = {
            "post": {
                "operationId": name,
                "summary": tool_desc,
                "description": tool_desc,
                "requestBody": {
                    "required": True,
                    "content": {"application/json": {"schema": tdef.get("inputSchema", {"type": "object"})}},
                },
                "responses": {"200": {"description": "Tool result envelope"}},
            }
        }
    spec = {
        "openapi": "3.1.0",
        "info": {"title": "TU-VM MCP Tools", "version": "2.0.0"},
        "paths": paths,
    }
    return JSONResponse(content=spec)


@app.post("/call/{tool_name}")
async def call_tool(
    tool_name: str,
    request: Request,
    authorization: str | None = Header(default=None),
    credentials: HTTPAuthorizationCredentials | None = Depends(http_bearer),
    x_mcp_gateway_token: str | None = Depends(api_key_header),
    x_write_approval_token: str | None = Header(default=None, alias="X-Write-Approval-Token"),
    x_langgraph_supervised: str | None = Header(default=None, alias="X-LangGraph-Supervised"),
) -> dict[str, Any]:
    """Per-tool endpoint consumed by Open WebUI's OpenAPI tool-server integration."""
    try:
        body = await request.json()
    except (json.JSONDecodeError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid JSON request body")
    payload = InvokePayload(tool=tool_name, arguments=body)
    return await invoke(payload, authorization, credentials, x_mcp_gateway_token, x_write_approval_token, x_langgraph_supervised)


@app.post("/invoke")
async def invoke(
    payload: InvokePayload,
    authorization: str | None = Header(default=None),
    credentials: HTTPAuthorizationCredentials | None = Depends(http_bearer),
    x_mcp_gateway_token: str | None = Depends(api_key_header),
    x_write_approval_token: str | None = Header(default=None, alias="X-Write-Approval-Token"),
    x_langgraph_supervised: str | None = Header(default=None, alias="X-LangGraph-Supervised"),
) -> dict[str, Any]:
    tool = payload.tool.strip()
    auth_header = _auth_header_from_credentials(authorization, credentials, x_mcp_gateway_token)
    public_kb_read = (
        _env_bool("KB_PUBLIC_READ_ENABLED", True)
        and _is_kb_read_tool(tool)
        and not auth_header
    )
    if not public_kb_read:
        _check_auth(auth_header)
    rid = _request_id(payload)
    _apply_contract_defaults(payload, rid)
    await _policy_check(payload)
    arguments = _normalize_aliases(tool, dict(payload.arguments))
    write_tool = _is_write_tool(tool)
    is_supervised_call = str(x_langgraph_supervised or "").strip().lower() in {"1", "true", "yes", "on"}
    if not is_supervised_call:
        _enforce_write_approval(tool, arguments, x_write_approval_token)

    if (
        _env_bool("LANGGRAPH_SUPERVISOR_ENABLED", True)
        and _is_supervisor_delegated_tool(tool)
        and not is_supervised_call
    ):
        try:
            delegated = await _invoke_langgraph_supervisor(
                InvokePayload(
                    tool=tool,
                    arguments=arguments,
                    tenantId=payload.tenantId,
                    actorId=payload.actorId,
                    conversationId=payload.conversationId,
                    intentHash=payload.intentHash,
                    requestId=rid,
                ),
                rid,
            )
            return _as_tool_response(delegated)
        except HTTPException:
            if _env_bool("LANGGRAPH_SUPERVISOR_REQUIRED", True):
                raise
            logger.exception("Supervisor delegation failed; falling back to direct execution.")
        except Exception:
            if _env_bool("LANGGRAPH_SUPERVISOR_REQUIRED", True):
                raise HTTPException(status_code=503, detail="LangGraph supervisor unavailable")
            logger.exception("Supervisor delegation failed unexpectedly; falling back to direct execution.")

    await quota_manager.check_and_record(payload.tenantId, write=write_tool)
    is_n8n_tool = tool.startswith("n8n_")
    if is_n8n_tool:
        await circuit_breaker.allow()

    dedupe_key = _dedupe_key(payload)
    if write_tool:
        prior = await dedupe_store.lookup("dedupe_key", dedupe_key)
        if prior:
            prior["deduped"] = True
            return _as_tool_response(prior)

    async def _execute() -> dict[str, Any]:
        if tool.startswith("n8n_"):
            if not _n8n_enabled():
                raise HTTPException(status_code=503, detail="n8n tools are disabled")
            if tool not in _n8n_tool_names():
                raise HTTPException(status_code=400, detail=f"Unknown n8n tool '{tool}'")
            result = await _invoke_n8n_tool(tool, arguments, rid)
        elif tool.startswith("kb_"):
            if tool not in _kb_tool_names():
                raise HTTPException(status_code=400, detail=f"Unknown kb tool '{tool}'")
            result = await _invoke_kb_tool(tool, arguments, rid, public_request=public_kb_read)
        else:
            if not _affine_enabled():
                raise HTTPException(status_code=503, detail="AFFiNE MCP is disabled")
            result = await affine_conn.call_tool(tool, arguments)
            return result

        envelope: dict[str, Any] = {
            "schemaVersion": "v1",
            "tenantId": payload.tenantId,
            "actorId": payload.actorId,
            "requestId": rid,
            "conversationId": payload.conversationId,
            "intentHash": payload.intentHash,
            "tool": tool,
            "status": "ok",
            "claimed": False,
            "verifiedAt": None,
            "verificationEvidence": {},
            "result": result.get("result", result),
        }

        if write_tool:
            verification = await _verify_write_result(tool, result, arguments, rid)
            envelope["verificationEvidence"] = verification
            envelope["verifiedAt"] = _now_iso()
            envelope["claimed"] = bool(verification.get("verified", False))
            if not envelope["claimed"]:
                envelope["status"] = "unverified"
        else:
            envelope["claimed"] = True
            envelope["verifiedAt"] = _now_iso()
            envelope["verificationEvidence"] = {"verified": True, "reason": "READ_ONLY_ACTION"}
        proof = await _record_proof(envelope)
        if write_tool:
            await dedupe_store.append({"dedupe_key": dedupe_key, **proof})
        return _as_tool_response(proof)

    try:
        output = await quota_manager.run_in_slot(payload.tenantId, _execute())
        if is_n8n_tool:
            await circuit_breaker.mark_success()
        return output
    except HTTPException as exc:
        if is_n8n_tool:
            await circuit_breaker.mark_failure()
        error_entry = {
            "schemaVersion": "v1",
            "tenantId": payload.tenantId,
            "actorId": payload.actorId,
            "requestId": rid,
            "conversationId": payload.conversationId,
            "intentHash": payload.intentHash,
            "tool": tool,
            "status": "error",
            "claimed": False,
            "verifiedAt": _now_iso(),
            "verificationEvidence": {"verified": False, "reason": exc.detail},
            "errorClass": "HTTP",
            "retryable": exc.status_code in {408, 429, 500, 502, 503, 504},
            "error": exc.detail,
        }
        await dlq_store.append(error_entry)
        raise
    except Exception as exc:
        if is_n8n_tool:
            await circuit_breaker.mark_failure()
        logger.exception("Unexpected invoke error")
        error_entry = {
            "schemaVersion": "v1",
            "tenantId": payload.tenantId,
            "actorId": payload.actorId,
            "requestId": rid,
            "conversationId": payload.conversationId,
            "intentHash": payload.intentHash,
            "tool": tool,
            "status": "error",
            "claimed": False,
            "verifiedAt": _now_iso(),
            "verificationEvidence": {"verified": False, "reason": "UNEXPECTED_ERROR"},
            "errorClass": "RUNTIME",
            "retryable": True,
            "error": str(exc),
        }
        await dlq_store.append(error_entry)
        return _as_tool_response(error_entry)


@app.middleware("http")
async def audit_middleware(request: Request, call_next):
    request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
    started = time.time()
    logger.info("REQ id=%s %s %s", request_id, request.method, request.url.path)
    response = await call_next(request)
    elapsed_ms = int((time.time() - started) * 1000)
    response.headers["x-request-id"] = request_id
    logger.info("RES id=%s %s %s status=%s elapsed_ms=%s", request_id, request.method, request.url.path, response.status_code, elapsed_ms)
    return response


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="0.0.0.0", port=9002)
