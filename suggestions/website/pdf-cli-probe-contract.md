---
title: PDF Command Probe Contract
description: Constructional contract so tu-vm.sh PDF commands reach Tika on the Docker network and MinIO with the password already stored in .env.
last_updated: 2026-10-10
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# PDF Command Probe Contract

## Problem

`check_pdf_processing_status` reports Tika as down while the Tier 1 container is up, and it reports the `tika-pipe` bucket as missing when the bucket exists.

The Tika block curls the host:

```bash
if curl -s -f "http://localhost:9998/tika" >/dev/null 2>&1; then
    echo "  ✅ Tika API is responding"
else
    echo "  ⚠️  Tika API not responding"
fi
```

The `tika` service in `docker-compose.yml` has a container port of 9998 and no `ports:` entry. MinIO publishes `127.0.0.1:9000` and `127.0.0.1:9001`. Tika does not. From the host, `localhost:9998` is closed whenever the stack is running as composed. The warning is what a healthy install prints.

The bucket check and `test_pdf_processing` start `minio/mc` with the shell's `MINIO_ROOT_PASSWORD` or the published default:

```bash
mc alias set local http://ai_minio:9000 admin '${MINIO_ROOT_PASSWORD:-minio123456}'
```

`check_pdf_processing_status` and `test_pdf_processing` never read `.env`. A normal operator session does not export `MINIO_ROOT_PASSWORD`. The client then authenticates as `minio123456`. MinIO, after `generate_secrets`, is not that password. `mc ls` fails, and the script prints `tika-pipe bucket not found`.

`reset_pdf_pipeline` already loads the key from `.env` when the shell variable is empty. `resolve_minio_password` does the same lookup for bucket setup. The PDF status and PDF test commands are the two that skipped it.

Checked on 2026-10-10 from `tu-vm.sh` and `docker-compose.yml`. The Docker daemon was not required. The compose service has no host port, and the shell default is the string in those two `mc` lines.

Stage 48 (open PR #74) owns the missing Tika healthcheck and the image that has no `curl`. Stage 46 (open PR #72) owns `run_minio_mc` and its host-network client. This page is the `pdf-status` / `pdf-test` path, which does not call either of those.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `check_pdf_processing_status` | The status command that curls the host and uses the default MinIO password |
| `test_pdf_processing` | The upload test with the same password default |
| `reset_pdf_pipeline` | The PDF command that already reads `.env` |
| `resolve_minio_password` | Shared lookup for `.env`, the shell, then the container |
| `run_minio_mc` | The `mc` wrapper bucket setup already uses |
| `ai_helper_index` | Tier 1 container whose start command installs `curl` on `ai_network` |
| Compose DNS name `tika` | The service hostname on that network |
| Stage 48 `tika-pipeline-readiness-contract.md` (expected sibling, open PR #74) | Healthcheck and `service_started` |
| Stage 46 `minio-mc-client-transport-contract.md` (expected sibling, open PR #72) | Transport for `run_minio_mc` |

Out of scope:

- Publishing port 9998 on the host
- A new PDF application or a second MinIO client
- The Tika healthcheck binary (Stage 48)
- The `run_minio_mc` network mode (Stage 46)

## Proposal

Probe Tika from a container that is already on `ai_network`. Take the MinIO password from `resolve_minio_password`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Tika | `check_pdf_processing_status` | Replace the host curl with `docker exec ai_helper_index curl -fsS http://tika:9998/tika` |
| Password | `check_pdf_processing_status` and `test_pdf_processing` | `minio_pass="$(resolve_minio_password)"` and pass that value to `mc` |
| Client | those two functions | Call `run_minio_mc` for `ls`, `mb`, and `cp` once Stage 46's transport is the one in tree |
| Wording | the bucket failure branch | When `mc` cannot authenticate, say the password was rejected, and keep `bucket not found` for a real missing bucket |

### Rules

1. **A running Tika container with a closed host port is healthy.** The status command reaches `tika:9998` on the Docker network.
2. **The password is the one in `.env`.** An unset shell variable does not select `minio123456` when `.env` has `MINIO_ROOT_PASSWORD`.
3. **The host port stays closed.** The check does not add a `ports:` entry for Tika.
4. **Reset, status, and test agree.** All three use the same password lookup.

### Suggested contributor checklist

```text
1. With ai_tika and ai_helper_index running, pdf-status prints that the Tika API is responding
2. Nothing listens on host port 9998
3. With MINIO_ROOT_PASSWORD only in .env, pdf-status lists tika-pipe instead of saying the bucket is missing
4. pdf-test uploads with that same password
5. An unset .env and an unset shell variable still falls through to the published default inside resolve_minio_password
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| HTTP client on the Docker network | `curl` already installed in `ai_helper_index` | A host port or a new image |
| MinIO password | `resolve_minio_password` | `${MINIO_ROOT_PASSWORD:-minio123456}` in the PDF commands |
| `mc` invocation | `run_minio_mc` | A third `docker run minio/mc` copy |
