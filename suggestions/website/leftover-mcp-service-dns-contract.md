---
title: Leftover MCP Service DNS Contract
description: Constructional contract for leftover ai_n8n, ai_affine, ai_n8n_mcp, and processor Tika/MinIO URL defaults so Compose service DNS is the only internal hostname scheme.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Leftover MCP Service DNS Contract

## Problem

Stage 28 moved n8n → Postgres off a static IP. Stage 29 moved Open WebUI Tika/MinIO off `ai_tika` / `ai_minio`. The leftover defaults still use **container names** as hostnames:

| Location | Current default | Compose service DNS |
|---|---|---|
| `env.example` `N8N_INTERNAL_URL` | `http://ai_n8n:5678` | `http://n8n:5678` |
| `env.example` `N8N_MCP_SERVER_URL` | `http://ai_n8n_mcp:3000/mcp` | `http://n8n_mcp:3000/mcp` |
| `env.example` `AFFINE_BASE_URL` | `http://ai_affine:3010` | `http://affine:3010` |
| `env.example` `MCP_GATEWAY_URL` | `http://ai_mcp_gateway:9002` | `http://mcp_gateway:9002` |
| `env.example` `LANGGRAPH_SUPERVISOR_URL` | `http://ai_langgraph_supervisor:9010` | `http://langgraph_supervisor:9010` |
| Compose `mcp_gateway` fallbacks | same `ai_*` URLs | same service names |
| `tika_minio_processor` | `TIKA_URL=http://ai_tika:9998`, `MINIO_ENDPOINT=ai_minio:9000` | `tika` / `minio` |

`container_name` still resolves on the Docker network, so this is not a runtime outage today. It **is** a contribution trap: Stage 28/29 said "use service DNS"; new PRs keep copying `ai_*` from `env.example`. Dropping or renaming a `container_name` later breaks MCP and the processor while Open WebUI keeps working.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose service names (`n8n`, `affine`, `n8n_mcp`, `tika`, `minio`) | Official Docker DNS |
| `container_name: ai_*` | Operator-facing `docker` CLI names; keep them |
| Stage 21 `nginx-upstream-dns-contract.md` (expected sibling) | Nginx resolver rules |
| Stage 28 `n8n-postgres-service-dns-contract.md` (expected sibling) | First service-DNS leftover (Postgres IP) |
| Stage 29 `openwebui-tika-service-dns-contract.md` (expected sibling) | Open WebUI Tika/MinIO only |
| `KB_TIKA_URL` / `KB_MINIO_ENDPOINT` | Already use `tika` / `minio` — copy this pattern |

Out of scope:

- Removing `container_name`
- Changing published hostnames (`n8n.tu.lan`)
- A Consul / Traefik service registry
- Rewriting Stage 28 or Stage 29 pages

## Proposal

Change **defaults** to Compose service names. Leave `container_name` and `tu-vm.sh` docker-inspect maps alone.

Suggested first wave:

1. `env.example` internal URLs listed above.
2. Compose `mcp_gateway` `${...:-http://...}` fallbacks.
3. Processor `TIKA_URL` and `MINIO_ENDPOINT`.
4. `README.md` tables that document the internal URL defaults.

Existing `.env` files that already contain `http://ai_n8n:5678` keep working until the operator regenerates or edits them. Document that in the playbook, do not migrate `.env` from a script.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Defaults | `env.example` + Compose `:-` fallbacks | Service names |
| Processor | `tika_minio_processor.environment` | `tika` / `minio` |
| Docs | README internal URL table | Match the new defaults |
| CI | `docker compose config` | Confirm interpolation |

### Rules

1. **Service name for in-network HTTP.** `container_name` is for `docker exec` / `docker inspect`.
2. **Do not rewrite Stage 29.** Open WebUI Tika is already specified there; this page is MCP + processor + env.example leftovers.
3. **Do not add network aliases** just to keep `ai_n8n` working after a rename.
4. **Public vhosts stay `*.tu.lan`.** This page is east-west DNS only.
5. **GitHub remains intake.** Requests for a discovery API are out of scope.

### Suggested contributor checklist

```text
1. Replace ai_n8n / ai_affine / ai_n8n_mcp / ai_mcp_gateway / ai_langgraph_supervisor in env.example
2. Match mcp_gateway Compose fallbacks
3. Point processor TIKA_URL and MINIO_ENDPOINT at tika / minio
4. Leave container_name and tu-vm.sh inspect maps unchanged
5. docker compose config still renders
6. With a fresh .env, mcp_gateway and the processor resolve peers
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Internal HTTP | Compose service DNS | `container_name` or IPAM literals |
| Operator CLI names | Existing `container_name: ai_*` | Renaming every container |
| Open WebUI Tika | Stage 29 page | Copying that contract here |
| n8n → Postgres | Stage 28 page | Another static-IP essay |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one PR for `env.example`, Compose fallbacks, and processor env.
3. Mention in CONTRIBUTING that new internal URLs must use service names.

## Acceptance criteria

- [ ] No new default in `env.example` or Compose `:-` uses an `ai_*` hostname.
- [ ] Processor uses `tika` and `minio`.
- [ ] `container_name` values are unchanged.
- [ ] Existing operator `.env` files with `ai_*` URLs still work until edited.
- [ ] Stage 28/29 reviews do not treat this as a rewrite of those pages.

## Rollback

Restore the previous URL defaults. Running containers with old `.env` values are unaffected.

## Success metrics

- New contributors copy `http://n8n:5678`, not `http://ai_n8n:5678`.
- Dropping a `container_name` later does not break MCP or the processor.
- No service-discovery microservice is proposed.
