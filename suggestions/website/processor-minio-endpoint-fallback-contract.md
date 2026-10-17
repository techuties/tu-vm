---
title: Processor MinIO Endpoint Contract
description: Constructional contract so the document processor uses Docker DNS for MinIO and exits when that lookup fails, instead of copying 172.20.0.21 into Python.
last_updated: 2026-10-17
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Processor MinIO Endpoint Contract

## Problem

`UniversalMinIOProcessor` rewrites `MINIO_ENDPOINT` before it builds the boto3 client. Compose sets that endpoint to `ai_minio:9000`. The client cannot use a hostname that contains an underscore, so the processor resolves the name and then uses the IP.

The resolution order is `socket.gethostbyname`, then `socket.gethostbyname` of the name plus `.local`, then a fixed address when the host is `ai_minio`:

```text
resolved_ip = '172.20.0.21'
```

Checked on 2026-10-17 by constructing `UniversalMinIOProcessor` with boto3 and the Tika health request stubbed, on a host where `ai_minio` does not resolve. The processor logged `Using static IP for MinIO: 172.20.0.21:9000` and passed `endpoint_url=http://172.20.0.21:9000` to the client.

MinIO's compose service already sets `ipv4_address: 172.20.0.21`. The Python string is a second copy of that address. If the compose address changes, the watcher still dials `.21`.

`tika_minio_processor` is the only service in this compose file with a network attachment and no `ipv4_address`. Its own address comes from the pool. This page does not republish the pool. The open IPAM registry page (PR #44) already owns the table of pinned addresses. The defect here is the copied MinIO address inside the processor, used only after DNS fails.

A failed lookup should stop the process. `restart: unless-stopped` will start it again when Docker DNS for `ai_minio` is available. Dialing a stale IP reports bucket errors instead of a restart.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `MINIO_ENDPOINT=ai_minio:9000` | The name Compose already sets |
| `socket.gethostbyname` | The lookup to keep as the success path |
| MinIO `ipv4_address: 172.20.0.21` | The live address. One source of truth |
| `tika_minio_processor` `networks: [ai_network]` | The only service on that network without a pinned address |
| Open PR #44 `compose-ipam-address-registry.md` (expected sibling) | The address table. Do not copy it into this page |
| Stage 46 MinIO `mc` transport (open PR #72) | Host-side `mc`. This page is the processor's boto3 endpoint |

Out of scope:

- A new object-storage client or a MinIO sidecar
- Changing bucket names, `.gitkeep` handling, or the attempt cap (Stages 56 and 41)
- Republishing every service address from the IPAM registry
- Pointing the processor at `127.0.0.1:9000` (that bind is for host tools, not for a container on `ai_network`)

## Proposal

Keep boto3 and the underscore workaround. Delete the hardcoded address.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Lookup | `UniversalMinIOProcessor.__init__` | On DNS success, keep using the resolved IP so boto3 does not have to accept `ai_minio` |
| Failure | Same block | If both lookups fail, log the name and raise. Do not substitute `172.20.0.21` |
| Process | `universal_auto_processor.py` `main` | Let that exception exit non-zero so Docker restarts the watcher |
| Address | `tika_minio_processor` | Optional, and only this service: set `ipv4_address` the same way neighboring services do. Do not edit the other rows |

### Rules

1. **DNS success stays the normal path.** A resolved A record is the endpoint.
2. **DNS failure is a crash, not a guessed IP.** No third address lives in Python.
3. **Do not add a `.local` search as a new mechanism.** The current `.local` attempt can stay or go. It must not be replaced with another literal.
4. **Do not restate the IPAM table.** PR #44 owns the full registry. This page may pin only `tika_minio_processor`.
5. **Do not change `MINIO_ENDPOINT` to an IP in Compose.** The service name remains the configuration operators read.

### Suggested contributor checklist

```text
1. With ai_minio resolvable, the client endpoint is the looked-up address, not a literal from source
2. With getaddrinfo failing, the process exits non-zero and does not log 172.20.0.21
3. A PDF still processes when DNS works
4. Compose still sets MINIO_ENDPOINT=ai_minio:9000
5. No other service's ipv4_address line changes in the same patch
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Service address | Docker DNS on `ai_network` | A copied literal from compose |
| Underscore hostnames | Resolve, then pass the IP to boto3 | A new HTTP library |
| Restart | The service's existing `unless-stopped` policy | A supervisor process inside the image |
