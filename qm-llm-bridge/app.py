import asyncio
import os
import time
import uuid
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse


app = FastAPI(title="Queue Manager LLM Bridge", version="1.0.0")

QM_BASE_URL = os.getenv("QM_BASE_URL", "http://192.168.1.41:8081").rstrip("/")
QM_TIMEOUT_SECONDS = float(os.getenv("QM_TIMEOUT_SECONDS", "30"))
QM_TEXT_MODEL_DEFAULT = os.getenv("QM_TEXT_MODEL_DEFAULT", "llama3.2")
QM_EMBED_MODEL_DEFAULT = os.getenv("QM_EMBED_MODEL_DEFAULT", "nomic-embed-text")
QM_CHAT_SERVICE = os.getenv("QM_CHAT_SERVICE", "chat-vllm")
QM_QUEUE_WAIT_SECONDS = float(os.getenv("QM_QUEUE_WAIT_SECONDS", "90"))


def _request_id(request: Request) -> str:
    incoming = request.headers.get("x-request-id", "").strip()
    return incoming if incoming else str(uuid.uuid4())


def _first_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(_first_text(v) for v in value if v is not None).strip()
    if isinstance(value, dict):
        if isinstance(value.get("choices"), list) and value["choices"]:
            first = value["choices"][0] or {}
            if isinstance(first, dict):
                msg = first.get("message")
                if isinstance(msg, dict) and msg.get("content") is not None:
                    return _first_text(msg.get("content"))
                if first.get("text") is not None:
                    return _first_text(first.get("text"))
        for key in ("content", "text", "response", "caption", "output", "result"):
            if key in value:
                return _first_text(value[key])
    return str(value)


def _extract_response_text(payload: dict[str, Any]) -> str:
    if "result" in payload:
        return _first_text(payload["result"])
    return _first_text(payload)


def _messages_to_prompt(messages: list[dict[str, Any]]) -> str:
    chunks: list[str] = []
    for msg in messages:
        role = str(msg.get("role", "user")).strip()
        content = _first_text(msg.get("content", ""))
        if not content:
            continue
        chunks.append(f"{role}: {content}")
    return "\n".join(chunks).strip()


async def _qm_request(method: str, path: str, request_id: str, json_payload: dict[str, Any] | None = None) -> dict[str, Any]:
    url = f"{QM_BASE_URL}{path}"
    headers = {
        "X-Request-ID": request_id,
        "X-Source": "openwebui-qm-bridge",
    }
    async with httpx.AsyncClient(timeout=QM_TIMEOUT_SECONDS) as client:
        resp = await client.request(method, url, headers=headers, json=json_payload)
    if resp.status_code >= 400:
        detail = resp.text
        raise HTTPException(status_code=resp.status_code, detail=detail[:1000])
    try:
        return resp.json()
    except Exception:
        raise HTTPException(status_code=502, detail="Queue Manager returned non-JSON response")


async def _qm_submit_and_wait(
    request_id: str,
    model: str,
    messages: list[dict[str, Any]],
    source: str = "openwebui-qm-bridge",
) -> dict[str, Any]:
    submit_payload = {
        "service": QM_CHAT_SERVICE,
        "payload": {
            "model": model,
            "messages": messages,
            "prompt": _messages_to_prompt(messages),
        },
        "priority": 1,
        "source": source,
    }
    submitted = await _qm_request("POST", "/queue/submit", request_id, submit_payload)
    req_id = submitted.get("request_id")
    if not req_id:
        raise HTTPException(status_code=502, detail="Queue Manager did not return request_id")

    started = time.time()
    while time.time() - started < QM_QUEUE_WAIT_SECONDS:
        status_payload = await _qm_request("GET", f"/queue/request/{req_id}", request_id)
        status = str(status_payload.get("status", "")).lower()
        if status == "completed":
            return status_payload.get("result", {})
        if status in {"failed", "cancelled"}:
            err = status_payload.get("error") or "queue request failed"
            raise HTTPException(status_code=502, detail=f"Queue request {status}: {err}")
        await asyncio.sleep(1.0)

    raise HTTPException(status_code=504, detail="Timed out waiting for queue completion")


def _ollama_done_payload(model: str, text: str, started: float) -> dict[str, Any]:
    elapsed = max(0.0, time.time() - started)
    return {
        "model": model,
        "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "message": {"role": "assistant", "content": text},
        "done_reason": "stop",
        "done": True,
        "total_duration": int(elapsed * 1_000_000_000),
    }


@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    rid = _request_id(request)
    request.state.request_id = rid
    response = await call_next(request)
    response.headers["X-Request-ID"] = rid
    return response


@app.get("/health")
async def health(request: Request):
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    payload = await _qm_request("GET", "/health", rid)
    return {"ok": True, "queue_manager": payload}


@app.get("/api/tags")
async def ollama_tags(request: Request):
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    routing = await _qm_request("GET", "/routing-table", rid)
    models = []
    for item in routing if isinstance(routing, list) else routing.get("data", []):
        model_name = item.get("model") or item.get("model_id")
        if not model_name:
            continue
        models.append({"name": model_name, "model": model_name, "modified_at": None, "size": 0})
    if not models:
        models.append({"name": QM_TEXT_MODEL_DEFAULT, "model": QM_TEXT_MODEL_DEFAULT, "modified_at": None, "size": 0})
    return {"models": models}


@app.post("/api/chat")
async def ollama_chat(payload: dict[str, Any], request: Request):
    started = time.time()
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    model = str(payload.get("model") or QM_TEXT_MODEL_DEFAULT)
    messages = payload.get("messages")
    if not isinstance(messages, list):
        raise HTTPException(status_code=400, detail="Field 'messages' must be a list")
    qm_result = await _qm_submit_and_wait(rid, model, messages)
    text = _extract_response_text(qm_result)
    return _ollama_done_payload(model, text, started)


@app.post("/api/generate")
async def ollama_generate(payload: dict[str, Any], request: Request):
    started = time.time()
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    model = str(payload.get("model") or QM_TEXT_MODEL_DEFAULT)
    prompt = str(payload.get("prompt") or "")
    qm_result = await _qm_submit_and_wait(rid, model, [{"role": "user", "content": prompt}])
    text = _extract_response_text(qm_result)
    response = _ollama_done_payload(model, text, started)
    response["response"] = text
    return response


@app.post("/api/embeddings")
async def ollama_embeddings(payload: dict[str, Any], request: Request):
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    model = str(payload.get("model") or QM_EMBED_MODEL_DEFAULT)
    prompt = payload.get("prompt")
    if not isinstance(prompt, str) or not prompt.strip():
        raise HTTPException(status_code=400, detail="Field 'prompt' must be a non-empty string")
    qm_payload = {"text": prompt}
    qm_result = await _qm_request("POST", f"/embeddings/{model}", rid, qm_payload)
    embedding = qm_result.get("embedding") or qm_result.get("result", {}).get("embedding") or []
    return {"embedding": embedding}


@app.get("/v1/models")
async def openai_models(request: Request):
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    routing = await _qm_request("GET", "/routing-table", rid)
    items = []
    for item in routing if isinstance(routing, list) else routing.get("data", []):
        model_name = item.get("model") or item.get("model_id")
        if model_name:
            items.append({"id": model_name, "object": "model", "owned_by": "queue-manager"})
    if not items:
        items.append({"id": QM_TEXT_MODEL_DEFAULT, "object": "model", "owned_by": "queue-manager"})
    return {"object": "list", "data": items}


@app.post("/v1/chat/completions")
async def openai_chat_completions(payload: dict[str, Any], request: Request):
    started = time.time()
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    model = str(payload.get("model") or QM_TEXT_MODEL_DEFAULT)
    messages = payload.get("messages")
    if not isinstance(messages, list):
        raise HTTPException(status_code=400, detail="Field 'messages' must be a list")
    qm_result = await _qm_submit_and_wait(rid, model, messages, source="openwebui-qm-bridge-openai")
    text = _extract_response_text(qm_result)
    usage = {
        "prompt_tokens": 0,
        "completion_tokens": 0,
        "total_tokens": 0,
    }
    return {
        "id": f"chatcmpl-{uuid.uuid4().hex}",
        "object": "chat.completion",
        "created": int(started),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": text},
                "finish_reason": "stop",
            }
        ],
        "usage": usage,
    }


@app.post("/v1/embeddings")
async def openai_embeddings(payload: dict[str, Any], request: Request):
    rid = getattr(request.state, "request_id", str(uuid.uuid4()))
    model = str(payload.get("model") or QM_EMBED_MODEL_DEFAULT)
    input_text = payload.get("input")
    if isinstance(input_text, list):
        merged = "\n".join(str(v) for v in input_text)
    else:
        merged = str(input_text or "")
    if not merged.strip():
        raise HTTPException(status_code=400, detail="Field 'input' must be non-empty")
    qm_result = await _qm_request("POST", f"/embeddings/{model}", rid, {"text": merged})
    embedding = qm_result.get("embedding") or qm_result.get("result", {}).get("embedding") or []
    return {
        "object": "list",
        "data": [{"object": "embedding", "index": 0, "embedding": embedding}],
        "model": model,
        "usage": {"prompt_tokens": 0, "total_tokens": 0},
    }


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"error": str(exc.detail)})
