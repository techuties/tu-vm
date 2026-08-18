---
title: Tika-MinIO Processor Python Contribution Contract
description: Constructional contract for community changes to tika-minio-processor Python so watch/retry/status behavior stays in the existing Alpine image instead of a second document worker.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Tika-MinIO Processor Python Contribution Contract

## Problem

`tika-minio-processor/` is one of two in-tree Python services (with `helper/uploader.py`). It is the MinIO watch loop that calls Apache Tika and writes extracted text back to buckets. Community PRs that want a new mime type, a faster poll, or a second OCR engine tend to add another worker container or fork Tika itself.

Stage 19 owns **Tika XML** (`tika-config/tika-config.xml`). Stage 10 owns the **pipeline wiring**. This page is the **Python contribution surface**: `universal_auto_processor.py`, `universal_processor.py`, the Dockerfile, and `requirements.txt`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika-minio-processor/universal_auto_processor.py` | Watch loop (`WATCH_BUCKETS`, retry backoff) |
| `tika-minio-processor/universal_processor.py` | Tika HTTP, MinIO S3, status JSON |
| `tika-minio-processor/tika_processor.py`, `auto_processor.py` | Legacy modules still copied into the image |
| `tika-minio-processor/Dockerfile` | `python:3-alpine`; `CMD` is the universal watcher |
| `tika-minio-processor/requirements.txt` | `requests`, `boto3`, `botocore`, `watchdog` |
| `docker-compose.yml` `tika_minio_processor` | Env timeouts, `WATCH_BUCKETS=tika-pipe,n8n-workflows`, `/tmp` status mount |
| Helper `/status/pdf-processing` | Reads `/tmp/tika-processing-status.json` |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Pipeline ops, not Python module rules |
| Stage 13 `pdf-operator-day2-contract.md` (expected sibling) | `pdf-logs` / test / reset |
| Stage 19 `tika-xml-config-contribution-contract.md` (expected sibling) | Parser/timeout XML — do not duplicate here |

Out of scope:

- Replacing the watcher with Airflow, Prefect, or a hosted ETL
- A second OCR/extractor sidecar (Stage 19 XML contract)
- Changing Tika vs PyMuPDF defaults (Stage 14 loader switch)
- Re-arguing Tier 1 vs Tier 2 placement (Stage 19 Compose profiles)

## Proposal

Treat `tika-minio-processor/` as the **community Python surface** for watch/retry/status behavior.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| New mime / extension | `SUPPORTED_EXTENSIONS` in `universal_processor.py` | Sample fixture under `fixtures/` or an existing PDF test |
| Watch/retry env | Compose env already listed (`PROCESSOR_*`, `TIKA_TIMEOUT_*`) | Document energy cost of shorter `CHECK_INTERVAL` |
| Status JSON | `STATUS_FILE = /tmp/tika-processing-status.json` | Keep keys the helper already reads |
| Dependencies | `requirements.txt` | Pin only what the universal modules import |
| Image | `Dockerfile` | Stay on `python:3-alpine`; do not add OCR binaries |
| Legacy scripts | `tika_processor.py`, `auto_processor.py` | Deprecate or stop `COPY`ing unused files |

### Rules

1. **One worker.** Keep `command: ["python", "universal_auto_processor.py"]`. Do not add a parallel processor service.
2. **Python, not a new framework.** boto3 + requests stay. Do not introduce Celery, Kafka, or Unstructured as a merge prerequisite.
3. **XML vs Python.** Parser/OCR timeouts that Tika already exposes belong in `tika-config.xml`. Processor env timeouts wrap HTTP calls; keep them documented and do not silently exceed `TIKA_TIMEOUT_MAX_SECONDS`.
4. **Status file contract.** Helper and dashboard notifications depend on atomic writes to `/tmp/tika-processing-status.json`. Changing keys requires a helper + fixture update in the same PR.
5. **Do not widen `/tmp`.** The shared mount exists for the status file. Do not use it as a scratch corpus or host-temp dump.
6. **Energy.** `CHECK_INTERVAL=10` plus OCR on every image is a laptop cost. Shorter intervals need a note; do not default below 10s.
7. **Syntax gate.** Community PRs compile with `python3 -m py_compile` on the four modules (prefer adding this to CI/smoke later).
8. **GitHub remains intake.** Requests for a hosted document pipeline stay Issues.

### Suggested contributor checklist

```text
1. Read universal_auto_processor.py and universal_processor.py
2. Change only the mime/retry/status keys required
3. Do not add a second worker image or OCR container
4. Keep STATUS_FILE path and helper-consumed keys stable
5. python3 -m py_compile tika-minio-processor/*.py
6. Note energy impact of poll interval or OCR flags
7. Exercise pdf-logs / an existing PDF test when Tika + MinIO are up
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Watch + extract | Existing Alpine processor + Tika HTTP | Airflow / a second Python worker |
| Parser behavior | Stage 19 Tika XML | Forking `apache/tika` |
| Day-2 ops | Stage 13 PDF toolkit | Ad-hoc `docker exec` only in chat |
| Deps | `requirements.txt` + digest-pinned base | Unpinned `pip install` in the Dockerfile |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `python3 -m py_compile` on `tika-minio-processor/*.py` in CI/smoke.
3. Optional: stop copying unused `tika_processor.py` / `auto_processor.py` after a deprecation note.

## Acceptance criteria

- [ ] Single-worker rule is stated.
- [ ] Python modules (not Tika XML) are the contribution surface for watch/retry/status.
- [ ] Status JSON keys stay compatible with the helper.
- [ ] Second extractor/worker images are out of scope.
- [ ] Compile-check is listed as the preferred code follow-up.

## Rollback

Revert the Python files and Compose env independently. A compile gate can be removed without changing the running watcher. Do not drop `WATCH_BUCKETS` members without a migration note for n8n workflow uploads.

## Success metrics

- Mime/retry PRs edit `tika-minio-processor/` instead of adding sidecars.
- Helper PDF notifications keep working after community Python changes.
- Legacy unused modules shrink or disappear without behavior change.
