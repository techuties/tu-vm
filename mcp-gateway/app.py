import asyncio
import json
import logging
import os
import shlex
from contextlib import AsyncExitStack
from typing import Any

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import JSONResponse
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("mcp-gateway")

app = FastAPI(title="MCP Gateway", version="1.0.0")


def _env_bool(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


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
                raise RuntimeError(
                    "No AFFiNE auth configured. Set AFFINE_API_TOKEN (recommended), "
                    "or AFFINE_COOKIE, or AFFINE_EMAIL+AFFINE_PASSWORD."
                )

            logger.info("Starting affine MCP server via stdio: %s %s", command, " ".join(args))

            server_params = StdioServerParameters(command=command, args=args, env=env)
            stack = AsyncExitStack()
            stdio = await stack.enter_async_context(stdio_client(server_params))
            read_stream, write_stream = stdio
            session = await stack.enter_async_context(ClientSession(read_stream, write_stream))
            await session.initialize()

            self._stack = stack
            self._session = session
            logger.info("AFFiNE MCP session initialized")

    async def list_tools(self) -> list[dict[str, Any]]:
        async with self._lock:
            await self._connect()
            assert self._session is not None
            res = await self._session.list_tools()
            tools = getattr(res, "tools", [])
            return [_normalize_tool(t) for t in tools]

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


affine_conn = AffineMcpConnection()


def _check_auth(auth_header: str | None) -> None:
    expected_token = os.getenv("MCP_GATEWAY_TOKEN", "").strip()
    if not expected_token:
        raise HTTPException(status_code=500, detail="MCP_GATEWAY_TOKEN is not configured")

    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")

    token = auth_header.split(" ", 1)[1].strip()
    if token != expected_token:
        raise HTTPException(status_code=401, detail="Invalid token")


def _affine_enabled() -> bool:
    enabled = _env_bool("AFFINE_MCP_ENABLED", True)
    allowed = [s.strip().lower() for s in os.getenv("MCP_ALLOWED_SERVERS", "affine").split(",") if s.strip()]
    if not allowed:
        allowed = ["affine"]
    return enabled and ("affine" in allowed)


@app.on_event("shutdown")
async def shutdown_event() -> None:
    await affine_conn.close()


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "ok": True,
        "affine_enabled": _affine_enabled(),
    }


@app.get("/tools")
async def list_tools(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _check_auth(authorization)
    if not _affine_enabled():
        return {"tools": []}
    try:
        tools = await affine_conn.list_tools()
        return {"tools": tools}
    except Exception as exc:
        logger.exception("Failed listing tools")
        return JSONResponse(
            status_code=503,
            content={"tools": [], "error": f"Unable to list AFFiNE tools: {str(exc)}"},
        )


@app.post("/invoke")
async def invoke(payload: dict[str, Any], authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _check_auth(authorization)

    if not _affine_enabled():
        raise HTTPException(status_code=503, detail="AFFiNE MCP is disabled")

    tool = payload.get("tool")
    arguments = payload.get("arguments", {})
    if not isinstance(tool, str) or not tool.strip():
        raise HTTPException(status_code=400, detail="Field 'tool' must be a non-empty string")
    if not isinstance(arguments, dict):
        raise HTTPException(status_code=400, detail="Field 'arguments' must be an object")

    try:
        result = await affine_conn.call_tool(tool, arguments)
        return result
    except Exception as exc:
        logger.exception("Tool invocation failed: %s", tool)
        return {
            "content": [],
            "error": f"Invocation failed: {str(exc)}",
        }


@app.middleware("http")
async def audit_middleware(request: Request, call_next):
    try:
        body = await request.body()
        body_text = body.decode("utf-8", errors="replace")
        if len(body_text) > 1000:
            body_text = body_text[:1000] + "...<truncated>"
        logger.info("REQ %s %s body=%s", request.method, request.url.path, body_text)
    except Exception:
        logger.info("REQ %s %s", request.method, request.url.path)
    response = await call_next(request)
    logger.info("RES %s %s status=%s", request.method, request.url.path, response.status_code)
    return response


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="0.0.0.0", port=9002)
