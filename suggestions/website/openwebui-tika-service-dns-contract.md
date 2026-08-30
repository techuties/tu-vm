---
title: Open WebUI Tika Service DNS Contract
description: Constructional contract for leftover container_name DNS (ai_tika, ai_minio) in Open WebUI and the processor after Stage 28 moved n8n off a hardcoded Postgres IP.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Tika Service DNS Contract

## Problem

Stage 28 fixes n8n → Postgres (`DB_POSTGRESDB_HOST: postgres` instead of `172.20.0.10`). The same Compose file still mixes **Compose service DNS** with **`container_name` hostnames**:

| Consumer | Key | Value today | Honest target |
|---|---|---|---|
| `open-webui` | `TIKA_SERVER_URL` | `http://ai_tika:9998` | `http://tika:9998` |
| `tika_minio_processor` | `TIKA_URL` | `http://ai_tika:9998` | `http://tika:9998` |
| `tika_minio_processor` | `MINIO_ENDPOINT` | `ai_minio:9000` | `minio:9000` |
| `mcp_gateway` | `KB_TIKA_URL` (default) | `http://tika:9998` | already honest |
| `mcp_gateway` | `KB_MINIO_ENDPOINT` (default) | `minio:9000` | already honest |
| `env.example` | `N8N_INTERNAL_URL` | `http://ai_n8n:5678` | `http://n8n:5678` (follow-up) |

`container_name` DNS works only while those exact names exist. Compose service names survive project-name prefixes, `include:` splits (Stage 28), and CODEOWNERS-friendly file moves. Open WebUI already talks to `postgres`, `redis`, `qdrant`, and `ollama` by service name. Tika is the leftover exception on the same service.

Stage 21 is Nginx upstream resolver policy. Stage 28 is n8n → Postgres. This page is the leftover **first-party clients that still use `ai_*` container names**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose service names `tika`, `minio` | User-defined network DNS |
| `container_name: ai_tika` / `ai_minio` | Operator-facing `docker ps` names; not API hosts |
| Open WebUI `OLLAMA_BASE_URL: http://ollama:11434` | Precedent on the same service |
| MCP KB defaults `tika` / `minio` | Precedent on the gateway |
| Stage 21 `nginx-upstream-dns-contract.md` (expected sibling) | Edge resolver, not app env |
| Stage 28 `n8n-postgres-service-dns-contract.md` (expected sibling) | IP → service name for n8n only |
| Stage 28 `compose-include-split-contract.md` (expected sibling) | Splits make container_name DNS more brittle |

Out of scope:

- Removing `container_name` (operators rely on `ai_*` in docs)
- Changing Tika's listen port or MinIO console
- Rewriting Nginx vhosts (`tika` is not a public vhost today)
- Hardcoding `172.20.0.20` / `.21` as a “fix”

## Proposal

Point first-party env URLs at Compose service names. Keep `container_name` for humans.

```yaml
# open-webui
TIKA_SERVER_URL: "http://tika:9998"

# tika_minio_processor
TIKA_URL: http://tika:9998
MINIO_ENDPOINT: minio:9000
```

Follow-up (same pattern, separate commit if review prefers a smaller diff): `N8N_INTERNAL_URL`, `N8N_MCP_SERVER_URL`, `AFFINE_BASE_URL`, `LANGGRAPH_SUPERVISOR_URL` defaults in Compose and `env.example`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `open-webui` | `TIKA_SERVER_URL` | `http://tika:9998` |
| Compose processor | `TIKA_URL`, `MINIO_ENDPOINT` | service names |
| `env.example` | MCP / n8n defaults that use `ai_*` | service names |
| Docs | this page | `container_name` is for `docker exec`, not URLs |
| Nginx | none | Edge already uses service names |

### Rules

1. **Service name in URLs.** `container_name` stays for CLI identity only.
2. **Do not embed IPAM.** Stage 18 owns `172.20.0.0/16`; clients use DNS.
3. **Match existing honest clients.** Open WebUI → `ollama` / `postgres`; KB → `tika` / `minio`.
4. **One PR can do Tika/MinIO only.** n8n/AFFiNE/MCP URL leftovers are the same rule, not a new framework.
5. **GitHub remains intake.** Requests for “use host.docker.internal for Tika” are out of scope.

### Suggested contributor checklist

```text
1. Change Open WebUI TIKA_SERVER_URL to http://tika:9998
2. Change processor TIKA_URL and MINIO_ENDPOINT to tika / minio
3. Leave container_name: ai_tika and ai_minio
4. grep compose and env.example for ai_tika / ai_minio / ai_n8n hostnames
5. Confirm docker compose config still renders
6. Upload a small PDF and confirm the processor still reaches Tika
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| In-stack DNS | Compose service names on `ai_network` | `container_name` or static IPv4 in app env |
| Include / split | Stage 28 `include:` | Rewriting URLs every time a file moves |
| Edge routing | Stage 21 Nginx resolver | Teaching Open WebUI about `*.tu.lan` for Tika |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Open WebUI + processor in one PR; MCP/`env.example` defaults in the same PR if the diff stays small.
3. Restart Open WebUI and the processor after merge (env-only change).

## Acceptance criteria

- [ ] `TIKA_SERVER_URL` uses host `tika`, not `ai_tika`.
- [ ] Processor `TIKA_URL` / `MINIO_ENDPOINT` use `tika` / `minio`.
- [ ] `container_name` values are unchanged.
- [ ] No `172.20.0.2x` literals are added.
- [ ] `docker compose config` still renders.

## Rollback

Restore the `ai_*` hostnames. Containers still resolve them while `container_name` exists. No data migration.

## Success metrics

- `grep -n 'ai_tika\\|ai_minio' docker-compose.yml env.example` is empty for URL/host keys.
- Stage 28 include splits do not break the document pipeline.
- Contributors copy service-name URLs into new first-party clients by default.
