#!/usr/bin/env python3
"""Ensure fixtures/status-full-contract.json matches the helper /status shape used as /status/full via nginx."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "fixtures" / "status-full-contract.json"

REQUIRED_TOP: dict[str, type] = {
    "vm_ip": str,
    "services": dict,
    "postgres": bool,
    "redis": bool,
    "qdrant": bool,
    "ollama": bool,
    "tika": bool,
    "minio": bool,
}

SERVICE_KEYS = (
    "landing",
    "openwebui",
    "mcp_gateway",
    "langgraph_supervisor",
    "n8n",
    "affine",
    "pihole",
)


def _fail(msg: str) -> None:
    print(f"[status-contract] ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not FIXTURE.is_file():
        _fail(f"missing fixture: {FIXTURE.relative_to(ROOT)}")
    try:
        data = json.loads(FIXTURE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        _fail(f"invalid JSON: {e}")

    for key, typ in REQUIRED_TOP.items():
        if key not in data:
            _fail(f"missing top-level key: {key}")
        if type(data[key]) is not typ:
            _fail(f"wrong type for {key!r}: expected {typ.__name__}, got {type(data[key]).__name__}")

    svc = data["services"]
    for sk in SERVICE_KEYS:
        if sk not in svc:
            _fail(f"services missing key: {sk}")
        if not isinstance(svc[sk], str) or not svc[sk]:
            _fail(f"services.{sk} must be a non-empty string")

    if "memory_mb" in data:
        m = data["memory_mb"]
        if not isinstance(m, dict):
            _fail("memory_mb must be an object")
        for x in ("total", "used", "free"):
            if x not in m:
                _fail(f"memory_mb missing {x}")
            if type(m[x]) is not int:
                _fail(f"memory_mb.{x} must be int")

    if "disk_mb" in data:
        d = data["disk_mb"]
        if not isinstance(d, dict):
            _fail("disk_mb must be an object")
        for x in ("total", "used", "free"):
            if x not in d:
                _fail(f"disk_mb missing {x}")
            if type(d[x]) is not int:
                _fail(f"disk_mb.{x} must be int")

    if "cpu_cores" in data and type(data["cpu_cores"]) is not int:
        _fail("cpu_cores must be int")

    if "load_avg" in data:
        la = data["load_avg"]
        if not isinstance(la, dict):
            _fail("load_avg must be an object")
        for x in ("1m", "5m", "15m"):
            if x not in la:
                _fail(f"load_avg missing {x}")
            if type(la[x]) not in (int, float):
                _fail(f"load_avg.{x} must be numeric")

    print("[status-contract] OK:", FIXTURE.relative_to(ROOT))


if __name__ == "__main__":
    main()
