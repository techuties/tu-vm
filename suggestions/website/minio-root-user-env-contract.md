---
title: MinIO Root User Env Contract
description: Constructional contract for interpolating MINIO_ROOT_USER from .env everywhere admin is hardcoded so identity stays one secret pair.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# MinIO Root User Env Contract

## Problem

`env.example` already declares `MINIO_ROOT_USER=admin`. Compose does not interpolate it:

```yaml
MINIO_ROOT_USER: admin
MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-minio123456}
```

The same literal `admin` is copied into:

| Location | Key / usage |
|---|---|
| `tika_minio_processor` | `MINIO_ACCESS_KEY=admin` |
| `mcp_gateway` default | `KB_MINIO_ACCESS_KEY:-admin` |
| `env.example` | `KB_MINIO_ACCESS_KEY=admin` |
| `tu-vm.sh` `mc alias set` helpers | hardcoded user `admin` |

Changing `MINIO_ROOT_USER` in `.env` (or rotating away from `admin`) updates nothing the containers actually use. Password rotation via `generate-secrets` already works; user rotation is a trap.

Stage 23 is MinIO versioning/ILM. Stage 24 is SSE/KMS. Stage 15 is bucket lifecycle. This page is leftover **identity interpolation**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `env.example` `MINIO_ROOT_USER` | Already the operator-facing name |
| Compose `minio.environment` | Password interpolated; user hardcoded |
| Processor `MINIO_ACCESS_KEY` | Must match the root user |
| MCP `KB_MINIO_ACCESS_KEY` | Must match if KB uses the root pair |
| `tu-vm.sh` MinIO `mc` one-liners | Must pass the same user |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | How `.env` keys are added |
| Stage 24 `minio-sse-kms-contract.md` (expected sibling) | Encryption, not identity |

Out of scope:

- A second IAM user store or LDAP
- Replacing `mc` with a custom client
- Changing bucket names or ILM
- MinIO Console OIDC

## Proposal

Interpolate one user everywhere the root identity is required.

Suggested first wave:

| Location | Suggested value |
|---|---|
| Compose `minio` | `MINIO_ROOT_USER: ${MINIO_ROOT_USER:-admin}` |
| Processor | `MINIO_ACCESS_KEY: ${MINIO_ROOT_USER:-admin}` |
| MCP gateway default | `KB_MINIO_ACCESS_KEY:-${MINIO_ROOT_USER:-admin}` **or** keep a dedicated KB user only if it is created in MinIO |
| `tu-vm.sh` `mc alias set` | `"${MINIO_ROOT_USER:-admin}"` instead of `admin` |
| Docs / generate-secrets output | Print the interpolated user, not a literal |

Prefer keeping the KB pair equal to the root pair until a dedicated `kb` user exists. Do not invent a user-provisioning job.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `minio`, `tika_minio_processor`, `mcp_gateway` | Interpolate the same key |
| Scripts | `tu-vm.sh` MinIO helpers | Read `MINIO_ROOT_USER` |
| Env | `env.example` | Already present; add a one-line "must match processor/KB" note |
| CI | `docker compose config` | Confirm interpolation |

### Rules

1. **One root user key.** `MINIO_ROOT_USER` is the source of truth.
2. **Processor access key is not a second identity** unless a dedicated user is created with `mc admin user`.
3. **Do not commit a non-default user** in samples that operators cannot change.
4. **Password stays `MINIO_ROOT_PASSWORD`.** This page does not change secret generation.
5. **GitHub remains intake.** Requests for "MinIO LDAP" are a different product.

### Suggested contributor checklist

```text
1. Wire MINIO_ROOT_USER on the minio service
2. Point processor MINIO_ACCESS_KEY at the same interpolation
3. Point KB_MINIO_ACCESS_KEY at the same interpolation (or document a dedicated user)
4. Replace literal admin in tu-vm.sh mc alias set
5. Recreate minio + processor; upload a test object
6. docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Root identity | Official `MINIO_ROOT_USER` | Hardcoded `admin` |
| Processor / KB auth | Same interpolated user | A sidecar that syncs users |
| Day-2 `mc` | Existing `tu-vm.sh` helpers | A new MinIO CLI wrapper |
| Encryption | Stage 24 SSE/KMS | Mixing identity into SSE |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one PR that interpolates the user in Compose, processor, KB default, and `mc` helpers.
3. Recreate `ai_minio` after changing the user; existing `minio_data` keeps the previous root identity until `mc admin user` or a volume reset.

## Acceptance criteria

- [ ] Compose `MINIO_ROOT_USER` reads `${MINIO_ROOT_USER:-admin}`.
- [ ] Processor and KB defaults follow that value.
- [ ] `tu-vm.sh` `mc` helpers no longer hardcode `admin`.
- [ ] Changing only `.env` and recreating MinIO + processor is enough to use a non-default user on a fresh volume.
- [ ] Stage 23/24 reviews do not treat this as ILM or SSE.

## Rollback

Restore literal `admin` in Compose and scripts. Existing objects are unchanged; a changed root user on an old volume needs the original identity to unlock.

## Success metrics

- `MINIO_ROOT_USER` in `.env` is no longer a documentation-only key.
- Contributors stop copying `admin` into new services.
- Password **and** user rotation follow the same generate-secrets path.
